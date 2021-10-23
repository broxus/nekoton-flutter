use crate::{
    match_result,
    models::{FromPtr, HandleError, NativeError, NativeStatus, ToPtr},
    parse_address, runtime, send_to_result_port,
    transport::gql_transport::{MutexGqlTransport, GQL_TRANSPORT_NOT_FOUND},
    RUNTIME,
};
use nekoton::transport::gql::GqlTransport;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    sync::Arc,
};

#[no_mangle]
pub unsafe extern "C" fn get_participant_info(
    result_port: c_longlong,
    transport: *mut c_void,
    address: *mut c_char,
    wallet_address: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let address = address.from_ptr();
    let wallet_address = wallet_address.from_ptr();

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
            internal_get_participant_info(transport.clone(), address, wallet_address).await;
        let result = match_result(result);

        *transport_guard = Some(transport);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_participant_info(
    transport: Arc<GqlTransport>,
    address: String,
    wallet_address: String,
) -> Result<u64, NativeError> {
    let address = parse_address(&address)?;
    let wallet_address = parse_address(&wallet_address)?;

    let result = nekoton_depool::get_participant_info(transport, address, wallet_address)
        .await
        .handle_error(NativeStatus::DePoolError)?;
    let result = serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?;

    let result = result.to_ptr();

    Ok(result as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_depool_info(
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

        let result = internal_get_depool_info(transport.clone(), address).await;
        let result = match_result(result);

        *transport_guard = Some(transport);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_depool_info(
    transport: Arc<GqlTransport>,
    address: String,
) -> Result<u64, NativeError> {
    let address = parse_address(&address)?;

    let result = nekoton_depool::get_depool_info(transport, address)
        .await
        .handle_error(NativeStatus::DePoolError)?;
    let result = serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?;

    let result = result.to_ptr();

    Ok(result as c_ulonglong)
}
