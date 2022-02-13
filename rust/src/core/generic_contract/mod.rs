pub mod handler;
pub mod models;

use self::handler::GenericContractSubscriptionHandlerImpl;
use crate::{
    crypto::{derived_key::DerivedKeySignParams, encrypted_key::EncryptedKeyPassword},
    models::{HandleError, MatchResult},
    parse_address, runtime, send_to_result_port,
    transport::models::{match_transport, TransportType},
    FromPtr, ToPtr, RUNTIME,
};
use nekoton::{
    core::{generic_contract::GenericContract, keystore::KeyStore, TransactionExecutionOptions},
    crypto::{DerivedKeySigner, EncryptedKeySigner, UnsignedMessage},
    transport::{gql::GqlTransport, Transport},
};
use nekoton_abi::TransactionId;
use nekoton_utils::SimpleClock;
use num_traits::FromPrimitive;
use std::{
    ffi::c_void,
    os::raw::{c_char, c_int, c_longlong, c_ulonglong},
    sync::Arc,
};
use tokio::sync::Mutex;

#[no_mangle]
pub unsafe extern "C" fn generic_contract_subscribe(
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

            let handler = GenericContractSubscriptionHandlerImpl {
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            };
            let handler = Arc::new(handler);

            let clock = Arc::new(SimpleClock {});

            let generic_contract = GenericContract::subscribe(clock, transport, address, handler)
                .await
                .handle_error()?;

            let generic_contract = Box::new(Arc::new(Mutex::new(generic_contract)));

            let ptr = Box::into_raw(generic_contract) as c_ulonglong;

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
pub unsafe extern "C" fn clone_generic_contract_ptr(generic_contract: *mut c_void) -> *mut c_void {
    let generic_contract = generic_contract as *mut Arc<Mutex<GenericContract>>;
    let cloned = Arc::clone(&*generic_contract);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_generic_contract_ptr(generic_contract: *mut c_void) {
    let generic_contract = generic_contract as *mut Arc<Mutex<GenericContract>>;

    let _ = Box::from_raw(generic_contract);
}

#[no_mangle]
pub unsafe extern "C" fn get_generic_contract_address(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    runtime!().spawn(async move {
        async fn internal_fn(generic_contract: &mut GenericContract) -> Result<u64, String> {
            let address = generic_contract.address().to_string().to_ptr() as c_ulonglong;

            Ok(address)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_generic_contract_contract_state(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    runtime!().spawn(async move {
        async fn internal_fn(generic_contract: &mut GenericContract) -> Result<u64, String> {
            let contract_state = generic_contract.contract_state();
            let contract_state = serde_json::to_string(&contract_state)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(contract_state)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_generic_contract_pending_transactions(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    runtime!().spawn(async move {
        async fn internal_fn(generic_contract: &mut GenericContract) -> Result<u64, String> {
            let pending_transactions = generic_contract.pending_transactions();
            let pending_transactions = serde_json::to_string(pending_transactions)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(pending_transactions)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn get_generic_contract_polling_method(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    runtime!().spawn(async move {
        async fn internal_fn(generic_contract: &mut GenericContract) -> Result<u64, String> {
            let polling_method = generic_contract.polling_method();
            let polling_method = serde_json::to_string(&polling_method)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(polling_method)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_estimate_fees(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    message: *mut c_void,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    let message = message as *mut Box<dyn UnsignedMessage>;
    let message = Arc::from_raw(message) as Arc<Box<dyn UnsignedMessage>>;
    let message = (*message).clone();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            message: Box<dyn UnsignedMessage>,
        ) -> Result<u64, String> {
            let signature = [u8::default(); ed25519_dalek::SIGNATURE_LENGTH];

            let message = message.sign(&signature).handle_error()?.message;

            let fees = generic_contract
                .estimate_fees(&message)
                .await
                .handle_error()?;

            let fees = fees.to_string().to_ptr() as u64;

            Ok(fees)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract, message)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_send(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    keystore: *mut c_void,
    message: *mut c_void,
    sign_input: *mut c_char,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    let message = message as *mut Box<dyn UnsignedMessage>;
    let message = Arc::from_raw(message) as Arc<Box<dyn UnsignedMessage>>;
    let message = (*message).clone();

    let sign_input = sign_input.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
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

            let pending_transaction = generic_contract
                .send(&message.message, message.expire_at)
                .await
                .handle_error()?;

            let pending_transaction = serde_json::to_string(&pending_transaction)
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(pending_transaction)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract, keystore, message, sign_input)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
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
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    let keystore = keystore as *mut KeyStore;
    let keystore = Arc::from_raw(keystore) as Arc<KeyStore>;

    let message = message as *mut Box<dyn UnsignedMessage>;
    let message = Arc::from_raw(message) as Arc<Box<dyn UnsignedMessage>>;
    let message = (*message).clone();

    let sign_input = sign_input.from_ptr();
    let options = options.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            keystore: Arc<KeyStore>,
            mut message: Box<dyn UnsignedMessage>,
            sign_input: String,
            options: String,
        ) -> Result<u64, String> {
            let options =
                serde_json::from_str::<TransactionExecutionOptions>(&options).handle_error()?;

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

            let transaction = generic_contract
                .execute_transaction_locally(&message.message, options)
                .await
                .handle_error()?;

            let transaction =
                serde_json::to_string(&transaction).handle_error()?.to_ptr() as c_ulonglong;

            Ok(transaction)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(
            &mut generic_contract,
            keystore,
            message,
            sign_input,
            options,
        )
        .await
        .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_refresh(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    runtime!().spawn(async move {
        async fn internal_fn(generic_contract: &mut GenericContract) -> Result<u64, String> {
            let _ = generic_contract.refresh().await.handle_error()?;

            Ok(0)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_preload_transactions(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    from: *mut c_char,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

    let from = from.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            from: String,
        ) -> Result<u64, String> {
            let from = serde_json::from_str::<TransactionId>(&from).handle_error()?;

            let _ = generic_contract
                .preload_transactions(from)
                .await
                .handle_error()?;

            Ok(0)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract, from)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn generic_contract_handle_block(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    transport: *mut c_void,
    transport_type: c_int,
    id: *mut c_char,
) {
    let generic_contract = generic_contract as *mut Mutex<GenericContract>;
    let generic_contract = Arc::from_raw(generic_contract) as Arc<Mutex<GenericContract>>;

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
            generic_contract: &mut GenericContract,
            transport: Arc<GqlTransport>,
            id: String,
        ) -> Result<u64, String> {
            let block = transport.get_block(&id).await.handle_error()?;

            let _ = generic_contract.handle_block(&block).await.handle_error()?;

            Ok(0)
        }

        let mut generic_contract = generic_contract.lock().await;

        let result = internal_fn(&mut generic_contract, transport, id)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}
