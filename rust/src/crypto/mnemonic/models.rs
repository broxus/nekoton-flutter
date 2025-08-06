use nekoton::crypto::{Bip39MnemonicData, GeneratedKey, MnemonicType};
use nekoton_utils::{serde_public_key, serde_secret_key};
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
pub struct GeneratedKeyHelper(#[serde(with = "GeneratedKeyDef")] pub GeneratedKey);

#[derive(Serialize)]
#[serde(remote = "GeneratedKey", rename_all = "camelCase")]
pub struct GeneratedKeyDef {
    pub words: Vec<&'static str>,
    #[serde(with = "MnemonicTypeDef")]
    pub account_type: MnemonicType,
}

#[derive(Serialize, Deserialize)]
pub struct MnemonicTypeHelper(#[serde(with = "MnemonicTypeDef")] pub MnemonicType);

#[derive(Serialize, Deserialize)]
#[serde(
    remote = "MnemonicType",
    rename_all = "camelCase",
    tag = "type",
    content = "data"
)]
pub enum MnemonicTypeDef {
    Legacy,
    Bip39(Bip39MnemonicData),
}

#[derive(Serialize)]
pub struct KeypairHelper(#[serde(with = "KeypairDef")] pub ed25519_dalek::Keypair);

#[derive(Serialize)]
#[serde(remote = "ed25519_dalek::Keypair")]
pub struct KeypairDef {
    #[serde(with = "serde_public_key")]
    pub public: ed25519_dalek::PublicKey,
    #[serde(with = "serde_secret_key")]
    pub secret: ed25519_dalek::SecretKey,
}
