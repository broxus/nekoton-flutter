mod gql_connection;
pub mod storage;

use self::{gql_connection::GqlConnectionImpl, storage::StorageImpl};
use crate::{match_result, models::NativeError};
use std::{
    ffi::c_void,
    os::raw::{c_longlong, c_ulonglong},
    sync::Arc,
    u64,
};
use tokio::sync::Mutex;

pub type MutexStorage = Mutex<Arc<StorageImpl>>;
pub type MutexGqlConnection = Mutex<Arc<GqlConnectionImpl>>;

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
pub unsafe extern "C" fn get_gql_connection(port: c_longlong) -> *mut c_void {
    let result = internal_get_gql_connection(port);
    match_result(result)
}

fn internal_get_gql_connection(port: c_longlong) -> Result<u64, NativeError> {
    let connection = GqlConnectionImpl { port };
    let connection = Arc::new(connection);
    let connection = Mutex::new(connection);
    let connection = Arc::new(connection);

    let ptr = Arc::into_raw(connection) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}
