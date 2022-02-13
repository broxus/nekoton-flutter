use nekoton::{
    core::models::{Transaction, TransactionsBatchInfo},
    transport::{gql::GqlTransport, jrpc::JrpcTransport, Transport},
};
use nekoton_abi::{GenTimings, LastTransactionId, TransactionId};
use num_derive::FromPrimitive;
use num_traits::FromPrimitive;
use serde::Serialize;
use std::{ffi::c_void, sync::Arc};

#[derive(FromPrimitive)]
pub enum TransportType {
    Jrpc,
    Gql,
}

pub unsafe fn match_transport(transport: *mut c_void, transport_type: i32) -> Arc<dyn Transport> {
    match FromPrimitive::from_i32(transport_type) {
        Some(TransportType::Jrpc) => {
            let jrpc_transport = transport as *mut JrpcTransport;
            Arc::from_raw(jrpc_transport) as Arc<dyn Transport>
        }
        Some(TransportType::Gql) => {
            let gql_transport = transport as *mut GqlTransport;
            Arc::from_raw(gql_transport) as Arc<dyn Transport>
        }
        None => panic!(),
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FullContractState {
    pub balance: String,
    pub gen_timings: GenTimings,
    pub last_transaction_id: Option<LastTransactionId>,
    pub is_deployed: bool,
    pub boc: String,
}

#[derive(Serialize)]
pub struct TransactionsList {
    pub transactions: Vec<Transaction>,
    pub continuation: Option<TransactionId>,
    pub info: Option<TransactionsBatchInfo>,
}
