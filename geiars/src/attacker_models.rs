use candle_core::{shape::Dim, Result, Tensor, D};
use candle_nn::ops::log_softmax;

pub(crate) enum Reduction {
    None,
    Batch,
    Sentence, // not used?
}

pub(crate) fn sequence_cross_entropy_with_logits(
    logits: &Tensor,
    targets: &Tensor,
    mask: &Tensor,
    label_smoothing: f32, // default 0, must be smaller than 1
    reduce: Reduction,
) -> Result<Tensor> {
    // flatten the logits tensor into one dimension, leaving the last dimension out
    // shape: (batch * sequence_length, num_classes)
    let logits_flat = logits.flatten_to(D::Minus2)?;
    //shape : (batch * sequence_length, num_classes)
    let log_probs_flat = log_softmax(&logits_flat, D::Minus1);
    //shape : (batch * max_len, 1)
    let targets_flat = targets.reshape((D::Minus1.to_index(targets.shape(), "reshape")?, 1))?;
    Ok(logits_flat)
}

#[cfg(test)]
mod test {
    use candle_core::{DType, Device, D};

    use super::*;

    #[test]
    fn logit_flattening_equivalent() -> Result<()> {
        let device = &Device::Cpu;
        let logits = candle_core::safetensors::load("logits.st", device)?
            .remove("logits")
            .unwrap();
        let py_logits_flat = candle_core::safetensors::load("logits_flat.st", device)?
            .remove("logits_flat")
            .unwrap();
        let rs_logits_flat = logits.flatten_to(D::Minus2)?;

        // sort of assert?
        py_logits_flat.eq(&rs_logits_flat)?;
        Ok(())
    }

    #[test]
    fn reshape_minus1_to_index_equivalent() -> Result<()> {
        let device = &Device::Cpu;
        let targets = candle_core::safetensors::load("targets.st", device)?
            .remove("targets")
            .unwrap();
        let py_targets_flat = candle_core::safetensors::load("targets_flat.st", device)?
            .remove("targets_flat")
            .unwrap();
        let rs_targets_flat = targets
            .reshape((D::Minus1.to_index(targets.shape(), "reshape")?, 1))
            // trying to duplicate the `.long()` that AFAIK converts to int64
            .and_then(|t| t.to_dtype(DType::U32))?;

        // sort of assert?
        py_targets_flat.eq(&rs_targets_flat)?;
        Ok(())
    }
}
