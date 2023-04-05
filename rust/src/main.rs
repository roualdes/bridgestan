use bridgestan::{BridgeStanError, Model};
use std::env;
use std::error::Error;
use std::path::Path;
use std::sync::Arc;
use std::thread::{self, JoinHandle};

fn main() -> Result<(), Box<dyn Error>> {
    let lib_path = env::args()
        .nth(1)
        .expect("Required to pass a path to the library!");
    let lib = bridgestan::open_library(Path::new(&lib_path))?;

    let lib = Arc::new(lib);

    let out: JoinHandle<Result<_, BridgeStanError>> = thread::spawn(move || {
        let data_path = env::args().nth(2).unwrap_or_default();

        let model = Model::new(lib, &data_path, 123)?;

        println!(
            "The model has {} parameters.",
            model.param_num(false, false)
        );

        let name = model.name().unwrap();
        println!("The model's name is {}.", name);

        // parallel evaluation of log_density_gradient

        let n = model.param_unc_num();

        // location for the results
        let mut grad = vec![vec![0.0; n]; 25];
        let theta = (1..n + 1).map(|s| s as f64).collect::<Vec<f64>>();

        thread::scope(|s| {
            for g in grad.iter_mut() {
                s.spawn(|| {
                    model
                        .log_density_gradient(theta.as_slice(), true, true, g.as_mut_slice())
                        .unwrap();
                });
            }
        });

        println!("{:?}", &grad);

        Ok(())
    });

    out.join().unwrap().unwrap();

    Ok(())
}
