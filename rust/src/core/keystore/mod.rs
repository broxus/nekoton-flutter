use std::{
    os::raw::{c_char, c_longlong, c_ulonglong, c_void},
    str::FromStr,
    sync::Arc,
    time::Duration,
};

use allo_isolate::Isolate;
use anyhow::Context;
use nekoton::{
    core::keystore::{KeyStore, KeyStoreBuilder},
    crypto::{
        DerivedKeyCreateInput, DerivedKeyExportParams, DerivedKeyGetPublicKeys,
        DerivedKeySignParams, DerivedKeySigner, DerivedKeyUpdateParams, EncryptedData,
        EncryptedKeyCreateInput, EncryptedKeyGetPublicKeys, EncryptedKeyPassword,
        EncryptedKeySigner, EncryptedKeyUpdateParams, EncryptionAlgorithm, LedgerKeyCreateInput,
        LedgerKeyGetPublicKeys, LedgerKeySigner, LedgerSignInput, LedgerUpdateKeyInput, Signature,
    },
    external::Storage,
};
use sha2::Digest;

use crate::{
    crypto::{
        derived_key::DERIVED_KEY_SIGNER_NAME,
        encrypted_key::{
            EncryptedKeyCreateInputHelper, EncryptedKeyExportOutputHelper,
            ENCRYPTED_KEY_SIGNER_NAME,
        },
        ledger_key::LEDGER_KEY_SIGNER_NAME,
        models::{SignatureParts, SignedData, SignedDataRaw},
    },
    external::{
        ledger_connection::{ledger_connection_from_native_ptr_opt, LedgerConnectionImpl},
        storage::StorageImpl,
    },
    ffi_box, parse_public_key, runtime, HandleError, MatchResult, PostWithResult,
    ToOptionalStringFromPtr, ToPtrAddress, ToStringFromPtr, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_create(
    result_port: c_longlong,
    storage: *mut c_void,
    connection: *mut c_void,
    signers: *mut c_char,
) {
    let storage = storage_impl_from_native_ptr(storage).clone();
    let connection = ledger_connection_from_native_ptr_opt(connection).cloned();

    let signers = signers.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            storage: Arc<dyn Storage>,
            connection: Option<Arc<LedgerConnectionImpl>>,
            signers: String,
        ) -> Result<serde_json::Value, String> {
            let signers = serde_json::from_str::<Vec<String>>(&signers).handle_error()?;

            let keystore_builder = map_keystore_builder(signers, connection)?;

            let keystore = keystore_builder.load(storage).await.handle_error()?;

            let ptr = keystore_new(keystore);

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let result = internal_fn(storage, connection, signers)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_entries(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore_from_native_ptr(keystore);

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore) -> Result<serde_json::Value, String> {
            let entries = keystore.get_entries().await;

            serde_json::to_value(entries).handle_error()
        }

        let result = internal_fn(keystore).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_add_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let entry = if signer == ENCRYPTED_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<EncryptedKeyCreateInputHelper>(&input)
                    .map(
                        |EncryptedKeyCreateInputHelper(encrypted_key_create_input)| {
                            encrypted_key_create_input
                        },
                    )
                    .handle_error()?;

                keystore
                    .add_key::<EncryptedKeySigner>(input)
                    .await
                    .handle_error()?
            } else if signer == DERIVED_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<DerivedKeyCreateInput>(&input).handle_error()?;

                keystore
                    .add_key::<DerivedKeySigner>(input)
                    .await
                    .handle_error()?
            } else if signer == LEDGER_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<LedgerKeyCreateInput>(&input).handle_error()?;

                keystore
                    .add_key::<LedgerKeySigner>(input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            serde_json::to_value(entry).handle_error()
        }

        let result = internal_fn(keystore, signer, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_add_keys(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let entries = if signer == ENCRYPTED_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<Vec<EncryptedKeyCreateInputHelper>>(&input)
                    .handle_error()?
                    .into_iter()
                    .map(
                        |EncryptedKeyCreateInputHelper(encrypted_key_create_input)| {
                            encrypted_key_create_input
                        },
                    )
                    .collect::<Vec<_>>();

                keystore
                    .add_keys::<EncryptedKeySigner, Vec<EncryptedKeyCreateInput>>(input)
                    .await
                    .handle_error()?
            } else if signer == DERIVED_KEY_SIGNER_NAME {
                let input =
                    serde_json::from_str::<Vec<DerivedKeyCreateInput>>(&input).handle_error()?;

                keystore
                    .add_keys::<DerivedKeySigner, Vec<DerivedKeyCreateInput>>(input)
                    .await
                    .handle_error()?
            } else if signer == LEDGER_KEY_SIGNER_NAME {
                let input =
                    serde_json::from_str::<Vec<LedgerKeyCreateInput>>(&input).handle_error()?;

                keystore
                    .add_keys::<LedgerKeySigner, Vec<LedgerKeyCreateInput>>(input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            serde_json::to_value(entries).handle_error()
        }

        let result = internal_fn(keystore, signer, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_update_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let entry = if signer == ENCRYPTED_KEY_SIGNER_NAME {
                let input =
                    serde_json::from_str::<EncryptedKeyUpdateParams>(&input).handle_error()?;

                keystore
                    .update_key::<EncryptedKeySigner>(input)
                    .await
                    .handle_error()?
            } else if signer == DERIVED_KEY_SIGNER_NAME {
                let input =
                    serde_json::from_str::<DerivedKeyUpdateParams>(&input).handle_error()?;

                keystore
                    .update_key::<DerivedKeySigner>(input)
                    .await
                    .handle_error()?
            } else if signer == LEDGER_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<LedgerUpdateKeyInput>(&input).handle_error()?;

                keystore
                    .update_key::<LedgerKeySigner>(input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            serde_json::to_value(entry).handle_error()
        }

        let result = internal_fn(keystore, signer, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_export_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            if signer == ENCRYPTED_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<EncryptedKeyPassword>(&input).handle_error()?;

                let output = keystore
                    .export_key::<EncryptedKeySigner>(input)
                    .await
                    .handle_error()?;

                serde_json::to_value(EncryptedKeyExportOutputHelper(output)).handle_error()
            } else if signer == DERIVED_KEY_SIGNER_NAME {
                let input =
                    serde_json::from_str::<DerivedKeyExportParams>(&input).handle_error()?;

                let output = keystore
                    .export_key::<DerivedKeySigner>(input)
                    .await
                    .handle_error()?;

                serde_json::to_value(output).handle_error()
            } else {
                panic!()
            }
        }

        let result = internal_fn(keystore, signer, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_get_public_keys(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            if signer == ENCRYPTED_KEY_SIGNER_NAME {
                let input =
                    serde_json::from_str::<EncryptedKeyGetPublicKeys>(&input).handle_error()?;

                let output = keystore
                    .get_public_keys::<EncryptedKeySigner>(input)
                    .await
                    .handle_error()?
                    .into_iter()
                    .map(|e| hex::encode(e.as_bytes()))
                    .collect::<Vec<_>>();

                serde_json::to_value(output).handle_error()
            } else if signer == DERIVED_KEY_SIGNER_NAME {
                let input =
                    serde_json::from_str::<DerivedKeyGetPublicKeys>(&input).handle_error()?;

                let output = keystore
                    .get_public_keys::<DerivedKeySigner>(input)
                    .await
                    .handle_error()?
                    .into_iter()
                    .map(|e| hex::encode(e.as_bytes()))
                    .collect::<Vec<_>>();

                serde_json::to_value(output).handle_error()
            } else if signer == LEDGER_KEY_SIGNER_NAME {
                let input =
                    serde_json::from_str::<LedgerKeyGetPublicKeys>(&input).handle_error()?;

                let output = keystore
                    .get_public_keys::<LedgerKeySigner>(input)
                    .await
                    .handle_error()?
                    .into_iter()
                    .map(|e| hex::encode(e.as_bytes()))
                    .collect::<Vec<_>>();

                serde_json::to_value(output).handle_error()
            } else {
                panic!()
            }
        }

        let result = internal_fn(keystore, signer, input).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_encrypt(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    data: *mut c_char,
    public_keys: *mut c_char,
    algorithm: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let data = data.to_string_from_ptr();
    let public_keys = public_keys.to_string_from_ptr();
    let algorithm = algorithm.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
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
                .collect::<Result<Vec<_>, anyhow::Error>>()
                .context("Bad keys")
                .handle_error()?;

            let algorithm = EncryptionAlgorithm::from_str(&algorithm)
                .context("Bad algorythm")
                .handle_error()?;

            let data = if signer == ENCRYPTED_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<EncryptedKeyPassword>(&input)
                    .context("Invalid EncryptedKeyPassword")
                    .handle_error()?;

                keystore
                    .encrypt::<EncryptedKeySigner>(&data, &public_keys, algorithm, input)
                    .await
                    .context("Failed to encrypt")
                    .handle_error()?
            } else if signer == DERIVED_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<DerivedKeySignParams>(&input)
                    .context("Invalid DerivedKeySignParams")
                    .handle_error()?;

                keystore
                    .encrypt::<DerivedKeySigner>(&data, &public_keys, algorithm, input)
                    .await
                    .context("DerivedKeySigner encrypt fail")
                    .handle_error()?
            } else if signer == LEDGER_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<LedgerSignInput>(&input).handle_error()?;

                keystore
                    .encrypt::<LedgerKeySigner>(&data, &public_keys, algorithm, input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            serde_json::to_value(data).handle_error()
        }

        let result = internal_fn(keystore, signer, data, public_keys, algorithm, input)
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
    signer: *mut c_char,
    data: *mut c_char,
    input: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let data = data.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            data: String,
            input: String,
        ) -> Result<serde_json::Value, String> {
            let data = serde_json::from_str::<EncryptedData>(&data).handle_error()?;

            let data = if signer == ENCRYPTED_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<EncryptedKeyPassword>(&input).handle_error()?;

                keystore
                    .decrypt::<EncryptedKeySigner>(&data, input)
                    .await
                    .handle_error()?
            } else if signer == DERIVED_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<DerivedKeySignParams>(&input).handle_error()?;

                keystore
                    .decrypt::<DerivedKeySigner>(&data, input)
                    .await
                    .handle_error()?
            } else if signer == LEDGER_KEY_SIGNER_NAME {
                let input = serde_json::from_str::<LedgerSignInput>(&input).handle_error()?;

                keystore
                    .decrypt::<LedgerKeySigner>(&data, input)
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            let data = base64::encode(data);

            serde_json::to_value(data).handle_error()
        }

        let result = internal_fn(keystore, signer, data, input)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_sign(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    data: *mut c_char,
    input: *mut c_char,
    signature_id: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let data = data.to_string_from_ptr();
    let input = input.to_string_from_ptr();
    let signature_id = signature_id.to_optional_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            data: String,
            input: String,
            signature_id: Option<String>,
        ) -> Result<serde_json::Value, String> {
            let data = base64::decode(&data).handle_error()?;
            let signature_id = signature_id.and_then(|x| x.parse().ok());
            let signature = sign(keystore, signer, &data, input, signature_id).await?;

            let signature = base64::encode(signature);

            serde_json::to_value(signature).handle_error()
        }

        let result = internal_fn(keystore, signer, data, input, signature_id)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_sign_data(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    data: *mut c_char,
    input: *mut c_char,
    signature_id: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let data = data.to_string_from_ptr();
    let input = input.to_string_from_ptr();
    let signature_id = signature_id.to_optional_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            data: String,
            input: String,
            signature_id: Option<String>,
        ) -> Result<serde_json::Value, String> {
            let data = base64::decode(data).handle_error()?;
            let hash: [u8; 32] = sha2::Sha256::digest(&data).into();
            let signature_id = signature_id.and_then(|x| x.parse().ok());

            let signature = sign(keystore, signer, &hash, input, signature_id).await?;

            let signed_data = SignedData {
                data_hash: hex::encode(hash),
                signature: base64::encode(signature),
                signature_hex: hex::encode(signature),
                signature_parts: SignatureParts {
                    high: format!("0x{}", hex::encode(&signature[..32])),
                    low: format!("0x{}", hex::encode(&signature[32..])),
                },
            };

            serde_json::to_value(signed_data).handle_error()
        }

        let result = internal_fn(keystore, signer, data, input, signature_id)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_sign_data_raw(
    result_port: c_longlong,
    keystore: *mut c_void,
    signer: *mut c_char,
    data: *mut c_char,
    input: *mut c_char,
    signature_id: *mut c_char,
) {
    let keystore = keystore_from_native_ptr(keystore);

    let signer = signer.to_string_from_ptr();
    let data = data.to_string_from_ptr();
    let input = input.to_string_from_ptr();
    let signature_id = signature_id.to_optional_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            signer: String,
            data: String,
            input: String,
            signature_id: Option<String>,
        ) -> Result<serde_json::Value, String> {
            let data = base64::decode(data).handle_error()?;
            let signature_id = signature_id.and_then(|x| x.parse().ok());

            let signature = sign(keystore, signer, &data, input, signature_id).await?;

            let signed_data_raw = SignedDataRaw {
                signature: base64::encode(signature),
                signature_hex: hex::encode(signature),
                signature_parts: SignatureParts {
                    high: format!("0x{}", hex::encode(&signature[..32])),
                    low: format!("0x{}", hex::encode(&signature[32..])),
                },
            };

            serde_json::to_value(signed_data_raw).handle_error()
        }

        let result = internal_fn(keystore, signer, data, input, signature_id)
            .await
            .match_result();

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
    let keystore = keystore_from_native_ptr(keystore);

    let public_key = public_key.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            public_key: String,
        ) -> Result<serde_json::Value, String> {
            let public_key = parse_public_key(&public_key).map_err(|e| e.to_string())?;

            let entry = keystore.remove_key(&public_key).await.handle_error()?;

            serde_json::to_value(entry).handle_error()
        }

        let result = internal_fn(keystore, public_key).await.match_result();

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
    let keystore = keystore_from_native_ptr(keystore);

    let public_keys = public_keys.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            keystore: &KeyStore,
            public_keys: String,
        ) -> Result<serde_json::Value, String> {
            let public_keys = serde_json::from_str::<Vec<&str>>(&public_keys)
                .context("invalid pubkeys")
                .handle_error()?
                .into_iter()
                .map(parse_public_key)
                .collect::<Result<Vec<_>, anyhow::Error>>()
                .handle_error()?;

            let entries = keystore.remove_keys(&public_keys).await.handle_error()?;

            serde_json::to_value(entries).handle_error()
        }

        let result = internal_fn(keystore, public_keys).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_is_password_cached(
    keystore: *mut c_void,
    public_key: *mut c_char,
    duration: c_ulonglong,
) -> *mut c_char {
    let keystore = keystore_from_native_ptr(keystore);

    let public_key = public_key.to_string_from_ptr();

    fn internal_fn(
        keystore: &KeyStore,
        public_key: String,
        duration: u64,
    ) -> Result<serde_json::Value, String> {
        let id = parse_public_key(&public_key).handle_error()?.to_bytes();

        let duration = Duration::from_millis(duration);

        let is_cached = keystore.is_password_cached(&id, duration);

        serde_json::to_value(is_cached).handle_error()
    }

    internal_fn(keystore, public_key, duration).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_clear(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore_from_native_ptr(keystore);

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore) -> Result<serde_json::Value, String> {
            keystore.clear().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let result = internal_fn(keystore).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_reload(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore_from_native_ptr(keystore);

    runtime!().spawn(async move {
        async fn internal_fn(keystore: &KeyStore) -> Result<serde_json::Value, String> {
            keystore.reload().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let result = internal_fn(keystore).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_keystore_verify_data(
    connection: *mut c_void,
    signers: *mut c_char,
    data: *mut c_char,
) -> *mut c_char {
    let connection = ledger_connection_from_native_ptr_opt(connection).cloned();
    let signers = signers.to_string_from_ptr();
    let data = data.to_string_from_ptr();

    fn internal_fn(
        connection: Option<Arc<LedgerConnectionImpl>>,
        signers: String,
        data: String,
    ) -> Result<serde_json::Value, String> {
        let signers = serde_json::from_str::<Vec<String>>(&signers).handle_error()?;

        let keystore_builder = map_keystore_builder(signers, connection)?;

        let is_valid = keystore_builder.verify(&data).is_ok();

        serde_json::to_value(is_valid).handle_error()
    }

    internal_fn(connection, signers, data).match_result()
}

async fn sign(
    keystore: &KeyStore,
    signer: String,
    data: &[u8],
    input: String,
    signature_id: Option<i32>,
) -> Result<Signature, String> {
    let signature_id = signature_id;
    if signer == ENCRYPTED_KEY_SIGNER_NAME {
        let input = serde_json::from_str::<EncryptedKeyPassword>(&input).handle_error()?;

        keystore
            .sign::<EncryptedKeySigner>(data, signature_id, input)
            .await
            .handle_error()
    } else if signer == DERIVED_KEY_SIGNER_NAME {
        let input = serde_json::from_str::<DerivedKeySignParams>(&input).handle_error()?;

        keystore
            .sign::<DerivedKeySigner>(data, signature_id, input)
            .await
            .handle_error()
    } else if signer == LEDGER_KEY_SIGNER_NAME {
        let input = serde_json::from_str::<LedgerSignInput>(&input).handle_error()?;

        keystore
            .sign::<LedgerKeySigner>(data, signature_id, input)
            .await
            .handle_error()
    } else {
        panic!()
    }
}

fn map_keystore_builder(
    signers: Vec<String>,
    connection: Option<Arc<LedgerConnectionImpl>>,
) -> Result<KeyStoreBuilder, String> {
    let mut keystore_builder = KeyStore::builder();

    if signers.contains(&ENCRYPTED_KEY_SIGNER_NAME.to_owned()) {
        keystore_builder = keystore_builder
            .with_signer::<EncryptedKeySigner>(ENCRYPTED_KEY_SIGNER_NAME, EncryptedKeySigner::new())
            .handle_error()?;
    }

    if signers.contains(&DERIVED_KEY_SIGNER_NAME.to_owned()) {
        keystore_builder = keystore_builder
            .with_signer::<DerivedKeySigner>(DERIVED_KEY_SIGNER_NAME, DerivedKeySigner::new())
            .handle_error()?;
    }

    if signers.contains(&LEDGER_KEY_SIGNER_NAME.to_owned()) {
        keystore_builder = keystore_builder
            .with_signer::<LedgerKeySigner>(
                LEDGER_KEY_SIGNER_NAME,
                LedgerKeySigner::new(connection.unwrap()),
            )
            .handle_error()?;
    }

    Ok(keystore_builder)
}

ffi_box!(keystore, KeyStore);
ffi_box!(storage_impl, Arc<StorageImpl>);
