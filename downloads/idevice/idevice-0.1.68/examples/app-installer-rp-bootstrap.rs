// SPDX-License-Identifier: AGPL-3.0-only
// Project-written public-source exporter; idevice retains its upstream MIT license.
//! Explicit trusted-USB setup only. Never prints identities, keys, PINs or raw errors.
use idevice::{
    IdeviceError, IdeviceService, lockdown::LockdownClient, provider::UsbmuxdProvider,
    remote_pairing::{RemotePairingLockdownService, RpPairingFile},
    usbmuxd::{Connection, UsbmuxdAddr},
};
use std::{
    ffi::OsString, fs::{self, File, OpenOptions}, future::Future, io::Write,
    path::{Path, PathBuf}, sync::{Arc, Condvar, Mutex}, time::Duration,
};
#[cfg(unix)]
use std::os::unix::fs::{DirBuilderExt, MetadataExt, OpenOptionsExt, PermissionsExt};

const RECORD_LIMIT: usize = 64 * 1024;
const GLOBAL_SECONDS: u64 = 480;
const OUTPUT: &str = "pairing.mobiledevicepairing";

#[derive(Debug, Clone, Copy)]
enum Failure {
    Arguments, Platform, Project, Private, Existing, Usb, Selection, Trust,
    Session, Service, Handshake, PairTimeout, PairAuthentication, Record,
    FreshVerification, Output, ExportOutcomeUnknown,
}
impl Failure {
    fn code(self) -> &'static str {
        match self {
            Self::Arguments => "ARGUMENTS", Self::Platform => "MAC_REQUIRED",
            Self::Project => "ACTIVE_PUBLIC_PROJECT_REQUIRED", Self::Private => "PRIVATE_DIRECTORY_UNSAFE",
            Self::Existing => "EXISTING_EXPORT_OR_LOCK_PRESERVED", Self::Usb => "USB_SERVICE",
            Self::Selection => "PHYSICAL_USB_SELECTION", Self::Trust => "EXISTING_USB_TRUST",
            Self::Session => "AUTHENTICATED_USB_SESSION", Self::Service => "REMOTE_PAIRING_SERVICE",
            Self::Handshake => "REMOTE_PAIRING_HANDSHAKE", Self::PairTimeout => "PAIR_TIMEOUT_OUTCOME_UNKNOWN",
            Self::PairAuthentication => "PAIR_AUTHENTICATION_NO_EXPORT", Self::Record => "STRICT_V2_RECORD",
            Self::FreshVerification => "FRESH_PINNED_VERIFICATION_NO_EXPORT",
            Self::Output => "PUBLIC_STATUS_OUTPUT_UNAVAILABLE",
            Self::ExportOutcomeUnknown => "EXPORT_OUTCOME_UNKNOWN_PRESERVE_PRIVATE_FILE",
        }
    }
}
type Result<T> = std::result::Result<T, Failure>;
struct Arguments { root: PathBuf, udid: String, manual_local_pin: bool }

fn status(code: &'static str) -> Result<()> {
    let mut output = std::io::stdout().lock();
    writeln!(output, "RP_EXPORT_STAGE: {code}").and_then(|_| output.flush()).map_err(|_| Failure::Output)
}
fn valid_udid(value: &str) -> bool {
    let bytes = value.as_bytes();
    (bytes.len() == 40 && bytes.iter().all(u8::is_ascii_hexdigit))
        || (bytes.len() == 25 && bytes[8] == b'-'
            && bytes[..8].iter().chain(&bytes[9..]).all(u8::is_ascii_hexdigit))
}
fn arguments(raw: Vec<OsString>) -> Result<Option<Arguments>> {
    let mut raw = raw.into_iter();
    let (mut root, mut udid, mut execute, mut manual_local_pin) = (None, None, false, false);
    while let Some(arg) = raw.next() {
        match arg.to_str() {
            Some("--execute") if !execute => execute = true,
            Some("--repo-root") if root.is_none() => root = raw.next().map(PathBuf::from),
            Some("--device-udid") if udid.is_none() => udid = raw.next().and_then(|v| v.into_string().ok()),
            Some("--manual-local-pin") if !manual_local_pin => manual_local_pin = true,
            _ => return Err(Failure::Arguments),
        }
    }
    // Plan mode does not canonicalize paths, inspect a phone, or start a watchdog.
    if !execute { return Ok(None); }
    let root = root.ok_or(Failure::Arguments)?;
    let udid = udid.filter(|v| valid_udid(v)).ok_or(Failure::Arguments)?;
    Ok(Some(Arguments { root, udid, manual_local_pin }))
}

#[cfg(unix)]
fn regular_small(path: &Path, limit: u64) -> Result<Vec<u8>> {
    use std::io::Read;
    let file = OpenOptions::new().read(true)
        .custom_flags(libc::O_NOFOLLOW | libc::O_NONBLOCK | libc::O_CLOEXEC)
        .open(path).map_err(|_| Failure::Project)?;
    let meta = file.metadata().map_err(|_| Failure::Project)?;
    if !meta.is_file() || meta.len() > limit { return Err(Failure::Project); }
    let mut bytes = Vec::new();
    file.take(limit + 1).read_to_end(&mut bytes).map_err(|_| Failure::Project)?;
    if bytes.len() as u64 > limit { return Err(Failure::Project); }
    Ok(bytes)
}
#[cfg(unix)]
fn private_directory(parent: &Path, name: &str) -> Result<PathBuf> {
    let path = parent.join(name);
    match fs::symlink_metadata(&path) {
        Ok(_) => {},
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
            fs::DirBuilder::new().mode(0o700).create(&path).map_err(|_| Failure::Private)?;
        }
        Err(_) => return Err(Failure::Private),
    }
    let meta = fs::symlink_metadata(&path).map_err(|_| Failure::Private)?;
    if !meta.is_dir() || meta.file_type().is_symlink()
        || meta.uid() != unsafe { libc::getuid() } || meta.mode() & 0o777 != 0o700 {
        return Err(Failure::Private);
    }
    Ok(path)
}
#[cfg(unix)]
fn active_output(root: &Path) -> Result<PathBuf> {
    let root = root.canonicalize().map_err(|_| Failure::Project)?;
    if root.file_name().and_then(|v| v.to_str()) != Some("dokkan-offline-public") {
        return Err(Failure::Project);
    }
    let mut device = root.clone();
    for component in ["app-installer", "device"] {
        device.push(component);
        let meta = fs::symlink_metadata(&device).map_err(|_| Failure::Project)?;
        if !meta.is_dir() || meta.file_type().is_symlink() { return Err(Failure::Project); }
    }
    let marker = regular_small(&device.join("PUBLIC-CONTINUATION.md"), 128 * 1024)?;
    if !String::from_utf8_lossy(&marker).starts_with("# App Installer public-source continuation") {
        return Err(Failure::Project);
    }
    let ignored = regular_small(&device.join(".gitignore"), 4096)?;
    if !String::from_utf8_lossy(&ignored).lines().any(|line| line.trim() == "/private/") {
        return Err(Failure::Project);
    }
    let private = private_directory(&device, "private")?;
    private_directory(&private, "secure-rp")
}
fn require_absent(path: &Path) -> Result<()> {
    match fs::symlink_metadata(path) {
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        _ => Err(Failure::Existing),
    }
}
#[cfg(unix)]
struct ExportLock { path: PathBuf, inode: u64 }
#[cfg(unix)]
impl ExportLock {
    fn acquire(directory: &Path) -> Result<Self> {
        require_absent(&directory.join(OUTPUT))?;
        let path = directory.join(".rp-export.lock");
        let file = OpenOptions::new().write(true).create_new(true).mode(0o600)
            .custom_flags(libc::O_NOFOLLOW | libc::O_CLOEXEC).open(&path).map_err(|_| Failure::Existing)?;
        let lock = Self { path, inode: file.metadata().map_err(|_| Failure::Private)?.ino() };
        require_absent(&directory.join(OUTPUT))?;
        Ok(lock)
    }
}
#[cfg(unix)]
impl Drop for ExportLock {
    fn drop(&mut self) {
        if fs::symlink_metadata(&self.path).is_ok_and(|meta| meta.is_file() && meta.ino() == self.inode) {
            let _ = fs::remove_file(&self.path);
        }
    }
}
#[cfg(unix)]
fn durable_new_export(directory: &Path, bytes: &[u8]) -> Result<()> {
    let mut file = OpenOptions::new().write(true).create_new(true).mode(0o600)
        .custom_flags(libc::O_NOFOLLOW | libc::O_CLOEXEC)
        .open(directory.join(OUTPUT)).map_err(|error| {
            if error.kind() == std::io::ErrorKind::AlreadyExists { Failure::Existing }
            else { Failure::ExportOutcomeUnknown }
        })?;
    // Never unlink on failure: preserve an incomplete or uncertain private file.
    file.write_all(bytes).and_then(|_| file.sync_all()).map_err(|_| Failure::ExportOutcomeUnknown)?;
    File::open(directory).and_then(|dir| dir.sync_all()).map_err(|_| Failure::ExportOutcomeUnknown)
}

// The watchdog bounds synchronous filesystem/crypto work as well as async waits.
// An interrupted pairing/write is explicitly unknown, never reported successful.
struct Watchdog { done: Arc<(Mutex<bool>, Condvar)>, thread: Option<std::thread::JoinHandle<()>> }
impl Watchdog {
    fn start() -> Self {
        let done = Arc::new((Mutex::new(false), Condvar::new()));
        let other = Arc::clone(&done);
        let thread = std::thread::spawn(move || {
            let (lock, condition) = &*other;
            let guard = lock.lock().unwrap_or_else(|e| e.into_inner());
            let (finished, _) = condition.wait_timeout_while(guard, Duration::from_secs(GLOBAL_SECONDS), |v| !*v)
                .unwrap_or_else(|e| e.into_inner());
            if !*finished {
                let _ = writeln!(std::io::stderr(), "RP_EXPORT_ERROR: GLOBAL_TIMEOUT_OUTCOME_UNKNOWN_PRESERVE_PRIVATE_FILES");
                std::process::exit(1);
            }
        });
        Self { done, thread: Some(thread) }
    }
}
impl Drop for Watchdog {
    fn drop(&mut self) {
        let (lock, condition) = &*self.done;
        *lock.lock().unwrap_or_else(|e| e.into_inner()) = true;
        condition.notify_all();
        if let Some(thread) = self.thread.take() { let _ = thread.join(); }
    }
}
async fn step<T>(future: impl Future<Output = std::result::Result<T, IdeviceError>>, failure: Failure) -> Result<T> {
    tokio::time::timeout(Duration::from_secs(20), future).await.map_err(|_| failure)?.map_err(|_| failure)
}
fn local_pin(manual: bool) -> String {
    if !manual {
        // Official already-trusted USB control-channel value, never a guessed
        // network/user PIN. The normal awaitingUserConsent path selects it in idevice.
        return "000000".into();
    }
    // Only explicitly requested local manual UI. No PIN/account field enters chat.
    let script = r#"set answer to display dialog "Enter the six-digit remote-pairing code shown on this iPhone. Do not enter an Apple-account password." default answer "" with hidden answer buttons {"Cancel", "Pair"} default button "Pair" cancel button "Cancel" giving up after 60
if gave up of answer then return ""
return text returned of answer"#;
    let result = std::process::Command::new("/usr/bin/osascript").args(["-e", script])
        .stdin(std::process::Stdio::null()).stderr(std::process::Stdio::null()).output();
    let Ok(output) = result else { return String::new(); };
    if !output.status.success() || output.stdout.len() > 16 { return String::new(); }
    let Ok(value) = std::str::from_utf8(&output.stdout) else { return String::new(); };
    let value = value.trim();
    if value.len() == 6 && value.bytes().all(|v| v.is_ascii_digit()) { value.to_owned() } else { String::new() }
}
fn strict_record(record: &RpPairingFile) -> Result<Vec<u8>> {
    if record.peer_identifier().is_none() || record.peer_public_key_bytes().is_none()
        || record.alt_irk().is_none_or(|key| key.len() != 16) {
        return Err(Failure::Record);
    }
    let bytes = record.to_bytes();
    if bytes.len() > RECORD_LIMIT { return Err(Failure::Record); }
    RpPairingFile::from_bytes(&bytes).map_err(|_| Failure::Record)?;
    Ok(bytes)
}
#[cfg(unix)]
async fn execute(args: Arguments) -> Result<()> {
    status("STARTED")?;
    let directory = active_output(&args.root)?;
    let _export_lock = ExportLock::acquire(&directory)?;
    let address = UsbmuxdAddr::default();
    let mut mux = step(address.connect(1), Failure::Usb).await?;
    let mut selected = step(mux.get_devices(), Failure::Usb).await?.into_iter()
        .filter(|dev| dev.connection_type == Connection::Usb && dev.udid.eq_ignore_ascii_case(&args.udid));
    let device = selected.next().ok_or(Failure::Selection)?;
    if selected.next().is_some() { return Err(Failure::Selection); }
    let trust = step(mux.get_pair_record(&device.udid), Failure::Trust).await?;
    let provider = UsbmuxdProvider { addr: address, tag: 2, udid: device.udid,
        device_id: device.device_id, label: "AppInstaller RP Export".into() };
    status("USB_SELECTED")?;
    let mut lockdown = step(LockdownClient::connect(&provider), Failure::Session).await?;
    step(lockdown.start_session(&trust), Failure::Session).await?;
    let live = step(lockdown.get_value(Some("UniqueDeviceID"), None), Failure::Selection).await?;
    let model = step(lockdown.get_value(Some("ProductType"), None), Failure::Selection).await?;
    if !live.as_string().is_some_and(|v| v.eq_ignore_ascii_case(&args.udid))
        || !model.as_string().and_then(|v| v.strip_prefix("iPhone")).is_some_and(|v| {
            v.split_once(',').is_some_and(|(a,b)| !a.is_empty() && !b.is_empty()
                && a.bytes().chain(b.bytes()).all(|v| v.is_ascii_digit()))
        }) { return Err(Failure::Selection); }
    step(lockdown.stop_session(), Failure::Session).await?;
    drop(lockdown);
    status("USB_TRUST_VERIFIED")?;
    let service = step(RemotePairingLockdownService::connect(&provider), Failure::Service).await?;
    let host = format!("AppInstaller Public {}", uuid::Uuid::new_v4());
    let mut client = service.into_client(&host).map_err(|_| Failure::Service)?;
    step(client.attempt_pair_verify(), Failure::Handshake).await?;
    // Explicit initial setup after verified USB trust, never an automatic
    // recovery after a failed pinned verification or an imported v1 identity.
    step(client.send_pair_verified_failed(), Failure::Handshake).await?;
    let mut record = RpPairingFile::generate(&host);
    status("AUTHENTICATED_SETUP_PENDING")?;
    tokio::time::timeout(Duration::from_secs(180), client.pair(&mut record, || async { local_pin(args.manual_local_pin) }))
        .await.map_err(|_| Failure::PairTimeout)?.map_err(|_| Failure::PairAuthentication)?;
    let initial_bytes = strict_record(&record)?;
    drop(client);
    status("M6_AUTHENTICATED_FRESH_VERIFY_PENDING")?;
    let service = step(RemotePairingLockdownService::connect(&provider), Failure::FreshVerification).await?;
    let mut client = service.into_client(&host).map_err(|_| Failure::FreshVerification)?;
    step(client.attempt_pair_verify(), Failure::FreshVerification).await?;
    step(client.validate_pairing(&mut record), Failure::FreshVerification).await?;
    if strict_record(&record)? != initial_bytes { return Err(Failure::FreshVerification); }
    drop(client);
    status("FRESH_PINNED_VERIFICATION_SUCCEEDED")?;
    durable_new_export(&directory, &initial_bytes)?;
    status("EXPORTED_PRIVATE_V2")?;
    Ok(())
}
fn main() {
    let raw: Vec<_> = std::env::args_os().skip(1).collect();
    if raw == [OsString::from("--version")] {
        println!("app-installer-rp-bootstrap {}", env!("CARGO_PKG_VERSION")); return;
    }
    if raw.is_empty() || raw == [OsString::from("--help")] {
        println!("PLAN ONLY. Explicit --execute --repo-root ACTIVE_dokkan-offline-public --device-udid LOCAL_SELECTION creates one private version-2 USB export. Optional --manual-local-pin permits local displayed-code UI only. No phone install, Apple credentials, trust reset or existing-file replacement."); return;
    }
    std::panic::set_hook(Box::new(|_| eprintln!("RP_EXPORT_ERROR: INTERRUPTED_OUTCOME_UNKNOWN_PRESERVE_PRIVATE_FILES")));
    let result = arguments(raw).and_then(|args| {
        let Some(args) = args else { println!("PLAN ONLY. No local actions performed."); return Ok(()); };
        #[cfg(unix)] {
            if !cfg!(target_os = "macos") { return Err(Failure::Platform); }
            let _watchdog = Watchdog::start();
            tokio::runtime::Builder::new_multi_thread().worker_threads(2).enable_all().build()
                .map_err(|_| Failure::Platform)?.block_on(execute(args))
        }
        #[cfg(not(unix))] { let _ = args; Err(Failure::Platform) }
    });
    if let Err(error) = result { eprintln!("RP_EXPORT_ERROR: {}", error.code()); std::process::exit(1); }
}

#[cfg(all(test, unix))]
mod tests {
    use super::*;
    #[test]
    fn explicit_arguments_and_plan_have_no_device_actions() {
        assert!(arguments(vec![]).unwrap().is_none());
        assert!(arguments(["--repo-root", "/TEST-ONLY/nonexistent", "--device-udid", "not-a-phone"].map(OsString::from).to_vec()).unwrap().is_none());
        assert!(arguments(["--execute", "--repo-root", "/TEST-ONLY/nonexistent", "--device-udid", "not-a-phone"].map(OsString::from).to_vec()).is_err());
        let valid = arguments(["--execute", "--repo-root", "/TEST-ONLY/dokkan-offline-public", "--device-udid", "00000000-0000000000000000"].map(OsString::from).to_vec()).unwrap().unwrap();
        assert!(!valid.manual_local_pin);
    }
    #[test]
    fn private_export_never_replaces_existing_file_or_symlink() {
        use std::os::unix::fs::symlink;
        let base = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("target")
            .join(format!("TEST-ONLY-rp-export-{}", std::process::id()));
        fs::create_dir_all(&base).unwrap();
        let directory = private_directory(&base, "private").unwrap();
        assert_eq!(fs::metadata(&directory).unwrap().permissions().mode() & 0o777, 0o700);
        let _lock = ExportLock::acquire(&directory).unwrap();
        assert!(ExportLock::acquire(&directory).is_err());
        durable_new_export(&directory, b"TEST-ONLY no real pairing identity").unwrap();
        assert_eq!(fs::metadata(directory.join(OUTPUT)).unwrap().mode() & 0o777, 0o600);
        assert!(durable_new_export(&directory, b"TEST-ONLY replacement").is_err());
        assert_eq!(fs::read(directory.join(OUTPUT)).unwrap(), b"TEST-ONLY no real pairing identity");
        fs::remove_file(directory.join(OUTPUT)).unwrap();
        let sentinel = base.join("TEST-ONLY-sentinel"); fs::write(&sentinel,b"untouched").unwrap();
        symlink(&sentinel, directory.join(OUTPUT)).unwrap();
        assert!(durable_new_export(&directory,b"TEST-ONLY denied").is_err());
        assert_eq!(fs::read(sentinel).unwrap(),b"untouched");
        drop(_lock); fs::remove_dir_all(base).unwrap();
    }
}
