use std::{
    ffi::{c_int, CStr},
    ptr::NonNull,
};

use binding::{bs_model_rng, Bridgestan};
use thiserror::Error;

mod binding;

pub struct Model(Bridgestan);

pub struct ModelRng<'lib> {
    ctx: NonNull<bs_model_rng>,
    lib: &'lib Model,
}

#[derive(Error, Debug)]
pub enum Error {
    #[error("Could not create bs_model_rng. Maybe data is invalid?")]
    ConstructFaild(),
    #[error("Provided arrays had incorrect shapes.")]
    InvalidShape(),
    #[error("Stan retured an error when constraining parameters.")]
    ConstrainFailed(),
    #[error("Stan failed while computing unconstrained parameters.")]
    UnconstrainFailed(),
    #[error("Stan failed while computing the log density.")]
    LogDensityFailed(),
}

type Result<T> = std::result::Result<T, Error>;

impl<'lib> ModelRng<'lib> {
    pub fn new(model: &'lib Model, data: &CStr, seed: u32, chain: u32) -> Result<Self> {
        // TODO Data should not have to be mut
        let ctx = unsafe { model.0.bs_construct(data.as_ptr() as *mut _, seed, chain) };
        Ok(Self {
            lib: model,
            ctx: NonNull::new(ctx).ok_or_else(|| Error::ConstructFaild())?,
        })
    }

    pub fn name(&mut self) -> &CStr {
        unsafe { CStr::from_ptr(self.lib.0.bs_name(self.ctx.as_ptr())) }
    }

    pub fn model_info(&mut self) -> &CStr {
        unsafe { CStr::from_ptr(self.lib.0.bs_model_info(self.ctx.as_ptr())) }
    }

    pub fn param_names(&mut self, include_tp: bool, include_gq: bool) -> &CStr {
        unsafe {
            CStr::from_ptr(self.lib.0.bs_param_names(
                self.ctx.as_ptr(),
                include_tp.into(),
                include_gq.into(),
            ))
        }
    }

    pub fn param_unc_names(&mut self) -> &CStr {
        unsafe { CStr::from_ptr(self.lib.0.bs_param_unc_names(self.ctx.as_ptr())) }
    }

    pub fn param_num(&mut self, include_tp: bool, include_gq: bool) -> usize {
        unsafe {
            self.lib
                .0
                .bs_param_num(self.ctx.as_ptr(), include_tp.into(), include_gq.into())
        }
        .try_into()
        .expect("Stan returned an invalid number of parameters.")
    }

    pub fn param_unc_num(&mut self) -> usize {
        unsafe { self.lib.0.bs_param_unc_num(self.ctx.as_ptr()) }
            .try_into()
            .expect("Stan returned an invalid number of parameters.")
    }

    pub fn param_constrain(
        &mut self,
        include_tp: bool,
        include_gq: bool,
        theta_unc: &[f64],
        theta: &mut [f64],
    ) -> Result<()> {
        if theta_unc.len() != self.param_unc_num() {
            return Err(Error::InvalidShape());
        }
        if theta.len() != self.param_num(include_tp, include_gq) {
            return Err(Error::InvalidShape());
        }

        let retcode = unsafe {
            self.lib.0.bs_param_constrain(
                self.ctx.as_ptr(),
                include_tp.into(),
                include_gq.into(),
                theta_unc.as_ptr(),
                theta.as_mut_ptr(),
            )
        };

        if retcode != 0 {
            return Err(Error::ConstrainFailed());
        }
        Ok(())
    }

    pub fn param_unconstrain(&mut self, theta: &[f64], theta_unc: &mut [f64]) -> Result<()> {
        if theta_unc.len() != self.param_unc_num() {
            return Err(Error::InvalidShape());
        }
        // TODO what are include_tp and include_gq?
        if theta.len() != self.param_num(false, false) {
            return Err(Error::InvalidShape());
        }

        let retcode = unsafe {
            self.lib.0.bs_param_unconstrain(
                self.ctx.as_ptr(),
                theta.as_ptr(),
                theta_unc.as_mut_ptr(),
            )
        };

        if retcode != 0 {
            return Err(Error::UnconstrainFailed());
        }
        Ok(())
    }

    pub fn param_unconstrain_json(&mut self, json: &CStr, theta_unc: &mut [f64]) -> Result<()> {
        if theta_unc.len() != self.param_unc_num() {
            return Err(Error::InvalidShape());
        }
        let retcode = unsafe {
            self.lib.0.bs_param_unconstrain_json(
                self.ctx.as_ptr(),
                json.as_ptr(),
                theta_unc.as_mut_ptr(),
            )
        };

        if retcode != 0 {
            return Err(Error::UnconstrainFailed());
        }
        Ok(())
    }

    // TODO shouldn't this be called theta_unc?
    pub fn log_density(&mut self, propto: bool, jacobian: bool, theta: &[f64]) -> Result<f64> {
        // Check that the arrays fits in c_int
        let _: c_int = theta.len().try_into().map_err(|_| Error::InvalidShape())?;
        if theta.len() != self.param_unc_num() {
            return Err(Error::InvalidShape());
        }

        let mut lp = 0f64;
        let retcode = unsafe {
            self.lib.0.bs_log_density(
                self.ctx.as_ptr(),
                propto.into(),
                jacobian.into(),
                theta.as_ptr(),
                &mut lp as *mut f64,
            )
        };

        if retcode != 0 {
            return Err(Error::LogDensityFailed());
        }
        Ok(lp)
    }

    // TODO shouldn't this be called theta_unc?
    pub fn log_density_gradient(
        &mut self,
        propto: bool,
        jacobian: bool,
        theta: &[f64],
        grad: &mut [f64],
    ) -> Result<f64> {
        // Check that the arrays fits in c_int
        let _: c_int = theta.len().try_into().map_err(|_| Error::InvalidShape())?;
        if theta.len() != self.param_unc_num() {
            return Err(Error::InvalidShape());
        }
        if grad.len() != self.param_unc_num() {
            return Err(Error::InvalidShape());
        }

        let mut lp = 0f64;
        let retcode = unsafe {
            self.lib.0.bs_log_density_gradient(
                self.ctx.as_ptr(),
                propto.into(),
                jacobian.into(),
                theta.as_ptr(),
                &mut lp as *mut f64,
                grad.as_mut_ptr(),
            )
        };

        if retcode != 0 {
            return Err(Error::LogDensityFailed());
        }
        Ok(lp)
    }

    pub fn log_density_hessian(
        &mut self,
        propto: bool,
        jacobian: bool,
        theta: &[f64],
        grad: &mut [f64],
        hessian: &mut [f64],
    ) -> Result<f64> {
        // Check that the arrays fits in c_int TODO is this needed?
        let theta_len: c_int = theta.len().try_into().map_err(|_| Error::InvalidShape())?;
        // Check that the arrays fits in c_int
        let expected_hessian_len = theta_len
            .checked_mul(theta_len)
            .ok_or_else(|| Error::InvalidShape())?;
        if theta.len() != self.param_unc_num() {
            return Err(Error::InvalidShape());
        }
        if grad.len() != self.param_unc_num() {
            return Err(Error::InvalidShape());
        }
        if hessian.len() != expected_hessian_len.try_into().unwrap() {
            return Err(Error::InvalidShape());
        }

        let mut lp = 0f64;
        let retcode = unsafe {
            self.lib.0.bs_log_density_hessian(
                self.ctx.as_ptr(),
                propto.into(),
                jacobian.into(),
                theta.as_ptr(),
                &mut lp as *mut f64,
                grad.as_mut_ptr(),
                hessian.as_mut_ptr(),
            )
        };

        if retcode != 0 {
            return Err(Error::LogDensityFailed());
        }
        Ok(lp)
    }
}

impl<'lib> Drop for ModelRng<'lib> {
    fn drop(&mut self) {
        let retcode = unsafe { self.lib.0.bs_destruct(self.ctx.as_ptr()) };
        if retcode != 0 {
            panic!("Failed to destroy stan model.");
        }
    }
}
