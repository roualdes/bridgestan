mod common;
use std::{f64::consts::PI, ffi::CString};

use common::get_model;

use approx::{assert_abs_diff_eq, assert_ulps_eq};

use bridgestan::{BridgeStanError, Model};

#[test]
fn throw_data() {
    let (lib, data) = get_model("throw_data");
    let Err(err) = Model::new(&lib, data, 42) else {
        panic!("throw_data model should not successfully be created.");
    };

    let BridgeStanError::ConstructFailed(msg) = err else {
        panic!("Creating throw_data model return an unexpected error");
    };
    assert!(msg.contains("find this text: datafails"));
}

#[test]
#[should_panic(expected = "number of parameters")]
fn bad_arglength() {
    let (lib, data) = get_model("stdnormal");
    let model = Model::new(&lib, data, 42).unwrap();
    let theta = vec![];
    let mut grad = vec![];
    let _ = model.log_density_gradient(&theta[..], true, true, &mut grad[..]);
}

#[test]
fn logp_gradient() {
    let (lib, data) = get_model("stdnormal");
    let model = Model::new(&lib, data, 42).unwrap();
    let theta = vec![1f64];
    let mut grad = vec![0f64];
    let logp = model
        .log_density_gradient(&theta[..], false, true, &mut grad[..])
        .unwrap();
    assert_ulps_eq!(logp, (2. * PI).sqrt().recip().ln() - 0.5);
    assert_ulps_eq!(grad[0], -1f64);
}

#[test]
fn logp_hessian() {
    let (lib, data) = get_model("stdnormal");
    let model = Model::new(&lib, data, 42).unwrap();
    let theta = vec![1f64];
    let mut grad = vec![0f64];
    let mut hessian = vec![0f64];
    let logp = model
        .log_density_hessian(&theta[..], false, true, &mut grad[..], &mut hessian)
        .unwrap();
    assert_ulps_eq!(logp, (2. * PI).sqrt().recip().ln() - 0.5);
    assert_ulps_eq!(grad[0], -1f64);
    assert_abs_diff_eq!(hessian[0], -1f64, epsilon = 1e-10);
}

#[test]
fn hessian_vector_product() {
    let (lib, data) = get_model("simple");
    let model = Model::new(&lib, data, 42).unwrap();

    let n = model.param_unc_num();
    use rand::Rng;

    let mut rng = rand::thread_rng();

    let theta = vec![0.0; n];
    let v: Vec<f64> = (0..n).map(|_| rng.gen()).collect();

    let mut out = vec![0.0; n];
    let _logp = model
        .log_density_hessian_vector_product(&theta, &v, false, true, &mut out)
        .unwrap();

    let minus_v: Vec<f64> = v.iter().map(|x| -x).collect();
    assert_eq!(minus_v, out);
}

#[test]
#[should_panic(expected = "must come from the same")]
fn bad_rng() {
    let (lib1, data1) = get_model("stdnormal");
    let (lib2, data2) = get_model("bernoulli");

    let model1 = Model::new(&lib1, data1, 42).unwrap();
    let model2 = Model::new(&lib2, data2, 42).unwrap();

    let mut rng1 = model1.new_rng(123232).unwrap();

    let theta = vec![0.0; model2.param_unc_num()];
    let mut out = vec![0.0; model2.param_num(false, true)];

    let _ = model2.param_constrain(&theta, false, true, &mut out, Some(&mut rng1));
}

#[test]
fn good_rng_different_instance() {
    let (lib1, data1) = get_model("bernoulli");
    let (_, data2) = get_model("bernoulli");

    let model1 = Model::new(&lib1, data1, 42).unwrap();
    let model2 = Model::new(&lib1, data2, 24).unwrap();

    let mut rng1 = model1.new_rng(123232).unwrap();

    let theta = vec![0.0; model2.param_unc_num()];
    let mut out = vec![0.0; model2.param_num(false, true)];

    let _ = model2.param_constrain(&theta, false, true, &mut out, Some(&mut rng1));
}

#[test]
fn test_params() {
    let (lib, data) = get_model("bernoulli");
    let model = Model::new(&lib, data, 42).unwrap();

    let n = model.param_num(false, false);
    assert!(n == 1);
    let k = model.param_num(true, false);
    let m = model.param_num(false, true);
    let l = model.param_num(true, true);
    assert!(k == 2);
    assert!(m == 2);
    assert!(l == 3);

    assert_eq!(model.param_names(true, true), "theta,logit_theta,y_sim");

    let mut theta_unc = vec![100f64];
    let mut out1 = vec![-1f64];
    let mut out2 = vec![-1f64; 2];
    let mut out3 = vec![-1f64; 3];

    let mut rng = model.new_rng(0).unwrap();

    model
        .param_constrain(&theta_unc[..], true, true, &mut out3, Some(&mut rng))
        .unwrap();
    assert!((out3[2] == 1.) | (out3[2] == 0.));

    assert!(out3[0] == 1.);
    assert_eq!(out3[1], f64::INFINITY);

    model
        .param_constrain(&theta_unc[..], true, false, &mut out2, Some(&mut rng))
        .unwrap();
    assert_eq!(out2, [1., f64::INFINITY]);

    model
        .param_constrain(&theta_unc[..], false, true, &mut out2, Some(&mut rng))
        .unwrap();
    assert_eq!(out2[0], 1.);
    assert!((out2[0] == 1.) | (out2[0] == 0.));

    model
        .param_constrain(&theta_unc[..], false, false, &mut out1, Some(&mut rng))
        .unwrap();
    assert_eq!(out1[0], 1.);

    model.param_unconstrain(&out1, &mut theta_unc).unwrap();
    assert_eq!(theta_unc[0], f64::INFINITY);

    model
        .param_unconstrain_json(CString::new(r#"{"theta": 0.5}"#).unwrap(), &mut theta_unc)
        .unwrap();
    assert_eq!(theta_unc[0], 0.);
}
