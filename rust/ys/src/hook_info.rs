use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct HookInfo {
    pub name: String,
    pub mp: String,
    pub tp: String,
}
