use anyhow::Result;
use clap::Parser;
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use strfmt::strfmt;
use tracing::{debug, info, trace};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use walkdir::WalkDir;
use ys::{AppFunc, FuncName, HookInfo};

/// Program to find ys-gc offsets
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Dir of ys
    #[arg(long)]
    gd: String,

    /// Ver of ys
    #[arg(long)]
    gv: String,
}

fn main() -> Result<()> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "warn,ys=trace".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let args = Args::parse();
    let rys = &Path::new(&args.gd).join("rys");
    let od = &rys.join(&args.gv);
    info!("Finding {} offsets in {} od={od:?} ...", &args.gv, &args.gd);

    let pc_dir = &format!("PC{}", &args.gv);
    let app_dir = &Path::new(&args.gd)
        .join(pc_dir)
        .join("inject")
        .join("appdata");
    let funcs_file = &app_dir.join("il2cpp-functions.h");
    let types_file = &app_dir.join("il2cpp-types.h");
    let unencs_file = &rys.join("unencs.json");
    let unencs_string = fs::read_to_string(unencs_file)?;
    let unencs: Vec<String> = serde_json::from_str(&unencs_string)?;
    debug!("unencs count: {}", unencs.len());
    let patterns_file = &rys.join("patterns.json");
    trace!("patterns_file={patterns_file:?}, funcs_file={funcs_file:?}, types_file={types_file:?}");
    let patterns_string = fs::read_to_string(patterns_file)?;
    let mut patterns: Vec<HookInfo> = serde_json::from_str(&patterns_string)?;
    debug!("patterns count: {}", patterns.len());
    let types_content = fs::read_to_string(types_file)?;
    let types = types_content.as_str();
    let funcs_content = fs::read_to_string(funcs_file)?;
    let funcs = funcs_content.as_str();
    let lines: Vec<_> = funcs.lines().collect();
    debug!("func_lines size: {}", lines.len());
    //未加密
    for m in unencs.iter() {
        let fname = format!("{}.h", m);
        let pattern = &format!(r", {}_\w+(, \(|\))", m);
        let re = Regex::new(pattern)?;
        let mut w = io::BufWriter::new(fs::File::create(od.join(fname))?);
        for line in lines.iter() {
            if re.is_match(line) {
                w.write_all(line.as_bytes())?;
                w.write_all("\n".as_bytes())?;
            }
        }
        w.flush()?;
    }
    let mut name_map = HashMap::new();
    let mut xps = Vec::new();
    //找加密串.
    let fnames_file = &rys.join("fnames.json");
    let fnames_string = fs::read_to_string(fnames_file)?;
    let fnames: Vec<FuncName> = serde_json::from_str(&fnames_string)?;
    debug!("fnames count: {}", fnames.len());
    for fname in fnames.iter() {
        let ename = fname.search_ename(funcs);
        name_map.insert(fname.name.clone(), ename.to_owned());
    }
    //找加密
    for pattern in patterns.iter_mut() {
        trace!("{pattern:?}");
        let info = &if let Some(tp) = pattern.tp.as_ref() {
            let tp = tp.as_str();
            if tp.starts_with('-') {
                trace!("re={}", &tp[1..]);
                let re = Regex::new(&tp[1..])?;
                pattern
                    .search_type_from_funcstr(&re, funcs, &lines, types)
                    .unwrap()
            } else {
                let re = Regex::new(tp)?;
                pattern
                    .search_type_from_typestr(&re, types, &lines)
                    .unwrap()
            }
        } else {
            let re = Regex::new(&pattern.mp)?;
            pattern
                .search_type_from_funclines(&re, &lines, types)
                .unwrap()
        };
        if let Some(xp) = pattern.xp.as_ref() {
            let xp = xp.as_str();
            let ss: Vec<_> = xp.split('-').collect();
            let mut vars = HashMap::new();
            vars.insert("x".to_string(), info.ename.clone());
            xps.push(HookInfo::new(ss[0].to_owned(), strfmt(ss[1], &vars)?));
        } else {
            name_map.insert(info.name.clone(), info.ename.clone());
        }
        let out = &od.join(format!("{}.h", &info.name));
        debug!("{info}, out={out:?}");
        info.write_to_file(out);
    }
    //加密二次查找
    for pattern in xps.iter_mut() {
        trace!("{pattern:?}");
        let re = Regex::new(&pattern.mp)?;
        let info = pattern
            .search_type_from_funclines(&re, &lines, types)
            .unwrap();
        name_map.insert(info.name.clone(), info.ename.clone());
        let out = &od.join(format!("{}.h", &info.name));
        debug!("{info}, out={out:?}");
        info.write_to_file(out);
    }
    //替换密文
    rep_encs(od, &name_map);
    //再次找加密串.
    let beebyte_dir = &rys.join("beebyte");
    for entry in WalkDir::new(beebyte_dir).into_iter().filter_map(|e| e.ok()) {
        let f = entry.path();
        trace!("{}", f.display());
        let ext = f.extension();
        if ext.is_none() || ext.unwrap().to_str().unwrap() != "json" {
            continue;
        }
        let name = f.file_name().unwrap().to_str().unwrap();
        let cname = name.split('.').collect::<Vec<_>>()[0];
        let h = &od.join(name.replace(".json", ".h"));
        trace!("{} cname={cname}, h={}", f.display(), h.display());
        let contents = fs::read_to_string(h)?;
        let contents = contents.as_str();
        let fnames_string = fs::read_to_string(f)?;
        let fnames: Vec<FuncName> = serde_json::from_str(&fnames_string)?;
        debug!("fnames count: {}", fnames.len());
        for fname in fnames.iter() {
            let ename = fname.search_ename(contents);
            name_map.insert(fname.name.clone(), ename.to_owned());
        }
    }
    //保存字符串映射
    let s = serde_json::to_string_pretty(&name_map)?;
    let enc = &od.join("name_map.json");
    fs::write(enc, s)?;
    //再次替换密文
    rep_encs(od, &name_map);
    //找hook地址
    let hooks_dir = &rys.join("hooks");
    let out = &od.join("hook.cpp");
    debug!("hooks_dir={}, out={}", hooks_dir.display(), out.display());
    let mut w = io::BufWriter::new(fs::File::create(out)?);
    for entry in WalkDir::new(hooks_dir).into_iter().filter_map(|e| e.ok()) {
        let f = entry.path();
        trace!("{}", f.display());
        let ext = f.extension();
        if ext.is_none() || ext.unwrap().to_str().unwrap() != "json" {
            continue;
        }
        let name = f.file_name().unwrap().to_str().unwrap();
        let cname = name.split('.').collect::<Vec<_>>()[0];
        let h = &od.join(name.replace(".json", ".h"));
        trace!("{} cname={cname}, h={}", f.display(), h.display());
        w.write_all("// ".as_bytes())?;
        w.write_all(cname.as_bytes())?;
        w.write_all("\n".as_bytes())?;
        let contents = fs::read_to_string(h)?;
        let contents = contents.as_str();
        let hooks = fs::read_to_string(f)?;
        let hooks = hooks.as_str();
        let mut hooks: Vec<AppFunc> = serde_json::from_str(hooks)?;
        for hook in hooks.iter_mut() {
            trace!("{hook:?}");
            let re = Regex::new(&hook.mp)?;
            let mat = re.find(contents).unwrap().as_str();
            trace!("{mat}");
            //(0x009724B0,
            let offset = mat.split(',').collect::<Vec<_>>()[0]
                .split('(')
                .collect::<Vec<_>>()[1];
            hook.offset = Some(offset.into());
            let mut vars = HashMap::new();
            vars.insert("x".to_string(), offset);
            let s = strfmt(&hook.tp, &vars)?;
            w.write_all(s.as_bytes())?;
            w.write_all("\n".as_bytes())?;
        }
        w.write_all("\n\n".as_bytes())?;
    }
    w.flush()?;
    Ok(())
}

fn rep_encs(od: &PathBuf, name_map: &HashMap<String, String>) {
    trace!("rep str in {} ...", od.display());
    for entry in WalkDir::new(od).into_iter().filter_map(|e| e.ok()) {
        let f = entry.path();
        trace!("{}", f.display());
        let ext = f.extension();
        if ext.is_none() || ext.unwrap().to_str().unwrap() != "h" {
            continue;
        }
        debug!("rep enc str in {}", f.display());
        let mut s = fs::read_to_string(f).unwrap();
        for (k, v) in name_map.iter() {
            s = s.replace(v, k);
        }
        fs::write(f, s).unwrap();
    }
}
