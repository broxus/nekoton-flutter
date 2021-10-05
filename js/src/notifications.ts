import {EventEmitter} from "events";

export class NotificationEmitter {
    emitter?: EventEmitter

    emit(method: string, params: unknown) {
        this.emitter?.emit(method, typeof params === 'string' ? JSON.parse(params) : undefined)

        // TODO: remove
        console.log(`${method} ${JSON.stringify(params)}`);
    }
}

export const notificationEmitter = new NotificationEmitter()

/**
 * Provider Events
 */

const disconnected = async (event: string) => notificationEmitter.emit('disconnected', event);
const transactionsFound = async (event: string) => notificationEmitter.emit('transactionsFound', event);
const contractStateChanged = async (event: string) => notificationEmitter.emit('contractStateChanged', event);
const networkChanged = async (event: string) => notificationEmitter.emit('networkChanged', event);
const permissionsChanged = async (event: string) => notificationEmitter.emit('permissionsChanged', event);
const loggedOut = async () => notificationEmitter.emit('loggedOut', undefined);
