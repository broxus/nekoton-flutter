use std::{
    os::raw::{c_char, c_void},
    sync::Arc,
};

use nekoton::transport::jrpc::JrpcTransport;

use crate::{
    external::jrpc_connection::JrpcConnectionImpl, HandleError, MatchResult, ToPtrAddress,
};

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_create(jrpc_connection: *mut c_void) -> *mut c_char {
    let jrpc_connection = (&*(jrpc_connection as *mut Arc<JrpcConnectionImpl>)).clone();

    fn internal_fn(jrpc_connection: Arc<JrpcConnectionImpl>) -> Result<serde_json::Value, String> {
        let jrpc_transport = JrpcTransport::new(jrpc_connection);

        let ptr = Box::into_raw(Box::new(Arc::new(jrpc_transport)));

        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(jrpc_connection).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_free_ptr(ptr: *mut c_void) {
    println!("nt_jrpc_transport_free_ptr");
    Box::from_raw(ptr as *mut Arc<JrpcTransport>);
}
