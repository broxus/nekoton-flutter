use allo_isolate::Isolate;
use async_trait::async_trait;
use nekoton::core::{
    models::{TokenWalletTransaction, TransactionWithData, TransactionsBatchInfo},
    token_wallet::TokenWalletSubscriptionHandler,
};
use nekoton_abi::num_bigint::BigUint;

use crate::{
    core::{models::OnTransactionsFoundPayload, token_wallet::models::OnBalanceChangedPayload},
    PostWithResult,
};

pub struct TokenWalletSubscriptionHandlerImpl {
    on_balance_changed_port: Isolate,
    on_transactions_found_port: Isolate,
}

impl TokenWalletSubscriptionHandlerImpl {
    pub fn new(on_balance_changed_port: i64, on_transactions_found_port: i64) -> Self {
        Self {
            on_balance_changed_port: Isolate::new(on_balance_changed_port),
            on_transactions_found_port: Isolate::new(on_transactions_found_port),
        }
    }
}

#[async_trait]
impl TokenWalletSubscriptionHandler for TokenWalletSubscriptionHandlerImpl {
    fn on_balance_changed(&self, balance: BigUint) {
        let payload = serde_json::to_string(&OnBalanceChangedPayload {
            balance: balance.to_string(),
        })
        .unwrap();

        self.on_balance_changed_port
            .post_with_result(payload)
            .unwrap();
    }

    fn on_transactions_found(
        &self,
        transactions: Vec<TransactionWithData<TokenWalletTransaction>>,
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
