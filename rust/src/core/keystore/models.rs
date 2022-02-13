use std::fmt;

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
