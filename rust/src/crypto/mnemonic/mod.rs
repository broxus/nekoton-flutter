pub mod models;

use crate::{
    crypto::mnemonic::models::{GeneratedKey, Keypair, MnemonicType},
    models::{HandleError, MatchResult},
    ToPtr, ToStringFromPtr,
};
use anyhow::Result;
use nekoton::crypto::{self, dict};
use std::{ffi::c_void, os::raw::c_char};

#[no_mangle]
pub unsafe extern "C" fn generate_key(mnemonic_type: *mut c_char) -> *mut c_void {
    let mnemonic_type = mnemonic_type.to_string_from_ptr();

    fn internal_fn(mnemonic_type: String) -> Result<u64, String> {
        let mnemonic_type = serde_json::from_str::<MnemonicType>(&mnemonic_type)
            .handle_error()?
            .to_core();

        let generated_key = crypto::generate_key(mnemonic_type)
            .map(GeneratedKey::from_core)
            .handle_error()?;

        let result = serde_json::to_string(&generated_key)
            .handle_error()?
            .to_ptr() as u64;

        Ok(result)
    }

    internal_fn(mnemonic_type).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn get_hints(input: *mut c_char) -> *mut c_void {
    let input = input.to_string_from_ptr();

    fn internal_fn(input: String) -> Result<u64, String> {
        let hints = dict::get_hints(&input);
        let hints = serde_json::to_string(&hints).handle_error()?.to_ptr() as u64;

        Ok(hints)
    }

    internal_fn(input).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn derive_from_phrase(
    phrase: *mut c_char,
    mnemonic_type: *mut c_char,
) -> *mut c_void {
    let phrase = phrase.to_string_from_ptr();
    let mnemonic_type = mnemonic_type.to_string_from_ptr();

    fn internal_fn(phrase: String, mnemonic_type: String) -> Result<u64, String> {
        let mnemonic_type = serde_json::from_str::<MnemonicType>(&mnemonic_type)
            .handle_error()?
            .to_core();

        let keypair = crypto::derive_from_phrase(&phrase, mnemonic_type)
            .map(Keypair::from_core)
            .handle_error()?;

        let keypair = serde_json::to_string(&keypair).handle_error()?.to_ptr() as u64;

        Ok(keypair)
    }

    internal_fn(phrase, mnemonic_type).match_result()
}
