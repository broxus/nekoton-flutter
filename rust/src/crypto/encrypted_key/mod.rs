use nekoton::crypto;
use nekoton_utils::serde_public_key;
use secstr::SecUtf8;
use serde::{Deserialize, Serialize};

use crate::{
    crypto::{mnemonic::models::MnemonicType, password_cache::Password},
    models::{ToNekoton, ToSerializable},
};

#[derive(Deserialize)]
pub struct EncryptedKeyCreateInput {
    pub name: Option<String>,
    pub phrase: SecUtf8,
    pub mnemonic_type: MnemonicType,
    pub password: Password,
}

impl ToNekoton<crypto::EncryptedKeyCreateInput> for EncryptedKeyCreateInput {
    fn to_nekoton(self) -> crypto::EncryptedKeyCreateInput {
        crypto::EncryptedKeyCreateInput {
            name: self.name,
            phrase: self.phrase,
            mnemonic_type: self.mnemonic_type.to_nekoton(),
            password: self.password.to_nekoton(),
        }
    }
}

#[derive(Serialize)]
pub struct EncryptedKeyExportOutput {
    pub phrase: SecUtf8,
    pub mnemonic_type: MnemonicType,
}

impl ToSerializable<EncryptedKeyExportOutput> for crypto::EncryptedKeyExportOutput {
    fn to_serializable(self) -> EncryptedKeyExportOutput {
        EncryptedKeyExportOutput {
            phrase: self.phrase,
            mnemonic_type: self.mnemonic_type.to_serializable(),
        }
    }
}

#[derive(Deserialize)]
pub struct EncryptedKeyPassword {
    #[serde(with = "serde_public_key")]
    pub public_key: ed25519_dalek::PublicKey,
    pub password: Password,
}

impl ToNekoton<crypto::EncryptedKeyPassword> for EncryptedKeyPassword {
    fn to_nekoton(self) -> crypto::EncryptedKeyPassword {
        crypto::EncryptedKeyPassword {
            public_key: self.public_key,
            password: self.password.to_nekoton(),
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

impl ToNekoton<crypto::EncryptedKeyUpdateParams> for EncryptedKeyUpdateParams {
    fn to_nekoton(self) -> crypto::EncryptedKeyUpdateParams {
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
                old_password: old_password.to_nekoton(),
                new_password: new_password.to_nekoton(),
            },
        }
    }
}
