use crate::{
    helpers::parse_public_key,
    match_result,
    models::{FromPtr, HandleError, NativeError, NativeStatus},
    runtime, send_to_result_port, RUNTIME,
};
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use bb8::{Pool, PooledConnection};
use nekoton::external::AdnlConnection;
use serde::{Deserialize, Serialize};
use std::{
    convert::TryFrom,
    ffi::c_void,
    net::SocketAddrV4,
    ops::DerefMut,
    os::raw::{c_char, c_longlong, c_ulonglong},
    sync::{atomic::Ordering, Arc},
    time::Duration,
    u64,
};
use tiny_adnl::{AdnlTcpClient, AdnlTcpClientConfig};
use tokio::sync::Mutex;
use ton_api::ton;

pub type MutexAdnlConnection = Mutex<Arc<AdnlConnectionImpl>>;

#[no_mangle]
pub unsafe extern "C" fn get_adnl_connection(result_port: c_longlong, adnl_config: *mut c_char) {
    let adnl_config = adnl_config.from_ptr();

    let rt = runtime!();
    rt.spawn(async move {
        let result = internal_get_adnl_connection(adnl_config).await;
        let result = match_result(result);
        send_to_result_port(result_port, result);
    });
}

async fn internal_get_adnl_connection(adnl_config: String) -> Result<u64, NativeError> {
    let adnl_config = serde_json::from_str::<AdnlConfig>(&adnl_config)
        .handle_error(NativeStatus::ConversionError)?;
    let adnl_manage_connection =
        AdnlManageConnection::new(&adnl_config).handle_error(NativeStatus::ConnectionError)?;
    let builder = Pool::builder();
    let pool = builder
        .max_size(adnl_config.max_connection_count)
        .min_idle(adnl_config.min_idle_connection_count)
        .max_lifetime(None)
        .build(adnl_manage_connection)
        .await
        .handle_error(NativeStatus::ConnectionError)?;

    let connection = AdnlConnectionImpl { pool };
    let connection = Arc::new(connection);
    let connection = Mutex::new(connection);
    let connection = Arc::new(connection);

    let ptr = Arc::into_raw(connection) as *mut c_void;
    let ptr = ptr as c_ulonglong;

    Ok(ptr)
}

#[no_mangle]
pub unsafe extern "C" fn free_adnl_connection(adnl_connection: *mut c_void) {
    let adnl_connection = adnl_connection as *mut MutexAdnlConnection;
    Arc::from_raw(adnl_connection);
}

pub struct AdnlConnectionImpl {
    pool: Pool<AdnlManageConnection>,
}

#[async_trait]
impl AdnlConnection for AdnlConnectionImpl {
    async fn query(&self, request: ton::TLObject) -> Result<ton::TLObject> {
        let connection = self.pool.get().await.map_err(|e| anyhow!("{:#?}", e))?;

        let response = connection
            .query(&request)
            .await
            .map_err(|e| anyhow!("{}", e))?;

        Ok(response)
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct AdnlConfig {
    pub server_address: SocketAddrV4,
    pub server_key: String,
    pub max_connection_count: u32,
    pub min_idle_connection_count: Option<u32>,
    pub socket_read_timeout: Duration,
    pub socket_send_timeout: Duration,
    pub last_block_threshold: Duration,
    pub ping_timeout: Duration,
}

impl TryFrom<&AdnlConfig> for AdnlTcpClientConfig {
    type Error = anyhow::Error;

    fn try_from(c: &AdnlConfig) -> Result<Self> {
        Ok(AdnlTcpClientConfig {
            server_address: c.server_address,
            server_key: parse_public_key(&c.server_key)
                .map_err(|e| anyhow!("Invalid server key"))?,
            socket_read_timeout: c.socket_read_timeout,
            socket_send_timeout: c.socket_send_timeout,
        })
    }
}

pub struct AdnlManageConnection {
    config: AdnlTcpClientConfig,
    ping_timeout: Duration,
}

impl AdnlManageConnection {
    pub fn new(config: &AdnlConfig) -> Result<Self> {
        Ok(Self {
            config: AdnlTcpClientConfig::try_from(config)?,
            ping_timeout: config.ping_timeout,
        })
    }
}

#[async_trait]
impl bb8::ManageConnection for AdnlManageConnection {
    type Connection = Arc<AdnlTcpClient>;
    type Error = anyhow::Error;

    async fn connect(&self) -> Result<Self::Connection, Self::Error> {
        log::debug!("Establishing adnl connection...");
        match AdnlTcpClient::connect(self.config.clone()).await {
            Ok(connection) => {
                log::debug!("Established adnl connection");
                Ok(connection)
            }
            Err(e) => {
                log::debug!("Failed to establish adnl connection");
                Err(e)
            }
        }
    }

    async fn is_valid(&self, conn: &mut PooledConnection<'_, Self>) -> Result<(), Self::Error> {
        log::trace!("Check if connection is valid...");
        match conn.deref_mut().ping(self.ping_timeout).await {
            Ok(_) => {
                log::trace!("Connection is valid");
                Ok(())
            }
            Err(e) => {
                log::trace!("Connection is invalid");
                Err(e)
            }
        }
    }

    fn has_broken(&self, connection: &mut Self::Connection) -> bool {
        connection.has_broken.load(Ordering::Acquire)
    }
}
