use super::models::TransactionAdditionalInfo;
use crate::core::{
    models::{
        OnMessageExpiredPayload, OnMessageSentPayload, OnStateChangedPayload,
        OnTransactionsFoundPayload,
    },
    post_subscription_data,
};
use async_trait::async_trait;
use nekoton::core::{
    models::{self, PendingTransaction, Transaction, TransactionWithData, TransactionsBatchInfo},
    ton_wallet::TonWalletSubscriptionHandler,
};

pub struct TonWalletSubscriptionHandlerImpl {
    pub on_message_sent_port: i64,
    pub on_message_expired_port: i64,
    pub on_state_changed_port: i64,
    pub on_transactions_found_port: i64,
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
        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_message_sent_port, payload);
    }

    fn on_message_expired(&self, pending_transaction: PendingTransaction) {
        let payload = OnMessageExpiredPayload {
            pending_transaction,
        };
        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_message_expired_port, payload);
    }

    fn on_state_changed(&self, new_state: models::ContractState) {
        let payload = OnStateChangedPayload { new_state };
        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_state_changed_port, payload);
    }

    fn on_transactions_found(
        &self,
        transactions: Vec<TransactionWithData<models::TransactionAdditionalInfo>>,
        batch_info: TransactionsBatchInfo,
    ) {
        let transactions = transactions
            .iter()
            .map(|e| -> TransactionWithData<TransactionAdditionalInfo> {
                TransactionWithData::<TransactionAdditionalInfo> {
                    transaction: e.transaction.clone(),
                    data: e
                        .data
                        .clone()
                        .map(|e| TransactionAdditionalInfo::from_core(e)),
                }
            })
            .collect::<Vec<_>>();

        let payload = OnTransactionsFoundPayload::<TransactionAdditionalInfo> {
            transactions,
            batch_info,
        };
        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_transactions_found_port, payload);
    }
}
