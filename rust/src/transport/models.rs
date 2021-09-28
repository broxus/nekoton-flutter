use nekoton::core::models::{Transaction, TransactionsBatchInfo};
use nekoton_abi::{GenTimings, LastTransactionId, TransactionId};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct JsFullContractState {
    pub balance: String,
    pub gen_timings: GenTimings,
    pub last_transaction_id: Option<LastTransactionId>,
    pub is_deployed: bool,
    pub boc: String,
}

#[derive(Serialize, Deserialize)]
pub struct JsTransactionsList {
    pub transactions: Vec<Transaction>,
    pub continuation: Option<TransactionId>,
    pub info: Option<TransactionsBatchInfo>,
}

#[derive(Serialize, Deserialize)]
pub struct JsExecutionOutput {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub output: Option<serde_json::Value>,
    pub code: i32,
}

#[derive(Serialize, Deserialize)]
pub struct JsSplittedTvc {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub data: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedInput {
    pub method: String,
    pub input: serde_json::Value,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedOutput {
    pub method: String,
    pub output: serde_json::Value,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedEvent {
    pub event: String,
    pub data: serde_json::Value,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedTransaction {
    pub method: String,
    pub input: serde_json::Value,
    pub output: serde_json::Value,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedTransactionEvent {
    pub event: String,
    pub data: serde_json::Value,
}
