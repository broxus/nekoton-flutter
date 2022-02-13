use super::models::{OnBalanceChangedPayload, TokenWalletTransaction};
use crate::core::{models::OnTransactionsFoundPayload, post_subscription_data};
use async_trait::async_trait;
use nekoton::core::{
    models::{self, TransactionWithData, TransactionsBatchInfo},
    token_wallet::TokenWalletSubscriptionHandler,
};
use nekoton_abi::num_bigint::BigUint;

pub struct TokenWalletSubscriptionHandlerImpl {
    pub on_balance_changed_port: i64,
    pub on_transactions_found_port: i64,
}

#[async_trait]
impl TokenWalletSubscriptionHandler for TokenWalletSubscriptionHandlerImpl {
    fn on_balance_changed(&self, balance: BigUint) {
        let payload = OnBalanceChangedPayload {
            balance: balance.to_string(),
        };
        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_balance_changed_port, payload);
    }

    fn on_transactions_found(
        &self,
        transactions: Vec<TransactionWithData<models::TokenWalletTransaction>>,
        batch_info: TransactionsBatchInfo,
    ) {
        let transactions = transactions
            .iter()
            .map(|e| -> TransactionWithData<TokenWalletTransaction> {
                TransactionWithData::<TokenWalletTransaction> {
                    transaction: e.transaction.clone(),
                    data: e.data.clone().map(|e| TokenWalletTransaction::from_core(e)),
                }
            })
            .collect::<Vec<_>>();

        let payload = OnTransactionsFoundPayload::<TokenWalletTransaction> {
            transactions,
            batch_info,
        };
        let payload = serde_json::to_string(&payload).unwrap();

        post_subscription_data(self.on_transactions_found_port, payload);
    }
}
