//! Durable intent log for only this installer's uniquely named AFC staging directories.
//! Contains paths only, never credentials/pairing/signing data. No broad directory cleanup.
use idevice::{afc::AfcClient, provider::TcpProvider, IdeviceService};
use rootcause::prelude::*;
use std::{
    collections::HashSet,
    fs::{self, OpenOptions},
    io::Write,
    path::Path,
};
const PREFIX: &str = "PublicStaging/AI-org.tin.appinstaller-";
const MAX_INTENTS: usize = 256;
fn valid(path: &str) -> bool {
    path.strip_prefix(PREFIX)
        .and_then(|s| s.strip_suffix(".app"))
        .is_some_and(|token| {
            token.len() == 32
                && token
                    .bytes()
                    .all(|b| b.is_ascii_hexdigit() && !b.is_ascii_uppercase())
        })
}
fn load(work: &Path) -> Result<Vec<String>, Report> {
    let path = work.join("device-cleanups.json");
    let metadata = match fs::symlink_metadata(&path) {
        Ok(m) => m,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(vec![]),
        Err(e) => return Err(e.into()),
    };
    if !metadata.file_type().is_file() || metadata.len() > 64 * 1024 {
        return Err(report!("Invalid cleanup intent log").into());
    }
    let mut paths: Vec<String> = serde_json::from_slice(&fs::read(path)?)?;
    if paths.len() > MAX_INTENTS || paths.iter().any(|p| !valid(p)) {
        return Err(report!("Invalid cleanup intent paths").into());
    }
    // A repeated durable record must not trigger multiple deletion attempts against
    // one directory using the same stale AFC listing.
    let mut seen = HashSet::new();
    paths.retain(|path| seen.insert(path.clone()));
    Ok(paths)
}
fn save(work: &Path, paths: &[String]) -> Result<(), Report> {
    let temp = work.join("device-cleanups.json.pending");
    if fs::symlink_metadata(&temp).is_ok_and(|m| !m.file_type().is_file()) {
        return Err(report!("Invalid cleanup pending file").into());
    }
    let mut options = OpenOptions::new();
    options.create(true).write(true).truncate(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    let mut file = options.open(&temp)?;
    file.write_all(&serde_json::to_vec(paths)?)?;
    file.sync_all()?;
    fs::rename(&temp, work.join("device-cleanups.json"))?;
    Ok(())
}
/// Persist and fsync BEFORE upload. Names cannot contain arbitrary original archive components.
pub fn remember(work: &Path, basename: &str) -> Result<(), Report> {
    let path = format!("PublicStaging/{basename}");
    if !valid(&path) {
        return Err(report!("Invalid owned staging name").into());
    }
    let mut paths = load(work)?;
    if !paths.contains(&path) {
        if paths.len() >= MAX_INTENTS {
            return Err(report!("Too many pending device cleanups").into());
        }
        paths.push(path);
        save(work, &paths)?;
    }
    Ok(())
}

// The same retry loop serves real AFC and deterministic offline tests. No mock
// socket, phone, or account connection is needed to verify ownership/cancellation.
trait StagingDevice {
    async fn staging_names(&mut self) -> Result<Vec<String>, ()>;
    async fn remove_owned(&mut self, path: &str) -> Result<(), ()>;
}
impl StagingDevice for AfcClient {
    async fn staging_names(&mut self) -> Result<Vec<String>, ()> {
        self.list_dir("PublicStaging").await.map_err(|_| ())
    }
    async fn remove_owned(&mut self, path: &str) -> Result<(), ()> {
        self.remove_all(path.to_owned()).await.map_err(|_| ())
    }
}
async fn retry_paths(
    work: &Path,
    paths: Vec<String>,
    device: &mut impl StagingDevice,
) -> Result<(), Report> {
    let names = match device.staging_names().await {
        Ok(v) => v,
        Err(_) => return Ok(()),
    };
    let mut remaining = Vec::new();
    for path in &paths {
        // Recheck every name at deletion, even though parsing already validated it.
        if !valid(path) {
            return Err(report!("Invalid owned staging path").into());
        }
        let basename = path
            .strip_prefix("PublicStaging/")
            .ok_or_else(|| report!("Invalid staging prefix"))?;
        if names.iter().any(|n| n == basename) && device.remove_owned(path).await.is_err() {
            remaining.push(path.clone());
        }
    }
    // Commit removals only after every awaited attempt returns. Dropping this
    // future (cancellation/crash) leaves the previous durable intent log intact.
    if remaining != paths {
        save(work, &remaining)?;
    }
    Ok(())
}
/// Retry on each authorized device connection, including after crash/cancellation.
/// Failed removals remain in the log. An observed missing owned directory also completes intent.
pub async fn retry(work: &Path, provider: &TcpProvider) -> Result<(), Report> {
    let paths = load(work)?;
    if paths.is_empty() {
        return Ok(());
    }
    let mut client = match AfcClient::connect(provider).await {
        Ok(c) => c,
        Err(_) => return Ok(()),
    };
    retry_paths(work, paths, &mut client).await
}
/// Same owned-only durable retry loop over an authenticated Remote Pairing RSD tunnel.
pub async fn retry_rsd(
    work: &Path,
    provider: &mut impl idevice::provider::RsdProvider,
    handshake: &mut idevice::rsd::RsdHandshake,
) -> Result<(), Report> {
    use idevice::RsdService;
    let paths = load(work)?;
    if paths.is_empty() {
        return Ok(());
    }
    let mut client = match AfcClient::connect_rsd(provider, handshake).await {
        Ok(client) => client,
        Err(_) => return Ok(()),
    };
    retry_paths(work, paths, &mut client).await
}
pub fn unique_basename(sequence: u64) -> String {
    let time = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    let token = ((std::process::id() as u128) << 96)
        | ((time & u64::MAX as u128) << 32)
        | (sequence as u32 as u128);
    format!("AI-org.tin.appinstaller-{token:032x}.app")
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{
        future::Future,
        path::PathBuf,
        sync::Arc,
        task::{Context, Poll, Wake, Waker},
    };
    struct Work(PathBuf);
    impl Work {
        fn new(label: &str) -> Self {
            let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
                .join("target/cleanup-tests")
                .join(format!(
                    "{label}-{}-{}",
                    std::process::id(),
                    std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap()
                        .as_nanos()
                ));
            fs::create_dir_all(&path).unwrap();
            Self(path)
        }
        fn path(&self) -> &Path {
            &self.0
        }
    }
    impl Drop for Work {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
            if let Some(parent) = self.0.parent() {
                let _ = fs::remove_dir(parent);
            }
        }
    }
    #[derive(Default)]
    struct FakeAfc {
        names: Vec<String>,
        attempts: Vec<String>,
        fail_remove: bool,
        fail_list: bool,
        pending_remove: bool,
        list_calls: usize,
    }
    impl StagingDevice for FakeAfc {
        async fn staging_names(&mut self) -> Result<Vec<String>, ()> {
            self.list_calls += 1;
            if self.fail_list {
                Err(())
            } else {
                Ok(self.names.clone())
            }
        }
        async fn remove_owned(&mut self, path: &str) -> Result<(), ()> {
            self.attempts.push(path.to_owned());
            if self.pending_remove {
                std::future::pending::<()>().await;
            }
            if self.fail_remove {
                return Err(());
            }
            let basename = path.strip_prefix("PublicStaging/").unwrap();
            self.names.retain(|n| n != basename);
            Ok(())
        }
    }
    async fn offline_retry(work: &Path, device: &mut FakeAfc) -> Result<(), Report> {
        let paths = load(work)?;
        if paths.is_empty() {
            return Ok(());
        }
        retry_paths(work, paths, device).await
    }
    fn basename(index: usize) -> String {
        format!("AI-org.tin.appinstaller-{index:032x}.app")
    }
    fn run(future: impl Future<Output = ()>) {
        tokio::runtime::Builder::new_current_thread()
            .build()
            .unwrap()
            .block_on(future)
    }
    struct NoWake;
    impl Wake for NoWake {
        fn wake(self: Arc<Self>) {}
    }

    #[test]
    fn failed_and_cancelled_upload_intents_survive_success_or_absence_clears() {
        run(async {
            let work = Work::new("retry-lifecycle");
            let name = basename(1);
            let path = format!("PublicStaging/{name}");
            remember(work.path(), &name).unwrap();
            let mut device = FakeAfc {
                names: vec![name.clone()],
                fail_remove: true,
                ..Default::default()
            };
            offline_retry(work.path(), &mut device).await.unwrap();
            assert_eq!(
                load(work.path()).unwrap(),
                vec![path.clone()],
                "failed AFC removal must retain a durable upload intent"
            );
            assert_eq!(device.attempts, vec![path.clone()]);
            device.fail_remove = false;
            device.pending_remove = true;
            device.attempts.clear();
            let mut retry = Box::pin(offline_retry(work.path(), &mut device));
            let waker = Waker::from(Arc::new(NoWake));
            let mut context = Context::from_waker(&waker);
            assert!(matches!(retry.as_mut().poll(&mut context), Poll::Pending));
            drop(retry);
            assert_eq!(
                load(work.path()).unwrap(),
                vec![path.clone()],
                "cancellation before AFC completion must preserve intent for the next connection"
            );
            assert_eq!(device.attempts, vec![path.clone()]);
            device.pending_remove = false;
            device.attempts.clear();
            offline_retry(work.path(), &mut device).await.unwrap();
            assert!(load(work.path()).unwrap().is_empty());
            assert_eq!(device.attempts, vec![path.clone()]);
            remember(work.path(), &name).unwrap();
            device.attempts.clear();
            offline_retry(work.path(), &mut device).await.unwrap();
            assert!(
                load(work.path()).unwrap().is_empty(),
                "observed absent directory completes a stale upload intent"
            );
            assert!(device.attempts.is_empty());
            remember(work.path(), &name).unwrap();
            device.fail_list = true;
            offline_retry(work.path(), &mut device).await.unwrap();
            assert_eq!(
                load(work.path()).unwrap(),
                vec![path],
                "failed AFC listing must not imply absence"
            );
        });
    }

    #[test]
    fn foreign_paths_never_removed_and_duplicate_intents_are_bounded() {
        run(async {
            let work = Work::new("ownership");
            let name = basename(7);
            let owned = format!("PublicStaging/{name}");
            let foreign=["PublicStaging", "PublicStaging/OtherInstaller.app", "PublicStaging/AI-org.tin.appinstaller-0000000000000000000000000000000A.app", "PublicStaging/AI-org.tin.appinstaller-00000000000000000000000000000000.app/../Foreign.app", "/PublicStaging/AI-org.tin.appinstaller-00000000000000000000000000000000.app", "PublicStaging/AI-other-installer-00000000000000000000000000000000.app"];
            let mut device = FakeAfc {
                names: vec![name.clone(), "OtherInstaller.app".into()],
                ..Default::default()
            };
            for invalid in foreign {
                fs::write(
                    work.path().join("device-cleanups.json"),
                    serde_json::to_vec(&vec![owned.clone(), invalid.to_owned()]).unwrap(),
                )
                .unwrap();
                assert!(offline_retry(work.path(), &mut device).await.is_err());
                assert!(device.attempts.is_empty());
                assert_eq!(
                    device.list_calls, 0,
                    "invalid log must fail before any AFC work"
                );
            }
            save(work.path(), &[]).unwrap();
            assert!(remember(work.path(), "OtherInstaller.app").is_err());
            for _ in 0..MAX_INTENTS + 10 {
                remember(work.path(), &name).unwrap();
            }
            assert_eq!(
                load(work.path()).unwrap(),
                vec![owned.clone()],
                "remember is idempotent for a repeated upload intent"
            );
            fs::write(
                work.path().join("device-cleanups.json"),
                serde_json::to_vec(&vec![owned.clone(); MAX_INTENTS]).unwrap(),
            )
            .unwrap();
            offline_retry(work.path(), &mut device).await.unwrap();
            assert_eq!(
                device.attempts,
                vec![owned],
                "duplicate durable entries must not repeat deletion against a stale listing"
            );
            assert!(load(work.path()).unwrap().is_empty());
            for index in 0..MAX_INTENTS {
                remember(work.path(), &basename(index)).unwrap();
            }
            assert_eq!(load(work.path()).unwrap().len(), MAX_INTENTS);
            assert!(remember(work.path(), &basename(MAX_INTENTS)).is_err());
            assert_eq!(
                load(work.path()).unwrap().len(),
                MAX_INTENTS,
                "overflow must retain the previous bounded log"
            );
        });
    }
}
