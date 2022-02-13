pub mod accounts_storage;
pub mod generic_contract;
pub mod keystore;
pub mod models;
pub mod token_wallet;
pub mod ton_wallet;

use allo_isolate::Isolate;
use nekoton::crypto::UnsignedMessage;
use std::{ffi::c_void, sync::Arc};

fn post_subscription_data(port: i64, data: String) {
    let isolate = Isolate::new(port);
    isolate.post(data);
}

#[no_mangle]
pub unsafe extern "C" fn clone_unsigned_message_ptr(unsigned_message: *mut c_void) -> *mut c_void {
    let unsigned_message = unsigned_message as *mut Arc<Box<dyn UnsignedMessage>>;
    let cloned = Arc::clone(&*unsigned_message);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_unsigned_message_ptr(unsigned_message: *mut c_void) {
    let unsigned_message = unsigned_message as *mut Arc<Box<dyn UnsignedMessage>>;

    let _ = Box::from_raw(unsigned_message);
}
