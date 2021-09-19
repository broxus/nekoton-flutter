use crate::{
    external::adnl_connection::MutexAdnlConnection, match_result, models::NativeError, runtime,
    send_to_result_port, RUNTIME,
};
use nekoton::transport::adnl::AdnlTransport;
use std::{
    ffi::c_void,
    os::raw::{c_longlong, c_ulonglong},
    sync::Arc,
    u64,
};
use tokio::sync::Mutex;

pub type MutexAdnlTransport = Mutex<Arc<AdnlTransport>>;

#[no_mangle]
pub unsafe extern "C" fn get_adnl_transport(result_port: c_longlong, connection: *mut c_void) {
    let connection = connection as *mut MutexAdnlConnection;
    let connection = &(*connection);

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_get_adnl_transport(connection).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_adnl_transport(connection: &MutexAdnlConnection) -> Result<u64, NativeError> {
    let connection = connection.lock().await;

    let connection = connection.clone();

    let transport = AdnlTransport::new(connection);
    let transport = Arc::new(transport);
    let transport = Mutex::new(transport);
    let transport = Arc::new(transport);

    let ptr = Arc::into_raw(transport) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn free_adnl_transport(adnl_transport: *mut c_void) {
    let adnl_transport = adnl_transport as *mut MutexAdnlTransport;
    Arc::from_raw(adnl_transport);
}
