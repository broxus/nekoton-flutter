// use super::models::{
//     AbiError, ExecutionOutput, GenTimings, JsMethodName, LastTransactionId, MethodName, ParamsList,
//     TokensObject,
// };
// use js_sys;
// use nekoton_abi::{
//     self,
//     num_bigint::{BigInt, BigUint},
//     num_traits::Num,
//     read_function_id,
// };
// use nekoton_utils::TrustMe;
// use serde::Deserialize;
// use std::{collections::BTreeMap, str::FromStr};
// use ton_block::{Deserializable, MsgAddressInt, Serializable};
// use wasm_bindgen::{prelude::*, JsCast};

// pub fn parse_gen_timings(data: GenTimings) -> Result<nekoton_abi::GenTimings, JsValue> {
//     #[derive(Clone, Deserialize)]
//     #[serde(rename_all = "camelCase")]
//     struct ParsedGenTimings {
//         gen_lt: String,
//         gen_utime: u32,
//     }

//     let ParsedGenTimings { gen_lt, gen_utime } =
//         JsValue::into_serde::<ParsedGenTimings>(&data).handle_error()?;
//     let gen_lt = u64::from_str(&gen_lt).handle_error()?;
//     match (gen_lt, gen_utime) {
//         (0, _) | (_, 0) => Ok(nekoton_abi::GenTimings::Unknown),
//         (gen_lt, gen_utime) => Ok(nekoton_abi::GenTimings::Known { gen_lt, gen_utime }),
//     }
// }

// pub fn parse_last_transaction_id(
//     data: LastTransactionId,
// ) -> Result<nekoton_abi::LastTransactionId, JsValue> {
//     #[derive(Deserialize)]
//     #[serde(rename_all = "camelCase")]
//     struct ParsedLastTransactionId {
//         is_exact: bool,
//         lt: String,
//         hash: Option<String>,
//     }

//     let ParsedLastTransactionId { is_exact, lt, hash } =
//         JsValue::into_serde::<ParsedLastTransactionId>(&data).handle_error()?;
//     let lt = u64::from_str(&lt).handle_error()?;

//     Ok(match (is_exact, hash) {
//         (true, Some(hash)) => {
//             let hash = ton_types::UInt256::from_str(&hash).handle_error()?;
//             nekoton_abi::LastTransactionId::Exact(nekoton_abi::TransactionId { lt, hash })
//         }
//         (false, None) => nekoton_abi::LastTransactionId::Inexact { latest_lt: lt },
//         _ => return Err(String::new()).handle_error(),
//     })
// }

// pub fn parse_account_stuff(boc: &str) -> Result<ton_block::AccountStuff, JsValue> {
//     ton_block::AccountStuff::construct_from_base64(boc).handle_error()
// }

// pub fn parse_contract_abi(contract_abi: &str) -> Result<ton_abi::Contract, JsValue> {
//     ton_abi::Contract::load(&mut std::io::Cursor::new(contract_abi)).handle_error()
// }

// #[allow(unused_unsafe)]
// pub fn parse_tokens_object(
//     params: &[ton_abi::Param],
//     tokens: TokensObject,
// ) -> Result<Vec<ton_abi::Token>, AbiError> {
//     if params.is_empty() {
//         return Ok(Default::default());
//     }

//     if !tokens.is_object() {
//         return Err(AbiError::ExpectedObject);
//     }

//     let mut result = Vec::with_capacity(params.len());
//     for param in params.iter() {
//         let value = unsafe {
//             js_sys::Reflect::get(&tokens, &JsValue::from_str(&param.name))
//                 .map_err(|_| AbiError::TuplePropertyNotFound)?
//         };
//         result.push(parse_token(param, value)?)
//     }

//     Ok(result)
// }

// pub fn parse_token(param: &ton_abi::Param, value: JsValue) -> Result<ton_abi::Token, AbiError> {
//     let value = parse_token_value(&param.kind, value)?;
//     Ok(ton_abi::Token {
//         name: param.name.clone(),
//         value,
//     })
// }

// #[allow(unused_unsafe)]
// pub fn parse_token_value(
//     param: &ton_abi::ParamType,
//     value: JsValue,
// ) -> Result<ton_abi::TokenValue, AbiError> {
//     let value = match param {
//         &ton_abi::ParamType::Uint(size) => {
//             let number = if let Some(value) = value.as_string() {
//                 if let Some(value) = value.strip_prefix("0x") {
//                     BigUint::from_str_radix(value, 16)
//                 } else {
//                     BigUint::from_str(&value)
//                 }
//                 .map_err(|_| AbiError::InvalidNumber)
//             } else if let Some(value) = value.as_f64() {
//                 if value as u64 as f64 != value {
//                     return Err(AbiError::ExpectedIntegerNumber);
//                 }

//                 if value >= 0.0 {
//                     Ok(BigUint::from(value as u64))
//                 } else {
//                     Err(AbiError::ExpectedUnsignedNumber)
//                 }
//             } else {
//                 Err(AbiError::ExpectedStringOrNumber)
//             }?;

//             ton_abi::TokenValue::Uint(ton_abi::Uint { number, size })
//         }
//         &ton_abi::ParamType::Int(size) => {
//             let number = if let Some(value) = value.as_string() {
//                 if let Some(value) = value.strip_prefix("0x") {
//                     BigInt::from_str_radix(value, 16)
//                 } else {
//                     BigInt::from_str(&value)
//                 }
//                 .map_err(|_| AbiError::InvalidNumber)
//             } else if let Some(value) = value.as_f64() {
//                 if value as i64 as f64 != value {
//                     return Err(AbiError::ExpectedIntegerNumber);
//                 }

//                 Ok(BigInt::from(value as i64))
//             } else {
//                 Err(AbiError::ExpectedStringOrNumber)
//             }?;

//             ton_abi::TokenValue::Int(ton_abi::Int { number, size })
//         }
//         ton_abi::ParamType::Bool => value
//             .as_bool()
//             .map(ton_abi::TokenValue::Bool)
//             .ok_or(AbiError::ExpectedBoolean)?,
//         ton_abi::ParamType::Tuple(params) => {
//             if !value.is_object() {
//                 return Err(AbiError::ExpectedObject);
//             }

//             let mut result = Vec::with_capacity(params.len());
//             for param in params.iter() {
//                 let value = unsafe {
//                     js_sys::Reflect::get(&value, &JsValue::from_str(&param.name))
//                         .map_err(|_| AbiError::TuplePropertyNotFound)?
//                 };
//                 result.push(parse_token(param, value)?)
//             }

//             ton_abi::TokenValue::Tuple(result)
//         }
//         ton_abi::ParamType::Array(param) => {
//             if !js_sys::Array::is_array(&value) {
//                 return Err(AbiError::ExpectedArray);
//             }
//             let value: js_sys::Array = value.unchecked_into();

//             ton_abi::TokenValue::Array(
//                 value
//                     .iter()
//                     .map(|value| parse_token_value(param.as_ref(), value))
//                     .collect::<Result<_, AbiError>>()?,
//             )
//         }
//         ton_abi::ParamType::FixedArray(param, size) => {
//             if !js_sys::Array::is_array(&value) {
//                 return Err(AbiError::ExpectedArray);
//             }
//             let value: js_sys::Array = value.unchecked_into();

//             if value.length() != *size as u32 {
//                 return Err(AbiError::InvalidArrayLength);
//             }

//             ton_abi::TokenValue::FixedArray(
//                 value
//                     .iter()
//                     .map(|value| parse_token_value(param.as_ref(), value))
//                     .collect::<Result<_, AbiError>>()?,
//             )
//         }
//         ton_abi::ParamType::Cell => {
//             let value = if let Some(value) = value.as_string() {
//                 if value.is_empty() {
//                     Ok(ton_types::Cell::default())
//                 } else {
//                     base64::decode(&value)
//                         .map_err(|_| AbiError::InvalidCell)
//                         .and_then(|value| {
//                             ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(&value))
//                                 .map_err(|_| AbiError::InvalidCell)
//                         })
//                 }
//             } else if value.is_null() {
//                 Ok(ton_types::Cell::default())
//             } else {
//                 Err(AbiError::ExpectedString)
//             }?;

//             ton_abi::TokenValue::Cell(value)
//         }
//         ton_abi::ParamType::Map(param_key, param_value) => {
//             if !js_sys::Array::is_array(&value) {
//                 return Err(AbiError::ExpectedArray);
//             }
//             let value: js_sys::Array = value.unchecked_into();

//             let mut result = BTreeMap::new();

//             for value in value.iter() {
//                 if !js_sys::Array::is_array(&value) {
//                     return Err(AbiError::ExpectedMapItem);
//                 }
//                 let value: js_sys::Array = value.unchecked_into();
//                 if value.length() != 2 {
//                     return Err(AbiError::ExpectedMapItem);
//                 }

//                 let key = parse_token_value(param_key.as_ref(), value.get(0))?;
//                 let value = parse_token_value(param_value.as_ref(), value.get(1))?;

//                 result.insert(
//                     serde_json::to_string(&key).map_err(|_| AbiError::InvalidMappingKey)?,
//                     value,
//                 );
//             }

//             ton_abi::TokenValue::Map(*param_key.clone(), result)
//         }
//         ton_abi::ParamType::Address => {
//             let value = if let Some(value) = value.as_string() {
//                 MsgAddressInt::from_str(&value).map_err(|_| AbiError::InvalidAddress)
//             } else {
//                 Err(AbiError::ExpectedString)
//             }?;

//             ton_abi::TokenValue::Address(match value {
//                 MsgAddressInt::AddrStd(value) => ton_block::MsgAddress::AddrStd(value),
//                 MsgAddressInt::AddrVar(value) => ton_block::MsgAddress::AddrVar(value),
//             })
//         }
//         ton_abi::ParamType::Bytes => {
//             let value = if let Some(value) = value.as_string() {
//                 if value.is_empty() {
//                     Ok(Vec::new())
//                 } else {
//                     base64::decode(&value).map_err(|_| AbiError::InvalidBytes)
//                 }
//             } else {
//                 Err(AbiError::ExpectedString)
//             }?;

//             ton_abi::TokenValue::Bytes(value)
//         }
//         &ton_abi::ParamType::FixedBytes(size) => {
//             let value = if let Some(value) = value.as_string() {
//                 base64::decode(&value).map_err(|_| AbiError::InvalidBytes)
//             } else {
//                 Err(AbiError::ExpectedString)
//             }?;

//             if value.len() != size {
//                 return Err(AbiError::InvalidBytesLength);
//             }

//             ton_abi::TokenValue::FixedBytes(value)
//         }
//         ton_abi::ParamType::Gram => {
//             let value = if let Some(value) = value.as_string() {
//                 if let Some(value) = value.strip_prefix("0x") {
//                     u128::from_str_radix(value, 16)
//                 } else {
//                     u128::from_str(&value)
//                 }
//                 .map_err(|_| AbiError::InvalidNumber)
//             } else if let Some(value) = value.as_f64() {
//                 if value >= 0.0 {
//                     Ok(value as u128)
//                 } else {
//                     Err(AbiError::InvalidNumber)
//                 }
//             } else {
//                 Err(AbiError::ExpectedStringOrNumber)
//             }?;

//             ton_abi::TokenValue::Gram(ton_block::Grams(value))
//         }
//         ton_abi::ParamType::Time => {
//             let value = if let Some(value) = value.as_string() {
//                 if let Some(value) = value.strip_prefix("0x") {
//                     u64::from_str_radix(value, 16)
//                 } else {
//                     u64::from_str(&value)
//                 }
//                 .map_err(|_| AbiError::InvalidNumber)
//             } else if let Some(value) = value.as_f64() {
//                 if value >= 0.0 {
//                     Ok(value as u64)
//                 } else {
//                     Err(AbiError::ExpectedUnsignedNumber)
//                 }
//             } else {
//                 Err(AbiError::ExpectedStringOrNumber)
//             }?;

//             ton_abi::TokenValue::Time(value)
//         }
//         ton_abi::ParamType::Expire => {
//             let value = if let Some(value) = value.as_f64() {
//                 if value >= 0.0 {
//                     Ok(value as u32)
//                 } else {
//                     Err(AbiError::ExpectedUnsignedNumber)
//                 }
//             } else if let Some(value) = value.as_string() {
//                 if let Some(value) = value.strip_prefix("0x") {
//                     u32::from_str_radix(value, 16)
//                 } else {
//                     u32::from_str(&value)
//                 }
//                 .map_err(|_| AbiError::InvalidNumber)
//             } else {
//                 Err(AbiError::ExpectedStringOrNumber)
//             }?;

//             ton_abi::TokenValue::Expire(value)
//         }
//         ton_abi::ParamType::PublicKey => {
//             let value = if let Some(value) = value.as_string() {
//                 if value.is_empty() {
//                     Ok(None)
//                 } else {
//                     hex::decode(value.strip_prefix("0x").unwrap_or(&value))
//                         .map_err(|_| AbiError::InvalidPublicKey)
//                         .and_then(|value| {
//                             ed25519_dalek::PublicKey::from_bytes(&value)
//                                 .map_err(|_| AbiError::InvalidPublicKey)
//                         })
//                         .map(Some)
//                 }
//             } else {
//                 Err(AbiError::ExpectedString)
//             }?;

//             ton_abi::TokenValue::PublicKey(value)
//         }
//         _ => return Err(AbiError::UnexpectedToken),
//     };

//     Ok(value)
// }

// #[allow(unused_unsafe)]
// pub fn make_token_value(value: &ton_abi::TokenValue) -> Result<JsValue, JsValue> {
//     Ok(match value {
//         ton_abi::TokenValue::Uint(value) => JsValue::from(value.number.to_string()),
//         ton_abi::TokenValue::Int(value) => JsValue::from(value.number.to_string()),
//         ton_abi::TokenValue::Bool(value) => JsValue::from(*value),
//         ton_abi::TokenValue::Tuple(values) => {
//             let tuple = js_sys::Object::new();
//             for token in values.iter() {
//                 unsafe {
//                     js_sys::Reflect::set(
//                         &tuple,
//                         &JsValue::from_str(&token.name),
//                         &make_token_value(&token.value)?,
//                     )
//                     .trust_me();
//                 }
//             }
//             tuple.unchecked_into()
//         }
//         ton_abi::TokenValue::Array(values) | ton_abi::TokenValue::FixedArray(values) => values
//             .iter()
//             .map(make_token_value)
//             .collect::<Result<js_sys::Array, _>>()
//             .map(JsCast::unchecked_into)?,
//         ton_abi::TokenValue::Cell(value) => {
//             let data = ton_types::serialize_toc(value).handle_error()?;
//             JsValue::from(base64::encode(&data))
//         }
//         ton_abi::TokenValue::Map(_, values) => values
//             .iter()
//             .map(|(key, value)| {
//                 Result::<JsValue, JsValue>::Ok(
//                     [JsValue::from_str(key.as_str()), make_token_value(&value)?]
//                         .iter()
//                         .collect::<js_sys::Array>()
//                         .unchecked_into(),
//                 )
//             })
//             .collect::<Result<js_sys::Array, _>>()?
//             .unchecked_into(),
//         ton_abi::TokenValue::Address(value) => JsValue::from(value.to_string()),
//         ton_abi::TokenValue::Bytes(value) | ton_abi::TokenValue::FixedBytes(value) => {
//             JsValue::from(base64::encode(value))
//         }
//         ton_abi::TokenValue::Gram(value) => JsValue::from(value.0.to_string()),
//         ton_abi::TokenValue::Time(value) => JsValue::from(value.to_string()),
//         ton_abi::TokenValue::Expire(value) => JsValue::from(*value),
//         ton_abi::TokenValue::PublicKey(value) => {
//             JsValue::from(value.map(|value| hex::encode(value.as_bytes())))
//         }
//     })
// }

// #[allow(unused_unsafe)]
// pub fn make_tokens_object(tokens: &[ton_abi::Token]) -> Result<TokensObject, JsValue> {
//     let object = js_sys::Object::new();
//     for token in tokens.iter() {
//         unsafe {
//             js_sys::Reflect::set(
//                 &object,
//                 &JsValue::from_str(&token.name),
//                 &make_token_value(&token.value)?,
//             )
//             .trust_me();
//         }
//     }
//     Ok(object.unchecked_into())
// }

// pub fn make_execution_output(
//     data: &nekoton_abi::ExecutionOutput,
// ) -> Result<ExecutionOutput, JsValue> {
//     Ok(ObjectBuilder::new()
//         .set(
//             "output",
//             data.tokens.as_deref().map(make_tokens_object).transpose()?,
//         )
//         .set("code", data.result_code)
//         .build()
//         .unchecked_into())
// }

// pub fn parse_public_key(public_key: &str) -> Result<ed25519_dalek::PublicKey, JsValue> {
//     ed25519_dalek::PublicKey::from_bytes(&hex::decode(&public_key).handle_error()?).handle_error()
// }

// #[allow(unused_unsafe)]
// pub fn insert_init_data(
//     contract_abi: &ton_abi::Contract,
//     data: ton_types::SliceData,
//     public_key: &Option<ed25519_dalek::PublicKey>,
//     tokens: TokensObject,
// ) -> Result<ton_types::SliceData, JsValue> {
//     let mut map = ton_types::HashmapE::with_hashmap(
//         ton_abi::Contract::DATA_MAP_KEYLEN,
//         data.reference_opt(0),
//     );

//     if let Some(public_key) = public_key {
//         map.set_builder(
//             0u64.write_to_new_cell().trust_me().into(),
//             &ton_types::BuilderData::new()
//                 .append_raw(public_key.as_bytes(), 256)
//                 .trust_me(),
//         )
//         .handle_error()?;
//     }

//     if !contract_abi.data().is_empty() {
//         if !tokens.is_object() {
//             return Err(AbiError::ExpectedObject).handle_error();
//         }

//         for (param_name, param) in contract_abi.data() {
//             let value = unsafe {
//                 js_sys::Reflect::get(&tokens, &JsValue::from_str(param_name.as_str()))
//                     .map_err(|_| AbiError::TuplePropertyNotFound)
//                     .handle_error()?
//             };

//             let builder = parse_token_value(&param.value.kind, value)
//                 .handle_error()?
//                 .pack_into_chain(2)
//                 .handle_error()?;

//             map.set_builder(param.key.write_to_new_cell().trust_me().into(), &builder)
//                 .handle_error()?;
//         }
//     }

//     map.write_to_new_cell().map(From::from).handle_error()
// }

// pub fn parse_params_list(params: ParamsList) -> Result<Vec<ton_abi::Param>, AbiError> {
//     if !js_sys::Array::is_array(&params) {
//         return Err(AbiError::ExpectedObject);
//     }
//     let params: js_sys::Array = params.unchecked_into();
//     params.iter().map(parse_param).collect()
// }

// #[allow(unused_unsafe)]
// pub fn parse_param(param: JsValue) -> Result<ton_abi::Param, AbiError> {
//     if !param.is_object() {
//         return Err(AbiError::ExpectedObject);
//     }

//     let name = unsafe {
//         match js_sys::Reflect::get(&param, &JsValue::from_str("name"))
//             .ok()
//             .and_then(|value| value.as_string())
//         {
//             Some(name) => name,
//             _ => return Err(AbiError::ExpectedString),
//         }
//     };

//     let mut kind: ton_abi::ParamType = unsafe {
//         match js_sys::Reflect::get(&param, &JsValue::from_str("type"))
//             .ok()
//             .and_then(|value| value.as_string())
//         {
//             Some(kind) => parse_param_type(&kind)?,
//             _ => return Err(AbiError::ExpectedString),
//         }
//     };

//     let components: Vec<ton_abi::Param> = unsafe {
//         match js_sys::Reflect::get(&param, &JsValue::from_str("components")) {
//             Ok(components) => {
//                 if js_sys::Array::is_array(&components) {
//                     let components: js_sys::Array = components.unchecked_into();
//                     components
//                         .iter()
//                         .map(parse_param)
//                         .collect::<Result<_, AbiError>>()?
//                 } else if components.is_undefined() {
//                     Vec::new()
//                 } else {
//                     return Err(AbiError::ExpectedObject);
//                 }
//             }
//             _ => return Err(AbiError::ExpectedObject),
//         }
//     };

//     kind.set_components(components)
//         .map_err(|_| AbiError::InvalidComponents)?;

//     Ok(ton_abi::Param { name, kind })
// }

// pub fn parse_param_type(kind: &str) -> Result<ton_abi::ParamType, AbiError> {
//     if let Some(']') = kind.chars().last() {
//         let num: String = kind
//             .chars()
//             .rev()
//             .skip(1)
//             .take_while(|c| *c != '[')
//             .collect::<String>()
//             .chars()
//             .rev()
//             .collect();

//         let count = kind.len();
//         return if num.is_empty() {
//             let subtype = parse_param_type(&kind[..count - 2])?;
//             Ok(ton_abi::ParamType::Array(Box::new(subtype)))
//         } else {
//             let len = num
//                 .parse::<usize>()
//                 .map_err(|_| AbiError::ExpectedParamType)?;

//             let subtype = parse_param_type(&kind[..count - num.len() - 2])?;
//             Ok(ton_abi::ParamType::FixedArray(Box::new(subtype), len))
//         };
//     }

//     let result = match kind {
//         "bool" => ton_abi::ParamType::Bool,
//         "tuple" => ton_abi::ParamType::Tuple(Vec::new()),
//         s if s.starts_with("int") => {
//             let len = (&s[3..])
//                 .parse::<usize>()
//                 .map_err(|_| AbiError::ExpectedParamType)?;
//             ton_abi::ParamType::Int(len)
//         }
//         s if s.starts_with("uint") => {
//             let len = (&s[4..])
//                 .parse::<usize>()
//                 .map_err(|_| AbiError::ExpectedParamType)?;
//             ton_abi::ParamType::Uint(len)
//         }
//         s if s.starts_with("map(") && s.ends_with(')') => {
//             let types: Vec<&str> = kind[4..kind.len() - 1].splitn(2, ',').collect();
//             if types.len() != 2 {
//                 return Err(AbiError::ExpectedParamType);
//             }

//             let key_type = parse_param_type(types[0])?;
//             let value_type = parse_param_type(types[1])?;

//             match key_type {
//                 ton_abi::ParamType::Int(_)
//                 | ton_abi::ParamType::Uint(_)
//                 | ton_abi::ParamType::Address => {
//                     ton_abi::ParamType::Map(Box::new(key_type), Box::new(value_type))
//                 }
//                 _ => return Err(AbiError::ExpectedParamType),
//             }
//         }
//         "cell" => ton_abi::ParamType::Cell,
//         "address" => ton_abi::ParamType::Address,
//         "gram" => ton_abi::ParamType::Gram,
//         "bytes" => ton_abi::ParamType::Bytes,
//         s if s.starts_with("fixedbytes") => {
//             let len = (&s[10..])
//                 .parse::<usize>()
//                 .map_err(|_| AbiError::ExpectedParamType)?;
//             ton_abi::ParamType::FixedBytes(len)
//         }
//         "time" => ton_abi::ParamType::Time,
//         "expire" => ton_abi::ParamType::Expire,
//         "pubkey" => ton_abi::ParamType::PublicKey,
//         _ => return Err(AbiError::ExpectedParamType),
//     };

//     Ok(result)
// }

// pub fn parse_slice(boc: &str) -> Result<ton_types::SliceData, JsValue> {
//     let body = base64::decode(boc).handle_error()?;
//     let cell =
//         ton_types::deserialize_tree_of_cells(&mut std::io::Cursor::new(&body)).handle_error()?;
//     Ok(cell.into())
// }

// pub fn make_transfer_recipient(
//     data: nekoton::core::models::TransferRecipient,
// ) -> super::models::TransferRecipient {
//     let (ty, address) = match data {
//         nekoton::core::models::TransferRecipient::OwnerWallet(address) => ("owner_wallet", address),
//         nekoton::core::models::TransferRecipient::TokenWallet(address) => ("token_wallet", address),
//     };

//     ObjectBuilder::new()
//         .set("type", ty)
//         .set("address", address.to_string())
//         .build()
//         .unchecked_into()
// }

// pub fn make_known_payload(
//     data: Option<nekoton::core::models::KnownPayload>,
// ) -> Option<super::models::KnownPayload> {
//     let (ty, data) = match data? {
//         nekoton::core::models::KnownPayload::Comment(comment) => {
//             ("comment", JsValue::from(comment))
//         }
//         nekoton::core::models::KnownPayload::TokenOutgoingTransfer(transfer) => (
//             "token_outgoing_transfer",
//             ObjectBuilder::new()
//                 .set("to", make_transfer_recipient(transfer.to))
//                 .set("tokens", transfer.tokens.to_string())
//                 .build(),
//         ),
//         nekoton::core::models::KnownPayload::TokenSwapBack(swap_back) => (
//             "token_swap_back",
//             ObjectBuilder::new()
//                 .set("tokens", swap_back.tokens.to_string())
//                 .set("to", swap_back.to)
//                 .build(),
//         ),
//         _ => return None,
//     };

//     Some(
//         ObjectBuilder::new()
//             .set("type", ty)
//             .set("data", data)
//             .build()
//             .unchecked_into(),
//     )
// }

// pub fn guess_method_by_input<'a>(
//     contract_abi: &'a ton_abi::Contract,
//     message_body: &ton_types::SliceData,
//     method: JsMethodName,
//     internal: bool,
// ) -> Result<Option<&'a ton_abi::Function>, JsValue> {
//     match parse_method_name(method)? {
//         MethodName::Known(name) => Ok(Some(contract_abi.function(&name).handle_error()?)),
//         MethodName::Guess(names) => {
//             let input_id =
//                 match read_input_function_id(contract_abi, message_body.clone(), internal) {
//                     Ok(id) => id,
//                     Err(_) => return Ok(None),
//                 };

//             let mut method = None;
//             for name in names.iter() {
//                 let function = contract_abi.function(name).handle_error()?;
//                 if function.input_id == input_id {
//                     method = Some(function);
//                     break;
//                 }
//             }
//             Ok(method)
//         }
//     }
// }

// pub fn read_input_function_id(
//     contract_abi: &ton_abi::Contract,
//     mut body: ton_types::SliceData,
//     internal: bool,
// ) -> Result<u32, JsValue> {
//     if internal {
//         read_function_id(&body).handle_error()
//     } else {
//         if body.get_next_bit().handle_error()? {
//             body.move_by(ed25519_dalek::SIGNATURE_LENGTH * 8)
//                 .handle_error()?
//         }
//         for header in contract_abi.header() {
//             match header.kind {
//                 ton_abi::ParamType::PublicKey => {
//                     if body.get_next_bit().handle_error()? {
//                         body.move_by(ed25519_dalek::PUBLIC_KEY_LENGTH * 8)
//                             .handle_error()?;
//                     }
//                 }
//                 ton_abi::ParamType::Time => body.move_by(64).handle_error()?,
//                 ton_abi::ParamType::Expire => body.move_by(32).handle_error()?,
//                 _ => return Err(AbiError::UnsupportedHeader).handle_error(),
//             }
//         }
//         read_function_id(&body).handle_error()
//     }
// }

// pub fn parse_method_name(value: JsMethodName) -> Result<MethodName, JsValue> {
//     let value: JsValue = value.unchecked_into();
//     if let Some(value) = value.as_string() {
//         Ok(MethodName::Known(value))
//     } else if js_sys::Array::is_array(&value) {
//         let value: js_sys::Array = value.unchecked_into();
//         Ok(MethodName::Guess(
//             value
//                 .iter()
//                 .map(|value| match value.as_string() {
//                     Some(value) => Ok(value),
//                     None => Err(AbiError::ExpectedStringOrArray),
//                 })
//                 .collect::<Result<Vec<_>, AbiError>>()
//                 .handle_error()?,
//         ))
//     } else {
//         Err(AbiError::ExpectedStringOrArray).handle_error()
//     }
// }

// pub fn parse_address(address: &str) -> Result<MsgAddressInt, JsValue> {
//     MsgAddressInt::from_str(address).handle_error()
// }

// impl<T, E> HandleError for Result<T, E>
// where
//     E: ToString,
// {
//     type Output = T;

//     fn handle_error(self) -> Result<Self::Output, JsValue> {
//         self.map_err(|e| {
//             let error = e.to_string();
//             js_sys::Error::new(&error).unchecked_into()
//         })
//     }
// }

// pub trait HandleError {
//     type Output;

//     fn handle_error(self) -> Result<Self::Output, JsValue>;
// }

// pub struct ObjectBuilder {
//     object: js_sys::Object,
// }

// #[allow(unused_unsafe)]
// impl ObjectBuilder {
//     pub fn new() -> Self {
//         Self {
//             object: js_sys::Object::new(),
//         }
//     }

//     pub fn set<T>(self, key: &str, value: T) -> Self
//     where
//         JsValue: From<T>,
//     {
//         let key = JsValue::from_str(key);
//         let value = JsValue::from(value);
//         unsafe { js_sys::Reflect::set(&self.object, &key, &value).trust_me() };
//         self
//     }

//     pub fn build(self) -> JsValue {
//         JsValue::from(self.object)
//     }
// }

// impl Default for ObjectBuilder {
//     fn default() -> Self {
//         Self::new()
//     }
// }
