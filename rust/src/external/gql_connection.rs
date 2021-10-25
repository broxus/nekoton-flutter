use crate::{
    match_result,
    models::{NativeError, NativeStatus},
    runtime, send_to_result_port, FromPtr, REQUEST_TIMEOUT, RUNTIME,
};
use allo_isolate::Isolate;
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nekoton::external::GqlConnection;
use serde::Serialize;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_uint, c_ulonglong},
    sync::Arc,
    u64,
};
use tokio::{
    sync::{
        oneshot::{self, Sender},
        Mutex,
    },
    time::timeout,
};

pub type MutexGqlConnection = Mutex<Option<Arc<GqlConnectionImpl>>>;

const GQL_REQUEST_ERROR: &str = "Unable to make gql request";
pub const GQL_CONNECTION_NOT_FOUND: &str = "Gql connection not found";

#[no_mangle]
pub unsafe extern "C" fn get_gql_connection(port: c_longlong) -> *mut c_void {
    let result = internal_get_gql_connection(port);
    match_result(result)
}

fn internal_get_gql_connection(port: c_longlong) -> Result<u64, NativeError> {
    let connection = GqlConnectionImpl { port };
    let connection = Arc::new(connection);
    let connection = Mutex::new(Some(connection));
    let connection = Arc::new(connection);

    let ptr = Arc::into_raw(connection) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn free_gql_connection(result_port: c_longlong, gql_connection: *mut c_void) {
    let gql_connection = gql_connection as *mut MutexGqlConnection;
    let gql_connection = &(*gql_connection);

    let rt = runtime!();
    rt.spawn(async move {
        let mut gql_connection_guard = gql_connection.lock().await;
        let gql_connection = gql_connection_guard.take();
        match gql_connection {
            Some(gql_connection) => gql_connection,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GQL_CONNECTION_NOT_FOUND.to_owned(),
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

pub struct GqlConnectionImpl {
    pub port: i64,
}

#[async_trait]
impl GqlConnection for GqlConnectionImpl {
    fn is_local(&self) -> bool {
        false
    }

    async fn post(&self, data: &str) -> Result<String> {
        let data = data.to_owned();

        let (tx, rx) = oneshot::channel::<Result<String, String>>();
        let tx = Box::new(tx);
        let tx = Box::into_raw(tx) as u64;

        let request = GqlRequest {
            tx: tx.to_string(),
            data,
        };
        let request = serde_json::to_string(&request).map_err(|e| anyhow!("{}", e))?;

        let isolate = Isolate::new(self.port);
        let sent = isolate.post(request);

        if sent {
            timeout(REQUEST_TIMEOUT, rx)
                .await
                .map_err(|e| anyhow!("{}", e))?
                .map_err(|e| anyhow!("{}", e))?
                .map_err(|e| anyhow!("{}", e))
        } else {
            let tx = tx as *mut Sender<Result<String, String>>;
            unsafe { Box::from_raw(tx) };

            Err(anyhow!(GQL_REQUEST_ERROR.to_owned()))
        }
    }
}

#[derive(Serialize)]
pub struct GqlRequest {
    pub tx: String,
    pub data: String,
}

#[no_mangle]
pub unsafe extern "C" fn resolve_gql_request(
    tx: *mut c_char,
    is_successful: c_uint,
    value: *mut c_char,
) {
    let tx = tx.from_ptr().parse::<u64>().unwrap();
    let tx = tx as *mut c_void;
    let tx = tx as *mut Sender<Result<String, String>>;
    let tx = Box::from_raw(tx);
    let is_successful = is_successful != 0;
    let value = value.from_ptr();

    let result;

    if is_successful {
        result = Ok(value);
    } else {
        result = Err(value);
    }

    let _ = tx.send(result);
}
