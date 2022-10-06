#![feature(core_ffi_c)]
#![allow(
    clippy::missing_safety_doc,
    clippy::too_many_arguments,
    clippy::large_enum_variant,
    clippy::borrowed_box
)]

mod core;
mod crypto;
mod external;
mod helpers;
mod models;
mod transport;

use std::{
    intrinsics::transmute,
    io,
    os::raw::{c_char, c_void},
    str::FromStr,
    sync::Arc,
};

use allo_isolate::ffi::{DartCObject, DartPort};
use anyhow::Result;
use lazy_static::lazy_static;
use models::{HandleError, ToPtrFromAddress, ToStringFromPtr};
use nekoton_utils::SimpleClock;
use tokio::runtime::{Builder, Runtime};
use ton_block::MsgAddressInt;

lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread()
        .enable_all()
        .thread_name("nekoton_flutter")
        .build();
    static ref CLOCK: Arc<SimpleClock> = Arc::new(SimpleClock {});
}

#[macro_export]
macro_rules! runtime {
    () => {
        RUNTIME.as_ref().unwrap()
    };
}

#[macro_export]
macro_rules! clock {
    () => {
        CLOCK.clone()
    };
}

#[no_mangle]
pub unsafe extern "C" fn nt_store_dart_post_cobject(ptr: *mut c_void) {
    let ptr = transmute::<
        *mut c_void,
        unsafe extern "C" fn(port_id: DartPort, message: *mut DartCObject) -> bool,
    >(ptr);

    allo_isolate::store_dart_post_cobject(ptr);
}

#[no_mangle]
pub unsafe extern "C" fn nt_cstring_to_void_ptr(ptr: *mut c_char) -> *mut c_void {
    ptr.to_string_from_ptr().to_ptr_from_address::<c_void>()
}

#[no_mangle]
pub unsafe extern "C" fn nt_free_cstring(ptr: *mut c_char) {
    ptr.to_string_from_ptr();
}

fn parse_hash(hash: &str) -> Result<ton_types::UInt256, String> {
    ton_types::UInt256::from_str(hash).handle_error()
}

fn parse_public_key(public_key: &str) -> Result<ed25519_dalek::PublicKey, String> {
    ed25519_dalek::PublicKey::from_bytes(&hex::decode(&public_key).handle_error()?).handle_error()
}

fn parse_address(address: &str) -> Result<MsgAddressInt, String> {
    MsgAddressInt::from_str(address).handle_error()
}
