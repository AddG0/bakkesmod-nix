use std::path::{Component, Path, PathBuf};

/// Reject relative paths containing `..` or that are absolute.
pub fn validate_relative(rel: &Path) -> Result<(), String> {
    for c in rel.components() {
        match c {
            Component::ParentDir => {
                return Err(format!("Path contains '..': {}", rel.display()));
            }
            Component::RootDir | Component::Prefix(_) => {
                return Err(format!("Path is absolute: {}", rel.display()));
            }
            _ => {}
        }
    }
    Ok(())
}

/// Resolve a path that may not fully exist yet (like `realpath -m`).
/// Canonicalizes the longest existing prefix, then appends the rest.
pub fn resolve_nonexistent(path: &Path) -> std::io::Result<PathBuf> {
    if let Ok(canonical) = path.canonicalize() {
        return Ok(canonical);
    }

    // Walk up until we find an existing ancestor
    let mut existing = path.to_path_buf();
    let mut tail = Vec::new();

    loop {
        if existing.exists() {
            let base = existing.canonicalize()?;
            let mut result = base;
            for part in tail.iter().rev() {
                result.push(part);
            }
            return Ok(result);
        }
        match existing.file_name() {
            Some(name) => {
                tail.push(name.to_os_string());
                existing.pop();
            }
            None => return Ok(path.to_path_buf()),
        }
    }
}

/// Verify that `target` is under `base` after resolution.
pub fn ensure_under(target: &Path, base: &Path) -> Result<PathBuf, String> {
    let resolved = resolve_nonexistent(target)
        .map_err(|e| format!("Failed to resolve {}: {e}", target.display()))?;
    let canonical_base = base
        .canonicalize()
        .map_err(|e| format!("Failed to canonicalize base {}: {e}", base.display()))?;

    if resolved.starts_with(&canonical_base) {
        Ok(resolved)
    } else {
        Err(format!(
            "Path escapes data directory: {} (resolved to {})",
            target.display(),
            resolved.display()
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::os::unix::fs::symlink;

    fn scratch(tag: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("bakkes-sync-{tag}"));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        dir.canonicalize().unwrap()
    }

    #[test]
    fn accepts_a_path_that_stays_inside_the_plugin() {
        for ok in ["plugin.dll", "plugins/settings/x.set", "./data/file.bin"] {
            assert!(
                validate_relative(Path::new(ok)).is_ok(),
                "rejected a legitimate path: {ok}"
            );
        }
    }

    #[test]
    fn rejects_a_path_that_climbs_out_with_dotdot() {
        for bad in ["../evil.dll", "plugins/../../evil.dll", ".."] {
            let err = validate_relative(Path::new(bad))
                .expect_err(&format!("accepted a traversal path: {bad}"));
            assert!(err.contains(".."), "error should name the cause: {err}");
        }
    }

    #[test]
    fn rejects_an_absolute_path() {
        let err = validate_relative(Path::new("/etc/passwd")).expect_err("accepted /etc/passwd");
        assert!(err.contains("absolute"), "error should name the cause: {err}");
    }

    #[test]
    fn resolves_a_path_whose_tail_does_not_exist_yet() {
        let base = scratch("resolve-missing-tail");
        let resolved = resolve_nonexistent(&base.join("not/created/yet.dll")).unwrap();

        assert_eq!(resolved, base.join("not/created/yet.dll"));
    }

    #[test]
    fn resolves_through_a_symlinked_ancestor() {
        let base = scratch("resolve-symlink");
        fs::create_dir(base.join("real")).unwrap();
        symlink(base.join("real"), base.join("link")).unwrap();

        let resolved = resolve_nonexistent(&base.join("link/file.dll")).unwrap();

        assert_eq!(resolved, base.join("real/file.dll"));
    }

    #[test]
    fn accepts_a_destination_inside_the_data_directory() {
        let base = scratch("under-ok");

        assert!(ensure_under(&base.join("plugins/a.dll"), &base).is_ok());
    }

    #[test]
    fn rejects_a_destination_that_escapes_the_data_directory() {
        let base = scratch("under-escape");
        let err = ensure_under(&base.join("../outside.dll"), &base)
            .expect_err("accepted a path outside the data directory");

        assert!(err.contains("escapes"), "error should name the cause: {err}");
    }

    #[test]
    fn rejects_a_destination_reached_through_a_symlink_out_of_the_data_directory() {
        let root = scratch("under-symlink");
        let base = root.join("data");
        let outside = root.join("outside");
        fs::create_dir(&base).unwrap();
        fs::create_dir(&outside).unwrap();
        symlink(&outside, base.join("escape")).unwrap();

        let err = ensure_under(&base.join("escape/evil.dll"), &base)
            .expect_err("followed a symlink out of the data directory");

        assert!(err.contains("escapes"), "error should name the cause: {err}");
    }
}
