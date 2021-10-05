import {EventEmitter} from "events";

export class NotificationEmitter {
    emitter?: EventEmitter

    emit(method: string, params: unknown) {
        this.emitter?.emit(method, params)

        // TODO: remove
        console.log(`${method} ${JSON.stringify(params)}`);
    }
}

export const notificationEmitter = new NotificationEmitter()

/**
 * Provider Events
 */

const disconnected = async (event: any) => notificationEmitter.emit('disconnected', event);
const transactionsFound = async (event: any) => notificationEmitter.emit('transactionsFound', event);
const contractStateChanged = async (event: any) => notificationEmitter.emit('contractStateChanged', event);
const networkChanged = async (event: any) => notificationEmitter.emit('networkChanged', event);
const permissionsChanged = async (event: any) => notificationEmitter.emit('permissionsChanged', event);
const loggedOut = async () => notificationEmitter.emit('loggedOut', undefined);
