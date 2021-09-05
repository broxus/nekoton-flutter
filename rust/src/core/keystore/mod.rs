pub mod models;

use crate::{
    core::keystore::models::{KeySigner, MutexKeyStore},
    crypto::{
        derived_key::{DerivedKeyExportParams, DerivedKeyUpdateParams},
        encrypted_key::{EncryptedKeyPassword, EncryptedKeyUpdateParams},
    },
    external::storage::StorageImpl,
    match_result,
    models::{NativeError, NativeStatus},
    runtime, send_to_result_port, FromPtr, ToPtr, RUNTIME,
};
use crate::{
    crypto::{
        derived_key::{DerivedKeyCreateInput, DerivedKeySignParams},
        encrypted_key::{EncryptedKeyCreateInput, EncryptedKeyExportOutput},
    },
    external::storage::MutexStorage,
};
use anyhow::anyhow;
use nekoton::{
    core::keystore::KeyStore,
    crypto::{DerivedKeySigner, EncryptedKeySigner},
};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    sync::Arc,
};
use tokio::sync::Mutex;

pub const KEY_STORE_NOT_FOUND: &str = "Key store not found";
pub const UNKNOWN_SIGNER: &str = "Unknown signer";

#[no_mangle]
pub unsafe extern "C" fn get_keystore(result_port: c_longlong, storage: *mut c_void) {
    let storage = storage as *mut MutexStorage;
    let storage = &(*storage);

    let rt = runtime!();
    rt.spawn(async move {
        let storage = storage.lock().await;
        let storage = storage.clone();

        let result = internal_get_keystore(storage).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_keystore(storage: Arc<StorageImpl>) -> Result<u64, NativeError> {
    let keystore = KeyStore::builder(storage)
        .with_signer::<EncryptedKeySigner>(
            &KeySigner::EncryptedKeySigner.to_string(),
            EncryptedKeySigner::new(),
        )
        .map_err(|e| NativeError {
            status: NativeStatus::KeyStoreError,
            info: e.to_string(),
        })?
        .with_signer::<DerivedKeySigner>(
            &KeySigner::DerivedKeySigner.to_string(),
            DerivedKeySigner::new(),
        )
        .map_err(|e| NativeError {
            status: NativeStatus::KeyStoreError,
            info: e.to_string(),
        })?
        .load()
        .await
        .map_err(|e| NativeError {
            status: NativeStatus::KeyStoreError,
            info: e.to_string(),
        })?;

    let keystore = Mutex::new(Some(keystore));
    let keystore = Arc::new(keystore);

    let ptr = Arc::into_raw(keystore) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn get_entries(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let rt = runtime!();
    rt.spawn(async move {
        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_entries(&keystore).await;
        let result = match_result(result);

        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_entries(keystore: &KeyStore) -> Result<u64, NativeError> {
    let entries = keystore.get_entries().await;

    let mut result = Vec::new();
    for entry in entries {
        result.push(entry);
    }
    let result = serde_json::to_string(&result).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn add_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    create_key_input: *mut c_char,
) {
    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let create_key_input = create_key_input.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_add_key(&keystore, create_key_input).await;
        let result = match_result(result);

        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_add_key(
    keystore: &KeyStore,
    create_key_input: String,
) -> Result<u64, NativeError> {
    let entry = if let Ok(create_key_input) =
        serde_json::from_str::<EncryptedKeyCreateInput>(&create_key_input)
    {
        let entry = keystore
            .add_key::<EncryptedKeySigner>(create_key_input.to_core())
            .await
            .map_err(|e| NativeError {
                status: NativeStatus::KeyStoreError,
                info: e.to_string(),
            })?;
        serde_json::to_string(&entry).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?
    } else if let Ok(create_key_input) =
        serde_json::from_str::<DerivedKeyCreateInput>(&create_key_input)
    {
        let entry = keystore
            .add_key::<DerivedKeySigner>(create_key_input.to_core())
            .await
            .map_err(|e| NativeError {
                status: NativeStatus::KeyStoreError,
                info: e.to_string(),
            })?;
        serde_json::to_string(&entry).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?
    } else {
        return Err(NativeError {
            status: NativeStatus::KeyStoreError,
            info: UNKNOWN_SIGNER.to_owned(),
        });
    };

    Ok(entry.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn update_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    update_key_input: *mut c_char,
) {
    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let update_key_input = update_key_input.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_update_key(&keystore, update_key_input).await;
        let result = match_result(result);

        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_update_key(
    keystore: &KeyStore,
    update_key_input: String,
) -> Result<u64, NativeError> {
    let entry = if let Ok(update_key_input) =
        serde_json::from_str::<EncryptedKeyUpdateParams>(&update_key_input)
    {
        let entry = keystore
            .update_key::<EncryptedKeySigner>(update_key_input.to_core())
            .await
            .map_err(|e| NativeError {
                status: NativeStatus::KeyStoreError,
                info: e.to_string(),
            })?;
        serde_json::to_string(&entry).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?
    } else if let Ok(update_key_input) =
        serde_json::from_str::<DerivedKeyUpdateParams>(&update_key_input)
    {
        let entry = keystore
            .update_key::<DerivedKeySigner>(update_key_input.to_core())
            .await
            .map_err(|e| NativeError {
                status: NativeStatus::KeyStoreError,
                info: e.to_string(),
            })?;
        serde_json::to_string(&entry).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?
    } else {
        return Err(NativeError {
            status: NativeStatus::KeyStoreError,
            info: UNKNOWN_SIGNER.to_owned(),
        });
    };

    Ok(entry.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn export_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    export_key_input: *mut c_char,
) {
    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let export_key_input = export_key_input.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_export_key(&keystore, export_key_input).await;
        let result = match_result(result);

        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_export_key(
    keystore: &KeyStore,
    export_key_input: String,
) -> Result<u64, NativeError> {
    let phrase = if let Ok(export_key_input) =
        serde_json::from_str::<EncryptedKeyPassword>(&export_key_input)
    {
        let output = keystore
            .export_key::<EncryptedKeySigner>(export_key_input.to_core())
            .await
            .map_err(|e| NativeError {
                status: NativeStatus::KeyStoreError,
                info: e.to_string(),
            })?;

        let output = EncryptedKeyExportOutput::from_core(output);
        let output = serde_json::to_string(&output).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?;
        output
    } else if let Ok(export_key_input) =
        serde_json::from_str::<DerivedKeyExportParams>(&export_key_input)
    {
        let output = keystore
            .export_key::<DerivedKeySigner>(export_key_input.to_core())
            .await
            .map_err(|e| NativeError {
                status: NativeStatus::KeyStoreError,
                info: e.to_string(),
            })?;

        let output = serde_json::to_string(&output).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?;
        output
    } else {
        return Err(NativeError {
            status: NativeStatus::KeyStoreError,
            info: UNKNOWN_SIGNER.to_owned(),
        });
    };

    Ok(phrase.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn check_key_password(
    result_port: c_longlong,
    keystore: *mut c_void,
    sign_input: *mut c_char,
) {
    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let sign_input = sign_input.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_check_key_password(&keystore, sign_input).await;
        let result = match_result(result);

        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_check_key_password(
    keystore: &KeyStore,
    sign_input: String,
) -> Result<u64, NativeError> {
    let hash = [u8::default(); ed25519_dalek::SIGNATURE_LENGTH];

    let result = if let Ok(sign_input) = serde_json::from_str::<EncryptedKeyPassword>(&sign_input) {
        keystore
            .sign::<EncryptedKeySigner>(&hash, sign_input.to_core())
            .await
    } else if let Ok(sign_input) = serde_json::from_str::<DerivedKeySignParams>(&sign_input) {
        keystore
            .sign::<DerivedKeySigner>(&hash, sign_input.to_core())
            .await
    } else {
        Err(anyhow!(UNKNOWN_SIGNER))
    };

    Ok(result.is_ok() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn remove_key(
    result_port: c_longlong,
    keystore: *mut c_void,
    public_key: *mut c_char,
) {
    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let public_key = public_key.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_remove_key(&keystore, public_key).await;
        let result = match_result(result);

        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_remove_key(keystore: &KeyStore, public_key: String) -> Result<u64, NativeError> {
    let public_key = hex::decode(public_key).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;
    let public_key =
        ed25519_dalek::PublicKey::from_bytes(&public_key).map_err(|e| NativeError {
            status: NativeStatus::ConversionError,
            info: e.to_string(),
        })?;

    let entry = keystore
        .remove_key(&public_key)
        .await
        .map_err(|e| NativeError {
            status: NativeStatus::KeyStoreError,
            info: e.to_string(),
        })?;
    let entry = serde_json::to_string(&entry).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

    Ok(entry.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn clear_keystore(result_port: c_longlong, keystore: *mut c_void) {
    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let rt = runtime!();
    rt.spawn(async move {
        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_clear_keystore(&keystore).await;
        let result = match_result(result);

        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_clear_keystore(keystore: &KeyStore) -> Result<u64, NativeError> {
    let _ = keystore.clear().await.map_err(|e| NativeError {
        status: NativeStatus::KeyStoreError,
        info: e.to_string(),
    })?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn free_keystore(keystore: *mut c_void) {
    let keystore = keystore as *mut MutexKeyStore;
    Arc::from_raw(keystore);
}
