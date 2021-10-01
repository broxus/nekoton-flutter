pub mod handler;
pub mod models;

use self::handler::GenericContractSubscriptionHandlerImpl;
use super::keystore::UNKNOWN_SIGNER;
use crate::{
    core::{
        generic_contract::models::MutexGenericContract,
        keystore::{models::MutexKeyStore, KEY_STORE_NOT_FOUND},
        MutexUnsignedMessage,
    },
    crypto::{derived_key::DerivedKeySignParams, encrypted_key::EncryptedKeyPassword},
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    parse_address, runtime, send_to_result_port,
    transport::gql_transport::MutexGqlTransport,
    FromPtr, ToPtr, RUNTIME,
};
use nekoton::{
    core::{generic_contract::GenericContract, keystore::KeyStore, TransactionExecutionOptions},
    crypto::{DerivedKeySigner, EncryptedKeySigner},
    transport::gql::GqlTransport,
};
use nekoton_abi::TransactionId;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    sync::Arc,
};
use tokio::sync::Mutex;

pub const GENERIC_CONTRACT_NOT_FOUND: &str = "Generic contract not found";

#[no_mangle]
pub unsafe extern "C" fn generic_contract_subscribe(
    result_port: c_longlong,
    port: c_longlong,
    transport: *mut c_void,
    address: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let address = address.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let transport = transport.lock().await;
        let transport = transport.clone();

        let result = internal_generic_contract_subscribe(port, transport, address).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_generic_contract_subscribe(
    port: c_longlong,
    transport: Arc<GqlTransport>,
    address: String,
) -> Result<u64, NativeError> {
    let address = parse_address(&address)?;

    let handler = GenericContractSubscriptionHandlerImpl { port };
    let handler = Arc::new(handler);

    let generic_contract = GenericContract::subscribe(transport, address, handler)
        .await
        .handle_error(NativeStatus::GenericContractError)?;

    let generic_contract = Mutex::new(Some(generic_contract));
    let generic_contract = Arc::new(generic_contract);

    let generic_contract = Arc::into_raw(generic_contract) as c_ulonglong;

    Ok(generic_contract)
}

#[no_mangle]
pub unsafe extern "C" fn get_generic_contract_address(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_generic_contract_address(&mut generic_contract).await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_generic_contract_address(
    generic_contract: &mut GenericContract,
) -> Result<u64, NativeError> {
    let address = generic_contract.address();
    let address = address.to_string();

    Ok(address.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_generic_contract_contract_state(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_generic_contract_contract_state(&mut generic_contract).await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_generic_contract_contract_state(
    generic_contract: &mut GenericContract,
) -> Result<u64, NativeError> {
    let contract_state = generic_contract.contract_state();
    let contract_state =
        serde_json::to_string(&contract_state).handle_error(NativeStatus::ConversionError)?;

    Ok(contract_state.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_generic_contract_pending_transactions(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result =
            internal_get_generic_contract_pending_transactions(&mut generic_contract).await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_generic_contract_pending_transactions(
    generic_contract: &mut GenericContract,
) -> Result<u64, NativeError> {
    let pending_transactions = generic_contract.pending_transactions();
    let pending_transactions =
        serde_json::to_string(pending_transactions).handle_error(NativeStatus::ConversionError)?;

    Ok(pending_transactions.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_generic_contract_polling_method(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_generic_contract_polling_method(&mut generic_contract).await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_generic_contract_polling_method(
    generic_contract: &mut GenericContract,
) -> Result<u64, NativeError> {
    let polling_method = generic_contract.polling_method();
    let polling_method =
        serde_json::to_string(&polling_method).handle_error(NativeStatus::ConversionError)?;

    Ok(polling_method.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_send(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    keystore: *mut c_void,
    message: *mut c_void,
    sign_input: *mut c_char,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let message = message as *mut MutexUnsignedMessage;
    let message = &(*message);

    let sign_input = sign_input.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let mut keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                *generic_contract_guard = Some(generic_contract);
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_generic_contract_send(
            &mut generic_contract,
            &mut keystore,
            message,
            sign_input,
        )
        .await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);
        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_generic_contract_send(
    generic_contract: &mut GenericContract,
    keystore: &mut KeyStore,
    message: &MutexUnsignedMessage,
    sign_input: String,
) -> Result<u64, NativeError> {
    let message = unsafe { Arc::from_raw(message) };
    let message = message.lock().await;
    let mut message = dyn_clone::clone_box(&**message);

    message.refresh_timeout();

    let hash = message.hash();

    let signature =
        if let Ok(sign_input) = serde_json::from_str::<EncryptedKeyPassword>(&sign_input) {
            keystore
                .sign::<EncryptedKeySigner>(hash, sign_input.to_core())
                .await
                .handle_error(NativeStatus::KeyStoreError)?
        } else if let Ok(sign_input) = serde_json::from_str::<DerivedKeySignParams>(&sign_input) {
            keystore
                .sign::<DerivedKeySigner>(hash, sign_input.to_core())
                .await
                .handle_error(NativeStatus::KeyStoreError)?
        } else {
            return Err(NativeError {
                status: NativeStatus::KeyStoreError,
                info: UNKNOWN_SIGNER.to_owned(),
            });
        };

    let message = message
        .sign(&signature)
        .handle_error(NativeStatus::CryptoError)?;

    let pending_transaction = generic_contract
        .send(&message.message, message.expire_at)
        .await
        .handle_error(NativeStatus::GenericContractError)?;

    let pending_transaction =
        serde_json::to_string(&pending_transaction).handle_error(NativeStatus::ConversionError)?;

    Ok(pending_transaction.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_refresh(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_generic_contract_refresh(&mut generic_contract).await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);

        send_to_result_port(result_port, result);
    });
}

async fn internal_generic_contract_refresh(
    generic_contract: &mut GenericContract,
) -> Result<u64, NativeError> {
    let _ = generic_contract
        .refresh()
        .await
        .handle_error(NativeStatus::GenericContractError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_handle_block(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    transport: *mut c_void,
    id: *mut c_char,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let id = id.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let transport = transport.lock().await;
        let transport = transport.clone();

        let result =
            internal_generic_contract_handle_block(&mut generic_contract, transport, id).await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);

        send_to_result_port(result_port, result);
    });
}

async fn internal_generic_contract_handle_block(
    generic_contract: &mut GenericContract,
    transport: Arc<GqlTransport>,
    id: String,
) -> Result<u64, NativeError> {
    let block = transport
        .get_block(&id)
        .await
        .handle_error(NativeStatus::TransportError)?;

    let _ = generic_contract
        .handle_block(&block)
        .await
        .handle_error(NativeStatus::GenericContractError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_preload_transactions(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    from: *mut c_char,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let from = from.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result =
            internal_generic_contract_preload_transactions(&mut generic_contract, from).await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);

        send_to_result_port(result_port, result);
    });
}

async fn internal_generic_contract_preload_transactions(
    generic_contract: &mut GenericContract,
    from: String,
) -> Result<u64, NativeError> {
    let from =
        serde_json::from_str::<TransactionId>(&from).handle_error(NativeStatus::ConversionError)?;

    let _ = generic_contract
        .preload_transactions(from)
        .await
        .handle_error(NativeStatus::GenericContractError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_estimate_fees(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    message: *mut c_void,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let message = message as *mut MutexUnsignedMessage;
    let message = &(*message);

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_generic_contract_estimate_fees(&mut generic_contract, message).await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);

        send_to_result_port(result_port, result);
    });
}

async fn internal_generic_contract_estimate_fees(
    generic_contract: &mut GenericContract,
    message: &MutexUnsignedMessage,
) -> Result<u64, NativeError> {
    let message = message.lock().await;
    let message = dyn_clone::clone_box(&**message);

    let signature = [u8::default(); ed25519_dalek::SIGNATURE_LENGTH];

    let message = message
        .sign(&signature)
        .handle_error(NativeStatus::GenericContractError)?;
    let message = message.message;

    let fees = generic_contract
        .estimate_fees(&message)
        .await
        .handle_error(NativeStatus::GenericContractError)?;

    Ok(fees)
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_execute_transaction_locally(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    keystore: *mut c_void,
    message: *mut c_void,
    sign_input: *mut c_char,
    options: *mut c_char,
) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    let generic_contract = &(*generic_contract);

    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let message = message as *mut MutexUnsignedMessage;
    let message = &(*message);

    let sign_input = sign_input.from_ptr();
    let options = options.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut generic_contract_guard = generic_contract.lock().await;
        let generic_contract = generic_contract_guard.take();
        let mut generic_contract = match generic_contract {
            Some(generic_contract) => generic_contract,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GENERIC_CONTRACT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let mut keystore_guard = keystore.lock().await;
        let keystore = keystore_guard.take();
        let mut keystore = match keystore {
            Some(keystore) => keystore,
            None => {
                *generic_contract_guard = Some(generic_contract);
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_generic_contract_execute_transaction_locally(
            &mut generic_contract,
            &mut keystore,
            message,
            sign_input,
            options,
        )
        .await;
        let result = match_result(result);

        *generic_contract_guard = Some(generic_contract);
        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_generic_contract_execute_transaction_locally(
    generic_contract: &mut GenericContract,
    keystore: &mut KeyStore,
    message: &MutexUnsignedMessage,
    sign_input: String,
    options: String,
) -> Result<u64, NativeError> {
    let message = unsafe { Arc::from_raw(message) };
    let message = message.lock().await;
    let mut message = dyn_clone::clone_box(&**message);

    let options = serde_json::from_str::<TransactionExecutionOptions>(&options)
        .handle_error(NativeStatus::ConversionError)?;

    message.refresh_timeout();

    let hash = message.hash();

    let signature =
        if let Ok(sign_input) = serde_json::from_str::<EncryptedKeyPassword>(&sign_input) {
            keystore
                .sign::<EncryptedKeySigner>(hash, sign_input.to_core())
                .await
                .handle_error(NativeStatus::KeyStoreError)?
        } else if let Ok(sign_input) = serde_json::from_str::<DerivedKeySignParams>(&sign_input) {
            keystore
                .sign::<DerivedKeySigner>(hash, sign_input.to_core())
                .await
                .handle_error(NativeStatus::KeyStoreError)?
        } else {
            return Err(NativeError {
                status: NativeStatus::KeyStoreError,
                info: UNKNOWN_SIGNER.to_owned(),
            });
        };

    let message = message
        .sign(&signature)
        .handle_error(NativeStatus::CryptoError)?;

    let transaction = generic_contract
        .execute_transaction_locally(&message.message, options)
        .await
        .handle_error(NativeStatus::GenericContractError)?;

    let transaction =
        serde_json::to_string(&transaction).handle_error(NativeStatus::ConversionError)?;

    Ok(transaction.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn free_generic_contract(generic_contract: *mut c_void) {
    let generic_contract = generic_contract as *mut MutexGenericContract;
    Arc::from_raw(generic_contract);
}
