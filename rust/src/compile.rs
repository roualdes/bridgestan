use crate::bs_safe::{BridgeStanError, Result};
use log::info;
use path_absolutize::Absolutize;
use std::path::{Path, PathBuf};

const MAKE: &str = if cfg!(target_os = "windows") {
    "mingw32-make"
} else {
    "make"
};

/// Compile a Stan Model. Requires a path to the BridgeStan sources (can be
/// downloaded with [`download_bridgestan_src`](crate::download_bridgestan_src) if that feature
/// is enabled), a path to the `.stan` file, and additional arguments
/// for the Stan compiler and the make command.
pub fn compile_model(
    bs_path: &Path,
    stan_file: &Path,
    stanc_args: &[&str],
    make_args: &[&str],
) -> Result<PathBuf> {
    // using path_absolutize crate for now since
    // std::fs::canonicalize doesn't behave well on windows
    // we may switch to std::path::absolute once it stabilizes, see
    // https://github.com/roualdes/bridgestan/pull/212#discussion_r1513375667
    let stan_file = stan_file
        .absolutize()
        .map_err(|e| BridgeStanError::ModelCompilingFailed(e.to_string()))?;

    // get --include-paths=model_dir
    let includir_stan_file_dir = stan_file
        .parent()
        .and_then(Path::to_str)
        .map(|x| format!("--include-paths={x}"))
        .unwrap_or_default();

    let includir_stan_file_dir = includir_stan_file_dir.as_str();

    if stan_file.extension().unwrap_or_default() != "stan" {
        return Err(BridgeStanError::ModelCompilingFailed(
            "File must be a .stan file".to_owned(),
        ));
    }

    // add _model suffix and change extension to .so
    let output = stan_file.with_extension("");
    let output = output.with_file_name(format!(
        "{}_model",
        output.file_name().unwrap_or_default().to_string_lossy()
    ));
    let output = output.with_extension("so");

    let stanc_args = [&[includir_stan_file_dir], stanc_args].concat();
    let stanc_args = stanc_args.join(" ");
    let stanc_args = format!("STANCFLAGS={}", stanc_args);
    let stanc_args = [stanc_args.as_str()];

    let cmd = [
        &[output.to_str().unwrap_or_default()],
        make_args,
        stanc_args.as_slice(),
    ]
    .concat();

    info!(
        "Compiling model with command: {} \"{}\"",
        MAKE,
        cmd.join("\" \"")
    );
    std::process::Command::new(MAKE)
        .args(cmd)
        .current_dir(bs_path)
        .env("STAN_THREADS", "true")
        .output()
        .map_err(|e| e.to_string())
        .and_then(|proc| {
            if !proc.status.success() {
                Err(format!(
                    "{} {}",
                    String::from_utf8_lossy(proc.stdout.as_slice()).into_owned(),
                    String::from_utf8_lossy(proc.stderr.as_slice()).into_owned(),
                ))
            } else {
                Ok(())
            }
        })
        .map_err(|e| BridgeStanError::ModelCompilingFailed(e.to_string()))?;
    info!("Finished compiling model");

    Ok(output)
}
