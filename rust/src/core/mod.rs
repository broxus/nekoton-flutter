mod accounts_storage;
mod keystore;
mod token_wallet;
pub mod ton_wallet;

use allo_isolate::Isolate;
use nekoton::{
    core::{
        self,
        models::{TransactionWithData, TransactionsBatchInfo},
    },
    crypto::UnsignedMessage,
};
use nekoton_utils::{serde_u64, serde_uint256};
use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;
use ton_types::UInt256;

type MutexUnsignedMessage = Mutex<Box<dyn UnsignedMessage>>;

fn post_subscription_data(port: i64, data: String) {
    let isolate = Isolate::new(port);
    isolate.post(data);
}

#[derive(Serialize)]
pub struct SubscriptionHandlerMessage {
    pub event: String,
    pub payload: String,
}

#[derive(Serialize)]
pub struct OnTransactionsFoundPayload<T> {
    pub transactions: Vec<TransactionWithData<T>>,
    pub batch_info: TransactionsBatchInfo,
}

#[derive(Serialize, Deserialize)]
pub struct ContractState {
    #[serde(with = "serde_u64")]
    pub balance: u64,
    pub gen_timings: GenTimings,
    pub last_transaction_id: Option<LastTransactionId>,
    pub is_deployed: bool,
}

impl ContractState {
    pub fn from_core(contract_state: core::models::ContractState) -> Self {
        Self {
            balance: contract_state.balance,
            gen_timings: GenTimings::from_core(contract_state.gen_timings),
            last_transaction_id: contract_state
                .last_transaction_id
                .map(|last_transaction_id| LastTransactionId::from_core(last_transaction_id)),
            is_deployed: contract_state.is_deployed,
        }
    }

    pub fn to_core(self) -> core::models::ContractState {
        core::models::ContractState {
            balance: self.balance,
            gen_timings: self.gen_timings.to_core(),
            last_transaction_id: self
                .last_transaction_id
                .map(|last_transaction_id| last_transaction_id.to_core()),
            is_deployed: self.is_deployed,
        }
    }
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "runtimeType")]
pub enum GenTimings {
    Unknown,
    Known {
        #[serde(with = "serde_u64")]
        gen_lt: u64,
        gen_utime: u32,
    },
}

impl GenTimings {
    pub fn from_core(gen_timings: nekoton_abi::GenTimings) -> Self {
        match gen_timings {
            nekoton_abi::GenTimings::Unknown => Self::Unknown,
            nekoton_abi::GenTimings::Known { gen_lt, gen_utime } => {
                Self::Known { gen_lt, gen_utime }
            }
        }
    }

    pub fn to_core(self) -> nekoton_abi::GenTimings {
        match self {
            GenTimings::Unknown => nekoton_abi::GenTimings::Unknown,
            GenTimings::Known { gen_lt, gen_utime } => {
                nekoton_abi::GenTimings::Known { gen_lt, gen_utime }
            }
        }
    }
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "runtimeType")]
pub enum LastTransactionId {
    Exact {
        transaction_id: TransactionId,
    },
    Inexact {
        #[serde(with = "serde_u64")]
        latest_lt: u64,
    },
}

impl LastTransactionId {
    pub fn from_core(last_transaction_id: nekoton_abi::LastTransactionId) -> Self {
        match last_transaction_id {
            nekoton_abi::LastTransactionId::Exact(transaction_id) => Self::Exact {
                transaction_id: TransactionId::from_core(transaction_id),
            },
            nekoton_abi::LastTransactionId::Inexact { latest_lt } => Self::Inexact { latest_lt },
        }
    }

    pub fn to_core(self) -> nekoton_abi::LastTransactionId {
        match self {
            LastTransactionId::Exact { transaction_id } => {
                nekoton_abi::LastTransactionId::Exact(transaction_id.to_core())
            }
            LastTransactionId::Inexact { latest_lt } => {
                nekoton_abi::LastTransactionId::Inexact { latest_lt }
            }
        }
    }
}

#[derive(Serialize, Deserialize)]
pub struct TransactionId {
    #[serde(with = "serde_u64")]
    pub lt: u64,
    #[serde(with = "serde_uint256")]
    pub hash: UInt256,
}

impl TransactionId {
    pub fn from_core(transaction_id: nekoton_abi::TransactionId) -> Self {
        Self {
            lt: transaction_id.lt,
            hash: transaction_id.hash,
        }
    }

    pub fn to_core(self) -> nekoton_abi::TransactionId {
        nekoton_abi::TransactionId {
            lt: self.lt,
            hash: self.hash,
        }
    }
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
