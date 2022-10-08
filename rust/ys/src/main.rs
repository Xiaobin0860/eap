use anyhow::Result;
use clap::Parser;
use std::path::Path;
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
    info!("Finding {} offsets in {} ...", &args.gv, &args.gd);

    let patterns_file = Path::new(&args.gd).join("patterns.json");
    trace!("patterns_file={patterns_file:?}");
    let patterns_string = std::fs::read_to_string(patterns_file)?;
    let patterns: Vec<HookInfo> = serde_json::from_str(&patterns_string)?;
    debug!("patterns count: {}", patterns.len());
    for pattern in patterns.iter() {
        trace!("{pattern:?}");
    }

    Ok(())
}
