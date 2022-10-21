use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct FuncName {
    pub name: String,
    pub fp: String,
}
