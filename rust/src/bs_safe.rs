use crate::ffi;
use std::borrow::Borrow;
use std::ffi::c_char;
use std::ffi::c_int;
use std::ffi::c_uint;
use std::ffi::CStr;
use std::ffi::NulError;
use std::ffi::OsStr;
use std::ptr::null;
use std::ptr::null_mut;
use std::ptr::NonNull;
use std::str::Utf8Error;

use itertools::Itertools;
// This is more or less equivalent to manually defining Display and From<other error types>
use thiserror::Error;

pub use ffi::Bridgestan as StanLibrary;

#[derive(Error, Debug)]
pub enum BridgeStanError {
    #[error("Could not load target library: {0}")]
    LoadLibraryError(#[from] libloading::Error),
    #[error("Bad Stan library version: Got {0} but expected {1}")]
    BadLibraryVersion(String, String),
    #[error("The Stan library was compiled without threading support. Config was {0}")]
    StanThreadsError(String),
    #[error("Failed to encode string to null-terminated C string")]
    StringEncodeError(#[from] NulError),
    #[error("Failed to decode string to UTF8")]
    StringDecodeError(#[from] Utf8Error),
    #[error("Failed to construct model: {0}")]
    ConstructFailedError(String),
    #[error("Failed during evaluation: {0}")]
    EvaluationFailed(String),
    #[error("Failed to interpret variable names")]
    InvalidVariableNames(),
}

type Result<T> = std::result::Result<T, BridgeStanError>;

/// Open a compiled stan library.
///
/// The library should have been compiled with bridgestan,
/// with the same version as the rust library.
pub fn open_library<P: AsRef<OsStr>>(path: P) -> Result<StanLibrary> {
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
    Ok(unsafe { StanLibrary::from_library(library) }?)
}

// TODO for C Api
//
// * Access generated data?
// * integer generated values? (expand and generated data)
// * StanThreads?
// * Should bs_destruct_rng return an int? Should we panic if that happens?
// * Return &[u8] or assume utf8 and convert to str?
// * param_unconstrain: What lengths are allowed (ie include_tp, inclued_gq)
// * Put lib in Arc?

/// A Stan model instance with data
pub struct Model<T: Borrow<StanLibrary>> {
    model: NonNull<ffi::bs_model>,
    lib: T,
    seed: u32,
}

// Stan model is thread safe
unsafe impl<T: Sync + Borrow<StanLibrary>> Sync for Model<T> {}
unsafe impl<T: Send + Borrow<StanLibrary>> Send for Model<T> {}

/// A random number generator for Stan
pub struct Rng<T: Borrow<StanLibrary>> {
    rng: NonNull<ffi::bs_rng>,
    lib: T,
}

unsafe impl<T: Sync + Borrow<StanLibrary>> Sync for Rng<T> {}
unsafe impl<T: Send + Borrow<StanLibrary>> Send for Rng<T> {}

impl<T: Borrow<StanLibrary>> Drop for Rng<T> {
    fn drop(&mut self) {
        unsafe {
            // We don't handle error messages during deconstruct
            let _ = self
                .lib
                .borrow()
                .bs_destruct_rng(self.rng.as_ptr(), null_mut());
        }
    }
}

impl<T: Borrow<StanLibrary>> Rng<T> {
    pub fn new(lib: T, seed: u32, chain_id: u32) -> Result<Self> {
        let mut err = ErrorMsg::new(lib.borrow());
        let rng = unsafe {
            lib.borrow()
                .bs_construct_rng(seed as c_uint, chain_id as c_uint, err.as_ptr())
        };
        if let Some(rng) = NonNull::new(rng) {
            drop(err);
            Ok(Self { rng, lib })
        } else {
            Err(BridgeStanError::ConstructFailedError(err.message()))
        }
    }
}

struct ErrorMsg<'lib> {
    msg: *mut c_char,
    lib: &'lib StanLibrary,
}

impl<'lib> Drop for ErrorMsg<'lib> {
    fn drop(&mut self) {
        if !self.msg.is_null() {
            unsafe { self.lib.bs_free_error_msg(self.msg) };
        }
    }
}

impl<'lib> ErrorMsg<'lib> {
    fn new(lib: &'lib StanLibrary) -> Self {
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

#[non_exhaustive]
#[derive(Clone, Debug)]
pub struct Parameter {
    pub name: String,
    pub shape: Vec<usize>,
    pub size: usize,
    pub start_idx: usize,
    pub end_idx: usize,
}

impl<T: Borrow<StanLibrary> + Clone> Model<T> {
    /// Return a clone of the underlying stan library
    pub fn clone_library(&self) -> T {
        self.lib.clone()
    }
}

impl<T: Borrow<StanLibrary>> Model<T> {
    /// Create a new instance of the compiled Stan model.
    /// Data is specified as a JSON file at the given path, or empty for no data
    /// Seed and chain ID are used for reproducibility.
    pub fn new<D: AsRef<CStr>>(lib: T, data: Option<D>, seed: u32) -> Result<Self> {
        let mut err = ErrorMsg::new(lib.borrow());

        let data_ptr = data
            .as_ref()
            .map(|data| data.as_ref().as_ptr())
            .unwrap_or(null());
        let model = unsafe { lib.borrow().bs_construct(data_ptr, seed, err.as_ptr()) };
        // Make sure data lives until here
        drop(data);

        if let Some(model) = NonNull::new(model) {
            drop(err);
            let model = Self { model, lib, seed };
            // If STAN_THREADS is not true, the safty guaranties we are
            // making would be incorrect
            let info = model.info()?;
            if !info.contains("STAN_THREADS=true") {
                Err(BridgeStanError::StanThreadsError(info.to_string()))
            } else {
                Ok(model)
            }
        } else {
            Err(BridgeStanError::ConstructFailedError(err.message()))
        }
    }

    /// Return a reference to the underlying stan library
    pub fn ref_library(&self) -> &StanLibrary {
        self.lib.borrow()
    }

    pub fn new_rng(&self, chain_id: u32) -> Result<Rng<&StanLibrary>> {
        Rng::new(self.ref_library(), self.seed, chain_id)
    }

    /// Return the name of the model or error if UTF decode fails
    pub fn name(&self) -> Result<&str> {
        let cstr = unsafe { CStr::from_ptr(self.lib.borrow().bs_name(self.model.as_ptr())) };
        Ok(cstr.to_str()?)
    }

    /// Return information about the compiled model
    pub fn info(&self) -> Result<&str> {
        let cstr = unsafe { CStr::from_ptr(self.lib.borrow().bs_model_info(self.model.as_ptr())) };
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
            CStr::from_ptr(self.lib.borrow().bs_param_names(
                self.model.as_ptr(),
                include_tp as c_int,
                include_gq as c_int,
            ))
        };
        Ok(cstr.to_str()?)
    }

    /// Return meta information about the constrained parameters of the model
    pub fn params(&self, include_tp: bool, include_gq: bool) -> Result<Vec<Parameter>> {
        let var_string = self.param_names(include_tp, include_gq)?;
        let name_idxs: Result<Vec<(&str, Vec<usize>)>> = var_string
            .split(',')
            .map(|var| {
                let mut parts = var.split('.');
                let name = parts
                    .next()
                    .ok_or_else(BridgeStanError::InvalidVariableNames)?;
                let idxs: Result<Vec<usize>> = parts
                    .map(|mut idx| {
                        if idx == "real" {
                            idx = "1";
                        }
                        if idx == "imag" {
                            idx = "2";
                        }
                        let idx: usize = idx
                            .parse()
                            .map_err(|_| BridgeStanError::InvalidVariableNames())?;
                        Ok(idx - 1)
                    })
                    .collect();
                Ok((name, idxs?))
            })
            .collect();

        let mut variables = Vec::new();
        let mut start_idx = 0;
        for (name, idxs) in &name_idxs?.iter().group_by(|(name, _)| name) {
            let shape: Vec<usize> = idxs
                .map(|(_name, idx)| idx)
                .fold(None, |acc, elem| {
                    let mut shape = acc.unwrap_or(elem.clone());
                    shape
                        .iter_mut()
                        .zip_eq(elem.iter())
                        .for_each(|(old, &new)| {
                            *old = new.max(*old);
                        });
                    Some(shape)
                })
                .unwrap_or(vec![]);
            let size = shape.iter().product();
            let end_idx = start_idx + size;
            variables.push(Parameter {
                name: name.to_string(),
                shape,
                size,
                start_idx,
                end_idx,
            });
            start_idx = end_idx;
        }
        Ok(variables)
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
        let cstr =
            unsafe { CStr::from_ptr(self.lib.borrow().bs_param_unc_names(self.model.as_ptr())) };
        Ok(cstr.to_str()?)
    }

    /// Number of parameters in the model on the constrained scale.
    /// Will also count transformed parameters and generated quantities if requested
    pub fn param_num(&self, include_tp: bool, include_gq: bool) -> usize {
        unsafe {
            self.lib.borrow().bs_param_num(
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
        unsafe { self.lib.borrow().bs_param_unc_num(self.model.as_ptr()) }
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

        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.lib.borrow().bs_log_density_gradient(
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

    pub fn param_constrain<R: Borrow<StanLibrary>>(
        &self,
        theta_unc: &[f64],
        include_tp: bool,
        include_gq: bool,
        out: &mut [f64],
        rng: &mut Rng<R>,
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

        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.lib.borrow().bs_param_constrain(
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
        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.lib.borrow().bs_param_unconstrain(
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

impl<T: Borrow<StanLibrary>> Drop for Model<T> {
    /// Free the memory allocated in C++.
    fn drop(&mut self) {
        unsafe { self.lib.borrow().bs_destruct(self.model.as_ptr()) }
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
impl<T: Borrow<StanLibrary>> CpuLogpFunc for Model<T> {
    type Err = BridgeStanError;

    fn dim(&self) -> usize {
        self.param_unc_num()
    }

    fn logp(&mut self, position: &[f64], grad: &mut [f64]) -> Result<f64> {
        let logp = self.log_density_gradient(position, false, true, grad)?;

        Ok(logp)
    }
}
