"""Standalone current-checkpoint correctness observer.

One mode per process: gsi, gsc, or gerbil. This does not seal acceptance,
admit a release, repeat Gambit bootstrap, or rewrite the retained DENY
preflight. The auditor launches it; the editor does not run native builds.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import time

from gambit_smp.framework import ROOT, digest, execute
from gambit_smp.suite_primitives import (
    admitted_suite,
    check_runtime,
    runtime_view,
    selected_files,
    runner_option,
)

RUNTIME = ROOT / ".cache/processor-interrupt-collective-wait/runtime-retirement-native-01/candidate-runtime"
SUITE_IDENTITY = RUNTIME.parent / "suite-identity.json"
ACCEPTED_RECEIPT = ROOT / "evidence/source-results/runtime-retirement/receipt.json"
ENV_RECEIPT = ROOT / ".cache/current-checkpoint-environment-01/receipt.json"
ENV_PROBE = ROOT / ".cache/current-checkpoint-environment-01/probe.log"
OLD_PREFLIGHT = ROOT / ".cache/processor-interrupt-collective-wait/runtime-retirement-full-gsi-02/retry-preflight.json"
GERBIL_SOURCE = (ROOT / "../gerbil-gambit-bootstrap-audit").resolve()
GERBIL_HEAD = "1cfb032c7a1612637da6205f5f8a15683eba3ba0"
WALL_SECONDS = 1800
STAGE_SECONDS = 1800
EXPECTED_UNIT_FILES = 374
GCC16_PATH = "/opt/homebrew/opt/gcc@16/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"


def call_execute(argv, cwd, budget, env):
    """framework.execute yields code, log, timeout, seconds and a metadata dict."""
    meta = {}
    result = execute(argv, cwd, budget, env, meta)
    if isinstance(result, dict):
        meta.update(result)
        return result["code"], result["log"], result["timeout"], result["seconds"], meta
    if len(result) == 5 and isinstance(result[4], dict):
        code, log, timeout, seconds, extra = result
        meta.update(extra)
        return code, log, timeout, seconds, meta
    code, log, timeout, seconds = result
    return code, log, timeout, seconds, meta


def file_budget(mode, relative):
    name = relative.name
    if mode == "gsi" and ("prim_port" in name or "prim-port" in name):
        return 20
    if mode == "gsc" and name == "_num.scm":
        return 90
    return 300


def json_ready(value):
    if isinstance(value, dict):
        return {str(key): json_ready(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [json_ready(item) for item in value]
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    return str(value)


def load_identity():
    accepted = json.loads(ACCEPTED_RECEIPT.read_text())
    if accepted.get("status") != "PASS":
        raise ValueError("successful exact incremental acceptance receipt required")
    identity = accepted["candidateIdentity"]
    suite = json.loads(SUITE_IDENTITY.read_text())
    if any(suite.get(k) != v for k, v in identity.items()):
        raise ValueError("suite-identity.json does not match accepted candidateIdentity")
    check_runtime(RUNTIME, identity)
    return identity


def retained_denial():
    document = json.loads(OLD_PREFLIGHT.read_text())
    if document.get("decision") != "DENY":
        raise ValueError("old CLI native_suite retry preflight is not the retained DENY")
    return {
        "path": str(OLD_PREFLIGHT.relative_to(ROOT)),
        "status": "DENY",
        "sha256": digest(OLD_PREFLIGHT),
        "altered": False,
        "passedClaimed": False,
        "reason": "old adapter cannot associate summary/env records",
    }


def environment_binding():
    """The control file has no status field. PASS is exit 0, no timeout, quiescent."""
    document = json.loads(ENV_RECEIPT.read_text())
    if (document.get("exit") != 0 or document.get("timeout") is not False
            or not document.get("parentReaped") or not document.get("processGroupQuiescent")
            or document.get("candidateReceiptSha256") != digest(SUITE_IDENTITY)
            or document.get("logSha256") != digest(ENV_PROBE)):
        raise ValueError("exact current producer and successful environment control required")
    log = ENV_PROBE.read_text()
    if any(log.splitlines().count("ENVIRONMENT:" + op + ":PASS") != 1
           for op in ("udp-open", "process-pipe-sort", "user-info")):
        raise ValueError("all original environment operation markers required")
    return {"receipt": str(ENV_RECEIPT.relative_to(ROOT)),
            "receiptSha256": digest(ENV_RECEIPT), "probeLogSha256": digest(ENV_PROBE),
            "candidateReceiptSha256": document["candidateReceiptSha256"]}


def base_env():
    env = dict(os.environ)
    env["PATH"] = GCC16_PATH
    env["CC"] = "/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16"
    env["GERBIL_GCC"] = env["CC"]
    return env


class Campaign:
    def __init__(self, out, mode):
        self.out = out
        self.mode = mode
        self.started = time.monotonic()
        self.path = out / "receipt.json"
        if self.path.exists():
            raise ValueError("existing campaign is immutable; use a fresh output")
        else:
            self.receipt = {
                "schema": "current-checkpoint-qualification-observation.v1",
                "status": "RUNNING",
                "mode": mode,
                "sealedAcceptance": False,
                "releaseAdmitted": False,
                "runtimeAdmitted": False,
                "bootstrapRepeated": False,
                "gambitBootstrapInvoked": False,
                "oldCliGate": "DENY-RETAINED",
                "observation": "standalone-manually-audited-current-source-correctness",
                "commands": [],
            }
        self.receipt["status"] = "RUNNING"

    def save(self):
        self.receipt["seconds"] = time.monotonic() - self.started
        self.path.write_text(json.dumps(self.receipt, indent=2) + "\n")

    def remaining(self, limit):
        if self.mode == "gerbil":
            return limit
        return min(limit, WALL_SECONDS - (time.monotonic() - self.started))

    def log_path(self, name):
        path = self.out / name
        if not path.exists():
            return path
        stem = path.name
        for index in range(2, 1000):
            candidate = self.out / f"{stem}.attempt{index}"
            if not candidate.exists():
                return candidate
        raise ValueError("log name space exhausted: " + name)

    def run(self, name, argv, cwd, cap, env, *, file=None, source=None, identity_sha=None):
        budget = self.remaining(cap)
        record = {
            "stage": name,
            "file": None if file is None else str(file),
            "argv": [str(item) for item in argv],
            "cwd": str(cwd),
            "budgetSeconds": budget,
            "identitySha256": identity_sha,
            "sourceSha256": None if source is None else digest(source),
        }
        if budget <= 0:
            record.update(exit=None, timeout=True, seconds=0, log=None, logSha256=None,
                          reaped=None, quiescent=None, admitted=False,
                          error="wall cap exhausted")
            self.receipt["commands"].append(record)
            self.receipt["wallCapExhausted"] = True
            self.save()
            return record
        code, log, timeout, seconds, meta = call_execute(argv, cwd, budget, env)
        path = self.log_path(name + ".log")
        path.write_text(log)
        record.update(
            exit=code,
            timeout=bool(timeout),
            seconds=seconds,
            log=path.name,
            logSha256=digest(path),
            reaped=meta.get("parentReaped"),
            quiescent=meta.get("processGroupQuiescent"),
            metadata=json_ready(meta),
            admitted=False,
        )
        self.receipt["commands"].append(record)
        self.save()
        return record


def qualify_suite(campaign, identity):
    identity_sha = json.dumps(observed_identity(identity), sort_keys=True)
    check_runtime(RUNTIME, identity)
    campaign.receipt["identityBefore"] = json.loads(identity_sha)
    unit = RUNTIME / "tests/unit-tests"
    runner = RUNTIME / "tests/run-unit-tests.scm"
    files = selected_files(unit, ["."], inventory="unit")
    campaign.receipt["unitFileCount"] = len(files)
    campaign.receipt["exactOriginalInventory"] = len(files) == EXPECTED_UNIT_FILES
    if len(files) != EXPECTED_UNIT_FILES:
        raise ValueError(f"unit inventory is {len(files)}, required {EXPECTED_UNIT_FILES}")
    if not runner.is_file():
        raise ValueError("original run-unit-tests.scm is missing")
    mirror = campaign.out / "runtime-view"
    tests = runtime_view(RUNTIME, mirror)
    shutil.copytree(unit, tests / "unit-tests")
    shutil.copy2(runner, tests / runner.name)
    campaign.receipt["fixtureSha256"] = {str(f): digest(unit / f) for f in files}
    campaign.receipt["runnerSha256"] = digest(runner)
    campaign.receipt["testInputs"] = {str(p.relative_to(unit)): digest(p)
        for p in unit.rglob("*") if p.is_file()}
    env = base_env()
    env["GAMBOPT"] = "p2,~~lib={lib},~~bin={bin},~~include={include}".format(
        lib=RUNTIME / "lib", bin=RUNTIME / "bin", include=RUNTIME / "include")
    env.update(GAMBIT_SMP_EXPECTED_PROCESSORS="2", GAMBIT_SMP_AVAILABLE_CPUS="12")
    tool = RUNTIME / "gsi/gsi"
    for relative in files:
        source = unit / relative
        source_sha = digest(source)
        dest = tests / "unit-tests" / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.exists() or digest(dest) != source_sha:
            shutil.copy2(source, dest)
        if digest(source) != source_sha:
            raise ValueError("fixture changed while copying: " + str(relative))
        record = campaign.run(
            f"{campaign.mode}-file-{len(campaign.receipt['commands']):03}",
            [tool, "-:" + runner_option(env["GAMBOPT"]), "-f", "run-unit-tests.scm",
             "-" + campaign.mode, str(Path("unit-tests") / relative)],
            tests,
            file_budget(campaign.mode, relative),
            env,
            file=relative,
            source=source,
            identity_sha=identity_sha,
        )
        if record.get("error") == "wall cap exhausted":
            break
        log = (campaign.out / record["log"]).read_text()
        record["admitted"] = bool(admitted_suite(record["exit"], log, record["timeout"], 1)
            and record["reaped"] and record["quiescent"])
        campaign.save()
    check_runtime(RUNTIME, identity)
    campaign.receipt["inputsStable"] = (digest(runner) == campaign.receipt["runnerSha256"]
        and digest(tests / runner.name) == campaign.receipt["runnerSha256"]
        and all(digest(unit / f) == sha == digest(tests / "unit-tests" / f)
                for f, sha in campaign.receipt["testInputs"].items()))
    campaign.receipt["identityAfter"] = observed_identity(identity)
    if campaign.receipt["identityBefore"] != campaign.receipt["identityAfter"]:
        raise ValueError("runtime identity changed during the suite")


def observed_identity(identity):
    observed = {
        "binarySha256": digest(RUNTIME / "gsi/gsi"),
        "gscSha256": digest(RUNTIME / "gsc/gsc"),
        "librarySha256": digest(RUNTIME / "lib/libgambit.a"),
    }
    for field, value in observed.items():
        if value != identity[field]:
            raise ValueError("live runtime artifact does not match candidateIdentity: " + field)
    return observed


def install_runtime_assets(clone, campaign):
    """Copy the current native products the way build_gambit installs them.

    This does not run the gambit target, make bootstrap, or from-scratch.
    """
    stage0 = clone / "bootstrap"
    build = clone / "build"
    for directory in (stage0 / "bin", build / "bin", build / "lib", build / "include"):
        directory.mkdir(parents=True, exist_ok=True)
    copies = [
        (RUNTIME / "gsi/gsi", stage0 / "bin/gsi"),
        (RUNTIME / "gsi/gsi", build / "bin/gsi"),
        (RUNTIME / "gsc/gsc", build / "bin/gsc"),
        (RUNTIME / "bin/gambuild-C", build / "bin/gambuild-C"),
        (RUNTIME / "include/gambit.h", build / "include/gambit.h"),
        (RUNTIME / "lib/_define-syntax.scm", build / "lib/_define-syntax.scm"),
        (RUNTIME / "lib/_gambit.c", build / "lib/_gambit.c"),
        (RUNTIME / "lib/libgambit.a", build / "lib/libgambit.a"),
    ]
    copies.extend((path, build / "include" / path.name) for path in (RUNTIME / "include").glob("gambit-not*.h"))
    copies.extend((path, build / "lib" / path.name) for path in (RUNTIME / "lib").glob("*#.scm"))
    copies.extend((path, build / "lib" / path.name) for path in (RUNTIME / "gsc").glob("*#.scm"))
    for name in (
        "lib/libgambit.so", "lib/libgambit.dylib",
        "gsi/libgambitgsi.so", "gsi/libgambitgsi.a", "gsi/libgambitgsi.dylib",
        "gsc/libgambitgsc.so", "gsc/libgambitgsc.a", "gsc/libgambitgsc.dylib",
    ):
        source = RUNTIME / name
        if source.exists():
            copies.append((source, build / "lib" / source.name))
    manifest = []
    for source, dest in copies:
        if not source.is_file():
            raise ValueError("required current runtime asset missing: " + str(source))
        shutil.copy2(source, dest)
        manifest.append({
            "source": str(source),
            "dest": str(dest.relative_to(clone)),
            "sha256": digest(dest),
        })
        if digest(source) != digest(dest):
            raise ValueError("installed asset does not match current runtime: " + str(dest))
    campaign.receipt["installedRuntimeAssets"] = manifest
    campaign.receipt["gambitBootstrapInvoked"] = False
    campaign.save()


def gerbil_env(out):
    prefix = out / "prefix"
    gerbil_path = out / "gerbil-path"
    prefix.mkdir(parents=True, exist_ok=True)
    gerbil_path.mkdir(parents=True, exist_ok=True)
    env = base_env()
    env.update(
        GERBIL_PREFIX=str(prefix),
        GERBIL_PATH=str(gerbil_path),
        GERBIL_BUILD_CORES="6",
        GERBIL_BUILD_FLAGS="-j6",
        CC="/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16",
        GERBIL_GCC="/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16",
    )
    for name in ("GERBIL_HOME", "GERBIL_LOADPATH", "GERBIL_GSC", "GERBIL_SOURCE", "GERBIL_STAGE0", "GAMBOPT"):
        env.pop(name, None)
    return env


def qualify_gerbil(campaign):
    clone = campaign.out / "gerbil-source"
    env = gerbil_env(campaign.out)
    if not clone.exists():
        cloned = campaign.run(
            "clone-gerbil-source", ["/bin/cp", "-cR", GERBIL_SOURCE, clone], ROOT, STAGE_SECONDS, env)
        if cloned.get("exit") != 0 or cloned.get("timeout"):
            raise ValueError("Gerbil source clone failed")
    head = campaign.run("git-head", ["/usr/bin/git", "-C", clone, "rev-parse", "HEAD"], clone, 30, env)
    if head.get("exit") != 0:
        raise ValueError("cloned Gerbil HEAD could not be read")
    observed = (campaign.out / head["log"]).read_text().strip()
    campaign.receipt["gerbilHead"] = observed
    if observed != GERBIL_HEAD:
        raise ValueError("cloned Gerbil HEAD is not " + GERBIL_HEAD)
    src = clone / "src"
    source_inputs = {str(p.relative_to(GERBIL_SOURCE)): digest(p) for folder in
        ("src/gerbil", "src/std", "src/lang", "src/tools", "src/build")
        for p in (GERBIL_SOURCE / folder).rglob("*")
        if p.is_file() and p.suffix in {".ss", ".scm", ".sh", ".c", ".h"}}
    for name in ("src/build.sh", "build.sh", "build-env.sh"):
        source_inputs[name] = digest(GERBIL_SOURCE / name)
    if any(digest(clone / p) != sha for p, sha in source_inputs.items()):
        raise ValueError("cloned Gerbil source differs from original")
    campaign.receipt["gerbilSourceInputs"] = source_inputs
    campaign.save()
    prepare = campaign.run("prepare", ["./build.sh", "prepare"], src, STAGE_SECONDS, env)
    if prepare.get("exit") != 0 or prepare.get("timeout"):
        raise ValueError("prepare failed; bootstrap and build were only the copied tree")
    install_runtime_assets(clone, campaign)
    check_runtime(RUNTIME, load_identity())
    for stage in ("boot-gxi", "stage0", "stage1", "stdlib", "libgerbil", "lang", "tools"):
        record = campaign.run(stage, ["./build.sh", stage], src, STAGE_SECONDS, env)
        if record.get("exit") != 0 or record.get("timeout") or record.get("error"):
            campaign.receipt["gerbilStoppedAt"] = stage
            return
    campaign.run("gxtest", ["./build.sh", "env", "gxtest", "./..."], src, STAGE_SECONDS, env)
    check_runtime(RUNTIME, load_identity())
    campaign.receipt["originalGerbilSourceUnchanged"] = all(
        digest(GERBIL_SOURCE / p) == sha for p, sha in source_inputs.items())
    if not campaign.receipt["originalGerbilSourceUnchanged"]:
        raise ValueError("original Gerbil source changed during observation")


def finish(campaign, identity):
    files = [row for row in campaign.receipt["commands"] if row.get("file") is not None]
    if campaign.mode in {"gsi", "gsc"}:
        ran = {row["file"] for row in files if row.get("log")}
        campaign.receipt["filesRan"] = len(ran)
        campaign.receipt["failedFiles"] = sorted(
            row["file"] for row in files if row.get("admitted") is not True)
        complete = len(ran) == EXPECTED_UNIT_FILES and not campaign.receipt.get("wallCapExhausted")
        campaign.receipt["status"] = ("COVERAGE-PASS" if complete and not campaign.receipt["failedFiles"]
            and campaign.receipt.get("inputsStable") else "DENY")
    else:
        stages = [row["stage"] for row in campaign.receipt["commands"]]
        test = next((row for row in campaign.receipt["commands"] if row["stage"] == "gxtest"), None)
        ok = (test is not None and test.get("exit") == 0 and not test.get("timeout")
              and "gerbilStoppedAt" not in campaign.receipt
              and all(r.get("exit") == 0 and not r.get("timeout") and r.get("reaped")
                      and r.get("quiescent") for r in campaign.receipt["commands"]))
        campaign.receipt["status"] = "BUILD-TEST-PASS" if ok else "DENY"
        campaign.receipt["stagesObserved"] = stages
    campaign.receipt["sealedAcceptance"] = False
    campaign.receipt["releaseAdmitted"] = False
    campaign.receipt["runtimeAdmitted"] = False
    campaign.receipt["bootstrapRepeated"] = False
    if campaign.mode in {"gsi", "gsc"}:
        check_runtime(RUNTIME, identity)
    campaign.save()


def main():
    global RUNTIME, SUITE_IDENTITY, ACCEPTED_RECEIPT, ENV_RECEIPT, ENV_PROBE
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", type=Path, default=RUNTIME)
    parser.add_argument("--identity", type=Path, default=SUITE_IDENTITY)
    parser.add_argument("--acceptance-receipt", type=Path, default=ACCEPTED_RECEIPT)
    parser.add_argument("--environment-receipt", type=Path, default=ENV_RECEIPT)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--mode", choices=("gsi", "gsc", "gerbil"), required=True)
    args = parser.parse_args()
    RUNTIME = args.runtime.resolve()
    SUITE_IDENTITY = args.identity.resolve()
    ACCEPTED_RECEIPT = args.acceptance_receipt.resolve()
    ENV_RECEIPT = args.environment_receipt.resolve()
    ENV_PROBE = ENV_RECEIPT.parent / "probe.log"
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    identity = load_identity()
    campaign = Campaign(out, args.mode)
    campaign.receipt["runtime"] = str(RUNTIME.relative_to(ROOT))
    campaign.receipt["candidateIdentity"] = {
        field: identity[field] for field in ("binarySha256", "gscSha256", "librarySha256")}
    campaign.receipt["suiteIdentity"] = str(SUITE_IDENTITY.relative_to(ROOT))
    campaign.receipt["acceptedReceiptSha256"] = digest(ACCEPTED_RECEIPT)
    campaign.receipt["environment"] = environment_binding()
    campaign.receipt["oldCliNativeSuiteRetry"] = retained_denial()
    campaign.receipt["bootstrapRepeated"] = False
    campaign.save()
    try:
        if args.mode == "gerbil":
            qualify_gerbil(campaign)
        else:
            qualify_suite(campaign, identity)
    except BaseException as error:
        campaign.receipt["status"] = "FAIL"
        campaign.receipt["error"] = str(error)
        campaign.receipt["sealedAcceptance"] = False
        campaign.receipt["releaseAdmitted"] = False
        raise
    finally:
        try:
            if args.mode != "gerbil":
                check_runtime(RUNTIME, identity)
                campaign.receipt["originalCheckpointUnchanged"] = True
        finally:
            if campaign.receipt.get("status") == "RUNNING":
                finish(campaign, identity)
            else:
                campaign.save()
    print(json.dumps({
        "status": campaign.receipt["status"],
        "sealedAcceptance": False,
        "releaseAdmitted": False,
        "receipt": str(campaign.path),
    }))
    return 0 if campaign.receipt["status"] in {"COVERAGE-PASS", "BUILD-TEST-PASS"} else 1


LIFECYCLE_RUNS = (
    ".cache/tasks/repair-9-12/lifecycle-join-recovery-1",
    ".cache/tasks/repair-9-12/lifecycle-join-recovery-2",
)
LIFECYCLE_STDOUT = "LIFECYCLE-JOIN:STILL-JOINABLE-THEN-SUCCESS\n"
MILESTONE_PATH = Path("docs/smp-threaded-vm-milestone.md")
REVIEW_PATH = Path("evidence/research/processor-interrupt-collective-wait/current-checkpoint-qualification-review.md")
# Darwin EINVAL. A detached join returns this and the thread is no longer joinable.
_EINVAL = 22


def os_join_error_then_success(text):
    """True only when the captured transcript records an OS join errno, then 0.

    The errno has to be the value ___thread_join got from pthread_join while the
    worker was still joinable. A success banner with no errno, or EINVAL, is not
    that sequence.
    """
    import re
    # The pre-join witness path prints only this banner. It is not an OS join error.
    if text == LIFECYCLE_STDOUT or text.strip() == LIFECYCLE_STDOUT.strip():
        return False
    match = re.fullmatch(
        r"LIFECYCLE-JOIN:OS-JOIN-ERROR ([1-9][0-9]*)\n"
        r"LIFECYCLE-JOIN:SAME-OWNER-JOIN 0\n"
        r"LIFECYCLE-JOIN:STILL-JOINABLE-THEN-SUCCESS\n",
        text,
    )
    if match is None:
        return False
    return int(match.group(1)) != _EINVAL


def pre_join_flag_before_join(root, relative):
    """True when this receipt's setup.c stores ___LW_REFUSED before ___thread_join.

    That store is not a still-joinable OS join error. A later banner, or even a
    three-line transcript pasted onto the same tree, does not make the run a
    same-owner recovery.
    """
    setup = Path(root) / relative / "run/core/source/lib/setup.c"
    if not setup.is_file():
        return False
    text = setup.read_text(errors="replace")
    flag = text.find("___vms->lifecycle_witness |= ___LW_REFUSED")
    if flag == -1:
        return False
    join = text.find("___thread_join", flag)
    return join != -1 and flag < join


def os_join_errno_recorded(root, relative):
    """True when setup.c stores errno from ___thread_join, then joins again.

    The banner string and a ___LW_REFUSED store before pthread_join do not
    record that sequence.
    """
    if pre_join_flag_before_join(root, relative):
        return False
    setup = Path(root) / relative / "run/core/source/lib/setup.c"
    if not setup.is_file():
        return False
    text = setup.read_text(errors="replace")
    first = text.find("___thread_join")
    if first == -1:
        return False
    errno = text.find("___ERRNO_FROM_ERR_CODE", first)
    if errno == -1:
        return False
    second = text.find("___thread_join", errno)
    return first < errno < second


def _lifecycle_run_ok(root, relative):
    if pre_join_flag_before_join(root, relative):
        return False
    if not os_join_errno_recorded(root, relative):
        return False
    run = root / relative
    receipt_path = run / "receipt.json"
    stdout_path = run / "run/join-probe/run-executable.stdout"
    process_path = run / "run/join-probe/run-executable.process.json"
    observation_path = run / "run/join-probe.observation.json"
    if not (receipt_path.is_file() and stdout_path.is_file() and process_path.is_file() and observation_path.is_file()):
        return False
    receipt = json.loads(receipt_path.read_text())
    process = json.loads(process_path.read_text())
    observation = json.loads(observation_path.read_text())
    expected = process.get("environment", {}).get("GAMBIT_SMP_EXPECTED_PROCESSORS")
    try:
        processors = int(expected)
    except (TypeError, ValueError):
        return False
    arguments = observation.get("step", {}).get("arguments", {})
    stdout = stdout_path.read_text()
    return (receipt.get("outcome") == "PASS" and receipt.get("exit") == 0
            and receipt.get("timeout") is False and receipt.get("childOutcome") == "PASS"
            and os_join_error_then_success(stdout)
            and arguments.get("stdout") == stdout
            and process.get("exit") == 0 and process.get("timeout") is False
            and arguments.get("processorTopology") == "host-managed"
            and processors > 1)


def qualify_nine_of_twelve(root):
    """Admit 9/12 only from two lifecycle campaign receipts and the milestone text.

    A model flag, one native pass, a one-processor shrink, or a bare digit edit
    stays at the historical count. runtimeAdmitted is not the counter.
    """
    root = Path(root)
    for relative in LIFECYCLE_RUNS:
        if pre_join_flag_before_join(root, relative):
            return {"admitted": False, "count": "8/12", "closed": None, "runsOk": False}
        stdout_path = root / relative / "run/join-probe/run-executable.stdout"
        if stdout_path.is_file():
            text = stdout_path.read_text()
            if text == LIFECYCLE_STDOUT or not os_join_error_then_success(text):
                return {"admitted": False, "count": "8/12", "closed": None, "runsOk": False}
    milestone = (root / MILESTONE_PATH).read_text()
    review = (root / REVIEW_PATH).read_text()
    runs_ok = all(_lifecycle_run_ok(root, relative) for relative in LIFECYCLE_RUNS)
    history = ("Cumulative completion is **8/12**" in milestone and "6/12" in milestone
               and "remains 8/12" in review)
    current = ("Cumulative completion is **9/12**" in milestone
               and "Cumulative completion is **9/12**" in review
               and "lifecycle failure/rollback gate is closed" in milestone
               and "lifecycle failure/rollback gate is closed" in review)
    others_open = ("Complete GC/FFI, Gerbil correctness, and release performance remain open." in milestone
                   and "Complete GC/FFI, Gerbil correctness, and release performance remain open." in review
                   and "Numerical compiled case within its contract" in review
                   and "Source-causal crash repair" in review
                   and "Matched accepted full producer" in review
                   and "GC/FFI gate is closed" not in milestone
                   and "Gerbil correctness gate is closed" not in milestone
                   and "release performance gate is closed" not in milestone)
    admitted = bool(runs_ok and history and current and others_open)
    return {"admitted": admitted, "count": "9/12" if admitted else "8/12",
            "closed": "lifecycle" if admitted else None,
            "runsOk": runs_ok}


if __name__ == "__main__":
    raise SystemExit(main())
