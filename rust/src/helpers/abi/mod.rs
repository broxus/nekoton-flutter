mod models;

use std::{
    borrow::Cow,
    collections::HashMap,
    os::raw::{c_char, c_schar, c_uint},
    str::FromStr,
    sync::Arc,
    time::{SystemTime, UNIX_EPOCH},
};

use nekoton::{
    core::{
        models::{Expiration, ExpireAt, Transaction},
        parsing::parse_payload,
        utils::make_labs_unsigned_message,
    },
    crypto::SignedMessage,
};
use nekoton_abi::{guess_method_by_input, insert_state_init_data, FunctionExt, MethodName};
use ton_block::{Deserializable, Serializable};

use crate::{
    clock,
    helpers::{
        abi::models::{
            AbiParam, DecodedEvent, DecodedInput, DecodedOutput, DecodedTransaction,
            DecodedTransactionEvent, ExecutionOutput,
        },
        parse_account_stuff,
    },
    models::{HandleError, MatchResult, ToOptionalStringFromPtr, ToPtrAddress, ToSerializable},
    parse_address, parse_public_key, ToStringFromPtr, CLOCK,
};

#[no_mangle]
pub unsafe extern "C" fn nt_check_public_key(public_key: *mut c_char) -> *mut c_char {
    let public_key = public_key.to_string_from_ptr();

    fn internal_fn(public_key: String) -> Result<serde_json::Value, String> {
        parse_public_key(&public_key)?;

        Ok(serde_json::Value::Null)
    }

    internal_fn(public_key).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_run_local(
    account_stuff_boc: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
    input: *mut c_char,
    responsible: c_uint,
) -> *mut c_char {
    let account_stuff_boc = account_stuff_boc.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();
    let method = method.to_string_from_ptr();
    let input = input.to_string_from_ptr();
    let responsible = responsible != 0;

    fn internal_fn(
        account_stuff_boc: String,
        contract_abi: String,
        method: String,
        input: String,
        responsible: bool,
    ) -> Result<serde_json::Value, String> {
        let account_stuff = parse_account_stuff(&account_stuff_boc)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = contract_abi.function(&method).handle_error()?;

        let input = serde_json::from_str::<serde_json::Value>(&input).handle_error()?;
        let input = nekoton_abi::parse_abi_tokens(&method.inputs, input).handle_error()?;

        let output = if responsible {
            method
                .run_local_responsible(clock!().as_ref(), account_stuff, &input)
                .handle_error()?
        } else {
            method
                .run_local(clock!().as_ref(), account_stuff, &input)
                .handle_error()?
        };

        let tokens = output
            .tokens
            .map(|e| nekoton_abi::make_abi_tokens(&e).handle_error())
            .transpose()?;

        let execution_output = ExecutionOutput {
            output: tokens,
            code: output.result_code,
        };

        serde_json::to_value(execution_output).handle_error()
    }

    internal_fn(account_stuff_boc, contract_abi, method, input, responsible).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_expected_address(
    tvc: *mut c_char,
    contract_abi: *mut c_char,
    workchain_id: c_schar,
    public_key: *mut c_char,
    init_data: *mut c_char,
) -> *mut c_char {
    let tvc = tvc.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();
    let public_key = public_key.to_optional_string_from_ptr();
    let init_data = init_data.to_string_from_ptr();

    fn internal_fn(
        tvc: String,
        contract_abi: String,
        workchain_id: i8,
        public_key: Option<String>,
        init_data: String,
    ) -> Result<serde_json::Value, String> {
        let mut state_init = ton_block::StateInit::construct_from_base64(&tvc).handle_error()?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let public_key = public_key.as_deref().map(parse_public_key).transpose()?;

        let params = contract_abi
            .data
            .iter()
            .map(|(_, v)| v.value.to_owned())
            .collect::<Vec<_>>();

        let init_data = serde_json::from_str::<serde_json::Value>(&init_data).handle_error()?;
        let init_data = nekoton_abi::parse_abi_tokens(&params, init_data).handle_error()?;

        state_init.data = if let Some(data) = state_init.data.take() {
            Some(
                insert_state_init_data(&contract_abi, data.into(), &public_key, init_data)
                    .handle_error()?
                    .into_cell(),
            )
        } else {
            None
        };

        let cell = state_init.serialize().handle_error()?;
        let repr_hash = cell.repr_hash().to_hex_string();

        let address = format!("{workchain_id}:{repr_hash}");
        let state_init = ton_types::serialize_toc(&cell)
            .map(base64::encode)
            .handle_error()?;

        serde_json::to_value((address, state_init)).handle_error()
    }

    internal_fn(tvc, contract_abi, workchain_id, public_key, init_data).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_encode_internal_input(
    contract_abi: *mut c_char,
    method: *mut c_char,
    input: *mut c_char,
) -> *mut c_char {
    let contract_abi = contract_abi.to_string_from_ptr();
    let method = method.to_string_from_ptr();
    let input = input.to_string_from_ptr();

    fn internal_fn(
        contract_abi: String,
        method: String,
        input: String,
    ) -> Result<serde_json::Value, String> {
        let contract_abi = parse_contract_abi(&contract_abi)?;

        let method = contract_abi.function(&method).handle_error()?;

        let input = serde_json::from_str::<serde_json::Value>(&input).handle_error()?;
        let input = nekoton_abi::parse_abi_tokens(&method.inputs, input).handle_error()?;

        let body = method
            .encode_internal_input(&input)
            .and_then(|e| e.into_cell())
            .handle_error()?;

        let body = ton_types::serialize_toc(&body).handle_error()?;

        let body = base64::encode(&body);

        serde_json::to_value(body).handle_error()
    }

    internal_fn(contract_abi, method, input).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_create_external_message_without_signature(
    dst: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
    state_init: *mut c_char,
    input: *mut c_char,
    timeout: c_uint,
) -> *mut c_char {
    let dst = dst.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();
    let method = method.to_string_from_ptr();
    let state_init = state_init.to_optional_string_from_ptr();
    let input = input.to_string_from_ptr();

    fn internal_fn(
        dst: String,
        contract_abi: String,
        method: String,
        state_init: Option<String>,
        input: String,
        timeout: u32,
    ) -> Result<serde_json::Value, String> {
        let dst = parse_address(&dst)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = contract_abi.function(&method).handle_error()?;

        let state_init = state_init
            .as_deref()
            .map(ton_block::StateInit::construct_from_base64)
            .transpose()
            .handle_error()?;

        let input = serde_json::from_str::<serde_json::Value>(&input).handle_error()?;
        let input = nekoton_abi::parse_abi_tokens(&method.inputs, input).handle_error()?;

        let time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis();

        let expire_at = ExpireAt::new_from_millis(
            Expiration::Timeout(timeout),
            time.try_into().handle_error()?,
        );

        let mut header = HashMap::with_capacity(3);

        header.insert(
            "time".to_string(),
            ton_abi::TokenValue::Time(time.try_into().handle_error()?),
        );
        header.insert(
            "expire".to_string(),
            ton_abi::TokenValue::Expire(expire_at.timestamp),
        );
        header.insert("pubkey".to_string(), ton_abi::TokenValue::PublicKey(None));

        let body = method
            .encode_input(&header, &input, false, None, Some(dst.clone()))
            .handle_error()?;

        let mut message =
            ton_block::Message::with_ext_in_header(ton_block::ExternalInboundMessageHeader {
                dst,
                ..Default::default()
            });

        if let Some(state_init) = state_init {
            message.set_state_init(state_init);
        }

        message.set_body(body.into());

        let signed_message = SignedMessage {
            message,
            expire_at: expire_at.timestamp,
        }
        .to_serializable();

        serde_json::to_value(signed_message).handle_error()
    }

    internal_fn(dst, contract_abi, method, state_init, input, timeout).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_create_external_message(
    dst: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
    state_init: *mut c_char,
    input: *mut c_char,
    public_key: *mut c_char,
    timeout: c_uint,
) -> *mut c_char {
    let dst = dst.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();
    let method = method.to_string_from_ptr();
    let state_init = state_init.to_optional_string_from_ptr();
    let input = input.to_string_from_ptr();
    let public_key = public_key.to_string_from_ptr();

    fn internal_fn(
        dst: String,
        contract_abi: String,
        method: String,
        state_init: Option<String>,
        input: String,
        public_key: String,
        timeout: u32,
    ) -> Result<serde_json::Value, String> {
        let dst = parse_address(&dst)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = contract_abi.function(&method).handle_error()?;

        let state_init = state_init
            .as_deref()
            .map(ton_block::StateInit::construct_from_base64)
            .transpose()
            .handle_error()?;

        let input = serde_json::from_str::<serde_json::Value>(&input).handle_error()?;
        let input = nekoton_abi::parse_abi_tokens(&method.inputs, input).handle_error()?;

        let public_key = parse_public_key(&public_key)?;

        let mut message =
            ton_block::Message::with_ext_in_header(ton_block::ExternalInboundMessageHeader {
                dst,
                ..Default::default()
            });

        if let Some(state_init) = state_init {
            message.set_state_init(state_init);
        }

        let unsigned_message = make_labs_unsigned_message(
            clock!().as_ref(),
            message,
            Expiration::Timeout(timeout),
            &public_key,
            Cow::Owned(method.to_owned()),
            input,
        )
        .handle_error()?;

        let ptr = Box::into_raw(Box::new(Arc::new(unsigned_message)));

        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(
        dst,
        contract_abi,
        method,
        state_init,
        input,
        public_key,
        timeout,
    )
    .match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_parse_known_payload(payload: *mut c_char) -> *mut c_char {
    let payload = payload.to_string_from_ptr();

    fn internal_fn(payload: String) -> Result<serde_json::Value, String> {
        let payload = parse_slice(&payload)?;

        let known_payload = parse_payload(payload).map(|e| e.to_serializable());

        serde_json::to_value(known_payload).handle_error()
    }

    internal_fn(payload).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_decode_input(
    message_body: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
    internal: c_uint,
) -> *mut c_char {
    let message_body = message_body.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();
    let method = method.to_optional_string_from_ptr();
    let internal = internal != 0;

    fn internal_fn(
        message_body: String,
        contract_abi: String,
        method: Option<String>,
        internal: bool,
    ) -> Result<serde_json::Value, String> {
        let message_body = parse_slice(&message_body)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = parse_method_name(method)?;

        let input = nekoton_abi::decode_input(&contract_abi, message_body, &method, internal)
            .handle_error()?;

        let input = match input {
            Some((method, input)) => {
                let input = nekoton_abi::make_abi_tokens(&input).handle_error()?;

                let input = DecodedInput {
                    method: method.name.to_owned(),
                    input,
                };

                serde_json::to_value(input).handle_error()?
            }
            None => serde_json::Value::Null,
        };

        Ok(input)
    }

    internal_fn(message_body, contract_abi, method, internal).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_decode_event(
    message_body: *mut c_char,
    contract_abi: *mut c_char,
    event: *mut c_char,
) -> *mut c_char {
    let message_body = message_body.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();
    let event = event.to_optional_string_from_ptr();

    fn internal_fn(
        message_body: String,
        contract_abi: String,
        event: Option<String>,
    ) -> Result<serde_json::Value, String> {
        let message_body = parse_slice(&message_body)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let event = parse_method_name(event)?;

        let event =
            nekoton_abi::decode_event(&contract_abi, message_body, &event).handle_error()?;

        let event = match event {
            Some((event, data)) => {
                let data = nekoton_abi::make_abi_tokens(&data).handle_error()?;

                let event = DecodedEvent {
                    event: event.name.to_owned(),
                    data,
                };

                serde_json::to_value(event).handle_error()?
            }
            None => serde_json::Value::Null,
        };

        Ok(event)
    }

    internal_fn(message_body, contract_abi, event).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_decode_output(
    message_body: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
) -> *mut c_char {
    let message_body = message_body.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();
    let method = method.to_optional_string_from_ptr();

    fn internal_fn(
        message_body: String,
        contract_abi: String,
        method: Option<String>,
    ) -> Result<serde_json::Value, String> {
        let message_body = parse_slice(&message_body)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = parse_method_name(method)?;

        let output =
            nekoton_abi::decode_output(&contract_abi, message_body, &method).handle_error()?;

        let output = match output {
            Some((method, output)) => {
                let output = nekoton_abi::make_abi_tokens(&output).handle_error()?;

                let output = DecodedOutput {
                    method: method.name.to_owned(),
                    output,
                };

                serde_json::to_value(output).handle_error()?
            }
            None => serde_json::Value::Null,
        };

        Ok(output)
    }

    internal_fn(message_body, contract_abi, method).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_decode_transaction(
    transaction: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
) -> *mut c_char {
    let transaction = transaction.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();
    let method = method.to_optional_string_from_ptr();

    fn internal_fn(
        transaction: String,
        contract_abi: String,
        method: Option<String>,
    ) -> Result<serde_json::Value, String> {
        let transaction = serde_json::from_str::<Transaction>(&transaction).handle_error()?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = parse_method_name(method)?;

        let internal = transaction.in_msg.src.is_some();

        let in_msg_body = match transaction.in_msg.body {
            Some(body) => body.data.into(),
            None => return Ok(serde_json::Value::Null),
        };

        let method = match guess_method_by_input(&contract_abi, &in_msg_body, &method, internal)
            .handle_error()?
        {
            Some(method) => method,
            None => return Ok(serde_json::Value::Null),
        };

        let input = method.decode_input(in_msg_body, internal).handle_error()?;
        let input = nekoton_abi::make_abi_tokens(&input).handle_error()?;

        let ext_out_msgs = transaction
            .out_msgs
            .iter()
            .filter_map(|e| {
                if e.dst.is_some() {
                    return None;
                };

                Some(match e.body.to_owned() {
                    Some(body) => Ok(body.data.into()),
                    None => Err("Expected message body").handle_error(),
                })
            })
            .collect::<Result<Vec<_>, String>>()?;

        let output = nekoton_abi::process_raw_outputs(&ext_out_msgs, method).handle_error()?;
        let output = nekoton_abi::make_abi_tokens(&output).handle_error()?;

        let decoded_transaction = DecodedTransaction {
            method: method.name.to_owned(),
            input,
            output,
        };

        serde_json::to_value(decoded_transaction).handle_error()
    }

    internal_fn(transaction, contract_abi, method).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_decode_transaction_events(
    transaction: *mut c_char,
    contract_abi: *mut c_char,
) -> *mut c_char {
    let transaction = transaction.to_string_from_ptr();
    let contract_abi = contract_abi.to_string_from_ptr();

    fn internal_fn(transaction: String, contract_abi: String) -> Result<serde_json::Value, String> {
        let transaction = serde_json::from_str::<Transaction>(&transaction).handle_error()?;
        let contract_abi = parse_contract_abi(&contract_abi)?;

        let ext_out_msgs = transaction
            .out_msgs
            .iter()
            .filter_map(|e| {
                if e.dst.is_some() {
                    return None;
                };

                Some(match e.body.to_owned() {
                    Some(body) => Ok(body.data.into()),
                    None => Err("Expected message body").handle_error(),
                })
            })
            .collect::<Result<Vec<_>, String>>()?;

        let events = ext_out_msgs
            .into_iter()
            .filter_map(|e| {
                let id = nekoton_abi::read_function_id(&e).ok()?;
                let event = contract_abi.event_by_id(id).ok()?;
                let tokens = event.decode_input(e).ok()?;

                let data = match nekoton_abi::make_abi_tokens(&tokens) {
                    Ok(data) => Ok(DecodedTransactionEvent {
                        event: event.name.to_owned(),
                        data,
                    }),
                    Err(err) => Err(err).handle_error(),
                };

                Some(data)
            })
            .collect::<Result<Vec<_>, String>>()?;

        serde_json::to_value(events).handle_error()
    }

    internal_fn(transaction, contract_abi).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_boc_hash(boc: *mut c_char) -> *mut c_char {
    let boc = boc.to_string_from_ptr();

    fn internal_fn(boc: String) -> Result<serde_json::Value, String> {
        let body = base64::decode(boc).handle_error()?;

        let hash = ton_types::deserialize_tree_of_cells(&mut body.as_slice())
            .handle_error()?
            .repr_hash()
            .to_hex_string();

        serde_json::to_value(hash).handle_error()
    }

    internal_fn(boc).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_pack_into_cell(
    params: *mut c_char,
    tokens: *mut c_char,
) -> *mut c_char {
    let params = params.to_string_from_ptr();
    let tokens = tokens.to_string_from_ptr();

    fn internal_fn(params: String, tokens: String) -> Result<serde_json::Value, String> {
        let params = parse_params_list(&params)?;
        let tokens = serde_json::from_str::<serde_json::Value>(&tokens).handle_error()?;
        let tokens = nekoton_abi::parse_abi_tokens(&params, tokens).handle_error()?;
        let version = ton_abi::contract::AbiVersion { major: 2, minor: 2 };

        let cell = nekoton_abi::pack_into_cell(&tokens, version).handle_error()?;
        let bytes = ton_types::serialize_toc(&cell).handle_error()?;

        let bytes = base64::encode(&bytes);

        serde_json::to_value(bytes).handle_error()
    }

    internal_fn(params, tokens).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_unpack_from_cell(
    params: *mut c_char,
    boc: *mut c_char,
    allow_partial: c_uint,
) -> *mut c_char {
    let params = params.to_string_from_ptr();
    let boc = boc.to_string_from_ptr();
    let allow_partial = allow_partial != 0;

    fn internal_fn(
        params: String,
        boc: String,
        allow_partial: bool,
    ) -> Result<serde_json::Value, String> {
        let params = parse_params_list(&params)?;
        let body = base64::decode(boc).handle_error()?;
        let cell = ton_types::deserialize_tree_of_cells(&mut body.as_slice()).handle_error()?;
        let version = ton_abi::contract::AbiVersion { major: 2, minor: 2 };

        let tokens = nekoton_abi::unpack_from_cell(&params, cell.into(), allow_partial, version)
            .handle_error()
            .and_then(|e| nekoton_abi::make_abi_tokens(&e).handle_error())?;

        serde_json::to_value(tokens).handle_error()
    }

    internal_fn(params, boc, allow_partial).match_result()
}

fn parse_contract_abi(contract_abi: &str) -> Result<ton_abi::Contract, String> {
    ton_abi::Contract::load(contract_abi).handle_error()
}

fn parse_method_name(value: Option<String>) -> Result<MethodName, String> {
    match value {
        Some(value) => {
            if let Ok(value) = serde_json::from_str::<String>(&value) {
                Ok(MethodName::Known(value))
            } else if let Ok(value) = serde_json::from_str::<Vec<String>>(&value) {
                Ok(MethodName::GuessInRange(value))
            } else {
                Err(AbiError::ExpectedStringOrArray).handle_error()
            }
        }
        None => Ok(MethodName::Guess),
    }
}

fn parse_slice(boc: &str) -> Result<ton_types::SliceData, String> {
    let body = base64::decode(boc).handle_error()?;
    let cell = ton_types::deserialize_tree_of_cells(&mut body.as_slice()).handle_error()?;
    Ok(cell.into())
}

fn parse_params_list(params: &str) -> Result<Vec<ton_abi::Param>, String> {
    let params = serde_json::from_str::<Vec<AbiParam>>(params).handle_error()?;

    params
        .iter()
        .map(parse_param)
        .collect::<Result<_, AbiError>>()
        .handle_error()
}

fn parse_param(param: &AbiParam) -> Result<ton_abi::Param, AbiError> {
    let name = param.name.to_owned();

    let mut kind: ton_abi::ParamType = parse_param_type(&param.param_type)?;

    let components: Vec<ton_abi::Param> = match &param.components {
        Some(components) => components
            .iter()
            .map(parse_param)
            .collect::<Result<_, AbiError>>()?,
        None => Vec::new(),
    };

    kind.set_components(components)
        .map_err(|_| AbiError::InvalidComponents)?;

    Ok(ton_abi::Param { name, kind })
}

fn parse_param_type(kind: &str) -> Result<ton_abi::ParamType, AbiError> {
    if let Some(']') = kind.chars().last() {
        let num: String = kind
            .chars()
            .rev()
            .skip(1)
            .take_while(|c| *c != '[')
            .collect::<String>()
            .chars()
            .rev()
            .collect();

        let count = kind.len();
        return if num.is_empty() {
            let subtype = parse_param_type(&kind[..count - 2])?;
            Ok(ton_abi::ParamType::Array(Box::new(subtype)))
        } else {
            let len = num
                .parse::<usize>()
                .map_err(|_| AbiError::ExpectedParamType)?;

            let subtype = parse_param_type(&kind[..count - num.len() - 2])?;
            Ok(ton_abi::ParamType::FixedArray(Box::new(subtype), len))
        };
    }

    let result = match kind {
        "bool" => ton_abi::ParamType::Bool,
        "tuple" => ton_abi::ParamType::Tuple(Vec::new()),
        s if s.starts_with("int") => {
            let len = usize::from_str(&s[3..]).map_err(|_| AbiError::ExpectedParamType)?;
            ton_abi::ParamType::Int(len)
        }
        s if s.starts_with("uint") => {
            let len = usize::from_str(&s[4..]).map_err(|_| AbiError::ExpectedParamType)?;
            ton_abi::ParamType::Uint(len)
        }
        s if s.starts_with("varint") => {
            let len = usize::from_str(&s[6..]).map_err(|_| AbiError::ExpectedParamType)?;
            ton_abi::ParamType::Int(len)
        }
        s if s.starts_with("varuint") => {
            let len = usize::from_str(&s[7..]).map_err(|_| AbiError::ExpectedParamType)?;
            ton_abi::ParamType::Uint(len)
        }
        s if s.starts_with("map(") && s.ends_with(')') => {
            let types: Vec<&str> = kind[4..kind.len() - 1].splitn(2, ',').collect();
            if types.len() != 2 {
                return Err(AbiError::ExpectedParamType);
            }

            let key_type = parse_param_type(types[0])?;
            let value_type = parse_param_type(types[1])?;

            match key_type {
                ton_abi::ParamType::Int(_)
                | ton_abi::ParamType::Uint(_)
                | ton_abi::ParamType::Address => {
                    ton_abi::ParamType::Map(Box::new(key_type), Box::new(value_type))
                }
                _ => return Err(AbiError::ExpectedParamType),
            }
        }
        "cell" => ton_abi::ParamType::Cell,
        "address" => ton_abi::ParamType::Address,
        "token" | "gram" => ton_abi::ParamType::Token,
        "bytes" => ton_abi::ParamType::Bytes,
        s if s.starts_with("fixedbytes") => {
            let len = usize::from_str(&s[10..]).map_err(|_| AbiError::ExpectedParamType)?;
            ton_abi::ParamType::FixedBytes(len)
        }
        "time" => ton_abi::ParamType::Time,
        "expire" => ton_abi::ParamType::Expire,
        "pubkey" => ton_abi::ParamType::PublicKey,
        "string" => ton_abi::ParamType::String,
        s if s.starts_with("optional(") && s.ends_with(')') => {
            let inner_type = parse_param_type(&s[9..s.len() - 1])?;
            ton_abi::ParamType::Optional(Box::new(inner_type))
        }
        s if s.starts_with("ref(") && s.ends_with(')') => {
            let inner_type = parse_param_type(&s[4..s.len() - 1])?;
            ton_abi::ParamType::Ref(Box::new(inner_type))
        }
        _ => return Err(AbiError::ExpectedParamType),
    };

    Ok(result)
}

#[derive(thiserror::Error, Debug)]
enum AbiError {
    #[error("Expected param type")]
    ExpectedParamType,
    #[error("Expected string or array")]
    ExpectedStringOrArray,
    #[error("Invalid components")]
    InvalidComponents,
}
