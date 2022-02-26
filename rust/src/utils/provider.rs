use crate::{
    core::ton_wallet::models::KnownPayload,
    models::{HandleError, MatchResult},
    parse_address, parse_public_key,
    utils::models::{
        DecodedEvent, DecodedInput, DecodedOutput, DecodedTransaction, DecodedTransactionEvent,
        ExecutionOutput, SplittedTvc,
    },
    FromPtr, ToPtr,
};
use nekoton::core::{
    models::{Expiration, Transaction},
    parsing::parse_payload,
    utils::make_labs_unsigned_message,
};
use nekoton_abi::{get_state_init_hash, guess_method_by_input, FunctionExt, MethodName};
use nekoton_utils::SimpleClock;
use std::{
    borrow::Cow,
    ffi::c_void,
    os::raw::{c_char, c_schar, c_uint, c_ulonglong},
    sync::Arc,
    u64,
};
use ton_block::{Deserializable, MsgAddressInt, Serializable};

#[no_mangle]
pub unsafe extern "C" fn run_local(
    account_stuff_boc: *mut c_char,
    contract_abi: *mut c_char,
    method: *mut c_char,
    input: *mut c_char,
) -> *mut c_void {
    let account_stuff_boc = account_stuff_boc.from_ptr();
    let contract_abi = contract_abi.from_ptr();
    let method = method.from_ptr();
    let input = input.from_ptr();

    fn internal_fn(
        account_stuff_boc: String,
        contract_abi: String,
        method: String,
        input: String,
    ) -> Result<u64, String> {
        let account_stuff = parse_account_stuff(&account_stuff_boc)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = contract_abi.function(&method).handle_error()?;
        let input = parse_abi_tokens_value(&input)?;
        let input = nekoton_abi::parse_abi_tokens(&method.inputs, input).handle_error()?;

        let clock = SimpleClock {};

        let output = method
            .run_local(&clock, account_stuff, &input)
            .handle_error()?;

        let tokens = output
            .tokens
            .map(|e| nekoton_abi::make_abi_tokens(&e).handle_error())
            .transpose()?;

        let execution_output = ExecutionOutput {
            output: tokens,
            code: output.result_code,
        };
        let execution_output = serde_json::to_string(&execution_output)
            .handle_error()?
            .to_ptr() as c_ulonglong;

        Ok(execution_output)
    }

    internal_fn(account_stuff_boc, contract_abi, method, input).match_result()
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

    fn internal_fn(
        tvc: String,
        contract_abi: String,
        workchain_id: i8,
        public_key: Option<String>,
        init_data: String,
    ) -> Result<u64, String> {
        let state_init = ton_block::StateInit::construct_from_base64(&tvc).handle_error()?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let public_key = public_key.as_deref().map(parse_public_key).transpose()?;

        let params = contract_abi
            .data()
            .iter()
            .map(|(_, v)| v.value.clone())
            .collect::<Vec<_>>();

        let init_data = parse_abi_tokens_value(&init_data)?;
        let init_data = nekoton_abi::parse_abi_tokens(&params, init_data).handle_error()?;

        let hash = get_state_init_hash(state_init, &contract_abi, &public_key, init_data)
            .handle_error()?;

        let result = MsgAddressInt::AddrStd(ton_block::MsgAddrStd {
            anycast: None,
            workchain_id,
            address: hash.into(),
        })
        .to_string()
        .to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(tvc, contract_abi, workchain_id, public_key, init_data).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn pack_into_cell(params: *mut c_char, tokens: *mut c_char) -> *mut c_void {
    let params = params.from_ptr();
    let tokens = tokens.from_ptr();

    fn internal_fn(params: String, tokens: String) -> Result<u64, String> {
        let params = parse_params_list(&params)?;
        let tokens = parse_abi_tokens_value(&tokens)?;
        let tokens = nekoton_abi::parse_abi_tokens(&params, tokens).handle_error()?;

        let cell = nekoton_abi::pack_into_cell(&tokens).handle_error()?;
        let bytes = ton_types::serialize_toc(&cell).handle_error()?;

        let result = base64::encode(&bytes).to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(params, tokens).match_result()
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

    fn internal_fn(params: String, boc: String, allow_partial: bool) -> Result<u64, String> {
        let params = parse_params_list(&params)?;
        let body = base64::decode(boc).handle_error()?;
        let cell = ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(&body))
            .handle_error()?;
        let result = nekoton_abi::unpack_from_cell(&params, cell.into(), allow_partial)
            .handle_error()
            .and_then(|tokens| nekoton_abi::make_abi_tokens(&tokens).handle_error())?;

        let result = serde_json::to_string(&result).handle_error()?.to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(params, boc, allow_partial).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn extract_public_key(boc: *mut c_char) -> *mut c_void {
    let boc = boc.from_ptr();

    fn internal_fn(boc: String) -> Result<u64, String> {
        let public_key = parse_account_stuff(&boc)
            .and_then(|x| nekoton_abi::extract_public_key(&x).handle_error())
            .map(hex::encode)?
            .to_ptr() as c_ulonglong;

        Ok(public_key)
    }

    internal_fn(boc).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn code_to_tvc(code: *mut c_char) -> *mut c_void {
    let code = code.from_ptr();

    fn internal_fn(code: String) -> Result<u64, String> {
        let cell = base64::decode(code).handle_error()?;
        let result = ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(cell))
            .handle_error()
            .and_then(|x| nekoton_abi::code_to_tvc(x).handle_error())
            .and_then(|x| x.serialize().handle_error())
            .and_then(|x| ton_types::serialize_toc(&x).handle_error())
            .map(base64::encode)?
            .to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(code).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn split_tvc(tvc: *mut c_char) -> *mut c_void {
    let tvc = tvc.from_ptr();

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

        let result = SplittedTvc { data, code };
        let result = serde_json::to_string(&result).handle_error()?.to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(tvc).match_result()
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

    fn internal_fn(contract_abi: String, method: String, input: String) -> Result<u64, String> {
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = contract_abi.function(&method).handle_error()?;
        let input = parse_abi_tokens_value(&input)?;
        let input = nekoton_abi::parse_abi_tokens(&method.inputs, input).handle_error()?;

        let body = method
            .encode_input(&Default::default(), &input, true, None)
            .and_then(|value| value.into_cell())
            .handle_error()?;
        let body = ton_types::serialize_toc(&body).handle_error()?;
        let result = base64::encode(&body).to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(contract_abi, method, input).match_result()
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

    fn internal_fn(
        message_body: String,
        contract_abi: String,
        method: String,
        internal: bool,
    ) -> Result<u64, String> {
        let message_body = parse_slice(&message_body)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = parse_method_name(&method)?;

        let result = nekoton_abi::decode_input(&contract_abi, message_body, &method, internal)
            .handle_error()?;
        let result = match result {
            Some((method, input)) => {
                let input = nekoton_abi::make_abi_tokens(&input).handle_error()?;
                let result = DecodedInput {
                    method: method.name.clone(),
                    input,
                };
                serde_json::to_string(&result).handle_error()?
            }
            None => get_null_string()?,
        }
        .to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(message_body, contract_abi, method, internal).match_result()
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

    fn internal_fn(
        message_body: String,
        contract_abi: String,
        method: String,
    ) -> Result<u64, String> {
        let message_body = parse_slice(&message_body)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = parse_method_name(&method)?;

        let result =
            nekoton_abi::decode_output(&contract_abi, message_body, &method).handle_error()?;
        let result = match result {
            Some((method, output)) => {
                let output = nekoton_abi::make_abi_tokens(&output).handle_error()?;
                let result = DecodedOutput {
                    method: method.name.clone(),
                    output,
                };
                serde_json::to_string(&result).handle_error()?
            }
            None => get_null_string()?,
        }
        .to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(message_body, contract_abi, method).match_result()
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

    fn internal_fn(
        message_body: String,
        contract_abi: String,
        event: String,
    ) -> Result<u64, String> {
        let message_body = parse_slice(&message_body)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let event = parse_method_name(&event)?;

        let result =
            nekoton_abi::decode_event(&contract_abi, message_body, &event).handle_error()?;
        let result = match result {
            Some((event, data)) => {
                let data = nekoton_abi::make_abi_tokens(&data).handle_error()?;
                let result = DecodedEvent {
                    event: event.name.clone(),
                    data,
                };
                serde_json::to_string(&result).handle_error()?
            }
            None => get_null_string()?,
        }
        .to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(message_body, contract_abi, event).match_result()
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

    fn internal_fn(
        transaction: String,
        contract_abi: String,
        method: String,
    ) -> Result<u64, String> {
        let transaction = parse_transaction(&transaction)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = parse_method_name(&method)?;

        let internal = transaction.in_msg.src.is_some();

        let in_msg_body = match transaction.in_msg.body {
            Some(body) => body.data.into(),
            None => return Ok(get_null_string()?.to_ptr() as c_ulonglong),
        };

        let method = match guess_method_by_input(&contract_abi, &in_msg_body, &method, internal)
            .handle_error()?
        {
            Some(method) => method,
            None => return Ok(get_null_string()?.to_ptr() as c_ulonglong),
        };

        let input = method.decode_input(in_msg_body, internal).handle_error()?;

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
                    None => Err("Expected message body").handle_error(),
                })
            })
            .collect::<Result<Vec<_>, String>>()?;

        let output = nekoton_abi::process_raw_outputs(&ext_out_msgs, method).handle_error()?;

        let input = nekoton_abi::make_abi_tokens(&input).handle_error()?;
        let output = nekoton_abi::make_abi_tokens(&output).handle_error()?;

        let result = DecodedTransaction {
            method: method.name.clone(),
            input,
            output,
        };
        let result = serde_json::to_string(&result).handle_error()?.to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(transaction, contract_abi, method).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn decode_transaction_events(
    transaction: *mut c_char,
    contract_abi: *mut c_char,
) -> *mut c_void {
    let transaction = transaction.from_ptr();
    let contract_abi = contract_abi.from_ptr();

    fn internal_fn(transaction: String, contract_abi: String) -> Result<u64, String> {
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
                    None => Err("Expected message body").handle_error(),
                })
            })
            .collect::<Result<Vec<_>, String>>()?;

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
                    Err(err) => Err(err).handle_error(),
                })
            })
            .collect::<Result<Vec<_>, String>>()?;

        let result = serde_json::to_string(&events).handle_error()?.to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(transaction, contract_abi).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn parse_known_payload(payload: *mut c_char) -> *mut c_void {
    let payload = payload.from_ptr();

    fn internal_fn(payload: String) -> Result<u64, String> {
        let payload = parse_slice(&payload)?;
        let known_payload = parse_payload(payload);
        let result = known_payload.map(|e| KnownPayload::from_core(e));
        let result = serde_json::to_string(&result).handle_error()?.to_ptr() as c_ulonglong;

        Ok(result)
    }

    internal_fn(payload).match_result()
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
    let state_init = match !state_init.is_null() {
        true => Some(state_init.from_ptr()),
        false => None,
    };
    let input = input.from_ptr();
    let public_key = public_key.from_ptr();

    fn internal_fn(
        dst: String,
        contract_abi: String,
        method: String,
        state_init: Option<String>,
        input: String,
        public_key: String,
        timeout: u32,
    ) -> Result<u64, String> {
        let dst = parse_address(&dst)?;
        let contract_abi = parse_contract_abi(&contract_abi)?;
        let method = contract_abi.function(&method).handle_error()?;
        let state_init = state_init
            .as_deref()
            .map(ton_block::StateInit::construct_from_base64)
            .transpose()
            .handle_error()?;
        let input = parse_abi_tokens_value(&input)?;
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

        let clock = SimpleClock {};

        let message = make_labs_unsigned_message(
            &clock,
            message,
            Expiration::Timeout(timeout),
            &public_key,
            Cow::Owned(method.clone()),
            input,
        )
        .handle_error()?;

        let message = Box::new(Arc::new(message));
        let ptr = Box::into_raw(message) as c_ulonglong;

        Ok(ptr)
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

fn parse_account_stuff(boc: &str) -> Result<ton_block::AccountStuff, String> {
    ton_block::AccountStuff::construct_from_base64(boc).handle_error()
}

fn parse_contract_abi(contract_abi: &str) -> Result<ton_abi::Contract, String> {
    ton_abi::Contract::load(&mut std::io::Cursor::new(contract_abi)).handle_error()
}

fn parse_params_list(data: &str) -> Result<Vec<ton_abi::Param>, String> {
    serde_json::from_str::<Vec<ton_abi::Param>>(data).handle_error()
}

fn parse_abi_tokens_value(data: &str) -> Result<serde_json::Value, String> {
    serde_json::from_str::<serde_json::Value>(&data).handle_error()
}

fn parse_slice(boc: &str) -> Result<ton_types::SliceData, String> {
    let body = base64::decode(boc).handle_error()?;
    let cell =
        ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(&body)).handle_error()?;
    Ok(cell.into())
}

fn parse_method_name(value: &str) -> Result<MethodName, String> {
    if let Ok(value) = serde_json::from_str::<String>(&value) {
        Ok(MethodName::Known(value))
    } else if let Ok(value) = serde_json::from_str::<Vec<String>>(&value) {
        Ok(MethodName::GuessInRange(value))
    } else {
        Err(value).handle_error()
    }
}

fn parse_transaction(data: &str) -> Result<Transaction, String> {
    serde_json::from_str::<Transaction>(&data).handle_error()
}

fn get_null_string() -> Result<String, String> {
    serde_json::to_string(&serde_json::Value::Null).handle_error()
}
