use crate::{runtime, FromPtr, RUNTIME};
use allo_isolate::Isolate;
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nekoton::external::Storage;
use serde::Serialize;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_uint},
    sync::Arc,
};
use tokio::sync::{
    oneshot::{self, Sender},
    Mutex,
};

type MutexStorageSender = Mutex<Option<Sender<Result<Option<String>, String>>>>;

const STORAGE_REQUEST_ERROR: &str = "Unable to make storage request";

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
    let tx = Arc::into_raw(tx) as usize;

    let request = StorageRequest {
        tx,
        key,
        value,
        request_type,
    };
    let request = serde_json::to_string(&request).map_err(|e| anyhow!("{}", e))?;

    let isolate = Isolate::new(port);
    let sent = isolate.post(request);

    if sent {
        let result = rx.await.map_err(|e| anyhow!("{}", e))?;

        result.map_err(|e| anyhow!("{}", e))
    } else {
        let tx = tx as *mut MutexStorageSender;
        unsafe { Arc::from_raw(tx) };

        Err(anyhow!(STORAGE_REQUEST_ERROR.to_owned()))
    }
}

#[derive(Serialize)]
pub struct StorageRequest {
    pub tx: usize,
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
    tx: *mut c_void,
    is_successful: c_uint,
    value: *mut c_char,
) {
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
        let tx = tx.take().unwrap();

        let result;

        if is_successful {
            result = Ok(value);
        } else {
            result = Err(value.unwrap());
        }

        tx.send(result).unwrap();
    });
}
