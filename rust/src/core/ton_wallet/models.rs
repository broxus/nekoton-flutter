use crate::core::token_wallet::models::TokenOutgoingTransfer;
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

impl TransactionAdditionalInfo {
    pub fn from_core(transaction_additional_info: models::TransactionAdditionalInfo) -> Self {
        match transaction_additional_info {
            models::TransactionAdditionalInfo::Comment(value) => Self::Comment { value },
            models::TransactionAdditionalInfo::DePoolOnRoundComplete(notification) => {
                Self::DePoolOnRoundComplete { notification }
            }
            models::TransactionAdditionalInfo::DePoolReceiveAnswer(notification) => {
                Self::DePoolReceiveAnswer { notification }
            }
            models::TransactionAdditionalInfo::TokenWalletDeployed(notification) => {
                Self::TokenWalletDeployed { notification }
            }
            models::TransactionAdditionalInfo::WalletInteraction(info) => Self::WalletInteraction {
                info: WalletInteractionInfo::from_core(info),
            },
            _ => Self::Comment {
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

impl WalletInteractionInfo {
    pub fn from_core(wallet_interaction_info: models::WalletInteractionInfo) -> Self {
        Self {
            recipient: wallet_interaction_info.recipient,
            known_payload: wallet_interaction_info
                .known_payload
                .map(|e| KnownPayload::from_core(e)),
            method: WalletInteractionMethod::from_core(wallet_interaction_info.method),
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

impl KnownPayload {
    pub fn from_core(known_payload: models::KnownPayload) -> Self {
        match known_payload {
            models::KnownPayload::Comment(value) => Self::Comment { value },
            models::KnownPayload::TokenOutgoingTransfer(token_outgoing_transfer) => {
                Self::TokenOutgoingTransfer {
                    token_outgoing_transfer: TokenOutgoingTransfer::from_core(
                        token_outgoing_transfer,
                    ),
                }
            }
            models::KnownPayload::TokenSwapBack(token_swap_back) => {
                Self::TokenSwapBack { token_swap_back }
            }
            _ => Self::Comment {
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

impl WalletInteractionMethod {
    pub fn from_core(wallet_interaction_method: models::WalletInteractionMethod) -> Self {
        match wallet_interaction_method {
            models::WalletInteractionMethod::WalletV3Transfer => Self::WalletV3Transfer,
            models::WalletInteractionMethod::Multisig(multisig_transaction) => Self::Multisig {
                multisig_transaction: MultisigTransaction::from_core(*multisig_transaction),
            },
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
}

impl MultisigTransaction {
    pub fn from_core(multisig_transaction: models::MultisigTransaction) -> Self {
        match multisig_transaction {
            models::MultisigTransaction::Send(multisig_send_transaction) => Self::Send {
                multisig_send_transaction,
            },
            models::MultisigTransaction::Submit(multisig_submit_transaction) => Self::Submit {
                multisig_submit_transaction,
            },
            models::MultisigTransaction::Confirm(multisig_confirm_transaction) => Self::Confirm {
                multisig_confirm_transaction,
            },
        }
    }
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "runtimeType")]
pub enum WalletType {
    Multisig { multisig_type: MultisigType },
    WalletV3,
}

impl WalletType {
    pub fn from_core(contract: ton_wallet::WalletType) -> Self {
        match contract {
            ton_wallet::WalletType::Multisig(multisig_type) => Self::Multisig { multisig_type },
            ton_wallet::WalletType::WalletV3 => Self::WalletV3,
        }
    }

    pub fn to_core(self) -> ton_wallet::WalletType {
        match self {
            WalletType::Multisig { multisig_type } => {
                ton_wallet::WalletType::Multisig(multisig_type)
            }
            WalletType::WalletV3 => ton_wallet::WalletType::WalletV3,
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

impl ExistingWalletInfo {
    pub fn from_core(existing_wallet_info: ton_wallet::ExistingWalletInfo) -> Self {
        Self {
            address: existing_wallet_info.address,
            public_key: existing_wallet_info.public_key,
            wallet_type: WalletType::from_core(existing_wallet_info.wallet_type),
            contract_state: existing_wallet_info.contract_state,
        }
    }

    pub fn to_core(self) -> ton_wallet::ExistingWalletInfo {
        ton_wallet::ExistingWalletInfo {
            address: self.address,
            public_key: self.public_key,
            wallet_type: self.wallet_type.to_core(),
            contract_state: self.contract_state,
        }
    }
}
