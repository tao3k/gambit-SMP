"""Produce a scoped allocator candidate and inspect actual GNU code generation."""
import argparse
import difflib
import json
from pathlib import Path
import re
import shlex
import shutil

from gambit_smp.check_gambit import admitted_model, reuse_model_receipt
from gambit_smp.framework import ROOT, digest, execute, gnu_compiler


OLD = "#define ALLOC_MEM_LOCK() ___SPINLOCK_LOCK(alloc_mem_lock)"
NEW = ("#define ALLOC_MEM_LOCK() do { \\\n"
       "  ___SPINLOCK_LOCK(alloc_mem_lock); \\\n"
       "  ___SHARED_MEMORY_BARRIER(); \\\n"
       "} while (0)")


def candidate(source):
    if source.count(OLD + "\n") != 1 or source.count("#define ALLOC_MEM_LOCK()\n") != 1:
        raise ValueError("reviewed allocator definitions changed")
    unlock = "#define ALLOC_MEM_UNLOCK() ___SPINLOCK_UNLOCK(alloc_mem_lock)"
    if source.count(unlock + "\n") != 1:
        raise ValueError("reviewed allocator release changed")
    calls = re.findall(r"^\s+ALLOC_MEM_LOCK\(\);\s*$", source, re.MULTILINE)
    if len(calls) != 6:
        raise ValueError("allocator call-site inventory changed; audit required")
    return source.replace(OLD + "\n", NEW + "\n", 1)


def lock_definitions(source):
    begin = "#ifdef ___SINGLE_THREADED_VMS\n\n#define ALLOC_MEM_LOCK()"
    if source.count(begin) != 1:
        raise ValueError("allocator conditional boundary changed")
    start = source.index(begin)
    end = source.index("\n#endif", start) + len("\n#endif")
    return source[start:end] + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--header", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    parser.add_argument("--model-receipt", type=Path, required=True,
                        help="original handoff receipt with its complete local logs")
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    args = parser.parse_args()
    source, header = args.source.resolve(strict=True), args.header.resolve(strict=True)
    audit = json.loads((ROOT / "evidence/research-audit.json").read_text())
    issue = next(row for row in audit["issues"] if row["id"] == "allocator-ticket-acquire-scope")
    expected = {row["path"]: row["sha256"] for row in issue["evidence"]}
    for path in (source, header):
        if expected.get(path.relative_to(ROOT).as_posix()) != digest(path):
            raise ValueError("allocator source/header differs from reviewed context")
    cases = ROOT / "models/gambit/cases.json"
    case = next(row for row in json.loads(cases.read_text())["cases"]
                if row["id"] == "ticket_queue_handoff")
    proof = args.model_receipt.resolve(strict=True)
    proof.relative_to(ROOT)
    model_rows = reuse_model_receipt(proof, case, ROOT / "models/gambit")
    model_logs = []
    for row in model_rows:
        log = (proof.parent / row["log"]).resolve(strict=True)
        log.relative_to(proof.parent.resolve())
        if (row.get("sourceStable") is not True or
                not admitted_model(row["exit"], log.read_text(), row["timeout"], row["variant"] == "old")):
            raise ValueError("handoff model log does not support reuse")
        model_logs.append(log)
    compiler, env, version = gnu_compiler(args.gcc)
    makefile = source.parent / "makefile"
    configured = re.findall(r"^C_COMPILER = (.+)$", makefile.read_text(), re.MULTILINE)
    if (len(configured) != 1 or len(shlex.split(configured[0])) != 1 or
            Path(shlex.split(configured[0])[0]).resolve(strict=True) != Path(compiler)):
        raise ValueError("compiler differs from configured source")
    fixture = ROOT / "models/gambit/native/allocator_acquire_codegen.c"
    paths = (source, header, makefile, fixture, cases, proof, *model_logs, Path(__file__).resolve(),
             ROOT / "models/gambit/ticket_queue_handoff.qnt",
             ROOT / "evidence/research-audit.json", ROOT / "src/gambit_smp/check_gambit.py",
             ROOT / "src/gambit_smp/framework.py")
    inputs = {path.relative_to(ROOT).as_posix(): digest(path) for path in paths}
    baseline = source.read_text()
    revised = candidate(baseline)
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    (out / "mem.c").write_text(revised)
    patch = "".join(difflib.unified_diff(baseline.splitlines(keepends=True),
        revised.splitlines(keepends=True), fromfile="a/lib/mem.c", tofile="b/lib/mem.c"))
    (out / "allocator-acquire.patch").write_text(patch)
    receipt = {"schema": "gambit-allocator-acquire-codegen.v1", "inputs": inputs,
               "compiler": version.splitlines()[0], "compilerSha256": digest(Path(compiler)),
               "diagnosticOnly": True, "runtimeAdmitted": False, "releaseAdmitted": False,
               "scope": "Scoped ALLOC macro candidate, real generated header, GNU assembly only. "
                        "Not executed concurrency, full compilation, source causality or speedup.",
               "results": []}
    for policy, text in (("baseline", baseline), ("candidate", revised)):
        directory = out / policy
        directory.mkdir()
        shutil.copyfile(header, directory / "gambit.h")
        shutil.copyfile(fixture, directory / fixture.name)
        (directory / "allocator-lock-source.inc").write_text(lock_definitions(text))
        code, log, timeout, seconds = execute([compiler, "-O2", "-S", str(directory / fixture.name),
            "-o", str(directory / "allocator.s")], directory, 30, env=env)
        (directory / "compile.log").write_text(log)
        row = {"policy": policy, "exit": code, "timeout": timeout, "seconds": seconds}
        if code == 0 and not timeout:
            row["assemblySha256"] = digest(directory / "allocator.s")
        receipt["results"].append(row)
    stable = all(digest(ROOT / name) == sha for name, sha in inputs.items())
    stable = stable and digest(Path(compiler)) == receipt["compilerSha256"]
    receipt.update(contextStable=stable, candidateSourceSha256=digest(out / "mem.c"),
                   patchSha256=digest(out / "allocator-acquire.patch"))
    ok = stable and all(row["exit"] == 0 and not row["timeout"] for row in receipt["results"])
    receipt["status"] = "compiled-inspection-required" if ok else "DENY"
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(receipt["status"] + "; runtimeAdmitted=false")
    return 0 if ok else 1


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('allocator-acquire')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('allocator-acquire', main))
