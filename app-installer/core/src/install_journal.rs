//! One unconfirmed, user-approved install transaction. Public app source/metadata only;
//! no pairing records, signing keys or credentials. Never infer device success from this file.
use serde::{de::DeserializeOwned, Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::{
    fs::{self, File, OpenOptions},
    io::{self, Read, Write},
    path::{Path, PathBuf},
};
const NAME: &str = "pending-install.json";
const MAX_SOURCE: u64 = 16 * 1024 * 1024 * 1024;
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Pending<R> {
    version: u32,
    pub bundle_id: String,
    pub source_sha256: String,
    pub record: R,
}
fn invalid() -> io::Error {
    io::Error::new(
        io::ErrorKind::InvalidData,
        "Invalid protected install journal",
    )
}
fn valid_hash(hash: &str) -> bool {
    hash.len() == 64
        && hash
            .bytes()
            .all(|b| b.is_ascii_digit() || (b'a'..=b'f').contains(&b))
}
fn valid_id(id: &str) -> bool {
    !id.is_empty()
        && id.len() <= 255
        && id
            .split('.')
            .all(|p| !p.is_empty() && p.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-'))
}
fn open_regular(path: &Path) -> io::Result<File> {
    let metadata = fs::symlink_metadata(path)?;
    if !metadata.file_type().is_file() || metadata.len() > MAX_SOURCE {
        return Err(invalid());
    }
    #[cfg(unix)]
    {
        use std::os::unix::fs::MetadataExt;
        if metadata.nlink() != 1 {
            return Err(invalid());
        }
    }
    let file = File::open(path)?;
    let actual = file.metadata()?;
    if !actual.is_file() || actual.len() > MAX_SOURCE {
        return Err(invalid());
    }
    Ok(file)
}
pub fn hash_file(path: &Path) -> io::Result<String> {
    let mut file = open_regular(path)?;
    let mut hash = Sha256::new();
    let mut bytes = [0u8; 65536];
    let mut total = 0u64;
    loop {
        let n = file.read(&mut bytes)?;
        if n == 0 {
            break;
        }
        total = total.checked_add(n as u64).ok_or_else(invalid)?;
        if total > MAX_SOURCE {
            return Err(invalid());
        }
        hash.update(&bytes[..n]);
    }
    let mut out = String::with_capacity(64);
    for b in hash.finalize() {
        out.push_str(&format!("{b:02x}"));
    }
    Ok(out)
}
pub fn read<R: DeserializeOwned>(work: &Path) -> io::Result<Option<Pending<R>>> {
    let path = work.join(NAME);
    let metadata = match fs::symlink_metadata(&path) {
        Ok(m) => m,
        Err(e) if e.kind() == io::ErrorKind::NotFound => return Ok(None),
        Err(e) => return Err(e),
    };
    if !metadata.file_type().is_file() || metadata.len() > 256 * 1024 {
        return Err(invalid());
    }
    let record: Pending<R> = serde_json::from_slice(&fs::read(path)?).map_err(|_| invalid())?;
    if record.version != 1 || !valid_id(&record.bundle_id) || !valid_hash(&record.source_sha256) {
        return Err(invalid());
    }
    Ok(Some(record))
}
pub fn candidate<R>(work: &Path, pending: &Pending<R>) -> PathBuf {
    work.join("sources")
        .join(format!("pending-install-{}.ipa", pending.source_sha256))
}
fn sync_parent(path: &Path) -> io::Result<()> {
    File::open(path.parent().ok_or_else(invalid)?)?.sync_all()
}
fn atomic_json(path: &Path, bytes: &[u8]) -> io::Result<()> {
    let temp = path.with_extension("json.new");
    if fs::symlink_metadata(&temp).is_ok_and(|m| !m.file_type().is_file()) {
        return Err(invalid());
    }
    let mut options = OpenOptions::new();
    options.write(true).create(true).truncate(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    let mut file = options.open(&temp)?;
    file.write_all(bytes)?;
    file.sync_all()?;
    fs::rename(temp, path)?;
    sync_parent(path)
}
/// Retain exact validated input and commit intent before any upload/install request.
pub fn prepare<R: Serialize + DeserializeOwned>(
    work: &Path,
    bundle_id: &str,
    record: &R,
    source: &Path,
) -> io::Result<()> {
    let old = read::<R>(work)?;
    if old
        .as_ref()
        .is_some_and(|p| !p.bundle_id.eq_ignore_ascii_case(bundle_id))
    {
        return Err(invalid());
    }
    let hash = hash_file(source)?;
    let path = work
        .join("sources")
        .join(format!("pending-install-{hash}.ipa"));
    if !path.exists() {
        let temp = path.with_extension("ipa.new");
        if fs::symlink_metadata(&temp).is_ok_and(|m| !m.file_type().is_file()) {
            return Err(invalid());
        }
        let mut input = open_regular(source)?;
        let mut options = OpenOptions::new();
        options.create(true).truncate(true).write(true);
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            options.mode(0o600);
        }
        let mut output = options.open(&temp)?;
        io::copy(&mut input, &mut output)?;
        output.sync_all()?;
        if hash_file(&temp)? != hash {
            return Err(invalid());
        }
        fs::rename(temp, &path)?;
        sync_parent(&path)?;
    } else if hash_file(&path)? != hash {
        return Err(invalid());
    }
    let pending = Pending {
        version: 1,
        bundle_id: bundle_id.to_owned(),
        source_sha256: hash,
        record,
    };
    atomic_json(
        &work.join(NAME),
        &serde_json::to_vec(&pending).map_err(|_| invalid())?,
    )?;
    // Exactly one committed intent; discard the former candidate only after replacement commits.
    if let Some(old) = old {
        let old_path = candidate(work, &old);
        if old_path != path {
            let _ = fs::remove_file(old_path);
        }
    }
    Ok(())
}
pub fn verified_candidate<R>(work: &Path, pending: &Pending<R>) -> io::Result<PathBuf> {
    let path = candidate(work, pending);
    if hash_file(&path)? != pending.source_sha256 {
        return Err(invalid());
    }
    Ok(path)
}
pub fn clear<R>(work: &Path, pending: &Pending<R>) -> io::Result<()> {
    match fs::remove_file(work.join(NAME)) {
        Ok(()) => {}
        Err(e) if e.kind() == io::ErrorKind::NotFound => {}
        Err(e) => return Err(e),
    }
    sync_parent(&work.join(NAME))?;
    match fs::remove_file(candidate(work, pending)) {
        Ok(()) => Ok(()),
        Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(()),
        Err(e) => Err(e),
    }
}
/// Remove only unreferenced names in this module's namespace, never ordinary cached sources.
pub fn cleanup_unreferenced<R: DeserializeOwned>(work: &Path) -> io::Result<()> {
    let active = read::<R>(work)?;
    let retained = active.as_ref().map(|p| candidate(work, p));
    for entry in fs::read_dir(work.join("sources"))? {
        let entry = entry?;
        let path = entry.path();
        let name = entry.file_name();
        let Some(name) = name.to_str() else { continue };
        let Some(rest) = name.strip_prefix("pending-install-") else {
            continue;
        };
        let hash = rest
            .strip_suffix(".ipa")
            .or_else(|| rest.strip_suffix(".ipa.new"));
        if hash.is_some_and(valid_hash)
            && retained.as_ref() != Some(&path)
            && !entry.file_type()?.is_dir()
        {
            fs::remove_file(path)?;
        }
    }
    // An uncommitted JSON replacement cannot have initiated an upload.
    let uncommitted = work.join("pending-install.json.new");
    if fs::symlink_metadata(&uncommitted)
        .is_ok_and(|m| m.file_type().is_file() || m.file_type().is_symlink())
    {
        fs::remove_file(uncommitted)?;
    }
    Ok(())
}
