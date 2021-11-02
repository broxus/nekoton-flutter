use crate::{
    match_result,
    models::{NativeError, NativeStatus},
    runtime, send_to_result_port, FromPtr, RUNTIME,
};
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nekoton::external::Storage;
use pickledb::{PickleDb, PickleDbDumpPolicy, SerializationMethod};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    path::Path,
    sync::Arc,
    u64,
};
use tokio::sync::Mutex;

pub type MutexStorage = Mutex<Option<Arc<StorageImpl>>>;

pub const STORAGE_NOT_FOUND: &str = "Storage not found";

#[no_mangle]
pub unsafe extern "C" fn get_storage(dir: *mut c_char) -> *mut c_void {
    let result = internal_get_storage(dir);
    match_result(result)
}

fn internal_get_storage(dir: *mut c_char) -> Result<u64, NativeError> {
    let dir = dir.from_ptr();

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
    let db = std::sync::Mutex::new(Some(db));

    let storage = StorageImpl { db };
    let storage = Arc::new(storage);
    let storage = Mutex::new(Some(storage));
    let storage = Arc::new(storage);

    let ptr = Arc::into_raw(storage) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn free_storage(result_port: c_longlong, storage: *mut c_void) {
    let storage = storage as *mut MutexStorage;
    let storage = &(*storage);

    let rt = runtime!();
    rt.spawn(async move {
        let mut storage_guard = storage.lock().await;
        let storage = storage_guard.take();
        match storage {
            Some(storage) => storage,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: STORAGE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = Ok(0);
        let result = match_result(result);

        send_to_result_port(result_port, result);
    });
}

pub struct StorageImpl {
    pub db: std::sync::Mutex<Option<PickleDb>>,
}

#[async_trait]
impl Storage for StorageImpl {
    async fn get(&self, key: &str) -> Result<Option<String>> {
        let mut db_guard = match self.db.lock().ok() {
            Some(db_guard) => db_guard,
            None => return Err(anyhow!("Mutex db error")),
        };

        match db_guard.take() {
            Some(db) => {
                let result = db.get::<String>(key);
                *db_guard = Some(db);
                Ok(result)
            }
            None => return Err(anyhow!("Mutex db error")),
        }
    }

    async fn set(&self, key: &str, value: &str) -> Result<()> {
        let mut db_guard = match self.db.lock().ok() {
            Some(db_guard) => db_guard,
            None => return Err(anyhow!("Mutex db error")),
        };

        match db_guard.take() {
            Some(mut db) => {
                let result = db
                    .set::<String>(key, &value.to_owned())
                    .map_err(|e| anyhow!("{}", e));
                *db_guard = Some(db);
                result
            }
            None => return Err(anyhow!("Mutex db error")),
        }
    }

    fn set_unchecked(&self, key: &str, value: &str) {
        let mut db_guard = match self.db.lock().ok() {
            Some(db_guard) => db_guard,
            None => return,
        };

        let _ = match db_guard.take() {
            Some(mut db) => {
                let result = db.set::<String>(key, &value.to_owned());
                *db_guard = Some(db);
                result
            }
            None => return,
        };
    }

    async fn remove(&self, key: &str) -> Result<()> {
        let mut db_guard = match self.db.lock().ok() {
            Some(db_guard) => db_guard,
            None => return Err(anyhow!("Mutex db error")),
        };

        match db_guard.take() {
            Some(mut db) => {
                let result = db.rem(key).map(|_| ()).map_err(|e| anyhow!("{}", e));
                *db_guard = Some(db);
                result
            }
            None => return Err(anyhow!("Mutex db error")),
        }
    }

    fn remove_unchecked(&self, key: &str) {
        let mut db_guard = match self.db.lock().ok() {
            Some(db_guard) => db_guard,
            None => return,
        };

        let _ = match db_guard.take() {
            Some(mut db) => {
                let result = db.rem(key);
                *db_guard = Some(db);
                result
            }
            None => return,
        };
    }
}
