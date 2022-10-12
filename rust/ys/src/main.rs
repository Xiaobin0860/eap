use anyhow::Result;
use clap::Parser;
use regex::Regex;
use std::fs;
use std::io::{self, Write};
use std::path::Path;
use tracing::{debug, info, trace};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use ys::HookInfo;

static UNENC_MODULES: &[&str] = &[
    "Application",
    "GameManager",
    "MonoInLevelMapPage",
    "CameraState",
    "Miscs",
    "CriwareMediaPlayer",
    "LuaEnv",
    "Lua_xlua",
    "LuaManager",
    "MonoInLevelPlayerProfilePage",
    "MonoFriendInformationDialog",
    "EnviroSky",
    "Camera",
    "GameObject",
    "Transform",
    "Component",
    "Object",
    "Vector3",
    "Renderer",
    "Mathf",
    "Input",
    "Marshal",
    "LocalEntityInfoData",
];

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
    for m in UNENC_MODULES {
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
    for pattern in patterns.iter_mut() {
        trace!("{pattern:?}");
        let info = &if let Some(tp) = pattern.tp.as_ref() {
            let tp = tp.as_str();
            if tp.starts_with('-') {
                trace!("re={}", &tp[1..]);
                let re = Regex::new(&tp[1..])?;
                pattern.search_types(&re, funcs, &lines).unwrap()
            } else {
                let re = Regex::new(tp)?;
                pattern.search_types(&re, types, &lines).unwrap()
            }
        } else {
            let re = Regex::new(&pattern.mp)?;
            pattern.search_type(&re, &lines).unwrap()
        };
        let out = &od.join(format!("{}.h", &info.name));
        debug!("{info}, out={out:?}");
        let mut w = io::BufWriter::new(fs::File::create(out)?);
        for l in info.methods.iter() {
            let l = l.replace(&info.ename, &info.name);
            w.write_all(l.as_bytes())?;
            w.write_all("\n".as_bytes())?;
        }
        w.flush()?;
    }

    Ok(())
}
