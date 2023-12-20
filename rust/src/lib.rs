#![warn(clippy::as_ptr_cast_mut, clippy::ptr_as_ptr, clippy::borrow_as_ptr)]
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
    ffi::{CStr, CString},
    intrinsics::transmute,
    io,
    os::raw::{c_char, c_void},
    str::FromStr,
    sync::Arc,
};

use allo_isolate::{
    ffi::{DartCObject, DartPort},
    IntoDart, Isolate,
};
use anyhow::{Context, Result};
use lazy_static::lazy_static;
use nekoton_utils::SimpleClock;
use serde::Serialize;
use tokio::runtime::{Builder, Runtime};
use ton_block::MsgAddressInt;

pub const ISOLATE_MESSAGE_POST_ERROR: &str = "Message was not posted successfully";

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
pub unsafe extern "C" fn nt_void_ptr_to_c_str(ptr: *mut c_void) -> *mut c_char {
    let string = (ptr as u64).to_string();
    let c_string = CString::new(string).unwrap();

    c_string.into_raw()
}

#[no_mangle]
pub unsafe extern "C" fn nt_free_cstring(ptr: *mut c_char) {
    if (ptr as u64) < 65536 {
        log::error!("nt_free_cstring: ptr is null");
        panic!("nt_free_cstring: ptr is null");
    }
    ptr.to_string_from_ptr();
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase", tag = "type", content = "data")]
pub enum ExecutionResult<T>
where
    T: Serialize,
{
    Ok(T),
    Err(String),
}

pub trait MatchResult {
    fn match_result(self) -> *mut c_char;
}

impl<T> MatchResult for Result<T, String>
where
    T: Serialize,
{
    fn match_result(self) -> *mut c_char {
        let result = match self {
            Ok(ok) => ExecutionResult::Ok(ok),
            Err(err) => ExecutionResult::Err(err),
        };

        serde_json::to_string(&result).unwrap().to_cstring_ptr()
    }
}

pub trait HandleError {
    type Output;

    fn handle_error(self) -> Result<Self::Output, String>;
}

impl<T, E> HandleError for Result<T, E>
where
    E: ToString,
{
    type Output = T;

    fn handle_error(self) -> Result<Self::Output, String> {
        self.map_err(|e| e.to_string())
    }
}

pub trait PostWithResult {
    fn post_with_result(&self, data: impl IntoDart) -> Result<(), String>;
}

impl PostWithResult for Isolate {
    fn post_with_result(&self, data: impl IntoDart) -> Result<(), String> {
        match self.post(data) {
            true => Ok(()),
            false => Err(ISOLATE_MESSAGE_POST_ERROR).handle_error(),
        }
    }
}

fn parse_hash(hash: &str) -> Result<ton_types::UInt256, String> {
    ton_types::UInt256::from_str(hash).handle_error()
}

fn parse_public_key(public_key: &str) -> Result<ed25519_dalek::PublicKey, anyhow::Error> {
    Ok(ed25519_dalek::PublicKey::from_bytes(
        &hex::decode(public_key).context("Bad hex data")?,
    )?)
}

fn parse_address(address: &str) -> Result<MsgAddressInt, String> {
    MsgAddressInt::from_str(address).handle_error()
}

pub trait ToPtrAddress {
    fn to_ptr_address(self) -> String;
}

impl<T> ToPtrAddress for *mut T {
    fn to_ptr_address(self) -> String {
        (self as u64).to_string()
    }
}

pub trait ToPtrFromAddress {
    fn to_ptr_from_address<T>(self) -> *mut T;
}

impl ToPtrFromAddress for String {
    fn to_ptr_from_address<T>(self) -> *mut T {
        let address = u64::from_str(&self).unwrap();
        if address < 65536 {
            panic!("Invalid address");
        }

        address as *mut T
    }
}

pub trait ToCStringPtr {
    fn to_cstring_ptr(self) -> *mut c_char;
}

impl ToCStringPtr for String {
    fn to_cstring_ptr(self) -> *mut c_char {
        CString::new(self).unwrap().into_raw()
    }
}

pub trait ToStringFromPtr {
    unsafe fn to_string_from_ptr(self) -> String;
}

impl ToStringFromPtr for *mut c_char {
    unsafe fn to_string_from_ptr(self) -> String {
        CStr::from_ptr(self).to_str().unwrap().to_owned()
    }
}

pub trait ToOptionalStringFromPtr {
    unsafe fn to_optional_string_from_ptr(self) -> Option<String>;
}

impl ToOptionalStringFromPtr for *mut c_char {
    unsafe fn to_optional_string_from_ptr(self) -> Option<String> {
        match !self.is_null() {
            true => Some(self.to_string_from_ptr()),
            false => None,
        }
    }
}

/// creates ffi constructor and destructor for the given type
/// exmaple:
/// ```ignore
/// ffi_constructor_and_destructor!(Arc, wallet: TONWallet);
///
/// // will create:
/// fn wallet_new(wallet: TONWallet) -> *mut c_void
/// {
///   Box::into_raw(Box::new(Arc::new(wallet))) as *mut c_void
/// }
///
/// fn nt_wallet_free_ptr(wallet: *mut c_void){
///  let _ = unsafe { Box::from_raw(wallet as *mut Arc<TONWallet>) };
/// }
/// ```
#[macro_export]
macro_rules! ffi_box {
    ($name:ident, $type:ty) => {
         ::paste::paste! {
            /// creates new ffi object of type $type
            #[allow(clippy::disallowed_methods,clippy::ptr_as_ptr,dead_code)]
            pub  fn [< $name _new >](data: $type) -> *mut std::ffi::c_void {
                Box::into_raw(Box::new(data)) as *mut std::ffi::c_void
            }

            #[no_mangle]
            #[allow(clippy::disallowed_methods,clippy::ptr_as_ptr,dead_code)]
            pub unsafe extern "C" fn [< nt_ $name _free_ptr >](ptr: *mut std::ffi::c_void) {
                 #[allow(clippy::disallowed_methods)]
                 if (ptr as u64) < 65536 {
                     log::error!(concat!("nt_", stringify!($name), "_free_ptr: ptr is null"));
                     panic!(concat!("nt_", stringify!($name), "_free_ptr: ptr is null"));
                 }
                let _ = unsafe { Box::from_raw(ptr as *mut $type) };
            }

             /// creates new ffi object of type $type
             /// SAFETY: ptr must be valid pointer to $type
             /// Panics if ptr < 65536
            #[allow(clippy::disallowed_methods,clippy::ptr_as_ptr,dead_code)]
            pub unsafe fn [< $name _from_native_ptr >]<'b>(ptr: *mut std::ffi::c_void) -> &'b $type {
                 if (ptr as u64) < 65536 {
                    log::error!(concat!("nt_", stringify!($name), "_from_native_ptr: ptr is null"));
                    panic!(concat!("nt_", stringify!($name), "_from_native_ptr: ptr is null"));
                }
                &*(ptr as *const $type)
            }

            #[allow(clippy::disallowed_methods,clippy::ptr_as_ptr,dead_code)]
            pub unsafe fn [< $name _from_native_ptr_opt >]<'b>(ptr: *mut std::ffi::c_void) -> Option<&'b $type> {
                if ptr.is_null() {
                    None
                } else {
                    Some(&*(ptr as *const $type))
                }
            }

            /// creates new ffi object of type $type
            /// SAFETY: ptr must be valid pointer to $type
            /// Panics if ptr < 65536
            #[allow(clippy::disallowed_methods,clippy::ptr_as_ptr,dead_code)]
            pub unsafe fn [< $name _from_native_ptr_mut >]<'b>(ptr: *mut std::ffi::c_void) -> &'b mut $type {
                 if (ptr as u64) < 65536 {
                    log::error!(concat!("nt_", stringify!($name), "_from_native_ptr: ptr is null"));
                    panic!(concat!("nt_", stringify!($name), "_from_native_ptr: ptr is null"));
                }
                &mut *(ptr as *mut $type)
            }


            /// creates new ffi object of type $type
            /// SAFETY: ptr must be valid pointer to $type
            /// Panics if ptr < 65536
            #[allow(clippy::disallowed_methods,clippy::ptr_as_ptr,dead_code)]
            pub unsafe fn [< $name _from_native_ptr_owned >]<'b>(ptr: *mut std::ffi::c_void) -> Box<$type> {
                if (ptr as u64) < 65536 {
                    log::error!(concat!("nt_", stringify!($name), "_from_native_ptr: ptr is null"));
                    panic!(concat!("nt_", stringify!($name), "_from_native_ptr: ptr is null"));
                }
                Box::from_raw(ptr as *mut $type)
            }
         }
    };
}

#[no_mangle]
pub unsafe extern "C" fn nt_init_logging() {
    log_panics::init();
    #[cfg(target_os = "android")]
    {
        android_logger::init_once(
            android_logger::Config::default().with_min_level(log::Level::Debug),
        );
    }
}

ffi_box!(channel_err, tokio::sync::oneshot::Sender<Result<String>>);
ffi_box!(channel_option, tokio::sync::oneshot::Sender<Option<String>>);
ffi_box!(
    channel_result_option,
    tokio::sync::oneshot::Sender<Result<Option<String>>>
);
ffi_box!(
    channel_result_unit,
    tokio::sync::oneshot::Sender<Result<()>>
);

#[cfg(test)]
mod test {
    #[test]
    fn test_ffi() {
        ffi_box!(test, String);

        let ptr = test_new("test".to_owned());
        let s = unsafe { test_from_native_ptr(ptr) };
        println!("{}", s.len());
        unsafe {
            nt_test_free_ptr(ptr);
        }
    }
}
