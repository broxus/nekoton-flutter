use nekoton::crypto;
use nekoton_utils::{serde_message, serde_uint256};
use serde::{Deserialize, Serialize};
use ton_block::Serializable;
use ton_types::{Cell, UInt256};

use crate::models::{HandleError, ToNekoton, ToSerializable};

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
pub struct SignedData {
    pub data_hash: String,
    pub signature: String,
    pub signature_hex: String,
    pub signature_parts: SignatureParts,
}

#[derive(Serialize)]
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
