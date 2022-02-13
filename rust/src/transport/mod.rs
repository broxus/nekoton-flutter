pub mod gql_transport;
pub mod jrpc_transport;
pub mod models;

use self::models::match_transport;
use crate::{
    models::{FromPtr, HandleError, MatchResult, ToPtr},
    parse_address, runtime, send_to_result_port,
    transport::models::{FullContractState, TransactionsList},
    RUNTIME,
};
use nekoton::{
    core::models::{Transaction, TransactionsBatchInfo, TransactionsBatchType},
    transport::{models::RawContractState, Transport},
};
use nekoton_abi::TransactionId;
use std::{
    convert::TryFrom,
    ffi::c_void,
    os::raw::{c_char, c_int, c_longlong, c_uchar, c_ulonglong},
    sync::Arc,
};

#[no_mangle]
pub unsafe extern "C" fn get_full_account_state(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    address: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let address = address.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let raw_contract_state = transport
                .get_contract_state(&address)
                .await
                .handle_error()?;

            let full_contract_state = match raw_contract_state {
                RawContractState::Exists(state) => {
                    let account_cell =
                        ton_block::Serializable::serialize(&state.account).handle_error()?;
                    let boc = ton_types::serialize_toc(&account_cell)
                        .map(base64::encode)
                        .handle_error()?;

                    let full_contract_state = FullContractState {
                        balance: state.account.storage.balance.grams.0.to_string(),
                        gen_timings: state.timings,
                        last_transaction_id: Some(state.last_transaction_id),
                        is_deployed: matches!(
                            &state.account.storage.state,
                            ton_block::AccountState::AccountActive {
                                init_code_hash: _,
                                state_init: _,
                            }
                        ),
                        boc,
                    };

                    Some(full_contract_state)
                }
                RawContractState::NotExists => None,
            };

            let full_contract_state = serde_json::to_string(&full_contract_state)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(full_contract_state)
        }

        let result = internal_fn(transport, address).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_transactions(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    address: *mut c_char,
    continuation: *mut c_char,
    limit: c_uchar,
) {
    let transport = match_transport(transport, transport_type);

    let address = address.from_ptr();
    let continuation = match !continuation.is_null() {
        true => Some(continuation.from_ptr()),
        false => None,
    };

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
            continuation: Option<String>,
            limit: u8,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;
            let continuation = continuation
                .map(|e| serde_json::from_str::<TransactionId>(&e))
                .transpose()
                .handle_error()?;
            let before_lt = continuation.map(|id| id.lt);

            let raw_transactions = transport
                .get_transactions(
                    address,
                    TransactionId {
                        lt: before_lt.unwrap_or(u64::MAX),
                        hash: Default::default(),
                    },
                    limit,
                )
                .await
                .handle_error()?;

            let transactions = raw_transactions
                .clone()
                .into_iter()
                .filter_map(|transaction| {
                    Transaction::try_from((transaction.hash, transaction.data)).ok()
                })
                .collect::<Vec<_>>();

            let continuation = raw_transactions.last().and_then(|transaction| {
                (transaction.data.prev_trans_lt != 0).then(|| TransactionId {
                    lt: transaction.data.prev_trans_lt,
                    hash: transaction.data.prev_trans_hash,
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
            let transactions_list = serde_json::to_string(&transactions_list)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(transactions_list)
        }

        let result = internal_fn(transport, address, continuation, limit)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}
