# pylint: disable=missing-docstring,redefined-outer-name,unused-argument,pointless-statement,line-too-long,protected-access,too-few-public-methods
import os
import pathlib

import numpy as np
import pytest
import tensorstore
import torch

from zetta_utils.geometry import BBox3D, IntVec3D, Vec3D
from zetta_utils.layer.volumetric import (
    VolumetricFrontend,
    VolumetricIndex,
    VolumetricLayer,
)
from zetta_utils.layer.volumetric.cloudvol import CVBackend
from zetta_utils.layer.volumetric.layer_set import VolumetricSetBackend
from zetta_utils.layer.volumetric.precomputed import PrecomputedInfoSpec, precomputed
from zetta_utils.layer.volumetric.tensorstore import TSBackend

THIS_DIR = pathlib.Path(__file__).parent.resolve()
INFOS_DIR = os.path.abspath(THIS_DIR / "../../../assets/infos/")
LAYER_X0_PATH = "file://" + os.path.join(INFOS_DIR, "layer_x0")
LAYER_X1_PATH = "file://" + os.path.join(INFOS_DIR, "layer_x1")
LAYER_X2_PATH = "file://" + os.path.join(INFOS_DIR, "layer_x2")
LAYER_X3_PATH = "file://" + os.path.join(INFOS_DIR, "layer_x3")
LAYER_X4_PATH = "file://" + os.path.join(INFOS_DIR, "layer_x4")
LAYER_X5_PATH = "file://" + os.path.join(INFOS_DIR, "scratch", "layer_x5")
LAYER_X6_PATH = "file://" + os.path.join(INFOS_DIR, "scratch", "layer_x6")
LAYER_X7_PATH = "file://" + os.path.join(INFOS_DIR, "scratch", "layer_x7")

# Hack to mock a immutable method `write_info`
_write_info_notmock = precomputed._write_info
_getitem_notmock = tensorstore.TensorStore.__getitem__


@pytest.fixture
def clear_caches():
    precomputed._info_cache.clear()


def test_ts_backend_bad_path_exc():
    with pytest.raises(RuntimeError):
        TSBackend(path="abc")


def test_ts_backend_dtype():
    info_spec = PrecomputedInfoSpec(reference_path=LAYER_X0_PATH, data_type="uint8")
    tsb = TSBackend(path=LAYER_X0_PATH, info_spec=info_spec, on_info_exists="overwrite")

    assert tsb.dtype == torch.uint8


def test_ts_backend_dtype_exc():
    info_spec = PrecomputedInfoSpec(reference_path=LAYER_X0_PATH, data_type="nonsense")
    tsb = TSBackend(path=LAYER_X6_PATH, info_spec=info_spec, on_info_exists="overwrite")
    with pytest.raises(ValueError):
        tsb.dtype


def test_ts_backend_info_expect_same_exc(mocker):
    precomputed._write_info = mocker.MagicMock()
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
    )
    with pytest.raises(RuntimeError):
        TSBackend(path=LAYER_X1_PATH, info_spec=info_spec, on_info_exists="expect_same")
    precomputed._write_info.assert_not_called()


@pytest.mark.parametrize(
    "path, reference, mode",
    [
        [LAYER_X0_PATH, LAYER_X0_PATH, "overwrite"],
        [LAYER_X0_PATH, LAYER_X0_PATH, "expect_same"],
        [LAYER_X0_PATH, None, "overwrite"],
        [LAYER_X0_PATH, None, "expect_same"],
    ],
)
def test_ts_backend_info_no_action(path, reference, mode, mocker):
    precomputed._write_info = mocker.MagicMock()
    info_spec = PrecomputedInfoSpec(
        reference_path=reference,
    )
    TSBackend(path=path, info_spec=info_spec, on_info_exists=mode)

    precomputed._write_info.assert_not_called()


@pytest.mark.parametrize(
    "path, reference, mode",
    [
        [LAYER_X1_PATH, LAYER_X0_PATH, "overwrite"],
        [".", LAYER_X0_PATH, "overwrite"],
    ],
)
def test_ts_backend_info_overwrite(clear_caches, path, reference, mode, mocker):
    precomputed._write_info = mocker.MagicMock()
    info_spec = PrecomputedInfoSpec(
        reference_path=reference,
        default_chunk_size=IntVec3D(999, 999, 1),
    )
    TSBackend(path=path, info_spec=info_spec, on_info_exists=mode)

    precomputed._write_info.assert_called_once()


@pytest.mark.parametrize(
    "path, reference",
    [
        [LAYER_X0_PATH, LAYER_X0_PATH],
    ],
)
def test_ts_backend_info_no_overwrite_when_same_as_cached(clear_caches, path, reference, mocker):
    precomputed._write_info = mocker.MagicMock()
    info_spec = PrecomputedInfoSpec(
        reference_path=reference,
    )
    TSBackend(path=path, info_spec=info_spec, on_info_exists="overwrite")

    precomputed._write_info.assert_not_called()


def test_ts_backend_read_idx(clear_caches, mocker):
    expected_shape = (1, 3, 4, 5)
    tsb = TSBackend(path=LAYER_X0_PATH)
    index = VolumetricIndex(
        bbox=BBox3D.from_slices((slice(0, 3), slice(1, 5), slice(2, 7))),
        resolution=Vec3D(1, 1, 1),
    )
    result = tsb.read(index)
    assert result.shape == expected_shape


def test_ts_backend_read_partial(clear_caches, mocker):
    tensorstore.TensorStore.__getitem__ = mocker.MagicMock(
        return_value=np.ones(shape=(1, 1, 1, 1), dtype=np.uint8)
    )
    tsb = TSBackend(path=LAYER_X0_PATH)
    index = VolumetricIndex(
        bbox=BBox3D.from_slices((slice(-1, 1), slice(0, 1), slice(0, 1))),
        resolution=Vec3D(1, 1, 1),
    )
    result = tsb.read(index)
    assert result[:, 0:1, :, :] == torch.zeros((1, 1, 1, 1), dtype=torch.uint8)
    assert result[:, 1:2, :, :] == torch.ones((1, 1, 1, 1), dtype=torch.uint8)


def test_ts_backend_write_idx(clear_caches, mocker):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
    )
    tsb = TSBackend(path=LAYER_X5_PATH, info_spec=info_spec, on_info_exists="overwrite")
    value = torch.ones([1, 3, 4, 5], dtype=torch.uint8)

    index = VolumetricIndex(
        bbox=BBox3D.from_slices((slice(0, 3), slice(1, 5), slice(2, 7))),
        resolution=Vec3D(1, 1, 1),
    )
    tsb.write(index, value)


def test_ts_backend_write_scalar_idx(clear_caches, mocker):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
    )
    tsb = TSBackend(path=LAYER_X5_PATH, info_spec=info_spec, on_info_exists="overwrite")
    value = torch.tensor([1], dtype=torch.uint8)

    index = VolumetricIndex(
        bbox=BBox3D.from_slices((slice(0, 3), slice(1, 5), slice(2, 7))),
        resolution=Vec3D(1, 1, 1),
    )
    tsb.write(index, value)


@pytest.mark.parametrize(
    "data_in,expected_exc",
    [
        # Too many dims
        [torch.ones((1, 2, 3, 4, 5, 6)), ValueError],
    ],
)
def test_ts_backend_write_exc(data_in, expected_exc, clear_caches, mocker):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
    )
    tsb = TSBackend(path=LAYER_X5_PATH, info_spec=info_spec, on_info_exists="overwrite")
    index = VolumetricIndex(
        bbox=BBox3D.from_slices((slice(1, 1), slice(1, 2), slice(2, 3))),
        resolution=Vec3D(1, 1, 1),
    )
    with pytest.raises(expected_exc):
        tsb.write(index, data_in)


def test_ts_get_chunk_size(clear_caches):
    precomputed._write_info = _write_info_notmock
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(1024, 1024, 1),
    )
    tsb = TSBackend(path=LAYER_X7_PATH, info_spec=info_spec, on_info_exists="overwrite")

    assert tsb.get_chunk_size(Vec3D(2, 2, 1)) == IntVec3D(1024, 1024, 1)


def test_ts_get_voxel_offset(clear_caches):
    precomputed._write_info = _write_info_notmock
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(1024, 1024, 1),
        default_voxel_offset=IntVec3D(1, 2, 3),
    )
    tsb = TSBackend(path=LAYER_X7_PATH, info_spec=info_spec, on_info_exists="overwrite")

    assert tsb.get_voxel_offset(Vec3D(2, 2, 1)) == IntVec3D(1, 2, 3)


def test_ts_with_changes(clear_caches, mocker):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(1024, 1024, 1),
    )
    precomputed._write_info = _write_info_notmock
    tsb = TSBackend(path=LAYER_X5_PATH, info_spec=info_spec, on_info_exists="overwrite")
    tsb_new = tsb.with_changes(
        name=LAYER_X5_PATH,
        voxel_offset_res=(IntVec3D(3, 2, 1), Vec3D(2, 2, 1)),
        chunk_size_res=(IntVec3D(512, 512, 1), Vec3D(2, 2, 1)),
        enforce_chunk_aligned_writes=False,
    )
    assert tsb_new.name == LAYER_X5_PATH
    assert tsb_new.get_voxel_offset(Vec3D(2, 2, 1)) == IntVec3D(3, 2, 1)
    assert tsb_new.get_chunk_size(Vec3D(2, 2, 1)) == IntVec3D(512, 512, 1)
    assert not tsb_new.enforce_chunk_aligned_writes


def test_ts_from_precomputed_cv(clear_caches, mocker):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(1024, 1024, 1),
    )
    cvb = CVBackend(path=LAYER_X5_PATH, info_spec=info_spec, on_info_exists="overwrite")
    tsb = TSBackend.from_precomputed(cvb)
    assert tsb.path == cvb.path
    assert tsb.info_spec == cvb.info_spec
    assert tsb.on_info_exists == cvb.on_info_exists


def test_ts_from_precomputed_layer_set(clear_caches, mocker):
    info_spec1 = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(1024, 1024, 1),
    )
    info_spec2 = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(1023, 1023, 1),
    )
    cvb1 = CVBackend(path=LAYER_X6_PATH, info_spec=info_spec1, on_info_exists="overwrite")
    cvb2 = CVBackend(path=LAYER_X7_PATH, info_spec=info_spec2, on_info_exists="overwrite")
    lsb = VolumetricSetBackend(
        layers={
            "cvb1": VolumetricLayer(cvb1, VolumetricFrontend()),
            "cvb2": VolumetricLayer(cvb2, VolumetricFrontend()),
        }
    )
    tsb = TSBackend.from_precomputed(lsb)
    assert TSBackend.from_precomputed(lsb.layers["cvb1"].backend) == tsb.layers["cvb1"].backend
    assert TSBackend.from_precomputed(lsb.layers["cvb2"].backend) == tsb.layers["cvb2"].backend


def test_ts_with_changes_exc(clear_caches, mocker):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(1024, 1024, 1),
    )
    tsb = TSBackend(path=LAYER_X5_PATH, info_spec=info_spec, on_info_exists="overwrite")
    with pytest.raises(KeyError):
        tsb.with_changes(nonsensename="nonsensevalue")


def test_ts_with_changes_exc_assert(clear_caches, mocker):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X5_PATH,
        default_chunk_size=IntVec3D(1024, 1024, 1),
    )
    tsb = TSBackend(path=LAYER_X5_PATH, info_spec=info_spec, on_info_exists="overwrite")
    with pytest.raises(ValueError):
        tsb.with_changes(enforce_chunk_aligned_writes=True)


def test_ts_assert_idx_is_chunk_aligned(clear_caches):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(3, 5, 7),
        default_voxel_offset=IntVec3D(1, 2, 3),
    )
    tsb = TSBackend(path=LAYER_X4_PATH, info_spec=info_spec, on_info_exists="overwrite")
    index = VolumetricIndex(
        bbox=BBox3D.from_slices(
            (slice(1, 4), slice(-8, 12), slice(-18, -11)), resolution=Vec3D(2, 2, 1)
        ),
        resolution=Vec3D(2, 2, 1),
    )
    tsb.assert_idx_is_chunk_aligned(index)


def test_ts_assert_idx_is_chunk_aligned_exc(clear_caches):
    info_spec = PrecomputedInfoSpec(
        reference_path=LAYER_X0_PATH,
        default_chunk_size=IntVec3D(3, 5, 7),
        default_voxel_offset=IntVec3D(1, 2, 3),
    )
    tsb = TSBackend(path=LAYER_X4_PATH, info_spec=info_spec, on_info_exists="overwrite")
    index = VolumetricIndex(
        bbox=BBox3D.from_slices(
            (slice(1, 5), slice(-8, 12), slice(-18, -11)), resolution=Vec3D(2, 2, 1)
        ),
        resolution=Vec3D(2, 2, 1),
    )

    with pytest.raises(ValueError):
        tsb.assert_idx_is_chunk_aligned(index)
