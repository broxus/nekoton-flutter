use crate::{
    external::gql_connection::{GqlConnectionImpl, MutexGqlConnection, GQL_CONNECTION_NOT_FOUND},
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    parse_address, runtime, send_to_result_port, FromPtr, ToPtr, REQUEST_TIMEOUT, RUNTIME,
};
use nekoton::transport::gql::GqlTransport;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    sync::Arc,
    u64,
};
use tokio::sync::Mutex;

pub type MutexGqlTransport = Mutex<Option<Arc<GqlTransport>>>;

pub const GQL_TRANSPORT_NOT_FOUND: &str = "Gql transport not found";

#[no_mangle]
pub unsafe extern "C" fn get_gql_transport(result_port: c_longlong, connection: *mut c_void) {
    let connection = connection as *mut MutexGqlConnection;
    let connection = &(*connection);

    let rt = runtime!();
    rt.spawn(async move {
        let mut connection_guard = connection.lock().await;
        let connection = connection_guard.take();
        let connection = match connection {
            Some(connection) => connection,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GQL_CONNECTION_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_gql_transport(connection.clone()).await;
        let result = match_result(result);

        *connection_guard = Some(connection);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_gql_transport(
    connection: Arc<GqlConnectionImpl>,
) -> Result<u64, NativeError> {
    let transport = GqlTransport::new(connection);
    let transport = Arc::new(transport);
    let transport = Mutex::new(Some(transport));
    let transport = Arc::new(transport);

    let ptr = Arc::into_raw(transport) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn free_gql_transport(result_port: c_longlong, gql_transport: *mut c_void) {
    let gql_transport = gql_transport as *mut MutexGqlTransport;
    let gql_transport = &(*gql_transport);

    let rt = runtime!();
    rt.spawn(async move {
        let mut gql_transport_guard = gql_transport.lock().await;
        let gql_transport = gql_transport_guard.take();
        match gql_transport {
            Some(gql_transport) => gql_transport,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GQL_TRANSPORT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = Ok(0);
        let result = match_result(result);

        send_to_result_port(result_port, result);
    });
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
        let mut transport_guard = transport.lock().await;
        let transport = transport_guard.take();
        let transport = match transport {
            Some(transport) => transport,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GQL_TRANSPORT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_latest_block_id(transport.clone(), address).await;
        let result = match_result(result);

        *transport_guard = Some(transport);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_latest_block_id(
    transport: Arc<GqlTransport>,
    address: String,
) -> Result<u64, NativeError> {
    let address = parse_address(&address)?;

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
        let mut transport_guard = transport.lock().await;
        let transport = transport_guard.take();
        let transport = match transport {
            Some(transport) => transport,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GQL_TRANSPORT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result =
            internal_wait_for_next_block_id(transport.clone(), current_block_id, address).await;
        let result = match_result(result);

        *transport_guard = Some(transport);

        send_to_result_port(result_port, result);
    });
}

async fn internal_wait_for_next_block_id(
    transport: Arc<GqlTransport>,
    current_block_id: String,
    address: String,
) -> Result<u64, NativeError> {
    let address = parse_address(&address)?;
    let timeout = REQUEST_TIMEOUT;

    let next_block_id = transport
        .wait_for_next_block(&current_block_id, &address, timeout)
        .await
        .handle_error(NativeStatus::TransportError)?;

    Ok(next_block_id.to_ptr() as c_ulonglong)
}
