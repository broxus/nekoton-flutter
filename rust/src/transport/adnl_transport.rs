use crate::{
    external::adnl_connection::{
        AdnlConnectionImpl, MutexAdnlConnection, ADNL_CONNECTION_NOT_FOUND,
    },
    match_result,
    models::{NativeError, NativeStatus},
    runtime, send_to_result_port, RUNTIME,
};
use nekoton::transport::adnl::AdnlTransport;
use std::{
    ffi::c_void,
    os::raw::{c_longlong, c_ulonglong},
    sync::Arc,
    u64,
};
use tokio::sync::Mutex;

pub type MutexAdnlTransport = Mutex<Option<Arc<AdnlTransport>>>;

pub const ADNL_TRANSPORT_NOT_FOUND: &str = "Adnl transport not found";

#[no_mangle]
pub unsafe extern "C" fn get_adnl_transport(result_port: c_longlong, connection: *mut c_void) {
    let connection = connection as *mut MutexAdnlConnection;
    let connection = &(*connection);

    let rt = runtime!();
    rt.spawn(async move {
        let mut connection_guard = connection.lock().await;
        let connection = connection_guard.take();
        let connection = match connection {
            Some(connection) => connection,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ADNL_CONNECTION_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = internal_get_adnl_transport(connection.clone()).await;
        let result = match_result(result);

        *connection_guard = Some(connection);

        send_to_result_port(result_port, result);
    });
}

async fn internal_get_adnl_transport(
    connection: Arc<AdnlConnectionImpl>,
) -> Result<u64, NativeError> {
    let transport = AdnlTransport::new(connection);
    let transport = Arc::new(transport);
    let transport = Mutex::new(Some(transport));
    let transport = Arc::new(transport);

    let ptr = Arc::into_raw(transport) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn free_adnl_transport(result_port: c_longlong, adnl_transport: *mut c_void) {
    let adnl_transport = adnl_transport as *mut MutexAdnlTransport;
    let adnl_transport = &(*adnl_transport);

    let rt = runtime!();
    rt.spawn(async move {
        let mut adnl_transport_guard = adnl_transport.lock().await;
        let adnl_transport = adnl_transport_guard.take();
        match adnl_transport {
            Some(adnl_transport) => adnl_transport,
            None => {
                let result = match_result(Err(NativeError {
                    status: NativeStatus::MutexError,
                    info: ADNL_TRANSPORT_NOT_FOUND.to_owned(),
                }));
                send_to_result_port(result_port, result);
                return;
            }
        };

        let result = Ok(0);
        let result = match_result(result);

        send_to_result_port(result_port, result);
    });
}
