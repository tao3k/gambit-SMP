"""One installed entry point for model, source, native, and evidence adapters."""
import argparse
from importlib import import_module
import os
from pathlib import Path
import sys


COMMANDS = {
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


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, epilog=
        "trajectory clues: caller-authored Scheme/Datalog queries over registered Evidence; "
        "source-bound, expandable incremental slices. Python API: "
        "gambit_smp.repository_clues and gambit_smp.engine_api. "
        "Reads do not select or authorize actions.")
    parser.add_argument("--root", type=Path, help="research checkout containing models and evidence")
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
    previous = sys.argv
    try:
        sys.argv = ["gambit-smp " + args.command, *args.arguments]
        return adapter.main()
    finally:
        sys.argv = previous
