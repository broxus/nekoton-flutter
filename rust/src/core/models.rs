use nekoton::core::{
    self,
    models::{
        ContractState, PendingTransaction, Transaction, TransactionWithData, TransactionsBatchInfo,
    },
};
use nekoton_utils::{serde_address, serde_boc, serde_optional_address};
use serde::{Deserialize, Serialize};

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

impl Expiration {
    pub fn to_core(self) -> core::models::Expiration {
        match self {
            Expiration::Never => core::models::Expiration::Never,
            Expiration::Timeout { value } => core::models::Expiration::Timeout(value),
            Expiration::Timestamp { value } => core::models::Expiration::Timestamp(value),
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

impl InternalMessage {
    pub fn from_core(internal_message: nekoton::core::InternalMessage) -> Self {
        Self {
            source: internal_message.source,
            destination: internal_message.destination,
            amount: internal_message.amount.to_string(),
            bounce: internal_message.bounce,
            body: internal_message.body,
        }
    }
}
