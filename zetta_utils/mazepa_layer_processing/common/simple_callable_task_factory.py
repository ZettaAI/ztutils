from typing import Any, Callable, Generic, TypeVar

import attrs
from typing_extensions import ParamSpec

from zetta_utils import builder, mazepa
from zetta_utils.layer import IndexChunker, Layer, LayerIndex

from .chunked_apply import ChunkedApplyFlowType

IndexT = TypeVar("IndexT", bound=LayerIndex)
P = ParamSpec("P")


@builder.register("SimpleCallableTaskFactory")
@mazepa.task_factory_cls
@attrs.frozen
class SimpleCallableTaskFactory(Generic[P]):
    """
    Naive Wrapper that converts a callalbe to a task.
    No type checking will be performed on the callable.
    """

    fn: Callable[P, Any]
    # download_layers: bool = True # Could be made optoinal

    def __call__(self, *args: P.args, **kwargs: P.kwargs) -> None:
        # TODO: Is it possible to make mypy check this statically?
        # try task_factory_with_idx_cls
        assert len(args) == 0
        assert "idx" in kwargs
        assert "dst" in kwargs
        idx: IndexT = kwargs["idx"]  # type: ignore
        dst: Layer[Any, IndexT] = kwargs["dst"]  # type: ignore

        fn_kwargs = {}
        for k, v in kwargs.items():
            if k in ["dst", "idx"]:
                pass
            elif isinstance(v, Layer):
                fn_kwargs[f"{k}_data"] = v[idx]
            else:
                fn_kwargs[k] = v

        result = self.fn(**fn_kwargs)
        dst[idx] = result


@builder.register("build_chunked_apply_callable_flow_type")
def build_chunked_apply_callable_flow_type(
    fn: Callable[P, Any], chunker: IndexChunker[IndexT]
) -> ChunkedApplyFlowType[IndexT, P, None]:
    factory = SimpleCallableTaskFactory[P](fn=fn)
    return ChunkedApplyFlowType[IndexT, P, None](
        chunker=chunker,
        task_factory=factory,
    )
