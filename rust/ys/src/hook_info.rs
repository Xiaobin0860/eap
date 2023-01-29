use regex::Regex;
use serde::{Deserialize, Serialize};
use std::fmt::Display;
use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;
use tracing::{debug, trace};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct HookInfo {
    pub name: String,
    pub mp: String,
    pub tp: Option<String>,
    pub xp: Option<String>,
    pub ename: Option<String>,
    pub methods: Option<Vec<MethodInfo>>,
}

#[derive(Default)]
pub struct TypeInfo {
    pub name: String,
    pub ename: String,
    pub methods: Vec<String>,
    pub typdef: String,
}

impl TypeInfo {
    pub fn new(name: String, ename: String) -> Self {
        Self {
            name,
            ename,
            methods: Vec::new(),
            ..Default::default()
        }
    }

    pub fn write_to_file(&self, out: &PathBuf) {
        let mut w = io::BufWriter::new(fs::File::create(out).unwrap());
        w.write_all(self.typdef.as_bytes()).unwrap();
        w.write_all("\n".as_bytes()).unwrap();
        for l in self.methods.iter() {
            w.write_all(l.as_bytes()).unwrap();
            w.write_all("\n".as_bytes()).unwrap();
        }
        w.flush().unwrap();
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
    pub fn new(name: String, mp: String) -> Self {
        Self {
            name,
            mp,
            ..Default::default()
        }
    }

    pub fn search_type_from_funclines(
        &mut self,
        re: &Regex,
        lines: &Vec<&str>,
        types: &str,
    ) -> Option<TypeInfo> {
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
                self.search_type(types, &mut info);
                return Some(info);
            }
        }
        None
    }

    pub fn search_type_from_typestr(
        &mut self,
        re: &Regex,
        types: &str,
        lines: &Vec<&str>,
    ) -> Option<TypeInfo> {
        if let Some(mat) = re.find(types) {
            //struct NEMKAPOLJCG__Fields {
            //struct __declspec(align(8)) PFIDMOFNNFJ__Fields {
            //struct DDPHHPLKABA LHBAOFDMMFN;
            //struct NAJBLKFGKAI {
            // EJNMNDFACFD* ALJHICJOGIE;
            let mat = mat.as_str();
            let ss: Vec<_> = mat.split('\n').collect();
            let mat = ss[0];
            trace!("mat={mat}");
            let ename = if mat.find("__Fields").is_some() {
                *mat.split("__Fields").collect::<Vec<_>>()[0]
                    .split(' ')
                    .collect::<Vec<_>>()
                    .last()
                    .unwrap()
            } else {
                mat.split(' ').collect::<Vec<_>>()[1]
                    .split('*')
                    .collect::<Vec<_>>()[0]
            };
            debug!("{} => {}", self.name, ename);
            let mut info = TypeInfo::new(self.name.to_owned(), ename.to_owned());
            self.ename = Some(ename.to_owned());
            self.search_methods(lines, &mut info);
            self.search_type(types, &mut info);
            Some(info)
        } else {
            None
        }
    }

    pub fn search_type_from_funcstr(
        &mut self,
        re: &Regex,
        funcs: &str,
        lines: &Vec<&str>,
        types: &str,
    ) -> Option<TypeInfo> {
        if let Some(mat) = re.find(funcs) {
            //DO_APP_FUNC(0x009724B0, void, MLMBKNNFJEI_ReturnToObjectPool, (MLMBKNNFJEI * __this, MethodInfo * method));
            let mat = mat.as_str();
            let ss: Vec<_> = mat.split('\n').collect();
            let mat = ss[0];
            trace!("mat={mat}");
            let ss: Vec<_> = mat.split(',').collect();
            let ss: Vec<_> = ss[2].split('_').collect();
            let ename = &ss[0][1..];
            debug!("{} => {}", self.name, ename);
            let mut info = TypeInfo::new(self.name.to_owned(), ename.to_owned());
            self.ename = Some(ename.to_owned());
            self.search_methods(lines, &mut info);
            self.search_type(types, &mut info);
            Some(info)
        } else {
            None
        }
    }

    pub fn isearch(&self, name: &str, ename: &str, flines: &Vec<&str>, types: &str) -> TypeInfo {
        let mut info = TypeInfo::new(name.to_owned(), ename.to_owned());
        self.ios_search_type(types, &mut info);
        self.search_methods(flines, &mut info);
        info
    }

    fn search_methods(&self, lines: &[&str], info: &mut TypeInfo) {
        let re = &format!(r"DO.*, {}_\.*\w+, \(", &info.ename);
        let re = Regex::new(re).unwrap();
        let mut ok = false;
        for line in lines {
            if ok && line.starts_with("DO_APP_FUNC_METHODINFO") {
                info.methods.push(line.replace(&info.ename, &self.name));
                ok = false;
            } else if re.is_match(line) {
                info.methods.push(line.replace(&info.ename, &self.name));
                ok = true;
            } else {
                ok = false;
            }
        }
    }

    fn search_type(&self, types: &str, info: &mut TypeInfo) {
        let re = &format!(r"struct .*{}__Fields \{{.*\n([^}}]*\n)*\}};", &info.ename);
        let re = Regex::new(re).unwrap();
        if let Some(mat) = re.find(types) {
            info.typdef = mat.as_str().replace(&info.ename, &self.name);
        }
    }

    fn ios_search_type(&self, types: &str, info: &mut TypeInfo) {
        let re = &format!(r"struct {}__Fields \{{.*\n([^}}]*\n)*\}};", &info.ename);
        let re = Regex::new(re).unwrap();
        if let Some(mat) = re.find(types) {
            info.typdef = mat.as_str().replace(&info.ename, &self.name);
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
