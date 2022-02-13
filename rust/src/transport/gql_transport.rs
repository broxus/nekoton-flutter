use crate::{
    external::gql_connection::GqlConnectionImpl,
    models::{HandleError, MatchResult},
    parse_address, runtime, send_to_result_port, FromPtr, ToPtr, RUNTIME,
};
use nekoton::transport::gql::GqlTransport;
use nekoton_transport::gql::{GqlClient, GqlNetworkSettings};
use std::{
    ffi::c_void,
    os::raw::{c_char, c_longlong, c_ulonglong},
    sync::Arc,
    time::Duration,
    u64,
};

#[no_mangle]
pub unsafe extern "C" fn create_gql_transport(settings: *mut c_char) -> *mut c_void {
    fn internal_fn(settings: *mut c_char) -> Result<u64, String> {
        let settings = settings.from_ptr();
        let settings = serde_json::from_str::<GqlNetworkSettings>(&settings).handle_error()?;

        let client = GqlClient::new(settings).handle_error()?;

        let gql_connection = GqlConnectionImpl { client };
        let gql_connection = Arc::new(gql_connection);

        let gql_transport = GqlTransport::new(gql_connection);
        let gql_transport = Box::new(Arc::new(gql_transport));

        let ptr = Box::into_raw(gql_transport) as *mut c_void as c_ulonglong;

        Ok(ptr)
    }

    internal_fn(settings).match_result()
}

#[no_mangle]
pub unsafe extern "C" fn clone_gql_transport_ptr(gql_transport: *mut c_void) -> *mut c_void {
    let gql_transport = gql_transport as *mut Arc<GqlTransport>;
    let cloned = Arc::clone(&*gql_transport);

    Arc::into_raw(cloned) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn free_gql_transport_ptr(gql_transport: *mut c_void) {
    let gql_transport = gql_transport as *mut Arc<GqlTransport>;

    let _ = Box::from_raw(gql_transport);
}

#[no_mangle]
pub unsafe extern "C" fn get_latest_block_id(
    result_port: c_longlong,
    gql_transport: *mut c_void,
    address: *mut c_char,
) {
    let gql_transport = gql_transport as *mut GqlTransport;
    let gql_transport = Arc::from_raw(gql_transport);

    let address = address.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            gql_transport: Arc<GqlTransport>,
            address: String,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let latest_block_id = gql_transport
                .get_latest_block(&address)
                .await
                .handle_error()?
                .id
                .to_ptr() as c_ulonglong;

            Ok(latest_block_id)
        }

        let result = internal_fn(gql_transport, address).await.match_result();

        send_to_result_port(result_port, result);
    });
}

#[no_mangle]
pub unsafe extern "C" fn wait_for_next_block_id(
    result_port: c_longlong,
    gql_transport: *mut c_void,
    current_block_id: *mut c_char,
    address: *mut c_char,
    timeout: c_ulonglong,
) {
    let gql_transport = gql_transport as *mut GqlTransport;
    let gql_transport = Arc::from_raw(gql_transport);

    let current_block_id = current_block_id.from_ptr();
    let address = address.from_ptr();

    runtime!().spawn(async move {
        async fn internal_fn(
            gql_transport: Arc<GqlTransport>,
            current_block_id: String,
            address: String,
            timeout: u64,
        ) -> Result<u64, String> {
            let address = parse_address(&address)?;

            let timeout = Duration::from_millis(timeout);

            let next_block_id = gql_transport
                .wait_for_next_block(&current_block_id, &address, timeout)
                .await
                .handle_error()?
                .to_ptr() as c_ulonglong;

            Ok(next_block_id)
        }

        let result = internal_fn(gql_transport, current_block_id, address, timeout)
            .await
            .match_result();

        send_to_result_port(result_port, result);
    });
}
