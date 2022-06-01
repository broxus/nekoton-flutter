use std::{
    os::raw::{c_char, c_void},
    sync::Arc,
    u64,
};

use nekoton::transport::jrpc::JrpcTransport;
use nekoton_transport::jrpc::JrpcClient;

use crate::{
    external::jrpc_connection::JrpcConnectionImpl,
    models::{HandleError, MatchResult, ToStringFromPtr},
};

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_create(endpoint: *mut c_char) -> *mut c_void {
    let endpoint = endpoint.to_string_from_ptr();

    fn internal_fn(endpoint: String) -> Result<u64, String> {
        let client = JrpcClient::new(endpoint).handle_error()?;

        let jrpc_connection = Arc::new(JrpcConnectionImpl::new(client));

        let jrpc_transport = JrpcTransport::new(jrpc_connection);

        let ptr = Box::into_raw(Box::new(Arc::new(jrpc_transport))) as u64;

        Ok(ptr)
    }

    internal_fn(endpoint).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<JrpcTransport>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<JrpcTransport>);
}
