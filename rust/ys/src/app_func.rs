use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct AppFunc {
    pub tp: String,
    pub mp: String,
    pub xp: Option<String>,
    pub offset: Option<String>,
}
