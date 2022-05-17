fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .out_dir("src/abi")
        .compile(&["proto/routeguide.proto"], &["proto"])?;
    Ok(())
}
