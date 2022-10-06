use std::sync::Arc;

use anyhow::Result;
use async_trait::async_trait;
use nekoton::external::{GqlConnection, GqlRequest};
use nekoton_transport::gql::GqlClient;

pub struct GqlConnectionImpl {
    client: Arc<GqlClient>,
    local: bool,
}

impl GqlConnectionImpl {
    pub fn new(client: Arc<GqlClient>, local: bool) -> Self {
        Self { client, local }
    }
}

#[async_trait]
impl GqlConnection for GqlConnectionImpl {
    fn is_local(&self) -> bool {
        self.local
    }

    async fn post(&self, req: GqlRequest) -> Result<String> {
        self.client.post(req).await
    }
}
