use super::mnemonic::models::MnemonicType;
use crate::crypto::password_cache::Password;
use nekoton::crypto;
use nekoton_utils::serde_public_key;
use secstr::SecUtf8;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct EncryptedKeyCreateInput {
    pub name: Option<String>,
    pub phrase: SecUtf8,
    pub mnemonic_type: MnemonicType,
    pub password: Password,
}

impl EncryptedKeyCreateInput {
    pub fn to_core(self) -> crypto::EncryptedKeyCreateInput {
        crypto::EncryptedKeyCreateInput {
            name: self.name,
            phrase: self.phrase,
            mnemonic_type: self.mnemonic_type.to_core(),
            password: self.password.to_core(),
        }
    }
}

#[derive(Serialize)]
pub struct EncryptedKeyExportOutput {
    pub phrase: SecUtf8,
    pub mnemonic_type: MnemonicType,
}

impl EncryptedKeyExportOutput {
    pub fn from_core(encrypted_key_export_output: crypto::EncryptedKeyExportOutput) -> Self {
        Self {
            phrase: encrypted_key_export_output.phrase,
            mnemonic_type: MnemonicType::from_core(encrypted_key_export_output.mnemonic_type),
        }
    }
}

#[derive(Deserialize)]
pub struct EncryptedKeyPassword {
    #[serde(with = "serde_public_key")]
    pub public_key: ed25519_dalek::PublicKey,
    pub password: Password,
}

impl EncryptedKeyPassword {
    pub fn to_core(self) -> crypto::EncryptedKeyPassword {
        crypto::EncryptedKeyPassword {
            public_key: self.public_key,
            password: self.password.to_core(),
        }
    }
}

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum EncryptedKeyUpdateParams {
    Rename {
        #[serde(with = "serde_public_key")]
        public_key: ed25519_dalek::PublicKey,
        name: String,
    },
    ChangePassword {
        #[serde(with = "serde_public_key")]
        public_key: ed25519_dalek::PublicKey,
        old_password: Password,
        new_password: Password,
    },
}

impl EncryptedKeyUpdateParams {
    pub fn to_core(self) -> crypto::EncryptedKeyUpdateParams {
        match self {
            EncryptedKeyUpdateParams::Rename { public_key, name } => {
                crypto::EncryptedKeyUpdateParams::Rename { public_key, name }
            }
            EncryptedKeyUpdateParams::ChangePassword {
                public_key,
                old_password,
                new_password,
            } => crypto::EncryptedKeyUpdateParams::ChangePassword {
                public_key,
                old_password: old_password.to_core(),
                new_password: new_password.to_core(),
            },
        }
    }
}
