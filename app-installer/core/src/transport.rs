//! Explicit credential-selected device transport. RP authenticates a pinned device
//! before audited TLS-PSK and RSD. No legacy failure can silently change transport.
use super::*;
use idevice::{
    remote_pairing::{connect_tls_psk_tunnel, RemotePairingClient, RpPairingFile, RpPairingSocket},
    rsd::RsdHandshake,
    tcp::{adapter::Adapter, handle::AdapterHandle},
    RsdService,
};
use std::net::IpAddr;

pub(super) enum Credentials {
    Lockdown(PairingFile),
    Remote(RpPairingFile),
}
impl Credentials {
    pub(super) fn kind(&self) -> &'static str {
        match self {
            Self::Lockdown(_) => "lockdown",
            Self::Remote(_) => "remote",
        }
    }
}
pub(super) fn parse_credentials(bytes: &[u8]) -> Result<Credentials, Report> {
    let dictionary: plist::Dictionary = plist::from_bytes(bytes)
        .map_err(|_| failure("The pairing file could not be read safely."))?;
    if dictionary.contains_key("public_key")
        || dictionary.contains_key("app_installer_rp_version")
        || dictionary.contains_key("peer_public_key")
    {
        return RpPairingFile::from_bytes(bytes).map(Credentials::Remote).map_err(|_|failure("Remote Pairing requires a trusted version-2 USB export with its device identity pin. Create a new secure export for this iPhone."));
    }
    PairingFile::from_bytes(bytes)
        .map(Credentials::Lockdown)
        .map_err(|_| failure("The Lockdown pairing file could not be read safely."))
}
pub(super) enum DeviceTransport {
    Lockdown(TcpProvider),
    Remote {
        handle: AdapterHandle,
        handshake: RsdHandshake,
        _control: RemotePairingClient<RpPairingSocket<tokio::net::TcpStream>>,
    },
}
impl DeviceTransport {
    pub(super) async fn connect(
        credentials: Credentials,
        host: IpAddr,
        rp_port: u16,
    ) -> Result<Self, Report> {
        match credentials {
            Credentials::Lockdown(pairing) => Ok(Self::Lockdown(TcpProvider {
                addr: host,
                scope_id: None,
                pairing_file: pairing,
                label: "AppInstaller".into(),
            })),
            Credentials::Remote(mut pairing) => {
                let stream = device_step(DeviceStage::RemoteControl, async {
                    Ok::<_, IdeviceError>(tokio::net::TcpStream::connect((host, rp_port)).await?)
                })
                .await?;
                let mut control =
                    RemotePairingClient::new(RpPairingSocket::new(stream), "App Installer");
                device_step(DeviceStage::RemoteVerify, control.attempt_pair_verify()).await?;
                device_step(
                    DeviceStage::RemoteVerify,
                    control.validate_pairing(&mut pairing),
                )
                .await?;
                let port =
                    device_step(DeviceStage::RemoteTunnel, control.create_tcp_listener()).await?;
                let key=control.authenticated_encryption_key().map_err(|_|failure("The Remote Pairing device identity was not authenticated. No tunnel was opened."))?;
                let stream = device_step(DeviceStage::RemoteTunnel, async {
                    Ok::<_, IdeviceError>(tokio::net::TcpStream::connect((host, port)).await?)
                })
                .await?;
                let tunnel = device_step(
                    DeviceStage::RemoteTunnel,
                    connect_tls_psk_tunnel(stream, key),
                )
                .await?;
                let our_ip: IpAddr = tunnel.info.client_address.parse().map_err(|_| {
                    failure("The authenticated device tunnel returned an invalid address.")
                })?;
                let their_ip: IpAddr = tunnel.info.server_address.parse().map_err(|_| {
                    failure("The authenticated device tunnel returned an invalid address.")
                })?;
                let rsd_port = tunnel.info.server_rsd_port;
                let mtu = tunnel.info.mtu;
                let mut adapter = Adapter::new(Box::new(tunnel.into_inner()), our_ip, their_ip);
                adapter.set_mss(usize::from(mtu).saturating_sub(60));
                let mut handle = adapter.to_async_handle();
                let stream = device_step(DeviceStage::RemoteDiscovery, async {
                    Ok::<_, IdeviceError>(handle.connect(rsd_port).await?)
                })
                .await?;
                let handshake =
                    device_step(DeviceStage::RemoteDiscovery, RsdHandshake::new(stream)).await?;
                Ok(Self::Remote {
                    handle,
                    handshake,
                    _control: control,
                })
            }
        }
    }
    pub(super) async fn cleanup(&mut self, work: &Path) -> Result<(), Report> {
        let result = match self {
            Self::Lockdown(provider) => {
                tokio::time::timeout(
                    DeviceStage::Cleanup.timeout(),
                    crate::cleanup::retry(work, provider),
                )
                .await
            }
            Self::Remote {
                handle, handshake, ..
            } => {
                tokio::time::timeout(
                    DeviceStage::Cleanup.timeout(),
                    crate::cleanup::retry_rsd(work, handle, handshake),
                )
                .await
            }
        };
        match result {
            Ok(Ok(())) => Ok(()),
            Ok(Err(_)) => Err(Report::new(device_diagnostic(
                DeviceStage::Cleanup,
                Some(&IdeviceError::UnexpectedResponse(String::new())),
            ))
            .into()),
            Err(_) => Err(Report::new(device_diagnostic(DeviceStage::Cleanup, None)).into()),
        }
    }
    pub(super) async fn apps(
        &mut self,
        work: &Path,
    ) -> Result<HashMap<String, plist::Value>, Report> {
        match self {
            Self::Lockdown(provider) => lockdown_apps(provider, work).await,
            Self::Remote {
                handle, handshake, ..
            } => {
                let cleanup = DeviceStage::Cleanup;
                match tokio::time::timeout(cleanup.timeout(),crate::cleanup::retry_rsd(work,handle,handshake)).await{Ok(Ok(()))=>{},Ok(Err(_))=>return Err(failure("Device staging cleanup could not finish safely. No app records were removed.")),Err(_)=>return Err(Report::new(device_diagnostic(cleanup,None)).into())}
                let mut client = device_step(
                    DeviceStage::RemoteService,
                    InstallationProxyClient::connect_rsd(handle, handshake),
                )
                .await?;
                device_step(
                    DeviceStage::Lookup,
                    client.get_apps_with_attributes(
                        Some("User"),
                        None,
                        Some(vec![
                            "CFBundleIdentifier".into(),
                            "CFBundleVersion".into(),
                            "CFBundleShortVersionString".into(),
                        ]),
                    ),
                )
                .await
            }
        }
    }
    pub(super) async fn profiles(&mut self) -> Result<Vec<Vec<u8>>, Report> {
        let mut client = match self {
            Self::Lockdown(provider) => {
                device_step(DeviceStage::Profiles, MisagentClient::connect(provider)).await?
            }
            Self::Remote {
                handle, handshake, ..
            } => {
                device_step(
                    DeviceStage::Profiles,
                    MisagentClient::connect_rsd(handle, handshake),
                )
                .await?
            }
        };
        device_step(DeviceStage::Profiles, client.copy_all()).await
    }
    pub(super) async fn info(&mut self) -> Result<isideload::util::device::IdeviceInfo, Report> {
        match self {
            Self::Lockdown(provider) => isideload::util::device::IdeviceInfo::from_device(provider)
                .await
                .map_err(|_| {
                    failure(
                        "The device identity could not be read through its verified connection.",
                    )
                }),
            Self::Remote {
                handle, handshake, ..
            } => {
                let mut client = device_step(
                    DeviceStage::DeviceInfo,
                    LockdownClient::connect_rsd(handle, handshake),
                )
                .await?;
                let name = device_step(
                    DeviceStage::DeviceInfo,
                    client.get_value(Some("DeviceName"), None),
                )
                .await?
                .as_string()
                .ok_or_else(|| failure("The device returned invalid identity metadata."))?
                .to_owned();
                let udid = device_step(
                    DeviceStage::DeviceInfo,
                    client.get_value(Some("UniqueDeviceID"), None),
                )
                .await?
                .as_string()
                .ok_or_else(|| failure("The device returned invalid identity metadata."))?
                .to_owned();
                Ok(isideload::util::device::IdeviceInfo::new(name, udid))
            }
        }
    }
    pub(super) async fn install(&mut self, app_path: &Path) -> Result<(), Report> {
        let progress = |p| {
            publish(
                "progress",
                "Installing…",
                json!({"progress":p as f64/100.0}),
            )
        };
        match self {
            Self::Lockdown(provider) => {
                isideload::sideload::install::install_app(provider, app_path, progress).await
            }
            Self::Remote {
                handle, handshake, ..
            } => {
                isideload::sideload::install::install_app_rsd(handle, handshake, app_path, progress)
                    .await
            }
        }
    }
}
// AdapterHandle closes its worker when its last sender/stream is dropped. Keeping
// all handles operation-scoped lets cancellation drop the tunnel without spawning
// an unbounded cleanup task or leaving an unpolled async close future.
