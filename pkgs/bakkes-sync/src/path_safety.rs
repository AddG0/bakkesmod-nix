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
