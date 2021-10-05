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

const disconnected = async (event: any) => notificationEmitter.emit('disconnected', JSON.parse(event));
const transactionsFound = async (event: any) => notificationEmitter.emit('transactionsFound', JSON.parse(event));
const contractStateChanged = async (event: any) => notificationEmitter.emit('contractStateChanged', JSON.parse(event));
const networkChanged = async (event: any) => notificationEmitter.emit('networkChanged', JSON.parse(event));
const permissionsChanged = async (event: any) => notificationEmitter.emit('permissionsChanged', JSON.parse(event));
const loggedOut = async () => notificationEmitter.emit('loggedOut', {});
