pub mod handler;
pub mod models;

use self::models::ExistingWalletInfo;
use crate::{
    core::{
        models::Expiration,
        ton_wallet::{handler::TonWalletSubscriptionHandlerImpl, models::WalletType},
    },
    crypto::{derived_key::DerivedKeySignParams, encrypted_key::EncryptedKeyPassword},
    models::{HandleError, MatchResult},
    parse_address, parse_public_key, runtime, send_to_result_port,
    transport::models::{match_transport, TransportType},
    FromPtr, ToPtr, RUNTIME,
};
use nekoton::{
    core::{
        keystore::KeyStore,
        ton_wallet::{TonWallet, TransferAction},
    },
    crypto::{DerivedKeySigner, EncryptedKeySigner, UnsignedMessage},
    transport::{gql::GqlTransport, models::RawContractState, Transport},
};
use nekoton_abi::{create_boc_or_comment_payload, TransactionId};
use nekoton_utils::SimpleClock;
use num_traits::FromPrimitive;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_int, c_longlong, c_schar, c_uchar, c_ulonglong},
    sync::Arc,
};
use tokio::sync::Mutex;

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_subscribe(
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

    let public_key = public_key.from_ptr();
    let contract = contract.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            on_message_sent_port: c_longlong,
            on_message_expired_port: c_longlong,
            on_state_changed_port: c_longlong,
            on_transactions_found_port: c_longlong,
            transport: Arc<dyn Transport>,
            workchain: i8,
            public_key: String,
            contract: String,
        ) -> Result<u64, String> {
            let public_key = parse_public_key(&public_key)?;

            let contract = serde_json::from_str::<WalletType>(&contract)
                .handle_error()?
                .to_core();

            let handler = TonWalletSubscriptionHandlerImpl {
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            };
            let handler = Arc::new(handler);

            let clock = Arc::new(SimpleClock {});

            let ton_wallet =
                TonWallet::subscribe(clock, transport, workchain, public_key, contract, handler)
                    .await
                    .handle_error()?;

            let ton_wallet = Box::new(Arc::new(Mutex::new(ton_wallet)));

            let ptr = Box::into_raw(ton_wallet) as c_ulonglong;

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
pub unsafe extern "C" fn ton_wallet_subscribe_by_address(
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

    let address = address.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            on_message_sent_port: c_longlong,
            on_message_expired_port: c_longlong,
            on_state_changed_port: c_longlong,
            on_transactions_found_port: c_longlong,
            transport: Arc<dyn Transport>,
            address: String,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let handler = TonWalletSubscriptionHandlerImpl {
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            };
            let handler = Arc::new(handler);

            let clock = Arc::new(SimpleClock {});

            let ton_wallet = TonWallet::subscribe_by_address(clock, transport, address, handler)
                .await
                .handle_error()?;

            let ton_wallet = Box::new(Arc::new(Mutex::new(ton_wallet)));

            let ptr = Box::into_raw(ton_wallet) as c_ulonglong;

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
pub unsafe extern "C" fn ton_wallet_subscribe_by_existing(
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

    let existing_wallet = existing_wallet.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            on_message_sent_port: c_longlong,
            on_message_expired_port: c_longlong,
            on_state_changed_port: c_longlong,
            on_transactions_found_port: c_longlong,
            transport: Arc<dyn Transport>,
            existing_wallet: String,
        ) -> Result<u64, String> {
            let existing_wallet =
                serde_json::from_str::<ExistingWalletInfo>(&existing_wallet).handle_error()?;

            let handler = TonWalletSubscriptionHandlerImpl {
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            };
            let handler = Arc::new(handler);

            let clock = Arc::new(SimpleClock {});

            let ton_wallet = TonWallet::subscribe_by_existing(
                clock,
                transport,
                existing_wallet.to_core(),
                handler,
            )
            .await
            .handle_error()?;

            let ton_wallet = Box::new(Arc::new(Mutex::new(ton_wallet)));

            let ptr = Box::into_raw(ton_wallet) as c_ulonglong;

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
pub unsafe extern "C" fn clone_ton_wallet_ptr(ton_wallet: *mut c_void) -> *mut c_void {
    let ton_wallet = ton_wallet as *mut Arc<Mutex<TonWallet>>;
    let cloned = Arc::clone(&*ton_wallet);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_ton_wallet_ptr(ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet as *mut Arc<Mutex<TonWallet>>;

    let _ = Box::from_raw(ton_wallet);
}

#[no_mangle]
pub unsafe extern "C" fn find_existing_wallets(
    result_port: c_longlong,
    transport: *mut c_void,
    transport_type: c_int,
    public_key: *mut c_char,
    workchain_id: c_schar,
) {
    let transport = match_transport(transport, transport_type);

    let public_key = public_key.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            transport: Arc<dyn Transport>,
            public_key: String,
            workchain_id: i8,
        ) -> Result<u64, String> {
            let public_key = parse_public_key(&public_key)?;

            let existing_wallets = nekoton::core::ton_wallet::find_existing_wallets(
                transport.as_ref(),
                &public_key,
                workchain_id,
            )
            .await
            .handle_error()?
            .into_iter()
            .map(|e| ExistingWalletInfo::from_core(e))
            .collect::<Vec<_>>();

            let existing_wallets = serde_json::to_string(&existing_wallets)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(existing_wallets)
        }

        let result = internal_fn(transport, public_key, workchain_id)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_workchain(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let workchain = ton_wallet.workchain() as c_ulonglong;

            Ok(workchain)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_address(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let address = ton_wallet.address().to_string().to_ptr() as c_ulonglong;

            Ok(address)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_public_key(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let public_key = ton_wallet.public_key();
            let public_key = hex::encode(public_key.to_bytes()).to_ptr() as c_ulonglong;

            Ok(public_key)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_wallet_type(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let contract = ton_wallet.wallet_type();
            let contract = WalletType::from_core(contract);
            let contract = serde_json::to_string(&contract).handle_error()?.to_ptr() as c_ulonglong;

            Ok(contract)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_contract_state(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let contract_state = ton_wallet.contract_state();
            let contract_state = serde_json::to_string(&contract_state)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(contract_state)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_pending_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let pending_transactions = ton_wallet.pending_transactions();
            let pending_transactions = serde_json::to_string(pending_transactions)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(pending_transactions)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_polling_method(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let polling_method = ton_wallet.polling_method();
            let polling_method = serde_json::to_string(&polling_method)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(polling_method)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_details(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let details = ton_wallet.details();
            let details = serde_json::to_string(&details).handle_error()?.to_ptr() as c_ulonglong;

            Ok(details)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_unconfirmed_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let unconfirmed_transactions = ton_wallet.get_unconfirmed_transactions();
            let unconfirmed_transactions = serde_json::to_string(&unconfirmed_transactions)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(unconfirmed_transactions)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_ton_wallet_custodians(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let custodians = ton_wallet
                .get_custodians()
                .clone()
                .map(|e| e.iter().map(|e| e.to_hex_string()).collect::<Vec<_>>());

            let custodians =
                serde_json::to_string(&custodians).handle_error()?.to_ptr() as c_ulonglong;

            Ok(custodians)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_prepare_deploy(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    let expiration = expiration.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            expiration: String,
        ) -> Result<u64, String> {
            let expiration = serde_json::from_str::<Expiration>(&expiration)
                .handle_error()?
                .to_core();

            let message = ton_wallet.prepare_deploy(expiration).handle_error()?;

            let message = Box::new(Arc::new(message));
            let ptr = Box::into_raw(message) as c_ulonglong;

            Ok(ptr)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet, expiration)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_prepare_deploy_with_multiple_owners(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    expiration: *mut c_char,
    custodians: *mut c_char,
    req_confirms: c_uchar,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    let expiration = expiration.from_ptr();
    let custodians = custodians.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            expiration: String,
            custodians: String,
            req_confirms: u8,
        ) -> Result<u64, String> {
            let expiration = serde_json::from_str::<Expiration>(&expiration)
                .handle_error()?
                .to_core();

            let custodians = serde_json::from_str::<Vec<String>>(&custodians)
                .handle_error()?
                .into_iter()
                .map(|e| parse_public_key(&e))
                .collect::<Result<Vec<_>, String>>()?;

            let message = ton_wallet
                .prepare_deploy_with_multiple_owners(expiration, &custodians, req_confirms)
                .handle_error()?;

            let message = Box::new(Arc::new(message));
            let ptr = Box::into_raw(message) as c_ulonglong;

            Ok(ptr)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet, expiration, custodians, req_confirms)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_prepare_transfer(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    transport: *mut c_void,
    transport_type: c_int,
    public_key: *mut c_char,
    destination: *mut c_char,
    amount: *mut c_char,
    body: *mut c_char,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    let transport = match_transport(transport, transport_type);

    let public_key = public_key.from_ptr();
    let destination = destination.from_ptr();
    let amount = amount.from_ptr();
    let body = match !body.is_null() {
        true => Some(body.from_ptr()),
        false => None,
    };
    let expiration = expiration.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            transport: Arc<dyn Transport>,
            public_key: String,
            destination: String,
            amount: String,
            body: Option<String>,

            expiration: String,
        ) -> Result<u64, String> {
            let public_key = parse_public_key(&public_key)?;

            let destination = parse_address(&destination)?;

            let amount = amount.parse::<u64>().handle_error()?;

            let body = body
                .map(|e| create_boc_or_comment_payload(&e))
                .transpose()
                .handle_error()?;

            let expiration = serde_json::from_str::<Expiration>(&expiration)
                .handle_error()?
                .to_core();

            let address = ton_wallet.address();

            let account_state = transport.get_contract_state(address).await.handle_error()?;

            let account_stuff = match account_state {
                RawContractState::NotExists => return Err(String::from("Not exists")),
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
                .handle_error()?;

            let message = match action {
                TransferAction::DeployFirst => return Err(String::from("Deploy first")),
                TransferAction::Sign(message) => message,
            };

            let message = Box::new(Arc::new(message));
            let ptr = Box::into_raw(message) as c_ulonglong;

            Ok(ptr)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(
            &mut ton_wallet,
            transport,
            public_key,
            destination,
            amount,
            body,
            expiration,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_prepare_confirm_transaction(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    transport: *mut c_void,
    transport_type: c_int,
    public_key: *mut c_char,
    transaction_id: *mut c_char,
    expiration: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    let transport = match_transport(transport, transport_type);

    let public_key = public_key.from_ptr();
    let transaction_id = transaction_id.from_ptr();
    let expiration = expiration.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            transport: Arc<dyn Transport>,
            public_key: String,
            transaction_id: String,
            expiration: String,
        ) -> Result<u64, String> {
            let public_key = parse_public_key(&public_key)?;

            let transaction_id = transaction_id.parse::<u64>().handle_error()?;

            let expiration = serde_json::from_str::<Expiration>(&expiration)
                .handle_error()?
                .to_core();

            let address = ton_wallet.address();

            let account_state = transport.get_contract_state(address).await.handle_error()?;

            let account_stuff = match account_state {
                RawContractState::NotExists => return Err(String::from("Not exists")),
                RawContractState::Exists(contract) => contract.account,
            };

            let message = ton_wallet
                .prepare_confirm_transaction(
                    &account_stuff,
                    &public_key,
                    transaction_id,
                    expiration,
                )
                .handle_error()?;

            let message = Box::new(Arc::new(message));
            let ptr = Box::into_raw(message) as c_ulonglong;

            Ok(ptr)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(
            &mut ton_wallet,
            transport,
            public_key,
            transaction_id,
            expiration,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_estimate_fees(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    message: *mut c_void,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    let message = message as *mut Box<dyn UnsignedMessage>;
    let message = Arc::from_raw(message) as Arc<Box<dyn UnsignedMessage>>;
    let message = (*message).clone();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            message: Box<dyn UnsignedMessage>,
        ) -> Result<u64, String> {
            let signature = [u8::default(); ed25519_dalek::SIGNATURE_LENGTH];

            let message = message.sign(&signature).handle_error()?.message;

            let fees = ton_wallet.estimate_fees(&message).await.handle_error()?;

            let fees = fees.to_string().to_ptr() as u64;

            Ok(fees)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet, message).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_send(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    keystore: *mut c_void,
    message: *mut c_void,
    sign_input: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    let message = message as *mut Box<dyn UnsignedMessage>;
    let message = Arc::from_raw(message) as Arc<Box<dyn UnsignedMessage>>;
    let message = (*message).clone();

    let sign_input = sign_input.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            keystore: Arc<KeyStore>,
            mut message: Box<dyn UnsignedMessage>,
            sign_input: String,
        ) -> Result<u64, String> {
            let clock = SimpleClock {};

            message.refresh_timeout(&clock);

            let hash = message.hash();

            let signature = if let Ok(sign_input) =
                serde_json::from_str::<EncryptedKeyPassword>(&sign_input)
            {
                keystore
                    .sign::<EncryptedKeySigner>(hash, sign_input.to_core())
                    .await
                    .handle_error()?
            } else if let Ok(sign_input) = serde_json::from_str::<DerivedKeySignParams>(&sign_input)
            {
                keystore
                    .sign::<DerivedKeySigner>(hash, sign_input.to_core())
                    .await
                    .handle_error()?
            } else {
                panic!()
            };

            let message = message.sign(&signature).handle_error()?;

            let pending_transaction = ton_wallet
                .send(&message.message, message.expire_at)
                .await
                .handle_error()?;

            let pending_transaction = serde_json::to_string(&pending_transaction)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(pending_transaction)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet, keystore, message, sign_input)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_refresh(result_port: c_longlong, ton_wallet: *mut c_void) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet) -> Result<u64, String> {
            let _ = ton_wallet.refresh().await.handle_error()?;

            Ok(0)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_preload_transactions(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    from: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    let from = from.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(ton_wallet: &mut TonWallet, from: String) -> Result<u64, String> {
            let from = serde_json::from_str::<TransactionId>(&from).handle_error()?;

            let _ = ton_wallet.preload_transactions(from).await.handle_error()?;

            Ok(0)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet, from).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn ton_wallet_handle_block(
    result_port: c_longlong,
    ton_wallet: *mut c_void,
    transport: *mut c_void,
    transport_type: c_int,
    id: *mut c_char,
) {
    let ton_wallet = ton_wallet as *mut Mutex<TonWallet>;
    let ton_wallet = Arc::from_raw(ton_wallet) as Arc<Mutex<TonWallet>>;

    let transport = match FromPrimitive::from_i32(transport_type) {
        Some(TransportType::Gql) => {
            let gql_transport = transport as *mut GqlTransport;
            Arc::from_raw(gql_transport) as Arc<GqlTransport>
        }
        Some(TransportType::Jrpc) => {
            let result = Err(String::from("Not a GQL transport")).match_result();

            send_to_result_port(result_port, result);

            return;
        }
        None => panic!(),
    };

    let id = id.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            ton_wallet: &mut TonWallet,
            transport: Arc<GqlTransport>,
            id: String,
        ) -> Result<u64, String> {
            let block = transport.get_block(&id).await.handle_error()?;

            let _ = ton_wallet.handle_block(&block).await.handle_error()?;

            Ok(0)
        }

        let mut ton_wallet = ton_wallet.lock().await;

        let result = internal_fn(&mut ton_wallet, transport, id)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}
