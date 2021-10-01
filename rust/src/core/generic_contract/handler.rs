use super::models::{
    OnMessageExpiredPayload, OnMessageSentPayload, OnStateChangedPayload,
    OnTransactionsFoundPayload,
};
use crate::core::{post_subscription_data, SubscriptionHandlerMessage};
use async_trait::async_trait;
use nekoton::core::{
    generic_contract::GenericContractSubscriptionHandler,
    models::{self, PendingTransaction, Transaction, TransactionsBatchInfo},
};

pub struct GenericContractSubscriptionHandlerImpl {
    pub port: i64,
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

        if let Ok(payload) = serde_json::to_string(&payload) {
            let message = SubscriptionHandlerMessage {
                event: "on_message_sent".to_owned(),
                payload,
            };

            if let Ok(message) = serde_json::to_string(&message) {
                post_subscription_data(self.port, message);
            };
        };
    }

    fn on_message_expired(&self, pending_transaction: PendingTransaction) {
        let payload = OnMessageExpiredPayload {
            pending_transaction,
        };

        if let Ok(payload) = serde_json::to_string(&payload) {
            let message = SubscriptionHandlerMessage {
                event: "on_message_expired".to_owned(),
                payload,
            };

            if let Ok(message) = serde_json::to_string(&message) {
                post_subscription_data(self.port, message);
            };
        };
    }

    fn on_state_changed(&self, new_state: models::ContractState) {
        let payload = OnStateChangedPayload { new_state };

        if let Ok(payload) = serde_json::to_string(&payload) {
            let message = SubscriptionHandlerMessage {
                event: "on_state_changed".to_owned(),
                payload,
            };

            if let Ok(message) = serde_json::to_string(&message) {
                post_subscription_data(self.port, message);
            };
        };
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

        if let Ok(payload) = serde_json::to_string(&payload) {
            let message = SubscriptionHandlerMessage {
                event: "on_transactions_found".to_owned(),
                payload,
            };

            if let Ok(message) = serde_json::to_string(&message) {
                post_subscription_data(self.port, message);
            };
        };
    }
}
