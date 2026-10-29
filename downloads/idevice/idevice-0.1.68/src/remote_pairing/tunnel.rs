// Jackson Coxson
//! TLS-PSK tunnel connect helpers for remote pairing.
//!
//! These functions combine TLS-PSK handshake + CDTunnel handshake into a single call.
//! The CDTunnel protocol itself lives in [`crate::tunnel`].

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tracing::debug;

use crate::{IdeviceError, ReadWrite};

// Re-export for backwards compatibility
pub use crate::tunnel::{CdTunnel, TunnelInfo};

const CDTUNNEL_MAGIC: &[u8] = b"CDTunnel";
const DEFAULT_MTU: u16 = 16000;

/// Wraps a `tokio::net::TcpStream` with TLS-PSK using a pure-Rust implementation
/// and performs the CDTunnel handshake, returning a ready-to-use tunnel.
///
/// `encryption_key` is the key from `RemotePairingClient::encryption_key()`.
///
/// This uses a built-in TLS 1.2 PSK-AES256-CBC-SHA384 implementation with no
/// external TLS library dependency.
pub async fn connect_tls_psk_tunnel_native<S: ReadWrite>(
    stream: S,
    encryption_key: &[u8],
) -> Result<CdTunnel<super::tls_psk::TlsPskStream<S>>, IdeviceError> {
    let tls_stream = super::tls_psk::tls_psk_handshake(stream, encryption_key).await?;
    debug!("Native TLS-PSK handshake complete");

    establish_tunnel(tls_stream).await
}

async fn establish_tunnel<S: ReadWrite>(mut tls_stream: S) -> Result<CdTunnel<S>, IdeviceError> {
    // CDTunnel handshake over the authenticated TLS byte stream.
    let request = serde_json::json!({
        "type": "clientHandshakeRequest",
        "mtu": DEFAULT_MTU
    });
    let body = serde_json::to_vec(&request)?;

    let mut pkt = Vec::new();
    pkt.extend_from_slice(CDTUNNEL_MAGIC);
    pkt.extend_from_slice(&(body.len() as u16).to_be_bytes());
    pkt.extend_from_slice(&body);
    tls_stream.write_all(&pkt).await?;
    tls_stream.flush().await?;

    debug!("Sent CDTunnel handshake request via TLS");

    // Read a framed byte stream, not one assumed TLS record. This preserves
    // fragmented responses and any application bytes coalesced after the frame.
    let mut header = [0u8; 10];
    tls_stream.read_exact(&mut header).await?;
    if &header[..CDTUNNEL_MAGIC.len()] != CDTUNNEL_MAGIC {
        return Err(IdeviceError::UnexpectedResponse(
            "Invalid CDTunnel magic".into(),
        ));
    }
    let body_len = usize::from(u16::from_be_bytes([header[8], header[9]]));
    if body_len == 0 || body_len > 16384 {
        return Err(IdeviceError::UnexpectedResponse(
            "Invalid CDTunnel handshake size".into(),
        ));
    }
    let mut response_body = vec![0u8; body_len];
    tls_stream.read_exact(&mut response_body).await?;
    let response: serde_json::Value = serde_json::from_slice(&response_body)
        .map_err(|_| IdeviceError::UnexpectedResponse("Invalid CDTunnel handshake JSON".into()))?;
    if response.get("type").and_then(|value| value.as_str()) != Some("serverHandshakeResponse") {
        return Err(IdeviceError::UnexpectedResponse(
            "Invalid CDTunnel response type".into(),
        ));
    }

    let client_params =
        response
            .get("clientParameters")
            .ok_or(IdeviceError::UnexpectedResponse(
                "missing clientParameters in CDTunnel response".into(),
            ))?;

    let client_address = client_params
        .get("address")
        .and_then(|a| a.as_str())
        .ok_or(IdeviceError::UnexpectedResponse(
            "missing client address in CDTunnel response".into(),
        ))?
        .to_string();

    let mtu = client_params
        .get("mtu")
        .and_then(|m| m.as_u64())
        .filter(|mtu| (1280..=u64::from(DEFAULT_MTU)).contains(mtu))
        .ok_or_else(|| IdeviceError::UnexpectedResponse("Invalid CDTunnel MTU".into()))?
        as u16;

    let server_address = response
        .get("serverAddress")
        .and_then(|a| a.as_str())
        .ok_or(IdeviceError::UnexpectedResponse(
            "missing server address in CDTunnel response".into(),
        ))?
        .to_string();

    let server_rsd_port = response
        .get("serverRSDPort")
        .and_then(|p| p.as_u64())
        .filter(|port| (1..=u64::from(u16::MAX)).contains(port))
        .ok_or_else(|| IdeviceError::UnexpectedResponse("Invalid CDTunnel RSD port".into()))?
        as u16;
    for address in [&client_address, &server_address] {
        let address: std::net::Ipv6Addr = address.parse().map_err(|_| {
            IdeviceError::UnexpectedResponse("Invalid CDTunnel IPv6 address".into())
        })?;
        if address.is_unspecified() || address.is_multicast() {
            return Err(IdeviceError::UnexpectedResponse(
                "Invalid CDTunnel IPv6 address".into(),
            ));
        }
    }

    let info = TunnelInfo {
        client_address,
        netmask: client_params
            .get("netmask")
            .and_then(|n| n.as_str())
            .unwrap_or("")
            .to_string(),
        server_address,
        mtu,
        server_rsd_port,
    };

    debug!("CDTunnel established with validated parameters");

    Ok(CdTunnel {
        inner: tls_stream,
        info,
    })
}

/// Wraps a `tokio::net::TcpStream` with TLS-PSK using OpenSSL and performs
/// the CDTunnel handshake, returning a ready-to-use tunnel.
///
/// `encryption_key` is the key from `RemotePairingClient::encryption_key()`.
///
/// Requires the `openssl` feature and an already authenticated RP pair-verify
/// shared secret. OpenSSL verifies the TLS Finished and CBC record MACs; no
/// handwritten-TLS fallback is attempted.
#[cfg(feature = "openssl")]
pub async fn connect_tls_psk_tunnel<S: ReadWrite>(
    stream: S,
    encryption_key: &[u8],
) -> Result<CdTunnel<tokio_openssl::SslStream<S>>, IdeviceError> {
    use openssl::ssl::{SslConnector, SslMethod, SslVerifyMode, SslVersion};
    // This connector is only for a successfully authenticated RP pair-verify
    // X25519 session. Discovery, host signatures or an unverified exchange do
    // not establish this peer key. There is deliberately no certificate mode or
    // fallback cipher/transport here.
    if encryption_key.len() != 32 {
        return Err(IdeviceError::InternalError(
            "Invalid authenticated RP tunnel key size".into(),
        ));
    }
    let psk = encryption_key.to_vec();
    let mut builder = SslConnector::builder(SslMethod::tls_client())
        .map_err(|_| IdeviceError::InternalError("TLS-PSK configuration failed".into()))?;
    builder.set_verify(SslVerifyMode::PEER);
    builder
        .set_cipher_list("PSK-AES256-CBC-SHA384")
        .map_err(|_| {
            IdeviceError::InternalError("Required TLS-PSK cipher is unavailable".into())
        })?;
    builder.set_psk_client_callback(move |_ssl, _hint, identity, psk_out| {
        if identity.is_empty() || psk_out.len() < psk.len() {
            return Err(openssl::error::ErrorStack::get());
        }
        identity[0] = 0; // RP uses the empty PSK identity, terminated as required by OpenSSL.
        psk_out[..psk.len()].copy_from_slice(&psk);
        Ok(psk.len())
    });
    builder
        .set_min_proto_version(Some(SslVersion::TLS1_2))
        .map_err(|_| IdeviceError::InternalError("TLS-PSK version configuration failed".into()))?;
    builder
        .set_max_proto_version(Some(SslVersion::TLS1_2))
        .map_err(|_| IdeviceError::InternalError("TLS-PSK version configuration failed".into()))?;
    let connector = builder.build();
    // Leave verification defaults in force. In this PSK-only suite identity is
    // proved by the authenticated RP session secret and library-verified Finished;
    // no X.509 certificate or DNS name is accepted as an alternative credential.
    let ssl = connector
        .configure()
        .and_then(|configuration| configuration.into_ssl("localhost"))
        .map_err(|_| IdeviceError::InternalError("TLS-PSK configuration failed".into()))?;

    let mut tls_stream = tokio_openssl::SslStream::new(ssl, stream).map_err(|_| {
        IdeviceError::InternalError("TLS-PSK transport configuration failed".into())
    })?;
    std::pin::Pin::new(&mut tls_stream)
        .connect()
        .await
        .map_err(|_| {
            IdeviceError::InternalError("Authenticated TLS-PSK handshake failed".into())
        })?;
    if tls_stream.ssl().version2() != Some(SslVersion::TLS1_2)
        || tls_stream
            .ssl()
            .current_cipher()
            .map(|cipher| cipher.name())
            != Some("PSK-AES256-CBC-SHA384")
    {
        return Err(IdeviceError::InternalError(
            "Unexpected TLS-PSK negotiated parameters".into(),
        ));
    }
    establish_tunnel(tls_stream).await
}

#[cfg(test)]
mod security_tests {
    use super::*;

    async fn framed_response(
        body: Vec<u8>,
        declared_len: Option<u16>,
        trailing: &[u8],
    ) -> Result<CdTunnel<tokio::io::DuplexStream>, IdeviceError> {
        let (client, mut server) = tokio::io::duplex(65536);
        let trailing = trailing.to_vec();
        let task = tokio::spawn(async move {
            let mut header = [0; 10];
            server.read_exact(&mut header).await.unwrap();
            let request_len = usize::from(u16::from_be_bytes([header[8], header[9]]));
            let mut request = vec![0; request_len];
            server.read_exact(&mut request).await.unwrap();
            let mut response = CDTUNNEL_MAGIC.to_vec();
            response.extend_from_slice(&declared_len.unwrap_or(body.len() as u16).to_be_bytes());
            response.extend_from_slice(&body);
            response.extend_from_slice(&trailing);
            // A fragmented stream is legal; no response-body slice may assume
            // one read/TLS record contained the declared body.
            for fragment in response.chunks(3) {
                if server.write_all(fragment).await.is_err() {
                    break;
                }
            }
        });
        let result = establish_tunnel(client).await;
        task.await.unwrap();
        result
    }
    #[cfg(feature = "openssl")]
    async fn openssl_psk_fixture(valid_key: bool, response: serde_json::Value) {
        use openssl::ssl::{Ssl, SslContextBuilder, SslMethod, SslVerifyMode, SslVersion};
        let mut secret = vec![0u8; 32];
        rand::fill(secret.as_mut_slice());
        let mut server_secret = secret.clone();
        if !valid_key {
            server_secret[0] ^= 1;
        }
        let mut context = SslContextBuilder::new(SslMethod::tls_server()).unwrap();
        context
            .set_min_proto_version(Some(SslVersion::TLS1_2))
            .unwrap();
        context
            .set_max_proto_version(Some(SslVersion::TLS1_2))
            .unwrap();
        context.set_cipher_list("PSK-AES256-CBC-SHA384").unwrap();
        context.set_verify(SslVerifyMode::PEER);
        context.set_psk_server_callback(move |_ssl, identity, output| {
            if identity != Some(b"".as_slice()) || output.len() < server_secret.len() {
                return Err(openssl::error::ErrorStack::get());
            }
            output[..server_secret.len()].copy_from_slice(&server_secret);
            Ok(server_secret.len())
        });
        let context = context.build();
        let (client, server) = tokio::io::duplex(65536);
        let task = tokio::spawn(async move {
            let ssl = Ssl::new(&context).unwrap();
            let mut server = tokio_openssl::SslStream::new(ssl, server).unwrap();
            let accepted = std::pin::Pin::new(&mut server).accept().await.is_ok();
            if !accepted {
                return false;
            }
            assert_eq!(server.ssl().version2(), Some(SslVersion::TLS1_2));
            assert_eq!(
                server.ssl().current_cipher().unwrap().name(),
                "PSK-AES256-CBC-SHA384"
            );
            let mut header = [0; 10];
            server.read_exact(&mut header).await.unwrap();
            let mut request = vec![0; usize::from(u16::from_be_bytes([header[8], header[9]]))];
            server.read_exact(&mut request).await.unwrap();
            let body = serde_json::to_vec(&response).unwrap();
            let mut framed = CDTUNNEL_MAGIC.to_vec();
            framed.extend_from_slice(&(body.len() as u16).to_be_bytes());
            framed.extend_from_slice(&body);
            server.write_all(&framed).await.unwrap();
            server.flush().await.unwrap();
            true
        });
        let result = connect_tls_psk_tunnel(client, &secret).await;
        assert_eq!(
            result.is_ok(),
            valid_key,
            "Production OpenSSL connector must reject a peer lacking the exact authenticated RP PSK"
        );
        assert_eq!(task.await.unwrap(), valid_key);
    }
    #[tokio::test]
    async fn rp_tunnel_security_fragmentation_truncation_and_endpoint_bounds() {
        super::super::socket::assert_rp_socket_security().await;
        let valid = serde_json::json!({"type":"serverHandshakeResponse","clientParameters":{"address":"fd00::2","mtu":1500},"serverAddress":"fd00::1","serverRSDPort":12345});
        #[cfg(feature = "openssl")]
        {
            openssl_psk_fixture(true, valid.clone()).await;
            openssl_psk_fixture(false, valid.clone()).await;
        }
        let mut tunnel = framed_response(serde_json::to_vec(&valid).unwrap(), None, b"next packet")
            .await
            .unwrap();
        assert_eq!(tunnel.info.server_rsd_port, 12345);
        let mut next = [0; 11];
        tunnel.inner.read_exact(&mut next).await.unwrap();
        assert_eq!(
            &next, b"next packet",
            "Handshake must preserve coalesced application bytes"
        );
        assert!(
            framed_response(vec![b'{'], Some(100), &[]).await.is_err(),
            "Truncated declared body fails without panic"
        );
        assert!(framed_response(vec![], Some(0), &[]).await.is_err());
        assert!(framed_response(vec![], Some(u16::MAX), &[]).await.is_err());
        for (field, value) in [
            ("serverRSDPort", serde_json::json!(65536)),
            ("serverRSDPort", serde_json::json!(0)),
            ("serverAddress", serde_json::json!("203.0.113.1")),
            ("serverAddress", serde_json::json!("::")),
            ("type", serde_json::json!("clientHandshakeRequest")),
        ] {
            let mut invalid = valid.clone();
            invalid[field] = value;
            assert!(
                framed_response(serde_json::to_vec(&invalid).unwrap(), None, &[])
                    .await
                    .is_err()
            );
        }
        for mtu in [0, 1279, 16001, 65536] {
            let mut invalid = valid.clone();
            invalid["clientParameters"]["mtu"] = serde_json::json!(mtu);
            assert!(
                framed_response(serde_json::to_vec(&invalid).unwrap(), None, &[])
                    .await
                    .is_err()
            );
        }
    }
}
