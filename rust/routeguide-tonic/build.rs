fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("cargo:rerun-if-changed=proto/routeguide.proto");
    println!("cargo:rerun-if-changed=build.rs");

    tonic_build::configure()
        .type_attribute("routeguide.Point", "#[derive(Hash, Eq)]")
        .out_dir("src/abi")
        .compile(&["proto/routeguide.proto"], &["proto"])?;

    std::process::Command::new("cargo")
        .args(["fmt", "--", "src/abi/routeguide.rs"])
        .status()
        .expect("cargo fmt failed");

    Ok(())
}
