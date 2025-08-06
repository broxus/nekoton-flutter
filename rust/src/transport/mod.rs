use std::{
    convert::TryFrom,
    os::raw::{c_char, c_longlong, c_uchar, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
pub use gql_transport::gql_connection_new;
use nekoton::crypto::SignedMessage;
use nekoton::{
    core::models::{Transaction, TransactionsBatchInfo, TransactionsBatchType},
    transport::{models::RawContractState, Transport},
};
use nekoton_abi::TransactionId;
use nekoton_utils::SimpleClock;
use ton_block::Serializable;

use crate::{
    clock, parse_address, parse_hash, runtime,
    transport::{
        gql_transport::gql_transport_from_native_ptr,
        jrpc_transport::jrpc_transport_from_native_ptr,
        models::{
            AccountsList, FullContractState, RawContractStateHelper, TransactionsList,
            TransportType,
        },
        proto_transport::proto_transport_from_native_ptr,
    },
    HandleError, MatchResult, PostWithResult, ToOptionalStringFromPtr, ToPtrAddress,
    ToStringFromPtr, CLOCK, RUNTIME,
};

mod gql_transport;
mod jrpc_transport;
pub mod models;
mod proto_transport;

#[no_mangle]
pub unsafe extern "C" fn nt_transport_get_contract_state(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
    address: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let address = address.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let contract_state = transport
                .get_contract_state(&address)
                .await
                .handle_error()?;

            serde_json::to_value(RawContractStateHelper(contract_state)).handle_error()
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
    transport_type: *mut c_char,
    address: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let address = address.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

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
                        balance: state.account.storage.balance.grams.as_u128().to_string(),
                        gen_timings: state.timings,
                        last_transaction_id: Some(state.last_transaction_id),
                        is_deployed,
                        code_hash: None,
                        boc,
                    })
                },
                RawContractState::NotExists { .. } => None,
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
    transport_type: *mut c_char,
    code_hash: *mut c_char,
    limit: c_uchar,
    continuation: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let code_hash = code_hash.to_string_from_ptr();
    let continuation = continuation.to_optional_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

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
    transport_type: *mut c_char,
    address: *mut c_char,
    from_lt: *mut c_char,
    limit: c_uchar,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let address = address.to_string_from_ptr();
    let from_lt = from_lt.to_optional_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
            from_lt: Option<String>,
            limit: u8,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let from_lt = from_lt
                .map(|e| e.parse::<u64>())
                .transpose()
                .handle_error()?
                .unwrap_or(u64::MAX);

            let raw_transactions = transport
                .get_transactions(&address, from_lt, limit)
                .await
                .handle_error()?;

            let transactions = raw_transactions
                .clone()
                .into_iter()
                .filter_map(|e| Transaction::try_from((e.hash, e.data)).ok())
                .collect::<Vec<_>>();

            let continuation = raw_transactions.last().and_then(|e| {
                (e.data.prev_trans_lt != 0).then_some(TransactionId {
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

        let result = internal_fn(transport, address, from_lt, limit)
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
    transport_type: *mut c_char,
    hash: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let hash = hash.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

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

#[no_mangle]
pub unsafe extern "C" fn nt_transport_get_signature_id(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(transport: Arc<dyn Transport>) -> Result<serde_json::Value, String> {
            let id = transport
                .get_capabilities(&SimpleClock)
                .await
                .handle_error()?
                .signature_id();
            serde_json::to_value(id).handle_error()
        }

        let result = internal_fn(transport).await.match_result();
        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_transport_get_network_id(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(transport: Arc<dyn Transport>) -> Result<serde_json::Value, String> {
            let id = transport
                .get_capabilities(&SimpleClock)
                .await
                .handle_error()?
                .global_id;
            serde_json::to_value(id).handle_error()
        }

        let result = internal_fn(transport).await.match_result();
        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_transport_simulate_transaction_tree(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
    signed_message: *mut c_char,
    ignored_compute_phase_codes: *mut c_char,
    ignored_action_phase_codes: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let transport = match_transport(transport, &transport_type);
    let signed_message = signed_message.to_string_from_ptr();
    let ignored_compute_phase_codes = ignored_compute_phase_codes.to_string_from_ptr();
    let ignored_action_phase_codes = ignored_action_phase_codes.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            signed_message: String,
            ignored_compute_phase_codes: String,
            ignored_action_phase_codes: String,
        ) -> Result<serde_json::Value, String> {
            let signed_message =
                serde_json::from_str::<SignedMessage>(&signed_message).handle_error()?;
            let ignored_compute_phase_codes: Vec<i32> =
                serde_json::from_str(&ignored_compute_phase_codes).handle_error()?;
            let ignored_action_phase_codes: Vec<i32> =
                serde_json::from_str(&ignored_action_phase_codes).handle_error()?;

            let config = transport
                .get_blockchain_config(clock!().as_ref(), false)
                .await
                .handle_error()
                .unwrap();

            let mut transactions_tree =
                nekoton::core::transactions_tree::TransactionsTreeStream::new(
                    signed_message.message,
                    config,
                    transport,
                    clock!(),
                );

            let errors = simulate_transaction_tree(
                &mut transactions_tree,
                &ignored_compute_phase_codes,
                &ignored_action_phase_codes,
            )
            .await
            .handle_error()
            .unwrap();

            let result = errors
                .into_iter()
                .map(|(address, error)| make_tx_tree_simulation_error(&address, &error))
                .collect::<Result<Vec<_>, String>>()
                .unwrap();

            serde_json::to_value(result).handle_error()
        }

        async fn simulate_transaction_tree(
            stream: &mut nekoton::core::transactions_tree::TransactionsTreeStream,
            ignored_compute_phase_codes: &[i32],
            ignored_action_phase_codes: &[i32],
        ) -> Result<Vec<(ton_block::MsgAddressInt, TxTreeSimulationError)>, String> {
            let mut result = Vec::new();
            stream.disable_signature_check();
            'stream: while let Some(tx) = stream.next().await.map_err(|e| e.to_string())? {
                let address = 'address: {
                    if let Some(in_msg) = &tx.in_msg {
                        if let Some(dst) = in_msg.read_struct().map_err(|e| e.to_string())?.dst() {
                            break 'address dst;
                        }
                    }
                    continue 'stream;
                };

                if tx.end_status == ton_block::AccountStatus::AccStateFrozen {
                    result.push((address, TxTreeSimulationError::Frozen));
                    continue;
                } else if tx.orig_status == ton_block::AccountStatus::AccStateFrozen
                    && tx.end_status == ton_block::AccountStatus::AccStateNonexist
                {
                    result.push((address, TxTreeSimulationError::Deleted));
                    continue;
                }

                let ton_block::TransactionDescr::Ordinary(descr) =
                    tx.read_description().map_err(|e| e.to_string())?
                else {
                    continue;
                };

                if let ton_block::TrComputePhase::Vm(compute) = descr.compute_ph {
                    if !compute.success && !ignored_compute_phase_codes.contains(&compute.exit_code)
                    {
                        result.push((
                            address,
                            TxTreeSimulationError::ComputePhase {
                                code: compute.exit_code,
                            },
                        ));
                        continue;
                    }
                }

                if let Some(action) = descr.action {
                    if !action.success && !ignored_action_phase_codes.contains(&action.result_code)
                    {
                        result.push((
                            address,
                            TxTreeSimulationError::ActionPhase {
                                code: action.result_code,
                            },
                        ));
                        continue;
                    }
                }
            }
            Ok(result)
        }

        let result = internal_fn(
            transport,
            signed_message,
            ignored_compute_phase_codes,
            ignored_action_phase_codes,
        )
        .await
        .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

pub unsafe fn match_transport(transport: *mut c_void, transport_type: &str) -> Arc<dyn Transport> {
    let transport_type = serde_json::from_str::<TransportType>(transport_type).unwrap();

    match transport_type {
        TransportType::Jrpc => {
            jrpc_transport_from_native_ptr(transport).clone() as Arc<dyn Transport>
        },
        TransportType::Gql => {
            gql_transport_from_native_ptr(transport).clone() as Arc<dyn Transport>
        },
        TransportType::Proto => {
            proto_transport_from_native_ptr(transport).clone() as Arc<dyn Transport>
        },
    }
}

enum TxTreeSimulationError {
    ComputePhase { code: i32 },
    ActionPhase { code: i32 },
    Frozen,
    Deleted,
}

fn make_tx_tree_simulation_error(
    address: &ton_block::MsgAddressInt,
    error: &TxTreeSimulationError,
) -> Result<serde_json::Value, String> {
    let error = match error {
        TxTreeSimulationError::ComputePhase { code } => serde_json::json!({
            "type" : "compute_phase",
            "code": *code,
        }),
        TxTreeSimulationError::ActionPhase { code } => serde_json::json!({
            "type" : "action_phase",
            "code": *code,
        }),
        TxTreeSimulationError::Frozen => serde_json::json!({
            "type" : "frozen",
        }),
        TxTreeSimulationError::Deleted => serde_json::json!({
            "type" : "deleted",
        }),
    };

    Ok(serde_json::json!({
        "address" : address.to_string(),
        "error": error,
    }))
}
