use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct AppFunc {
    pub tp: String,
    pub mp: String,
    pub mi: Option<String>,
}
