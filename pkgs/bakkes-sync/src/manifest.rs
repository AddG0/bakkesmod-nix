use serde::Deserialize;

#[derive(Deserialize)]
pub struct Manifest {
    pub config_content: String,
    pub plugins: Vec<Plugin>,
}

#[derive(Deserialize)]
pub struct Plugin {
    pub name: String,
    pub source_dir: String,
}

pub fn load(path: &str) -> Result<Manifest, String> {
    let data = std::fs::read_to_string(path)
        .map_err(|e| format!("Failed to read manifest {path}: {e}"))?;
    serde_json::from_str(&data)
        .map_err(|e| format!("Failed to parse manifest: {e}"))
}
