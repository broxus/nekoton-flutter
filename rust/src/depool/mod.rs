use crate::{
    match_result,
    models::{FromPtr, NativeError, NativeStatus, ToPtr},
    runtime, send_to_result_port,
    transport::gql_transport::MutexGqlTransport,
    RUNTIME,
};
use nekoton::transport::gql::GqlTransport;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    str::FromStr,
    sync::Arc,
};
use ton_block::MsgAddressInt;

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
        let transport = transport.lock().await;
        let transport = transport.clone();

        let result = internal_get_participant_info(transport, address, wallet_address).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_participant_info(
    transport: Arc<GqlTransport>,
    address: String,
    wallet_address: String,
) -> Result<u64, NativeError> {
    let address = MsgAddressInt::from_str(&address).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;
    let wallet_address = MsgAddressInt::from_str(&wallet_address).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

    let result = nekoton_depool::get_participant_info(transport, address, wallet_address)
        .await
        .map_err(|e| NativeError {
            status: NativeStatus::DePoolError,
            info: e.to_string(),
        })?;
    let result = serde_json::to_string(&result).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

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
        let transport = transport.lock().await;
        let transport = transport.clone();

        let result = internal_get_depool_info(transport, address).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_depool_info(
    transport: Arc<GqlTransport>,
    address: String,
) -> Result<u64, NativeError> {
    let address = MsgAddressInt::from_str(&address).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

    let result = nekoton_depool::get_depool_info(transport, address)
        .await
        .map_err(|e| NativeError {
            status: NativeStatus::DePoolError,
            info: e.to_string(),
        })?;
    let result = serde_json::to_string(&result).map_err(|e| NativeError {
        status: NativeStatus::ConversionError,
        info: e.to_string(),
    })?;

    let result = result.to_ptr();

    Ok(result as c_ulonglong)
}
