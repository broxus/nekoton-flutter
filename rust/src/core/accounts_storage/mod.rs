pub mod models;

use crate::{
    core::{accounts_storage::models::AssetsList, ton_wallet::models::WalletType},
    external::storage::StorageImpl,
    models::{HandleError, MatchResult},
    parse_address, parse_public_key, runtime, send_to_result_port, FromPtr, ToPtr, RUNTIME,
};
use nekoton::{core::accounts_storage::AccountsStorage, external::Storage};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_schar, c_ulonglong},
    sync::Arc,
};
use ton_block::AccountStorage;

#[no_mangle]
pub unsafe extern "C" fn create_accounts_storage(result_port: c_longlong, storage: *mut c_void) {
    let storage = storage as *mut StorageImpl;
    let storage = Arc::from_raw(storage) as Arc<dyn Storage>;

    runtime!().spawn(async move {
        async fn internal_fn(storage: Arc<dyn Storage>) -> Result<u64, String> {
            let accounts_storage = AccountsStorage::load(storage).await.handle_error()?;

            let accounts_storage = Box::new(Arc::new(accounts_storage));

            let ptr = Box::into_raw(accounts_storage) as *mut c_void as c_ulonglong;

            Ok(ptr)
        }

        let result = internal_fn(storage).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn clone_accounts_storage_ptr(accounts_storage: *mut c_void) -> *mut c_void {
    let accounts_storage = accounts_storage as *mut Arc<AccountStorage>;
    let cloned = Arc::clone(&*accounts_storage);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_accounts_storage_ptr(accounts_storage: *mut c_void) {
    let accounts_storage = accounts_storage as *mut Arc<AccountStorage>;

    let _ = Box::from_raw(accounts_storage);
}

#[no_mangle]
pub unsafe extern "C" fn get_accounts(result_port: c_longlong, accounts_storage: *mut c_void) {
    let accounts_storage = accounts_storage as *mut AccountsStorage;
    let accounts_storage = Arc::from_raw(accounts_storage) as Arc<AccountsStorage>;

    runtime!().spawn(async move {
        async fn internal_fn(accounts_storage: &AccountsStorage) -> Result<u64, String> {
            let data = accounts_storage.stored_data().await;

            let accounts = data
                .accounts()
                .values()
                .into_iter()
                .map(|e| AssetsList::from_core(e.clone()))
                .collect::<Vec<_>>();

            let accounts = serde_json::to_string(&accounts).handle_error()?.to_ptr() as c_ulonglong;

            Ok(accounts)
        }

        let result = internal_fn(&accounts_storage).await.match_result();

        send_to_result_port(result_port, result);
    });
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
    let accounts_storage = accounts_storage as *mut AccountsStorage;
    let accounts_storage = Arc::from_raw(accounts_storage) as Arc<AccountsStorage>;

    let name = name.from_ptr();
    let public_key = public_key.from_ptr();
    let contract = contract.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            name: String,
            public_key: String,
            contract: String,
            workchain: i8,
        ) -> Result<u64, String> {
            let contract = serde_json::from_str::<WalletType>(&contract)
                .handle_error()?
                .to_core();

            let public_key = parse_public_key(&public_key)?;

            let assets = accounts_storage
                .add_account(&name, public_key, contract, workchain)
                .await
                .handle_error()
                .map(|e| AssetsList::from_core(e))?;

            let assets = serde_json::to_string(&assets).handle_error()?.to_ptr() as c_ulonglong;

            Ok(assets)
        }

        let result = internal_fn(&accounts_storage, name, public_key, contract, workchain)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn rename_account(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    address: *mut c_char,
    name: *mut c_char,
) {
    let accounts_storage = accounts_storage as *mut AccountsStorage;
    let accounts_storage = Arc::from_raw(accounts_storage) as Arc<AccountsStorage>;

    let address = address.from_ptr();
    let name = name.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            address: String,
            name: String,
        ) -> Result<u64, String> {
            let assets = accounts_storage
                .rename_account(&address, name)
                .await
                .handle_error()
                .map(|e| AssetsList::from_core(e.clone()))?;

            let assets = serde_json::to_string(&assets).handle_error()?.to_ptr() as c_ulonglong;

            Ok(assets)
        }

        let result = internal_fn(&accounts_storage, address, name)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn remove_account(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    address: *mut c_char,
) {
    let accounts_storage = accounts_storage as *mut AccountsStorage;
    let accounts_storage = Arc::from_raw(accounts_storage) as Arc<AccountsStorage>;

    let address = address.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            address: String,
        ) -> Result<u64, String> {
            let assets = accounts_storage
                .remove_account(&address)
                .await
                .handle_error()
                .map(|e| e.map(|e| AssetsList::from_core(e.clone())))?;

            let assets = serde_json::to_string(&assets).handle_error()?.to_ptr() as c_ulonglong;

            Ok(assets)
        }

        let result = internal_fn(&accounts_storage, address).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn add_token_wallet(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    address: *mut c_char,
    network_group: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let accounts_storage = accounts_storage as *mut AccountsStorage;
    let accounts_storage = Arc::from_raw(accounts_storage) as Arc<AccountsStorage>;

    let address = address.from_ptr();
    let network_group = network_group.from_ptr();
    let root_token_contract = root_token_contract.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            address: String,
            network_group: String,
            root_token_contract: String,
        ) -> Result<u64, String> {
            let root_token_contract = parse_address(&root_token_contract)?;

            let assets = accounts_storage
                .add_token_wallet(&address, &network_group, root_token_contract)
                .await
                .handle_error()
                .map(|e| AssetsList::from_core(e.clone()))?;

            let assets = serde_json::to_string(&assets).handle_error()?.to_ptr() as c_ulonglong;

            Ok(assets)
        }

        let result = internal_fn(
            &accounts_storage,
            address,
            network_group,
            root_token_contract,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn remove_token_wallet(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    address: *mut c_char,
    network_group: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let accounts_storage = accounts_storage as *mut AccountsStorage;
    let accounts_storage = Arc::from_raw(accounts_storage) as Arc<AccountsStorage>;

    let address = address.from_ptr();
    let network_group = network_group.from_ptr();
    let root_token_contract = root_token_contract.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            address: String,
            network_group: String,
            root_token_contract: String,
        ) -> Result<u64, String> {
            let root_token_contract = parse_address(&root_token_contract)?;

            let assets = accounts_storage
                .remove_token_wallet(&address, &network_group, &root_token_contract)
                .await
                .handle_error()
                .map(|e| AssetsList::from_core(e.clone()))?;

            let assets = serde_json::to_string(&assets).handle_error()?.to_ptr() as c_ulonglong;

            Ok(assets)
        }

        let result = internal_fn(
            &accounts_storage,
            address,
            network_group,
            root_token_contract,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn clear_accounts_storage(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
) {
    let accounts_storage = accounts_storage as *mut AccountsStorage;
    let accounts_storage = Arc::from_raw(accounts_storage) as Arc<AccountsStorage>;

    runtime!().spawn(async move {
        async fn internal_fn(accounts_storage: &AccountsStorage) -> Result<u64, String> {
            let _ = accounts_storage.clear().await.handle_error()?;

            Ok(0)
        }

        let result = internal_fn(&accounts_storage).await.match_result();

        send_to_result_port(result_port, result);
    });
}
