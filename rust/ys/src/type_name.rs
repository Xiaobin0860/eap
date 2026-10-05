use regex::Regex;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct TypeName {
    pub name: String,
    pub fp: String,
    pub idx: usize,
}

impl TypeName {
    /// Returns the encrypted name for this pattern, or None if it no longer
    /// matches (game update). Callers must skip on None.
    pub fn search_ename<'a>(&self, contents: &'a str) -> Option<&'a str> {
        let re = Regex::new(&self.fp).ok()?;
        let mat = re.find(contents)?.as_str();
        //DO(xx, DKJFENEJIFH*, LCBase_ListenEvent, (LCBase * __this, PAIDKIKKFCJ * e, Me
        mat.split(',').nth(self.idx)?.split(' ').nth(1)?.split('*').next()
    }
}
