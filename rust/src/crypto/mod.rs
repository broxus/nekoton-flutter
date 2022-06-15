pub(crate) mod derived_key;
pub(crate) mod encrypted_key;
pub(crate) mod ledger_key;
mod mnemonic;
pub(crate) mod models;

use std::{
    os::raw::{c_char, c_longlong, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
use ed25519_dalek::Verifier;
use nekoton::crypto::UnsignedMessage;
use tokio::sync::RwLock;

use crate::{
    clock, parse_public_key, runtime, HandleError, MatchResult, PostWithResult, ToStringFromPtr,
    CLOCK, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_refresh_timeout(
    result_port: c_longlong,
    unsigned_message: *mut c_void,
) {
    let unsigned_message = unsigned_message_from_ptr(unsigned_message);

    runtime!().spawn(async move {
        fn internal_fn(
            unsigned_message: &mut Box<dyn UnsignedMessage>,
        ) -> Result<serde_json::Value, String> {
            unsigned_message.refresh_timeout(clock!().as_ref());

            Ok(serde_json::Value::Null)
        }

        let mut unsigned_message = unsigned_message.write().await;

        let result = internal_fn(&mut unsigned_message).match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_expire_at(
    result_port: c_longlong,
    unsigned_message: *mut c_void,
) {
    let unsigned_message = unsigned_message_from_ptr(unsigned_message);

    runtime!().spawn(async move {
        fn internal_fn(
            unsigned_message: &Box<dyn UnsignedMessage>,
        ) -> Result<serde_json::Value, String> {
            let expire_at = unsigned_message.expire_at();

            serde_json::to_value(expire_at).handle_error()
        }

        let unsigned_message = unsigned_message.read().await;

        let result = internal_fn(&unsigned_message).match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_unsigned_message_hash(
    result_port: c_longlong,
    unsigned_message: *mut c_void,
) {
    let unsigned_message = unsigned_message_from_ptr(unsigned_message);

    runtime!().spawn(async move {
        fn internal_fn(
            unsigned_message: &Box<dyn UnsignedMessage>,
        ) -> Result<serde_json::Value, String> {
            let hash = unsigned_message.hash();

            let hash = base64::encode(&hash);

            serde_json::to_value(hash).handle_error()
        }

        let unsigned_message = unsigned_message.read().await;

        let result = internal_fn(&unsigned_message).match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
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
        ) -> Result<serde_json::Value, String> {
            let signature: [u8; ed25519_dalek::SIGNATURE_LENGTH] = base64::decode(&signature)
                .handle_error()?
                .as_slice()
                .try_into()
                .handle_error()?;

            let signed_message = unsigned_message.sign(&signature).handle_error()?;

            serde_json::to_value(&signed_message).handle_error()
        }

        let unsigned_message = unsigned_message.read().await;

        let result = internal_fn(&unsigned_message, signature).match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
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
) -> *mut c_char {
    let public_key = public_key.to_string_from_ptr();
    let data_hash = data_hash.to_string_from_ptr();
    let signature = signature.to_string_from_ptr();

    fn internal_fn(
        public_key: String,
        data_hash: String,
        signature: String,
    ) -> Result<serde_json::Value, String> {
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

        let is_valid = public_key.verify(&data_hash, &signature).is_ok();

        serde_json::to_value(is_valid).handle_error()
    }

    internal_fn(public_key, data_hash, signature).match_result()
}
