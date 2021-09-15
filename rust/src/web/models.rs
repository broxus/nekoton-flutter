use thiserror;
use wasm_bindgen::prelude::*;

#[wasm_bindgen(typescript_custom_section)]
const GEN_TIMINGS: &str = r#"
export type GenTimings = {
    genLt: string,
    genUtime: number,
};
"#;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "GenTimings")]
    pub type GenTimings;
}

#[wasm_bindgen(typescript_custom_section)]
const LAST_TRANSACTION_ID: &str = r#"
export type LastTransactionId = {
    isExact: boolean,
    lt: string,
    hash?: string,
};
"#;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "LastTransactionId")]
    pub type LastTransactionId;
}

#[wasm_bindgen(typescript_custom_section)]
const TOKEN: &str = r#"
export type AbiToken =
    | boolean
    | string
    | number
    | { [K in string]: AbiToken }
    | AbiToken[]
    | (readonly [AbiToken, AbiToken])[];
    
type TokensObject = { [K in string]: AbiToken };
"#;

#[wasm_bindgen(typescript_custom_section)]
const EXECUTION_OUTPUT: &str = r#"
export type ExecutionOutput = {
    output?: TokensObject,
    code: number,
};
"#;

#[wasm_bindgen(typescript_custom_section)]
const DECODED_TRANSACTION: &str = r#"
export type DecodedTransaction = {
    method: string,
    input: TokensObject,
    output: TokensObject,
};
"#;

#[wasm_bindgen(typescript_custom_section)]
const METHOD_NAME: &str = r#"
export type MethodName = string | string[]
"#;

#[wasm_bindgen(typescript_custom_section)]
const DECODED_INPUT: &str = r#"
export type DecodedInput = {
    method: string,
    input: TokensObject,
};
"#;

#[wasm_bindgen(typescript_custom_section)]
const DECODED_EVENT: &str = r#"
export type DecodedEvent = {
    event: string,
    data: TokensObject,
};
"#;

#[wasm_bindgen(typescript_custom_section)]
const DECODED_TRANSACTION_EVENTS: &str = r#"
export type DecodedTransactionEvents = Array<DecodedEvent>;
"#;

#[wasm_bindgen(typescript_custom_section)]
const DECODED_OUTPUT: &str = r#"
export type DecodedOutput = {
    method: string,
    output: TokensObject,
};
"#;

#[wasm_bindgen(typescript_custom_section)]
const PARAM: &str = r#"
export type AbiParamKindUint = 'uint8' | 'uint16' | 'uint32' | 'uint64' | 'uint128' | 'uint160' | 'uint256';
export type AbiParamKindInt = 'int8' | 'int16' | 'int32' | 'int64' | 'int128' | 'int160' | 'int256';
export type AbiParamKindTuple = 'tuple';
export type AbiParamKindBool = 'bool';
export type AbiParamKindCell = 'cell';
export type AbiParamKindAddress = 'address';
export type AbiParamKindBytes = 'bytes';
export type AbiParamKindGram = 'gram';
export type AbiParamKindTime = 'time';
export type AbiParamKindExpire = 'expire';
export type AbiParamKindPublicKey = 'pubkey';
export type AbiParamKindArray = `${AbiParamKind}[]`;

export type AbiParamKindMap = `map(${AbiParamKindInt | AbiParamKindUint | AbiParamKindAddress},${AbiParamKind | `${AbiParamKind}[]`})`;

export type AbiParamKind =
  | AbiParamKindUint
  | AbiParamKindInt
  | AbiParamKindTuple
  | AbiParamKindBool
  | AbiParamKindCell
  | AbiParamKindAddress
  | AbiParamKindBytes
  | AbiParamKindGram
  | AbiParamKindTime
  | AbiParamKindExpire
  | AbiParamKindPublicKey;

export type AbiParam = {
  name: string;
  type: AbiParamKind | AbiParamKindMap | AbiParamKindArray;
  components?: AbiParam[];
};
"#;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "AbiToken")]
    pub type JsTokenValue;

    #[wasm_bindgen(typescript_type = "TokensObject")]
    pub type TokensObject;

    #[wasm_bindgen(typescript_type = "ExecutionOutput")]
    pub type ExecutionOutput;

    #[wasm_bindgen(typescript_type = "DecodedTransaction")]
    pub type DecodedTransaction;

    #[wasm_bindgen(typescript_type = "MethodName")]
    pub type JsMethodName;

    #[wasm_bindgen(typescript_type = "DecodedInput")]
    pub type DecodedInput;

    #[wasm_bindgen(typescript_type = "DecodedEvent")]
    pub type DecodedEvent;

    #[wasm_bindgen(typescript_type = "DecodedTransactionEvents")]
    pub type DecodedTransactionEvents;

    #[wasm_bindgen(typescript_type = "DecodedOutput")]
    pub type DecodedOutput;

    #[wasm_bindgen(typescript_type = "Array<AbiParam>")]
    pub type ParamsList;
}

#[wasm_bindgen(typescript_custom_section)]
const STATE_INIT: &str = r#"
export type StateInit = {
    data: string | undefined;
    code: string | undefined;
};
"#;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "StateInit")]
    pub type StateInit;
}

#[wasm_bindgen(typescript_custom_section)]
const KNOWN_PAYLOAD: &str = r#"
export type KnownPayload =
    | EnumItem<'comment', string>
    | EnumItem<'token_outgoing_transfer', { to: TransferRecipient, tokens: string }>
    | EnumItem<'token_swap_back', { tokens: string, to: string }>;
"#;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "KnownPayload")]
    pub type KnownPayload;
}

#[wasm_bindgen(typescript_custom_section)]
const TRANSFER_RECIPIENT: &str = r#"
export type TransferRecipient = {
    type: 'owner_wallet' | 'token_wallet',
    address: string,
};
"#;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "TransferRecipient")]
    pub type TransferRecipient;
}

#[wasm_bindgen(typescript_custom_section)]
const TRANSACTION: &str = r#"
export type Transaction = {
    id: TransactionId,
    prevTransactionId?: TransactionId,
    createdAt: number,
    aborted: boolean,
    origStatus: AccountStatus,
    endStatus: AccountStatus,
    totalFees: string,
    inMessage: Message,
    outMessages: Message[],
};
"#;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "Transaction")]
    pub type Transaction;
}

pub enum MethodName {
    Known(String),
    Guess(Vec<String>),
}

#[derive(thiserror::Error, Debug)]
pub enum AbiError {
    #[error("Unexpected token")]
    UnexpectedToken,
    #[error("Expected boolean")]
    ExpectedBoolean,
    #[error("Expected string")]
    ExpectedString,
    #[error("Expected param type")]
    ExpectedParamType,
    #[error("Expected string or array")]
    ExpectedStringOrArray,
    #[error("Expected string or number")]
    ExpectedStringOrNumber,
    #[error("Expected unsigned number")]
    ExpectedUnsignedNumber,
    #[error("Expected integer")]
    ExpectedIntegerNumber,
    #[error("Expected array")]
    ExpectedArray,
    #[error("Expected tuple of two elements")]
    ExpectedMapItem,
    #[error("Expected object")]
    ExpectedObject,
    #[error("Expected message")]
    ExpectedMessage,
    #[error("Expected message body")]
    ExpectedMessageBody,
    #[error("Invalid array length")]
    InvalidArrayLength,
    #[error("Invalid number")]
    InvalidNumber,
    #[error("Invalid cell")]
    InvalidCell,
    #[error("Invalid address")]
    InvalidAddress,
    #[error("Invalid base64 encoded bytes")]
    InvalidBytes,
    #[error("Invalid bytes length")]
    InvalidBytesLength,
    #[error("Invalid public key")]
    InvalidPublicKey,
    #[error("Invalid mapping key")]
    InvalidMappingKey,
    #[error("Invalid components")]
    InvalidComponents,
    #[error("Tuple property not found")]
    TuplePropertyNotFound,
    #[error("Unsupported header")]
    UnsupportedHeader,
}
