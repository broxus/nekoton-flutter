use nekoton::core::{models, token_wallet::TokenWallet};
use nekoton_utils::serde_address;
use serde::Serialize;
use tokio::sync::Mutex;
use ton_block::MsgAddressInt;

pub type MutexTokenWallet = Mutex<Option<TokenWallet>>;

#[derive(Serialize)]
pub struct OnBalanceChangedPayload {
    pub balance: String,
}

#[derive(Serialize)]
#[serde(tag = "runtimeType")]
pub enum TokenWalletTransaction {
    IncomingTransfer {
        token_incoming_transfer: models::TokenIncomingTransfer,
    },
    OutgoingTransfer {
        token_outgoing_transfer: TokenOutgoingTransfer,
    },
    SwapBack {
        token_swap_back: models::TokenSwapBack,
    },
    Accept {
        value: String,
    },
    TransferBounced {
        value: String,
    },
    SwapBackBounced {
        value: String,
    },
}

impl TokenWalletTransaction {
    pub fn from_core(token_wallet_transaction: models::TokenWalletTransaction) -> Self {
        match token_wallet_transaction {
            models::TokenWalletTransaction::IncomingTransfer(token_incoming_transfer) => {
                Self::IncomingTransfer {
                    token_incoming_transfer,
                }
            }
            models::TokenWalletTransaction::OutgoingTransfer(token_outgoing_transfer) => {
                Self::OutgoingTransfer {
                    token_outgoing_transfer: TokenOutgoingTransfer::from_core(
                        token_outgoing_transfer,
                    ),
                }
            }
            models::TokenWalletTransaction::SwapBack(token_swap_back) => {
                Self::SwapBack { token_swap_back }
            }
            models::TokenWalletTransaction::Accept(value) => Self::Accept {
                value: value.to_string(),
            },
            models::TokenWalletTransaction::TransferBounced(value) => Self::TransferBounced {
                value: value.to_string(),
            },
            models::TokenWalletTransaction::SwapBackBounced(value) => Self::SwapBackBounced {
                value: value.to_string(),
            },
        }
    }
}

#[derive(Serialize)]
pub struct TokenOutgoingTransfer {
    pub to: TransferRecipient,
    pub tokens: String,
}

impl TokenOutgoingTransfer {
    pub fn from_core(token_outgoing_transfer: models::TokenOutgoingTransfer) -> Self {
        Self {
            to: TransferRecipient::from_core(token_outgoing_transfer.to),
            tokens: token_outgoing_transfer.tokens.to_string(),
        }
    }
}

#[derive(Serialize)]
#[serde(tag = "runtimeType")]
pub enum TransferRecipient {
    OwnerWallet {
        #[serde(with = "serde_address")]
        address: MsgAddressInt,
    },
    TokenWallet {
        #[serde(with = "serde_address")]
        address: MsgAddressInt,
    },
}

impl TransferRecipient {
    pub fn from_core(transfer_recipient: models::TransferRecipient) -> Self {
        match transfer_recipient {
            models::TransferRecipient::OwnerWallet(address) => Self::OwnerWallet { address },
            models::TransferRecipient::TokenWallet(address) => Self::TokenWallet { address },
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TokenWalletInfo {
    #[serde(with = "serde_address")]
    pub owner: MsgAddressInt,
    #[serde(with = "serde_address")]
    pub address: MsgAddressInt,
    pub symbol: models::Symbol,
    pub version: models::TokenWalletVersion,
    pub balance: String,
    pub contract_state: models::ContractState,
}
