use crate::ffi;
use std::borrow::Borrow;
use std::ffi::c_char;
use std::ffi::c_int;
use std::ffi::c_uint;
use std::ffi::CStr;
use std::ffi::OsStr;
#[cfg(windows)]
use std::mem::forget;
use std::mem::ManuallyDrop;
use std::ptr::NonNull;
use std::ptr::{null, null_mut};
use std::str::Utf8Error;

// This is more or less equivalent to manually defining Display and From<other error types>
use thiserror::Error;

/// A loaded shared library for a stan model
pub struct StanLibrary(ManuallyDrop<ffi::Bridgestan>);

// To work around a bug on windows where unloading a library
// can lead to deadlocks.
//
// See https://github.com/roualdes/bridgestan/issues/111
#[cfg(windows)]
impl Drop for StanLibrary {
    fn drop(&mut self) {
        let lib = unsafe { ManuallyDrop::take(&mut self.0) };
        forget(lib.into_library());
    }
}

#[cfg(not(windows))]
impl Drop for StanLibrary {
    fn drop(&mut self) {
        unsafe { ManuallyDrop::drop(&mut self.0) };
    }
}

/// A callback for print statements in stan models
pub type StanPrintCallback = extern "C" fn(*const c_char, usize);

impl StanLibrary {
    /// Provide a callback function to be called when stan prints a message
    ///
    /// # Safety
    ///
    /// The provided function must never panic.
    ///
    /// Since the call is proteted by a mutex internally, it does not
    /// need to be thread safe.
    pub unsafe fn set_print_callback(&mut self, callback: StanPrintCallback) -> Result<()> {
        let mut err = ErrorMsg::new(self);
        let rc = unsafe { self.0.bs_set_print_callback(Some(callback), err.as_ptr()) };

        if rc == 0 {
            Ok(())
        } else {
            Err(BridgeStanError::EvaluationFailed(err.message()))
        }
    }
}

/// Error type for bridgestan interface
#[derive(Error, Debug)]
#[non_exhaustive]
pub enum BridgeStanError {
    #[error("Could not load target library: {0}")]
    InvalidLibrary(#[from] libloading::Error),
    #[error("Bad Stan library version: Got {0} but expected {1}")]
    BadLibraryVersion(String, String),
    #[error("The Stan library was compiled without threading support. Config was {0}")]
    StanThreads(String),
    #[error("Failed to decode string to UTF8")]
    InvalidString(#[from] Utf8Error),
    #[error("Failed to construct model: {0}")]
    ConstructFailed(String),
    #[error("Failed during evaluation: {0}")]
    EvaluationFailed(String),
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

    let lib = unsafe { ffi::Bridgestan::from_library(library) }?;
    let lib = ManuallyDrop::new(lib);
    Ok(StanLibrary(lib))
}

/// A Stan model instance with data
pub struct Model<T: Borrow<StanLibrary>> {
    model: NonNull<ffi::bs_model>,
    lib: T,
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
            self.lib.borrow().0.bs_rng_destruct(self.rng.as_ptr());
        }
    }
}

impl<T: Borrow<StanLibrary>> Rng<T> {
    pub fn new(lib: T, seed: u32) -> Result<Self> {
        let mut err = ErrorMsg::new(lib.borrow());
        let rng = unsafe {
            lib.borrow()
                .0
                .bs_rng_construct(seed as c_uint, err.as_ptr())
        };
        if let Some(rng) = NonNull::new(rng) {
            drop(err);
            Ok(Self { rng, lib })
        } else {
            Err(BridgeStanError::ConstructFailed(err.message()))
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
            unsafe { self.lib.0.bs_free_error_msg(self.msg) };
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

impl<T: Borrow<StanLibrary>> Model<T> {
    /// Create a new instance of the compiled Stan model.
    ///
    /// Data is specified as a JSON file at the given path, a JSON string literal,
    /// or empty for no data. The seed is used if the model has RNG functions in
    /// the `transformed data` section.
    pub fn new<D: AsRef<CStr>>(lib: T, data: Option<D>, seed: u32) -> Result<Self> {
        let mut err = ErrorMsg::new(lib.borrow());

        let data_ptr = data
            .as_ref()
            .map(|data| data.as_ref().as_ptr())
            .unwrap_or(null());
        let model = unsafe {
            lib.borrow()
                .0
                .bs_model_construct(data_ptr, seed, err.as_ptr())
        };
        // Make sure data lives until here
        drop(data);

        if let Some(model) = NonNull::new(model) {
            drop(err);
            let model = Self { model, lib };
            // If STAN_THREADS is not true, the safty guaranties we are
            // making would be incorrect
            let info = model.info();
            if !info.to_string_lossy().contains("STAN_THREADS=true") {
                Err(BridgeStanError::StanThreads(
                    info.to_string_lossy().into_owned(),
                ))
            } else {
                Ok(model)
            }
        } else {
            Err(BridgeStanError::ConstructFailed(err.message()))
        }
    }

    /// Return a reference to the underlying stan library
    pub fn ref_library(&self) -> &StanLibrary {
        self.lib.borrow()
    }

    pub fn new_rng(&self, seed: u32) -> Result<Rng<&StanLibrary>> {
        Rng::new(self.ref_library(), seed)
    }

    /// Return the name of the model or error if UTF decode fails
    pub fn name(&self) -> Result<&str> {
        let cstr = unsafe { CStr::from_ptr(self.lib.borrow().0.bs_name(self.model.as_ptr())) };
        Ok(cstr.to_str()?)
    }

    /// Return information about the compiled model
    pub fn info(&self) -> &CStr {
        unsafe { CStr::from_ptr(self.lib.borrow().0.bs_model_info(self.model.as_ptr())) }
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
    pub fn param_names(&self, include_tp: bool, include_gq: bool) -> &str {
        let cstr = unsafe {
            CStr::from_ptr(self.lib.borrow().0.bs_param_names(
                self.model.as_ptr(),
                include_tp as c_int,
                include_gq as c_int,
            ))
        };
        cstr.to_str()
            .expect("Stan model has invalid parameter names")
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
    pub fn param_unc_names(&mut self) -> &str {
        let cstr =
            unsafe { CStr::from_ptr(self.lib.borrow().0.bs_param_unc_names(self.model.as_ptr())) };
        cstr.to_str()
            .expect("Stan model has invalid parameter names")
    }

    /// Number of parameters in the model on the constrained scale.
    /// Will also count transformed parameters and generated quantities if requested
    pub fn param_num(&self, include_tp: bool, include_gq: bool) -> usize {
        unsafe {
            self.lib.borrow().0.bs_param_num(
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
        unsafe { self.lib.borrow().0.bs_param_unc_num(self.model.as_ptr()) }
            .try_into()
            .expect("Stan returned an invalid number of parameters")
    }

    /// Compute the log of the prior times likelihood density
    ///
    /// Drop jacobian determinant terms if `jacobian == false` and
    /// drop constant terms of the density if `propto == true`.
    pub fn log_density(&self, theta_unc: &[f64], propto: bool, jacobian: bool) -> Result<f64> {
        let n = self.param_unc_num();
        assert_eq!(
            theta_unc.len(),
            n,
            "Argument 'theta_unc' must be the same size as the number of parameters!"
        );
        let mut val = 0.0;

        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.lib.borrow().0.bs_log_density(
                self.model.as_ptr(),
                propto as c_int,
                jacobian as c_int,
                theta_unc.as_ptr(),
                &mut val,
                err.as_ptr(),
            )
        };

        if rc == 0 {
            Ok(val)
        } else {
            Err(BridgeStanError::EvaluationFailed(err.message()))
        }
    }

    /// Compute the log of the prior times likelihood density and its gradient
    ///
    /// Drop jacobian determinant terms if `jacobian == false` and
    /// drop constant terms of the density if `propto == true`.
    /// The gradient of the log density is stored in `grad`.
    pub fn log_density_gradient(
        &self,
        theta_unc: &[f64],
        propto: bool,
        jacobian: bool,
        grad: &mut [f64],
    ) -> Result<f64> {
        let n = self.param_unc_num();
        assert_eq!(
            theta_unc.len(),
            n,
            "Argument 'theta_unc' must be the same size as the number of parameters!"
        );
        assert_eq!(
            grad.len(),
            n,
            "Argument 'grad' must be the same size as the number of parameters!"
        );

        let mut val = 0.0;

        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.lib.borrow().0.bs_log_density_gradient(
                self.model.as_ptr(),
                propto as c_int,
                jacobian as c_int,
                theta_unc.as_ptr(),
                &mut val,
                grad.as_mut_ptr(),
                err.as_ptr(),
            )
        };

        if rc == 0 {
            Ok(val)
        } else {
            Err(BridgeStanError::EvaluationFailed(err.message()))
        }
    }

    /// Compute the log of the prior times likelihood density and gradient and hessian.
    ///
    /// Drop jacobian determinant terms if `jacobian == false` and
    /// drop constant terms of the density if `propto == true`.
    /// The gradient of the log density is stored in `grad`, the
    /// hessian is stored in `hessian`.
    pub fn log_density_hessian(
        &self,
        theta_unc: &[f64],
        propto: bool,
        jacobian: bool,
        grad: &mut [f64],
        hessian: &mut [f64],
    ) -> Result<f64> {
        let n = self.param_unc_num();
        assert_eq!(
            theta_unc.len(),
            n,
            "Argument 'theta_unc' must be the same size as the number of parameters!"
        );
        assert_eq!(
            grad.len(),
            n,
            "Argument 'grad' must be the same size as the number of parameters!"
        );
        assert_eq!(
            hessian.len(),
            n.checked_mul(n).expect("Overflow for size of hessian"),
            "Argument 'hessian' must be the same size as the number of parameters squared!"
        );

        let mut val = 0.0;

        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.lib.borrow().0.bs_log_density_hessian(
                self.model.as_ptr(),
                propto as c_int,
                jacobian as c_int,
                theta_unc.as_ptr(),
                &mut val,
                grad.as_mut_ptr(),
                hessian.as_mut_ptr(),
                err.as_ptr(),
            )
        };

        if rc == 0 {
            Ok(val)
        } else {
            Err(BridgeStanError::EvaluationFailed(err.message()))
        }
    }

    /// Map a point in unconstrained parameter space to the constrained space
    ///
    /// # Arguments
    ///
    /// `theta_unc`: The point in the unconstained parameter space.
    ///
    /// `include_tp`: Include transformed parameters
    ///
    /// `include_gq`: Include generated quantities
    ///
    /// `out`: Array of length `self.param_num(include_tp, include_gp)`, where
    /// the constrained parameters will be stored.
    ///
    /// `rng`: A Stan random number generator. Has to be provided if `include_gp`.
    pub fn param_constrain<R: Borrow<StanLibrary>>(
        &self,
        theta_unc: &[f64],
        include_tp: bool,
        include_gq: bool,
        out: &mut [f64],
        rng: Option<&mut Rng<R>>,
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

        if include_gq {
            assert!(
                rng.is_some(),
                "Rng was not provided even though generated quantities are requested."
            );
        }

        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.lib.borrow().0.bs_param_constrain(
                self.model.as_ptr(),
                include_tp as c_int,
                include_gq as c_int,
                theta_unc.as_ptr(),
                out.as_mut_ptr(),
                rng.map(|rng| rng.rng.as_ptr()).unwrap_or(null_mut()),
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
    ///
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
            self.lib.borrow().0.bs_param_unconstrain(
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

impl<T: Borrow<StanLibrary> + Clone> Model<T> {
    /// Return a clone of the underlying stan library
    pub fn clone_library_ref(&self) -> T {
        self.lib.clone()
    }
}

impl<T: Borrow<StanLibrary>> Drop for Model<T> {
    /// Free the memory allocated in C++.
    fn drop(&mut self) {
        unsafe { self.lib.borrow().0.bs_model_destruct(self.model.as_ptr()) }
    }
}
