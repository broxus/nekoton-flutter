use crate::core::ton_wallet::models::WalletType;
use nekoton::core::accounts_storage::{self, AccountsStorage, AdditionalAssets};
use nekoton_utils::{serde_address, serde_public_key};
use serde::Serialize;
use std::collections::HashMap;
use tokio::sync::Mutex;
use ton_block::MsgAddressInt;

pub type MutexAccountsStorage = Mutex<Option<AccountsStorage>>;

#[derive(Serialize)]
pub struct AssetsList {
    pub name: String,
    pub ton_wallet: TonWalletAsset,
    pub additional_assets: HashMap<String, AdditionalAssets>,
}

impl AssetsList {
    pub fn from_core(assets_list: accounts_storage::AssetsList) -> Self {
        Self {
            name: assets_list.name,
            ton_wallet: TonWalletAsset::from_core(assets_list.ton_wallet),
            additional_assets: assets_list.additional_assets,
        }
    }
}

#[derive(Serialize)]
pub struct TonWalletAsset {
    #[serde(with = "serde_address")]
    pub address: MsgAddressInt,
    #[serde(with = "serde_public_key")]
    pub public_key: ed25519_dalek::PublicKey,
    pub contract: WalletType,
}

impl TonWalletAsset {
    pub fn from_core(ton_wallet_asset: accounts_storage::TonWalletAsset) -> Self {
        Self {
            address: ton_wallet_asset.address,
            public_key: ton_wallet_asset.public_key,
            contract: WalletType::from_core(ton_wallet_asset.contract),
        }
    }
}
