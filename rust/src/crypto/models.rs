use nekoton::crypto;
use nekoton_utils::serde_uint256;
use serde::{Deserialize, Serialize};
use ton_block::Serializable;
use ton_types::{Cell, UInt256};

use crate::{
    models::{ToNekoton, ToSerializable},
    HandleError,
};

#[derive(Serialize, Deserialize)]
pub struct SignedMessage {
    #[serde(with = "serde_uint256")]
    pub hash: UInt256,
    pub expire_at: u32,
    #[serde(with = "serde_message")]
    pub boc: ton_block::Message,
}

impl ToSerializable<SignedMessage> for crypto::SignedMessage {
    fn to_serializable(self) -> SignedMessage {
        let cell: Cell = self
            .message
            .write_to_new_cell()
            .handle_error()
            .unwrap()
            .into();

        let hash = cell.repr_hash();

        SignedMessage {
            hash,
            expire_at: self.expire_at,
            boc: self.message,
        }
    }
}

impl ToNekoton<crypto::SignedMessage> for SignedMessage {
    fn to_nekoton(self) -> crypto::SignedMessage {
        crypto::SignedMessage {
            message: self.boc,
            expire_at: self.expire_at,
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SignedData {
    pub data_hash: String,
    pub signature: String,
    pub signature_hex: String,
    pub signature_parts: SignatureParts,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SignedDataRaw {
    pub signature: String,
    pub signature_hex: String,
    pub signature_parts: SignatureParts,
}

#[derive(Serialize)]
pub struct SignatureParts {
    pub high: String,
    pub low: String,
}

pub mod serde_message {
    use nekoton_utils::serde_cell;
    use serde::de::Error;
    use ton_block::{Deserializable, Serializable};

    use super::*;

    pub fn serialize<S>(data: &ton_block::Message, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        use serde::ser::Error;

        serde_cell::serialize(&data.serialize().map_err(S::Error::custom)?, serializer)
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<ton_block::Message, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let data = String::deserialize(deserializer)?;
        ton_block::Message::construct_from_base64(&data).map_err(D::Error::custom)
    }
}
