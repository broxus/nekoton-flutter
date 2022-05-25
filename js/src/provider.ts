import {
    JsonRpcRequest,
    JsonRpcResponse,
    JsonRpcId,
    JsonRpcVersion,
    JsonRpcSuccess,
} from './jrpc'
import {
    ConsoleLike,
    Maybe,
    NekotonRpcError,
    SafeEventEmitter,
    getRpcPromiseCallback,
    requestDart,
} from './utils'
import { RpcErrorCode } from './errors'
import { notificationEmitter } from "./notifications";

type InitializeProviderOptions = {
    logger?: ConsoleLike
    maxEventListeners?: number
    shouldSetOnWindow?: boolean
}

export const initializeProvider = ({
                                       logger = console,
                                       maxEventListeners = 100,
                                       shouldSetOnWindow = true,
                                   }: InitializeProviderOptions) => {
    let provider = new NekotonInpageProvider({
        logger,
        maxEventListeners,
    })
    notificationEmitter.emitter = provider;

    if (shouldSetOnWindow) {
        setGlobalProvider(provider)
    }

    return provider
}

export function setGlobalProvider(
    providerInstance: NekotonInpageProvider
): void {
    ;(window as Record<string, any>).__ever = providerInstance
    window.dispatchEvent(new Event('ever#initialized'))

    // TODO: remove later
    ;(window as Record<string, any>).ton = providerInstance
    window.dispatchEvent(new Event('ton#initialized'))
}

interface UnvalidatedJsonRpcRequest {
    id?: JsonRpcId
    jsonrpc?: JsonRpcVersion
    method: string
    params?: unknown
}

interface NekotonInpageProviderOptions {
    logger?: ConsoleLike
    maxEventListeners?: number
}

interface RequestArguments {
    method: string
    params?: unknown[] | Record<string, unknown>
}

interface InternalState {
    isConnected: boolean
    isPermanentlyDisconnected: boolean
}

class NekotonInpageProvider extends SafeEventEmitter {
    private readonly _log: ConsoleLike
    private _state: InternalState

    constructor(
        {
            logger = console,
            maxEventListeners = 100,
        }: NekotonInpageProviderOptions
    ) {
        super()

        validateLoggerObject(logger)
        this._log = logger

        this.setMaxListeners(maxEventListeners)

        this._state = {
            isConnected: false,
            isPermanentlyDisconnected: false,
        }

        this.on('connect', () => {
            this._state.isConnected = true
        })
    }

    get isConnected(): boolean {
        return this._state.isConnected
    }

    public async request<T>(args: RequestArguments): Promise<Maybe<T>> {
        if (!args || typeof args !== 'object' || Array.isArray(args)) {
            throw new NekotonRpcError(RpcErrorCode.INVALID_REQUEST, 'Invalid request args')
        }

        const { method, params } = args

        if (method.length === 0) {
            throw new NekotonRpcError(RpcErrorCode.INVALID_REQUEST, 'Invalid request method')
        }

        if (
            params !== undefined &&
            !Array.isArray(params) &&
            (typeof params !== 'object' || params === null)
        ) {
            throw new NekotonRpcError(RpcErrorCode.INVALID_REQUEST, 'Invalid request params')
        }

        return new Promise<T>((resolve, reject) => {
            this._rpcRequest({ method, params }, getRpcPromiseCallback(resolve, reject))
        })
    }

    public sendAsync(
        payload: JsonRpcRequest<unknown>,
        callback: (error: Error | null, response?: JsonRpcResponse<unknown>) => void
    ) {
        this._rpcRequest(payload, callback)
    }

    public addListener(eventName: string, listener: (...args: unknown[]) => void) {
        return super.addListener(eventName, listener)
    }

    public removeListener(eventName: string, listener: (...args: unknown[]) => void) {
        return super.removeListener(eventName, listener)
    }

    public on(eventName: string, listener: (...args: unknown[]) => void) {
        return super.on(eventName, listener)
    }

    public once(eventName: string, listener: (...args: unknown[]) => void) {
        return super.once(eventName, listener)
    }

    public prependListener(eventName: string, listener: (...args: unknown[]) => void) {
        return super.prependListener(eventName, listener)
    }

    public prependOnceListener(eventName: string, listener: (...args: unknown[]) => void) {
        return super.prependOnceListener(eventName, listener)
    }

    private _rpcRequest = (
        payload: UnvalidatedJsonRpcRequest,
        callback: (...args: any[]) => void
    ) => {
        requestDart(payload.method, payload.params).then((result: any) => {
            callback(null, { result: result } as JsonRpcSuccess<unknown>)
        }).catch((e: Error) => {
            callback(e)
        });
    }
}

const validateLoggerObject = (logger: ConsoleLike) => {
    if (logger !== console) {
        if (typeof logger === 'object') {
            const methodKeys = ['log', 'warn', 'error', 'debug', 'info', 'trace']
            for (const key of methodKeys) {
                if (typeof logger[key as keyof ConsoleLike] !== 'function') {
                    throw new Error(`Invalid logger method: "${key}"`)
                }
            }
            return
        }
        throw new Error('Invalid logger object')
    }
}
