pub mod bs_safe;
pub mod bs_unsafe;

use bs_safe::StanModel;
use std::env;
use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    let data_path = env::args().nth(1).unwrap_or("".to_string());

    let model = StanModel::new(&data_path, 123, 0)?;

    let s = model.name()?;
    println!("The model's name is {}.", s);
    println!(
        "The model has {} parameters.",
        model.param_num(false, false)
    );

    Ok(())
}
