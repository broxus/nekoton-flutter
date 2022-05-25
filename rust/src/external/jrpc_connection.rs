use std::sync::Arc;

use anyhow::Result;
use async_trait::async_trait;
use nekoton::external::JrpcConnection;
use nekoton_transport::jrpc::JrpcClient;

pub struct JrpcConnectionImpl {
    client: Arc<JrpcClient>,
}

impl JrpcConnectionImpl {
    pub fn new(client: Arc<JrpcClient>) -> Self {
        Self { client }
    }
}

#[async_trait]

impl JrpcConnection for JrpcConnectionImpl {
    async fn post(&self, data: &str) -> Result<String> {
        self.client.post(data).await
    }
}
