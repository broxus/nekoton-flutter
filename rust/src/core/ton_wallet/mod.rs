mod handler;
pub mod models;

use std::{
    os::raw::{c_char, c_longlong, c_schar, c_uchar, c_uint, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
use nekoton::{
    core::{
        models::{Expiration, MessageFlags},
        ton_wallet::{
            extract_wallet_init_data, find_existing_wallets, get_wallet_custodians,
            ExistingWalletInfo, Gift, TonWallet, TransferAction,
        },
    },
    crypto::SignedMessage,
    transport::Transport,
};
use nekoton_abi::create_boc_or_comment_payload;
use tokio::sync::RwLock;
use ton_block::{Block, Deserializable};

use crate::{
    clock,
    core::ton_wallet::{
        handler::TonWalletSubscriptionHandlerImpl,
        models::{ExistingWalletInfoHelper, WalletTypeHelper},
    },
    crypto::unsigned_message_new,
    ffi_box, parse_address, parse_public_key, runtime,
    transport::{match_transport, models::RawContractStateHelper},
    HandleError, MatchResult, PostWithResult, ToOptionalStringFromPtr, ToPtrAddress,
    ToStringFromPtr, CLOCK, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_subscribe(
    result_port: c_longlong,
    on_message_sent_port: c_longlong,
    on_message_expired_port: c_longlong,
    on_state_changed_port: c_longlong,
    on_transactions_found_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
    workchain: c_schar,
    public_key: *mut c_char,
    contract: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let public_key = public_key.to_string_from_ptr();
    let contract = contract.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type); // todo: can be reason of crash

    runtime!().spawn(async move {
        async fn internal_fn(
            on_message_sent_port: i64,
            on_message_expired_port: i64,
            on_state_changed_port: i64,
            on_transactions_found_port: i64,
            transport: Arc<dyn Transport>,
            workchain: i8,
            public_key: String,
            contract: String,
        ) -> Result<serde_json::Value, String> {
            let public_key = parse_public_key(&public_key)?;

            let contract = serde_json::from_str::<WalletTypeHelper>(&contract)
                .map(|WalletTypeHelper(wallet_type)| wallet_type)
                .handle_error()?;

            let handler = Arc::new(TonWalletSubscriptionHandlerImpl::new(
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            ));

            let ton_wallet = TonWallet::subscribe(
                clock!(),
                transport,
                workchain,
                public_key,
                contract,
                handler,
            )
            .await
            .handle_error()?;

            let ptr = ton_wallet_new(Arc::new(RwLock::new(ton_wallet)));
            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let result = internal_fn(
            on_message_sent_port,
            on_message_expired_port,
            on_state_changed_port,
            on_transactions_found_port,
            transport,
            workchain,
            public_key,
            contract,
        )
        .await
        .match_result();

        log::debug!("nt_ton_wallet_subscribe {}", result.to_ptr_address());

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_subscribe_by_address(
    result_port: c_longlong,
    on_message_sent_port: c_longlong,
    on_message_expired_port: c_longlong,
    on_state_changed_port: c_longlong,
    on_transactions_found_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
    address: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let address = address.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(
            on_message_sent_port: i64,
            on_message_expired_port: i64,
            on_state_changed_port: i64,
            on_transactions_found_port: i64,
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let handler = Arc::new(TonWalletSubscriptionHandlerImpl::new(
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            ));

            let ton_wallet = TonWallet::subscribe_by_address(clock!(), transport, address, handler)
                .await
                .handle_error()?;

            let ptr = ton_wallet_new(Arc::new(RwLock::new(ton_wallet)));

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let result = internal_fn(
            on_message_sent_port,
            on_message_expired_port,
            on_state_changed_port,
            on_transactions_found_port,
            transport,
            address,
        )
        .await
        .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_subscribe_by_existing(
    result_port: c_longlong,
    on_message_sent_port: c_longlong,
    on_message_expired_port: c_longlong,
    on_state_changed_port: c_longlong,
    on_transactions_found_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
    existing_wallet: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let existing_wallet = existing_wallet.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(
            on_message_sent_port: i64,
            on_message_expired_port: i64,
            on_state_changed_port: i64,
            on_transactions_found_port: i64,
            transport: Arc<dyn Transport>,
            existing_wallet: String,
        ) -> Result<serde_json::Value, String> {
            let existing_wallet =
                serde_json::from_str::<ExistingWalletInfoHelper>(&existing_wallet)
                    .map(|ExistingWalletInfoHelper(existing_wallet_info)| existing_wallet_info)
                    .handle_error()?;

            let handler = Arc::new(TonWalletSubscriptionHandlerImpl::new(
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            ));

            let ton_wallet =
                TonWallet::subscribe_by_existing(clock!(), transport, existing_wallet, handler)
                    .await
                    .handle_error()?;

            let ptr = ton_wallet_new(Arc::new(RwLock::new(ton_wallet)));

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let result = internal_fn(
            on_message_sent_port,
            on_message_expired_port,
            on_state_changed_port,
            on_transactions_found_port,
            transport,
            existing_wallet,
        )
        .await
        .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_workchain(result_port: c_longlong, ton_wallet: *mut c_void) {
    log::debug!("nt_ton_wallet_workchain {}", ton_wallet.to_ptr_address());
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let workchain = ton_wallet.workchain();

            serde_json::to_value(workchain).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_address(result_port: c_longlong, ton_wallet: *mut c_void) {
    log::debug!("nt_ton_wallet_address {}", ton_wallet.to_ptr_address());
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let address = ton_wallet.address().to_string();

            serde_json::to_value(address).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_public_key(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let public_key = ton_wallet.public_key();

            let public_key = hex::encode(public_key.to_bytes());

            serde_json::to_value(public_key).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_wallet_type(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let contract = ton_wallet.wallet_type();

            serde_json::to_value(WalletTypeHelper(contract)).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_contract_state(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let contract_state = ton_wallet.contract_state();

            serde_json::to_value(contract_state).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_pending_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let pending_transactions = ton_wallet.pending_transactions();

            serde_json::to_value(pending_transactions).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_polling_method(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let polling_method = ton_wallet.polling_method();

            serde_json::to_value(polling_method).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_details(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let details = ton_wallet.details();

            serde_json::to_value(details).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_unconfirmed_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let unconfirmed_transactions = ton_wallet.get_unconfirmed_transactions();

            serde_json::to_value(unconfirmed_transactions).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_custodians(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<serde_json::Value, String> {
            let custodians = ton_wallet
                .get_custodians()
                .to_owned()
                .map(|e| e.iter().map(|e| e.to_hex_string()).collect::<Vec<_>>());

            serde_json::to_value(custodians).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_prepare_deploy(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    let expiration = expiration.to_string_from_ptr();

    runtime!().spawn(async move {
        fn internal_fn(
            ton_wallet: &TonWallet,
            expiration: String,
        ) -> Result<serde_json::Value, String> {
            let expiration = serde_json::from_str::<Expiration>(&expiration).handle_error()?;

            let unsigned_message = ton_wallet.prepare_deploy(expiration).handle_error()?;

            let ptr = unsigned_message_new(Arc::new(RwLock::new(unsigned_message)));

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet, expiration).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_prepare_deploy_with_multiple_owners(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    expiration: *mut c_char,
    custodians: *mut c_char,
    req_confirms: c_uchar,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    let expiration = expiration.to_string_from_ptr();
    let custodians = custodians.to_string_from_ptr();

    runtime!().spawn(async move {
        fn internal_fn(
            ton_wallet: &TonWallet,
            expiration: String,
            custodians: String,
            req_confirms: u8,
        ) -> Result<serde_json::Value, String> {
            let expiration = serde_json::from_str::<Expiration>(&expiration).handle_error()?;

            let custodians = serde_json::from_str::<Vec<&str>>(&custodians)
                .handle_error()?
                .into_iter()
                .map(parse_public_key)
                .collect::<Result<Vec<_>, String>>()?;

            let unsigned_message = ton_wallet
                .prepare_deploy_with_multiple_owners(expiration, &custodians, req_confirms, None)
                .handle_error()?;

            let ptr = unsigned_message_new(Arc::new(RwLock::new(unsigned_message)));

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet, expiration, custodians, req_confirms).match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_prepare_transfer(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    contract_state: *mut c_char,
    public_key: *mut c_char,
    destination: *mut c_char,
    amount: *mut c_char,
    bounce: c_uint,
    body: *mut c_char,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    let contract_state = contract_state.to_string_from_ptr();
    let public_key = public_key.to_string_from_ptr();
    let destination = destination.to_string_from_ptr();
    let amount = amount.to_string_from_ptr();
    let body = body.to_optional_string_from_ptr();
    let expiration = expiration.to_string_from_ptr();

    runtime!().spawn(async move {
        fn internal_fn(
            ton_wallet: &mut TonWallet,
            contract_state: String,
            public_key: String,
            destination: String,
            amount: String,
            bounce: u32,
            body: Option<String>,
            expiration: String,
        ) -> Result<serde_json::Value, String> {
            let contract_state = serde_json::from_str::<RawContractStateHelper>(&contract_state)
                .map(|RawContractStateHelper(raw_contract_state)| raw_contract_state)
                .handle_error()?;

            let current_state = match contract_state {
                nekoton::transport::models::RawContractState::NotExists => {
                    return Err("Not exists").handle_error();
                },
                nekoton::transport::models::RawContractState::Exists(contract) => contract.account,
            };

            let public_key = parse_public_key(&public_key)?;

            let destination = parse_address(&destination)?;

            let amount = amount.parse::<u64>().handle_error()?;

            let bounce = bounce != 0;

            let body = body
                .map(|e| create_boc_or_comment_payload(&e))
                .transpose()
                .handle_error()?;

            let expiration = serde_json::from_str::<Expiration>(&expiration).handle_error()?;

            let gift = Gift {
                flags: MessageFlags::default().into(),
                bounce,
                destination,
                amount,
                body,
                state_init: None,
            };

            let action = ton_wallet
                .prepare_transfer(&current_state, &public_key, gift, expiration)
                .handle_error()?;

            let unsigned_message = match action {
                TransferAction::DeployFirst => return Err("Deploy first").handle_error(),
                TransferAction::Sign(unsigned_message) => unsigned_message,
            };

            let ptr = unsigned_message_new(Arc::new(RwLock::new(unsigned_message)));

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(
            &mut ton_wallet,
            contract_state,
            public_key,
            destination,
            amount,
            bounce,
            body,
            expiration,
        )
        .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_prepare_confirm_transaction(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    contract_state: *mut c_char,
    public_key: *mut c_char,
    transaction_id: *mut c_char,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    let contract_state = contract_state.to_string_from_ptr();
    let public_key = public_key.to_string_from_ptr();
    let transaction_id = transaction_id.to_string_from_ptr();
    let expiration = expiration.to_string_from_ptr();

    runtime!().spawn(async move {
        fn internal_fn(
            ton_wallet: &TonWallet,
            contract_state: String,
            public_key: String,
            transaction_id: String,
            expiration: String,
        ) -> Result<serde_json::Value, String> {
            let contract_state = serde_json::from_str::<RawContractStateHelper>(&contract_state)
                .map(|RawContractStateHelper(raw_contract_state)| raw_contract_state)
                .handle_error()?;

            let current_state = match contract_state {
                nekoton::transport::models::RawContractState::NotExists => {
                    return Err("Not exists").handle_error();
                },
                nekoton::transport::models::RawContractState::Exists(contract) => contract.account,
            };

            let public_key = parse_public_key(&public_key)?;

            let transaction_id = transaction_id.parse::<u64>().handle_error()?;

            let expiration = serde_json::from_str::<Expiration>(&expiration).handle_error()?;

            let unsigned_message = ton_wallet
                .prepare_confirm_transaction(
                    &current_state,
                    &public_key,
                    transaction_id,
                    expiration,
                )
                .handle_error()?;

            let ptr = unsigned_message_new(Arc::new(RwLock::new(unsigned_message)));

            serde_json::to_value(ptr.to_ptr_address()).handle_error()
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(
            &ton_wallet,
            contract_state,
            public_key,
            transaction_id,
            expiration,
        )
        .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_estimate_fees(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    signed_message: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    let signed_message = signed_message.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            signed_message: String,
        ) -> Result<serde_json::Value, String> {
            let message = serde_json::from_str::<SignedMessage>(&signed_message)
                .handle_error()?
                .message;

            let fees = ton_wallet
                .estimate_fees(&message)
                .await
                .handle_error()?
                .to_string();

            serde_json::to_value(fees).handle_error()
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet, signed_message)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_send(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    signed_message: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    let signed_message = signed_message.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            signed_message: String,
        ) -> Result<serde_json::Value, String> {
            let signed_message =
                serde_json::from_str::<SignedMessage>(&signed_message).handle_error()?;

            let pending_transaction = ton_wallet
                .send(&signed_message.message, signed_message.expire_at)
                .await
                .handle_error()?;

            serde_json::to_value(pending_transaction).handle_error()
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet, signed_message)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_refresh(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<serde_json::Value, String> {
            ton_wallet.refresh().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_preload_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    from_lt: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    let from_lt = from_lt.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            from_lt: String,
        ) -> Result<serde_json::Value, String> {
            let from_lt = from_lt.parse::<u64>().handle_error()?;

            ton_wallet
                .preload_transactions(from_lt)
                .await
                .handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet, from_lt).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_handle_block(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    block: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_native_ptr(ton_wallet);

    let block = block.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            block: String,
        ) -> Result<serde_json::Value, String> {
            let block = Block::construct_from_base64(&block).handle_error()?;

            ton_wallet.handle_block(&block).await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet, block).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_find_existing_wallets(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
    public_key: *mut c_char,
    workchain_id: c_schar,
    wallet_types: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let public_key = public_key.to_string_from_ptr();
    let wallet_types = wallet_types.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            public_key: String,
            workchain_id: i8,
            wallet_types: String,
        ) -> Result<serde_json::Value, String> {
            let public_key = parse_public_key(&public_key)?;

            let wallet_types = serde_json::from_str::<Vec<WalletTypeHelper>>(&wallet_types)
                .handle_error()?
                .into_iter()
                .map(|WalletTypeHelper(wallet_type)| wallet_type)
                .collect::<Vec<_>>();

            let existing_wallets =
                find_existing_wallets(transport.as_ref(), &public_key, workchain_id, &wallet_types)
                    .await
                    .handle_error()?
                    .into_iter()
                    .map(ExistingWalletInfoHelper)
                    .collect::<Vec<_>>();

            serde_json::to_value(existing_wallets).handle_error()
        }

        let result = internal_fn(transport, public_key, workchain_id, wallet_types)
            .await
            .match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_existing_wallet_info(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
    address: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let address = address.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let raw_contract_state = transport
                .get_contract_state(&address)
                .await
                .handle_error()?;

            let existing_contract = match raw_contract_state {
                nekoton::transport::models::RawContractState::Exists(state) => state,
                nekoton::transport::models::RawContractState::NotExists => {
                    return Err("Account not exists").handle_error();
                },
            };

            let (public_key, wallet_type) =
                extract_wallet_init_data(&existing_contract).handle_error()?;

            let existing_wallet_info = ExistingWalletInfo {
                address: existing_contract.account.addr.to_owned(),
                public_key,
                wallet_type,
                contract_state: existing_contract.brief(),
            };

            serde_json::to_value(ExistingWalletInfoHelper(existing_wallet_info)).handle_error()
        }

        let result = internal_fn(transport, address).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_wallet_custodians(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: *mut c_char,
    address: *mut c_char,
) {
    let transport_type = transport_type.to_string_from_ptr();
    let address = address.to_string_from_ptr();

    let transport = match_transport(transport, &transport_type);

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<serde_json::Value, String> {
            let address = parse_address(&address)?;

            let raw_contract_state = transport
                .get_contract_state(&address)
                .await
                .handle_error()?;

            let existing_contract = match raw_contract_state {
                nekoton::transport::models::RawContractState::Exists(state) => state,
                nekoton::transport::models::RawContractState::NotExists => {
                    return Err("Account not exists").handle_error();
                },
            };

            let (public_key, wallet_type) =
                extract_wallet_init_data(&existing_contract).handle_error()?;

            let custodians = get_wallet_custodians(
                clock!().as_ref(),
                &existing_contract,
                &public_key,
                wallet_type,
            )
            .handle_error()?
            .into_iter()
            .map(|e| e.to_hex_string())
            .collect::<Vec<_>>();

            serde_json::to_value(custodians).handle_error()
        }

        let result = internal_fn(transport, address).await.match_result();

        Isolate::new(result_port)
            .post_with_result(result.to_ptr_address())
            .unwrap();
    });
}

ffi_box!(ton_wallet, Arc<RwLock<TonWallet>>);

#[cfg(test)]
mod test {
    use std::sync::{Arc, RwLock};

    use nekoton::core::ton_wallet::TonWallet;

    #[test]
    fn ask_miri() {
        let ptr = Box::into_raw(Box::new(RwLock::new(String::new())));

        let ton_wallet = unsafe { &*(ptr as *mut RwLock<String>) };

        let len = ton_wallet.read().unwrap().len();

        unsafe {
            Box::from_raw(ptr as *mut RwLock<String>);
        }
    }
}
