use nekoton::core::models::{Transaction, TransactionsBatchInfo};
use nekoton_abi::{GenTimings, LastTransactionId, TransactionId};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct JsFullContractState {
    balance: String,
    gen_timings: GenTimings,
    last_transaction_id: Option<LastTransactionId>,
    is_deployed: bool,
    boc: String,
}

#[derive(Serialize, Deserialize)]
pub struct JsTransactionsList {
    transactions: Vec<Transaction>,
    continuation: Option<TransactionId>,
    info: Option<TransactionsBatchInfo>,
}

#[derive(Serialize, Deserialize)]
pub struct JsExecutionOutput {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    output: Option<serde_json::Value>,
    code: i32,
}

#[derive(Serialize, Deserialize)]
pub struct JsSplittedTvc {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    data: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    code: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedInput {
    method: String,
    input: serde_json::Value,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedOutput {
    method: String,
    output: serde_json::Value,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedEvent {
    event: String,
    data: serde_json::Value,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedTransaction {
    method: String,
    input: serde_json::Value,
    output: serde_json::Value,
}

#[derive(Serialize, Deserialize)]
pub struct JsDecodedTransactionEvent {
    event: String,
    data: serde_json::Value,
}
