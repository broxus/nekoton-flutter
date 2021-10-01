use nekoton::core::{
    generic_contract::GenericContract,
    models::{ContractState, PendingTransaction, Transaction, TransactionsBatchInfo},
};
use serde::Serialize;
use tokio::sync::Mutex;

pub type MutexGenericContract = Mutex<Option<GenericContract>>;

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
pub struct OnTransactionsFoundPayload {
    pub transactions: Vec<Transaction>,
    pub batch_info: TransactionsBatchInfo,
}
