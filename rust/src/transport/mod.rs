pub mod adnl_transport;
pub mod gql_transport;

use crate::{
    match_result,
    models::{FromPtr, HandleError, NativeError, NativeStatus, ToPtr},
    runtime, send_to_result_port,
    transport::gql_transport::MutexGqlTransport,
    RUNTIME,
};
use nekoton::transport::Transport;
use nekoton_abi::TransactionId;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_uchar, c_ulonglong},
    str::FromStr,
};
use ton_block::MsgAddressInt;

#[no_mangle]
pub unsafe extern "C" fn get_contract_state(
    result_port: c_longlong,
    transport: *mut c_void,
    address: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);
    let address = address.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_get_contract_state(transport, address).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_contract_state(
    transport: &MutexGqlTransport,
    address: String,
) -> Result<u64, NativeError> {
    let transport = transport.lock().await;

    let address = MsgAddressInt::from_str(&address).handle_error(NativeStatus::ConversionError)?;

    let raw_contract_state = transport
        .get_contract_state(&address)
        .await
        .handle_error(NativeStatus::TransportError)?;
    let raw_contract_state =
        serde_json::to_string(&raw_contract_state).handle_error(NativeStatus::ConversionError)?;

    Ok(raw_contract_state.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_transactions(
    result_port: c_longlong,
    transport: *mut c_void,
    address: *mut c_char,
    from: *mut c_char,
    count: c_uchar,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);
    let address = address.from_ptr();
    let from = from.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_get_transactions(transport, address, from, count).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_transactions(
    transport: &MutexGqlTransport,
    address: String,
    from: String,
    count: u8,
) -> Result<u64, NativeError> {
    let transport = transport.lock().await;

    let address = MsgAddressInt::from_str(&address).handle_error(NativeStatus::ConversionError)?;
    let from =
        serde_json::from_str::<TransactionId>(&from).handle_error(NativeStatus::ConversionError)?;

    let _raw_transactions = transport
        .get_transactions(address, from, count)
        .await
        .handle_error(NativeStatus::TransportError)?;
    let raw_transactions =
        serde_json::to_string(&Vec::<String>::new()).handle_error(NativeStatus::ConversionError)?;

    Ok(raw_transactions.to_ptr() as c_ulonglong)
}
