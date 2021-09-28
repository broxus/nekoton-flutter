pub mod models;

use crate::{
    core::{
        accounts_storage::models::{AssetsList, MutexAccountsStorage},
        ton_wallet::models::WalletType,
    },
    external::storage::{MutexStorage, StorageImpl},
    helpers::{parse_address, parse_public_key},
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    runtime, send_to_result_port, FromPtr, ToPtr, RUNTIME,
};
use nekoton::core::accounts_storage::AccountsStorage;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_schar, c_ulonglong},
    sync::Arc,
};
use tokio::sync::Mutex;

const ACCOUNTS_STORAGE_NOT_FOUND: &str = "Accounts storage not found";

#[no_mangle]
pub unsafe extern "C" fn get_accounts_storage(result_port: c_longlong, storage: *mut c_void) {
    let storage = storage as *mut MutexStorage;
    let storage = &(*storage);

    let rt = runtime!();
    rt.spawn(async move {
        let storage = storage.lock().await;
        let storage = storage.clone();

        let result = internal_get_accounts_storage(storage).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_accounts_storage(storage: Arc<StorageImpl>) -> Result<u64, NativeError> {
    let accounts_storage = AccountsStorage::load(storage)
        .await
        .handle_error(NativeStatus::AccountsStorageError)?;

    let accounts_storage = Mutex::new(Some(accounts_storage));
    let accounts_storage = Arc::new(accounts_storage);

    let ptr = Arc::into_raw(accounts_storage) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn get_accounts(result_port: c_longlong, accounts_storage: *mut c_void) {
    let accounts_storage = accounts_storage as *mut MutexAccountsStorage;
    let accounts_storage = &(*accounts_storage);

    let rt = runtime!();
    rt.spawn(async move {
        let mut accounts_storage_guard = accounts_storage.lock().await;
        let accounts_storage = accounts_storage_guard.take();
        let accounts_storage = match accounts_storage {
            Some(accounts_storage) => accounts_storage,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ACCOUNTS_STORAGE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_accounts(&accounts_storage).await;
        let result = match_result(result);

        *accounts_storage_guard = Some(accounts_storage);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_accounts(accounts_storage: &AccountsStorage) -> Result<u64, NativeError> {
    let accounts = {
        let data = accounts_storage.stored_data().await;
        let accounts = data.accounts();
        let accounts = accounts.values();

        let mut result = Vec::new();
        for address in accounts {
            let address = AssetsList::from_core(address.clone());
            result.push(address);
        }

        serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?
    };

    Ok(accounts.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn add_account(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    name: *mut c_char,
    public_key: *mut c_char,
    contract: *mut c_char,
    workchain: c_schar,
) {
    let accounts_storage = accounts_storage as *mut MutexAccountsStorage;
    let accounts_storage = &(*accounts_storage);

    let name = name.from_ptr();
    let public_key = public_key.from_ptr();
    let contract = contract.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut accounts_storage_guard = accounts_storage.lock().await;
        let accounts_storage = accounts_storage_guard.take();
        let accounts_storage = match accounts_storage {
            Some(accounts_storage) => accounts_storage,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ACCOUNTS_STORAGE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result =
            internal_add_account(&accounts_storage, name, public_key, contract, workchain).await;
        let result = match_result(result);

        *accounts_storage_guard = Some(accounts_storage);

        send_to_result_port(result_port, result);
    });
}

async fn internal_add_account(
    accounts_storage: &AccountsStorage,
    name: String,
    public_key: String,
    contract: String,
    workchain: i8,
) -> Result<u64, NativeError> {
    let contract = serde_json::from_str::<WalletType>(&contract)
        .handle_error(NativeStatus::ConversionError)?;
    let contract = contract.to_core();

    let public_key = parse_public_key(&public_key)?;

    let assets = accounts_storage
        .add_account(&name, public_key, contract, workchain)
        .await
        .handle_error(NativeStatus::AccountsStorageError)?;

    let assets = AssetsList::from_core(assets);
    let assets = serde_json::to_string(&assets).handle_error(NativeStatus::ConversionError)?;

    Ok(assets.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn rename_account(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    address: *mut c_char,
    name: *mut c_char,
) {
    let accounts_storage = accounts_storage as *mut MutexAccountsStorage;
    let accounts_storage = &(*accounts_storage);

    let address = address.from_ptr();
    let name = name.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut accounts_storage_guard = accounts_storage.lock().await;
        let accounts_storage = accounts_storage_guard.take();
        let accounts_storage = match accounts_storage {
            Some(accounts_storage) => accounts_storage,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ACCOUNTS_STORAGE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_rename_account(&accounts_storage, address, name).await;
        let result = match_result(result);

        *accounts_storage_guard = Some(accounts_storage);

        send_to_result_port(result_port, result);
    });
}

async fn internal_rename_account(
    accounts_storage: &AccountsStorage,
    address: String,
    name: String,
) -> Result<u64, NativeError> {
    let assets = accounts_storage
        .rename_account(&address, name)
        .await
        .handle_error(NativeStatus::AccountsStorageError)?;

    let assets = AssetsList::from_core(assets);
    let assets = serde_json::to_string(&assets).handle_error(NativeStatus::ConversionError)?;

    Ok(assets.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn remove_account(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    address: *mut c_char,
) {
    let accounts_storage = accounts_storage as *mut MutexAccountsStorage;
    let accounts_storage = &(*accounts_storage);

    let address = address.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut accounts_storage_guard = accounts_storage.lock().await;
        let accounts_storage = accounts_storage_guard.take();
        let accounts_storage = match accounts_storage {
            Some(accounts_storage) => accounts_storage,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ACCOUNTS_STORAGE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_remove_account(&accounts_storage, address).await;
        let result = match_result(result);

        *accounts_storage_guard = Some(accounts_storage);

        send_to_result_port(result_port, result);
    });
}

async fn internal_remove_account(
    accounts_storage: &AccountsStorage,
    address: String,
) -> Result<u64, NativeError> {
    let assets = accounts_storage
        .remove_account(&address)
        .await
        .handle_error(NativeStatus::AccountsStorageError)?;
    let assets = assets.map(|assets| AssetsList::from_core(assets));
    let assets = serde_json::to_string(&assets).handle_error(NativeStatus::ConversionError)?;

    Ok(assets.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn add_token_wallet(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    address: *mut c_char,
    network_group: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let accounts_storage = accounts_storage as *mut MutexAccountsStorage;
    let accounts_storage = &(*accounts_storage);

    let address = address.from_ptr();
    let network_group = network_group.from_ptr();
    let root_token_contract = root_token_contract.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut accounts_storage_guard = accounts_storage.lock().await;
        let accounts_storage = accounts_storage_guard.take();
        let accounts_storage = match accounts_storage {
            Some(accounts_storage) => accounts_storage,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ACCOUNTS_STORAGE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_add_token_wallet(
            &accounts_storage,
            address,
            network_group,
            root_token_contract,
        )
        .await;
        let result = match_result(result);

        *accounts_storage_guard = Some(accounts_storage);

        send_to_result_port(result_port, result);
    });
}

async fn internal_add_token_wallet(
    accounts_storage: &AccountsStorage,
    address: String,
    network_group: String,
    root_token_contract: String,
) -> Result<u64, NativeError> {
    let root_token_contract = parse_address(&root_token_contract)?;

    let assets = accounts_storage
        .add_token_wallet(&address, &network_group, root_token_contract)
        .await
        .handle_error(NativeStatus::AccountsStorageError)?;

    let assets = AssetsList::from_core(assets);
    let assets = serde_json::to_string(&assets).handle_error(NativeStatus::ConversionError)?;

    Ok(assets.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn remove_token_wallet(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    address: *mut c_char,
    network_group: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let accounts_storage = accounts_storage as *mut MutexAccountsStorage;
    let accounts_storage = &(*accounts_storage);

    let address = address.from_ptr();
    let network_group = network_group.from_ptr();
    let root_token_contract = root_token_contract.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut accounts_storage_guard = accounts_storage.lock().await;
        let accounts_storage = accounts_storage_guard.take();
        let accounts_storage = match accounts_storage {
            Some(accounts_storage) => accounts_storage,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ACCOUNTS_STORAGE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_remove_token_wallet(
            &accounts_storage,
            address,
            network_group,
            root_token_contract,
        )
        .await;
        let result = match_result(result);

        *accounts_storage_guard = Some(accounts_storage);

        send_to_result_port(result_port, result);
    });
}

async fn internal_remove_token_wallet(
    accounts_storage: &AccountsStorage,
    address: String,
    network_group: String,
    root_token_contract: String,
) -> Result<u64, NativeError> {
    let root_token_contract = parse_address(&root_token_contract)?;

    let assets = accounts_storage
        .remove_token_wallet(&address, &network_group, &root_token_contract)
        .await
        .handle_error(NativeStatus::AccountsStorageError)?;

    let assets = AssetsList::from_core(assets);
    let assets = serde_json::to_string(&assets).handle_error(NativeStatus::ConversionError)?;

    Ok(assets.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn clear_accounts_storage(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
) {
    let accounts_storage = accounts_storage as *mut MutexAccountsStorage;
    let accounts_storage = &(*accounts_storage);

    let rt = runtime!();
    rt.spawn(async move {
        let mut accounts_storage_guard = accounts_storage.lock().await;
        let accounts_storage = accounts_storage_guard.take();
        let accounts_storage = match accounts_storage {
            Some(accounts_storage) => accounts_storage,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ACCOUNTS_STORAGE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_clear_accounts_storage(&accounts_storage).await;
        let result = match_result(result);

        *accounts_storage_guard = Some(accounts_storage);

        send_to_result_port(result_port, result);
    });
}

async fn internal_clear_accounts_storage(
    accounts_storage: &AccountsStorage,
) -> Result<u64, NativeError> {
    let _ = accounts_storage
        .clear()
        .await
        .handle_error(NativeStatus::AccountsStorageError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn free_accounts_storage(accounts_storage: *mut c_void) {
    let accounts_storage = accounts_storage as *mut MutexAccountsStorage;
    Arc::from_raw(accounts_storage);
}
