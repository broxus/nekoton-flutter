mod models;

use std::{
    os::raw::{c_char, c_longlong, c_void},
    sync::Arc,
};

use nekoton::{
    core::accounts_storage::{AccountsStorage, ACCOUNTS_STORAGE_KEY},
    external::Storage,
};

use crate::{
    core::accounts_storage::models::AccountToAdd,
    external::storage::storage_from_ptr,
    models::{HandleError, MatchResult, ToNekoton, ToOptionalCStringPtr, ToSerializable},
    parse_address, runtime, send_to_result_port, ToCStringPtr, ToStringFromPtr, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_key() -> *mut c_char {
    ACCOUNTS_STORAGE_KEY.to_owned().to_cstring_ptr()
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_create(result_port: c_longlong, storage: *mut c_void) {
    let storage = storage_from_ptr(storage);

    runtime!().spawn(async move {
        async fn internal_fn(storage: Arc<dyn Storage>) -> Result<u64, String> {
            let accounts_storage = AccountsStorage::load(storage).await.handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(accounts_storage))) as u64;

            Ok(ptr)
        }

        let result = internal_fn(storage).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_entries(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    runtime!().spawn(async move {
        async fn internal_fn(accounts_storage: &AccountsStorage) -> Result<u64, String> {
            let entries = accounts_storage
                .stored_data()
                .await
                .accounts()
                .values()
                .into_iter()
                .map(|e| e.to_owned().to_serializable())
                .collect::<Vec<_>>();

            let entries = serde_json::to_string(&entries)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(entries)
        }

        let result = internal_fn(&accounts_storage).await.match_result();

        send_to_result_port(result_port, result);
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
        ) -> Result<u64, String> {
            let new_account = serde_json::from_str::<AccountToAdd>(&new_account)
                .handle_error()?
                .to_nekoton();

            let entry = accounts_storage
                .add_account(new_account)
                .await
                .handle_error()?
                .to_serializable();

            let entry = serde_json::to_string(&entry)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(entry)
        }

        let result = internal_fn(&accounts_storage, new_account)
            .await
            .match_result();

        send_to_result_port(result_port, result);
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
        ) -> Result<u64, String> {
            let new_accounts = serde_json::from_str::<Vec<AccountToAdd>>(&new_accounts)
                .handle_error()?
                .into_iter()
                .map(|e| e.to_nekoton())
                .collect::<Vec<_>>();

            let entries = accounts_storage
                .add_accounts(new_accounts)
                .await
                .handle_error()?
                .into_iter()
                .map(|e| e.to_serializable())
                .collect::<Vec<_>>();

            let entries = serde_json::to_string(&entries)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(entries)
        }

        let result = internal_fn(&accounts_storage, new_accounts)
            .await
            .match_result();

        send_to_result_port(result_port, result);
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
        ) -> Result<u64, String> {
            let entry = accounts_storage
                .rename_account(&account, name)
                .await
                .handle_error()?
                .to_serializable();

            let entry = serde_json::to_string(&entry)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(entry)
        }

        let result = internal_fn(&accounts_storage, account, name)
            .await
            .match_result();

        send_to_result_port(result_port, result);
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
        ) -> Result<u64, String> {
            let root_token_contract = parse_address(&root_token_contract)?;

            let entry = accounts_storage
                .add_token_wallet(&account, &network_group, root_token_contract)
                .await
                .handle_error()?
                .to_serializable();

            let entry = serde_json::to_string(&entry)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(entry)
        }

        let result = internal_fn(
            &accounts_storage,
            account,
            network_group,
            root_token_contract,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
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
        ) -> Result<u64, String> {
            let root_token_contract = parse_address(&root_token_contract)?;

            let entry = accounts_storage
                .remove_token_wallet(&account, &network_group, &root_token_contract)
                .await
                .handle_error()?
                .to_serializable();

            let entry = serde_json::to_string(&entry)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(entry)
        }

        let result = internal_fn(
            &accounts_storage,
            account,
            network_group,
            root_token_contract,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
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
        ) -> Result<u64, String> {
            let entry = accounts_storage
                .remove_account(&account)
                .await
                .handle_error()?
                .map(|e| e.to_serializable());

            let entry = entry
                .as_ref()
                .map(serde_json::to_string)
                .transpose()
                .handle_error()?
                .to_optional_cstring_ptr() as u64;

            Ok(entry)
        }

        let result = internal_fn(&accounts_storage, account).await.match_result();

        send_to_result_port(result_port, result);
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
        ) -> Result<u64, String> {
            let accounts = serde_json::from_str::<Vec<&str>>(&accounts).handle_error()?;

            let entries = accounts_storage
                .remove_accounts(accounts)
                .await
                .handle_error()?
                .into_iter()
                .map(|e| e.to_serializable())
                .collect::<Vec<_>>();

            let entries = serde_json::to_string(&entries)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(entries)
        }

        let result = internal_fn(&accounts_storage, accounts)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_clear(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    runtime!().spawn(async move {
        async fn internal_fn(accounts_storage: &AccountsStorage) -> Result<u64, String> {
            accounts_storage.clear().await.handle_error()?;

            Ok(u64::default())
        }

        let result = internal_fn(&accounts_storage).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_reload(
    result_port: c_longlong,
    accounts_storage: *mut c_void,
) {
    let accounts_storage = accounts_storage_from_ptr(accounts_storage);

    runtime!().spawn(async move {
        async fn internal_fn(accounts_storage: &AccountsStorage) -> Result<u64, String> {
            accounts_storage.reload().await.handle_error()?;

            Ok(u64::default())
        }

        let result = internal_fn(&accounts_storage).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_accounts_storage_verify_data(data: *mut c_char) -> *mut c_void {
    let data = data.to_string_from_ptr();

    fn internal_fn(data: String) -> Result<u64, String> {
        let is_valid = AccountsStorage::verify(&data).is_ok() as u64;

        Ok(is_valid)
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
