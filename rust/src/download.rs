use crate::bs_safe::{BridgeStanError, Result};
use crate::VERSION;
use flate2::read::GzDecoder;
use log::info;
use std::{env::temp_dir, fs, path::PathBuf};
use tar::Archive;

/// Download and unzip the BridgeStan source distribution for this version
/// to `~/.bridgestan/bridgestan-$VERSION`.
/// Requires feature `download-bridgestan-src`.
pub fn download_bridgestan_src() -> Result<PathBuf> {
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
