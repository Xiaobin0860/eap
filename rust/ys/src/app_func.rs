use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct ParamInfo {
    pub idx: usize,
    pub typ: Option<String>,
    pub name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct AppFunc {
    pub tp: String,
    pub mp: String,
    pub mi: Option<String>,
    pub ps: Option<Vec<ParamInfo>>,
}
