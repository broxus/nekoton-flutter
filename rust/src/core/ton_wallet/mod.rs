pub mod handler;
pub mod models;

use self::models::{ExistingWalletInfo, MultisigPendingTransaction};
use super::keystore::UNKNOWN_SIGNER;
use crate::{
    core::{
        keystore::{models::MutexKeyStore, KEY_STORE_NOT_FOUND},
        ton_wallet::{
            handler::TonWalletSubscriptionHandlerImpl,
            models::{MutexTonWallet, WalletType},
        },
        ContractState, Expiration, MutexUnsignedMessage,
    },
    crypto::{derived_key::DerivedKeySignParams, encrypted_key::EncryptedKeyPassword},
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    runtime, send_to_result_port,
    transport::gql_transport::MutexGqlTransport,
    FromPtr, ToPtr, RUNTIME,
};
use nekoton::{
    core::{
        keystore::KeyStore,
        ton_wallet::{TonWallet, TransferAction},
    },
    crypto::{DerivedKeySigner, EncryptedKeySigner},
    transport::{gql::GqlTransport, models::RawContractState, Transport},
};
use nekoton_abi::{create_comment_payload, TransactionId};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_schar, c_uchar, c_ulonglong},
    str::FromStr,
    sync::Arc,
};
use tokio::sync::Mutex;
use ton_block::MsgAddressInt;
use ton_types::SliceData;

pub const TON_WALLET_NOT_FOUND: &str = "Ton wallet not found";
const NOT_EXISTS: &str = "Not exists";
const DEPLOY_FIRST: &str = "Deploy first";

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_subscribe(
    result_port: c_longlong,
    port: c_longlong,
    transport: *mut c_void,
    workchain: c_schar,
    public_key: *mut c_char,
    contract: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let public_key = public_key.from_ptr();
    let contract = contract.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let transport = transport.lock().await;
        let transport = transport.clone();

        let result =
            internal_ton_wallet_subscribe(port, transport, workchain, public_key, contract).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_subscribe(
    port: c_longlong,
    transport: Arc<GqlTransport>,
    workchain: i8,
    public_key: String,
    contract: String,
) -> Result<u64, NativeError> {
    let public_key = hex::decode(public_key).handle_error(NativeStatus::ConversionError)?;
    let public_key = ed25519_dalek::PublicKey::from_bytes(&public_key)
        .handle_error(NativeStatus::ConversionError)?;

    let contract = serde_json::from_str::<WalletType>(&contract)
        .handle_error(NativeStatus::ConversionError)?;
    let contract = WalletType::to_core(contract);

    let handler = TonWalletSubscriptionHandlerImpl { port };
    let handler = Arc::new(handler);

    let ton_wallet = TonWallet::subscribe(transport, workchain, public_key, contract, handler)
        .await
        .handle_error(NativeStatus::TonWalletError)?;

    let ton_wallet = Mutex::new(Some(ton_wallet));
    let ton_wallet = Arc::new(ton_wallet);

    let ton_wallet = Arc::into_raw(ton_wallet) as c_ulonglong;

    Ok(ton_wallet)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_subscribe_by_address(
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

        let result = internal_ton_wallet_subscribe_by_address(port, transport, address).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_subscribe_by_address(
    port: c_longlong,
    transport: Arc<GqlTransport>,
    address: String,
) -> Result<u64, NativeError> {
    let address = MsgAddressInt::from_str(&address).handle_error(NativeStatus::ConversionError)?;

    let handler = TonWalletSubscriptionHandlerImpl { port };
    let handler = Arc::new(handler);

    let ton_wallet = TonWallet::subscribe_by_address(transport, address, handler)
        .await
        .handle_error(NativeStatus::TonWalletError)?;

    let ton_wallet = Mutex::new(Some(ton_wallet));
    let ton_wallet = Arc::new(ton_wallet);

    let ton_wallet = Arc::into_raw(ton_wallet) as c_ulonglong;

    Ok(ton_wallet)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_subscribe_by_existing(
    result_port: c_longlong,
    port: c_longlong,
    transport: *mut c_void,
    existing_wallet: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let existing_wallet = existing_wallet.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let transport = transport.lock().await;
        let transport = transport.clone();

        let result =
            internal_ton_wallet_subscribe_by_existing(port, transport, existing_wallet).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_subscribe_by_existing(
    port: c_longlong,
    transport: Arc<GqlTransport>,
    existing_wallet: String,
) -> Result<u64, NativeError> {
    let existing_wallet = serde_json::from_str::<ExistingWalletInfo>(&existing_wallet)
        .handle_error(NativeStatus::ConversionError)?;

    let handler = TonWalletSubscriptionHandlerImpl { port };
    let handler = Arc::new(handler);

    let ton_wallet =
        TonWallet::subscribe_by_existing(transport, existing_wallet.to_core(), handler)
            .await
            .handle_error(NativeStatus::TonWalletError)?;

    let ton_wallet = Mutex::new(Some(ton_wallet));
    let ton_wallet = Arc::new(ton_wallet);

    let ton_wallet = Arc::into_raw(ton_wallet) as c_ulonglong;

    Ok(ton_wallet)
}

#[no_mangle]
pub unsafe extern "C" fn find_existing_wallets(
    result_port: c_longlong,
    transport: *mut c_void,
    public_key: *mut c_char,
    workchain_id: c_schar,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let public_key = public_key.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let transport = transport.lock().await;
        let transport = transport.clone();

        let result = internal_find_existing_wallets(transport, public_key, workchain_id).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_find_existing_wallets(
    transport: Arc<GqlTransport>,
    public_key: String,
    workchain_id: i8,
) -> Result<u64, NativeError> {
    let public_key = hex::decode(public_key).handle_error(NativeStatus::ConversionError)?;
    let public_key = ed25519_dalek::PublicKey::from_bytes(&public_key)
        .handle_error(NativeStatus::ConversionError)?;

    let existing_wallets = nekoton::core::ton_wallet::find_existing_wallets(
        transport.as_ref(),
        &public_key,
        workchain_id,
    )
    .await
    .handle_error(NativeStatus::TonWalletError)?;

    let existing_wallets = existing_wallets
        .into_iter()
        .map(|e| ExistingWalletInfo::from_core(e))
        .collect::<Vec<ExistingWalletInfo>>();

    let existing_wallets =
        serde_json::to_string(&existing_wallets).handle_error(NativeStatus::ConversionError)?;

    Ok(existing_wallets.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_address(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_address(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_address(ton_wallet: &mut TonWallet) -> Result<u64, NativeError> {
    let address = ton_wallet.address();
    let address = address.to_string();

    Ok(address.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_public_key(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_public_key(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_public_key(
    ton_wallet: &mut TonWallet,
) -> Result<u64, NativeError> {
    let public_key = ton_wallet.public_key();
    let public_key = hex::encode(public_key.to_bytes());

    Ok(public_key.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_wallet_type(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_wallet_type(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_wallet_type(
    ton_wallet: &mut TonWallet,
) -> Result<u64, NativeError> {
    let contract = ton_wallet.wallet_type();
    let contract = WalletType::from_core(contract);
    let contract = serde_json::to_string(&contract).handle_error(NativeStatus::ConversionError)?;

    Ok(contract.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_contract_state(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_contract_state(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_contract_state(
    ton_wallet: &mut TonWallet,
) -> Result<u64, NativeError> {
    let contract_state = ton_wallet.contract_state();
    let contract_state = ContractState::from_core(contract_state.clone());
    let contract_state =
        serde_json::to_string(&contract_state).handle_error(NativeStatus::ConversionError)?;

    Ok(contract_state.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_pending_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_pending_transactions(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_pending_transactions(
    ton_wallet: &mut TonWallet,
) -> Result<u64, NativeError> {
    let pending_transactions = ton_wallet.pending_transactions();
    let pending_transactions =
        serde_json::to_string(pending_transactions).handle_error(NativeStatus::ConversionError)?;

    Ok(pending_transactions.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_polling_method(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_polling_method(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_polling_method(
    ton_wallet: &mut TonWallet,
) -> Result<u64, NativeError> {
    let polling_method = ton_wallet.polling_method();
    let polling_method =
        serde_json::to_string(&polling_method).handle_error(NativeStatus::ConversionError)?;

    Ok(polling_method.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_details(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_details(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_details(ton_wallet: &mut TonWallet) -> Result<u64, NativeError> {
    let details = ton_wallet.details();
    let details = serde_json::to_string(&details).handle_error(NativeStatus::ConversionError)?;

    Ok(details.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_unconfirmed_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_unconfirmed_transactions(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_unconfirmed_transactions(
    ton_wallet: &mut TonWallet,
) -> Result<u64, NativeError> {
    let unconfirmed_transactions = ton_wallet.get_unconfirmed_transactions();
    let unconfirmed_transactions = unconfirmed_transactions
        .into_iter()
        .map(|e| MultisigPendingTransaction::from_core(e.clone()))
        .collect::<Vec<MultisigPendingTransaction>>();
    let unconfirmed_transactions = serde_json::to_string(&unconfirmed_transactions)
        .handle_error(NativeStatus::ConversionError)?;

    Ok(unconfirmed_transactions.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_custodians(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_ton_wallet_custodians(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_ton_wallet_custodians(
    ton_wallet: &mut TonWallet,
) -> Result<u64, NativeError> {
    let custodians = ton_wallet.get_custodians();
    let custodians = custodians.clone();
    let custodians =
        custodians.map(|e| e.iter().map(|e| e.to_hex_string()).collect::<Vec<String>>());
    let custodians =
        serde_json::to_string(&custodians).handle_error(NativeStatus::ConversionError)?;

    Ok(custodians.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_prepare_deploy(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let expiration = expiration.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_ton_wallet_prepare_deploy(&mut ton_wallet, expiration).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_prepare_deploy(
    ton_wallet: &mut TonWallet,
    expiration: String,
) -> Result<u64, NativeError> {
    let expiration = serde_json::from_str::<Expiration>(&expiration)
        .handle_error(NativeStatus::ConversionError)?;
    let expiration = expiration.to_core();

    let message = ton_wallet
        .prepare_deploy(expiration)
        .handle_error(NativeStatus::TonWalletError)?;

    let message = Mutex::new(message);
    let message = Arc::new(message);

    let message = Arc::into_raw(message) as c_ulonglong;

    Ok(message)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_prepare_deploy_with_multiple_owners(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    expiration: *mut c_char,
    custodians: *mut c_char,
    req_confirms: c_uchar,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let expiration = expiration.from_ptr();
    let custodians = custodians.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_ton_wallet_prepare_deploy_with_multiple_owners(
            &mut ton_wallet,
            expiration,
            custodians,
            req_confirms,
        )
        .await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_prepare_deploy_with_multiple_owners(
    ton_wallet: &mut TonWallet,
    expiration: String,
    custodians: String,
    req_confirms: u8,
) -> Result<u64, NativeError> {
    let expiration = serde_json::from_str::<Expiration>(&expiration)
        .handle_error(NativeStatus::ConversionError)?;
    let expiration = expiration.to_core();

    let custodians = serde_json::from_str::<Vec<String>>(&custodians)
        .handle_error(NativeStatus::ConversionError)?;
    let custodians = custodians
        .into_iter()
        .map(|e| -> Result<ed25519_dalek::PublicKey, NativeError> {
            let public_key = hex::decode(e).handle_error(NativeStatus::ConversionError)?;
            let public_key = ed25519_dalek::PublicKey::from_bytes(&public_key)
                .handle_error(NativeStatus::ConversionError)?;

            Ok(public_key)
        })
        .collect::<Result<Vec<ed25519_dalek::PublicKey>, NativeError>>()?;

    let message = ton_wallet
        .prepare_deploy_with_multiple_owners(expiration, &custodians, req_confirms)
        .handle_error(NativeStatus::TonWalletError)?;

    let message = Mutex::new(message);
    let message = Arc::new(message);

    let message = Arc::into_raw(message) as c_ulonglong;

    Ok(message)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_prepare_transfer(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    transport: *mut c_void,
    expiration: *mut c_char,
    destination: *mut c_char,
    amount: c_ulonglong,
    body: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let expiration = expiration.from_ptr();
    let destination = destination.from_ptr();
    let body = if !body.is_null() {
        Some(body.from_ptr())
    } else {
        None
    };

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let transport = transport.lock().await;
        let transport = transport.clone();

        let result =
            internal_ton_wallet_prepare_transfer_params(expiration, destination, body).await;
        let (expiration, destination, body) = match result {
            Ok((expiration, destination, body)) => (expiration, destination, body),
            Err(error) => {
                *ton_wallet_guard = Some(ton_wallet);
                let result = match_result(Err(error));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_ton_wallet_prepare_transfer(
            &mut ton_wallet,
            transport,
            expiration,
            destination,
            amount,
            body,
        )
        .await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

pub async fn internal_ton_wallet_prepare_transfer_params(
    expiration: String,
    destination: String,
    body: Option<String>,
) -> Result<
    (
        nekoton::core::models::Expiration,
        MsgAddressInt,
        Option<SliceData>,
    ),
    NativeError,
> {
    let expiration = serde_json::from_str::<Expiration>(&expiration)
        .handle_error(NativeStatus::ConversionError)?;
    let expiration = expiration.to_core();
    let destination =
        MsgAddressInt::from_str(&destination).handle_error(NativeStatus::ConversionError)?;
    let body = match body {
        Some(comment) => {
            let body = create_comment_payload(&comment).handle_error(NativeStatus::AbiError)?;
            Some(body)
        }
        None => None,
    };

    Ok((expiration, destination, body))
}

pub async fn internal_ton_wallet_prepare_transfer(
    ton_wallet: &mut TonWallet,
    transport: Arc<GqlTransport>,
    expiration: nekoton::core::models::Expiration,
    destination: MsgAddressInt,
    amount: u64,
    body: Option<SliceData>,
) -> Result<u64, NativeError> {
    let address = ton_wallet.address();
    let public_key = ton_wallet.public_key();
    let public_key = public_key.clone();

    let account_state = transport
        .get_contract_state(address)
        .await
        .handle_error(NativeStatus::TonWalletError)?;
    let account_stuff = match account_state {
        RawContractState::NotExists => {
            return Err(NativeError {
                status: NativeStatus::TonWalletError,
                info: NOT_EXISTS.to_owned(),
            })
        }
        RawContractState::Exists(contract) => contract.account,
    };

    let action = ton_wallet
        .prepare_transfer(
            &account_stuff,
            &public_key,
            destination,
            amount,
            false,
            body,
            expiration,
        )
        .handle_error(NativeStatus::TonWalletError)?;

    let message = match action {
        TransferAction::DeployFirst => {
            return Err(NativeError {
                status: NativeStatus::TonWalletError,
                info: DEPLOY_FIRST.to_owned(),
            })
        }
        TransferAction::Sign(message) => message,
    };

    let message = Mutex::new(message);
    let message = Arc::new(message);

    let message = Arc::into_raw(message) as c_ulonglong;

    Ok(message)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_prepare_confirm_transaction(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    transport: *mut c_void,
    transaction_id: c_ulonglong,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let expiration = expiration.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let transport = transport.lock().await;
        let transport = transport.clone();

        let result = internal_ton_wallet_prepare_confirm_transaction(
            &mut ton_wallet,
            transport,
            transaction_id,
            expiration,
        )
        .await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

pub async fn internal_ton_wallet_prepare_confirm_transaction(
    ton_wallet: &mut TonWallet,
    transport: Arc<GqlTransport>,
    transaction_id: u64,
    expiration: String,
) -> Result<u64, NativeError> {
    let expiration = serde_json::from_str::<Expiration>(&expiration)
        .handle_error(NativeStatus::ConversionError)?;
    let expiration = expiration.to_core();

    let address = ton_wallet.address();
    let public_key = ton_wallet.public_key();
    let public_key = public_key.clone();

    let account_state = transport
        .get_contract_state(address)
        .await
        .handle_error(NativeStatus::TonWalletError)?;
    let account_stuff = match account_state {
        RawContractState::NotExists => {
            return Err(NativeError {
                status: NativeStatus::TonWalletError,
                info: NOT_EXISTS.to_owned(),
            })
        }
        RawContractState::Exists(contract) => contract.account,
    };

    let message = ton_wallet
        .prepare_confirm_transaction(&account_stuff, &public_key, transaction_id, expiration)
        .handle_error(NativeStatus::TonWalletError)?;

    let message = Mutex::new(message);
    let message = Arc::new(message);

    let message = Arc::into_raw(message) as c_ulonglong;

    Ok(message)
}

#[no_mangle]
pub unsafe extern "C" fn prepare_add_ordinary_stake(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    transport: *mut c_void,
    expiration: *mut c_char,
    depool: *mut c_char,
    depool_fee: c_ulonglong,
    stake: c_ulonglong,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let expiration = expiration.from_ptr();
    let depool = depool.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let transport = transport.lock().await;
        let transport = transport.clone();

        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_prepare_add_ordinary_stake(
            &mut ton_wallet,
            transport,
            expiration,
            depool,
            depool_fee,
            stake,
        )
        .await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_prepare_add_ordinary_stake(
    ton_wallet: &mut TonWallet,
    transport: Arc<GqlTransport>,
    expiration: String,
    depool: String,
    depool_fee: c_ulonglong,
    stake: c_ulonglong,
) -> Result<u64, NativeError> {
    let expiration = serde_json::from_str::<Expiration>(&expiration)
        .handle_error(NativeStatus::ConversionError)?;
    let expiration = expiration.to_core();
    let depool = MsgAddressInt::from_str(&depool).handle_error(NativeStatus::ConversionError)?;

    let internal_message = nekoton_depool::prepare_add_ordinary_stake(depool, depool_fee, stake)
        .handle_error(NativeStatus::AbiError)?;

    let result = internal_ton_wallet_prepare_transfer(
        ton_wallet,
        transport,
        expiration,
        internal_message.destination,
        internal_message.amount,
        Some(internal_message.body),
    )
    .await?;

    Ok(result)
}

#[no_mangle]
pub unsafe extern "C" fn prepare_withdraw_part(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    transport: *mut c_void,
    expiration: *mut c_char,
    depool: *mut c_char,
    depool_fee: c_ulonglong,
    withdraw_value: c_ulonglong,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let expiration = expiration.from_ptr();
    let depool = depool.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let transport = transport.lock().await;
        let transport = transport.clone();

        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_prepare_withdraw_part(
            &mut ton_wallet,
            transport,
            expiration,
            depool,
            depool_fee,
            withdraw_value,
        )
        .await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_prepare_withdraw_part(
    ton_wallet: &mut TonWallet,
    transport: Arc<GqlTransport>,
    expiration: String,
    depool: String,
    depool_fee: c_ulonglong,
    withdraw_value: c_ulonglong,
) -> Result<u64, NativeError> {
    let expiration = serde_json::from_str::<Expiration>(&expiration)
        .handle_error(NativeStatus::ConversionError)?;
    let expiration = expiration.to_core();
    let depool = MsgAddressInt::from_str(&depool).handle_error(NativeStatus::ConversionError)?;

    let internal_message =
        nekoton_depool::prepare_withdraw_part(depool, depool_fee, withdraw_value)
            .handle_error(NativeStatus::AbiError)?;

    let result = internal_ton_wallet_prepare_transfer(
        ton_wallet,
        transport,
        expiration,
        internal_message.destination,
        internal_message.amount,
        Some(internal_message.body),
    )
    .await?;

    Ok(result)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_estimate_fees(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    message: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let message = message as *mut MutexUnsignedMessage;
    let message = &(*message);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_ton_wallet_estimate_fees(&mut ton_wallet, message).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_estimate_fees(
    ton_wallet: &mut TonWallet,
    message: &MutexUnsignedMessage,
) -> Result<u64, NativeError> {
    let message = message.lock().await;
    let message = dyn_clone::clone_box(&**message);

    let signature = [u8::default(); ed25519_dalek::SIGNATURE_LENGTH];

    let message = message
        .sign(&signature)
        .handle_error(NativeStatus::TonWalletError)?;
    let message = message.message;

    let fees = ton_wallet
        .estimate_fees(&message)
        .await
        .handle_error(NativeStatus::TonWalletError)?;

    Ok(fees)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_send(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    keystore: *mut c_void,
    message: *mut c_void,
    sign_input: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let keystore = keystore as *mut MutexKeyStore;
    let keystore = &(*keystore);

    let message = message as *mut MutexUnsignedMessage;
    let message = &(*message);

    let sign_input = sign_input.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
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
                *ton_wallet_guard = Some(ton_wallet);
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: KEY_STORE_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result =
            internal_ton_wallet_send(&mut ton_wallet, &mut keystore, message, sign_input).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);
        *keystore_guard = Some(keystore);

        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_send(
    ton_wallet: &mut TonWallet,
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

    let pending_transaction = ton_wallet
        .send(&message.message, message.expire_at)
        .await
        .handle_error(NativeStatus::TonWalletError)?;

    let pending_transaction =
        serde_json::to_string(&pending_transaction).handle_error(NativeStatus::ConversionError)?;

    Ok(pending_transaction.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_refresh(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_ton_wallet_refresh(&mut ton_wallet).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_refresh(ton_wallet: &mut TonWallet) -> Result<u64, NativeError> {
    let _ = ton_wallet
        .refresh()
        .await
        .handle_error(NativeStatus::TonWalletError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_preload_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    from: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let from = from.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_ton_wallet_preload_transactions(&mut ton_wallet, from).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_preload_transactions(
    ton_wallet: &mut TonWallet,
    from: String,
) -> Result<u64, NativeError> {
    let from =
        serde_json::from_str::<TransactionId>(&from).handle_error(NativeStatus::ConversionError)?;

    let _ = ton_wallet
        .preload_transactions(from)
        .await
        .handle_error(NativeStatus::TonWalletError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_handle_block(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    transport: *mut c_void,
    id: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    let ton_wallet = &(*ton_wallet);

    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let id = id.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut ton_wallet_guard = ton_wallet.lock().await;
        let ton_wallet = ton_wallet_guard.take();
        let mut ton_wallet = match ton_wallet {
            Some(ton_wallet) => ton_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TON_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let transport = transport.lock().await;
        let transport = transport.clone();

        let result = internal_ton_wallet_handle_block(&mut ton_wallet, transport, id).await;
        let result = match_result(result);

        *ton_wallet_guard = Some(ton_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_ton_wallet_handle_block(
    ton_wallet: &mut TonWallet,
    transport: Arc<GqlTransport>,
    id: String,
) -> Result<u64, NativeError> {
    let block = transport
        .get_block(&id)
        .await
        .handle_error(NativeStatus::TransportError)?;

    let _ = ton_wallet
        .handle_block(&block)
        .await
        .handle_error(NativeStatus::TonWalletError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn free_ton_wallet(ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet as *mut MutexTonWallet;
    Arc::from_raw(ton_wallet);
}
