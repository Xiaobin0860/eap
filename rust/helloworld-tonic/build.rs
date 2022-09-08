fn main() {
    println!("cargo:rerun-if-changed=proto/helloworld.proto");
    println!("cargo:rerun-if-changed=build.rs");

    tonic_build::compile_protos("proto/helloworld.proto").unwrap();
}
