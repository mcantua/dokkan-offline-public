//! Credential-selected device transport. Pair verification authenticates the
//! pinned device before any PSK tunnel or RSD service is used. No auto re-pairing,
//! legacy fallback, system TUN interface or changes to routing are involved.
use super::*;
use idevice::{
    lockdown::LockdownClient,
    remote_pairing::{RemotePairingClient, RpPairingFile, RpPairingSocket},
    rsd::RsdHandshake,
    tcp::{adapter::Adapter, handle::AdapterHandle},
    IdeviceError, ReadWrite, RsdService,
};
use std::{future::Future, net::{IpAddr, Ipv6Addr}};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

pub(super) enum Credentials { Lockdown(PairingFile), Remote(RpPairingFile) }
impl Credentials {
    pub(super) fn kind(&self) -> &'static str {
        match self { Self::Lockdown(_) => "lockdown", Self::Remote(_) => "remote" }
    }
}
pub(super) fn parse_credentials(bytes: &[u8]) -> Result<Credentials, Report> {
    if bytes.is_empty() || bytes.len() > 1024 * 1024 { return Err(failure("The pairing file size is invalid.")); }
    let fields: plist::Dictionary = plist::from_bytes(bytes)
        .map_err(|_| failure("The pairing file could not be read safely."))?;
    if ["format_version", "public_key", "private_key", "peer_identifier", "peer_public_key"].iter().any(|key| fields.contains_key(key)) {
        RpPairingFile::from_bytes(bytes).map(Credentials::Remote)
            .map_err(|_| failure("Remote Pairing requires a version-2 trusted USB export with its authenticated device identity. Create a new secure export for this iPhone."))
    } else {
        PairingFile::from_bytes(bytes).map(Credentials::Lockdown)
            .map_err(|_| failure("The Lockdown pairing file could not be read safely."))
    }
}
async fn step<T>(message: &'static str, future: impl Future<Output=Result<T,IdeviceError>>) -> Result<T,Report> {
    match tokio::time::timeout(Duration::from_secs(20),future).await {
        Ok(Ok(value)) => Ok(value),
        _ => Err(failure(message)),
    }
}
// This connector is intentionally local to core. Enabling idevice's OpenSSL
// feature would also select unrelated legacy TLS behavior and is prohibited.
async fn authenticated_psk<S: ReadWrite>(stream:S,key:&[u8]) -> Result<tokio_openssl::SslStream<S>,IdeviceError> {
    use openssl::ssl::{SslConnector,SslMethod,SslVerifyMode,SslVersion};
    fn invalid() -> IdeviceError { IdeviceError::InternalError("Authenticated RP TLS-PSK failed".into()) }
    if key.len()!=32 {return Err(invalid());}
    let key=Zeroizing::new(key.to_vec());
    let mut builder=SslConnector::builder(SslMethod::tls_client()).map_err(|_|invalid())?;
    builder.set_verify(SslVerifyMode::PEER);
    builder.set_min_proto_version(Some(SslVersion::TLS1_2)).map_err(|_|invalid())?;
    builder.set_max_proto_version(Some(SslVersion::TLS1_2)).map_err(|_|invalid())?;
    builder.set_cipher_list("PSK-AES256-CBC-SHA384").map_err(|_|invalid())?;
    builder.set_psk_client_callback(move |_,_,identity,output| {
        if identity.is_empty() || output.len()<key.len() {return Err(openssl::error::ErrorStack::get());}
        identity[0]=0;
        output[..key.len()].copy_from_slice(&key);
        Ok(key.len())
    });
    // No accept-all verifier, certificate fallback, hostname-verification
    // override, PSK truncation or handwritten TLS implementation.
    let ssl=builder.build().configure().and_then(|config|config.into_ssl("localhost")).map_err(|_|invalid())?;
    let mut stream=tokio_openssl::SslStream::new(ssl,stream).map_err(|_|invalid())?;
    std::pin::Pin::new(&mut stream).connect().await.map_err(|_|invalid())?;
    if stream.ssl().version2()!=Some(SslVersion::TLS1_2) || stream.ssl().current_cipher().map(|cipher|cipher.name())!=Some("PSK-AES256-CBC-SHA384") {return Err(invalid());}
    Ok(stream)
}
struct TunnelParameters { client:Ipv6Addr, server:Ipv6Addr, mtu:u16, rsd_port:u16 }
/// Independently owns OS shutdown of the tunnel socket. jktcp moves its TLS
/// stream into a detached task whose pending connect can block before polling
/// the handle channel again. Closing a handle alone cannot interrupt that read.
/// shutdown(Both) applies to every duplicated descriptor for this connection,
/// including the descriptor inside OpenSSL/the adapter, without an async wait.
struct TunnelShutdown(std::net::TcpStream);
impl TunnelShutdown {
    fn retain(stream:tokio::net::TcpStream)->std::io::Result<(tokio::net::TcpStream,Self)>{
        let stream=stream.into_std()?;
        let shutdown=Self(stream.try_clone()?);
        let stream=tokio::net::TcpStream::from_std(stream)?;
        Ok((stream,shutdown))
    }
}
impl Drop for TunnelShutdown {
    fn drop(&mut self){let _=self.0.shutdown(std::net::Shutdown::Both);}
}
async fn tunnel_handshake<S:ReadWrite>(mut stream:S) -> Result<(S,TunnelParameters),IdeviceError> {
    fn invalid() -> IdeviceError {IdeviceError::UnexpectedResponse("Invalid authenticated RP tunnel parameters".into())}
    let body=serde_json::to_vec(&json!({"type":"clientHandshakeRequest","mtu":16000})).map_err(|_|invalid())?;
    let mut request=b"CDTunnel".to_vec(); request.extend_from_slice(&(body.len() as u16).to_be_bytes()); request.extend_from_slice(&body);
    stream.write_all(&request).await?; stream.flush().await?;
    // A TLS byte stream can fragment or coalesce records. Read only this exact
    // frame, leaving following IP bytes in the TLS stream for the userspace stack.
    let mut header=[0;10];stream.read_exact(&mut header).await?;
    if &header[..8]!=b"CDTunnel" {return Err(invalid());}
    let length=usize::from(u16::from_be_bytes([header[8],header[9]]));
    if length==0 || length>16384 {return Err(invalid());}
    let mut body=vec![0;length];stream.read_exact(&mut body).await?;
    let value:Value=serde_json::from_slice(&body).map_err(|_|invalid())?;
    if value.get("type").and_then(Value::as_str)!=Some("serverHandshakeResponse") {return Err(invalid());}
    let client=value.get("clientParameters").ok_or_else(invalid)?;
    let address=|value:Option<&Value>|->Result<Ipv6Addr,IdeviceError>{
        let address:Ipv6Addr=value.and_then(Value::as_str).ok_or_else(invalid)?.parse().map_err(|_|invalid())?;
        if address.is_unspecified()||address.is_multicast(){return Err(invalid());} Ok(address)
    };
    let parameters=TunnelParameters{
        client:address(client.get("address"))?, server:address(value.get("serverAddress"))?,
        mtu:client.get("mtu").and_then(Value::as_u64).filter(|value|(1280..=16000).contains(value)).ok_or_else(invalid)? as u16,
        rsd_port:value.get("serverRSDPort").and_then(Value::as_u64).filter(|value|(1..=u64::from(u16::MAX)).contains(value)).ok_or_else(invalid)? as u16,
    };
    if parameters.client==parameters.server {return Err(invalid());}
    Ok((stream,parameters))
}
pub(super) enum DeviceTransport {
    Lockdown(TcpProvider),
    // Fields drop in declaration order: shutdown interrupts the detached worker
    // before handles/control are released. During construction the local guard
    // likewise survives every await and shuts down on error/cancellation.
    Remote { _shutdown:TunnelShutdown, handle:AdapterHandle, handshake:RsdHandshake, _control:RemotePairingClient<RpPairingSocket<tokio::net::TcpStream>> },
}
impl DeviceTransport {
    pub(super) async fn connect(credentials:Credentials,host:IpAddr,port:u16)->Result<Self,Report>{
        match credentials {
            Credentials::Lockdown(pairing_file)=>Ok(Self::Lockdown(TcpProvider{addr:host,scope_id:None,pairing_file,label:"AppInstaller".into()})),
            Credentials::Remote(mut pairing)=>{
                if port==0 {return Err(failure("Remote Pairing service port is invalid."));}
                let stream=step("The Remote Pairing service could not be reached. Keep LocalDevVPN connected on this iPhone.",async{Ok::<_,IdeviceError>(tokio::net::TcpStream::connect((host,port)).await?)}).await?;
                let mut control=RemotePairingClient::new(RpPairingSocket::new(stream),"App Installer");
                step("The Remote Pairing handshake could not be established.",control.attempt_pair_verify()).await?;
                step("The Remote Pairing device identity could not be authenticated. Import this iPhone's trusted USB export.",control.validate_pairing(&mut pairing)).await?;
                let port=step("The authenticated device could not open its Remote Pairing tunnel.",control.create_tcp_listener()).await?;
                let key=Zeroizing::new(control.authenticated_encryption_key().map_err(|_|failure("Remote Pairing has no authenticated tunnel key."))?.to_vec());
                let stream=step("The authenticated Remote Pairing tunnel could not be reached.",async{Ok::<_,IdeviceError>(tokio::net::TcpStream::connect((host,port)).await?)}).await?;
                let (stream,shutdown)=TunnelShutdown::retain(stream).map_err(|_|failure("The authenticated tunnel could not establish cancellation ownership."))?;
                let stream=step("The authenticated Remote Pairing TLS tunnel could not be established.",authenticated_psk(stream,&key)).await?;
                let (stream,parameters)=step("The authenticated device returned invalid tunnel parameters.",tunnel_handshake(stream)).await?;
                let mut adapter=Adapter::new(Box::new(stream),IpAddr::V6(parameters.client),IpAddr::V6(parameters.server));
                adapter.set_mss(usize::from(parameters.mtu)-60);
                let mut handle=adapter.to_async_handle();
                let stream=step("Remote service discovery could not connect through the authenticated tunnel.",async{Ok::<_,IdeviceError>(handle.connect(parameters.rsd_port).await?)}).await?;
                let handshake=step("The authenticated device's service discovery handshake failed.",RsdHandshake::new(stream)).await?;
                Ok(Self::Remote{_shutdown:shutdown,handle,handshake,_control:control})
            }
        }
    }
    pub(super) async fn cleanup(&mut self,work:&Path)->Result<(),Report>{
        let result=match self {
            Self::Lockdown(provider)=>tokio::time::timeout(Duration::from_secs(20),crate::cleanup::retry(work,provider)).await,
            Self::Remote{handle,handshake,..}=>tokio::time::timeout(Duration::from_secs(20),crate::cleanup::retry_rsd(work,handle,handshake)).await,
        };
        match result {Ok(Ok(()))=>Ok(()),_=>Err(failure("Device staging cleanup could not finish safely. No app records were removed."))}
    }
    pub(super) async fn apps(&mut self,work:&Path)->Result<HashMap<String,plist::Value>,Report>{
        self.cleanup(work).await?;
        let mut client=match self{
            Self::Lockdown(provider)=>step("The paired device's app service could not be opened.",InstallationProxyClient::connect(provider)).await?,
            Self::Remote{handle,handshake,..}=>step("The authenticated remote app service could not be opened.",InstallationProxyClient::connect_rsd(handle,handshake)).await?,
        };
        step("The connected device's installed apps could not be checked. App records were kept.",client.get_apps_with_attributes(Some("User"),None,Some(vec!["CFBundleIdentifier".into(),"CFBundleVersion".into(),"CFBundleShortVersionString".into()]))).await
    }
    pub(super) async fn profiles(&mut self)->Result<Vec<Vec<u8>>,Report>{
        let mut client=match self{
            Self::Lockdown(provider)=>step("The paired device's development profiles could not be opened.",MisagentClient::connect(provider)).await?,
            Self::Remote{handle,handshake,..}=>step("The authenticated device's development profiles could not be opened.",MisagentClient::connect_rsd(handle,handshake)).await?,
        };
        step("Current development-app usage could not be verified. No install was started.",client.copy_all()).await
    }
    pub(super) async fn info(&mut self)->Result<isideload::util::device::IdeviceInfo,Report>{
        match self{
            Self::Lockdown(provider)=>tokio::time::timeout(Duration::from_secs(20),isideload::util::device::IdeviceInfo::from_device(provider)).await.map_err(|_|failure("The paired device's identity check timed out."))?.map_err(|_|failure("The paired device's identity could not be read.")),
            Self::Remote{handle,handshake,..}=>{
                let mut client=step("The authenticated device's identity service could not be opened.",LockdownClient::connect_rsd(handle,handshake)).await?;
                let name=step("The authenticated device name could not be read.",client.get_value(Some("DeviceName"),None)).await?.as_string().ok_or_else(||failure("The device returned invalid identity metadata."))?.to_owned();
                let udid=step("The authenticated device identity could not be read.",client.get_value(Some("UniqueDeviceID"),None)).await?.as_string().ok_or_else(||failure("The device returned invalid identity metadata."))?.to_owned();
                if name.is_empty()||udid.is_empty()||name.len()>1024||udid.len()>255{return Err(failure("The device returned invalid identity metadata."));}
                Ok(isideload::util::device::IdeviceInfo::new(name,udid))
            }
        }
    }
    pub(super) async fn install(&mut self,path:&Path)->Result<(),Report>{
        let callback=|p|publish("progress","Installing…",json!({"progress":p as f64/100.0}));
        let result=match self{
            Self::Lockdown(provider)=>isideload::sideload::install::install_app(provider,path,callback).await,
            Self::Remote{handle,handshake,..}=>isideload::sideload::install::install_app_rsd(handle,handshake,path,callback).await,
        };
        result.map_err(|_|failure("The device did not confirm this installation. Its approved source was kept for recovery; no success was recorded."))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Observes destruction of the real adapter-owned TLS stream, rather than
    // treating loss of a front-end handle as proof that its worker terminated.
    #[derive(Debug)]
    struct ObservedTransport<S:ReadWrite>{inner:S,dropped:Option<tokio::sync::oneshot::Sender<()>>}
    impl<S:ReadWrite> Drop for ObservedTransport<S>{
        fn drop(&mut self){if let Some(sender)=self.dropped.take(){let _=sender.send(());}}
    }
    impl<S:ReadWrite> tokio::io::AsyncRead for ObservedTransport<S>{
        fn poll_read(mut self:std::pin::Pin<&mut Self>,cx:&mut std::task::Context<'_>,buffer:&mut tokio::io::ReadBuf<'_>)->std::task::Poll<std::io::Result<()>>{
            std::pin::Pin::new(&mut self.inner).poll_read(cx,buffer)
        }
    }
    impl<S:ReadWrite> tokio::io::AsyncWrite for ObservedTransport<S>{
        fn poll_write(mut self:std::pin::Pin<&mut Self>,cx:&mut std::task::Context<'_>,buffer:&[u8])->std::task::Poll<std::io::Result<usize>>{
            std::pin::Pin::new(&mut self.inner).poll_write(cx,buffer)
        }
        fn poll_flush(mut self:std::pin::Pin<&mut Self>,cx:&mut std::task::Context<'_>)->std::task::Poll<std::io::Result<()>>{
            std::pin::Pin::new(&mut self.inner).poll_flush(cx)
        }
        fn poll_shutdown(mut self:std::pin::Pin<&mut Self>,cx:&mut std::task::Context<'_>)->std::task::Poll<std::io::Result<()>>{
            std::pin::Pin::new(&mut self.inner).poll_shutdown(cx)
        }
    }

    #[tokio::test]
    async fn public_remote_transport_psk_requires_matching_secret_and_real_tls_finished() {
        use openssl::ssl::{Ssl,SslContextBuilder,SslMethod,SslVerifyMode,SslVersion};
        #[derive(Clone, Copy, PartialEq, Eq)]
        enum Case { Matching, WrongPsk, WrongCipher, CorruptServerFinishedRecord }
        for case in [Case::Matching, Case::WrongPsk, Case::WrongCipher, Case::CorruptServerFinishedRecord] {
            // Independent OpenSSL server, entirely in memory. No device socket,
            // Apple request, credentials, certificate bypass or filesystem key.
            let server_key=[0x5au8;32];
            let mut builder=SslContextBuilder::new(SslMethod::tls_server()).unwrap();
            builder.set_verify(SslVerifyMode::PEER);
            builder.set_min_proto_version(Some(SslVersion::TLS1_2)).unwrap();
            builder.set_max_proto_version(Some(SslVersion::TLS1_2)).unwrap();
            builder.set_cipher_list(if case==Case::WrongCipher {"PSK-AES128-CBC-SHA"} else {"PSK-AES256-CBC-SHA384"}).unwrap();
            builder.set_psk_server_callback(move |_,_,output| {
                if output.len()<server_key.len(){return Err(openssl::error::ErrorStack::get());}
                output[..server_key.len()].copy_from_slice(&server_key);Ok(server_key.len())
            });
            let ssl=Ssl::new(&builder.build()).unwrap();
            let (client,downstream)=tokio::io::duplex(65536);
            let (upstream,server)=tokio::io::duplex(65536);
            let (mut from_client,mut to_client)=tokio::io::split(downstream);
            let (mut from_server,mut to_server)=tokio::io::split(upstream);
            let client_relay=tokio::spawn(async move {let _=tokio::io::copy(&mut from_client,&mut to_server).await;});
            let server_relay=tokio::spawn(async move {
                let mut encrypted=false;let mut corrupted=false;
                loop {
                    let mut header=[0u8;5];
                    if from_server.read_exact(&mut header).await.is_err(){break;}
                    let size=usize::from(u16::from_be_bytes([header[3],header[4]]));assert!(size<=18432);
                    let mut body=vec![0;size];if from_server.read_exact(&mut body).await.is_err(){break;}
                    if header[0]==20{encrypted=true;}
                    else if header[0]==22 && encrypted && !corrupted && case==Case::CorruptServerFinishedRecord {
                        // Corrupt the actual encrypted server Finished record,
                        // keeping TLS framing intact. Library record MAC/Finished
                        // verification must fail before returning a usable stream.
                        *body.last_mut().unwrap()^=1;corrupted=true;
                    }
                    if to_client.write_all(&header).await.is_err() || to_client.write_all(&body).await.is_err(){break;}
                }
                corrupted
            });
            let server=tokio::spawn(async move {
                let mut stream=tokio_openssl::SslStream::new(ssl,server).unwrap();
                let accepted=std::pin::Pin::new(&mut stream).accept().await;
                if case==Case::Matching {
                    accepted.unwrap();
                    let mut message=[0;4];stream.read_exact(&mut message).await.unwrap();
                    assert_eq!(&message,b"ping");stream.write_all(b"pong").await.unwrap();
                } else if case==Case::CorruptServerFinishedRecord { accepted.unwrap(); }
                else {assert!(accepted.is_err());}
            });
            let key=if case==Case::WrongPsk{[0xa5;32]}else{[0x5a;32]};
            let result=tokio::time::timeout(Duration::from_secs(5),authenticated_psk(client,&key)).await.unwrap();
            if case==Case::Matching {
                let mut client=result.unwrap();client.write_all(b"ping").await.unwrap();
                let mut message=[0;4];client.read_exact(&mut message).await.unwrap();assert_eq!(&message,b"pong");
            }else{assert!(result.is_err());}
            tokio::time::timeout(Duration::from_secs(5),server).await.unwrap().unwrap();
            assert_eq!(tokio::time::timeout(Duration::from_secs(5),server_relay).await.unwrap().unwrap(),case==Case::CorruptServerFinishedRecord);
            client_relay.abort();
        }
        for length in [0,16,31,33,64] {
            let (client,_)=tokio::io::duplex(128);
            assert!(authenticated_psk(client,&vec![1;length]).await.is_err());
        }
    }
    #[tokio::test]
    async fn public_remote_transport_tunnel_frames_are_bounded_and_preserve_following_ip_bytes() {
        async fn response(value:Value,declared:Option<u16>,trailing:&[u8])->Result<(tokio::io::DuplexStream,TunnelParameters),IdeviceError>{
            let (client,mut server)=tokio::io::duplex(65536);
            let trailing=trailing.to_vec();
            let peer=tokio::spawn(async move {
                let mut header=[0;10];server.read_exact(&mut header).await.unwrap();assert_eq!(&header[..8],b"CDTunnel");
                let mut request=vec![0;usize::from(u16::from_be_bytes([header[8],header[9]]))];server.read_exact(&mut request).await.unwrap();
                let request:Value=serde_json::from_slice(&request).unwrap();assert_eq!(request["type"],"clientHandshakeRequest");
                let body=serde_json::to_vec(&value).unwrap();let mut frame=b"CDTunnel".to_vec();frame.extend_from_slice(&declared.unwrap_or(body.len() as u16).to_be_bytes());frame.extend_from_slice(&body);frame.extend_from_slice(&trailing);
                for fragment in frame.chunks(3){server.write_all(fragment).await.unwrap();}
            });
            let result=tokio::time::timeout(Duration::from_secs(5),tunnel_handshake(client)).await.unwrap();peer.await.unwrap();result
        }
        let valid=json!({"type":"serverHandshakeResponse","clientParameters":{"address":"::2","mtu":1500},"serverAddress":"::3","serverRSDPort":1234});
        let (mut stream,parameters)=response(valid.clone(),None,&[0x60,0,0,0,1]).await.unwrap();
        assert_eq!(parameters.mtu,1500);assert_eq!(parameters.rsd_port,1234);
        let mut following=[0;5];stream.read_exact(&mut following).await.unwrap();assert_eq!(following,[0x60,0,0,0,1]);
        for (key,value) in [("serverRSDPort",json!(0)),("serverRSDPort",json!(65536)),("serverAddress",json!("::")),("serverAddress",json!("ff02::1")),("serverAddress",json!("::2")),("type",json!("clientHandshakeRequest"))]{
            let mut invalid=valid.clone();invalid[key]=value;assert!(response(invalid,None,&[]).await.is_err());
        }
        for mtu in [0,1279,16001,65536]{let mut invalid=valid.clone();invalid["clientParameters"]["mtu"]=json!(mtu);assert!(response(invalid,None,&[]).await.is_err());}
        assert!(response(valid.clone(),Some(0),&[]).await.is_err());
        assert!(response(valid.clone(),Some(16385),&[]).await.is_err());
        assert!(response(valid,Some(16384),&[]).await.is_err());
        // A plain/unpinned remote record never falls through to legacy Lockdown.
        let unpinned=RpPairingFile::generate("synthetic-host").to_bytes();
        assert!(parse_credentials(&unpinned).is_err());

        // Reproduce a SYN read blocked inside the actual detached jktcp worker.
        // A real cloud-loopback TLS peer completes the production PSK/CDTunnel
        // handshakes, consumes the SYN, then deliberately never sends SYN-ACK.
        // Both an outer timeout and task abortion must interrupt the actual OS
        // socket and destroy the background worker's TLS stream within a bound.
        async fn blocked_worker_ends(cancel:bool){
            use openssl::ssl::{Ssl,SslContextBuilder,SslMethod,SslVerifyMode,SslVersion};
            let key=[0x71u8;32];
            let mut context=SslContextBuilder::new(SslMethod::tls_server()).unwrap();
            context.set_verify(SslVerifyMode::PEER);
            context.set_min_proto_version(Some(SslVersion::TLS1_2)).unwrap();
            context.set_max_proto_version(Some(SslVersion::TLS1_2)).unwrap();
            context.set_cipher_list("PSK-AES256-CBC-SHA384").unwrap();
            context.set_psk_server_callback(move |_,_,output|{
                if output.len()<key.len(){return Err(openssl::error::ErrorStack::get());}
                output[..key.len()].copy_from_slice(&key);Ok(key.len())
            });
            let ssl=Ssl::new(&context.build()).unwrap();
            let listener=tokio::net::TcpListener::bind((std::net::Ipv4Addr::LOCALHOST,0)).await.unwrap();
            let address=listener.local_addr().unwrap();
            let (syn_sent,syn_received)=tokio::sync::oneshot::channel();
            let server=tokio::spawn(async move{
                let (stream,_)=listener.accept().await.unwrap();
                let mut stream=tokio_openssl::SslStream::new(ssl,stream).unwrap();
                std::pin::Pin::new(&mut stream).accept().await.unwrap();
                let mut header=[0u8;10];stream.read_exact(&mut header).await.unwrap();
                assert_eq!(&header[..8],b"CDTunnel");
                let mut request=vec![0;usize::from(u16::from_be_bytes([header[8],header[9]]))];stream.read_exact(&mut request).await.unwrap();
                let response=serde_json::to_vec(&json!({"type":"serverHandshakeResponse","clientParameters":{"address":"::2","mtu":1500},"serverAddress":"::3","serverRSDPort":1234})).unwrap();
                stream.write_all(b"CDTunnel").await.unwrap();stream.write_all(&(response.len() as u16).to_be_bytes()).await.unwrap();stream.write_all(&response).await.unwrap();
                let mut ip=[0u8;40];stream.read_exact(&mut ip).await.unwrap();
                assert_eq!(ip[0]>>4,6);assert_eq!(ip[6],6);
                let mut tcp=vec![0;usize::from(u16::from_be_bytes([ip[4],ip[5]]))];stream.read_exact(&mut tcp).await.unwrap();
                assert!(tcp.len()>=20);assert_ne!(tcp[13]&2,0);
                syn_sent.send(()).unwrap();
                let closed=async{
                    let mut bytes=[0;4096];
                    loop{match stream.read(&mut bytes).await{Ok(0)|Err(_)=>break,Ok(_)=>{}}}
                };
                tokio::time::timeout(Duration::from_secs(2),closed).await.expect("tunnel socket remained open after owner drop");
            });
            let stream=tokio::net::TcpStream::connect(address).await.unwrap();
            let (stream,shutdown)=TunnelShutdown::retain(stream).unwrap();
            let stream=authenticated_psk(stream,&key).await.unwrap();
            let (stream,parameters)=tunnel_handshake(stream).await.unwrap();
            let (dropped,worker_ended)=tokio::sync::oneshot::channel();
            let transport=ObservedTransport{inner:stream,dropped:Some(dropped)};
            let mut adapter=Adapter::new(Box::new(transport),IpAddr::V6(parameters.client),IpAddr::V6(parameters.server));
            adapter.set_mss(usize::from(parameters.mtu)-60);
            let owner=tokio::spawn(async move{
                let _shutdown=shutdown;
                let mut handle=adapter.to_async_handle();
                tokio::time::timeout(Duration::from_millis(250),handle.connect(parameters.rsd_port)).await.is_err()
            });
            tokio::time::timeout(Duration::from_secs(2),syn_received).await.unwrap().unwrap();
            if cancel{owner.abort();assert!(owner.await.unwrap_err().is_cancelled());}
            else{assert!(owner.await.unwrap());}
            tokio::time::timeout(Duration::from_secs(2),worker_ended).await.expect("detached adapter worker retained its TLS stream").unwrap();
            tokio::time::timeout(Duration::from_secs(2),server).await.unwrap().unwrap();
        }
        blocked_worker_ends(false).await;
        blocked_worker_ends(true).await;
    }
}
