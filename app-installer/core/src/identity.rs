//! Stable source-to-signing identities. Raw third-party bundle IDs are not globally claimable.
//! A selected developer team and canonical source ID deterministically choose one installed ID.
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashSet;

pub const INSTALLER_ORIGINAL_ID: &str = "org.tin.appinstaller";
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct ExtensionIdentity {
    pub original_bundle_id: String,
    pub signed_bundle_id: String,
}
pub struct ExistingIdentity<'a> {
    pub original: &'a str,
    pub signed: &'a str,
    pub team: &'a str,
    pub extensions: &'a [ExtensionIdentity],
    pub is_self: bool,
    pub installed: bool,
}
#[derive(Debug, PartialEq, Eq)]
pub enum IdentityError {
    InvalidIdentifier,
    InvalidExtension,
    ConflictingRecord,
    OtherTeamInstalled,
}
#[derive(Debug)]
pub struct IdentityPlan {
    pub original_bundle_id: String,
    pub signed_bundle_id: String,
    pub extensions: Vec<ExtensionIdentity>,
    pub extension_rewrites: Vec<(String, String)>,
    pub is_self: bool,
}
fn same(a: &str, b: &str) -> bool {
    a.eq_ignore_ascii_case(b)
}
fn valid(id: &str) -> bool {
    !id.is_empty()
        && id.len() <= 255
        && id.split('.').all(|part| {
            !part.is_empty() && part.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-')
        })
}
fn hash(input: &str) -> String {
    let digest = Sha256::digest(input.to_ascii_lowercase().as_bytes());
    let mut out = String::with_capacity(32);
    for byte in &digest[..16] {
        out.push_str(&format!("{byte:02x}"));
    }
    out
}
fn effective_original<'a>(record: &'a ExistingIdentity<'_>) -> &'a str {
    if record.original.is_empty() {
        record.signed
    } else {
        record.original
    }
}
/// Existing installed identity wins for same-team updates, including legacy records.
/// Switching team while the old app remains installed fails before another identity is created.
pub fn plan(
    input: &str,
    input_extensions: &[String],
    team: &str,
    records: &[ExistingIdentity<'_>],
    own_id: Option<&str>,
) -> Result<IdentityPlan, IdentityError> {
    if !valid(input)
        || team.is_empty()
        || team.len() > 128
        || !team.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-')
    {
        return Err(IdentityError::InvalidIdentifier);
    }
    let matching = records
        .iter()
        .filter(|r| same(effective_original(r), input) || same(r.signed, input))
        .collect::<Vec<_>>();
    let canonical = matching
        .first()
        .map(|r| effective_original(r))
        .unwrap_or(input);
    if matching
        .iter()
        .any(|r| !same(effective_original(r), canonical))
    {
        return Err(IdentityError::ConflictingRecord);
    }
    let self_record = matching.iter().find(|r| r.is_self).copied();
    let is_self = self_record.is_some()
        || own_id.is_some_and(|own| same(own, input) || same(INSTALLER_ORIGINAL_ID, input));
    if !is_self
        && matching
            .iter()
            .any(|r| !r.team.is_empty() && !same(r.team, team) && r.installed)
    {
        return Err(IdentityError::OtherTeamInstalled);
    }
    let reusable = matching
        .iter()
        .find(|r| r.team.is_empty() || same(r.team, team))
        .copied();
    if let Some(prior) = reusable {
        if matching
            .iter()
            .filter(|r| r.team.is_empty() || same(r.team, team))
            .any(|r| !same(r.signed, prior.signed))
        {
            return Err(IdentityError::ConflictingRecord);
        }
    }
    let original = if is_self {
        INSTALLER_ORIGINAL_ID
    } else {
        canonical
    };
    let signed = if is_self {
        own_id
            .or_else(|| self_record.map(|r| r.signed))
            .ok_or(IdentityError::ConflictingRecord)?
            .to_owned()
    } else if let Some(prior) = reusable {
        prior.signed.to_owned()
    } else {
        format!("org.tin.sideload.t{}.a{}", hash(team), hash(original))
    };
    if !valid(&signed) {
        return Err(IdentityError::InvalidIdentifier);
    }
    let mut extensions = vec![];
    let mut rewrites = vec![];
    let mut signed_ids = HashSet::from([signed.to_ascii_lowercase()]);
    for ext in input_extensions {
        if !valid(ext)
            || !ext
                .strip_prefix(input)
                .is_some_and(|suffix| suffix.starts_with('.') && suffix.len() > 1)
        {
            return Err(IdentityError::InvalidExtension);
        }
        let known = matching
            .iter()
            .flat_map(|r| r.extensions.iter())
            .find(|m| same(&m.original_bundle_id, ext) || same(&m.signed_bundle_id, ext));
        let original_ext = known.map(|m| m.original_bundle_id.as_str()).unwrap_or(ext);
        let retained = reusable.and_then(|r| {
            r.extensions.iter().find(|m| {
                same(&m.original_bundle_id, original_ext) || same(&m.signed_bundle_id, ext)
            })
        });
        let signed_ext = retained
            .map(|m| m.signed_bundle_id.clone())
            .unwrap_or_else(|| format!("{signed}.e{}", hash(original_ext)));
        if !valid(&signed_ext)
            || !signed_ext.starts_with(&format!("{signed}."))
            || !signed_ids.insert(signed_ext.to_ascii_lowercase())
        {
            return Err(IdentityError::ConflictingRecord);
        }
        extensions.push(ExtensionIdentity {
            original_bundle_id: original_ext.to_owned(),
            signed_bundle_id: signed_ext.clone(),
        });
        rewrites.push((ext.clone(), signed_ext));
    }
    Ok(IdentityPlan {
        original_bundle_id: original.to_owned(),
        signed_bundle_id: signed,
        extensions,
        extension_rewrites: rewrites,
        is_self,
    })
}

pub struct AdoptedIdentity {
    pub signed: String,
    pub extensions: Vec<ExtensionIdentity>,
}
/// Adopt a direct/common legacy installed ID only with matching selected-team ownership.
/// An occupied identity never silently causes a second app to be created.
pub fn adopt_external(
    input: &str,
    extensions: &[String],
    team: &str,
    installed: &[String],
    owned: &[String],
) -> Result<Option<AdoptedIdentity>, IdentityError> {
    let alternate = format!("{input}.{team}");
    let candidates = installed
        .iter()
        .filter(|id| same(id, input) || same(id, &alternate))
        .collect::<Vec<_>>();
    if candidates.len() > 1 {
        return Err(IdentityError::ConflictingRecord);
    }
    // Prefer an observed installed identity. Otherwise preserve a source App ID already
    // owned by this team, keeping its legitimate container/domain/service configuration.
    let selected = candidates.first().map(|id| id.as_str()).or_else(|| {
        owned
            .iter()
            .find(|id| same(id, input))
            .or_else(|| owned.iter().find(|id| same(id, &alternate)))
            .map(String::as_str)
    });
    let Some(signed) = selected else {
        return Ok(None);
    };
    if !owned.iter().any(|id| same(id, signed)) {
        return Err(IdentityError::OtherTeamInstalled);
    }
    let mut mapping = vec![];
    for ext in extensions {
        let suffix = ext
            .strip_prefix(input)
            .ok_or(IdentityError::InvalidExtension)?;
        if !suffix.starts_with('.') || suffix.len() < 2 {
            return Err(IdentityError::InvalidExtension);
        }
        let proposed = format!("{signed}{suffix}");
        if let Some(existing) = owned.iter().find(|id| same(id, &proposed)) {
            mapping.push(ExtensionIdentity {
                original_bundle_id: ext.clone(),
                signed_bundle_id: existing.clone(),
            });
        }
    }
    Ok(Some(AdoptedIdentity {
        signed: signed.to_owned(),
        extensions: mapping,
    }))
}

/// Apply only to the caller's already-validated private staging application.
/// Use upstream update logic for main relationships, then assign each bounded extension ID.
pub fn apply(
    application: &mut isideload::sideload::application::Application,
    input: &str,
    identity: &IdentityPlan,
) -> Result<(), IdentityError> {
    let inputs = application
        .bundle
        .app_extensions()
        .iter()
        .map(|ext| {
            ext.bundle_identifier()
                .map(str::to_owned)
                .ok_or(IdentityError::InvalidExtension)
        })
        .collect::<Result<Vec<_>, _>>()?;
    application
        .update_bundle_id(input, &identity.signed_bundle_id)
        .map_err(|_| IdentityError::InvalidExtension)?;
    for (extension, input_id) in application
        .bundle
        .app_extensions_mut()
        .iter_mut()
        .zip(&inputs)
    {
        let signed = identity
            .extension_rewrites
            .iter()
            .find(|(source, _)| source == input_id)
            .map(|(_, signed)| signed)
            .ok_or(IdentityError::InvalidExtension)?;
        extension.set_bundle_identifier(signed);
        extension
            .write_info()
            .map_err(|_| IdentityError::InvalidExtension)?;
    }
    application
        .bundle
        .write_info()
        .map_err(|_| IdentityError::InvalidIdentifier)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn repeat_import_updates_same_main_extensions_and_team_namespace() {
        let originals = vec![
            "com.vendor.game.share".to_owned(),
            "com.vendor.game.widget".to_owned(),
        ];
        let first = plan("com.vendor.game", &originals, "TEAM123", &[], None).unwrap();
        assert_ne!(first.signed_bundle_id, "com.vendor.game");
        assert!(first.signed_bundle_id.len() < 255);
        assert!(first.extensions.iter().all(|m| m
            .signed_bundle_id
            .starts_with(&format!("{}.", first.signed_bundle_id))));
        let records = [ExistingIdentity {
            original: &first.original_bundle_id,
            signed: &first.signed_bundle_id,
            team: "TEAM123",
            extensions: &first.extensions,
            is_self: false,
            installed: true,
        }];
        let update = plan("com.vendor.game", &originals, "TEAM123", &records, None).unwrap();
        assert_eq!(update.signed_bundle_id, first.signed_bundle_id);
        assert_eq!(update.extensions, first.extensions);
        let signed_extensions = first
            .extensions
            .iter()
            .map(|e| e.signed_bundle_id.clone())
            .collect::<Vec<_>>();
        let resigned = plan(
            &first.signed_bundle_id,
            &signed_extensions,
            "TEAM123",
            &records,
            None,
        )
        .unwrap();
        assert_eq!(resigned.original_bundle_id, first.original_bundle_id);
        assert_eq!(resigned.extensions, first.extensions);
        // Exercise actual upstream Application mutation + written Info.plists, not just hashes.
        let fixture = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("target")
            .join(format!(
                "identity-{}-{}",
                std::process::id(),
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_nanos()
            ));
        let app = fixture.join("Game.app");
        std::fs::create_dir_all(app.join("PlugIns")).unwrap();
        fn info(path: &std::path::Path, id: &str) {
            std::fs::create_dir_all(path).unwrap();
            let mut p = plist::Dictionary::new();
            p.insert("CFBundleIdentifier".into(), plist::Value::String(id.into()));
            p.insert("CFBundleName".into(), plist::Value::String("Test".into()));
            plist::to_file_xml(path.join("Info.plist"), &p).unwrap();
        }
        info(&app, "com.vendor.game");
        info(&app.join("PlugIns/Share.appex"), &originals[0]);
        info(&app.join("PlugIns/Widget.appex"), &originals[1]);
        let mut application =
            isideload::sideload::application::Application::new(app.clone()).unwrap();
        apply(&mut application, "com.vendor.game", &first).unwrap();
        let written: plist::Dictionary = plist::from_file(app.join("Info.plist")).unwrap();
        assert_eq!(
            written["CFBundleIdentifier"].as_string(),
            Some(first.signed_bundle_id.as_str())
        );
        for leaf in ["Share.appex", "Widget.appex"] {
            let written: plist::Dictionary =
                plist::from_file(app.join("PlugIns").join(leaf).join("Info.plist")).unwrap();
            let signed = written["CFBundleIdentifier"].as_string().unwrap();
            assert!(first
                .extensions
                .iter()
                .any(|m| m.signed_bundle_id == signed));
        }
        std::fs::remove_dir_all(fixture).unwrap();
        let other = plan("com.vendor.game", &originals, "TEAM456", &[], None).unwrap();
        assert_ne!(other.signed_bundle_id, first.signed_bundle_id);
        assert_eq!(
            plan("com.vendor.game", &originals, "TEAM456", &records, None).unwrap_err(),
            IdentityError::OtherTeamInstalled
        );
    }
    #[test]
    fn self_and_legacy_installs_keep_identity_and_long_source_ids_stay_bounded() {
        let actual = "org.tin.appinstaller.EXISTINGTEAM";
        let self_plan = plan(INSTALLER_ORIGINAL_ID, &[], "OTHERTEAM", &[], Some(actual)).unwrap();
        assert_eq!(self_plan.signed_bundle_id, actual);
        assert!(self_plan.is_self);
        let owned_original =
            adopt_external("com.owner.app", &[], "TEAM", &[], &["com.owner.app".into()])
                .unwrap()
                .unwrap();
        assert_eq!(owned_original.signed, "com.owner.app");
        assert!(adopt_external(
            "com.foreign.app",
            &[],
            "TEAM",
            &[],
            &["com.owner.app".into()]
        )
        .unwrap()
        .is_none());
        let installed = vec!["com.vendor.game.TEAM".into()];
        let owned = vec![
            "com.vendor.game.TEAM".into(),
            "com.vendor.game.TEAM.share".into(),
        ];
        let adopted = adopt_external(
            "com.vendor.game",
            &["com.vendor.game.share".into()],
            "TEAM",
            &installed,
            &owned,
        )
        .unwrap()
        .unwrap();
        assert_eq!(adopted.signed, "com.vendor.game.TEAM");
        assert_eq!(
            adopted.extensions[0].signed_bundle_id,
            "com.vendor.game.TEAM.share"
        );
        assert!(matches!(
            adopt_external("com.vendor.game", &[], "TEAM", &installed, &[]),
            Err(IdentityError::OtherTeamInstalled)
        ));
        assert!(matches!(
            adopt_external(
                "com.vendor.game",
                &[],
                "TEAM",
                &["com.vendor.game".into(), "com.vendor.game.TEAM".into()],
                &owned
            ),
            Err(IdentityError::ConflictingRecord)
        ));
        let legacy = [ExistingIdentity {
            original: "",
            signed: "com.personal.owned",
            team: "",
            extensions: &[],
            is_self: false,
            installed: true,
        }];
        assert_eq!(
            plan("com.personal.owned", &[], "TEAM", &legacy, None)
                .unwrap()
                .signed_bundle_id,
            "com.personal.owned"
        );
        let long = format!("com.{}", "a".repeat(251));
        let ext = format!("{long}.x");
        assert!(ext.len() > 255);
        let long_plan = plan(&long, &[], "TEAM", &[], None).unwrap();
        assert!(long_plan.signed_bundle_id.len() < 100);
        assert_eq!(
            plan(&long, &[ext], "TEAM", &[], None).unwrap_err(),
            IdentityError::InvalidExtension
        );
    }
}
