// Jackson Coxson

use base64::{Engine as _, engine::general_purpose::STANDARD as B64};
use plist_macro::plist;
use serde::Serialize;
use serde_json::json;
use std::{fmt::Debug, pin::Pin};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tracing::{debug, warn};

use crate::{
    IdeviceError, ReadWrite, RemoteXpcClient, remote_pairing::RPPAIRING_MAGIC, xpc::XPCObject,
};

pub trait RpPairingSocketProvider: Debug {
    fn send_plain(
        &mut self,
        value: impl Serialize,
        seq: usize,
    ) -> Pin<Box<dyn Future<Output = Result<(), IdeviceError>> + Send + '_>>;

    fn send_encrypted(
        &mut self,
        ciphertext: Vec<u8>,
        seq: usize,
    ) -> Pin<Box<dyn Future<Output = Result<(), IdeviceError>> + Send + '_>>;

    fn recv_plain<'a>(
        &'a mut self,
    ) -> Pin<Box<dyn Future<Output = Result<plist::Value, IdeviceError>> + Send + 'a>>;

    /// rppairing uses b64, while RemoteXPC uses raw bytes just fine
    fn serialize_bytes(b: &[u8]) -> plist::Value;
    fn deserialize_bytes(v: plist::Value) -> Option<Vec<u8>>;
}

#[derive(Debug)]
pub struct RpPairingSocket<R: ReadWrite> {
    pub inner: R,
    /// The value placed in the `originatedBy` field of every envelope we send.
    ///
    /// The host (the side that connects to a device and initiates pairing) sends
    /// `"host"`. The responder side - a "pairable host" that a device connects to
    /// and pairs *into* (see [`crate::remote_pairing::PairableHost`]) - sends
    /// `"device"`, because in rppairing terms it plays the accessory/responder role.
    originated_by: &'static str,
}

impl<R: ReadWrite> RpPairingSocket<R> {
    /// Creates a socket for the initiating host (sends `originatedBy: "host"`).
    pub fn new(socket: R) -> Self {
        Self {
            inner: socket,
            originated_by: "host",
        }
    }

    /// Creates a socket for the responder side (sends `originatedBy: "device"`).
    ///
    /// Use this when accepting a device-initiated pairing with
    /// [`crate::remote_pairing::PairableHost`].
    pub fn new_device(socket: R) -> Self {
        Self {
            inner: socket,
            originated_by: "device",
        }
    }

    async fn send_rppairing(&mut self, value: impl Serialize) -> Result<(), IdeviceError> {
        let x = serde_json::to_vec(&value).map_err(|_| invalid_frame())?;
        // Check before the wire u16 conversion; never send a prefix claiming a
        // different length from the following JSON document.
        if x.is_empty() || x.len() > usize::from(u16::MAX) {
            return Err(invalid_frame());
        }
        let mut frame = Vec::with_capacity(RPPAIRING_MAGIC.len() + 2 + x.len());
        frame.extend_from_slice(RPPAIRING_MAGIC);
        frame.extend_from_slice(&(x.len() as u16).to_be_bytes());
        frame.extend_from_slice(&x);
        self.inner.write_all(&frame).await?;
        self.inner.flush().await?;
        Ok(())
    }
}

impl<R: ReadWrite> RpPairingSocketProvider for RpPairingSocket<R> {
    fn send_plain(
        &mut self,
        value: impl Serialize,
        seq: usize,
    ) -> Pin<Box<dyn Future<Output = Result<(), IdeviceError>> + Send + '_>> {
        let v = json!({
            "message": {"plain": {"_0": value}},
            "originatedBy": self.originated_by,
            "sequenceNumber": seq
        });

        Box::pin(async move {
            self.send_rppairing(v).await?;
            Ok(())
        })
    }

    fn send_encrypted(
        &mut self,
        ciphertext: Vec<u8>,
        seq: usize,
    ) -> Pin<Box<dyn Future<Output = Result<(), IdeviceError>> + Send + '_>> {
        let v = json!({
            "message": {"streamEncrypted": {"_0": B64.encode(&ciphertext)}},
            "originatedBy": self.originated_by,
            "sequenceNumber": seq
        });

        Box::pin(async move {
            self.send_rppairing(v).await?;
            Ok(())
        })
    }

    fn recv_plain<'a>(
        &'a mut self,
    ) -> Pin<Box<dyn Future<Output = Result<plist::Value, IdeviceError>> + Send + 'a>> {
        Box::pin(async move {
            let mut magic = vec![0u8; RPPAIRING_MAGIC.len()];
            self.inner.read_exact(&mut magic).await?;
            if magic != RPPAIRING_MAGIC {
                return Err(invalid_frame());
            }

            let mut packet_len_bytes = [0u8; 2];
            self.inner.read_exact(&mut packet_len_bytes).await?;
            let packet_len = u16::from_be_bytes(packet_len_bytes);
            if packet_len == 0 {
                return Err(invalid_frame());
            }

            let mut value = vec![0u8; packet_len as usize];
            self.inner.read_exact(&mut value).await?;

            let value: serde_json::Value =
                serde_json::from_slice(&value).map_err(|_| invalid_frame())?;
            if !value.is_object() {
                return Err(invalid_frame());
            }

            // Try plain first, then return the whole message dict for encrypted
            if let Some(v) = value
                .get("message")
                .and_then(|x| x.get("plain"))
                .and_then(|x| x.get("_0"))
            {
                if !v.is_object() {
                    return Err(invalid_frame());
                }
                plist::to_value(v).map_err(|_| invalid_frame())
            } else {
                // Return the full message for encrypted handling
                plist::to_value(&value).map_err(|_| invalid_frame())
            }
        })
    }

    fn serialize_bytes(b: &[u8]) -> plist::Value {
        plist!(B64.encode(b))
    }

    fn deserialize_bytes(v: plist::Value) -> Option<Vec<u8>> {
        if let plist::Value::String(v) = v {
            B64.decode(v).ok()
        } else {
            None
        }
    }
}

impl<R: ReadWrite> RpPairingSocketProvider for RemoteXpcClient<R> {
    fn send_plain(
        &mut self,
        value: impl Serialize,
        seq: usize,
    ) -> Pin<Box<dyn Future<Output = Result<(), IdeviceError>> + Send + '_>> {
        let value: plist::Value = match plist::to_value(&value) {
            Ok(value) => value,
            Err(_) => return Box::pin(async { Err(invalid_frame()) }),
        };
        let value: XPCObject = value.into();

        let v = crate::xpc!({
            "mangledTypeName": "RemotePairing.ControlChannelMessageEnvelope",
            "value": {
                "message": {"plain": {"_0": value}},
                "originatedBy": "host",
                "sequenceNumber": seq as u64
            }
        });
        debug!("Sending RP RemoteXPC envelope");

        Box::pin(async move {
            self.send_object(v, true).await?;
            Ok(())
        })
    }

    fn send_encrypted(
        &mut self,
        ciphertext: Vec<u8>,
        seq: usize,
    ) -> Pin<Box<dyn Future<Output = Result<(), IdeviceError>> + Send + '_>> {
        let v = crate::xpc!({
            "mangledTypeName": "RemotePairing.ControlChannelMessageEnvelope",
            "value": {
                "message": {"streamEncrypted": {"_0": ciphertext}},
                "originatedBy": "host",
                "sequenceNumber": seq as u64
            }
        });

        Box::pin(async move {
            self.send_object(v, true).await?;
            Ok(())
        })
    }

    fn recv_plain<'a>(
        &'a mut self,
    ) -> Pin<Box<dyn Future<Output = Result<plist::Value, IdeviceError>> + Send + 'a>> {
        Box::pin(async move {
            let msg = self.recv_root().await?;
            debug!("Received RP RemoteXPC envelope");
            let msg = msg.into_dictionary().and_then(|mut x| x.remove("value"));

            let msg = match msg {
                Some(v) => v,
                None => {
                    return Err(IdeviceError::UnexpectedResponse(
                        "missing value field in RemoteXPC message".into(),
                    ));
                }
            };

            // Try plain first
            if let Some(plain) = msg
                .as_dictionary()
                .and_then(|x| x.get("message"))
                .and_then(|x| x.as_dictionary())
                .and_then(|x| x.get("plain"))
                .and_then(|x| x.as_dictionary())
                .and_then(|x| x.get("_0"))
                .cloned()
            {
                return Ok(plain);
            }

            // Return the whole value dict for encrypted handling
            Ok(msg)
        })
    }

    fn serialize_bytes(b: &[u8]) -> plist::Value {
        plist::Value::Data(b.to_owned())
    }

    fn deserialize_bytes(v: plist::Value) -> Option<Vec<u8>> {
        if let plist::Value::Data(v) = v {
            Some(v)
        } else {
            warn!("Non-data passed to rppairingsocket::deserialize_bytes for RemoteXPC provider");
            None
        }
    }
}

fn invalid_frame() -> IdeviceError {
    IdeviceError::UnexpectedResponse("Invalid Remote Pairing message frame".into())
}

// Invoked by the existing grouped tunnel-security test; no third test run or
// additional standalone test method is needed for these pre-auth wire cases.
#[cfg(test)]
pub(super) async fn assert_rp_socket_security() {
    async fn receive(
        magic: &[u8],
        body: &[u8],
        declared: u16,
    ) -> Result<plist::Value, IdeviceError> {
        let (client, mut server) = tokio::io::duplex(65536);
        let mut frame = magic.to_vec();
        frame.extend_from_slice(&declared.to_be_bytes());
        frame.extend_from_slice(body);
        let task = tokio::spawn(async move {
            let _ = server.write_all(&frame).await;
        });
        let result = RpPairingSocket::new(client).recv_plain().await;
        task.await.unwrap();
        result
    }
    let body =
        br#"{"message":{"plain":{"_0":{"state":2}}},"originatedBy":"device","sequenceNumber":0}"#;
    let valid = receive(RPPAIRING_MAGIC, body, body.len() as u16)
        .await
        .unwrap();
    assert_eq!(
        valid
            .as_dictionary()
            .unwrap()
            .get("state")
            .and_then(plist::Value::as_unsigned_integer),
        Some(2)
    );
    assert!(
        receive(b"BADMAGIC!", body, body.len() as u16)
            .await
            .is_err()
    );
    assert!(receive(RPPAIRING_MAGIC, &[], 0).await.is_err());
    assert!(receive(RPPAIRING_MAGIC, b"{}", 100).await.is_err());
    for unsupported in [
        br#"{"message":{"plain":{"_0":null}}}"#.as_slice(),
        b"{",
        b"[]",
    ] {
        assert!(
            receive(RPPAIRING_MAGIC, unsupported, unsupported.len() as u16)
                .await
                .is_err(),
            "Malformed/unsupported pre-auth JSON must fail without panic"
        );
    }
    let (client, mut server) = tokio::io::duplex(65536);
    let mut socket = RpPairingSocket::new(client);
    assert!(
        socket
            .send_plain(
                serde_json::json!({"oversizedNonsecretFixture":"X".repeat(65536)}),
                0
            )
            .await
            .is_err()
    );
    drop(socket);
    let mut output = Vec::new();
    server.read_to_end(&mut output).await.unwrap();
    assert!(
        output.is_empty(),
        "Overflow rejection must precede every frame write"
    );
}
