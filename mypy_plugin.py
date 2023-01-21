# pylint: disable=all # type: ignore
from __future__ import annotations

from typing import Callable, Final, Optional

from mypy.plugin import ClassDefContext, Plugin
from mypy.plugins.common import add_method_to_class  # add_attribute_to_class,
from mypy.types import AnyType, Parameters, TypeOfAny


def task_maker_cls_hook(ctx):  # pragma: no cover # type: ignore
    call_method = ctx.cls.info.get_method("__call__")
    if call_method is not None and call_method.type is not None:
        args = call_method.arguments
        for arg in args[1:]:
            if arg.type_annotation is None:
                arg.type_annotation = AnyType(TypeOfAny.unannotated)

        return_type = ctx.api.named_type(
            fullname="zetta_utils.mazepa.Task",
            args=[
                call_method.type.ret_type,
            ],
        )
        add_method_to_class(
            ctx.api,
            ctx.cls,
            "make_task",
            args=args[1:],
            return_type=return_type,
        )

    return True

def task_maker_cls_hook_2(ctx):  # pragma: no cover # type: ignore

    reference_method = ctx.cls.info.get_method("__call__")
    created_method = ctx.cls.info.get_method("make_task")
    return True

    for i in range(len(reference_method.arguments)):
        if reference_method.arguments[i].variable.type != created_method.arguments[i].variable.type:
            breakpoint()
        if reference_method.arguments[i].variable.name!= created_method.arguments[i].variable.name:
            breakpoint()

    return True

def flow_schema_cls_hook(ctx):  # pragma: no cover # type: ignore
    reference_method = ctx.cls.info.get_method("flow")
    if reference_method is not None:
        args = reference_method.arguments
        for arg in args[1:]:
            if arg.type_annotation is None:
                arg.type_annotation = AnyType(TypeOfAny.unannotated)
        #breakpoint()
        return_type = ctx.api.named_type(
            fullname="zetta_utils.mazepa.Flow",
        )

        add_method_to_class(
            ctx.api,
            ctx.cls,
            "__call__",
            args=args[1:],
            return_type=return_type,
        )

    return True

def flow_schema_cls_hook_2(ctx):  # pragma: no cover # type: ignore
    reference_method = ctx.cls.info.get_method("flow")
    created_method = ctx.cls.info.get_method("__call__")

    return True
    for i in range(len(reference_method.arguments)):
        if reference_method.arguments[i].variable.type != created_method.arguments[i].variable.type:
            breakpoint()
        if reference_method.arguments[i].variable.name!= created_method.arguments[i].variable.name:
            breakpoint()

    return True

TASK_FACTORY_CLS_MAKERS: Final = {
    "zetta_utils.mazepa.tasks.taskable_operation_cls",
    # "zetta_utils.mazepa.tasks.taskable_operation_with_idx_cls"
}
FLOW_TYPE_CLS_MAKERS: Final = {"zetta_utils.mazepa.flows.flow_schema_cls"}


class MazepaPlugin(Plugin):
    def get_class_decorator_hook(
        self, fullname: str
    ) -> Optional[Callable[[ClassDefContext], bool]]:  # pragma: no cover
        if fullname in TASK_FACTORY_CLS_MAKERS:
            return task_maker_cls_hook
        if fullname in FLOW_TYPE_CLS_MAKERS:
            return flow_schema_cls_hook
        return None

    def get_class_decorator_hook_2(
        self, fullname: str
    ) -> Optional[Callable[[ClassDefContext], bool]]:  # pragma: no cover
        if fullname in TASK_FACTORY_CLS_MAKERS:
            return task_maker_cls_hook_2
        if fullname in FLOW_TYPE_CLS_MAKERS:
            return flow_schema_cls_hook_2
        return None





class DummyPlugin(Plugin):  # pragma: no cover
    pass


def plugin(version):  # pragma: no cover
    try:
        from zetta_utils import mazepa  # pylint: disable
    except ModuleNotFoundError:
        return DummyPlugin
    else:
        return MazepaPlugin
