pub mod models;

use self::models::{
    DecodedEvent, DecodedInput, DecodedOutput, DecodedTransaction, DecodedTransactionEvent,
    ExecutionOutput, SplittedTvc,
};
use crate::{
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    parse_address, parse_public_key, FromPtr, ToPtr,
};
use nekoton::core::models::Transaction;
use nekoton_abi::{
    create_boc_payload, get_state_init_hash, guess_method_by_input, parse_comment_payload,
    FunctionBuilder, FunctionExt, GenTimings, LastTransactionId, MethodName,
};
use serde_json::json;
use std::{
    borrow::Cow,
    collections::HashMap,
    ffi::c_void,
    os::raw::{c_char, c_schar, c_uint, c_ulonglong},
    sync::Arc,
    u64,
};
use tokio::sync::Mutex;
use ton_abi::{ParamType, Token};
use ton_block::{Deserializable, MsgAddressInt, Serializable};

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
    let addr = parse_address(&addr)?;

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
    let gen_timings = parse_gen_timings(&gen_timings)?;
    let last_transaction_id = parse_last_transaction_id(&last_transaction_id)?;
    let account_stuff = parse_account_stuff(&account_stuff_boc)?;
    let contract_abi = parse_contract_abi(&contract_abi)?;
    let method = contract_abi
        .function(&method)
        .handle_error(NativeStatus::AbiError)?;
    let input = parse_abi_tokens_value(&input)?;
    let input = nekoton_abi::parse_abi_tokens(&method.inputs, input)
        .handle_error(NativeStatus::ConversionError)?;

    let output = method
        .run_local(account_stuff, gen_timings, &last_transaction_id, &input)
        .handle_error(NativeStatus::AbiError)?;

    let tokens = output
        .tokens
        .map(|e| nekoton_abi::make_abi_tokens(&e).handle_error(NativeStatus::AbiError))
        .transpose()?;

    let execution_output = ExecutionOutput {
        output: tokens,
        code: output.result_code,
    };
    let execution_output =
        serde_json::to_string(&execution_output).handle_error(NativeStatus::ConversionError)?;

    Ok(execution_output.to_ptr() as c_ulonglong)
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
    let public_key = match !public_key.is_null() {
        true => Some(public_key.from_ptr()),
        false => None,
    };
    let init_data = init_data.from_ptr();

    let result =
        internal_get_expected_address(tvc, contract_abi, workchain_id, public_key, init_data);
    match_result(result)
}

fn internal_get_expected_address(
    tvc: String,
    contract_abi: String,
    workchain_id: i8,
    public_key: Option<String>,
    init_data: String,
) -> Result<u64, NativeError> {
    let state_init = ton_block::StateInit::construct_from_base64(&tvc)
        .handle_error(NativeStatus::ConversionError)?;
    let contract_abi = parse_contract_abi(&contract_abi)?;
    let public_key = public_key.as_deref().map(parse_public_key).transpose()?;

    let params = contract_abi
        .data()
        .iter()
        .map(|(_, v)| v.value.clone())
        .collect::<Vec<ton_abi::Param>>();

    let init_data = parse_abi_tokens_value(&init_data)?;
    let init_data = nekoton_abi::parse_abi_tokens(&params, init_data)
        .handle_error(NativeStatus::ConversionError)?;

    let hash = get_state_init_hash(state_init, &contract_abi, &public_key, init_data)
        .handle_error(NativeStatus::ConversionError)?;

    let result = MsgAddressInt::AddrStd(ton_block::MsgAddrStd {
        anycast: None,
        workchain_id,
        address: hash.into(),
    })
    .to_string();

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
    let params = parse_params_list(&params)?;
    let tokens = parse_abi_tokens_value(&tokens)?;
    let tokens = nekoton_abi::parse_abi_tokens(&params, tokens)
        .handle_error(NativeStatus::ConversionError)?;

    let cell = nekoton_abi::pack_into_cell(&tokens).handle_error(NativeStatus::AbiError)?;
    let bytes = ton_types::serialize_toc(&cell).handle_error(NativeStatus::ConversionError)?;

    let result = base64::encode(&bytes);

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
    let params = parse_params_list(&params)?;
    let body = base64::decode(boc).handle_error(NativeStatus::ConversionError)?;
    let cell = ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(&body))
        .handle_error(NativeStatus::ConversionError)?;
    let result = nekoton_abi::unpack_from_cell(&params, cell.into(), allow_partial)
        .handle_error(NativeStatus::ConversionError)
        .and_then(|tokens| {
            nekoton_abi::make_abi_tokens(&tokens).handle_error(NativeStatus::ConversionError)
        })?;

    let result = serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?;

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn extract_public_key(boc: *mut c_char) -> *mut c_void {
    let boc = boc.from_ptr();

    let result = internal_extract_public_key(boc);
    match_result(result)
}

fn internal_extract_public_key(boc: String) -> Result<u64, NativeError> {
    let public_key = parse_account_stuff(&boc)
        .and_then(|x| nekoton_abi::extract_public_key(&x).handle_error(NativeStatus::AbiError))
        .map(hex::encode)?;

    Ok(public_key.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn code_to_tvc(code: *mut c_char) -> *mut c_void {
    let code = code.from_ptr();

    let result = internal_code_to_tvc(code);
    match_result(result)
}

fn internal_code_to_tvc(code: String) -> Result<u64, NativeError> {
    let cell = base64::decode(code).handle_error(NativeStatus::ConversionError)?;
    let result = ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(cell))
        .handle_error(NativeStatus::AbiError)
        .and_then(|x| nekoton_abi::code_to_tvc(x).handle_error(NativeStatus::AbiError))
        .and_then(|x| x.serialize().handle_error(NativeStatus::AbiError))
        .and_then(|x| ton_types::serialize_toc(&x).handle_error(NativeStatus::AbiError))
        .map(base64::encode)?;

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn split_tvc(tvc: *mut c_char) -> *mut c_void {
    let tvc = tvc.from_ptr();

    let result = internal_split_tvc(tvc);
    match_result(result)
}

fn internal_split_tvc(tvc: String) -> Result<u64, NativeError> {
    let state_init = ton_block::StateInit::construct_from_base64(&tvc)
        .handle_error(NativeStatus::ConversionError)?;

    let data = match state_init.data {
        Some(data) => {
            let data =
                ton_types::serialize_toc(&data).handle_error(NativeStatus::ConversionError)?;
            Some(base64::encode(data))
        }
        None => None,
    };

    let code = match state_init.code {
        Some(code) => {
            let code =
                ton_types::serialize_toc(&code).handle_error(NativeStatus::ConversionError)?;
            Some(base64::encode(code))
        }
        None => None,
    };

    let result = SplittedTvc { data, code };
    let result = serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?;

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
    let contract_abi = parse_contract_abi(&contract_abi)?;
    let method = contract_abi
        .function(&method)
        .handle_error(NativeStatus::AbiError)?;
    let input = parse_abi_tokens_value(&input)?;
    let input = nekoton_abi::parse_abi_tokens(&method.inputs, input)
        .handle_error(NativeStatus::ConversionError)?;

    let body = method
        .encode_input(&Default::default(), &input, true, None)
        .and_then(|value| value.into_cell())
        .handle_error(NativeStatus::AbiError)?;
    let body = ton_types::serialize_toc(&body).handle_error(NativeStatus::ConversionError)?;
    let result = base64::encode(&body);

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
    let message_body = parse_slice(&message_body)?;
    let contract_abi = parse_contract_abi(&contract_abi)?;
    let method = parse_method_name(&method)?;

    let result = nekoton_abi::decode_input(&contract_abi, message_body, &method, internal)
        .handle_error(NativeStatus::AbiError)?;
    let result = match result {
        Some((method, input)) => {
            let input =
                nekoton_abi::make_abi_tokens(&input).handle_error(NativeStatus::ConversionError)?;
            let result = DecodedInput {
                method: method.name.clone(),
                input,
            };
            serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?
        }
        None => get_null_string()?,
    };

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
    let message_body = parse_slice(&message_body)?;
    let contract_abi = parse_contract_abi(&contract_abi)?;
    let method = parse_method_name(&method)?;

    let result = nekoton_abi::decode_output(&contract_abi, message_body, &method)
        .handle_error(NativeStatus::AbiError)?;
    let result = match result {
        Some((method, output)) => {
            let output = nekoton_abi::make_abi_tokens(&output)
                .handle_error(NativeStatus::ConversionError)?;
            let result = DecodedOutput {
                method: method.name.clone(),
                output,
            };
            serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?
        }
        None => get_null_string()?,
    };

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
    let message_body = parse_slice(&message_body)?;
    let contract_abi = parse_contract_abi(&contract_abi)?;
    let event = parse_method_name(&event)?;

    let result = nekoton_abi::decode_event(&contract_abi, message_body, &event)
        .handle_error(NativeStatus::AbiError)?;
    let result = match result {
        Some((event, data)) => {
            let data =
                nekoton_abi::make_abi_tokens(&data).handle_error(NativeStatus::ConversionError)?;
            let result = DecodedEvent {
                event: event.name.clone(),
                data,
            };
            serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?
        }
        None => get_null_string()?,
    };

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
    let transaction = parse_transaction(&transaction)?;
    let contract_abi = parse_contract_abi(&contract_abi)?;
    let method = parse_method_name(&method)?;

    let internal = transaction.in_msg.src.is_some();

    let in_msg_body = match transaction.in_msg.body {
        Some(body) => body.data.into(),
        None => return Ok(get_null_string()?.to_ptr() as c_ulonglong),
    };

    let method = match guess_method_by_input(&contract_abi, &in_msg_body, &method, internal)
        .handle_error(NativeStatus::ConversionError)?
    {
        Some(method) => method,
        None => return Ok(get_null_string()?.to_ptr() as c_ulonglong),
    };

    let input = method
        .decode_input(in_msg_body, internal)
        .handle_error(NativeStatus::AbiError)?;

    let ext_out_msgs = transaction
        .out_msgs
        .iter()
        .filter_map(|message| {
            match message.dst.clone() {
                Some(_) => return None,
                _ => {}
            };

            Some(match message.body.clone() {
                Some(body) => Ok(body.data.into()),
                None => Err("Expected message body").handle_error(NativeStatus::AbiError),
            })
        })
        .collect::<Result<Vec<_>, NativeError>>()?;

    let output = nekoton_abi::process_raw_outputs(&ext_out_msgs, method)
        .handle_error(NativeStatus::AbiError)?;

    let input = nekoton_abi::make_abi_tokens(&input).handle_error(NativeStatus::ConversionError)?;
    let output =
        nekoton_abi::make_abi_tokens(&output).handle_error(NativeStatus::ConversionError)?;

    let result = DecodedTransaction {
        method: method.name.clone(),
        input,
        output,
    };
    let result = serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?;

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
    let transaction = parse_transaction(&transaction)?;
    let contract_abi = parse_contract_abi(&contract_abi)?;

    let ext_out_msgs = transaction
        .out_msgs
        .iter()
        .filter_map(|message| {
            match message.dst.clone() {
                Some(_) => return None,
                _ => {}
            };

            Some(match message.body.clone() {
                Some(body) => Ok(body.data.into()),
                None => Err("Expected message body").handle_error(NativeStatus::AbiError),
            })
        })
        .collect::<Result<Vec<_>, NativeError>>()?;

    let events = ext_out_msgs
        .into_iter()
        .filter_map(|body| {
            let id = nekoton_abi::read_function_id(&body).ok()?;
            let event = contract_abi.event_by_id(id).ok()?;
            let tokens = event.decode_input(body).ok()?;

            Some(match nekoton_abi::make_abi_tokens(&tokens) {
                Ok(data) => Ok(DecodedTransactionEvent {
                    event: event.name.clone(),
                    data,
                }),
                Err(err) => Err(err).handle_error(NativeStatus::AbiError),
            })
        })
        .collect::<Result<Vec<_>, NativeError>>()?;

    let result = serde_json::to_string(&events).handle_error(NativeStatus::ConversionError)?;

    Ok(result.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn parse_known_payload(payload: *mut c_char) -> *mut c_void {
    let payload = payload.from_ptr();

    let result = internal_parse_known_payload(payload);
    match_result(result)
}

fn internal_parse_known_payload(payload: String) -> Result<u64, NativeError> {
    let payload = parse_slice(&payload)?;
    let known_payload = nekoton::core::parsing::parse_payload(payload);
    let result = known_payload.map(|e| crate::core::ton_wallet::models::KnownPayload::from_core(e));
    let result = serde_json::to_string(&result).handle_error(NativeStatus::ConversionError)?;

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
    let dst = parse_address(&dst)?;
    let contract_abi = parse_contract_abi(&contract_abi)?;
    let method = contract_abi
        .function(&method)
        .handle_error(NativeStatus::AbiError)?;
    let state_init = state_init
        .as_deref()
        .map(ton_block::StateInit::construct_from_base64)
        .transpose()
        .handle_error(NativeStatus::ConversionError)?;
    let input = parse_abi_tokens_value(&input)?;
    let input = nekoton_abi::parse_abi_tokens(&method.inputs, input)
        .handle_error(NativeStatus::ConversionError)?;
    let public_key = parse_public_key(&public_key)?;

    let mut message =
        ton_block::Message::with_ext_in_header(ton_block::ExternalInboundMessageHeader {
            dst,
            ..Default::default()
        });
    if let Some(state_init) = state_init {
        message.set_state_init(state_init);
    }

    let message = nekoton::core::utils::make_labs_unsigned_message(
        message,
        nekoton::core::models::Expiration::Timeout(timeout),
        &public_key,
        Cow::Owned(method.clone()),
        input,
    )
    .handle_error(NativeStatus::AbiError)?;

    let message = Mutex::new(message);
    let message = Arc::new(message);

    let message = Arc::into_raw(message) as c_ulonglong;

    Ok(message)
}

fn parse_account_stuff(boc: &str) -> Result<ton_block::AccountStuff, NativeError> {
    ton_block::AccountStuff::construct_from_base64(boc).handle_error(NativeStatus::ConversionError)
}

fn parse_contract_abi(contract_abi: &str) -> Result<ton_abi::Contract, NativeError> {
    ton_abi::Contract::load(&mut std::io::Cursor::new(contract_abi))
        .handle_error(NativeStatus::ConversionError)
}

fn parse_last_transaction_id(data: &str) -> Result<LastTransactionId, NativeError> {
    serde_json::from_str::<LastTransactionId>(&data).handle_error(NativeStatus::ConversionError)
}

fn parse_gen_timings(data: &str) -> Result<GenTimings, NativeError> {
    serde_json::from_str::<GenTimings>(&data).handle_error(NativeStatus::ConversionError)
}

fn parse_params_list(data: &str) -> Result<Vec<ton_abi::Param>, NativeError> {
    serde_json::from_str::<Vec<ton_abi::Param>>(data).handle_error(NativeStatus::ConversionError)
}

fn parse_abi_tokens_value(data: &str) -> Result<serde_json::Value, NativeError> {
    serde_json::from_str::<serde_json::Value>(&data).handle_error(NativeStatus::ConversionError)
}

fn parse_slice(boc: &str) -> Result<ton_types::SliceData, NativeError> {
    let body = base64::decode(boc).handle_error(NativeStatus::ConversionError)?;
    let cell = ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(&body))
        .handle_error(NativeStatus::ConversionError)?;
    Ok(cell.into())
}

fn parse_method_name(value: &str) -> Result<MethodName, NativeError> {
    if let Ok(value) = serde_json::from_str::<String>(&value) {
        Ok(MethodName::Known(value))
    } else if let Ok(value) = serde_json::from_str::<Vec<String>>(&value) {
        Ok(MethodName::GuessInRange(value))
    } else {
        Err(value).handle_error(NativeStatus::ConversionError)
    }
}

fn parse_transaction(data: &str) -> Result<Transaction, NativeError> {
    serde_json::from_str::<Transaction>(&data).handle_error(NativeStatus::ConversionError)
}

fn get_null_string() -> Result<String, NativeError> {
    serde_json::to_string(&json!(null)).handle_error(NativeStatus::ConversionError)
}
