use crate::error::{CodeSignError, Result};
use crate::control::{check_stop, StopPredicate};
use crate::macho::{DEFAULT_CMS_BLOB_RESERVATION, MachOSigningConfig, sign_macho_file_controlled};
use crate::signature::CmsSigner;
use plist::{Dictionary, Value};
use rayon::prelude::*;
use sha1::Digest as _;
use std::collections::BTreeMap;
use std::fs;
use std::io::{self, Read};
use std::path::{Path, PathBuf};

const RESOURCE_BUFFER_BYTES: usize = 64 * 1024;

const FAIRPLAY_DIR: &str = "SC_Info";
const CODE_SIGNATURE_DIR: &str = "_CodeSignature";
const CODE_RESOURCES_FILE: &str = "CodeResources";

pub struct BundleSigningSettings<'a> {
    pub team_id: String,
    pub main_entitlements: Dictionary,
    pub entitlements_by_bundle_id: BTreeMap<String, Dictionary>,
    pub cms_signer: Option<&'a dyn CmsSigner>,
    pub embedded_mobileprovision: Option<&'a [u8]>,
    pub embedded_mobileprovisions_by_bundle_id: BTreeMap<String, &'a [u8]>,
    pub cms_blob_reservation: usize,
}

impl<'a> BundleSigningSettings<'a> {
    pub fn new(
        team_id: impl Into<String>,
        main_entitlements: Dictionary,
        cms_signer: Option<&'a dyn CmsSigner>,
    ) -> Self {
        Self {
            team_id: team_id.into(),
            main_entitlements,
            entitlements_by_bundle_id: BTreeMap::new(),
            cms_signer,
            embedded_mobileprovision: None,
            embedded_mobileprovisions_by_bundle_id: BTreeMap::new(),
            cms_blob_reservation: DEFAULT_CMS_BLOB_RESERVATION,
        }
    }
}

#[derive(Debug)]
pub struct Bundle {
    path: PathBuf,
    app_info: Dictionary,
}

impl Bundle {
    pub fn open(path: impl Into<PathBuf>) -> Result<Self> {
        let path = path.into();
        let info_path = path.join("Info.plist");
        if !info_path.exists() {
            return Err(CodeSignError::MissingInfoPlist(info_path));
        }

        let file =
            fs::File::open(&info_path).map_err(|source| CodeSignError::io(&info_path, source))?;
        let app_info = match Value::from_reader(file)? {
            Value::Dictionary(dict) => dict,
            _ => {
                return Err(CodeSignError::macho(
                    &info_path,
                    "Info.plist is not a dictionary",
                ));
            }
        };

        Ok(Self { path, app_info })
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn bundle_identifier(&self) -> Result<&str> {
        self.info_string("CFBundleIdentifier")
    }

    pub fn executable_name(&self) -> Result<&str> {
        self.info_string("CFBundleExecutable")
    }

    pub fn sign(&mut self, settings: &BundleSigningSettings<'_>) -> Result<CodeResourcesMaps> {
        self.sign_controlled(settings, &|| false)
    }

    /// The predicate is shared by concurrent bundle/resource workers. Cancellation
    /// is cooperative at file boundaries, bounded resource chunks and executable
    /// code pages/crypto phases. Individual OS/crypto operations are synchronous.
    pub fn sign_controlled(
        &mut self,
        settings: &BundleSigningSettings<'_>,
        should_stop: &StopPredicate<'_>,
    ) -> Result<CodeResourcesMaps> {
        self.sign_inner(settings, true, should_stop)
    }

    fn sign_inner(
        &mut self,
        settings: &BundleSigningSettings<'_>,
        is_root: bool,
        should_stop: &StopPredicate<'_>,
    ) -> Result<CodeResourcesMaps> {
        check_stop(should_stop)?;
        remove_fairplay_dir(&self.path)?;

        let bundle_id = self.bundle_identifier()?.to_string();
        let executable = self.executable_name()?.to_string();
        let sub_bundles = self.sub_bundles()?;
        let sub_bundles_for_hashing = sub_bundles.clone();

        let code_signature_dir = self.path.join(CODE_SIGNATURE_DIR);
        check_stop(should_stop)?;
        fs::create_dir_all(&code_signature_dir)
            .map_err(|source| CodeSignError::io(&code_signature_dir, source))?;

        let code_resources_path = code_signature_dir.join(CODE_RESOURCES_FILE);
        check_stop(should_stop)?;
        if code_resources_path.exists() {
            fs::remove_file(&code_resources_path)
                .map_err(|source| CodeSignError::io(&code_resources_path, source))?;
        }

        let info_data = encode_binary_plist(&self.app_info)?;
        let info_path = self.path.join("Info.plist");
        check_stop(should_stop)?;
        fs::write(&info_path, &info_data)
            .map_err(|source| CodeSignError::io(&info_path, source))?;
        let mobileprovision = settings
            .embedded_mobileprovisions_by_bundle_id
            .get(&bundle_id)
            .copied()
            .or_else(|| {
                if is_root {
                    settings.embedded_mobileprovision
                } else {
                    None
                }
            });
        if let Some(mobileprovision) = mobileprovision {
            check_stop(should_stop)?;
            let profile_path = self.path.join("embedded.mobileprovision");
            fs::write(&profile_path, mobileprovision)
                .map_err(|source| CodeSignError::io(&profile_path, source))?;
        }

        let (sub_results, bundle_files) = rayon::join(
            || sign_sub_bundles(&self.path, sub_bundles, settings, should_stop),
            || collect_own_bundle_files(&self.path, &executable, &sub_bundles_for_hashing, should_stop),
        );
        let sub_results = sub_results?;
        let bundle_files = bundle_files?;
        sign_libraries(&bundle_files.libraries, settings, should_stop)?;
        let resource_hashes = hash_resource_files(&self.path, &bundle_files.resource_files, should_stop)?;

        let mut maps = CodeResourcesMaps::default();

        for sub in &sub_results {
            check_stop(should_stop)?;
            merge_sub_bundle_resources(&mut maps, &self.path, sub, should_stop)?;
        }

        for hash in resource_hashes {
            check_stop(should_stop)?;
            maps.insert_hash(hash);
        }

        let code_resources = encode_code_resources(&maps)?;
        check_stop(should_stop)?;
        fs::write(&code_resources_path, &code_resources)
            .map_err(|source| CodeSignError::io(&code_resources_path, source))?;

        let empty_entitlements = Dictionary::new();
        let bundle_entitlements = settings
            .entitlements_by_bundle_id
            .get(&bundle_id)
            .or_else(|| is_root.then_some(&settings.main_entitlements))
            .unwrap_or(&empty_entitlements);

        let mut config = MachOSigningConfig::new(
            &bundle_id,
            &settings.team_id,
            bundle_entitlements,
            settings.cms_signer,
        );
        config.cms_blob_reservation = settings.cms_blob_reservation;
        config.info_plist = Some(&info_data);
        config.code_resources = Some(&code_resources);
        check_stop(should_stop)?;
        sign_macho_file_controlled(&self.path.join(&executable), &config, should_stop)?;
        check_stop(should_stop)?;

        Ok(maps)
    }

    fn info_string(&self, key: &'static str) -> Result<&str> {
        self.app_info
            .get(key)
            .and_then(Value::as_string)
            .ok_or(CodeSignError::MissingInfoString(key))
    }

    fn sub_bundles(&self) -> Result<Vec<PathBuf>> {
        let mut bundles = Vec::new();
        for folder in ["Frameworks", "PlugIns"] {
            let dir = self.path.join(folder);
            if !dir.exists() {
                continue;
            }

            for entry in fs::read_dir(&dir).map_err(|source| CodeSignError::io(&dir, source))? {
                let entry = entry.map_err(|source| CodeSignError::io(&dir, source))?;
                let path = entry.path();
                if entry
                    .file_type()
                    .map_err(|source| CodeSignError::io(&path, source))?
                    .is_dir()
                    && path.join("Info.plist").exists()
                {
                    bundles.push(path);
                }
            }
        }
        bundles.sort();
        Ok(bundles)
    }
}

#[derive(Debug)]
struct SubBundleResult {
    path: PathBuf,
    relative_root: String,
    executable: String,
    resources: CodeResourcesMaps,
}

#[derive(Clone, Debug)]
struct FileHash {
    relative_path: String,
    sha1: [u8; 20],
    sha256: [u8; 32],
    optional: bool,
}

#[derive(Debug)]
struct BundleFiles {
    resource_files: Vec<PathBuf>,
    libraries: Vec<PathBuf>,
}

fn merge_sub_bundle_resources(
    maps: &mut CodeResourcesMaps,
    parent_path: &Path,
    sub: &SubBundleResult,
    should_stop: &StopPredicate<'_>,
) -> Result<()> {
    maps.merge_rerooted(&sub.relative_root, &sub.resources);
    maps.insert_hash(hash_bundle_file(
        parent_path,
        &sub.path.join(&sub.executable),
        should_stop,
    )?);
    maps.insert_hash(hash_bundle_file(
        parent_path,
        &sub.path.join(CODE_SIGNATURE_DIR).join(CODE_RESOURCES_FILE),
        should_stop,
    )?);
    Ok(())
}

#[derive(Clone, Debug, Default)]
pub struct CodeResourcesMaps {
    pub files: Dictionary,
    pub files2: Dictionary,
    hashes: Vec<FileHash>,
}

impl CodeResourcesMaps {
    fn insert_hash(&mut self, hash: FileHash) {
        self.hashes.push(hash.clone());
        let sha1 = hash.sha1.to_vec();
        if !omit_from_files(&hash.relative_path) {
            if hash.optional {
                let mut file = Dictionary::new();
                file.insert("hash".to_string(), Value::Data(sha1.clone()));
                file.insert("optional".to_string(), Value::Boolean(true));
                self.files
                    .insert(hash.relative_path.clone(), Value::Dictionary(file));
            } else {
                self.files
                    .insert(hash.relative_path.clone(), Value::Data(sha1.clone()));
            }
        }

        if !omit_from_files2(&hash.relative_path) {
            let mut file2 = Dictionary::new();
            file2.insert("hash".to_string(), Value::Data(sha1));
            file2.insert("hash2".to_string(), Value::Data(hash.sha256.to_vec()));
            if hash.optional {
                file2.insert("optional".to_string(), Value::Boolean(true));
            }
            self.files2
                .insert(hash.relative_path, Value::Dictionary(file2));
        }
    }

    fn merge_rerooted(&mut self, root: &str, other: &Self) {
        for hash in &other.hashes {
            let mut hash = hash.clone();
            hash.relative_path = join_relative(root, &hash.relative_path);
            self.insert_hash(hash);
        }
    }
}

fn omit_from_files(relative_path: &str) -> bool {
    relative_path.ends_with(".lproj/locversion.plist")
}

fn omit_from_files2(relative_path: &str) -> bool {
    omit_from_files(relative_path)
        || relative_path == "Info.plist"
        || relative_path == "PkgInfo"
        || relative_path == ".DS_Store"
        || relative_path.ends_with("/.DS_Store")
}

pub fn sign_bundle(path: impl Into<PathBuf>, settings: &BundleSigningSettings<'_>) -> Result<()> {
    sign_bundle_controlled(path, settings, &|| false)
}

/// Sign with a shared stop/deadline predicate. No worker outlives this call:
/// Rayon joins its scoped jobs before returning, including on cancellation.
pub fn sign_bundle_controlled(
    path: impl Into<PathBuf>,
    settings: &BundleSigningSettings<'_>,
    should_stop: &StopPredicate<'_>,
) -> Result<()> {
    check_stop(should_stop)?;
    let mut bundle = Bundle::open(path)?;
    bundle.sign_controlled(settings, should_stop)?;
    Ok(())
}

fn sign_sub_bundles(
    root_path: &Path,
    sub_bundles: Vec<PathBuf>,
    settings: &BundleSigningSettings<'_>,
    should_stop: &StopPredicate<'_>,
) -> Result<Vec<SubBundleResult>> {
    sub_bundles
        .into_par_iter()
        .map(|path| {
            check_stop(should_stop)?;
            let mut bundle = Bundle::open(&path)?;
            let result = bundle.sign_inner(settings, false, should_stop)?;
            let relative_root = relative_path_string(root_path, &path)?;
            let executable = bundle.executable_name()?.to_string();
            Ok(SubBundleResult {
                path,
                relative_root,
                executable,
                resources: result,
            })
        })
        .collect()
}

fn collect_own_bundle_files(
    bundle_path: &Path,
    executable: &str,
    sub_bundles: &[PathBuf],
    should_stop: &StopPredicate<'_>,
) -> Result<BundleFiles> {
    let mut resource_files = Vec::new();
    let mut libraries = Vec::new();

    walk_files_pruned(
        bundle_path,
        should_stop,
        &mut |dir| !sub_bundles.iter().any(|sub_bundle| sub_bundle == dir),
        &mut |path| {
            let relative = relative_path_string(bundle_path, path)?;
            if path.extension().and_then(|value| value.to_str()) == Some("dylib") {
                libraries.push(path.to_path_buf());
            }
            if should_hash_resource(&relative, executable) {
                resource_files.push(path.to_path_buf());
            }
            Ok(())
        },
    )?;

    resource_files.sort();
    libraries.sort();

    Ok(BundleFiles {
        resource_files,
        libraries,
    })
}

fn sign_libraries(libraries: &[PathBuf], settings: &BundleSigningSettings<'_>, should_stop: &StopPredicate<'_>) -> Result<()> {
    libraries
        .par_iter()
        .map(|path| {
            check_stop(should_stop)?;
            let identifier = path
                .file_name()
                .and_then(|value| value.to_str())
                .ok_or_else(|| CodeSignError::InvalidBundlePath(path.clone()))?;
            let entitlements = Dictionary::new();
            let mut config = MachOSigningConfig::new(
                identifier,
                &settings.team_id,
                &entitlements,
                settings.cms_signer,
            );
            config.cms_blob_reservation = settings.cms_blob_reservation;
            sign_macho_file_controlled(path, &config, should_stop)?;
            check_stop(should_stop)
        })
        .collect::<Result<Vec<_>>>()?;
    Ok(())
}

fn hash_resource_files(bundle_path: &Path, resource_files: &[PathBuf], should_stop: &StopPredicate<'_>) -> Result<Vec<FileHash>> {
    resource_files
        .par_iter()
        .map(|path| hash_bundle_file(bundle_path, path, should_stop))
        .collect()
}

fn remove_fairplay_dir(bundle_path: &Path) -> Result<()> {
    let fairplay_path = bundle_path.join(FAIRPLAY_DIR);
    if fairplay_path.exists() {
        fs::remove_dir_all(&fairplay_path)
            .map_err(|source| CodeSignError::io(&fairplay_path, source))?;
    }
    Ok(())
}

fn walk_files_pruned(
    root: &Path,
    should_stop: &StopPredicate<'_>,
    should_descend: &mut impl FnMut(&Path) -> bool,
    visitor: &mut impl FnMut(&Path) -> Result<()>,
) -> Result<()> {
    let mut stack = vec![root.to_path_buf()];
    while let Some(dir) = stack.pop() {
        check_stop(should_stop)?;
        for entry in fs::read_dir(&dir).map_err(|source| CodeSignError::io(&dir, source))? {
            check_stop(should_stop)?;
            let entry = entry.map_err(|source| CodeSignError::io(&dir, source))?;
            let path = entry.path();
            let file_type = entry
                .file_type()
                .map_err(|source| CodeSignError::io(&path, source))?;
            if file_type.is_dir() && should_descend(&path) {
                stack.push(path);
            } else if file_type.is_file() {
                visitor(&path)?;
            }
        }
    }
    Ok(())
}

fn should_hash_resource(relative: &str, executable: &str) -> bool {
    if relative == executable || relative.starts_with(FAIRPLAY_DIR) {
        return false;
    }

    for nested_root in ["Frameworks/", "PlugIns/"] {
        if let Some(rest) = relative.strip_prefix(nested_root)
            && rest.contains('/')
        {
            return false;
        }
    }

    true
}

fn hash_bundle_file(bundle_path: &Path, path: &Path, should_stop: &StopPredicate<'_>) -> Result<FileHash> {
    check_stop(should_stop)?;
    let relative_path = relative_path_string(bundle_path, path)?;
    let mut file = fs::File::open(path).map_err(|source| CodeSignError::io(path, source))?;
    let (sha1, sha256) = hash_resource_reader(&mut file, path, should_stop)?;
    Ok(FileHash {
        optional: relative_path.contains(".lproj"),
        relative_path,
        sha1,
        sha256,
    })
}

fn hash_resource_reader(
    reader: &mut impl Read,
    path: &Path,
    should_stop: &StopPredicate<'_>,
) -> Result<([u8; 20], [u8; 32])> {
    let mut sha1 = sha1::Sha1::new();
    let mut sha256 = sha2::Sha256::new();
    let mut buffer = [0u8; RESOURCE_BUFFER_BYTES];
    loop {
        check_stop(should_stop)?;
        let count = match reader.read(&mut buffer) {
            Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
            result => result.map_err(|source| CodeSignError::io(path, source))?,
        };
        check_stop(should_stop)?;
        if count == 0 { break; }
        sha1.update(&buffer[..count]);
        sha256.update(&buffer[..count]);
    }
    check_stop(should_stop)?;
    Ok((sha1.finalize().into(), sha256.finalize().into()))
}

fn encode_code_resources(maps: &CodeResourcesMaps) -> Result<Vec<u8>> {
    let mut code_resources = Dictionary::new();
    code_resources.insert("files".to_string(), Value::Dictionary(maps.files.clone()));
    code_resources.insert("files2".to_string(), Value::Dictionary(maps.files2.clone()));
    code_resources.insert("rules".to_string(), rules());
    code_resources.insert("rules2".to_string(), rules2());

    let mut data = Vec::new();
    plist::to_writer_xml(&mut data, &Value::Dictionary(code_resources))?;
    Ok(data)
}

fn rules() -> Value {
    let mut rules = Dictionary::new();
    rules.insert("^.*".to_string(), Value::Boolean(true));
    rules.insert(
        "^.*\\.lproj/".to_string(),
        weighted_rule([("optional", Value::Boolean(true))], 1000.0),
    );
    rules.insert(
        "^.*\\.lproj/locversion.plist$".to_string(),
        weighted_rule([("omit", Value::Boolean(true))], 1100.0),
    );
    rules.insert("^Base\\.lproj/".to_string(), weight_only_rule(1010.0));
    rules.insert("^version.plist$".to_string(), Value::Boolean(true));
    Value::Dictionary(rules)
}

fn rules2() -> Value {
    let mut rules = Dictionary::new();
    rules.insert(".*\\.dSYM($|/)".to_string(), weight_only_rule(11.0));
    rules.insert(
        "^(.*/)?\\.DS_Store$".to_string(),
        weighted_rule([("omit", Value::Boolean(true))], 2000.0),
    );
    rules.insert("^.*".to_string(), Value::Boolean(true));
    rules.insert(
        "^.*\\.lproj/".to_string(),
        weighted_rule([("optional", Value::Boolean(true))], 1000.0),
    );
    rules.insert(
        "^.*\\.lproj/locversion.plist$".to_string(),
        weighted_rule([("omit", Value::Boolean(true))], 1100.0),
    );
    rules.insert("^Base\\.lproj/".to_string(), weight_only_rule(1010.0));
    rules.insert(
        "^Info\\.plist$".to_string(),
        weighted_rule([("omit", Value::Boolean(true))], 20.0),
    );
    rules.insert(
        "^PkgInfo$".to_string(),
        weighted_rule([("omit", Value::Boolean(true))], 20.0),
    );
    rules.insert(
        "^embedded\\.provisionprofile$".to_string(),
        weight_only_rule(20.0),
    );
    rules.insert("^version\\.plist$".to_string(), weight_only_rule(20.0));
    Value::Dictionary(rules)
}

fn weighted_rule<const N: usize>(entries: [(&str, Value); N], weight: f64) -> Value {
    let mut dict = Dictionary::new();
    for (key, value) in entries {
        dict.insert(key.to_string(), value);
    }
    dict.insert("weight".to_string(), Value::Real(weight));
    Value::Dictionary(dict)
}

fn weight_only_rule(weight: f64) -> Value {
    weighted_rule::<0>([], weight)
}

fn encode_binary_plist(dict: &Dictionary) -> Result<Vec<u8>> {
    let mut data = Vec::new();
    plist::to_writer_binary(&mut data, &Value::Dictionary(dict.clone()))?;
    Ok(data)
}

fn relative_path_string(root: &Path, path: &Path) -> Result<String> {
    let relative = path
        .strip_prefix(root)
        .map_err(|_| CodeSignError::InvalidBundlePath(path.to_path_buf()))?;
    path_to_forward_slashes(relative)
}

fn path_to_forward_slashes(path: &Path) -> Result<String> {
    let mut parts = Vec::new();
    for component in path.components() {
        parts.push(
            component
                .as_os_str()
                .to_str()
                .ok_or_else(|| CodeSignError::InvalidBundlePath(path.to_path_buf()))?,
        );
    }
    Ok(parts.join("/"))
}

fn join_relative(root: &str, child: &str) -> String {
    if root.is_empty() {
        child.to_string()
    } else if child.is_empty() {
        root.to_string()
    } else {
        format!("{root}/{child}")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::{Arc, atomic::{AtomicBool, Ordering}};

    struct PatternReader {
        position: u64,
        length: u64,
        reads: usize,
        max_request: usize,
        fail_after: Option<u64>,
        interrupt_once: bool,
        stop_after: Option<(usize, Arc<AtomicBool>)>,
    }
    impl PatternReader {
        fn new(length: u64) -> Self {
            Self {position:0,length,reads:0,max_request:0,fail_after:None,interrupt_once:true,stop_after:None}
        }
    }
    impl Read for PatternReader {
        fn read(&mut self, output: &mut [u8]) -> io::Result<usize> {
            self.reads += 1;
            self.max_request = self.max_request.max(output.len());
            if self.interrupt_once {
                self.interrupt_once = false;
                return Err(io::ErrorKind::Interrupted.into());
            }
            if self.fail_after.is_some_and(|limit| self.position >= limit) {
                return Err(io::Error::other("Synthetic resource read failed"));
            }
            // Deliberate partial reads exercise the production loop rather than
            // assuming disk reads always fill the supplied chunk.
            let count = output.len().min(8193).min((self.length-self.position) as usize);
            for (offset, byte) in output[..count].iter_mut().enumerate() {
                *byte = ((self.position+offset as u64)%251) as u8;
            }
            self.position += count as u64;
            if let Some((after, flag)) = &self.stop_after {
                if self.reads >= *after {flag.store(true,Ordering::Release);}
            }
            Ok(count)
        }
    }

    #[test]
    fn resource_signing_streams_exact_hashes_and_propagates_io_errors() {
        let length=2*1024*1024+17;
        let mut reader=PatternReader::new(length);
        let actual=hash_resource_reader(&mut reader,Path::new("synthetic-resource"),&||false).unwrap();
        let expected:Vec<u8>=(0..length).map(|offset|(offset%251)as u8).collect();
        assert_eq!(actual.0,<[u8;20]>::from(sha1::Sha1::digest(&expected)));
        assert_eq!(actual.1,<[u8;32]>::from(sha2::Sha256::digest(&expected)));
        assert!(reader.reads>length as usize/RESOURCE_BUFFER_BYTES);
        assert_eq!(reader.max_request,RESOURCE_BUFFER_BYTES);
        let empty=hash_resource_reader(&mut io::empty(),Path::new("empty"),&||false).unwrap();
        assert_eq!(empty.0,<[u8;20]>::from(sha1::Sha1::digest([])));
        assert_eq!(empty.1,<[u8;32]>::from(sha2::Sha256::digest([])));
        reader=PatternReader::new(length);reader.fail_after=Some(RESOURCE_BUFFER_BYTES as u64);
        assert!(matches!(hash_resource_reader(&mut reader,Path::new("failing-resource"),&||false),Err(CodeSignError::Io{..})));
        assert!(reader.position<length);
        // The controlled executable path must still produce a real ad-hoc
        // embedded signature when no stop is requested.
        let executable=std::env::temp_dir().join(format!("codesign-controlled-positive-{}-{}",std::process::id(),std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos()));
        let original=crate::macho::tests::minimal_macho_with_empty_signature();
        fs::write(&executable,&original).unwrap();
        let entitlements=Dictionary::new();
        let config=MachOSigningConfig::new("synthetic.executable","SYNTHETIC",&entitlements,None);
        sign_macho_file_controlled(&executable,&config,&||false).unwrap();
        assert_ne!(fs::read(&executable).unwrap(),original);
        fs::remove_file(executable).unwrap();
    }

    #[test]
    fn resource_signing_cancellation_is_bounded_and_prevents_unstarted_writes() {
        let stop=Arc::new(AtomicBool::new(false));
        // A logical 4 GiB resource does not need an allocation or full read to
        // observe cancellation in the actual production hashing helper.
        let mut reader=PatternReader::new(4*1024*1024*1024);
        reader.interrupt_once=false;
        reader.stop_after=Some((2,stop.clone()));
        assert!(matches!(hash_resource_reader(&mut reader,Path::new("large-resource"),&||stop.load(Ordering::Acquire)),Err(CodeSignError::Cancelled)));
        assert_eq!(reader.reads,2);
        assert!(reader.position<=2*RESOURCE_BUFFER_BYTES as u64);
        let reads=reader.reads;
        assert!(matches!(hash_resource_reader(&mut reader,Path::new("large-resource"),&||true),Err(CodeSignError::Cancelled)));
        assert_eq!(reader.reads,reads,"An already stopped pass cannot read again");
        let test_root=std::env::temp_dir().join(format!("apple-codesign-stop-{}-{}",std::process::id(),std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos()));
        fs::create_dir_all(&test_root).unwrap();
        let original=b"original metadata must remain intact";
        fs::write(test_root.join("Info.plist"),original).unwrap();
        let settings=BundleSigningSettings::new("SYNTHETIC",Dictionary::new(),None);
        assert!(matches!(sign_bundle_controlled(&test_root,&settings,&||true),Err(CodeSignError::Cancelled)));
        assert_eq!(fs::read(test_root.join("Info.plist")).unwrap(),original);
        assert!(!test_root.join(CODE_SIGNATURE_DIR).exists());
        assert!(matches!(sign_bundle_controlled(test_root.join("missing"),&settings,&||true),Err(CodeSignError::Cancelled)));
        // Cancel after real page hashing/code-directory construction, from the
        // CMS callback. Its synthetic bytes are never trusted/installed; the
        // important property is that the original file is not replaced.
        struct StopDuringCms(Arc<AtomicBool>);
        impl CmsSigner for StopDuringCms {
            fn sign(&self,_:crate::signature::CmsSigningRequest<'_>)->Result<Vec<u8>> {
                self.0.store(true,Ordering::Release);
                Ok(vec![0x30,0])
            }
        }
        let executable=test_root.join("SyntheticExecutable");
        let executable_bytes=crate::macho::tests::minimal_macho_with_empty_signature();
        fs::write(&executable,&executable_bytes).unwrap();
        let stop=Arc::new(AtomicBool::new(false));
        let cms=StopDuringCms(stop.clone());
        let entitlements=Dictionary::new();
        let config=MachOSigningConfig::new("synthetic.executable","SYNTHETIC",&entitlements,Some(&cms));
        assert!(matches!(sign_macho_file_controlled(&executable,&config,&||stop.load(Ordering::Acquire)),Err(CodeSignError::Cancelled)));
        assert!(stop.load(Ordering::Acquire),"The real signing path must reach the CMS callback");
        assert_eq!(fs::read(&executable).unwrap(),executable_bytes,"Cancellation before replacement preserves the original executable");
        fs::remove_dir_all(test_root).unwrap();
    }

    fn test_hash(relative_path: &str) -> FileHash {
        FileHash {
            relative_path: relative_path.to_string(),
            sha1: [1; 20],
            sha256: [2; 32],
            optional: false,
        }
    }

    #[test]
    fn files2_omits_only_the_current_bundles_info_and_pkginfo() {
        let mut child = CodeResourcesMaps::default();
        child.insert_hash(test_hash("Info.plist"));
        child.insert_hash(test_hash("PkgInfo"));

        assert!(child.files.contains_key("Info.plist"));
        assert!(!child.files2.contains_key("Info.plist"));
        assert!(!child.files2.contains_key("PkgInfo"));

        let mut parent = CodeResourcesMaps::default();
        parent.merge_rerooted("PlugIns/Widget.appex", &child);

        assert!(
            parent
                .files2
                .contains_key("PlugIns/Widget.appex/Info.plist")
        );
        assert!(parent.files2.contains_key("PlugIns/Widget.appex/PkgInfo"));
    }

    #[test]
    fn direct_dylibs_are_hashed_from_their_final_signed_contents() {
        let test_root = std::env::temp_dir().join(format!(
            "apple-codesign-dylib-resources-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let dylib = test_root.join("Frameworks/Patch.dylib");
        fs::create_dir_all(dylib.parent().unwrap()).unwrap();
        fs::write(&dylib, b"unsigned").unwrap();

        let bundle_files = collect_own_bundle_files(&test_root, "Main", &[], &|| false).unwrap();
        assert_eq!(bundle_files.libraries, vec![dylib.clone()]);
        assert_eq!(bundle_files.resource_files, vec![dylib.clone()]);

        fs::write(&dylib, b"signed").unwrap();
        let hashes = hash_resource_files(&test_root, &bundle_files.resource_files, &|| false).unwrap();
        let expected_sha256: [u8; 32] = sha2::Sha256::digest(b"signed").into();
        assert_eq!(hashes[0].sha256, expected_sha256);

        fs::remove_dir_all(test_root).unwrap();
    }

    #[test]
    fn parent_seals_nested_bundle_code_resources() {
        let test_root = std::env::temp_dir().join(format!(
            "apple-codesign-nested-resources-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let child_path = test_root.join("Frameworks/Example.framework");
        let signature_path = child_path.join(CODE_SIGNATURE_DIR);
        fs::create_dir_all(&signature_path).unwrap();
        fs::write(child_path.join("Example"), b"executable").unwrap();
        fs::write(signature_path.join(CODE_RESOURCES_FILE), b"resources").unwrap();

        let mut child_resources = CodeResourcesMaps::default();
        child_resources.insert_hash(test_hash("Resource.txt"));
        let child = SubBundleResult {
            path: child_path,
            relative_root: "Frameworks/Example.framework".to_string(),
            executable: "Example".to_string(),
            resources: child_resources,
        };
        let mut parent = CodeResourcesMaps::default();

        merge_sub_bundle_resources(&mut parent, &test_root, &child, &|| false).unwrap();

        assert!(
            parent
                .files2
                .contains_key("Frameworks/Example.framework/Resource.txt")
        );
        assert!(
            parent
                .files2
                .contains_key("Frameworks/Example.framework/Example")
        );
        assert!(
            parent
                .files2
                .contains_key("Frameworks/Example.framework/_CodeSignature/CodeResources")
        );

        fs::remove_dir_all(test_root).unwrap();
    }
}
