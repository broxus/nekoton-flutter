use std::{
    os::raw::{c_char, c_longlong},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::{bail, Result};
use async_trait::async_trait;
use nekoton::external::{LedgerConnection, LedgerSignatureContext};
use tokio::sync::oneshot::channel;

use crate::{
    channel_err_new, ffi_box, nt_channel_err_free_ptr, HandleError, MatchResult, ToPtrAddress,
    ToPtrFromAddress, ISOLATE_MESSAGE_POST_ERROR,
};

pub struct LedgerConnectionImpl {
    get_public_key_port: Isolate,
    _sign_port: Isolate,
}

impl LedgerConnectionImpl {
    pub fn new(get_public_key_port: i64, sign_port: i64) -> Self {
        Self {
            get_public_key_port: Isolate::new(get_public_key_port),
            _sign_port: Isolate::new(sign_port),
        }
    }
}

#[async_trait]
impl LedgerConnection for LedgerConnectionImpl {
    async fn get_public_key(
        &self,
        account_id: u16,
    ) -> Result<[u8; ed25519_dalek::PUBLIC_KEY_LENGTH]> {
        let (tx, rx) = channel::<Result<String>>();

        let tx = channel_err_new(tx).to_ptr_address();

        let request = serde_json::to_string(&(tx.clone(), account_id))?;

        match self.get_public_key_port.post(request) {
            true => rx
                .await
                .unwrap()
                .map(|e| -> [u8; ed25519_dalek::PUBLIC_KEY_LENGTH] {
                    hex::decode(e).unwrap().as_slice().try_into().unwrap()
                }),
            false => {
                unsafe { nt_channel_err_free_ptr(tx.to_ptr_from_address()) }

                bail!(ISOLATE_MESSAGE_POST_ERROR)
            },
        }
    }

    async fn sign(
        &self,
        _account: u16,
        _signature_id: Option<i32>,
        _message: &[u8],
    ) -> Result<[u8; ed25519_dalek::SIGNATURE_LENGTH]> {
        todo!()
    }

    async fn sign_transaction(
        &self,
        _account: u16,
        _wallet: u16,
        _signature_id: Option<i32>,
        _message: &[u8],
        _context: &LedgerSignatureContext,
    ) -> Result<[u8; ed25519_dalek::SIGNATURE_LENGTH]> {
        todo!()
    }
}

#[no_mangle]
pub unsafe extern "C" fn nt_ledger_connection_create(
    get_public_key_port: c_longlong,
    sign_port: c_longlong,
) -> *mut c_char {
    fn internal_fn(get_public_key_port: i64, sign_port: i64) -> Result<serde_json::Value, String> {
        let ledger_connection = LedgerConnectionImpl::new(get_public_key_port, sign_port);

        let ptr = ledger_connection_new(Arc::new(ledger_connection));
        serde_json::to_value(ptr.to_ptr_address()).handle_error()
    }

    internal_fn(get_public_key_port, sign_port).match_result()
}

ffi_box!(ledger_connection, Arc<LedgerConnectionImpl>);
