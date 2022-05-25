mod accounts_storage;
mod generic_contract;
mod keystore;
mod models;
mod token_wallet;
mod ton_wallet;

use allo_isolate::Isolate;

use crate::models::HandleError;

fn post_subscription_data(port: i64, data: String) -> Result<(), String> {
    match Isolate::new(port).post(data) {
        true => Ok(()),
        false => Err("Message was not posted successfully").handle_error(),
    }
}
