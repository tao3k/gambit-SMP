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
from gambit_smp.suite_primitives import selected_files, admitted_suite
from gambit_smp.framework import digest
from gambit_smp.source_materialize import materialize
from gambit_smp.gambit_build_primitives import build_seed_core


ROOT = Path(__file__).resolve().parents[2]
CONFIG = Path(__file__).with_name("modules.json")
LOCK = Path(__file__).with_name("source.lock.json")
FLAGS = ("--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms")


def record(argv, cwd, deadline, output):
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
    return result


def observe(argv, cwd, deadline, output):
    result = record(argv, cwd, deadline, output)
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
    def __init__(self, deadline, logs):
        self.deadline, self.logs = deadline, logs

    def run(self, name, argv, cwd, cap):
        result = record(argv, cwd, min(self.deadline, time.monotonic() + cap), self.logs / name)
        if result.group_quiescent is not True:
            raise RuntimeError("build process group was not reaped")
        return result.exit, result.stdout + result.stderr, result.timeout, result.seconds


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
