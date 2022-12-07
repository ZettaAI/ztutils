"""Output logging."""
# pylint: disable=global-statement
from __future__ import annotations

import logging
import os
from contextlib import contextmanager
from contextvars import ContextVar
from typing import Optional

import cachetools
import logging_loki
import typeguard
from rich.logging import RichHandler
from rich.traceback import install

SUPRESS_TRACEBACK_MODULES = [cachetools, typeguard]

LOKI_HANDLER = None


class InjectingFilter(logging.Filter):
    """
    A filter which injects context-specific information into logs
    """

    def __init__(self):
        super().__init__()

    def filter(self, record):
        for k in ["zetta_user", "zetta_project"]:
            value = CTX_VARS[k].get()
            if LOKI_HANDLER is not None:
                LOKI_HANDLER.emitter.tags[k] = value
            setattr(record, k, value)
        return True


def update_traceback():
    install(show_locals=True, suppress=SUPRESS_TRACEBACK_MODULES)


def add_supress_traceback_module(module):
    SUPRESS_TRACEBACK_MODULES.append(module)
    update_traceback()


update_traceback()


def get_time_str(log_time):
    return log_time.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]


SAVED_LEVEL = "ERROR"


def configure_logger(level=None, third_party_level="WARN"):
    for _ in (
        "python_jsonschema_objects",
        "pytorch_lightning",
        "urllib3",
        "google",
        "gcsfs",
        "fsspec",
        "asyncio",
        "botocore",
        "matplotlib",
        "git",
        "h5py",
        "torch",
    ):
        logging.getLogger(_).setLevel(third_party_level)

    global SAVED_LEVEL
    if level is None:
        level = SAVED_LEVEL
    else:
        if isinstance(level, int):
            level = max(0, 20 - 10 * level)
        SAVED_LEVEL = level

    rich_handler = RichHandler(
        rich_tracebacks=True,
        show_path=False,
        show_time=True,
        enable_link_path=False,
        log_time_format=get_time_str,
    )
    rich_handler.addFilter(InjectingFilter())
    handlers = [rich_handler]
    if LOKI_HANDLER is not None:
        handlers.append(LOKI_HANDLER)
    logging.basicConfig(
        level=level, format="%(name)s %(pathname)20s:%(lineno)4d \n%(message)s", handlers=handlers
    )
    logging.getLogger("mazepa").setLevel(level)
    logging.getLogger("zetta_utils").setLevel(level)


def get_logger(name):
    configure_logger()
    return logging.getLogger(name)


def set_verbosity(verbosity_level):
    global SAVED_LEVEL
    SAVED_LEVEL = verbosity_level
    logging.getLogger("zetta_utils").setLevel(verbosity_level)
    logging.getLogger("mazepa").setLevel(verbosity_level)


ENV_CTX_VARS = [
    "zetta_user",
    "zetta_project",
    "my_node_name",
    "my_pod_name",
    "my_pod_ip",
    "my_pod_service_account",
]
CTX_VARS = {k: ContextVar[Optional[str]](k, default=None) for k in ENV_CTX_VARS}


def set_logging_tag(name, value):
    print(f"Set up logging tag '{name}' to {value}")
    CTX_VARS[name].set(value)


@contextmanager
def logging_tag_ctx(key, value):
    old_value = CTX_VARS[key].get()
    set_logging_tag(key, value)
    yield
    set_logging_tag(key, old_value)


def _init_ctx_vars():
    for k in CTX_VARS:
        k_env = k.upper()
        if k_env in os.environ:
            set_logging_tag(k, os.environ[k_env])


_init_ctx_vars()

GRAFANA_USER_ID = "340203"
GRAFANA_KEY = os.environ.get("GRAFANA_CLOUD_ACCESS_KEY", None)
if GRAFANA_KEY is not None:
    LOKI_HANDLER = logging_loki.LokiHandler(
        url=f"https://{GRAFANA_USER_ID}:{GRAFANA_KEY}@logs-prod3.grafana.net/loki/api/v1/push",
        version="1",
    )
    print(
        "Configured Grafana Cloud Loki logging. "
        "Access logs from this machine at https://sergiytest.grafana.net/explore"
    )
else:
    print(
        "Failed to find `GRAFANA_CLOUD_ACCESS_KEY` env variable -- Loki logs won't be accessible."
    )

configure_logger()
