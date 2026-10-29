//! Fail-closed entitlement gate before any developer-account mutations.
//! Capability policy is separate; this parser preserves all bounded typed entitlement values.
//! The original signature is untrusted:
//! inspect every FAT slice, reject ambiguous blobs, and require XML/DER agreement.
use plist::{
    stream::{Event, XmlReader},
    Dictionary, Value,
};
use std::{
    collections::HashSet,
    fs::{self, File},
    io::{Read, Seek, SeekFrom},
    path::Path,
};

const MAX_SIGNATURE: usize = 4 * 1024 * 1024;
const MAX_XML: usize = 256 * 1024;
const MAX_VALUE_BYTES: usize = 64 * 1024;
const MAX_DEPTH: usize = 16;
const MAX_EVENTS: usize = 8192;
const ARM64: u32 = 0x0100_000c;
const XML_SLOT: u32 = 5;
const DER_SLOT: u32 = 7;
const XML_MAGIC: u32 = 0xfade_7171;
const DER_MAGIC: u32 = 0xfade_7172;

fn at(file: &mut File, pos: u64, len: usize) -> Result<Vec<u8>, ()> {
    if len > MAX_SIGNATURE
        || pos.checked_add(len as u64).ok_or(())? > file.metadata().map_err(|_| ())?.len()
    {
        return Err(());
    }
    let mut data = vec![0; len];
    file.seek(SeekFrom::Start(pos)).map_err(|_| ())?;
    file.read_exact(&mut data).map_err(|_| ())?;
    Ok(data)
}
fn n32(data: &[u8], pos: usize, big: bool) -> Result<u32, ()> {
    let bytes = data
        .get(pos..pos.checked_add(4).ok_or(())?)
        .ok_or(())?
        .try_into()
        .map_err(|_| ())?;
    Ok(if big {
        u32::from_be_bytes(bytes)
    } else {
        u32::from_le_bytes(bytes)
    })
}
fn n64(data: &[u8], pos: usize, big: bool) -> Result<u64, ()> {
    let bytes = data
        .get(pos..pos.checked_add(8).ok_or(())?)
        .ok_or(())?
        .try_into()
        .map_err(|_| ())?;
    Ok(if big {
        u64::from_be_bytes(bytes)
    } else {
        u64::from_le_bytes(bytes)
    })
}
fn entitlements(path: &Path) -> Result<Dictionary, ()> {
    if !fs::symlink_metadata(path)
        .map_err(|_| ())?
        .file_type()
        .is_file()
    {
        return Err(());
    }
    let mut file = File::open(path).map_err(|_| ())?;
    let file_len = file.metadata().map_err(|_| ())?.len();
    let header = at(&mut file, 0, 8)?;
    let magic = &header[..4];
    if !matches!(
        magic,
        [0xca, 0xfe, 0xba, 0xbe]
            | [0xca, 0xfe, 0xba, 0xbf]
            | [0xbe, 0xba, 0xfe, 0xca]
            | [0xbf, 0xba, 0xfe, 0xca]
    ) {
        return slice_entitlements(&mut file, 0, file_len, Some(ARM64), None);
    }
    let big = magic[0] == 0xca;
    let wide = magic == [0xca, 0xfe, 0xba, 0xbf] || magic == [0xbf, 0xba, 0xfe, 0xca];
    let count = n32(&header, 4, big)? as usize;
    if count == 0 || count > 32 {
        return Err(());
    }
    let stride = if wide { 32 } else { 20 };
    let table = at(&mut file, 8, count * stride)?;
    let table_end = 8 + table.len() as u64;
    let mut ranges: Vec<(u64, u64)> = Vec::with_capacity(count);
    let mut architecture_ids = HashSet::new();
    let mut all = None;
    let mut arm64 = false;
    for i in 0..count {
        let pos = i * stride;
        let cpu = n32(&table, pos, big)?;
        let subtype = n32(&table, pos + 4, big)?;
        if !architecture_ids.insert((cpu, subtype)) {
            return Err(());
        }
        let base = if wide {
            n64(&table, pos + 8, big)?
        } else {
            n32(&table, pos + 8, big)? as u64
        };
        let len = if wide {
            n64(&table, pos + 16, big)?
        } else {
            n32(&table, pos + 12, big)? as u64
        };
        let end = base.checked_add(len).ok_or(())?;
        if base < table_end
            || len < 28
            || end > file_len
            || ranges.iter().any(|(a, b)| base < *b && end > *a)
        {
            return Err(());
        }
        ranges.push((base, end));
        // Every slice is inspected: an alternate arm64e or old CPU slice cannot hide a capability.
        let current = slice_entitlements(&mut file, base, len, Some(cpu), Some(subtype))?;
        if all.as_ref().is_some_and(|previous| previous != &current) {
            return Err(());
        }
        all = Some(current);
        arm64 |= cpu == ARM64;
    }
    if !arm64 {
        return Err(());
    }
    all.ok_or(())
}
fn slice_entitlements(
    file: &mut File,
    base: u64,
    slice_len: u64,
    cpu: Option<u32>,
    subtype: Option<u32>,
) -> Result<Dictionary, ()> {
    if slice_len < 28 {
        return Err(());
    }
    let first = at(file, base, 28)?;
    let (wide, big) = match first[..4] {
        [0xcf, 0xfa, 0xed, 0xfe] => (true, false),
        [0xfe, 0xed, 0xfa, 0xcf] => (true, true),
        [0xce, 0xfa, 0xed, 0xfe] => (false, false),
        [0xfe, 0xed, 0xfa, 0xce] => (false, true),
        _ => return Err(()),
    };
    let header_len = if wide { 32 } else { 28 };
    if slice_len < header_len as u64
        || cpu.is_some_and(|cpu| n32(&first, 4, big) != Ok(cpu))
        || subtype.is_some_and(|subtype| n32(&first, 8, big) != Ok(subtype))
        || (n32(&first, 4, big)? == ARM64 && !wide)
        || n32(&first, 12, big)? != 2
    {
        return Err(());
    }
    let count = n32(&first, 16, big)? as usize;
    let command_len = n32(&first, 20, big)? as usize;
    if count > 4096
        || command_len > MAX_SIGNATURE
        || header_len as u64 + command_len as u64 > slice_len
    {
        return Err(());
    }
    let cmds = at(
        file,
        base.checked_add(header_len as u64).ok_or(())?,
        command_len,
    )?;
    let mut pos = 0usize;
    let mut signature = None;
    for _ in 0..count {
        let command = n32(&cmds, pos, big)?;
        let len = n32(&cmds, pos.checked_add(4).ok_or(())?, big)? as usize;
        if len < 8
            || len % if wide { 8 } else { 4 } != 0
            || pos.checked_add(len).ok_or(())? > cmds.len()
        {
            return Err(());
        }
        if command == 0x1d {
            if len != 16 || signature.is_some() {
                return Err(());
            }
            signature = Some((
                n32(&cmds, pos + 8, big)? as u64,
                n32(&cmds, pos + 12, big)? as usize,
            ));
        }
        pos += len;
    }
    if pos != cmds.len() {
        return Err(());
    }
    let Some((start, len)) = signature else {
        return Ok(Dictionary::new());
    };
    if start < (header_len + command_len) as u64
        || len < 12
        || len > MAX_SIGNATURE
        || start.checked_add(len as u64).ok_or(())? > slice_len
    {
        return Err(());
    }
    let sig = at(file, base.checked_add(start).ok_or(())?, len)?;
    signature_entitlements(&sig)
}
pub(crate) fn signature_entitlements(sig: &[u8]) -> Result<Dictionary, ()> {
    if n32(sig, 0, true)? != 0xfade_0cc0 {
        return Err(());
    }
    let len = n32(sig, 4, true)? as usize;
    let count = n32(sig, 8, true)? as usize;
    let index_end = 12usize
        .checked_add(count.checked_mul(8).ok_or(())?)
        .ok_or(())?;
    if len < 12
        || len > sig.len()
        || count > 256
        || index_end > len
        || sig[len..].iter().any(|b| *b != 0)
    {
        return Err(());
    }
    let mut slots = HashSet::new();
    let mut ranges: Vec<(usize, usize)> = Vec::with_capacity(count);
    let mut xml = None;
    let mut der = None;
    for i in 0..count {
        let slot = n32(sig, 12 + i * 8, true)?;
        let pos = n32(sig, 16 + i * 8, true)? as usize;
        if !slots.insert(slot) || pos < index_end {
            return Err(());
        }
        let magic = n32(sig, pos, true)?;
        let child_len = n32(sig, pos.checked_add(4).ok_or(())?, true)? as usize;
        let end = pos.checked_add(child_len).ok_or(())?;
        if child_len < 8 || end > len || ranges.iter().any(|(a, b)| pos < *b && end > *a) {
            return Err(());
        }
        ranges.push((pos, end));
        match slot {
            XML_SLOT => {
                if magic != XML_MAGIC {
                    return Err(());
                }
                xml = Some(parse_basic_xml(&sig[pos + 8..end])?);
            }
            DER_SLOT => {
                if magic != DER_MAGIC {
                    return Err(());
                }
                der = Some(&sig[pos..end]);
            }
            _ => {
                // An entitlement blob under a different index must not have another interpretation.
                if magic == XML_MAGIC || magic == DER_MAGIC {
                    return Err(());
                }
            }
        }
    }
    match (xml, der) {
        (None, Some(_)) => Err(()), // DER-only sources need a separate audited decoder.
        (Some(xml), Some(der)) => {
            let canonical =
                apple_codesign_quick::signature::der_entitlements_blob(&xml).map_err(|_| ())?;
            if canonical != der {
                return Err(());
            }
            Ok(xml)
        }
        (Some(xml), None) => Ok(xml),
        (None, None) => Ok(Dictionary::new()),
    }
}
/// Bounded iterative XML parse: preserve typed values without duplicate-key coalescing
/// or recursively allocating an attacker-controlled plist tree.
fn parse_basic_xml(bytes: &[u8]) -> Result<Dictionary, ()> {
    if bytes.len() > MAX_XML {
        return Err(());
    }
    let end = bytes
        .iter()
        .rposition(|b| *b != 0)
        .map(|n| n + 1)
        .unwrap_or(0);
    let text = std::str::from_utf8(&bytes[..end]).map_err(|_| ())?;
    if text.contains("<!ENTITY") || text.contains("<![CDATA[") || text.contains('\0') {
        return Err(());
    }
    // plist's XML reader ignores unknown named entities; never let that change a key/value.
    for tail in text.split('&').skip(1) {
        let entity = tail.split_once(';').ok_or(())?.0;
        if !matches!(entity, "amp" | "lt" | "gt" | "apos" | "quot") {
            let number = entity
                .strip_prefix("#x")
                .map(|s| (s, 16))
                .or_else(|| entity.strip_prefix('#').map(|s| (s, 10)))
                .ok_or(())?;
            if number.0.is_empty()
                || u32::from_str_radix(number.0, number.1)
                    .ok()
                    .and_then(char::from_u32)
                    .is_none()
            {
                return Err(());
            }
        }
    }
    parse_entitlement_events(XmlReader::new(text.as_bytes()))
}
enum Frame {
    Array(Vec<Value>),
    Dictionary(Dictionary, Option<String>),
}
fn parse_entitlement_events(
    events: impl Iterator<Item = Result<Event<'static>, plist::Error>>,
) -> Result<Dictionary, ()> {
    let mut stack: Vec<Frame> = Vec::new();
    let mut root = None;
    for (count, event) in events.enumerate() {
        if count >= MAX_EVENTS {
            return Err(());
        }
        let event = event.map_err(|_| ())?;
        let value = match event {
            Event::StartArray(_) => {
                if stack.len() >= MAX_DEPTH {
                    return Err(());
                }
                stack.push(Frame::Array(Vec::new()));
                continue;
            }
            Event::StartDictionary(_) => {
                if stack.len() >= MAX_DEPTH {
                    return Err(());
                }
                stack.push(Frame::Dictionary(Dictionary::new(), None));
                continue;
            }
            Event::EndCollection => match stack.pop().ok_or(())? {
                Frame::Array(values) => Value::Array(values),
                Frame::Dictionary(values, key) => {
                    if key.is_some() {
                        return Err(());
                    }
                    Value::Dictionary(values)
                }
            },
            Event::Boolean(value) => Value::Boolean(value),
            Event::Integer(value) => Value::Integer(value),
            Event::Real(value) => {
                if !value.is_finite() {
                    return Err(());
                }
                Value::Real(value)
            }
            Event::String(value) => {
                if value.len() > MAX_VALUE_BYTES {
                    return Err(());
                }
                Value::String(value.into_owned())
            }
            Event::Data(value) => {
                if value.len() > MAX_VALUE_BYTES {
                    return Err(());
                }
                Value::Data(value.into_owned())
            }
            Event::Date(value) => Value::Date(value),
            Event::Uid(value) => Value::Uid(value),
            _ => return Err(()),
        };
        match stack.last_mut() {
            Some(Frame::Array(values)) => values.push(value),
            Some(Frame::Dictionary(values, key)) => match key.take() {
                Some(key) => {
                    values.insert(key, value);
                }
                None => {
                    let Value::String(value) = value else {
                        return Err(());
                    };
                    if value.is_empty() || value.len() > 512 || values.contains_key(&value) {
                        return Err(());
                    }
                    *key = Some(value);
                }
            },
            None => {
                if root.is_some() {
                    return Err(());
                }
                let Value::Dictionary(dictionary) = value else {
                    return Err(());
                };
                root = Some(dictionary);
            }
        }
    }
    if !stack.is_empty() {
        return Err(());
    }
    root.ok_or(())
}

fn identity_prefix(value: &str) -> bool {
    !value.is_empty() && value.len() <= 64 && value.bytes().all(|b| b.is_ascii_alphanumeric())
}
pub fn read_entitlements(bundle: &Path, bundle_id: &str) -> Result<Dictionary, ()> {
    if bundle_id.is_empty()
        || bundle_id.len() > 255
        || bundle_id.starts_with('.')
        || bundle_id.ends_with('.')
        || bundle_id.contains("..")
        || !bundle_id.contains('.')
        || !bundle_id
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || b == b'.' || b == b'-')
    {
        return Err(());
    }
    let info_path = bundle.join("Info.plist");
    if !fs::symlink_metadata(&info_path)
        .map_err(|_| ())?
        .file_type()
        .is_file()
        || fs::metadata(&info_path).map_err(|_| ())?.len() > MAX_SIGNATURE as u64
    {
        return Err(());
    }
    let info: Dictionary = plist::from_file(info_path).map_err(|_| ())?;
    let executable = info
        .get("CFBundleExecutable")
        .and_then(Value::as_string)
        .ok_or(())?;
    if executable.is_empty()
        || executable.len() > 255
        || executable.contains(['/', '\\', ':'])
        || executable == "."
        || executable == ".."
        || executable.chars().any(char::is_control)
    {
        return Err(());
    }
    let original = entitlements(&bundle.join(executable))?;
    if original
        .get("application-identifier")
        .is_some_and(|v| v.as_string().is_none())
    {
        return Err(());
    }
    let app_id = original
        .get("application-identifier")
        .and_then(Value::as_string);
    let prefix = match app_id {
        Some(id) => {
            let (prefix, id) = id.split_once('.').ok_or(())?;
            if !identity_prefix(prefix) || id != bundle_id {
                return Err(());
            }
            Some(prefix)
        }
        None => None,
    };
    // A legacy App-ID prefix may differ from its developer team ID; both must be typed identifiers.
    if original
        .get("com.apple.developer.team-identifier")
        .is_some_and(|v| !v.as_string().is_some_and(identity_prefix))
    {
        return Err(());
    }
    if original
        .get("get-task-allow")
        .is_some_and(|v| v.as_boolean().is_none())
    {
        return Err(());
    }
    if let Some(groups) = original.get("keychain-access-groups") {
        let groups = groups.as_array().ok_or(())?;
        if groups.len() > 256
            || groups.iter().any(|group| {
                !group
                    .as_string()
                    .is_some_and(|s| !s.is_empty() && s.len() <= 512)
            })
        {
            return Err(());
        }
    }
    let _ = prefix;
    Ok(original)
}
/// Compatibility policy for older callers/tests. New signing policy must consume the full
/// read_entitlements result and compare it with Apple's actual selected profile grants.
#[cfg(test)]
pub fn ensure_basic_entitlements(bundle: &Path, bundle_id: &str) -> Result<(), ()> {
    let original = read_entitlements(bundle, bundle_id)?;
    if original
        .get("application-identifier")
        .is_some_and(|v| v.as_string().is_none())
    {
        return Err(());
    }
    let app_id = original
        .get("application-identifier")
        .and_then(Value::as_string);
    let wildcard = app_id
        .and_then(|id| id.split_once('.'))
        .map(|(prefix, _)| format!("{prefix}.*"));
    for (key, value) in &original {
        match key.as_str() {
            "application-identifier" | "com.apple.developer.team-identifier" | "get-task-allow" => {
                ()
            }
            "keychain-access-groups" => {
                let groups = value.as_array().ok_or(())?;
                if groups.len() > 1 {
                    return Err(());
                }
                for group in groups {
                    let group = group.as_string().ok_or(())?;
                    if Some(group) != app_id && Some(group) != wildcard.as_deref() {
                        return Err(());
                    }
                }
            }
            _ => return Err(()),
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{
        path::PathBuf,
        sync::atomic::{AtomicU64, Ordering},
    };
    static NEXT: AtomicU64 = AtomicU64::new(1);
    struct Fixture(PathBuf);
    impl Drop for Fixture {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
        }
    }
    fn bundle(binary: Vec<u8>) -> Fixture {
        let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("target")
            .join(format!(
                "capabilities-{}-{}",
                std::process::id(),
                NEXT.fetch_add(1, Ordering::Relaxed)
            ));
        fs::create_dir_all(&path).unwrap();
        let mut info = Dictionary::new();
        info.insert("CFBundleExecutable".into(), "Test".into());
        plist::to_file_xml(path.join("Info.plist"), &info).unwrap();
        fs::write(path.join("Test"), binary).unwrap();
        Fixture(path)
    }
    fn basic() -> Dictionary {
        let mut e = Dictionary::new();
        e.insert(
            "application-identifier".into(),
            "OLDTEAM123.org.example.app".into(),
        );
        e.insert(
            "com.apple.developer.team-identifier".into(),
            "OLDTEAM123".into(),
        );
        e.insert("get-task-allow".into(), Value::Boolean(false));
        e.insert(
            "keychain-access-groups".into(),
            Value::Array(vec!["OLDTEAM123.org.example.app".into()]),
        );
        e
    }
    fn xml_blob(e: &Dictionary) -> Vec<u8> {
        let mut xml = vec![];
        plist::to_writer_xml(&mut xml, e).unwrap();
        xml_blob_bytes(xml)
    }
    fn xml_blob_bytes(xml: Vec<u8>) -> Vec<u8> {
        let mut out = vec![];
        out.extend(XML_MAGIC.to_be_bytes());
        out.extend(((xml.len() + 8) as u32).to_be_bytes());
        out.extend(xml);
        out
    }
    fn superblob(slots: Vec<(u32, Vec<u8>)>) -> Vec<u8> {
        let mut out = vec![];
        let count = slots.len();
        let len = 12 + count * 8 + slots.iter().map(|(_, blob)| blob.len()).sum::<usize>();
        for word in [0xfade_0cc0, len as u32, count as u32] {
            out.extend(word.to_be_bytes());
        }
        let mut offset = 12 + count * 8;
        for (slot, blob) in &slots {
            out.extend(slot.to_be_bytes());
            out.extend((offset as u32).to_be_bytes());
            offset += blob.len();
        }
        for (_, blob) in slots {
            out.extend(blob);
        }
        out
    }
    fn binary(sig: Vec<u8>) -> Vec<u8> {
        let mut data = vec![];
        for word in [
            0xfeed_facfu32,
            ARM64,
            0,
            2,
            1,
            16,
            0,
            0,
            0x1d,
            16,
            48,
            sig.len() as u32,
        ] {
            data.extend(word.to_le_bytes());
        }
        data.extend(sig);
        data
    }
    fn signed(e: &Dictionary, der: bool) -> Vec<u8> {
        let mut slots = vec![(XML_SLOT, xml_blob(e))];
        if der {
            slots.push((
                DER_SLOT,
                apple_codesign_quick::signature::der_entitlements_blob(e).unwrap(),
            ));
        }
        binary(superblob(slots))
    }
    fn fat(first: Vec<u8>, mut second: Vec<u8>) -> Vec<u8> {
        second[8..12].copy_from_slice(&2u32.to_le_bytes());
        let mut out = vec![];
        for word in [
            0xcafe_babeu32,
            2,
            ARM64,
            0,
            48,
            first.len() as u32,
            0,
            ARM64,
            2,
            48 + first.len() as u32,
            second.len() as u32,
            0,
        ] {
            out.extend(word.to_be_bytes());
        }
        out.extend(first);
        out.extend(second);
        out
    }
    #[test]
    fn identity_schema_and_der_agreement_fail_closed() {
        let good = basic();
        for der in [false, true] {
            let f = bundle(signed(&good, der));
            assert!(ensure_basic_entitlements(&f.0, "org.example.app").is_ok());
        }
        // The parser preserves capabilities for the separate selected-profile policy.
        let mut extended = good.clone();
        extended.insert(
            "com.apple.security.application-groups".into(),
            Value::Array(vec!["group.synthetic.authorized".into()]),
        );
        let mut nested = Dictionary::new();
        nested.insert("flag".into(), Value::Boolean(true));
        nested.insert("count".into(), Value::Integer(3u64.into()));
        extended.insert("com.example.structured".into(), Value::Dictionary(nested));
        for der in [false, true] {
            let f = bundle(signed(&extended, der));
            assert_eq!(
                read_entitlements(&f.0, "org.example.app").unwrap(),
                extended
            );
            assert!(ensure_basic_entitlements(&f.0, "org.example.app").is_err());
        }
        let mut typed = good.clone();
        typed.insert("com.example.data".into(), Value::Data(vec![1, 2, 3]));
        typed.insert(
            "com.example.date".into(),
            Value::Date((std::time::UNIX_EPOCH + std::time::Duration::from_secs(1)).into()),
        );
        typed.insert("com.example.real".into(), Value::Real(1.5));
        let f = bundle(signed(&typed, false));
        assert_eq!(read_entitlements(&f.0, "org.example.app").unwrap(), typed);
        let deep = format!(
            "<plist><dict><key>com.example.deep</key>{}<string>value</string>{}</dict></plist>",
            "<array>".repeat(MAX_DEPTH + 1),
            "</array>".repeat(MAX_DEPTH + 1)
        );
        let f = bundle(binary(superblob(vec![(
            XML_SLOT,
            xml_blob_bytes(deep.into_bytes()),
        )])));
        assert!(read_entitlements(&f.0, "org.example.app").is_err());
        for (key, value) in [
            ("application-identifier", Value::Boolean(true)),
            (
                "application-identifier",
                Value::String("OLDTEAM123.org.other.app".into()),
            ),
            ("com.apple.developer.team-identifier", Value::Array(vec![])),
            ("get-task-allow", Value::String("false".into())),
            (
                "keychain-access-groups",
                Value::Array(vec!["EVILTEAM12.org.example.app".into()]),
            ),
            (
                "com.apple.security.application-groups",
                Value::Array(vec!["group.shared".into()]),
            ),
        ] {
            let mut bad = good.clone();
            bad.insert(key.into(), value);
            let f = bundle(signed(&bad, false));
            assert!(ensure_basic_entitlements(&f.0, "org.example.app").is_err());
        }
        let mut hidden = good.clone();
        hidden.insert(
            "com.apple.security.application-groups".into(),
            Value::Array(vec!["group.hidden".into()]),
        );
        let f = bundle(binary(superblob(vec![
            (XML_SLOT, xml_blob(&good)),
            (
                DER_SLOT,
                apple_codesign_quick::signature::der_entitlements_blob(&hidden).unwrap(),
            ),
        ])));
        assert!(ensure_basic_entitlements(&f.0, "org.example.app").is_err());
        let der_only = bundle(binary(superblob(vec![(
            DER_SLOT,
            apple_codesign_quick::signature::der_entitlements_blob(&good).unwrap(),
        )])));
        assert!(ensure_basic_entitlements(&der_only.0, "org.example.app").is_err());
        let duplicate=bundle(binary(superblob(vec![(XML_SLOT,xml_blob_bytes(b"<plist><dict><key>get-task-allow</key><true/><key>get-task-allow</key><false/></dict></plist>".to_vec()))])));
        assert!(ensure_basic_entitlements(&duplicate.0, "org.example.app").is_err());
        let entity = bundle(binary(superblob(vec![(
            XML_SLOT,
            xml_blob_bytes(
                b"<plist><dict><key>get-task-allow</key><fa&unknown;lse/></dict></plist>".to_vec(),
            ),
        )])));
        assert!(ensure_basic_entitlements(&entity.0, "org.example.app").is_err());
    }
    #[test]
    fn fat_slices_signature_ranges_and_extension_capabilities_cannot_hide() {
        let good = basic();
        let same = bundle(fat(signed(&good, true), signed(&good, true)));
        assert!(ensure_basic_entitlements(&same.0, "org.example.app").is_ok());
        let mut bad = good.clone();
        bad.insert(
            "com.apple.developer.icloud-services".into(),
            Value::Array(vec!["CloudDocuments".into()]),
        );
        let hidden = bundle(fat(signed(&good, true), signed(&bad, false)));
        assert!(ensure_basic_entitlements(&hidden.0, "org.example.app").is_err());
        let mut duplicate = superblob(vec![
            (XML_SLOT, xml_blob(&good)),
            (XML_SLOT, xml_blob(&good)),
        ]);
        let f = bundle(binary(duplicate.clone()));
        assert!(ensure_basic_entitlements(&f.0, "org.example.app").is_err());
        // Even opaque non-entitlement indexes must not alias or overlap another child.
        duplicate[20..24].copy_from_slice(&0x10000u32.to_be_bytes());
        duplicate[24..28].copy_from_slice(&28u32.to_be_bytes());
        let f = bundle(binary(duplicate));
        assert!(ensure_basic_entitlements(&f.0, "org.example.app").is_err());
        let mut offset = superblob(vec![(XML_SLOT, xml_blob(&good))]);
        offset[16..20].copy_from_slice(&12u32.to_be_bytes());
        let f = bundle(binary(offset));
        assert!(ensure_basic_entitlements(&f.0, "org.example.app").is_err());
        let f = bundle(signed(&good, true));
        let file = fs::OpenOptions::new()
            .write(true)
            .open(f.0.join("Test"))
            .unwrap();
        file.set_len(50).unwrap();
        assert!(ensure_basic_entitlements(&f.0, "org.example.app").is_err());
        // The engine invokes the same gate for each extension before mutating Apple's account.
        let mut extension = basic();
        extension.insert(
            "application-identifier".into(),
            "OLDTEAM123.org.example.app.extension".into(),
        );
        extension.insert(
            "keychain-access-groups".into(),
            Value::Array(vec!["OLDTEAM123.org.example.app.extension".into()]),
        );
        let f = bundle(signed(&extension, true));
        assert!(ensure_basic_entitlements(&f.0, "org.example.app.extension").is_ok());
        extension.insert(
            "com.apple.developer.networking.networkextension".into(),
            Value::Array(vec!["packet-tunnel-provider".into()]),
        );
        let f = bundle(signed(&extension, true));
        assert!(ensure_basic_entitlements(&f.0, "org.example.app.extension").is_err());
    }
}
