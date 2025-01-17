from __future__ import annotations

from typing import Mapping, Union

import attrs
import torch
from numpy import typing as npt

from ... import DataProcessor, IndexProcessor, JointIndexDataProcessor, Layer
from .. import UserVolumetricIndex, VolumetricFrontend, VolumetricIndex
from . import VolumetricSetBackend

VolumetricSetDataProcT = Union[
    DataProcessor[dict[str, npt.NDArray]],
    JointIndexDataProcessor[dict[str, npt.NDArray], VolumetricIndex],
]
VolumetricSetDataWriteProcT = Union[
    DataProcessor[Mapping[str, npt.NDArray | torch.Tensor]],
    JointIndexDataProcessor[Mapping[str, npt.NDArray | torch.Tensor], VolumetricIndex],
]


@attrs.frozen
class VolumetricLayerSet(
    Layer[VolumetricIndex, dict[str, npt.NDArray], Mapping[str, npt.NDArray | torch.Tensor]]
):
    backend: VolumetricSetBackend
    frontend: VolumetricFrontend

    readonly: bool = False

    index_procs: tuple[IndexProcessor[VolumetricIndex], ...] = ()
    read_procs: tuple[VolumetricSetDataProcT, ...] = ()
    write_procs: tuple[VolumetricSetDataWriteProcT, ...] = ()

    def __getitem__(self, idx: UserVolumetricIndex) -> dict[str, npt.NDArray]:
        idx_backend = self.frontend.convert_idx(idx)
        return self.read_with_procs(idx=idx_backend)

    def __setitem__(
        self,
        idx: UserVolumetricIndex,
        data: Mapping[str, Union[npt.NDArray, torch.Tensor, int, float, bool]],
    ):
        idx_backend: VolumetricIndex | None = None
        idx_last: VolumetricIndex | None = None
        data_backend = {}
        for k, v in data.items():
            idx_backend, this_data_backend = self.frontend.convert_write(idx_user=idx, data_user=v)
            data_backend[k] = this_data_backend
            assert idx_last is None or idx_backend == idx_last
            idx_last = idx_backend
        assert idx_backend is not None
        self.write_with_procs(idx=idx_backend, data=data_backend)

    def pformat(self) -> str:  # pragma: no cover
        return self.backend.pformat()

    def with_changes(self, **kwargs):
        return attrs.evolve(self, **kwargs)  # pragma: no cover
