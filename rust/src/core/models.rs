use nekoton::core::models::{
    ContractState, PendingTransaction, Transaction, TransactionsBatchInfo,
};
use serde::Serialize;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OnMessageSentPayload {
    pub pending_transaction: PendingTransaction,
    pub transaction: Option<Transaction>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OnMessageExpiredPayload {
    pub pending_transaction: PendingTransaction,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OnStateChangedPayload {
    pub new_state: ContractState,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OnTransactionsFoundPayload<T> {
    pub transactions: Vec<T>,
    pub batch_info: TransactionsBatchInfo,
}
