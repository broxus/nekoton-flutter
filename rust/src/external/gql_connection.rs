use crate::{
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    runtime, send_to_result_port, FromPtr, RUNTIME,
};
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nekoton::external::GqlConnection;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    sync::Arc,
    u64,
};
use tokio::sync::Mutex;

pub type MutexGqlConnection = Mutex<Option<Arc<GqlConnectionImpl>>>;

pub const GQL_CONNECTION_NOT_FOUND: &str = "Gql connection not found";

#[no_mangle]
pub unsafe extern "C" fn get_gql_connection(url: *mut c_char) -> *mut c_void {
    let result = internal_get_gql_connection(url);
    match_result(result)
}

fn internal_get_gql_connection(url: *mut c_char) -> Result<u64, NativeError> {
    let url = url.from_ptr();
    let url = reqwest::Url::parse(&url)
        .handle_error(NativeStatus::ConversionError)?
        .join("graphql")
        .handle_error(NativeStatus::ConversionError)?;

    let client = reqwest::Client::new();

    let connection = GqlConnectionImpl { url, client };
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
    pub client: reqwest::Client,
    pub url: reqwest::Url,
}

#[async_trait]
impl GqlConnection for GqlConnectionImpl {
    fn is_local(&self) -> bool {
        false
    }

    async fn post(&self, data: &str) -> Result<String> {
        self.client
            .post(self.url.clone())
            .header("Content-Type", "application/json")
            .body(data.to_owned())
            .send()
            .await?
            .text()
            .await
            .map_err(|e| anyhow!("{}", e))
    }
}
