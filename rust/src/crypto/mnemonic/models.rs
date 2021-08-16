use nekoton::crypto;
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
pub struct GeneratedKey {
    pub words: Vec<String>,
    pub mnemonic_type: MnemonicType,
}

impl GeneratedKey {
    pub fn from_core(generated_key: crypto::GeneratedKey) -> Self {
        Self {
            words: generated_key.words,
            mnemonic_type: MnemonicType::from_core(generated_key.account_type),
        }
    }
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "runtimeType")]
pub enum MnemonicType {
    Legacy,
    Labs { id: u16 },
}

impl MnemonicType {
    pub fn from_core(mnemonic_type: crypto::MnemonicType) -> Self {
        match mnemonic_type {
            crypto::MnemonicType::Legacy => Self::Legacy,
            crypto::MnemonicType::Labs(id) => Self::Labs { id },
        }
    }

    pub fn to_core(self) -> crypto::MnemonicType {
        match self {
            MnemonicType::Legacy => crypto::MnemonicType::Legacy,
            MnemonicType::Labs { id } => crypto::MnemonicType::Labs(id),
        }
    }
}

#[derive(Serialize)]
pub struct Keypair {
    pub secret: String,
    pub public: String,
}
