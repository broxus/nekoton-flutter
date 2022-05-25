use nekoton::{
    core::models::{Transaction, TransactionsBatchInfo},
    transport::models,
};
use nekoton_abi::{GenTimings, LastTransactionId, TransactionId};
use nekoton_utils::{serde_optional_address, serde_vec_address};
use num_derive::FromPrimitive;
use serde::{Deserialize, Serialize};
use ton_block::MsgAddressInt;

use crate::models::{ToNekoton, ToSerializable};

#[derive(FromPrimitive)]
pub enum TransportType {
    Jrpc,
    Gql,
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "runtimeType")]
pub enum RawContractState {
    NotExists,
    Exists {
        existing_contract: models::ExistingContract,
    },
}

impl ToSerializable<RawContractState> for models::RawContractState {
    fn to_serializable(self) -> RawContractState {
        match self {
            models::RawContractState::NotExists => RawContractState::NotExists,
            models::RawContractState::Exists(existing_contract) => {
                RawContractState::Exists { existing_contract }
            }
        }
    }
}

impl ToNekoton<models::RawContractState> for RawContractState {
    fn to_nekoton(self) -> models::RawContractState {
        match self {
            RawContractState::NotExists => models::RawContractState::NotExists,
            RawContractState::Exists { existing_contract } => {
                models::RawContractState::Exists(existing_contract)
            }
        }
    }
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
