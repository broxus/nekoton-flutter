pub(crate) mod gql_connection;
pub(crate) mod jrpc_connection;
pub(crate) mod ledger_connection;
pub(crate) mod storage;

use std::os::raw::{c_char, c_void};

use anyhow::{anyhow, Result};
use tokio::sync::oneshot::Sender;

use crate::ToOptionalStringFromPtr;

#[no_mangle]
pub unsafe extern "C" fn nt_external_resolve_request_with_string(
    tx: *mut c_void,
    ok: *mut c_char,
    err: *mut c_char,
) {
    let tx = Box::from_raw(tx as *mut Sender<Result<String>>);

    let ok = ok.to_optional_string_from_ptr();
    let err = err.to_optional_string_from_ptr();

    let result = match ok {
        Some(ok) => Ok(ok),
        None => match err {
            Some(err) => Err(anyhow!(err)),
            None => panic!(),
        },
    };

    tx.send(result).unwrap();
}

#[no_mangle]
pub unsafe extern "C" fn nt_external_resolve_request_with_optional_string(
    tx: *mut c_void,
    ok: *mut c_char,
    err: *mut c_char,
) {
    let tx = Box::from_raw(tx as *mut Sender<Result<Option<String>>>);

    let ok = ok.to_optional_string_from_ptr();
    let err = err.to_optional_string_from_ptr();

    let result = match ok {
        Some(ok) => Ok(Some(ok)),
        None => match err {
            Some(err) => Err(anyhow!(err)),
            None => Ok(None),
        },
    };

    tx.send(result).unwrap();
}

#[no_mangle]
pub unsafe extern "C" fn nt_external_resolve_request_with_unit(tx: *mut c_void, err: *mut c_char) {
    let tx = Box::from_raw(tx as *mut Sender<Result<()>>);

    let err = err.to_optional_string_from_ptr();

    let result = match err {
        Some(err) => Err(anyhow!(err)),
        None => Ok(()),
    };

    tx.send(result).unwrap();
}
