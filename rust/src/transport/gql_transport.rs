use std::{
    ffi::{c_char, c_longlong, c_ulonglong, c_void},
    sync::Arc,
    time::Duration,
    u64,
};

use nekoton::transport::gql::GqlTransport;
use nekoton_transport::gql::{GqlClient, GqlNetworkSettings};
use ton_block::Serializable;

use crate::{
    external::gql_connection::GqlConnectionImpl,
    models::{HandleError, MatchResult},
    parse_address, runtime, send_to_result_port, ToCStringPtr, ToStringFromPtr, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_create(settings: *mut c_char) -> *mut c_void {
    let settings = settings.to_string_from_ptr();

    fn internal_fn(settings: String) -> Result<u64, String> {
        let settings = serde_json::from_str::<GqlNetworkSettings>(&settings).handle_error()?;

        let client = GqlClient::new(settings.clone()).handle_error()?;
        let local = settings.local;

        let gql_connection = Arc::new(GqlConnectionImpl::new(client, local));

        let gql_transport = GqlTransport::new(gql_connection);

        let ptr = Box::into_raw(Box::new(Arc::new(gql_transport))) as u64;

        Ok(ptr)
    }

    internal_fn(settings).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_get_latest_block_id(
    result_port: c_longlong,
    gql_transport: *mut c_void,
    address: *mut c_char,
) {
    let gql_transport = gql_transport_from_ptr(gql_transport);

    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            gql_transport: Arc<GqlTransport>,
            address: String,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let latest_block_id = gql_transport
                .get_latest_block(&address)
                .await
                .handle_error()?
                .id
                .to_cstring_ptr() as u64;

            Ok(latest_block_id)
        }

        let result = internal_fn(gql_transport, address).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_get_block(
    result_port: c_longlong,
    gql_transport: *mut c_void,
    id: *mut c_char,
) {
    let gql_transport = gql_transport_from_ptr(gql_transport);

    let id = id.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(gql_transport: Arc<GqlTransport>, id: String) -> Result<u64, String> {
            let block = gql_transport.get_block(&id).await.handle_error()?;

            let block = block
                .serialize()
                .as_ref()
                .map(ton_types::serialize_toc)
                .handle_error()?
                .map(base64::encode)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(block)
        }

        let result = internal_fn(gql_transport, id).await.match_result();

        send_to_result_port(result_port, result);
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
    let gql_transport = gql_transport_from_ptr(gql_transport);

    let current_block_id = current_block_id.to_string_from_ptr();
    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            gql_transport: Arc<GqlTransport>,
            current_block_id: String,
            address: String,
            timeout: u64,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let timeout = Duration::from_millis(timeout);

            let next_block_id = gql_transport
                .wait_for_next_block(&current_block_id, &address, timeout)
                .await
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(next_block_id)
        }

        let result = internal_fn(gql_transport, current_block_id, address, timeout)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<GqlTransport>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_gql_transport_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<GqlTransport>);
}

unsafe fn gql_transport_from_ptr(ptr: *mut c_void) -> Arc<GqlTransport> {
    Arc::from_raw(ptr as *mut GqlTransport)
}
