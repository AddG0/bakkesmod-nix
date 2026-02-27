use std::fs;
use std::io::Write;
use std::path::Path;

use crate::log;
use crate::manifest::Manifest;

pub fn sync(manifest: &Manifest, bakkes_data: &Path) -> Result<(), String> {
    let cfg_dir = bakkes_data.join("cfg");
    fs::create_dir_all(&cfg_dir)
        .map_err(|e| format!("Failed to create cfg dir: {e}"))?;

    // Write nix-config.cfg atomically via temp+rename
    let nix_config = cfg_dir.join("nix-config.cfg");
    let tmp = cfg_dir.join(".nix-config.cfg.tmp");

    {
        let mut f = fs::File::create(&tmp)
            .map_err(|e| format!("Failed to create temp config: {e}"))?;
        f.write_all(manifest.config_content.as_bytes())
            .map_err(|e| format!("Failed to write config: {e}"))?;
    }

    fs::rename(&tmp, &nix_config)
        .map_err(|e| format!("Failed to rename config: {e}"))?;

    // Ensure autoexec.cfg contains `exec nix-config.cfg`
    let autoexec = cfg_dir.join("autoexec.cfg");
    let exec_line = "exec nix-config.cfg";

    let contents = fs::read_to_string(&autoexec).unwrap_or_default();
    if !contents.lines().any(|l| l.trim() == exec_line) {
        let mut f = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&autoexec)
            .map_err(|e| format!("Failed to open autoexec.cfg: {e}"))?;

        // Ensure trailing newline before appending
        if !contents.is_empty() && !contents.ends_with('\n') {
            f.write_all(b"\n")
                .map_err(|e| format!("Failed to write to autoexec.cfg: {e}"))?;
        }
        writeln!(f, "{exec_line}")
            .map_err(|e| format!("Failed to write exec line: {e}"))?;
        log!("Added nix-config.cfg to autoexec.cfg");
    }

    log!("Config sync complete");
    Ok(())
}
