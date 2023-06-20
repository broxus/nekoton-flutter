use nekoton::core::{
    models::{
        self, ContractState, DePoolOnRoundCompleteNotification, DePoolReceiveAnswerNotification,
        TokenWalletDeployedNotification,
    },
    ton_wallet::{self, MultisigType},
};
use nekoton_utils::{serde_address, serde_optional_address, serde_public_key};
use serde::{Deserialize, Serialize};
use ton_block::MsgAddressInt;

use crate::{
    core::token_wallet::models::TokenOutgoingTransfer,
    models::{ToNekoton, ToSerializable},
};

#[derive(Serialize)]
#[serde(tag = "runtimeType")]
pub enum TransactionAdditionalInfo {
    Comment {
        value: String,
    },
    DePoolOnRoundComplete {
        notification: DePoolOnRoundCompleteNotification,
    },
    DePoolReceiveAnswer {
        notification: DePoolReceiveAnswerNotification,
    },
    TokenWalletDeployed {
        notification: TokenWalletDeployedNotification,
    },
    WalletInteraction {
        info: WalletInteractionInfo,
    },
}

impl ToSerializable<TransactionAdditionalInfo> for models::TransactionAdditionalInfo {
    fn to_serializable(self) -> TransactionAdditionalInfo {
        match self {
            models::TransactionAdditionalInfo::Comment(value) => {
                TransactionAdditionalInfo::Comment { value }
            }
            models::TransactionAdditionalInfo::DePoolOnRoundComplete(notification) => {
                TransactionAdditionalInfo::DePoolOnRoundComplete { notification }
            }
            models::TransactionAdditionalInfo::DePoolReceiveAnswer(notification) => {
                TransactionAdditionalInfo::DePoolReceiveAnswer { notification }
            }
            models::TransactionAdditionalInfo::TokenWalletDeployed(notification) => {
                TransactionAdditionalInfo::TokenWalletDeployed { notification }
            }
            models::TransactionAdditionalInfo::WalletInteraction(info) => {
                TransactionAdditionalInfo::WalletInteraction {
                    info: info.to_serializable(),
                }
            }
            _ => TransactionAdditionalInfo::Comment {
                value: String::new(),
            },
        }
    }
}

#[derive(Serialize)]
pub struct WalletInteractionInfo {
    #[serde(with = "serde_optional_address")]
    pub recipient: Option<MsgAddressInt>,
    pub known_payload: Option<KnownPayload>,
    pub method: WalletInteractionMethod,
}

impl ToSerializable<WalletInteractionInfo> for models::WalletInteractionInfo {
    fn to_serializable(self) -> WalletInteractionInfo {
        WalletInteractionInfo {
            recipient: self.recipient,
            known_payload: self.known_payload.map(|e| e.to_serializable()),
            method: self.method.to_serializable(),
        }
    }
}

#[derive(Serialize)]
#[serde(tag = "runtimeType")]
pub enum KnownPayload {
    Comment {
        value: String,
    },
    TokenOutgoingTransfer {
        token_outgoing_transfer: TokenOutgoingTransfer,
    },
    TokenSwapBack {
        token_swap_back: models::TokenSwapBack,
    },
}

impl ToSerializable<KnownPayload> for models::KnownPayload {
    fn to_serializable(self) -> KnownPayload {
        match self {
            models::KnownPayload::Comment(value) => KnownPayload::Comment { value },
            models::KnownPayload::TokenOutgoingTransfer(token_outgoing_transfer) => {
                KnownPayload::TokenOutgoingTransfer {
                    token_outgoing_transfer: token_outgoing_transfer.to_serializable(),
                }
            }
            models::KnownPayload::TokenSwapBack(token_swap_back) => {
                KnownPayload::TokenSwapBack { token_swap_back }
            }
            _ => KnownPayload::Comment {
                value: String::new(),
            },
        }
    }
}

#[derive(Serialize)]
#[serde(tag = "runtimeType")]
pub enum WalletInteractionMethod {
    WalletV3Transfer,
    Multisig {
        multisig_transaction: MultisigTransaction,
    },
}

impl ToSerializable<WalletInteractionMethod> for models::WalletInteractionMethod {
    fn to_serializable(self) -> WalletInteractionMethod {
        match self {
            models::WalletInteractionMethod::WalletV3Transfer => {
                WalletInteractionMethod::WalletV3Transfer
            }
            models::WalletInteractionMethod::Multisig(multisig_transaction) => {
                WalletInteractionMethod::Multisig {
                    multisig_transaction: multisig_transaction.to_serializable(),
                }
            }
        }
    }
}

#[derive(Serialize)]
#[serde(tag = "runtimeType")]
pub enum MultisigTransaction {
    Send {
        multisig_send_transaction: models::MultisigSendTransaction,
    },
    Submit {
        multisig_submit_transaction: models::MultisigSubmitTransaction,
    },
    Confirm {
        multisig_confirm_transaction: models::MultisigConfirmTransaction,
    },
    SubmitUpdate {
        multisig_submit_update_transaction: models::MultisigSubmitUpdate,
    },
    ConfirmUpdate {
        multisig_confirm_update_transaction: models::MultisigConfirmUpdate,
    },
    ExecuteUpdate {
        multisig_execute_update_transaction: models::MultisigExecuteUpdate,
    },
}

impl ToSerializable<MultisigTransaction> for models::MultisigTransaction {
    fn to_serializable(self) -> MultisigTransaction {
        match self {
            models::MultisigTransaction::Send(multisig_send_transaction) => {
                MultisigTransaction::Send {
                    multisig_send_transaction,
                }
            }
            models::MultisigTransaction::Submit(multisig_submit_transaction) => {
                MultisigTransaction::Submit {
                    multisig_submit_transaction,
                }
            }
            models::MultisigTransaction::Confirm(multisig_confirm_transaction) => {
                MultisigTransaction::Confirm {
                    multisig_confirm_transaction,
                }
            }
            models::MultisigTransaction::SubmitUpdate(multisig_submit_update_transaction) => {
                MultisigTransaction::SubmitUpdate {
                    multisig_submit_update_transaction,
                }
            }
            models::MultisigTransaction::ConfirmUpdate(multisig_confirm_update_transaction) => {
                MultisigTransaction::ConfirmUpdate {
                    multisig_confirm_update_transaction,
                }
            }
            models::MultisigTransaction::ExecuteUpdate(multisig_execute_update_transaction) => {
                MultisigTransaction::ExecuteUpdate {
                    multisig_execute_update_transaction,
                }
            }
        }
    }
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "runtimeType")]
pub enum WalletType {
    Multisig { multisig_type: MultisigType },
    WalletV3,
    HighloadWalletV2,
    EverWallet,
}

impl ToSerializable<WalletType> for ton_wallet::WalletType {
    fn to_serializable(self) -> WalletType {
        match self {
            ton_wallet::WalletType::Multisig(multisig_type) => {
                WalletType::Multisig { multisig_type }
            }
            ton_wallet::WalletType::WalletV3 => WalletType::WalletV3,
            ton_wallet::WalletType::HighloadWalletV2 => WalletType::HighloadWalletV2,
            ton_wallet::WalletType::EverWallet => WalletType::EverWallet,
        }
    }
}

impl ToNekoton<ton_wallet::WalletType> for WalletType {
    fn to_nekoton(self) -> ton_wallet::WalletType {
        match self {
            WalletType::Multisig { multisig_type } => {
                ton_wallet::WalletType::Multisig(multisig_type)
            }
            WalletType::WalletV3 => ton_wallet::WalletType::WalletV3,
            WalletType::HighloadWalletV2 => ton_wallet::WalletType::HighloadWalletV2,
            WalletType::EverWallet => ton_wallet::WalletType::EverWallet,
        }
    }
}

#[derive(Serialize, Deserialize)]
pub struct ExistingWalletInfo {
    #[serde(with = "serde_address")]
    pub address: MsgAddressInt,
    #[serde(with = "serde_public_key")]
    pub public_key: ed25519_dalek::PublicKey,
    pub wallet_type: WalletType,
    pub contract_state: ContractState,
}

impl ToSerializable<ExistingWalletInfo> for ton_wallet::ExistingWalletInfo {
    fn to_serializable(self) -> ExistingWalletInfo {
        ExistingWalletInfo {
            address: self.address,
            public_key: self.public_key,
            wallet_type: self.wallet_type.to_serializable(),
            contract_state: self.contract_state,
        }
    }
}

impl ToNekoton<ton_wallet::ExistingWalletInfo> for ExistingWalletInfo {
    fn to_nekoton(self) -> ton_wallet::ExistingWalletInfo {
        ton_wallet::ExistingWalletInfo {
            address: self.address,
            public_key: self.public_key,
            wallet_type: self.wallet_type.to_nekoton(),
            contract_state: self.contract_state,
        }
    }
}
