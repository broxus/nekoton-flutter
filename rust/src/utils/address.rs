use crate::{
    models::{HandleError, MatchResult},
    parse_address, ToPtr, ToStringFromPtr,
};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_uint},
    u64,
};

#[no_mangle]
pub unsafe extern "C" fn pack_std_smc_addr(
    base64_url: c_uint,
    addr: *mut c_char,
    bounceable: c_uint,
) -> *mut c_void {
    let addr = addr.to_string_from_ptr();

    fn internal_fn(base64_url: u32, addr: String, bounceable: u32) -> Result<u64, String> {
        let base64_url = base64_url != 0;
        let bounceable = bounceable != 0;

        let addr = parse_address(&addr)?;

        let packed_addr = nekoton_utils::pack_std_smc_addr(base64_url, &addr, bounceable)
            .handle_error()?
            .to_ptr() as u64;

        Ok(packed_addr)
    }

    internal_fn(base64_url, addr, bounceable).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn unpack_std_smc_addr(
    packed: *mut c_char,
    base64_url: c_uint,
) -> *mut c_void {
    let packed = packed.to_string_from_ptr();

    fn internal_fn(packed: String, base64_url: u32) -> Result<u64, String> {
        let base64_url = base64_url != 0;

        let unpacked_addr = nekoton_utils::unpack_std_smc_addr(&packed, base64_url)
            .handle_error()?
            .to_string()
            .to_ptr() as u64;

        Ok(unpacked_addr)
    }

    internal_fn(packed, base64_url).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn validate_address(address: *mut c_char) -> *mut c_void {
    let is_valid = nekoton_utils::validate_address(&address.to_string_from_ptr()) as u64;

    Ok(is_valid).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn repack_address(address: *mut c_char) -> *mut c_void {
    let address = address.to_string_from_ptr();

    fn internal_fn(address: String) -> Result<u64, String> {
        let address = nekoton_utils::repack_address(&address)
            .handle_error()?
            .to_string()
            .to_ptr() as u64;

        Ok(address)
    }

    internal_fn(address).match_result()
}
