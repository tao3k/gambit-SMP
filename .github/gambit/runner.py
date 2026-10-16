"""Actions-only upstream CI transport; never a research/admission producer."""
import argparse
from dataclasses import asdict
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import time

from gambit_smp.process_observation import capture
from gambit_smp.recipes import tree_identity
from gambit_smp.suite_primitives import selected_files, admitted_suite


ROOT = Path(__file__).resolve().parents[2]
CONFIG = Path(__file__).with_name("modules.json")
FLAGS = ("--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms")


def observe(argv, cwd, deadline, output):
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        raise TimeoutError("CI module whole budget exhausted before launch")
    result = capture(argv, cwd, remaining, dict(os.environ))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.with_suffix(".stdout").write_text(result.stdout)
    output.with_suffix(".stderr").write_text(result.stderr)
    output.with_suffix(".json").write_text(json.dumps({
        "argv": argv, "cwd": str(cwd), "processBudgetSeconds": remaining,
        **asdict(result)}, indent=2) + "\n")
    if result.exit != 0 or result.timeout or result.group_quiescent is not True:
        raise RuntimeError(f"{output.name}: exit={result.exit} timeout={result.timeout} "
                           f"quiescent={result.group_quiescent}; see Actions logs")
    return result.stdout


def inventory(runtime):
    return tree_identity(runtime)


def verify(runtime, identity, revision):
    if identity["checkout"] != revision:
        raise ValueError("artifact checkout identity differs")
    actual = inventory(runtime)
    if actual != identity["files"]:
        raise ValueError("source/generated/binary inventory drift")


def suite_command(runtime, spec):
    # Reuse the production inventory semantics; no empty/helper-only green run.
    files = selected_files(runtime / "tests/unit-tests",
                           [spec["selection"].removeprefix("unit-tests/")],
                           inventory="stress" if spec["stress"] else "unit")
    if not files:
        raise ValueError("empty official suite inventory")
    command = [str(runtime / "gsi/gsi"),
               f"-:p2,~~bin={runtime}/bin,~~lib={runtime}/lib,~~include={runtime}/include",
               "-f", "run-unit-tests.scm"]
    if spec["stress"]:
        command.append("-stress")
    return [*command, "-gsi", "-gsc", spec["selection"]], files


def main():
    specs = json.loads(CONFIG.read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("module", choices=["build", *specs])
    args = parser.parse_args()
    if os.environ.get("GITHUB_ACTIONS") != "true":
        parser.error("requires an isolated Actions runner; never build in Working")
    runtime = ROOT / "vendor/gambit"
    logs = ROOT / ".ci/gambit-logs"
    logs.mkdir(parents=True, exist_ok=True)
    identity_path = logs / "identity.json"
    revision = os.environ["GITHUB_SHA"]
    cap = 15 if args.module == "patch-contracts" else 600 if args.module == "build" else 300
    deadline = time.monotonic() + cap

    if args.module == "patch-contracts":
        observe([sys.executable, "-m", "unittest", *specs[args.module]["modules"]],
                ROOT, deadline, logs / args.module)
        return

    if args.module == "build":
        git = lambda argv: subprocess.check_output(["git", *argv], cwd=ROOT, text=True).strip()
        pinned = git(["rev-parse", "HEAD:vendor/gambit"])
        if git(["-C", str(runtime), "rev-parse", "HEAD"]) != pinned:
            raise ValueError("Gambit gitlink mismatch")
        if git(["-C", str(runtime), "status", "--porcelain", "--untracked-files=no"]):
            raise ValueError("modified vendor source")
        compiler = observe(["gcc", "--version"], ROOT, deadline, logs / "compiler")
        observe(["./configure", "CC=gcc", *FLAGS, "--enable-c-opt=-O3",
                 "--enable-c-opt-rts=-O3"], runtime, deadline, logs / "configure")
        observe(["make", f"-j{os.cpu_count() or 1}", "core"], runtime, deadline, logs / "build")
        macros = observe(["gcc", "-dM", "-E", "-x", "c", "-I", str(runtime / "include"),
                          "-include", "gambit.h", "/dev/null"], ROOT, deadline, logs / "macros")
        for flag in ("___MULTIPLE_VMS", "___MULTIPLE_THREADED_VMS"):
            if not any(line.startswith(f"#define {flag} ") or line == f"#define {flag}"
                       for line in macros.splitlines()):
                raise ValueError(f"effective configuration omits {flag}")
        if "define-cond-expand-feature|enable-smp|" not in (runtime / "lib/makefile").read_text():
            raise ValueError("effective Scheme prelude omits SMP")
        identity_path.write_text(json.dumps({"checkout": revision, "vendorRevision": pinned,
            "compiler": compiler, "flags": FLAGS, "files": inventory(runtime)}, indent=2) + "\n")
        with tarfile.open(ROOT / ".ci/gambit-runtime.tar", "w") as archive:
            archive.add(runtime, arcname="vendor/gambit")
            archive.add(logs, arcname=".ci/gambit-logs")
        return

    identity = json.loads(identity_path.read_text())
    verify(runtime, identity, revision)
    spec = specs[args.module]
    if spec["kind"] == "make":
        command, files = ["make", *spec["targets"]], None
    else:
        command, files = suite_command(runtime, spec)
    output = observe(command, runtime / "tests", deadline, logs / args.module)
    if files is not None:
        (logs / f"{args.module}.inventory.json").write_text(json.dumps([str(p) for p in files]) + "\n")
        # Upstream counts files once, even when each file runs in two modes.
        if not admitted_suite(0, output, False, len(files)):
            raise ValueError("official suite did not complete the exact declared inventory")


if __name__ == "__main__":
    main()
