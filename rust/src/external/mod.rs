pub mod gql_connection;
pub mod jrpc_connection;
pub mod ledger_connection;
pub mod proto_connection;
pub mod storage;

use std::os::raw::{c_char, c_void};

use anyhow::anyhow;

use crate::{
    channel_err_from_native_ptr_owned, channel_result_option_from_native_ptr_owned,
    channel_result_unit_from_native_ptr_owned, ToOptionalStringFromPtr,
};

#[no_mangle]
pub unsafe extern "C" fn nt_external_resolve_request_with_string(
    tx: *mut c_void,
    ok: *mut c_char,
    err: *mut c_char,
) {
    let tx = channel_err_from_native_ptr_owned(tx);

    let ok = ok.to_optional_string_from_ptr();
    let err = err.to_optional_string_from_ptr();

    let result = match ok {
        Some(ok) => Ok(ok),
        None => match err {
            Some(err) => Err(anyhow!(err)),
            None => panic!(),
        },
    };

    if let Err(e) = tx.send(result) {
        log::error!("channel closed: {:?}", e);
    }
}

#[no_mangle]
pub unsafe extern "C" fn nt_external_resolve_request_with_optional_string(
    tx: *mut c_void,
    ok: *mut c_char,
    err: *mut c_char,
) {
    let tx = channel_result_option_from_native_ptr_owned(tx);

    let ok = ok.to_optional_string_from_ptr();
    let err = err.to_optional_string_from_ptr();

    let result = match ok {
        Some(ok) => Ok(Some(ok)),
        None => match err {
            Some(err) => Err(anyhow!(err)),
            None => Ok(None),
        },
    };

    if let Err(e) = tx.send(result) {
        log::error!("channel closed: {:?}", e);
    }
}

#[no_mangle]
pub unsafe extern "C" fn nt_external_resolve_request_with_unit(tx: *mut c_void, err: *mut c_char) {
    let tx = channel_result_unit_from_native_ptr_owned(tx);

    let err = err.to_optional_string_from_ptr();

    let result = match err {
        Some(err) => Err(anyhow!(err)),
        None => Ok(()),
    };

    if let Err(e) = tx.send(result) {
        log::error!("channel closed: {:?}", e);
    }
}
