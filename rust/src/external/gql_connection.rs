use anyhow::Result;
use async_trait::async_trait;
use nekoton::external::GqlConnection;
use nekoton_transport::gql::GqlClient;
use std::sync::Arc;

pub struct GqlConnectionImpl {
    pub client: Arc<GqlClient>,
}

#[async_trait]
impl GqlConnection for GqlConnectionImpl {
    fn is_local(&self) -> bool {
        false
    }

    async fn post(&self, data: &str) -> Result<String> {
        self.client.post(data).await
    }
}
