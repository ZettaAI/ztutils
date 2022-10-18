from typing import Any, Callable, Literal
import os
import mazepa
from typeguard import typechecked

from zetta_utils.layer import Layer, IndexChunker
from zetta_utils.layer.volumetric import VolumetricIndex
from .. import ChunkedApply
from . import ComputeFieldTaskFactory


@mazepa.flow_type
@typechecked
def compute_z_neighbor_fields(
    src: Layer[Any, VolumetricIndex],
    dst_dir: str,
    compute_field_method: Callable,
    idx: VolumetricIndex,
    chunker: IndexChunker[VolumetricIndex],
    dst_layer_builder: Callable[..., Layer[Any, VolumetricIndex]],
    dst_layer_prefix: str = "neighbor_field_z",
    farthest_neighbor: int = 3,
    direction: Literal["backward", "forward"] = "backward",
):
    if direction == "backward":
        z_offsets = range(-1, -farthest_neighbor - 1, -1)
    else:
        z_offsets = range(1, farthest_neighbor + 1)

    for z_offset in z_offsets:
        dst_path = os.path.join(dst_dir, f"{dst_layer_prefix}_{z_offset}")
        dst = dst_layer_builder(path=dst_path)

        comp_fact = ComputeFieldTaskFactory(
            compute_field_method=compute_field_method,
            tgt_offset=(0, 0, z_offset),
        )

        # TODO: chunked apply is completely untyped here. How to type it to check runtime args?
        comp_flow = ChunkedApply(
            chunker=chunker,
            task_factory=comp_fact,
        )(idx=idx, src=src, dst=dst)

        yield comp_flow
