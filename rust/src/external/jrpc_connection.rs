use std::sync::Arc;

use anyhow::Result;
use async_trait::async_trait;
use nekoton::external::{JrpcConnection, JrpcRequest};
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
    async fn post(&self, req: JrpcRequest) -> Result<String> {
        self.client.post(req).await
    }
}
