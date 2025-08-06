use std::{
    os::raw::{c_char, c_longlong},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::{bail, Result};
use async_trait::async_trait;
use nekoton::external::{ProtoConnection, ProtoRequest};
use tokio::sync::oneshot::channel;

use crate::{
    channel_err_new, ffi_box, nt_channel_err_free_ptr, HandleError, MatchResult, ToPtrAddress,
    ToPtrFromAddress, ISOLATE_MESSAGE_POST_ERROR,
};

pub struct ProtoConnectionImpl {
    port: Isolate,
}

impl ProtoConnectionImpl {
    pub fn new(port: i64) -> Self {
        Self {
            port: Isolate::new(port),
        }
    }
}

#[async_trait]
impl ProtoConnection for ProtoConnectionImpl {
    async fn post(&self, req: ProtoRequest) -> Result<Vec<u8>> {
        let (tx, rx) = channel::<Result<String>>();

        let tx = channel_err_new(tx).to_ptr_address();
        let data = base64::encode(&req.data);

        let request = serde_json::to_string(&(tx.clone(), data))?;

        match self.port.post(request) {
            true => {
                let response = rx.await.unwrap()?;
                // Decode the base64 response from Dart back to bytes
                let response_bytes = base64::decode(&response)
                    .map_err(|e| anyhow::anyhow!("Failed to decode base64 response: {}", e))?;
                Ok(response_bytes)
            },
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
pub unsafe extern "C" fn nt_proto_connection_create(port: c_longlong) -> *mut c_char {
    fn internal_fn(port: i64) -> Result<serde_json::Value, String> {
        let proto_connection = ProtoConnectionImpl::new(port);

        let ptr = proto_connection_new(Arc::new(proto_connection));
        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(port).match_result()
}

ffi_box!(proto_connection, Arc<ProtoConnectionImpl>);
