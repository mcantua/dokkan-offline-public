//! Remote Pairing

use crate::IdeviceError;
use base64::Engine as _;
use errors::RemotePairingError;

use chacha20poly1305::{
    ChaCha20Poly1305, Key, KeyInit, Nonce,
    aead::{Aead, Payload},
};
use ed25519_dalek::{Signature, VerifyingKey};
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
        &self.encryption_key
    }

    /// Performs the RPPairing handshake, then verifies an existing pinned peer.
    /// A newly generated in-memory identity uses explicit pair-setup instead.
    /// Failed verification never silently replaces a saved peer pin.
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
        self.attempt_pair_verify().await?;

        if pairing_file.peer_pin.is_some() {
            // A failed pinned verification must never silently replace the peer identity.
            self.validate_pairing(pairing_file).await?;
        } else {
            self.send_pair_verified_failed().await?;
            self.pair(pairing_file, pin_callback).await?;
        }
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
        let (peer_identifier, peer_signing_key) = pairing_file.peer_pin.clone()
            .ok_or_else(|| invalid_pairing("pair-verify requires an authenticated peer pin"))?;
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

        let data = tlv::deserialize_tlv8(&data)?;

        if data
            .iter()
            .any(|x| x.tlv_type == tlv::PairingDataComponentType::ErrorResponse)
        {
            self.send_pair_verified_failed().await?;
            return Err(RemotePairingError::PairVerifyFailed.into());
        }

        require_state(&data, 2)?;
        let peer_pub_bytes: [u8; 32] = logical_field(&data, tlv::PairingDataComponentType::PublicKey, 32, 32)?
            .try_into().map_err(|_| invalid_pairing("invalid pair-verify ephemeral key"))?;
        let device_public_key = x25519_dalek::PublicKey::from(peer_pub_bytes);
        let shared_secret = x_private_key.diffie_hellman(&device_public_key);
        if !shared_secret.was_contributory() {
            return Err(invalid_pairing("invalid pair-verify shared secret"));
        }
        let okm = derive_key(b"Pair-Verify-Encrypt-Salt", b"Pair-Verify-Encrypt-Info", shared_secret.as_bytes())?;
        let cipher = ChaCha20Poly1305::new(Key::from_slice(&okm));
        let encrypted = logical_field(&data, tlv::PairingDataComponentType::EncryptedData, 16, 65535)?;
        let plaintext = decrypt_identity_tlv(&cipher, b"\x00\x00\x00\x00PV-Msg02", &encrypted)?;
        verify_pair_verify_identity(&plaintext, &peer_identifier, &peer_signing_key,
            device_public_key.as_bytes(), x_public_key.as_bytes())?;

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
            .map_err(RemotePairingError::ChachaEncryption)?;

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
        let data = tlv::deserialize_tlv8(&data)?;

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
        // Commit the session secret only after both authenticated peer messages.
        self.encryption_key = shared_secret.as_bytes().to_vec();
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
        let (salt, public_key, pin) = self.request_pair_consent(pin_callback).await?;
        let key = self.init_srp_context(&salt, &public_key, &pin).await?;
        let mut staged = pairing_file.clone();
        let (tlv, peer_pin) = self.save_pair_record_on_peer(&mut staged, &key).await?;
        let peer_device = peer_device::parse_peer_device_from_tlv(&tlv)?;
        staged.alt_irk = Some(peer_device.alt_irk.clone());
        staged.peer_pin = Some(peer_pin);
        *pairing_file = staged;
        self.encryption_key = key;
        let (cc, sc) = Self::derive_main_ciphers(&self.encryption_key);
        self.client_cipher = cc;
        self.server_cipher = sc;
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

        let pairing_data = match if response.get("pairingRejectedWithError").is_some() {
            return Err(RemotePairingError::PairingRejected("peer declined pairing".into()).into());
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

        let tlv = tlv::deserialize_tlv8(&match R::deserialize_bytes(pairing_data) {
            Some(t) => t,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "failed to deserialize pairing data bytes in pair consent".into(),
                ));
            }
        })?;
        require_state(&tlv, 2)?;
        let salt = logical_field(&tlv, tlv::PairingDataComponentType::Salt, 16, 16)?;
        let public_key = logical_field(&tlv, tlv::PairingDataComponentType::PublicKey, 384, 384)?;

        let pin = match pin {
            Some(p) => p,
            None => pin_callback().await,
        };

        Ok((salt, public_key, pin))
    }

    /// Returns the encryption key
    async fn init_srp_context(
        &mut self,
        salt: &[u8],
        public_key: &[u8],
        pin: &str,
    ) -> Result<Vec<u8>, IdeviceError> {
        validate_pin(pin)?;
        if salt.len() != 16 || public_key.len() != 384 {
            return Err(invalid_pairing("invalid SRP salt or public key length"));
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
            pin.as_bytes(),
            salt,
            public_key,
            false,
        ) {
            Ok(v) => v,
            Err(_) => {
                warn!("SRP verifier creation failed");
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
        let response = tlv::deserialize_tlv8(&match R::deserialize_bytes(response.to_owned()) {
            Some(r) => r,
            None => {
                return Err(IdeviceError::UnexpectedResponse(
                    "failed to deserialize SRP proof response bytes".into(),
                ));
            }
        })?;

        require_state(&response, 4)?;
        let proof = logical_field(&response, tlv::PairingDataComponentType::Proof, 64, 64)?;

        match verifier.verify_server(&proof) {
            Ok(_) => Ok(verifier.key().to_vec()),
            Err(_) => {
                warn!("Server authentication failed");
                Err(RemotePairingError::SrpAuthFailed.into())
            }
        }
    }

    async fn save_pair_record_on_peer(
        &mut self,
        pairing_file: &mut RpPairingFile,
        encryption_key: &[u8],
    ) -> Result<(Vec<tlv::TLV8Entry>, (String, VerifyingKey)), IdeviceError> {
        let setup_encryption_key = derive_key(b"Pair-Setup-Encrypt-Salt", b"Pair-Setup-Encrypt-Info", encryption_key)?;

        pairing_file.recreate_signing_keys();

        if pairing_file.identifier.is_empty() || pairing_file.identifier.len() > 1024 {
            return Err(invalid_pairing("invalid host pairing identifier"));
        }
        let mut signbuf = Vec::with_capacity(32 + pairing_file.identifier.len() + 32);
        let hkdf_out = derive_key(b"Pair-Setup-Controller-Sign-Salt", b"Pair-Setup-Controller-Sign-Info", encryption_key)?;

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
                warn!("Pairing encryption failed");
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

        let tlv = tlv::deserialize_tlv8(&response)?;
        require_state(&tlv, 6)?;
        let encrypted_data = logical_field(&tlv, tlv::PairingDataComponentType::EncryptedData, 16, 65535)?;
        let tlv = decrypt_identity_tlv(&cipher, b"\x00\x00\x00\x00PS-Msg06", &encrypted_data)?;
        let peer_pin = verify_setup_identity(&tlv, encryption_key)?;
        Ok((tlv, peer_pin))
    }

    /// Send an encrypted request and receive an encrypted response.
    /// Used for post-pairing RPCs like creating tunnel listeners.
    pub async fn send_receive_encrypted_request(
        &mut self,
        request: plist::Value,
    ) -> Result<plist::Value, IdeviceError> {
        let plaintext = serde_json::to_vec(
            &plist::to_value(&request).map_err(|_| invalid_pairing("failed to encode pairing request"))?,
        )
        .map_err(|_| invalid_pairing("invalid pairing RPC encoding"))?;

        // Build nonce: 8-byte LE sequence number + 4 zero bytes
        let mut nonce_bytes = [0u8; 12];
        nonce_bytes[..8].copy_from_slice(&self.encrypted_sequence_number.to_le_bytes());
        let nonce = Nonce::from_slice(&nonce_bytes);

        let ciphertext = self
            .client_cipher
            .encrypt(
                nonce,
                Payload {
                    msg: &plaintext,
                    aad: b"",
                },
            )
            .map_err(|e| IdeviceError::RemotePairing(RemotePairingError::ChachaEncryption(e)))?;

        self.inner
            .send_encrypted(ciphertext, self.sequence_number)
            .await?;
        self.sequence_number += 1;

        // Receive encrypted response
        let response = self.inner.recv_plain().await?;
        let encrypted_data = response
            .get_by("message")
            .and_then(|m| m.get_by("streamEncrypted"))
            .and_then(|s| s.get_by("_0"))
            .and_then(|d| {
                // Could be bytes directly or base64
                R::deserialize_bytes(d.to_owned())
            })
            .ok_or(IdeviceError::UnexpectedResponse(
                "missing encrypted data in streamEncrypted response".into(),
            ))?;

        let decrypted = self
            .server_cipher
            .decrypt(
                nonce,
                Payload {
                    msg: &encrypted_data,
                    aad: b"",
                },
            )
            .map_err(|e| IdeviceError::RemotePairing(RemotePairingError::ChachaEncryption(e)))?;

        self.encrypted_sequence_number += 1;

        let value: plist::Value = serde_json::from_slice(&decrypted)
            .map_err(|_| invalid_pairing("invalid pairing RPC encoding"))?;

        // Extract response._1
        let result = value
            .get_by("response")
            .and_then(|r| r.get_by("_1"))
            .cloned()
            .ok_or(IdeviceError::UnexpectedResponse(
                "missing response._1 in encrypted response".into(),
            ))?;

        Ok(result)
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
            .filter(|port| *port > 0 && *port <= u16::MAX as u64)
            .ok_or_else(|| invalid_pairing("missing or invalid createListener port"))?;

        Ok(port as u16)
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
        } else if response.get_by("pairingRejectedWithError").is_some() {
            Err(RemotePairingError::PairingRejected("peer declined pairing".into()).into())
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
            .field("sequence_number", &self.sequence_number)
            .finish()
    }
}

fn invalid_pairing(message: &str) -> IdeviceError {
    IdeviceError::UnexpectedResponse(message.into())
}

fn validate_pin(pin: &str) -> Result<(), IdeviceError> {
    if pin.len() != 6 || !pin.bytes().all(|byte| byte.is_ascii_digit()) {
        return Err(invalid_pairing("pairing PIN must contain six ASCII digits"));
    }
    Ok(())
}

fn require_no_error(entries: &[tlv::TLV8Entry]) -> Result<(), IdeviceError> {
    if tlv::contains_component(entries, tlv::PairingDataComponentType::ErrorResponse) {
        return Err(RemotePairingError::PairVerifyFailed.into());
    }
    Ok(())
}

fn logical_field(entries: &[tlv::TLV8Entry], component: tlv::PairingDataComponentType,
    minimum: usize, maximum: usize) -> Result<Vec<u8>, IdeviceError> {
    let value = tlv::collect_unique_component_data(entries, component)?
        .ok_or_else(|| invalid_pairing("missing required pairing field"))?;
    if value.len() < minimum || value.len() > maximum {
        return Err(invalid_pairing("invalid pairing field length"));
    }
    Ok(value)
}

fn require_state(entries: &[tlv::TLV8Entry], expected: u8) -> Result<(), IdeviceError> {
    require_no_error(entries)?;
    let state = logical_field(entries, tlv::PairingDataComponentType::State, 1, 1)?;
    if state[0] != expected { return Err(invalid_pairing("unexpected pairing message state")); }
    Ok(())
}

fn derive_key(salt: &[u8], info: &[u8], secret: &[u8]) -> Result<[u8; 32], IdeviceError> {
    let mut key = [0; 32];
    Hkdf::<Sha512>::new(Some(salt), secret).expand(info, &mut key)
        .map_err(|_| invalid_pairing("pairing key derivation failed"))?;
    Ok(key)
}

fn decrypt_identity_tlv(cipher: &ChaCha20Poly1305, nonce: &[u8; 12], ciphertext: &[u8])
    -> Result<Vec<tlv::TLV8Entry>, IdeviceError> {
    let plaintext = cipher.decrypt(Nonce::from_slice(nonce), Payload { msg: ciphertext, aad: b"" })
        .map_err(RemotePairingError::ChachaEncryption)?;
    Ok(tlv::deserialize_tlv8(&plaintext)?)
}

fn identity_identifier(entries: &[tlv::TLV8Entry]) -> Result<String, IdeviceError> {
    let bytes = logical_field(entries, tlv::PairingDataComponentType::Identifier, 1, 1024)?;
    String::from_utf8(bytes).map_err(|_| invalid_pairing("pairing identifier is not UTF-8"))
}

fn identity_signature(entries: &[tlv::TLV8Entry]) -> Result<Signature, IdeviceError> {
    let bytes = logical_field(entries, tlv::PairingDataComponentType::Signature, 64, 64)?;
    Signature::from_slice(&bytes).map_err(|_| invalid_pairing("invalid peer signature length"))
}

fn verify_setup_identity(entries: &[tlv::TLV8Entry], shared_key: &[u8])
    -> Result<(String, VerifyingKey), IdeviceError> {
    require_no_error(entries)?;
    let identifier = identity_identifier(entries)?;
    let bytes: [u8; 32] = logical_field(entries, tlv::PairingDataComponentType::PublicKey, 32, 32)?
        .try_into().map_err(|_| invalid_pairing("invalid peer public key length"))?;
    let key = VerifyingKey::from_bytes(&bytes).map_err(|_| invalid_pairing("invalid peer public key"))?;
    let signature = identity_signature(entries)?;
    let material = derive_key(b"Pair-Setup-Accessory-Sign-Salt", b"Pair-Setup-Accessory-Sign-Info", shared_key)?;
    let mut signed = Vec::with_capacity(32 + identifier.len() + 32);
    signed.extend_from_slice(&material);
    signed.extend_from_slice(identifier.as_bytes());
    signed.extend_from_slice(&bytes);
    key.verify_strict(&signed, &signature).map_err(|_| invalid_pairing("pair-setup peer authentication failed"))?;
    Ok((identifier, key))
}

fn verify_pair_verify_identity(entries: &[tlv::TLV8Entry], pinned_identifier: &str,
    pinned_key: &VerifyingKey, accessory_ephemeral: &[u8; 32], host_ephemeral: &[u8; 32])
    -> Result<(), IdeviceError> {
    require_no_error(entries)?;
    let identifier = identity_identifier(entries)?;
    if identifier != pinned_identifier { return Err(invalid_pairing("pair-verify peer identity mismatch")); }
    let signature = identity_signature(entries)?;
    let mut signed = Vec::with_capacity(32 + identifier.len() + 32);
    signed.extend_from_slice(accessory_ephemeral);
    signed.extend_from_slice(identifier.as_bytes());
    signed.extend_from_slice(host_ephemeral);
    pinned_key.verify_strict(&signed, &signature)
        .map_err(|_| invalid_pairing("pair-verify peer authentication failed"))?;
    Ok(())
}

#[cfg(test)]
mod authentication_tests {
    use super::*;
    use ed25519_dalek::SigningKey;
    use tlv::{PairingDataComponentType as T, TLV8Entry};

    fn entry(tlv_type: T, data: Vec<u8>) -> TLV8Entry { TLV8Entry { tlv_type, data } }

    fn setup_identity(secret: &[u8], identifier: &str) -> Vec<TLV8Entry> {
        let mut key = SigningKey::from_bytes(&[7; 32]);
        let public = VerifyingKey::from(&key);
        let material = derive_key(b"Pair-Setup-Accessory-Sign-Salt", b"Pair-Setup-Accessory-Sign-Info", secret).unwrap();
        let mut message = material.to_vec();
        message.extend_from_slice(identifier.as_bytes());
        message.extend_from_slice(public.as_bytes());
        let signature: Signature = key.sign(&message);
        vec![entry(T::Identifier, identifier.as_bytes().to_vec()),
            entry(T::PublicKey, public.to_bytes().to_vec()), entry(T::Signature, signature.to_vec())]
    }

    #[test]
    fn authenticated_m6_requires_exact_identity_and_valid_signature() {
        let secret = [9; 64];
        let valid = setup_identity(&secret, "synthetic-accessory");
        assert_eq!(verify_setup_identity(&valid, &secret).unwrap().0, "synthetic-accessory");
        assert!(verify_setup_identity(&valid, &[8; 64]).is_err());
        for (index, replacement) in [
            (0, Vec::new()), (0, vec![b'x'; 1025]), (0, vec![0xff]),
            (1, vec![0; 31]), (2, vec![0; 63]), (2, vec![0; 64]),
        ] {
            let mut changed = valid.clone(); changed[index].data = replacement;
            assert!(verify_setup_identity(&changed, &secret).is_err());
        }
        let mut duplicate = valid.clone(); duplicate.push(valid[0].clone());
        assert!(verify_setup_identity(&duplicate, &secret).is_err());
        let mut separated_duplicate = valid.clone();
        separated_duplicate.push(entry(T::Separator, Vec::new()));
        separated_duplicate.push(valid[1].clone());
        assert!(verify_setup_identity(&separated_duplicate, &secret).is_err());
    }

    #[test]
    fn m6_aead_failure_is_an_error_and_long_identity_fragments_authenticate() {
        let secret = [9; 64];
        let identifier = "x".repeat(700);
        let valid = setup_identity(&secret, &identifier);
        let cipher = ChaCha20Poly1305::new(Key::from_slice(&[5; 32]));
        let nonce = b"\x00\x00\x00\x00PS-Msg06";
        let wire = tlv::serialize_tlv8(&valid);
        let mut encrypted = cipher.encrypt(Nonce::from_slice(nonce), wire.as_slice()).unwrap();
        let decrypted = decrypt_identity_tlv(&cipher, nonce, &encrypted).unwrap();
        assert_eq!(verify_setup_identity(&decrypted, &secret).unwrap().0, identifier);
        encrypted[0] ^= 1;
        assert!(decrypt_identity_tlv(&cipher, nonce, &encrypted).is_err());
        assert!(decrypt_identity_tlv(&cipher, nonce, &[]).is_err());
    }

    fn verify_identity(identifier: &str, accessory: &[u8; 32], host: &[u8; 32])
        -> (Vec<TLV8Entry>, VerifyingKey) {
        let mut signing_key = SigningKey::from_bytes(&[4; 32]);
        let mut message = accessory.to_vec();
        message.extend_from_slice(identifier.as_bytes()); message.extend_from_slice(host);
        let signature: Signature = signing_key.sign(&message);
        (vec![entry(T::Identifier, identifier.as_bytes().to_vec()), entry(T::Signature, signature.to_vec())],
            VerifyingKey::from(&signing_key))
    }

    #[test]
    fn pair_verify_m2_checks_pin_signature_and_both_ephemerals() {
        let accessory = [2; 32]; let host = [3; 32];
        let (valid, public) = verify_identity("synthetic-peer", &accessory, &host);
        assert!(verify_pair_verify_identity(&valid, "synthetic-peer", &public, &accessory, &host).is_ok());
        assert!(verify_pair_verify_identity(&valid, "different-peer", &public, &accessory, &host).is_err());
        assert!(verify_pair_verify_identity(&valid, "synthetic-peer", &public, &host, &accessory).is_err());
        let other = VerifyingKey::from(&SigningKey::from_bytes(&[8; 32]));
        assert!(verify_pair_verify_identity(&valid, "synthetic-peer", &other, &accessory, &host).is_err());
        let mut bad = valid.clone(); bad[1].data[0] ^= 1;
        assert!(verify_pair_verify_identity(&bad, "synthetic-peer", &public, &accessory, &host).is_err());
        let mut duplicate = valid.clone(); duplicate.push(valid[1].clone());
        assert!(verify_pair_verify_identity(&duplicate, "synthetic-peer", &public, &accessory, &host).is_err());
        let cipher = ChaCha20Poly1305::new(Key::from_slice(&[6; 32]));
        let nonce = b"\x00\x00\x00\x00PV-Msg02";
        let encrypted = cipher.encrypt(Nonce::from_slice(nonce), tlv::serialize_tlv8(&valid).as_slice()).unwrap();
        let recovered = decrypt_identity_tlv(&cipher, nonce, &encrypted).unwrap();
        assert!(verify_pair_verify_identity(&recovered, "synthetic-peer", &public, &accessory, &host).is_ok());
        assert!(decrypt_identity_tlv(&cipher, b"\x00\x00\x00\x00PV-Msg03", &encrypted).is_err());
    }

    #[test]
    fn short_or_non_ascii_pin_is_rejected_without_slicing() {
        for pin in ["", "1", "12345", "1234567", "abcdef", "１２３", "12 456"] {
            assert!(validate_pin(pin).is_err());
        }
        assert!(validate_pin("123456").is_ok());
    }

    #[test]
    fn message_state_and_cryptographic_field_lengths_fail_closed() {
        assert!(require_state(&[entry(T::State, vec![6])], 6).is_ok());
        for entries in [vec![], vec![entry(T::State, vec![4])], vec![entry(T::State, vec![6, 6])],
            vec![entry(T::State, vec![6]), entry(T::State, vec![6])],
            vec![entry(T::State, vec![6]), entry(T::ErrorResponse, vec![2])]] {
            assert!(require_state(&entries, 6).is_err());
        }
        let short_chunks = vec![entry(T::Identifier, vec![b'a'; 254]), entry(T::Identifier, vec![b'b'; 10])];
        assert!(logical_field(&short_chunks, T::Identifier, 1, 1024).is_err());
        let srp = vec![entry(T::PublicKey, vec![0x55; 384])];
        let encoded = tlv::serialize_tlv8(&srp);
        assert_eq!(encoded[1], 255);
        assert_eq!(encoded[258], 129);
        assert_eq!(logical_field(&tlv::deserialize_tlv8(&encoded).unwrap(), T::PublicKey, 384, 384).unwrap(), vec![0x55; 384]);
        for length in [16, 254, 255, 256, 510, 1024] {
            let m5 = vec![entry(T::EncryptedData, vec![0x66; length]), entry(T::State, vec![5])];
            let wire = tlv::serialize_tlv8(&m5);
            let decoded = tlv::deserialize_tlv8(&wire).unwrap();
            require_state(&decoded, 5).unwrap();
            assert_eq!(logical_field(&decoded, T::EncryptedData, 16, 65535).unwrap(), vec![0x66; length]);
        }
    }
}
