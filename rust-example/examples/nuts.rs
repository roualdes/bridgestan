use bridgestan::bs_safe::StanModel;
use nuts_rs::{new_sampler, Chain, SampleStats, SamplerArgs};
use std::env;
use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    let data_path = env::args().nth(1).unwrap_or("".to_string());

    let model = StanModel::new(&data_path, 123, 0)?;

    // We get the default sampler arguments
    let mut sampler_args = SamplerArgs::default();

    sampler_args.num_tune = 1000;
    sampler_args.step_size_adapt.target_accept = 0.8;

    let chain = 0;
    let seed = 42;
    let mut sampler = new_sampler(model, sampler_args, chain, seed);

    // Set to some initial position and start drawing samples.
    sampler
        .set_position(&vec![0f64; 10])
        .expect("Unrecoverable error during init");

    let mut trace = vec![]; // Collection of all draws
    let mut stats = vec![]; // Collection of statistics like the acceptance rate for each draw
    for _ in 0..2000 {
        let (draw, info) = sampler.draw().expect("Unrecoverable error during sampling");
        trace.push(draw);
        let _info_vec = info.to_vec(); // We can collect the stats in a Vec
                                       // Or get more detailed information about divergences
        if let Some(div_info) = info.divergence_info() {
            println!("Divergence at position {:?}", div_info.start_location());
        }
        stats.push(info);
    }

    let (_, draws) = trace.split_at(1000);

    println!("{:?}", draws);

    Ok(())
}
