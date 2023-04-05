fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .out_dir("src/abi")
        .compile(&["proto/abi.proto"], &["proto"])?;

    std::process::Command::new("cargo")
        .args(["fmt", "--", "src/abi/abi.rs"])
        .status()
        .expect("cargo fmt failed");

    println!("cargo:rerun-if-changed=proto/abi.proto");
    println!("cargo:rerun-if-changed=build.rs");

    Ok(())
}
