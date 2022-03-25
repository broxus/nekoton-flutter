use crate::{models::MatchResult, runtime, ToStringFromPtr, RUNTIME};
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nekoton::external::Storage;
use pickledb::{PickleDb, PickleDbDumpPolicy, SerializationMethod};
use std::{ffi::c_void, os::raw::c_char, path::Path, sync::Arc};
use tokio::sync::Mutex;

#[no_mangle]
pub unsafe extern "C" fn create_storage(dir: *mut c_char) -> *mut c_void {
    let dir = dir.to_string_from_ptr();

    fn internal_fn(dir: String) -> Result<u64, String> {
        let path = Path::new(&dir).join("nekoton_storage.db");

        let db = match PickleDb::load(
            path.clone(),
            PickleDbDumpPolicy::AutoDump,
            SerializationMethod::Json,
        ) {
            Ok(db) => db,
            Err(_) => PickleDb::new(
                path,
                PickleDbDumpPolicy::AutoDump,
                SerializationMethod::Json,
            ),
        };
        let db = Arc::new(Mutex::new(db));

        let storage = StorageImpl { db };

        let ptr = Box::into_raw(Box::new(Arc::new(storage))) as *mut c_void as u64;

        Ok(ptr)
    }

    internal_fn(dir).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn clone_storage_ptr(storage: *mut c_void) -> *mut c_void {
    let storage = storage as *mut Arc<StorageImpl>;
    let cloned = Arc::clone(&*storage);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_storage_ptr(storage: *mut c_void) {
    let storage = storage as *mut Arc<StorageImpl>;

    let _ = Box::from_raw(storage);
}

pub struct StorageImpl {
    pub db: Arc<Mutex<PickleDb>>,
}

#[async_trait]
impl Storage for StorageImpl {
    async fn get(&self, key: &str) -> Result<Option<String>> {
        Ok(self.db.lock().await.get::<String>(key))
    }

    async fn set(&self, key: &str, value: &str) -> Result<()> {
        self.db
            .lock()
            .await
            .set::<String>(key, &value.to_owned())
            .map_err(|e| anyhow!("{}", e))
    }

    fn set_unchecked(&self, key: &str, value: &str) {
        let db = self.db.clone();
        let key = key.to_string();
        let value = value.to_string();

        runtime!().spawn(async move {
            let _ = db.lock().await.set::<String>(&key, &value.to_owned());
        });
    }

    async fn remove(&self, key: &str) -> Result<()> {
        self.db
            .lock()
            .await
            .rem(key)
            .map(|_| ())
            .map_err(|e| anyhow!("{}", e))
    }

    fn remove_unchecked(&self, key: &str) {
        let db = self.db.clone();
        let key = key.to_string();

        runtime!().spawn(async move {
            let _ = db.lock().await.rem(&key);
        });
    }
}
