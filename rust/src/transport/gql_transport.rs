use std::{
    os::raw::{c_char, c_longlong, c_ulonglong, c_void},
    sync::Arc,
    time::Duration,
    u64,
};

use allo_isolate::Isolate;
use nekoton::transport::gql::GqlTransport;
use ton_block::Serializable;

use crate::{
    external::gql_connection::GqlConnectionImpl, ffi_box, parse_address, runtime, HandleError,
    MatchResult, PostWithResult, ToPtrAddress, ToStringFromPtr, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_create(gql_connection: *mut c_void) -> *mut c_char {
    let gql_connection = gql_connection_from_native_ptr(gql_connection).clone();

    fn internal_fn(gql_connection: Arc<GqlConnectionImpl>) -> Result<serde_json::Value, String> {
        let gql_transport = GqlTransport::new(gql_connection);
        let ptr = gql_transport_new(Arc::new(gql_transport));

        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(gql_connection).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_get_latest_block_id(
    result_port: c_longlong,
    gql_transport: *mut c_void,
    address: *mut c_char,
) {
    let gql_transport = gql_transport_from_native_ptr(gql_transport).clone();

    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            gql_transport: Arc<GqlTransport>,
            address: String,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let latest_block_id = gql_transport
                .get_latest_block(&address)
                .await
                .handle_error()?
                .id;

            serde_json::to_value(latest_block_id).handle_error()
        }

        let result = internal_fn(gql_transport, address).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_get_block(
    result_port: c_longlong,
    gql_transport: *mut c_void,
    id: *mut c_char,
) {
    let gql_transport = gql_transport_from_native_ptr(gql_transport).clone();

    let id = id.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            gql_transport: Arc<GqlTransport>,
            id: String,
        ) -> Result<serde_json::Value, String> {
            let block = gql_transport.get_block(&id).await.handle_error()?;

            let block = block
                .serialize()
                .as_ref()
                .map(ton_types::serialize_toc)
                .handle_error()?
                .map(base64::encode)
                .handle_error()?;

            serde_json::to_value(block).handle_error()
        }

        let result = internal_fn(gql_transport, id).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_wait_for_next_block_id(
    result_port: c_longlong,
    gql_transport: *mut c_void,
    current_block_id: *mut c_char,
    address: *mut c_char,
    timeout: c_ulonglong,
) {
    let gql_transport = gql_transport_from_native_ptr(gql_transport).clone();

    let current_block_id = current_block_id.to_string_from_ptr();
    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            gql_transport: Arc<GqlTransport>,
            current_block_id: String,
            address: String,
            timeout: u64,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let timeout = Duration::from_millis(timeout);

            let next_block_id = gql_transport
                .wait_for_next_block(&current_block_id, &address, timeout)
                .await
                .handle_error()?;

            serde_json::to_value(next_block_id).handle_error()
        }

        let result = internal_fn(gql_transport, current_block_id, address, timeout)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

ffi_box!(gql_connection, Arc<GqlConnectionImpl>);
ffi_box!(gql_transport, Arc<GqlTransport>);
