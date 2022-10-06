mod models;

use std::{
    os::raw::{c_char, c_longlong, c_ulonglong, c_void},
    sync::Arc,
    time::Duration,
};

use allo_isolate::Isolate;
use nekoton::{
    core::keystore::{KeyStore, KeyStoreBuilder, KEYSTORE_STORAGE_KEY},
    crypto::{
        self, DerivedKeySigner, EncryptedData, EncryptedKeySigner, EncryptionAlgorithm, Signature,
    },
    external::Storage,
};
use sha2::Digest;

use crate::{
    core::keystore::models::KeySigner,
    crypto::{
        derived_key::{
            DerivedKeyCreateInput, DerivedKeyExportParams, DerivedKeySignParams,
            DerivedKeyUpdateParams,
        },
        encrypted_key::{EncryptedKeyCreateInput, EncryptedKeyPassword, EncryptedKeyUpdateParams},
        models::{SignatureParts, SignedData, SignedDataRaw},
    },
    external::storage::storage_from_ptr,
    models::{
        HandleError, MatchResult, PostWithResult, ToCStringPtr, ToNekoton, ToPtrAddress,
        ToSerializable,
    },
    parse_public_key, runtime, ToStringFromPtr, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_storage_key() -> *mut c_char {
    KEYSTORE_STORAGE_KEY.to_owned().to_cstring_ptr()
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_create(result_port: c_longlong, storage: *mut c_void) {
    let storage = storage_from_ptr(storage);

    runtime!().spawn(async move {
        async fn internal_fn(storage: Arc<dyn Storage>) -> Result<serde_json::Value, String> {
            let keystore = build_keystore()?.load(storage).await.handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(keystore)));

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let result = internal_fn(storage).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_entries(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore_from_ptr(keystore);

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore) -> Result<serde_json::Value, String> {
            let entries = keystore.get_entries().await;

            serde_json::to_value(entries).handle_error()
        }

        let result = internal_fn(&keystore).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_add_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let entry = if let Ok(input) = serde_json::from_str::<EncryptedKeyCreateInput>(&input) {
                let input = input.to_nekoton();

                keystore
                    .add_key::<EncryptedKeySigner>(input)
                    .await
                    .handle_error()?
            } else if let Ok(input) = serde_json::from_str::<DerivedKeyCreateInput>(&input) {
                let input = input.to_nekoton();

                keystore
                    .add_key::<DerivedKeySigner>(input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            serde_json::to_value(entry).handle_error()
        }

        let result = internal_fn(&keystore, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_add_keys(
    result_port: c_longlong,
    keystore: *mut c_void,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let entries = if let Ok(input) =
                serde_json::from_str::<Vec<EncryptedKeyCreateInput>>(&input)
            {
                let input = input
                    .into_iter()
                    .map(|e| e.to_nekoton())
                    .collect::<Vec<_>>();

                keystore
                    .add_keys::<EncryptedKeySigner, Vec<crypto::EncryptedKeyCreateInput>>(input)
                    .await
                    .handle_error()?
            } else if let Ok(input) = serde_json::from_str::<Vec<DerivedKeyCreateInput>>(&input) {
                let input = input
                    .into_iter()
                    .map(|e| e.to_nekoton())
                    .collect::<Vec<_>>();

                keystore
                    .add_keys::<DerivedKeySigner, Vec<crypto::DerivedKeyCreateInput>>(input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            serde_json::to_value(entries).handle_error()
        }

        let result = internal_fn(&keystore, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_update_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let entry = if let Ok(input) = serde_json::from_str::<EncryptedKeyUpdateParams>(&input)
            {
                let input = input.to_nekoton();

                keystore
                    .update_key::<EncryptedKeySigner>(input)
                    .await
                    .handle_error()?
            } else if let Ok(input) = serde_json::from_str::<DerivedKeyUpdateParams>(&input) {
                let input = input.to_nekoton();

                keystore
                    .update_key::<DerivedKeySigner>(input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            serde_json::to_value(entry).handle_error()
        }

        let result = internal_fn(&keystore, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_export_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            input: String,
        ) -> Result<serde_json::Value, String> {
            if let Ok(input) = serde_json::from_str::<EncryptedKeyPassword>(&input) {
                let input = input.to_nekoton();

                let output = keystore
                    .export_key::<EncryptedKeySigner>(input)
                    .await
                    .handle_error()?
                    .to_serializable();

                serde_json::to_value(output).handle_error()
            } else if let Ok(input) = serde_json::from_str::<DerivedKeyExportParams>(&input) {
                let input = input.to_nekoton();

                let output = keystore
                    .export_key::<DerivedKeySigner>(input)
                    .await
                    .handle_error()?;

                serde_json::to_value(output).handle_error()
            } else {
                panic!()
            }
        }

        let result = internal_fn(&keystore, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_encrypt(
    result_port: c_longlong,
    keystore: *mut c_void,
    data: *mut c_char,
    public_keys: *mut c_char,
    algorithm: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let data = data.to_string_from_ptr();
    let public_keys = public_keys.to_string_from_ptr();
    let algorithm = algorithm.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            data: String,
            public_keys: String,
            algorithm: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let data = base64::decode(data).handle_error()?;

            let public_keys = serde_json::from_str::<Vec<&str>>(&public_keys)
                .handle_error()?
                .into_iter()
                .map(parse_public_key)
                .collect::<Result<Vec<_>, String>>()?;

            let algorithm =
                serde_json::from_str::<EncryptionAlgorithm>(&algorithm).handle_error()?;

            let data = if let Ok(input) = serde_json::from_str::<EncryptedKeyPassword>(&input) {
                let input = input.to_nekoton();

                keystore
                    .encrypt::<EncryptedKeySigner>(&data, &public_keys, algorithm, input)
                    .await
                    .handle_error()?
            } else if let Ok(input) = serde_json::from_str::<DerivedKeySignParams>(&input) {
                let input = input.to_nekoton();

                keystore
                    .encrypt::<DerivedKeySigner>(&data, &public_keys, algorithm, input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            serde_json::to_value(data).handle_error()
        }

        let result = internal_fn(&keystore, data, public_keys, algorithm, input)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_decrypt(
    result_port: c_longlong,
    keystore: *mut c_void,
    data: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let data = data.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            data: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let data = serde_json::from_str::<EncryptedData>(&data).handle_error()?;

            let data = if let Ok(input) = serde_json::from_str::<EncryptedKeyPassword>(&input) {
                let input = input.to_nekoton();

                keystore
                    .decrypt::<EncryptedKeySigner>(&data, input)
                    .await
                    .handle_error()?
            } else if let Ok(input) = serde_json::from_str::<DerivedKeySignParams>(&input) {
                let input = input.to_nekoton();

                keystore
                    .decrypt::<DerivedKeySigner>(&data, input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            let data = base64::encode(&data);

            serde_json::to_value(data).handle_error()
        }

        let result = internal_fn(&keystore, data, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_sign(
    result_port: c_longlong,
    keystore: *mut c_void,
    data: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let data = data.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            data: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let data = base64::decode(&data).handle_error()?;

            let signature = sign(keystore, &data, input).await?;

            let signature = base64::encode(&signature);

            serde_json::to_value(signature).handle_error()
        }

        let result = internal_fn(&keystore, data, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_sign_data(
    result_port: c_longlong,
    keystore: *mut c_void,
    data: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let data = data.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            data: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let data = base64::decode(data).handle_error()?;
            let hash: [u8; 32] = sha2::Sha256::digest(&data).into();

            let signature = sign(keystore, &hash, input).await?;

            let signed_data = SignedData {
                data_hash: hex::encode(hash),
                signature: base64::encode(&signature),
                signature_hex: hex::encode(&signature),
                signature_parts: SignatureParts {
                    high: format!("0x{}", hex::encode(&signature[..32])),
                    low: format!("0x{}", hex::encode(&signature[32..])),
                },
            };

            serde_json::to_value(signed_data).handle_error()
        }

        let result = internal_fn(&keystore, data, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_sign_data_raw(
    result_port: c_longlong,
    keystore: *mut c_void,
    data: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let data = data.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            data: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let data = base64::decode(data).handle_error()?;

            let signature = sign(keystore, &data, input).await?;

            let signed_data_raw = SignedDataRaw {
                signature: base64::encode(&signature),
                signature_hex: hex::encode(&signature),
                signature_parts: SignatureParts {
                    high: format!("0x{}", hex::encode(&signature[..32])),
                    low: format!("0x{}", hex::encode(&signature[32..])),
                },
            };

            serde_json::to_value(signed_data_raw).handle_error()
        }

        let result = internal_fn(&keystore, data, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_remove_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    public_key: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let public_key = public_key.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            public_key: String,
        ) -> Result<serde_json::Value, String> {
            let public_key = parse_public_key(&public_key)?;

            let entry = keystore.remove_key(&public_key).await.handle_error()?;

            serde_json::to_value(entry).handle_error()
        }

        let result = internal_fn(&keystore, public_key).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_remove_keys(
    result_port: c_longlong,
    keystore: *mut c_void,
    public_keys: *mut c_char,
) {
    let keystore = keystore_from_ptr(keystore);

    let public_keys = public_keys.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            public_keys: String,
        ) -> Result<serde_json::Value, String> {
            let public_keys = serde_json::from_str::<Vec<&str>>(&public_keys)
                .handle_error()?
                .into_iter()
                .map(parse_public_key)
                .collect::<Result<Vec<_>, String>>()?;

            let entries = keystore.remove_keys(&public_keys).await.handle_error()?;

            serde_json::to_value(entries).handle_error()
        }

        let result = internal_fn(&keystore, public_keys).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_clear(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore_from_ptr(keystore);

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore) -> Result<serde_json::Value, String> {
            keystore.clear().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let result = internal_fn(&keystore).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_reload(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore_from_ptr(keystore);

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore) -> Result<serde_json::Value, String> {
            keystore.reload().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let result = internal_fn(&keystore).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_verify_data(data: *mut c_char) -> *mut c_char {
    let data = data.to_string_from_ptr();

    fn internal_fn(data: String) -> Result<serde_json::Value, String> {
        let is_valid = build_keystore()?.verify(&data).is_ok();

        serde_json::to_value(is_valid).handle_error()
    }

    internal_fn(data).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_is_password_cached(
    keystore: *mut c_void,
    public_key: *mut c_char,
    duration: c_ulonglong,
) -> *mut c_char {
    let keystore = keystore_from_ptr(keystore);

    let public_key = public_key.to_string_from_ptr();

    fn internal_fn(
        keystore: &KeyStore,
        public_key: String,
        duration: u64,
    ) -> Result<serde_json::Value, String> {
        let id = parse_public_key(&public_key)?.to_bytes();

        let duration = Duration::from_millis(duration);

        let is_cached = keystore.is_password_cached(&id, duration);

        serde_json::to_value(is_cached).handle_error()
    }

    internal_fn(&keystore, public_key, duration).match_result()
}

fn build_keystore() -> Result<KeyStoreBuilder, String> {
    KeyStore::builder()
        .with_signer::<EncryptedKeySigner>(
            &KeySigner::EncryptedKeySigner.to_string(),
            EncryptedKeySigner::new(),
        )
        .handle_error()?
        .with_signer::<DerivedKeySigner>(
            &KeySigner::DerivedKeySigner.to_string(),
            DerivedKeySigner::new(),
        )
        .handle_error()
}

async fn sign(keystore: &KeyStore, data: &[u8], input: String) -> Result<Signature, String> {
    if let Ok(input) = serde_json::from_str::<EncryptedKeyPassword>(&input) {
        let input = input.to_nekoton();

        keystore
            .sign::<EncryptedKeySigner>(data, input)
            .await
            .handle_error()
    } else if let Ok(input) = serde_json::from_str::<DerivedKeySignParams>(&input) {
        let input = input.to_nekoton();

        keystore
            .sign::<DerivedKeySigner>(data, input)
            .await
            .handle_error()
    } else {
        panic!()
    }
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<KeyStore>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<KeyStore>);
}

unsafe fn keystore_from_ptr(ptr: *mut c_void) -> Arc<KeyStore> {
    Arc::from_raw(ptr as *mut KeyStore)
}
