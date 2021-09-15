use std::{
    ffi::{CStr, CString},
    os::raw::{c_char, c_uint, c_ulonglong},
};

#[repr(C)]
pub struct NativeResult {
    pub status_code: c_uint,
    pub payload: c_ulonglong,
}

pub struct NativeError {
    pub status: NativeStatus,
    pub info: String,
}

pub enum NativeStatus {
    Success,
    MutexError,
    ConversionError,
    AccountsStorageError,
    KeyStoreError,
    TokenWalletError,
    TonWalletError,
    CryptoError,
    DePoolError,
    AbiError,
    TransportError,
}

pub trait ToPtr {
    fn to_ptr(self) -> *mut c_char;
}

impl ToPtr for String {
    fn to_ptr(self) -> *mut c_char {
        CString::new(self).unwrap().into_raw()
    }
}

pub trait FromPtr {
    fn from_ptr(self) -> String;
}

impl FromPtr for *mut c_char {
    fn from_ptr(self) -> String {
        let string = unsafe { CStr::from_ptr(self) };
        string.to_str().unwrap().to_owned()
    }
}

pub trait HandleError {
    type Output;

    fn handle_error(self, status: NativeStatus) -> Result<Self::Output, NativeError>;
}

impl<T, E> HandleError for Result<T, E>
where
    E: ToString,
{
    type Output = T;

    fn handle_error(self, status: NativeStatus) -> Result<Self::Output, NativeError> {
        self.map_err(|e| NativeError {
            status,
            info: e.to_string(),
        })
    }
}
