use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::{bail, Result};
use async_trait::async_trait;
use nekoton::external::JrpcConnection;
use serde::Serialize;
use tokio::sync::oneshot::{channel, Sender};

use crate::{HandleError, MatchResult, ToPtrAddress, ToPtrFromAddress};

pub struct JrpcConnectionImpl {
    port: Isolate,
}

impl JrpcConnectionImpl {
    pub fn new(port: i64) -> Self {
        Self {
            port: Isolate::new(port),
        }
    }
}

#[async_trait]
impl JrpcConnection for JrpcConnectionImpl {
    async fn post(&self, data: &str) -> Result<String> {
        let (tx, rx) = channel::<Result<String>>();

        let tx = Box::into_raw(Box::new(tx)).to_ptr_address();
        let data = data.to_owned();

        let request = serde_json::to_string(&JrpcConnectionPostRequest {
            tx: tx.clone(),
            data,
        })?;

        match self.port.post(request) {
            true => rx.await.unwrap(),
            false => {
                unsafe {
                    Box::from_raw(tx.to_ptr_from_address::<Sender<Result<String>>>());
                }

                bail!("Message was not posted successfully")
            },
        }
    }
}

#[derive(Serialize)]
pub struct JrpcConnectionPostRequest {
    pub tx: String,
    pub data: String,
}

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_connection_create(port: c_longlong) -> *mut c_char {
    fn internal_fn(port: i64) -> Result<serde_json::Value, String> {
        let jrpc_connection = JrpcConnectionImpl::new(port);

        let ptr = Box::into_raw(Box::new(Arc::new(jrpc_connection)));

        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(port).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_connection_free_ptr(ptr: *mut c_void) {
    println!("nt_jrpc_connection_free_ptr");
    Box::from_raw(ptr as *mut Arc<JrpcConnectionImpl>);
}
