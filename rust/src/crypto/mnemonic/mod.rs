pub mod models;

use std::os::raw::c_char;

use anyhow::Result;
use nekoton::crypto::{derive_from_phrase, dict, generate_key};

use crate::{
    crypto::mnemonic::models::{GeneratedKeyHelper, KeypairHelper, MnemonicTypeHelper},
    HandleError, MatchResult, ToStringFromPtr,
};

#[no_mangle]
pub unsafe extern "C" fn nt_generate_key(mnemonic_type: *mut c_char) -> *mut c_char {
    let mnemonic_type = mnemonic_type.to_string_from_ptr();

    fn internal_fn(mnemonic_type: String) -> Result<serde_json::Value, String> {
        let mnemonic_type = serde_json::from_str::<MnemonicTypeHelper>(&mnemonic_type)
            .map(|MnemonicTypeHelper(mnemonic_type)| mnemonic_type)
            .handle_error()?;

        let generated_key = generate_key(mnemonic_type);

        serde_json::to_value(GeneratedKeyHelper(generated_key)).handle_error()
    }

    internal_fn(mnemonic_type).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_hints(input: *mut c_char) -> *mut c_char {
    let input = input.to_string_from_ptr();

    fn internal_fn(input: String) -> Result<serde_json::Value, String> {
        let hints = dict::get_hints(&input);

        serde_json::to_value(hints).handle_error()
    }

    internal_fn(input).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_derive_from_phrase(
    phrase: *mut c_char,
    mnemonic_type: *mut c_char,
) -> *mut c_char {
    let phrase = phrase.to_string_from_ptr();
    let mnemonic_type = mnemonic_type.to_string_from_ptr();

    fn internal_fn(phrase: String, mnemonic_type: String) -> Result<serde_json::Value, String> {
        let mnemonic_type = serde_json::from_str::<MnemonicTypeHelper>(&mnemonic_type)
            .map(|MnemonicTypeHelper(mnemonic_type)| mnemonic_type)
            .handle_error()?;

        let keypair = derive_from_phrase(&phrase, mnemonic_type).handle_error()?;

        serde_json::to_value(KeypairHelper(keypair)).handle_error()
    }

    internal_fn(phrase, mnemonic_type).match_result()
}
