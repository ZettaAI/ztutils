from typing import Protocol, TypeVar

import torch
from torch import Tensor
from typing_extensions import ParamSpec

from zetta_utils import builder

from .mask import kornia_erosion

P = ParamSpec("P")


class MultiTensorOp(Protocol[P]):
    """
    Protocol which defines what it means for a function to be a MultiTensorOp:
    it must take a `data1` and 'data2' arguments of Tensor type, and return a
    tensor of the same type.
    """

    def __call__(self, data1: Tensor, data2: Tensor, *args: P.args, **k: P.kwargs) -> Tensor:
        ...


OpT = TypeVar("OpT", bound=MultiTensorOp)


def skip_on_empty_datas(fn: OpT) -> OpT:
    """
    Decorator that ensures early exit for a tensor op when `data1` and 'data2' are both zeros.
    """

    def wrapped(data1: Tensor, data2: Tensor, *args: P.args, **kwargs: P.kwargs) -> Tensor:
        if (data1 != 0).sum() == 0 and (data2 != 0).sum() == 0:
            result = data1
        else:
            result = fn(data1, data2, *args, **kwargs)
        return result

    return wrapped  # type: ignore


@builder.register("compute_pixel_error")
@skip_on_empty_datas
def compute_pixel_error(data1: Tensor, data2: Tensor, erosion: int = 3, **kwargs) -> Tensor:
    """
    Returns the symmetric pixel difference of two tensors in the area
    where two tensors overlap after erosion to exclude edge artifacts.
    :param data1: Input tensor (CXYZ).
    :param data2: Input tensor (CXYZ).
    :param erosion: Follows skimage convention, defaults to 3.
    :param kwargs: Additional keyword arguments passed to kornia_dilation.
    :return: The symmetric difference of the two input tensors.
    """
    dilated_mask = torch.logical_or(
        kornia_erosion(data1, width=erosion, **kwargs) == 0,
        kornia_erosion(data2, width=erosion, **kwargs) == 0,
    )
    zeros = torch.zeros_like(data1)
    return torch.where(
        dilated_mask, zeros, torch.minimum((data1 - data2).abs(), (data2 - data1).abs())
    )


@builder.register("erode_combine")
@skip_on_empty_datas
def erode_combine(data1: Tensor, data2: Tensor, erosion: int = 3, **kwargs) -> Tensor:
    """
    Combines two tensors by taking values from each one where they do not overlap,
    and averaging the two where they do. The overlap is determined after erosion
    on the zero mask to exclude edge artifacts.
    :param data1: Input tensor (CXYZ).
    :param data2: Input tensor (CXYZ).
    :param erosion: Follows skimage convention, defaults to 3.
    :param kwargs: Additional keyword arguments passed to kornia_dilation.
    :return: The symmetric difference of the two input tensors.
    """
    mask1 = kornia_erosion(data1, width=erosion, **kwargs) != 0
    mask2 = kornia_erosion(data2, width=erosion, **kwargs) != 0
    not_mask1 = torch.logical_not(mask1)
    not_mask2 = torch.logical_not(mask2)
    result = torch.where(
        torch.logical_and(mask1, mask2),
        (0.5 * data1 + 0.5 * data2).to(data1.dtype),
        torch.zeros_like(data1),
    )
    result = torch.where(not_mask2, data1, result)
    result = torch.where(not_mask1, data2, result)
    result = torch.where(torch.logical_and(not_mask1, not_mask2), torch.zeros_like(data1), result)

    return result
