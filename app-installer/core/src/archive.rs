//! Bounded, fail-closed validation before a third-party signer sees an IPA.
//! Extract only to a new private staging directory; no archive paths appear in errors.
use std::{
    collections::{HashMap, HashSet},
    fmt,
    fs::{self, File, OpenOptions},
    io::{self, Read, Seek, SeekFrom, Write},
    path::{Path, PathBuf},
};
use unicode_casefold::UnicodeCaseFold;
use unicode_normalization::UnicodeNormalization;
use zip::ZipArchive;

const MAX_ARCHIVE_BYTES: u64 = 16 * 1024 * 1024 * 1024;
const MAX_UNCOMPRESSED_BYTES: u64 = 16 * 1024 * 1024 * 1024;
const MAX_FILE_BYTES: u64 = 4 * 1024 * 1024 * 1024;
const MAX_ENTRIES: usize = 100_000;
const MAX_CENTRAL_BYTES: u64 = 32 * 1024 * 1024;
const MAX_PATH_STORAGE_BYTES: usize = 32 * 1024 * 1024;
const MAX_RATIO: u64 = 1_000;
const MAX_PLIST_BYTES: u64 = 4 * 1024 * 1024;
const MAX_LOAD_COMMAND_BYTES: u64 = 16 * 1024 * 1024;
const ARM64: u32 = 0x0100_000c;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ValidationError {
    Io,
    InvalidZip,
    UnsafePath,
    DuplicatePath,
    SpecialFile,
    ArchiveLimit,
    InvalidLayout,
    InvalidInfo,
    UnsupportedExecutable,
    EncryptedExecutable,
    DestinationExists,
}
impl fmt::Display for ValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(match self {
            Self::Io => "The IPA could not be read or staged.",
            Self::InvalidZip => "The IPA archive is invalid or unsupported.",
            Self::UnsafePath => "The IPA contains an unsafe file path.",
            Self::DuplicatePath => "The IPA contains conflicting file paths.",
            Self::SpecialFile => "The IPA contains a symbolic link or special file.",
            Self::ArchiveLimit => "The IPA exceeds a supported archive limit.",
            Self::InvalidLayout => "The IPA must contain one supported iPhone app.",
            Self::InvalidInfo => "The IPA app information is invalid.",
            Self::UnsupportedExecutable => "The IPA does not contain a supported arm64 executable.",
            Self::EncryptedExecutable => {
                "The IPA contains an encrypted executable. Import a decrypted copy you own."
            }
            Self::DestinationExists => "The IPA staging location is already in use.",
        })
    }
}
impl std::error::Error for ValidationError {}
impl From<io::Error> for ValidationError {
    fn from(_: io::Error) -> Self {
        Self::Io
    }
}

/// Owns the entire private staging tree. Drop removes it on success, failure or cancellation.
/// The engine may retain a separately copied original IPA after a confirmed installation;
/// it must not retain signing private keys or provisioning files from this staging tree.
#[derive(Debug)]
pub struct ValidatedIpa {
    pub app_dir: PathBuf,
    pub bundle_id: String,
    pub display_name: String,
    pub extension_ids: Vec<String>,
    staging_dir: PathBuf,
}
impl Drop for ValidatedIpa {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.staging_dir);
    }
}

struct StagingGuard {
    path: PathBuf,
    keep: bool,
}
impl Drop for StagingGuard {
    fn drop(&mut self) {
        if !self.keep {
            let _ = fs::remove_dir_all(&self.path);
        }
    }
}
struct Entry {
    index: usize,
    path: PathBuf,
    directory: bool,
    size: u64,
    executable: bool,
}

/// The destination must be a new child of an existing trusted private directory.
/// Existing destinations are never emptied or overwritten. No remote requests occur.
pub fn validate_and_extract(
    input: &Path,
    destination: &Path,
) -> Result<ValidatedIpa, ValidationError> {
    let input_info = fs::symlink_metadata(input)?;
    if !input_info.file_type().is_file() {
        return Err(ValidationError::InvalidZip);
    }
    let mut file = File::open(input)?;
    let declared_entries = inspect_directory_limits(&mut file)?;
    let mut archive = ZipArchive::new(file).map_err(|_| ValidationError::InvalidZip)?;
    if archive.len() != declared_entries {
        return Err(ValidationError::DuplicatePath);
    }
    if archive.is_empty() || archive.len() > MAX_ENTRIES {
        return Err(ValidationError::ArchiveLimit);
    }
    let (entries, app_name) = inspect_entries(&mut archive)?;
    let leaf = destination.file_name().ok_or(ValidationError::UnsafePath)?;
    if leaf == "." || leaf == ".." {
        return Err(ValidationError::UnsafePath);
    }
    let parent = destination
        .parent()
        .ok_or(ValidationError::UnsafePath)?
        .canonicalize()?;
    if !parent.is_dir() {
        return Err(ValidationError::UnsafePath);
    }
    let staging = parent.join(leaf);
    match fs::create_dir(&staging) {
        Ok(()) => (),
        Err(e) if e.kind() == io::ErrorKind::AlreadyExists => {
            return Err(ValidationError::DestinationExists)
        }
        Err(_) => return Err(ValidationError::Io),
    }
    let mut guard = StagingGuard {
        path: staging.clone(),
        keep: false,
    };
    private_permissions(&staging, true, false)?;
    for entry in &entries {
        let target = staging.join(&entry.path);
        if entry.directory {
            create_private_dirs(&staging, &entry.path)?;
            continue;
        }
        create_private_dirs(
            &staging,
            entry.path.parent().ok_or(ValidationError::UnsafePath)?,
        )?;
        let mut output = OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&target)?;
        private_permissions(&target, false, entry.executable)?;
        let mut source = archive
            .by_index(entry.index)
            .map_err(|_| ValidationError::InvalidZip)?;
        let written = io::copy(&mut source.by_ref().take(entry.size + 1), &mut output)
            .map_err(|_| ValidationError::InvalidZip)?;
        if written != entry.size {
            return Err(ValidationError::InvalidZip);
        }
        // Finish through EOF to make the ZIP reader validate CRC and declared size.
        let mut extra = [0u8; 1];
        if source
            .read(&mut extra)
            .map_err(|_| ValidationError::InvalidZip)?
            != 0
        {
            return Err(ValidationError::InvalidZip);
        }
        output.flush()?;
    }
    let app_dir = staging.join("Payload").join(app_name);
    let (bundle_id, display_name, _) = inspect_bundle(&app_dir, true)?;
    let mut extension_ids = Vec::new();
    let mut identities = HashSet::from([bundle_id.to_ascii_lowercase()]);
    let mut bundles = Vec::new();
    collect_code_bundles(&app_dir, &mut bundles)?;
    for path in bundles {
        let is_extension = path.extension().is_some_and(|e| e == "appex");
        let is_app = path.extension().is_some_and(|e| e == "app");
        if is_extension || is_app {
            let (id, _, _) = inspect_bundle(&path, true)?;
            if !identities.insert(id.to_ascii_lowercase()) {
                return Err(ValidationError::InvalidInfo);
            }
            if is_extension {
                extension_ids.push(id);
            }
        } else if path.extension().is_some_and(|e| e == "framework") {
            // Frameworks must expose an unencrypted arm64 dynamic library.
            inspect_bundle(&path, false)?;
        } else if path.extension().is_some_and(|e| e == "dylib") {
            inspect_macho(&path, false)?;
        }
    }
    extension_ids.sort();
    guard.keep = true;
    Ok(ValidatedIpa {
        app_dir,
        bundle_id,
        display_name,
        extension_ids,
        staging_dir: staging,
    })
}

/// Bound central-directory allocation before zip::ZipArchive parses attacker-controlled metadata.
/// ZIP64 is supported; split-disk and self-extracting archives are deliberately unsupported.
fn inspect_directory_limits(file: &mut File) -> Result<usize, ValidationError> {
    let len = file.metadata()?.len();
    if len < 22 {
        return Err(ValidationError::InvalidZip);
    }
    if len > MAX_ARCHIVE_BYTES {
        return Err(ValidationError::ArchiveLimit);
    }
    if read_at::<4>(file, 0)? != [0x50, 0x4b, 0x03, 0x04] {
        return Err(ValidationError::InvalidZip);
    }
    let tail_len = len.min(22 + 65_535) as usize;
    file.seek(SeekFrom::Start(len - tail_len as u64))?;
    let mut tail = vec![0u8; tail_len];
    file.read_exact(&mut tail)?;
    let eocd = (0..=tail_len - 22)
        .rev()
        .find(|&n| {
            tail[n..n + 4] == [0x50, 0x4b, 0x05, 0x06]
                && n + 22 + u16::from_le_bytes([tail[n + 20], tail[n + 21]]) as usize == tail_len
        })
        .ok_or(ValidationError::InvalidZip)?;
    let eocd_offset = len - tail_len as u64 + eocd as u64;
    let bytes = &tail[eocd..eocd + 22];
    let u16field = |n: usize| u16::from_le_bytes([bytes[n], bytes[n + 1]]);
    if u16field(4) != 0 || u16field(6) != 0 {
        return Err(ValidationError::InvalidZip);
    }
    let (count, size, offset, limit) = if u16field(10) == u16::MAX
        || u32_at(bytes, 12, false) == u32::MAX
        || u32_at(bytes, 16, false) == u32::MAX
    {
        let locator_offset = eocd_offset
            .checked_sub(20)
            .ok_or(ValidationError::InvalidZip)?;
        let locator = read_at::<20>(file, locator_offset)?;
        if locator[..4] != [0x50, 0x4b, 0x06, 0x07]
            || u32_at(&locator, 4, false) != 0
            || u32_at(&locator, 16, false) != 1
        {
            return Err(ValidationError::InvalidZip);
        }
        let record_offset = u64_at(&locator, 8, false);
        if record_offset
            .checked_add(56)
            .is_none_or(|end| end > locator_offset)
        {
            return Err(ValidationError::InvalidZip);
        }
        let record = read_at::<56>(file, record_offset)?;
        let record_size = u64_at(&record, 4, false);
        if record[..4] != [0x50, 0x4b, 0x06, 0x06]
            || !(44..=MAX_CENTRAL_BYTES).contains(&record_size)
            || record_offset
                .checked_add(12 + record_size)
                .is_none_or(|end| end > locator_offset)
            || u32_at(&record, 16, false) != 0
            || u32_at(&record, 20, false) != 0
            || u64_at(&record, 24, false) != u64_at(&record, 32, false)
        {
            return Err(ValidationError::InvalidZip);
        }
        (
            u64_at(&record, 32, false),
            u64_at(&record, 40, false),
            u64_at(&record, 48, false),
            record_offset,
        )
    } else {
        if u16field(8) != u16field(10) {
            return Err(ValidationError::InvalidZip);
        }
        (
            u16field(10) as u64,
            u32_at(bytes, 12, false) as u64,
            u32_at(bytes, 16, false) as u64,
            eocd_offset,
        )
    };
    if count == 0 || count > MAX_ENTRIES as u64 || size > MAX_CENTRAL_BYTES {
        return Err(ValidationError::ArchiveLimit);
    }
    if offset.checked_add(size).is_none_or(|end| end > limit) || size < count * 46 {
        return Err(ValidationError::InvalidZip);
    }
    file.seek(SeekFrom::Start(0))?;
    Ok(count as usize)
}

fn inspect_entries<R: Read + Seek>(
    archive: &mut ZipArchive<R>,
) -> Result<(Vec<Entry>, String), ValidationError> {
    let mut entries = Vec::with_capacity(archive.len());
    // Reserve every ancestor as a directory so implicit/explicit directory entries coexist,
    // while aliases and file/parent conflicts are rejected before touching the filesystem.
    let mut paths: HashMap<String, (String, bool, bool)> = HashMap::new();
    let mut main_apps = HashSet::new();
    let mut total = 0u64;
    let mut path_storage = 0usize;
    for index in 0..archive.len() {
        let file = archive
            .by_index(index)
            .map_err(|_| ValidationError::InvalidZip)?;
        let raw = std::str::from_utf8(file.name_raw()).map_err(|_| ValidationError::UnsafePath)?;
        if file.encrypted() {
            return Err(ValidationError::InvalidZip);
        }
        let directory = file.is_dir();
        let name = raw.strip_suffix('/').unwrap_or(raw);
        let components = safe_path_components(name)?;
        let mode = file.unix_mode().unwrap_or(0);
        let kind = mode & 0o170000;
        if !matches!(kind, 0 | 0o100000 | 0o040000)
            || (kind == 0o040000 && !directory)
            || (kind == 0o100000 && directory)
        {
            return Err(ValidationError::SpecialFile);
        }
        if directory && file.size() != 0 {
            return Err(ValidationError::InvalidZip);
        }
        if file.size() > MAX_FILE_BYTES {
            return Err(ValidationError::ArchiveLimit);
        }
        total = total
            .checked_add(file.size())
            .ok_or(ValidationError::ArchiveLimit)?;
        if total > MAX_UNCOMPRESSED_BYTES {
            return Err(ValidationError::ArchiveLimit);
        }
        if file.size() > 1024 * 1024 && file.size() / file.compressed_size().max(1) > MAX_RATIO {
            return Err(ValidationError::ArchiveLimit);
        }
        let mut original = String::new();
        for (n, component) in components.iter().enumerate() {
            if n > 0 {
                original.push('/');
            }
            original.push_str(component);
            let final_component = n + 1 == components.len();
            let needs_directory = !final_component || directory;
            let key = original.nfd().case_fold().nfd().collect::<String>();
            match paths.get_mut(&key) {
                Some((spelling, was_directory, explicit)) => {
                    if spelling != &original
                        || *was_directory != needs_directory
                        || (final_component && *explicit)
                    {
                        return Err(ValidationError::DuplicatePath);
                    }
                    if final_component {
                        *explicit = true;
                    }
                }
                None => {
                    path_storage = path_storage
                        .checked_add(key.len() + original.len())
                        .ok_or(ValidationError::ArchiveLimit)?;
                    if path_storage > MAX_PATH_STORAGE_BYTES || paths.len() >= 200_000 {
                        return Err(ValidationError::ArchiveLimit);
                    }
                    paths.insert(key, (original.clone(), needs_directory, final_component));
                }
            }
        }
        if components.len() >= 2 && components[0] == "Payload" && components[1].ends_with(".app") {
            main_apps.insert(components[1].to_owned());
        }
        entries.push(Entry {
            index,
            path: components.iter().collect(),
            directory,
            size: file.size(),
            executable: mode & 0o111 != 0,
        });
    }
    if main_apps.len() != 1 {
        return Err(ValidationError::InvalidLayout);
    }
    let app = main_apps
        .into_iter()
        .next()
        .ok_or(ValidationError::InvalidLayout)?;
    let info_key = format!("Payload/{app}/Info.plist")
        .nfd()
        .case_fold()
        .nfd()
        .collect::<String>();
    if !paths
        .get(&info_key)
        .is_some_and(|(name, directory, explicit)| {
            name == &format!("Payload/{app}/Info.plist") && !directory && *explicit
        })
    {
        return Err(ValidationError::InvalidLayout);
    }
    Ok((entries, app))
}

fn safe_path_components(name: &str) -> Result<Vec<&str>, ValidationError> {
    if name.is_empty()
        || name.len() > 1024
        || name.starts_with('/')
        || name.contains('\\')
        || name.contains(':')
        || name.chars().any(char::is_control)
    {
        return Err(ValidationError::UnsafePath);
    }
    let parts: Vec<_> = name.split('/').collect();
    if parts.len() > 64
        || parts.iter().any(|p| {
            p.is_empty()
                || *p == "."
                || *p == ".."
                || p.len() > 255
                || p.ends_with('.')
                || p.ends_with(' ')
        })
    {
        return Err(ValidationError::UnsafePath);
    }
    Ok(parts)
}
fn create_private_dirs(base: &Path, relative: &Path) -> Result<(), ValidationError> {
    let mut current = base.to_owned();
    for component in relative.components() {
        current.push(component);
        match fs::create_dir(&current) {
            Ok(()) => private_permissions(&current, true, false)?,
            Err(e) if e.kind() == io::ErrorKind::AlreadyExists => {
                if !fs::symlink_metadata(&current)?.file_type().is_dir() {
                    return Err(ValidationError::UnsafePath);
                }
            }
            Err(_) => return Err(ValidationError::Io),
        }
    }
    Ok(())
}
fn private_permissions(
    path: &Path,
    directory: bool,
    executable: bool,
) -> Result<(), ValidationError> {
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(
            path,
            fs::Permissions::from_mode(if directory || executable {
                0o700
            } else {
                0o600
            }),
        )?;
    }
    #[cfg(not(unix))]
    {
        let _ = (path, directory, executable);
    }
    Ok(())
}
fn inspect_bundle(
    bundle: &Path,
    application: bool,
) -> Result<(String, String, PathBuf), ValidationError> {
    let info_path = bundle.join("Info.plist");
    if fs::metadata(&info_path)?.len() > MAX_PLIST_BYTES {
        return Err(ValidationError::InvalidInfo);
    }
    let value = plist::Value::from_file(info_path).map_err(|_| ValidationError::InvalidInfo)?;
    let info = value.as_dictionary().ok_or(ValidationError::InvalidInfo)?;
    let id = info
        .get("CFBundleIdentifier")
        .and_then(plist::Value::as_string)
        .ok_or(ValidationError::InvalidInfo)?;
    if id.is_empty()
        || id.len() > 255
        || !id.contains('.')
        || id.starts_with('.')
        || id.ends_with('.')
        || id.contains("..")
        || !id
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || b == b'.' || b == b'-')
    {
        return Err(ValidationError::InvalidInfo);
    }
    let executable = info
        .get("CFBundleExecutable")
        .and_then(plist::Value::as_string)
        .ok_or(ValidationError::InvalidInfo)?;
    if safe_path_components(executable)?.len() != 1 {
        return Err(ValidationError::InvalidInfo);
    }
    let exe = bundle.join(executable);
    if !fs::symlink_metadata(&exe)?.file_type().is_file() {
        return Err(ValidationError::UnsupportedExecutable);
    }
    inspect_macho(&exe, application)?;
    private_permissions(&exe, false, true)?;
    let display_name = info
        .get("CFBundleDisplayName")
        .or_else(|| info.get("CFBundleName"))
        .and_then(plist::Value::as_string)
        .filter(|s| !s.is_empty() && s.len() <= 512 && !s.chars().any(char::is_control))
        .unwrap_or(id)
        .to_owned();
    Ok((id.to_owned(), display_name, exe))
}
fn collect_code_bundles(dir: &Path, results: &mut Vec<PathBuf>) -> Result<(), ValidationError> {
    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();
        let extension = path.extension().and_then(|e| e.to_str()).unwrap_or("");
        let normalized = extension.to_ascii_lowercase();
        if entry.file_type()?.is_dir() {
            // Watch/embedded apps require their own recursive provisioning strategy.
            // The current engine handles the main app and .appex bundles only.
            if normalized == "app" {
                return Err(ValidationError::InvalidLayout);
            }
            if normalized == "appex" || normalized == "framework" {
                // Do not let case aliases hide code from case-sensitive library traversal.
                if extension != normalized {
                    return Err(ValidationError::InvalidLayout);
                }
                results.push(path.clone());
            }
            collect_code_bundles(&path, results)?;
        } else if normalized == "dylib" {
            if extension != normalized {
                return Err(ValidationError::InvalidLayout);
            }
            results.push(path);
        }
    }
    Ok(())
}
fn read_at<const N: usize>(file: &mut File, offset: u64) -> Result<[u8; N], ValidationError> {
    file.seek(SeekFrom::Start(offset))?;
    let mut result = [0u8; N];
    file.read_exact(&mut result)
        .map_err(|_| ValidationError::UnsupportedExecutable)?;
    Ok(result)
}
fn u32_at(bytes: &[u8], n: usize, big: bool) -> u32 {
    let b = bytes[n..n + 4].try_into().expect("fixed parser field");
    if big {
        u32::from_be_bytes(b)
    } else {
        u32::from_le_bytes(b)
    }
}
fn u64_at(bytes: &[u8], n: usize, big: bool) -> u64 {
    let b = bytes[n..n + 8].try_into().expect("fixed parser field");
    if big {
        u64::from_be_bytes(b)
    } else {
        u64::from_le_bytes(b)
    }
}
pub(crate) fn inspect_macho(path: &Path, application: bool) -> Result<(), ValidationError> {
    let mut file = File::open(path)?;
    let len = file.metadata()?.len();
    if len < 32 {
        return Err(ValidationError::UnsupportedExecutable);
    }
    let first = read_at::<8>(&mut file, 0)?;
    let (fat, fat64, big) = match first[..4] {
        [0xca, 0xfe, 0xba, 0xbe] => (true, false, true),
        [0xca, 0xfe, 0xba, 0xbf] => (true, true, true),
        [0xbe, 0xba, 0xfe, 0xca] => (true, false, false),
        [0xbf, 0xba, 0xfe, 0xca] => (true, true, false),
        _ => (false, false, false),
    };
    if !fat {
        return inspect_arm64_slice(&mut file, 0, len, application);
    }
    let count = u32_at(&first, 4, big) as u64;
    if count == 0 || count > 32 {
        return Err(ValidationError::UnsupportedExecutable);
    }
    let entry_size = if fat64 { 32u64 } else { 20u64 };
    let table_end = 8 + count * entry_size;
    if table_end > len {
        return Err(ValidationError::UnsupportedExecutable);
    }
    let mut ranges: Vec<(u64, u64)> = Vec::new();
    let mut found = false;
    for n in 0..count {
        let data = read_at::<32>(&mut file, 8 + n * entry_size)?;
        let cpu = u32_at(&data, 0, big);
        let offset = if fat64 {
            u64_at(&data, 8, big)
        } else {
            u32_at(&data, 8, big) as u64
        };
        let size = if fat64 {
            u64_at(&data, 16, big)
        } else {
            u32_at(&data, 12, big) as u64
        };
        let alignment = u32_at(&data, if fat64 { 24 } else { 16 }, big);
        if alignment > 16
            || offset % (1u64 << alignment) != 0
            || (fat64 && u32_at(&data, 28, big) != 0)
        {
            return Err(ValidationError::UnsupportedExecutable);
        }
        let end = offset
            .checked_add(size)
            .ok_or(ValidationError::UnsupportedExecutable)?;
        if offset < table_end
            || size < 32
            || end > len
            || ranges.iter().any(|(a, b)| offset < *b && end > *a)
        {
            return Err(ValidationError::UnsupportedExecutable);
        }
        ranges.push((offset, end));
        if cpu == ARM64 {
            inspect_arm64_slice(&mut file, offset, size, application)?;
            found = true;
        }
    }
    if found {
        Ok(())
    } else {
        Err(ValidationError::UnsupportedExecutable)
    }
}
fn inspect_arm64_slice(
    file: &mut File,
    offset: u64,
    size: u64,
    application: bool,
) -> Result<(), ValidationError> {
    let header = read_at::<32>(file, offset)?;
    let filetype = u32_at(&header, 12, false);
    if u32_at(&header, 0, false) != 0xfeed_facf
        || u32_at(&header, 4, false) != ARM64
        || filetype != if application { 2 } else { 6 }
    {
        return Err(ValidationError::UnsupportedExecutable);
    }
    let count = u32_at(&header, 16, false);
    let command_bytes = u32_at(&header, 20, false) as u64;
    if count == 0
        || count > 4096
        || command_bytes > MAX_LOAD_COMMAND_BYTES
        || 32 + command_bytes > size
    {
        return Err(ValidationError::UnsupportedExecutable);
    }
    let end = offset + 32 + command_bytes;
    let mut position = offset + 32;
    let mut deployment = false;
    for _ in 0..count {
        if position + 8 > end {
            return Err(ValidationError::UnsupportedExecutable);
        }
        let command = read_at::<8>(file, position)?;
        let kind = u32_at(&command, 0, false);
        let length = u32_at(&command, 4, false) as u64;
        if length < 8 || length % 8 != 0 || position + length > end {
            return Err(ValidationError::UnsupportedExecutable);
        }
        if kind == 0x32 {
            // LC_BUILD_VERSION: iPhoneOS, never arm64 simulator/macOS.
            if length < 24 || deployment {
                return Err(ValidationError::UnsupportedExecutable);
            }
            let build = read_at::<24>(file, position)?;
            if u32_at(&build, 8, false) != 2 || 24 + u32_at(&build, 20, false) as u64 * 8 > length {
                return Err(ValidationError::UnsupportedExecutable);
            }
            deployment = true;
        } else if kind == 0x25 {
            // Older LC_VERSION_MIN_IPHONEOS.
            if length < 16 || deployment {
                return Err(ValidationError::UnsupportedExecutable);
            }
            deployment = true;
        } else if kind == 0x24 || kind == 0x2f || kind == 0x30 {
            return Err(ValidationError::UnsupportedExecutable);
        } else if kind == 0x19 {
            // LC_SEGMENT_64 file-backed data must stay inside the slice.
            if length < 72 {
                return Err(ValidationError::UnsupportedExecutable);
            }
            let segment = read_at::<72>(file, position)?;
            let start = u64_at(&segment, 40, false);
            let bytes = u64_at(&segment, 48, false);
            if start.checked_add(bytes).is_none_or(|end| end > size)
                || 72 + u32_at(&segment, 64, false) as u64 * 80 > length
            {
                return Err(ValidationError::UnsupportedExecutable);
            }
        } else if kind == 0x21 || kind == 0x2c {
            if length < if kind == 0x2c { 24 } else { 20 } {
                return Err(ValidationError::UnsupportedExecutable);
            }
            let crypt = read_at::<20>(file, position)?;
            let crypt_start = u32_at(&crypt, 8, false) as u64;
            let crypt_size = u32_at(&crypt, 12, false) as u64;
            if crypt_start
                .checked_add(crypt_size)
                .is_none_or(|end| end > size)
            {
                return Err(ValidationError::UnsupportedExecutable);
            }
            if u32_at(&crypt, 16, false) != 0 {
                return Err(ValidationError::EncryptedExecutable);
            }
        }
        position += length;
    }
    if position != end || !deployment {
        return Err(ValidationError::UnsupportedExecutable);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{
        io::Cursor,
        sync::atomic::{AtomicU64, Ordering},
    };
    use zip::{write::SimpleFileOptions, ZipWriter};
    static NEXT: AtomicU64 = AtomicU64::new(1);
    struct TestDir(PathBuf);
    impl TestDir {
        fn new() -> Self {
            let base = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("target/archive-tests");
            fs::create_dir_all(&base).unwrap();
            let p = base.join(format!(
                "{}-{}",
                std::process::id(),
                NEXT.fetch_add(1, Ordering::Relaxed)
            ));
            fs::create_dir(&p).unwrap();
            Self(p)
        }
    }
    impl Drop for TestDir {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
        }
    }
    fn executable(encrypted: bool) -> Vec<u8> {
        let mut words = vec![
            0xfeed_facf,
            ARM64,
            0,
            2,
            2,
            48,
            0,
            0,
            0x32,
            24,
            2,
            0x00100000,
            0x00100500,
            0,
            0x2c,
            24,
            0,
            0,
            encrypted as u32,
            0,
        ];
        words.drain(..).flat_map(u32::to_le_bytes).collect()
    }
    fn info(id: &str, name: &str) -> Vec<u8> {
        let mut p = plist::Dictionary::new();
        p.insert("CFBundleIdentifier".into(), id.into());
        p.insert("CFBundleExecutable".into(), name.into());
        p.insert("CFBundleDisplayName".into(), "Test App".into());
        let mut out = Vec::new();
        plist::Value::Dictionary(p).to_writer_xml(&mut out).unwrap();
        out
    }
    fn ipa(extra: Option<(&str, Vec<u8>)>, encrypted: bool) -> Vec<u8> {
        ipa_entries(extra.into_iter().collect(), encrypted, false)
    }
    fn ipa_entries(extra: Vec<(&str, Vec<u8>)>, encrypted: bool, deflated: bool) -> Vec<u8> {
        let mut z = ZipWriter::new(Cursor::new(Vec::new()));
        let options = SimpleFileOptions::default().compression_method(if deflated {
            zip::CompressionMethod::Deflated
        } else {
            zip::CompressionMethod::Stored
        });
        z.start_file("Payload/Test.app/Info.plist", options)
            .unwrap();
        z.write_all(&info("org.example.test", "Test")).unwrap();
        z.start_file("Payload/Test.app/Test", options).unwrap();
        z.write_all(&executable(encrypted)).unwrap();
        for (name, data) in extra {
            z.start_file(name, options).unwrap();
            z.write_all(&data).unwrap();
        }
        z.finish().unwrap().into_inner()
    }
    #[test]
    fn rejects_adversarial_archives_without_leftovers() {
        let t = TestDir::new();
        let input = t.0.join("test.ipa");
        let out = t.0.join("stage");
        for name in [
            "../outside",
            "/absolute",
            "Payload/Test.app/../escape",
            "Payload/Test.app\\bad",
            "Payload/test.app/Other",
            "Payload/Test.app/INFO.plist",
        ] {
            fs::write(&input, ipa(Some((name, vec![1])), false)).unwrap();
            assert!(
                validate_and_extract(&input, &out).is_err(),
                "unsafe fixture accepted"
            );
            assert!(!out.exists());
        }
        // Unicode-equivalent names cannot become one file on Apple's filesystem.
        fs::write(
            &input,
            ipa_entries(
                vec![
                    ("Payload/Test.app/é", vec![1]),
                    ("Payload/Test.app/e\u{301}", vec![2]),
                ],
                false,
                false,
            ),
        )
        .unwrap();
        assert_eq!(
            validate_and_extract(&input, &out).unwrap_err(),
            ValidationError::DuplicatePath
        );
        assert!(!out.exists());
        // zip 8 coalesces exact duplicate central names. The declared-count comparison must catch them.
        let mut duplicate = ipa(Some(("Payload/Test.app/Info.plisx", vec![1])), false);
        let old = b"Payload/Test.app/Info.plisx";
        let new = b"Payload/Test.app/Info.plist";
        let offsets: Vec<_> = duplicate
            .windows(old.len())
            .enumerate()
            .filter_map(|(n, b)| (b == old).then_some(n))
            .collect();
        assert_eq!(offsets.len(), 2);
        for n in offsets {
            duplicate[n..n + old.len()].copy_from_slice(new);
        }
        fs::write(&input, duplicate).unwrap();
        assert_eq!(
            validate_and_extract(&input, &out).unwrap_err(),
            ValidationError::DuplicatePath
        );
        assert!(!out.exists());
        // A false ZIP64 count cannot cause unbounded allocation by the ZIP library.
        let mut metadata = ipa(None, false);
        let eocd = metadata.len() - 22;
        metadata[eocd + 10..eocd + 12].copy_from_slice(&u16::MAX.to_le_bytes());
        fs::write(&input, metadata).unwrap();
        assert!(validate_and_extract(&input, &out).is_err());
        assert!(!out.exists());
        fs::write(
            &input,
            ipa_entries(
                vec![("Payload/Test.app/zeros", vec![0; 2 * 1024 * 1024])],
                false,
                true,
            ),
        )
        .unwrap();
        assert_eq!(
            validate_and_extract(&input, &out).unwrap_err(),
            ValidationError::ArchiveLimit
        );
        assert!(!out.exists());
        fs::write(&input, ipa(None, true)).unwrap();
        assert_eq!(
            validate_and_extract(&input, &out).unwrap_err(),
            ValidationError::EncryptedExecutable
        );
        assert!(!out.exists());
        // An encrypted extension is rejected even when the main executable is clear.
        fs::write(
            &input,
            ipa_entries(
                vec![
                    (
                        "Payload/Test.app/PlugIns/Extension.appex/Info.plist",
                        info("org.example.test.extension", "Extension"),
                    ),
                    (
                        "Payload/Test.app/PlugIns/Extension.appex/Extension",
                        executable(true),
                    ),
                ],
                false,
                false,
            ),
        )
        .unwrap();
        assert_eq!(
            validate_and_extract(&input, &out).unwrap_err(),
            ValidationError::EncryptedExecutable
        );
        assert!(!out.exists());
        // arm64 simulator binaries share the CPU type but must not be accepted as phone apps.
        let mut simulator = executable(false);
        simulator[40..44].copy_from_slice(&7u32.to_le_bytes());
        let mut archive = ipa(None, false);
        // Build a clean fixture with the simulator executable instead of altering ZIP CRC.
        let mut z = ZipWriter::new(Cursor::new(Vec::new()));
        let options = SimpleFileOptions::default();
        z.start_file("Payload/Test.app/Info.plist", options)
            .unwrap();
        z.write_all(&info("org.example.test", "Test")).unwrap();
        z.start_file("Payload/Test.app/Test", options).unwrap();
        z.write_all(&simulator).unwrap();
        archive.clear();
        archive.extend(z.finish().unwrap().into_inner());
        fs::write(&input, archive).unwrap();
        assert_eq!(
            validate_and_extract(&input, &out).unwrap_err(),
            ValidationError::UnsupportedExecutable
        );
        assert!(!out.exists());
        // Unix symlink type is not a writable ordinary file, even with a safe name.
        let mut bytes = ipa(Some(("Payload/Test.app/link", b"Test".to_vec())), false);
        let mut position = 0;
        while position + 46 <= bytes.len() {
            if bytes[position..position + 4] == [0x50, 0x4b, 0x01, 0x02] {
                let n = u16::from_le_bytes(bytes[position + 28..position + 30].try_into().unwrap())
                    as usize;
                if &bytes[position + 46..position + 46 + n] == b"Payload/Test.app/link" {
                    bytes[position + 5] = 3; // Unix host
                    bytes[position + 38..position + 42]
                        .copy_from_slice(&(0o120777u32 << 16).to_le_bytes());
                    break;
                }
            }
            position += 1;
        }
        fs::write(&input, bytes).unwrap();
        assert_eq!(
            validate_and_extract(&input, &out).unwrap_err(),
            ValidationError::SpecialFile
        );
        assert!(!out.exists());
        assert!(!t.0.join("outside").exists());
    }
    #[test]
    fn accepts_valid_arm64_bundle_preserves_identity_and_cleans_staging() {
        let t = TestDir::new();
        let input = t.0.join("test.ipa");
        let out = t.0.join("stage");
        fs::write(&input, ipa(None, false)).unwrap();
        let validated = validate_and_extract(&input, &out).unwrap();
        assert_eq!(validated.bundle_id, "org.example.test");
        assert_eq!(validated.display_name, "Test App");
        assert!(validated.app_dir.join("Test").is_file());
        assert!(validated.extension_ids.is_empty());
        // An existing destination is never removed or overwritten, including on errors.
        assert_eq!(
            validate_and_extract(&input, &out).unwrap_err(),
            ValidationError::DestinationExists
        );
        assert!(validated.app_dir.join("Test").is_file());
        drop(validated);
        assert!(!out.exists());
    }
}
