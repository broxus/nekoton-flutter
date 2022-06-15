use nekoton::core::{
    models::ContractState,
    ton_wallet::{ExistingWalletInfo, MultisigType, WalletType},
};
use nekoton_utils::{serde_address, serde_public_key};
use serde::{Deserialize, Serialize};
use ton_block::MsgAddressInt;

#[derive(Serialize, Deserialize)]
pub struct WalletTypeHelper(#[serde(with = "WalletTypeDef")] pub WalletType);

#[derive(Serialize, Deserialize)]
#[serde(
    remote = "WalletType",
    rename_all = "camelCase",
    tag = "type",
    content = "data"
)]
pub enum WalletTypeDef {
    Multisig(MultisigType),
    WalletV3,
    HighloadWalletV2,
}

#[derive(Serialize, Deserialize)]
pub struct ExistingWalletInfoHelper(
    #[serde(with = "ExistingWalletInfoDef")] pub ExistingWalletInfo,
);

#[derive(Serialize, Deserialize)]
#[serde(remote = "ExistingWalletInfo", rename_all = "camelCase")]
pub struct ExistingWalletInfoDef {
    #[serde(with = "serde_address")]
    pub address: MsgAddressInt,
    #[serde(with = "serde_public_key")]
    pub public_key: ed25519_dalek::PublicKey,
    #[serde(with = "WalletTypeDef")]
    pub wallet_type: WalletType,
    pub contract_state: ContractState,
}
