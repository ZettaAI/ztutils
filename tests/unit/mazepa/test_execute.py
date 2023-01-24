# pylint: disable=global-statement,redefined-outer-name,unused-argument
from __future__ import annotations

import functools
from contextlib import AbstractContextManager
from typing import Any

import pytest

from zetta_utils.mazepa import (
    Dependency,
    InMemoryExecutionState,
    LocalExecutionQueue,
    TaskStatus,
    concurrent_flow,
    execute,
    flow_schema,
    taskable_operation,
)
from zetta_utils.mazepa.remote_execution_queues import SQSExecutionQueue

TASK_COUNT = 0


@pytest.fixture
def reset_task_count():
    global TASK_COUNT
    TASK_COUNT = 0


@taskable_operation
def dummy_task(argument: str) -> Any:
    global TASK_COUNT
    TASK_COUNT += 1
    return f"return-for-{argument}"


@flow_schema
def dummy_flow():
    task1 = dummy_task.make_task(argument="x1")
    yield task1
    yield Dependency(task1)
    assert task1.status == TaskStatus.SUCCEEDED
    assert task1.outcome.return_value == "return-for-x1"
    task2 = dummy_task.make_task(argument="x2")
    yield task2


@flow_schema
def empty_flow():
    yield []


def test_local_execution_defaults(reset_task_count):
    execute(
        concurrent_flow(
            [
                dummy_flow(),
                dummy_flow(),
                dummy_flow(),
            ]
        ),
        batch_gap_sleep_sec=0,
        max_batch_len=2,
    )
    assert TASK_COUNT == 6


def test_local_execution_one_flow(reset_task_count):
    execute(
        dummy_flow(),
        batch_gap_sleep_sec=0,
        max_batch_len=1,
    )
    assert TASK_COUNT == 2


def test_local_execution_one_callable(reset_task_count) -> None:
    execute(
        functools.partial(dummy_task, argument="x0"),
        batch_gap_sleep_sec=0,
        max_batch_len=1,
    )
    assert TASK_COUNT == 1


def test_local_execution_one_task(reset_task_count) -> None:
    execute(
        dummy_task.make_task(argument="x0"),
        batch_gap_sleep_sec=0,
        max_batch_len=1,
    )
    assert TASK_COUNT == 1


def test_local_execution_killed_by_upkeep(reset_task_count):
    execute(dummy_flow(), batch_gap_sleep_sec=0, max_batch_len=1, upkeep_fn=lambda _: False)
    assert TASK_COUNT == 0


def make_mock_ctx_mngr(mocker) -> AbstractContextManager[Any]:
    mngr_m = mocker.NonCallableMock(spec=AbstractContextManager)
    mngr_m.__enter__ = mocker.MagicMock()
    mngr_m.__exit__ = mocker.MagicMock()
    return mngr_m


def test_local_execution_state(reset_task_count):
    execute(
        InMemoryExecutionState(
            [
                dummy_flow(),
                dummy_flow(),
                dummy_flow(),
            ]
        ),
        execution_id="yo",
        batch_gap_sleep_sec=0,
        max_batch_len=2,
    )
    assert TASK_COUNT == 6


def test_local_execution_state_queue(reset_task_count):
    execute(
        InMemoryExecutionState(
            [
                dummy_flow(),
                dummy_flow(),
                dummy_flow(),
            ]
        ),
        exec_queue=LocalExecutionQueue(debug=True),
        batch_gap_sleep_sec=0,
        max_batch_len=2,
    )
    assert TASK_COUNT == 6


def test_local_no_sleep(mocker):
    sleep_m = mocker.patch("time.sleep")
    execute(
        empty_flow(),
        batch_gap_sleep_sec=10,
        max_batch_len=2,
    )
    sleep_m.assert_not_called()


def test_non_local_sleep(mocker):
    sleep_m = mocker.patch("time.sleep")
    queue_m = mocker.MagicMock(spec=SQSExecutionQueue)
    execute(
        empty_flow(),
        batch_gap_sleep_sec=10,
        max_batch_len=2,
        exec_queue=queue_m,
    )
    sleep_m.assert_called_once()
