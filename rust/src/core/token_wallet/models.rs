use serde::Serialize;

#[derive(Serialize)]
pub struct OnBalanceChangedPayload {
    pub balance: String,
}
