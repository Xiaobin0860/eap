use regex::Regex;
use serde::{Deserialize, Serialize};
use std::fmt::Display;
use tracing::{debug, trace};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct HookInfo {
    pub name: String,
    pub mp: String,
    pub tp: Option<String>,
    pub ename: Option<String>,
    pub methods: Option<Vec<MethodInfo>>,
}

#[derive(Default)]
pub struct TypeInfo {
    pub name: String,
    pub ename: String,
    pub methods: Vec<String>,
}

impl TypeInfo {
    pub fn new(name: String, ename: String) -> Self {
        Self {
            name,
            ename,
            methods: Vec::new(),
        }
    }
}

impl Display for TypeInfo {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{{{}, {}, {}}}",
            &self.name,
            &self.ename,
            self.methods.len()
        )
    }
}

impl HookInfo {
    pub fn search_type<'a>(&mut self, re: &Regex, lines: &Vec<String>) -> Option<TypeInfo> {
        for line in lines.iter() {
            if re.is_match(line) {
                trace!("{} match line {}", self.name, line);
                //DO_APP_FUNC(0x030AC1E0, void, FFEKNPFBNFH__ctor_2, (FFEKNPFBNFH * __this,
                let ss: Vec<_> = line.split(',').collect();
                let ss: Vec<_> = ss[2].split('_').collect();
                let ename = &ss[0][1..];
                debug!("{} => {}", self.name, ename);
                let mut info = TypeInfo::new(self.name.to_owned(), ename.to_owned());
                self.ename = Some(ename.to_owned());
                self.search_methods(lines, &mut info);
                return Some(info);
            }
        }
        None
    }

    pub fn search_types<'a>(
        &mut self,
        re: &Regex,
        types: &'a str,
        lines: &Vec<String>,
    ) -> Option<TypeInfo> {
        if let Some(mat) = re.find(types) {
            //struct NEMKAPOLJCG__Fields {
            let ss: Vec<_> = types[mat.start()..mat.end()].split('{').collect();
            let ss: Vec<_> = ss[0].split(' ').collect();
            let ss: Vec<_> = ss[1].split('_').collect();
            let ename = ss[0];
            debug!("{} => {}", self.name, ename);
            let mut info = TypeInfo::new(self.name.to_owned(), ename.to_owned());
            self.ename = Some(ename.to_owned());
            self.search_methods(lines, &mut info);
            Some(info)
        } else {
            None
        }
    }

    fn search_methods(&self, lines: &Vec<String>, info: &mut TypeInfo) {
        let re = &format!(r", {}_\w+, \(", &info.ename);
        let re = Regex::new(re).unwrap();
        let mut ok = false;
        for line in lines.iter() {
            if ok && line.starts_with("DO_APP_FUNC_METHODINFO") {
                info.methods.push(line.to_owned());
                ok = false;
            } else if re.is_match(line) {
                info.methods.push(line.to_owned());
                ok = true;
            } else {
                ok = false;
            }
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct MethodInfo {
    pub fname: String,
    pub mp: Option<String>,
    pub sig: Option<String>,
    pub ename: Option<String>,
    pub idx: usize,
    pub offset: Option<u64>,
}
