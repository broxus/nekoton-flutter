use crate::{
    external::gql_connection::MutexGqlConnection,
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    runtime, send_to_result_port, FromPtr, ToPtr, RUNTIME,
};
use nekoton::transport::gql::GqlTransport;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    str::FromStr,
    sync::Arc,
    time::Duration,
    u64,
};
use tokio::sync::Mutex;
use ton_block::MsgAddressInt;

pub type MutexGqlTransport = Mutex<Arc<GqlTransport>>;

#[no_mangle]
pub unsafe extern "C" fn get_gql_transport(result_port: c_longlong, connection: *mut c_void) {
    let connection = connection as *mut MutexGqlConnection;
    let connection = &(*connection);

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_get_gql_transport(connection).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_gql_transport(connection: &MutexGqlConnection) -> Result<u64, NativeError> {
    let connection = connection.lock().await;

    let connection = connection.clone();

    let transport = GqlTransport::new(connection);
    let transport = Arc::new(transport);
    let transport = Mutex::new(transport);
    let transport = Arc::new(transport);

    let ptr = Arc::into_raw(transport) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn free_gql_transport(gql_transport: *mut c_void) {
    let gql_transport = gql_transport as *mut MutexGqlTransport;
    Arc::from_raw(gql_transport);
}

#[no_mangle]
pub unsafe extern "C" fn get_latest_block_id(
    result_port: c_longlong,
    transport: *mut c_void,
    address: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);
    let address = address.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_get_latest_block_id(transport, address).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_latest_block_id(
    transport: &MutexGqlTransport,
    address: String,
) -> Result<u64, NativeError> {
    let transport = transport.lock().await;

    let address = MsgAddressInt::from_str(&address).handle_error(NativeStatus::ConversionError)?;

    let latest_block = transport
        .get_latest_block(&address)
        .await
        .handle_error(NativeStatus::TransportError)?;

    let id = latest_block.id;

    Ok(id.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn wait_for_next_block_id(
    result_port: c_longlong,
    transport: *mut c_void,
    current_block_id: *mut c_char,
    address: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);
    let current_block_id = current_block_id.from_ptr();
    let address = address.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_wait_for_next_block_id(transport, current_block_id, address).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_wait_for_next_block_id(
    transport: &MutexGqlTransport,
    current_block_id: String,
    address: String,
) -> Result<u64, NativeError> {
    let transport = transport.lock().await;

    let address = MsgAddressInt::from_str(&address).handle_error(NativeStatus::ConversionError)?;
    let timeout = Duration::from_secs(30);

    let next_block_id = transport
        .wait_for_next_block(&current_block_id, &address, timeout)
        .await
        .handle_error(NativeStatus::TransportError)?;

    Ok(next_block_id.to_ptr() as c_ulonglong)
}
