#!/usr/bin/env python3
"""Isolated upstream-suite adapter using the common bounded execution framework."""
import argparse
import json
from pathlib import Path
import shutil
import time
from math import isqrt

from gambit_smp.framework import available_processors, digest, execute, gnu_compiler, positive_int, parallel_jobs, apply_untracked_patch, gnu_build_driver
from gambit_smp.runtime_identity import check


def selected_files(root, selections):
    root = root.resolve()
    files = set()
    for selection in selections:
        relative = Path(selection)
        path = (root / relative).resolve()
        if relative.is_absolute() or not path.is_relative_to(root.resolve()) or not path.exists():
            raise ValueError("suite selection must exist inside upstream unit-tests")
        candidates = path.rglob("*.scm") if path.is_dir() else (path,)
        files.update(p.relative_to(root) for p in candidates
                     if p.suffix == ".scm" and p.name != "#.scm" and not p.name.endswith("_stress.scm"))
    if not files:
        raise ValueError("empty suite selection")
    return sorted(files)


def runtime_view(runtime, mirror):
    mirror.mkdir(parents=True)
    for name in ("gsi", "gsc", "lib", "include", "bin"):
        (mirror / name).symlink_to(runtime / name, target_is_directory=True)
    tests = mirror / "tests"
    tests.mkdir()
    return tests


def admitted_suite(code, output, timed_out, expected):
    marker = f"PASSED ALL {expected} UNIT TESTS"
    return code == 0 and not timed_out and output.splitlines().count(marker) == 1 and "*** FAILED" not in output


from gambit_smp.suite_primitives import campaign_status


def admitted_processors(code, output, timed_out, requested):
    return code == 0 and not timed_out and output.strip() == f"PROCESSORS:{requested}"


def extra_fixture(source, destination, unit):
    relative = Path(destination)
    target = unit / relative
    if relative.is_absolute() or not target.resolve().is_relative_to(unit.resolve()) or target.exists():
        raise ValueError("extra fixture must be a new path inside the isolated unit-tests")
    if source.suffix != ".scm" or relative.suffix != ".scm":
        raise ValueError("extra fixture requires Scheme source")
    expected = digest(source)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    if digest(source) != expected or digest(target) != expected:
        raise ValueError("extra fixture changed during snapshot")
    return expected


def fixture_patch(data, mirror, sources, allowed):
    allowed = {name for name in allowed if name.startswith("tests/unit-tests/")
               and Path(name).name != "#.scm" and Path(name).suffix == ".scm" and name[6:] in sources}
    return {name[6:]: sha for name, sha in apply_untracked_patch(mirror, data, allowed).items()}


def partitions(files, jobs):
    if jobs <= 0 or len(files) != len(set(files)):
        raise ValueError("positive capacity and unique test files required")
    return [files[index::jobs] for index in range(min(jobs, len(files)))]


def capacity(cpu, files, parallel, processors=None, jobs=None):
    if cpu <= 0 or files <= 0:
        raise ValueError("positive host capacity and file count required")
    budget = max(2, cpu)
    if not parallel:
        population = processors or budget - 1
        if population + 1 > budget:
            raise ValueError("runner and child VM populations exceed available CPU budget")
        return population, 1
    workers = min(files, jobs or (max(1, budget // (processors + 1)) if processors else isqrt(cpu)))
    population = processors or max(1, budget // workers - 1)
    if workers * (population + 1) > budget:
        raise ValueError("parallel VM populations exceed available CPU budget")
    return population, workers


def runner_option(option):
    return ",".join("p1" if part.startswith("p") and part[1:].isdigit() else part
                    for part in option.split(","))


def parallel_suite(runtime, copied, out, mode, files, jobs, timeout, environment,
                   option, sources, patched, extras):
    groups = partitions(files, jobs)

    def worker(item, deadline):
        index, group = item
        work = runtime_view(runtime, out / "shards" / mode / str(index))
        shutil.copytree(copied / "unit-tests", work / "unit-tests")
        shutil.copyfile(copied / "run-unit-tests.scm", work / "run-unit-tests.scm")
        remaining = deadline - time.monotonic()
        metadata = {}
        if remaining > 0:
            code, output, timed_out, seconds = execute(
                [str(runtime / "gsi/gsi"), "-:" + runner_option(option), "-f", "run-unit-tests.scm", "-" + mode]
                + [str(Path("unit-tests") / p) for p in group], work, remaining,
                env=environment, metadata=metadata)
        else:
            code, output, timed_out, seconds = -9, "whole budget exhausted before shard launch\n", True, 0
        (out / f"{mode}-{index}.log").write_text(output)
        stable = all((work / name).is_file() and digest(work / name) == patched.get(name, sha)
                     for name, sha in sources.items())
        stable = stable and all(digest(work / "unit-tests" / name) == patched.get("unit-tests/" + name, row["sha256"])
                                for name, row in extras.items())
        accepted = admitted_suite(code, output, timed_out, len(group)) and stable
        print(f"{mode} shard {index}: {'PASS' if accepted else 'DENY'}; {len(group)} files", flush=True)
        return dict(shard=index, files=[str(p) for p in group], exit=code,
                    timeout=timed_out, seconds=round(seconds, 3), accepted=accepted,
                    sourceStable=stable, process=metadata)

    start = time.monotonic()
    rows = parallel_jobs(list(enumerate(groups)), worker, jobs, timeout)
    seconds = time.monotonic() - start
    complete = sorted(p for row in rows for p in row["files"]) == sorted(str(p) for p in files)
    accepted = complete and all(row["accepted"] for row in rows) and seconds <= timeout
    code = 0 if accepted else next((row["exit"] for row in rows if not row["accepted"]), -9)
    output = "".join((out / f"{mode}-{row['shard']}.log").read_text() for row in rows)
    return code, output, any(row["timeout"] for row in rows) or seconds > timeout, seconds, rows


def atomic_suite(runtime, copied, out, mode, files, jobs, timeout, environment,
                 option, sources, patched, extras, inputs_stable, checkpoint):
    # One file per worker gives each independently verified case the same
    # bounded budget. This is coverage, never a new whole-mode deadline.
    if jobs <= 0 or len(files) != len(set(files)):
        raise ValueError("positive capacity and unique test files required")
    groups = [files[index:index + jobs] for index in range(0, len(files), jobs)]
    rows, outputs = [], []
    start = time.monotonic()
    for index, group in enumerate(groups):
        if not inputs_stable():
            code, output, timed_out, seconds, shards = -1, "input drift before batch\n", False, 0, []
        else:
            code, output, timed_out, seconds, shards = parallel_suite(
                runtime, copied, out / "batches" / mode / str(index), mode,
                group, jobs, timeout, environment, option, sources, patched, extras)
        accepted = (code == 0 and not timed_out and seconds <= timeout and
                    inputs_stable() and bool(shards) and all(row["accepted"] for row in shards))
        rows.append(dict(batch=index, files=[str(p) for p in group],
                         exit=code, timeout=timed_out, seconds=round(seconds, 3),
                         accepted=accepted, shards=shards))
        outputs.append(output)
        checkpoint(rows)
        print(f"{mode} batch {index}: {'PASS' if accepted else 'DENY'}; {len(group)} files", flush=True)
        if not accepted:
            break
    complete = (len(rows) == len(groups) and
                sorted(p for row in rows for p in row["files"]) == sorted(str(p) for p in files))
    accepted = complete and all(row["accepted"] for row in rows)
    code = 0 if accepted else next((row["exit"] or -1 for row in rows if not row["accepted"]), -1)
    return code, "".join(outputs), any(row["timeout"] for row in rows), time.monotonic() - start, rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--toolchain-receipt", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--timeout", type=float, required=True,
                        help="bounded whole-suite budget for each mode, not a per-file gate")
    parser.add_argument("--mode", choices=("gsi", "gsc"), action="append")
    parser.add_argument("--parallel", action="store_true",
                        help="isolated upstream-runner shards under one whole-mode budget")
    parser.add_argument("--atomic-coverage", action="store_true",
                        help="host-sized batches for complete correctness coverage, not whole-mode timing admission")
    parser.add_argument("--jobs", type=positive_int,
                        help="explicit shard capacity control; parallel default is host available CPUs")
    parser.add_argument("--processors", type=positive_int, default=None,
                        help="explicit topology control; default is host available CPU capacity")
    parser.add_argument("--min-heap-kib", type=positive_int,
                        help="diagnostic allocation-pressure control, never a normal acceptance default")
    parser.add_argument("--extra-fixture", nargs=2, action="append", default=[],
                        metavar=("SOURCE", "DESTINATION"), help="add a source fixture only to the isolated suite")
    parser.add_argument("--fixture-patch", nargs=3, action="append", default=[],
                        metavar=("PATCH", "MODEL", "MODEL_RECEIPT"),
                        help="model-bound test-only patch applied to the isolated snapshot")
    parser.add_argument("--retry-hypotheses", type=Path,
                        help="failure-ID to causal hypothesis mapping; changed routes still require review, not automatic execution")
    parser.add_argument("--scope-review", type=Path,
                        help="exact-input review of aggregate budget failures for a smaller diagnostic scope")
    parser.add_argument("selection", nargs="+")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("positive suite budget required")
    if args.jobs is not None and not args.parallel:
        parser.error("--jobs requires --parallel")
    if args.atomic_coverage and not args.parallel:
        parser.error("--atomic-coverage requires --parallel")
    runtime, out = args.runtime.resolve(), args.out.resolve()
    identity = json.loads(args.toolchain_receipt.read_text())
    check(runtime, identity)
    compiler_path, environment, compiler = gnu_compiler(args.gcc)
    driver = gnu_build_driver(runtime, compiler_path)
    host_capacity = available_processors()
    modes = args.mode or ("gsi", "gsc")
    tests = runtime / "tests"
    unit = tests / "unit-tests"
    sources = {p.relative_to(tests).as_posix(): digest(p)
               for p in unit.rglob("*") if p.is_file()}
    sources["run-unit-tests.scm"] = digest(tests / "run-unit-tests.scm")
    out.mkdir(parents=True, exist_ok=False)
    mirror = out / "runtime"
    copied = runtime_view(runtime, mirror)
    shutil.copytree(unit, copied / "unit-tests")
    shutil.copyfile(tests / "run-unit-tests.scm", copied / "run-unit-tests.scm")
    extras = {destination: {"source": Path(source), "sha256": extra_fixture(Path(source), destination, copied / "unit-tests")}
              for source, destination in args.extra_fixture}
    patchable_sources = {**sources, **{"unit-tests/" + name: row["sha256"] for name, row in extras.items()}}
    adapter_names = ["native_suite.py", "framework.py", "runtime_identity.py",
                     "retry_gate.py", "research_audit.py", "evidence_index.py",
                     "ascent_program.py", "reasoning_history.py"]
    if args.fixture_patch:
        adapter_names.append("check_gambit.py")
    adapter_sources = {name: digest(Path(__file__).with_name(name)) for name in adapter_names}
    patched, patches = {}, []
    proof_sources = [(Path(__file__).with_name(name), sha) for name, sha in adapter_sources.items()]
    if args.fixture_patch:
        from gambit_smp.check_gambit import MODELS, reuse_model_receipt
        cases = {case["id"]: case for case in json.loads((MODELS / "cases.json").read_text())["cases"]}
        for patch_name, model, model_receipt in args.fixture_patch:
            case = cases[model]
            model_receipt = Path(model_receipt)
            reuse_model_receipt(model_receipt, case)
            patch = Path(patch_name)
            before = digest(patch)
            changes = fixture_patch(patch.read_bytes(), mirror, patchable_sources, set(case["source"]))
            if digest(patch) != before or set(changes).intersection(patched):
                raise ValueError("fixture patch drift or overlapping patched tests")
            patched.update(changes)
            model_source = MODELS / (model + ".qnt")
            proof_sources.extend((path, digest(path)) for path in (patch, model_receipt, model_source))
            patches.append({"patchSha256": before, "model": model,
                            "modelSha256": digest(model_source),
                            "modelReceiptSha256": digest(model_receipt), "derivedFiles": changes})
    files = selected_files(copied / "unit-tests", args.selection)
    from gambit_smp.retry_gate import preflight
    from gambit_smp.framework import ROOT
    root = ROOT
    hypotheses = json.loads(args.retry_hypotheses.read_text()) if args.retry_hypotheses else {}
    if not isinstance(hypotheses, dict):
        raise ValueError("retry hypotheses must be an object keyed by failure ID")
    retry = preflight(root, runtime, args.toolchain_receipt, files, modes,
                      args.timeout, hypotheses, copied / "unit-tests", args.scope_review)
    (out / "retry-preflight.json").write_text(json.dumps(retry, indent=2) + "\n")
    if retry["decision"] not in {"NOT_REQUIRED", "SCOPED_REVIEWED"}:
        (out / "receipt.json").write_text(json.dumps({
            "schema": "gambit-upstream-suite-preflight.v1",
            "status": retry["decision"], "runtimeExecuted": False,
            "adapterSources": adapter_sources,
            "selectedFiles": [str(path) for path in files], "modes": modes,
            "retryPreflightSha256": digest(out / "retry-preflight.json")}, indent=2) + "\n")
        print("SUITE-PREFLIGHT-" + retry["decision"], flush=True)
        return 2 if retry["decision"] == "DENY" else 3
    proof_sources.extend((root / name, sha) for name, sha in retry["executionInputs"].items())
    if args.retry_hypotheses:
        proof_sources.append((args.retry_hypotheses, digest(args.retry_hypotheses)))
    processors, jobs = capacity(host_capacity, len(files), args.parallel, args.processors, args.jobs)
    option = f"p{processors},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    if args.min_heap_kib is not None:
        option = f"m{args.min_heap_kib}," + option
    environment["GAMBOPT"] = option
    environment["GAMBIT_SMP_EXPECTED_PROCESSORS"] = str(processors)
    receipt = {"schema": "gambit-upstream-atomic-coverage.v1" if args.atomic_coverage else "gambit-upstream-suite.v1", "candidateReceiptSha256": digest(args.toolchain_receipt),
               "adapterSources": adapter_sources,
               "scope": "complete-file correctness coverage; not whole-mode timing admission" if args.atomic_coverage else "whole-mode upstream suite admission",
               "performanceAdmitted": False,
               "gsiSha256": identity["binarySha256"], "gscSha256": identity["gscSha256"],
               "processors": processors,
               "processorSelection": "host-auto-shared-budget" if args.parallel and args.processors is None else "host-auto" if args.processors is None else "explicit-control",
               "minHeapKiBControl": args.min_heap_kib,
               "compiler": compiler.splitlines()[0], "buildDriver": driver, "sourceFiles": sources,
               "extraFixtures": {name: {"sha256": row["sha256"],
                   "testedSha256": patched.get("unit-tests/" + name, row["sha256"])} for name, row in extras.items()},
               "fixturePatches": patches,
               "jobs": jobs, "jobSelection": "host-auto" if args.parallel and args.jobs is None else "explicit-control" if args.parallel else "upstream-sequential",
               "hostCpuCapacity": host_capacity, "scheduledVmProcessors": jobs * processors,
               "runnerProcessors": 1,
               "scheduledRunnerAndChildProcessors": jobs * (processors + 1),
               "capacityScope": "runner plus one active Scheme child per shard; excludes external GCC processes",
               "selectedFiles": [str(p) for p in files], "filesPerMode": len(files),
               "wholeSuiteBudgetPerMode": None if args.atomic_coverage else args.timeout,
               "atomicBatchBudgetPerMode": args.timeout if args.atomic_coverage else None,
               "plannedAtomicBatchesPerMode": (len(files) + jobs - 1) // jobs if args.atomic_coverage else None,
               "modes": modes,
               "results": [], "status": "RUNNING"}
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    code, output, timed_out, seconds = execute(
        [str(runtime / "gsi/gsi"), "-:debug-settings=-,io-settings=lu", "-e",
         '(println "PROCESSORS:" (##current-vm-processor-count))'], copied,
        min(args.timeout, 10), env=environment)
    accepted = admitted_processors(code, output, timed_out, processors)
    receipt["processorProbe"] = dict(exit=code, timeout=timed_out,
                                    seconds=round(seconds, 3), accepted=accepted)
    (out / "processor-probe.log").write_text(output)
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    if not accepted:
        receipt["status"] = "DENY"
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        return 1
    def inputs_stable():
        try:
            check(runtime, identity)
        except ValueError as error:
            receipt["candidateDrift"] = str(error)
            return False
        return (all((tests / p).is_file() and (copied / p).is_file()
                    and digest(tests / p) == sha and digest(copied / p) == patched.get(p, sha)
                    for p, sha in sources.items())
                and all(digest(row["source"]) == row["sha256"] and
                        digest(copied / "unit-tests" / name) == patched.get("unit-tests/" + name, row["sha256"])
                        for name, row in extras.items())
                and all(path.is_file() and digest(path) == sha for path, sha in proof_sources)
                and gnu_build_driver(runtime, compiler_path) == driver)

    ok = True
    for mode in modes:
        metadata = {}
        if args.atomic_coverage:
            def checkpoint(rows):
                receipt["atomicProgress"] = dict(mode=mode, batches=rows,
                    coveredFiles=sum(len(row["files"]) for row in rows if row["accepted"]))
                (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
            code, output, timed_out, seconds, batches = atomic_suite(
                runtime, copied, out, mode, files, jobs, args.timeout, environment,
                option, sources, patched, extras, inputs_stable, checkpoint)
            metadata["batches"] = batches
        elif args.parallel:
            code, output, timed_out, seconds, shards = parallel_suite(
                runtime, copied, out, mode, files, jobs, args.timeout, environment,
                option, sources, patched, extras)
            metadata["shards"] = shards
        else:
            code, output, timed_out, seconds = execute(
                [str(runtime / "gsi/gsi"), "-:" + runner_option(option), "-f", "run-unit-tests.scm", "-" + mode]
                + [str(Path("unit-tests") / p) for p in files], copied, args.timeout,
                env=environment, metadata=metadata)
        (out / (mode + ".log")).write_text(output)
        stable = inputs_stable()
        if args.atomic_coverage:
            suite_ok = code == 0 and not timed_out and all(row["accepted"] for row in metadata["batches"])
        else:
            suite_ok = (code == 0 and not timed_out and all(row["accepted"] for row in metadata["shards"])) if args.parallel else admitted_suite(code, output, timed_out, len(files))
        accepted = suite_ok and stable
        receipt["results"].append(dict(mode=mode, exit=code, timeout=timed_out,
            seconds=round(seconds, 3), accepted=accepted, sourceStable=stable, process=metadata))
        ok = ok and accepted
        receipt["status"] = "RUNNING" if ok else "DENY"
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        print(f"{mode}: {'PASS' if accepted else 'DENY'}; {seconds:.3f}s; {len(files)} files", flush=True)
        if not accepted:
            break
    try:
        check(runtime, identity)
    except ValueError as error:
        receipt["status"] = "DENY"
        receipt["candidateDrift"] = str(error)
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        raise
    receipt["status"] = campaign_status(receipt["results"], modes, args.atomic_coverage)
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
