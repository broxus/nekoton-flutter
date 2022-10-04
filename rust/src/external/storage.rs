use std::{
    os::raw::{c_char, c_longlong, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::{bail, Result};
use async_trait::async_trait;
use nekoton::external::Storage;
use tokio::sync::oneshot::{channel, Sender};

use crate::{HandleError, MatchResult, ToPtrAddress, ToPtrFromAddress, ISOLATE_MESSAGE_POST_ERROR};

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

        let tx = Box::into_raw(Box::new(tx)).to_ptr_address();
        let key = key.to_owned();

        let request = serde_json::to_string(&(tx.clone(), key))?;

        match self.get_port.post(request) {
            true => rx.await.unwrap(),
            false => {
                unsafe {
                    Box::from_raw(tx.to_ptr_from_address::<Sender<Result<Option<String>>>>());
                }

                bail!(ISOLATE_MESSAGE_POST_ERROR)
            },
        }
    }

    async fn set(&self, key: &str, value: &str) -> Result<()> {
        let (tx, rx) = channel::<Result<()>>();

        let tx = Box::into_raw(Box::new(tx)).to_ptr_address();
        let key = key.to_owned();
        let value = value.to_owned();

        let request = serde_json::to_string(&(tx.clone(), key, value))?;

        match self.set_port.post(request) {
            true => rx.await.unwrap(),
            false => {
                unsafe {
                    Box::from_raw(tx.to_ptr_from_address::<Sender<Result<()>>>());
                }

                bail!(ISOLATE_MESSAGE_POST_ERROR)
            },
        }
    }

    fn set_unchecked(&self, key: &str, value: &str) {
        let key = key.to_owned();
        let value = value.to_owned();

        let request = serde_json::to_string(&(key, value)).unwrap();

        self.set_unchecked_port.post(request);
    }

    async fn remove(&self, key: &str) -> Result<()> {
        let (tx, rx) = channel::<Result<()>>();

        let tx = Box::into_raw(Box::new(tx)).to_ptr_address();
        let key = key.to_owned();

        let request = serde_json::to_string(&(tx.clone(), key))?;

        match self.remove_port.post(request) {
            true => rx.await.unwrap(),
            false => {
                unsafe {
                    Box::from_raw(tx.to_ptr_from_address::<Sender<Result<()>>>());
                }

                bail!(ISOLATE_MESSAGE_POST_ERROR)
            },
        }
    }

    fn remove_unchecked(&self, key: &str) {
        let key = key.to_owned();

        let request = serde_json::to_string(&key).unwrap();

        self.remove_unchecked_port.post(request);
    }
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

        serde_json::to_value(ptr.to_ptr_address()).handle_error()
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
pub unsafe extern "C" fn nt_storage_free_ptr(ptr: *mut c_void) {
    println!("nt_storage_free_ptr");
    Box::from_raw(ptr as *mut Arc<StorageImpl>);
}
