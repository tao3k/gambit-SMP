"""Run source-bound POSIX notification schedules; never admit the Gambit runtime."""
import argparse
import json
from pathlib import Path
import re
import shlex
import shutil

from gambit_smp.framework import ROOT, digest, execute, gnu_compiler
from gambit_smp.protocol_evidence import checked_rows


def matched(point, actual):
    if point not in (1, 2, 3) or not isinstance(actual, dict):
        return False
    common = (actual.get("point") == point and actual.get("count") == 0
              and actual.get("queueEmpty") is True and actual.get("joined") is True
              and actual.get("workSignals") == 1 and actual.get("waitCalls", 0) >= 1
              and actual.get("waitErrors") == 0)
    if point == 3:
        return (common and actual.get("workSignalBeforeWait") is False
                and actual.get("nonzeroWakeups", 0) >= 1 and actual.get("restoredCount") == 2)
    return common and actual.get("workSignalBeforeWait") is True


def extract(source):
    begin = "___HIDDEN void end_heap_chunk\n"
    end = "___HIDDEN void set_heap_msection\n"
    if source.count(begin) != 1 or source.count(end) != 1:
        raise ValueError("publisher boundaries changed; audit required")
    left, right = source.index(begin), source.index(end)
    if left >= right:
        raise ValueError("publisher boundaries reversed")
    names = ("___PSTATE_MEM", "___VMSTATE_MEM", "alloc_heap_ptr", "alloc_heap_chunk_start",
             "heap_chunks_to_scan_lock", "heap_chunks_to_scan_head", "heap_chunks_to_scan_tail",
             "scan_ptr", "scan_termination_mutex", "scan_termination_condvar", "NULL_CHUNK_LINK")
    macros = []
    for name in names:
        rows = re.findall(r"^#define\s+" + re.escape(name) + r"(?=\s|\()[^\n]*$",
                          source[:left], re.MULTILINE)
        if len(rows) != 1:
            raise ValueError("unique source macro required: " + name)
        macros.append(rows[0])
    marker = "      /* Signal being idle and wait for more work or termination */"
    if source.count(marker) != 1:
        raise ValueError("idle block boundary changed")
    first = source.index("      ___MUTEX_LOCK(scan_termination_mutex);", source.index(marker))
    last = source.index("\n    }\n\n#endif\n}", first)
    return "\n".join(macros) + "\n" + source[left:right], source[first:last]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--header", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    source, header = args.source.resolve(strict=True), args.header.resolve(strict=True)
    manifest_path = ROOT / "evidence/gc-wait-notification.json"
    proof = ROOT / "evidence/model-results/gc-wait-notification/receipt.json"
    manifest = json.loads(manifest_path.read_text())
    checked_rows(ROOT, manifest, proof)
    for path in (source, header):
        name = path.relative_to(ROOT).as_posix()
        if manifest["contextInputs"].get(name) != digest(path):
            raise ValueError("source/header differs from reviewed model context")
    compiler, env, version = gnu_compiler(args.gcc)
    makefile = source.parent / "makefile"
    configured = re.findall(r"^C_COMPILER = (.+)$", makefile.read_text(), re.MULTILINE)
    if len(configured) != 1 or len(shlex.split(configured[0])) != 1:
        raise ValueError("one configured compiler required")
    if Path(shlex.split(configured[0])[0]).resolve(strict=True) != Path(compiler):
        raise ValueError("fixture compiler differs from configured source compiler")
    flags = re.findall(r"^FLAGS_OBJ = (.*)$", makefile.read_text(), re.MULTILINE)
    if len(flags) != 1 or any(word.startswith("-std=") or word == "-ansi"
                              for word in shlex.split(flags[0])):
        raise ValueError("source language override requires an explicit fixture audit")
    code, macros, timeout, _ = execute([compiler, "-dM", "-E", "-x", "c", "/dev/null"], ROOT, 10, env=env)
    language = re.findall(r"^#define __STDC_VERSION__ (\d+)L$", macros, re.MULTILINE)
    if code != 0 or timeout or len(language) != 1:
        raise ValueError("cannot attest configured default C language")
    fixture = ROOT / "models/gambit/native/gc_wait_notification_schedule.c"
    paths = (source, header, makefile, fixture, manifest_path, proof, Path(__file__).resolve(),
             ROOT / "src/gambit_smp/framework.py", ROOT / "src/gambit_smp/protocol_evidence.py")
    inputs = {p.relative_to(ROOT).as_posix(): digest(p) for p in paths}
    publish, wait = extract(source.read_text())
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    (out / "gc-publish-source.inc").write_text(publish)
    (out / "gc-wait-source.inc").write_text(wait)
    shutil.copyfile(header, out / "gambit.h")
    shutil.copyfile(fixture, out / fixture.name)
    receipt = dict(schema="gambit-gc-wait-source-schedule.v1", inputs=inputs,
        diagnosticOnly=True, runtimeAdmitted=False, releaseAdmitted=False,
        scope="Unchanged publisher and idle-count/wait fragment with generated header. "
              "Real POSIX mutex/condition/thread calls; fixture-controlled interleavings, "
              "queue consumption and disabled activity logging. Not full scanning, VM "
              "execution, source repair, native GC/bootstrap admission or a speed claim.",
        compiler=version.splitlines()[0], compilerSha256=digest(Path(compiler)),
        configuredCompilerVerified=True, defaultCVersion=int(language[0]), results=[])
    code, log, timeout, seconds = execute([compiler, "-O1", "-pthread",
        "-Wall", "-Wextra", "-Werror", "-Wno-unused-value", str(out / fixture.name),
        "-o", str(out / "schedule")], out, 30, env=env)
    (out / "compile.log").write_text(log)
    receipt["compile"] = dict(exit=code, timeout=timeout, seconds=seconds)
    if code == 0 and not timeout:
        for point in (1, 2, 3):
            code, log, timeout, seconds = execute([str(out / "schedule"), str(point)], out, 5, env=env)
            (out / f"point-{point}.log").write_text(log)
            try:
                actual = json.loads(log)
            except ValueError:
                actual = None
            receipt["results"].append(dict(point=point, exit=code, timeout=timeout,
                seconds=seconds, actual=actual, matched=code == 0 and not timeout and matched(point, actual)))
    stable = all(digest(ROOT / name) == sha for name, sha in inputs.items())
    stable = stable and digest(Path(compiler)) == receipt["compilerSha256"]
    stable = stable and (out / "gc-publish-source.inc").read_text() == publish
    stable = stable and (out / "gc-wait-source.inc").read_text() == wait
    stable = stable and digest(out / "gambit.h") == inputs[header.relative_to(ROOT).as_posix()]
    stable = stable and digest(out / fixture.name) == inputs[fixture.relative_to(ROOT).as_posix()]
    ok = stable and len(receipt["results"]) == 3 and all(r["matched"] for r in receipt["results"])
    receipt.update(sourceStable=stable, status="source-schedule-observed" if ok else "DENY")
    if receipt["compile"]["exit"] == 0 and not receipt["compile"]["timeout"]:
        receipt["binarySha256"] = digest(out / "schedule")
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"status": receipt["status"], "schedules": len(receipt["results"]),
                      "runtimeAdmitted": False}))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
