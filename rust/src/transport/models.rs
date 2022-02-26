use nekoton::core::models::{Transaction, TransactionsBatchInfo};
use nekoton_abi::{GenTimings, LastTransactionId, TransactionId};
use num_derive::FromPrimitive;
use serde::Serialize;

#[derive(FromPrimitive)]
pub enum TransportType {
    Jrpc,
    Gql,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FullContractState {
    pub balance: String,
    pub gen_timings: GenTimings,
    pub last_transaction_id: Option<LastTransactionId>,
    pub is_deployed: bool,
    pub code_hash: Option<String>,
    pub boc: String,
}

#[derive(Serialize)]
pub struct TransactionsList {
    pub transactions: Vec<Transaction>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub continuation: Option<TransactionId>,
    pub info: Option<TransactionsBatchInfo>,
}
