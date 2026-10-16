"""Compare extracted GC notification protocols with real POSIX interleavings."""
import argparse
from contextlib import ExitStack
import json
from pathlib import Path
import shutil

from gambit_smp.framework import ROOT, digest, gnu_compiler
from gambit_smp.gc_wait_source import extract
from gambit_smp.locked_object import BuildStages, configure_source, tool_identity
from gambit_smp.source_materialize import locked_source


def matched(policy, point, actual):
    if not isinstance(actual, dict) or actual.get("point") != point:
        return False
    if actual.get("joined") is not True or actual.get("finalCount") != 0:
        return False
    if policy == "baseline":
        return (point in (1, 2) and actual.get("consumed") == 0 and
                actual.get("signals") == 1 and actual.get("waits") == 1 and
                actual.get("signalBeforeWait") is True and actual.get("pendingAtWait") is True and
                actual.get("countAtWait") == 1)
    if policy != "candidate" or point not in (1, 2, 3):
        return False
    if actual.get("consumed") != (2 if point == 3 else 1) or actual.get("signals") != (2 if point == 3 else 1):
        return False
    if point == 1:
        return (actual.get("waits", 0) >= 1 and actual.get("signalBeforeWait") is True and
                actual.get("pendingAtWait") is False and actual.get("countAtWait") == 1)
    return point == 3 or (actual.get("waits", 0) >= 1 and actual.get("signalBeforeWait") is False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gcc", type=Path, required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    compiler, env, version = gnu_compiler(args.gcc)
    autoconf_path = shutil.which("autoconf")
    if autoconf_path is None:
        raise ValueError("autoconf required")
    env["PATH"] += ":" + str(Path(autoconf_path).absolute().parent)
    env["CC"] = compiler
    record = dict(schema="gambit-notification-source-schedules.v1", results=[],
        compiler=version.splitlines()[0], compilerSha256=digest(Path(compiler)),
        environment={key: env.get(key) for key in ("PATH", "CC", "CFLAGS", "CPPFLAGS", "LDFLAGS", "LIBS")},
        tools=tool_identity(env), runtimeAdmitted=False, releaseAdmitted=False, nativeGcPassed=False,
        scope="Extracted publisher/wait code and configured header; real POSIX threads. "
              "Queue consumption is metadata-only. Not payload GC, phase completion or bootstrap.")
    fixture = ROOT / "models/gambit/native/gc_notification_candidate_schedule.c"
    with ExitStack() as stack:
        sources, inputs = {}, {}
        for policy, number in (("baseline", "026"), ("candidate", "029")):
            source, bound = stack.enter_context(locked_source(ROOT, f"evidence/runtime-source-{number}.lock.json"))
            inputs.update(bound)
            sources[policy] = source
        for path in (fixture, Path(__file__).resolve(), ROOT / "src/gambit_smp/gc_wait_source.py",
                     ROOT / "src/gambit_smp/locked_object.py"):
            inputs[path.relative_to(ROOT).as_posix()] = digest(path)
        record["inputs"] = inputs
        candidate = sources["candidate"]
        if digest(candidate / "include/gambit.h.in") != digest(sources["baseline"] / "include/gambit.h.in"):
            raise ValueError("matched header templates required")
        setup, ok = configure_source(candidate, out, compiler, env, str(Path(autoconf_path).resolve()))
        record["setup"] = setup.results
        if ok:
            header = candidate / "include/gambit.h"
            record["generatedHeaderSha256"] = digest(header)
            for policy, source in sources.items():
                directory = out / policy
                directory.mkdir()
                publish, wait = extract((source / "lib/mem.c").read_text())
                protected = "___MUTEX_LOCK(scan_termination_mutex);" in publish
                if protected != (policy == "candidate"):
                    raise ValueError("source notification policy differs from control contract")
                for name, text in (("gc-publish-source.inc", publish), ("gc-wait-source.inc", wait)):
                    (directory / name).write_text(text)
                shutil.copyfile(header, directory / "gambit.h")
                shutil.copyfile(fixture, directory / fixture.name)
                stages = BuildStages(source, directory, env)
                binary = directory / "schedule"
                code, _, timeout, _ = stages.run("compile", [compiler, "-O1", "-pthread",
                    "-Wall", "-Wextra", "-Werror", "-Wno-unused-value",
                    "-DPROTECTED_PUBLISHER=" + str(int(protected)),
                    fixture.name, "-o", str(binary)], directory, 30)
                row = dict(policy=policy, sourceSha256=digest(source / "lib/mem.c"),
                    publisherSha256=digest(directory / "gc-publish-source.inc"),
                    waitSha256=digest(directory / "gc-wait-source.inc"), stages=stages.results, schedules=[])
                record["results"].append(row)
                if code != 0 or timeout:
                    ok = False
                    break
                row["binarySha256"] = digest(binary)
                for point in ((1, 2) if policy == "baseline" else (1, 2, 3)):
                    code, log, timeout, _ = stages.run("point-" + str(point), [str(binary), str(point)], directory, 5)
                    try:
                        actual = json.loads(log)
                    except ValueError:
                        actual = None
                    success = code == 0 and not timeout and matched(policy, point, actual)
                    row["schedules"].append(dict(point=point, actual=actual, expectedOutcomeMatched=success,
                        negativeControl=policy == "baseline"))
                    if not success:
                        ok = False
                        break
                if not ok:
                    break
        record["contextStable"] = all(digest(ROOT / name) == sha for name, sha in inputs.items())
        record["contextStable"] &= digest(Path(compiler)) == record["compilerSha256"]
        ok &= record["contextStable"]
    record["status"] = "source-schedules-observed" if ok else "DENY"
    (out / "receipt.json").write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps({key: record[key] for key in ("status", "results", "runtimeAdmitted")}))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
