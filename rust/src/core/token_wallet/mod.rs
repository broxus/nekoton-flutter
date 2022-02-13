pub mod handler;
pub mod models;

use crate::{
    core::token_wallet::{handler::TokenWalletSubscriptionHandlerImpl, models::MutexTokenWallet},
    match_result,
    models::{HandleError, NativeError, NativeStatus},
    parse_address, runtime, send_to_result_port,
    transport::gql_transport::{MutexGqlTransport, GQL_TRANSPORT_NOT_FOUND},
    FromPtr, ToPtr, RUNTIME,
};
use nekoton::{
    core::{models::TransferRecipient, token_wallet::TokenWallet},
    transport::gql::GqlTransport,
};
use nekoton_abi::{num_bigint::BigUint, TransactionId};
use nekoton_utils::SimpleClock;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_uint, c_ulonglong},
    str::FromStr,
    sync::Arc,
};
use tokio::sync::Mutex;

const TOKEN_WALLET_NOT_FOUND: &str = "Token wallet not found";

#[no_mangle]
pub unsafe extern "C" fn token_wallet_subscribe(
    result_port: c_longlong,
    port: c_longlong,
    transport: *mut c_void,
    owner: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let owner = owner.from_ptr();
    let root_token_contract = root_token_contract.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut transport_guard = transport.lock().await;
        let transport = transport_guard.take();
        let transport = match transport {
            Some(transport) => transport,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GQL_TRANSPORT_NOT_FOUND.to_owned(),
                }));

                send_to_result_port(result_port, result);
                return;
            }
        };

        let result =
            internal_token_wallet_subscribe(port, transport.clone(), owner, root_token_contract)
                .await;
        let result = match_result(result);

        *transport_guard = Some(transport);

        send_to_result_port(result_port, result);
    });
}

async fn internal_token_wallet_subscribe(
    port: c_longlong,
    transport: Arc<GqlTransport>,
    owner: String,
    root_token_contract: String,
) -> Result<u64, NativeError> {
    let owner = parse_address(&owner)?;
    let root_token_contract = parse_address(&root_token_contract)?;

    let handler = TokenWalletSubscriptionHandlerImpl { port: Some(port) };
    let handler = Arc::new(handler);

    let token_wallet = TokenWallet::subscribe(
        Arc::new(SimpleClock {}),
        transport,
        owner,
        root_token_contract,
        handler,
    )
    .await
    .handle_error(NativeStatus::TokenWalletError)?;

    let token_wallet = Mutex::new(Some(token_wallet));
    let token_wallet = Arc::new(token_wallet);

    let token_wallet = Arc::into_raw(token_wallet) as c_ulonglong;

    Ok(token_wallet)
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_info(
    result_port: c_longlong,
    transport: *mut c_void,
    owner: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let owner = owner.from_ptr();
    let root_token_contract = root_token_contract.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut transport_guard = transport.lock().await;
        let transport = transport_guard.take();
        let transport = match transport {
            Some(transport) => transport,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GQL_TRANSPORT_NOT_FOUND.to_owned(),
                }));

                send_to_result_port(result_port, result);
                return;
            }
        };

        let result =
            internal_get_token_wallet_info(transport.clone(), owner, root_token_contract).await;
        let result = match_result(result);

        *transport_guard = Some(transport);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_token_wallet_info(
    transport: Arc<GqlTransport>,
    owner: String,
    root_token_contract: String,
) -> Result<u64, NativeError> {
    let owner = parse_address(&owner)?;
    let root_token_contract = parse_address(&root_token_contract)?;

    let handler = TokenWalletSubscriptionHandlerImpl { port: None };
    let handler = Arc::new(handler);

    let token_wallet = TokenWallet::subscribe(
        Arc::new(SimpleClock {}),
        transport,
        owner,
        root_token_contract.clone(),
        handler,
    )
    .await
    .handle_error(NativeStatus::TokenWalletError)?;

    let owner: ton_block::MsgAddressInt = token_wallet.owner().clone();
    let address: ton_block::MsgAddressInt = token_wallet.address().clone();
    let symbol: nekoton::core::models::Symbol = token_wallet.symbol().clone();
    let version: nekoton::core::models::TokenWalletVersion = token_wallet.version();
    let balance: String = token_wallet.balance().to_string();
    let contract_state: nekoton::core::models::ContractState =
        token_wallet.contract_state().clone();

    let info = models::TokenWalletInfo {
        owner,
        address,
        symbol,
        version,
        balance,
        contract_state,
    };
    let info = serde_json::to_string(&info).handle_error(NativeStatus::ConversionError)?;

    Ok(info.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_owner(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_token_wallet_owner(&mut token_wallet).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_token_wallet_owner(
    token_wallet: &mut TokenWallet,
) -> Result<u64, NativeError> {
    let owner = token_wallet.owner();
    let owner = owner.to_string();

    Ok(owner.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_address(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_token_wallet_address(&mut token_wallet).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_token_wallet_address(
    token_wallet: &mut TokenWallet,
) -> Result<u64, NativeError> {
    let address = token_wallet.address();
    let address = address.to_string();

    Ok(address.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_symbol(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_token_wallet_symbol(&mut token_wallet).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_token_wallet_symbol(
    token_wallet: &mut TokenWallet,
) -> Result<u64, NativeError> {
    let symbol = token_wallet.symbol();
    let symbol = serde_json::to_string(&symbol).handle_error(NativeStatus::ConversionError)?;

    Ok(symbol.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_version(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_token_wallet_version(&mut token_wallet).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_token_wallet_version(
    token_wallet: &mut TokenWallet,
) -> Result<u64, NativeError> {
    let version = token_wallet.version();
    let version = serde_json::to_string(&version).handle_error(NativeStatus::ConversionError)?;

    Ok(version.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_balance(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_token_wallet_balance(&mut token_wallet).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_token_wallet_balance(
    token_wallet: &mut TokenWallet,
) -> Result<u64, NativeError> {
    let balance = token_wallet.balance();
    let balance = balance.to_string();

    Ok(balance.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_contract_state(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_token_wallet_contract_state(&mut token_wallet).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_token_wallet_contract_state(
    token_wallet: &mut TokenWallet,
) -> Result<u64, NativeError> {
    let contract_state = token_wallet.contract_state();
    let contract_state =
        serde_json::to_string(&contract_state).handle_error(NativeStatus::ConversionError)?;

    Ok(contract_state.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn token_wallet_prepare_transfer(
    result_port: c_longlong,
    token_wallet: *mut c_void,
    destination: *mut c_char,
    tokens: *mut c_char,
    notify_receiver: c_uint,
    payload: *mut c_char,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let destination = destination.from_ptr();
    let tokens = tokens.from_ptr();
    let notify_receiver = notify_receiver != 0;
    let payload = if !payload.is_null() {
        Some(payload.from_ptr())
    } else {
        None
    };

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_token_wallet_prepare_transfer(
            &mut token_wallet,
            destination,
            tokens,
            notify_receiver,
            payload,
        )
        .await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_token_wallet_prepare_transfer(
    token_wallet: &mut TokenWallet,
    destination: String,
    tokens: String,
    notify_receiver: bool,
    payload: Option<String>,
) -> Result<u64, NativeError> {
    let destination = parse_address(&destination)?;
    let destination = TransferRecipient::OwnerWallet(destination);

    let tokens = BigUint::from_str(&tokens).handle_error(NativeStatus::ConversionError)?;

    let payload = match payload {
        Some(payload) => {
            let payload = nekoton_abi::create_comment_payload(&payload)
                .handle_error(NativeStatus::AbiError)?;
            let payload = payload.into_cell();
            payload
        }
        None => ton_types::Cell::default(),
    };

    let message = token_wallet
        .prepare_transfer(destination, tokens, notify_receiver, payload)
        .handle_error(NativeStatus::TokenWalletError)?;
    let message = super::InternalMessage::from_core(message);
    let message = serde_json::to_string(&message).handle_error(NativeStatus::ConversionError)?;

    Ok(message.to_ptr() as c_ulonglong)
}

#[no_mangle]
pub unsafe extern "C" fn token_wallet_refresh(result_port: c_longlong, token_wallet: *mut c_void) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_token_wallet_refresh(&mut token_wallet).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_token_wallet_refresh(token_wallet: &mut TokenWallet) -> Result<u64, NativeError> {
    let _ = token_wallet
        .refresh()
        .await
        .handle_error(NativeStatus::TokenWalletError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn token_wallet_preload_transactions(
    result_port: c_longlong,
    token_wallet: *mut c_void,
    from: *mut c_char,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let from = from.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_token_wallet_preload_transactions(&mut token_wallet, from).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);

        send_to_result_port(result_port, result);
    });
}

async fn internal_token_wallet_preload_transactions(
    token_wallet: &mut TokenWallet,
    from: String,
) -> Result<u64, NativeError> {
    let from =
        serde_json::from_str::<TransactionId>(&from).handle_error(NativeStatus::ConversionError)?;

    let _ = token_wallet
        .preload_transactions(from)
        .await
        .handle_error(NativeStatus::TokenWalletError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn token_wallet_handle_block(
    result_port: c_longlong,
    token_wallet: *mut c_void,
    transport: *mut c_void,
    id: *mut c_char,
) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let transport = transport as *mut MutexGqlTransport;
    let transport = &(*transport);

    let id = id.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        let mut token_wallet = match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let mut transport_guard = transport.lock().await;
        let transport = transport_guard.take();
        let transport = match transport {
            Some(transport) => transport,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: GQL_TRANSPORT_NOT_FOUND.to_owned(),
                }));

                *token_wallet_guard = Some(token_wallet);

                send_to_result_port(result_port, result);
                return;
            }
        };

        let result =
            internal_token_wallet_handle_block(&mut token_wallet, transport.clone(), id).await;
        let result = match_result(result);

        *token_wallet_guard = Some(token_wallet);
        *transport_guard = Some(transport);

        send_to_result_port(result_port, result);
    });
}

async fn internal_token_wallet_handle_block(
    token_wallet: &mut TokenWallet,
    transport: Arc<GqlTransport>,
    id: String,
) -> Result<u64, NativeError> {
    let block = transport
        .get_block(&id)
        .await
        .handle_error(NativeStatus::TransportError)?;

    let _ = token_wallet
        .handle_block(&block)
        .await
        .handle_error(NativeStatus::TokenWalletError)?;

    Ok(0)
}

#[no_mangle]
pub unsafe extern "C" fn free_token_wallet(result_port: c_longlong, token_wallet: *mut c_void) {
    let token_wallet = token_wallet as *mut MutexTokenWallet;
    let token_wallet = &(*token_wallet);

    let rt = runtime!();
    rt.spawn(async move {
        let mut token_wallet_guard = token_wallet.lock().await;
        let token_wallet = token_wallet_guard.take();
        match token_wallet {
            Some(token_wallet) => token_wallet,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: TOKEN_WALLET_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = Ok(0);
        let result = match_result(result);

        send_to_result_port(result_port, result);
    });
}
