use async_trait::async_trait;
use nekoton::core::{
    generic_contract::GenericContractSubscriptionHandler,
    models::{self, PendingTransaction, Transaction, TransactionsBatchInfo},
};

use crate::core::{
    generic_contract::models::OnTransactionsFoundPayload,
    models::{OnMessageExpiredPayload, OnMessageSentPayload, OnStateChangedPayload},
    post_subscription_data,
};

pub struct GenericContractSubscriptionHandlerImpl {
    on_message_sent_port: i64,
    on_message_expired_port: i64,
    on_state_changed_port: i64,
    on_transactions_found_port: i64,
}

impl GenericContractSubscriptionHandlerImpl {
    pub fn new(
        on_message_sent_port: i64,
        on_message_expired_port: i64,
        on_state_changed_port: i64,
        on_transactions_found_port: i64,
    ) -> Self {
        Self {
            on_message_sent_port,
            on_message_expired_port,
            on_state_changed_port,
            on_transactions_found_port,
        }
    }
}

#[async_trait]
impl GenericContractSubscriptionHandler for GenericContractSubscriptionHandlerImpl {
    fn on_message_sent(
        &self,
        pending_transaction: PendingTransaction,
        transaction: Option<Transaction>,
    ) {
        let payload = OnMessageSentPayload {
            pending_transaction,
            transaction,
        };

        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_message_sent_port, payload).unwrap();
    }

    fn on_message_expired(&self, pending_transaction: PendingTransaction) {
        let payload = OnMessageExpiredPayload {
            pending_transaction,
        };

        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_message_expired_port, payload).unwrap();
    }

    fn on_state_changed(&self, new_state: models::ContractState) {
        let payload = OnStateChangedPayload { new_state };

        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_state_changed_port, payload).unwrap();
    }

    fn on_transactions_found(
        &self,
        transactions: Vec<Transaction>,
        batch_info: TransactionsBatchInfo,
    ) {
        let payload = OnTransactionsFoundPayload {
            transactions,
            batch_info,
        };

        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_transactions_found_port, payload).unwrap();
    }
}
