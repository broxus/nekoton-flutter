pub(crate) mod derived_key;
pub(crate) mod encrypted_key;
mod mnemonic;
pub(crate) mod models;
mod password_cache;

use std::{
    ffi::{c_char, c_longlong, c_void},
    sync::Arc,
};

use ed25519_dalek::*;
use nekoton::crypto::UnsignedMessage;
use tokio::sync::RwLock;

use crate::{
    models::{HandleError, MatchResult, ToSerializable, ToStringFromPtr},
    parse_public_key, runtime, send_to_result_port, ToCStringPtr, CLOCK, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_refresh_timeout(
    result_port: c_longlong,
    unsigned_message: *mut c_void,
) {
    let unsigned_message = unsigned_message_from_ptr(unsigned_message);

    runtime!().spawn(async move {
        fn internal_fn(unsigned_message: &mut Box<dyn UnsignedMessage>) -> Result<u64, String> {
            unsigned_message.refresh_timeout(CLOCK.as_ref());

            Ok(u64::default())
        }

        let mut unsigned_message = unsigned_message.write().await;

        let result = internal_fn(&mut unsigned_message).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_expire_at(
    result_port: c_longlong,
    unsigned_message: *mut c_void,
) {
    let unsigned_message = unsigned_message_from_ptr(unsigned_message);

    runtime!().spawn(async move {
        fn internal_fn(unsigned_message: &Box<dyn UnsignedMessage>) -> Result<u64, String> {
            let expire_at = unsigned_message.expire_at() as u64;

            Ok(expire_at)
        }

        let unsigned_message = unsigned_message.read().await;

        let result = internal_fn(&unsigned_message).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_hash(
    result_port: c_longlong,
    unsigned_message: *mut c_void,
) {
    let unsigned_message = unsigned_message_from_ptr(unsigned_message);

    runtime!().spawn(async move {
        fn internal_fn(unsigned_message: &Box<dyn UnsignedMessage>) -> Result<u64, String> {
            let hash = unsigned_message.hash();

            let hash = base64::encode(&hash).to_cstring_ptr() as u64;

            Ok(hash)
        }

        let unsigned_message = unsigned_message.read().await;

        let result = internal_fn(&unsigned_message).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_sign(
    result_port: c_longlong,
    unsigned_message: *mut c_void,
    signature: *mut c_char,
) {
    let unsigned_message = unsigned_message_from_ptr(unsigned_message);

    let signature = signature.to_string_from_ptr();

    runtime!().spawn(async move {
        fn internal_fn(
            unsigned_message: &Box<dyn UnsignedMessage>,
            signature: String,
        ) -> Result<u64, String> {
            let signature: [u8; 64] = base64::decode(&signature)
                .handle_error()?
                .as_slice()
                .try_into()
                .handle_error()?;

            let signed_message = unsigned_message
                .sign(&signature)
                .handle_error()?
                .to_serializable();

            let signed_message = serde_json::to_string(&signed_message)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(signed_message)
        }

        let unsigned_message = unsigned_message.read().await;

        let result = internal_fn(&unsigned_message, signature).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(
        &*(ptr as *mut Arc<RwLock<Box<dyn UnsignedMessage>>>),
    )) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<RwLock<Box<dyn UnsignedMessage>>>);
}

unsafe fn unsigned_message_from_ptr(ptr: *mut c_void) -> Arc<RwLock<Box<dyn UnsignedMessage>>> {
    Arc::from_raw(ptr as *mut RwLock<Box<dyn UnsignedMessage>>)
}

#[no_mangle]
pub unsafe extern "C" fn nt_verify_signature(
    public_key: *mut c_char,
    data_hash: *mut c_char,
    signature: *mut c_char,
) -> *mut c_void {
    let public_key = public_key.to_string_from_ptr();
    let data_hash = data_hash.to_string_from_ptr();
    let signature = signature.to_string_from_ptr();

    fn internal_fn(
        public_key: String,
        data_hash: String,
        signature: String,
    ) -> Result<u64, String> {
        let public_key = parse_public_key(&public_key)?;

        let data_hash = match hex::decode(&data_hash) {
            Ok(data_hash) => data_hash,
            Err(e) => match base64::decode(&data_hash) {
                Ok(data_hash) => data_hash,
                Err(_) => return Err(e).handle_error(),
            },
        };

        if data_hash.len() != 32 {
            return Err("Invalid data hash. Expected 32 bytes").handle_error();
        }

        let signature = match base64::decode(&signature) {
            Ok(signature) => signature,
            Err(e) => match hex::decode(&signature) {
                Ok(signature) => signature,
                Err(_) => return Err(e).handle_error(),
            },
        };

        let signature = match ed25519_dalek::Signature::try_from(signature.as_slice()) {
            Ok(signature) => signature,
            Err(_) => return Err("Invalid signature. Expected 64 bytes").handle_error(),
        };

        let is_valid = public_key.verify(&data_hash, &signature).is_ok() as u64;

        Ok(is_valid)
    }

    internal_fn(public_key, data_hash, signature).match_result()
}
