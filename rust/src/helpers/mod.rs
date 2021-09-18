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
    os::raw::{c_char, c_schar, c_uint, c_ulonglong},
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
        .input("roundId", ParamType::Uint(64))
        .input("reward", ParamType::Uint(64))
        .input("ordinaryStake", ParamType::Uint(64))
        .input("vestingStake", ParamType::Uint(64))
        .input("lockStake", ParamType::Uint(64))
        .input("reinvest", ParamType::Bool)
        .input("reason", ParamType::Uint(8))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "receiveAnswer";
    let depool_message = FunctionBuilder::new(function_name)
        .input("errcode", ParamType::Uint(32))
        .input("comment", ParamType::Uint(64))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "onTransfer";
    let depool_message = FunctionBuilder::new(function_name)
        .input("source", ParamType::Address)
        .input("amount", ParamType::Uint(128))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "withdrawFromPoolingRound";
    let depool_message = FunctionBuilder::new(function_name)
        .input("withdrawValue", ParamType::Uint(64))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "withdrawPart";
    let depool_message = FunctionBuilder::new(function_name)
        .input("withdrawValue", ParamType::Uint(64))
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
        .input("stake", ParamType::Uint(64))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "setVestingDonor";
    let depool_message = FunctionBuilder::new(function_name)
        .input("donor", ParamType::Address)
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "setLockDonor";
    let depool_message = FunctionBuilder::new(function_name)
        .input("donor", ParamType::Address)
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "addVestingStake";
    let depool_message = FunctionBuilder::new(function_name)
        .input("stake", ParamType::Uint(64))
        .input("beneficiary", ParamType::Address)
        .input("withdrawalPeriod", ParamType::Uint(32))
        .input("totalPeriod", ParamType::Uint(32))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "addLockStake";
    let depool_message = FunctionBuilder::new(function_name)
        .input("stake", ParamType::Uint(64))
        .input("beneficiary", ParamType::Address)
        .input("withdrawalPeriod", ParamType::Uint(32))
        .input("totalPeriod", ParamType::Uint(32))
        .build();
    if let Ok(tokens) = depool_message.decode_input(data.clone(), true) {
        let result = serialize_tokens(function_name, tokens)?;
        return Ok(result.to_ptr() as c_ulonglong);
    }

    let function_name = "transferStake";
    let depool_message = FunctionBuilder::new(function_name)
        .input("dest", ParamType::Address)
        .input("amount", ParamType::Uint(64))
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

#[no_mangle]
pub unsafe extern "C" fn run_local(
    gen_timings: *mut c_char,
    last_transaction_id: *mut c_char,
    account_stuff_boc: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
    input: *mut c_char,
) -> *mut c_void {
    let gen_timings = gen_timings.from_ptr();
    let last_transaction_id = last_transaction_id.from_ptr();
    let account_stuff_boc = account_stuff_boc.from_ptr();
    let contract_abi = contract_abi.from_ptr();
    let method = method.from_ptr();
    let input = input.from_ptr();

    let result = internal_run_local(
        gen_timings,
        last_transaction_id,
        account_stuff_boc,
        contract_abi,
        method,
        input,
    );
    match_result(result)
}

fn internal_run_local(
    gen_timings: String,
    last_transaction_id: String,
    account_stuff_boc: String,
    contract_abi: String,
    method: String,
    input: String,
) -> Result<u64, NativeError> {
    let result = String::from("{output: {}, code: 0}");

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_expected_address(
    tvc: *mut c_char,
    contract_abi: *mut c_char,
    workchain_id: c_schar,
    public_key: *mut c_char,
    init_data: *mut c_char,
) -> *mut c_void {
    let tvc = tvc.from_ptr();
    let contract_abi = contract_abi.from_ptr();
    let public_key = public_key.from_ptr();
    let init_data = init_data.from_ptr();

    let result =
        internal_get_expected_address(tvc, contract_abi, workchain_id, public_key, init_data);
    match_result(result)
}

fn internal_get_expected_address(
    tvc: String,
    contract_abi: String,
    workchain_id: i8,
    public_key: String,
    init_data: String,
) -> Result<u64, NativeError> {
    let result = String::new();

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn pack_into_cell(params: *mut c_char, tokens: *mut c_char) -> *mut c_void {
    let params = params.from_ptr();
    let tokens = tokens.from_ptr();

    let result = internal_pack_into_cell(params, tokens);
    match_result(result)
}

fn internal_pack_into_cell(params: String, tokens: String) -> Result<u64, NativeError> {
    let result = String::new();

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn unpack_from_cell(
    params: *mut c_char,
    boc: *mut c_char,
    allow_partial: c_uint,
) -> *mut c_void {
    let params = params.from_ptr();
    let boc = boc.from_ptr();
    let allow_partial = allow_partial != 0;

    let result = internal_unpack_from_cell(params, boc, allow_partial);
    match_result(result)
}

fn internal_unpack_from_cell(
    params: String,
    boc: String,
    allow_partial: bool,
) -> Result<u64, NativeError> {
    let result = String::from("{}");

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn extract_public_key(boc: *mut c_char) -> *mut c_void {
    let boc = boc.from_ptr();

    let result = internal_extract_public_key(boc);
    match_result(result)
}

fn internal_extract_public_key(boc: String) -> Result<u64, NativeError> {
    let result = String::new();

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn code_to_tvc(code: *mut c_char) -> *mut c_void {
    let code = code.from_ptr();

    let result = internal_code_to_tvc(code);
    match_result(result)
}

fn internal_code_to_tvc(code: String) -> Result<u64, NativeError> {
    let result = String::new();

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn split_tvc(tvc: *mut c_char) -> *mut c_void {
    let tvc = tvc.from_ptr();

    let result = internal_split_tvc(tvc);
    match_result(result)
}

fn internal_split_tvc(tvc: String) -> Result<u64, NativeError> {
    let result = String::from("{data:\"data\", code: \"code\"}");

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn encode_internal_input(
    contract_abi: *mut c_char,
    method: *mut c_char,
    input: *mut c_char,
) -> *mut c_void {
    let contract_abi = contract_abi.from_ptr();
    let method = method.from_ptr();
    let input = input.from_ptr();

    let result = internal_encode_internal_input(contract_abi, method, input);
    match_result(result)
}

fn internal_encode_internal_input(
    contract_abi: String,
    method: String,
    input: String,
) -> Result<u64, NativeError> {
    let result = String::new();

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn decode_input(
    message_body: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
    internal: c_uint,
) -> *mut c_void {
    let message_body = message_body.from_ptr();
    let contract_abi = contract_abi.from_ptr();
    let method = method.from_ptr();
    let internal = internal != 0;

    let result = internal_decode_input(message_body, contract_abi, method, internal);
    match_result(result)
}

fn internal_decode_input(
    message_body: String,
    contract_abi: String,
    method: String,
    internal: bool,
) -> Result<u64, NativeError> {
    let result = String::from("{method:\"method\", input: {}}");

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn decode_output(
    message_body: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
) -> *mut c_void {
    let message_body = message_body.from_ptr();
    let contract_abi = contract_abi.from_ptr();
    let method = method.from_ptr();

    let result = internal_decode_output(message_body, contract_abi, method);
    match_result(result)
}

fn internal_decode_output(
    message_body: String,
    contract_abi: String,
    method: String,
) -> Result<u64, NativeError> {
    let result = String::from("{method:\"method\", output: {}}");

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn decode_event(
    message_body: *mut c_char,
    contract_abi: *mut c_char,
    event: *mut c_char,
) -> *mut c_void {
    let message_body = message_body.from_ptr();
    let contract_abi = contract_abi.from_ptr();
    let event = event.from_ptr();

    let result = internal_decode_event(message_body, contract_abi, event);
    match_result(result)
}

fn internal_decode_event(
    message_body: String,
    contract_abi: String,
    event: String,
) -> Result<u64, NativeError> {
    let result = String::from("{event:\"event\", data: {}}");

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn decode_transaction(
    transaction: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
) -> *mut c_void {
    let transaction = transaction.from_ptr();
    let contract_abi = contract_abi.from_ptr();
    let method = method.from_ptr();

    let result = internal_decode_transaction(transaction, contract_abi, method);
    match_result(result)
}

fn internal_decode_transaction(
    transaction: String,
    contract_abi: String,
    method: String,
) -> Result<u64, NativeError> {
    let result = String::from("{method:\"method\", input: {}, output:{}}");

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn decode_transaction_events(
    transaction: *mut c_char,
    contract_abi: *mut c_char,
) -> *mut c_void {
    let transaction = transaction.from_ptr();
    let contract_abi = contract_abi.from_ptr();

    let result = internal_decode_transaction_events(transaction, contract_abi);
    match_result(result)
}

fn internal_decode_transaction_events(
    transaction: String,
    contract_abi: String,
) -> Result<u64, NativeError> {
    let result = String::from("[{event:\"event\", data: {}}]");

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn create_external_message(
    dst: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
    state_init: *mut c_char,
    input: *mut c_char,
    public_key: *mut c_char,
    timeout: c_uint,
) -> *mut c_void {
    let dst = dst.from_ptr();
    let contract_abi = contract_abi.from_ptr();
    let method = method.from_ptr();
    let state_init = if !state_init.is_null() {
        Some(state_init.from_ptr())
    } else {
        None
    };
    let input = input.from_ptr();
    let public_key = public_key.from_ptr();

    let result = internal_create_external_message(
        dst,
        contract_abi,
        method,
        state_init,
        input,
        public_key,
        timeout,
    );
    match_result(result)
}

fn internal_create_external_message(
    dst: String,
    contract_abi: String,
    method: String,
    state_init: Option<String>,
    input: String,
    public_key: String,
    timeout: u32,
) -> Result<u64, NativeError> {
    let result = String::new();

    Ok(result.to_ptr() as c_ulonglong)
}
