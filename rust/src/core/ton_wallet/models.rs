use crate::core::{
    token_wallet::models::{TokenOutgoingTransfer, TokenSwapBack},
    ContractState,
};
use nekoton::core::{
    models::{
        self, DePoolOnRoundCompleteNotification, DePoolReceiveAnswerNotification, EthEventStatus,
        PendingTransaction, TokenWalletDeployedNotification, TonEventStatus, Transaction,
    },
    ton_wallet::{self, MultisigType, TonWallet},
};
use nekoton_utils::{
    serde_address, serde_cell, serde_optional_address, serde_public_key, serde_string,
    serde_uint256, serde_vec_uint256,
};
use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;
use ton_block::MsgAddressInt;
use ton_types::UInt256;

pub type MutexTonWallet = Mutex<Option<TonWallet>>;

#[derive(Serialize)]
pub struct OnMessageSentPayload {
    pub pending_transaction: PendingTransaction,
    pub transaction: Option<Transaction>,
}

#[derive(Serialize)]
pub struct OnMessageExpiredPayload {
    pub pending_transaction: PendingTransaction,
}

#[derive(Serialize)]
pub struct OnStateChangedPayload {
    pub new_state: ContractState,
}

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
    EthEventStatusChanged {
        status: EthEventStatus,
    },
    TonEventStatusChanged {
        status: TonEventStatus,
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
            models::TransactionAdditionalInfo::EthEventStatusChanged(status) => {
                Self::EthEventStatusChanged { status }
            }
            models::TransactionAdditionalInfo::TonEventStatusChanged(status) => {
                Self::TonEventStatusChanged { status }
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
        token_swap_back: TokenSwapBack,
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
            models::KnownPayload::TokenSwapBack(token_swap_back) => Self::TokenSwapBack {
                token_swap_back: TokenSwapBack::from_core(token_swap_back),
            },
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
        multisig_send_transaction: MultisigSendTransaction,
    },
    Submit {
        multisig_submit_transaction: MultisigSubmitTransaction,
    },
    Confirm {
        multisig_confirm_transaction: models::MultisigConfirmTransaction,
    },
}

impl MultisigTransaction {
    pub fn from_core(multisig_transaction: models::MultisigTransaction) -> Self {
        match multisig_transaction {
            models::MultisigTransaction::Send(multisig_send_transaction) => Self::Send {
                multisig_send_transaction: MultisigSendTransaction::from_core(
                    multisig_send_transaction,
                ),
            },
            models::MultisigTransaction::Submit(multisig_submit_transaction) => Self::Submit {
                multisig_submit_transaction: MultisigSubmitTransaction::from_core(
                    multisig_submit_transaction,
                ),
            },
            models::MultisigTransaction::Confirm(multisig_confirm_transaction) => Self::Confirm {
                multisig_confirm_transaction,
            },
        }
    }
}

#[derive(Serialize)]
pub struct MultisigSubmitTransaction {
    #[serde(with = "serde_uint256")]
    pub custodian: UInt256,
    #[serde(with = "serde_address")]
    pub dest: MsgAddressInt,
    pub value: String,
    pub bounce: bool,
    pub all_balance: bool,
    #[serde(with = "serde_cell")]
    pub payload: ton_types::Cell,
    #[serde(with = "serde_string")]
    pub trans_id: u64,
}

impl MultisigSubmitTransaction {
    pub fn from_core(multisig_submit_transaction: models::MultisigSubmitTransaction) -> Self {
        Self {
            custodian: multisig_submit_transaction.custodian,
            dest: multisig_submit_transaction.dest,
            value: multisig_submit_transaction.value.to_string(),
            bounce: multisig_submit_transaction.bounce,
            all_balance: multisig_submit_transaction.all_balance,
            payload: multisig_submit_transaction.payload,
            trans_id: multisig_submit_transaction.trans_id,
        }
    }
}

#[derive(Serialize)]
pub struct MultisigSendTransaction {
    #[serde(with = "serde_address")]
    pub dest: MsgAddressInt,
    pub value: String,
    pub bounce: bool,
    pub flags: u8,
    #[serde(with = "serde_cell")]
    pub payload: ton_types::Cell,
}

impl MultisigSendTransaction {
    pub fn from_core(multisig_send_transaction: models::MultisigSendTransaction) -> Self {
        Self {
            dest: multisig_send_transaction.dest,
            value: multisig_send_transaction.value.to_string(),
            bounce: multisig_send_transaction.bounce,
            flags: multisig_send_transaction.flags,
            payload: multisig_send_transaction.payload,
        }
    }
}

#[derive(Serialize)]
pub struct MultisigPendingTransaction {
    #[serde(with = "serde_string")]
    pub id: u64,
    #[serde(with = "serde_vec_uint256")]
    pub confirmations: Vec<UInt256>,
    pub signs_required: u8,
    pub signs_received: u8,
    #[serde(with = "serde_uint256")]
    pub creator: UInt256,
    pub index: u8,
    #[serde(with = "serde_address")]
    pub dest: MsgAddressInt,
    pub value: String,
    pub send_flags: u16,
    #[serde(with = "serde_cell")]
    pub payload: ton_types::Cell,
    pub bounce: bool,
}

impl MultisigPendingTransaction {
    pub fn from_core(multisig_pending_transaction: models::MultisigPendingTransaction) -> Self {
        Self {
            id: multisig_pending_transaction.id,
            confirmations: multisig_pending_transaction.confirmations,
            signs_required: multisig_pending_transaction.signs_required,
            signs_received: multisig_pending_transaction.signs_received,
            creator: multisig_pending_transaction.creator,
            index: multisig_pending_transaction.index,
            dest: multisig_pending_transaction.dest,
            value: multisig_pending_transaction.value.to_string(),
            send_flags: multisig_pending_transaction.send_flags,
            payload: multisig_pending_transaction.payload,
            bounce: multisig_pending_transaction.bounce,
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
            contract_state: ContractState::from_core(existing_wallet_info.contract_state),
        }
    }

    pub fn to_core(self) -> ton_wallet::ExistingWalletInfo {
        ton_wallet::ExistingWalletInfo {
            address: self.address,
            public_key: self.public_key,
            wallet_type: self.wallet_type.to_core(),
            contract_state: self.contract_state.to_core(),
        }
    }
}
