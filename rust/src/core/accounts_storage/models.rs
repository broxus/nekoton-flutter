use std::collections::HashMap;

use nekoton::core::{
    accounts_storage::{AccountToAdd, AdditionalAssets, AssetsList, NetworkGroup, TonWalletAsset},
    ton_wallet::WalletType,
};
use nekoton_utils::{serde_address, serde_optional_address, serde_public_key};
use serde::{Deserialize, Serialize};
use ton_block::MsgAddressInt;

use crate::core::ton_wallet::models::WalletTypeDef;

#[derive(Deserialize)]
pub struct AccountToAddHelper(#[serde(with = "AccountToAddDef")] pub AccountToAdd);

#[derive(Deserialize)]
#[serde(remote = "AccountToAdd", rename_all = "camelCase")]
pub struct AccountToAddDef {
    pub name: String,
    #[serde(with = "serde_public_key")]
    pub public_key: ed25519_dalek::PublicKey,
    #[serde(with = "WalletTypeDef")]
    pub contract: WalletType,
    pub workchain: i8,
    #[serde(
        with = "serde_optional_address",
        skip_serializing_if = "Option::is_none"
    )]
    pub explicit_address: Option<MsgAddressInt>,
}

#[derive(Serialize)]
pub struct AssetsListHelper(#[serde(with = "AssetsListDef")] pub AssetsList);

#[derive(Serialize)]
#[serde(remote = "AssetsList", rename_all = "camelCase")]
pub struct AssetsListDef {
    pub name: String,
    #[serde(with = "TonWalletAssetDef")]
    pub ton_wallet: TonWalletAsset,
    pub additional_assets: HashMap<NetworkGroup, AdditionalAssets>,
}

#[derive(Serialize)]
#[serde(remote = "TonWalletAsset", rename_all = "camelCase")]
pub struct TonWalletAssetDef {
    #[serde(with = "serde_address")]
    pub address: MsgAddressInt,
    #[serde(with = "serde_public_key")]
    pub public_key: ed25519_dalek::PublicKey,
    #[serde(with = "WalletTypeDef")]
    pub contract: WalletType,
}
