mod abi;
mod models;

use std::{
    ffi::{c_char, c_uint, c_void},
    u64,
};

use ton_block::{Deserializable, MaybeDeserialize, Serializable};

use crate::{
    helpers::models::SplittedTvc,
    models::{HandleError, MatchResult, ToCStringPtr, ToStringFromPtr},
    parse_address,
};

#[no_mangle]
pub unsafe extern "C" fn nt_pack_std_smc_addr(
    base64_url: c_uint,
    addr: *mut c_char,
    bounceable: c_uint,
) -> *mut c_void {
    let addr = addr.to_string_from_ptr();

    fn internal_fn(base64_url: u32, addr: String, bounceable: u32) -> Result<u64, String> {
        let base64_url = base64_url != 0;
        let addr = parse_address(&addr)?;
        let bounceable = bounceable != 0;

        let packed_addr = nekoton_utils::pack_std_smc_addr(base64_url, &addr, bounceable)
            .handle_error()?
            .to_cstring_ptr() as u64;

        Ok(packed_addr)
    }

    internal_fn(base64_url, addr, bounceable).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_unpack_std_smc_addr(
    packed: *mut c_char,
    base64_url: c_uint,
) -> *mut c_void {
    let packed = packed.to_string_from_ptr();

    fn internal_fn(packed: String, base64_url: u32) -> Result<u64, String> {
        let base64_url = base64_url != 0;

        let unpacked_addr = nekoton_utils::unpack_std_smc_addr(&packed, base64_url)
            .handle_error()?
            .to_string()
            .to_cstring_ptr() as u64;

        Ok(unpacked_addr)
    }

    internal_fn(packed, base64_url).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_validate_address(address: *mut c_char) -> *mut c_void {
    let address = address.to_string_from_ptr();

    fn internal_fn(address: String) -> Result<u64, String> {
        let is_valid = nekoton_utils::validate_address(&address) as u64;

        Ok(is_valid)
    }

    internal_fn(address).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_repack_address(address: *mut c_char) -> *mut c_void {
    let address = address.to_string_from_ptr();

    fn internal_fn(address: String) -> Result<u64, String> {
        let address = nekoton_utils::repack_address(&address)
            .handle_error()?
            .to_string()
            .to_cstring_ptr() as u64;

        Ok(address)
    }

    internal_fn(address).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_extract_public_key(boc: *mut c_char) -> *mut c_void {
    let boc = boc.to_string_from_ptr();

    fn internal_fn(boc: String) -> Result<u64, String> {
        let public_key = parse_account_stuff(&boc)
            .and_then(|e| nekoton_abi::extract_public_key(&e).handle_error())
            .map(hex::encode)?
            .to_cstring_ptr() as u64;

        Ok(public_key)
    }

    internal_fn(boc).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_code_to_tvc(code: *mut c_char) -> *mut c_void {
    let code = code.to_string_from_ptr();

    fn internal_fn(code: String) -> Result<u64, String> {
        let cell = base64::decode(code).handle_error()?;

        let tvc = ton_types::deserialize_tree_of_cells(&mut cell.as_slice())
            .handle_error()
            .and_then(|e| nekoton_abi::code_to_tvc(e).handle_error())
            .and_then(|e| e.serialize().handle_error())
            .and_then(|e| ton_types::serialize_toc(&e).handle_error())
            .map(base64::encode)?
            .to_cstring_ptr() as u64;

        Ok(tvc)
    }

    internal_fn(code).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_split_tvc(tvc: *mut c_char) -> *mut c_void {
    let tvc = tvc.to_string_from_ptr();

    fn internal_fn(tvc: String) -> Result<u64, String> {
        let state_init = ton_block::StateInit::construct_from_base64(&tvc).handle_error()?;

        let data = match state_init.data {
            Some(data) => {
                let data = ton_types::serialize_toc(&data).handle_error()?;

                Some(base64::encode(data))
            }
            None => None,
        };

        let code = match state_init.code {
            Some(code) => {
                let code = ton_types::serialize_toc(&code).handle_error()?;

                Some(base64::encode(code))
            }
            None => None,
        };

        let tvc = SplittedTvc { data, code };

        let tvc = serde_json::to_string(&tvc).handle_error()?.to_cstring_ptr() as u64;

        Ok(tvc)
    }

    internal_fn(tvc).match_result()
}

fn parse_account_stuff(boc: &str) -> Result<ton_block::AccountStuff, String> {
    let bytes = base64::decode(boc).handle_error()?;
    ton_types::deserialize_tree_of_cells(&mut bytes.as_slice())
        .and_then(|cell| {
            let slice = &mut cell.into();
            Ok(ton_block::AccountStuff {
                addr: Deserializable::construct_from(slice)?,
                storage_stat: Deserializable::construct_from(slice)?,
                storage: ton_block::AccountStorage {
                    last_trans_lt: Deserializable::construct_from(slice)?,
                    balance: Deserializable::construct_from(slice)?,
                    state: Deserializable::construct_from(slice)?,
                    init_code_hash: if slice.remaining_bits() > 0 {
                        ton_types::UInt256::read_maybe_from(slice)?
                    } else {
                        None
                    },
                },
            })
        })
        .handle_error()
}
