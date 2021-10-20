use crate::{match_result, models::NativeError, runtime, FromPtr, RUNTIME};
use allo_isolate::Isolate;
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nekoton::external::Storage;
use serde::Serialize;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_uint, c_ulonglong},
    sync::Arc,
    time::Duration,
    u64,
};
use tokio::{
    sync::{
        oneshot::{self, Sender},
        Mutex,
    },
    time::timeout,
};

pub type MutexStorage = Mutex<Arc<StorageImpl>>;
pub type MutexStorageSender = Mutex<Option<Sender<Result<Option<String>, String>>>>;

const STORAGE_REQUEST_ERROR: &str = "Unable to make storage request";

#[no_mangle]
pub unsafe extern "C" fn get_storage(port: c_longlong) -> *mut c_void {
    let result = internal_get_storage(port);
    match_result(result)
}

fn internal_get_storage(port: c_longlong) -> Result<u64, NativeError> {
    let storage = StorageImpl { port };
    let storage = Arc::new(storage);
    let storage = Mutex::new(storage);
    let storage = Arc::new(storage);

    let ptr = Arc::into_raw(storage) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn free_storage(storage: *mut c_void) {
    let storage = storage as *mut MutexStorage;
    Arc::from_raw(storage);
}

pub struct StorageImpl {
    pub port: i64,
}

#[async_trait]
impl Storage for StorageImpl {
    async fn get(&self, key: &str) -> Result<Option<String>> {
        let key = key.to_owned();
        let value = make_storage_request(self.port, key, None, StorageRequestType::Get).await?;
        Ok(value)
    }

    async fn set(&self, key: &str, value: &str) -> Result<()> {
        let key = key.to_owned();
        let value = value.to_owned();
        make_storage_request(self.port, key, Some(value), StorageRequestType::Set).await?;
        Ok(())
    }

    fn set_unchecked(&self, key: &str, value: &str) {
        let key = key.to_owned();
        let value = value.to_owned();
        let _ = make_storage_request(self.port, key, Some(value), StorageRequestType::Set);
    }

    async fn remove(&self, key: &str) -> Result<()> {
        let key = key.to_owned();
        make_storage_request(self.port, key, None, StorageRequestType::Remove).await?;
        Ok(())
    }

    fn remove_unchecked(&self, key: &str) {
        let key = key.to_owned();
        let _ = make_storage_request(self.port, key, None, StorageRequestType::Remove);
    }
}

async fn make_storage_request(
    port: i64,
    key: String,
    value: Option<String>,
    request_type: StorageRequestType,
) -> Result<Option<String>> {
    let (tx, rx) = oneshot::channel::<Result<Option<String>, String>>();
    let tx = Mutex::new(Some(tx));
    let tx = Arc::new(tx);
    let tx = Arc::into_raw(tx) as u64;

    let request = StorageRequest {
        tx: tx.to_string(),
        key,
        value,
        request_type,
    };
    let request = serde_json::to_string(&request).map_err(|e| anyhow!("{}", e))?;

    let isolate = Isolate::new(port);
    let sent = isolate.post(request);

    if sent {
        timeout(Duration::from_secs(60), rx)
            .await
            .map_err(|e| anyhow!("{}", e))?
            .map_err(|e| anyhow!("{}", e))?
            .map_err(|e| anyhow!("{}", e))
    } else {
        let tx = tx as *mut MutexStorageSender;
        unsafe { Arc::from_raw(tx) };

        Err(anyhow!(STORAGE_REQUEST_ERROR.to_owned()))
    }
}

#[derive(Serialize)]
pub struct StorageRequest {
    pub tx: String,
    pub key: String,
    pub value: Option<String>,
    pub request_type: StorageRequestType,
}

#[derive(Serialize)]
pub enum StorageRequestType {
    Get,
    Set,
    Remove,
}

#[no_mangle]
pub unsafe extern "C" fn resolve_storage_request(
    tx: *mut c_char,
    is_successful: c_uint,
    value: *mut c_char,
) {
    let tx = tx.from_ptr().parse::<u64>().unwrap();
    let tx = tx as *mut c_void;
    let tx = tx as *mut MutexStorageSender;
    let tx = Arc::from_raw(tx);
    let is_successful = is_successful != 0;
    let value = match value.is_null() {
        true => None,
        false => Some(value.from_ptr()),
    };

    let rt = runtime!();
    rt.spawn(async move {
        let mut tx = tx.lock().await;

        if let Some(tx) = tx.take() {
            let result;

            if is_successful {
                result = Ok(value);
            } else {
                result = Err(value.unwrap_or(String::new()));
            }

            let _ = tx.send(result);
        }
    });
}
