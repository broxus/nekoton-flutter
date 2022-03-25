use crate::{
    external::jrpc_connection::JrpcConnectionImpl,
    models::{HandleError, MatchResult, ToStringFromPtr},
};
use nekoton::transport::jrpc::JrpcTransport;
use nekoton_transport::jrpc::JrpcClient;
use std::{ffi::c_void, os::raw::c_char, sync::Arc, u64};

#[no_mangle]
pub unsafe extern "C" fn create_jrpc_transport(endpoint: *mut c_char) -> *mut c_void {
    let endpoint = endpoint.to_string_from_ptr();

    fn internal_fn(endpoint: String) -> Result<u64, String> {
        let client = JrpcClient::new(endpoint).handle_error()?;

        let jrpc_connection = JrpcConnectionImpl { client };
        let jrpc_connection = Arc::new(jrpc_connection);

        let jrpc_transport = JrpcTransport::new(jrpc_connection);

        let ptr = Box::into_raw(Box::new(Arc::new(jrpc_transport))) as *mut c_void as u64;

        Ok(ptr)
    }

    internal_fn(endpoint).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn clone_jrpc_transport_ptr(jrpc_transport: *mut c_void) -> *mut c_void {
    let jrpc_transport = jrpc_transport as *mut Arc<JrpcTransport>;
    let cloned = Arc::clone(&*jrpc_transport);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_jrpc_transport_ptr(jrpc_transport: *mut c_void) {
    let jrpc_transport = jrpc_transport as *mut Arc<JrpcTransport>;

    let _ = Box::from_raw(jrpc_transport);
}
