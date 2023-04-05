use bridgestan::StanModel;
use nuts_rs::{new_sampler, Chain, SampleStats, SamplerArgs};
use std::env;
use std::error::Error;
use std::path::Path;

fn main() -> Result<(), Box<dyn Error>> {
    let lib_path = env::args()
        .nth(1)
        .expect("Required to pass a path to the library!");
    let lib = bridgestan::open_library(Path::new(&lib_path))?;

    let data_path = env::args().nth(2).unwrap_or_default();

    let model = StanModel::new(&lib, &data_path, 123, 0)?;

    let n = model.param_unc_num();

    // We get the default sampler arguments
    let mut sampler_args = SamplerArgs::default();

    sampler_args.num_tune = 1000;
    sampler_args.step_size_adapt.target_accept = 0.8;

    let chain = 0;
    let seed = 42;
    let mut sampler = new_sampler(model, sampler_args, chain, seed);

    // Set to some initial position and start drawing samples.
    sampler
        .set_position(&vec![0f64; n])
        .expect("Unrecoverable error during init");

    let mut trace = vec![]; // Collection of all draws
    let mut stats = vec![]; // Collection of statistics like the acceptance rate for each draw
    for _ in 0..2000 {
        let (draw, info) = sampler.draw().expect("Unrecoverable error during sampling");
        trace.push(draw);
        if let Some(div_info) = info.divergence_info() {
            println!("Divergence at position {:?}", div_info.start_location());
        }
        stats.push(info);
    }

    let (_, draws) = trace.split_at(1000);

    println!("{:?}", draws[999]);
    println!("Done!");

    Ok(())
}
