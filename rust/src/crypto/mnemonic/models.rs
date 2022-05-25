use nekoton::crypto;
use nekoton_utils::{serde_public_key, serde_secret_key};
use serde::{Deserialize, Serialize};

use crate::models::{ToNekoton, ToSerializable};

#[derive(Serialize)]
pub struct GeneratedKey {
    pub words: Vec<String>,
    pub account_type: MnemonicType,
}

impl ToSerializable<GeneratedKey> for crypto::GeneratedKey {
    fn to_serializable(self) -> GeneratedKey {
        GeneratedKey {
            words: self.words,
            account_type: self.account_type.to_serializable(),
        }
    }
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "runtimeType")]
pub enum MnemonicType {
    Legacy,
    Labs { id: u16 },
}

impl ToSerializable<MnemonicType> for crypto::MnemonicType {
    fn to_serializable(self) -> MnemonicType {
        match self {
            crypto::MnemonicType::Legacy => MnemonicType::Legacy,
            crypto::MnemonicType::Labs(id) => MnemonicType::Labs { id },
        }
    }
}

impl ToNekoton<crypto::MnemonicType> for MnemonicType {
    fn to_nekoton(self) -> crypto::MnemonicType {
        match self {
            MnemonicType::Legacy => crypto::MnemonicType::Legacy,
            MnemonicType::Labs { id } => crypto::MnemonicType::Labs(id),
        }
    }
}

#[derive(Serialize)]
pub struct Keypair {
    #[serde(with = "serde_public_key")]
    pub public: ed25519_dalek::PublicKey,
    #[serde(with = "serde_secret_key")]
    pub secret: ed25519_dalek::SecretKey,
}

impl ToSerializable<Keypair> for ed25519_dalek::Keypair {
    fn to_serializable(self) -> Keypair {
        Keypair {
            public: self.public,
            secret: self.secret,
        }
    }
}
