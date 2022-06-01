mod handler;
mod models;

use std::{
    os::raw::{c_char, c_int, c_longlong, c_void},
    sync::Arc,
};

use nekoton::{
    core::{generic_contract::GenericContract, TransactionExecutionOptions},
    transport::Transport,
};
use nekoton_abi::TransactionId;
use tokio::sync::RwLock;
use ton_block::{Block, Deserializable};

use crate::{
    core::generic_contract::handler::GenericContractSubscriptionHandlerImpl,
    crypto::models::SignedMessage,
    models::{HandleError, MatchResult, ToNekoton},
    parse_address, runtime, send_to_result_port,
    transport::match_transport,
    ToCStringPtr, ToStringFromPtr, CLOCK, RUNTIME,
};

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_subscribe(
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

            let handler = Arc::new(GenericContractSubscriptionHandlerImpl::new(
                on_message_sent_port,
                on_message_expired_port,
                on_state_changed_port,
                on_transactions_found_port,
            ));

            let generic_contract =
                GenericContract::subscribe(CLOCK.clone(), transport, address, handler)
                    .await
                    .handle_error()?;

            let ptr = Box::into_raw(Box::new(Arc::new(RwLock::new(generic_contract)))) as u64;

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
pub unsafe extern "C" fn nt_generic_contract_address(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    runtime!().spawn(async move {
        fn internal_fn(generic_contract: &GenericContract) -> Result<u64, String> {
            let address = generic_contract.address().to_string().to_cstring_ptr() as u64;

            Ok(address)
        }

        let generic_contract = generic_contract.read().await;

        let result = internal_fn(&generic_contract).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_contract_state(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    runtime!().spawn(async move {
        fn internal_fn(generic_contract: &GenericContract) -> Result<u64, String> {
            let contract_state = generic_contract.contract_state();

            let contract_state = serde_json::to_string(&contract_state)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(contract_state)
        }

        let generic_contract = generic_contract.read().await;

        let result = internal_fn(&generic_contract).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_pending_transactions(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    runtime!().spawn(async move {
        fn internal_fn(generic_contract: &GenericContract) -> Result<u64, String> {
            let pending_transactions = generic_contract.pending_transactions();

            let pending_transactions = serde_json::to_string(pending_transactions)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(pending_transactions)
        }

        let generic_contract = generic_contract.read().await;

        let result = internal_fn(&generic_contract).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_polling_method(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    runtime!().spawn(async move {
        fn internal_fn(generic_contract: &GenericContract) -> Result<u64, String> {
            let polling_method = generic_contract.polling_method();

            let polling_method = serde_json::to_string(&polling_method)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(polling_method)
        }

        let generic_contract = generic_contract.read().await;

        let result = internal_fn(&generic_contract).match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_estimate_fees(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    signed_message: *mut c_char,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    let signed_message = signed_message.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            signed_message: String,
        ) -> Result<u64, String> {
            let message = serde_json::from_str::<SignedMessage>(&signed_message)
                .handle_error()?
                .to_nekoton()
                .message;

            let fees = generic_contract
                .estimate_fees(&message)
                .await
                .handle_error()?
                .to_string()
                .to_cstring_ptr() as u64;

            Ok(fees)
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, signed_message)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_send(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    signed_message: *mut c_char,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    let signed_message = signed_message.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            signed_message: String,
        ) -> Result<u64, String> {
            let signed_message = serde_json::from_str::<SignedMessage>(&signed_message)
                .handle_error()?
                .to_nekoton();

            let pending_transaction = generic_contract
                .send(&signed_message.message, signed_message.expire_at)
                .await
                .handle_error()?;

            let pending_transaction = serde_json::to_string(&pending_transaction)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(pending_transaction)
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, signed_message)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_execute_transaction_locally(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    signed_message: *mut c_char,
    options: *mut c_char,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    let signed_message = signed_message.to_string_from_ptr();
    let options = options.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            signed_message: String,
            options: String,
        ) -> Result<u64, String> {
            let message = serde_json::from_str::<SignedMessage>(&signed_message)
                .handle_error()?
                .to_nekoton()
                .message;

            let options =
                serde_json::from_str::<TransactionExecutionOptions>(&options).handle_error()?;

            let transaction = generic_contract
                .execute_transaction_locally(&message, options)
                .await
                .handle_error()?;

            let transaction = serde_json::to_string(&transaction)
                .handle_error()?
                .to_cstring_ptr() as u64;

            Ok(transaction)
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, signed_message, options)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_refresh(
    result_port: c_longlong,
    generic_contract: *mut c_void,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    runtime!().spawn(async move {
        async fn internal_fn(generic_contract: &mut GenericContract) -> Result<u64, String> {
            generic_contract.refresh().await.handle_error()?;

            Ok(u64::default())
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_preload_transactions(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    from: *mut c_char,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    let from = from.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            from: String,
        ) -> Result<u64, String> {
            let from = serde_json::from_str::<TransactionId>(&from).handle_error()?;

            generic_contract
                .preload_transactions(from)
                .await
                .handle_error()?;

            Ok(u64::default())
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, from)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_handle_block(
    result_port: c_longlong,
    generic_contract: *mut c_void,
    block: *mut c_char,
) {
    let generic_contract = generic_contract_from_ptr(generic_contract);

    let block = block.to_string_from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            generic_contract: &mut GenericContract,
            block: String,
        ) -> Result<u64, String> {
            let block = Block::construct_from_base64(&block).handle_error()?;

            generic_contract.handle_block(&block).await.handle_error()?;

            Ok(u64::default())
        }

        let mut generic_contract = generic_contract.write().await;

        let result = internal_fn(&mut generic_contract, block)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_clone_ptr(ptr: *mut c_void) -> *mut c_void {
    Arc::into_raw(Arc::clone(&*(ptr as *mut Arc<RwLock<GenericContract>>))) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn nt_generic_contract_free_ptr(ptr: *mut c_void) {
    Box::from_raw(ptr as *mut Arc<RwLock<GenericContract>>);
}

unsafe fn generic_contract_from_ptr(ptr: *mut c_void) -> Arc<RwLock<GenericContract>> {
    Arc::from_raw(ptr as *mut RwLock<GenericContract>)
}
