mod handler;
pub(crate) mod models;

use std::{
    ffi::{c_char, c_int, c_longlong, c_schar, c_uchar, c_uint, c_void},
    sync::Arc,
};

use nekoton::{
    core::ton_wallet::{self, TonWallet, TransferAction},
    transport::Transport,
};
use nekoton_abi::{create_boc_or_comment_payload, TransactionId};
use tokio::sync::RwLock;
use ton_block::{Block, Deserializable};

use crate::{
    core::{
        models::Expiration,
        ton_wallet::{
            handler::TonWalletSubscriptionHandlerImpl,
            models::{ExistingWalletInfo, WalletType},
        },
    },
    crypto::models::SignedMessage,
    models::{HandleError, MatchResult, ToNekoton, ToOptionalStringFromPtr, ToSerializable},
    parse_address, parse_public_key, runtime, send_to_result_port,
    transport::{match_transport, models::RawContractState},
    ToCStringPtr, ToStringFromPtr, CLOCK, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_subscribe(
    result_port: c_longlong,
    on_message_sent_port: c_longlong,
    on_message_expired_port: c_longlong,
    on_state_changed_port: c_longlong,
    on_transactions_found_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    workchain: c_schar,
    public_key: *mut c_char,
    contract: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let public_key = public_key.to_string_from_ptr();
    let contract = contract.to_string_from_ptr();

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
        ) -> Result<u64, String> {
            let public_key = parse_public_key(&public_key)?;

            let contract = serde_json::from_str::<WalletType>(&contract)
                .handle_error()?
                .to_nekoton();

            let handler = Arc::new(TonWalletSubscriptionHandlerImpl::new(
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            ));

            let ton_wallet = TonWallet::subscribe(
                CLOCK.clone(),
                transport,
                workchain,
                public_key,
                contract,
                handler,
            )
            .await
            .handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(ton_wallet)))) as u64;

            Ok(ptr)
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

        send_to_result_port(result_port, result);
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
    transport_type: c_int,
    address: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            on_message_sent_port: i64,
            on_message_expired_port: i64,
            on_state_changed_port: i64,
            on_transactions_found_port: i64,
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let handler = Arc::new(TonWalletSubscriptionHandlerImpl::new(
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            ));

            let ton_wallet =
                TonWallet::subscribe_by_address(CLOCK.clone(), transport, address, handler)
                    .await
                    .handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(ton_wallet)))) as u64;

            Ok(ptr)
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

        send_to_result_port(result_port, result);
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
    transport_type: c_int,
    existing_wallet: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let existing_wallet = existing_wallet.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            on_message_sent_port: i64,
            on_message_expired_port: i64,
            on_state_changed_port: i64,
            on_transactions_found_port: i64,
            transport: Arc<dyn Transport>,
            existing_wallet: String,
        ) -> Result<u64, String> {
            let existing_wallet = serde_json::from_str::<ExistingWalletInfo>(&existing_wallet)
                .handle_error()?
                .to_nekoton();

            let handler = Arc::new(TonWalletSubscriptionHandlerImpl::new(
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            ));

            let ton_wallet = TonWallet::subscribe_by_existing(
                CLOCK.clone(),
                transport,
                existing_wallet,
                handler,
            )
            .await
            .handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(ton_wallet)))) as u64;

            Ok(ptr)
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

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_workchain(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let workchain = ton_wallet.workchain() as u64;

            Ok(workchain)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_address(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let address = ton_wallet.address().to_string().to_cstring_ptr() as u64;

            Ok(address)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_public_key(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let public_key = ton_wallet.public_key();

            let public_key = hex::encode(public_key.to_bytes()).to_cstring_ptr() as u64;

            Ok(public_key)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_wallet_type(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let contract = ton_wallet.wallet_type().to_serializable();

            let contract = serde_json::to_string(&contract)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(contract)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_contract_state(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let contract_state = ton_wallet.contract_state();

            let contract_state = serde_json::to_string(&contract_state)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(contract_state)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_pending_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let pending_transactions = ton_wallet.pending_transactions();

            let pending_transactions = serde_json::to_string(pending_transactions)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(pending_transactions)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_polling_method(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let polling_method = ton_wallet.polling_method();

            let polling_method = serde_json::to_string(&polling_method)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(polling_method)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_details(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let details = ton_wallet.details();

            let details = serde_json::to_string(&details)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(details)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_unconfirmed_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let unconfirmed_transactions = ton_wallet.get_unconfirmed_transactions();

            let unconfirmed_transactions = serde_json::to_string(&unconfirmed_transactions)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(unconfirmed_transactions)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_custodians(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet) -> Result<u64, String> {
            let custodians = ton_wallet
                .get_custodians()
                .to_owned()
                .map(|e| e.iter().map(|e| e.to_hex_string()).collect::<Vec<_>>());

            let custodians = serde_json::to_string(&custodians)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(custodians)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_prepare_deploy(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    let expiration = expiration.to_string_from_ptr();

    runtime!().spawn(async move {
        fn internal_fn(ton_wallet: &TonWallet, expiration: String) -> Result<u64, String> {
            let expiration = serde_json::from_str::<Expiration>(&expiration)
                .handle_error()?
                .to_nekoton();

            let unsigned_message = ton_wallet.prepare_deploy(expiration).handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(unsigned_message)))) as u64;

            Ok(ptr)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet, expiration).match_result();

        send_to_result_port(result_port, result);
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
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    let expiration = expiration.to_string_from_ptr();
    let custodians = custodians.to_string_from_ptr();

    runtime!().spawn(async move {
        fn internal_fn(
            ton_wallet: &TonWallet,
            expiration: String,
            custodians: String,
            req_confirms: u8,
        ) -> Result<u64, String> {
            let expiration = serde_json::from_str::<Expiration>(&expiration)
                .handle_error()?
                .to_nekoton();

            let custodians = serde_json::from_str::<Vec<&str>>(&custodians)
                .handle_error()?
                .into_iter()
                .map(parse_public_key)
                .collect::<Result<Vec<_>, String>>()?;

            let unsigned_message = ton_wallet
                .prepare_deploy_with_multiple_owners(expiration, &custodians, req_confirms)
                .handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(unsigned_message)))) as u64;

            Ok(ptr)
        }

        let ton_wallet = ton_wallet.read().await;

        let result = internal_fn(&ton_wallet, expiration, custodians, req_confirms).match_result();

        send_to_result_port(result_port, result);
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
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

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
        ) -> Result<u64, String> {
            let contract_state = serde_json::from_str::<RawContractState>(&contract_state)
                .handle_error()?
                .to_nekoton();

            let current_state = match contract_state {
                nekoton::transport::models::RawContractState::NotExists => {
                    return Err("Not exists").handle_error()
                }
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

            let expiration = serde_json::from_str::<Expiration>(&expiration)
                .handle_error()?
                .to_nekoton();

            let action = ton_wallet
                .prepare_transfer(
                    &current_state,
                    &public_key,
                    destination,
                    amount,
                    bounce,
                    body,
                    expiration,
                )
                .handle_error()?;

            let unsigned_message = match action {
                TransferAction::DeployFirst => return Err("Deploy first").handle_error(),
                TransferAction::Sign(unsigned_message) => unsigned_message,
            };

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(unsigned_message)))) as u64;

            Ok(ptr)
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

        send_to_result_port(result_port, result);
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
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

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
        ) -> Result<u64, String> {
            let contract_state = serde_json::from_str::<RawContractState>(&contract_state)
                .handle_error()?
                .to_nekoton();

            let current_state = match contract_state {
                nekoton::transport::models::RawContractState::NotExists => {
                    return Err("Not exists").handle_error()
                }
                nekoton::transport::models::RawContractState::Exists(contract) => contract.account,
            };

            let public_key = parse_public_key(&public_key)?;

            let transaction_id = transaction_id.parse::<u64>().handle_error()?;

            let expiration = serde_json::from_str::<Expiration>(&expiration)
                .handle_error()?
                .to_nekoton();

            let unsigned_message = ton_wallet
                .prepare_confirm_transaction(
                    &current_state,
                    &public_key,
                    transaction_id,
                    expiration,
                )
                .handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(unsigned_message)))) as u64;

            Ok(ptr)
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

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_estimate_fees(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    signed_message: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    let signed_message = signed_message.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            signed_message: String,
        ) -> Result<u64, String> {
            let message = serde_json::from_str::<SignedMessage>(&signed_message)
                .handle_error()?
                .to_nekoton()
                .message;

            let fees = ton_wallet
                .estimate_fees(&message)
                .await
                .handle_error()?
                .to_string()
                .to_cstring_ptr() as u64;

            Ok(fees)
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet, signed_message)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_send(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    signed_message: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    let signed_message = signed_message.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            signed_message: String,
        ) -> Result<u64, String> {
            let signed_message = serde_json::from_str::<SignedMessage>(&signed_message)
                .handle_error()?
                .to_nekoton();

            let pending_transaction = ton_wallet
                .send(&signed_message.message, signed_message.expire_at)
                .await
                .handle_error()?;

            let pending_transaction = serde_json::to_string(&pending_transaction)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(pending_transaction)
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet, signed_message)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_refresh(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            ton_wallet.refresh().await.handle_error()?;

            Ok(u64::default())
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_preload_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    from: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    let from = from.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet, from: String) -> Result<u64, String> {
            let from = serde_json::from_str::<TransactionId>(&from).handle_error()?;

            ton_wallet.preload_transactions(from).await.handle_error()?;

            Ok(u64::default())
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet, from).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_handle_block(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    block: *mut c_char,
) {
    let ton_wallet = ton_wallet_from_ptr(ton_wallet);

    let block = block.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet, block: String) -> Result<u64, String> {
            let block = Block::construct_from_base64(&block).handle_error()?;

            ton_wallet.handle_block(&block).await.handle_error()?;

            Ok(u64::default())
        }

        let mut ton_wallet = ton_wallet.write().await;

        let result = internal_fn(&mut ton_wallet, block).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_find_existing_wallets(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    public_key: *mut c_char,
    workchain_id: c_schar,
    wallet_types: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let public_key = public_key.to_string_from_ptr();
    let wallet_types = wallet_types.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            public_key: String,
            workchain_id: i8,
            wallet_types: String,
        ) -> Result<u64, String> {
            let public_key = parse_public_key(&public_key)?;

            let wallet_types = serde_json::from_str::<Vec<WalletType>>(&wallet_types)
                .handle_error()?
                .into_iter()
                .map(|e| e.to_nekoton())
                .collect::<Vec<_>>();

            let existing_wallets = ton_wallet::find_existing_wallets(
                transport.as_ref(),
                &public_key,
                workchain_id,
                &wallet_types,
            )
            .await
            .handle_error()?
            .into_iter()
            .map(|e| e.to_serializable())
            .collect::<Vec<_>>();

            let existing_wallets = serde_json::to_string(&existing_wallets)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(existing_wallets)
        }

        let result = internal_fn(transport, public_key, workchain_id, wallet_types)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_existing_wallet_info(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    address: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let raw_contract_state = transport
                .get_contract_state(&address)
                .await
                .handle_error()?;

            let existing_contract = match raw_contract_state {
                nekoton::transport::models::RawContractState::Exists(state) => state,
                nekoton::transport::models::RawContractState::NotExists => {
                    return Err("Account not exists").handle_error();
                }
            };

            let (public_key, wallet_type) =
                ton_wallet::extract_wallet_init_data(&existing_contract).handle_error()?;

            let existing_wallet_info = ExistingWalletInfo {
                address: existing_contract.account.addr.to_owned(),
                public_key,
                wallet_type: wallet_type.to_serializable(),
                contract_state: existing_contract.brief(),
            };

            let existing_wallet_info = serde_json::to_string(&existing_wallet_info)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(existing_wallet_info)
        }

        let result = internal_fn(transport, address).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_get_wallet_custodians(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    address: *mut c_char,
) {
    let transport = match_transport(transport, transport_type);

    let address = address.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let raw_contract_state = transport
                .get_contract_state(&address)
                .await
                .handle_error()?;

            let existing_contract = match raw_contract_state {
                nekoton::transport::models::RawContractState::Exists(state) => state,
                nekoton::transport::models::RawContractState::NotExists => {
                    return Err("Account not exists").handle_error();
                }
            };

            let (public_key, wallet_type) =
                ton_wallet::extract_wallet_init_data(&existing_contract).handle_error()?;

            let custodians = ton_wallet::get_wallet_custodians(
                CLOCK.as_ref(),
                &existing_contract,
                &public_key,
                wallet_type,
            )
            .handle_error()?
            .into_iter()
            .map(|e| e.to_hex_string())
            .collect::<Vec<_>>();

            let custodians = serde_json::to_string(&custodians)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(custodians)
        }

        let result = internal_fn(transport, address).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<RwLock<TonWallet>>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_ton_wallet_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<RwLock<TonWallet>>);
}

unsafe fn ton_wallet_from_ptr(ptr: *mut c_void) -> Arc<RwLock<TonWallet>> {
    Arc::from_raw(ptr as *mut RwLock<TonWallet>)
}
