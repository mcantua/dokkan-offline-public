//! Trusted-USB bootstrap of an authenticated, peer-pinned RP record.
//! Never logs device identifiers, pairing contents, keys, PINs or raw errors.
use idevice::{
    IdeviceError, IdeviceService,
    lockdown::LockdownClient,
    provider::UsbmuxdProvider,
    remote_pairing::{PairingStage, RemotePairingLockdownService, RpPairingFile, errors::RemotePairingError},
    usbmuxd::{Connection, UsbmuxdAddr},
};
use std::{
    cell::Cell,
    ffi::OsString,
    fs::{self, File, OpenOptions},
    io::{Read, Write},
    path::{Path, PathBuf},
    time::Duration,
};
#[cfg(unix)]
use std::os::unix::fs::{DirBuilderExt, MetadataExt, OpenOptionsExt, PermissionsExt};
use zeroize::Zeroizing;

#[derive(Clone, Copy, Debug)]
enum Failure {
    Arguments, Platform, Project, PrivateDirectory, ExistingExport, Usb,
    Selection, SystemPairing, TrustedSession, RemotePairing, NewRecordVerification, Record, File,
    PairTimeout, PairRejected, PairSrpProof, PairProtocol, PairTransport, PairIdentity,
}
impl Failure {
    fn message(self) -> &'static str {
        match self {
            Self::Arguments => "RP_BOOTSTRAP_STOPPED: use the reviewed wizard arguments and explicit consent.",
            Self::Platform => "RP_BOOTSTRAP_STOPPED: this helper requires the approved Mac USB connection.",
            Self::Project => "RP_BOOTSTRAP_STOPPED: the existing reviewed setup project could not be verified.",
            Self::PrivateDirectory => "RP_BOOTSTRAP_STOPPED: the private export folder must be owned by this user, private and free of symlinks.",
            Self::ExistingExport => "RP_BOOTSTRAP_STOPPED: a private export or interrupted export already exists; it was preserved.",
            Self::Usb => "RP_BOOTSTRAP_STOPPED: the system USB device service is unavailable.",
            Self::Selection => "RP_BOOTSTRAP_STOPPED: the selected physical USB iPhone could not be verified.",
            Self::SystemPairing => "RP_BOOTSTRAP_STOPPED: existing system USB trust is unavailable; use the normal Apple Trust UI first.",
            Self::TrustedSession => "RP_BOOTSTRAP_STOPPED: the authenticated USB identity or session could not be verified.",
            Self::RemotePairing => "RP_BOOTSTRAP_STOPPED: explicit remote pairing was cancelled or could not be authenticated; no new export was committed.",
            Self::PairTimeout => "RP_BOOTSTRAP_STOPPED: remote-pairing authentication timed out; no new export was committed.",
            Self::PairRejected => "RP_BOOTSTRAP_STOPPED: the device rejected trusted USB remote pairing; no new export was committed.",
            Self::PairSrpProof => "RP_BOOTSTRAP_STOPPED: remote-pairing SRP proof could not be authenticated; no new export was committed.",
            Self::PairProtocol => "RP_BOOTSTRAP_STOPPED: remote-pairing protocol data could not be decoded safely; no new export was committed.",
            Self::PairTransport => "RP_BOOTSTRAP_STOPPED: remote-pairing USB transport failed; no new export was committed.",
            Self::PairIdentity => "RP_BOOTSTRAP_STOPPED: remote-pairing peer identity could not be authenticated; no new export was committed.",
            Self::NewRecordVerification => "RP_BOOTSTRAP_STOPPED: newly paired identity could not be verified on a fresh USB connection; no new export was committed.",
            Self::Record => "RP_BOOTSTRAP_STOPPED: the authenticated version-2 device pin could not be verified.",
            Self::File => "RP_BOOTSTRAP_STOPPED: private export could not finish; keep any existing export for reviewed recovery.",
        }
    }
}
type Result<T> = std::result::Result<T, Failure>;
struct Arguments { root: PathBuf, udid: String }

fn valid_udid(value: &str) -> bool {
    let bytes = value.as_bytes();
    (bytes.len() == 40 && bytes.iter().all(u8::is_ascii_hexdigit))
        || (bytes.len() == 25 && bytes[8] == b'-'
            && bytes[..8].iter().chain(&bytes[9..]).all(u8::is_ascii_hexdigit))
}
fn parse_arguments(arguments: impl IntoIterator<Item = OsString>) -> Result<Arguments> {
    let mut args = arguments.into_iter();
    let (mut root, mut udid, mut consent) = (None, None, false);
    while let Some(argument) = args.next() {
        match argument.to_str() {
            Some("--repo-root") if root.is_none() => root = args.next().map(PathBuf::from),
            Some("--device-udid") if udid.is_none() => udid = args.next().and_then(|value| value.into_string().ok()),
            Some("--consent") if !consent => consent = true,
            _ => return Err(Failure::Arguments),
        }
    }
    let root = root.ok_or(Failure::Arguments)?;
    let udid = udid.filter(|value| valid_udid(value)).ok_or(Failure::Arguments)?;
    if !consent { return Err(Failure::Arguments); }
    Ok(Arguments { root, udid })
}

#[cfg(unix)]
fn private_directory(parent: &Path, name: &str) -> Result<PathBuf> {
    let path = parent.join(name);
    match fs::symlink_metadata(&path) {
        Ok(_) => {},
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
            fs::DirBuilder::new().mode(0o700).create(&path).map_err(|_| Failure::PrivateDirectory)?;
        }
        Err(_) => return Err(Failure::PrivateDirectory),
    }
    let info = fs::symlink_metadata(&path).map_err(|_| Failure::PrivateDirectory)?;
    // getuid is a read-only libc call; only this user's existing private tree is allowed.
    let uid = unsafe { libc::getuid() };
    if info.file_type().is_symlink() || !info.is_dir() || info.uid() != uid || info.mode() & 0o077 != 0 {
        return Err(Failure::PrivateDirectory);
    }
    Ok(path)
}
#[cfg(unix)]
fn output_directory(root: &Path) -> Result<PathBuf> {
    let root = root.canonicalize().map_err(|_| Failure::Project)?;
    let manifest = root.join("BootstrapKitManifest.json");
    let info = fs::symlink_metadata(&manifest).map_err(|_| Failure::Project)?;
    if !info.is_file() || info.file_type().is_symlink() || info.len() > 4 * 1024 * 1024 {
        return Err(Failure::Project);
    }
    let value: serde_json::Value = serde_json::from_slice(&fs::read(manifest).map_err(|_| Failure::Project)?)
        .map_err(|_| Failure::Project)?;
    if value["project"] != "claude-chatg" || value["test_fixture"] != false {
        return Err(Failure::Project);
    }
    let mut parent = root;
    for component in ["app-installer", "device"] {
        parent = parent.join(component);
        let info = fs::symlink_metadata(&parent).map_err(|_| Failure::Project)?;
        if !info.is_dir() || info.file_type().is_symlink() { return Err(Failure::Project); }
    }
    let private = private_directory(&parent, "private")?;
    let output = private_directory(&private, "secure-rp")?;
    for name in [".pairing.mobiledevicepairing.pending"] {
        match fs::symlink_metadata(output.join(name)) {
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {},
            _ => return Err(Failure::ExistingExport),
        }
    }
    Ok(output)
}
struct Pending(PathBuf);
impl Drop for Pending {
    fn drop(&mut self) { let _ = fs::remove_file(&self.0); }
}
#[cfg(unix)]
fn write_atomic(directory: &Path, bytes: &[u8]) -> Result<()> {
    let pending = directory.join(".pairing.mobiledevicepairing.pending");
    let destination = directory.join("pairing.mobiledevicepairing");
    let mut output = OpenOptions::new().write(true).create_new(true).mode(0o600)
        .open(&pending).map_err(|_| Failure::ExistingExport)?;
    let _cleanup = Pending(pending.clone());
    output.write_all(bytes).and_then(|_| output.sync_all()).map_err(|_| Failure::File)?;
    drop(output);
    // Atomic no-replace publication. hard_link fails if a file OR symlink already
    // occupies the final path; the complete 0600 inode is visible all at once.
    fs::hard_link(&pending, &destination).map_err(|_| Failure::ExistingExport)?;
    fs::remove_file(&pending).map_err(|_| Failure::File)?;
    // File contents are synchronized before publication; directory persistence
    // is best effort across supported macOS filesystems.
    let _ = File::open(directory).and_then(|file| file.sync_all());
    Ok(())
}

// This is the official trusted-USB control-channel protocol value, not a
// guessed user PIN. The only caller is below the verified USB Lockdown session.
// There is no generic network-pairing entry point or displayed-code fallback.
async fn trusted_usb_pairing_code() -> String { "000000".to_owned() }

const RECORD_LIMIT: u64 = 64 * 1024;
#[cfg(unix)]
fn existing_record(directory: &Path) -> Result<Option<RpPairingFile>> {
    let path = directory.join("pairing.mobiledevicepairing");
    let file = match OpenOptions::new().read(true)
        .custom_flags(libc::O_NOFOLLOW | libc::O_NONBLOCK | libc::O_CLOEXEC).open(path) {
        Ok(file) => file,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(_) => return Err(Failure::ExistingExport),
    };
    let info = file.metadata().map_err(|_| Failure::ExistingExport)?;
    if !info.is_file() || info.uid() != unsafe { libc::getuid() }
        || info.mode() & 0o777 != 0o600 || info.nlink() != 1 || info.len() > RECORD_LIMIT {
        return Err(Failure::ExistingExport);
    }
    let mut bytes = Zeroizing::new(Vec::new());
    file.take(RECORD_LIMIT + 1).read_to_end(&mut bytes).map_err(|_| Failure::ExistingExport)?;
    if bytes.len() as u64 > RECORD_LIMIT { return Err(Failure::ExistingExport); }
    let record = RpPairingFile::from_bytes(&bytes).map_err(|_| Failure::ExistingExport)?;
    if !record.has_peer_pin() || record.alt_irk().is_none_or(|key| key.len() != 16) {
        return Err(Failure::ExistingExport);
    }
    Ok(Some(record))
}
// Opening this service constructs a NEW authenticated USB Lockdown/service
// connection. Never reuse the SRP setup stream or fall back to pair() here.
async fn verify_new_record(
    provider: &UsbmuxdProvider, sending_host: &str, record: &mut RpPairingFile,
) -> Result<()> {
    let service = step(RemotePairingLockdownService::connect(provider), Failure::NewRecordVerification).await?;
    let mut client = service.into_client(sending_host).map_err(|_| Failure::NewRecordVerification)?;
    step(client.attempt_pair_verify(), Failure::NewRecordVerification).await?;
    step(client.validate_pairing(record), Failure::NewRecordVerification).await
}
#[cfg(unix)]
async fn publish_new_record<F, Fut>(directory: &Path, bytes: &[u8], verify: F) -> Result<()>
where F: FnOnce() -> Fut, Fut: std::future::Future<Output = Result<()>> {
    emit_status("RP_BOOTSTRAP_NEW_RECORD_VERIFY_PENDING");
    verify().await?;
    emit_status("RP_BOOTSTRAP_NEW_RECORD_VERIFIED");
    // An unsuccessful reconnect, handshake or pinned verification can never
    // publish even a structurally valid credential. Existing output stays intact.
    write_atomic(directory, bytes)
}
fn emit_status(line: &'static str) {
    println!("{line}");
    // The Python wrapper can forward only its exact public stage allowlist.
    // Flush even when stdout is a pipe; never expose a library error or payload.
    let _ = std::io::stdout().flush();
}
fn pairing_stage_line(stage: PairingStage) -> &'static str {
    match stage {
        PairingStage::Consent => "RP_BOOTSTRAP_PAIR_CONSENT_PENDING",
        PairingStage::SrpProof => "RP_BOOTSTRAP_PAIR_SRP_PROOF_PENDING",
        PairingStage::PeerRecord => "RP_BOOTSTRAP_PAIR_PEER_RECORD_PENDING",
        PairingStage::PeerIdentity => "RP_BOOTSTRAP_PAIR_PEER_IDENTITY_PENDING",
    }
}
fn classify_pair_error(error: &IdeviceError, stage: PairingStage) -> Failure {
    // Match only public typed variants. Never inspect, format, or forward any
    // error's String payload, device message, identity, bytes, or nested source.
    match error {
        IdeviceError::Timeout => Failure::PairTimeout,
        IdeviceError::Socket(error) if error.kind() == std::io::ErrorKind::TimedOut => Failure::PairTimeout,
        IdeviceError::Socket(_) | IdeviceError::NoEstablishedConnection => Failure::PairTransport,
        IdeviceError::RemotePairing(RemotePairingError::PairingRejected(_)) => Failure::PairRejected,
        IdeviceError::RemotePairing(RemotePairingError::SrpAuthFailed) => Failure::PairSrpProof,
        IdeviceError::RemotePairing(RemotePairingError::ChachaEncryption(_) | RemotePairingError::PairVerifyFailed) => Failure::PairIdentity,
        IdeviceError::RemotePairing(RemotePairingError::UnknownTlv(_)
            | RemotePairingError::MalformedTlv | RemotePairingError::Base64DecodeError(_))
            | IdeviceError::Json(_) | IdeviceError::Plist(_) | IdeviceError::Utf8(_)
            | IdeviceError::Utf8Error => Failure::PairProtocol,
        IdeviceError::UnexpectedResponse(_) if stage == PairingStage::PeerIdentity => Failure::PairIdentity,
        IdeviceError::UnexpectedResponse(_) => Failure::PairProtocol,
        _ => Failure::RemotePairing,
    }
}
fn finish_pair(
    outcome: std::result::Result<std::result::Result<(), IdeviceError>, tokio::time::error::Elapsed>,
    stage: PairingStage,
) -> Result<()> {
    match outcome {
        Err(_) => Err(Failure::PairTimeout),
        Ok(Err(error)) => Err(classify_pair_error(&error, stage)),
        Ok(Ok(())) => Ok(()),
    }
}
async fn step<T>(future: impl std::future::Future<Output = std::result::Result<T, IdeviceError>>, failure: Failure) -> Result<T> {
    tokio::time::timeout(Duration::from_secs(20), future).await.map_err(|_| failure)?.map_err(|_| failure)
}
#[cfg(unix)]
async fn run(arguments: Arguments) -> Result<()> {
    if !cfg!(target_os = "macos") { return Err(Failure::Platform); }
    emit_status("RP_BOOTSTRAP_STARTED");
    let directory = output_directory(&arguments.root)?;
    // Refuse malformed/unsafe existing data before USB activity or generating
    // any new identity. A valid record can only be reused after peer verification.
    let existing = existing_record(&directory)?;
    // Ignore USBMUXD_SOCKET_ADDRESS and all remote service overrides. Only the
    // local system Unix socket is contacted; network/simulator rows are excluded.
    let address = UsbmuxdAddr::default();
    let mut mux = step(address.connect(1), Failure::Usb).await?;
    let mut devices = step(mux.get_devices(), Failure::Usb).await?.into_iter()
        .filter(|device| device.connection_type == Connection::Usb && device.udid.eq_ignore_ascii_case(&arguments.udid));
    let selected = devices.next().ok_or(Failure::Selection)?;
    if devices.next().is_some() { return Err(Failure::Selection); }
    let system_record = step(mux.get_pair_record(&selected.udid), Failure::SystemPairing).await?;
    let provider = UsbmuxdProvider { addr: address, tag: 2, udid: selected.udid,
                                  device_id: selected.device_id, label: "AppInstaller Secure RP Bootstrap".into() };
    emit_status("RP_BOOTSTRAP_USB_SELECTED");
    let mut lockdown = step(LockdownClient::connect(&provider), Failure::TrustedSession).await?;
    step(lockdown.start_session(&system_record), Failure::TrustedSession).await?;
    let live_id = step(lockdown.get_value(Some("UniqueDeviceID"), None), Failure::Selection).await?;
    let model = step(lockdown.get_value(Some("ProductType"), None), Failure::Selection).await?;
    let model = model.as_string().ok_or(Failure::Selection)?;
    if !live_id.as_string().is_some_and(|id| id.eq_ignore_ascii_case(&arguments.udid))
        || !model.strip_prefix("iPhone").is_some_and(|tail| tail.split_once(',').is_some_and(|(major, minor)|
            !major.is_empty() && !minor.is_empty() && major.bytes().chain(minor.bytes()).all(|c| c.is_ascii_digit()))) {
        return Err(Failure::Selection);
    }
    step(lockdown.stop_session(), Failure::TrustedSession).await?;
    drop(lockdown);
    emit_status("RP_BOOTSTRAP_USB_TRUST_VERIFIED");
    let service = step(RemotePairingLockdownService::connect(&provider), Failure::TrustedSession).await?;
    let sending_host = if existing.is_some() { "AppInstaller Setup".to_owned() }
        else { format!("AppInstaller Setup {}", uuid::Uuid::new_v4()) };
    let mut client = service.into_client(&sending_host).map_err(|_| Failure::RemotePairing)?;
    step(client.attempt_pair_verify(), Failure::RemotePairing).await?;
    if let Some(mut record) = existing {
        // Failure never falls back to pair(): preserve the original identity and
        // require reviewed recovery rather than silently rotating its key.
        step(client.validate_pairing(&mut record), Failure::ExistingExport).await?;
        emit_status("RP_BOOTSTRAP_EXISTING_VERIFIED");
        emit_status("RP_BOOTSTRAP_READY");
        return Ok(());
    }
    let mut record = RpPairingFile::generate(&sending_host);
    emit_status("RP_BOOTSTRAP_AUTHENTICATED_PAIRING_PENDING");
    // Explicit, consented initial setup over the already trusted USB channel.
    // Never call connect(), which must not silently fall back to re-pairing.
    let stage = Cell::new(PairingStage::Consent);
    let outcome = tokio::time::timeout(Duration::from_secs(180),
        client.pair_with_progress(&mut record, trusted_usb_pairing_code, |phase| {
            stage.set(phase);
            emit_status(pairing_stage_line(phase));
        })).await;
    finish_pair(outcome, stage.get())?;
    if !record.has_peer_pin() || record.alt_irk().is_none_or(|key| key.len() != 16) { return Err(Failure::Record); }
    let bytes = Zeroizing::new(record.to_pinned_bytes().map_err(|_| Failure::Record)?);
    if bytes.len() as u64 > RECORD_LIMIT { return Err(Failure::Record); }
    let mut checked = RpPairingFile::from_bytes(&bytes).map_err(|_| Failure::Record)?;
    if !checked.has_peer_pin() { return Err(Failure::Record); }
    // Match the official tool's second connection, with strict peer pinning.
    // The first connection is deliberately dropped before the new verifier.
    drop(client);
    publish_new_record(&directory, &bytes, || verify_new_record(&provider, &sending_host, &mut checked)).await?;
    emit_status("RP_BOOTSTRAP_READY");
    Ok(())
}
fn main() {
    std::panic::set_hook(Box::new(|_| eprintln!("RP_BOOTSTRAP_STOPPED: secure operation interrupted; preserve existing private exports.")));
    let raw: Vec<_> = std::env::args_os().skip(1).collect();
    if raw.as_slice() == [OsString::from("--version")] {
        println!("app-installer-rp-bootstrap {}", env!("CARGO_PKG_VERSION"));
        return;
    }
    if raw.is_empty() || raw.as_slice() == [OsString::from("--help")] {
        println!("Trusted-USB peer-pinned remote pairing helper. No action without --repo-root PROJECT --device-udid LOCAL_SELECTION --consent. No Apple credentials; no overwrite; private export only.");
        return;
    }
    let result = parse_arguments(raw).and_then(|arguments| {
        #[cfg(unix)] {
            tokio::runtime::Builder::new_multi_thread().worker_threads(2).enable_all().build()
                .map_err(|_| Failure::Platform)?.block_on(run(arguments))
        }
        #[cfg(not(unix))] { let _ = arguments; Err(Failure::Platform) }
    });
    if let Err(error) = result { eprintln!("{}", error.message()); std::process::exit(1); }
}

#[cfg(all(test, unix))]
mod tests {
    use super::*;
    #[test]
    fn requires_explicit_consent_valid_physical_selection_and_exact_arguments() {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        assert_eq!(runtime.block_on(trusted_usb_pairing_code()), "000000");
        let valid = ["--repo-root", "/TEST-ONLY/project", "--device-udid", "00000000-0000000000000000", "--consent"];
        assert!(parse_arguments(valid.map(OsString::from)).is_ok());
        for invalid in [vec!["--repo-root", "/TEST-ONLY/project"],
                        vec!["--repo-root", "/TEST-ONLY/project", "--device-udid", "simulator-alias", "--consent"],
                        vec!["--repo-root", "/TEST-ONLY/project", "--device-udid", "00000000-0000000000000000"],
                        vec!["--repo-root", "/TEST-ONLY/project", "--device-udid", "00000000-0000000000000000", "--consent", "--force"]] {
            assert!(parse_arguments(invalid.into_iter().map(OsString::from)).is_err());
        }
    }
    #[test]
    fn private_atomic_export_never_overwrites_existing_file_or_symlink() {
        use std::os::unix::fs::symlink;
        let base=PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("target")
            .join(format!("TEST-ONLY-export-{}",std::process::id()));
        fs::create_dir_all(&base).unwrap();
        let directory=private_directory(&base,"private").unwrap();
        assert_eq!(fs::metadata(&directory).unwrap().mode() & 0o777,0o700);
        assert!(existing_record(&directory).unwrap().is_none());
        write_atomic(&directory,b"TEST-ONLY no signing or pairing secrets").unwrap();
        let final_path=directory.join("pairing.mobiledevicepairing");
        assert!(existing_record(&directory).is_err());
        assert_eq!(fs::metadata(&final_path).unwrap().mode() & 0o777,0o600);
        assert_eq!(fs::metadata(&final_path).unwrap().nlink(),1);
        assert!(write_atomic(&directory,b"TEST-ONLY replacement denied").is_err());
        assert_eq!(fs::read(&final_path).unwrap(),b"TEST-ONLY no signing or pairing secrets");
        fs::remove_file(&final_path).unwrap();
        // Only synthetic ephemeral keys: no real device, host, or user data.
        let mut fixture=RpPairingFile::generate("TEST-ONLY-host");
        let peer=RpPairingFile::generate("TEST-ONLY-peer");
        fixture.peer_identifier=Some("TEST-ONLY-peer".into());
        fixture.peer_public_key=Some(peer.e_public_key);
        fixture.alt_irk=Some(vec![7;16]);
        let encoded=Zeroizing::new(fixture.to_pinned_bytes().unwrap());
        write_atomic(&directory,&encoded).unwrap();
        let reused=existing_record(&directory).unwrap().unwrap();
        assert_eq!(reused.identifier,fixture.identifier);
        assert_eq!(reused.e_public_key,fixture.e_public_key);
        assert_eq!(reused.peer_public_key,fixture.peer_public_key);
        assert!(write_atomic(&directory,b"TEST-ONLY denied rotation").is_err());
        assert_eq!(fs::read(&final_path).unwrap().as_slice(),encoded.as_slice());
        fs::set_permissions(&final_path,fs::Permissions::from_mode(0o644)).unwrap();
        assert!(existing_record(&directory).is_err());
        fs::remove_file(&final_path).unwrap();
        let sentinel=base.join("TEST-ONLY-sentinel");fs::write(&sentinel,b"untouched").unwrap();
        symlink(&sentinel,&final_path).unwrap();
        assert!(write_atomic(&directory,b"TEST-ONLY symlink denied").is_err());
        assert!(existing_record(&directory).is_err());
        assert_eq!(fs::read(&sentinel).unwrap(),b"untouched");
        fs::remove_dir_all(&base).unwrap();
    }
    #[test]
    fn new_record_verification_gates_private_publication_without_retry() {
        use std::cell::Cell;
        let base=PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("target")
            .join(format!("TEST-ONLY-new-record-{}",std::process::id()));
        fs::create_dir_all(&base).unwrap();
        let directory=private_directory(&base,"private").unwrap();
        let destination=directory.join("pairing.mobiledevicepairing");
        let runtime=tokio::runtime::Runtime::new().unwrap();
        let calls=Cell::new(0);
        // Injected result models a fresh-connection/handshake/authentication
        // rejection. It uses no device socket, pairing identity or real key.
        let denied=runtime.block_on(publish_new_record(&directory,b"TEST-ONLY synthetic credential",||async {
            calls.set(calls.get()+1);
            assert!(!destination.exists());
            Err(Failure::NewRecordVerification)
        }));
        assert!(matches!(denied,Err(Failure::NewRecordVerification)));
        assert_eq!(calls.get(),1);
        assert!(!destination.exists());
        assert!(!directory.join(".pairing.mobiledevicepairing.pending").exists());
        runtime.block_on(publish_new_record(&directory,b"TEST-ONLY synthetic credential",||async {
            calls.set(calls.get()+1);
            assert!(!destination.exists());
            Ok(())
        })).unwrap();
        assert_eq!(calls.get(),2);
        assert_eq!(fs::metadata(&destination).unwrap().mode()&0o777,0o600);
        assert_eq!(fs::read(&destination).unwrap(),b"TEST-ONLY synthetic credential");
        // Even an accepted verifier cannot replace previously committed bytes.
        assert!(runtime.block_on(publish_new_record(&directory,b"TEST-ONLY replacement",||async {Ok(())})).is_err());
        assert_eq!(fs::read(&destination).unwrap(),b"TEST-ONLY synthetic credential");
        fs::remove_dir_all(base).unwrap();
    }

    #[test]
    fn pairing_progress_and_failure_routing_are_fixed_and_private() {
        let phases=[PairingStage::Consent,PairingStage::SrpProof,PairingStage::PeerRecord,PairingStage::PeerIdentity];
        assert_eq!(phases.map(pairing_stage_line),[
            "RP_BOOTSTRAP_PAIR_CONSENT_PENDING","RP_BOOTSTRAP_PAIR_SRP_PROOF_PENDING",
            "RP_BOOTSTRAP_PAIR_PEER_RECORD_PENDING","RP_BOOTSTRAP_PAIR_PEER_IDENTITY_PENDING"]);
        let secret="TEST-ONLY payload must never appear in diagnostics";
        let rejected=IdeviceError::RemotePairing(RemotePairingError::PairingRejected(secret.into()));
        assert!(matches!(classify_pair_error(&rejected,PairingStage::Consent),Failure::PairRejected));
        let proof=IdeviceError::RemotePairing(RemotePairingError::SrpAuthFailed);
        assert!(matches!(classify_pair_error(&proof,PairingStage::SrpProof),Failure::PairSrpProof));
        let malformed=IdeviceError::RemotePairing(RemotePairingError::MalformedTlv);
        assert!(matches!(classify_pair_error(&malformed,PairingStage::PeerRecord),Failure::PairProtocol));
        let private=IdeviceError::UnexpectedResponse(secret.into());
        for phase in phases {
            let failure=classify_pair_error(&private,phase);
            assert!(!failure.message().contains(secret));
            assert!(matches!(failure,Failure::PairIdentity) == (phase==PairingStage::PeerIdentity));
        }
        let transport=IdeviceError::Socket(std::io::Error::new(std::io::ErrorKind::BrokenPipe,secret));
        assert!(matches!(classify_pair_error(&transport,PairingStage::PeerRecord),Failure::PairTransport));
        let runtime=tokio::runtime::Runtime::new().unwrap();
        let expired=runtime.block_on(async {
            tokio::time::timeout(Duration::ZERO,std::future::pending::<std::result::Result<(),IdeviceError>>()).await
        });
        assert!(matches!(finish_pair(expired,PairingStage::Consent),Err(Failure::PairTimeout)));
        assert!(matches!(finish_pair(Ok(Err(rejected)),PairingStage::Consent),Err(Failure::PairRejected)));
        assert!(finish_pair(Ok(Ok(())),PairingStage::PeerIdentity).is_ok());
    }

}
