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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::manifest::Manifest;

    fn fixture(tag: &str) -> std::path::PathBuf {
        let data = std::env::temp_dir().join(format!("bakkes-sync-config-{tag}"));
        let _ = fs::remove_dir_all(&data);
        fs::create_dir_all(&data).unwrap();
        data.canonicalize().unwrap()
    }

    fn manifest(config_content: &str) -> Manifest {
        Manifest {
            config_content: config_content.to_string(),
            plugins: Vec::new(),
        }
    }

    fn autoexec(data: &Path) -> String {
        fs::read_to_string(data.join("cfg/autoexec.cfg")).unwrap()
    }

    #[test]
    fn writes_the_declared_config_and_makes_autoexec_run_it() {
        let data = fixture("writes");

        sync(&manifest("gui_scale \"1.2\"\n"), &data).unwrap();

        assert_eq!(
            fs::read_to_string(data.join("cfg/nix-config.cfg")).unwrap(),
            "gui_scale \"1.2\"\n"
        );
        assert!(
            autoexec(&data).contains("exec nix-config.cfg"),
            "autoexec.cfg never sources the generated config"
        );
    }

    #[test]
    fn replaces_the_previous_generations_config() {
        let data = fixture("replaces");

        sync(&manifest("gui_scale \"1.0\"\n"), &data).unwrap();
        sync(&manifest("gui_scale \"2.0\"\n"), &data).unwrap();

        let written = fs::read_to_string(data.join("cfg/nix-config.cfg")).unwrap();
        assert_eq!(written, "gui_scale \"2.0\"\n", "kept a stale setting");
    }

    #[test]
    fn syncing_repeatedly_sources_the_config_once() {
        let data = fixture("idempotent");

        sync(&manifest(""), &data).unwrap();
        sync(&manifest(""), &data).unwrap();
        sync(&manifest(""), &data).unwrap();

        assert_eq!(
            autoexec(&data).matches("exec nix-config.cfg").count(),
            1,
            "appended a duplicate exec line: {:?}",
            autoexec(&data)
        );
    }

    #[test]
    fn keeps_the_players_own_autoexec_lines() {
        let data = fixture("preserves");
        fs::create_dir_all(data.join("cfg")).unwrap();
        fs::write(data.join("cfg/autoexec.cfg"), "bind F5 \"boost\"\n").unwrap();

        sync(&manifest(""), &data).unwrap();

        let contents = autoexec(&data);
        assert!(contents.contains("bind F5"), "dropped the player's binding: {contents:?}");
        assert!(contents.contains("exec nix-config.cfg"));
    }

    #[test]
    fn does_not_join_its_exec_line_onto_an_unterminated_last_line() {
        let data = fixture("no-newline");
        fs::create_dir_all(data.join("cfg")).unwrap();
        fs::write(data.join("cfg/autoexec.cfg"), "bind F5 \"boost\"").unwrap();

        sync(&manifest(""), &data).unwrap();

        assert!(
            autoexec(&data).lines().any(|l| l.trim() == "exec nix-config.cfg"),
            "exec line was glued to the previous one: {:?}",
            autoexec(&data)
        );
    }
}
