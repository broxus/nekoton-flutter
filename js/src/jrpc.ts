import {
    Maybe,
    JsonRpcError,
} from './utils'

export type JsonRpcVersion = '2.0'
export type JsonRpcId = number | string | void

export interface JsonRpcRequest<T> {
    jsonrpc: JsonRpcVersion
    method: string
    id: JsonRpcId
    params?: T
}

export interface JsonRpcNotification<T> {
    jsonrpc: JsonRpcVersion
    method: string
    params?: T
}

interface JsonRpcResponseBase {
    jsonrpc: JsonRpcVersion
    id: JsonRpcId
}

export interface JsonRpcSuccess<T> extends JsonRpcResponseBase {
    result: Maybe<T>
}

export interface JsonRpcFailure extends JsonRpcResponseBase {
    error: JsonRpcError
}

export type JsonRpcResponse<T> = JsonRpcSuccess<T> | JsonRpcFailure

export interface PendingJsonRpcResponse<T> extends JsonRpcResponseBase {
    result?: T
    error?: Error | JsonRpcError
}
