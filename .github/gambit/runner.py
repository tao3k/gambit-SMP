"""Actions-only upstream CI transport; never a research/admission producer."""
import argparse
from dataclasses import asdict
import json
import os
from pathlib import Path
import subprocess
import shutil
import sys
import tarfile
import time

from gambit_smp.process_observation import capture
from gambit_smp.recipes import tree_identity
from gambit_smp.suite_primitives import selected_files
from gambit_smp.native_capabilities import run_suite_groups
from gambit_smp.framework import digest
from gambit_smp.source_materialize import materialize
from gambit_smp.gambit_build_primitives import build_seed_core


ROOT = Path(__file__).resolve().parents[2]
CONFIG = Path(__file__).with_name("modules.json")
LOCK = Path(__file__).with_name("source.lock.json")
FLAGS = ("--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms")


def record(argv, cwd, deadline, output, *, environment=None):
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        raise TimeoutError("CI module whole budget exhausted before launch")
    environment = dict(os.environ) if environment is None else environment
    result = capture(argv, cwd, remaining, environment)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.with_suffix(".stdout").write_text(result.stdout)
    output.with_suffix(".stderr").write_text(result.stderr)
    output.with_suffix(".json").write_text(json.dumps({
        "argv": argv, "cwd": str(cwd), "processBudgetSeconds": remaining,
        "runtimeOptions": environment.get("GAMBOPT"),
        **asdict(result)}, indent=2) + "\n")
    return result


def observe(argv, cwd, deadline, output, *, environment=None):
    result = record(argv, cwd, deadline, output, environment=environment)
    if result.exit != 0 or result.timeout or result.group_quiescent is not True:
        raise RuntimeError(f"{output.name}: exit={result.exit} timeout={result.timeout} "
                           f"quiescent={result.group_quiescent}; see Actions logs")
    return result.stdout


def inventory(runtime):
    return tree_identity(runtime)


def verify(runtime, identity, revision):
    if identity["checkout"] != revision:
        raise ValueError("artifact checkout identity differs")
    if identity["sourceLockSha256"] != digest(LOCK):
        raise ValueError("artifact source lock differs")
    actual = inventory(runtime)
    if actual != identity["files"]:
        raise ValueError("source/generated/binary inventory drift")


class BuildStages:
    """Adapt the existing build primitive to the existing process transport."""
    def __init__(self, deadline, logs, *, directory=None, environment=None):
        self.deadline, self.logs, self.directory = deadline, logs, directory
        self.environment = environment

    def run(self, name, argv, cwd, cap):
        result = record([str(arg) for arg in argv], cwd,
                        min(self.deadline, time.monotonic() + cap), self.logs / name,
                        environment=self.environment)
        if result.group_quiescent is not True:
            raise RuntimeError("owned process group was not reaped")
        return result.exit, result.stdout + result.stderr, result.timeout, result.seconds


def run_modes(runtime, spec, deadline, logs, workspace, environment):
    modes = spec["modes"]
    if not modes or len(modes) != len(set(modes)) or any(mode not in {"gsi", "gsc"} for mode in modes):
        raise ValueError("nonempty unique official suite modes required")
    logs.mkdir(parents=True, exist_ok=True)
    files = selected_files(runtime / "tests/unit-tests",
                           [spec["selection"].removeprefix("unit-tests/")],
                           inventory="stress" if spec["stress"] else "unit")
    outcomes = []
    for index, mode in enumerate(modes):
        if time.monotonic() >= deadline:
            outcomes.append({"mode": mode, "started": False, "reason": "whole-budget-exhausted"})
            continue
        directory, mode_logs = workspace / mode, logs / mode
        directory.mkdir(parents=True)
        mode_logs.mkdir(parents=True)
        context = BuildStages(deadline, mode_logs, directory=directory, environment=environment)
        arguments = {"mode": mode, "regime": "whole-parallel",
                     "inventory": "stress" if spec["stress"] else "unit"}
        option = f"p2,~~bin={runtime}/bin,~~lib={runtime}/lib,~~include={runtime}/include"
        try:
            rows = run_suite_groups(context, runtime, runtime / "tests", arguments, files, 1, option)
            outcomes.append({"mode": mode, "started": True, "rows": rows})
        except Exception as error:
            outcomes.append({"mode": mode, "started": None, "error": str(error)})
            outcomes.extend({"mode": later, "started": False, "reason": "preceding-mode-exception"}
                            for later in modes[index + 1:])
            (logs / "modes.json").write_text(json.dumps(outcomes, indent=2) + "\n")
            raise
        finally:
            for name in ("suite-plan.json", "suite-progress.json"):
                if (directory / name).exists():
                    shutil.copy2(directory / name, mode_logs / name)
    (logs / "modes.json").write_text(json.dumps(outcomes, indent=2) + "\n")
    if not all(row["started"] and row["rows"] and all(item["accepted"] for item in row["rows"])
               for row in outcomes):
        raise RuntimeError("official suite modes did not all complete within the shared budget")


def main():
    specs = json.loads(CONFIG.read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("module", choices=["build", *specs])
    args = parser.parse_args()
    if os.environ.get("GITHUB_ACTIONS") != "true":
        parser.error("requires an isolated Actions runner; never build in Working")
    runtime = ROOT / ".ci/gambit"
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

    if args.module in specs and "blocker" in specs[args.module]:
        # Explicit CI hold, not a waiver or inference/admission decision.
        # No native process is launched, and this job remains a hard failure.
        (logs / (args.module + ".blocked.json")).write_text(json.dumps({
            "status": "BLOCKED_UNFIXED_NATIVE_FAILURE", "nativeProcessLaunched": False,
            "checkout": revision, "sourceLockSha256": digest(LOCK),
            "blocker": specs[args.module]["blocker"]}, indent=2) + "\n")
        raise RuntimeError("unfixed native failure: " + specs[args.module]["blocker"]["reason"])

    if args.module == "build":
        git = lambda argv: subprocess.check_output(["git", *argv], cwd=ROOT, text=True).strip()
        pinned = git(["rev-parse", "HEAD:vendor/gambit"])
        vendor = ROOT / "vendor/gambit"
        if git(["-C", str(vendor), "rev-parse", "HEAD"]) != pinned:
            raise ValueError("Gambit gitlink mismatch")
        if git(["-C", str(vendor), "status", "--porcelain", "--untracked-files=no"]):
            raise ValueError("modified vendor source")
        # The same materializer validates the exact base, overlay and candidate bytes.
        # Vendor/Working remain untouched. Real Git metadata is needed by the
        # official bootstrap; do not silently replace it with dummy gsc-boot.
        source = materialize(LOCK, runtime, root=ROOT)
        observe(["git", "clone", "--bare", "--no-hardlinks", str(vendor), str(runtime / ".git")],
                ROOT, deadline, logs / "build-git-metadata")
        observe(["git", "-C", str(runtime), "config", "core.bare", "false"],
                ROOT, deadline, logs / "build-git-worktree")
        observe(["git", "-C", str(runtime), "read-tree", pinned],
                ROOT, deadline, logs / "build-git-index")
        (logs / "materialization.json").write_text(json.dumps(source, indent=2) + "\n")
        compiler = observe(["gcc", "--version"], ROOT, deadline, logs / "compiler")
        observe(["aclocal"], runtime, deadline, logs / "aclocal")
        observe(["autoconf"], runtime, deadline, logs / "autoconf")
        observe(["./configure", "CC=gcc", *FLAGS, "--enable-c-opt=-O3",
                 "--enable-c-opt-rts=-O3"], runtime, deadline, logs / "configure")
        ok, build = build_seed_core(BuildStages(deadline, logs), runtime, deadline - time.monotonic())
        (logs / "build-observation.json").write_text(json.dumps(build, indent=2) + "\n")
        if not ok:
            raise RuntimeError("three-flag patched CI core failed; see seed-core observation")
        macros = observe(["gcc", "-dM", "-E", "-x", "c", "-I", str(runtime / "include"),
                          "-include", "gambit.h", "/dev/null"], ROOT, deadline, logs / "macros")
        for flag in ("___MULTIPLE_VMS", "___MULTIPLE_THREADED_VMS"):
            if not any(line.startswith(f"#define {flag} ") or line == f"#define {flag}"
                       for line in macros.splitlines()):
                raise ValueError(f"effective configuration omits {flag}")
        if "define-cond-expand-feature|enable-smp|" not in (runtime / "lib/makefile").read_text():
            raise ValueError("effective Scheme prelude omits SMP")
        # Only disposable CI metadata is removed, after bootstrap. No active tree.
        shutil.rmtree(runtime / ".git")
        identity_path.write_text(json.dumps({"checkout": revision, "vendorRevision": pinned,
            "sourceLockSha256": digest(LOCK), "patchSha256": json.loads(LOCK.read_text())["patchSha256"],
            "scope": "patched-upstream-ci-core-not-current-repair-candidate",
            "compiler": compiler, "flags": FLAGS, "files": inventory(runtime)}, indent=2) + "\n")
        with tarfile.open(ROOT / ".ci/gambit-runtime.tar", "w") as archive:
            archive.add(runtime, arcname=".ci/gambit")
            archive.add(logs, arcname=".ci/gambit-logs")
        return

    identity = json.loads(identity_path.read_text())
    verify(runtime, identity, revision)
    spec = specs[args.module]
    environment = dict(os.environ)
    if spec["kind"] == "make":
        observe(["make", *spec["targets"]], runtime / "tests", deadline, logs / args.module)
    else:
        # Official runner children do not inherit the parent's -:p2 argument.
        # Documented GAMBOPT carries it to both gsi and gsc subprocesses.
        environment["GAMBOPT"] = "p2"
        run_modes(runtime, spec, deadline, logs / args.module,
                  ROOT / ".ci/suites" / args.module, environment)


if __name__ == "__main__":
    main()
