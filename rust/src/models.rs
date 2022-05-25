use std::{
    ffi::{c_char, c_uint, c_ulonglong, c_void, CStr, CString},
    ptr::null,
};

#[repr(C)]
pub struct ExecutionResult {
    pub status_code: c_uint,
    pub payload: c_ulonglong,
}

enum ExecutionStatus {
    Ok,
    Err,
}

pub trait ToCStringPtr {
    fn to_cstring_ptr(self) -> *mut c_char;
}

impl ToCStringPtr for String {
    fn to_cstring_ptr(self) -> *mut c_char {
        CString::new(self).unwrap().into_raw()
    }
}

pub trait ToOptionalCStringPtr {
    fn to_optional_cstring_ptr(self) -> *mut c_char;
}

impl ToOptionalCStringPtr for Option<String> {
    fn to_optional_cstring_ptr(self) -> *mut c_char {
        match self {
            Some(string) => string.to_cstring_ptr(),
            None => null::<c_char>() as *mut c_char,
        }
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

pub trait MatchResult {
    fn match_result(self) -> *mut c_void;
}

impl MatchResult for Result<u64, String> {
    fn match_result(self) -> *mut c_void {
        let result = match self {
            Ok(data) => ExecutionResult {
                status_code: ExecutionStatus::Ok as c_uint,
                payload: data as c_ulonglong,
            },
            Err(err) => ExecutionResult {
                status_code: ExecutionStatus::Err as c_uint,
                payload: err.to_cstring_ptr() as c_ulonglong,
            },
        };

        Box::into_raw(Box::new(result)) as *mut c_void
    }
}

pub trait ToNekoton<T> {
    fn to_nekoton(self) -> T;
}

pub trait ToSerializable<T> {
    fn to_serializable(self) -> T;
}
