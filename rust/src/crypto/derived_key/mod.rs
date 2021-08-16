use crate::crypto::password_cache::Password;
use nekoton::crypto;
use nekoton_utils::serde_public_key;
use secstr::SecUtf8;
use serde::Deserialize;

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

impl DerivedKeyCreateInput {
    pub fn to_core(self) -> crypto::DerivedKeyCreateInput {
        match self {
            DerivedKeyCreateInput::Import {
                key_name,
                phrase,
                password,
            } => crypto::DerivedKeyCreateInput::Import {
                key_name,
                phrase,
                password: password.to_core(),
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
                password: password.to_core(),
            },
        }
    }
}

#[derive(Deserialize)]
pub struct DerivedKeyExportParams {
    #[serde(with = "serde_public_key")]
    pub master_key: ed25519_dalek::PublicKey,
    pub password: Password,
}

impl DerivedKeyExportParams {
    pub fn to_core(self) -> crypto::DerivedKeyExportParams {
        crypto::DerivedKeyExportParams {
            master_key: self.master_key,
            password: self.password.to_core(),
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

impl DerivedKeyUpdateParams {
    pub fn to_core(self) -> crypto::DerivedKeyUpdateParams {
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
                old_password: old_password.to_core(),
                new_password: new_password.to_core(),
            },
        }
    }
}

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum DerivedKeySignParams {
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

impl DerivedKeySignParams {
    pub fn to_core(self) -> crypto::DerivedKeySignParams {
        match self {
            DerivedKeySignParams::ByAccountId {
                master_key,
                account_id,
                password,
            } => crypto::DerivedKeySignParams::ByAccountId {
                master_key,
                account_id,
                password: password.to_core(),
            },
            DerivedKeySignParams::ByPublicKey {
                master_key,
                public_key,
                password,
            } => crypto::DerivedKeySignParams::ByPublicKey {
                master_key,
                public_key,
                password: password.to_core(),
            },
        }
    }
}
