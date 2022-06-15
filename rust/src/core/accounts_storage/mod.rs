mod models;

use std::{
    os::raw::{c_char, c_longlong, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
use nekoton::{core::accounts_storage::AccountsStorage, external::Storage};

use crate::{
    core::accounts_storage::models::{AccountToAddHelper, AssetsListHelper},
    external::storage::storage_from_ptr,
    parse_address, runtime, HandleError, MatchResult, PostWithResult, ToStringFromPtr, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_create(result_port: c_longlong, storage: *mut c_void) {
    let storage = storage_from_ptr(storage);

    runtime!().spawn(async move {
        async fn internal_fn(storage: Arc<dyn Storage>) -> Result<serde_json::Value, String> {
            let accounts_storage = AccountsStorage::load(storage).await.handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(accounts_storage)));

            serde_json::to_value(ptr as usize).handle_error()
        }

        let result = internal_fn(storage).await.match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_entries(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
        ) -> Result<serde_json::Value, String> {
            let entries = accounts_storage
                .stored_data()
                .await
                .accounts()
                .values()
                .into_iter()
                .cloned()
                .map(AssetsListHelper)
                .collect::<Vec<_>>();

            serde_json::to_value(&entries).handle_error()
        }

        let result = internal_fn(&accounts_storage).await.match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_add_account(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    new_account: *mut c_char,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    let new_account = new_account.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            new_account: String,
        ) -> Result<serde_json::Value, String> {
            let new_account = serde_json::from_str::<AccountToAddHelper>(&new_account)
                .map(|AccountToAddHelper(account_to_add)| account_to_add)
                .handle_error()?;

            let entry = accounts_storage
                .add_account(new_account)
                .await
                .handle_error()?;

            serde_json::to_value(&AssetsListHelper(entry)).handle_error()
        }

        let result = internal_fn(&accounts_storage, new_account)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_add_accounts(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    new_accounts: *mut c_char,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    let new_accounts = new_accounts.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            new_accounts: String,
        ) -> Result<serde_json::Value, String> {
            let new_accounts = serde_json::from_str::<Vec<AccountToAddHelper>>(&new_accounts)
                .handle_error()?
                .into_iter()
                .map(|AccountToAddHelper(account_to_add)| account_to_add)
                .collect::<Vec<_>>();

            let entries = accounts_storage
                .add_accounts(new_accounts)
                .await
                .handle_error()?
                .into_iter()
                .map(AssetsListHelper)
                .collect::<Vec<_>>();

            serde_json::to_value(&entries).handle_error()
        }

        let result = internal_fn(&accounts_storage, new_accounts)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_rename_account(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    account: *mut c_char,
    name: *mut c_char,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    let account = account.to_string_from_ptr();
    let name = name.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            account: String,
            name: String,
        ) -> Result<serde_json::Value, String> {
            let entry = accounts_storage
                .rename_account(&account, name)
                .await
                .handle_error()?;

            serde_json::to_value(&AssetsListHelper(entry)).handle_error()
        }

        let result = internal_fn(&accounts_storage, account, name)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_add_token_wallet(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    account: *mut c_char,
    network_group: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    let account = account.to_string_from_ptr();
    let network_group = network_group.to_string_from_ptr();
    let root_token_contract = root_token_contract.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            account: String,
            network_group: String,
            root_token_contract: String,
        ) -> Result<serde_json::Value, String> {
            let root_token_contract = parse_address(&root_token_contract)?;

            let entry = accounts_storage
                .add_token_wallet(&account, &network_group, root_token_contract)
                .await
                .handle_error()?;

            serde_json::to_value(&AssetsListHelper(entry)).handle_error()
        }

        let result = internal_fn(
            &accounts_storage,
            account,
            network_group,
            root_token_contract,
        )
        .await
        .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_remove_token_wallet(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    account: *mut c_char,
    network_group: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    let account = account.to_string_from_ptr();
    let network_group = network_group.to_string_from_ptr();
    let root_token_contract = root_token_contract.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            account: String,
            network_group: String,
            root_token_contract: String,
        ) -> Result<serde_json::Value, String> {
            let root_token_contract = parse_address(&root_token_contract)?;

            let entry = accounts_storage
                .remove_token_wallet(&account, &network_group, &root_token_contract)
                .await
                .handle_error()?;

            serde_json::to_value(&AssetsListHelper(entry)).handle_error()
        }

        let result = internal_fn(
            &accounts_storage,
            account,
            network_group,
            root_token_contract,
        )
        .await
        .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_remove_account(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    account: *mut c_char,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    let account = account.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            account: String,
        ) -> Result<serde_json::Value, String> {
            let entry = accounts_storage
                .remove_account(&account)
                .await
                .handle_error()?
                .map(AssetsListHelper);

            serde_json::to_value(entry).handle_error()
        }

        let result = internal_fn(&accounts_storage, account).await.match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_remove_accounts(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
    accounts: *mut c_char,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    let accounts = accounts.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
            accounts: String,
        ) -> Result<serde_json::Value, String> {
            let accounts = serde_json::from_str::<Vec<&str>>(&accounts).handle_error()?;

            let entries = accounts_storage
                .remove_accounts(accounts)
                .await
                .handle_error()?
                .into_iter()
                .map(AssetsListHelper)
                .collect::<Vec<_>>();

            serde_json::to_value(&entries).handle_error()
        }

        let result = internal_fn(&accounts_storage, accounts)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_clear(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
        ) -> Result<serde_json::Value, String> {
            accounts_storage.clear().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let result = internal_fn(&accounts_storage).await.match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_reload(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    runtime!().spawn(async move {
        async fn internal_fn(
            accounts_storage: &AccountsStorage,
        ) -> Result<serde_json::Value, String> {
            accounts_storage.reload().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let result = internal_fn(&accounts_storage).await.match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_verify_data(data: *mut c_char) -> *mut c_char {
    let data = data.to_string_from_ptr();

    fn internal_fn(data: String) -> Result<serde_json::Value, String> {
        let is_valid = AccountsStorage::verify(&data).is_ok();

        serde_json::to_value(is_valid).handle_error()
    }

    internal_fn(data).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<AccountsStorage>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<AccountsStorage>);
}

unsafe fn accounts_storage_from_ptr(ptr: *mut c_void) -> Arc<AccountsStorage> {
    Arc::from_raw(ptr as *mut AccountsStorage)
}
