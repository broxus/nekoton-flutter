use nekoton::core::keystore::KeyStore;
use std::fmt;
use tokio::sync::Mutex;

pub type MutexKeyStore = Mutex<Option<KeyStore>>;

#[derive(Debug)]
pub enum KeySigner {
    EncryptedKeySigner,
    DerivedKeySigner,
}

impl fmt::Display for KeySigner {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:?}", self)
    }
}
