mod config;
mod log;
mod manifest;
mod path_safety;
mod plugins;

use std::path::Path;
use std::process::ExitCode;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();

    if args.len() != 4 {
        eprintln!("Usage: bakkes-sync <config|plugins> <manifest-path> <bakkes-data-dir>");
        return ExitCode::FAILURE;
    }

    let command = &args[1];
    let manifest_path = &args[2];
    let bakkes_data = Path::new(&args[3]);

    if !bakkes_data.is_dir() {
        log!("ERROR: BakkesMod data directory not found: {}", bakkes_data.display());
        log!("BakkesMod must be launched at least once to create this directory.");
        return ExitCode::FAILURE;
    }

    let manifest = match manifest::load(manifest_path) {
        Ok(m) => m,
        Err(e) => {
            log!("ERROR: {e}");
            return ExitCode::FAILURE;
        }
    };

    let result = match command.as_str() {
        "config" => config::sync(&manifest, bakkes_data),
        "plugins" => plugins::sync(&manifest, bakkes_data),
        _ => {
            eprintln!("Unknown command: {command}");
            eprintln!("Usage: bakkes-sync <config|plugins> <manifest-path> <bakkes-data-dir>");
            return ExitCode::FAILURE;
        }
    };

    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            log!("ERROR: {e}");
            ExitCode::FAILURE
        }
    }
}
