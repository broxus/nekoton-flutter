use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_uint},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::Result;
use async_trait::async_trait;
use nekoton::external::GqlConnection;
use serde::Serialize;
use tokio::sync::oneshot::channel;

use crate::{HandleError, MatchResult, PostWithResult};

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

    async fn post(&self, data: &str) -> Result<String> {
        let (tx, rx) = channel::<Result<String>>();

        let tx = Box::into_raw(Box::new(tx)) as usize;
        let data = data.to_owned();

        let request = serde_json::to_string(&GqlConnectionPostRequest { tx, data })?;

        self.port.post_with_result(request).unwrap();

        rx.await.unwrap()
    }
}

#[derive(Serialize)]
pub struct GqlConnectionPostRequest {
    pub tx: usize,
    pub data: String,
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

        serde_json::to_value(ptr as usize).handle_error()
    }

    internal_fn(is_local, port).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_connection_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<GqlConnectionImpl>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_connection_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<GqlConnectionImpl>);
}

pub unsafe fn gql_connection_from_ptr(ptr: *mut c_void) -> Arc<GqlConnectionImpl> {
    Arc::from_raw(ptr as *mut GqlConnectionImpl)
}
