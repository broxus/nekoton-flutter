use std::{
    os::raw::{c_char, c_longlong, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
use anyhow::{bail, Result};
use async_trait::async_trait;
use nekoton::external::{LedgerConnection, LedgerSignatureContext};
use serde::Serialize;
use tokio::sync::oneshot::{channel, Sender};

use crate::{HandleError, MatchResult};

pub struct LedgerConnectionImpl {
    get_public_key_port: Isolate,
    sign_port: Isolate,
}

impl LedgerConnectionImpl {
    pub fn new(get_public_key_port: i64, sign_port: i64) -> Self {
        Self {
            get_public_key_port: Isolate::new(get_public_key_port),
            sign_port: Isolate::new(sign_port),
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

        let tx = Box::into_raw(Box::new(tx)) as usize;

        let request =
            serde_json::to_string(&LedgerConnectionGetPublicKeyRequest { tx, account_id })?;

        match self.get_public_key_port.post(request) {
            true => rx
                .await
                .unwrap()
                .map(|e| -> [u8; ed25519_dalek::PUBLIC_KEY_LENGTH] {
                    hex::decode(&e).unwrap().as_slice().try_into().unwrap()
                }),
            false => {
                unsafe {
                    Box::from_raw(tx as *mut Sender<Result<String>>);
                }

                bail!("Message was not posted successfully")
            },
        }
    }

    async fn sign(
        &self,
        account: u16,
        message: &[u8],
        context: &Option<LedgerSignatureContext>,
    ) -> Result<[u8; ed25519_dalek::SIGNATURE_LENGTH]> {
        let (tx, rx) = channel::<Result<String>>();

        let tx = Box::into_raw(Box::new(tx)) as usize;
        let message = message.to_owned();
        let context = context.to_owned();

        let request = serde_json::to_string(&LedgerConnectionSignRequest {
            tx,
            account,
            message,
            context,
        })?;

        match self.sign_port.post(request) {
            true => rx
                .await
                .unwrap()
                .map(|e| -> [u8; ed25519_dalek::SIGNATURE_LENGTH] {
                    hex::decode(&e).unwrap().as_slice().try_into().unwrap()
                }),
            false => {
                unsafe {
                    Box::from_raw(tx as *mut Sender<Result<String>>);
                }

                bail!("Message was not posted successfully")
            },
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LedgerConnectionGetPublicKeyRequest {
    pub tx: usize,
    pub account_id: u16,
}

#[derive(Serialize)]
pub struct LedgerConnectionSignRequest {
    pub tx: usize,
    pub account: u16,
    pub message: Vec<u8>,
    pub context: Option<LedgerSignatureContext>,
}

#[no_mangle]
pub unsafe extern "C" fn nt_ledger_connection_create(
    get_public_key_port: c_longlong,
    sign_port: c_longlong,
) -> *mut c_char {
    fn internal_fn(get_public_key_port: i64, sign_port: i64) -> Result<serde_json::Value, String> {
        let ledger_connection = LedgerConnectionImpl::new(get_public_key_port, sign_port);

        let ptr = Box::into_raw(Box::new(Arc::new(ledger_connection)));

        serde_json::to_value(ptr as usize).handle_error()
    }

    internal_fn(get_public_key_port, sign_port).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn nt_ledger_connection_free_ptr(ptr: *mut c_void) {
    println!("nt_ledger_connection_free_ptr");
    Box::from_raw(ptr as *mut Arc<LedgerConnectionImpl>);
}
