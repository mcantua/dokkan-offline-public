// Jackson Coxson

#[cfg(not(target_arch = "wasm32"))]
use std::path::Path;

use ed25519_dalek::{SigningKey, VerifyingKey};
use plist::Dictionary;
use plist_macro::plist_to_xml_bytes;
use rsa::rand_core::OsRng;

use crate::IdeviceError;

#[derive(Clone)]
pub struct RpPairingFile {
    pub e_private_key: SigningKey,
    pub e_public_key: VerifyingKey,
    pub identifier: String,
    pub alt_irk: Option<Vec<u8>>,
    // Adopted only after authenticated pair-setup M6; never inferred on import.
    pub(crate) peer_pin: Option<(String, VerifyingKey)>,
}

impl RpPairingFile {
    /// Returns the Ed25519 public key bytes (32 bytes).
    pub fn public_key_bytes(&self) -> Vec<u8> {
        self.e_public_key.to_bytes().to_vec()
    }

    /// Returns the Ed25519 private key bytes (32 bytes).
    pub fn private_key_bytes(&self) -> Vec<u8> {
        self.e_private_key.to_bytes().to_vec()
    }

    /// Returns the identifier string.
    pub fn identifier(&self) -> &str {
        &self.identifier
    }

    /// Returns the `alt_irk` bytes (16 bytes).
    pub fn alt_irk(&self) -> Option<&[u8]> {
        self.alt_irk.as_deref()
    }

    pub fn generate(sending_host: &str) -> Self {
        // Ed25519 private key (persistent signing key)
        let ed25519_private_key = SigningKey::generate(&mut OsRng);
        let ed25519_public_key = VerifyingKey::from(&ed25519_private_key);

        let identifier =
            uuid::Uuid::new_v3(&uuid::Uuid::NAMESPACE_DNS, sending_host.as_bytes()).to_string();

        Self {
            e_private_key: ed25519_private_key,
            e_public_key: ed25519_public_key,
            identifier,
            alt_irk: None,
            peer_pin: None,
        }
    }

    pub(crate) fn recreate_signing_keys(&mut self) {
        let ed25519_private_key = SigningKey::generate(&mut OsRng);
        let ed25519_public_key = VerifyingKey::from(&ed25519_private_key);
        self.e_public_key = ed25519_public_key;
        self.e_private_key = ed25519_private_key;
        self.alt_irk = None;
        self.peer_pin = None;
    }

    /// Serialize a version-2 XML plist. An unpaired in-memory identity has no peer
    /// pin and its bytes deliberately cannot be re-imported as trusted pairing.
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut dict = plist::Dictionary::new();
        dict.insert("format_version".into(), plist::Value::Integer(2.into()));
        if let Some((identifier, public_key)) = &self.peer_pin {
            dict.insert("peer_identifier".into(), plist::Value::String(identifier.clone()));
            dict.insert("peer_public_key".into(), plist::Value::Data(public_key.to_bytes().to_vec()));
        }
        dict.insert(
            "public_key".into(),
            plist::Value::Data(self.e_public_key.to_bytes().to_vec()),
        );
        dict.insert(
            "private_key".into(),
            plist::Value::Data(self.e_private_key.to_bytes().to_vec()),
        );
        dict.insert(
            "identifier".into(),
            plist::Value::String(self.identifier.clone()),
        );
        if let Some(irk) = &self.alt_irk {
            dict.insert("alt_irk".into(), plist::Value::Data(irk.clone()));
        }
        plist_to_xml_bytes(&dict)
    }

    /// Parse a version-2 XML/binary plist with a previously authenticated peer pin.
    /// Legacy remote exports deliberately fail closed and require explicit re-pairing.
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, IdeviceError> {
        if bytes.is_empty() || bytes.len() > 1024 * 1024 {
            return Err(invalid_record("remote pairing record size is invalid"));
        }
        let mut p: Dictionary = plist::from_bytes(bytes)
            .map_err(|_| invalid_record("invalid remote pairing plist"))?;
        if p.remove("format_version").and_then(|v| v.as_unsigned_integer()) != Some(2) {
            return Err(invalid_record("remote pairing record requires version 2 and an authenticated peer pin"));
        }
        let public_key = read_public_key(&mut p, "public_key")?;
        let secret: [u8; 32] = p.remove("private_key").and_then(|v| v.into_data())
            .and_then(|v| v.try_into().ok())
            .ok_or_else(|| invalid_record("invalid host signing key"))?;
        let private_key = SigningKey::from_bytes(&secret);
        if VerifyingKey::from(&private_key) != public_key {
            return Err(invalid_record("host public and private keys do not match"));
        }
        let identifier = read_identifier(&mut p, "identifier")?;
        let peer_identifier = read_identifier(&mut p, "peer_identifier")?;
        let peer_public_key = read_public_key(&mut p, "peer_public_key")?;
        let alt_irk = match p.remove("alt_irk") {
            None => None,
            Some(plist::Value::Data(value)) if value.len() == 16 => Some(value),
            Some(_) => return Err(invalid_record("invalid remote identity key length")),
        };
        if !p.is_empty() {
            return Err(invalid_record("unexpected fields in version-2 remote pairing record"));
        }
        Ok(Self {
            e_private_key: private_key,
            e_public_key: public_key,
            identifier,
            alt_irk,
            peer_pin: Some((peer_identifier, peer_public_key)),
        })
    }

    pub fn peer_identifier(&self) -> Option<&str> {
        self.peer_pin.as_ref().map(|(identifier, _)| identifier.as_str())
    }

    pub fn peer_public_key_bytes(&self) -> Option<[u8; 32]> {
        self.peer_pin.as_ref().map(|(_, key)| key.to_bytes())
    }

    /// Publish a new owner-only export. Existing files are never replaced.
    /// A failed write may leave the newly created 0600 file incomplete; it never
    /// overwrites an existing export or creates a plaintext temporary/backup copy.
    #[cfg(not(target_arch = "wasm32"))]
    pub async fn write_to_file(&self, path: impl AsRef<Path>) -> Result<(), IdeviceError> {
        if self.peer_pin.is_none() {
            return Err(invalid_record("cannot persist unauthenticated remote pairing"));
        }
        #[cfg(unix)]
        {
            use tokio::io::AsyncWriteExt;

            let mut options = tokio::fs::OpenOptions::new();
            options.write(true).create_new(true).mode(0o600);
            let mut output = options.open(path).await?;
            let bytes = self.to_bytes();
            output.write_all(&bytes).await?;
            output.sync_all().await?;
            Ok(())
        }
        #[cfg(not(unix))]
        {
            let _ = path;
            Err(invalid_record("private remote pairing export ACL support is required on this platform"))
        }
    }

    #[cfg(not(target_arch = "wasm32"))]
    pub async fn read_from_file(path: impl AsRef<Path>) -> Result<Self, IdeviceError> {
        use tokio::io::AsyncReadExt;

        let input = tokio::fs::File::open(path).await?;
        let mut bytes = Vec::new();
        input.take(1024 * 1024 + 1).read_to_end(&mut bytes).await?;
        Self::from_bytes(&bytes)
    }
}

impl std::fmt::Debug for RpPairingFile {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("RpPairingFile")
            .field("peer_pinned", &self.peer_pin.is_some())
            .finish()
    }
}

fn invalid_record(message: &str) -> IdeviceError {
    IdeviceError::UnexpectedResponse(message.into())
}

fn read_identifier(p: &mut Dictionary, name: &str) -> Result<String, IdeviceError> {
    p.remove(name).and_then(|v| v.into_string())
        .filter(|value| !value.is_empty() && value.len() <= 1024)
        .ok_or_else(|| invalid_record("missing or invalid remote pairing identifier"))
}

fn read_public_key(p: &mut Dictionary, name: &str) -> Result<VerifyingKey, IdeviceError> {
    let bytes: [u8; 32] = p.remove(name).and_then(|v| v.into_data())
        .and_then(|v| v.try_into().ok())
        .ok_or_else(|| invalid_record("missing or invalid remote pairing public key"))?;
    let key = VerifyingKey::from_bytes(&bytes)
        .map_err(|_| invalid_record("invalid remote pairing public key"))?;
    if key.is_weak() { return Err(invalid_record("weak remote pairing public key")); }
    Ok(key)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn pinned() -> RpPairingFile {
        let mut record = RpPairingFile::generate("synthetic-host");
        let peer = SigningKey::from_bytes(&[42; 32]);
        record.peer_pin = Some(("synthetic-peer".into(), VerifyingKey::from(&peer)));
        record
    }

    #[test]
    fn pinned_v2_round_trip_and_legacy_rejection() {
        let record = pinned();
        let restored = RpPairingFile::from_bytes(&record.to_bytes()).unwrap();
        assert_eq!(restored.peer_identifier(), Some("synthetic-peer"));
        assert_eq!(restored.peer_public_key_bytes(), record.peer_public_key_bytes());
        assert!(RpPairingFile::from_bytes(&RpPairingFile::generate("synthetic-host").to_bytes()).is_err());
        let mut plist: Dictionary = plist::from_bytes(&record.to_bytes()).unwrap();
        plist.remove("format_version");
        assert!(RpPairingFile::from_bytes(&plist_to_xml_bytes(&plist)).is_err());
    }

    #[test]
    fn invalid_keys_identifiers_and_version_fail_closed() {
        for (field, value) in [
            ("private_key", plist::Value::Data(vec![3; 32])),
            ("peer_public_key", plist::Value::Data(vec![1; 31])),
            ("peer_identifier", plist::Value::String(String::new())),
            ("identifier", plist::Value::String("x".repeat(1025))),
            ("alt_irk", plist::Value::Data(vec![1; 15])),
            ("format_version", plist::Value::Integer(3.into())),
            ("HostID", plist::Value::String("synthetic-mixed-lockdown-field".into())),
            ("unknown_metadata", plist::Value::String("synthetic-unknown-field".into())),
        ] {
            let mut plist: Dictionary = plist::from_bytes(&pinned().to_bytes()).unwrap();
            plist.insert(field.into(), value);
            assert!(RpPairingFile::from_bytes(&plist_to_xml_bytes(&plist)).is_err());
        }
    }
}
