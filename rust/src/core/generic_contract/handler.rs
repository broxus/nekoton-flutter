use allo_isolate::Isolate;
use async_trait::async_trait;
use nekoton::core::{
    generic_contract::GenericContractSubscriptionHandler,
    models::{ContractState, PendingTransaction, Transaction, TransactionsBatchInfo},
};

use crate::{
    core::models::{
        OnMessageExpiredPayload, OnMessageSentPayload, OnStateChangedPayload,
        OnTransactionsFoundPayload,
    },
    PostWithResult,
};

pub struct GenericContractSubscriptionHandlerImpl {
    on_message_sent_port: Isolate,
    on_message_expired_port: Isolate,
    on_state_changed_port: Isolate,
    on_transactions_found_port: Isolate,
}

impl GenericContractSubscriptionHandlerImpl {
    pub fn new(
        on_message_sent_port: i64,
        on_message_expired_port: i64,
        on_state_changed_port: i64,
        on_transactions_found_port: i64,
    ) -> Self {
        Self {
            on_message_sent_port: Isolate::new(on_message_sent_port),
            on_message_expired_port: Isolate::new(on_message_expired_port),
            on_state_changed_port: Isolate::new(on_state_changed_port),
            on_transactions_found_port: Isolate::new(on_transactions_found_port),
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
        let payload = serde_json::to_string(&OnMessageSentPayload {
            pending_transaction,
            transaction,
        })
        .unwrap();

        self.on_message_sent_port.post_with_result(payload).unwrap();
    }

    fn on_message_expired(&self, pending_transaction: PendingTransaction) {
        let payload = serde_json::to_string(&OnMessageExpiredPayload {
            pending_transaction,
        })
        .unwrap();

        self.on_message_expired_port
            .post_with_result(payload)
            .unwrap();
    }

    fn on_state_changed(&self, new_state: ContractState) {
        let payload = serde_json::to_string(&OnStateChangedPayload { new_state }).unwrap();

        self.on_state_changed_port
            .post_with_result(payload)
            .unwrap();
    }

    fn on_transactions_found(
        &self,
        transactions: Vec<Transaction>,
        batch_info: TransactionsBatchInfo,
    ) {
        let payload = serde_json::to_string(&OnTransactionsFoundPayload {
            transactions,
            batch_info,
        })
        .unwrap();

        self.on_transactions_found_port
            .post_with_result(payload)
            .unwrap();
    }
}
