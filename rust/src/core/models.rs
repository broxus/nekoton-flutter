use nekoton::core::{
    self,
    models::{
        self, ContractState, PendingTransaction, Transaction, TransactionWithData,
        TransactionsBatchInfo,
    },
};
use nekoton_utils::{serde_address, serde_boc, serde_optional_address};
use serde::{Deserialize, Serialize};

use crate::models::{ToNekoton, ToSerializable};

#[derive(Serialize)]
pub struct OnMessageSentPayload {
    pub pending_transaction: PendingTransaction,
    pub transaction: Option<Transaction>,
}

#[derive(Serialize)]
pub struct OnMessageExpiredPayload {
    pub pending_transaction: PendingTransaction,
}

#[derive(Serialize)]
pub struct OnStateChangedPayload {
    pub new_state: ContractState,
}

#[derive(Serialize)]
pub struct OnTransactionsFoundPayload<T> {
    pub transactions: Vec<TransactionWithData<T>>,
    pub batch_info: TransactionsBatchInfo,
}

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum Expiration {
    Never,
    Timeout { value: u32 },
    Timestamp { value: u32 },
}

impl ToNekoton<models::Expiration> for Expiration {
    fn to_nekoton(self) -> models::Expiration {
        match self {
            Expiration::Never => models::Expiration::Never,
            Expiration::Timeout { value } => models::Expiration::Timeout(value),
            Expiration::Timestamp { value } => models::Expiration::Timestamp(value),
        }
    }
}

#[derive(Serialize)]
pub struct InternalMessage {
    #[serde(with = "serde_optional_address")]
    pub source: Option<ton_block::MsgAddressInt>,
    #[serde(with = "serde_address")]
    pub destination: ton_block::MsgAddressInt,
    pub amount: String,
    pub bounce: bool,
    #[serde(with = "serde_boc")]
    pub body: ton_types::SliceData,
}

impl ToSerializable<InternalMessage> for core::InternalMessage {
    fn to_serializable(self) -> InternalMessage {
        InternalMessage {
            source: self.source,
            destination: self.destination,
            amount: self.amount.to_string(),
            bounce: self.bounce,
            body: self.body,
        }
    }
}
