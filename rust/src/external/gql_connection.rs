use crate::{runtime, FromPtr, RUNTIME};
use allo_isolate::Isolate;
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use nekoton::external::GqlConnection;
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

type MutexGqlSender = Mutex<Option<Sender<Result<String, String>>>>;

const GQL_REQUEST_ERROR: &str = "Unable to make gql request";

pub struct GqlConnectionImpl {
    pub port: i64,
}

#[async_trait]
impl GqlConnection for GqlConnectionImpl {
    async fn post(&self, data: &str) -> Result<String> {
        let data = data.to_owned();

        let (tx, rx) = oneshot::channel::<Result<String, String>>();
        let tx = Mutex::new(Some(tx));
        let tx = Arc::new(tx);
        let tx = Arc::into_raw(tx) as usize;

        let request = GqlRequest { tx, data };
        let request = serde_json::to_string(&request).map_err(|e| anyhow!("{}", e))?;

        let isolate = Isolate::new(self.port);
        let sent = isolate.post(request);

        if sent {
            let result = rx.await.map_err(|e| anyhow!("{}", e))?;

            result.map_err(|e| anyhow!("{}", e))
        } else {
            let tx = tx as *mut MutexGqlSender;
            unsafe { Arc::from_raw(tx) };

            Err(anyhow!(GQL_REQUEST_ERROR.to_owned()))
        }
    }
}

#[derive(Serialize)]
pub struct GqlRequest {
    pub tx: usize,
    pub data: String,
}

#[no_mangle]
pub unsafe extern "C" fn resolve_gql_request(
    tx: *mut c_void,
    is_successful: c_uint,
    value: *mut c_char,
) {
    let tx = tx as *mut MutexGqlSender;
    let tx = Arc::from_raw(tx);
    let is_successful = is_successful != 0;
    let value = value.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut tx = tx.lock().await;
        let tx = tx.take().unwrap();

        let result;

        if is_successful {
            result = Ok(value);
        } else {
            result = Err(value);
        }

        tx.send(result).unwrap();
    });
}
