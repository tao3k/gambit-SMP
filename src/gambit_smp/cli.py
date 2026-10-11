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
    "suite": "native_suite",
    "bootstrap": "bootstrap_runtime",
    "compiler-cost": "compiler_cost",
    "identity": "runtime_identity",
    "evidence": "evidence_index",
    "audit": "research_audit",
    "publish-protocol": "protocol_evidence",
    "publish-progress": "progress_evidence",
    "papers": "paper_cache",
    "upstream-audit": "upstream_audit",
    "upstream-snapshot": "upstream_snapshot",
    "debug": "debug_runtime",
    "crash": "crash_evidence",
}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, help="research checkout containing models and evidence")
    parser.add_argument("command", choices=COMMANDS)
    parser.add_argument("arguments", nargs=argparse.REMAINDER,
                        help="adapter options; use COMMAND --help")
    args = parser.parse_args(argv)
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
