use nekoton::core::models::{Transaction, TransactionsBatchInfo};
use nekoton_abi::{GenTimings, LastTransactionId, TransactionId};
use serde::Serialize;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FullContractState {
    pub balance: String,
    pub gen_timings: GenTimings,
    pub last_transaction_id: Option<LastTransactionId>,
    pub is_deployed: bool,
    pub boc: String,
}

#[derive(Serialize)]
pub struct TransactionsList {
    pub transactions: Vec<Transaction>,
    pub continuation: Option<TransactionId>,
    pub info: Option<TransactionsBatchInfo>,
}
