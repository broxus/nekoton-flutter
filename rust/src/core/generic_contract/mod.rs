mod handler;

use std::{
    os::raw::{c_char, c_longlong, c_void},
    sync::Arc,
};

use allo_isolate::Isolate;
use nekoton::{
    core::{generic_contract::GenericContract, TransactionExecutionOptions},
    crypto::SignedMessage,
    transport::Transport,
};
use nekoton_abi::TransactionId;
use tokio::sync::RwLock;
use ton_block::{Block, Deserializable};

use crate::{
    clock, core::generic_contract::handler::GenericContractSubscriptionHandlerImpl, parse_address,
    runtime, transport::match_transport, HandleError, MatchResult, PostWithResult, ToStringFromPtr,
    CLOCK, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_subscribe(
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

            let handler = Arc::new(GenericContractSubscriptionHandlerImpl::new(
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            ));

            let generic_contract =
                GenericContract::subscribe(clock!(), transport, address, handler)
                    .await
                    .handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(generic_contract))));

            serde_json::to_value(ptr as usize).handle_error()
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

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_address(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    runtime!().spawn(async move {
        fn internal_fn(generic_contract: &GenericContract) -> Result<serde_json::Value, String> {
            let address = generic_contract.address().to_string();

            serde_json::to_value(address).handle_error()
        }

        let generic_contract = generic_contract.read().await;

        let result = internal_fn(&generic_contract).match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_contract_state(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    runtime!().spawn(async move {
        fn internal_fn(generic_contract: &GenericContract) -> Result<serde_json::Value, String> {
            let contract_state = generic_contract.contract_state();

            serde_json::to_value(&contract_state).handle_error()
        }

        let generic_contract = generic_contract.read().await;

        let result = internal_fn(&generic_contract).match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_pending_transactions(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    runtime!().spawn(async move {
        fn internal_fn(generic_contract: &GenericContract) -> Result<serde_json::Value, String> {
            let pending_transactions = generic_contract.pending_transactions();

            serde_json::to_value(pending_transactions).handle_error()
        }

        let generic_contract = generic_contract.read().await;

        let result = internal_fn(&generic_contract).match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_polling_method(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    runtime!().spawn(async move {
        fn internal_fn(generic_contract: &GenericContract) -> Result<serde_json::Value, String> {
            let polling_method = generic_contract.polling_method();

            serde_json::to_value(&polling_method).handle_error()
        }

        let generic_contract = generic_contract.read().await;

        let result = internal_fn(&generic_contract).match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_estimate_fees(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    signed_message: *mut c_char,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    let signed_message = signed_message.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            signed_message: String,
        ) -> Result<serde_json::Value, String> {
            let message = serde_json::from_str::<SignedMessage>(&signed_message)
                .handle_error()?
                .message;

            let fees = generic_contract
                .estimate_fees(&message)
                .await
                .handle_error()?
                .to_string();

            serde_json::to_value(fees).handle_error()
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, signed_message)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_send(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    signed_message: *mut c_char,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    let signed_message = signed_message.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            signed_message: String,
        ) -> Result<serde_json::Value, String> {
            let signed_message =
                serde_json::from_str::<SignedMessage>(&signed_message).handle_error()?;

            let pending_transaction = generic_contract
                .send(&signed_message.message, signed_message.expire_at)
                .await
                .handle_error()?;

            serde_json::to_value(&pending_transaction).handle_error()
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, signed_message)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_execute_transaction_locally(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    signed_message: *mut c_char,
    options: *mut c_char,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    let signed_message = signed_message.to_string_from_ptr();
    let options = options.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            signed_message: String,
            options: String,
        ) -> Result<serde_json::Value, String> {
            let message = serde_json::from_str::<SignedMessage>(&signed_message)
                .handle_error()?
                .message;

            let options =
                serde_json::from_str::<TransactionExecutionOptions>(&options).handle_error()?;

            let transaction = generic_contract
                .execute_transaction_locally(&message, options)
                .await
                .handle_error()?;

            serde_json::to_value(&transaction).handle_error()
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, signed_message, options)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_refresh(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
        ) -> Result<serde_json::Value, String> {
            generic_contract.refresh().await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract).await.match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_preload_transactions(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    from: *mut c_char,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    let from = from.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            from: String,
        ) -> Result<serde_json::Value, String> {
            let from = serde_json::from_str::<TransactionId>(&from).handle_error()?;

            generic_contract
                .preload_transactions(from)
                .await
                .handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, from)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_handle_block(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    block: *mut c_char,
) {
    let generic_contract = &*(generic_contract as *mut RwLock<GenericContract>);

    let block = block.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            block: String,
        ) -> Result<serde_json::Value, String> {
            let block = Block::construct_from_base64(&block).handle_error()?;

            generic_contract.handle_block(&block).await.handle_error()?;

            Ok(serde_json::Value::Null)
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, block)
            .await
            .match_result();

        Isolate::new(result_port).post_with_result(result).unwrap();
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_free_ptr(ptr: *mut c_void) {
    println!("nt_generic_contract_free_ptr");
    Box::from_raw(ptr as *mut Arc<RwLock<GenericContract>>);
}
