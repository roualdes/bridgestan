use crate::bs_safe::{BridgeStanError, Result};
use flate2::read::GzDecoder;
use log::info;
use path_absolutize::Absolutize;
use std::{
    env::temp_dir,
    fs,
    path::{Path, PathBuf},
};
use tar::Archive;

pub(crate) const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Download and unzip the BridgeStan source distribution for this version
/// to ~/.bridgestan/bridgestan-version
pub fn get_bridgestan_src() -> Result<PathBuf> {
    let homedir = dirs::home_dir().unwrap_or(temp_dir());

    let bs_path_download_temp = homedir.join(".bridgestan_tmp_dir");
    let bs_path_download = homedir.join(".bridgestan");

    let bs_path_download_temp_join_version =
        bs_path_download_temp.join(format!("bridgestan-{VERSION}"));
    let bs_path_download_join_version = bs_path_download.join(format!("bridgestan-{VERSION}"));

    if !bs_path_download_join_version.exists() {
        info!("Downloading BridgeStan");

        fs::remove_dir_all(&bs_path_download_temp).unwrap_or_default();
        fs::create_dir(&bs_path_download_temp).unwrap_or_default();
        fs::create_dir(&bs_path_download).unwrap_or_default();

        let url = "https://github.com/roualdes/bridgestan/releases/download/".to_owned()
            + format!("v{VERSION}/bridgestan-{VERSION}.tar.gz").as_str();

        let response = ureq::get(url.as_str())
            .call()
            .map_err(|e| BridgeStanError::DownloadFailed(e.to_string()))?;
        let len = response
            .header("Content-Length")
            .and_then(|s| s.parse::<usize>().ok())
            .unwrap_or(50_000_000);

        let mut bytes: Vec<u8> = Vec::with_capacity(len);
        response
            .into_reader()
            .read_to_end(&mut bytes)
            .map_err(|e| BridgeStanError::DownloadFailed(e.to_string()))?;

        let tar = GzDecoder::new(bytes.as_slice());
        let mut archive = Archive::new(tar);
        archive
            .unpack(&bs_path_download_temp)
            .map_err(|e| BridgeStanError::DownloadFailed(e.to_string()))?;

        fs::rename(
            bs_path_download_temp_join_version,
            &bs_path_download_join_version,
        )
        .map_err(|e| BridgeStanError::DownloadFailed(e.to_string()))?;

        fs::remove_dir(bs_path_download_temp).unwrap_or_default();

        info!("Finished downloading BridgeStan");
    }

    Ok(bs_path_download_join_version)
}

/// Compile a Stan Model given a stan_file and the path to BridgeStan
/// if None, then calls get_bridgestan_src() to download BridgeStan
pub fn compile_model<P>(
    stan_file: P,
    stanc_args: Vec<&str>,
    make_args: Vec<&str>,
    bs_path: Option<P>,
) -> Result<PathBuf>
where
    P: AsRef<Path>,
{
    let bs_path = match bs_path {
        Some(path) => path.as_ref().to_owned(),
        None => get_bridgestan_src()?,
    };

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
