pub mod models;

use crate::{
    core::keystore::models::KeySigner,
    crypto::{
        derived_key::{
            DerivedKeyCreateInput, DerivedKeyExportParams, DerivedKeySignParams,
            DerivedKeyUpdateParams,
        },
        encrypted_key::{
            EncryptedKeyCreateInput, EncryptedKeyExportOutput, EncryptedKeyPassword,
            EncryptedKeyUpdateParams,
        },
    },
    external::storage::StorageImpl,
    models::{HandleError, MatchResult},
    parse_public_key, runtime, send_to_result_port, FromPtr, ToPtr, RUNTIME,
};
use nekoton::{
    core::keystore::KeyStore,
    crypto::{DerivedKeySigner, EncryptedKeySigner},
    external::Storage,
};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    sync::Arc,
};

#[no_mangle]
pub unsafe extern "C" fn create_keystore(result_port: c_longlong, storage: *mut c_void) {
    let storage = storage as *mut StorageImpl;
    let storage = Arc::from_raw(storage) as Arc<dyn Storage>;

    runtime!().spawn(async move {
        async fn internal_fn(storage: Arc<dyn Storage>) -> Result<u64, String> {
            let keystore = KeyStore::builder()
                .with_signer::<EncryptedKeySigner>(
                    &KeySigner::EncryptedKeySigner.to_string(),
                    EncryptedKeySigner::new(),
                )
                .handle_error()?
                .with_signer::<DerivedKeySigner>(
                    &KeySigner::DerivedKeySigner.to_string(),
                    DerivedKeySigner::new(),
                )
                .handle_error()?
                .load(storage)
                .await
                .handle_error()?;

            let keystore = Box::new(Arc::new(keystore));

            let ptr = Box::into_raw(keystore) as *mut c_void as c_ulonglong;

            Ok(ptr)
        }

        let result = internal_fn(storage).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn clone_keystore_ptr(keystore: *mut c_void) -> *mut c_void {
    let keystore = keystore as *mut Arc<KeyStore>;
    let cloned = Arc::clone(&*keystore);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_keystore_ptr(keystore: *mut c_void) {
    let keystore = keystore as *mut Arc<KeyStore>;

    let _ = Box::from_raw(keystore);
}

#[no_mangle]
pub unsafe extern "C" fn get_entries(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore) -> Result<u64, String> {
            let entries = keystore.get_entries().await;

            let entries = serde_json::to_string(&entries).handle_error()?.to_ptr() as c_ulonglong;

            Ok(entries)
        }

        let result = internal_fn(&keystore).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn add_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    create_key_input: *mut c_char,
) {
    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    let create_key_input = create_key_input.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore, create_key_input: String) -> Result<u64, String> {
            let entry = if let Ok(create_key_input) =
                serde_json::from_str::<EncryptedKeyCreateInput>(&create_key_input)
            {
                let entry = keystore
                    .add_key::<EncryptedKeySigner>(create_key_input.to_core())
                    .await
                    .handle_error()?;
                serde_json::to_string(&entry).handle_error()?
            } else if let Ok(create_key_input) =
                serde_json::from_str::<DerivedKeyCreateInput>(&create_key_input)
            {
                let entry = keystore
                    .add_key::<DerivedKeySigner>(create_key_input.to_core())
                    .await
                    .handle_error()?;
                serde_json::to_string(&entry).handle_error()?
            } else {
                panic!()
            }
            .to_ptr() as c_ulonglong;

            Ok(entry)
        }

        let result = internal_fn(&keystore, create_key_input)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn update_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    update_key_input: *mut c_char,
) {
    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    let update_key_input = update_key_input.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore, update_key_input: String) -> Result<u64, String> {
            let entry = if let Ok(update_key_input) =
                serde_json::from_str::<EncryptedKeyUpdateParams>(&update_key_input)
            {
                let entry = keystore
                    .update_key::<EncryptedKeySigner>(update_key_input.to_core())
                    .await
                    .handle_error()?;
                serde_json::to_string(&entry).handle_error()?
            } else if let Ok(update_key_input) =
                serde_json::from_str::<DerivedKeyUpdateParams>(&update_key_input)
            {
                let entry = keystore
                    .update_key::<DerivedKeySigner>(update_key_input.to_core())
                    .await
                    .handle_error()?;
                serde_json::to_string(&entry).handle_error()?
            } else {
                panic!()
            }
            .to_ptr() as c_ulonglong;

            Ok(entry)
        }

        let result = internal_fn(&keystore, update_key_input)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn export_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    export_key_input: *mut c_char,
) {
    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    let export_key_input = export_key_input.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore, export_key_input: String) -> Result<u64, String> {
            let phrase = if let Ok(export_key_input) =
                serde_json::from_str::<EncryptedKeyPassword>(&export_key_input)
            {
                let output = keystore
                    .export_key::<EncryptedKeySigner>(export_key_input.to_core())
                    .await
                    .handle_error()?;

                let output = EncryptedKeyExportOutput::from_core(output);
                let output = serde_json::to_string(&output).handle_error()?;
                output
            } else if let Ok(export_key_input) =
                serde_json::from_str::<DerivedKeyExportParams>(&export_key_input)
            {
                let output = keystore
                    .export_key::<DerivedKeySigner>(export_key_input.to_core())
                    .await
                    .handle_error()?;

                let output = serde_json::to_string(&output).handle_error()?;
                output
            } else {
                panic!()
            }
            .to_ptr() as c_ulonglong;

            Ok(phrase)
        }

        let result = internal_fn(&keystore, export_key_input)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn check_key_password(
    result_port: c_longlong,
    keystore: *mut c_void,
    sign_input: *mut c_char,
) {
    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    let sign_input = sign_input.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore, sign_input: String) -> Result<u64, String> {
            let hash = [u8::default(); ed25519_dalek::SIGNATURE_LENGTH];

            let result = if let Ok(sign_input) =
                serde_json::from_str::<EncryptedKeyPassword>(&sign_input)
            {
                keystore
                    .sign::<EncryptedKeySigner>(&hash, sign_input.to_core())
                    .await
            } else if let Ok(sign_input) = serde_json::from_str::<DerivedKeySignParams>(&sign_input)
            {
                keystore
                    .sign::<DerivedKeySigner>(&hash, sign_input.to_core())
                    .await
            } else {
                panic!()
            };

            let is_valid = result.is_ok() as c_ulonglong;

            Ok(is_valid)
        }

        let result = internal_fn(&keystore, sign_input).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn remove_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    public_key: *mut c_char,
) {
    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    let public_key = public_key.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore, public_key: String) -> Result<u64, String> {
            let public_key = parse_public_key(&public_key)?;

            let entry = keystore.remove_key(&public_key).await.handle_error()?;

            let entry = serde_json::to_string(&entry).handle_error()?.to_ptr() as c_ulonglong;

            Ok(entry)
        }

        let result = internal_fn(&keystore, public_key).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn clear_keystore(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore) -> Result<u64, String> {
            let _ = keystore.clear().await.handle_error()?;

            Ok(0)
        }

        let result = internal_fn(&keystore).await.match_result();

        send_to_result_port(result_port, result);
    });
}
