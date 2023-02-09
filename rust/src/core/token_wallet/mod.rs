mod handler;
pub(crate) mod models;

use std::{
    os::raw::{c_char, c_int, c_longlong, c_uint, c_void},
    str::FromStr,
    sync::Arc,
};

use allo_isolate::Isolate;
use nekoton::{
    core::{
        models::TransferRecipient,
        token_wallet::{self, TokenWallet},
    },
    transport::Transport,
};
use nekoton_abi::{create_boc_or_comment_payload, num_bigint::BigUint, TransactionId};
use tokio::sync::RwLock;
use ton_block::{Block, Deserializable};

use crate::{
    clock,
    core::token_wallet::handler::TokenWalletSubscriptionHandlerImpl,
    models::{
        HandleError, MatchResult, PostWithResult, ToOptionalStringFromPtr, ToPtrAddress,
        ToSerializable,
    },
    parse_address, runtime,
    transport::match_transport,
    ToStringFromPtr, CLOCK, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_subscribe(
    result_port: c_longlong,
    on_balance_changed_port: c_longlong,
    on_transactions_found_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    owner: *mut c_char,
    root_token_contract: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let owner = owner.to_string_from_ptr();
    let root_token_contract = root_token_contract.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            on_balance_changed_port: i64,
            on_transactions_found_port: i64,
            transport: Arc<dyn Transport>,
            owner: String,
            root_token_contract: String,
        ) -> Result<serde_json::Value, String> {
            let owner = parse_address(&owner)?;

            let root_token_contract = parse_address(&root_token_contract)?;

            let handler = Arc::new(TokenWalletSubscriptionHandlerImpl::new(
                on_balance_changed_port,
                on_transactions_found_port,
            ));

            let token_wallet = TokenWallet::subscribe(
                clock!().clone(),
                transport,
                owner,
                root_token_contract,
                handler,
            )
                .await
                .handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(token_wallet))));

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
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

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_owner(result_port: c_longlong, token_wallet: *mut c_void) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    runtime!().spawn(async move {
        fn internal_fn(token_wallet: &TokenWallet) -> Result<serde_json::Value, String> {
            let owner = token_wallet.owner().to_string();

            serde_json::to_value(owner).handle_error()
        }

        let token_wallet = token_wallet.read().await;

        let result = internal_fn(&token_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_address(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    runtime!().spawn(async move {
        fn internal_fn(token_wallet: &TokenWallet) -> Result<serde_json::Value, String> {
            let address = token_wallet.address().to_string();

            serde_json::to_value(address).handle_error()
        }

        let token_wallet = token_wallet.read().await;

        let result = internal_fn(&token_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_symbol(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    runtime!().spawn(async move {
        fn internal_fn(token_wallet: &TokenWallet) -> Result<serde_json::Value, String> {
            let symbol = token_wallet.symbol();

            serde_json::to_value(symbol).handle_error()
        }

        let token_wallet = token_wallet.read().await;

        let result = internal_fn(&token_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_version(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    runtime!().spawn(async move {
        fn internal_fn(token_wallet: &TokenWallet) -> Result<serde_json::Value, String> {
            let version = token_wallet.version();

            serde_json::to_value(version).handle_error()
        }

        let token_wallet = token_wallet.read().await;

        let result = internal_fn(&token_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_balance(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    runtime!().spawn(async move {
        fn internal_fn(token_wallet: &TokenWallet) -> Result<serde_json::Value, String> {
            let balance = token_wallet.balance().to_string();

            serde_json::to_value(balance).handle_error()
        }

        let token_wallet = token_wallet.read().await;

        let result = internal_fn(&token_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_contract_state(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    runtime!().spawn(async move {
        fn internal_fn(token_wallet: &TokenWallet) -> Result<serde_json::Value, String> {
            let contract_state = token_wallet.contract_state();

            serde_json::to_value(contract_state).handle_error()
        }

        let token_wallet = token_wallet.read().await;

        let result = internal_fn(&token_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_prepare_transfer(
    result_port: c_longlong,
    token_wallet: *mut c_void,
    destination: *mut c_char,
    tokens: *mut c_char,
    notify_receiver: c_uint,
    payload: *mut c_char,
    attached_amount: *mut c_char,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    let destination = destination.to_string_from_ptr();
    let tokens = tokens.to_string_from_ptr();
    let notify_receiver = notify_receiver != 0;
    let payload = payload.to_optional_string_from_ptr();
    let attached_amount = attached_amount.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            token_wallet: &TokenWallet,
            destination: String,
            tokens: String,
            notify_receiver: bool,
            payload: Option<String>,
            attached_amount: String,
        ) -> Result<serde_json::Value, String> {
            let destination = parse_address(&destination)?;

            let destination = TransferRecipient::OwnerWallet(destination);

            let tokens = BigUint::from_str(&tokens).handle_error()?;
            let attached_amount = attached_amount.parse().handle_error()?;

            let payload = match payload {
                Some(payload) => create_boc_or_comment_payload(&payload)
                    .handle_error()?
                    .into_cell(),
                None => ton_types::Cell::default(),
            };

            let internal_message = token_wallet
                .prepare_transfer(destination, tokens, notify_receiver, payload, attached_amount)
                .handle_error()
                .map(|e| e.to_serializable())?;

            serde_json::to_value(internal_message).handle_error()
        }

        let token_wallet = token_wallet.read().await;

        let result = internal_fn(&token_wallet, destination, tokens, notify_receiver, payload, attached_amount)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_refresh(
    result_port: c_longlong,
    token_wallet: *mut c_void,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    runtime!().spawn(async move {
        async fn internal_fn(token_wallet: &mut TokenWallet) -> Result<serde_json::Value, String> {
            token_wallet.refresh().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut token_wallet = token_wallet.write().await;

        let result = internal_fn(&mut token_wallet).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_preload_transactions(
    result_port: c_longlong,
    token_wallet: *mut c_void,
    from: *mut c_char,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    let from = from.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            token_wallet: &mut TokenWallet,
            from: String,
        ) -> Result<serde_json::Value, String> {
            let from = serde_json::from_str::<TransactionId>(&from).handle_error()?;

            token_wallet
                .preload_transactions(from.lt)
                .await
                .handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut token_wallet = token_wallet.write().await;

        let result = internal_fn(&mut token_wallet, from).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_handle_block(
    result_port: c_longlong,
    token_wallet: *mut c_void,
    block: *mut c_char,
) {
    let token_wallet = token_wallet_from_ptr(token_wallet);

    let block = block.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            token_wallet: &mut TokenWallet,
            block: String,
        ) -> Result<serde_json::Value, String> {
            let block = Block::construct_from_base64(&block).handle_error()?;

            token_wallet.handle_block(&block).await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut token_wallet = token_wallet.write().await;

        let result = internal_fn(&mut token_wallet, block).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_token_root_details(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    root_token_contract: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let root_token_contract = root_token_contract.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            root_token_contract: String,
        ) -> Result<serde_json::Value, String> {
            let root_token_contract = parse_address(&root_token_contract)?;

            let token_root_details = token_wallet::get_token_root_details(
                clock!().as_ref(),
                transport.as_ref(),
                &root_token_contract,
            )
                .await
                .handle_error()?;

            serde_json::to_value(token_root_details).handle_error()
        }

        let result = internal_fn(transport, root_token_contract)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_token_wallet_details(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    token_wallet: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let token_wallet = token_wallet.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            token_wallet: String,
        ) -> Result<serde_json::Value, String> {
            let token_wallet = parse_address(&token_wallet)?;

            let details = token_wallet::get_token_wallet_details(
                clock!().as_ref(),
                transport.as_ref(),
                &token_wallet,
            )
                .await
                .handle_error()?;

            serde_json::to_value(details).handle_error()
        }

        let result = internal_fn(transport, token_wallet).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_token_root_details_from_token_wallet(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    token_wallet_address: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let token_wallet_address = token_wallet_address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            token_wallet_address: String,
        ) -> Result<serde_json::Value, String> {
            let token_wallet_address = parse_address(&token_wallet_address)?;

            let details = token_wallet::get_token_root_details_from_token_wallet(
                clock!().as_ref(),
                transport.as_ref(),
                &token_wallet_address,
            )
                .await
                .handle_error()?;

            let details = (details.0.to_string(), details.1);

            serde_json::to_value(details).handle_error()
        }

        let result = internal_fn(transport, token_wallet_address)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<RwLock<TokenWallet>>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_token_wallet_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<RwLock<TokenWallet>>);
}

unsafe fn token_wallet_from_ptr(ptr: *mut c_void) -> Arc<RwLock<TokenWallet>> {
    Arc::from_raw(ptr as *mut RwLock<TokenWallet>)
}
