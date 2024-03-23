use crate::bs_safe::{BridgeStanError, Result};
use log::info;
use path_absolutize::Absolutize;
use std::path::{Path, PathBuf};

/// Compile a Stan Model given the path to BridgeStan and to a stan_file
pub fn compile_model<P>(
    bs_path: P,
    stan_file: P,
    stanc_args: Vec<&str>,
    make_args: Vec<&str>,
) -> Result<PathBuf>
where
    P: AsRef<Path>,
{
    // using path_absolutize crate for now since
    // std::fs::canonicalize doesn't behave well on windows
    // we may switch to std::path::absolute once it stabilizes, see
    // https://github.com/roualdes/bridgestan/pull/212#discussion_r1513375667
    let stan_file = stan_file
        .as_ref()
        .absolutize()
        .map_err(|e| BridgeStanError::ModelCompilingFailed(e.to_string()))?;

    // get --include-paths=model_dir
    let includir_stan_file_dir = stan_file
        .parent()
        .and_then(Path::to_str)
        .map(|x| format!("--include-paths={x}"))
        .map(|x| vec![x])
        .unwrap_or_default();
    let includir_stan_file_dir = includir_stan_file_dir
        .iter()
        .map(String::as_str)
        .collect::<Vec<&str>>();

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

    let stanc_args = [includir_stan_file_dir.as_slice(), stanc_args.as_slice()].concat();
    let stanc_args = stanc_args.join(" ");
    let stanc_args = format!("STANCFLAGS={}", stanc_args);
    let stanc_args = [stanc_args.as_str()];

    let cmd = [
        &[output.to_str().unwrap_or_default()],
        make_args.as_slice(),
        stanc_args.as_slice(),
    ]
    .concat();

    let make = if cfg!(target_os = "windows") {
        "mingw32-make"
    } else {
        "make"
    };
    info!(
        "Compiling model with command: {} \"{}\"",
        make,
        cmd.join("\" \"")
    );
    std::process::Command::new(make)
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
