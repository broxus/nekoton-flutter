use std::{
    os::raw::{c_char, c_void},
    sync::Arc,
};

use nekoton::transport::jrpc::JrpcTransport;

use crate::{
    external::jrpc_connection::{jrpc_connection_from_native_ptr, JrpcConnectionImpl},
    ffi_box, HandleError, MatchResult, ToPtrAddress,
};

#[no_mangle]
pub unsafe extern "C" fn nt_jrpc_transport_create(jrpc_connection: *mut c_void) -> *mut c_char {
    let jrpc_connection = jrpc_connection_from_native_ptr(jrpc_connection).clone();

    fn internal_fn(jrpc_connection: Arc<JrpcConnectionImpl>) -> Result<serde_json::Value, String> {
        let jrpc_transport = JrpcTransport::new(jrpc_connection);

        let ptr = jrpc_transport_new(Arc::new(jrpc_transport));

        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(jrpc_connection).match_result()
}

ffi_box!(jrpc_transport, Arc<JrpcTransport>);
