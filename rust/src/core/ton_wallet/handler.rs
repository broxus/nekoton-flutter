use async_trait::async_trait;
use nekoton::core::{
    models::{self, PendingTransaction, Transaction, TransactionWithData, TransactionsBatchInfo},
    ton_wallet::TonWalletSubscriptionHandler,
};

use crate::{
    core::{
        models::{
            OnMessageExpiredPayload, OnMessageSentPayload, OnStateChangedPayload,
            OnTransactionsFoundPayload,
        },
        post_subscription_data,
        ton_wallet::models::TransactionAdditionalInfo,
    },
    models::ToSerializable,
};

pub struct TonWalletSubscriptionHandlerImpl {
    on_message_sent_port: i64,
    on_message_expired_port: i64,
    on_state_changed_port: i64,
    on_transactions_found_port: i64,
}

impl TonWalletSubscriptionHandlerImpl {
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
        transactions: Vec<TransactionWithData<models::TransactionAdditionalInfo>>,
        batch_info: TransactionsBatchInfo,
    ) {
        let transactions = transactions
            .iter()
            .map(|e| TransactionWithData::<TransactionAdditionalInfo> {
                transaction: e.transaction.to_owned(),
                data: e.data.to_owned().map(|e| e.to_serializable()),
            })
            .collect::<Vec<_>>();

        let payload = OnTransactionsFoundPayload::<TransactionAdditionalInfo> {
            transactions,
            batch_info,
        };

        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_transactions_found_port, payload).unwrap();
    }
}
