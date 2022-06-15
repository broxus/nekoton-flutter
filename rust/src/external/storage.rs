use std::{
    os::raw::{c_char, c_longlong, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::Result;
use async_trait::async_trait;
use nekoton::external::Storage;
use serde::Serialize;
use tokio::sync::oneshot::channel;

use crate::{HandleError, MatchResult, PostWithResult};

pub struct StorageImpl {
    get_port: Isolate,
    set_port: Isolate,
    set_unchecked_port: Isolate,
    remove_port: Isolate,
    remove_unchecked_port: Isolate,
}

impl StorageImpl {
    pub fn new(
        get_port: i64,
        set_port: i64,
        set_unchecked_port: i64,
        remove_port: i64,
        remove_unchecked_port: i64,
    ) -> Self {
        Self {
            get_port: Isolate::new(get_port),
            set_port: Isolate::new(set_port),
            set_unchecked_port: Isolate::new(set_unchecked_port),
            remove_port: Isolate::new(remove_port),
            remove_unchecked_port: Isolate::new(remove_unchecked_port),
        }
    }
}

#[async_trait]
impl Storage for StorageImpl {
    async fn get(&self, key: &str) -> Result<Option<String>> {
        let (tx, rx) = channel::<Result<Option<String>>>();

        let tx = Box::into_raw(Box::new(tx)) as usize;
        let key = key.to_owned();

        let request = serde_json::to_string(&StorageGetRequest { tx, key })?;

        self.get_port.post_with_result(request).unwrap();

        rx.await.unwrap()
    }

    async fn set(&self, key: &str, value: &str) -> Result<()> {
        let (tx, rx) = channel::<Result<()>>();

        let tx = Box::into_raw(Box::new(tx)) as usize;
        let key = key.to_owned();
        let value = value.to_owned();

        let request = serde_json::to_string(&StorageSetRequest { tx, key, value })?;

        self.set_port.post_with_result(request).unwrap();

        rx.await.unwrap()
    }

    fn set_unchecked(&self, key: &str, value: &str) {
        let key = key.to_owned();
        let value = value.to_owned();

        let request = serde_json::to_string(&StorageSetUncheckedRequest { key, value }).unwrap();

        self.set_unchecked_port.post_with_result(request).unwrap();
    }

    async fn remove(&self, key: &str) -> Result<()> {
        let (tx, rx) = channel::<Result<()>>();

        let tx = Box::into_raw(Box::new(tx)) as usize;
        let key = key.to_owned();

        let request = serde_json::to_string(&StorageRemoveRequest { tx, key })?;

        self.remove_port.post_with_result(request).unwrap();

        rx.await.unwrap()
    }

    fn remove_unchecked(&self, key: &str) {
        let key = key.to_owned();

        let request = serde_json::to_string(&StorageRemoveUncheckedRequest { key }).unwrap();

        self.remove_unchecked_port
            .post_with_result(request)
            .unwrap();
    }
}

#[derive(Serialize)]
pub struct StorageGetRequest {
    pub tx: usize,
    pub key: String,
}

#[derive(Serialize)]
pub struct StorageSetRequest {
    pub tx: usize,
    pub key: String,
    pub value: String,
}

#[derive(Serialize)]
pub struct StorageSetUncheckedRequest {
    pub key: String,
    pub value: String,
}

#[derive(Serialize)]
pub struct StorageRemoveRequest {
    pub tx: usize,
    pub key: String,
}

#[derive(Serialize)]
pub struct StorageRemoveUncheckedRequest {
    pub key: String,
}

#[no_mangle]
pub unsafe extern "C" fn nt_storage_create(
    get_port: c_longlong,
    set_port: c_longlong,
    set_unchecked_port: c_longlong,
    remove_port: c_longlong,
    remove_unchecked_port: c_longlong,
) -> *mut c_char {
    fn internal_fn(
        get_port: i64,
        set_port: i64,
        set_unchecked_port: i64,
        remove_port: i64,
        remove_unchecked_port: i64,
    ) -> Result<serde_json::Value, String> {
        let storage = StorageImpl::new(
            get_port,
            set_port,
            set_unchecked_port,
            remove_port,
            remove_unchecked_port,
        );

        let ptr = Box::into_raw(Box::new(Arc::new(storage)));

        serde_json::to_value(ptr as usize).handle_error()
    }

    internal_fn(
        get_port,
        set_port,
        set_unchecked_port,
        remove_port,
        remove_unchecked_port,
    )
    .match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_storage_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<StorageImpl>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_storage_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<StorageImpl>);
}

pub unsafe fn storage_from_ptr(ptr: *mut c_void) -> Arc<StorageImpl> {
    Arc::from_raw(ptr as *mut StorageImpl)
}
