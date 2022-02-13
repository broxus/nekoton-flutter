pub mod models;

use crate::{
    crypto::mnemonic::models::{GeneratedKey, Keypair, MnemonicType},
    models::{HandleError, MatchResult},
    FromPtr, ToPtr,
};
use anyhow::Result;
use nekoton::crypto::{self, dict};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_ulonglong},
};

#[no_mangle]
pub unsafe extern "C" fn generate_key(mnemonic_type: *mut c_char) -> *mut c_void {
    fn internal_fn(mnemonic_type: *mut c_char) -> Result<u64, String> {
        let mnemonic_type = mnemonic_type.from_ptr();
        let mnemonic_type = serde_json::from_str::<MnemonicType>(&mnemonic_type)
            .handle_error()?
            .to_core();

        let generated_key = crypto::generate_key(mnemonic_type)
            .map(|e| GeneratedKey::from_core(e))
            .handle_error()?;

        let result = serde_json::to_string(&generated_key)
            .handle_error()?
            .to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(mnemonic_type).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn get_hints(input: *mut c_char) -> *mut c_void {
    fn internal_fn(input: *mut c_char) -> Result<u64, String> {
        let input = input.from_ptr();

        let hints = dict::get_hints(&input);
        let hints = serde_json::to_string(&hints).handle_error()?.to_ptr() as c_ulonglong;

        Ok(hints)
    }

    internal_fn(input).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn derive_from_phrase(
    phrase: *mut c_char,
    mnemonic_type: *mut c_char,
) -> *mut c_void {
    fn internal_fn(phrase: *mut c_char, mnemonic_type: *mut c_char) -> Result<u64, String> {
        let phrase = phrase.from_ptr();

        let mnemonic_type = mnemonic_type.from_ptr();
        let mnemonic_type = serde_json::from_str::<MnemonicType>(&mnemonic_type)
            .handle_error()?
            .to_core();

        let keypair = crypto::derive_from_phrase(&phrase, mnemonic_type)
            .map(|e| Keypair::from_core(e))
            .handle_error()?;

        let keypair = serde_json::to_string(&keypair).handle_error()?.to_ptr() as c_ulonglong;

        Ok(keypair)
    }

    internal_fn(phrase, mnemonic_type).match_result()
}
