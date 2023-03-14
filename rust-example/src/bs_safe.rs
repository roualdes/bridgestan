use crate::ffi;
use std::ffi::CStr;
use std::ffi::CString;
use std::ffi::NulError;
use std::str::Utf8Error;

// This is more or less equivalent to manually defining Display and From<other error types>
use thiserror::Error;

#[derive(Error, Debug, PartialEq, Eq)]
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
    model: *mut ffi::bs_model_rng,
}

// BridgeStan model is thread safe
unsafe impl Send for StanModel {}
unsafe impl Sync for StanModel {}

impl StanModel {
    /// Create a new instance of the compiled Stan model.
    /// Data is specified as a JSON file at the given path, or empty for no data
    /// Seed and chain ID are used for reproducibility.
    pub fn new(path: &str, seed: u32, chain_id: u32) -> Result<Self, BridgeStanError> {
        let data = CString::new(path)?.into_raw();

        let model = unsafe { ffi::bs_construct(data, seed, chain_id) };

        // retake pointer to free memory
        let _ = unsafe { CString::from_raw(data) };

        if model.is_null() {
            return Err(BridgeStanError::AllocateFailedError);
        }
        Ok(StanModel { model })
    }

    /// Return the name of the model or error if UTF decode fails
    pub fn name(&self) -> Result<&str, BridgeStanError> {
        let cstr = unsafe { CStr::from_ptr(ffi::bs_name(self.model)) };
        let res = cstr.to_str()?;
        Ok(res)
    }

    /// Number of parameters in the model on the constrained scale.
    /// Will also count transformed parameters and generated quantities if requested
    pub fn param_num(&self, include_tp: bool, include_gq: bool) -> usize {
        unsafe { ffi::bs_param_num(self.model, include_tp as i32, include_gq as i32) }
            .try_into()
            .unwrap()
    }

    /// Return the number of parameters on the unconstrained scale.
    /// In particular, this is the size of the slice required by the log_density functions.
    pub fn param_unc_num(&self) -> usize {
        unsafe { ffi::bs_param_unc_num(self.model) }
            .try_into()
            .unwrap()
    }

    pub fn log_density_gradient<'a>(
        &self,
        theta: &[f64],
        propto: bool,
        jacobian: bool,
        out: &'a mut [f64],
    ) -> Result<(f64, &'a mut [f64]), BridgeStanError> {
        let n = self.param_unc_num();
        assert_eq!(
            theta.len(),
            n,
            "Argument 'theta' must be the same size as the number of parameters!"
        );
        assert_eq!(
            out.len(),
            n,
            "Argument 'out' must be the same size as the number of parameters!"
        );

        let mut val = 0.0;
        let rc = unsafe {
            ffi::bs_log_density_gradient(
                self.model,
                propto as i32,
                jacobian as i32,
                theta.as_ptr(),
                &mut val,
                out.as_mut_ptr(),
            )
        };

        if rc == 0 {
            Ok((val, out))
        } else {
            Err(BridgeStanError::EvaluationFailed)
        }
    }

    pub fn param_constrain<'a>(
        &self,
        theta_unc: &[f64],
        include_tp: bool,
        include_gq: bool,
        out: &'a mut [f64],
    ) -> Result<&'a mut [f64], BridgeStanError> {
        let n = self.param_unc_num();
        assert_eq!(
            theta_unc.len(),
            n,
            "Argument 'theta_unc' must be the same size as the number of parameters!"
        );
        let out_n = self.param_num(include_tp, include_gq);
        assert_eq!(
            out.len(),
            out_n,
            "Argument 'out' must be the same size as the number of parameters!"
        );

        let rc = unsafe {
            ffi::bs_param_constrain(
                self.model,
                include_tp as i32,
                include_gq as i32,
                theta_unc.as_ptr(),
                out.as_mut_ptr(),
            )
        };

        if rc == 0 {
            Ok(out)
        } else {
            Err(BridgeStanError::EvaluationFailed)
        }
    }

    // etc, need more functions
}

impl Drop for StanModel {
    /// Free the memory allocated in C++. Panics if deallocation fails
    fn drop(&mut self) {
        if unsafe { ffi::bs_destruct(self.model) } != 0 {
            panic!("Deallocating model_rng failed")
        }
    }
}

#[cfg(feature = "nuts")]
use nuts_rs::{CpuLogpFunc, LogpError};

#[cfg(feature = "nuts")]
impl LogpError for BridgeStanError {
    fn is_recoverable(&self) -> bool {
        return *self == BridgeStanError::EvaluationFailed;
    }
}

#[cfg(feature = "nuts")]
impl CpuLogpFunc for StanModel {
    type Err = BridgeStanError;

    fn dim(&self) -> usize {
        self.param_unc_num()
    }

    fn logp(&mut self, position: &[f64], grad: &mut [f64]) -> Result<f64, Self::Err> {
        let (logp, _grad) = self.log_density_gradient(position, false, true, grad)?;

        Ok(logp)
    }
}
