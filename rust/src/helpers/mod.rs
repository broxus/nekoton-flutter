mod abi;

use std::os::raw::{c_char, c_uint};

use nekoton_abi::{get_code_salt, set_code_salt};
use ton_block::{Deserializable, MaybeDeserialize, Serializable};

use crate::{parse_address, HandleError, MatchResult, ToStringFromPtr};

#[no_mangle]
pub unsafe extern "C" fn nt_pack_std_smc_addr(
    base64_url: c_uint,
    addr: *mut c_char,
    bounceable: c_uint,
) -> *mut c_char {
    let addr = addr.to_string_from_ptr();

    fn internal_fn(
        base64_url: u32,
        addr: String,
        bounceable: u32,
    ) -> Result<serde_json::Value, String> {
        let base64_url = base64_url != 0;
        let addr = parse_address(&addr)?;
        let bounceable = bounceable != 0;

        let packed_addr =
            nekoton_utils::pack_std_smc_addr(base64_url, &addr, bounceable).handle_error()?;

        serde_json::to_value(packed_addr).handle_error()
    }

    internal_fn(base64_url, addr, bounceable).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_unpack_std_smc_addr(
    packed: *mut c_char,
    base64_url: c_uint,
) -> *mut c_char {
    let packed = packed.to_string_from_ptr();

    fn internal_fn(packed: String, base64_url: u32) -> Result<serde_json::Value, String> {
        let base64_url = base64_url != 0;

        let unpacked_addr = nekoton_utils::unpack_std_smc_addr(&packed, base64_url)
            .handle_error()?
            .to_string();

        serde_json::to_value(unpacked_addr).handle_error()
    }

    internal_fn(packed, base64_url).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_validate_address(address: *mut c_char) -> *mut c_char {
    let address = address.to_string_from_ptr();

    fn internal_fn(address: String) -> Result<serde_json::Value, String> {
        let is_valid = nekoton_utils::validate_address(&address);

        serde_json::to_value(is_valid).handle_error()
    }

    internal_fn(address).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_repack_address(address: *mut c_char) -> *mut c_char {
    let address = address.to_string_from_ptr();

    fn internal_fn(address: String) -> Result<serde_json::Value, String> {
        let address = nekoton_utils::repack_address(&address)
            .handle_error()?
            .to_string();

        serde_json::to_value(address).handle_error()
    }

    internal_fn(address).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_extract_public_key(boc: *mut c_char) -> *mut c_char {
    let boc = boc.to_string_from_ptr();

    fn internal_fn(boc: String) -> Result<serde_json::Value, String> {
        let public_key = parse_account_stuff(&boc)
            .and_then(|e| nekoton_abi::extract_public_key(&e).handle_error())
            .map(hex::encode)?;

        serde_json::to_value(public_key).handle_error()
    }

    internal_fn(boc).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_code_to_tvc(code: *mut c_char) -> *mut c_char {
    let code = code.to_string_from_ptr();

    fn internal_fn(code: String) -> Result<serde_json::Value, String> {
        let cell = base64::decode(code).handle_error()?;

        let tvc = ton_types::deserialize_tree_of_cells(&mut cell.as_slice())
            .handle_error()
            .and_then(|e| nekoton_abi::code_to_tvc(e).handle_error())
            .and_then(|e| e.serialize().handle_error())
            .and_then(|e| ton_types::serialize_toc(&e).handle_error())
            .map(base64::encode)?;

        serde_json::to_value(tvc).handle_error()
    }

    internal_fn(code).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_merge_tvc(code: *mut c_char, data: *mut c_char) -> *mut c_char {
    let code = code.to_string_from_ptr();
    let data = data.to_string_from_ptr();

    fn internal_fn(code: String, data: String) -> Result<serde_json::Value, String> {
        let state_init = ton_block::StateInit {
            code: Some(parse_cell(&code)?),
            data: Some(parse_cell(&data)?),
            ..Default::default()
        };

        let cell = state_init.serialize().handle_error()?;
        let bytes = ton_types::serialize_toc(&cell).handle_error()?;

        serde_json::to_value(base64::encode(bytes)).handle_error()
    }

    internal_fn(code, data).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_split_tvc(tvc: *mut c_char) -> *mut c_char {
    let tvc = tvc.to_string_from_ptr();

    fn internal_fn(tvc: String) -> Result<serde_json::Value, String> {
        let state_init = ton_block::StateInit::construct_from_base64(&tvc).handle_error()?;

        let data = match state_init.data {
            Some(data) => {
                let data = ton_types::serialize_toc(&data).handle_error()?;

                Some(base64::encode(data))
            },
            None => None,
        };

        let code = match state_init.code {
            Some(code) => {
                let code = ton_types::serialize_toc(&code).handle_error()?;

                Some(base64::encode(code))
            },
            None => None,
        };

        serde_json::to_value((data, code)).handle_error()
    }

    internal_fn(tvc).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_set_code_salt(code: *mut c_char, salt: *mut c_char) -> *mut c_char {
    let code = code.to_string_from_ptr();
    let salt = salt.to_string_from_ptr();

    fn internal_fn(code: String, salt: String) -> Result<serde_json::Value, String> {
        let code = set_code_salt(parse_cell(&code)?, parse_cell(&salt)?)
            .and_then(|cell| ton_types::serialize_toc(&cell))
            .map(base64::encode)
            .handle_error();

        serde_json::to_value(code).handle_error()
    }

    internal_fn(code, salt).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_code_salt(code: *mut c_char) -> *mut c_char {
    let code = code.to_string_from_ptr();

    fn internal_fn(code: String) -> Result<serde_json::Value, String> {
        let salt = match get_code_salt(parse_cell(&code)?).handle_error()? {
            Some(salt) => Some(base64::encode(
                ton_types::serialize_toc(&salt).handle_error()?,
            )),
            None => None,
        };

        serde_json::to_value(salt).handle_error()
    }

    internal_fn(code).match_result()
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

pub fn parse_cell(boc: &str) -> Result<ton_types::Cell, String> {
    let boc = boc.trim();
    if boc.is_empty() {
        Ok(ton_types::Cell::default())
    } else {
        let body = base64::decode(boc).handle_error()?;
        ton_types::deserialize_tree_of_cells(&mut body.as_slice()).handle_error()
    }
}
