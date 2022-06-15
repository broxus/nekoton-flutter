use std::{
    os::raw::{c_char, c_void},
    sync::Arc,
};

use nekoton::transport::jrpc::JrpcTransport;

use crate::{
    external::jrpc_connection::{jrpc_connection_from_ptr, JrpcConnectionImpl},
    HandleError, MatchResult,
};

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_create(jrpc_connection: *mut c_void) -> *mut c_char {
    let jrpc_connection = jrpc_connection_from_ptr(jrpc_connection);

    fn internal_fn(jrpc_connection: Arc<JrpcConnectionImpl>) -> Result<serde_json::Value, String> {
        let jrpc_transport = JrpcTransport::new(jrpc_connection);

        let ptr = Box::into_raw(Box::new(Arc::new(jrpc_transport)));

        serde_json::to_value(ptr as usize).handle_error()
    }

    internal_fn(jrpc_connection).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<JrpcTransport>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<JrpcTransport>);
}
