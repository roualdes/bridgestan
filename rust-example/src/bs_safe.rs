use crate::bs_unsafe;
use std::ffi::CStr;
use std::ffi::CString;
use std::ffi::NulError;
use std::str::Utf8Error;

// This is more or less equivalent to manually defining Display and From<other error types>
use thiserror::Error;

#[derive(Error, Debug)]
pub enum BridgeStanError {
    #[error("failed to encode string to null-terminated C string")]
    StringEncodeError(#[from] NulError),
    #[error("failed to decode string to UTF8")]
    StringDecodeError(#[from] Utf8Error),
    #[error("failed to allocate model_rng")]
    AllocateFailedError,
    #[error("failed evaluate function, see C stderr")]
    EvaluationFailed,
}

/// Safe wrapper for BridgeStan C functions
#[non_exhaustive]
pub struct StanModel {
    model: *mut bs_unsafe::model_rng,
}

impl StanModel {
    pub fn new(path: &str, seed: u32, chain_id: u32) -> Result<Self, BridgeStanError> {
        let data = CString::new(path)?.into_raw();

        let model = unsafe { bs_unsafe::construct(data, seed, chain_id) };

        // retake pointer to free memory
        let _ = unsafe { CString::from_raw(data) };

        if model.is_null() {
            return Err(BridgeStanError::AllocateFailedError);
        }
        Ok(StanModel { model })
    }

    pub fn name(&self) -> Result<&str, BridgeStanError> {
        let cstr = unsafe { CStr::from_ptr(bs_unsafe::name(self.model)) };
        let res = cstr.to_str()?;
        Ok(res)
    }

    pub fn param_num(&self, include_tp: bool, include_gq: bool) -> usize {
        unsafe { bs_unsafe::param_num(self.model, include_tp as i32, include_gq as i32) }
            .try_into()
            .unwrap()
    }

    pub fn param_unc_num(&self) -> usize {
        unsafe { bs_unsafe::param_unc_num(self.model) }
            .try_into()
            .unwrap()
    }

    pub fn log_density_gradient(
        &self,
        theta: &Vec<f64>,
        propto: bool,
        jacobian: bool,
    ) -> Result<(f64, Vec<f64>), BridgeStanError> {
        let n = self.param_unc_num();
        if theta.len() < n {
            panic!("Size of theta is not large enough")
        }
        let mut grad = vec![0.0; n];
        let mut val = 0.0;
        let rc = unsafe {
            bs_unsafe::log_density_gradient(
                self.model,
                propto as i32,
                jacobian as i32,
                theta.as_ptr(),
                &mut val,
                grad.as_mut_ptr(),
            )
        };

        if rc == 0 {
            Ok((val, grad))
        } else {
            Err(BridgeStanError::EvaluationFailed)
        }
    }

    // etc, need more functions
}

impl Drop for StanModel {
    fn drop(&mut self) {
        if unsafe { bs_unsafe::destruct(self.model) } != 0 {
            panic!("Deallocating model_rng failed")
        }
    }
}
