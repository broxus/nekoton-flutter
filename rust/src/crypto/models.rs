use serde::Serialize;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SignedData {
    pub data_hash: String,
    pub signature: String,
    pub signature_hex: String,
    pub signature_parts: SignatureParts,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SignedDataRaw {
    pub signature: String,
    pub signature_hex: String,
    pub signature_parts: SignatureParts,
}

#[derive(Serialize)]
pub struct SignatureParts {
    pub high: String,
    pub low: String,
}
