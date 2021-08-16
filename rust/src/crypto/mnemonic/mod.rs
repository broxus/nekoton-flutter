pub mod models;

use crate::{
    crypto::mnemonic::models::{GeneratedKey, Keypair, MnemonicType},
    match_result,
    models::{NativeError, NativeStatus},
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
    let result = internal_generate_key(mnemonic_type);
    match_result(result)
}

fn internal_generate_key(mnemonic_type: *mut c_char) -> Result<u64, NativeError> {
    let mnemonic_type = mnemonic_type.from_ptr();
    let mnemonic_type =
        serde_json::from_str::<MnemonicType>(&mnemonic_type).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?;
    let mnemonic_type = mnemonic_type.to_core();
    let generated_key = crypto::generate_key(mnemonic_type).map_err(|e| NativeError {
        status: NativeStatus::CryptoError,
        info: e.to_string(),
    })?;
    let generated_key = GeneratedKey::from_core(generated_key);

    let result = serde_json::to_string(&generated_key).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_hints(input: *mut c_char) -> *mut c_void {
    let result = internal_get_hints(input);
    match_result(result)
}

fn internal_get_hints(input: *mut c_char) -> Result<u64, NativeError> {
    let input = input.from_ptr();
    let hints = dict::get_hints(&input);
    let hints = serde_json::to_string(&hints).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

    Ok(hints.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn derive_from_phrase(
    phrase: *mut c_char,
    mnemonic_type: *mut c_char,
) -> *mut c_void {
    let result = internal_derive_from_phrase(phrase, mnemonic_type);
    match_result(result)
}

fn internal_derive_from_phrase(
    phrase: *mut c_char,
    mnemonic_type: *mut c_char,
) -> Result<u64, NativeError> {
    let phrase = phrase.from_ptr();

    let mnemonic_type = mnemonic_type.from_ptr();
    let mnemonic_type =
        serde_json::from_str::<MnemonicType>(&mnemonic_type).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?;
    let mnemonic_type = mnemonic_type.to_core();

    let keypair = crypto::derive_from_phrase(&phrase, mnemonic_type).map_err(|e| NativeError {
        status: NativeStatus::CryptoError,
        info: e.to_string(),
    })?;

    let secret = hex::encode(keypair.secret.to_bytes());
    let public = hex::encode(keypair.public.to_bytes());

    let keypair = Keypair { secret, public };
    let keypair = serde_json::to_string(&keypair).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

    Ok(keypair.to_ptr() as c_ulonglong)
}
