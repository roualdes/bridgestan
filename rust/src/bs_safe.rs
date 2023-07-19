use crate::ffi;
use std::borrow::Borrow;
use std::collections::hash_map::DefaultHasher;
use std::ffi::c_char;
use std::ffi::c_int;
use std::ffi::c_uint;
use std::ffi::CStr;
use std::ffi::OsStr;
use std::hash::Hash;
use std::hash::Hasher;
use std::mem::forget;
use std::mem::ManuallyDrop;
use std::ptr::NonNull;
use std::ptr::{null, null_mut};
use std::str::Utf8Error;
use std::time::Instant;

// This is more or less equivalent to manually defining Display and From<other error types>
use thiserror::Error;

/// A loaded shared library for a Stan model
pub struct StanLibrary {
    lib: ManuallyDrop<ffi::BridgeStan>,
    id: u64,
}

// To work around a bug where unloading a library
// can lead to deadlocks.
//
// See https://github.com/roualdes/bridgestan/issues/111
impl Drop for StanLibrary {
    fn drop(&mut self) {
        let lib = unsafe { ManuallyDrop::take(&mut self.lib) };
        forget(lib.into_library());
    }
}

/// A callback for print statements in Stan models
pub type StanPrintCallback = extern "C" fn(*const c_char, usize);

impl StanLibrary {
    /// Provide a callback function to be called when Stan prints a message
    ///
    /// # Safety
    ///
    /// The provided function must never panic.
    ///
    /// Since the call is protected by a mutex internally, it does not
    /// need to be thread safe.
    pub unsafe fn set_print_callback(&mut self, callback: StanPrintCallback) -> Result<()> {
        let mut err = ErrorMsg::new(self);
        let rc = unsafe { self.lib.bs_set_print_callback(Some(callback), err.as_ptr()) };

        if rc == 0 {
            Ok(())
        } else {
            Err(BridgeStanError::SetCallbackFailed(err.message()))
        }
    }

    /// Unload the Stan library.
    ///
    /// # Safety
    ///
    /// There seem to be issues around unloading libraries in threaded
    /// code that are not fully understood:
    /// <https://github.com/roualdes/bridgestan/issues/111>
    pub unsafe fn unload_library(mut self) {
        let lib = unsafe { ManuallyDrop::take(&mut self.lib) };
        drop(lib.into_library());
        forget(self);
    }
}

#[derive(Error, Debug)]
#[error("Could not load target library: {0}")]
pub struct LoadingError(#[from] libloading::Error);

/// Error type for bridgestan interface
#[derive(Error, Debug)]
#[non_exhaustive]
pub enum BridgeStanError {
    /// The provided library could not be loaded.
    #[error(transparent)]
    InvalidLibrary(#[from] LoadingError),
    /// The version of the Stan library does not match the version of the rust crate.
    #[error("Bad Stan library version: Got {0} but expected {1}")]
    BadLibraryVersion(String, String),
    /// The Stan library could not be loaded because it was compiled without threading support.
    #[error("The Stan library was compiled without threading support. Config was {0}")]
    StanThreads(String),
    /// Stan returned a string that couldn't be decoded using UTF8.
    #[error("Failed to decode string to UTF8")]
    InvalidString(#[from] Utf8Error),
    /// The model could not be instantiated, possibly because if incorrect data.
    #[error("Failed to construct model: {0}")]
    ConstructFailed(String),
    /// Stan returned an error while computing the density.
    #[error("Failed during evaluation: {0}")]
    EvaluationFailed(String),
    /// Setting a print-callback failed.
    #[error("Failed to set a print-callback: {0}")]
    SetCallbackFailed(String),
}

type Result<T> = std::result::Result<T, BridgeStanError>;

/// Open a compiled Stan library.
///
/// The library should have been compiled with BridgeStan,
/// with the same version as the Rust library.
pub fn open_library<P: AsRef<OsStr>>(path: P) -> Result<StanLibrary> {
    let library = unsafe { libloading::Library::new(&path) }.map_err(LoadingError)?;
    let major: libloading::Symbol<*const c_int> =
        unsafe { library.get(b"bs_major_version") }.map_err(LoadingError)?;
    let major = unsafe { **major };
    let minor: libloading::Symbol<*const c_int> =
        unsafe { library.get(b"bs_minor_version") }.map_err(LoadingError)?;
    let minor = unsafe { **minor };
    let patch: libloading::Symbol<*const c_int> =
        unsafe { library.get(b"bs_patch_version") }.map_err(LoadingError)?;
    let patch = unsafe { **patch };
    let self_major: c_int = env!("CARGO_PKG_VERSION_MAJOR").parse().unwrap();
    let self_minor: c_int = env!("CARGO_PKG_VERSION_MINOR").parse().unwrap();
    let self_patch: c_int = env!("CARGO_PKG_VERSION_PATCH").parse().unwrap();

    if !((self_major == major) & (self_minor <= minor)) {
        return Err(BridgeStanError::BadLibraryVersion(
            format!("{}.{}.{}", major, minor, patch),
            format!("{}.{}.{}", self_major, self_minor, self_patch),
        ));
    }

    let lib = unsafe { ffi::BridgeStan::from_library(library) }.map_err(LoadingError)?;
    let lib = ManuallyDrop::new(lib);
    let mut hasher = DefaultHasher::new();
    Instant::now().hash(&mut hasher);
    path.as_ref().hash(&mut hasher);
    let id = hasher.finish();
    Ok(StanLibrary { lib, id })
}

/// A Stan model instance with data
pub struct Model<T: Borrow<StanLibrary>> {
    model: NonNull<ffi::bs_model>,
    lib: T,
}

// Stan model is thread safe
unsafe impl<T: Sync + Borrow<StanLibrary>> Sync for Model<T> {}
unsafe impl<T: Send + Borrow<StanLibrary>> Send for Model<T> {}

/// A random number generator for Stan models.
/// This is only used in the `param_contrain` method
/// of the model when requesting values from the `generated quantities` block.
/// Different threads should use different instances.
pub struct Rng<T: Borrow<StanLibrary>> {
    rng: NonNull<ffi::bs_rng>,
    lib: T,
}

// Use sites require exclusive reference which guarantees
// that the rng is not used in multiple threads concurrently.
unsafe impl<T: Sync + Borrow<StanLibrary>> Sync for Rng<T> {}
unsafe impl<T: Send + Borrow<StanLibrary>> Send for Rng<T> {}

impl<T: Borrow<StanLibrary>> Drop for Rng<T> {
    fn drop(&mut self) {
        unsafe {
            self.lib.borrow().lib.bs_rng_destruct(self.rng.as_ptr());
        }
    }
}

impl<T: Borrow<StanLibrary>> Rng<T> {
    pub fn new(lib: T, seed: u32) -> Result<Self> {
        let mut err = ErrorMsg::new(lib.borrow());
        let rng = unsafe {
            lib.borrow()
                .lib
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
            unsafe { self.lib.lib.bs_free_error_msg(self.msg) };
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
    /// *Panics* if there was no error message.
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
    fn ffi_lib(&self) -> &ffi::BridgeStan {
        &self.lib.borrow().lib
    }

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
                .lib
                .bs_model_construct(data_ptr, seed, err.as_ptr())
        };
        // Make sure data lives until here
        drop(data);

        if let Some(model) = NonNull::new(model) {
            drop(err);
            let model = Self { model, lib };
            // If STAN_THREADS is not true, the safety guaranties we are
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

    /// Return a reference to the underlying Stan library
    pub fn ref_library(&self) -> &StanLibrary {
        self.lib.borrow()
    }

    /// Create a new `Rng` random number generator from the library underlying this model.
    ///
    /// This can be used in `param_constrain` when values from the `generated quantities`
    /// block are desired.
    ///
    /// This instance can only be used with models from the same
    /// Stan library. Invalid usage will otherwise result in a
    /// panic.
    pub fn new_rng(&self, seed: u32) -> Result<Rng<&StanLibrary>> {
        Rng::new(self.ref_library(), seed)
    }

    /// Return the name of the model or error if UTF decode fails
    pub fn name(&self) -> Result<&str> {
        let cstr = unsafe { CStr::from_ptr(self.ffi_lib().bs_name(self.model.as_ptr())) };
        Ok(cstr.to_str()?)
    }

    /// Return information about the compiled model
    pub fn info(&self) -> &CStr {
        unsafe { CStr::from_ptr(self.ffi_lib().bs_model_info(self.model.as_ptr())) }
    }

    /// Return a comma-separated sequence of indexed parameter names,
    /// including the transformed parameters and/or generated quantities
    /// as specified.
    ///
    /// The parameters are returned in the order they are declared.
    /// Multivariate parameters are return in column-major (more
    /// generally last-index major) order.  Parameter indices are separated
    /// with periods (`.`).  For example, `a[3]` is written `a.3` and `b[2, 3]`
    /// as `b.2.3`.  The numbering follows Stan and is indexed from 1.
    ///
    /// If `include_tp` is set the names will also include the transformed
    /// parameters of the Stan model after the parameters. If `include_gq` is
    /// set, we also include the names of the generated quantities at
    /// the very end.
    pub fn param_names(&self, include_tp: bool, include_gq: bool) -> &str {
        let cstr = unsafe {
            CStr::from_ptr(self.ffi_lib().bs_param_names(
                self.model.as_ptr(),
                include_tp,
                include_gq,
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
    /// generally last-index major) order.  Parameter indices are separated with
    /// periods (`.`).  For example, `a[3]` is written `a.3` and `b[2,
    /// 3]` as `b.2.3`.  The numbering follows Stan and is indexed from 1.
    pub fn param_unc_names(&mut self) -> &str {
        let cstr =
            unsafe { CStr::from_ptr(self.ffi_lib().bs_param_unc_names(self.model.as_ptr())) };
        cstr.to_str()
            .expect("Stan model has invalid parameter names")
    }

    /// Number of parameters in the model on the constrained scale.
    ///
    /// Will also count transformed parameters (`include_tp`) and generated
    /// quantities (`include_gq`) if requested.
    pub fn param_num(&self, include_tp: bool, include_gq: bool) -> usize {
        unsafe {
            self.ffi_lib()
                .bs_param_num(self.model.as_ptr(), include_tp, include_gq)
        }
        .try_into()
        .expect("Stan returned an invalid number of parameters")
    }

    /// Return the number of parameters on the unconstrained scale.
    ///
    /// In particular, this is the size of the slice required by the log_density functions.
    pub fn param_unc_num(&self) -> usize {
        unsafe { self.ffi_lib().bs_param_unc_num(self.model.as_ptr()) }
            .try_into()
            .expect("Stan returned an invalid number of parameters")
    }

    /// Compute the log of the prior times likelihood density
    ///
    /// Drop jacobian determinant terms of the transformation from unconstrained
    /// to the constrained space if `jacobian == false` and drop terms
    /// of the density that do not depend on the parameters if `propto == true`.
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
            self.ffi_lib().bs_log_density(
                self.model.as_ptr(),
                propto,
                jacobian,
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
    /// Drop jacobian determinant terms of the transformation from unconstrained
    /// to the constrained space if `jacobian == false` and drop terms
    /// of the density that do not depend on the parameters if `propto == true`.
    ///
    /// The gradient of the log density will be stored in `grad`.
    ///
    /// *Panics* if the provided buffer has incorrect shape. The gradient buffer `grad`
    /// must have length `self.param_unc_num()`.
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
            self.ffi_lib().bs_log_density_gradient(
                self.model.as_ptr(),
                propto,
                jacobian,
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

    /// Compute the log of the prior times likelihood density and its gradient and hessian.
    ///
    /// Drop jacobian determinant terms of the transformation from unconstrained
    /// to the constrained space if `jacobian == false` and drop terms
    /// of the density that do not depend on the parameters if `propto == true`.
    ///
    /// The gradient of the log density will be stored in `grad`, the
    /// hessian is stored in `hessian`.
    ///
    /// *Panics* if the provided buffers have incorrect shapes. The gradient buffer `grad`
    /// must have length `self.param_unc_num()` and the `hessian` buffer must
    /// have length `self.param_unc_num() * self.param_unc_num()`.
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
            self.ffi_lib().bs_log_density_hessian(
                self.model.as_ptr(),
                propto,
                jacobian,
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

    /// Map a point in unconstrained parameter space to the constrained space.
    ///
    /// `theta_unc` must contain the point in the unconstrained parameter space.
    ///
    /// If `include_tp` is set the output will also include the transformed
    /// parameters of the Stan model after the parameters. If `include_gq` is
    /// set, we also include the generated quantities at the very end.
    ///
    /// *Panics* if the provided buffer has incorrect shape. The length of the `out` buffer
    /// `self.param_num(include_tp, include_gq)`.
    /// *Panics* if `include_gq` is set but no random number generator is provided.
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

        if let Some(rng) = &rng {
            assert!(
                rng.lib.borrow().id == self.lib.borrow().id,
                "Rng and model must come from the same Stan library"
            );
        }

        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.ffi_lib().bs_param_constrain(
                self.model.as_ptr(),
                include_tp,
                include_gq,
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

    /// Map a point in constrained parameter space to the unconstrained space.
    pub fn param_unconstrain(&self, theta: &[f64], theta_unc: &mut [f64]) -> Result<()> {
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
            self.ffi_lib().bs_param_unconstrain(
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

    /// Map a constrained point in json format to the unconstrained space.
    ///
    /// The JSON schema assumed is fully defined in the *CmdStan Reference Manual*.
    /// A value for each parameter in the Stan program should be provided, with
    /// dimensions and size corresponding to the Stan program declarations.
    pub fn param_unconstrain_json<S: AsRef<CStr>>(
        &self,
        json: S,
        theta_unc: &mut [f64],
    ) -> Result<()> {
        assert_eq!(
            theta_unc.len(),
            self.param_unc_num(),
            "Argument 'theta_unc' must be the same size as the number of parameters!"
        );
        let mut err = ErrorMsg::new(self.lib.borrow());
        let rc = unsafe {
            self.ffi_lib().bs_param_unconstrain_json(
                self.model.as_ptr(),
                json.as_ref().as_ptr(),
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
    /// Return a clone of the underlying Stan library
    pub fn clone_library_ref(&self) -> T {
        self.lib.clone()
    }
}

impl<T: Borrow<StanLibrary>> Drop for Model<T> {
    /// Free the memory allocated in C++.
    fn drop(&mut self) {
        unsafe { self.ffi_lib().bs_model_destruct(self.model.as_ptr()) }
    }
}
