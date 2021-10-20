pub mod core;
pub mod crypto;
pub mod depool;
pub mod external;
pub mod helpers;
pub mod models;
pub mod transport;

use allo_isolate::{
    ffi::{DartCObject, DartPort},
    Isolate,
};
use lazy_static::lazy_static;
use models::{FromPtr, HandleError, NativeError, NativeResult, NativeStatus, ToPtr};
use std::{
    ffi::c_void,
    intrinsics::transmute,
    io,
    os::raw::{c_char, c_longlong, c_uint, c_ulonglong},
    str::FromStr,
    u64,
};
use tokio::runtime::{Builder, Runtime};
use ton_block::MsgAddressInt;

lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread()
        .enable_time()
        .worker_threads(4)
        .thread_name("nekoton_flutter")
        .thread_stack_size(3 * 1024 * 1024)
        .build();
}

#[macro_export]
macro_rules! runtime {
    () => {
        RUNTIME.as_ref().unwrap()
    };
}

#[no_mangle]
pub unsafe extern "C" fn store_post_cobject(ptr: *mut c_void) {
    let ptr = transmute::<
        *mut c_void,
        unsafe extern "C" fn(port_id: DartPort, message: *mut DartCObject) -> bool,
    >(ptr);
    allo_isolate::store_dart_post_cobject(ptr);
}

pub fn match_result(result: Result<u64, NativeError>) -> *mut c_void {
    let result = match result {
        Ok(success) => NativeResult {
            status_code: NativeStatus::Success as c_uint,
            payload: success,
        },
        Err(error) => NativeResult {
            status_code: error.status as c_uint,
            payload: error.info.to_ptr() as c_ulonglong,
        },
    };

    let result = Box::new(result);
    let result = Box::into_raw(result);
    let result = result as *mut c_void;

    result
}

pub fn send_to_result_port(port: c_longlong, result: *mut c_void) {
    let result = result as c_ulonglong;
    let isolate = Isolate::new(port);
    isolate.post(result);
}

#[no_mangle]
pub unsafe extern "C" fn free_cstring(str: *mut c_char) {
    str.from_ptr();
}

#[no_mangle]
pub unsafe extern "C" fn free_native_result(ptr: *mut c_void) {
    let result = ptr as *mut NativeResult;
    Box::from_raw(result);
}

pub fn parse_public_key(public_key: &str) -> Result<ed25519_dalek::PublicKey, NativeError> {
    ed25519_dalek::PublicKey::from_bytes(
        &hex::decode(&public_key).handle_error(NativeStatus::ConversionError)?,
    )
    .handle_error(NativeStatus::ConversionError)
}

pub fn parse_address(address: &str) -> Result<MsgAddressInt, NativeError> {
    MsgAddressInt::from_str(address).handle_error(NativeStatus::ConversionError)
}
