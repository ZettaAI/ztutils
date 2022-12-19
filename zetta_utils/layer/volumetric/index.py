# pylint: disable=missing-docstring
from __future__ import annotations

from typing import Optional

import attrs

from zetta_utils import builder

# from zetta_utils.common.partial import ComparablePartial
from zetta_utils.bcube import BoundingCube
from zetta_utils.typing import IntVec3D, Vec3D


@builder.register("VolumetricIndex", cast_to_vec3d=["resolution"])
@attrs.mutable
class VolumetricIndex:  # pragma: no cover # pure delegation, no logic
    resolution: Vec3D
    bcube: BoundingCube
    allow_slice_rounding: bool = False

    def to_slices(self):
        return self.bcube.to_slices(self.resolution, self.allow_slice_rounding)

    def pad(self, pad: IntVec3D):
        return VolumetricIndex(
            bcube=self.bcube.pad(pad=pad, resolution=self.resolution),
            resolution=self.resolution,
        )

    def crop(self, crop: IntVec3D):
        return VolumetricIndex(
            bcube=self.bcube.crop(crop=crop, resolution=self.resolution),
            resolution=self.resolution,
        )

    def translate(self, offset: Vec3D):
        return VolumetricIndex(
            bcube=self.bcube.translate(offset=offset, resolution=self.resolution),
            resolution=self.resolution,
        )

    def translate_start(self, offset: Vec3D):
        return VolumetricIndex(
            bcube=self.bcube.translate_start(offset=offset, resolution=self.resolution),
            resolution=self.resolution,
        )

    def translate_stop(self, offset: Vec3D):
        return VolumetricIndex(
            bcube=self.bcube.translate_stop(offset=offset, resolution=self.resolution),
            resolution=self.resolution,
        )

    def pformat(self, resolution: Optional[Vec3D] = None):
        return self.bcube.pformat(resolution)

    def get_size(self):
        return self.bcube.get_size()

    def intersects(self: VolumetricIndex, other: VolumetricIndex) -> bool:
        return self.bcube.intersects(other.bcube)
