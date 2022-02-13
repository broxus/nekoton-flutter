use nekoton::core::models::{Transaction, TransactionsBatchInfo};
use serde::Serialize;

#[derive(Serialize)]
pub struct OnTransactionsFoundPayload {
    pub transactions: Vec<Transaction>,
    pub batch_info: TransactionsBatchInfo,
}
