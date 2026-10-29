//! A dedicated integration-test process: library unit/TLS tests cannot initialize
//! Rustls's process-global provider before this first-account transport regression.
use app_installer_core::{ai_initialize, Status};
use isideload::{anisette::remote_v3::RemoteV3AnisetteProvider, util::storage::InMemoryStorage};
use std::{ffi::CString, path::PathBuf};

struct Work(PathBuf);
impl Drop for Work {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
        if let Some(parent) = self.0.parent() {
            let _ = std::fs::remove_dir(parent);
        }
    }
}

#[test]
fn first_account_http_transport_builds_in_a_fresh_process_without_network() {
    assert!(rustls::crypto::CryptoProvider::get_default().is_none());
    let work = Work(
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("target/first-account-transport")
            .join(std::process::id().to_string()),
    );
    std::fs::create_dir_all(&work.0).unwrap();
    let work_path = CString::new(work.0.canonicalize().unwrap().to_str().unwrap()).unwrap();
    assert_eq!(ai_initialize(work_path.as_ptr()), Status::Ok);
    // This is the real first constructor used by account_builder, not another HTTP
    // stack. new() only constructs its Reqwest client; no send/provision/account call.
    // Before the fix, it panics because rustls-no-provider has no explicit default.
    let provider = RemoteV3AnisetteProvider::new(
        "https://example.invalid",
        Box::new(InMemoryStorage::new()),
        "0".into(),
    )
    .expect("first-account transport construction must not abort");
    drop(provider);
    assert!(rustls::crypto::CryptoProvider::get_default().is_some());
    assert_eq!(ai_initialize(work_path.as_ptr()), Status::Ok);
}
