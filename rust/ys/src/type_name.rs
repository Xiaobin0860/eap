use regex::Regex;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct TypeName {
    pub name: String,
    pub fp: String,
    pub idx: usize,
}

impl TypeName {
    pub fn search_ename<'a>(&self, contents: &'a str) -> &'a str {
        let re = Regex::new(&self.fp).unwrap();
        let mat = re.find(contents).unwrap().as_str();
        //DO(xx, DKJFENEJIFH*, LCBase_ListenEvent, (LCBase * __this, PAIDKIKKFCJ * e, Me
        mat.split(',').collect::<Vec<_>>()[self.idx]
            .split(' ')
            .collect::<Vec<_>>()[1]
            .split('*')
            .collect::<Vec<_>>()[0]
    }
}
