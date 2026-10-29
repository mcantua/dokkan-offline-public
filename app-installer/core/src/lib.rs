//! Native C API, offline policy and pinned Apple/device engine.
pub mod archive;
mod capabilities;
mod cleanup;
mod engine;
mod install_journal;
pub(crate) mod entitlement_policy;
pub(crate) mod signed_verification;
mod identity;
use std::ffi::c_char;

#[repr(i32)]
#[derive(Debug, PartialEq, Eq)]
pub enum Status {
    Ok = 0,
    NotReady = 1,
    AppLimit = 2,
    AppIdLimit = 3,
    UnknownUsage = 4,
    InvalidArgument = 5,
    Busy = 6,
    StorageLocked = 7,
}

/// active_count includes the installer; updates do not consume another app slot.
/// App-ID usage must come from Apple's current response, including extensions.
pub fn preflight(
    paid: bool,
    active_count: Option<u32>,
    updating: bool,
    ids_available: Option<u32>,
    ids_needed: u32,
) -> Status {
    if paid {
        return Status::Ok;
    }
    let (Some(active), Some(available)) = (active_count, ids_available) else {
        return Status::UnknownUsage;
    };
    if !updating && active >= 3 {
        return Status::AppLimit;
    }
    if ids_needed > available {
        return Status::AppIdLimit;
    }
    Status::Ok
}

/// Uses the actual provisioning expiry, never a fixed paid-account duration.
pub fn needs_warning(expiry: i64, now: i64) -> bool {
    expiry.saturating_sub(now) <= 2 * 24 * 60 * 60
}

#[no_mangle]
pub extern "C" fn ai_backend_ready() -> bool {
    true
}
#[no_mangle]
pub extern "C" fn ai_status_message() -> *const c_char {
    b"Sign in, import pairing and enable LocalDevVPN to continue.\0"
        .as_ptr()
        .cast()
}
#[no_mangle]
pub extern "C" fn ai_register_self_bundle(path: *const c_char) -> Status {
    engine::register_self_bundle(path)
}
#[no_mangle]
pub extern "C" fn ai_initialize(path: *const c_char) -> Status {
    engine::initialize(path)
}
#[no_mangle]
pub extern "C" fn ai_login(email: *const c_char, password: *const c_char) -> Status {
    engine::login(email, password)
}
#[no_mangle]
pub extern "C" fn ai_restore_session() -> Status {
    engine::restore()
}
#[no_mangle]
pub extern "C" fn ai_submit_2fa(code: *const c_char) -> Status {
    engine::submit_code(code)
}
#[no_mangle]
pub extern "C" fn ai_select_team(team: *const c_char) -> Status {
    engine::select_team(team)
}
#[no_mangle]
pub extern "C" fn ai_lock() {
    engine::lock()
}
#[no_mangle]
pub extern "C" fn ai_request_2fa(action: i32, number_id: u32) -> Status {
    engine::request_2fa(action, number_id)
}
#[no_mangle]
pub extern "C" fn ai_resend_2fa() -> Status {
    engine::resend()
}
#[no_mangle]
pub extern "C" fn ai_import_pairing(data: *const u8, length: usize) -> Status {
    engine::import_pairing(data, length)
}
#[no_mangle]
pub extern "C" fn ai_set_device_host(host: *const c_char) -> Status {
    engine::set_host(host)
}
#[no_mangle]
pub extern "C" fn ai_set_remote_pairing_port(port: u16) -> Status {
    engine::set_remote_pairing_port(port)
}
#[no_mangle]
pub extern "C" fn ai_pairing_kind() -> i32 {
    engine::pairing_kind()
}
#[no_mangle]
pub extern "C" fn ai_match_remote_pairing_service(identifier: *const c_char, auth_tag: *const c_char) -> bool {
    engine::match_remote_pairing_service(identifier, auth_tag)
}
#[no_mangle]
pub extern "C" fn ai_sign_ipa(path: *const c_char) -> Status {
    engine::sign_ipa(path)
}
#[no_mangle]
pub extern "C" fn ai_install_ipa(path: *const c_char) -> Status {
    engine::install_ipa(path)
}
#[no_mangle]
pub extern "C" fn ai_list_installed() -> Status {
    engine::list_installed()
}
#[no_mangle]
pub extern "C" fn ai_refresh_all() -> Status {
    engine::refresh_all()
}
#[no_mangle]
pub extern "C" fn ai_cancel() {
    let _ = engine::cancel();
}
#[no_mangle]
pub extern "C" fn ai_sign_out() -> Status {
    engine::sign_out()
}
#[no_mangle]
pub extern "C" fn ai_poll_event_json() -> *mut c_char {
    engine::poll()
}
#[no_mangle]
pub extern "C" fn ai_snapshot_json() -> *mut c_char {
    engine::snapshot_json()
}
#[no_mangle]
pub unsafe extern "C" fn ai_free_string(ptr: *mut c_char) {
    unsafe { engine::free_string(ptr) }
}
#[no_mangle]
pub extern "C" fn ai_needs_warning(expiry: i64, now: i64) -> bool {
    needs_warning(expiry, now)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn free_account_preflight_covers_updates_extensions_and_unknown_usage() {
        assert_eq!(
            preflight(false, Some(3), false, Some(10), 1),
            Status::AppLimit
        );
        assert_eq!(preflight(false, Some(3), true, Some(0), 0), Status::Ok);
        assert_eq!(
            preflight(false, Some(2), false, Some(1), 2),
            Status::AppIdLimit
        );
        assert_eq!(
            preflight(false, None, false, Some(10), 1),
            Status::UnknownUsage
        );
        assert_eq!(preflight(true, None, false, None, 20), Status::Ok);
    }
    #[test]
    fn expiry_boundary_expired_and_extreme_values() {
        let now = 1_800_000_000;
        assert!(!needs_warning(now + 172_801, now));
        assert!(needs_warning(now + 172_800, now));
        assert!(needs_warning(now - 1, now));
        // Refresh deadline covers the entire installed app, including an earlier extension.
        let main_expiry=now+5*24*60*60;
        let extension_expiry=now+24*60*60;
        assert!(!needs_warning(main_expiry,now));
        assert!(needs_warning(super::engine::earliest_profile_expiry(main_expiry,[extension_expiry]),now));

        assert!(!needs_warning(i64::MAX, i64::MIN));
        assert!(needs_warning(i64::MIN, i64::MAX));
    }
}
