use regex::Regex;
use serde::{Deserialize, Serialize};
use tracing::{trace, warn};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct FuncName {
    pub name: String,
    pub fp: String,
}

impl FuncName {
    /// Returns the encrypted name for this pattern, or None if the pattern no
    /// longer matches (e.g. after a game update). Callers must skip on None.
    pub fn search_ename<'a>(&self, contents: &'a str) -> Option<&'a str> {
        let fp = self.fp.as_str();
        if fp.starts_with('-') {
            let idx: usize = fp[1..2].parse().ok()?;
            //取参数类型名
            let re = Regex::new(&fp[2..]).ok()?;
            let mat = re.find(contents)?.as_str();
            //LCBase_ListenEvent, (LCBase * __this, PAIDKIKKFCJ * e, Me
            mat.split(',').nth(idx)?.split(' ').nth(1)?.split('*').next()
        } else if fp.starts_with('+') {
            //取参数名
            let idx: usize = fp[1..2].parse().ok()?;
            let re = Regex::new(&fp[2..]).ok()?;
            let mat = re.find(contents)?.as_str();
            //VCHumanoidMove_IAEEOEMELPD, (VCHumanoidMove * __this, Vector3 GNGMCEBLIKL,
            mat.split(',').nth(idx)?.split(' ').last()
        } else {
            //查方法名
            let re = Regex::new(fp).ok()?;
            trace!("fp={fp}");
            let mat = re.find(contents)?.as_str();
            trace!("mat={mat}");
            let ss: Vec<_> = mat.split(',').nth(1)?.split('_').collect();
            let nre = Regex::new(r", \w+_\d+, \(").unwrap();
            if nre.is_match(mat) {
                //void, VCHumanoidMove_IOBHMHCNEPD_1, (
                ss.get(ss.len().checked_sub(2)?).copied()
            } else {
                //GameObject *, MihoyoRubyTextMeshEffect_MCIBIEJLHJB_CNMMAFCJAKH, (
                ss.last().copied()
            }
        }
    }
}
