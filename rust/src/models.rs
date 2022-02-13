use std::{
    ffi::{c_void, CStr, CString},
    os::raw::{c_char, c_uint, c_ulonglong},
};

#[repr(C)]
pub struct ExecutionResult {
    pub status_code: c_uint,
    pub payload: c_ulonglong,
}

pub enum ExecutionStatus {
    Ok,
    Err,
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
            Ok(success) => ExecutionResult {
                status_code: ExecutionStatus::Ok as c_uint,
                payload: success as c_ulonglong,
            },
            Err(error) => ExecutionResult {
                status_code: ExecutionStatus::Err as c_uint,
                payload: error.to_ptr() as c_ulonglong,
            },
        };

        Box::into_raw(Box::new(result)) as *mut c_void
    }
}
