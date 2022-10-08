use anyhow::Result;
use clap::Parser;
use regex::Regex;
use std::io::{self, Write};
use std::path::Path;
use std::{fs, io::BufRead};
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
    let patterns_file = &rys.join("patterns.json");
    trace!("patterns_file={patterns_file:?}, funcs_file={funcs_file:?}, types_file={types_file:?}");
    let patterns_string = fs::read_to_string(patterns_file)?;
    let mut patterns: Vec<HookInfo> = serde_json::from_str(&patterns_string)?;
    debug!("patterns count: {}", patterns.len());

    let lines: Vec<String> = io::BufReader::new(fs::File::open(funcs_file)?)
        .lines()
        .into_iter()
        .map(|s| s.unwrap())
        .collect();
    debug!("func_lines size: {}", lines.len());
    let mut app = io::BufWriter::new(fs::File::create(od.join("Application.h"))?);
    for line in lines.iter() {
        if line.contains(", Application_") {
            app.write_all(line.as_bytes())?;
            app.write_all("\n".as_bytes())?;
        }
    }
    app.flush()?;
    for pattern in patterns.iter_mut() {
        trace!("{pattern:?}");
        let re = Regex::new(&pattern.mp)?;
        let info = &pattern.search_type(&re, &lines).unwrap();
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
