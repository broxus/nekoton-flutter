pub mod adnl_transport;
pub mod gql_transport;
pub mod models;

use crate::{
    match_result,
    models::{FromPtr, HandleError, NativeError, NativeStatus, ToPtr},
    parse_address, runtime, send_to_result_port,
    transport::{
        gql_transport::MutexGqlTransport,
        models::{FullContractState, TransactionsList},
    },
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
    os::raw::{c_char, c_longlong, c_uchar, c_ulonglong},
};

#[no_mangle]
pub unsafe extern "C" fn get_full_account_state(
    result_port: c_longlong,
    transport: *mut c_void,
    address: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);
    let address = address.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_get_full_account_state(transport, address).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_full_account_state(
    transport: &MutexGqlTransport,
    address: String,
) -> Result<u64, NativeError> {
    let transport = transport.lock().await;

    let address = parse_address(&address)?;

    let raw_contract_state = transport
        .get_contract_state(&address)
        .await
        .handle_error(NativeStatus::TransportError)?;

    let full_contract_state = match raw_contract_state {
        RawContractState::Exists(state) => {
            let account_cell = ton_block::Serializable::serialize(&state.account)
                .handle_error(NativeStatus::ConversionError)?;
            let boc = ton_types::serialize_toc(&account_cell)
                .map(base64::encode)
                .handle_error(NativeStatus::ConversionError)?;

            let full_contract_state = FullContractState {
                balance: state.account.storage.balance.grams.0.to_string(),
                gen_timings: state.timings,
                last_transaction_id: Some(state.last_transaction_id),
                is_deployed: matches!(
                    &state.account.storage.state,
                    ton_block::AccountState::AccountActive(_)
                ),
                boc,
            };

            Some(full_contract_state)
        }
        RawContractState::NotExists => None,
    };

    let full_contract_state =
        serde_json::to_string(&full_contract_state).handle_error(NativeStatus::ConversionError)?;

    Ok(full_contract_state.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_transactions(
    result_port: c_longlong,
    transport: *mut c_void,
    address: *mut c_char,
    from: *mut c_char,
    count: c_uchar,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);
    let address = address.from_ptr();
    let from = from.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_get_transactions(transport, address, from, count).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_transactions(
    transport: &MutexGqlTransport,
    address: String,
    continuation: String,
    limit: u8,
) -> Result<u64, NativeError> {
    let transport = transport.lock().await;

    let address = parse_address(&address)?;
    let continuation = serde_json::from_str::<Option<TransactionId>>(&continuation)
        .handle_error(NativeStatus::ConversionError)?;
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
        .handle_error(NativeStatus::TransportError)?;

    let transactions = raw_transactions
        .clone()
        .into_iter()
        .filter_map(|transaction| Transaction::try_from((transaction.hash, transaction.data)).ok())
        .collect::<Vec<Transaction>>();

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
    let transactions_list =
        serde_json::to_string(&transactions_list).handle_error(NativeStatus::ConversionError)?;

    Ok(transactions_list.to_ptr() as c_ulonglong)
}
