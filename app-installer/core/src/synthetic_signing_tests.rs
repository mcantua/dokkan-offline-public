//! These fixtures use RAM-only synthetic keys, certificates and profiles.
//! They are not Apple-issued, are never installable, and must fail production Apple trust.
use super::*;
use cms::{
    builder::{SignedDataBuilder, SignerInfoBuilder},
    cert::IssuerAndSerialNumber,
    signed_data::EncapsulatedContentInfo,
};
use der::asn1::Any;
use isideload::{
    dev::{app_ids::Profile as DeveloperProfile, teams::DeveloperTeam},
    sideload::{application::Application, cert_identity::CertificateIdentity},
};
use rsa::{pkcs1v15::SigningKey, rand_core::OsRng, signature::Keypair, RsaPrivateKey};
use std::{
    io::Write,
    path::PathBuf,
    str::FromStr,
    sync::{
        atomic::{AtomicU64, Ordering},
        OnceLock,
    },
    time::Duration,
};
use x509_cert::{
    builder::{Builder, CertificateBuilder, Profile},
    name::Name,
    serial_number::SerialNumber,
    time::{Time, Validity},
};
const TEAM: &str = "TESTTEAM01";
const ID: &str = "org.example.synthetic";
const DEVICE: &str = "synthetic-device-never-a-real-phone";
static NEXT: AtomicU64 = AtomicU64::new(1);
struct Material {
    key: RsaPrivateKey,
    leaf: Certificate,
    root: Certificate,
    profile: Vec<u8>,
    requested: Dictionary,
    grants: Dictionary,
    now: SystemTime,
}
fn material() -> &'static Material {
    static MATERIAL: OnceLock<Material> = OnceLock::new();
    MATERIAL.get_or_init(|| {
        let now = SystemTime::now();
        let validity = Validity {
            not_before: Time::try_from(now - Duration::from_secs(60)).unwrap(),
            not_after: Time::try_from(now + Duration::from_secs(24 * 3600)).unwrap(),
        };
        let root_key =
            SigningKey::<sha2_010::Sha256>::new(RsaPrivateKey::new(&mut OsRng, 2048).unwrap());
        let root_name = Name::from_str("CN=Cloud Synthetic Root,O=NOT Apple").unwrap();
        let root_spki =
            spki::SubjectPublicKeyInfoOwned::from_key(root_key.verifying_key()).unwrap();
        let root = CertificateBuilder::new(
            Profile::Root,
            SerialNumber::from(1u32),
            validity,
            root_name.clone(),
            root_spki,
            &root_key,
        )
        .unwrap()
        .build::<Signature>()
        .unwrap();
        let key = RsaPrivateKey::new(&mut OsRng, 2048).unwrap();
        let signing = SigningKey::<sha2_010::Sha256>::new(key.clone());
        let leaf_spki = spki::SubjectPublicKeyInfoOwned::from_key(signing.verifying_key()).unwrap();
        let mut builder = CertificateBuilder::new(
            Profile::Leaf {
                issuer: root_name,
                enable_key_agreement: false,
                enable_key_encipherment: false,
            },
            SerialNumber::from(2u32),
            validity,
            Name::from_str("CN=Cloud Synthetic Developer,OU=TESTTEAM01,O=NOT Apple").unwrap(),
            leaf_spki,
            &root_key,
        )
        .unwrap();
        builder
            .add_extension(&ExtendedKeyUsage(vec![ObjectIdentifier::new_unwrap(
                "1.3.6.1.5.5.7.3.3",
            )]))
            .unwrap();
        let leaf = builder.build::<Signature>().unwrap();
        let mut grants = Dictionary::new();
        grants.insert(
            "application-identifier".into(),
            format!("{TEAM}.{ID}").into(),
        );
        grants.insert("com.apple.developer.team-identifier".into(), TEAM.into());
        grants.insert("get-task-allow".into(), Value::Boolean(true));
        grants.insert(
            "keychain-access-groups".into(),
            Value::Array(vec![format!("{TEAM}.{ID}").into()]),
        );
        grants.insert(
            "com.apple.security.application-groups".into(),
            Value::Array(vec!["group.org.example.synthetic".into()]),
        );
        grants.insert(
            "com.apple.developer.associated-domains".into(),
            Value::Array(vec!["*".into()]),
        );
        let mut structured = Dictionary::new();
        structured.insert("feature".into(), Value::Boolean(true));
        structured.insert("level".into(), Value::Integer(2u64.into()));
        structured.insert(
            "tags".into(),
            Value::Array(vec!["local".into(), "other-authorized".into()]),
        );
        grants.insert(
            "com.example.structured-capability".into(),
            Value::Dictionary(structured.clone()),
        );
        let mut requested = grants.clone();
        requested.insert("get-task-allow".into(), Value::Boolean(false));
        requested.insert(
            "com.apple.developer.associated-domains".into(),
            Value::Array(vec!["applinks:synthetic.example".into()]),
        );
        structured.insert("tags".into(), Value::Array(vec!["local".into()]));
        requested.insert(
            "com.example.structured-capability".into(),
            Value::Dictionary(structured),
        );
        grants.insert(
            "com.example.unused-profile-privilege".into(),
            Value::Boolean(true),
        );
        let mut profile = Dictionary::new();
        profile.insert("Name".into(), "SYNTHETIC, NOT APPLE AUTHORIZATION".into());
        profile.insert("UUID".into(), "00000000-0000-0000-0000-000000000001".into());
        profile.insert("TeamIdentifier".into(), Value::Array(vec![TEAM.into()]));
        profile.insert(
            "ApplicationIdentifierPrefix".into(),
            Value::Array(vec![TEAM.into()]),
        );
        profile.insert(
            "ProvisionedDevices".into(),
            Value::Array(vec![DEVICE.into()]),
        );
        profile.insert(
            "CreationDate".into(),
            Value::Date((now - Duration::from_secs(1)).into()),
        );
        profile.insert(
            "ExpirationDate".into(),
            Value::Date((now + Duration::from_secs(12 * 3600)).into()),
        );
        profile.insert(
            "DeveloperCertificates".into(),
            Value::Array(vec![Value::Data(leaf.to_der().unwrap())]),
        );
        profile.insert("Entitlements".into(), Value::Dictionary(grants.clone()));
        let mut xml = vec![];
        plist::to_writer_xml(&mut xml, &profile).unwrap();
        let profile = profile_cms(&xml, &signing, &leaf, &root);
        Material {
            key,
            leaf,
            root,
            profile,
            requested,
            grants,
            now,
        }
    })
}
fn profile_cms(
    xml: &[u8],
    key: &SigningKey<sha2_010::Sha256>,
    leaf: &Certificate,
    root: &Certificate,
) -> Vec<u8> {
    let content = EncapsulatedContentInfo {
        econtent_type: ObjectIdentifier::new_unwrap(DATA_OID),
        econtent: Some(Any::encode_from(&OctetString::new(xml).unwrap()).unwrap()),
    };
    let algorithm = spki::AlgorithmIdentifierOwned {
        oid: ObjectIdentifier::new_unwrap(SHA256_OID),
        parameters: None,
    };
    let sid = SignerIdentifier::IssuerAndSerialNumber(IssuerAndSerialNumber {
        issuer: leaf.tbs_certificate.issuer.clone(),
        serial_number: leaf.tbs_certificate.serial_number.clone(),
    });
    let signer = SignerInfoBuilder::new(key, sid, algorithm.clone(), &content, None).unwrap();
    let mut builder = SignedDataBuilder::new(&content);
    builder.add_digest_algorithm(algorithm).unwrap();
    builder
        .add_certificate(CertificateChoices::Certificate(leaf.clone()))
        .unwrap();
    builder
        .add_certificate(CertificateChoices::Certificate(root.clone()))
        .unwrap();
    builder
        .add_signer_info::<SigningKey<sha2_010::Sha256>, Signature>(signer)
        .unwrap();
    builder.build().unwrap().to_der().unwrap()
}
fn profile_cms_ec(
    xml: &[u8],
    pair: &ring::signature::EcdsaKeyPair,
    authority: &Certificate,
    root: &Certificate,
    sha384: bool,
) -> Vec<u8> {
    use cms::{
        content_info::CmsVersion,
        signed_data::{CertificateSet, SignerInfo, SignerInfos},
    };
    use der::asn1::SetOfVec;
    use x509_cert::attr::Attribute;
    let digest_oid = if sha384 { SHA384_OID } else { SHA256_OID };
    let signature_oid = if sha384 {
        "1.2.840.10045.4.3.3"
    } else {
        "1.2.840.10045.4.3.2"
    };
    let digest = if sha384 {
        sha2::Sha384::digest(xml).to_vec()
    } else {
        Sha256::digest(xml).to_vec()
    };
    let attributes = SetOfVec::try_from(vec![
        Attribute {
            oid: ObjectIdentifier::new_unwrap("1.2.840.113549.1.9.3"),
            values: SetOfVec::try_from(vec![Any::encode_from(&ObjectIdentifier::new_unwrap(
                DATA_OID,
            ))
            .unwrap()])
            .unwrap(),
        },
        Attribute {
            oid: ObjectIdentifier::new_unwrap("1.2.840.113549.1.9.4"),
            values: SetOfVec::try_from(vec![
                Any::encode_from(&OctetString::new(digest).unwrap()).unwrap()
            ])
            .unwrap(),
        },
    ])
    .unwrap();
    let rng = ring::rand::SystemRandom::new();
    let signature = pair.sign(&rng, &attributes.to_der().unwrap()).unwrap();
    let digest_algorithm = spki::AlgorithmIdentifierOwned {
        oid: ObjectIdentifier::new(digest_oid).unwrap(),
        parameters: None,
    };
    let signer = SignerInfo {
        version: CmsVersion::V1,
        sid: SignerIdentifier::IssuerAndSerialNumber(IssuerAndSerialNumber {
            issuer: authority.tbs_certificate.issuer.clone(),
            serial_number: authority.tbs_certificate.serial_number.clone(),
        }),
        digest_alg: digest_algorithm.clone(),
        signed_attrs: Some(attributes),
        signature_algorithm: spki::AlgorithmIdentifierOwned {
            oid: ObjectIdentifier::new(signature_oid).unwrap(),
            parameters: None,
        },
        signature: OctetString::new(signature.as_ref()).unwrap(),
        unsigned_attrs: None,
    };
    let signed = SignedData {
        version: CmsVersion::V1,
        digest_algorithms: SetOfVec::try_from(vec![digest_algorithm]).unwrap(),
        encap_content_info: EncapsulatedContentInfo {
            econtent_type: ObjectIdentifier::new_unwrap(DATA_OID),
            econtent: Some(Any::encode_from(&OctetString::new(xml).unwrap()).unwrap()),
        },
        certificates: Some(CertificateSet(
            SetOfVec::try_from(vec![
                CertificateChoices::Certificate(authority.clone()),
                CertificateChoices::Certificate(root.clone()),
            ])
            .unwrap(),
        )),
        crls: None,
        signer_infos: SignerInfos(SetOfVec::try_from(vec![signer]).unwrap()),
    };
    ContentInfo {
        content_type: ObjectIdentifier::new_unwrap("1.2.840.113549.1.7.2"),
        content: Any::encode_from(&signed).unwrap(),
    }
    .to_der()
    .unwrap()
}

struct Fixture(PathBuf);
impl Drop for Fixture {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}
fn fixture() -> Fixture {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("target")
        .join(format!(
            "synthetic-signing-{}-{}",
            std::process::id(),
            NEXT.fetch_add(1, Ordering::Relaxed)
        ));
    fs::create_dir_all(root.join("Payload/Test.app")).unwrap();
    Fixture(root)
}
fn unsigned_macho() -> Vec<u8> {
    let mut data = vec![0u8; 512];
    let put = |data: &mut [u8], offset: usize, value: u32| {
        data[offset..offset + 4].copy_from_slice(&value.to_le_bytes())
    };
    for (n, value) in [0xfeed_facfu32, 0x0100_000c, 0, 2, 4, 184, 0, 0]
        .into_iter()
        .enumerate()
    {
        put(&mut data, n * 4, value)
    }
    for (offset, name, fileoff, size) in [
        (32usize, b"__TEXT".as_slice(), 0u64, 512u64),
        (104, b"__LINKEDIT".as_slice(), 512, 0),
    ] {
        put(&mut data, offset, 0x19);
        put(&mut data, offset + 4, 72);
        data[offset + 8..offset + 8 + name.len()].copy_from_slice(name);
        data[offset + 24..offset + 32].copy_from_slice(&fileoff.to_le_bytes());
        data[offset + 32..offset + 40].copy_from_slice(&size.to_le_bytes());
        data[offset + 40..offset + 48].copy_from_slice(&fileoff.to_le_bytes());
        data[offset + 48..offset + 56].copy_from_slice(&size.to_le_bytes());
        put(&mut data, offset + 56, 7);
        put(&mut data, offset + 60, 5);
    }
    for (n, value) in [0x1d, 16, 512, 0, 0x32, 24, 2, 0x00100400, 0x00100500, 0]
        .into_iter()
        .enumerate()
    {
        put(&mut data, 176 + n * 4, value)
    }
    data
}
fn sign_fixture(f: &Fixture) -> PathBuf {
    sign_fixture_material(f, material())
}
fn sign_fixture_material(f: &Fixture, m: &Material) -> PathBuf {
    sign_fixture_material_binary(f, m, unsigned_macho())
}
fn sign_fixture_material_binary(f: &Fixture, m: &Material, unsigned: Vec<u8>) -> PathBuf {
    let app = f.0.join("Payload/Test.app");
    let mut info = Dictionary::new();
    info.insert("CFBundleIdentifier".into(), ID.into());
    info.insert("CFBundleExecutable".into(), "Test".into());
    info.insert("CFBundleName".into(), "Synthetic Test".into());
    info.insert("CFBundlePackageType".into(), "APPL".into());
    plist::to_file_xml(app.join("Info.plist"), &info).unwrap();
    fs::write(app.join("Test"), unsigned).unwrap();
    fs::write(app.join("hello.txt"), b"Synthetic payload resource").unwrap();
    let profile = DeveloperProfile {
        encoded_profile: m.profile.clone().into(),
        filename: "synthetic.mobileprovision".into(),
        provisioning_profile_id: "synthetic".into(),
        name: "NOT APPLE AUTHORIZATION".into(),
        status: "Active".into(),
        r#type: "Development".into(),
        distribution_method: "development".into(),
        pro_pro_platorm: None,
        uuid: "00000000-0000-0000-0000-000000000001".into(),
        date_expire: (m.now + Duration::from_secs(12 * 3600)).into(),
        managing_app: None,
        app_id_id: "synthetic".into(),
        is_template_profile: false,
        is_team_profile: Some(true),
        is_free_provisioning_profile: Some(true),
    };
    let cert = CertificateIdentity {
        machine_id: "synthetic".into(),
        machine_name: "synthetic".into(),
        private_key: m.key.clone(),
        certificate: m.leaf.clone(),
    };
    let team = DeveloperTeam {
        name: Some("SYNTHETIC".into()),
        team_id: TEAM.into(),
        r#type: None,
        status: None,
        memberships: None,
    };
    let mut application = Application::new(app.clone()).unwrap();
    let reconciled =
        crate::entitlement_policy::reconcile(&m.requested, ID, ID, TEAM, &m.grants).unwrap();
    tokio::runtime::Runtime::new()
        .unwrap()
        .block_on(isideload::sideload::sign::sign_with_entitlements(
            &mut application,
            &cert,
            &profile,
            &reconciled,
            &[],
            &team,
            Some(|_: f32| async {}),
        ))
        .unwrap();
    let actual = crate::capabilities::read_entitlements(&app, ID).unwrap();
    assert_eq!(actual, reconciled);
    assert!(!actual.contains_key("com.example.unused-profile-privilege"));
    assert_eq!(
        actual.get("com.apple.security.application-groups"),
        m.requested.get("com.apple.security.application-groups")
    );
    assert_eq!(
        actual.get("com.apple.developer.associated-domains"),
        m.requested.get("com.apple.developer.associated-domains")
    );
    assert_eq!(
        actual.get("com.example.structured-capability"),
        m.requested.get("com.example.structured-capability")
    );
    app
}
fn verify(app: &Path) -> Result<VerificationReport> {
    let m = material();
    verify_with_roots(
        app,
        TEAM,
        ID,
        DEVICE,
        &m.profile,
        &m.leaf.to_der().unwrap(),
        m.now,
        std::slice::from_ref(&m.root),
    )
}
#[test]
fn actual_isideload_signing_round_trip_and_tamper_detection() {
    let f = fixture();
    let app = sign_fixture(&f);
    let report = verify(&app).unwrap();
    assert_eq!(report.executable_slices, 1);
    assert!(report.resource_files >= 2);
    assert!(!report.live_installation_verified);
    assert!(!report.revocation_checked);
    // Package the actual signed output, validate/extract it, and verify its signatures again.
    let ipa = f.0.join("synthetic.ipa");
    let file = File::create(&ipa).unwrap();
    let mut zip = zip::ZipWriter::new(file);
    let mut stack = vec![f.0.join("Payload")];
    while let Some(dir) = stack.pop() {
        for entry in fs::read_dir(dir).unwrap() {
            let entry = entry.unwrap();
            let p = entry.path();
            if entry.file_type().unwrap().is_dir() {
                stack.push(p)
            } else {
                let name = p.strip_prefix(&f.0).unwrap().to_str().unwrap();
                zip.start_file(name, zip::write::SimpleFileOptions::default())
                    .unwrap();
                zip.write_all(&fs::read(p).unwrap()).unwrap();
            }
        }
    }
    zip.finish().unwrap();
    let validated =
        crate::archive::validate_and_extract(&ipa, &f.0.join("verified-stage")).unwrap();
    assert_eq!(validated.bundle_id, ID);
    verify(&validated.app_dir).unwrap();
    drop(validated);
    assert!(!f.0.join("verified-stage").exists());
    let original = fs::read(app.join("Test")).unwrap();
    let mut changed = original.clone();
    changed[300] ^= 1;
    fs::write(app.join("Test"), changed).unwrap();
    assert!(matches!(verify(&app), Err(VerificationError::HashMismatch)));
    fs::write(app.join("Test"), &original).unwrap();
    let mut appended = original.clone();
    appended.extend(b"unsigned-trailing-data");
    fs::write(app.join("Test"), appended).unwrap();
    assert!(verify(&app).is_err());
    fs::write(app.join("Test"), &original).unwrap();
    let fat_fixture = fixture();
    let first = unsigned_macho();
    let mut second = unsigned_macho();
    second[8..12].copy_from_slice(&2u32.to_le_bytes());
    let mut fat = vec![0u8; 32768 + second.len()];
    for (n, value) in [
        0xcafe_babeu32,
        2,
        0x0100_000c,
        0,
        16384,
        first.len() as u32,
        14,
        0x0100_000c,
        2,
        32768,
        second.len() as u32,
        14,
    ]
    .into_iter()
    .enumerate()
    {
        fat[n * 4..n * 4 + 4].copy_from_slice(&value.to_be_bytes());
    }
    fat[16384..16384 + first.len()].copy_from_slice(&first);
    fat[32768..].copy_from_slice(&second);
    let fat_app = sign_fixture_material_binary(&fat_fixture, material(), fat);
    assert_eq!(verify(&fat_app).unwrap().executable_slices, 2);
    let original_fat = fs::read(fat_app.join("Test")).unwrap();
    let mut appended = original_fat.clone();
    appended.extend(b"unsigned-fat-trailer");
    fs::write(fat_app.join("Test"), appended).unwrap();
    assert!(verify(&fat_app).is_err());
    let mut gap = original_fat.clone();
    gap[48] = 1;
    fs::write(fat_app.join("Test"), gap).unwrap();
    assert!(verify(&fat_app).is_err());
    fs::write(fat_app.join("Test"), original_fat).unwrap();
    let m = material();
    let dylib = f.0.join("Injected.dylib");
    let mut raw = unsigned_macho();
    raw[12..16].copy_from_slice(&6u32.to_le_bytes());
    let signer = apple_codesign_quick::RustCryptoCmsSigner::new(
        m.key.clone(),
        m.leaf.clone(),
        vec![m.root.clone()],
    );
    let empty = Dictionary::new();
    let config = apple_codesign_quick::macho::MachOSigningConfig::new(
        "Injected.dylib",
        TEAM,
        &empty,
        Some(&signer),
    );
    let clean = apple_codesign_quick::sign_macho_data(&dylib, &raw, &config).unwrap();
    fs::write(&dylib, clean).unwrap();
    assert_eq!(
        verify_macho(
            &dylib,
            TEAM,
            "Injected.dylib",
            &m.leaf,
            std::slice::from_ref(&m.root),
            m.now,
            None,
            None,
            false
        )
        .unwrap(),
        1
    );
    let mut injected = Dictionary::new();
    injected.insert("get-task-allow".into(), Value::Boolean(true));
    let config = apple_codesign_quick::macho::MachOSigningConfig::new(
        "Injected.dylib",
        TEAM,
        &injected,
        Some(&signer),
    );
    fs::write(
        &dylib,
        apple_codesign_quick::sign_macho_data(&dylib, &raw, &config).unwrap(),
    )
    .unwrap();
    assert!(matches!(
        verify_macho(
            &dylib,
            TEAM,
            "Injected.dylib",
            &m.leaf,
            std::slice::from_ref(&m.root),
            m.now,
            None,
            None,
            false
        ),
        Err(VerificationError::Entitlements)
    ));
    let resource = fs::read(app.join("hello.txt")).unwrap();
    fs::write(app.join("hello.txt"), b"modified resource").unwrap();
    assert!(verify(&app).is_err());
    fs::write(app.join("hello.txt"), resource).unwrap();
    let mut changed = original.clone();
    let start = u32::from_le_bytes(changed[184..188].try_into().unwrap()) as usize;
    let sig = &changed[start..];
    let count = word(sig, 8, true).unwrap() as usize;
    let cms = (0..count)
        .find_map(|n| {
            (word(sig, 12 + n * 8, true).unwrap() == 0x10000)
                .then(|| word(sig, 16 + n * 8, true).unwrap() as usize)
        })
        .unwrap();
    let cms_start = start + cms + 8;
    let cms_len = der_len(&changed[cms_start..]).unwrap();
    changed[cms_start + cms_len - 1] ^= 1;
    fs::write(app.join("Test"), changed).unwrap();
    assert!(verify(&app).is_err());
    fs::write(app.join("Test"), original).unwrap();
}
#[test]
fn synthetic_profiles_never_establish_apple_authorization_or_wrong_identity() {
    let f = fixture();
    let app = sign_fixture(&f);
    let m = material();
    let cert = m.leaf.to_der().unwrap();
    assert!(verify_signed_bundle(&app, TEAM, ID, DEVICE, &m.profile, &cert, m.now).is_err());
    assert!(verify_with_roots(
        &app,
        "OTHERTEAM1",
        ID,
        DEVICE,
        &m.profile,
        &cert,
        m.now,
        std::slice::from_ref(&m.root)
    )
    .is_err());
    assert!(verify_with_roots(
        &app,
        TEAM,
        ID,
        "another-device",
        &m.profile,
        &cert,
        m.now,
        std::slice::from_ref(&m.root)
    )
    .is_err());
    assert!(verify_with_roots(
        &app,
        TEAM,
        ID,
        DEVICE,
        &m.profile,
        &cert,
        m.now + Duration::from_secs(13 * 3600),
        std::slice::from_ref(&m.root)
    )
    .is_err());
    let mut profile = m.profile.clone();
    let middle = profile.len() / 2;
    profile[middle] ^= 1;
    assert!(verify_with_roots(
        &app,
        TEAM,
        ID,
        DEVICE,
        &profile,
        &cert,
        m.now,
        std::slice::from_ref(&m.root)
    )
    .is_err());
    fs::write(app.join("unsealed.txt"), b"not in signed resource seal").unwrap();
    assert!(matches!(verify(&app), Err(VerificationError::Resource)));
    // Exercise complete signing/profile/code verification with EC CA paths like newer
    // Apple PKI roots, using only independently generated synthetic RAM-only EC keys.
    use ring::signature::KeyPair;
    for (curve, signature_oid, algorithm) in [
        (
            "1.2.840.10045.3.1.7",
            "1.2.840.10045.4.3.2",
            &ring::signature::ECDSA_P256_SHA256_ASN1_SIGNING,
        ),
        (
            "1.3.132.0.34",
            "1.2.840.10045.4.3.3",
            &ring::signature::ECDSA_P384_SHA384_ASN1_SIGNING,
        ),
    ] {
        let rng = ring::rand::SystemRandom::new();
        let private = ring::signature::EcdsaKeyPair::generate_pkcs8(algorithm, &rng).unwrap();
        let pair =
            ring::signature::EcdsaKeyPair::from_pkcs8(algorithm, private.as_ref(), &rng).unwrap();
        let signature_alg = spki::AlgorithmIdentifierOwned {
            oid: ObjectIdentifier::new(signature_oid).unwrap(),
            parameters: None,
        };
        let mut root = m.root.clone();
        root.tbs_certificate.subject_public_key_info = spki::SubjectPublicKeyInfoOwned {
            algorithm: spki::AlgorithmIdentifierOwned {
                oid: ObjectIdentifier::new_unwrap("1.2.840.10045.2.1"),
                parameters: Some(Any::encode_from(&ObjectIdentifier::new(curve).unwrap()).unwrap()),
            },
            subject_public_key: der::asn1::BitString::from_bytes(pair.public_key().as_ref())
                .unwrap(),
        };
        root.tbs_certificate.signature = signature_alg.clone();
        root.signature_algorithm = signature_alg.clone();
        root.signature = der::asn1::BitString::from_bytes(
            pair.sign(&rng, &root.tbs_certificate.to_der().unwrap())
                .unwrap()
                .as_ref(),
        )
        .unwrap();
        let mut leaf = m.leaf.clone();
        leaf.tbs_certificate.signature = signature_alg.clone();
        leaf.signature_algorithm = signature_alg;
        leaf.signature = der::asn1::BitString::from_bytes(
            pair.sign(&rng, &leaf.tbs_certificate.to_der().unwrap())
                .unwrap()
                .as_ref(),
        )
        .unwrap();
        let mut authority = leaf.clone();
        authority.tbs_certificate.serial_number = SerialNumber::from(3u32);
        authority.tbs_certificate.subject_public_key_info =
            root.tbs_certificate.subject_public_key_info.clone();
        authority.signature = der::asn1::BitString::from_bytes(
            pair.sign(&rng, &authority.tbs_certificate.to_der().unwrap())
                .unwrap()
                .as_ref(),
        )
        .unwrap();
        let content = verify_cms(&m.profile, None, std::slice::from_ref(&m.root), m.now, None)
            .unwrap()
            .content;
        let mut plist: Dictionary = plist::from_bytes(&content).unwrap();
        plist.insert(
            "DeveloperCertificates".into(),
            Value::Array(vec![Value::Data(leaf.to_der().unwrap())]),
        );
        let mut xml = vec![];
        plist::to_writer_xml(&mut xml, &plist).unwrap();
        let ec = Material {
            key: m.key.clone(),
            leaf: leaf.clone(),
            root: root.clone(),
            profile: profile_cms_ec(&xml, &pair, &authority, &root, curve == "1.3.132.0.34"),
            requested: m.requested.clone(),
            grants: m.grants.clone(),
            now: m.now,
        };
        let fixture = fixture();
        let app = sign_fixture_material(&fixture, &ec);
        let report = verify_with_roots(
            &app,
            TEAM,
            ID,
            DEVICE,
            &ec.profile,
            &ec.leaf.to_der().unwrap(),
            ec.now,
            std::slice::from_ref(&ec.root),
        )
        .unwrap();
        assert!(!report.live_installation_verified);
        assert!(verify_signed_bundle(
            &app,
            TEAM,
            ID,
            DEVICE,
            &ec.profile,
            &ec.leaf.to_der().unwrap(),
            ec.now
        )
        .is_err());
    }
}
