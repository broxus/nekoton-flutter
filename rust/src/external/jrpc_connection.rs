use anyhow::Result;
use async_trait::async_trait;
use nekoton::external::JrpcConnection;
use nekoton_transport::jrpc::JrpcClient;
use std::sync::Arc;

pub struct JrpcConnectionImpl {
    pub client: Arc<JrpcClient>,
}

#[async_trait]
impl JrpcConnection for JrpcConnectionImpl {
    async fn post(&self, data: &str) -> Result<String> {
        self.client.post(data).await
    }
}
