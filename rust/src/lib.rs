pub mod core;
pub mod crypto;
pub mod external;
pub mod models;
pub mod transport;
pub mod utils;

use allo_isolate::{
    ffi::{DartCObject, DartPort},
    Isolate,
};
use anyhow::Result;
use lazy_static::lazy_static;
use models::{ExecutionResult, FromPtr, HandleError, ToPtr};
use std::{
    ffi::c_void,
    intrinsics::transmute,
    io,
    os::raw::{c_char, c_longlong, c_ulonglong},
    str::FromStr,
};
use tokio::runtime::{Builder, Runtime};
use ton_block::MsgAddressInt;

lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread()
        .enable_time()
        .enable_io()
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

pub fn send_to_result_port(port: c_longlong, result: *mut c_void) {
    Isolate::new(port).post(result as c_ulonglong);
}

#[no_mangle]
pub unsafe extern "C" fn free_cstring(str: *mut c_char) {
    str.from_ptr();
}

#[no_mangle]
pub unsafe extern "C" fn free_execution_result(ptr: *mut c_void) {
    let result = ptr as *mut ExecutionResult;

    Box::from_raw(result);
}

pub fn parse_public_key(public_key: &str) -> Result<ed25519_dalek::PublicKey, String> {
    ed25519_dalek::PublicKey::from_bytes(&hex::decode(&public_key).handle_error()?).handle_error()
}

pub fn parse_address(address: &str) -> Result<MsgAddressInt, String> {
    MsgAddressInt::from_str(address).handle_error()
}
