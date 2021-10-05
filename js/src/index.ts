;(window as Record<string, any>).hasTonProvider = true

// @ts-ignore
let __define: Define | undefined

const cleanContextForImports = () => {
    // @ts-ignore
    __define = window.define
    try {
        // @ts-ignore
        window.define = undefined
    } catch (_) {
        console.warn('Nekoton: global.define could not be deleted')
    }
}

const restoreContextAfterImports = () => {
    try {
        // @ts-ignore
        window.define = __define
    } catch (_) {
        console.warn('Nekoton: global.define could not be overwritten')
    }
}

cleanContextForImports()

import log from 'loglevel'
import { initializeProvider } from './provider'

restoreContextAfterImports()

// TODO: somehow determine log level
log.setDefaultLevel('debug')

initializeProvider({
    logger: log,
})
