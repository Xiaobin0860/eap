use anyhow::Result;
use clap::Parser;
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::io::{self, Write};
use std::path::Path;
use strfmt::strfmt;
use tracing::{debug, info, trace};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use ys::HookInfo;

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
    let mut xps = Vec::new();
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
        }
        let out = &od.join(format!("{}.h", &info.name));
        debug!("{info}, out={out:?}");
        info.write_to_file(out);
    }
    for pattern in xps.iter_mut() {
        trace!("{pattern:?}");
        let re = Regex::new(&pattern.mp)?;
        let info = pattern
            .search_type_from_funclines(&re, &lines, types)
            .unwrap();
        let out = &od.join(format!("{}.h", &info.name));
        debug!("{info}, out={out:?}");
        info.write_to_file(out);
    }
    Ok(())
}
