pub mod accounts_storage;
pub mod generic_contract;
pub mod keystore;
pub mod token_wallet;
pub mod ton_wallet;

use allo_isolate::Isolate;
use nekoton::{
    core::{
        self,
        models::{TransactionWithData, TransactionsBatchInfo},
    },
    crypto::UnsignedMessage,
};
use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;

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
