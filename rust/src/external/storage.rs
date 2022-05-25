use std::{
    ffi::{c_char, c_longlong, c_void},
    path::Path,
    sync::Arc,
};

use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nekoton::external::Storage;
use pickledb::{PickleDb, PickleDbDumpPolicy, SerializationMethod};
use tokio::sync::RwLock;

use crate::{
    models::{HandleError, MatchResult, ToOptionalCStringPtr},
    runtime, send_to_result_port, ToStringFromPtr, RUNTIME,
};

pub const NEKOTON_STORAGE_FILENAME: &str = "nekoton_storage.db";

pub struct StorageImpl {
    db: Arc<RwLock<PickleDb>>,
}

impl StorageImpl {
    pub fn new(db: Arc<RwLock<PickleDb>>) -> Self {
        Self { db }
    }
}

#[async_trait]
impl Storage for StorageImpl {
    async fn get(&self, key: &str) -> Result<Option<String>> {
        Ok(self.db.read().await.get::<String>(key))
    }

    async fn set(&self, key: &str, value: &str) -> Result<()> {
        self.db
            .write()
            .await
            .set::<String>(key, &value.to_owned())
            .map_err(|e| anyhow!("{}", e))
    }

    fn set_unchecked(&self, key: &str, value: &str) {
        let db = self.db.clone();
        let key = key.to_string();
        let value = value.to_string();

        runtime!().spawn(async move {
            let _ = db.write().await.set::<String>(&key, &value.to_owned());
        });
    }

    async fn remove(&self, key: &str) -> Result<()> {
        self.db
            .write()
            .await
            .rem(key)
            .map(|_| ())
            .map_err(|e| anyhow!("{}", e))
    }

    fn remove_unchecked(&self, key: &str) {
        let db = self.db.clone();
        let key = key.to_string();

        runtime!().spawn(async move {
            let _ = db.write().await.rem(&key);
        });
    }
}

#[no_mangle]
pub unsafe extern "C" fn nt_storage_create(dir: *mut c_char) -> *mut c_void {
    let dir = dir.to_string_from_ptr();

    fn internal_fn(dir: String) -> Result<u64, String> {
        let db_path = Path::new(&dir).join(NEKOTON_STORAGE_FILENAME);

        let db = match PickleDb::load(
            &db_path,
            PickleDbDumpPolicy::AutoDump,
            SerializationMethod::Json,
        ) {
            Ok(db) => db,
            Err(_) => PickleDb::new(
                &db_path,
                PickleDbDumpPolicy::AutoDump,
                SerializationMethod::Json,
            ),
        };

        let db = Arc::new(RwLock::new(db));

        let storage = StorageImpl::new(db);

        let ptr = Box::into_raw(Box::new(Arc::new(storage))) as u64;

        Ok(ptr)
    }

    internal_fn(dir).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_storage_get(
    result_port: c_longlong,
    storage: *mut c_void,
    key: *mut c_char,
) {
    let storage = storage_from_ptr(storage);

    let key = key.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(storage: Arc<dyn Storage>, key: String) -> Result<u64, String> {
            let value = storage
                .get(&key)
                .await
                .handle_error()?
                .to_optional_cstring_ptr() as u64;

            Ok(value)
        }

        let result = internal_fn(storage, key).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_storage_set(
    result_port: c_longlong,
    storage: *mut c_void,
    key: *mut c_char,
    value: *mut c_char,
) {
    let storage = storage_from_ptr(storage);

    let key = key.to_string_from_ptr();
    let value = value.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            storage: Arc<dyn Storage>,
            key: String,
            value: String,
        ) -> Result<u64, String> {
            storage.set(&key, &value).await.handle_error()?;

            Ok(u64::default())
        }

        let result = internal_fn(storage, key, value).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_storage_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<StorageImpl>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_storage_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<StorageImpl>);
}

pub unsafe fn storage_from_ptr(ptr: *mut c_void) -> Arc<dyn Storage> {
    Arc::from_raw(ptr as *mut StorageImpl)
}
