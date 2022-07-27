# pylint: disable=missing-docstring # pragma: no cover
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Iterable, Callable, Tuple, Literal, Generic, TypeVar


class Index(ABC):  # pylint: disable=too-few-public-methods
    pass


BoundedIndex = TypeVar("BoundedIndex", bound=Index)


class IndexConverter(ABC, Generic[BoundedIndex]):  # pylint: disable=too-few-public-methods
    @abstractmethod
    def __call__(self, raw_idx) -> BoundedIndex:
        """
        Returns an index in a canonical form expected by the backend.
        """


class IndexAdjuster(ABC, Generic[BoundedIndex]):  # pylint: disable=too-few-public-methods
    @abstractmethod
    def __call__(self, idx: BoundedIndex) -> BoundedIndex:
        """
        Modifies incoming canonical index.
        """


class IndexAdjusterWithProcessors(
    ABC, Generic[BoundedIndex]
):  # pylint: disable=too-few-public-methods
    @abstractmethod
    def __call__(
        self, idx: BoundedIndex, mode: Literal["read", "write"]
    ) -> Tuple[BoundedIndex, Iterable[Callable]]:
        """
        Modifies incoming canonical index and returns it alongside with a list
        of processors to be applied to data after reading/before writing.
        """
