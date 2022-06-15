use nekoton::{
    core::models::{Transaction, TransactionsBatchInfo},
    transport::models::{ExistingContract, RawContractState},
};
use nekoton_abi::{GenTimings, LastTransactionId, TransactionId};
use nekoton_utils::{serde_optional_address, serde_vec_address};
use serde::{Deserialize, Serialize};
use ton_block::MsgAddressInt;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum TransportType {
    Jrpc,
    Gql,
}

#[derive(Serialize, Deserialize)]
pub struct RawContractStateHelper(#[serde(with = "RawContractStateDef")] pub RawContractState);

#[derive(Serialize, Deserialize)]
#[serde(
    remote = "RawContractState",
    rename_all = "camelCase",
    tag = "type",
    content = "data"
)]
pub enum RawContractStateDef {
    NotExists,
    Exists(ExistingContract),
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

#[derive(Serialize)]
pub struct AccountsList {
    #[serde(with = "serde_vec_address")]
    pub accounts: Vec<MsgAddressInt>,
    #[serde(
        with = "serde_optional_address",
        skip_serializing_if = "Option::is_none"
    )]
    pub continuation: Option<MsgAddressInt>,
}
