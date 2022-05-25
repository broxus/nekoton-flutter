use async_trait::async_trait;
use nekoton::core::{
    models::{self, TransactionWithData, TransactionsBatchInfo},
    token_wallet::TokenWalletSubscriptionHandler,
};
use nekoton_abi::num_bigint::BigUint;

use crate::{
    core::{
        models::OnTransactionsFoundPayload,
        post_subscription_data,
        token_wallet::models::{OnBalanceChangedPayload, TokenWalletTransaction},
    },
    models::ToSerializable,
};

pub struct TokenWalletSubscriptionHandlerImpl {
    on_balance_changed_port: i64,
    on_transactions_found_port: i64,
}

impl TokenWalletSubscriptionHandlerImpl {
    pub fn new(on_balance_changed_port: i64, on_transactions_found_port: i64) -> Self {
        Self {
            on_balance_changed_port,
            on_transactions_found_port,
        }
    }
}

#[async_trait]
impl TokenWalletSubscriptionHandler for TokenWalletSubscriptionHandlerImpl {
    fn on_balance_changed(&self, balance: BigUint) {
        let payload = OnBalanceChangedPayload {
            balance: balance.to_string(),
        };

        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_balance_changed_port, payload).unwrap();
    }

    fn on_transactions_found(
        &self,
        transactions: Vec<TransactionWithData<models::TokenWalletTransaction>>,
        batch_info: TransactionsBatchInfo,
    ) {
        let transactions = transactions
            .iter()
            .map(|e| TransactionWithData::<TokenWalletTransaction> {
                transaction: e.transaction.to_owned(),
                data: e.data.to_owned().map(|e| e.to_serializable()),
            })
            .collect::<Vec<_>>();

        let payload = OnTransactionsFoundPayload::<TokenWalletTransaction> {
            transactions,
            batch_info,
        };

        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_transactions_found_port, payload).unwrap();
    }
}
