use crate::{
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    FromPtr, ToPtr,
};
use nekoton_abi::{create_boc_payload, parse_comment_payload, FunctionBuilder};
use serde_json::json;
use std::{
    collections::HashMap,
    ffi::c_void,
    os::raw::{c_char, c_uint, c_ulonglong},
    str::FromStr,
    u64,
};
use ton_abi::{ParamType, Token};
use ton_block::MsgAddressInt;

#[no_mangle]
pub unsafe extern "C" fn pack_std_smc_addr(
    base64_url: c_uint,
    addr: *mut c_char,
    bounceable: c_uint,
) -> *mut c_void {
    let result = internal_pack_std_smc_addr(base64_url, addr, bounceable);
    match_result(result)
}

fn internal_pack_std_smc_addr(
    base64_url: c_uint,
    addr: *mut c_char,
    bounceable: c_uint,
) -> Result<u64, NativeError> {
    let base64_url = base64_url != 0;
    let bounceable = bounceable != 0;

    let addr = addr.from_ptr();
    let addr = MsgAddressInt::from_str(&addr).handle_error(NativeStatus::ConversionError)?;

    let packed_addr =
        nekoton_utils::pack_std_smc_addr(base64_url, &addr, bounceable).map_err(|e| {
            NativeError {
                status: NativeStatus::ConversionError,
                info: e.to_string(),
            }
        })?;

    Ok(packed_addr.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn unpack_std_smc_addr(
    packed: *mut c_char,
    base64_url: c_uint,
) -> *mut c_void {
    let result = internal_unpack_std_smc_addr(packed, base64_url);
    match_result(result)
}

fn internal_unpack_std_smc_addr(
    packed: *mut c_char,
    base64_url: c_uint,
) -> Result<u64, NativeError> {
    let base64_url = base64_url != 0;
    let packed = packed.from_ptr();

    let unpacked_addr = nekoton_utils::unpack_std_smc_addr(&packed, base64_url)
        .handle_error(NativeStatus::ConversionError)?;
    let unpacked_addr = unpacked_addr.to_string();

    Ok(unpacked_addr.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn validate_address(address: *mut c_char) -> *mut c_void {
    let result = nekoton_utils::validate_address(&address.from_ptr());
    match_result(Ok(result as c_ulonglong))
}

#[no_mangle]
pub unsafe extern "C" fn repack_address(address: *mut c_char) -> *mut c_void {
    let result = internal_repack_address(address);
    match_result(result)
}

fn internal_repack_address(address: *mut c_char) -> Result<u64, NativeError> {
    let address = address.from_ptr();

    let address =
        nekoton_utils::repack_address(&address).handle_error(NativeStatus::ConversionError)?;
    let address = address.to_string();

    Ok(address.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn parse_message_body_data(data: *mut c_char) -> *mut c_void {
    let result = internal_parse_message_body_data(data);
    match_result(result)
}

fn internal_parse_message_body_data(data: *mut c_char) -> Result<u64, NativeError> {
    let data = data.from_ptr();

    let data = create_boc_payload(&data).handle_error(NativeStatus::AbiError)?;

    if let Some(comment) = parse_comment_payload(data.clone()) {
        let result = json!({ "runtimeType": "comment", "value": comment }).to_string();
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "onRoundComplete";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("roundId", ParamType::Uint(64))
        .in_arg("reward", ParamType::Uint(64))
        .in_arg("ordinaryStake", ParamType::Uint(64))
        .in_arg("vestingStake", ParamType::Uint(64))
        .in_arg("lockStake", ParamType::Uint(64))
        .in_arg("reinvest", ParamType::Bool)
        .in_arg("reason", ParamType::Uint(8))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "receiveAnswer";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("errcode", ParamType::Uint(32))
        .in_arg("comment", ParamType::Uint(64))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "onTransfer";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("source", ParamType::Address)
        .in_arg("amount", ParamType::Uint(128))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "withdrawFromPoolingRound";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("withdrawValue", ParamType::Uint(64))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "withdrawPart";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("withdrawValue", ParamType::Uint(64))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "withdrawAll";
    let depool_message = FunctionBuilder::new(function_name).build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "cancelWithdrawal";
    let depool_message = FunctionBuilder::new(function_name).build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "addOrdinaryStake";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("stake", ParamType::Uint(64))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "setVestingDonor";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("donor", ParamType::Address)
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "setLockDonor";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("donor", ParamType::Address)
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "addVestingStake";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("stake", ParamType::Uint(64))
        .in_arg("beneficiary", ParamType::Address)
        .in_arg("withdrawalPeriod", ParamType::Uint(32))
        .in_arg("totalPeriod", ParamType::Uint(32))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "addLockStake";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("stake", ParamType::Uint(64))
        .in_arg("beneficiary", ParamType::Address)
        .in_arg("withdrawalPeriod", ParamType::Uint(32))
        .in_arg("totalPeriod", ParamType::Uint(32))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "transferStake";
    let depool_message = FunctionBuilder::new(function_name)
        .in_arg("dest", ParamType::Address)
        .in_arg("amount", ParamType::Uint(64))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "receiveFunds";
    let depool_message = FunctionBuilder::new(function_name).build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    Ok(0)
}

fn serialize_tokens(data_type: &str, tokens: Vec<Token>) -> Result<String, NativeError> {
    let mut map = HashMap::new();

    map.insert("runtimeType".to_owned(), data_type.to_owned());
    tokens.iter().for_each(|e| {
        map.insert(e.name.clone(), e.value.to_string());
    });
    let string = serde_json::to_string(&map).handle_error(NativeStatus::ConversionError)?;

    Ok(string)
}
