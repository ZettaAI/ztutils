import attrs
import einops
import torch
from typeguard import typechecked

from zetta_utils import builder, convnet, tensor_ops


@builder.register("naive_misd")
def naive_misd(src: torch.Tensor, tgt: torch.Tensor) -> torch.Tensor:
    result = ((src == 0) + (tgt == 0)).byte()
    return result


@builder.register("MisalignmentDetector")
@typechecked
@attrs.mutable
class MisalignmentDetector:
    # Don't create the model during initialization for efficient serialization
    model_path: str

    def __call__(self, src: torch.Tensor, tgt: torch.Tensor) -> torch.Tensor:
        if False:  # TODO: skip on no data # pylint: disable=using-constant-test
            result = torch.zeros(  # type: ignore
                (1, src.shape[1], src.shape[2], src.shape[3]),
            )
        else:
            if torch.cuda.is_available():
                device = "cuda"
            else:
                device = "cpu"

            # load model during the call _with caching_
            model = convnet.utils.load_model(self.model_path, device=device, use_cache=True)

            # the input is assumed to be uint8 encoding
            assert src.dtype == torch.uint8
            assert tgt.dtype == torch.uint8
            src_zcxy = einops.rearrange(src, "C X Y Z -> Z C X Y").float()
            tgt_zcxy = einops.rearrange(tgt, "C X Y Z -> Z C X Y").float()

            data_in = torch.cat((src_zcxy, tgt_zcxy), 1) - 127.0
            data_in /= 255.0

            result = model(data_in.to(device))

            result = einops.rearrange(result, "Z C X Y -> C X Y Z")
            src_mask = tensor_ops.mask.filter_cc(
                (src == 127) + (src == 0),
                mode="keep_large",
                thr=1000,
            )
            tgt_mask = tensor_ops.mask.filter_cc(
                (tgt == 127) + (tgt == 0),
                mode="keep_large",
                thr=1000,
            )
            result[src_mask] = 1
            result[tgt_mask] = 1

            assert result.shape[0] == 1

            assert result.max() <= 1, "Final layer of misalignment detector assumed to be sigmoid"
            assert result.max() >= 0, "Final layer of misalignment detector assumed to be sigmoid"
            result = 255.0 * result

        return result.byte().to(src.device)