use nekoton::core::models;
use nekoton_utils::serde_address;
use serde::Serialize;
use ton_block::MsgAddressInt;

use crate::models::ToSerializable;

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

impl ToSerializable<TokenWalletTransaction> for models::TokenWalletTransaction {
    fn to_serializable(self) -> TokenWalletTransaction {
        match self {
            models::TokenWalletTransaction::IncomingTransfer(token_incoming_transfer) => {
                TokenWalletTransaction::IncomingTransfer {
                    token_incoming_transfer,
                }
            }
            models::TokenWalletTransaction::OutgoingTransfer(token_outgoing_transfer) => {
                TokenWalletTransaction::OutgoingTransfer {
                    token_outgoing_transfer: token_outgoing_transfer.to_serializable(),
                }
            }
            models::TokenWalletTransaction::SwapBack(token_swap_back) => {
                TokenWalletTransaction::SwapBack { token_swap_back }
            }
            models::TokenWalletTransaction::Accept(value) => TokenWalletTransaction::Accept {
                value: value.to_string(),
            },
            models::TokenWalletTransaction::TransferBounced(value) => {
                TokenWalletTransaction::TransferBounced {
                    value: value.to_string(),
                }
            }
            models::TokenWalletTransaction::SwapBackBounced(value) => {
                TokenWalletTransaction::SwapBackBounced {
                    value: value.to_string(),
                }
            }
        }
    }
}

#[derive(Serialize)]
pub struct TokenOutgoingTransfer {
    pub to: TransferRecipient,
    pub tokens: String,
}

impl ToSerializable<TokenOutgoingTransfer> for models::TokenOutgoingTransfer {
    fn to_serializable(self) -> TokenOutgoingTransfer {
        TokenOutgoingTransfer {
            to: self.to.to_serializable(),
            tokens: self.tokens.to_string(),
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

impl ToSerializable<TransferRecipient> for models::TransferRecipient {
    fn to_serializable(self) -> TransferRecipient {
        match self {
            models::TransferRecipient::OwnerWallet(address) => {
                TransferRecipient::OwnerWallet { address }
            }
            models::TransferRecipient::TokenWallet(address) => {
                TransferRecipient::TokenWallet { address }
            }
        }
    }
}
