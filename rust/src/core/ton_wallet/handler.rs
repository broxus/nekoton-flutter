use super::models::{
    OnMessageExpiredPayload, OnMessageSentPayload, OnStateChangedPayload, TransactionAdditionalInfo,
};
use crate::core::{
    post_subscription_data, ContractState, OnTransactionsFoundPayload, SubscriptionHandlerMessage,
};
use async_trait::async_trait;
use nekoton::core::{
    models::{self, PendingTransaction, Transaction, TransactionWithData, TransactionsBatchInfo},
    ton_wallet::TonWalletSubscriptionHandler,
};

pub struct TonWalletSubscriptionHandlerImpl {
    pub port: i64,
}

#[async_trait]
impl TonWalletSubscriptionHandler for TonWalletSubscriptionHandlerImpl {
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
        let new_state = ContractState::from_core(new_state);
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
        transactions: Vec<TransactionWithData<models::TransactionAdditionalInfo>>,
        batch_info: TransactionsBatchInfo,
    ) {
        let transactions = transactions
            .iter()
            .map(
                |transaction| -> TransactionWithData<TransactionAdditionalInfo> {
                    TransactionWithData::<TransactionAdditionalInfo> {
                        transaction: transaction.transaction.clone(),
                        data: transaction
                            .data
                            .clone()
                            .map(|data| TransactionAdditionalInfo::from_core(data)),
                    }
                },
            )
            .collect::<Vec<_>>();

        let payload = OnTransactionsFoundPayload::<TransactionAdditionalInfo> {
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
