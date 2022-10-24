use regex::Regex;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct FuncName {
    pub name: String,
    pub fp: String,
}

impl FuncName {
    pub fn search_ename<'a>(&self, contents: &'a str) -> &'a str {
        let fp = self.fp.as_str();
        if fp.starts_with('-') {
            let idx: usize = fp[1..2].parse().unwrap();
            //取参数类型名
            let re = Regex::new(&fp[2..]).unwrap();
            let mat = re.find(contents).unwrap().as_str();
            //LCBase_ListenEvent, (LCBase * __this, PAIDKIKKFCJ * e, Me
            mat.split(',').collect::<Vec<_>>()[idx]
                .split(' ')
                .collect::<Vec<_>>()[1]
        } else if fp.starts_with('+') {
            //取参数名
            let idx: usize = fp[1..2].parse().unwrap();
            let re = Regex::new(&fp[2..]).unwrap();
            let mat = re.find(contents).unwrap().as_str();
            //VCHumanoidMove_IAEEOEMELPD, (VCHumanoidMove * __this, Vector3 GNGMCEBLIKL,
            *mat.split(',').collect::<Vec<_>>()[idx]
                .split(' ')
                .collect::<Vec<_>>()
                .last()
                .unwrap()
        } else {
            //查方法名
            let re = Regex::new(fp).unwrap();
            let mat = re.find(contents).unwrap().as_str();
            let ss = mat.split(',').collect::<Vec<_>>()[1]
                .split('_')
                .collect::<Vec<_>>();
            if mat.find("_1, (").is_some() {
                //void, VCHumanoidMove_IOBHMHCNEPD_1, (
                ss[ss.len() - 2]
            } else {
                //GameObject *, MihoyoRubyTextMeshEffect_MCIBIEJLHJB_CNMMAFCJAKH, (
                ss[ss.len() - 1]
            }
        }
    }
}
