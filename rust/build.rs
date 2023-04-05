fn main() {
    #[cfg(target_os = "linux")]
    {
        use std::env;
        let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
        cbindgen::Builder::new()
            .with_language(cbindgen::Language::C)
            .with_no_includes()
            .with_crate(crate_dir)
            .with_parse_expand(&["nekoton-flutter"])
            .generate()
            .expect("Unable to generate bindings")
            .write_to_file("gen/bindings.h");
    }
}
