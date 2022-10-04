use nekoton::crypto::{EncryptedKeyCreateInput, EncryptedKeyExportOutput, MnemonicType, Password};
use secstr::SecUtf8;
use serde::{Deserialize, Serialize};

use super::mnemonic::models::MnemonicTypeDef;

pub const ENCRYPTED_KEY_SIGNER_NAME: &str = "EncryptedKeySigner";

#[derive(Deserialize)]
pub struct EncryptedKeyCreateInputHelper(
    #[serde(with = "EncryptedKeyCreateInputDef")] pub EncryptedKeyCreateInput,
);

#[derive(Deserialize)]
#[serde(remote = "EncryptedKeyCreateInput", rename_all = "camelCase")]
pub struct EncryptedKeyCreateInputDef {
    pub name: Option<String>,
    pub phrase: SecUtf8,
    #[serde(with = "MnemonicTypeDef")]
    pub mnemonic_type: MnemonicType,
    pub password: Password,
}

#[derive(Serialize)]
pub struct EncryptedKeyExportOutputHelper(
    #[serde(with = "EncryptedKeyExportOutputDef")] pub EncryptedKeyExportOutput,
);

#[derive(Serialize)]
#[serde(remote = "EncryptedKeyExportOutput", rename_all = "camelCase")]
pub struct EncryptedKeyExportOutputDef {
    pub phrase: SecUtf8,
    #[serde(with = "MnemonicTypeDef")]
    pub mnemonic_type: MnemonicType,
}
