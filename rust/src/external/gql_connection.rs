use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_uint},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::{bail, Result};
use async_trait::async_trait;
use nekoton::external::{GqlConnection, GqlRequest};
use tokio::sync::oneshot::{channel, Sender};

use crate::{HandleError, MatchResult, ToPtrAddress, ToPtrFromAddress, ISOLATE_MESSAGE_POST_ERROR};

pub struct GqlConnectionImpl {
    is_local: bool,
    port: Isolate,
}

impl GqlConnectionImpl {
    pub fn new(is_local: bool, port: i64) -> Self {
        Self {
            is_local,
            port: Isolate::new(port),
        }
    }
}

#[async_trait]
impl GqlConnection for GqlConnectionImpl {
    fn is_local(&self) -> bool {
        self.is_local
    }

    async fn post(&self, req: GqlRequest) -> Result<String> {
        let (tx, rx) = channel::<Result<String>>();

        let tx = Box::into_raw(Box::new(tx)).to_ptr_address();
        let data = req.data;

        let request = serde_json::to_string(&(tx.clone(), data))?;

        match self.port.post(request) {
            true => rx.await.unwrap(),
            false => {
                unsafe {
                    Box::from_raw(tx.to_ptr_from_address::<Sender<Result<String>>>());
                }

                bail!(ISOLATE_MESSAGE_POST_ERROR)
            },
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_connection_create(
    is_local: c_uint,
    port: c_longlong,
) -> *mut c_char {
    let is_local = is_local != 0;

    fn internal_fn(is_local: bool, port: i64) -> Result<serde_json::Value, String> {
        let gql_connection = GqlConnectionImpl::new(is_local, port);

        let ptr = Box::into_raw(Box::new(Arc::new(gql_connection)));

        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(is_local, port).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_connection_free_ptr(ptr: *mut c_void) {
    println!("nt_gql_connection_free_ptr");
    Box::from_raw(ptr as *mut Arc<GqlConnectionImpl>);
}
