// pub mod helpers;
// pub mod models;

// use self::{
//     helpers::{
//         guess_method_by_input, insert_init_data, make_execution_output, make_known_payload,
//         make_tokens_object, parse_account_stuff, parse_address, parse_contract_abi,
//         parse_gen_timings, parse_last_transaction_id, parse_method_name, parse_params_list,
//         parse_public_key, parse_slice, parse_tokens_object, read_input_function_id, HandleError,
//         ObjectBuilder,
//     },
//     models::{
//         AbiError, DecodedEvent, DecodedInput, DecodedOutput, DecodedTransaction,
//         DecodedTransactionEvents, ExecutionOutput, GenTimings, JsMethodName, KnownPayload,
//         LastTransactionId, MethodName, ParamsList, StateInit, TokensObject, Transaction,
//     },
// };
// use nekoton::crypto::UnsignedMessage;
// use nekoton_abi::{read_function_id, FunctionExt};
// use nekoton_utils::{self, TrustMe};
// use std::borrow::Cow;
// use ton_block::{Deserializable, GetRepresentationHash, MsgAddressInt, Serializable};
// use wasm_bindgen::{prelude::*, JsCast};

// pub fn check_address(address: &str) -> bool {
//     nekoton_utils::validate_address(address)
// }

// pub fn run_local(
//     gen_timings: GenTimings,
//     last_transaction_id: LastTransactionId,
//     account_stuff_boc: &str,
//     contract_abi: &str,
//     method: &str,
//     input: TokensObject,
// ) -> Result<ExecutionOutput, JsValue> {
//     let gen_timings = parse_gen_timings(gen_timings)?;
//     let last_transaction_id = parse_last_transaction_id(last_transaction_id)?;
//     let account_stuff = parse_account_stuff(account_stuff_boc)?;
//     let contract_abi = parse_contract_abi(contract_abi)?;
//     let method = contract_abi.function(method).handle_error()?;
//     let input = parse_tokens_object(&method.inputs, input).handle_error()?;

//     let output = method
//         .run_local(account_stuff, gen_timings, &last_transaction_id, &input)
//         .handle_error()?;

//     make_execution_output(&output)
// }

// pub fn get_expected_address(
//     tvc: &str,
//     contract_abi: &str,
//     workchain_id: i8,
//     public_key: Option<String>,
//     init_data: TokensObject,
// ) -> Result<String, JsValue> {
//     let mut state_init = ton_block::StateInit::construct_from_base64(tvc).handle_error()?;
//     let contract_abi = parse_contract_abi(contract_abi)?;
//     let public_key = public_key.as_deref().map(parse_public_key).transpose()?;

//     state_init.data = if let Some(data) = state_init.data.take() {
//         Some(insert_init_data(&contract_abi, data.into(), &public_key, init_data)?.into_cell())
//     } else {
//         None
//     };

//     let hash = state_init.hash().trust_me();

//     Ok(MsgAddressInt::AddrStd(ton_block::MsgAddrStd {
//         anycast: None,
//         workchain_id,
//         address: hash.into(),
//     })
//     .to_string())
// }

// pub fn pack_into_cell(params: ParamsList, tokens: TokensObject) -> Result<String, JsValue> {
//     let params = parse_params_list(params).handle_error()?;
//     let tokens = parse_tokens_object(&params, tokens).handle_error()?;

//     let cell = nekoton_abi::pack_into_cell(&tokens).handle_error()?;
//     let bytes = ton_types::serialize_toc(&cell).handle_error()?;
//     Ok(base64::encode(&bytes))
// }

// pub fn unpack_from_cell(
//     params: ParamsList,
//     boc: &str,
//     allow_partial: bool,
// ) -> Result<TokensObject, JsValue> {
//     let params = parse_params_list(params).handle_error()?;
//     let body = base64::decode(boc).handle_error()?;
//     let cell =
//         ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(&body)).handle_error()?;
//     nekoton_abi::unpack_from_cell(&params, cell.into(), allow_partial)
//         .handle_error()
//         .and_then(|tokens| make_tokens_object(&tokens))
// }

// pub fn extract_public_key(boc: &str) -> Result<String, JsValue> {
//     parse_account_stuff(boc)
//         .and_then(|x| nekoton_abi::extract_public_key(&x).handle_error())
//         .map(hex::encode)
// }

// pub fn split_tvc(tvc: &str) -> Result<StateInit, JsValue> {
//     let state_init = ton_block::StateInit::construct_from_base64(tvc).handle_error()?;

//     let data = match state_init.data {
//         Some(data) => {
//             let data = ton_types::serialize_toc(&data).handle_error()?;
//             Some(base64::encode(data))
//         }
//         None => None,
//     };

//     let code = match state_init.code {
//         Some(code) => {
//             let code = ton_types::serialize_toc(&code).handle_error()?;
//             Some(base64::encode(code))
//         }
//         None => None,
//     };

//     Ok(ObjectBuilder::new()
//         .set("data", data)
//         .set("code", code)
//         .build()
//         .unchecked_into())
// }

// pub fn code_to_tvc(code: &str) -> Result<String, JsValue> {
//     let cell = base64::decode(code).handle_error()?;
//     ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(cell))
//         .handle_error()
//         .and_then(|x| nekoton_abi::code_to_tvc(x).handle_error())
//         .and_then(|x| x.serialize().handle_error())
//         .and_then(|x| ton_types::serialize_toc(&x).handle_error())
//         .map(base64::encode)
// }

// pub fn parse_known_payload(payload: &str) -> Option<KnownPayload> {
//     let payload = parse_slice(payload).ok()?;
//     make_known_payload(nekoton::core::parsing::parse_payload(payload))
// }

// pub fn decode_input(
//     message_body: &str,
//     contract_abi: &str,
//     method: JsMethodName,
//     internal: bool,
// ) -> Result<Option<DecodedInput>, JsValue> {
//     let message_body = parse_slice(message_body)?;
//     let contract_abi = parse_contract_abi(contract_abi)?;
//     let method = match guess_method_by_input(&contract_abi, &message_body, method, internal)? {
//         Some(method) => method,
//         None => return Ok(None),
//     };

//     let input = method.decode_input(message_body, internal).handle_error()?;
//     Ok(Some(
//         ObjectBuilder::new()
//             .set("method", &method.name)
//             .set("input", make_tokens_object(&input)?)
//             .build()
//             .unchecked_into(),
//     ))
// }

// pub fn decode_event(
//     message_body: &str,
//     contract_abi: &str,
//     event: JsMethodName,
// ) -> Result<Option<DecodedEvent>, JsValue> {
//     let message_body = parse_slice(message_body)?;
//     let contract_abi = parse_contract_abi(contract_abi)?;
//     let events = contract_abi.events();
//     let event = match parse_method_name(event)? {
//         MethodName::Known(name) => match events.get(&name) {
//             Some(event) => event,
//             None => return Ok(None),
//         },
//         MethodName::Guess(names) => {
//             let id = match read_input_function_id(&contract_abi, message_body.clone(), true) {
//                 Ok(id) => id,
//                 Err(_) => return Ok(None),
//             };

//             let mut event = None;
//             for name in names.iter() {
//                 let function = match events.get(name) {
//                     Some(function) => function,
//                     None => continue,
//                 };

//                 if function.id == id {
//                     event = Some(function);
//                     break;
//                 }
//             }

//             match event {
//                 Some(event) => event,
//                 None => return Ok(None),
//             }
//         }
//     };

//     let data = event.decode_input(message_body).handle_error()?;
//     Ok(Some(
//         ObjectBuilder::new()
//             .set("event", &event.name)
//             .set("data", make_tokens_object(&data)?)
//             .build()
//             .unchecked_into(),
//     ))
// }

// pub fn decode_output(
//     message_body: &str,
//     contract_abi: &str,
//     method: JsMethodName,
// ) -> Result<Option<DecodedOutput>, JsValue> {
//     let message_body = parse_slice(message_body)?;
//     let contract_abi = parse_contract_abi(contract_abi)?;
//     let method = parse_method_name(method)?;

//     let method = match method {
//         MethodName::Known(name) => contract_abi.function(&name).handle_error()?,
//         MethodName::Guess(names) => {
//             let output_id = nekoton_abi::read_function_id(&message_body).handle_error()?;

//             let mut method = None;
//             for name in names.iter() {
//                 let function = contract_abi.function(name).handle_error()?;
//                 if function.output_id == output_id {
//                     method = Some(function);
//                     break;
//                 }
//             }

//             match method {
//                 Some(method) => method,
//                 None => return Ok(None),
//             }
//         }
//     };

//     let output = method.decode_output(message_body, true).handle_error()?;
//     Ok(Some(
//         ObjectBuilder::new()
//             .set("method", &method.name)
//             .set("output", make_tokens_object(&output)?)
//             .build()
//             .unchecked_into(),
//     ))
// }

// #[allow(unused_unsafe)]
// pub fn decode_transaction_events(
//     transaction: Transaction,
//     contract_abi: &str,
// ) -> Result<DecodedTransactionEvents, JsValue> {
//     let transaction: JsValue = transaction.unchecked_into();
//     if !transaction.is_object() {
//         return Err(AbiError::ExpectedObject).handle_error();
//     }

//     let contract_abi = parse_contract_abi(contract_abi)?;

//     let out_msgs =
//         unsafe { js_sys::Reflect::get(&transaction, &JsValue::from_str("outMessages"))? };
//     if !js_sys::Array::is_array(&out_msgs) {
//         return Err(AbiError::ExpectedArray).handle_error();
//     }

//     let body_key = JsValue::from_str("body");
//     let dst_key = JsValue::from_str("dst");
//     let ext_out_msgs = out_msgs
//         .unchecked_into::<js_sys::Array>()
//         .iter()
//         .filter_map(|message| {
//             unsafe {
//                 match js_sys::Reflect::get(&message, &dst_key) {
//                     Ok(dst) if dst.is_string() => return None,
//                     Err(error) => return Some(Err(error)),
//                     _ => {}
//                 };
//             }

//             Some(unsafe {
//                 match js_sys::Reflect::get(&message, &body_key).map(|item| item.as_string()) {
//                     Ok(Some(body)) => parse_slice(&body),
//                     Ok(None) => return None,
//                     Err(error) => Err(error),
//                 }
//             })
//         })
//         .collect::<Result<Vec<_>, JsValue>>()?;

//     let events = ext_out_msgs
//         .into_iter()
//         .filter_map(|body| {
//             let id = read_function_id(&body).ok()?;
//             let event = contract_abi.event_by_id(id).ok()?;
//             let tokens = event.decode_input(body).ok()?;

//             let data = match make_tokens_object(&tokens) {
//                 Ok(data) => data,
//                 Err(e) => return Some(Err(e)),
//             };

//             Some(Ok(ObjectBuilder::new()
//                 .set("event", &event.name)
//                 .set("data", data)
//                 .build()))
//         })
//         .collect::<Result<js_sys::Array, JsValue>>()?;

//     Ok(events.unchecked_into())
// }

// pub fn encode_internal_input(
//     contract_abi: &str,
//     method: &str,
//     input: TokensObject,
// ) -> Result<String, JsValue> {
//     let contract_abi = parse_contract_abi(contract_abi)?;
//     let method = contract_abi.function(method).handle_error()?;
//     let input = parse_tokens_object(&method.inputs, input).handle_error()?;

//     let body = method
//         .encode_input(&Default::default(), &input, true, None)
//         .and_then(|value| value.into_cell())
//         .handle_error()?;
//     let body = ton_types::serialize_toc(&body).handle_error()?;
//     Ok(base64::encode(&body))
// }

// pub fn repack_address(address: &str) -> Result<String, JsValue> {
//     nekoton_utils::repack_address(address)
//         .map(|x| x.to_string())
//         .handle_error()
// }

// pub fn create_external_message(
//     dst: &str,
//     contract_abi: &str,
//     method: &str,
//     state_init: Option<String>,
//     input: TokensObject,
//     public_key: &str,
//     timeout: u32,
// ) -> Result<Box<dyn UnsignedMessage>, JsValue> {
//     let dst = parse_address(dst)?;
//     let contract_abi = parse_contract_abi(contract_abi)?;
//     let method = contract_abi.function(method).handle_error()?;
//     let state_init = state_init
//         .as_deref()
//         .map(ton_block::StateInit::construct_from_base64)
//         .transpose()
//         .handle_error()?;
//     let input = parse_tokens_object(&method.inputs, input).handle_error()?;
//     let public_key = parse_public_key(public_key)?;

//     let mut message =
//         ton_block::Message::with_ext_in_header(ton_block::ExternalInboundMessageHeader {
//             dst,
//             ..Default::default()
//         });
//     if let Some(state_init) = state_init {
//         message.set_state_init(state_init);
//     }

//     Ok(nekoton::core::utils::make_labs_unsigned_message(
//         message,
//         nekoton::core::models::Expiration::Timeout(timeout),
//         &public_key,
//         Cow::Owned(method.clone()),
//         input,
//     )
//     .handle_error()?)
// }

// #[allow(unused_unsafe)]
// pub fn decode_transaction(
//     transaction: Transaction,
//     contract_abi: &str,
//     method: JsMethodName,
// ) -> Result<Option<DecodedTransaction>, JsValue> {
//     let transaction: JsValue = transaction.unchecked_into();
//     if !transaction.is_object() {
//         return Err(AbiError::ExpectedObject).handle_error();
//     }

//     let contract_abi = parse_contract_abi(contract_abi)?;

//     let in_msg = unsafe { js_sys::Reflect::get(&transaction, &JsValue::from_str("inMessage"))? };
//     if !in_msg.is_object() {
//         return Err(AbiError::ExpectedMessage).handle_error();
//     }
//     let internal = unsafe { js_sys::Reflect::get(&in_msg, &JsValue::from_str("src"))?.is_string() };

//     let body_key = JsValue::from_str("body");
//     let in_msg_body = unsafe {
//         match js_sys::Reflect::get(&in_msg, &body_key)?.as_string() {
//             Some(body) => parse_slice(&body)?,
//             None => return Ok(None),
//         }
//     };

//     let method = match guess_method_by_input(&contract_abi, &in_msg_body, method, internal)? {
//         Some(method) => method,
//         None => return Ok(None),
//     };

//     let input = method.decode_input(in_msg_body, internal).handle_error()?;

//     let out_msgs =
//         unsafe { js_sys::Reflect::get(&transaction, &JsValue::from_str("outMessages"))? };
//     if !js_sys::Array::is_array(&out_msgs) {
//         return Err(AbiError::ExpectedArray).handle_error();
//     }

//     let dst_key = JsValue::from_str("dst");
//     let ext_out_msgs = out_msgs
//         .unchecked_into::<js_sys::Array>()
//         .iter()
//         .filter_map(|message| {
//             unsafe {
//                 match js_sys::Reflect::get(&message, &dst_key) {
//                     Ok(dst) if dst.is_string() => return None,
//                     Err(error) => return Some(Err(error)),
//                     _ => {}
//                 }
//             };

//             Some(unsafe {
//                 match js_sys::Reflect::get(&message, &body_key).map(|item| item.as_string()) {
//                     Ok(Some(body)) => parse_slice(&body),
//                     Ok(None) => Err(AbiError::ExpectedMessageBody).handle_error(),
//                     Err(error) => Err(error),
//                 }
//             })
//         })
//         .collect::<Result<Vec<_>, JsValue>>()?;

//     let output = nekoton_abi::process_raw_outputs(&ext_out_msgs, method).handle_error()?;

//     Ok(Some(
//         ObjectBuilder::new()
//             .set("method", &method.name)
//             .set("input", make_tokens_object(&input)?)
//             .set("output", make_tokens_object(&output)?)
//             .build()
//             .unchecked_into(),
//     ))
// }
