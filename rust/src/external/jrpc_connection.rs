use std::{
    os::raw::{c_char, c_longlong},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::{bail, Result};
use async_trait::async_trait;
use nekoton::external::{JrpcConnection, JrpcRequest};
use tokio::sync::oneshot::channel;

use crate::{
    channel_err_new, ffi_box, nt_channel_err_free_ptr, HandleError, MatchResult, ToPtrAddress,
    ToPtrFromAddress, ISOLATE_MESSAGE_POST_ERROR,
};

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
    async fn post(&self, req: JrpcRequest) -> Result<String> {
        let (tx, rx) = channel::<Result<String>>();

        let tx = channel_err_new(tx).to_ptr_address();
        let data = req.data;

        let request = serde_json::to_string(&(tx.clone(), data))?;

        match self.port.post(request) {
            true => rx.await.unwrap(),
            false => {
                unsafe {
                    nt_channel_err_free_ptr(tx.to_ptr_from_address());
                }

                bail!(ISOLATE_MESSAGE_POST_ERROR)
            },
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_connection_create(port: c_longlong) -> *mut c_char {
    fn internal_fn(port: i64) -> Result<serde_json::Value, String> {
        let jrpc_connection = JrpcConnectionImpl::new(port);

        let ptr = jrpc_connection_new(Arc::new(jrpc_connection));
        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(port).match_result()
}

ffi_box!(jrpc_connection, Arc<JrpcConnectionImpl>);
