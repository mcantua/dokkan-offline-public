//! Portable, offline verification of this installer's actual signing output.
//! This proves hashes, cryptographic signatures and binding to the exact profile obtained
//! through authenticated developer services. It does not prove revocation status, Apple's
//! current account authorization, installation success, or physical-device compatibility.
use apple_codesign_quick::signature::HashAlgorithm;
use cms::{
    cert::CertificateChoices,
    content_info::ContentInfo,
    signed_data::{SignedData, SignerIdentifier},
};
use der::{
    asn1::{ObjectIdentifier, OctetString},
    Decode, Encode, Sequence,
};
use plist::{Dictionary, Value};
use rsa::{
    pkcs1v15::{Signature, VerifyingKey},
    pkcs8::DecodePublicKey,
    signature::Verifier,
    traits::PublicKeyParts,
    RsaPublicKey,
};
use sha2::{Digest, Sha256};
use std::{
    collections::{BTreeMap, HashSet},
    fmt,
    fs::{self, File},
    io::{Read, Seek, SeekFrom},
    path::{Component, Path},
    time::{SystemTime, UNIX_EPOCH},
};
use x509_cert::{
    ext::pkix::{BasicConstraints, ExtendedKeyUsage, KeyUsage},
    Certificate,
};

const MAX_META: usize = 4 * 1024 * 1024;
const SHA256_OID: &str = "2.16.840.1.101.3.4.2.1";
const SHA384_OID: &str = "2.16.840.1.101.3.4.2.2";
const SHA512_OID: &str = "2.16.840.1.101.3.4.2.3";
const DATA_OID: &str = "1.2.840.113549.1.7.1";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VerificationError {
    Io,
    Structure,
    HashMismatch,
    Signature,
    Certificate,
    Profile,
    Identity,
    Entitlements,
    Resource,
    Unsupported,
}
impl fmt::Display for VerificationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(match self {
            Self::Io => "Signed app data could not be read.",
            Self::Structure => "The signed app structure is invalid.",
            Self::HashMismatch => "The signed app failed an integrity check.",
            Self::Signature => "The app signature could not be verified.",
            Self::Certificate => "The signing certificate chain could not be verified.",
            Self::Profile => "The app does not match its authorized provisioning profile.",
            Self::Identity => "The signed app identity does not match the selected team.",
            Self::Entitlements => {
                "The signed app requests an entitlement its profile does not grant."
            }
            Self::Resource => "A signed app resource is missing, changed or unsealed.",
            Self::Unsupported => {
                "This signature format or algorithm needs additional verification support."
            }
        })
    }
}
impl std::error::Error for VerificationError {}
type Result<T> = std::result::Result<T, VerificationError>;
#[derive(Debug, Clone)]
pub struct VerificationReport {
    pub executable_slices: usize,
    pub resource_files: usize,
    pub profile_expiry: i64,
    /// Always false: offline crypto cannot establish device installation or revocation.
    pub live_installation_verified: bool,
    pub revocation_checked: bool,
}

/// `server_profile` MUST be the exact bytes returned by authenticated Apple developer
/// services for this operation, not a profile supplied by the imported IPA. The verifier
/// checks exact equality and the profile CMS/chain, but cannot itself prove API provenance.
pub fn verify_signed_bundle(
    bundle: &Path,
    team: &str,
    bundle_id: &str,
    device: &str,
    server_profile: &[u8],
    signing_cert_der: &[u8],
    now: SystemTime,
) -> Result<VerificationReport> {
    let anchors: &[(&[u8], &str)] = &[
        (
            isideload::sideload::cert_identity::APPLE_ROOT,
            "b0b1730ecbc7ff4505142c49f1295e6eda6bcaed7e2c68c5be91b5a11001f024",
        ),
        (
            include_bytes!("../../../downloads/apple-trust/AppleRootCA-G2.cer"),
            "c2b9b042dd57830e7d117dac55ac8ae19407d38e41d88f3215bc3a890444a050",
        ),
        (
            include_bytes!("../../../downloads/apple-trust/AppleRootCA-G3.cer"),
            "63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179",
        ),
    ];
    let mut roots = Vec::new();
    for (bytes, pin) in anchors {
        let digest = Sha256::digest(bytes)
            .iter()
            .map(|b| format!("{b:02x}"))
            .collect::<String>();
        if &digest != pin {
            return Err(VerificationError::Certificate);
        }
        roots.push(Certificate::from_der(bytes).map_err(|_| VerificationError::Certificate)?);
    }
    verify_with_roots(
        bundle,
        team,
        bundle_id,
        device,
        server_profile,
        signing_cert_der,
        now,
        &roots,
    )
}
fn verify_with_roots(
    bundle: &Path,
    team: &str,
    bundle_id: &str,
    device: &str,
    server_profile: &[u8],
    signing_cert_der: &[u8],
    now: SystemTime,
    roots: &[Certificate],
) -> Result<VerificationReport> {
    if team.is_empty()
        || bundle_id.is_empty()
        || device.is_empty()
        || server_profile.len() > MAX_META
        || signing_cert_der.len() > 64 * 1024
    {
        return Err(VerificationError::Identity);
    }
    let embedded = read_bounded(&bundle.join("embedded.mobileprovision"), MAX_META)?;
    if embedded != server_profile {
        return Err(VerificationError::Profile);
    }
    let profile_cms = verify_cms(&embedded, None, roots, now, None)?;
    let profile: Dictionary =
        plist::from_bytes(&profile_cms.content).map_err(|_| VerificationError::Profile)?;
    let expiry = profile
        .get("ExpirationDate")
        .and_then(Value::as_date)
        .ok_or(VerificationError::Profile)?;
    let expiry: SystemTime = expiry.into();
    if expiry <= now {
        return Err(VerificationError::Profile);
    }
    if profile
        .get("CreationDate")
        .and_then(Value::as_date)
        .is_some_and(|d| {
            let t: SystemTime = d.into();
            t > now + std::time::Duration::from_secs(300)
        })
    {
        return Err(VerificationError::Profile);
    }
    let teams = profile
        .get("TeamIdentifier")
        .and_then(Value::as_array)
        .ok_or(VerificationError::Profile)?;
    if teams.len() != 1 || teams[0].as_string() != Some(team) {
        return Err(VerificationError::Identity);
    }
    let all = profile
        .get("ProvisionsAllDevices")
        .and_then(Value::as_boolean)
        == Some(true);
    if !all
        && !profile
            .get("ProvisionedDevices")
            .and_then(Value::as_array)
            .is_some_and(|devices| devices.iter().any(|d| d.as_string() == Some(device)))
    {
        return Err(VerificationError::Profile);
    }
    if !profile
        .get("DeveloperCertificates")
        .and_then(Value::as_array)
        .is_some_and(|certs| certs.iter().any(|c| c.as_data() == Some(signing_cert_der)))
    {
        return Err(VerificationError::Certificate);
    }
    let grants = profile
        .get("Entitlements")
        .and_then(Value::as_dictionary)
        .ok_or(VerificationError::Profile)?;
    let actual = crate::capabilities::read_entitlements(bundle, bundle_id)
        .map_err(|_| VerificationError::Entitlements)?;
    if actual
        .get("com.apple.developer.team-identifier")
        .and_then(Value::as_string)
        != Some(team)
    {
        return Err(VerificationError::Identity);
    }
    let app_id = actual
        .get("application-identifier")
        .and_then(Value::as_string)
        .ok_or(VerificationError::Identity)?;
    let (prefix, id) = app_id.split_once('.').ok_or(VerificationError::Identity)?;
    if id != bundle_id
        || !profile
            .get("ApplicationIdentifierPrefix")
            .and_then(Value::as_array)
            .is_some_and(|p| p.iter().any(|p| p.as_string() == Some(prefix)))
    {
        return Err(VerificationError::Identity);
    }
    if !crate::entitlement_policy::grants_allow(&actual, grants) {
        return Err(VerificationError::Entitlements);
    }
    let expected =
        Certificate::from_der(signing_cert_der).map_err(|_| VerificationError::Certificate)?;
    let (slices, resources) =
        verify_code_bundle(bundle, team, bundle_id, &expected, roots, now, true)?;
    Ok(VerificationReport {
        executable_slices: slices,
        resource_files: resources,
        profile_expiry: expiry
            .duration_since(UNIX_EPOCH)
            .map_err(|_| VerificationError::Profile)?
            .as_secs() as i64,
        live_installation_verified: false,
        revocation_checked: false,
    })
}
fn read_bounded(path: &Path, max: usize) -> Result<Vec<u8>> {
    let meta = fs::symlink_metadata(path).map_err(|_| VerificationError::Io)?;
    if !meta.file_type().is_file() || meta.len() > max as u64 {
        return Err(VerificationError::Structure);
    }
    fs::read(path).map_err(|_| VerificationError::Io)
}
fn word(d: &[u8], p: usize, big: bool) -> Result<u32> {
    let b = d
        .get(p..p.checked_add(4).ok_or(VerificationError::Structure)?)
        .ok_or(VerificationError::Structure)?
        .try_into()
        .map_err(|_| VerificationError::Structure)?;
    Ok(if big {
        u32::from_be_bytes(b)
    } else {
        u32::from_le_bytes(b)
    })
}
fn wide(d: &[u8], p: usize, big: bool) -> Result<u64> {
    let b = d
        .get(p..p.checked_add(8).ok_or(VerificationError::Structure)?)
        .ok_or(VerificationError::Structure)?
        .try_into()
        .map_err(|_| VerificationError::Structure)?;
    Ok(if big {
        u64::from_be_bytes(b)
    } else {
        u64::from_le_bytes(b)
    })
}
fn read_at(file: &mut File, offset: u64, len: usize) -> Result<Vec<u8>> {
    if len > MAX_META
        || offset
            .checked_add(len as u64)
            .is_none_or(|end| file.metadata().map_or(true, |m| end > m.len()))
    {
        return Err(VerificationError::Structure);
    }
    let mut out = vec![0; len];
    file.seek(SeekFrom::Start(offset))
        .map_err(|_| VerificationError::Io)?;
    file.read_exact(&mut out)
        .map_err(|_| VerificationError::Io)?;
    Ok(out)
}
fn der_len(data: &[u8]) -> Result<usize> {
    if data.len() < 2 {
        return Err(VerificationError::Structure);
    }
    let first = data[1];
    let (header, len): (usize, usize) = if first < 128 {
        (2, first as usize)
    } else {
        let n = (first & 127) as usize;
        if n == 0 || n > 4 || data.len() < 2 + n || data[2] == 0 {
            return Err(VerificationError::Structure);
        }
        let mut len = 0usize;
        for b in &data[2..2 + n] {
            len = (len << 8) | *b as usize;
        }
        if len < 128 {
            return Err(VerificationError::Structure);
        }
        (2 + n, len)
    };
    let total = header
        .checked_add(len)
        .ok_or(VerificationError::Structure)?;
    if total > data.len() {
        return Err(VerificationError::Structure);
    }
    Ok(total)
}
struct CmsEvidence {
    content: Vec<u8>,
    leaf: Certificate,
}
#[derive(Sequence)]
struct DirectoryDigest {
    algorithm: ObjectIdentifier,
    digest: OctetString,
}
fn verify_cms(
    bytes: &[u8],
    detached: Option<&[u8]>,
    roots: &[Certificate],
    now: SystemTime,
    cds: Option<&[(HashAlgorithm, Vec<u8>)]>,
) -> Result<CmsEvidence> {
    if bytes.len() > MAX_META {
        return Err(VerificationError::Structure);
    }
    let len = der_len(bytes)?;
    if bytes[len..].iter().any(|b| *b != 0) {
        return Err(VerificationError::Structure);
    }
    let ci = ContentInfo::from_der(&bytes[..len]).map_err(|_| VerificationError::Signature)?;
    if ci.content_type.to_string() != "1.2.840.113549.1.7.2" {
        return Err(VerificationError::Signature);
    }
    let sd = SignedData::from_der(
        &ci.content
            .to_der()
            .map_err(|_| VerificationError::Signature)?,
    )
    .map_err(|_| VerificationError::Signature)?;
    if sd.signer_infos.0.len() != 1
        || sd.digest_algorithms.len() != 1
        || sd.encap_content_info.econtent_type.to_string() != DATA_OID
    {
        return Err(VerificationError::Unsupported);
    }
    let content = match (detached, sd.encap_content_info.econtent.as_ref()) {
        (Some(expected), None) => expected.to_vec(),
        (None, Some(content)) => content
            .decode_as::<OctetString>()
            .map_err(|_| VerificationError::Signature)?
            .as_bytes()
            .to_vec(),
        _ => return Err(VerificationError::Signature),
    };
    if content.len() > MAX_META {
        return Err(VerificationError::Structure);
    }
    let info = sd
        .signer_infos
        .0
        .get(0)
        .ok_or(VerificationError::Signature)?;
    let digest_oid = info.digest_alg.oid.to_string();
    let listed = sd
        .digest_algorithms
        .get(0)
        .ok_or(VerificationError::Signature)?;
    if listed.oid.to_string() != digest_oid
        || !matches!(digest_oid.as_str(), SHA256_OID | SHA384_OID | SHA512_OID)
    {
        return Err(VerificationError::Unsupported);
    }
    for params in [&info.digest_alg.parameters, &listed.parameters] {
        if params
            .as_ref()
            .is_some_and(|p| p.decode_as::<der::asn1::Null>().is_err())
        {
            return Err(VerificationError::Unsupported);
        }
    }
    let content_digest = match digest_oid.as_str() {
        SHA256_OID => Sha256::digest(&content).to_vec(),
        SHA384_OID => sha2::Sha384::digest(&content).to_vec(),
        SHA512_OID => sha2::Sha512::digest(&content).to_vec(),
        _ => return Err(VerificationError::Unsupported),
    };
    let mut certificates = Vec::new();
    for c in sd
        .certificates
        .as_ref()
        .ok_or(VerificationError::Certificate)?
        .0
        .iter()
    {
        match c {
            CertificateChoices::Certificate(c) => certificates.push(c.clone()),
            _ => return Err(VerificationError::Unsupported),
        }
    }
    if certificates.is_empty() || certificates.len() > 16 {
        return Err(VerificationError::Certificate);
    }
    let leaf = match &info.sid {
        SignerIdentifier::IssuerAndSerialNumber(sid) => {
            let matches: Vec<_> = certificates
                .iter()
                .filter(|c| {
                    c.tbs_certificate.issuer == sid.issuer
                        && c.tbs_certificate.serial_number == sid.serial_number
                })
                .collect();
            if matches.len() != 1 {
                return Err(VerificationError::Certificate);
            }
            (*matches[0]).clone()
        }
        _ => return Err(VerificationError::Unsupported),
    };
    verify_chain(&leaf, &certificates, roots, now, cds.is_some())?;
    let attrs = info
        .signed_attrs
        .as_ref()
        .ok_or(VerificationError::Signature)?;
    if attrs.len() > 32 {
        return Err(VerificationError::Signature);
    }
    let mut oids = HashSet::new();
    let mut digest_ok = false;
    let mut content_ok = false;
    let mut directory_ok = cds.is_none();
    for attr in attrs.iter() {
        let oid = attr.oid.to_string();
        if !oids.insert(oid.clone()) {
            return Err(VerificationError::Signature);
        }
        match oid.as_str() {
            "1.2.840.113549.1.9.4" => {
                if attr.values.len() != 1 {
                    return Err(VerificationError::Signature);
                }
                let digest = attr
                    .values
                    .get(0)
                    .ok_or(VerificationError::Signature)?
                    .decode_as::<OctetString>()
                    .map_err(|_| VerificationError::Signature)?;
                digest_ok = digest.as_bytes() == content_digest;
            }
            "1.2.840.113549.1.9.3" => {
                if attr.values.len() != 1 {
                    return Err(VerificationError::Signature);
                }
                content_ok = attr
                    .values
                    .get(0)
                    .ok_or(VerificationError::Signature)?
                    .decode_as::<ObjectIdentifier>()
                    .map_err(|_| VerificationError::Signature)?
                    .to_string()
                    == DATA_OID;
            }
            "1.2.840.113635.100.9.2" => {
                if let Some(cds) = cds {
                    if attr.values.len() != cds.len() {
                        return Err(VerificationError::Signature);
                    }
                    let mut seen = HashSet::new();
                    for value in attr.values.iter() {
                        let digest = value
                            .decode_as::<DirectoryDigest>()
                            .map_err(|_| VerificationError::Signature)?;
                        let oid = digest.algorithm.to_string();
                        let key = (oid.clone(), digest.digest.as_bytes().to_vec());
                        if !seen.insert(key) {
                            return Err(VerificationError::Signature);
                        }
                        if !cds.iter().any(|(algorithm, bytes)| match algorithm {
                            HashAlgorithm::Sha1 => {
                                oid == "1.3.14.3.2.26"
                                    && digest.digest.as_bytes() == algorithm.digest(bytes)
                            }
                            HashAlgorithm::Sha256 => {
                                oid == SHA256_OID
                                    && digest.digest.as_bytes() == algorithm.digest(bytes)
                            }
                        }) {
                            return Err(VerificationError::Signature);
                        }
                    }
                    directory_ok = true;
                }
            }
            _ => (),
        }
    }
    if !digest_ok || !content_ok || !directory_ok {
        return Err(VerificationError::Signature);
    }
    let supplied = info.signature_algorithm.oid.to_string();
    let signature_oid = match (digest_oid.as_str(), supplied.as_str()) {
        (SHA256_OID, "1.2.840.113549.1.1.1" | "1.2.840.113549.1.1.11") => "1.2.840.113549.1.1.11",
        (SHA384_OID, "1.2.840.113549.1.1.1" | "1.2.840.113549.1.1.12") => "1.2.840.113549.1.1.12",
        (SHA512_OID, "1.2.840.113549.1.1.1" | "1.2.840.113549.1.1.13") => "1.2.840.113549.1.1.13",
        (SHA256_OID, "1.2.840.10045.4.3.2") => "1.2.840.10045.4.3.2",
        (SHA384_OID, "1.2.840.10045.4.3.3") => "1.2.840.10045.4.3.3",
        _ => return Err(VerificationError::Unsupported),
    };
    if info
        .signature_algorithm
        .parameters
        .as_ref()
        .is_some_and(|p| p.decode_as::<der::asn1::Null>().is_err())
    {
        return Err(VerificationError::Unsupported);
    }
    let signed = attrs.to_der().map_err(|_| VerificationError::Signature)?;
    verify_public_key_signature(&leaf, &signed, info.signature.as_bytes(), signature_oid)?;
    Ok(CmsEvidence { content, leaf })
}
fn verify_public_key_signature(
    issuer: &Certificate,
    message: &[u8],
    signature: &[u8],
    oid: &str,
) -> Result<()> {
    let public = &issuer.tbs_certificate.subject_public_key_info;
    if public.algorithm.oid.to_string() == "1.2.840.10045.2.1" {
        let curve = public
            .algorithm
            .parameters
            .as_ref()
            .ok_or(VerificationError::Unsupported)?
            .decode_as::<ObjectIdentifier>()
            .map_err(|_| VerificationError::Unsupported)?
            .to_string();
        let algorithm = match (curve.as_str(), oid) {
            ("1.2.840.10045.3.1.7", "1.2.840.10045.4.3.2") => {
                &ring::signature::ECDSA_P256_SHA256_ASN1
            }
            ("1.2.840.10045.3.1.7", "1.2.840.10045.4.3.3") => {
                &ring::signature::ECDSA_P256_SHA384_ASN1
            }
            ("1.3.132.0.34", "1.2.840.10045.4.3.2") => &ring::signature::ECDSA_P384_SHA256_ASN1,
            ("1.3.132.0.34", "1.2.840.10045.4.3.3") => &ring::signature::ECDSA_P384_SHA384_ASN1,
            _ => return Err(VerificationError::Unsupported),
        };
        let key = public
            .subject_public_key
            .as_bytes()
            .ok_or(VerificationError::Certificate)?;
        return ring::signature::UnparsedPublicKey::new(algorithm, key)
            .verify(message, signature)
            .map_err(|_| VerificationError::Signature);
    }
    if public.algorithm.oid.to_string() != "1.2.840.113549.1.1.1" {
        return Err(VerificationError::Unsupported);
    }
    let spki = public
        .to_der()
        .map_err(|_| VerificationError::Certificate)?;
    let key =
        RsaPublicKey::from_public_key_der(&spki).map_err(|_| VerificationError::Unsupported)?;
    if key.n().bits() < 2048 {
        return Err(VerificationError::Certificate);
    }
    // Some still-used Apple intermediate CA certificates have legacy RSA/SHA-1
    // certificate signatures. This is certificate-path verification only: CMS/content
    // signatures below still require SHA-2, exact server-profile provenance and pinned roots.
    if oid == "1.2.840.113549.1.1.5" {
        let public = public
            .subject_public_key
            .as_bytes()
            .ok_or(VerificationError::Certificate)?;
        return ring::signature::UnparsedPublicKey::new(
            &ring::signature::RSA_PKCS1_2048_8192_SHA1_FOR_LEGACY_USE_ONLY,
            public,
        )
        .verify(message, signature)
        .map_err(|_| VerificationError::Signature);
    }
    let signature = Signature::try_from(signature).map_err(|_| VerificationError::Signature)?;
    match oid {
        "1.2.840.113549.1.1.11" => {
            VerifyingKey::<sha2_010::Sha256>::new(key).verify(message, &signature)
        }
        "1.2.840.113549.1.1.12" => {
            VerifyingKey::<sha2_010::Sha384>::new(key).verify(message, &signature)
        }
        "1.2.840.113549.1.1.13" => {
            VerifyingKey::<sha2_010::Sha512>::new(key).verify(message, &signature)
        }
        _ => return Err(VerificationError::Unsupported),
    }
    .map_err(|_| VerificationError::Signature)
}
fn verify_chain(
    leaf: &Certificate,
    certs: &[Certificate],
    roots: &[Certificate],
    now: SystemTime,
    code_signing: bool,
) -> Result<()> {
    fn valid(cert: &Certificate, now: SystemTime) -> bool {
        now >= cert.tbs_certificate.validity.not_before.to_system_time()
            && now < cert.tbs_certificate.validity.not_after.to_system_time()
    }
    fn walk(
        current: &Certificate,
        certs: &[Certificate],
        roots: &[Certificate],
        now: SystemTime,
        visited: &mut Vec<Certificate>,
        code_signing: bool,
    ) -> Result<()> {
        if !valid(current, now) || visited.len() > 8 || visited.contains(current) {
            return Err(VerificationError::Certificate);
        }
        if code_signing {
            if current
                .tbs_certificate
                .get::<ExtendedKeyUsage>()
                .map_err(|_| VerificationError::Certificate)?
                .is_some_and(|(_, usage)| {
                    !usage.0.iter().any(|oid| {
                        matches!(
                            oid.to_string().as_str(),
                            "1.3.6.1.5.5.7.3.3" | "2.5.29.37.0"
                        )
                    })
                })
            {
                return Err(VerificationError::Certificate);
            }
        }
        if roots.iter().any(|r| r == current) {
            return Ok(());
        }
        let extensions = current.tbs_certificate.extensions.as_deref().unwrap_or(&[]);
        if extensions.len() > 64 {
            return Err(VerificationError::Certificate);
        }
        let mut seen = HashSet::new();
        for extension in extensions {
            let oid = extension.extn_id.to_string();
            if !seen.insert(oid.clone()) {
                return Err(VerificationError::Certificate);
            }
            if extension.critical
                && !matches!(oid.as_str(), "2.5.29.19" | "2.5.29.15" | "2.5.29.37")
            {
                // Apple's critical code-signing marker extensions are NULL markers, not grants.
                if !oid.starts_with("1.2.840.113635.100.6.1.")
                    || extension.extn_value.as_bytes() != [0x05, 0x00]
                {
                    return Err(VerificationError::Unsupported);
                }
            }
        }
        if current.signature_algorithm != current.tbs_certificate.signature {
            return Err(VerificationError::Certificate);
        }
        visited.push(current.clone());
        for issuer in certs
            .iter()
            .chain(roots.iter())
            .filter(|issuer| issuer.tbs_certificate.subject == current.tbs_certificate.issuer)
        {
            let Ok(Some((critical, constraints))) =
                issuer.tbs_certificate.get::<BasicConstraints>()
            else {
                continue;
            };
            if !critical
                || !constraints.ca
                || constraints
                    .path_len_constraint
                    .is_some_and(|n| visited.len().saturating_sub(1) > n as usize)
            {
                continue;
            }
            let Ok(Some((_, usage))) = issuer.tbs_certificate.get::<KeyUsage>() else {
                continue;
            };
            if !usage.key_cert_sign() {
                continue;
            }
            let Some(signature) = current.signature.as_bytes() else {
                continue;
            };
            if verify_public_key_signature(
                issuer,
                &current
                    .tbs_certificate
                    .to_der()
                    .map_err(|_| VerificationError::Certificate)?,
                signature,
                &current.signature_algorithm.oid.to_string(),
            )
            .is_ok()
                && walk(issuer, certs, roots, now, visited, code_signing).is_ok()
            {
                visited.pop();
                return Ok(());
            }
        }
        visited.pop();
        Err(VerificationError::Certificate)
    }
    if leaf
        .tbs_certificate
        .get::<BasicConstraints>()
        .map_err(|_| VerificationError::Certificate)?
        .is_some_and(|(_, c)| c.ca)
    {
        return Err(VerificationError::Certificate);
    }
    let usage = leaf
        .tbs_certificate
        .get::<KeyUsage>()
        .map_err(|_| VerificationError::Certificate)?;
    if !usage.is_some_and(|(_, usage)| usage.digital_signature()) {
        return Err(VerificationError::Certificate);
    }
    walk(leaf, certs, roots, now, &mut Vec::new(), code_signing)
}

fn verify_code_bundle(
    bundle: &Path,
    team: &str,
    id: &str,
    expected: &Certificate,
    roots: &[Certificate],
    now: SystemTime,
    application: bool,
) -> Result<(usize, usize)> {
    let info_bytes = read_bounded(&bundle.join("Info.plist"), MAX_META)?;
    let info: Dictionary =
        plist::from_bytes(&info_bytes).map_err(|_| VerificationError::Structure)?;
    if info.get("CFBundleIdentifier").and_then(Value::as_string) != Some(id) {
        return Err(VerificationError::Identity);
    }
    let exe = info
        .get("CFBundleExecutable")
        .and_then(Value::as_string)
        .ok_or(VerificationError::Structure)?;
    if !safe_relative(exe) || exe.contains('/') {
        return Err(VerificationError::Structure);
    }
    let resource_bytes = read_bounded(&bundle.join("_CodeSignature/CodeResources"), MAX_META)?;
    let resource_count = verify_resources(bundle, exe, &resource_bytes)?;
    let mut slices = verify_macho(
        &bundle.join(exe),
        team,
        id,
        expected,
        roots,
        now,
        Some(&info_bytes),
        Some(&resource_bytes),
        application,
    )?;
    let mut resources = resource_count;
    let mut stack = vec![bundle.to_path_buf()];
    while let Some(dir) = stack.pop() {
        for entry in fs::read_dir(&dir).map_err(|_| VerificationError::Io)? {
            let entry = entry.map_err(|_| VerificationError::Io)?;
            let path = entry.path();
            let kind = entry.file_type().map_err(|_| VerificationError::Io)?;
            if kind.is_dir() {
                let extension = path.extension().and_then(|s| s.to_str()).unwrap_or("");
                if matches!(extension, "framework" | "appex") {
                    let child_info: Dictionary =
                        plist::from_bytes(&read_bounded(&path.join("Info.plist"), MAX_META)?)
                            .map_err(|_| VerificationError::Structure)?;
                    let child_id = child_info
                        .get("CFBundleIdentifier")
                        .and_then(Value::as_string)
                        .ok_or(VerificationError::Identity)?;
                    let (child_slices, child_resources) = verify_code_bundle(
                        &path,
                        team,
                        child_id,
                        expected,
                        roots,
                        now,
                        extension == "appex",
                    )?;
                    slices += child_slices;
                    resources += child_resources;
                } else {
                    stack.push(path);
                }
            } else if kind.is_file()
                && path != bundle.join(exe)
                && path.extension().is_some_and(|ext| ext == "dylib")
            {
                let name = path
                    .file_name()
                    .and_then(|n| n.to_str())
                    .ok_or(VerificationError::Identity)?;
                slices += verify_macho(&path, team, name, expected, roots, now, None, None, false)?;
            } else if !kind.is_file() {
                return Err(VerificationError::Structure);
            }
        }
    }
    Ok((slices, resources))
}
fn safe_relative(name: &str) -> bool {
    !name.is_empty()
        && !name.contains(['\\', ':'])
        && !name.chars().any(char::is_control)
        && Path::new(name)
            .components()
            .all(|c| matches!(c, Component::Normal(_)))
}
fn verify_resources(bundle: &Path, exe: &str, bytes: &[u8]) -> Result<usize> {
    let resource: Dictionary = plist::from_bytes(bytes).map_err(|_| VerificationError::Resource)?;
    let files = resource
        .get("files")
        .and_then(Value::as_dictionary)
        .ok_or(VerificationError::Resource)?;
    let files2 = resource
        .get("files2")
        .and_then(Value::as_dictionary)
        .ok_or(VerificationError::Resource)?;
    let mut sealed = HashSet::new();
    for (table, second) in [(files, false), (files2, true)] {
        if table.len() > 100_000 {
            return Err(VerificationError::Resource);
        }
        for (name, entry) in table {
            if !safe_relative(name) {
                return Err(VerificationError::Resource);
            }
            let (sha1, sha256) = if let Some(data) = entry.as_data() {
                if second {
                    return Err(VerificationError::Resource);
                }
                (Some(data), None)
            } else {
                let dict = entry.as_dictionary().ok_or(VerificationError::Resource)?;
                if dict
                    .keys()
                    .any(|k| !matches!(k.as_str(), "hash" | "hash2" | "optional"))
                {
                    return Err(VerificationError::Unsupported);
                }
                (
                    dict.get("hash").and_then(Value::as_data),
                    dict.get("hash2").and_then(Value::as_data),
                )
            };
            if sha1.is_none() || (second && sha256.is_none()) {
                return Err(VerificationError::Resource);
            }
            let (first, second_hash) = hash_file(&bundle.join(name))?;
            if sha1.is_some_and(|expected| expected != first)
                || (sha256.is_some_and(|expected| expected != second_hash))
            {
                return Err(VerificationError::HashMismatch);
            }
            sealed.insert(name.clone());
        }
    }
    let mut stack = vec![bundle.to_path_buf()];
    let mut count = 0;
    while let Some(dir) = stack.pop() {
        for entry in fs::read_dir(dir).map_err(|_| VerificationError::Io)? {
            let entry = entry.map_err(|_| VerificationError::Io)?;
            let p = entry.path();
            let ft = entry.file_type().map_err(|_| VerificationError::Io)?;
            if ft.is_dir() {
                stack.push(p);
                continue;
            }
            if !ft.is_file() {
                return Err(VerificationError::Resource);
            }
            let relative = p
                .strip_prefix(bundle)
                .map_err(|_| VerificationError::Resource)?
                .to_str()
                .ok_or(VerificationError::Resource)?
                .replace('\\', "/");
            if relative == exe
                || relative == "_CodeSignature/CodeResources"
                || relative == ".DS_Store"
                || relative.ends_with("/.DS_Store")
                || relative.ends_with(".lproj/locversion.plist")
            {
                continue;
            }
            if !sealed.contains(&relative) {
                return Err(VerificationError::Resource);
            }
            count += 1;
        }
    }
    Ok(count)
}
fn hash_file(path: &Path) -> Result<(Vec<u8>, Vec<u8>)> {
    let meta = fs::symlink_metadata(path).map_err(|_| VerificationError::Resource)?;
    if !meta.file_type().is_file() || meta.len() > 4 * 1024 * 1024 * 1024 {
        return Err(VerificationError::Resource);
    }
    let mut f = File::open(path).map_err(|_| VerificationError::Io)?;
    let mut first = sha1::Sha1::new();
    let mut second = Sha256::new();
    let mut buffer = [0u8; 64 * 1024];
    loop {
        let n = f.read(&mut buffer).map_err(|_| VerificationError::Io)?;
        if n == 0 {
            break;
        }
        first.update(&buffer[..n]);
        second.update(&buffer[..n]);
    }
    Ok((first.finalize().to_vec(), second.finalize().to_vec()))
}
struct Slice {
    base: u64,
    len: u64,
}
fn macho_slices(file: &mut File) -> Result<Vec<Slice>> {
    let len = file.metadata().map_err(|_| VerificationError::Io)?.len();
    let h = read_at(file, 0, 8)?;
    let big = h[..4] == [0xca, 0xfe, 0xba, 0xbe] || h[..4] == [0xca, 0xfe, 0xba, 0xbf];
    let fat = big || h[..4] == [0xbe, 0xba, 0xfe, 0xca] || h[..4] == [0xbf, 0xba, 0xfe, 0xca];
    if !fat {
        return Ok(vec![Slice { base: 0, len }]);
    }
    let wide = h[..4] == [0xca, 0xfe, 0xba, 0xbf] || h[..4] == [0xbf, 0xba, 0xfe, 0xca];
    let count = word(&h, 4, big)? as usize;
    if count == 0 || count > 32 {
        return Err(VerificationError::Structure);
    }
    let stride = if wide { 32 } else { 20 };
    let table = read_at(file, 8, count * stride)?;
    let mut out: Vec<Slice> = vec![];
    for n in 0..count {
        let p = n * stride;
        let base = if wide {
            wide_word(&table, p + 8, big)?
        } else {
            word(&table, p + 8, big)? as u64
        };
        let length = if wide {
            wide_word(&table, p + 16, big)?
        } else {
            word(&table, p + 12, big)? as u64
        };
        let align = word(&table, p + if wide { 24 } else { 16 }, big)?;
        if align > 16
            || base % (1u64 << align) != 0
            || (wide && word(&table, p + 28, big)? != 0)
            || base < (8 + table.len()) as u64
            || length < 28
            || base.checked_add(length).is_none_or(|end| end > len)
            || out
                .iter()
                .any(|s| base < s.base + s.len && base + length > s.base)
        {
            return Err(VerificationError::Structure);
        }
        let actual = read_at(file, base, 12)?;
        if word(&actual, 4, false)? != word(&table, p, big)?
            || word(&actual, 8, false)? != word(&table, p + 4, big)?
        {
            return Err(VerificationError::Structure);
        }
        out.push(Slice { base, len: length });
    }
    let mut ranges: Vec<_> = out.iter().map(|s| (s.base, s.base + s.len)).collect();
    ranges.sort_unstable();
    let mut cursor = 8 + table.len() as u64;
    for (start, end) in ranges {
        let gap = start
            .checked_sub(cursor)
            .ok_or(VerificationError::Structure)?;
        if gap > 65536 {
            return Err(VerificationError::Unsupported);
        }
        if gap > 0 && read_at(file, cursor, gap as usize)?.iter().any(|b| *b != 0) {
            return Err(VerificationError::Structure);
        }
        cursor = end;
    }
    if cursor != len {
        return Err(VerificationError::Structure);
    }
    Ok(out)
}
fn wide_word(d: &[u8], p: usize, big: bool) -> Result<u64> {
    wide(d, p, big)
}
fn verify_macho(
    path: &Path,
    team: &str,
    id: &str,
    expected: &Certificate,
    roots: &[Certificate],
    now: SystemTime,
    info: Option<&[u8]>,
    resources: Option<&[u8]>,
    application: bool,
) -> Result<usize> {
    crate::archive::inspect_macho(path, application).map_err(|_| VerificationError::Structure)?;
    let mut file = File::open(path).map_err(|_| VerificationError::Io)?;
    let slices = macho_slices(&mut file)?;
    for slice in &slices {
        let h = read_at(&mut file, slice.base, 32)?;
        let is64 = word(&h, 0, false)? == 0xfeed_facf;
        let header = if is64 { 32 } else { 28 };
        if !is64 && word(&h, 0, false)? != 0xfeed_face {
            return Err(VerificationError::Unsupported);
        }
        let count = word(&h, 16, false)? as usize;
        let len = word(&h, 20, false)? as usize;
        if count > 4096 || len > MAX_META || header + len > slice.len as usize {
            return Err(VerificationError::Structure);
        }
        let cmds = read_at(&mut file, slice.base + header as u64, len)?;
        let mut pos = 0usize;
        let mut signature = None;
        for _ in 0..count {
            let kind = word(&cmds, pos, false)?;
            let size = word(&cmds, pos + 4, false)? as usize;
            if size < 8 || pos.checked_add(size).is_none_or(|end| end > cmds.len()) {
                return Err(VerificationError::Structure);
            }
            if kind == 0x1d {
                if size != 16 || signature.is_some() {
                    return Err(VerificationError::Structure);
                }
                signature = Some((
                    word(&cmds, pos + 8, false)? as u64,
                    word(&cmds, pos + 12, false)? as usize,
                ));
            }
            pos += size;
        }
        if pos != cmds.len() {
            return Err(VerificationError::Structure);
        }
        let (start, size) = signature.ok_or(VerificationError::Signature)?;
        if size > MAX_META
            || start < (header + len) as u64
            || start.checked_add(size as u64) != Some(slice.len)
        {
            return Err(VerificationError::Structure);
        }
        let sig = read_at(&mut file, slice.base + start, size)?;
        let slots = signature_slots(&sig)?;
        // Also enforces lossless XML/DER agreement using the shared bounded parser.
        let entitlements = crate::capabilities::signature_entitlements(&sig)
            .map_err(|_| VerificationError::Entitlements)?;
        if !application && !entitlements.is_empty() {
            return Err(VerificationError::Entitlements);
        }
        let mut cds = vec![];
        let mut algorithms = HashSet::new();
        for (slot, bytes) in &slots {
            if *slot == 0 || (*slot >= 0x1000 && *slot < 0x1006) {
                let algorithm = verify_directory(
                    &mut file,
                    slice,
                    start,
                    bytes,
                    team,
                    id,
                    &slots,
                    info,
                    resources,
                    application,
                )?;
                if !algorithms.insert(algorithm.code_directory_hash_type()) {
                    return Err(VerificationError::Signature);
                }
                cds.push((algorithm, bytes.to_vec()));
            }
        }
        if !slots.contains_key(&0) || !cds.iter().any(|(a, _)| *a == HashAlgorithm::Sha256) {
            return Err(VerificationError::Signature);
        }
        let primary = slots.get(&0).ok_or(VerificationError::Signature)?;
        let cms = slots.get(&0x10000).ok_or(VerificationError::Signature)?;
        if word(cms, 0, true)? != 0xfade_0b01 {
            return Err(VerificationError::Signature);
        }
        let evidence = verify_cms(&cms[8..], Some(primary), roots, now, Some(&cds))?;
        if evidence.leaf != *expected {
            return Err(VerificationError::Certificate);
        }
        let eku = evidence
            .leaf
            .tbs_certificate
            .get::<ExtendedKeyUsage>()
            .map_err(|_| VerificationError::Certificate)?;
        if !eku.is_some_and(|(_, usage)| {
            usage
                .0
                .iter()
                .any(|oid| oid.to_string() == "1.3.6.1.5.5.7.3.3")
        }) {
            return Err(VerificationError::Certificate);
        }
    }
    Ok(slices.len())
}
fn signature_slots(sig: &[u8]) -> Result<BTreeMap<u32, &[u8]>> {
    if word(sig, 0, true)? != 0xfade_0cc0 {
        return Err(VerificationError::Structure);
    }
    let len = word(sig, 4, true)? as usize;
    let count = word(sig, 8, true)? as usize;
    if count > 256 || len > sig.len() || 12 + count * 8 > len {
        return Err(VerificationError::Structure);
    }
    let mut slots = BTreeMap::new();
    let mut ranges = vec![];
    for n in 0..count {
        let slot = word(sig, 12 + n * 8, true)?;
        let offset = word(sig, 16 + n * 8, true)? as usize;
        let size = word(sig, offset + 4, true)? as usize;
        let end = offset
            .checked_add(size)
            .ok_or(VerificationError::Structure)?;
        if offset < 12 + count * 8
            || size < 8
            || end > len
            || slots.contains_key(&slot)
            || ranges.iter().any(|(a, b)| offset < *b && end > *a)
        {
            return Err(VerificationError::Structure);
        }
        ranges.push((offset, end));
        slots.insert(slot, &sig[offset..end]);
    }
    Ok(slots)
}
fn c_string(data: &[u8], offset: usize) -> Result<&str> {
    let bytes = data.get(offset..).ok_or(VerificationError::Structure)?;
    let len = bytes
        .iter()
        .position(|b| *b == 0)
        .ok_or(VerificationError::Structure)?;
    if len == 0 || len > 512 {
        return Err(VerificationError::Identity);
    }
    std::str::from_utf8(&bytes[..len]).map_err(|_| VerificationError::Identity)
}
fn verify_directory(
    file: &mut File,
    slice: &Slice,
    signature_start: u64,
    cd: &[u8],
    team: &str,
    id: &str,
    slots: &BTreeMap<u32, &[u8]>,
    info: Option<&[u8]>,
    resources: Option<&[u8]>,
    application: bool,
) -> Result<HashAlgorithm> {
    if word(cd, 0, true)? != 0xfade_0c02
        || word(cd, 4, true)? as usize != cd.len()
        || word(cd, 8, true)? != 0x20400
        || cd.len() < 88
    {
        return Err(VerificationError::Unsupported);
    }
    let hash_offset = word(cd, 16, true)? as usize;
    let identifier = word(cd, 20, true)? as usize;
    let specials = word(cd, 24, true)? as usize;
    let code_slots = word(cd, 28, true)? as usize;
    let mut limit = word(cd, 32, true)? as u64;
    let hash_len = *cd.get(36).ok_or(VerificationError::Structure)? as usize;
    let algorithm = match cd.get(37) {
        Some(1) if hash_len == 20 => HashAlgorithm::Sha1,
        Some(2) if hash_len == 32 => HashAlgorithm::Sha256,
        _ => return Err(VerificationError::Unsupported),
    };
    let page = *cd.get(39).ok_or(VerificationError::Structure)?;
    if !(12..=16).contains(&page)
        || specials != if application { 7 } else { 5 }
        || word(cd, 44, true)? != 0
        || word(cd, 12, true)? & 2 != 0
    {
        return Err(VerificationError::Unsupported);
    }
    if limit == 0 {
        limit = wide(cd, 56, true)?
    }
    if limit != signature_start
        || limit > slice.len
        || code_slots as u64 != limit.div_ceil(1u64 << page)
    {
        return Err(VerificationError::Structure);
    }
    let metadata_end = hash_offset
        .checked_sub(specials * hash_len)
        .ok_or(VerificationError::Structure)?;
    if metadata_end < 88
        || metadata_end > cd.len()
        || hash_offset
            .checked_add(
                code_slots
                    .checked_mul(hash_len)
                    .ok_or(VerificationError::Structure)?,
            )
            .is_none_or(|end| end != cd.len())
    {
        return Err(VerificationError::Structure);
    }
    let team_offset = word(cd, 48, true)? as usize;
    if identifier < 88
        || team_offset < 88
        || c_string(&cd[..metadata_end], identifier)? != id
        || c_string(&cd[..metadata_end], team_offset)? != team
    {
        return Err(VerificationError::Identity);
    }
    for slot in 1..=specials {
        let start = hash_offset - slot * hash_len;
        let expected = &cd[start..start + hash_len];
        let content = match slot {
            1 => info,
            2 => slots.get(&2).copied(),
            3 => resources,
            5 => slots.get(&5).copied(),
            7 => slots.get(&7).copied(),
            _ => None,
        };
        let actual = content
            .map(|bytes| algorithm.digest(bytes))
            .unwrap_or_else(|| vec![0; hash_len]);
        if expected != actual {
            return Err(VerificationError::HashMismatch);
        }
    }
    for slot in 0..code_slots {
        let offset = slot as u64 * (1u64 << page);
        let size = (limit - offset).min(1u64 << page) as usize;
        let bytes = read_at(file, slice.base + offset, size)?;
        let expected = &cd[hash_offset + slot * hash_len..hash_offset + (slot + 1) * hash_len];
        if expected != algorithm.digest(&bytes) {
            return Err(VerificationError::HashMismatch);
        }
    }
    Ok(algorithm)
}

#[cfg(test)]
#[path = "synthetic_signing_tests.rs"]
mod synthetic_signing_tests;
