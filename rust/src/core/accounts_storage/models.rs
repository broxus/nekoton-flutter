use std::collections::HashMap;

use nekoton::core::accounts_storage::{self, AdditionalAssets};
use nekoton_utils::{serde_address, serde_optional_address, serde_public_key};
use serde::{Deserialize, Serialize};
use ton_block::MsgAddressInt;

use crate::{
    core::ton_wallet::models::WalletType,
    models::{ToNekoton, ToSerializable},
};

#[derive(Serialize, Deserialize)]
pub struct AccountToAdd {
    pub name: String,
    #[serde(with = "serde_public_key")]
    pub public_key: ed25519_dalek::PublicKey,
    pub contract: WalletType,
    pub workchain: i8,
    #[serde(with = "serde_optional_address")]
    pub explicit_address: Option<MsgAddressInt>,
}

impl ToNekoton<accounts_storage::AccountToAdd> for AccountToAdd {
    fn to_nekoton(self) -> accounts_storage::AccountToAdd {
        accounts_storage::AccountToAdd {
            name: self.name,
            public_key: self.public_key,
            contract: self.contract.to_nekoton(),
            workchain: self.workchain,
            explicit_address: self.explicit_address,
        }
    }
}

impl ToSerializable<AccountToAdd> for accounts_storage::AccountToAdd {
    fn to_serializable(self) -> AccountToAdd {
        AccountToAdd {
            name: self.name,
            public_key: self.public_key,
            contract: self.contract.to_serializable(),
            workchain: self.workchain,
            explicit_address: self.explicit_address,
        }
    }
}

#[derive(Serialize)]
pub struct AssetsList {
    pub name: String,
    pub ton_wallet: TonWalletAsset,
    pub additional_assets: HashMap<String, AdditionalAssets>,
}

impl ToSerializable<AssetsList> for accounts_storage::AssetsList {
    fn to_serializable(self) -> AssetsList {
        AssetsList {
            name: self.name,
            ton_wallet: self.ton_wallet.to_serializable(),
            additional_assets: self.additional_assets,
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

impl ToSerializable<TonWalletAsset> for accounts_storage::TonWalletAsset {
    fn to_serializable(self) -> TonWalletAsset {
        TonWalletAsset {
            address: self.address,
            public_key: self.public_key,
            contract: self.contract.to_serializable(),
        }
    }
}
