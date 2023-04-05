use nekoton::crypto;
use nekoton_utils::serde_public_key;
use secstr::SecUtf8;
use serde::Deserialize;

use crate::{crypto::password_cache::Password, models::ToNekoton};

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum DerivedKeyCreateInput {
    Import {
        key_name: Option<String>,
        phrase: SecUtf8,
        password: Password,
    },
    Derive {
        key_name: Option<String>,
        #[serde(with = "serde_public_key")]
        master_key: ed25519_dalek::PublicKey,
        account_id: u16,
        password: Password,
    },
}

impl ToNekoton<crypto::DerivedKeyCreateInput> for DerivedKeyCreateInput {
    fn to_nekoton(self) -> crypto::DerivedKeyCreateInput {
        match self {
            DerivedKeyCreateInput::Import {
                key_name,
                phrase,
                password,
            } => crypto::DerivedKeyCreateInput::Import {
                key_name,
                phrase,
                password: password.to_nekoton(),
            },
            DerivedKeyCreateInput::Derive {
                key_name,
                master_key,
                account_id,
                password,
            } => crypto::DerivedKeyCreateInput::Derive {
                key_name,
                master_key,
                account_id,
                password: password.to_nekoton(),
            },
        }
    }
}

#[derive(Deserialize)]
pub struct DerivedKeyExportSeedParams {
    #[serde(with = "serde_public_key")]
    pub master_key: ed25519_dalek::PublicKey,
    pub password: Password,
}

impl ToNekoton<crypto::DerivedKeyExportSeedParams> for DerivedKeyExportSeedParams {
    fn to_nekoton(self) -> crypto::DerivedKeyExportSeedParams {
        crypto::DerivedKeyExportSeedParams {
            master_key: self.master_key,
            password: self.password.to_nekoton(),
        }
    }
}

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum DerivedKeyUpdateParams {
    RenameKey {
        #[serde(with = "serde_public_key")]
        master_key: ed25519_dalek::PublicKey,
        #[serde(with = "serde_public_key")]
        public_key: ed25519_dalek::PublicKey,
        name: String,
    },
    ChangePassword {
        #[serde(with = "serde_public_key")]
        master_key: ed25519_dalek::PublicKey,
        old_password: Password,
        new_password: Password,
    },
}

impl ToNekoton<crypto::DerivedKeyUpdateParams> for DerivedKeyUpdateParams {
    fn to_nekoton(self) -> crypto::DerivedKeyUpdateParams {
        match self {
            DerivedKeyUpdateParams::RenameKey {
                master_key,
                public_key,
                name,
            } => crypto::DerivedKeyUpdateParams::RenameKey {
                master_key,
                public_key,
                name,
            },
            DerivedKeyUpdateParams::ChangePassword {
                master_key,
                old_password,
                new_password,
            } => crypto::DerivedKeyUpdateParams::ChangePassword {
                master_key,
                old_password: old_password.to_nekoton(),
                new_password: new_password.to_nekoton(),
            },
        }
    }
}

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum DerivedKeyPassword {
    ByAccountId {
        #[serde(with = "serde_public_key")]
        master_key: ed25519_dalek::PublicKey,
        account_id: u16,
        password: Password,
    },
    ByPublicKey {
        #[serde(with = "serde_public_key")]
        master_key: ed25519_dalek::PublicKey,
        #[serde(with = "serde_public_key")]
        public_key: ed25519_dalek::PublicKey,
        password: Password,
    },
}

impl ToNekoton<crypto::DerivedKeyPassword> for DerivedKeyPassword {
    fn to_nekoton(self) -> crypto::DerivedKeyPassword {
        match self {
            DerivedKeyPassword::ByAccountId {
                master_key,
                account_id,
                password,
            } => crypto::DerivedKeyPassword::ByAccountId {
                master_key,
                account_id,
                password: password.to_nekoton(),
            },
            DerivedKeyPassword::ByPublicKey {
                master_key,
                public_key,
                password,
            } => crypto::DerivedKeyPassword::ByPublicKey {
                master_key,
                public_key,
                password: password.to_nekoton(),
            },
        }
    }
}
