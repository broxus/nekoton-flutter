mod gql_transport;
mod jrpc_transport;
pub(crate) mod models;

use std::{
    convert::TryFrom,
    os::raw::{c_char, c_int, c_longlong, c_uchar, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
use nekoton::{
    core::models::{Transaction, TransactionsBatchInfo, TransactionsBatchType},
    transport::{gql::GqlTransport, jrpc::JrpcTransport, models::RawContractState, Transport},
};
use nekoton_abi::TransactionId;
use num_traits::FromPrimitive;
use ton_block::Serializable;

use crate::{
    models::{
        HandleError, MatchResult, PostWithResult, ToOptionalStringFromPtr, ToPtrAddress,
        ToSerializable, ToStringFromPtr,
    },
    parse_address, parse_hash, runtime,
    transport::models::{AccountsList, FullContractState, TransactionsList, TransportType},
    RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_transport_get_contract_state(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    address: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let contract_state = transport
                .get_contract_state(&address)
                .await
                .handle_error()?
                .to_serializable();

            serde_json::to_value(contract_state).handle_error()
        }

        let result = internal_fn(transport, address).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_transport_get_full_contract_state(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    address: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let raw_contract_state = transport
                .get_contract_state(&address)
                .await
                .handle_error()?;

            let full_contract_state = match raw_contract_state {
                RawContractState::Exists(state) => {
                    let boc = state
                        .account
                        .serialize()
                        .as_ref()
                        .map(ton_types::serialize_toc)
                        .handle_error()?
                        .map(base64::encode)
                        .handle_error()?;

                    let is_deployed = matches!(
                        &state.account.storage.state,
                        ton_block::AccountState::AccountActive { state_init: _ }
                    );

                    Some(FullContractState {
                        balance: state.account.storage.balance.grams.0.to_string(),
                        gen_timings: state.timings,
                        last_transaction_id: Some(state.last_transaction_id),
                        is_deployed,
                        code_hash: None,
                        boc,
                    })
                }
                RawContractState::NotExists => None,
            };

            serde_json::to_value(full_contract_state).handle_error()
        }

        let result = internal_fn(transport, address).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_transport_get_accounts_by_code_hash(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    code_hash: *mut c_char,
    limit: c_uchar,
    continuation: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let code_hash = code_hash.to_string_from_ptr();
    let continuation = continuation.to_optional_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            code_hash: String,
            limit: u8,
            continuation: Option<String>,
        ) -> Result<serde_json::Value, String> {
            let code_hash = parse_hash(&code_hash)?;
            let continuation = continuation.map(|addr| parse_address(&addr)).transpose()?;

            let accounts = transport
                .get_accounts_by_code_hash(&code_hash, limit, &continuation)
                .await
                .handle_error()?;

            let accounts_list = AccountsList {
                accounts: accounts.clone(),
                continuation: accounts.last().cloned(),
            };

            serde_json::to_value(accounts_list).handle_error()
        }

        let result = internal_fn(transport, code_hash, limit, continuation)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_transport_get_transactions(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    address: *mut c_char,
    continuation: *mut c_char,
    limit: c_uchar,
) {
    let transport = match_transport(transport, transport_type);

    let address = address.to_string_from_ptr();
    let continuation = continuation.to_optional_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
            continuation: Option<String>,
            limit: u8,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let continuation = continuation
                .map(|e| serde_json::from_str::<TransactionId>(&e))
                .transpose()
                .handle_error()?;

            let before_lt = continuation.map(|e| e.lt);

            let from = TransactionId {
                lt: before_lt.unwrap_or(u64::MAX),
                hash: Default::default(),
            };

            let raw_transactions = transport
                .get_transactions(&address, from.lt, limit)
                .await
                .handle_error()?;

            let transactions = raw_transactions
                .clone()
                .into_iter()
                .filter_map(|e| Transaction::try_from((e.hash, e.data)).ok())
                .collect::<Vec<_>>();

            let continuation = raw_transactions.last().and_then(|e| {
                (e.data.prev_trans_lt != 0).then(|| TransactionId {
                    lt: e.data.prev_trans_lt,
                    hash: e.data.prev_trans_hash,
                })
            });

            let batch_info = match (raw_transactions.first(), raw_transactions.last()) {
                (Some(first), Some(last)) => Some(TransactionsBatchInfo {
                    min_lt: last.data.lt,
                    max_lt: first.data.lt,
                    batch_type: TransactionsBatchType::New,
                }),
                _ => None,
            };

            let transactions_list = TransactionsList {
                transactions,
                continuation,
                info: batch_info,
            };

            serde_json::to_value(transactions_list).handle_error()
        }

        let result = internal_fn(transport, address, continuation, limit)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_transport_get_transaction(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    hash: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let hash = hash.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            hash: String,
        ) -> Result<serde_json::Value, String> {
            let hash = parse_hash(&hash)?;

            let transaction = transport
                .get_transaction(&hash)
                .await
                .handle_error()?
                .map(|e| Transaction::try_from((e.hash, e.data)))
                .transpose()
                .handle_error()?;

            serde_json::to_value(transaction).handle_error()
        }

        let result = internal_fn(transport, hash).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

pub unsafe fn match_transport(transport: *mut c_void, transport_type: i32) -> Arc<dyn Transport> {
    match FromPrimitive::from_i32(transport_type) {
        Some(TransportType::Jrpc) => {
            Arc::from_raw(transport as *mut JrpcTransport) as Arc<dyn Transport>
        }
        Some(TransportType::Gql) => {
            Arc::from_raw(transport as *mut GqlTransport) as Arc<dyn Transport>
        }
        None => panic!(),
    }
}
