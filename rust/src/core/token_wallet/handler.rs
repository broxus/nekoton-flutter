use super::models::{OnBalanceChangedPayload, TokenWalletTransaction};
use crate::core::{post_subscription_data, OnTransactionsFoundPayload, SubscriptionHandlerMessage};
use async_trait::async_trait;
use nekoton::core::{
    models::{self, TransactionWithData, TransactionsBatchInfo},
    token_wallet::TokenWalletSubscriptionHandler,
};
use nekoton_abi::num_bigint::BigUint;

pub struct TokenWalletSubscriptionHandlerImpl {
    pub port: i64,
}

#[async_trait]
impl TokenWalletSubscriptionHandler for TokenWalletSubscriptionHandlerImpl {
    fn on_balance_changed(&self, balance: BigUint) {
        let payload = OnBalanceChangedPayload {
            balance: balance.to_string(),
        };

        if let Ok(payload) = serde_json::to_string(&payload) {
            let message = SubscriptionHandlerMessage {
                event: "on_balance_changed".to_owned(),
                payload,
            };

            if let Ok(message) = serde_json::to_string(&message) {
                post_subscription_data(self.port, message);
            };
        };
    }

    fn on_transactions_found(
        &self,
        transactions: Vec<TransactionWithData<models::TokenWalletTransaction>>,
        batch_info: TransactionsBatchInfo,
    ) {
        let transactions = transactions
            .iter()
            .map(
                |transaction| -> TransactionWithData<TokenWalletTransaction> {
                    TransactionWithData::<TokenWalletTransaction> {
                        transaction: transaction.transaction.clone(),
                        data: transaction
                            .data
                            .clone()
                            .map(|data| TokenWalletTransaction::from_core(data)),
                    }
                },
            )
            .collect::<Vec<_>>();

        let payload = OnTransactionsFoundPayload::<TokenWalletTransaction> {
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
