from typing import Any, Generic, TypeVar

import attrs
from typing_extensions import ParamSpec

from zetta_utils import builder, log, mazepa
from zetta_utils.layer import IndexChunker, LayerIndex

logger = log.get_logger("zetta_utils")

IndexT = TypeVar("IndexT", bound=LayerIndex)
P = ParamSpec("P")
R_co = TypeVar("R_co", covariant=True)


@builder.register("ChunkedApplyFlow")
@mazepa.flow_type_cls
@attrs.mutable
class ChunkedApplyFlowType(Generic[IndexT, P, R_co]):
    task_factory: mazepa.TaskFactory[P, R_co]
    chunker: IndexChunker[IndexT]

    def flow(
        self,
        *args: P.args,
        **kwargs: P.kwargs,
    ) -> mazepa.FlowFnReturnType:
        # can't figure out how to force mypy to check this
        idx: IndexT
        assert len(args) == 0
        assert "idx" in kwargs
        idx = kwargs["idx"]  # type: ignore
        # task_args = args
        task_kwargs = {k: v for k, v in kwargs.items() if k not in ["idx"]}
        logger.info(f"Breaking {idx} into chunks with {self.chunker}.")
        idx_chunks = self.chunker(idx)
        tasks = [
            self.task_factory.make_task(
                idx=idx_chunk,  # type: ignore
                # *task_args,
                **task_kwargs,  # type: ignore
            )
            for idx_chunk in idx_chunks
        ]
        logger.info(f"Submitting {len(tasks)} processing tasks from factory {self.task_factory}.")
        yield tasks


@builder.register("build_chunked_apply_flow")
def build_chunked_apply_flow(
    task_factory: mazepa.TaskFactory[P, Any],
    chunker: IndexChunker[IndexT],
    *args: P.args,
    **kwargs: P.kwargs,
) -> mazepa.Flow:
    flow_type = ChunkedApplyFlowType[IndexT, P, None](
        chunker=chunker,
        task_factory=task_factory,
    )
    flow = flow_type(*args, **kwargs)

    return flow
