use std::{
    os::raw::{c_char, c_void},
    sync::Arc,
};

use nekoton::transport::proto::ProtoTransport;

use crate::{
    external::proto_connection::{proto_connection_from_native_ptr, ProtoConnectionImpl},
    ffi_box, HandleError, MatchResult, ToPtrAddress,
};

#[no_mangle]
pub unsafe extern "C" fn nt_proto_transport_create(proto_connection: *mut c_void) -> *mut c_char {
    let proto_connection = proto_connection_from_native_ptr(proto_connection).clone();

    fn internal_fn(proto_connection: Arc<ProtoConnectionImpl>) -> Result<serde_json::Value, String> {
        let proto_transport = ProtoTransport::new(proto_connection);

        let ptr = proto_transport_new(Arc::new(proto_transport));

        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(proto_connection).match_result()
}

ffi_box!(proto_transport, Arc<ProtoTransport>);
