use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct AbiParam {
    pub name: String,
    #[serde(alias = "type")]
    pub param_type: String,
    pub components: Option<Vec<AbiParam>>,
}

#[derive(Serialize)]
pub struct ExecutionOutput {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub output: Option<serde_json::Value>,
    pub code: i32,
}

#[derive(Serialize)]
pub struct DecodedInput {
    pub method: String,
    pub input: serde_json::Value,
}

#[derive(Serialize)]
pub struct DecodedOutput {
    pub method: String,
    pub output: serde_json::Value,
}

#[derive(Serialize)]
pub struct DecodedEvent {
    pub event: String,
    pub data: serde_json::Value,
}

#[derive(Serialize)]
pub struct DecodedTransaction {
    pub method: String,
    pub input: serde_json::Value,
    pub output: serde_json::Value,
}

#[derive(Serialize)]
pub struct DecodedTransactionEvent {
    pub event: String,
    pub data: serde_json::Value,
}
