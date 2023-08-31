use candle_core::{DType, Device, Result, Tensor};

mod attacker_models;

fn main() -> Result<()> {
    let logits = Tensor::zeros((2, 3), DType::F32, &Device::Cpu)?;
    let targets = Tensor::zeros((2, 3), DType::F32, &Device::Cpu)?;
    let mask = Tensor::zeros((2, 3), DType::F32, &Device::Cpu)?;
    let sequenced = attacker_models::sequence_cross_entropy_with_logits(
        &logits,
        &targets,
        &mask,
        0.2,
        attacker_models::Reduction::Batch,
    )?;
    dbg!(sequenced);
    Ok(())
}
