import safeStringify from 'fast-safe-stringify'
import {EventEmitter} from 'events'

import {RpcErrorCode} from './errors'
import { PendingJsonRpcResponse } from './jrpc'

export type Maybe<T> = Partial<T> | null | undefined

export type ConsoleLike = Pick<Console, 'log' | 'warn' | 'error' | 'debug' | 'info' | 'trace'>

type Handler = (...args: any[]) => void

interface EventMap {
    [k: string]: Handler | Handler[] | undefined
}

export interface JsonRpcError {
    code: number
    message: string
    data?: unknown
    stack?: string
}

export class NekotonRpcError<T> extends Error {
    code: number
    data?: T

    constructor(code: number, message: string, data?: T) {
        if (!Number.isInteger(code)) {
            throw new Error('"code" must be an integer')
        }

        if (!message || (typeof message as any) !== 'string') {
            throw new Error('"message" must be a nonempty string')
        }

        super(message)

        this.code = code
        this.data = data
    }

    serialize(): JsonRpcError {
        const serialized: JsonRpcError = {
            code: this.code,
            message: this.message,
        }
        if (this.data !== undefined) {
            serialized.data = this.data
        }
        if (this.stack) {
            serialized.stack = this.stack
        }
        return serialized
    }

    toString(): string {
        return safeStringify(this.serialize(), stringifyReplacer, 2)
    }
}

const FALLBACK_ERROR: JsonRpcError = {
    code: RpcErrorCode.INTERNAL,
    message: 'Unspecified error message',
}

const stringifyReplacer = (_: unknown, value: unknown): unknown => {
    if (value === '[Circular]') {
        return undefined
    }
    return value
}

const assignOriginalError = (error: unknown): unknown => {
    if (error && typeof error === 'object' && !Array.isArray(error)) {
        return Object.assign({}, error)
    }
    return error
}

const hasKey = (obj: Record<string, unknown>, key: string) => {
    return Object.prototype.hasOwnProperty.call(obj, key)
}

export class SafeEventEmitter extends EventEmitter {
    emit(type: string, ...args: any[]): boolean {
        let doError = type === 'error'

        const events: EventMap = (this as any)._events
        if (events !== undefined) {
            doError = doError && events.error === undefined
        } else if (!doError) {
            return false
        }

        if (doError) {
            let er
            if (args.length > 0) {
                ;[er] = args
            }
            if (er instanceof Error) {
                throw er
            }

            const err = new Error(`Unhandled error.${er ? ` (${er.message})` : ''}`)
            ;(err as any).context = er
            throw err
        }

        const handler = events[type]

        if (handler === undefined) {
            return false
        }

        if (typeof handler === 'function') {
            safeApply(handler, this, args)
        } else {
            const len = handler.length
            const listeners = arrayClone(handler)
            for (let i = 0; i < len; i += 1) {
                safeApply(listeners[i], this, args)
            }
        }

        return true
    }
}

function safeApply<T, A extends any[]>(
    handler: (this: T, ...args: A) => void,
    context: T,
    args: A
): void {
    try {
        Reflect.apply(handler, context, args)
    } catch (err) {
        // Throw error after timeout so as not to interrupt the stack
        setTimeout(() => {
            throw err
        })
    }
}

function arrayClone<T>(arr: T[]): T[] {
    const n = arr.length
    const copy = new Array(n)
    for (let i = 0; i < n; i += 1) {
        copy[i] = arr[i]
    }
    return copy
}

export const getRpcPromiseCallback = (
    resolve: (value?: any) => void,
    reject: (error?: Error) => void,
    unwrapResult = true
) => (error: Error, response: PendingJsonRpcResponse<unknown>) => {
    if (error || response.error) {
        reject(error || response.error)
    } else {
        !unwrapResult || Array.isArray(response) ? resolve(response) : resolve(response.result)
    }
}

export const requestDart = (requestName: any, args?: any) => (window as any).flutter_inappwebview.callHandler(requestName, args);
