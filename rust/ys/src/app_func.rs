use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct ParamInfo {
    pub idx: usize,
    pub typ: String,
    pub name: String,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct AppFunc {
    pub tp: String,
    pub mp: String,
    pub mi: Option<String>,
    pub ps: Option<Vec<ParamInfo>>,
}
