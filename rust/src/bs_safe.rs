use crate::ffi;
use std::ffi::c_char;
use std::ffi::c_int;
use std::ffi::CStr;
use std::ffi::CString;
use std::ffi::NulError;
use std::ptr::null_mut;
use std::ptr::NonNull;
use std::str::Utf8Error;

// This is more or less equivalent to manually defining Display and From<other error types>
use thiserror::Error;

#[derive(Error, Debug)]
pub enum BridgeStanError {
    #[error("Could not load target library: {0}")]
    LoadLibraryError(#[from] libloading::Error),
    #[error("Bad Stan library version: Got {0} but expected {1}")]
    BadLibraryVersion(String, String),
    #[error("The Stan library was compiled without threading support")]
    StanThreadsError(),
    #[error("failed to encode string to null-terminated C string")]
    StringEncodeError(#[from] NulError),
    #[error("failed to decode string to UTF8")]
    StringDecodeError(#[from] Utf8Error),
    #[error("failed to construct model: {0}")]
    ConstructFailedError(String),
    #[error("failed during evaluation: {0}")]
    EvaluationFailed(String),
}

type Result<T> = std::result::Result<T, BridgeStanError>;

pub fn open_library(path: &std::path::Path) -> Result<ffi::Bridgestan> {
    let library = unsafe { libloading::Library::new(path) }?;
    let major: libloading::Symbol<*const c_int> = unsafe { library.get(b"bs_major_version") }?;
    let major = unsafe { **major };
    let minor: libloading::Symbol<*const c_int> = unsafe { library.get(b"bs_minor_version") }?;
    let minor = unsafe { **minor };
    let patch: libloading::Symbol<*const c_int> = unsafe { library.get(b"bs_patch_version") }?;
    let patch = unsafe { **patch };
    let self_major: c_int = env!("CARGO_PKG_VERSION_MAJOR").parse().unwrap();
    let self_minor: c_int = env!("CARGO_PKG_VERSION_MINOR").parse().unwrap();
    let self_patch: c_int = env!("CARGO_PKG_VERSION_PATCH").parse().unwrap();

    if (self_major != major) | (self_minor != minor) {
        return Err(BridgeStanError::BadLibraryVersion(
            format!("{}.{}.{}", major, minor, patch),
            format!("{}.{}.{}", self_major, self_minor, self_patch),
        ));
    }
    Ok(unsafe { ffi::Bridgestan::from_library(library) }?)
}

// TODO for C Api
//
// * Access generated data?
// * integer generated values? (expand and generated data)
// * StanThreads?
// * Should bs_destruct_rng return an int? Should we panic if that happens?
// * Return &[u8] or assume utf8 and convert to str?
// * param_unconstrain: What lengths are allowed (ie include_tp, inclued_gq)

/// A Stan model instance with data
pub struct Model<'lib> {
    model: NonNull<ffi::bs_model>,
    lib: &'lib ffi::Bridgestan,
}

// Stan model is thread safe
unsafe impl<'lib> Sync for Model<'lib> {}
unsafe impl<'lib> Send for Model<'lib> {}

/// A random number generator for Stan
pub struct Rng<'lib> {
    rng: NonNull<ffi::bs_rng>,
    lib: &'lib ffi::Bridgestan,
}

impl<'lib> Drop for Rng<'lib> {
    fn drop(&mut self) {
        unsafe {
            // We don't handle error messages during deconstruct
            let _ = self.lib.bs_destruct_rng(self.rng.as_ptr(), null_mut());
        }
    }
}

struct ErrorMsg<'lib> {
    msg: *mut c_char,
    lib: &'lib ffi::Bridgestan,
}

impl<'lib> Drop for ErrorMsg<'lib> {
    fn drop(&mut self) {
        if !self.msg.is_null() {
            unsafe { self.lib.bs_free_error_msg(self.msg) };
        }
    }
}

impl<'lib> ErrorMsg<'lib> {
    fn new(lib: &'lib ffi::Bridgestan) -> Self {
        Self {
            msg: std::ptr::null_mut(),
            lib,
        }
    }

    fn as_ptr(&mut self) -> *mut *mut c_char {
        &mut self.msg
    }

    /// Return the error message as a String.
    ///
    /// Panics if there was no error message.
    fn message(&self) -> String {
        NonNull::new(self.msg)
            .map(|msg| {
                unsafe { CStr::from_ptr(msg.as_ptr()) }
                    .to_string_lossy()
                    .to_string()
            })
            .expect("Stan returned an error but no error message")
    }
}

impl<'lib> Model<'lib> {
    /// Create a new instance of the compiled Stan model.
    /// Data is specified as a JSON file at the given path, or empty for no data
    /// Seed and chain ID are used for reproducibility.
    pub fn new(lib: &'lib ffi::Bridgestan, path: &str, seed: u32) -> Result<Self> {
        let data = CString::new(path)?;

        let mut err = ErrorMsg::new(lib);
        let model = unsafe { lib.bs_construct(data.as_ptr(), seed, err.as_ptr()) };

        // Make sure data lives until here
        drop(data);

        NonNull::new(model)
            .map(|model| Self { model, lib })
            .ok_or_else(|| BridgeStanError::ConstructFailedError(err.message()))
            .and_then(|model| {
                let info = model.info()?;
                if !info.contains("STAN_THREADS=true") {
                    Err(BridgeStanError::StanThreadsError())
                } else {
                    Ok(model)
                }
            })
    }

    /// Return the name of the model or error if UTF decode fails
    pub fn name(&self) -> Result<&str> {
        let cstr = unsafe { CStr::from_ptr(self.lib.bs_name(self.model.as_ptr())) };
        Ok(cstr.to_str()?)
    }

    /// Return information about the compiled model
    pub fn info(&self) -> Result<&str> {
        let cstr = unsafe { CStr::from_ptr(self.lib.bs_model_info(self.model.as_ptr())) };
        Ok(cstr.to_str()?)
    }

    /// Return a comma-separated sequence of indexed parameter names,
    /// including the transformed parameters and/or generated quantities
    /// as specified.
    ///
    /// The parameters are returned in the order they are declared.
    /// Multivariate parameters are return in column-major (more
    /// generally last-index major) order.  Parameters are separated with
    /// periods (`.`).  For example, `a[3]` is written `a.3` and `b[2,
    /// 3]` as `b.2.3`.  The numbering follows Stan and is indexed from 1.
    ///
    /// # Arguments
    ///
    /// `include_tp`: Include transformed parameters
    /// `include_gp`: Include generated quantities
    pub fn param_names(&self, include_tp: bool, include_gq: bool) -> Result<&str> {
        let cstr = unsafe {
            CStr::from_ptr(self.lib.bs_param_names(
                self.model.as_ptr(),
                include_tp as c_int,
                include_gq as c_int,
            ))
        };
        Ok(cstr.to_str()?)
    }

    /// Return a comma-separated sequence of unconstrained parameters.
    /// Only parameters are unconstrained, so there are no unconstrained
    /// transformed parameters or generated quantities.
    ///
    /// The parameters are returned in the order they are declared.
    /// Multivariate parameters are return in column-major (more
    /// generally last-index major) order.  Parameters are separated with
    /// periods (`.`).  For example, `a[3]` is written `a.3` and `b[2,
    /// 3]` as `b.2.3`.  The numbering follows Stan and is indexed from 1.
    pub fn param_unc_names(&mut self) -> Result<&str> {
        Ok(unsafe { CStr::from_ptr(self.lib.bs_param_unc_names(self.model.as_ptr())) }.to_str()?)
    }

    /// Number of parameters in the model on the constrained scale.
    /// Will also count transformed parameters and generated quantities if requested
    pub fn param_num(&self, include_tp: bool, include_gq: bool) -> usize {
        unsafe {
            self.lib.bs_param_num(
                self.model.as_ptr(),
                include_tp as c_int,
                include_gq as c_int,
            )
        }
        .try_into()
        .expect("Stan returned an invalid number of parameters")
    }

    /// Return the number of parameters on the unconstrained scale.
    /// In particular, this is the size of the slice required by the log_density functions.
    pub fn param_unc_num(&self) -> usize {
        unsafe { self.lib.bs_param_unc_num(self.model.as_ptr()) }
            .try_into()
            .expect("Stan returned an invalid number of parameters")
    }

    pub fn log_density_gradient(
        &self,
        theta: &[f64],
        propto: bool,
        jacobian: bool,
        out: &mut [f64],
    ) -> Result<f64> {
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

        let mut err = ErrorMsg::new(self.lib);
        let rc = unsafe {
            self.lib.bs_log_density_gradient(
                self.model.as_ptr(),
                propto as c_int,
                jacobian as c_int,
                theta.as_ptr(),
                &mut val,
                out.as_mut_ptr(),
                err.as_ptr(),
            )
        };

        if rc == 0 {
            Ok(val)
        } else {
            Err(BridgeStanError::EvaluationFailed(err.message()))
        }
    }

    pub fn param_constrain(
        &self,
        theta_unc: &[f64],
        include_tp: bool,
        include_gq: bool,
        out: &mut [f64],
        rng: &mut Rng,
    ) -> Result<()> {
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

        let mut err = ErrorMsg::new(self.lib);
        let rc = unsafe {
            self.lib.bs_param_constrain(
                self.model.as_ptr(),
                include_tp as c_int,
                include_gq as c_int,
                theta_unc.as_ptr(),
                out.as_mut_ptr(),
                rng.rng.as_ptr(),
                err.as_ptr(),
            )
        };

        if rc == 0 {
            Ok(())
        } else {
            Err(BridgeStanError::EvaluationFailed(err.message()))
        }
    }

    /// Set the sequence of unconstrained parameters based on the
    /// specified constrained parameters, and return a return code of 0
    /// for success and -1 for failure.  Parameter order is as declared
    /// in the Stan program, with multivariate parameters given in
    /// last-index-major order.
    ///
    /// # Arguments
    /// `theta`: The vector of constrained parameters
    /// `theta_unc` Vector of unconstrained parameters
    pub fn param_unconstrain(&self, theta: &mut [f64], theta_unc: &mut [f64]) -> Result<()> {
        assert_eq!(
            theta_unc.len(),
            self.param_unc_num(),
            "Argument 'theta_unc' must be the same size as the number of parameters!"
        );
        assert_eq!(
            theta.len(),
            self.param_num(false, false),
            "Argument 'out' must be the same size as the number of parameters!"
        );
        let mut err = ErrorMsg::new(self.lib);
        let rc = unsafe {
            self.lib.bs_param_unconstrain(
                self.model.as_ptr(),
                theta.as_ptr(),
                theta_unc.as_mut_ptr(),
                err.as_ptr(),
            )
        };
        if rc == 0 {
            Ok(())
        } else {
            Err(BridgeStanError::EvaluationFailed(err.message()))
        }
    }
}

impl<'lib> Drop for Model<'lib> {
    /// Free the memory allocated in C++.
    fn drop(&mut self) {
        unsafe { self.lib.bs_destruct(self.model.as_ptr()) }
    }
}

#[cfg(feature = "nuts")]
use nuts_rs::{CpuLogpFunc, LogpError};

#[cfg(feature = "nuts")]
impl LogpError for BridgeStanError {
    fn is_recoverable(&self) -> bool {
        !matches!(self, BridgeStanError::EvaluationFailed(_))
    }
}

#[cfg(feature = "nuts")]
impl<'lib> CpuLogpFunc for Model<'lib> {
    type Err = BridgeStanError;

    fn dim(&self) -> usize {
        self.param_unc_num()
    }

    fn logp(&mut self, position: &[f64], grad: &mut [f64]) -> Result<f64> {
        let logp = self.log_density_gradient(position, false, true, grad)?;

        Ok(logp)
    }
}
