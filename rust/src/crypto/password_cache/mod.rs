use nekoton::crypto;
use secstr::SecUtf8;
use serde::Deserialize;
use std::time::Duration;

#[derive(Deserialize)]
#[serde(tag = "runtimeType")]
pub enum Password {
    Explicit {
        password: SecUtf8,
        cache_behavior: PasswordCacheBehavior,
    },
    FromCache,
}

impl Password {
    pub fn to_core(self) -> crypto::Password {
        match self {
            Password::Explicit {
                password,
                cache_behavior,
            } => crypto::Password::Explicit {
                password,
                cache_behavior: cache_behavior.to_core(),
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

impl PasswordCacheBehavior {
    pub fn to_core(self) -> crypto::PasswordCacheBehavior {
        match self {
            PasswordCacheBehavior::Store { duration } => {
                crypto::PasswordCacheBehavior::Store(Duration::from_millis(duration))
            }
            PasswordCacheBehavior::Remove => crypto::PasswordCacheBehavior::Remove,
        }
    }
}
