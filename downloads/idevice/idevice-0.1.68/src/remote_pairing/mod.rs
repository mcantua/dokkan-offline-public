//! Remote Pairing

use crate::IdeviceError;
use base64::Engine as _;
use errors::RemotePairingError;

use chacha20poly1305::{
    ChaCha20Poly1305, Key, KeyInit, Nonce,
    aead::{Aead, Payload},
};
use ed25519_dalek::Signature;
use hkdf::Hkdf;
use idevice_srp::{client::SrpClient, groups::G_3072};
use plist_macro::plist;
use plist_macro::{PlistConvertible, PlistExt};
use rand::Rng as _;
use rsa::{rand_core::OsRng, signature::SignerMut};
use serde::Serialize;
use sha2::Sha512;
use tracing::{debug, warn};
use x25519_dalek::{EphemeralSecret, PublicKey as X25519PublicKey};

pub mod errors;
mod lockdown;
mod opack;
mod peer_device;
mod responder;
mod rp_pairing_file;
mod socket;
pub mod tls_psk;
mod tlv;
pub mod tunnel;

// export
pub use lockdown::RemotePairingLockdownService;
pub use peer_device::{PeerDevice, compute_auth_tag};
pub use responder::{PAIRABLE_HOST_SERVICE_TYPE, PairableHost, PairableHostInfo};
pub use rp_pairing_file::RpPairingFile;
pub use socket::{RpPairingSocket, RpPairingSocketProvider};
#[cfg(feature = "openssl")]
pub use tunnel::connect_tls_psk_tunnel;
pub use tunnel::{CdTunnel, TunnelInfo, connect_tls_psk_tunnel_native};

const RPPAIRING_MAGIC: &[u8] = b"RPPairing";
const WIRE_PROTOCOL_VERSION: u8 = 19;

/// Fixed, non-sensitive progress stages for explicit initial pairing.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PairingStage {
    Consent,
    SrpProof,
    PeerRecord,
    PeerIdentity,
}

fn peer_identity_error() -> IdeviceError {
    IdeviceError::UnexpectedResponse(
        "Remote Pairing device identity could not be authenticated".into(),
    )
}
fn strict_tlv(bytes: &[u8]) -> Result<Vec<tlv::TLV8Entry>, IdeviceError> {
    if bytes.len() > 65535 {
        return Err(peer_identity_error());
    }
    let entries = tlv::deserialize_tlv8(bytes)?;
    if tlv::serialize_tlv8(&entries) != bytes {
        return Err(peer_identity_error());
    }
    Ok(entries)
}
fn one_component<'a>(
    entries: &'a [tlv::TLV8Entry],
    kind: tlv::PairingDataComponentType,
) -> Result<&'a [u8], IdeviceError> {
    let mut found = entries.iter().filter(|entry| entry.tlv_type == kind);
    let data = found.next().ok_or_else(peer_identity_error)?;
    if found.next().is_some() {
        return Err(peer_identity_error());
    }
    Ok(&data.data)
}
fn require_state(entries: &[tlv::TLV8Entry], state: u8) -> Result<(), IdeviceError> {
    if tlv::contains_component(entries, tlv::PairingDataComponentType::ErrorResponse)
        || one_component(entries, tlv::PairingDataComponentType::State)? != [state]
    {
        return Err(peer_identity_error());
    }
    Ok(())
}
fn peer_identifier(bytes: &[u8]) -> Result<String, IdeviceError> {
    let id = std::str::from_utf8(bytes).map_err(|_| peer_identity_error())?;
    if id.is_empty() || id.len() > 255 || id.chars().any(char::is_control) {
        return Err(peer_identity_error());
    }
    Ok(id.to_owned())
}
fn verify_pair_verify_peer(
    entries: &[tlv::TLV8Entry],
    cipher: &ChaCha20Poly1305,
    pairing: &RpPairingFile,
    device_ephemeral: &[u8; 32],
    host_ephemeral: &[u8; 32],
) -> Result<(), IdeviceError> {
    require_state(entries, 2)?;
    let encrypted =
        tlv::collect_component_data(entries, tlv::PairingDataComponentType::EncryptedData);
    if encrypted.is_empty() {
        return Err(peer_identity_error());
    }
    let clear = cipher
        .decrypt(
            Nonce::from_slice(b"\x00\x00\x00\x00PV-Msg02"),
            Payload {
                msg: &encrypted,
                aad: &[],
            },
        )
        .map_err(|_| peer_identity_error())?;
    let identity = strict_tlv(&clear)?;
    let identifier = peer_identifier(one_component(
        &identity,
        tlv::PairingDataComponentType::Identifier,
    )?)?;
    if pairing.peer_identifier.as_deref() != Some(&identifier) {
        return Err(peer_identity_error());
    }
    let signature = Signature::from_slice(one_component(
        &identity,
        tlv::PairingDataComponentType::Signature,
    )?)
    .map_err(|_| peer_identity_error())?;
    let mut message = Vec::new();
    message.extend_from_slice(device_ephemeral);
    message.extend_from_slice(identifier.as_bytes());
    message.extend_from_slice(host_ephemeral);
    pairing
        .peer_public_key
        .as_ref()
        .ok_or_else(peer_identity_error)?
        .verify_strict(&message, &signature)
        .map_err(|_| peer_identity_error())
}
fn verify_setup_accessory(
    entries: &[tlv::TLV8Entry],
    session_key: &[u8],
) -> Result<(String, ed25519_dalek::VerifyingKey), IdeviceError> {
    let identifier = peer_identifier(one_component(
        entries,
        tlv::PairingDataComponentType::Identifier,
    )?)?;
    let key_bytes: &[u8; 32] = one_component(entries, tlv::PairingDataComponentType::PublicKey)?
        .try_into()
        .map_err(|_| peer_identity_error())?;
    let key =
        ed25519_dalek::VerifyingKey::from_bytes(key_bytes).map_err(|_| peer_identity_error())?;
    if key.is_weak() {
        return Err(peer_identity_error());
    }
    let signature = Signature::from_slice(one_component(
        entries,
        tlv::PairingDataComponentType::Signature,
    )?)
    .map_err(|_| peer_identity_error())?;
    let mut accessory_x = [0u8; 32];
    Hkdf::<Sha512>::new(Some(b"Pair-Setup-Accessory-Sign-Salt"), session_key)
        .expand(b"Pair-Setup-Accessory-Sign-Info", &mut accessory_x)
        .map_err(|_| peer_identity_error())?;
    let mut message = accessory_x.to_vec();
    message.extend_from_slice(identifier.as_bytes());
    message.extend_from_slice(key_bytes);
    key.verify_strict(&message, &signature)
        .map_err(|_| peer_identity_error())?;
    Ok((identifier, key))
}

pub struct RemotePairingClient<R: RpPairingSocketProvider> {
    inner: R,
    sequence_number: usize,
    encrypted_sequence_number: u64,
    sending_host: String,

    /// The shared secret from X25519 (pair-verify) or SRP (initial pairing).
    /// Used as PSK for the TLS tunnel and to derive per-message encryption keys.
    encryption_key: Vec<u8>,

    client_cipher: ChaCha20Poly1305,
    server_cipher: ChaCha20Poly1305,

    paired_peer_device: Option<PeerDevice>,
    peer_authenticated: bool,
}

impl<R: RpPairingSocketProvider> RemotePairingClient<R> {
    pub fn new(inner: R, sending_host: &str) -> Self {
        // Initial ciphers are placeholders; they will be re-derived from
        // the actual encryption_key once pair-verify or pairing completes.
        let initial_key = vec![0u8; 32];
        let (client_cipher, server_cipher) = Self::derive_main_ciphers(&initial_key);

        Self {
            inner,
            sequence_number: 0,
            encrypted_sequence_number: 0,
            sending_host: sending_host.to_string(),
            encryption_key: initial_key,
            client_cipher,
            server_cipher,
            paired_peer_device: None,
            peer_authenticated: false,
        }
    }

    fn derive_main_ciphers(key: &[u8]) -> (ChaCha20Poly1305, ChaCha20Poly1305) {
        let hk = Hkdf::<sha2::Sha512>::new(None, key);
        let mut okm = [0u8; 32];
        hk.expand(b"ClientEncrypt-main", &mut okm).unwrap();
        let client_cipher = ChaCha20Poly1305::new(chacha20poly1305::Key::from_slice(&okm));

        let hk = Hkdf::<sha2::Sha512>::new(None, key);
        let mut okm = [0u8; 32];
        hk.expand(b"ServerEncrypt-main", &mut okm).unwrap();
        let server_cipher = ChaCha20Poly1305::new(chacha20poly1305::Key::from_slice(&okm));

        (client_cipher, server_cipher)
    }

    /// Returns the encryption key established during pairing.
    /// This is used as TLS-PSK for tunnel connections.
    pub fn encryption_key(&self) -> &[u8] {
        if self.peer_authenticated {
            &self.encryption_key
        } else {
            &[]
        }
    }
    pub fn authenticated_encryption_key(&self) -> Result<&[u8], IdeviceError> {
        if !self.peer_authenticated || self.encryption_key.len() != 32 {
            return Err(peer_identity_error());
        }
        Ok(&self.encryption_key)
    }

    /// Performs the RPPairing handshake and pinned pair-verify. Never silently
    /// creates/replaces trust after a failed verification. Explicit trusted-USB
    /// initial setup uses pair() and a new unpinned host identity.
    ///
    /// Both halves work against either of the services tvOS advertises. A
    /// successful return does not mean the connection can carry a tunnel, though:
    /// only `_remotepairing._tcp` serves [`Self::create_tcp_listener`], so on tvOS
    /// pairing and tunnel creation are worth keeping as separate connections.
    pub async fn connect<Fut>(
        &mut self,
        pairing_file: &mut RpPairingFile,
        pin_callback: impl Fn() -> Fut,
    ) -> Result<(), IdeviceError>
    where
        Fut: std::future::Future<Output = String>,
    {
        let _ = pin_callback;
        if !pairing_file.has_peer_pin() {
            return Err(peer_identity_error());
        }
        self.attempt_pair_verify().await?;
        self.validate_pairing(pairing_file).await?;
        Ok(())
    }

    /// Returns peer device info captured during this client's successful `pair()` flow.
    pub fn paired_peer_device(&self) -> Result<&PeerDevice, IdeviceError> {
        self.paired_peer_device
            .as_ref()
            .ok_or(IdeviceError::UnexpectedResponse(
                "paired peer device info is only available after a successful pair() call".into(),
            ))
    }

    pub async fn validate_pairing(
        &mut self,
        pairing_file: &mut RpPairingFile,
    ) -> Result<(), IdeviceError> {
        self.peer_authenticated = false;
        if !pairing_file.has_peer_pin() {
            return Err(peer_identity_error());
        }
        let x_private_key = EphemeralSecret::random_from_rng(OsRng);
        let x_public_key = X25519PublicKey::from(&x_private_key);

        let pairing_data = tlv::serialize_tlv8(&[
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::State,
                data: vec![0x01],
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::PublicKey,
                data: x_public_key.to_bytes().to_vec(),
            },
        ]);
        let pairing_data = R::serialize_bytes(&pairing_data);
        self.send_pairing_data(plist!({
            "data": pairing_data,
            "kind": "verifyManualPairing",
            "startNewSession": true
        }))
        .await?;
        debug!("Waiting for response from verifyManualPairing");

        let pairing_data = self.receive_pairing_data().await?;

        let data = match R::deserialize_bytes(pairing_data) {
            Some(d) => d,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "failed to deserialize pair-verify response bytes".into(),
                ));
            }
        };

        let data = strict_tlv(&data)?;

        if data
            .iter()
            .any(|x| x.tlv_type == tlv::PairingDataComponentType::ErrorResponse)
        {
            self.send_pair_verified_failed().await?;
            return Err(RemotePairingError::PairVerifyFailed.into());
        }

        require_state(&data, 2)?;
        if data
            .iter()
            .filter(|entry| entry.tlv_type == tlv::PairingDataComponentType::PublicKey)
            .count()
            != 1
        {
            return Err(peer_identity_error());
        }
        let device_public_key = match data
            .iter()
            .find(|x| x.tlv_type == tlv::PairingDataComponentType::PublicKey)
        {
            Some(d) => d,
            None => {
                warn!("No public key in TLV data");
                return Err(IdeviceError::UnexpectedResponse(
                    "missing public key in pair-verify TLV data".into(),
                ));
            }
        };
        let peer_pub_bytes: [u8; 32] = match device_public_key.data.as_slice().try_into() {
            Ok(d) => d,
            Err(_) => {
                warn!("Device public key isn't the expected size");
                return Err(IdeviceError::NotEnoughBytes(
                    32,
                    device_public_key.data.len(),
                ));
            }
        };
        let device_public_key = x25519_dalek::PublicKey::from(peer_pub_bytes);
        let shared_secret = x_private_key.diffie_hellman(&device_public_key);

        if !shared_secret.was_contributory() {
            return Err(peer_identity_error());
        }

        // Derive encryption key with HKDF-SHA512
        let hk =
            Hkdf::<sha2::Sha512>::new(Some(b"Pair-Verify-Encrypt-Salt"), shared_secret.as_bytes());

        let mut okm = [0u8; 32];
        hk.expand(b"Pair-Verify-Encrypt-Info", &mut okm).unwrap();

        // ChaCha20Poly1305 AEAD cipher
        let cipher = ChaCha20Poly1305::new(chacha20poly1305::Key::from_slice(&okm));

        verify_pair_verify_peer(
            &data,
            &cipher,
            pairing_file,
            device_public_key.as_bytes(),
            x_public_key.as_bytes(),
        )?;

        let ed25519_signing_key = &mut pairing_file.e_private_key;

        let mut signbuf = Vec::with_capacity(32 + pairing_file.identifier.len() + 32);
        signbuf.extend_from_slice(x_public_key.as_bytes()); // 32 bytes
        signbuf.extend_from_slice(pairing_file.identifier.as_bytes()); // variable
        signbuf.extend_from_slice(device_public_key.as_bytes()); // 32 bytes

        let signature: Signature = ed25519_signing_key.sign(&signbuf);

        let plaintext = vec![
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Identifier,
                data: pairing_file.identifier.as_bytes().to_vec(),
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Signature,
                data: signature.to_vec(),
            },
        ];
        let plaintext = tlv::serialize_tlv8(&plaintext);
        let nonce = Nonce::from_slice(b"\x00\x00\x00\x00PV-Msg03"); // 12-byte nonce
        let ciphertext = cipher
            .encrypt(
                nonce,
                Payload {
                    msg: &plaintext,
                    aad: &[],
                },
            )
            .expect("encryption should not fail");

        let msg = vec![
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::State,
                data: [0x03].to_vec(),
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::EncryptedData,
                data: ciphertext,
            },
        ];

        debug!("Waiting for signbuf response");
        self.send_pairing_data(plist! ({
            "data": R::serialize_bytes(&tlv::serialize_tlv8(&msg)),
            "kind": "verifyManualPairing",
            "startNewSession": false
        }))
        .await?;
        let res = self.receive_pairing_data().await?;

        let data = match R::deserialize_bytes(res) {
            Some(d) => d,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "failed to deserialize pair-verify signature response bytes".into(),
                ));
            }
        };
        let data = strict_tlv(&data)?;

        // Check if the device responded with an error (which is expected for a new pairing)
        if data
            .iter()
            .any(|x| x.tlv_type == tlv::PairingDataComponentType::ErrorResponse)
        {
            debug!(
                "Verification failed, device reported an error. This is expected for a new pairing."
            );
            self.send_pair_verified_failed().await?;
            // Return a specific error to the caller.
            return Err(RemotePairingError::PairVerifyFailed.into());
        }

        require_state(&data, 4)?;
        // Only a pinned device's valid transcript can establish production tunnel keys.
        self.encryption_key = shared_secret.as_bytes().to_vec();
        self.peer_authenticated = true;
        self.encrypted_sequence_number = 0;
        let (cc, sc) = Self::derive_main_ciphers(&self.encryption_key);
        self.client_cipher = cc;
        self.server_cipher = sc;

        Ok(())
    }

    pub async fn send_pair_verified_failed(&mut self) -> Result<(), IdeviceError> {
        self.inner
            .send_plain(
                plist!({
                    "event": {
                        "_0": {
                            "pairVerifyFailed": {}
                        }
                    }
                }),
                self.sequence_number,
            )
            .await?;
        self.sequence_number += 1;
        Ok(())
    }

    pub async fn attempt_pair_verify(&mut self) -> Result<plist::Value, IdeviceError> {
        debug!("Sending attemptPairVerify");
        self.inner
            .send_plain(
                plist!({
                    "request": {
                        "_0": {
                            "handshake": {
                                "_0": {
                                    "hostOptions": {
                                        "attemptPairVerify": true
                                    },
                                    "wireProtocolVersion": plist::Value::Integer(WIRE_PROTOCOL_VERSION.into()),
                                }
                            }
                        }
                    }
                }),
                self.sequence_number,
            )
            .await?;
        self.sequence_number += 1;

        debug!("Waiting for attemptPairVerify response");
        let response = self.inner.recv_plain().await?;

        let response = response
            .as_dictionary()
            .and_then(|x| x.get("response"))
            .and_then(|x| x.as_dictionary())
            .and_then(|x| x.get("_1"))
            .and_then(|x| x.as_dictionary())
            .and_then(|x| x.get("handshake"))
            .and_then(|x| x.as_dictionary())
            .and_then(|x| x.get("_0"));

        match response {
            Some(v) => Ok(v.to_owned()),
            None => Err(IdeviceError::UnexpectedResponse(
                "missing handshake response in attemptPairVerify".into(),
            )),
        }
    }

    pub async fn pair<Fut>(
        &mut self,
        pairing_file: &mut RpPairingFile,
        pin_callback: impl Fn() -> Fut,
    ) -> Result<(), IdeviceError>
    where
        Fut: std::future::Future<Output = String>,
    {
        self.pair_with_progress(pairing_file, pin_callback, |_| {})
            .await
    }

    pub async fn pair_with_progress<Fut>(
        &mut self,
        pairing_file: &mut RpPairingFile,
        pin_callback: impl Fn() -> Fut,
        mut on_stage: impl FnMut(PairingStage),
    ) -> Result<(), IdeviceError>
    where
        Fut: std::future::Future<Output = String>,
    {
        if pairing_file.has_peer_pin() {
            return Err(peer_identity_error());
        }
        self.peer_authenticated = false;
        on_stage(PairingStage::Consent);
        let (salt, public_key, pin) = self.request_pair_consent(pin_callback).await?;
        on_stage(PairingStage::SrpProof);
        let key = self.init_srp_context(&salt, &public_key, &pin).await?;
        on_stage(PairingStage::PeerRecord);
        let tlv = self.save_pair_record_on_peer(pairing_file, &key).await?;
        on_stage(PairingStage::PeerIdentity);
        let (peer_identifier, peer_key) = verify_setup_accessory(&tlv, &key)?;
        let peer_device = peer_device::parse_peer_device_from_tlv(&tlv)?;
        if peer_device.account_id != peer_identifier {
            return Err(peer_identity_error());
        }
        pairing_file.peer_identifier = Some(peer_identifier);
        pairing_file.peer_public_key = Some(peer_key);
        self.peer_authenticated = true;

        pairing_file.alt_irk = Some(peer_device.alt_irk.clone());
        self.paired_peer_device = Some(peer_device);

        Ok(())
    }

    /// Returns salt and public key and pin
    async fn request_pair_consent<Fut>(
        &mut self,
        pin_callback: impl Fn() -> Fut,
    ) -> Result<(Vec<u8>, Vec<u8>, String), IdeviceError>
    where
        Fut: std::future::Future<Output = String>,
    {
        let tlv = tlv::serialize_tlv8(&[
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Method,
                data: vec![0x00],
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::State,
                data: vec![0x01],
            },
        ]);
        let tlv = R::serialize_bytes(&tlv);
        self.send_pairing_data(plist!({
            "data": tlv,
            "kind": "setupManualPairing",
            "sendingHost": &self.sending_host,
            "startNewSession": true
        }))
        .await?;

        let response = self.inner.recv_plain().await?;
        let response = match response
            .get_by("event")
            .and_then(|x| x.get_by("_0"))
            .and_then(|x| x.as_dictionary())
        {
            Some(r) => r,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "missing event._0 in pair consent response".into(),
                ));
            }
        };

        let mut pin = None;

        let pairing_data = match if let Some(err) = response.get("pairingRejectedWithError") {
            let context = err
                .get_by("wrappedError")
                .and_then(|x| x.get_by("userInfo"))
                .and_then(|x| x.get_by("NSLocalizedDescription"))
                .and_then(|x| x.as_string())
                .map(|x| x.to_string());
            return Err(RemotePairingError::PairingRejected(context.unwrap_or_default()).into());
        } else if response.get("awaitingUserConsent").is_some() {
            pin = Some("000000".to_string());
            Some(self.receive_pairing_data().await?)
        } else {
            // On Apple TV, we can get the pin now
            response
                .get_by("pairingData")
                .and_then(|x| x.get_by("_0"))
                .and_then(|x| x.get_by("data"))
                .map(|x| x.to_owned())
        } {
            Some(p) => p,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "missing pairing data in pair consent response".into(),
                ));
            }
        };

        let tlv = strict_tlv(&match R::deserialize_bytes(pairing_data) {
            Some(t) => t,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "failed to deserialize pairing data bytes in pair consent".into(),
                ));
            }
        })?;

        require_state(&tlv, 2)?;
        let salt = one_component(&tlv, tlv::PairingDataComponentType::Salt)?.to_vec();
        let public_key =
            tlv::collect_component_data(&tlv, tlv::PairingDataComponentType::PublicKey);

        let pin = match pin {
            Some(p) => p,
            None => pin_callback().await,
        };

        if salt.is_empty() || salt.len() > 64 || public_key.len() != 384 {
            warn!("Pairing data did not contain salt or public key");
            return Err(IdeviceError::UnexpectedResponse(
                "pairing data missing salt or public key".into(),
            ));
        }

        Ok((salt, public_key, pin))
    }

    /// Returns the encryption key
    async fn init_srp_context(
        &mut self,
        salt: &[u8],
        public_key: &[u8],
        pin: &str,
    ) -> Result<Vec<u8>, IdeviceError> {
        if pin.len() != 6 || !pin.bytes().all(|byte| byte.is_ascii_digit()) {
            return Err(peer_identity_error());
        }
        let client = SrpClient::<Sha512>::new(
            &G_3072, // PRIME_3072 + generator
        );

        let mut a_private = [0u8; 32];
        rand::rng().fill_bytes(&mut a_private);

        let a_public = client.compute_public_ephemeral(&a_private);

        let verifier = match client.process_reply(
            &a_private,
            "Pair-Setup".as_bytes(),
            &pin.as_bytes()[..6],
            salt,
            public_key,
            false,
        ) {
            Ok(v) => v,
            Err(e) => {
                warn!("SRP verifier creation failed: {e:?}");
                return Err(RemotePairingError::SrpAuthFailed.into());
            }
        };

        let client_proof = verifier.proof();

        let tlv = tlv::serialize_tlv8(&[
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::State,
                data: vec![0x03],
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::PublicKey,
                data: a_public,
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Proof,
                data: client_proof.to_vec(),
            },
        ]);
        let tlv = R::serialize_bytes(&tlv);

        self.send_pairing_data(plist!({
            "data": tlv,
            "kind": "setupManualPairing",
            "sendingHost": &self.sending_host,
            "startNewSession": false,

        }))
        .await?;

        let response = self.receive_pairing_data().await?;
        let response = strict_tlv(&match R::deserialize_bytes(response.to_owned()) {
            Some(r) => r,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "failed to deserialize SRP proof response bytes".into(),
                ));
            }
        })?;

        require_state(&response, 4)?;
        let proof = one_component(&response, tlv::PairingDataComponentType::Proof)?;

        match verifier.verify_server(proof) {
            Ok(_) => Ok(verifier.key().to_vec()),
            Err(e) => {
                warn!("Server auth failed: {e:?}");
                Err(RemotePairingError::SrpAuthFailed.into())
            }
        }
    }

    async fn save_pair_record_on_peer(
        &mut self,
        pairing_file: &mut RpPairingFile,
        encryption_key: &[u8],
    ) -> Result<Vec<tlv::TLV8Entry>, IdeviceError> {
        let salt = b"Pair-Setup-Encrypt-Salt";
        let info = b"Pair-Setup-Encrypt-Info";

        let hk = Hkdf::<Sha512>::new(Some(salt), encryption_key);
        let mut setup_encryption_key = [0u8; 32];
        hk.expand(info, &mut setup_encryption_key)
            .expect("HKDF expand failed");

        // Save the SRP session key as the encryption key
        self.encryption_key = encryption_key.to_vec();

        pairing_file.recreate_signing_keys();
        {
            // Re-derive main ciphers from the SRP session key
            let (cc, sc) = Self::derive_main_ciphers(encryption_key);
            self.client_cipher = cc;
            self.server_cipher = sc;
        }

        let hk = Hkdf::<Sha512>::new(Some(b"Pair-Setup-Controller-Sign-Salt"), encryption_key);

        let mut signbuf = Vec::with_capacity(32 + pairing_file.identifier.len() + 32);

        let mut hkdf_out = [0u8; 32];
        hk.expand(b"Pair-Setup-Controller-Sign-Info", &mut hkdf_out)
            .expect("HKDF expand failed");

        signbuf.extend_from_slice(&hkdf_out);

        signbuf.extend_from_slice(pairing_file.identifier.as_bytes());
        signbuf.extend_from_slice(pairing_file.e_public_key.as_bytes());

        let signature = pairing_file.e_private_key.sign(&signbuf);

        let device_info = crate::plist!({
            "altIRK": b"\xe9\xe8-\xc0jIykVoT\x00\x19\xb1\xc7{".to_vec(),
            "btAddr": "11:22:33:44:55:66",
            "mac": b"\x11\x22\x33\x44\x55\x66".to_vec(),
            "remotepairing_serial_number": "AAAAAAAAAAAA",
            "accountID": pairing_file.identifier.as_str(),
            "model": "computer-model",
            "name": self.sending_host.as_str()
        });
        let device_info = opack::plist_to_opack(&device_info);

        let tlv = tlv::serialize_tlv8(&[
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Identifier,
                data: pairing_file.identifier.as_bytes().to_vec(),
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::PublicKey,
                data: pairing_file.e_public_key.to_bytes().to_vec(),
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Signature,
                data: signature.to_vec(),
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Info,
                data: device_info,
            },
        ]);

        let key = Key::from_slice(&setup_encryption_key); // 32 bytes
        let cipher = ChaCha20Poly1305::new(key);

        let nonce = Nonce::from_slice(b"\x00\x00\x00\x00PS-Msg05"); // 12 bytes

        let plaintext = &tlv;

        let ciphertext = match cipher.encrypt(
            nonce,
            Payload {
                msg: plaintext,
                aad: b"",
            },
        ) {
            Ok(c) => c,
            Err(e) => {
                warn!("Chacha encryption failed: {e:?}");
                return Err(RemotePairingError::ChachaEncryption(e).into());
            }
        };
        debug!("ciphertext len: {}", ciphertext.len());

        let tlv = tlv::serialize_tlv8(&[
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::EncryptedData,
                data: ciphertext,
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::State,
                data: vec![0x05],
            },
        ]);
        let tlv = R::serialize_bytes(&tlv);

        debug!("Sending encrypted data");
        self.send_pairing_data(plist!({
            "data": tlv,
            "kind": "setupManualPairing",
            "sendingHost": &self.sending_host,
            "startNewSession": false,
        }))
        .await?;

        debug!("Waiting for encrypted data");
        let response = match R::deserialize_bytes(self.receive_pairing_data().await?) {
            Some(r) => r,
            None => {
                warn!("Pairing data response was not deserializable");
                return Err(IdeviceError::UnexpectedResponse(
                    "failed to deserialize pair record response bytes".into(),
                ));
            }
        };

        let tlv = strict_tlv(&response)?;

        require_state(&tlv, 6)?;
        let mut encrypted_data = Vec::new();
        for t in tlv {
            match t.tlv_type {
                tlv::PairingDataComponentType::EncryptedData => encrypted_data.extend(t.data),
                tlv::PairingDataComponentType::ErrorResponse => {
                    warn!("TLV contained error response");
                    return Err(IdeviceError::UnexpectedResponse(
                        "TLV error response in pair record save".into(),
                    ));
                }
                _ => {}
            }
        }

        let nonce = Nonce::from_slice(b"\x00\x00\x00\x00PS-Msg06");

        let plaintext = cipher
            .decrypt(
                nonce,
                Payload {
                    msg: &encrypted_data,
                    aad: b"",
                },
            )
            .map_err(|_| peer_identity_error())?;

        let tlv = strict_tlv(&plaintext)?;

        Ok(tlv)
    }

    /// Send an encrypted request and receive an encrypted response.
    /// Used for post-pairing RPCs like creating tunnel listeners.
    pub async fn send_receive_encrypted_request(
        &mut self,
        request: plist::Value,
    ) -> Result<plist::Value, IdeviceError> {
        if !self.peer_authenticated {
            return Err(peer_identity_error());
        }
        // Consume the nonce and invalidate this session BEFORE the first await.
        // Cancellation/transport/authentication failure can never reuse its key/nonce.
        self.peer_authenticated = false;
        let counter = self.encrypted_sequence_number;
        self.encrypted_sequence_number = counter.checked_add(1).ok_or_else(peer_identity_error)?;
        let sequence = self.sequence_number;
        self.sequence_number = sequence.checked_add(1).ok_or_else(peer_identity_error)?;
        let result = async {
            let plaintext =
                serde_json::to_vec(&plist::to_value(&request).map_err(|_| peer_identity_error())?)
                    .map_err(|_| peer_identity_error())?;
            let mut nonce_bytes = [0u8; 12];
            nonce_bytes[..8].copy_from_slice(&counter.to_le_bytes());
            let nonce = Nonce::from_slice(&nonce_bytes);
            let ciphertext = self
                .client_cipher
                .encrypt(
                    nonce,
                    Payload {
                        msg: &plaintext,
                        aad: &[],
                    },
                )
                .map_err(|_| peer_identity_error())?;
            self.inner.send_encrypted(ciphertext, sequence).await?;
            let response = self.inner.recv_plain().await?;
            let encrypted = response
                .get_by("message")
                .and_then(|value| value.get_by("streamEncrypted"))
                .and_then(|value| value.get_by("_0"))
                .and_then(|value| R::deserialize_bytes(value.to_owned()))
                .ok_or_else(peer_identity_error)?;
            let clear = self
                .server_cipher
                .decrypt(
                    nonce,
                    Payload {
                        msg: &encrypted,
                        aad: &[],
                    },
                )
                .map_err(|_| peer_identity_error())?;
            let value: plist::Value =
                serde_json::from_slice(&clear).map_err(|_| peer_identity_error())?;
            value
                .get_by("response")
                .and_then(|value| value.get_by("_1"))
                .cloned()
                .ok_or_else(peer_identity_error)
        }
        .await;
        if result.is_ok() {
            self.peer_authenticated = true;
        }
        result
    }

    /// Send a request to create a TCP tunnel listener on the device.
    /// Returns the port the device is listening on.
    ///
    /// Not every endpoint that accepts pairing serves this. tvOS advertises a
    /// second `_remotepairing-manual-pairing._tcp` service which handles both
    /// pair-setup and pair-verify but reportedly rejects this request, so a device
    /// paired over that service must be reconnected over `_remotepairing._tcp`
    /// before a tunnel can be requested.
    pub async fn create_tcp_listener(&mut self) -> Result<u16, IdeviceError> {
        if !self.peer_authenticated {
            return Err(peer_identity_error());
        }
        let request = plist!({
            "request": {
                "_0": {
                    "createListener": {
                        "key": base64::engine::general_purpose::STANDARD.encode(&self.encryption_key),
                        "transportProtocolType": "tcp"
                    }
                }
            }
        });

        let response = self.send_receive_encrypted_request(request).await?;

        let port = response
            .get_by("createListener")
            .and_then(|c| c.get_by("port"))
            .and_then(|p| p.as_unsigned_integer())
            .ok_or_else(|| peer_identity_error())?;

        u16::try_from(port)
            .ok()
            .filter(|port| *port != 0)
            .ok_or_else(peer_identity_error)
    }

    async fn send_pairing_data(
        &mut self,
        pairing_data: impl Serialize + PlistConvertible,
    ) -> Result<(), IdeviceError> {
        self.inner
            .send_plain(
                plist!({
                    "event": {
                        "_0": {
                            "pairingData": {
                                "_0": pairing_data
                            }
                        }
                    }
                }),
                self.sequence_number,
            )
            .await?;

        self.sequence_number += 1;
        Ok(())
    }

    async fn receive_pairing_data(&mut self) -> Result<plist::Value, IdeviceError> {
        let response = self.inner.recv_plain().await?;

        let response = match response.get_by("event").and_then(|x| x.get_by("_0")) {
            Some(r) => r,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "missing event._0 in pairing data response".into(),
                ));
            }
        };

        if let Some(data) = response
            .get_by("pairingData")
            .and_then(|x| x.get_by("_0"))
            .and_then(|x| x.get_by("data"))
        {
            Ok(data.to_owned())
        } else if let Some(err) = response.get_by("pairingRejectedWithError") {
            let context = err
                .get_by("wrappedError")
                .and_then(|x| x.get_by("userInfo"))
                .and_then(|x| x.get_by("NSLocalizedDescription"))
                .and_then(|x| x.as_string())
                .map(|x| x.to_string());
            Err(RemotePairingError::PairingRejected(context.unwrap_or_default()).into())
        } else {
            Err(IdeviceError::UnexpectedResponse(
                "pairing data response contained neither data nor rejection".into(),
            ))
        }
    }
}

impl<R: RpPairingSocketProvider> std::fmt::Debug for RemotePairingClient<R> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("RemotePairingClient")
            .field("inner", &self.inner)
            .field("sequence_number", &self.sequence_number)
            .field("sending_host", &self.sending_host)
            .finish()
    }
}

#[cfg(test)]
mod secure_identity_tests {
    use super::*;
    use ed25519_dalek::SigningKey;
    #[derive(Debug)]
    struct FailingSocket(std::sync::Arc<std::sync::atomic::AtomicUsize>);
    impl RpPairingSocketProvider for FailingSocket {
        fn send_plain(
            &mut self,
            _: impl Serialize,
            _: usize,
        ) -> std::pin::Pin<
            Box<dyn std::future::Future<Output = Result<(), IdeviceError>> + Send + '_>,
        > {
            Box::pin(async { Err(peer_identity_error()) })
        }
        fn send_encrypted(
            &mut self,
            _: Vec<u8>,
            _: usize,
        ) -> std::pin::Pin<
            Box<dyn std::future::Future<Output = Result<(), IdeviceError>> + Send + '_>,
        > {
            self.0.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
            Box::pin(async { Err(peer_identity_error()) })
        }
        fn recv_plain<'a>(
            &'a mut self,
        ) -> std::pin::Pin<
            Box<dyn std::future::Future<Output = Result<plist::Value, IdeviceError>> + Send + 'a>,
        > {
            Box::pin(async { Err(peer_identity_error()) })
        }
        fn serialize_bytes(bytes: &[u8]) -> plist::Value {
            plist::Value::Data(bytes.to_vec())
        }
        fn deserialize_bytes(value: plist::Value) -> Option<Vec<u8>> {
            value.into_data()
        }
    }

    fn accessory_entries(key: &SigningKey, id: &str, session: &[u8]) -> Vec<tlv::TLV8Entry> {
        let mut material = [0u8; 32];
        Hkdf::<Sha512>::new(Some(b"Pair-Setup-Accessory-Sign-Salt"), session)
            .expand(b"Pair-Setup-Accessory-Sign-Info", &mut material)
            .unwrap();
        let mut message = material.to_vec();
        message.extend_from_slice(id.as_bytes());
        message.extend_from_slice(key.verifying_key().as_bytes());
        let signature = key.clone().sign(&message);
        vec![
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Identifier,
                data: id.as_bytes().to_vec(),
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::PublicKey,
                data: key.verifying_key().to_bytes().to_vec(),
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Signature,
                data: signature.to_bytes().to_vec(),
            },
        ]
    }
    #[test]
    fn rp_auth_trusted_setup_signature_and_strict_export_reject_substitution() {
        let accessory = SigningKey::generate(&mut OsRng);
        let session = [9u8; 64];
        let entries = accessory_entries(&accessory, "TEST_DEVICE", &session);
        let (id, pin) = verify_setup_accessory(&entries, &session).unwrap();
        let mut record = RpPairingFile::generate("synthetic-host");
        assert!(record.to_pinned_bytes().is_err());
        record.peer_identifier = Some(id);
        record.peer_public_key = Some(pin);
        let encoded = record.to_pinned_bytes().unwrap();
        let decoded = RpPairingFile::from_bytes(&encoded).unwrap();
        assert!(decoded.has_peer_pin());
        assert_eq!(decoded.peer_public_key, Some(accessory.verifying_key()));
        assert!(!format!("{decoded:?}").contains("TEST_DEVICE"));
        for index in 0..3 {
            let mut tampered = entries.clone();
            tampered[index].data[0] ^= 1;
            assert!(verify_setup_accessory(&tampered, &session).is_err());
        }
        assert!(verify_setup_accessory(&entries, &[8u8; 64]).is_err());
        let mut duplicate = entries.clone();
        duplicate.push(entries[0].clone());
        assert!(verify_setup_accessory(&duplicate, &session).is_err());
        let mut payload: plist::Dictionary = plist::from_bytes(&encoded).unwrap();
        payload.remove("app_installer_rp_version");
        let mut unversioned = Vec::new();
        plist::to_writer_xml(&mut unversioned, &payload).unwrap();
        assert!(RpPairingFile::from_bytes(&unversioned).is_err());
        payload.insert(
            "app_installer_rp_version".into(),
            plist::Value::Integer(2u64.into()),
        );
        payload.insert(
            "public_key".into(),
            plist::Value::Data(accessory.verifying_key().to_bytes().to_vec()),
        );
        let mut mismatched = Vec::new();
        plist::to_writer_xml(&mut mismatched, &payload).unwrap();
        assert!(RpPairingFile::from_bytes(&mismatched).is_err());
        assert!(strict_tlv(&[6, 1, 2, 255]).is_err());
    }
    #[test]
    fn rp_auth_verify_requires_pinned_peer_and_authenticates_exact_ephemeral_transcript() {
        let accessory = SigningKey::generate(&mut OsRng);
        let mut record = RpPairingFile::generate("synthetic-host");
        record.peer_identifier = Some("TEST_DEVICE".into());
        record.peer_public_key = Some(accessory.verifying_key());
        let host_secret = EphemeralSecret::random_from_rng(OsRng);
        let host_public = X25519PublicKey::from(&host_secret);
        let device_secret = EphemeralSecret::random_from_rng(OsRng);
        let device_public = X25519PublicKey::from(&device_secret);
        let shared = host_secret.diffie_hellman(&device_public);
        assert!(shared.was_contributory());
        let mut key = [0u8; 32];
        Hkdf::<Sha512>::new(Some(b"Pair-Verify-Encrypt-Salt"), shared.as_bytes())
            .expand(b"Pair-Verify-Encrypt-Info", &mut key)
            .unwrap();
        let cipher = ChaCha20Poly1305::new(Key::from_slice(&key));
        let mut message = device_public.as_bytes().to_vec();
        message.extend_from_slice(b"TEST_DEVICE");
        message.extend_from_slice(host_public.as_bytes());
        let signature = accessory.clone().sign(&message);
        let clear = tlv::serialize_tlv8(&[
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Identifier,
                data: b"TEST_DEVICE".to_vec(),
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::Signature,
                data: signature.to_bytes().to_vec(),
            },
        ]);
        let encrypted = cipher
            .encrypt(
                Nonce::from_slice(b"\x00\x00\x00\x00PV-Msg02"),
                Payload {
                    msg: &clear,
                    aad: &[],
                },
            )
            .unwrap();
        let entries = vec![
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::State,
                data: vec![2],
            },
            tlv::TLV8Entry {
                tlv_type: tlv::PairingDataComponentType::EncryptedData,
                data: encrypted,
            },
        ];
        assert!(
            verify_pair_verify_peer(
                &entries,
                &cipher,
                &record,
                device_public.as_bytes(),
                host_public.as_bytes()
            )
            .is_ok()
        );
        let mut altered_host = *host_public.as_bytes();
        altered_host[0] ^= 1;
        assert!(
            verify_pair_verify_peer(
                &entries,
                &cipher,
                &record,
                device_public.as_bytes(),
                &altered_host
            )
            .is_err()
        );
        let mut foreign = record.clone();
        foreign.peer_public_key = Some(SigningKey::generate(&mut OsRng).verifying_key());
        assert!(
            verify_pair_verify_peer(
                &entries,
                &cipher,
                &foreign,
                device_public.as_bytes(),
                host_public.as_bytes()
            )
            .is_err()
        );
        foreign = record.clone();
        foreign.peer_identifier = Some("OTHER_DEVICE".into());
        assert!(
            verify_pair_verify_peer(
                &entries,
                &cipher,
                &foreign,
                device_public.as_bytes(),
                host_public.as_bytes()
            )
            .is_err()
        );
        let mut tampered = entries.clone();
        tampered[1].data[0] ^= 1;
        assert!(
            verify_pair_verify_peer(
                &tampered,
                &cipher,
                &record,
                device_public.as_bytes(),
                host_public.as_bytes()
            )
            .is_err()
        );
        let mut wrong_state = entries.clone();
        wrong_state[0].data[0] = 4;
        assert!(
            verify_pair_verify_peer(
                &wrong_state,
                &cipher,
                &record,
                device_public.as_bytes(),
                host_public.as_bytes()
            )
            .is_err()
        );
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .unwrap()
            .block_on(async {
                let sends = std::sync::Arc::new(std::sync::atomic::AtomicUsize::new(0));
                let mut client = RemotePairingClient::new(FailingSocket(sends.clone()), "fixture");
                client.peer_authenticated = true;
                assert!(
                    client
                        .send_receive_encrypted_request(plist!({"request":"fixture"}))
                        .await
                        .is_err()
                );
                assert_eq!(client.encrypted_sequence_number, 1);
                assert!(client.encryption_key().is_empty());
                assert!(
                    client
                        .send_receive_encrypted_request(plist!({"different":"request"}))
                        .await
                        .is_err()
                );
                assert_eq!(sends.load(std::sync::atomic::Ordering::SeqCst), 1);
                client.peer_authenticated = true;
                client.encrypted_sequence_number = u64::MAX;
                assert!(
                    client
                        .send_receive_encrypted_request(plist!({"request":"exhausted"}))
                        .await
                        .is_err()
                );
                assert!(!client.peer_authenticated);
                assert_eq!(sends.load(std::sync::atomic::Ordering::SeqCst), 1);
            });
        let host = EphemeralSecret::random_from_rng(OsRng);
        assert!(
            !host
                .diffie_hellman(&X25519PublicKey::from([0u8; 32]))
                .was_contributory()
        );
    }
}

#[cfg(test)]
mod setup_wire_tests {
    use super::*;
    use ed25519_dalek::SigningKey;
    use idevice_srp::server::SrpServer;
    use std::{collections::VecDeque, future::Future, pin::Pin};

    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    enum ReplyMode {
        Success,
        BadServerProof,
        BadAccessorySignature,
        DuplicateAccessoryIdentity,
    }
    struct StrictSetupPeer {
        mode: ReplyMode,
        consent_event: bool,
        phase: u8,
        responses: VecDeque<plist::Value>,
        key: Vec<u8>,
        accessory: SigningKey,
        b: [u8; 32],
        salt: [u8; 16],
        verifier: Vec<u8>,
    }
    impl std::fmt::Debug for StrictSetupPeer {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            f.debug_struct("StrictSetupPeer")
                .field("phase", &self.phase)
                .finish_non_exhaustive()
        }
    }
    // Independent wire decoder: a repeated type continues the same logical
    // value only when the previous fragment occupied all 255 payload bytes.
    fn read_wire(bytes: &[u8]) -> Result<Vec<tlv::TLV8Entry>, IdeviceError> {
        let mut fields: Vec<tlv::TLV8Entry> = Vec::new();
        let mut offset = 0;
        let mut previous = None;
        while offset < bytes.len() {
            let header = bytes
                .get(offset..offset + 2)
                .ok_or_else(peer_identity_error)?;
            let kind = tlv::PairingDataComponentType::try_from(header[0])
                .map_err(|_| peer_identity_error())?;
            let length = usize::from(header[1]);
            offset += 2;
            let data = bytes
                .get(offset..offset + length)
                .ok_or_else(peer_identity_error)?;
            offset += length;
            if let Some((old_kind, old_length)) = previous {
                if old_kind == kind {
                    if old_length != 255 {
                        return Err(peer_identity_error());
                    }
                    fields.last_mut().unwrap().data.extend_from_slice(data);
                    previous = Some((kind, length));
                    continue;
                }
            }
            fields.push(tlv::TLV8Entry {
                tlv_type: kind,
                data: data.to_vec(),
            });
            previous = Some((kind, length));
        }
        Ok(fields)
    }
    fn field(kind: tlv::PairingDataComponentType, bytes: impl Into<Vec<u8>>) -> tlv::TLV8Entry {
        tlv::TLV8Entry {
            tlv_type: kind,
            data: bytes.into(),
        }
    }
    impl StrictSetupPeer {
        fn new(mode: ReplyMode, consent_event: bool) -> Self {
            let salt = [7; 16];
            let verifier =
                SrpClient::<Sha512>::new(&G_3072).compute_verifier(b"Pair-Setup", b"000000", &salt);
            Self {
                mode,
                consent_event,
                phase: 0,
                responses: VecDeque::new(),
                key: Vec::new(),
                accessory: SigningKey::generate(&mut OsRng),
                b: [42; 32],
                salt,
                verifier,
            }
        }
        fn respond(&mut self, entries: &[tlv::TLV8Entry]) {
            let data = plist::Value::Data(tlv::serialize_tlv8(entries));
            self.responses
                .push_back(plist!({"event":{"_0":{"pairingData":{"_0":{"data":data}}}}}));
        }
        fn process(&mut self, value: plist::Value) -> Result<(), IdeviceError> {
            use tlv::PairingDataComponentType::*;
            let data = value
                .get_by("event")
                .and_then(|v| v.get_by("_0"))
                .and_then(|v| v.get_by("pairingData"))
                .and_then(|v| v.get_by("_0"))
                .and_then(|v| v.get_by("data"))
                .and_then(plist::Value::as_data)
                .ok_or_else(peer_identity_error)?;
            let fields = read_wire(data)?;
            match self.phase {
                0 => {
                    require_state(&fields, 1)?;
                    if self.consent_event {
                        self.responses
                            .push_back(plist!({"event":{"_0":{"awaitingUserConsent":{}}}}));
                    }
                    let public = SrpServer::<Sha512>::new(&G_3072)
                        .compute_public_ephemeral(&self.b, &self.verifier);
                    self.respond(&[
                        field(State, [2]),
                        field(Salt, self.salt),
                        field(PublicKey, public),
                    ]);
                }
                1 => {
                    require_state(&fields, 3)?;
                    let a = one_component(&fields, PublicKey)?;
                    let server = SrpServer::<Sha512>::new(&G_3072)
                        .process_reply(&self.b, &self.verifier, a, b"Pair-Setup", &self.salt)
                        .map_err(|_| peer_identity_error())?;
                    server
                        .verify_client(one_component(&fields, Proof)?)
                        .map_err(|_| peer_identity_error())?;
                    self.key = server.key().to_vec();
                    let mut proof = server.proof().to_vec();
                    if self.mode == ReplyMode::BadServerProof {
                        proof[0] ^= 1;
                    }
                    self.respond(&[field(State, [4]), field(Proof, proof)]);
                }
                2 => {
                    require_state(&fields, 5)?;
                    let mut key = [0; 32];
                    Hkdf::<Sha512>::new(Some(b"Pair-Setup-Encrypt-Salt"), &self.key)
                        .expand(b"Pair-Setup-Encrypt-Info", &mut key)
                        .unwrap();
                    let cipher = ChaCha20Poly1305::new(Key::from_slice(&key));
                    let plain = cipher
                        .decrypt(
                            Nonce::from_slice(b"\0\0\0\0PS-Msg05"),
                            one_component(&fields, EncryptedData)?,
                        )
                        .map_err(|_| peer_identity_error())?;
                    let identity = read_wire(&plain)?;
                    let mut controller_x = [0; 32];
                    Hkdf::<Sha512>::new(Some(b"Pair-Setup-Controller-Sign-Salt"), &self.key)
                        .expand(b"Pair-Setup-Controller-Sign-Info", &mut controller_x)
                        .unwrap();
                    let host_id = one_component(&identity, Identifier)?;
                    let host_key: &[u8; 32] = one_component(&identity, PublicKey)?
                        .try_into()
                        .map_err(|_| peer_identity_error())?;
                    let mut signed = controller_x.to_vec();
                    signed.extend_from_slice(host_id);
                    signed.extend_from_slice(host_key);
                    ed25519_dalek::VerifyingKey::from_bytes(host_key)
                        .map_err(|_| peer_identity_error())?
                        .verify_strict(
                            &signed,
                            &ed25519_dalek::Signature::from_slice(one_component(
                                &identity,
                                tlv::PairingDataComponentType::Signature,
                            )?)
                            .map_err(|_| peer_identity_error())?,
                        )
                        .map_err(|_| peer_identity_error())?;
                    let host_info = opack::opack_to_plist(one_component(&identity, Info)?)
                        .map_err(|_| peer_identity_error())?;
                    assert!(
                        host_info
                            .get_by("name")
                            .and_then(plist::Value::as_string)
                            .unwrap()
                            .len()
                            > 255
                    );
                    let id = b"SYNTHETIC_DEVICE";
                    let mut accessory_x = [0; 32];
                    Hkdf::<Sha512>::new(Some(b"Pair-Setup-Accessory-Sign-Salt"), &self.key)
                        .expand(b"Pair-Setup-Accessory-Sign-Info", &mut accessory_x)
                        .unwrap();
                    let mut signed = accessory_x.to_vec();
                    signed.extend_from_slice(id);
                    signed.extend_from_slice(self.accessory.verifying_key().as_bytes());
                    let mut signature = self.accessory.sign(&signed).to_bytes();
                    if self.mode == ReplyMode::BadAccessorySignature {
                        signature[0] ^= 1;
                    }
                    let info = opack::plist_to_opack(
                        &plist!({"accountID":"SYNTHETIC_DEVICE","altIRK":vec![9u8;16],"model":"iPhoneSynthetic","name":"Synthetic Device","remotepairing_udid":"SYNTHETIC_NOT_REAL"}),
                    );
                    let mut entries = vec![
                        field(Identifier, id.to_vec()),
                        field(PublicKey, self.accessory.verifying_key().to_bytes()),
                        field(tlv::PairingDataComponentType::Signature, signature),
                        field(Info, info),
                    ];
                    if self.mode == ReplyMode::DuplicateAccessoryIdentity {
                        entries.push(field(Identifier, id.to_vec()));
                    }
                    let encrypted = cipher
                        .encrypt(
                            Nonce::from_slice(b"\0\0\0\0PS-Msg06"),
                            tlv::serialize_tlv8(&entries).as_slice(),
                        )
                        .unwrap();
                    self.respond(&[field(State, [6]), field(EncryptedData, encrypted)]);
                }
                _ => return Err(peer_identity_error()),
            }
            self.phase += 1;
            Ok(())
        }
    }
    impl RpPairingSocketProvider for StrictSetupPeer {
        fn send_plain(
            &mut self,
            value: impl Serialize,
            _: usize,
        ) -> Pin<Box<dyn Future<Output = Result<(), IdeviceError>> + Send + '_>> {
            let result = plist::to_value(&value)
                .map_err(|_| peer_identity_error())
                .and_then(|value| self.process(value));
            Box::pin(async move { result })
        }
        fn send_encrypted(
            &mut self,
            _: Vec<u8>,
            _: usize,
        ) -> Pin<Box<dyn Future<Output = Result<(), IdeviceError>> + Send + '_>> {
            Box::pin(async { Err(peer_identity_error()) })
        }
        fn recv_plain<'a>(
            &'a mut self,
        ) -> Pin<Box<dyn Future<Output = Result<plist::Value, IdeviceError>> + Send + 'a>> {
            let result = self.responses.pop_front().ok_or_else(peer_identity_error);
            Box::pin(async move { result })
        }
        fn serialize_bytes(bytes: &[u8]) -> plist::Value {
            plist::Value::Data(bytes.to_vec())
        }
        fn deserialize_bytes(value: plist::Value) -> Option<Vec<u8>> {
            value.into_data()
        }
    }
    #[tokio::test]
    async fn rp_setup_wire_actual_srp_and_m6_require_canonical_fragments_and_authenticated_peer() {
        for consent_event in [false, true] {
            for mode in [
                ReplyMode::Success,
                ReplyMode::BadServerProof,
                ReplyMode::BadAccessorySignature,
                ReplyMode::DuplicateAccessoryIdentity,
            ] {
                let peer = StrictSetupPeer::new(mode, consent_event);
                let pin = peer.accessory.verifying_key();
                let mut client = RemotePairingClient::new(peer, &"x".repeat(600));
                let mut record = RpPairingFile::generate("synthetic-host");
                let mut stages = Vec::new();
                let result = client
                    .pair_with_progress(
                        &mut record,
                        || async { "000000".into() },
                        |stage| stages.push(stage),
                    )
                    .await;
                assert_eq!(stages.first(), Some(&PairingStage::Consent));
                if mode == ReplyMode::Success {
                    result.unwrap();
                    assert_eq!(
                        stages,
                        vec![
                            PairingStage::Consent,
                            PairingStage::SrpProof,
                            PairingStage::PeerRecord,
                            PairingStage::PeerIdentity
                        ]
                    );
                    assert_eq!(record.peer_public_key, Some(pin));
                    assert_eq!(record.peer_identifier.as_deref(), Some("SYNTHETIC_DEVICE"));
                    assert!(
                        RpPairingFile::from_bytes(&record.to_pinned_bytes().unwrap())
                            .unwrap()
                            .has_peer_pin()
                    );
                } else {
                    assert!(result.is_err());
                    assert!(!record.has_peer_pin());
                    assert!(record.to_pinned_bytes().is_err());
                    assert!(client.authenticated_encryption_key().is_err());
                    if mode == ReplyMode::BadServerProof {
                        assert_eq!(stages.last(), Some(&PairingStage::SrpProof));
                    } else {
                        assert_eq!(stages.last(), Some(&PairingStage::PeerIdentity));
                    }
                }
            }
        }
    }
}
