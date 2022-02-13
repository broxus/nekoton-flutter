use crate::{
    models::{HandleError, MatchResult},
    parse_address, FromPtr, ToPtr,
};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_uint, c_ulonglong},
    u64,
};

#[no_mangle]
pub unsafe extern "C" fn pack_std_smc_addr(
    base64_url: c_uint,
    addr: *mut c_char,
    bounceable: c_uint,
) -> *mut c_void {
    fn internal_fn(
        base64_url: c_uint,
        addr: *mut c_char,
        bounceable: c_uint,
    ) -> Result<u64, String> {
        let base64_url = base64_url != 0;
        let bounceable = bounceable != 0;

        let addr = addr.from_ptr();
        let addr = parse_address(&addr)?;

        let packed_addr = nekoton_utils::pack_std_smc_addr(base64_url, &addr, bounceable)
            .handle_error()?
            .to_ptr() as c_ulonglong;

        Ok(packed_addr)
    }

    internal_fn(base64_url, addr, bounceable).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn unpack_std_smc_addr(
    packed: *mut c_char,
    base64_url: c_uint,
) -> *mut c_void {
    fn internal_fn(packed: *mut c_char, base64_url: c_uint) -> Result<u64, String> {
        let base64_url = base64_url != 0;
        let packed = packed.from_ptr();

        let unpacked_addr = nekoton_utils::unpack_std_smc_addr(&packed, base64_url)
            .handle_error()?
            .to_string()
            .to_ptr() as c_ulonglong;

        Ok(unpacked_addr)
    }

    internal_fn(packed, base64_url).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn validate_address(address: *mut c_char) -> *mut c_void {
    let is_valid = nekoton_utils::validate_address(&address.from_ptr()) as c_ulonglong;

    Ok(is_valid).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn repack_address(address: *mut c_char) -> *mut c_void {
    fn internal_fn(address: *mut c_char) -> Result<u64, String> {
        let address = address.from_ptr();

        let address = nekoton_utils::repack_address(&address)
            .handle_error()?
            .to_string()
            .to_ptr() as c_ulonglong;

        Ok(address)
    }

    internal_fn(address).match_result()
}
