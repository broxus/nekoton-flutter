use std::time::Duration;

use nekoton::crypto;
use secstr::SecUtf8;
use serde::Deserialize;

use crate::models::ToNekoton;

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum Password {
    Explicit {
        password: SecUtf8,
        cache_behavior: PasswordCacheBehavior,
    },
    FromCache,
}

impl ToNekoton<crypto::Password> for Password {
    fn to_nekoton(self) -> crypto::Password {
        match self {
            Password::Explicit {
                password,
                cache_behavior,
            } => crypto::Password::Explicit {
                password,
                cache_behavior: cache_behavior.to_nekoton(),
            },
            Password::FromCache => crypto::Password::FromCache,
        }
    }
}

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum PasswordCacheBehavior {
    Store { duration: u64 },
    Remove,
}

impl ToNekoton<crypto::PasswordCacheBehavior> for PasswordCacheBehavior {
    fn to_nekoton(self) -> crypto::PasswordCacheBehavior {
        match self {
            PasswordCacheBehavior::Store { duration } => {
                crypto::PasswordCacheBehavior::Store(Duration::from_millis(duration))
            }
            PasswordCacheBehavior::Remove => crypto::PasswordCacheBehavior::Remove,
        }
    }
}
