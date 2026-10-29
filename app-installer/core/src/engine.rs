//! Apple/device engine. No raw third-party errors or credential values enter UI events.
use crate::Status;
use apple_codesign_quick::ProvisioningProfile;
use idevice::{
    installation_proxy::InstallationProxyClient, misagent::MisagentClient,
    pairing_file::PairingFile, provider::TcpProvider, IdeviceService,
};
use isideload::{
    anisette::remote_v3::RemoteV3AnisetteProvider,
    auth::apple_account::{AppleAccount, TwoFactorCallbackResponse},
    dev::{
        app_groups::{AppGroup, AppGroupsApi},
        app_ids::{AppIdsApi, Profile},
        developer_session::DeveloperSession,
        devices::DevicesApi,
        teams::{DeveloperTeam, TeamsApi},
    },
    sideload::{
        application::Application, builder::MaxCertsBehavior, cert_identity::CertificateIdentity,
        sign,
    },
    util::storage::SideloadingStorage,
};
use rootcause::prelude::*;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::{
    collections::{HashMap, HashSet, VecDeque},
    ffi::{c_char, CStr, CString},
    path::{Path, PathBuf},
    sync::{
        atomic::{AtomicBool, AtomicU64, Ordering},
        Mutex, OnceLock,
    },
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::{
    runtime::Runtime,
    sync::{oneshot, Mutex as AsyncMutex},
    task::AbortHandle,
};
use x509_cert::der::Encode;
use zeroize::Zeroizing;
#[path = "transport.rs"]
mod transport;
use transport::DeviceTransport;

const ANISETTE_URL: &str = "https://ani.jkcoxson.com";
const PAIRING_KEY: &str = "engine.pairing";
static REMOTE_PAIRING_PORT: AtomicU64 = AtomicU64::new(0);
tokio::task_local! { static OPERATION_SCOPE:(u64, &'static str); }
static RUNTIME: OnceLock<Runtime> = OnceLock::new();
static ENGINE: OnceLock<AsyncMutex<Engine>> = OnceLock::new();
static EVENTS: Mutex<VecDeque<Value>> = Mutex::new(VecDeque::new());
static SNAPSHOT: OnceLock<Mutex<Value>> = OnceLock::new();
static CONTROL: Mutex<()> = Mutex::new(());
static AUTH_GENERATION: AtomicU64 = AtomicU64::new(0);
static BUSY: AtomicBool = AtomicBool::new(false);
static ACTIVE_OPERATION: Mutex<(u64, &'static str)> = Mutex::new((0, "state"));
static STAGING_ID: AtomicU64 = AtomicU64::new(0);
static SIGNED_IN: AtomicBool = AtomicBool::new(false);
static GENERATION: AtomicU64 = AtomicU64::new(0);
static CANCEL_GENERATION: AtomicU64 = AtomicU64::new(0);
static ABORT: Mutex<Option<AbortHandle>> = Mutex::new(None);
static TWO_FACTOR: Mutex<Option<oneshot::Sender<TwoFactorCallbackResponse>>> = Mutex::new(None);
static TWO_FACTOR_NUMBERS: Mutex<Vec<u32>> = Mutex::new(Vec::new());
static TEAM_SELECTION: Mutex<Option<oneshot::Sender<String>>> = Mutex::new(None);

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct Record {
    name: String,
    bundle_id: String,
    expiry: i64,
    source: String,
    #[serde(default)]
    original_bundle_id: String,
    #[serde(default)]
    team_id: String,
    #[serde(default)]
    extension_identities: Vec<crate::identity::ExtensionIdentity>,
    #[serde(default)]
    is_self: bool,
    #[serde(default)]
    bundle_version: Option<String>,
    #[serde(default)]
    short_version: Option<String>,
}
struct Staged {
    validated: crate::archive::ValidatedIpa,
    original: PathBuf,
    record: Record,
    cancel_generation: u64,
    initial_install: bool,
}
struct Engine {
    work: PathBuf,
    account: Option<AppleAccount>,
    dev: Option<DeveloperSession>,
    team: Option<DeveloperTeam>,
    auth_generation: u64,
    staged: Option<Staged>,
    records: Vec<Record>,
    device_host: String,
    self_bundle_id: Option<String>,
    // Runtime metadata from this actual running bundle, never an imported IPA.
    self_signing_identity: Option<plist::Dictionary>,
}

fn runtime() -> &'static Runtime {
    RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .build()
            .expect("runtime unavailable")
    })
}

fn configured_device_host() -> String {
    // Native code supplies an explicitly selected local tunnel address after
    // initialization. Never substitute a guessed address or read cwd files.
    String::new()
}

fn engine() -> &'static AsyncMutex<Engine> {
    ENGINE.get_or_init(|| {
        AsyncMutex::new(Engine {
            work: PathBuf::new(),
            account: None,
            dev: None,
            team: None,
            auth_generation: 0,
            staged: None,
            records: vec![],
            device_host: configured_device_host(),
            self_bundle_id: None,
            self_signing_identity: None,
        })
    })
}
fn snapshot() -> &'static Mutex<Value> {
    SNAPSHOT.get_or_init(|| Mutex::new(json!({"loginStatus":"signed_out","paired":false,"biometricEnabled":true,"busy":false,"ownExpiry":Value::Null,"statusMessage":"Sign in to continue.","backendReady":true,"apps":[]})))
}
fn publish(kind: &str, message: &str, mut extra: Value) {
    let (operation_id, operation) = OPERATION_SCOPE
        .try_with(|scope| *scope)
        .unwrap_or_else(|_| ACTIVE_OPERATION.lock().map(|v| *v).unwrap_or((0, "state")));
    if OPERATION_SCOPE
        .try_with(|scope| scope.0 != GENERATION.load(Ordering::Acquire))
        .unwrap_or(false)
    {
        return;
    }
    if (operation == "login" && matches!(kind, "error" | "done"))
        || matches!(kind, "cancelled" | "locked" | "signed_out")
    {
        let reset = json!({"loginStatus":if SIGNED_IN.load(Ordering::Acquire){"signed_in"}else{"signed_out"},"teams":[],"twoFactorNumbers":[],"unknown":false,"supportsSms":false,"canResend":false});
        if let (Some(target), Some(reset)) = (extra.as_object_mut(), reset.as_object()) {
            for (k, v) in reset {
                target.insert(k.clone(), v.clone());
            }
        }
    }
    let mut event =
        json!({"type":kind,"message":message,"operation":operation,"operationId":operation_id});
    if let Some(m) = extra.as_object() {
        for (k, v) in m {
            event[k] = v.clone();
        }
    }
    if let Ok(mut s) = snapshot().lock() {
        s["statusMessage"] = json!(message);
        s["operation"] = json!(operation);
        s["activeOperationId"] = json!(operation_id);
        s["busy"] = json!(BUSY.load(Ordering::Acquire));
        if let Some(m) = extra.as_object() {
            for (k, v) in m {
                s[k] = v.clone();
            }
        }
    }
    if let Ok(mut q) = EVENTS.lock() {
        if q.len() >= 128 {
            q.pop_front();
        }
        q.push_back(event);
    }
}
fn now() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        .min(i64::MAX as u64) as i64
}
#[derive(Debug)]
struct UserFacingError(&'static str);
impl std::fmt::Display for UserFacingError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.0)
    }
}
impl std::error::Error for UserFacingError {}
fn failure(message: &'static str) -> Report {
    Report::new(UserFacingError(message)).into()
}
fn safe_message(error: &Report) -> &'static str {
    error.iter_reports().find_map(|node| {
        node.downcast_current_context::<UserFacingError>().map(|error|error.0)
            .or_else(||node.downcast_current_context::<IndependentAppFailure>().map(|error|error.0))
    }).unwrap_or("The operation could not finish. Check your account, pairing file and LocalDevVPN, then try again.")
}
/// Only call before this app's provisioning/sign/install side effects. The
/// refresh scheduler never guesses independence from strings or generic errors.
#[derive(Debug)]
struct IndependentAppFailure(&'static str);
impl std::fmt::Display for IndependentAppFailure {
    fn fmt(&self,formatter:&mut std::fmt::Formatter<'_>)->std::fmt::Result {formatter.write_str(self.0)}
}
impl std::error::Error for IndependentAppFailure {}
fn independent_app_failure(message:&'static str)->Report {Report::new(IndependentAppFailure(message)).into()}
fn independent_app_error(error:&Report)->bool {
    error.iter_reports().any(|node|node.downcast_current_context::<IndependentAppFailure>().is_some())
}
fn c_string(ptr: *const c_char, max: usize) -> Result<Zeroizing<String>, Status> {
    if ptr.is_null() {
        return Err(Status::InvalidArgument);
    }
    let bytes = unsafe { CStr::from_ptr(ptr) }.to_bytes();
    if bytes.len() > max {
        return Err(Status::InvalidArgument);
    }
    let s = std::str::from_utf8(bytes).map_err(|_| Status::InvalidArgument)?;
    if s.is_empty() {
        return Err(Status::InvalidArgument);
    }
    Ok(Zeroizing::new(s.to_owned()))
}
fn enqueue<F>(operation: &'static str, future: F) -> Status
where
    F: std::future::Future<Output = Result<(&'static str, Value), Report>> + Send + 'static,
{
    let Ok(_control) = CONTROL.lock() else {
        return Status::NotReady;
    };
    if BUSY
        .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
        .is_err()
    {
        return Status::Busy;
    }
    let generation = GENERATION.fetch_add(1, Ordering::AcqRel) + 1;
    if let Ok(mut active) = ACTIVE_OPERATION.lock() {
        *active = (generation, operation);
    }
    publish("progress", "Working…", json!({}));
    let task = runtime().spawn(OPERATION_SCOPE.scope((generation, operation), async move {
        let result = tokio::time::timeout(Duration::from_secs(600), future).await;
        let Ok(_control) = CONTROL.lock() else { return };
        if GENERATION.load(Ordering::Acquire) != generation {
            return;
        }
        BUSY.store(false, Ordering::Release);
        match result {
            Ok(Ok((message, data))) => {
                let kind = if data.get("signed") == Some(&json!(true)) {
                    "signed"
                } else {
                    "done"
                };
                publish(kind, message, data)
            }
            Ok(Err(error)) => {
                let message = safe_message(&error);
                let category = if message.contains("App ID") {
                    "app_id_limit"
                } else if message.contains("3 active apps") {
                    "app_limit"
                } else if message.contains("capabilit") {
                    "unsupported_capability"
                } else if message.contains("membership") {
                    "membership_unknown"
                } else {
                    "operation_failed"
                };
                publish("error", message, json!({"errorCategory":category}));
            }
            Err(_) => publish(
                "error",
                "The operation timed out. Open the app and try again.",
                json!({}),
            ),
        }
        if let Ok(mut p) = TWO_FACTOR.lock() {
            p.take();
        }
        if let Ok(mut p) = TEAM_SELECTION.lock() {
            p.take();
        }
        if let Ok(mut p) = TWO_FACTOR_NUMBERS.lock() {
            p.clear();
        }
    }));
    if let Ok(mut h) = ABORT.lock() {
        *h = Some(task.abort_handle());
    }
    Status::Ok
}

#[cfg(target_os = "ios")]
unsafe extern "C" {
    fn ai_secure_read(
        key: *const c_char,
        buffer: *mut u8,
        capacity: usize,
        length: *mut usize,
    ) -> i32;
    fn ai_secure_write(key: *const c_char, data: *const u8, length: usize) -> i32;
    fn ai_secure_remove(key: *const c_char) -> i32;
}
#[derive(Clone, Copy)]
struct NativeStorage;
impl NativeStorage {
    fn raw_read(key: &str) -> Result<Option<Zeroizing<Vec<u8>>>, Report> {
        #[cfg(target_os = "ios")]
        {
            let key = CString::new(key)?;
            let mut size = 0;
            let status =
                unsafe { ai_secure_read(key.as_ptr(), std::ptr::null_mut(), 0, &mut size) };
            if status == 1 {
                return Ok(None);
            }
            if status != 0 || size > 16 * 1024 * 1024 {
                return Err(failure("Secure storage unavailable"));
            }
            let mut data = Zeroizing::new(vec![0; size]);
            let status =
                unsafe { ai_secure_read(key.as_ptr(), data.as_mut_ptr(), data.len(), &mut size) };
            if status != 0 || size > data.len() {
                return Err(failure("Secure storage unavailable"));
            }
            data.truncate(size);
            Ok(Some(data))
        }
        #[cfg(not(target_os = "ios"))]
        {
            let _ = key;
            Err(failure("Native Keychain required"))
        }
    }
    fn raw_write(key: &str, data: &[u8]) -> Result<(), Report> {
        #[cfg(target_os = "ios")]
        {
            let key = CString::new(key)?;
            if unsafe { ai_secure_write(key.as_ptr(), data.as_ptr(), data.len()) } != 0 {
                return Err(failure("Secure storage unavailable"));
            }
            Ok(())
        }
        #[cfg(not(target_os = "ios"))]
        {
            let _ = (key, data);
            Err(failure("Native Keychain required"))
        }
    }
    fn raw_delete(key: &str) -> Result<(), Report> {
        #[cfg(target_os = "ios")]
        {
            let key = CString::new(key)?;
            let s = unsafe { ai_secure_remove(key.as_ptr()) };
            if s != 0 && s != 1 {
                return Err(failure("Secure storage unavailable"));
            }
            Ok(())
        }
        #[cfg(not(target_os = "ios"))]
        {
            let _ = key;
            Err(failure("Native Keychain required"))
        }
    }
}
impl SideloadingStorage for NativeStorage {
    fn store(&self, key: &str, value: &str) -> Result<(), Report> {
        Self::raw_write(&format!("engine.{key}"), value.as_bytes())
    }
    fn retrieve(&self, key: &str) -> Result<Option<String>, Report> {
        Self::raw_read(&format!("engine.{key}"))?
            .map(|d| String::from_utf8(d.to_vec()).map_err(Report::from))
            .transpose()
    }
    fn delete(&self, key: &str) -> Result<(), Report> {
        Self::raw_delete(&format!("engine.{key}"))
    }
}
// Reqwest 0.13 rustls-no-provider deliberately panics without an explicitly
// installed default, even when rustls's ring feature is the only compiled backend.
// Set it before constructing HTTP clients; a concurrent prior installation is safe.
fn ensure_crypto_provider() -> Result<(), Report> {
    if rustls::crypto::CryptoProvider::get_default().is_none() {
        let _ = rustls::crypto::ring::default_provider().install_default();
    }
    rustls::crypto::CryptoProvider::get_default()
        .map(|_| ())
        .ok_or_else(|| failure("Secure network initialization could not finish."))
}
async fn account_builder(email: &str) -> Result<AppleAccount, Report> {
    ensure_crypto_provider()?;
    let anisette =
        RemoteV3AnisetteProvider::new(ANISETTE_URL, Box::new(NativeStorage), "0".into())?;
    AppleAccount::builder(email)
        .danger_debug(false)
        .err_429_retries(Some(1))
        .anisette_provider(anisette)
        .build()
        .await
}
async fn finish_login(mut account: AppleAccount) -> Result<(&'static str, Value), Report> {
    let mut dev = DeveloperSession::from_account(&mut account).await?;
    let teams = dev.list_teams().await?;
    let team = match teams.len() {
        0 => return Err(failure("No developer team available")),
        1 => teams[0].clone(),
        _ => {
            let (tx, rx) = oneshot::channel();
            if let Ok(mut pending) = TEAM_SELECTION.lock() {
                *pending = Some(tx);
            }
            publish(
                "needs_team",
                "Choose the developer team to use.",
                json!({"loginStatus":"needs_team","teams":teams.iter().map(|t|json!({"id":t.team_id,"name":t.name.clone().unwrap_or_else(||"Developer team".into())})).collect::<Vec<_>>()}),
            );
            let selected = tokio::time::timeout(Duration::from_secs(300), rx)
                .await
                .map_err(|_| failure("Team selection timed out"))?
                .map_err(|_| failure("Sign in cancelled"))?;
            teams
                .into_iter()
                .find(|t| t.team_id == selected)
                .ok_or_else(|| failure("Invalid developer team selection"))?
        }
    };
    let mut e = engine().lock().await;
    let _control = CONTROL
        .lock()
        .map_err(|_| failure("Task state unavailable"))?;
    if OPERATION_SCOPE
        .try_with(|scope| scope.0 != GENERATION.load(Ordering::Acquire))
        .unwrap_or(true)
    {
        return Err(failure("Sign in cancelled"));
    }
    let spd = account
        .spd
        .as_ref()
        .ok_or_else(|| failure("Session missing"))?;
    let mut bytes = Zeroizing::new(Vec::new());
    plist::to_writer_xml(&mut *bytes, spd)?;
    NativeStorage::raw_write("engine.account.spd", &bytes)?;
    NativeStorage::raw_write("engine.account.email", account.email.as_bytes())?;
    e.auth_generation = AUTH_GENERATION.fetch_add(1, Ordering::AcqRel) + 1;
    e.team = Some(team);
    e.dev = Some(dev);
    e.account = Some(account);
    SIGNED_IN.store(true, Ordering::Release);
    Ok(("Signed in.", json!({"loginStatus":"signed_in","teams":[]})))
}
async fn provider(e: &Engine) -> Result<DeviceTransport, Report> {
    let bytes =
        NativeStorage::raw_read(PAIRING_KEY)?.ok_or_else(|| failure("Pairing file required"))?;
    let credentials = transport::parse_credentials(&bytes)?;
    let address = e.device_host.parse().map_err(|_|failure("The device tunnel address is not configured. Check the approved LocalDevVPN setup."))?;
    DeviceTransport::connect(credentials, address, REMOTE_PAIRING_PORT.load(Ordering::Acquire) as u16).await
}
async fn device_apps(
    provider: &mut DeviceTransport,
    work: &Path,
) -> Result<HashMap<String, plist::Value>, Report> {
    provider.apps(work).await
}
fn is_installed(apps: &HashMap<String, plist::Value>, id: &str) -> bool {
    apps.keys().any(|key| key.eq_ignore_ascii_case(id))
}
fn version_evidence(info: &plist::Dictionary) -> Result<(String, Option<String>), Report> {
    let build = info
        .get("CFBundleVersion")
        .and_then(plist::Value::as_string)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| {
            failure("The app has no valid build version. Installation cannot be confirmed safely.")
        })?;
    let short = match info.get("CFBundleShortVersionString") {
        Some(value) => Some(
            value
                .as_string()
                .filter(|s| !s.is_empty())
                .ok_or_else(|| failure("The app has an invalid release version."))?
                .to_owned(),
        ),
        None => None,
    };
    Ok((build.to_owned(), short))
}
fn confirm_installed_version(
    apps: &HashMap<String, plist::Value>,
    record: &Record,
) -> Result<(), Report> {
    let info = apps
        .iter()
        .find(|(id, _)| id.eq_ignore_ascii_case(&record.bundle_id))
        .and_then(|(_, info)| info.as_dictionary())
        .ok_or_else(|| failure("Installation was not confirmed by the iPhone."))?;
    let (build,short)=version_evidence(info).map_err(|_|failure("The iPhone did not return the installed build version. The latest IPA was retained for confirmation."))?;
    if record.bundle_version.as_deref() != Some(build.as_str())
        || record
            .short_version
            .as_ref()
            .is_some_and(|expected| Some(expected) != short.as_ref())
    {
        return Err(failure("The iPhone still reports a different app version or build. The latest IPA was retained; installation was not confirmed."));
    }
    Ok(())
}
fn record_running_self(e: &mut Engine, record: Record) -> Result<(), Report> {
    let pending = pending_install(&e.work)?;
    let confirmed_transition = pending.as_ref().is_some_and(|p| {
        let intended = &p.record;
        p.bundle_id.eq_ignore_ascii_case(&record.bundle_id)
            && record.bundle_version.is_some()
            && record.bundle_version == intended.bundle_version
            && record.short_version == intended.short_version
            && record.expiry == intended.expiry
            && record.team_id == intended.team_id
            && e.records.iter().any(|old| {
                old.is_self
                    && old.bundle_id.eq_ignore_ascii_case(&record.bundle_id)
                    && (old.expiry != intended.expiry
                        || old
                            .bundle_version
                            .as_ref()
                            .is_some_and(|v| Some(v) != intended.bundle_version.as_ref())
                        || old
                            .short_version
                            .as_ref()
                            .is_some_and(|v| Some(v) != intended.short_version.as_ref()))
            })
    });
    e.records
        .retain(|r| !r.bundle_id.eq_ignore_ascii_case(&record.bundle_id));
    e.records.push(record);
    persist_records(e)?;
    if confirmed_transition {
        crate::install_journal::clear(&e.work, &pending.unwrap())?;
    }
    Ok(())
}

async fn development_app_count(
    provider: &mut DeviceTransport,
    apps: &HashMap<String, plist::Value>,
) -> Result<u32, Report> {
    let profiles = provider.profiles().await?;
    let mut ids = HashSet::new();
    for data in profiles {
        let p = ProvisioningProfile::parse(&data)?;
        if p.entitlements()
            .get("get-task-allow")
            .and_then(plist::Value::as_boolean)
            != Some(true)
        {
            continue;
        }
        let expiry = p
            .plist()
            .get("ExpirationDate")
            .and_then(plist::Value::as_date)
            .ok_or_else(|| failure("Profile expiry unknown"))?;
        let expiration: SystemTime = expiry.into();
        if expiration <= SystemTime::now() {
            continue;
        }
        let id = p
            .entitlements()
            .get("application-identifier")
            .and_then(plist::Value::as_string)
            .ok_or_else(|| failure("Profile app ID unknown"))?;
        let id = id
            .split_once('.')
            .map(|(_, id)| id)
            .ok_or_else(|| failure("Profile app ID unknown"))?;
        if id.contains('*') {
            return Err(failure("Wildcard development profile usage unknown"));
        }
        if is_installed(apps, id) {
            ids.insert(id.to_owned());
        }
    }
    // Conservative: all installed development apps count, including other teams/installers.
    u32::try_from(ids.len()).map_err(Report::from)
}
pub(super) fn earliest_profile_expiry(main: i64, extensions: impl IntoIterator<Item = i64>) -> i64 {
    extensions.into_iter().fold(main, i64::min)
}
fn source_filename(id: &str) -> String {
    let hash = Sha256::digest(id.as_bytes());
    let mut s = String::with_capacity(68);
    for byte in hash {
        s.push_str(&format!("{byte:02x}"));
    }
    s.push_str(".ipa");
    s
}
fn records_json(records: &[Record]) -> Value {
    json!(records.iter().map(|r|json!({"name":r.name,"bundleId":r.bundle_id,"originalBundleId":if r.original_bundle_id.is_empty(){&r.bundle_id}else{&r.original_bundle_id},"expiry":r.expiry})).collect::<Vec<_>>())
}
fn own_expiry(e: &Engine) -> Value {
    e.records
        .iter()
        .filter(|r| {
            r.is_self
                && e.self_bundle_id
                    .as_deref()
                    .is_none_or(|id| id.eq_ignore_ascii_case(&r.bundle_id))
        })
        .map(|r| r.expiry)
        .min()
        .map(|n| json!(n))
        .unwrap_or(Value::Null)
}
fn legacy_pending(e: &Engine) -> bool {
    e.records.iter().any(|r| {
        source_owned(&e.work, Path::new(&r.source))
            && std::fs::symlink_metadata(Path::new(&r.source).with_extension("ipa.pending")).is_ok()
    })
}
fn pending_install(work: &Path) -> Result<Option<crate::install_journal::Pending<Record>>, Report> {
    let pending = crate::install_journal::read::<Record>(work)?;
    if pending.as_ref().is_some_and(|p| {
        !p.record.bundle_id.eq_ignore_ascii_case(&p.bundle_id)
            || Path::new(&p.record.source)
                != work.join("sources").join(source_filename(&p.bundle_id))
    }) {
        return Err(failure("Protected install recovery metadata needs checking. Re-import the latest IPA before refreshing."));
    }
    Ok(pending)
}
fn record_state(e: &Engine) -> Value {
    let pending = pending_install(&e.work);
    json!({"apps":records_json(&e.records),"ownExpiry":own_expiry(e),"recoveryNeeded":legacy_pending(e)||pending.as_ref().map(|p|p.is_some()).unwrap_or(true),"recoveryBundleId":pending.ok().flatten().map(|p|p.bundle_id)})
}
fn write_records(work: &Path, records: &[Record]) -> Result<(), Report> {
    use std::io::Write;
    let bytes = serde_json::to_vec(records)?;
    let temp = work.join("installed.json.pending");
    if std::fs::symlink_metadata(&temp).is_ok_and(|m| !m.file_type().is_file()) {
        return Err(failure("Invalid protected metadata path"));
    }
    let mut options = std::fs::OpenOptions::new();
    options.write(true).create(true).truncate(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    let mut file = options.open(&temp)?;
    file.write_all(&bytes)?;
    file.sync_all()?;
    std::fs::rename(temp, work.join("installed.json"))?;
    std::fs::File::open(work)?.sync_all()?;
    Ok(())
}
fn persist_records(e: &Engine) -> Result<(), Report> {
    write_records(&e.work, &e.records)
}
fn source_owned(work: &Path, path: &Path) -> bool {
    let Some(name) = path
        .file_name()
        .and_then(|s| s.to_str())
        .and_then(|s| s.strip_suffix(".ipa"))
    else {
        return false;
    };
    name.len() == 64
        && name
            .bytes()
            .all(|b| b.is_ascii_digit() || (b'a'..=b'f').contains(&b))
        && path.parent().and_then(|p| p.canonicalize().ok())
            == work.join("sources").canonicalize().ok()
}
fn reconcile_confirmed_apps(
    e: &mut Engine,
    lookup: Result<HashMap<String, plist::Value>, Report>,
) -> Result<(), Report> {
    // Never prune or discard source data when the device query fails.
    let apps = lookup?;
    if let Some(pending) = pending_install(&e.work)? {
        let current_self = e
            .self_bundle_id
            .as_deref()
            .is_some_and(|id| id.eq_ignore_ascii_case(&pending.bundle_id));
        let previously_managed=e.records.iter().any(|record|record.bundle_id.eq_ignore_ascii_case(&pending.bundle_id));
        if !is_installed(&apps, &pending.bundle_id) && !current_self && !pending.initial_install && previously_managed {
            crate::install_journal::clear(&e.work, &pending)?;
        }
    }
    let retained = e
        .records
        .iter()
        .filter(|record| {
            is_installed(&apps, &record.bundle_id)
                || (record.is_self
                    && e.self_bundle_id
                        .as_deref()
                        .is_some_and(|id| id.eq_ignore_ascii_case(&record.bundle_id)))
        })
        .cloned()
        .collect::<Vec<_>>();
    if retained != e.records {
        write_records(&e.work, &retained)?;
        let removed = e
            .records
            .iter()
            .filter(|r| {
                !retained
                    .iter()
                    .any(|kept| kept.bundle_id.eq_ignore_ascii_case(&r.bundle_id))
            })
            .map(|r| r.source.clone())
            .collect::<Vec<_>>();
        e.records = retained;
        for source in removed {
            let path = PathBuf::from(source);
            if source_owned(&e.work, &path)
                && !e.records.iter().any(|r| Path::new(&r.source) == path)
            {
                let _ = std::fs::remove_file(path.with_extension("ipa.pending"));
                let _ = std::fs::remove_file(path);
            }
        }
    }
    Ok(())
}
fn cleanup_startup_transients(work: &Path) -> Result<(), Report> {
    // A fully serialized metadata replacement is written only after a confirmed install
    // and source promotion. Recover that atomic transaction before deleting scratch files.
    let pending = work.join("installed.json.pending");
    if std::fs::symlink_metadata(&pending)
        .is_ok_and(|m| m.file_type().is_file() && m.len() <= 256 * 1024)
    {
        let valid = std::fs::read(&pending)
            .ok()
            .and_then(|data| serde_json::from_slice::<Vec<Record>>(&data).ok())
            .is_some_and(|records| {
                records.iter().all(|r| {
                    source_owned(work, Path::new(&r.source))
                        && std::fs::symlink_metadata(&r.source)
                            .is_ok_and(|m| m.file_type().is_file())
                })
            });
        if valid {
            std::fs::rename(&pending, work.join("installed.json"))?;
        } else {
            std::fs::remove_file(&pending)?;
        }
    }
    for child in std::fs::read_dir(work.join("imports"))? {
        let child = child?;
        let name = child.file_name();
        let Some(name) = name.to_str().and_then(|s| s.strip_suffix(".ipa")) else {
            continue;
        };
        let owned = name.len() == 36
            && name.bytes().enumerate().all(|(i, b)| {
                if matches!(i, 8 | 13 | 18 | 23) {
                    b == b'-'
                } else {
                    b.is_ascii_hexdigit()
                }
            });
        if owned && !child.file_type()?.is_dir() {
            std::fs::remove_file(child.path())?;
        }
    }
    for child in std::fs::read_dir(work.join("staging"))? {
        let child = child?;
        let name = child.file_name();
        let Some(name) = name.to_str() else { continue };
        let parts = name.split('-').collect::<Vec<_>>();
        let owned = parts.len() == 3
            && matches!(parts[0], "app" | "self")
            && parts[1..]
                .iter()
                .all(|part| !part.is_empty() && part.bytes().all(|b| b.is_ascii_digit()));
        if owned {
            if child.file_type()?.is_dir() {
                std::fs::remove_dir_all(child.path())?;
            } else {
                std::fs::remove_file(child.path())?;
            }
        }
    }
    crate::install_journal::cleanup_unreferenced::<Record>(work)?;
    // Legacy source .ipa.pending candidates are not blindly deleted: after an interrupted
    // old-version update they may be the only latest input. No current working source is touched.
    Ok(())
}
fn checked_source(e: &Engine, path: &Path) -> Result<(), Report> {
    let parent = path
        .parent()
        .ok_or_else(|| failure("Invalid app source"))?
        .canonicalize()?;
    let allowed = e.work.join("imports").canonicalize()?;
    let sources = e.work.join("sources").canonicalize()?;
    if parent != allowed && parent != sources {
        return Err(failure("App source outside protected directory"));
    }
    if std::fs::symlink_metadata(path)?.file_type().is_symlink() {
        return Err(failure("App source is a symlink"));
    }
    Ok(())
}
fn membership_paid(team: &DeveloperTeam) -> Option<bool> {
    if team.r#type.as_deref() == Some("Free") {
        return Some(false);
    }
    let memberships = team.memberships.as_ref()?;
    if memberships.is_empty() {
        return Some(false);
    }
    let active_ios = memberships.iter().any(|m| {
        let platform = m.get("platform").and_then(plist::Value::as_string);
        let name = m.get("name").and_then(plist::Value::as_string);
        let status = m.get("status").and_then(plist::Value::as_string);
        let active = status.is_none_or(|s| s.eq_ignore_ascii_case("active"));
        let expires = m
            .get("dateExpire")
            .and_then(plist::Value::as_date)
            .map(|date| {
                let t: SystemTime = date.into();
                t > SystemTime::now()
            })
            .unwrap_or(true);
        active
            && expires
            && (platform.is_some_and(|p| p.eq_ignore_ascii_case("ios"))
                || matches!(
                    name,
                    Some("iOS Developer Program") | Some("Apple Developer Program")
                ))
    });
    active_ios.then_some(true)
}
fn installed_self_identity(entitlements:&plist::Dictionary,bundle_id:&str,team:&str)->Result<plist::Dictionary,Report>{
    let invalid=||failure("App Installer's existing Keychain identity could not be verified. Keep its original developer team and signed installation.");
    let app=entitlements.get("application-identifier").and_then(plist::Value::as_string).ok_or_else(invalid)?;
    if !app.ends_with(&format!(".{bundle_id}")) || team.is_empty()
        || entitlements.get("com.apple.developer.team-identifier").and_then(plist::Value::as_string).is_some_and(|value|value!=team) {return Err(invalid());}
    let groups=entitlements.get("keychain-access-groups").and_then(plist::Value::as_array).filter(|groups|!groups.is_empty()).ok_or_else(invalid)?;
    if groups.iter().any(|value|value.as_string().is_none_or(|value|value.is_empty()||value.len()>1024||value.chars().any(char::is_control))){return Err(invalid());}
    let mut identity=plist::Dictionary::new();
    identity.insert("application-identifier".into(),plist::Value::String(app.into()));
    identity.insert("com.apple.developer.team-identifier".into(),plist::Value::String(team.into()));
    identity.insert("keychain-access-groups".into(),plist::Value::Array(groups.clone()));
    Ok(identity)
}
fn self_refresh_requirements(e:&Engine,input:&str,team:&str,requested:&mut plist::Dictionary)->Result<Option<plist::Dictionary>,Report>{
    let own_source=e.self_bundle_id.as_deref().is_some_and(|own|own.eq_ignore_ascii_case(input)||input.eq_ignore_ascii_case(crate::identity::INSTALLER_ORIGINAL_ID))
        || e.records.iter().any(|record|record.is_self&&(record.bundle_id.eq_ignore_ascii_case(input)||record.original_bundle_id.eq_ignore_ascii_case(input)));
    if !own_source{return Ok(None);}
    let own=e.self_bundle_id.as_deref().ok_or_else(||failure("The running installer identity is unavailable. Reopen App Installer before updating it."))?;
    let record=e.records.iter().find(|record|record.is_self&&record.bundle_id.eq_ignore_ascii_case(own)).ok_or_else(||failure("The running installer's developer team is unavailable. Its saved data was kept."))?;
    if record.team_id.is_empty()||record.team_id!=team{return Err(failure("Self-refresh requires the developer team that signed this installed App Installer. Select its original team; its Keychain identity was not changed."));}
    let identity=e.self_signing_identity.as_ref().ok_or_else(||failure("The running installer's Keychain identity is unavailable. Reopen App Installer before updating it."))?;
    if identity.get("com.apple.developer.team-identifier").and_then(plist::Value::as_string)!=Some(team){return Err(failure("Self-refresh requires the developer team of the actual running installer. Its Keychain identity was not changed."));}
    let groups=identity.get("keychain-access-groups").ok_or_else(||failure("The running installer's Keychain access groups are unavailable."))?;
    if requested.get("keychain-access-groups").is_some_and(|candidate|candidate!=groups){return Err(failure("This installer update requests different Keychain access groups. Its existing account and pairing data must keep the original groups."));}
    // An unsigned new installer has no signing identity yet. Carry forward the
    // actual installed groups instead of inventing them from a selected team.
    requested.insert("keychain-access-groups".into(),groups.clone());
    Ok(Some(identity.clone()))
}
fn verify_self_entitlements(expected:&plist::Dictionary,signed:&plist::Dictionary)->Result<(),Report>{
    if expected.iter().any(|(key,value)|signed.get(key)!=Some(value)){
        return Err(failure("Apple's profile would change this installer's existing signing or Keychain identity. Use its original team and a profile authorizing its existing access groups; saved data was kept."));
    }
    Ok(())
}
async fn sign_path(e: &mut Engine, path: PathBuf, require_installed: bool) -> Result<(), Report> {
    if !SIGNED_IN.load(Ordering::Acquire) {
        return Err(failure("Sign in required"));
    }
    e.staged = None;
    let operation_cancel_generation = CANCEL_GENERATION.load(Ordering::Acquire);
    checked_source(e, &path).map_err(|_|independent_app_failure("This app's retained IPA is missing or could not be read safely. Import its latest IPA again."))?;
    let mut provider = provider(e).await?;
    let apps = device_apps(&mut provider, &e.work).await?;
    reconcile_confirmed_apps(e, Ok(apps.clone()))?;
    let destination = e.work.join("staging").join(format!(
        "app-{}-{}",
        now(),
        STAGING_ID.fetch_add(1, Ordering::AcqRel)
    ));
    let validated = crate::archive::validate_and_extract(&path, &destination)
        .map_err(|_| independent_app_failure("This app's IPA failed validation. Import a valid latest IPA again."))?;
    let mut application = Application::new(validated.app_dir.clone()).map_err(|_|independent_app_failure("This app's IPA bundle could not be opened safely."))?;
    let input_bundle_id = application.main_bundle_id().map_err(|_|independent_app_failure("This app's IPA identity is invalid."))?;
    let (bundle_version, short_version) = version_evidence(&application.bundle.app_info).map_err(|_|independent_app_failure("This app's IPA version metadata is invalid."))?;
    let name = application.main_app_name().map_err(|_|independent_app_failure("This app's IPA name metadata is invalid."))?;
    let mut main_requested =
        crate::capabilities::read_entitlements(&application.bundle.bundle_dir, &input_bundle_id)
            .map_err(|_| {
                independent_app_failure(
            "The app's required entitlements could not be read safely. No capability was removed.",
        )
            })?;
    crate::entitlement_policy::validate_requested(&main_requested)
        .map_err(|error| independent_app_failure(error.user_message()))?;
    let mut extension_requests = HashMap::new();
    let mut verified_expiries = vec![];
    for extension in application.bundle.app_extensions() {
        let id = extension
            .bundle_identifier()
            .ok_or_else(|| independent_app_failure("This app's extension identity is missing."))?;
        let requested=crate::capabilities::read_entitlements(&extension.bundle_dir,id)
            .map_err(|_|independent_app_failure("An extension's required entitlements could not be read safely. No capability was removed."))?;
        crate::entitlement_policy::validate_requested(&requested)
            .map_err(|error| independent_app_failure(error.user_message()))?;
        extension_requests.insert(id.to_owned(), requested);
    }

    let team = e.team.clone().ok_or_else(|| failure("Sign in required"))?;
    let self_identity=self_refresh_requirements(e,&input_bundle_id,&team.team_id,&mut main_requested)?;
    let loaded_extension_ids = application
        .bundle
        .app_extensions()
        .iter()
        .map(|ext| {
            ext.bundle_identifier()
                .map(str::to_owned)
                .ok_or_else(|| failure("Extension identity missing"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let mut loaded_sorted = loaded_extension_ids.clone();
    loaded_sorted.sort();
    if loaded_sorted != validated.extension_ids {
        return Err(failure(
            "This extension layout is not supported yet. No App ID was created.",
        ));
    }
    let account_email = e
        .account
        .as_ref()
        .ok_or_else(|| failure("Sign in required"))?
        .email
        .clone();
    let dev = e.dev.as_mut().ok_or_else(|| failure("Sign in required"))?;
    let quota = dev.list_app_ids(&team, None).await?;
    let recorded = e.records.iter().any(|r| {
        r.bundle_id.eq_ignore_ascii_case(&input_bundle_id)
            || r.original_bundle_id.eq_ignore_ascii_case(&input_bundle_id)
    });
    let adopted = if recorded {
        None
    } else {
        crate::identity::adopt_external(&input_bundle_id,&loaded_extension_ids,&team.team_id,&apps.keys().cloned().collect::<Vec<_>>(),&quota.app_ids.iter().map(|a|a.identifier.clone()).collect::<Vec<_>>()).map_err(|_|failure("A copy of this app is already installed outside the selected team's known identity. Select its original team or remove that copy yourself; a second app was not created."))?
    };
    let mut previous = e
        .records
        .iter()
        .map(|r| crate::identity::ExistingIdentity {
            original: &r.original_bundle_id,
            signed: &r.bundle_id,
            team: &r.team_id,
            extensions: &r.extension_identities,
            is_self: r.is_self,
            installed: is_installed(&apps, &r.bundle_id),
        })
        .collect::<Vec<_>>();
    if let Some(adopted) = &adopted {
        previous.push(crate::identity::ExistingIdentity {
            original: &input_bundle_id,
            signed: &adopted.signed,
            team: &team.team_id,
            extensions: &adopted.extensions,
            is_self: false,
            installed: is_installed(&apps, &adopted.signed),
        });
    }
    let identity=crate::identity::plan(&input_bundle_id,&loaded_extension_ids,&team.team_id,&previous,e.self_bundle_id.as_deref()).map_err(|error|match error{
        crate::identity::IdentityError::OtherTeamInstalled=>failure("This app is already installed under another developer team. Select that team or remove its copy yourself before switching."),
        _=>failure("The app's original and installed identities could not be matched safely. No App ID was created.")
    })?;
    if require_installed && !is_installed(&apps, &identity.signed_bundle_id) {
        return Err(failure(
            "The app was removed from the device. Refresh did not reinstall it.",
        ));
    }
    // Mutate only our validated staging copy. The original IPA remains unchanged for repeat imports.
    crate::identity::apply(&mut application, &input_bundle_id, &identity).map_err(|_| {
        failure("The app's staged bundle identities could not be rewritten safely.")
    })?;
    let bundle_id = identity.signed_bundle_id.clone();

    let mut all_ids = vec![bundle_id.clone()];
    all_ids.extend(
        identity
            .extensions
            .iter()
            .map(|ext| ext.signed_bundle_id.clone()),
    );
    // Account classification uses explicit membership evidence or an existing profile,
    // never an individual/company label. All checks precede device/certificate/App-ID mutations.
    let mut paid = membership_paid(&team);
    if paid.is_none() {
        if let Some(existing) = quota.app_ids.first() {
            paid = dev
                .download_team_provisioning_profile(&team, existing, None)
                .await?
                .is_free_provisioning_profile
                .map(|free| !free);
        }
    }
    let paid=paid.ok_or_else(||failure("Your account membership could not be confirmed. No new certificate or App ID was created."))?;
    if !paid && !is_installed(&apps, &bundle_id) {
        let active = development_app_count(&mut provider, &apps).await?;
        if active >= 3 {
            return Err(failure("Free Apple accounts allow 3 active apps, including this installer. Free an app slot before installing."));
        }
    }
    let needed = all_ids
        .iter()
        .filter(|id| !quota.app_ids.iter().any(|a| &a.identifier == *id))
        .count();
    if !paid
        && needed > 0
        && quota
            .available_quantity
            .is_some_and(|n| n < 0 || needed as i64 > n)
    {
        return Err(failure("Weekly App ID limit reached"));
    }
    if !paid && needed > 0 && quota.available_quantity.is_none() {
        return Err(failure("App ID usage unknown"));
    }
    let info = provider.info().await?;
    dev.ensure_device_registered(&team, "App Installer iPhone", &info.udid, None)
        .await?;
    type CertCallback = fn(
        Vec<isideload::dev::certificates::DevelopmentCertificate>,
    ) -> std::future::Ready<Result<Option<Vec<String>>, Report>>;
    let cert = CertificateIdentity::retrieve(
        "App Installer",
        &account_email,
        dev,
        &team,
        &NativeStorage,
        &MaxCertsBehavior::<CertCallback>::Error,
    )
    .await?;
    let mut profiles: Vec<(String, Profile, plist::Dictionary)> = vec![];
    let mut main_profile = None;
    let mut main_entitlements = None;
    let mut known_groups: Option<HashMap<String, AppGroup>> = None;
    for id in &all_ids {
        let (original_id, requested) = if id == &bundle_id {
            (&input_bundle_id, &main_requested)
        } else {
            let original = identity
                .extension_rewrites
                .iter()
                .find(|(_, signed)| signed == id)
                .map(|(original, _)| original)
                .ok_or_else(|| failure("Extension capability mapping missing"))?;
            (
                original,
                extension_requests
                    .get(original)
                    .ok_or_else(|| failure("Extension requirements missing"))?,
            )
        };
        let new_app_id = !quota
            .app_ids
            .iter()
            .any(|a| a.identifier.eq_ignore_ascii_case(id));
        let mut registered = match quota
            .app_ids
            .iter()
            .find(|a| a.identifier.eq_ignore_ascii_case(id))
        {
            Some(a) => a.clone(),
            None => dev.add_app_id(&team, &name, id, None).await?,
        };
        let memory = crate::entitlement_policy::memory_capabilities(requested);
        if new_app_id && !memory.is_empty() {
            dev.configure_new_memory_capabilities(&team,&registered,&memory).await
                .map_err(|_|failure("Apple did not authorize the requested memory or virtual-addressing capabilities. They were not silently removed."))?;
        }
        let desired = crate::entitlement_policy::feature_requests(requested);
        let updates = desired
            .into_iter()
            .filter(|(key, value)| registered.features.get(key) != Some(value))
            .collect::<plist::Dictionary>();
        if !updates.is_empty() {
            registered=dev.update_app_id(&team,&registered,updates,None).await
            .map_err(|_|failure("Apple did not allow the requested capabilities on this App ID. Required features were not removed."))?;
        }
        let groups = crate::entitlement_policy::app_groups(requested)
            .map_err(|error| failure(error.user_message()))?;
        if !groups.is_empty() {
            if known_groups.is_none() {
                known_groups=Some(dev.list_app_groups(&team,None).await
                .map_err(|_|failure("Apple's app-group ownership could not be checked. Shared groups were not renamed."))?
                .into_iter().map(|group|(group.identifier.clone(),group)).collect());
            }
            let cache = known_groups
                .as_mut()
                .ok_or_else(|| failure("App-group state unavailable"))?;
            let mut assignments = vec![];
            for group_id in groups {
                let group = match cache.get(&group_id) {
                    Some(group) => group.clone(),
                    None => {
                        let group=dev.add_app_group(&team,&name,&group_id,None).await
                        .map_err(|_|failure("Apple did not permit this source app's exact shared-container group. Another team's hardcoded group cannot be silently renamed."))?;
                        if group.identifier != group_id {
                            return Err(failure("Apple returned an unexpected shared-group identifier. The source app was not changed."));
                        }
                        cache.insert(group_id, group.clone());
                        group
                    }
                };
                assignments.push(group);
            }
            dev.assign_app_groups(&team,&assignments,&registered,None).await
                .map_err(|_|failure("Apple did not bind all required app groups to this App ID. No group was silently omitted."))?;
        }
        let profile = dev
            .download_team_provisioning_profile(&team, &registered, None)
            .await?;
        let parsed = ProvisioningProfile::parse(profile.encoded_profile.as_ref())?;
        if parsed.team_id() != team.team_id {
            return Err(failure(
                "Apple's profile belongs to another developer team.",
            ));
        }
        let entitlements = crate::entitlement_policy::reconcile(
            requested,
            original_id,
            id,
            &team.team_id,
            parsed.entitlements(),
        )
        .map_err(|error| failure(error.user_message()))?;
        if id == &bundle_id {
            if let Some(expected)=&self_identity{verify_self_entitlements(expected,&entitlements)?;}
            main_profile = Some(profile);
            main_entitlements = Some(entitlements);
        } else {
            profiles.push((id.clone(), profile, entitlements));
        }
    }
    let profile = main_profile.ok_or_else(|| failure("Provisioning profile missing"))?;
    if profile
        .is_free_provisioning_profile
        .is_some_and(|free| free == paid)
    {
        return Err(failure(
            "Apple account membership changed. Sign in again before continuing.",
        ));
    }
    let callback = |p: f32| async move {
        publish("progress", "Signing…", json!({"progress":p}));
    };
    let main_entitlements =
        main_entitlements.ok_or_else(|| failure("Main app entitlements missing"))?;
    sign::sign_with_entitlements(
        &mut application,
        &cert,
        &profile,
        &main_entitlements,
        &profiles,
        &team,
        Some(callback),
    )
    .await?;
    let signing_cert_der = cert.certificate.to_der()?;
    let verified=crate::signed_verification::verify_signed_bundle(
        &application.bundle.bundle_dir,&team.team_id,&bundle_id,&info.udid,
        profile.encoded_profile.as_ref(),&signing_cert_der,SystemTime::now(),
    ).map_err(|_|failure("The signed app failed independent profile, entitlement, certificate or resource verification. It was not sent to the iPhone."))?;
    for extension in application.bundle.app_extensions() {
        let id = extension
            .bundle_identifier()
            .ok_or_else(|| failure("Signed extension identity missing"))?;
        let (_, profile, _) = profiles
            .iter()
            .find(|(bundle_id, _, _)| bundle_id == id)
            .ok_or_else(|| failure("Signed extension profile evidence missing"))?;
        let extension_verified=crate::signed_verification::verify_signed_bundle(
            &extension.bundle_dir,&team.team_id,id,&info.udid,
            profile.encoded_profile.as_ref(),&signing_cert_der,SystemTime::now(),
        ).map_err(|_|failure("A signed extension failed independent profile, entitlement, certificate or resource verification. It was not sent to the iPhone."))?;
        verified_expiries.push(extension_verified.profile_expiry);
    }
    publish(
        "progress",
        "Signed profiles, required capabilities and code/resources verified offline.",
        json!({
            "offlineSignatureVerified":true,
            "verifiedExecutableSlices":verified.executable_slices,
            "verifiedResourceFiles":verified.resource_files,
            "liveInstallationVerified":verified.live_installation_verified,
            "revocationChecked":verified.revocation_checked
        }),
    );
    let expiry = earliest_profile_expiry(verified.profile_expiry, verified_expiries);
    let initial_install=!is_installed(&apps,&bundle_id);
    let record = Record {
        name,
        bundle_id,
        expiry,
        source: String::new(),
        original_bundle_id: identity.original_bundle_id,
        team_id: team.team_id,
        extension_identities: identity.extensions,
        is_self: identity.is_self,
        bundle_version: Some(bundle_version),
        short_version,
    };
    if operation_cancel_generation != CANCEL_GENERATION.load(Ordering::Acquire) {
        return Err(failure("Task cancelled"));
    }
    e.staged = Some(Staged {
        validated,
        original: path,
        record,
        cancel_generation: operation_cancel_generation,
        initial_install,
    });
    Ok(())
}
async fn install_staged(e: &mut Engine) -> Result<(), Report> {
    let mut provider = provider(e).await?;
    let mut staged = e
        .staged
        .take()
        .ok_or_else(|| failure("Sign the app first"))?;
    if staged.cancel_generation != CANCEL_GENERATION.load(Ordering::Acquire) {
        return Err(failure("Task cancelled"));
    }
    provider.cleanup(&e.work).await?;
    // Bundle-directory names do not define its signed CFBundleIdentifier. Use a unique,
    // installer-owned basename so upstream PublicStaging never overlaps another installer's app.
    let basename = crate::cleanup::unique_basename(STAGING_ID.fetch_add(1, Ordering::AcqRel));
    let app_path = staged.validated.app_dir.with_file_name(&basename);
    if app_path.exists() {
        return Err(failure("Owned staging directory already exists"));
    }
    std::fs::rename(&staged.validated.app_dir, &app_path)?;
    staged.validated.app_dir = app_path.clone();
    let source = e
        .work
        .join("sources")
        .join(source_filename(&staged.record.bundle_id));
    let mut intended_record = staged.record.clone();
    intended_record.source = source.to_string_lossy().into_owned();
    crate::install_journal::prepare_with_state(&e.work,&staged.record.bundle_id,&intended_record,&staged.original,staged.initial_install)
        .map_err(|_|failure("An interrupted install needs its latest IPA confirmed before another app can be installed. Re-import that app's latest IPA; existing source files were kept."))?;
    crate::cleanup::remember(&e.work, &basename)?;
    if staged.cancel_generation != CANCEL_GENERATION.load(Ordering::Acquire) {
        return Err(failure("Task cancelled"));
    }
    let result = provider.install(&app_path).await;
    // Cancellation/crash may interrupt this await. Durable intent remains for next connection.
    let _ = provider.cleanup(&e.work).await;
    result?;
    let apps = device_apps(&mut provider, &e.work).await?;
    confirm_installed_version(&apps, &staged.record)?;
    let pending = pending_install(&e.work)?
        .ok_or_else(|| failure("Approved install source journal missing"))?;
    if !pending
        .bundle_id
        .eq_ignore_ascii_case(&staged.record.bundle_id)
    {
        return Err(failure("Approved install identity changed"));
    }
    let candidate = crate::install_journal::verified_candidate(&e.work, &pending)?;
    let record = pending.record.clone();
    let temp = source.with_extension("ipa.pending");
    std::fs::copy(&candidate, &temp)?;
    if crate::install_journal::hash_file(&temp)? != pending.source_sha256 {
        return Err(failure("Retained app source did not verify"));
    }
    std::fs::File::open(&temp)?.sync_all()?;
    std::fs::rename(&temp, &source)?;
    let old_sources = e
        .records
        .iter()
        .filter(|r| {
            r.bundle_id == record.bundle_id
                || (!r.original_bundle_id.is_empty()
                    && r.original_bundle_id
                        .eq_ignore_ascii_case(&record.original_bundle_id))
        })
        .map(|r| r.source.clone())
        .collect::<Vec<_>>();
    e.records.retain(|r| {
        r.bundle_id != record.bundle_id
            && (r.original_bundle_id.is_empty()
                || !r
                    .original_bundle_id
                    .eq_ignore_ascii_case(&record.original_bundle_id))
    });
    e.records.push(record);
    persist_records(e)?;
    crate::install_journal::clear(&e.work, &pending)?;
    publish(
        "state",
        "Installed source and expiry recorded.",
        record_state(e),
    );
    // Delete superseded owned sources only after successful install + durable current metadata.
    for old in old_sources {
        let old = PathBuf::from(old);
        if old != source && old.parent() == Some(e.work.join("sources").as_path()) {
            let _ = std::fs::remove_file(old);
        }
    }
    Ok(())
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all="camelCase")]
struct RefreshOutcome { bundle_id:String, name:String, status:&'static str, message:&'static str }
trait RefreshOperations:Send {
    fn sign(&mut self,record:&Record)->impl std::future::Future<Output=Result<(),Report>>+Send;
    fn install(&mut self)->impl std::future::Future<Output=Result<(),Report>>+Send;
    fn continuation_allowed(&self)->Result<bool,Report>;
    fn report(&mut self,results:&[RefreshOutcome]);
}
struct EngineRefresh<'a>{engine:&'a mut Engine,cancellation:u64}
impl RefreshOperations for EngineRefresh<'_>{
    async fn sign(&mut self,record:&Record)->Result<(),Report>{
        sign_path(self.engine,PathBuf::from(&record.source),true).await
    }
    async fn install(&mut self)->Result<(),Report>{install_staged(self.engine).await}
    fn continuation_allowed(&self)->Result<bool,Report>{
        Ok(self.cancellation==CANCEL_GENERATION.load(Ordering::Acquire)
            && SIGNED_IN.load(Ordering::Acquire)
            && self.engine.account.is_some() && self.engine.dev.is_some() && self.engine.team.is_some()
            && pending_install(&self.engine.work)?.is_none() && !legacy_pending(self.engine))
    }
    fn report(&mut self,results:&[RefreshOutcome]){
        let mut state=record_state(self.engine);state["refreshResults"]=json!(results);
        publish("state","Refresh results updated.",state);
    }
}
async fn refresh_records(operations:&mut impl RefreshOperations,mut records:Vec<Record>)->Result<Vec<RefreshOutcome>,Report>{
    records.sort_by_key(|record|record.is_self);
    let mut results=Vec::new();operations.report(&results);
    for record in records {
        if let Err(error)=operations.sign(&record).await{
            let independent=independent_app_error(&error);
            results.push(RefreshOutcome{bundle_id:record.bundle_id,name:record.name,status:"failed",message:safe_message(&error)});
            operations.report(&results);
            if independent && operations.continuation_allowed()? {continue;}
            return Err(error);
        }
        if !operations.continuation_allowed()? {
            let message="Refresh stopped because authorization changed or an interrupted installation needs confirmation. Sources were kept.";
            results.push(RefreshOutcome{bundle_id:record.bundle_id,name:record.name,status:"failed",message});operations.report(&results);
            return Err(failure(message));
        }
        // Every installation error is fatal: a lost response can hide a device
        // success. Keep the exact pending source and never advance to another app.
        if let Err(error)=operations.install().await{
            results.push(RefreshOutcome{bundle_id:record.bundle_id,name:record.name,status:"failed",message:safe_message(&error)});operations.report(&results);
            return Err(error);
        }
        results.push(RefreshOutcome{bundle_id:record.bundle_id,name:record.name,status:"refreshed",message:"Refreshed and confirmed by the device."});operations.report(&results);
    }
    Ok(results)
}

fn zip_own_bundle(bundle: &Path, output: &Path) -> Result<(), Report> {
    use std::io::{Read, Write};
    fn add(
        writer: &mut zip::ZipWriter<std::fs::File>,
        path: &Path,
        base: &Path,
    ) -> Result<(), Report> {
        let metadata = std::fs::symlink_metadata(path)?;
        if metadata.file_type().is_symlink() {
            return Err(failure("Self-refresh source contains an unsupported link"));
        }
        let name = path
            .file_name()
            .and_then(|v| v.to_str())
            .ok_or_else(|| failure("Invalid self-refresh source"))?;
        if name == "ALTPairingFile.dat"
            || name == ".env"
            || ["p12", "p8", "pem", "key", "mobiledevicepairing"]
                .contains(&path.extension().and_then(|v| v.to_str()).unwrap_or(""))
        {
            return Err(failure(
                "Self-refresh source contains protected account data",
            ));
        }
        if metadata.is_dir() {
            for child in std::fs::read_dir(path)? {
                add(writer, &child?.path(), base)?;
            }
        } else if metadata.is_file() {
            let relative = path
                .strip_prefix(base)
                .map_err(|_| failure("Invalid self-refresh source"))?;
            let archive_name = format!("Payload/{}", relative.to_string_lossy());
            #[cfg(unix)]
            let mode = {
                use std::os::unix::fs::PermissionsExt;
                metadata.permissions().mode() & 0o777
            };
            #[cfg(not(unix))]
            let mode = 0o644;
            writer.start_file(
                archive_name,
                zip::write::SimpleFileOptions::default()
                    .compression_method(zip::CompressionMethod::Deflated)
                    .unix_permissions(mode),
            )?;
            let mut file = std::fs::File::open(path)?;
            let mut buf = [0u8; 65536];
            loop {
                let n = file.read(&mut buf)?;
                if n == 0 {
                    break;
                }
                writer.write_all(&buf[..n])?;
            }
        } else {
            return Err(failure("Self-refresh source contains a special file"));
        }
        Ok(())
    }
    let file = std::fs::OpenOptions::new()
        .create_new(true)
        .write(true)
        .open(output)?;
    let mut writer = zip::ZipWriter::new(file);
    let result = add(
        &mut writer,
        bundle,
        bundle
            .parent()
            .ok_or_else(|| failure("Invalid self-refresh source"))?,
    );
    if result.is_err() {
        drop(writer);
        let _ = std::fs::remove_file(output);
        return result;
    }
    if let Err(error) = writer.finish() {
        let _ = std::fs::remove_file(output);
        return Err(error.into());
    }
    Ok(())
}
pub fn register_self_bundle(ptr: *const c_char) -> Status {
    let bundle = match c_string(ptr, 4096) {
        Ok(s) => PathBuf::from(&*s),
        Err(s) => return s,
    };
    enqueue("register_self", async move {
        let mut e = engine().lock().await;
        if e.work.as_os_str().is_empty() {
            return Err(failure("Initialize the app first"));
        }
        let metadata = std::fs::symlink_metadata(&bundle)?;
        if !metadata.is_dir()
            || metadata.file_type().is_symlink()
            || bundle.extension().and_then(|v| v.to_str()) != Some("app")
        {
            return Err(failure("Invalid installer bundle"));
        }
        let info: plist::Dictionary = plist::from_file(bundle.join("Info.plist"))?;
        let (bundle_version, short_version) = version_evidence(&info)?;
        let id = info
            .get("CFBundleIdentifier")
            .and_then(plist::Value::as_string)
            .ok_or_else(|| failure("Installer identity missing"))?;
        if id != "org.tin.appinstaller" && !id.starts_with("org.tin.appinstaller.") {
            return Err(failure("Installer identity does not match this project"));
        }
        e.self_bundle_id = Some(id.to_owned());
        let profile =
            match std::fs::read(bundle.join("embedded.mobileprovision")) {
                Ok(bytes) => ProvisioningProfile::parse(&bytes)?,
                Err(_) => return Ok((
                    "Self-refresh will be available after the first reviewed signed installation.",
                    json!({"selfRefreshReady":false}),
                )),
            };
        let own_entitlements=crate::capabilities::read_entitlements(&bundle,id).map_err(|_|failure("The running installer's signed Keychain identity could not be read safely."))?;
        e.self_signing_identity=Some(installed_self_identity(&own_entitlements,id,profile.team_id())?);
        let expiry = profile
            .plist()
            .get("ExpirationDate")
            .and_then(plist::Value::as_date)
            .ok_or_else(|| failure("Installer profile expiry missing"))?;
        let expiration: SystemTime = expiry.into();
        let expiry = expiration.duration_since(UNIX_EPOCH)?.as_secs() as i64;
        let source = e.work.join("sources").join(source_filename(id));
        let temp = source.with_extension("ipa.pending");
        if temp.exists() {
            std::fs::remove_file(&temp)?;
        }
        zip_own_bundle(&bundle, &temp)?;
        let stage = e.work.join("staging").join(format!(
            "self-{}-{}",
            now(),
            STAGING_ID.fetch_add(1, Ordering::AcqRel)
        ));
        let validated = crate::archive::validate_and_extract(&temp, &stage)
            .map_err(|_| failure("Installed self-refresh source failed validation"));
        if let Err(error) = validated {
            let _ = std::fs::remove_file(&temp);
            return Err(error);
        }
        std::fs::rename(&temp, &source)?;
        record_running_self(
            &mut e,
            Record {
                name: "App Installer".into(),
                bundle_id: id.into(),
                expiry,
                source: source.to_string_lossy().into_owned(),
                original_bundle_id: crate::identity::INSTALLER_ORIGINAL_ID.into(),
                team_id: profile.team_id().into(),
                extension_identities: vec![],
                is_self: true,
                bundle_version: Some(bundle_version),
                short_version,
            },
        )?;
        Ok(("Self-refresh source is ready.", {
            let mut state = record_state(&e);
            state["selfRefreshReady"] = json!(true);
            state
        }))
    })
}

pub fn initialize(ptr: *const c_char) -> Status {
    if ensure_crypto_provider().is_err() {
        return Status::NotReady;
    }
    let path = match c_string(ptr, 4096) {
        Ok(s) => PathBuf::from(&*s),
        Err(s) => return s,
    };
    let Ok(_control) = CONTROL.lock() else {
        return Status::NotReady;
    };
    if BUSY.load(Ordering::Acquire) {
        return Status::Busy;
    }
    let Ok(mut e) = engine().try_lock() else {
        return Status::Busy;
    };
    if !e.work.as_os_str().is_empty() {
        return if path.canonicalize().ok() == Some(e.work.clone()) {
            Status::Ok
        } else {
            Status::InvalidArgument
        };
    }
    if !path.is_absolute()
        || std::fs::create_dir_all(&path).is_err()
        || !std::fs::symlink_metadata(&path).is_ok_and(|m| m.file_type().is_dir())
    {
        return Status::InvalidArgument;
    }
    let Ok(path) = path.canonicalize() else {
        return Status::InvalidArgument;
    };
    for child in ["imports", "sources", "staging"] {
        let child = path.join(child);
        if std::fs::create_dir_all(&child).is_err()
            || !std::fs::symlink_metadata(&child).is_ok_and(|m| m.file_type().is_dir())
        {
            return Status::InvalidArgument;
        }
    }
    if cleanup_startup_transients(&path).is_err() {
        return Status::NotReady;
    }
    e.work = path;
    if let Ok(data) = std::fs::read(e.work.join("installed.json")) {
        if let Ok(records) = serde_json::from_slice::<Vec<Record>>(&data) {
            e.records = records;
        }
    }
    // A crash after confirmed metadata commit but before journal cleanup is already recoverable.
    if let Ok(Some(pending)) = pending_install(&e.work) {
        if e.records.iter().any(|r| r == &pending.record)
            && crate::install_journal::hash_file(Path::new(&pending.record.source))
                .ok()
                .as_deref()
                == Some(&pending.source_sha256)
        {
            let _ = crate::install_journal::clear(&e.work, &pending);
        }
    }
    let state = record_state(&e);
    let message = if state["recoveryNeeded"] == json!(true) {
        "An interrupted install needs checking. Re-import that app's latest IPA before refreshing it."
    } else {
        "Ready to sign in."
    };
    publish("state", message, state);
    Status::Ok
}
pub fn login(email: *const c_char, password: *const c_char) -> Status {
    let email = match c_string(email, 320) {
        Ok(s) => s,
        Err(s) => return s,
    };
    let password = match c_string(password, 4096) {
        Ok(s) => s,
        Err(s) => return s,
    };
    enqueue("login", async move {
        let mut account = account_builder(&email).await?;
        account.login(&password,|params|async move{
            let(tx,rx)=oneshot::channel();if let Ok(mut pending)=TWO_FACTOR.lock(){*pending=Some(tx);}
            if let Ok(mut numbers)=TWO_FACTOR_NUMBERS.lock(){*numbers=params.numbers.iter().map(|n|n.id).collect();}
            publish("needs_2fa","Enter the code Apple sent you.",json!({"loginStatus":"needs_2fa","supportsSms":params.sms,"canResend":true,"unknown":params.unknown,"twoFactorNumbers":params.numbers.iter().map(|n|json!({"id":n.id,"lastTwoDigits":n.last_two_digits})).collect::<Vec<_>>()}));
            tokio::time::timeout(Duration::from_secs(300),rx).await.map_err(|_|failure("Code entry timed out"))?.map_err(|_|failure("Sign in cancelled"))
        }).await?;
        finish_login(account).await
    })
}
pub fn restore() -> Status {
    enqueue("login", async {
        let email = NativeStorage::raw_read("engine.account.email")?
            .ok_or_else(|| failure("Sign in required"))?;
        let spd = NativeStorage::raw_read("engine.account.spd")?
            .ok_or_else(|| failure("Sign in required"))?;
        let mut account = account_builder(std::str::from_utf8(&email)?).await?;
        account.spd = Some(plist::from_bytes(&spd)?);
        finish_login(account).await
    })
}
pub fn submit_code(ptr: *const c_char) -> Status {
    let code = match c_string(ptr, 6) {
        Ok(s) => s,
        Err(s) => return s,
    };
    if code.len() != 6 || !code.bytes().all(|b| b.is_ascii_digit()) {
        return Status::InvalidArgument;
    }
    let Ok(mut pending) = TWO_FACTOR.lock() else {
        return Status::NotReady;
    };
    match pending.take() {
        Some(tx) => {
            if tx
                .send(TwoFactorCallbackResponse::SubmitCode(code.to_string()))
                .is_ok()
            {
                Status::Ok
            } else {
                Status::NotReady
            }
        }
        None => Status::NotReady,
    }
}
pub fn select_team(ptr: *const c_char) -> Status {
    let selected = match c_string(ptr, 128) {
        Ok(s) => s,
        Err(s) => return s,
    };
    let Ok(mut pending) = TEAM_SELECTION.lock() else {
        return Status::NotReady;
    };
    match pending.take() {
        Some(tx) => {
            if tx.send(selected.to_string()).is_ok() {
                Status::Ok
            } else {
                Status::NotReady
            }
        }
        None => Status::NotReady,
    }
}
pub fn request_2fa(action: i32, number_id: u32) -> Status {
    let response = match action {
        0 => TwoFactorCallbackResponse::ResendCode,
        1 => TwoFactorCallbackResponse::SendToDevices,
        2 => {
            if !TWO_FACTOR_NUMBERS
                .lock()
                .map(|ids| ids.contains(&number_id))
                .unwrap_or(false)
            {
                return Status::InvalidArgument;
            }
            TwoFactorCallbackResponse::SendSms(number_id)
        }
        _ => return Status::InvalidArgument,
    };
    let Ok(mut pending) = TWO_FACTOR.lock() else {
        return Status::NotReady;
    };
    match pending.take() {
        Some(tx) => {
            if tx.send(response).is_ok() {
                Status::Ok
            } else {
                Status::NotReady
            }
        }
        None => Status::NotReady,
    }
}
pub fn resend() -> Status {
    let Ok(mut pending) = TWO_FACTOR.lock() else {
        return Status::NotReady;
    };
    match pending.take() {
        Some(tx) => {
            if tx.send(TwoFactorCallbackResponse::ResendCode).is_ok() {
                Status::Ok
            } else {
                Status::NotReady
            }
        }
        None => Status::NotReady,
    }
}
pub fn import_pairing(data: *const u8, length: usize) -> Status {
    let Ok(_control) = CONTROL.lock() else { return Status::NotReady };
    if BUSY.load(Ordering::Acquire) {
        return Status::Busy;
    }
    if data.is_null() || length == 0 || length > 1024 * 1024 {
        return Status::InvalidArgument;
    }
    let bytes = unsafe { std::slice::from_raw_parts(data, length) };
    let credentials = match transport::parse_credentials(bytes) {
        Ok(credentials) => credentials,
        Err(_) => return Status::InvalidArgument,
    };
    let Ok(mut e) = engine().try_lock() else { return Status::Busy };
    if NativeStorage::raw_write(PAIRING_KEY, bytes).is_err() {
        return Status::StorageLocked;
    }
    // A signed staging object/profile belonged to the previously paired device.
    // Changing credentials must require signing again for the selected identity.
    e.staged = None;
    CANCEL_GENERATION.fetch_add(1, Ordering::AcqRel);
    REMOTE_PAIRING_PORT.store(0, Ordering::Release);
    publish(
        "state",
        "Pairing file imported. Keep LocalDevVPN enabled.",
        json!({"paired":true,"pairingKind":credentials.kind(),"pairingVerified":false,"remotePairingPortConfigured":false}),
    );
    Status::Ok
}
pub fn set_host(ptr: *const c_char) -> Status {
    let host = match c_string(ptr, 64) { Ok(host) => host, Err(status) => return status };
    let address: std::net::IpAddr = match host.parse() {
        Ok(address) => address, Err(_) => return Status::InvalidArgument,
    };
    if address.is_unspecified() || address.is_multicast()
        || matches!(address, std::net::IpAddr::V4(ip) if ip.is_broadcast()) {
        return Status::InvalidArgument;
    }
    let Ok(_control) = CONTROL.lock() else { return Status::NotReady };
    if BUSY.load(Ordering::Acquire) { return Status::Busy; }
    let Ok(mut e) = engine().try_lock() else { return Status::Busy };
    let canonical = address.to_string();
    if e.device_host != canonical {
        e.device_host = canonical;
        e.staged = None;
        CANCEL_GENERATION.fetch_add(1, Ordering::AcqRel);
        REMOTE_PAIRING_PORT.store(0, Ordering::Release);
        publish("state", "Device tunnel configuration updated. Check the connection again.",
            json!({"deviceConfigured":true,"pairingVerified":false,"remotePairingPortConfigured":false}));
    }
    Status::Ok
}
pub fn set_remote_pairing_port(port: u16) -> Status {
    let Ok(_control) = CONTROL.lock() else { return Status::NotReady };
    if BUSY.load(Ordering::Acquire) { return Status::Busy; }
    REMOTE_PAIRING_PORT.store(u64::from(port), Ordering::Release);
    publish("state", "Remote Pairing discovery configuration updated.",
        json!({"remotePairingPortConfigured":port!=0,"pairingVerified":false}));
    Status::Ok
}
pub fn pairing_kind() -> i32 {
    match NativeStorage::raw_read(PAIRING_KEY) {
        Ok(None) | Err(_) => 0,
        Ok(Some(bytes)) => match transport::parse_credentials(&bytes) {
            Ok(transport::Credentials::Lockdown(_)) => 1,
            Ok(transport::Credentials::Remote(_)) => 2,
            Err(_) => -1,
        },
    }
}
pub fn match_remote_pairing_service(identifier: *const c_char, auth_tag: *const c_char) -> bool {
    let identifier = match c_string(identifier, 255) { Ok(value) if !value.is_empty() && !value.chars().any(char::is_control) => value, _ => return false };
    let auth_tag = match c_string(auth_tag, 128) { Ok(value) if !value.is_empty() => value, _ => return false };
    let Ok(Some(bytes)) = NativeStorage::raw_read(PAIRING_KEY) else { return false };
    let Ok(transport::Credentials::Remote(record)) = transport::parse_credentials(&bytes) else { return false };
    let Some(key) = record.alt_irk() else { return false };
    idevice::remote_pairing::PeerDevice::validate_auth_tag(key, &identifier, &auth_tag)
}

pub fn sign_ipa(ptr: *const c_char) -> Status {
    let path = match c_string(ptr, 4096) {
        Ok(s) => PathBuf::from(&*s),
        Err(s) => return s,
    };
    enqueue("sign", async move {
        let mut e = engine().lock().await;
        sign_path(&mut e, path, false).await?;
        Ok(("Signed. Ready to install.", json!({"signed":true})))
    })
}
pub fn install_ipa(_ptr: *const c_char) -> Status {
    enqueue("install", async {
        let mut e = engine().lock().await;
        install_staged(&mut e).await?;
        Ok(("Installed.", record_state(&e)))
    })
}
pub fn list_installed() -> Status {
    enqueue("list", async {
        let mut e = engine().lock().await;
        let mut provider = provider(&e).await?;
        let lookup = device_apps(&mut provider, &e.work).await;
        reconcile_confirmed_apps(&mut e, lookup)?;
        let mut state = record_state(&e);
        state["paired"] = json!(true);
        state["pairingVerified"] = json!(true);
        let message = if state["recoveryNeeded"] == json!(true) {
            "An interrupted install is present. Re-import that app's latest IPA to confirm it; automatic refresh will not downgrade it."
        } else {
            "Apps checked."
        };
        Ok((message, state))
    })
}
pub fn refresh_all() -> Status {
    enqueue("refresh_all", async {
        // A new accepted attempt must not display an earlier success if its
        // provider, lookup or recovery preflight fails before the batch starts.
        publish("state","Checking installed apps before refresh.",json!({"refreshResults":[]}));
        let mut e = engine().lock().await;
        let mut provider = provider(&e).await?;
        let lookup = device_apps(&mut provider, &e.work).await;
        reconcile_confirmed_apps(&mut e, lookup)?;
        drop(provider);
        if pending_install(&e.work)?.is_some() || legacy_pending(&e) {
            publish(
                "state",
                "Latest-source confirmation is required.",
                record_state(&e),
            );
            return Err(failure("An interrupted install needs its latest IPA confirmed. Re-import that app's latest IPA and retry. Automatic refresh will keep an unconfirmed first-install source, never reinstall a missing app or downgrade an uncertain update."));
        }
        let records = e.records.clone();
        if records.is_empty() {
            return Err(failure(
                "No installed app with a retained source IPA is available to refresh",
            ));
        }
        let cancellation=CANCEL_GENERATION.load(Ordering::Acquire);
        let results=refresh_records(&mut EngineRefresh{engine:&mut e,cancellation},records).await?;
        if results.iter().any(|result|result.status=="failed") {
            return Err(failure("Some apps could not be refreshed. Completed apps are marked refreshed; failed apps need attention."));
        }
        Ok(("Apps refreshed.", record_state(&e)))
    })
}
pub fn cancel() -> Status {
    let Ok(_control) = CONTROL.lock() else {
        return Status::NotReady;
    };
    let generation = GENERATION.fetch_add(1, Ordering::AcqRel) + 1;
    CANCEL_GENERATION.fetch_add(1, Ordering::AcqRel);
    REMOTE_PAIRING_PORT.store(0, Ordering::Release);
    if let Ok(mut active) = ACTIVE_OPERATION.lock() {
        *active = (generation, "cancel");
    }
    if let Ok(mut h) = ABORT.lock() {
        if let Some(h) = h.take() {
            h.abort();
        }
    }
    if let Ok(mut p) = TWO_FACTOR.lock() {
        p.take();
    }
    if let Ok(mut p) = TEAM_SELECTION.lock() {
        p.take();
    }
    if let Ok(mut p) = TWO_FACTOR_NUMBERS.lock() {
        p.clear();
    }
    BUSY.store(false, Ordering::Release);
    publish("cancelled", "Cancelled.", json!({"pairingVerified":false,"remotePairingPortConfigured":false}));
    Status::Ok
}
fn clear_session_memory() {
    let auth_generation = AUTH_GENERATION.load(Ordering::Acquire);
    runtime().spawn(async move {
        let mut e = engine().lock().await;
        if e.auth_generation == auth_generation {
            e.account = None;
            e.dev = None;
            e.team = None;
            e.staged = None;
        }
    });
}
pub fn lock() {
    cancel();
    SIGNED_IN.store(false, Ordering::Release);
    publish(
        "locked",
        "Unlock your saved session to continue.",
        json!({"loginStatus":"signed_out"}),
    );
    clear_session_memory();
}
pub fn sign_out() -> Status {
    cancel();
    SIGNED_IN.store(false, Ordering::Release);
    let deleted = NativeStorage::raw_delete("engine.account.email")
        .and_then(|_| NativeStorage::raw_delete("engine.account.spd"));
    publish(
        "signed_out",
        "Signed out.",
        json!({"loginStatus":"signed_out"}),
    );
    clear_session_memory();
    if deleted.is_ok() {
        Status::Ok
    } else {
        Status::StorageLocked
    }
}
fn into_json_string(value: Value) -> *mut c_char {
    CString::new(value.to_string())
        .map(CString::into_raw)
        .unwrap_or(std::ptr::null_mut())
}
pub fn poll() -> *mut c_char {
    EVENTS
        .lock()
        .ok()
        .and_then(|mut q| q.pop_front())
        .map(into_json_string)
        .unwrap_or(std::ptr::null_mut())
}
pub fn snapshot_json() -> *mut c_char {
    snapshot()
        .lock()
        .ok()
        .map(|v| into_json_string(v.clone()))
        .unwrap_or(std::ptr::null_mut())
}
pub unsafe fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(unsafe { CString::from_raw(ptr) });
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn membership_requires_evidence_and_never_guesses_individual_as_paid() {
        let mut team = DeveloperTeam {
            name: None,
            team_id: "TEST".into(),
            r#type: Some("Individual".into()),
            status: Some("active".into()),
            memberships: None,
        };
        assert_eq!(membership_paid(&team), None);
        team.memberships = Some(vec![]);
        assert_eq!(membership_paid(&team), Some(false));
        let mut membership = plist::Dictionary::new();
        membership.insert(
            "name".into(),
            plist::Value::String("Apple Developer Program".into()),
        );
        membership.insert("status".into(), plist::Value::String("active".into()));
        team.memberships = Some(vec![membership.clone()]);
        assert_eq!(membership_paid(&team), Some(true));
        membership.insert("status".into(), plist::Value::String("expired".into()));
        team.memberships = Some(vec![membership]);
        assert_eq!(membership_paid(&team), None);
        assert_eq!(source_filename(&"a".repeat(255)).len(), 68);
    }
    #[test]
    fn cancelled_sign_cannot_emit_success_or_release_a_new_operation() {
        EVENTS.lock().unwrap().clear();
        let (tx, rx) = oneshot::channel::<()>();
        assert_eq!(
            enqueue("sign", async move {
                let _ = rx.await;
                Ok(("Signed", json!({"signed":true})))
            }),
            Status::Ok
        );
        let old = snapshot().lock().unwrap()["activeOperationId"]
            .as_u64()
            .unwrap();
        cancel();
        let _ = tx.send(());
        assert_eq!(
            enqueue("list", async { Ok(("Apps checked", json!({}))) }),
            Status::Ok
        );
        runtime().block_on(async {
            for _ in 0..100 {
                if !BUSY.load(Ordering::Acquire) {
                    break;
                }
                tokio::time::sleep(Duration::from_millis(2)).await;
            }
        });
        let current = snapshot().lock().unwrap()["activeOperationId"]
            .as_u64()
            .unwrap();
        assert!(current > old);
        let events = EVENTS.lock().unwrap();
        assert!(!events
            .iter()
            .any(|e| e["type"] == "signed" && e["operationId"].as_u64() == Some(old)));
        assert!(events.iter().any(|e| e["type"] == "done"
            && e["operation"] == "list"
            && e["operationId"].as_u64() == Some(current)));
    }
    struct LifecycleFixture {
        engine: Engine,
    }
    impl LifecycleFixture {
        fn new(label: &str) -> Self {
            let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
                .join("target/lifecycle-tests")
                .join(format!(
                    "{}-{}-{}",
                    label,
                    std::process::id(),
                    STAGING_ID.fetch_add(1, Ordering::AcqRel)
                ));
            std::fs::create_dir_all(&path).unwrap();
            for child in ["sources", "imports", "staging"] {
                std::fs::create_dir(path.join(child)).unwrap();
            }
            Self {
                engine: Engine {
                    work: path.canonicalize().unwrap(),
                    account: None,
                    dev: None,
                    team: None,
                    auth_generation: 0,
                    staged: None,
                    records: vec![],
                    device_host: configured_device_host(),
                    self_bundle_id: None,
                    self_signing_identity: None,
                },
            }
        }
        fn record(&self, id: &str, bytes: &[u8]) -> Record {
            let path = self.engine.work.join("sources").join(source_filename(id));
            std::fs::write(&path, bytes).unwrap();
            Record {
                name: "Fixture".into(),
                bundle_id: id.into(),
                expiry: 100,
                source: path.to_string_lossy().into_owned(),
                original_bundle_id: id.into(),
                team_id: "TEAM".into(),
                extension_identities: vec![],
                is_self: false,
                bundle_version: Some("1".into()),
                short_version: Some("1.0".into()),
            }
        }
    }
    impl Drop for LifecycleFixture {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(&self.engine.work);
        }
    }
    #[test]
    fn recovery_failed_first_install_keeps_latest_input_after_empty_lookup_and_restart() {
        let mut fixture=LifecycleFixture::new("first-install-recovery");
        let work=fixture.engine.work.clone();
        let record=fixture.record("org.example.first",b"placeholder");
        std::fs::remove_file(&record.source).unwrap(); // No confirmed app or working source yet.
        let input=work.join("imports/11111111-2222-3333-4444-555555555555.ipa");
        std::fs::write(&input,b"exact approved first install").unwrap();
        crate::install_journal::prepare_with_state(&work,&record.bundle_id,&record,&input,true).unwrap();
        let pending=pending_install(&work).unwrap().unwrap();assert!(pending.initial_install);
        let candidate=crate::install_journal::verified_candidate(&work,&pending).unwrap();
        std::fs::remove_file(input).unwrap(); // Native terminal-error cleanup releases its import copy.
        assert!(reconcile_confirmed_apps(&mut fixture.engine,Err(failure("fixture offline"))).is_err());
        reconcile_confirmed_apps(&mut fixture.engine,Ok(HashMap::new())).unwrap();
        cleanup_startup_transients(&work).unwrap();
        reconcile_confirmed_apps(&mut fixture.engine,Ok(HashMap::new())).unwrap();
        assert!(fixture.engine.records.is_empty());
        assert_eq!(std::fs::read(&candidate).unwrap(),b"exact approved first install");
        assert_eq!(record_state(&fixture.engine)["recoveryNeeded"],json!(true));
        // A pre-upgrade journal lacking this field is also not evidence of user
        // removal when no confirmed managed record ever existed.
        let path=work.join("pending-install.json");
        let mut legacy:Value=serde_json::from_slice(&std::fs::read(&path).unwrap()).unwrap();
        legacy.as_object_mut().unwrap().remove("initialInstall");
        std::fs::write(&path,serde_json::to_vec(&legacy).unwrap()).unwrap();
        reconcile_confirmed_apps(&mut fixture.engine,Ok(HashMap::new())).unwrap();
        assert!(candidate.exists());assert!(pending_install(&work).unwrap().is_some());
        // A separately approved retry replaces only this intent after retaining
        // and hashing the new input; absence never performs that retry itself.
        let retry=work.join("imports/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.ipa");
        std::fs::write(&retry,b"new explicit retry input").unwrap();
        crate::install_journal::prepare_with_state(&work,&record.bundle_id,&record,&retry,true).unwrap();
        let next=pending_install(&work).unwrap().unwrap();assert!(!candidate.exists());
        assert_eq!(std::fs::read(crate::install_journal::verified_candidate(&work,&next).unwrap()).unwrap(),b"new explicit retry input");
        crate::install_journal::clear(&work,&next).unwrap(); // Explicit discard, not a lookup inference.
        // Confirmed removal of a previously managed update retains its existing
        // policy: clear intent/cache, never reinstall a removed app automatically.
        let managed=fixture.record("org.example.managed",b"old working input");
        fixture.engine.records.push(managed.clone());persist_records(&fixture.engine).unwrap();
        crate::install_journal::prepare(&work,&managed.bundle_id,&managed,&retry).unwrap();
        reconcile_confirmed_apps(&mut fixture.engine,Ok(HashMap::new())).unwrap();
        assert!(fixture.engine.records.is_empty());assert!(!Path::new(&managed.source).exists());
        assert!(pending_install(&work).unwrap().is_none());
        // Self-update uses the actual running signing identity, including a
        // legacy AppIdentifierPrefix distinct from the team's public identifier.
        let mut own=fixture.record("org.tin.appinstaller.fixture",b"running signed installer");
        own.is_self=true;own.original_bundle_id=crate::identity::INSTALLER_ORIGINAL_ID.into();
        fixture.engine.self_bundle_id=Some(own.bundle_id.clone());fixture.engine.records.push(own.clone());
        let old_group=format!("OLD.{}",own.bundle_id);
        let mut actual=plist::Dictionary::new();
        actual.insert("application-identifier".into(),plist::Value::String(old_group.clone()));
        actual.insert("com.apple.developer.team-identifier".into(),plist::Value::String("TEAM".into()));
        actual.insert("keychain-access-groups".into(),plist::Value::Array(vec![plist::Value::String(old_group.clone())]));
        let identity=installed_self_identity(&actual,&own.bundle_id,"TEAM").unwrap();
        fixture.engine.self_signing_identity=Some(identity.clone());
        let mut unsigned=plist::Dictionary::new();
        assert!(self_refresh_requirements(&fixture.engine,&own.bundle_id,"OTHER",&mut unsigned).is_err());
        assert!(unsigned.is_empty()); // Wrong team is refused before identity/profile mutations.
        let expected=self_refresh_requirements(&fixture.engine,crate::identity::INSTALLER_ORIGINAL_ID,"TEAM",&mut unsigned).unwrap().unwrap();
        assert_eq!(unsigned.get("keychain-access-groups"),actual.get("keychain-access-groups"));
        let mut profile=actual.clone();
        profile.insert("keychain-access-groups".into(),plist::Value::Array(vec![plist::Value::String("OLD.*".into())]));
        let signed=crate::entitlement_policy::reconcile(&unsigned,crate::identity::INSTALLER_ORIGINAL_ID,&own.bundle_id,"TEAM",&profile).unwrap();
        verify_self_entitlements(&expected,&signed).unwrap();
        let mut changed_profile=profile.clone();
        changed_profile.insert("application-identifier".into(),plist::Value::String(format!("NEW.{}",own.bundle_id)));
        changed_profile.insert("keychain-access-groups".into(),plist::Value::Array(vec![plist::Value::String("NEW.*".into()),plist::Value::String(old_group.clone())]));
        let remapped=crate::entitlement_policy::reconcile(&actual,&own.bundle_id,&own.bundle_id,"TEAM",&changed_profile).unwrap();
        assert_ne!(remapped.get("keychain-access-groups"),actual.get("keychain-access-groups"));
        assert!(verify_self_entitlements(&expected,&remapped).is_err());
        let mut conflicting=actual.clone();conflicting.insert("keychain-access-groups".into(),plist::Value::Array(vec![plist::Value::String("OTHER.shared".into())]));
        assert!(self_refresh_requirements(&fixture.engine,&own.bundle_id,"TEAM",&mut conflicting).is_err());
        // The same self-specific guard must not prevent legitimate default-group
        // remapping when a third-party source is installed under an owned ID.
        let mut third_party=actual.clone();
        third_party.insert("application-identifier".into(),plist::Value::String("OLD.org.example.source".into()));
        third_party.insert("keychain-access-groups".into(),plist::Value::Array(vec![plist::Value::String("OLD.org.example.source".into())]));
        assert!(self_refresh_requirements(&fixture.engine,"org.example.source","OTHER",&mut third_party).unwrap().is_none());
        changed_profile.insert("application-identifier".into(),plist::Value::String("NEW.org.example.signed".into()));
        let signed=crate::entitlement_policy::reconcile(&third_party,"org.example.source","org.example.signed","TEAM",&changed_profile).unwrap();
        assert_eq!(signed.get("keychain-access-groups"),Some(&plist::Value::Array(vec![plist::Value::String("NEW.org.example.signed".into())])));
    }
    #[tokio::test]
    async fn recovery_refresh_continues_local_failures_but_stops_auth_cancel_or_uncertain_install() {
        #[derive(Clone,Copy,PartialEq,Eq)]
        enum Fault { Local, Auth, NetworkLookingLocal, Unknown, Cancelled, Pending, Install }
        struct Operations {
            work:PathBuf,fault:Fault,current:Option<Record>,cancelled:bool,
            signed:Vec<String>,installed:Vec<String>,results:Vec<RefreshOutcome>,
        }
        impl RefreshOperations for Operations {
            async fn sign(&mut self,record:&Record)->Result<(),Report>{
                self.signed.push(record.bundle_id.clone());self.current=Some(record.clone());
                if record.bundle_id!="org.example.bad" {return Ok(());}
                match self.fault {
                    Fault::Local=>Err(independent_app_failure("This app's retained IPA failed local validation.")),
                    Fault::Auth=>Err(failure("Sign in required")),
                    // Matching human text does not make a network/auth error local.
                    Fault::NetworkLookingLocal=>Err(failure("This app's retained IPA failed local validation.")),
                    Fault::Unknown=>Err(report!("SYNTHETIC_PRIVATE_ERROR_DETAIL").into()),
                    Fault::Cancelled=>{self.cancelled=true;Err(independent_app_failure("This app's retained IPA failed local validation."))},
                    Fault::Pending=>{
                        crate::install_journal::prepare_with_state(&self.work,&record.bundle_id,record,Path::new(&record.source),false)?;
                        Err(independent_app_failure("This app's retained IPA failed local validation."))
                    }
                    Fault::Install=>Ok(()),
                }
            }
            async fn install(&mut self)->Result<(),Report>{
                let record=self.current.as_ref().unwrap();self.installed.push(record.bundle_id.clone());
                if self.fault==Fault::Install {
                    crate::install_journal::prepare_with_state(&self.work,&record.bundle_id,record,Path::new(&record.source),false)?;
                    return Err(failure("The device did not confirm installation. Its approved source was kept."));
                }
                Ok(())
            }
            fn continuation_allowed(&self)->Result<bool,Report>{Ok(!self.cancelled&&pending_install(&self.work)?.is_none())}
            fn report(&mut self,results:&[RefreshOutcome]){self.results=results.to_vec();}
        }
        for fault in [Fault::Local,Fault::Auth,Fault::NetworkLookingLocal,Fault::Unknown,Fault::Cancelled,Fault::Pending,Fault::Install] {
            let fixture=LifecycleFixture::new("refresh-recovery");
            let bad=fixture.record("org.example.bad",b"latest approved source");
            let good=fixture.record("org.example.good",b"good source");
            let mut own=fixture.record("org.tin.appinstaller.fixture",b"installer source");own.is_self=true;
            let mut operations=Operations{work:fixture.engine.work.clone(),fault,current:None,cancelled:false,signed:vec![],installed:vec![],results:vec![]};
            let result=refresh_records(&mut operations,vec![own.clone(),bad.clone(),good.clone()]).await;
            if fault==Fault::Local {
                let outcomes=result.unwrap();assert_eq!(outcomes.len(),3);
                assert_eq!(operations.signed,vec![bad.bundle_id.clone(),good.bundle_id.clone(),own.bundle_id.clone()]);
                assert_eq!(operations.installed,vec![good.bundle_id.clone(),own.bundle_id.clone()]);
                assert_eq!(outcomes.iter().map(|outcome|outcome.status).collect::<Vec<_>>(),vec!["failed","refreshed","refreshed"]);
            } else {
                assert!(result.is_err());assert_eq!(operations.signed,vec![bad.bundle_id.clone()]);
                if fault==Fault::Install {assert_eq!(operations.installed,vec![bad.bundle_id.clone()]);}
                else {assert!(operations.installed.is_empty());}
                assert_eq!(operations.results.len(),1);assert_eq!(operations.results[0].status,"failed");
                assert!(!serde_json::to_string(&operations.results).unwrap().contains("SYNTHETIC_PRIVATE_ERROR_DETAIL"));
                if matches!(fault,Fault::Install|Fault::Pending) {
                    let pending=pending_install(&operations.work).unwrap().unwrap();
                    assert_eq!(std::fs::read(crate::install_journal::verified_candidate(&operations.work,&pending).unwrap()).unwrap(),b"latest approved source");
                }
            }
            for record in [&bad,&good,&own] {assert!(Path::new(&record.source).exists());}
        }
    }
    #[test]
    fn lifecycle_query_failure_preserves_sources_and_confirmed_removal_never_reinstalls() {
        let mut fixture = LifecycleFixture::new("installed-only");
        let record = fixture.record("org.example.app", b"old approved source");
        fixture.engine.records.push(record.clone());
        persist_records(&fixture.engine).unwrap();
        let latest = fixture.engine.work.join("imports/latest.ipa");
        std::fs::write(&latest, b"new user approved source").unwrap();
        let mut intended = record.clone();
        intended.expiry = 200;
        crate::install_journal::prepare(
            &fixture.engine.work,
            &record.bundle_id,
            &intended,
            &latest,
        )
        .unwrap();
        let unrelated = fixture.engine.work.join("sources/user-document");
        std::fs::write(&unrelated, b"keep").unwrap();
        assert!(
            reconcile_confirmed_apps(&mut fixture.engine, Err(failure("Offline fixture"))).is_err()
        );
        assert_eq!(fixture.engine.records, vec![record.clone()]);
        assert!(Path::new(&record.source).exists());
        let mut installed = HashMap::new();
        installed.insert(
            record.bundle_id.clone(),
            plist::Value::Dictionary(plist::Dictionary::new()),
        );
        reconcile_confirmed_apps(&mut fixture.engine, Ok(installed)).unwrap();
        assert!(record_state(&fixture.engine)["recoveryNeeded"]
            .as_bool()
            .unwrap());
        assert_eq!(fixture.engine.records[0].expiry, 100); // Unconfirmed update never changes expiry/old source.
        let pending = pending_install(&fixture.engine.work).unwrap().unwrap();
        assert_eq!(
            std::fs::read(
                crate::install_journal::verified_candidate(&fixture.engine.work, &pending).unwrap()
            )
            .unwrap(),
            b"new user approved source"
        );
        reconcile_confirmed_apps(&mut fixture.engine, Ok(HashMap::new())).unwrap();
        assert!(fixture.engine.records.is_empty());
        assert!(!Path::new(&record.source).exists());
        assert!(pending_install(&fixture.engine.work).unwrap().is_none());
        assert!(unrelated.exists());
        let saved: Vec<Record> = serde_json::from_slice(
            &std::fs::read(fixture.engine.work.join("installed.json")).unwrap(),
        )
        .unwrap();
        assert!(saved.is_empty());
        let mut own = fixture.record("org.tin.appinstaller.fixture", b"running self");
        own.is_self = true;
        own.expiry = 321;
        fixture.engine.self_bundle_id = Some(own.bundle_id.clone());
        fixture.engine.records.push(own.clone());
        reconcile_confirmed_apps(&mut fixture.engine, Ok(HashMap::new())).unwrap();
        assert_eq!(fixture.engine.records, vec![own]);
        assert_eq!(record_state(&fixture.engine)["ownExpiry"], json!(321));
    }
    #[test]
    fn lifecycle_restart_retains_exact_unconfirmed_update_and_cleans_only_owned_transients() {
        let mut fixture = LifecycleFixture::new("restart");
        let work = fixture.engine.work.clone();
        let record = fixture.record("org.example.update", b"working source");
        fixture.engine.records.push(record.clone());
        persist_records(&fixture.engine).unwrap();
        let latest = work.join("imports/11111111-2222-3333-4444-555555555555.ipa");
        std::fs::write(&latest, b"approved latest source").unwrap();
        let mut intended = record.clone();
        intended.expiry = 999;
        crate::install_journal::prepare(&work, &record.bundle_id, &intended, &latest).unwrap();
        // Simulate an interrupted replacement: the previous stable source and confirmed expiry remain intact.
        let legacy = Path::new(&record.source).with_extension("ipa.pending");
        std::fs::write(&legacy, b"legacy latest source").unwrap();
        std::fs::create_dir(work.join("staging/app-1-2")).unwrap();
        std::fs::write(work.join("staging/app-1-2/temp"), b"scratch").unwrap();
        std::fs::create_dir(work.join("staging/user-folder")).unwrap();
        std::fs::write(work.join("imports/user-document"), b"keep").unwrap();
        std::fs::write(work.join("device-cleanups.json"), b"durable device intent").unwrap();
        std::fs::write(
            work.join("installed.json.pending"),
            serde_json::to_vec(&vec![record.clone()]).unwrap(),
        )
        .unwrap();
        cleanup_startup_transients(&work).unwrap();
        assert!(!latest.exists());
        assert!(!work.join("staging/app-1-2").exists());
        assert!(work.join("staging/user-folder").exists());
        assert!(work.join("imports/user-document").exists());
        assert_eq!(
            std::fs::read(work.join("device-cleanups.json")).unwrap(),
            b"durable device intent"
        );
        assert!(legacy.exists());
        assert_eq!(std::fs::read(&record.source).unwrap(), b"working source");
        let pending = pending_install(&work).unwrap().unwrap();
        assert_eq!(pending.record.expiry, 999);
        assert_eq!(
            std::fs::read(crate::install_journal::verified_candidate(&work, &pending).unwrap())
                .unwrap(),
            b"approved latest source"
        );
        assert!(record_state(&fixture.engine)["recoveryNeeded"]
            .as_bool()
            .unwrap());
        let confirmed: Vec<Record> =
            serde_json::from_slice(&std::fs::read(work.join("installed.json")).unwrap()).unwrap();
        assert_eq!(confirmed[0].expiry, 100);
        // A later explicit re-import replaces only the pending candidate; no metadata claims install success.
        let reimport = work.join("imports/reimport.ipa");
        std::fs::write(&reimport, b"explicit newest source").unwrap();
        crate::install_journal::prepare(&work, &record.bundle_id, &intended, &reimport).unwrap();
        assert!(!crate::install_journal::candidate(&work, &pending).exists());
        let newest = pending_install(&work).unwrap().unwrap();
        assert_eq!(
            std::fs::read(crate::install_journal::verified_candidate(&work, &newest).unwrap())
                .unwrap(),
            b"explicit newest source"
        );
        assert_eq!(fixture.engine.records[0].expiry, 100);
    }
    #[test]
    fn install_confirmation_and_running_self_require_actual_requested_build_and_profile_transition()
    {
        let mut fixture = LifecycleFixture::new("install-confirmation");
        let mut current = fixture.record("org.tin.appinstaller.fixture", b"old running installer");
        current.is_self = true;
        current.expiry = 100;
        fixture.engine.records.push(current.clone());
        fixture.engine.self_bundle_id = Some(current.bundle_id.clone());
        let mut info = plist::Dictionary::new();
        info.insert("CFBundleVersion".into(), "1".into());
        info.insert("CFBundleShortVersionString".into(), "1.0".into());
        let mut apps = HashMap::new();
        apps.insert(
            current.bundle_id.clone(),
            plist::Value::Dictionary(info.clone()),
        );
        assert!(confirm_installed_version(&apps, &current).is_ok()); // Same-version refresh is valid.
        let mut intended = current.clone();
        intended.bundle_version = Some("2".into());
        intended.short_version = Some("2.0".into());
        intended.expiry = 200;
        assert!(confirm_installed_version(&apps, &intended).is_err());
        info.insert("CFBundleVersion".into(), "2".into());
        info.insert("CFBundleShortVersionString".into(), "2.0".into());
        apps.insert(
            current.bundle_id.clone(),
            plist::Value::Dictionary(info.clone()),
        );
        assert!(confirm_installed_version(&apps, &intended).is_ok());
        info.remove("CFBundleVersion");
        apps.insert(current.bundle_id.clone(), plist::Value::Dictionary(info));
        assert!(confirm_installed_version(&apps, &intended).is_err());
        let latest = fixture.engine.work.join("imports/latest.ipa");
        std::fs::write(&latest, b"latest installer").unwrap();
        crate::install_journal::prepare(
            &fixture.engine.work,
            &intended.bundle_id,
            &intended,
            &latest,
        )
        .unwrap();
        record_running_self(&mut fixture.engine, current.clone()).unwrap();
        let pending = pending_install(&fixture.engine.work).unwrap().unwrap();
        assert!(crate::install_journal::verified_candidate(&fixture.engine.work, &pending).is_ok());
        assert_eq!(own_expiry(&fixture.engine), json!(100));
        record_running_self(&mut fixture.engine, intended.clone()).unwrap();
        assert!(pending_install(&fixture.engine.work).unwrap().is_none());
        assert_eq!(own_expiry(&fixture.engine), json!(200));
        // Same-build refresh can confirm through a newly verified running profile expiry.
        intended.expiry = 300;
        crate::install_journal::prepare(
            &fixture.engine.work,
            &intended.bundle_id,
            &intended,
            &latest,
        )
        .unwrap();
        record_running_self(&mut fixture.engine, intended.clone()).unwrap();
        assert!(pending_install(&fixture.engine.work).unwrap().is_none());
        // An identical visible version/profile cannot prove an interrupted same-build payload update.
        crate::install_journal::prepare(
            &fixture.engine.work,
            &intended.bundle_id,
            &intended,
            &latest,
        )
        .unwrap();
        record_running_self(&mut fixture.engine, intended).unwrap();
        assert!(pending_install(&fixture.engine.work).unwrap().is_some());
    }
}
