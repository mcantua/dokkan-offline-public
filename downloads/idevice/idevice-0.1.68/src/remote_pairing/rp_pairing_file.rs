// Jackson Coxson

#[cfg(not(target_arch = "wasm32"))]
use std::path::Path;

use ed25519_dalek::{SigningKey, VerifyingKey};
use plist::Dictionary;
use plist_macro::plist_to_xml_bytes;
use rsa::rand_core::OsRng;
use serde::de::Error;
use tracing::warn;

use crate::IdeviceError;

#[derive(Clone)]
pub struct RpPairingFile {
    pub e_private_key: SigningKey,
    pub e_public_key: VerifyingKey,
    pub identifier: String,
    pub alt_irk: Option<Vec<u8>>,
    /// Device identity captured from authenticated trusted-USB SRP setup.
    pub peer_identifier: Option<String>,
    pub peer_public_key: Option<VerifyingKey>,
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
            peer_identifier: None,
            peer_public_key: None,
        }
    }

    pub(crate) fn recreate_signing_keys(&mut self) {
        let ed25519_private_key = SigningKey::generate(&mut OsRng);
        let ed25519_public_key = VerifyingKey::from(&ed25519_private_key);
        self.e_public_key = ed25519_public_key;
        self.e_private_key = ed25519_private_key;
        self.alt_irk = None;
        self.peer_identifier = None;
        self.peer_public_key = None;
    }

    pub fn has_peer_pin(&self) -> bool {
        self.peer_identifier
            .as_deref()
            .is_some_and(valid_identifier)
            && self
                .peer_public_key
                .as_ref()
                .is_some_and(|key| !key.is_weak())
            && self.e_public_key == self.e_private_key.verifying_key()
    }

    /// Export only after authenticated trusted-USB setup captured the device pin.
    pub fn to_pinned_bytes(&self) -> Result<Vec<u8>, IdeviceError> {
        if !self.has_peer_pin() {
            return Err(invalid_record());
        }
        Ok(self.to_bytes())
    }

    /// Serialize to XML plist bytes.
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut dict = plist::Dictionary::new();
        dict.insert(
            "app_installer_rp_version".into(),
            plist::Value::Integer(2u64.into()),
        );
        if let Some(identifier) = &self.peer_identifier {
            dict.insert(
                "peer_identifier".into(),
                plist::Value::String(identifier.clone()),
            );
        }
        if let Some(key) = &self.peer_public_key {
            dict.insert(
                "peer_public_key".into(),
                plist::Value::Data(key.to_bytes().to_vec()),
            );
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

    /// Parse from plist bytes (XML or binary).
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, IdeviceError> {
        if bytes.len() > 64 * 1024 {
            return Err(invalid_record());
        }
        let mut p: Dictionary = plist::from_bytes(bytes)?;
        if p.remove("app_installer_rp_version")
            .and_then(|value| value.as_unsigned_integer())
            != Some(2)
        {
            return Err(invalid_record());
        }
        let peer_identifier = p
            .remove("peer_identifier")
            .and_then(plist::Value::into_string)
            .filter(|id| valid_identifier(id))
            .ok_or_else(invalid_record)?;
        let peer_public_key = p
            .remove("peer_public_key")
            .and_then(plist::Value::into_data)
            .filter(|data| data.len() == 32)
            .and_then(|data| VerifyingKey::from_bytes(data.as_slice().try_into().ok()?).ok())
            .filter(|key| !key.is_weak())
            .ok_or_else(invalid_record)?;

        let public_key = match p
            .remove("public_key")
            .and_then(|x| x.into_data())
            .filter(|x| x.len() == 32)
            .and_then(|x| VerifyingKey::from_bytes(&x[..32].try_into().unwrap()).ok())
        {
            Some(p) => p,
            None => {
                warn!("plist did not contain valid public key bytes");
                return Err(IdeviceError::Plist(plist::Error::missing_field(
                    "public_key",
                )));
            }
        };

        let private_key = match p
            .remove("private_key")
            .and_then(|x| x.into_data())
            .filter(|x| x.len() == 32)
        {
            Some(p) => SigningKey::from_bytes(&p.try_into().unwrap()),
            None => {
                warn!("plist did not contain valid private key bytes");
                return Err(IdeviceError::Plist(plist::Error::missing_field(
                    "private_key",
                )));
            }
        };

        let identifier = match p.remove("identifier").and_then(|x| x.into_string()) {
            Some(i) if valid_identifier(&i) => i,
            _ => {
                warn!("plist did not contain identifier");
                return Err(IdeviceError::Plist(plist::Error::missing_field(
                    "identifier",
                )));
            }
        };

        let alt_irk = match p.remove("alt_irk") {
            Some(plist::Value::Data(irk)) if irk.len() == 16 => Some(irk),
            Some(_) => return Err(invalid_record()),
            None => None,
        };

        if private_key.verifying_key() != public_key {
            return Err(invalid_record());
        }
        if !p.is_empty() {
            return Err(invalid_record());
        }
        Ok(Self {
            e_private_key: private_key,
            e_public_key: public_key,
            identifier,
            alt_irk,
            peer_identifier: Some(peer_identifier),
            peer_public_key: Some(peer_public_key),
        })
    }

    #[cfg(not(target_arch = "wasm32"))]
    pub async fn write_to_file(&self, path: impl AsRef<Path>) -> Result<(), IdeviceError> {
        tokio::fs::write(path, self.to_bytes()).await?;
        Ok(())
    }

    #[cfg(not(target_arch = "wasm32"))]
    pub async fn read_from_file(path: impl AsRef<Path>) -> Result<Self, IdeviceError> {
        let bytes = tokio::fs::read(path).await?;
        Self::from_bytes(&bytes)
    }
}

fn valid_identifier(id: &str) -> bool {
    !id.is_empty() && id.len() <= 255 && !id.chars().any(char::is_control)
}
fn invalid_record() -> IdeviceError {
    IdeviceError::UnexpectedResponse(
        "A trusted version-2 Remote Pairing export with a device identity pin is required".into(),
    )
}
impl std::fmt::Debug for RpPairingFile {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("RpPairingFile([redacted])")
    }
}

#[cfg(test)]
mod connectivity_tests {
    use super::*;

    #[test]
    fn rp_connectivity_optional_discovery_key_is_absent_or_exact_data() {
        let mut record = RpPairingFile::generate("synthetic-host");
        record.peer_identifier = Some("synthetic-device".into());
        record.peer_public_key = Some(SigningKey::generate(&mut OsRng).verifying_key());
        let encoded = record.to_pinned_bytes().unwrap();
        let mut payload: Dictionary = plist::from_bytes(&encoded).unwrap();
        // No discovery key is legitimate: the bounded fixed-port fallback still
        // requires full pinned pair-verify. A present malformed key is not absent.
        assert!(
            RpPairingFile::from_bytes(&encoded)
                .unwrap()
                .alt_irk
                .is_none()
        );
        for value in [
            plist::Value::String("not-a-key".into()),
            plist::Value::Integer(16u64.into()),
            plist::Value::Boolean(false),
            plist::Value::Array(vec![]),
            plist::Value::Data(vec![1; 15]),
            plist::Value::Data(vec![1; 17]),
        ] {
            payload.insert("alt_irk".into(), value);
            let mut bytes = Vec::new();
            plist::to_writer_xml(&mut bytes, &payload).unwrap();
            assert!(RpPairingFile::from_bytes(&bytes).is_err());
        }
        payload.insert("alt_irk".into(), plist::Value::Data(vec![1; 16]));
        let mut bytes = Vec::new();
        plist::to_writer_binary(&mut bytes, &payload).unwrap();
        let parsed = RpPairingFile::from_bytes(&bytes).unwrap();
        assert_eq!(parsed.alt_irk(), Some(&[1u8; 16][..]));
        assert!(RpPairingFile::from_bytes(&parsed.to_pinned_bytes().unwrap()).is_ok());
    }
}
