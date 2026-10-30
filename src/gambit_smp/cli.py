"""One installed entry point for model, source, native, and evidence adapters."""
import argparse
from importlib import import_module
import os
from pathlib import Path
import sys
from contextlib import nullcontext
from contextvars import ContextVar
from functools import wraps

from gambit_smp.task_entry import _dispatch, _observation_address, _observation_presenter


COMMANDS = {
    "workspace": "workspace",
    "agent": "grok_session",
    "tool": "tool_dispatch",
    "storage-retention": "storage_retention",
    "check": "check_gambit",
    "verify": "verify_protocols",
    "progress": "model_progress",
    "source-unit": "source_unit",
    "ffi-source-unit": "ffi_source_unit",
    "sync-schedule": "sync_retirement_source",
    "gc-wait-schedule": "gc_wait_source",
    "gc-queue-binding": "gc_queue_binding",
    "allocator-acquire": "allocator_acquire",
    "allocator-object": "allocator_object",
    "suite": "native_suite",
    "suite-coverage": "suite_coverage",
    "bootstrap": "bootstrap_runtime",
    "compiler-cost": "compiler_cost",
    "identity": "runtime_identity",
    "evidence": "evidence_index",
    "recipes": "recipes",
    "research": "research_kernel",
    "audit": "research_audit",
    "ascent-review": "ascent_review",
    "validate-review": "review_validation",
    "agent-context": "agent_context",
    "actions": "research_actions",
    "trajectory": "trajectory_exploration",
    "tool-environment": "tool_environment",
    "publish-protocol": "protocol_evidence",
    "recover-model": "recover_model",
    "publish-progress": "progress_evidence",
    "publish-source-observation": "source_evidence",
    "papers": "paper_cache",
    "materialize-source": "source_materialize",
    "reproduction-inputs": "reproduction_check",
    "induction-matrix": "induction_matrix",
    "upstream-audit": "upstream_audit",
    "upstream-snapshot": "upstream_snapshot",
    "debug": "debug_runtime",
    "crash": "crash_evidence",
}

HISTORICAL_PRODUCERS = frozenset({"source-unit", "ffi-source-unit", "sync-schedule", "gc-wait-schedule",
                                 "gc-queue-binding", "allocator-acquire", "allocator-object", "bootstrap"})


def observation_evidence(result, root):
    """Present registered references without changing native receipt admission."""
    recipe = result.get('recipe')
    if not isinstance(recipe, str) or not recipe:
        return result
    from gambit_smp.trajectory_exploration import repository_clues
    enriched = dict(result)
    try:
        enriched['evidence'] = repository_clues(root, bindings=[['recipe', recipe]])
    except (OSError, ValueError, RuntimeError) as error:
        enriched['evidenceError'] = str(error)
    return enriched


def main(argv=None, *, _callback=None):
    parser = argparse.ArgumentParser(description=__doc__, epilog=
        "trajectory clues: Scheme requests over registered Evidence and caller-owned DSL; "
        "source-bound, expandable incremental slices. Python API: "
        "from gambit_smp import repository_clues, engine_api (callables, not submodules). "
        "Reads do not select or authorize actions.")
    parser.add_argument("--root", type=Path, help="research checkout containing models and evidence")
    parser.add_argument("--process", help="registered process role inside the work item")
    parser.add_argument("--task", help="stable campaign ID; reuse across Codex and Grok")
    parser.add_argument("--historical-reproduction", action="store_true",
                        help="explicitly select a retained historical producer, not the new research lane")
    parser.add_argument("command", choices=COMMANDS)
    parser.add_argument("arguments", nargs=argparse.REMAINDER,
                        help="adapter options; use COMMAND --help")
    args = parser.parse_args(argv)
    if args.command in HISTORICAL_PRODUCERS and not args.historical_reproduction and "--help" not in args.arguments:
        parser.error("historical producer is not a new experiment entry point; use research with a sealed artifact graph")
    if args.root is not None:
        root = args.root.resolve()
        if not (root / "models/gambit/cases.json").is_file() or not (root / "evidence").is_dir():
            parser.error("--root must identify a Gambit SMP research checkout")
        os.environ["GAMBIT_SMP_ROOT"] = str(root)
    adapter = import_module("gambit_smp." + COMMANDS[args.command])
    target = _callback or adapter.main
    def invoke():
        token=_dispatch.set(True)
        address=_observation_address.set((selected_root, args.task or os.environ.get('GAMBIT_SMP_TASK_ID')))
        # Native execution returns its bound receipt. Catalog expansion is an
        # explicit read, never hidden work after the native budget has ended.
        presenter=_observation_presenter.set(
            (lambda result: result) if args.command == 'research' and '--run' in args.arguments
            else (lambda result: observation_evidence(result, selected_root)))
        try:return target()
        finally:
            _observation_presenter.reset(presenter)
            _observation_address.reset(address)
            _dispatch.reset(token)
    previous = sys.argv
    try:
        sys.argv = ["gambit-smp " + args.command, *args.arguments]
        from gambit_smp.framework import project_root
        from gambit_smp.task_dependencies import default_task
        from gambit_smp import workspace
        selected_root = (Path(os.environ["GAMBIT_SMP_TASK_ROOT"]).resolve(strict=True)
                         if args.root is None and os.environ.get("GAMBIT_SMP_TASK_ID") and os.environ.get("GAMBIT_SMP_TASK_ROOT")
                         else project_root())
        maintenance = args.command in {"workspace", "storage-retention"}
        if maintenance and (args.task is not None or args.process is not None):
            parser.error("workspace maintenance has its own task arguments")
        policy = getattr(adapter, "execution_policy", None)
        if not maintenance and "--help" not in args.arguments and policy is not None:
            if policy(args.arguments) in {"read", "journal"}:
                return invoke()
        task = args.task or os.environ.get("GAMBIT_SMP_TASK_ID") or default_task(selected_root)
        if args.command=='tool' and args.arguments[:1]==['grok-event-wait']:
            return invoke()
        if args.command=='agent' and args.process:parser.error('provider sessions use the work-item execution owner; maintenance processes run bounded tools')
        if args.command=='agent':
            if args.task:
                if '--task' in args.arguments:parser.error('specify the task once')
                sys.argv += ['--task',args.task]
            elif '--task' not in args.arguments and task:sys.argv += ['--task',task]
            if args.root is not None and '--workspace' not in args.arguments:sys.argv += ['--workspace',str(args.root)]
            return invoke()
        if task and not maintenance and "--help" not in args.arguments:
            from gambit_smp.work_process import scope as process_scope
            manager=process_scope(selected_root,task,args.process) if args.process else workspace.execution_scope(selected_root,task)
            with manager as (value, _, _):
                result = invoke()
                value["exit"] = result if isinstance(result, int) else 0
                return result
        if not maintenance and "--help" not in args.arguments:
            parser.error("execution requires --task or an adopted checkout task policy")
        return invoke()
    finally:
        sys.argv = previous
