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
        token_incoming_transfer: TokenIncomingTransfer,
    },
    OutgoingTransfer {
        token_outgoing_transfer: TokenOutgoingTransfer,
    },
    SwapBack {
        token_swap_back: TokenSwapBack,
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
                    token_incoming_transfer: TokenIncomingTransfer::from_core(
                        token_incoming_transfer,
                    ),
                }
            }
            models::TokenWalletTransaction::OutgoingTransfer(token_outgoing_transfer) => {
                Self::OutgoingTransfer {
                    token_outgoing_transfer: TokenOutgoingTransfer::from_core(
                        token_outgoing_transfer,
                    ),
                }
            }
            models::TokenWalletTransaction::SwapBack(token_swap_back) => Self::SwapBack {
                token_swap_back: TokenSwapBack::from_core(token_swap_back),
            },
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
pub struct TokenIncomingTransfer {
    pub tokens: String,
    #[serde(with = "serde_address")]
    pub sender_address: MsgAddressInt,
}

impl TokenIncomingTransfer {
    pub fn from_core(token_incoming_transfer: models::TokenIncomingTransfer) -> Self {
        Self {
            tokens: token_incoming_transfer.tokens.to_string(),
            sender_address: token_incoming_transfer.sender_address,
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
pub struct TokenSwapBack {
    pub tokens: String,
    pub to: String,
}

impl TokenSwapBack {
    pub fn from_core(token_swap_back: models::TokenSwapBack) -> Self {
        Self {
            tokens: token_swap_back.tokens.to_string(),
            to: token_swap_back.to,
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
