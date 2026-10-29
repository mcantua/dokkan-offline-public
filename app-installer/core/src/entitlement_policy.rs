//! Required entitlements are reconciled against the selected team's actual Apple profile.
//! No unavailable capability is stripped and no unrequested profile privilege is copied.
use plist::{Dictionary, Value};
use std::collections::BTreeSet;

const APP_ID: &str = "application-identifier";
const TEAM_ID: &str = "com.apple.developer.team-identifier";
const KEYCHAIN: &str = "keychain-access-groups";
const APP_GROUPS: &str = "com.apple.security.application-groups";

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PolicyError {
    InvalidIdentity,
    MalformedRequest,
    AppGroupUnavailable,
    SharedKeychainUnavailable,
    PushEnvironmentUnavailable,
    CloudContainerUnavailable,
    GrantUnavailable,
}
impl PolicyError {
    pub fn user_message(&self) -> &'static str {
        match self{
        Self::InvalidIdentity=>"Apple's profile does not authorize this app and developer team identity.",
        Self::MalformedRequest=>"The app's requested capabilities are malformed or cannot be reconciled safely.",
        Self::AppGroupUnavailable=>"Apple did not authorize the app's exact shared-container group IDs for this team. Required group IDs cannot be silently renamed or removed.",
        Self::SharedKeychainUnavailable=>"Apple did not authorize a required shared keychain group. A different team's hardcoded group cannot be silently replaced or removed.",
        Self::PushEnvironmentUnavailable=>"Apple's profile does not grant the app's requested push environment. Production push cannot be silently changed to development push.",
        Self::CloudContainerUnavailable=>"Apple did not grant the app's exact iCloud containers or environment. Existing cloud data and container ownership cannot be silently replaced.",
        Self::GrantUnavailable=>"Apple did not grant every required capability for this app. It was not signed, and no required capability was removed.",
    }
    }
}
fn unavailable(key: &str) -> PolicyError {
    match key {
        APP_GROUPS => PolicyError::AppGroupUnavailable,
        KEYCHAIN => PolicyError::SharedKeychainUnavailable,
        "aps-environment" => PolicyError::PushEnvironmentUnavailable,
        k if k.starts_with("com.apple.developer.icloud")
            || k.starts_with("com.apple.developer.ubiquity") =>
        {
            PolicyError::CloudContainerUnavailable
        }
        _ => PolicyError::GrantUnavailable,
    }
}
fn string_wildcards(key: &str) -> bool {
    matches!(
        key,
        APP_ID
            | KEYCHAIN
            | "com.apple.developer.associated-domains"
            | "com.apple.developer.icloud-container-identifiers"
            | "com.apple.developer.ubiquity-container-identifiers"
            | "com.apple.developer.ubiquity-kvstore-identifier"
            | "com.apple.developer.pass-type-identifiers"
    )
}
fn string_allowed(requested: &str, grant: &str, key: &str) -> bool {
    if requested == grant {
        return true;
    }
    if !string_wildcards(key) {
        return false;
    }
    // Apple's profile identity/container grant patterns are anchored namespaces, not regexes.
    // An internal/multiple wildcard has no inferred semantics and cannot widen a grant.
    if grant == "*" {
        return true;
    }
    grant
        .strip_suffix('*')
        .is_some_and(|prefix| !prefix.contains('*') && requested.starts_with(prefix))
}
fn value_allowed(requested: &Value, grant: &Value, key: &str, depth: usize) -> bool {
    if depth > 16 {
        return false;
    }
    match (requested, grant) {
        (Value::String(a), Value::String(b)) => string_allowed(a, b, key),
        (Value::Boolean(a), Value::Boolean(b)) => !*a || *b,
        (Value::Array(a), Value::Array(b)) => a.iter().all(|item| {
            b.iter()
                .any(|permitted| value_allowed(item, permitted, key, depth + 1))
        }),
        (Value::Dictionary(a), Value::Dictionary(b)) => a.iter().all(|(name, item)| {
            b.get(name)
                .is_some_and(|permitted| value_allowed(item, permitted, key, depth + 1))
        }),
        (Value::Integer(a), Value::Integer(b)) => a == b,
        (Value::Real(a), Value::Real(b)) => a.is_finite() && b.is_finite() && a == b,
        (Value::Data(a), Value::Data(b)) => a == b,
        (Value::Date(a), Value::Date(b)) => a == b,
        _ => false,
    }
}
/// Shared by the signed-output verifier: every emitted entitlement must be profile-authorized.
pub(crate) fn grants_allow(requested: &Dictionary, profile: &Dictionary) -> bool {
    requested.iter().all(|(key, value)| {
        profile
            .get(key)
            .is_some_and(|grant| value_allowed(value, grant, key, 0))
    })
}
fn strings(value: &Value) -> Result<Vec<String>, PolicyError> {
    let list = value.as_array().ok_or(PolicyError::MalformedRequest)?;
    if list.len() > 256 {
        return Err(PolicyError::MalformedRequest);
    }
    list.iter()
        .map(|v| {
            let s = v.as_string().ok_or(PolicyError::MalformedRequest)?;
            if s.is_empty() || s.len() > 1024 || s.chars().any(|c| c.is_control()) {
                return Err(PolicyError::MalformedRequest);
            }
            Ok(s.to_owned())
        })
        .collect()
}
pub fn app_groups(requested: &Dictionary) -> Result<Vec<String>, PolicyError> {
    let Some(value) = requested.get(APP_GROUPS) else {
        return Ok(vec![]);
    };
    let groups = strings(value)?;
    let mut unique = BTreeSet::new();
    for group in groups {
        if !group.starts_with("group.")
            || group.len() > 255
            || group
                .split('.')
                .any(|p| p.is_empty() || !p.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-'))
        {
            return Err(PolicyError::MalformedRequest);
        }
        unique.insert(group);
    }
    Ok(unique.into_iter().collect())
}
/// Reject malformed known capability shapes before any App-ID/certificate mutation.
/// Unknown legal plist structures remain eligible for exact server-profile authorization.
pub fn validate_requested(requested: &Dictionary) -> Result<(), PolicyError> {
    app_groups(requested)?;
    for (key, value) in requested {
        match key.as_str() {
            KEYCHAIN
            | "com.apple.developer.associated-domains"
            | "com.apple.developer.networking.networkextension"
            | "com.apple.developer.networking.vpn.api"
            | "com.apple.developer.nfc.readersession.formats"
            | "com.apple.developer.pass-type-identifiers"
            | "com.apple.developer.in-app-payments"
            | "com.apple.developer.applesignin"
            | "com.apple.developer.healthkit.access"
            | "com.apple.developer.icloud-container-identifiers"
            | "com.apple.developer.icloud-services"
            | "com.apple.developer.ubiquity-container-identifiers" => {
                strings(value)?;
            }
            "aps-environment" => {
                if !matches!(value.as_string(), Some("development") | Some("production")) {
                    return Err(PolicyError::MalformedRequest);
                }
            }
            "get-task-allow"
            | "inter-app-audio"
            | "com.apple.developer.game-center"
            | "com.apple.developer.healthkit"
            | "com.apple.developer.homekit"
            | "com.apple.developer.networking.HotspotConfiguration"
            | "com.apple.developer.authentication-services.autofill-credential-provider"
            | "com.apple.developer.networking.multipath"
            | "com.apple.developer.siri"
            | "com.apple.external-accessory.wireless-configuration"
            | "com.apple.developer.kernel.increased-memory-limit"
            | "com.apple.developer.kernel.increased-debugging-memory-limit"
            | "com.apple.developer.kernel.extended-virtual-addressing" => {
                if value.as_boolean().is_none() {
                    return Err(PolicyError::MalformedRequest);
                }
            }
            _ => {}
        }
    }
    Ok(())
}
/// Feature key facts are pinned in downloads/fastlane-capability-reference/SOURCE.md.
/// These are capability requests, never proof of availability: the returned profile is decisive.
pub fn feature_requests(requested: &Dictionary) -> Dictionary {
    let mut features = Dictionary::new();
    for (key, value) in requested {
        let enabled = match value {
            Value::Boolean(v) => *v,
            Value::Array(v) => !v.is_empty(),
            Value::String(v) => !v.is_empty(),
            _ => true,
        };
        if !enabled {
            continue;
        }
        if key == "com.apple.developer.default-data-protection" {
            let setting = match value.as_string() {
                Some("NSFileProtectionComplete") => Some("complete"),
                Some("NSFileProtectionCompleteUnlessOpen") => Some("unlessopen"),
                Some("NSFileProtectionCompleteUntilFirstUserAuthentication") => {
                    Some("untilfirstauth")
                }
                Some("NSFileProtectionNone") => Some(""),
                _ => None,
            };
            if let Some(setting) = setting {
                features.insert("dataProtection".into(), Value::String(setting.into()));
            }
            continue;
        }
        let feature = match key.as_str() {
            APP_GROUPS => Some("APG3427HIY"),
            "inter-app-audio" => Some("IAD53UNK2F"),
            "com.apple.developer.game-center" => Some("gameCenter"),
            "com.apple.developer.associated-domains" => Some("SKC3T5S89Y"),
            "com.apple.developer.healthkit" | "com.apple.developer.healthkit.access" => {
                Some("HK421J6T7P")
            }
            "com.apple.developer.homekit" => Some("homeKit"),
            "com.apple.developer.networking.HotspotConfiguration" => Some("HSC639VEI8"),
            "com.apple.developer.ClassKit-environment" => Some("PKTJAN2017"),
            "com.apple.developer.authentication-services.autofill-credential-provider" => {
                Some("CPEQ28MX4E")
            }
            "com.apple.developer.networking.multipath" => Some("MP49FN762P"),
            "com.apple.developer.networking.networkextension" => Some("NWEXT04537"),
            "com.apple.developer.nfc.readersession.formats" => Some("NFCTRMAY17"),
            "com.apple.developer.networking.vpn.api" => Some("V66P55NK2I"),
            "com.apple.developer.pass-type-identifiers" => Some("passbook"),
            "com.apple.developer.siri" => Some("SI015DKUHP"),
            "com.apple.external-accessory.wireless-configuration" => Some("WC421J6T7P"),
            // Push uses a separate portal operation in the public reference, not a guessed
            // updateAppId boolean. Existing actual profiles can still authorize it below.
            "aps-environment" => None,
            // Containers/merchant IDs require binding their exact registered resources.
            k if k.starts_with("com.apple.developer.icloud")
                || k.starts_with("com.apple.developer.ubiquity") =>
            {
                None
            }
            "com.apple.developer.in-app-payments" => None,
            _ => None,
        };
        if let Some(feature) = feature {
            features.insert(feature.into(), Value::Boolean(true));
        }
    }
    features
}
pub fn memory_capabilities(requested: &Dictionary) -> Vec<&'static str> {
    [
        (
            "com.apple.developer.kernel.increased-memory-limit",
            "INCREASED_MEMORY_LIMIT",
        ),
        (
            "com.apple.developer.kernel.increased-debugging-memory-limit",
            "INCREASED_MEMORY_LIMIT_DEBUGGING",
        ),
        (
            "com.apple.developer.kernel.extended-virtual-addressing",
            "EXTENDED_VIRTUAL_ADDRESSING",
        ),
    ]
    .into_iter()
    .filter_map(|(key, value)| {
        (requested.get(key).and_then(Value::as_boolean) == Some(true)).then_some(value)
    })
    .collect()
}
/// Regenerate signing identity/default keychain access, preserve every required feature grant.
/// Custom/shared groups and container/domain/service identifiers retain their exact values.
pub fn reconcile(
    requested: &Dictionary,
    original_bundle_id: &str,
    signed_bundle_id: &str,
    team_id: &str,
    profile: &Dictionary,
) -> Result<Dictionary, PolicyError> {
    validate_requested(requested)?;
    let granted_app = profile
        .get(APP_ID)
        .and_then(Value::as_string)
        .ok_or(PolicyError::InvalidIdentity)?;
    let (prefix, _) = granted_app
        .split_once('.')
        .ok_or(PolicyError::InvalidIdentity)?;
    if prefix.is_empty() || prefix.contains('*') {
        return Err(PolicyError::InvalidIdentity);
    }
    let signed_app = format!("{prefix}.{signed_bundle_id}");
    if !string_allowed(&signed_app, granted_app, APP_ID) {
        return Err(PolicyError::InvalidIdentity);
    }
    let mut signed = Dictionary::new();
    signed.insert(APP_ID.into(), Value::String(signed_app.clone()));
    match profile.get(TEAM_ID) {
        Some(Value::String(granted)) if granted == team_id => {
            signed.insert(TEAM_ID.into(), Value::String(team_id.into()));
        }
        None if !requested.contains_key(TEAM_ID) => {}
        _ => return Err(PolicyError::InvalidIdentity),
    }
    let old_app = requested.get(APP_ID).and_then(Value::as_string);
    if old_app.is_some_and(|id| !id.ends_with(&format!(".{original_bundle_id}"))) {
        return Err(PolicyError::MalformedRequest);
    }
    for (key, value) in requested {
        if key == APP_ID || key == TEAM_ID {
            continue;
        }
        let candidate = if key == KEYCHAIN {
            let groups = strings(value)?;
            Value::Array(
                groups
                    .into_iter()
                    .map(|group| {
                        // Only the bundle's own default group follows its regenerated identity.
                        // A custom group (including a shared group's hardcoded prefix) is unchanged.
                        Value::String(if old_app == Some(group.as_str()) {
                            signed_app.clone()
                        } else {
                            group
                        })
                    })
                    .collect(),
            )
        } else {
            value.clone()
        };
        let grant = profile.get(key).ok_or_else(|| unavailable(key))?;
        if !value_allowed(&candidate, grant, key, 0) {
            return Err(unavailable(key));
        }
        signed.insert(key.clone(), candidate);
    }
    // A default, app-private keychain group is part of regenerated app identity. Never add
    // all wildcard profile groups or another app's shared group merely because permitted.
    if !signed.contains_key(KEYCHAIN) {
        if let Some(grant) = profile.get(KEYCHAIN) {
            let own = Value::Array(vec![Value::String(signed_app)]);
            if value_allowed(&own, grant, KEYCHAIN, 0) {
                signed.insert(KEYCHAIN.into(), own);
            } else {
                return Err(PolicyError::SharedKeychainUnavailable);
            }
        }
    }
    if !grants_allow(&signed, profile) {
        return Err(PolicyError::GrantUnavailable);
    }
    Ok(signed)
}

#[cfg(test)]
mod tests {
    use super::*;
    fn profile() -> Dictionary {
        let mut p = Dictionary::new();
        p.insert(APP_ID.into(), Value::String("NEWTEAM.*".into()));
        p.insert(TEAM_ID.into(), Value::String("NEWTEAM".into()));
        p.insert(
            KEYCHAIN.into(),
            Value::Array(vec![Value::String("NEWTEAM.*".into())]),
        );
        p
    }
    #[test]
    fn required_grants_preserved_and_unused_profile_privileges_not_copied() {
        let mut requested = Dictionary::new();
        requested.insert(
            APP_ID.into(),
            Value::String("OLDTEAM.com.original.app".into()),
        );
        requested.insert(TEAM_ID.into(), Value::String("OLDTEAM".into()));
        requested.insert(
            KEYCHAIN.into(),
            Value::Array(vec![Value::String("OLDTEAM.com.original.app".into())]),
        );
        requested.insert(
            "com.apple.developer.associated-domains".into(),
            Value::Array(vec![Value::String("applinks:example.test".into())]),
        );
        requested.insert("com.apple.developer.healthkit".into(), Value::Boolean(true));
        let mut p = profile();
        p.insert(
            "com.apple.developer.associated-domains".into(),
            Value::Array(vec![Value::String("*".into())]),
        );
        p.insert("com.apple.developer.healthkit".into(), Value::Boolean(true));
        p.insert(
            "com.apple.developer.networking.networkextension".into(),
            Value::Array(vec![Value::String("packet-tunnel-provider".into())]),
        );
        assert!(validate_requested(&requested).is_ok());
        let signed = reconcile(
            &requested,
            "com.original.app",
            "org.tin.mapped",
            "NEWTEAM",
            &p,
        )
        .unwrap();
        assert_eq!(signed[APP_ID].as_string(), Some("NEWTEAM.org.tin.mapped"));
        assert_eq!(
            signed["com.apple.developer.associated-domains"],
            requested["com.apple.developer.associated-domains"]
        );
        assert!(!signed.contains_key("com.apple.developer.networking.networkextension"));
        assert!(grants_allow(&signed, &p));
        let mut malformed = requested.clone();
        malformed.insert(
            "com.apple.developer.healthkit".into(),
            Value::String("true".into()),
        );
        assert_eq!(
            validate_requested(&malformed),
            Err(PolicyError::MalformedRequest)
        );
        p.remove("com.apple.developer.healthkit");
        assert_eq!(
            reconcile(
                &requested,
                "com.original.app",
                "org.tin.mapped",
                "NEWTEAM",
                &p
            ),
            Err(PolicyError::GrantUnavailable)
        );
    }
    #[test]
    fn groups_push_cloud_and_nested_profile_values_cannot_be_widened_or_silently_remapped() {
        let mut p = profile();
        let mut requested = Dictionary::new();
        requested.insert(
            APP_GROUPS.into(),
            Value::Array(vec![Value::String("group.owner.shared".into())]),
        );
        p.insert(APP_GROUPS.into(), requested[APP_GROUPS].clone());
        let signed = reconcile(&requested, "com.app", "org.tin.mapped", "NEWTEAM", &p).unwrap();
        assert_eq!(signed[APP_GROUPS], requested[APP_GROUPS]);
        assert_eq!(app_groups(&requested).unwrap(), vec!["group.owner.shared"]);
        requested.insert(
            KEYCHAIN.into(),
            Value::Array(vec![Value::String("OLDTEAM.hardcoded.shared".into())]),
        );
        assert_eq!(
            reconcile(&requested, "com.app", "org.tin.mapped", "NEWTEAM", &p),
            Err(PolicyError::SharedKeychainUnavailable)
        );
        requested.remove(KEYCHAIN);
        requested.insert("aps-environment".into(), Value::String("production".into()));
        p.insert(
            "aps-environment".into(),
            Value::String("development".into()),
        );
        assert_eq!(
            reconcile(&requested, "com.app", "org.tin.mapped", "NEWTEAM", &p),
            Err(PolicyError::PushEnvironmentUnavailable)
        );
        requested.remove("aps-environment");
        let mut nested = Dictionary::new();
        nested.insert(
            "allowed".into(),
            Value::Array(vec![Value::String("one".into())]),
        );
        p.insert(
            "vendor.structured-grant".into(),
            Value::Dictionary(nested.clone()),
        );
        requested.insert(
            "vendor.structured-grant".into(),
            Value::Dictionary(nested.clone()),
        );
        assert!(grants_allow(&requested, &p));
        nested.insert(
            "allowed".into(),
            Value::Array(vec![Value::String("two".into())]),
        );
        requested.insert("vendor.structured-grant".into(), Value::Dictionary(nested));
        assert!(!grants_allow(&requested, &p));
    }
}
