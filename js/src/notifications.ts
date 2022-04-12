import { EventEmitter } from "events";

export class NotificationEmitter {
    emitter?: EventEmitter

    emit(method: string, params: unknown) {
        this.emitter?.emit(method, typeof params === 'string' ? JSON.parse(params) : undefined)
    }
}

export const notificationEmitter = new NotificationEmitter();

(window as any).__dartNotifications = {
    connected: async () => notificationEmitter.emit('connected', undefined),
    disconnected: async (event: string) => notificationEmitter.emit('disconnected', event),
    transactionsFound: async (event: string) => notificationEmitter.emit('transactionsFound', event),
    contractStateChanged: async (event: string) => notificationEmitter.emit('contractStateChanged', event),
    networkChanged: async (event: string) => notificationEmitter.emit('networkChanged', event),
    permissionsChanged: async (event: string) => notificationEmitter.emit('permissionsChanged', event),
    loggedOut: async () => notificationEmitter.emit('loggedOut', undefined),
}
