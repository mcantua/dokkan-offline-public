// Jackson Coxson

use super::errors::RemotePairingError;

// from pym3
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum PairingDataComponentType {
    Method = 0x00,
    Identifier = 0x01,
    Salt = 0x02,
    PublicKey = 0x03,
    Proof = 0x04,
    EncryptedData = 0x05,
    State = 0x06,
    ErrorResponse = 0x07,
    RetryDelay = 0x08,
    Certificate = 0x09,
    Signature = 0x0a,
    Permissions = 0x0b,
    FragmentData = 0x0c,
    FragmentLast = 0x0d,
    SessionId = 0x0e,
    Ttl = 0x0f,
    ExtraData = 0x10,
    Info = 0x11,
    Acl = 0x12,
    Flags = 0x13,
    ValidationData = 0x14,
    MfiAuthToken = 0x15,
    MfiProductType = 0x16,
    SerialNumber = 0x17,
    MfiAuthTokenUuid = 0x18,
    AppFlags = 0x19,
    OwnershipProof = 0x1a,
    SetupCodeType = 0x1b,
    ProductionData = 0x1c,
    AppInfo = 0x1d,
    Separator = 0xff,
}

#[derive(Debug, Clone)]
pub struct TLV8Entry {
    pub tlv_type: PairingDataComponentType,
    pub data: Vec<u8>,
}

pub fn collect_component_data(
    entries: &[TLV8Entry],
    component: PairingDataComponentType,
) -> Vec<u8> {
    let mut out = Vec::new();
    for entry in entries {
        if entry.tlv_type == component {
            out.extend_from_slice(&entry.data);
        }
    }
    out
}

pub fn contains_component(entries: &[TLV8Entry], component: PairingDataComponentType) -> bool {
    entries.iter().any(|entry| entry.tlv_type == component)
}

/// Read exactly one logical field, including its contiguous 255-byte fragments.
/// A later occurrence is a duplicate, not a continuation of authenticated data.
pub fn collect_unique_component_data(
    entries: &[TLV8Entry],
    component: PairingDataComponentType,
) -> Result<Option<Vec<u8>>, RemotePairingError> {
    let mut output: Option<Vec<u8>> = None;
    let mut previous_was_component = false;
    let mut previous_length = 0;
    for entry in entries {
        if entry.tlv_type == component {
            if entry.data.len() > 255 {
                return Err(RemotePairingError::MalformedTlv);
            }
            if let Some(data) = &mut output {
                if !previous_was_component || previous_length != 255 || entry.data.is_empty() {
                    return Err(RemotePairingError::MalformedTlv);
                }
                data.extend_from_slice(&entry.data);
            } else {
                output = Some(entry.data.clone());
            }
            previous_was_component = true;
            previous_length = entry.data.len();
        } else {
            previous_was_component = false;
        }
    }
    Ok(output)
}

pub fn serialize_tlv8(entries: &[TLV8Entry]) -> Vec<u8> {
    let mut out = Vec::new();
    for entry in entries {
        if entry.data.is_empty() {
            out.extend_from_slice(&[entry.tlv_type as u8, 0]);
        } else {
            // TLV8 continuation boundaries are 255 bytes. Never truncate a
            // logical field length through an unchecked usize-to-u8 cast.
            for chunk in entry.data.chunks(255) {
                out.extend_from_slice(&[entry.tlv_type as u8, chunk.len() as u8]);
                out.extend_from_slice(chunk);
            }
        }
    }
    out
}

pub fn deserialize_tlv8(input: &[u8]) -> Result<Vec<TLV8Entry>, RemotePairingError> {
    let mut index = 0;
    let mut result = Vec::new();

    while index + 2 <= input.len() {
        let type_byte = input[index];
        let length = input[index + 1] as usize;
        index += 2;

        if index + length > input.len() {
            return Err(RemotePairingError::MalformedTlv);
        }

        let data = input[index..index + length].to_vec();
        index += length;

        let tlv_type = PairingDataComponentType::try_from(type_byte)
            .map_err(|_| RemotePairingError::UnknownTlv(type_byte))?;

        result.push(TLV8Entry { tlv_type, data });
    }

    if index != input.len() {
        return Err(RemotePairingError::MalformedTlv);
    }
    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pairing_fields_use_canonical_fragments_and_reject_ambiguous_values() {
        use PairingDataComponentType::{PublicKey, Salt, State};
        for length in [0, 1, 254, 255, 256, 384, 510, 511, 1024] {
            let bytes: Vec<u8> = (0..length).map(|i| (i % 251) as u8).collect();
            let wire = serialize_tlv8(&[TLV8Entry { tlv_type: PublicKey, data: bytes.clone() }]);
            // Independent, direct wire inspection: all nonfinal chunks must
            // fill their one-byte length field, and no bytes may disappear.
            let mut offset = 0;
            let mut recovered = Vec::new();
            loop {
                assert_eq!(wire[offset], PublicKey as u8);
                let size = usize::from(wire[offset + 1]);
                offset += 2;
                recovered.extend_from_slice(&wire[offset..offset + size]);
                offset += size;
                if offset == wire.len() { break; }
                assert_eq!(size, 255);
            }
            assert_eq!(recovered, bytes);
            let entries = deserialize_tlv8(&wire).unwrap();
            assert_eq!(collect_unique_component_data(&entries, PublicKey).unwrap(), Some(bytes));
        }
        for malformed in [vec![State as u8], vec![State as u8, 1], vec![State as u8, 1, 2, 0]] {
            assert!(deserialize_tlv8(&malformed).is_err());
        }
        for entries in [
            vec![TLV8Entry { tlv_type: State, data: vec![2] }, TLV8Entry { tlv_type: State, data: vec![2] }],
            vec![TLV8Entry { tlv_type: PublicKey, data: vec![7; 255] }, TLV8Entry { tlv_type: Salt, data: vec![1] }, TLV8Entry { tlv_type: PublicKey, data: vec![7; 1] }],
        ] {
            assert!(collect_unique_component_data(&entries, entries[0].tlv_type).is_err());
        }
    }
}

impl TryFrom<u8> for PairingDataComponentType {
    type Error = u8;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        use PairingDataComponentType::*;
        Ok(match value {
            0x00 => Method,
            0x01 => Identifier,
            0x02 => Salt,
            0x03 => PublicKey,
            0x04 => Proof,
            0x05 => EncryptedData,
            0x06 => State,
            0x07 => ErrorResponse,
            0x08 => RetryDelay,
            0x09 => Certificate,
            0x0a => Signature,
            0x0b => Permissions,
            0x0c => FragmentData,
            0x0d => FragmentLast,
            0x0e => SessionId,
            0x0f => Ttl,
            0x10 => ExtraData,
            0x11 => Info,
            0x12 => Acl,
            0x13 => Flags,
            0x14 => ValidationData,
            0x15 => MfiAuthToken,
            0x16 => MfiProductType,
            0x17 => SerialNumber,
            0x18 => MfiAuthTokenUuid,
            0x19 => AppFlags,
            0x1a => OwnershipProof,
            0x1b => SetupCodeType,
            0x1c => ProductionData,
            0x1d => AppInfo,
            0xff => Separator,
            other => return Err(other),
        })
    }
}
