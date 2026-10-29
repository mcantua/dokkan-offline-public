// Original idevice implementation: Jackson Coxson. MIT license retained in LICENSE.txt.
// Local App Installer security patch to idevice 0.1.68.
// Devices use pairing-issued identities rather than DNS/WebPKI names. Trust is
// the exact device certificate imported in the authenticated pairing record,
// together with cryptographic TLS handshake proof that the peer owns its key.
// See ../PATCHES.md in the enclosing downloads/idevice directory.

use rustls::{
    ClientConfig, DigitallySignedStruct,
    client::{
        WebPkiServerVerifier,
        danger::{HandshakeSignatureValid, ServerCertVerified, ServerCertVerifier},
    },
    pki_types::{CertificateDer, PrivateKeyDer, ServerName, UnixTime, pem::PemObject},
};
use std::sync::Arc;

use crate::{IdeviceError, pairing_file::PairingFile};

#[derive(Debug)]
pub struct PairingCertificateVerifier {
    inner: Arc<WebPkiServerVerifier>,
    paired_device_certificate: CertificateDer<'static>,
}

impl PairingCertificateVerifier {
    pub fn new(
        inner: Arc<WebPkiServerVerifier>,
        paired_device_certificate: CertificateDer<'static>,
    ) -> Self {
        Self { inner, paired_device_certificate }
    }

    fn verify_pairing_pin(&self, certificate: &CertificateDer<'_>) -> Result<(), rustls::Error> {
        // Certificates are public identity data. The complete DER identity must
        // match; an untrusted cert with the same subject/name/public-key text
        // or an untrusted CA chain is not accepted as a substitute.
        if certificate.as_ref() == self.paired_device_certificate.as_ref() {
            Ok(())
        } else {
            Err(rustls::Error::InvalidCertificate(
                rustls::CertificateError::ApplicationVerificationFailure,
            ))
        }
    }
}

impl ServerCertVerifier for PairingCertificateVerifier {
    fn verify_server_cert(
        &self,
        end_entity: &CertificateDer<'_>,
        _intermediates: &[CertificateDer<'_>],
        _server_name: &ServerName<'_>,
        _ocsp: &[u8],
        _now: UnixTime,
    ) -> Result<ServerCertVerified, rustls::Error> {
        // No DNS name exists for this device identity. Exact pairing pinning
        // is the trust decision; handshake methods below verify possession.
        self.verify_pairing_pin(end_entity)?;
        Ok(ServerCertVerified::assertion())
    }

    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        self.verify_pairing_pin(cert)?;
        self.inner.verify_tls12_signature(message, cert, dss)
    }

    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        self.verify_pairing_pin(cert)?;
        self.inner.verify_tls13_signature(message, cert, dss)
    }

    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        self.inner.supported_verify_schemes()
    }
}

pub fn create_client_config(pairing_file: &PairingFile) -> Result<ClientConfig, IdeviceError> {
    let mut root_store = rustls::RootCertStore::empty();
    root_store.add(pairing_file.root_certificate.clone())?;
    let private_key = PrivateKeyDer::from_pem_slice(&pairing_file.host_private_key)?;

    let mut config = ClientConfig::builder()
        .with_root_certificates(root_store.clone())
        .with_client_auth_cert(vec![pairing_file.host_certificate.clone()], private_key)?;

    let inner = WebPkiServerVerifier::builder(Arc::new(root_store)).build()?;
    let verifier = Arc::new(PairingCertificateVerifier::new(
        inner,
        pairing_file.device_certificate.clone(),
    ));
    // The rustls custom-verifier API is named dangerous(); this verifier enforces
    // a pairing pin and real handshake signatures rather than bypassing checks.
    config.dangerous().set_certificate_verifier(verifier);

    Ok(config)
}

#[cfg(all(test, feature = "ring"))]
mod tests {
    use super::*;
    use rustls::{
        ClientConnection, ServerConfig, ServerConnection, SignatureAlgorithm, SignatureScheme,
        sign::{CertifiedKey, Signer, SigningKey, SingleCertAndKey},
        pki_types::{PrivatePkcs8KeyDer, SubjectPublicKeyInfoDer},
    };
    use std::{
        io::{Cursor, Read, Write},
        sync::atomic::{AtomicUsize, Ordering},
    };

    // Test credentials exist only in RAM. No fixture keys, sockets, Apple account,
    // filesystem certificate material, VPN connection or device is used.
    struct EphemeralIdentity {
        certificate: CertificateDer<'static>,
        private_key: PrivateKeyDer<'static>,
        private_key_pem: Vec<u8>,
    }

    fn identity() -> EphemeralIdentity {
        let generated = rcgen::generate_simple_self_signed(vec!["pairing-test.invalid".into()])
            .expect("generate ephemeral test identity");
        EphemeralIdentity {
            certificate: generated.cert.der().clone(),
            private_key: PrivatePkcs8KeyDer::from(generated.signing_key.serialize_der()).into(),
            private_key_pem: generated.signing_key.serialize_pem().into_bytes(),
        }
    }

    fn pairing(device: &EphemeralIdentity, host: &EphemeralIdentity) -> PairingFile {
        PairingFile {
            device_certificate: device.certificate.clone(),
            host_private_key: host.private_key_pem.clone(),
            host_certificate: host.certificate.clone(),
            root_private_key: vec![], // Not consumed by client TLS configuration.
            root_certificate: device.certificate.clone(),
            system_buid: "offline-test-system".into(),
            host_id: "offline-test-host".into(),
            escrow_bag: None,
            wifi_mac_address: String::new(),
            udid: None,
        }
    }

    #[derive(Debug)]
    struct TamperingKey {
        inner: Arc<dyn SigningKey>,
        signatures: Arc<AtomicUsize>,
    }

    impl SigningKey for TamperingKey {
        fn choose_scheme(&self, offered: &[SignatureScheme]) -> Option<Box<dyn Signer>> {
            self.inner.choose_scheme(offered).map(|inner| {
                Box::new(TamperingSigner {
                    inner,
                    signatures: self.signatures.clone(),
                }) as Box<dyn Signer>
            })
        }
        fn public_key(&self) -> Option<SubjectPublicKeyInfoDer<'_>> {
            self.inner.public_key()
        }
        fn algorithm(&self) -> SignatureAlgorithm { self.inner.algorithm() }
    }

    #[derive(Debug)]
    struct TamperingSigner {
        inner: Box<dyn Signer>,
        signatures: Arc<AtomicUsize>,
    }

    impl Signer for TamperingSigner {
        fn sign(&self, message: &[u8]) -> Result<Vec<u8>, rustls::Error> {
            let mut signature = self.inner.sign(message)?;
            // Preserve the ECDSA DER structure but invalidate its final integer byte.
            let last = signature.last_mut().expect("nonempty generated signature");
            *last ^= 1;
            self.signatures.fetch_add(1, Ordering::SeqCst);
            Ok(signature)
        }
        fn scheme(&self) -> SignatureScheme { self.inner.scheme() }
    }

    fn server(
        device: &EphemeralIdentity,
        protocol: &'static rustls::SupportedProtocolVersion,
        tampered: Option<Arc<AtomicUsize>>,
    ) -> ServerConnection {
        let builder = ServerConfig::builder_with_protocol_versions(&[protocol]).with_no_client_auth();
        let signing_key = rustls::crypto::ring::sign::any_supported_type(&device.private_key)
            .expect("load ephemeral server key");
        let key: Arc<dyn SigningKey> = match tampered {
            Some(signatures) => Arc::new(TamperingKey { inner: signing_key, signatures }),
            None => signing_key,
        };
        let certified = CertifiedKey::new(vec![device.certificate.clone()], key);
        let config = builder.with_cert_resolver(Arc::new(SingleCertAndKey::from(certified)));
        ServerConnection::new(Arc::new(config)).expect("create in-memory TLS server")
    }

    fn handshake(
        pairing: &PairingFile,
        mut server: ServerConnection,
    ) -> Result<(ClientConnection, ServerConnection), rustls::Error> {
        // Exercise the production client factory, not a test-only permissive verifier.
        let config = create_client_config(pairing).expect("create pinned client configuration");
        // Deliberately use a different DNS name: pairing identity, not DNS, is the anchor.
        let mut client = ClientConnection::new(
            Arc::new(config), ServerName::try_from("Device").expect("synthetic device name"),
        ).expect("create in-memory TLS client");
        for _ in 0..32 {
            let mut outbound = Vec::new();
            while client.wants_write() {
                client.write_tls(&mut outbound).expect("write TLS client bytes in RAM");
            }
            if !outbound.is_empty() {
                server.read_tls(&mut Cursor::new(outbound)).expect("read TLS client bytes in RAM");
                server.process_new_packets()?;
            }
            let mut outbound = Vec::new();
            while server.wants_write() {
                server.write_tls(&mut outbound).expect("write TLS server bytes in RAM");
            }
            if !outbound.is_empty() {
                client.read_tls(&mut Cursor::new(outbound)).expect("read TLS server bytes in RAM");
                client.process_new_packets()?;
            }
            if !client.is_handshaking() && !server.is_handshaking() {
                return Ok((client, server));
            }
        }
        panic!("bounded in-memory TLS handshake did not complete");
    }

    #[test]
    fn trusted_pairing_and_real_signature_complete_tls12_and_tls13() {
        let _ = rustls::crypto::ring::default_provider().install_default();
        let device = identity(); let host = identity();
        let paired = pairing(&device, &host);
        for protocol in [&rustls::version::TLS12, &rustls::version::TLS13] {
            let (mut client, mut server) = handshake(&paired, server(&device, protocol, None))
                .expect("trusted pin and valid private-key proof must authenticate");
            assert_eq!(client.protocol_version(), Some(protocol.version));
            assert_eq!(server.protocol_version(), Some(protocol.version));
            server.writer().write_all(b"authenticated device").expect("buffer application data");
            let mut encrypted = Vec::new();
            while server.wants_write() { server.write_tls(&mut encrypted).expect("encrypt in RAM"); }
            client.read_tls(&mut Cursor::new(encrypted)).expect("read encrypted data in RAM");
            client.process_new_packets().expect("authenticate application record");
            let mut plaintext = [0; 20];
            client.reader().read_exact(&mut plaintext).expect("decrypt application record");
            assert_eq!(&plaintext, b"authenticated device");
        }
    }

    #[test]
    fn substituted_identity_and_tampered_signature_fail_tls12_and_tls13() {
        let _ = rustls::crypto::ring::default_provider().install_default();
        let device = identity(); let host = identity(); let impostor = identity();
        let paired = pairing(&device, &host);
        for protocol in [&rustls::version::TLS12, &rustls::version::TLS13] {
            let substituted = handshake(&paired, server(&impostor, protocol, None));
            assert!(matches!(substituted, Err(rustls::Error::InvalidCertificate(
                rustls::CertificateError::ApplicationVerificationFailure
            ))), "a different, otherwise valid server certificate must fail the exact pairing pin");

            let signatures = Arc::new(AtomicUsize::new(0));
            let corrupted = handshake(&paired, server(&device, protocol, Some(signatures.clone())));
            assert!(signatures.load(Ordering::SeqCst) > 0, "the server must actually emit a tampered cryptographic signature");
            assert!(matches!(corrupted, Err(rustls::Error::InvalidCertificate(
                rustls::CertificateError::BadSignature
            ))), "a pinned certificate without a valid TLS handshake signature must fail");
        }
    }
}
