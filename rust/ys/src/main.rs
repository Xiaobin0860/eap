use anyhow::Result;
use clap::Parser;
use regex::Regex;
use std::collections::{BTreeMap, HashMap};
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
    let ios_od = &rys.join(format!("i{}", &args.gv));

    let pc_dir = &format!("PC{}", &args.gv);
    let ios_dir = &format!("iOS{}", &args.gv);
    let pc_dir = &Path::new(&args.gd)
        .join(pc_dir)
        .join("inject")
        .join("appdata");
    let ios_dir = &Path::new(&args.gd)
        .join(ios_dir)
        .join("inject")
        .join("appdata");
    let funcs_file = &pc_dir.join("il2cpp-functions.h");
    let types_file = &pc_dir.join("il2cpp-types.h");
    let ios_funcs_file = &ios_dir.join("il2cpp-functions.h");
    let ios_types_file = &ios_dir.join("il2cpp-types.h");
    let unencs_file = &rys.join("unencs.json");
    let unencs_string = fs::read_to_string(unencs_file)?;
    let unencs: Vec<String> = serde_json::from_str(&unencs_string)?;
    debug!("unencs count: {}", unencs.len());
    let patterns_file = &rys.join("patterns.json");
    trace!("patterns_file={patterns_file:?}, funcs_file={funcs_file:?}, types_file={types_file:?}, ios_funcs_file={ios_funcs_file:?}, ios_types_file={ios_types_file:?}");
    let patterns_string = fs::read_to_string(patterns_file)?;
    let mut patterns: Vec<HookInfo> = serde_json::from_str(&patterns_string)?;
    debug!("patterns count: {}", patterns.len());
    let types_content = fs::read_to_string(types_file)?;
    let types = types_content.as_str();
    let funcs_content = fs::read_to_string(funcs_file)?;
    let funcs = funcs_content.as_str();
    let lines: Vec<_> = funcs.lines().collect();
    debug!("func_lines size: {}", lines.len());

    //ios
    let ios_types_content = fs::read_to_string(ios_types_file).unwrap_or_default();
    let ios_types = ios_types_content.as_str();
    let ios_funcs_content = fs::read_to_string(ios_funcs_file).unwrap_or_default();
    let ios_funcs = ios_funcs_content.as_str();
    let ios_lines: Vec<_> = ios_funcs.lines().collect();
    debug!("ios_lines size: {}", ios_lines.len());

    //未加密
    for m in unencs.iter() {
        let fname = format!("{}.h", m);
        let pattern = &format!(r"DO.*, {}_\.*\w+(, \(|\))", m);
        let re = Regex::new(pattern)?;
        let td_re = &format!(r"struct .*{}__Fields \{{.*\n([^}}]*\n)*\}};", m);
        let td_re = Regex::new(td_re).unwrap();
        {
            let mut w = io::BufWriter::new(fs::File::create(od.join(&fname))?);
            if let Some(mat) = td_re.find(types) {
                w.write_all(mat.as_str().as_bytes())?;
                w.write_all("\n".as_bytes())?;
            }
            for line in lines.iter() {
                if re.is_match(line) {
                    w.write_all(line.as_bytes())?;
                    w.write_all("\n".as_bytes())?;
                }
            }
            w.flush()?;
        }

        //ios
        if !ios_types.is_empty() {
            let mut ios_w = io::BufWriter::new(fs::File::create(ios_od.join(&fname))?);
            if let Some(mat) = td_re.find(ios_types) {
                ios_w.write_all(mat.as_str().as_bytes())?;
                ios_w.write_all("\n".as_bytes())?;
            }
            for line in ios_lines.iter() {
                if re.is_match(line) {
                    ios_w.write_all(line.as_bytes())?;
                    ios_w.write_all("\n".as_bytes())?;
                }
            }
            ios_w.flush()?;
        }
    }
    let mut name_map = BTreeMap::new();
    let mut xps = Vec::new();
    //找加密串.
    let fnames_file = &rys.join("fnames.json");
    let fnames_string = fs::read_to_string(fnames_file)?;
    let fnames: Vec<FuncName> = serde_json::from_str(&fnames_string)?;
    debug!("fnames count: {}", fnames.len());
    for fname in fnames.iter() {
        let ename = fname.search_ename(funcs);
        try_insert(&mut name_map, &fname.name, ename);
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
        if info.name.find('_').is_some() {
            let names: Vec<_> = info.name.split('_').collect();
            let enames: Vec<_> = info.ename.split('_').collect();
            for i in 0..names.len() {
                try_insert(&mut name_map, names[i], enames[i]);
            }
        } else {
            try_insert(&mut name_map, &info.name, &info.ename);
        }
        //extra
        if let Some(xp) = pattern.xp.as_ref() {
            let xp = xp.as_str();
            let ss: Vec<_> = xp.split('-').collect();
            let mut vars = HashMap::new();
            vars.insert("x".to_string(), info.ename.clone());
            xps.push(HookInfo::new(ss[0].to_owned(), strfmt(ss[1], &vars)?));
        }
        let out = &od.join(format!("{}.h", &info.name));
        debug!("{info}, out={out:?}");
        info.write_to_file(out);

        //ios
        if !ios_types.is_empty() {
            let info = pattern.isearch(&info.name, &info.ename, &ios_lines, ios_types);
            let out = &ios_od.join(format!("{}.h", &info.name));
            info.write_to_file(out);
        }
    }
    //加密二次查找
    search_xps(
        od,
        ios_od,
        &lines,
        types,
        &ios_lines,
        ios_types,
        &mut xps,
        &mut name_map,
    )?;
    //替换密文
    rep_encs(od, &name_map);
    rep_encs(ios_od, &name_map);
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
            try_insert(&mut name_map, &fname.name, ename);
        }
    }
    //再次替换密文
    rep_encs(od, &name_map);
    rep_encs(ios_od, &name_map);
    let hooks_dir = &rys.join("hooks");
    //params
    xps.clear();
    for entry in WalkDir::new(hooks_dir).into_iter().filter_map(|e| e.ok()) {
        let f = entry.path();
        trace!("{}", f.display());
        let ext = f.extension();
        if ext.is_none() || ext.unwrap().to_str().unwrap() != "json" {
            continue;
        }
        let name = f.file_name().unwrap().to_str().unwrap();
        let cname = &name.replace(".json", "");
        let h = &od.join(name.replace(".json", ".h"));
        trace!("{} cname={cname}, h={}", f.display(), h.display());
        let contents = fs::read_to_string(h)?;
        let contents = contents.as_str();
        let hooks = fs::read_to_string(f)?;
        let hooks = hooks.as_str();
        let mut hooks: Vec<AppFunc> = serde_json::from_str(hooks)?;
        for hook in hooks.iter_mut() {
            if let Some(ps) = hook.ps.as_ref() {
                trace!("{hook:?}");
                let re = Regex::new(&hook.mp)?;
                let mat = re.find(contents).unwrap().as_str();
                trace!("{mat}");
                //DO_APP_FUNC(0x05C62210, VCCharacterCombat *, BaseEntity_GetVisualCombatComponent_3, (
                let pms = mat.split(", (").collect::<Vec<_>>()[1];
                //EHOCMLAEENL * __this, uint32_t BKLDHNCDCMG, MethodInfo* method));
                let pms = pms.split(')').collect::<Vec<_>>()[0];
                let pms = pms.split(", ").collect::<Vec<_>>();
                let mut pv = Vec::new();
                for pm in pms {
                    let pm = pm.split(' ').collect::<Vec<_>>();
                    let typ = pm[0].split('*').collect::<Vec<_>>()[0];
                    let name = *pm.last().unwrap();
                    trace!("{typ},{name}");
                    pv.push((typ, name));
                }
                for p in ps {
                    let (typ, name) = pv[p.idx];
                    try_insert(&mut name_map, &p.typ, typ);
                    try_insert(&mut name_map, &p.name, name);
                    let mut hi = HookInfo::default();
                    hi.name = p.typ.clone();
                    xps.push(HookInfo::new(
                        p.typ.clone(),
                        format!(r"DO.*, {}_\w+, \(", typ),
                    ));
                }
            }
        }
    }
    search_xps(
        od,
        ios_od,
        &lines,
        types,
        &ios_lines,
        ios_types,
        &mut xps,
        &mut name_map,
    )?;
    //再次替换密文
    rep_encs(od, &name_map);
    rep_encs(ios_od, &name_map);

    //保存字符串映射
    let s = serde_json::to_string_pretty(&name_map)?;
    let enc = &od.join("name_map.json");
    fs::write(enc, s)?;

    //找hook地址
    gen_hooks(od, hooks_dir)?;

    //ios
    if !ios_types.is_empty() {
        gen_hooks(ios_od, hooks_dir)?;
    }

    Ok(())
}

fn search_xps(
    od: &PathBuf,
    ios_od: &PathBuf,
    lines: &Vec<&str>,
    types: &str,
    ios_lines: &Vec<&str>,
    ios_types: &str,
    xps: &mut Vec<HookInfo>,
    name_map: &mut BTreeMap<String, String>,
) -> Result<()> {
    for pattern in xps.iter_mut() {
        trace!("{pattern:?}");
        let re = Regex::new(&pattern.mp)?;
        let info = pattern
            .search_type_from_funclines(&re, &lines, types)
            .unwrap();
        try_insert(name_map, &info.name, &info.ename);
        let out = &od.join(format!("{}.h", &info.name));
        debug!("{info}, out={out:?}");
        info.write_to_file(out);

        //ios
        if !ios_types.is_empty() {
            let info = pattern.isearch(&info.name, &info.ename, &ios_lines, ios_types);
            let out = &ios_od.join(format!("{}.h", &info.name));
            info.write_to_file(out);
        }
    }
    Ok(())
}

fn rep_encs(od: &PathBuf, name_map: &BTreeMap<String, String>) {
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

fn try_insert(name_map: &mut BTreeMap<String, String>, k: &str, v: &str) {
    if let Some(ref o) = name_map.insert(k.to_owned(), v.to_owned()) {
        if o != v {
            panic!("{k} => {o}!={v}");
        }
    }
}

fn gen_hooks(od: &PathBuf, hooks_dir: &PathBuf) -> Result<()> {
    let out = &od.join("hook.inc");
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
        let cname = &name.replace(".json", "");
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
            //DO_APP_FUNC(0x05C62210, VCCharacterCombat *, BaseEntity_GetVisualCombatComponent_3, (
            let ss = mat.split(',').collect::<Vec<_>>();
            let offset = ss[0].split('(').collect::<Vec<_>>()[1];
            let mut vars = HashMap::new();
            vars.insert("x".to_string(), offset);
            let s = strfmt(&hook.tp, &vars)?;
            w.write_all(s.as_bytes())?;
            w.write_all("\n".as_bytes())?;
            if let Some(mi) = hook.mi.as_ref() {
                let fname = &ss[2][1..];
                let mp = &format!("DO_APP_FUNC_METHODINFO.*{fname}");
                let re = Regex::new(mp)?;
                let mat = re.find(contents).unwrap().as_str();
                trace!("{mat}");
                //DO_APP_FUNC_METHODINFO(0x0A4B8E70,
                let offset = mat.split(',').collect::<Vec<_>>()[0]
                    .split('(')
                    .collect::<Vec<_>>()[1];
                vars.insert("x".to_string(), offset);
                let s = strfmt(mi, &vars)?;
                w.write_all(s.as_bytes())?;
                w.write_all("\n".as_bytes())?;
            }
        }
        w.write_all("\n\n".as_bytes())?;
    }
    w.flush()?;
    Ok(())
}
