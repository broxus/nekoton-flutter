pub mod handler;
pub mod models;

use crate::{
    core::{models::InternalMessage, token_wallet::handler::TokenWalletSubscriptionHandlerImpl},
    models::{HandleError, MatchResult},
    parse_address, runtime, send_to_result_port,
    transport::models::match_transport,
    FromPtr, ToPtr, RUNTIME,
};
use nekoton::{
    core::{models::TransferRecipient, token_wallet::TokenWallet},
    transport::Transport,
};
use nekoton_abi::{create_boc_or_comment_payload, num_bigint::BigUint, TransactionId};
use nekoton_utils::SimpleClock;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_int, c_longlong, c_uint, c_ulonglong},
    str::FromStr,
    sync::Arc,
};
use tokio::sync::Mutex;

#[no_mangle]
pub unsafe extern "C" fn token_wallet_subscribe(
    result_port: c_longlong,
    on_balance_changed_port: c_longlong,
    on_transactions_found_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    owner: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let owner = owner.from_ptr();
    let root_token_contract = root_token_contract.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            on_balance_changed_port: c_longlong,
            on_transactions_found_port: c_longlong,
            transport: Arc<dyn Transport>,
            owner: String,
            root_token_contract: String,
        ) -> Result<u64, String> {
            let owner = parse_address(&owner)?;
            let root_token_contract = parse_address(&root_token_contract)?;

            let handler = TokenWalletSubscriptionHandlerImpl {
                on_balance_changed_port,
                on_transactions_found_port,
            };
            let handler = Arc::new(handler);

            let clock = Arc::new(SimpleClock {});

            let token_wallet =
                TokenWallet::subscribe(clock, transport, owner, root_token_contract, handler)
                    .await
                    .handle_error()?;

            let token_wallet = Box::new(Arc::new(Mutex::new(token_wallet)));

            let ptr = Box::into_raw(token_wallet) as c_ulonglong;

            Ok(ptr)
        }

        let result = internal_fn(
            on_balance_changed_port,
            on_transactions_found_port,
            transport,
            owner,
            root_token_contract,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn clone_token_wallet_ptr(token_wallet: *mut c_void) -> *mut c_void {
    let token_wallet = token_wallet as *mut Arc<Mutex<TokenWallet>>;
    let cloned = Arc::clone(&*token_wallet);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_token_wallet_ptr(token_wallet: *mut c_void) {
    let token_wallet = token_wallet as *mut Arc<Mutex<TokenWallet>>;

    let _ = Box::from_raw(token_wallet);
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_owner(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet) -> Result<u64, String> {
            let owner = token_wallet.owner().to_string().to_ptr() as c_ulonglong;

            Ok(owner)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(&mut token_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_address(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet) -> Result<u64, String> {
            let address = token_wallet.address().to_string().to_ptr() as c_ulonglong;

            Ok(address)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(&mut token_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_symbol(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet) -> Result<u64, String> {
            let symbol = token_wallet.symbol();
            let symbol = serde_json::to_string(&symbol).handle_error()?.to_ptr() as c_ulonglong;

            Ok(symbol)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(&mut token_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_version(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet) -> Result<u64, String> {
            let version = token_wallet.version();
            let version = serde_json::to_string(&version).handle_error()?.to_ptr() as c_ulonglong;

            Ok(version)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(&mut token_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_balance(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet) -> Result<u64, String> {
            let balance = token_wallet.balance().to_string().to_ptr() as c_ulonglong;

            Ok(balance)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(&mut token_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_token_wallet_contract_state(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet) -> Result<u64, String> {
            let contract_state = token_wallet.contract_state();
            let contract_state = serde_json::to_string(&contract_state)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(contract_state)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(&mut token_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
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
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    let destination = destination.from_ptr();
    let tokens = tokens.from_ptr();
    let notify_receiver = notify_receiver != 0;
    let payload = match !payload.is_null() {
        true => Some(payload.from_ptr()),
        false => None,
    };

    runtime!().spawn(async move {
        async fn internal_fn(
            token_wallet: &mut TokenWallet,
            destination: String,
            tokens: String,
            notify_receiver: bool,
            payload: Option<String>,
        ) -> Result<u64, String> {
            let destination = parse_address(&destination)?;
            let destination = TransferRecipient::OwnerWallet(destination);

            let tokens = BigUint::from_str(&tokens).handle_error()?;

            let payload = match payload {
                Some(payload) => create_boc_or_comment_payload(&payload)
                    .handle_error()?
                    .into_cell(),
                None => ton_types::Cell::default(),
            };

            let message = token_wallet
                .prepare_transfer(destination, tokens, notify_receiver, payload)
                .handle_error()
                .map(|e| InternalMessage::from_core(e))?;

            let message = serde_json::to_string(&message).handle_error()?.to_ptr() as c_ulonglong;

            Ok(message)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(
            &mut token_wallet,
            destination,
            tokens,
            notify_receiver,
            payload,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn token_wallet_refresh(result_port: c_longlong, token_wallet: *mut c_void) {
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet) -> Result<u64, String> {
            let _ = token_wallet.refresh().await.handle_error()?;

            Ok(0)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(&mut token_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn token_wallet_preload_transactions(
    result_port: c_longlong,
    token_wallet: *mut c_void,
    from: *mut c_char,
) {
    let token_wallet = token_wallet as *mut Mutex<TokenWallet>;
    let token_wallet = Arc::from_raw(token_wallet) as Arc<Mutex<TokenWallet>>;

    let from = from.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet, from: String) -> Result<u64, String> {
            let from = serde_json::from_str::<TransactionId>(&from).handle_error()?;

            let _ = token_wallet
                .preload_transactions(from)
                .await
                .handle_error()?;

            Ok(0)
        }

        let mut token_wallet = token_wallet.lock().await;

        let result = internal_fn(&mut token_wallet, from).await.match_result();

        send_to_result_port(result_port, result);
    });
}
