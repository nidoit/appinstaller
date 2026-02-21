fn main() {
    println!("cargo::rerun-if-changed=packages.toml");
    tauri_build::build()
}
