"""Gambit SMP research and verification framework.

Public Evidence API: repository_clues evaluates caller-owned Scheme/Datalog
over registered Evidence, managing its checked engine by default. Its brief
and persistent checkpoint token support source-bound progressive reads.
engine_api is an optional context manager for grouped reads.

help(repository_clues) is the shared CLI/API contract for sources, term syntax,
scope, presentation and checkpoints. Queries inform reasoning, not action choice
or execution authority; hypotheses and exploration remain caller-owned.

CLI: gambit-smp trajectory clues --help (also python -m gambit_smp).
"""

from importlib import import_module

__all__ = ["engine_api", "repository_clues"]


def __getattr__(name):
    # Preserve CLI --root selection before importing checkout-bound modules.
    modules = {"engine_api": "ascent_program", "repository_clues": "trajectory_exploration"}
    if name not in modules:
        raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
    value = getattr(import_module(f"{__name__}.{modules[name]}"), name)
    globals()[name] = value
    return value


def __dir__():
    return sorted(set(globals()) | set(__all__))
