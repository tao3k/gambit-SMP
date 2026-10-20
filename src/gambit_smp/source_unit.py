#!/usr/bin/env python3
"""Fault injection on an unchanged extracted C function, not native ABI acceptance."""
import argparse
import json
from pathlib import Path
import re
import shutil
from gambit_smp.source_binding import checked_negate_header_hash
from gambit_smp.framework import ROOT, digest, execute, gnu_compiler, apply_untracked_patch


def sync_resource_functions(source):
    setup = "___HIDDEN void setup_sync_op_pstate\n"
    setup_end = "\n\n#endif\n\n\n___EXP_FUNC(void,___cleanup_pstate)"
    cleanup = "___EXP_FUNC(void,___cleanup_pstate)\n"
    cleanup_end = "\n\n___EXP_FUNC(___SCMOBJ,___setup_pstate)\n"
    pieces = []
    for start, end in ((setup, setup_end), (cleanup, cleanup_end)):
        if source.count(start) != 1 or source.count(end) != 1:
            raise ValueError("sync resource source boundaries changed; audit required")
        left, right = source.index(start), source.index(end)
        if left >= right:
            raise ValueError("sync resource source boundaries out of order")
        pieces.append(source[left:right])
    return "\n\n".join(pieces) + "\n"


def pstate_os_mem_functions(source):
    start = "___HIDDEN void cleanup_os_and_mem_pstate\n"
    end = "\n\n___HIDDEN void cleanup_os_and_mem_vmstate\n"
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("processor OS/memory helper boundaries changed")
    left, right = source.index(start), source.index(end)
    if left >= right:
        raise ValueError("processor OS/memory helper boundaries out of order")
    block = source[left:right]
    if block.count("___HIDDEN ___SCMOBJ setup_os_and_mem_pstate\n") != 1:
        raise ValueError("processor setup helper missing or duplicated")
    return block + "\n"


def pstate_setup_functions(source):
    boundaries = (
        ("___HIDDEN ___SCMOBJ setup_interrupts_pstate\n", "\n\n___EXP_FUNC(void,___raise_procedural_interrupt_pstate)"),
        ("___HIDDEN void cleanup_interrupts_pstate\n", "\n\n___HIDDEN void setup_processor_scmobj_pstate"),
        ("___HIDDEN ___SCMOBJ setup_sync_op_pstate\n", "\n\n#endif\n\n\n___EXP_FUNC(void,___cleanup_pstate)"),
        ("___HIDDEN void cleanup_failed_pstate\n", "\n\n___EXP_FUNC(___SCMOBJ,___setup_pstate)"),
        ("___EXP_FUNC(___SCMOBJ,___setup_pstate)\n", "\n\n___EXP_FUNC(void,___cleanup_vmstate)"),
    )
    blocks = [pstate_os_mem_functions(source)]
    for start, end in boundaries:
        if source.count(start) != 1 or source.count(end) != 1:
            raise ValueError("checked setup function boundary missing or ambiguous")
        left, right = source.index(start), source.index(end)
        if left >= right:
            raise ValueError("checked setup function boundaries reversed")
        blocks.append(source[left:right])
    return "\n\n".join(blocks) + "\n"


def source_fixture_run(out, fixture, compiler, environment, flags, label):
    binary = out / label
    code, log, timeout, seconds = execute([compiler, "-std=c11", "-O1", "-Wall", "-Wextra", "-Werror",
        *flags, str(out / fixture.name), "-o", str(binary)], out, 30, env=environment)
    (out / (label + "-compile.log")).write_text(log)
    row = {"compile": dict(exit=code, timeout=timeout, seconds=seconds), "label": label}
    if code == 0 and not timeout:
        code, log, timeout, seconds = execute([str(binary)], out, 5, env=environment)
        (out / (label + "-observe.log")).write_text(log)
        row["observation"] = dict(exit=code, timeout=timeout, seconds=seconds)
        return row, log
    return row, None


def vm_actlog_abort_unit(args, compiler, environment, version):
    from gambit_smp.protocol_evidence import checked_rows
    from gambit_smp.source_materialize import locked_source
    manifest_path = ROOT / "evidence/vm-activity-log-abort-source031.json"
    manifest = json.loads(manifest_path.read_text())
    checked_rows(ROOT, manifest, args.model_receipt)
    if args.source_lock != "evidence/runtime-source-031.lock.json":
        raise ValueError("activity log source review requires its exact source lock")
    patch = ROOT / "patches/candidate-vm-actlog-abort.patch"
    if digest(patch) != manifest["contextInputs"].get(str(patch.relative_to(ROOT))):
        raise ValueError("activity log patch differs from reviewed context")
    fixture = ROOT / "models/gambit/native/vm_activity_log_abort.c"
    inputs = {p.relative_to(ROOT).as_posix(): digest(p)
              for p in (manifest_path, patch, fixture, args.model_receipt.resolve(), Path(__file__).resolve())}
    with locked_source(ROOT, args.source_lock) as (source, source_inputs):
        inputs.update(source_inputs)
        before = source / "lib/actlog.c"
        if digest(before) != manifest["contextInputs"]["vendor/gambit/lib/actlog.c"]:
            raise ValueError("activity log baseline is not the reviewed submodule source")
        apply_untracked_patch(source, patch.read_bytes(), {"lib/actlog.c", "lib/actlog.h"})
        text = before.read_text()
        start, end = "___SCMOBJ ___setup_actlog_vmstate\n", "void ___cleanup_actlog_vmstate\n"
        if text.count(start) != 1 or text.count(end) != 1:
            raise ValueError("activity log source boundaries changed")
        block = text[text.index(start):text.index(end)]
        abort = block[block.index("void ___abort_actlog_vmstate\n"):]
        if any(token in abort for token in ("___actlog_stop_pstate", "___actlog_dump", "___PSTATE_FROM_PROCESSOR_ID")):
            raise ValueError("constructor abort must not visit P0 or dump")
        args.out.mkdir(parents=True, exist_ok=False)
        out = args.out.resolve()
        include = out / "vm-actlog-source.inc"
        include.write_text(block)
        shutil.copyfile(fixture, out / fixture.name)
        for name in ("actlog.c", "actlog.h"):
            shutil.copyfile(source / "lib" / name, out / name)
        receipt = dict(schema="gambit-actlog-abort-source-unit.v1", inputs=inputs,
            sourceFunctionsSha256=digest(include), candidateSourceSha256=digest(before),
            compiler=version.splitlines()[0], runtimeAdmitted=False, releaseAdmitted=False,
            scope="VM log array/mutex only, fresh exclusive successful init; no P0 buffers, native threads or constructor integration",
            results=[])
        for label, flags, count in (("posix", ["-DTEST_ENABLED", "-DTEST_POSIX"], 3),
                                    ("void-init", ["-DTEST_ENABLED"], 2),
                                    ("disabled", ["-Wno-unused-parameter"], 1)):
            row, output = source_fixture_run(out, fixture, compiler, environment, flags, label)
            try:
                actual = json.loads(output) if output is not None else None
            except ValueError:
                actual = None
            observed = row.get("observation", {})
            row.update(actual=actual, accepted=observed.get("exit") == 0 and observed.get("timeout") is False
                       and actual == {"checks": count, "arrayLive": 0, "mutexLive": 0})
            receipt["results"].append(row)
        checked = ("  if (!___MUTEX_INIT(___vms->actlog.mut))\n"
                   "    {\n      ___FREE_MEM(ptr);\n      return ___FIX(___UNKNOWN_ERR);\n    }")
        if block.count(checked) != 1:
            raise ValueError("activity log negative control no longer targets the exact init check")
        include.write_text(block.replace(checked, "  ___MUTEX_INIT(___vms->actlog.mut);"))
        row, output = source_fixture_run(out, fixture, compiler, environment,
                                        ["-DTEST_ENABLED", "-DTEST_POSIX"], "ignored-mutex-error-control")
        observed = row.get("observation", {})
        row.update(accepted=row["compile"]["exit"] == 0 and observed.get("exit", 0) != 0
                   and observed.get("timeout") is False and output is not None
                   and "EXPECTED-MUTEX-ERROR" in output,
                   scope="Named injected rejection control, not candidate code")
        receipt["results"].append(row)
        include.write_text(block)
        if args.native_runtime_root:
            from gambit_smp.runtime_identity import check
            identity_path = ROOT / "evidence/source-results/source031-native-gc-fixtures/identity.json"
            identity = json.loads(identity_path.read_text())
            runtime = args.native_runtime_root.resolve()
            check(runtime, identity)
            inputs[identity_path.relative_to(ROOT).as_posix()] = digest(identity_path)
            receipt["nativeHeaderSha256"] = digest(runtime / "include/gambit.h")
            receipt["nativeConfigSha256"] = digest(runtime / "include/config.h")
            receipt["candidateFiles"] = {name: digest(out / name) for name in ("actlog.c", "actlog.h")}
            for label, extra in (("object-enabled", ["-D___ACTIVITY_LOG"]), ("object-disabled", [])):
                command = [compiler, "-O0", "-fPIC", "-fwrapv", "-fno-strict-aliasing",
                    "-DHAVE_CONFIG_H", "-D___LIBRARY", *extra,
                    "-I" + str(runtime / "include"), "-I" + str(runtime / "lib"),
                    "-c", str(out / "actlog.c"), "-o", str(out / (label + ".o"))]
                code, log, timed_out, seconds = execute(command, out, 30, env=environment)
                (out / (label + ".log")).write_text(log)
                row = dict(label=label, exit=code, timeout=timed_out, seconds=seconds,
                           accepted=code == 0 and not timed_out,
                           scope="Complete actual C translation unit, diagnostic O0, not linked-runtime acceptance")
                if row["accepted"]:
                    row["objectSha256"] = digest(out / (label + ".o"))
                receipt["results"].append(row)
            check(runtime, identity)
        stable = all(digest(ROOT / name) == sha for name, sha in inputs.items())
        receipt.update(sourceStable=stable, status="source-unit-pass" if stable and all(
            row["accepted"] for row in receipt["results"]) else "DENY")
        artifacts = [*out.glob("*.log"), include, out / fixture.name, out / "actlog.c", out / "actlog.h"]
        receipt["artifacts"] = {path.name: digest(path) for path in sorted(artifacts)}
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("ACTLOG-ABORT-SOURCE-" + receipt["status"])
    return 0 if receipt["status"] == "source-unit-pass" else 1


def pstate_setup_unit(args, compiler, environment, version):
    from gambit_smp.protocol_evidence import checked_rows
    manifest = json.loads((ROOT / "evidence/pstate-setup-protocol.json").read_text())
    checked_rows(ROOT, manifest, args.model_receipt)
    candidate = json.loads(args.candidate_receipt.read_text())
    source = args.setup_source.resolve()
    patch = ROOT / candidate["patch"]
    if (source != (ROOT / candidate["source"]).resolve()
            or digest(source) != candidate["sourceSha256"]
            or digest(patch) != candidate["patchSha256"]
            or digest(args.model_receipt) != candidate["modelReceiptSha256"]):
        raise ValueError("candidate source/patch/model identity differs")
    block = pstate_setup_functions(source.read_text())
    fixture = ROOT / "models/gambit/native/pstate_setup_transaction.c"
    inputs = {str(path.relative_to(ROOT)): digest(path)
              for path in (source, patch, fixture, args.candidate_receipt.resolve(),
                           args.model_receipt.resolve(), Path(__file__).resolve())}
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    include = out / "pstate-setup-source.inc"
    include.write_text(block)
    shutil.copyfile(fixture, out / fixture.name)
    receipt = dict(schema="gambit-pstate-setup-source-unit.v1", inputs=inputs,
        scope="actual candidate helpers and setup caller, mocked primitive resources; no real GC/OS threads",
        sourceFunctionsSha256=digest(include), compiler=version.splitlines()[0],
        runtimeAdmitted=False, releaseAdmitted=False, results=[])
    ok = True
    for label, flags, expected in (("posix", ["-DTEST_POSIX"], 20), ("void-init", [], 10)):
        row, output = source_fixture_run(out, fixture, compiler, environment, flags, label)
        try:
            observed = json.loads(output) if output is not None else None
        except ValueError:
            observed = None
        result = row.get("observation", {})
        accepted = (result.get("exit") == 0 and result.get("timeout") is False
                    and observed == {"platform": label, "checks": expected, "invalid": 0})
        row.update(accepted=accepted, actual=observed)
        receipt["results"].append(row)
        ok = ok and accepted
    ignored = ("  if (!___MUTEX_INIT(___ps->sync_mut))\n"
               "    return ___FIX(___UNKNOWN_ERR);\n"
               "  if (!___CONDVAR_INIT(___ps->sync_cv))\n"
               "    {\n"
               "      ___MUTEX_DESTROY(___ps->sync_mut);\n"
               "      return ___FIX(___UNKNOWN_ERR);\n"
               "    }")
    if block.count(ignored) != 1:
        raise ValueError("negative control no longer targets exactly the checked sync setup branch")
    include.write_text(block.replace(ignored, "  ___MUTEX_INIT(___ps->sync_mut);\n  ___CONDVAR_INIT(___ps->sync_cv);"))
    row, output = source_fixture_run(out, fixture, compiler, environment, ["-DTEST_POSIX"], "ignored-sync-errors-control")
    result = row.get("observation", {})
    accepted = (row["compile"]["exit"] == 0 and result.get("exit", 0) != 0
                and result.get("timeout") is False and output is not None
                and "EXPECTED-SETUP-FAILURE-NOT-RETURNED" in output)
    row.update(accepted=accepted, scope="named injected negative policy, not the candidate")
    receipt["results"].append(row)
    include.write_text(block)
    stable = all(digest(ROOT / name) == sha for name, sha in inputs.items()) and include.read_text() == block
    receipt.update(sourceStable=stable, status="source-unit-pass" if ok and accepted and stable else "DENY")
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("PSTATE-SETUP-SOURCE-" + ("PASS" if receipt["status"] == "source-unit-pass" else "DENY"))
    return 0 if receipt["status"] == "source-unit-pass" else 1


def pstate_os_mem_unit(args, compiler, environment, version):
    from gambit_smp.protocol_evidence import checked_rows
    manifest = json.loads((ROOT / "evidence/pstate-setup-protocol.json").read_text())
    checked_rows(ROOT, manifest, args.model_receipt)
    source = args.setup_source.resolve()
    if digest(source) != manifest["contextInputs"].get(str(source.relative_to(ROOT))):
        raise ValueError("source differs from the checked setup contract")
    block = pstate_os_mem_functions(source.read_text())
    fixture = ROOT / "models/gambit/native/pstate_os_mem_transaction.c"
    inputs = {str(path.relative_to(ROOT)): digest(path)
              for path in (source, fixture, args.model_receipt.resolve(), Path(__file__).resolve())}
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    include = out / "pstate-os-mem-source.inc"
    include.write_text(block)
    shutil.copyfile(fixture, out / fixture.name)
    receipt = {"schema": "gambit-pstate-os-mem-source-unit.v1", "diagnosticOnly": True,
        "scope": "unchanged OS/memory setup and cleanup helpers; mocked primitive ownership and failure, not native heap/threads",
        "inputs": inputs, "blockSha256": digest(include), "compiler": version.splitlines()[0]}
    code, log, timeout, seconds = execute([compiler, "-std=c11", "-O1", "-Wall", "-Wextra", "-Werror",
        str(out / fixture.name), "-o", str(out / "pstate-unit")], out, 30, env=environment)
    (out / "compile.log").write_text(log)
    receipt["compile"] = dict(exit=code, timeout=timeout, seconds=seconds)
    accepted = False
    if code == 0 and not timeout:
        code, log, timeout, seconds = execute([str(out / "pstate-unit")], out, 5, env=environment)
        (out / "observe.log").write_text(log)
        accepted = code == 0 and not timeout and log.splitlines() == [
            "OS-FAILURE NO-OWNED-RESOURCES", "MEM-FAILURE OS-ALREADY-RELEASED",
            "SUCCESS MEMORY-BEFORE-OS", "BLIND-CLEANUP TWO-INVALID-RELEASES",
            "PSTATE-OS-MEM-TRANSACTION-OBSERVED"]
        receipt["observation"] = dict(exit=code, timeout=timeout, seconds=seconds, accepted=accepted)
    stable = all(digest(ROOT / name) == sha for name, sha in inputs.items()) and include.read_text() == block
    receipt.update(sourceStable=stable, status="source-unit-observation" if accepted and stable else "DENY")
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("PSTATE-OS-MEM-SOURCE-" + ("OBSERVED" if accepted and stable else "DENY"))
    return 0 if accepted and stable else 1


def continuation_chunk_block(source):
    left = "___HIDDEN void mark_captured_continuation\n"
    right = "\n\n___HIDDEN void mark_frame\n"
    if source.count(left) != 1 or source.count(right) != 1:
        raise ValueError("continuation source boundaries changed")
    function = source[source.index(left):source.index(right)]
    block = ("          if (alloc_heap_ptr >= alloc_heap_chunk_limit)\n"
             "            {\n"
             "              alloc_heap_ptr = alloc;\n"
             "              end_heap_chunk (___ps);\n"
             "              start_heap_chunk (___ps);\n"
             "              alloc = alloc_heap_ptr;\n"
             "            }")
    if function.count(block) != 1 or "*alloc++ = ___MAKE_HD_WORDS(words, ___sFRAME);" not in function:
        raise ValueError("continuation publication block changed; source audit required")
    return block + "\n"


def continuation_chunk_unit(args, compiler, environment, version):
    from gambit_smp.check_gambit import reuse_model_receipt
    case = next(row for row in json.loads((ROOT / "models/gambit/cases.json").read_text())["cases"]
                if row["id"] == "continuation_chunk_publication")
    reuse_model_receipt(args.model_receipt, case)
    source = args.mem_source.resolve()
    header = source.with_name("mem.h")
    if not re.search(r"^#define ___MSECTION_BIGGEST +255$", header.read_text(), re.MULTILINE) or not re.search(
            r"^#define ___MSECTION_CHUNK +___MSECTION_BIGGEST$", header.read_text(), re.MULTILINE):
        raise ValueError("chunk threshold changed; fixture audit required")
    block = continuation_chunk_block(source.read_text())
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    include = out / "continuation-chunk-source.inc"
    include.write_text(block)
    fixture = ROOT / "models/gambit/native/continuation_chunk_frontier.c"
    shutil.copyfile(fixture, out / fixture.name)
    inputs = {str(path.relative_to(ROOT)): digest(path)
              for path in (source, header, fixture, args.model_receipt.resolve())}
    receipt = {"schema": "gambit-continuation-chunk-source-unit.v1", "diagnosticOnly": True,
               "scope": "unchanged publication block, mocked complete frames and chunk callbacks; source mechanism only, not real GC or speedup",
               "inputs": inputs, "blockSha256": digest(include), "compiler": version.splitlines()[0]}
    code, log, timeout, seconds = execute([compiler, "-std=c11", "-O1", "-Wall", "-Wextra", "-Werror",
        "-DCHUNK_WORDS=255", str(out / fixture.name), "-o", str(out / "chunk-unit")], out, 30, env=environment)
    (out / "compile.log").write_text(log)
    receipt["compile"] = dict(exit=code, timeout=timeout, seconds=seconds)
    accepted = False
    if code == 0 and not timeout:
        code, log, timeout, seconds = execute([str(out / "chunk-unit")], out, 5, env=environment)
        (out / "observe.log").write_text(log)
        accepted = code == 0 and not timeout and log.splitlines() == [
            "LOCAL 254 COMMITTED 0 CLOSED 0", "LOCAL 256 COMMITTED 0 CLOSED 0",
            "LOCAL 256 COMMITTED 256 CLOSED 1", "STALE-COMMITTED-FRONTIER-OBSERVED"]
        receipt["observation"] = dict(exit=code, timeout=timeout, seconds=seconds, accepted=accepted)
    stable = all(digest(ROOT / name) == sha for name, sha in inputs.items()) and include.read_text() == block
    receipt.update(sourceStable=stable, status="source-unit-observation" if accepted and stable else "DENY")
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("CONTINUATION-CHUNK-SOURCE-" + ("OBSERVED" if accepted and stable else "DENY"))
    return 0 if accepted and stable else 1


def sync_resource_unit(args, compiler, environment, version):
    from gambit_smp.check_gambit import reuse_model_receipt
    case = next(row for row in json.loads((ROOT / "models/gambit/cases.json").read_text())["cases"]
                if row["id"] == "sync_resource_retirement")
    reuse_model_receipt(args.model_receipt, case)
    source = args.setup_source.resolve()
    source_hash = digest(source)
    function = sync_resource_functions(source.read_text())
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    include = out / "sync-resource-source.inc"
    include.write_text(function)
    fixture = ROOT / "models/gambit/native/sync_resource_retirement.c"
    shutil.copyfile(fixture, out / fixture.name)
    receipt = {"schema": "gambit-sync-resource-source-unit.v1", "diagnosticOnly": True,
        "scope": "unchanged SMP setup/cleanup functions with mocked resource accounting; mechanism observation, not native POSIX or repair admission",
        "sourceSha256": source_hash, "functionSha256": digest(include),
        "fixtureSha256": digest(fixture), "modelReceiptSha256": digest(args.model_receipt),
        "compiler": version.splitlines()[0], "results": []}
    code, log, timeout, seconds = execute(
        [compiler, "-std=c11", "-O1", "-Wall", "-Wextra", "-Werror", str(out / fixture.name),
         "-o", str(out / "sync-resource-unit")], out, 30, env=environment)
    (out / "compile.log").write_text(log)
    receipt["compile"] = dict(exit=code, timeout=timeout, seconds=seconds)
    accepted = False
    if code == 0 and not timeout:
        code, log, timeout, seconds = execute([str(out / "sync-resource-unit")], out, 5, env=environment)
        (out / "observe.log").write_text(log)
        accepted = code == 0 and not timeout and log.splitlines() == [
            "INITIALIZED 4 DESTROYED 0 DOUBLE_INIT 2", "SOURCE-RESOURCE-REUSE-REPRODUCED"]
        receipt["results"].append(dict(exit=code, timeout=timeout, seconds=seconds,
            accepted=accepted, observation="two-resource-reinitializations-without-destruction"))
    stable = (digest(source) == source_hash and include.read_text() == function
              and digest(out / fixture.name) == receipt["fixtureSha256"]
              and digest(args.model_receipt) == receipt["modelReceiptSha256"])
    receipt.update(sourceStable=stable,
                   status="source-unit-observation" if accepted and stable else "DENY")
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("SYNC-RESOURCE-SOURCE-" + ("OBSERVED" if accepted and stable else "DENY"))
    return 0 if accepted and stable else 1


def resize_function(source):
    start = "___SCMOBJ ___vm_resize_pstate\n"
    end = "\n\nvoid execute_sync_op\n"
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("source function boundaries changed; audit required")
    begin = source.index(start)
    finish = source.index(end, begin)
    return source[begin:finish] + "\n"


def shutdown_function(source):
    start = "void execute_sync_op_loop\n   ___P((___PSD\n         ___sync_op_struct *sop_ptr,\n         ___BOOL first_iter),\n        (___PSV\n"
    end = "\n\nvoid service_sync_op\n"
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("shutdown source function boundaries changed")
    begin = source.index(start)
    finish = source.index(end, begin)
    return source[begin:finish] + "\n"


def mark_function(source):
    start = "#ifdef ENABLE_CONSISTENCY_CHECKS\n\n#define mark_array(start,n) mark_array_debug (start,n,__LINE__)\n"
    end = "\n\n___HIDDEN void mark_captured_continuation\n"
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("mark-array source function boundaries changed")
    begin, finish = source.index(start), source.index(end)
    if finish <= begin:
        raise ValueError("mark-array source boundaries out of order")
    return source[begin:finish] + "\n"


def mark_expected(scenario):
    outcomes = (
        dict(sameReference=1, destinationForwarded=0, allocatedWords=8, selfRelocated=0),
        dict(sameReference=0, destinationForwarded=1, allocatedWords=16, selfRelocated=0),
        dict(sameReference=0, destinationForwarded=0, allocatedWords=0, selfRelocated=0),
        dict(sameReference=0, destinationForwarded=0, allocatedWords=3, selfRelocated=1),
        dict(sameReference=0, destinationForwarded=1, allocatedWords=16, selfRelocated=0))
    if scenario not in range(len(outcomes)):
        raise ValueError("unknown mark-array source-unit control")
    return outcomes[scenario]


def mark_representation(macros):
    values = {}
    for line in macros.splitlines():
        if line.startswith("#define "):
            row = line[8:].split(" ", 1)
            values[row[0]] = re.sub(r"\s+", "", row[1]) if len(row) == 2 else ""
    expected = {"___WORD_WIDTH": "64", "___WS": "8", "___TB": "3", "___LWS": "3",
        "___HTB": "3", "___SB": "5", "___LF": "(___HTB+___SB)",
        "___REFERENCE_TO_BODY": "1", "___MOVABLE0": "0", "___FORW": "3", "___STILL": "5",
        "___PERM": "6", "___sWEAK": "13", "___sBOXVALUES": "5",
        "___MEM_ALLOCATED(obj)": "((obj)&1)", "___TAG(ptr,tag)": "(___CAST(___WORD,ptr)+(tag))",
        "___UNTAG(obj)": "___CAST(___WORD*,(obj)&~___TMASK)",
        "___UNTAG_AS(obj,tag)": "___CAST(___WORD*,(obj)-(tag))",
        "___BODY0(obj)": "(___UNTAG(obj)+___REFERENCE_TO_BODY)",
        "___HD_TYP(head)": "((head)&___HTMASK)",
        "___HD_SUBTYPE(head)": "((head)>>___HTB&((1<<___SB)-1))",
        "___HD_WORDS(head)": "(((___CAST(___UWORD,head)+((___WS-1)<<___LF)))>>(___LF+___LWS))",
        "___TESTTYPE(x,typ)": "___TESTMASK(x,___TMASK,typ)",
        "___TESTMASK(x,mask,val)": "(((___CAST_U32(x)-(val))&(mask))==0)"}
    if "___USE_HANDLES" in values or "___SUPPORT_LOWLEVEL_EXEC" in values:
        raise ValueError("mock representation excludes handles and low-level execution")
    for name, value in expected.items():
        if values.get(name) != value:
            raise ValueError("mark-array mock representation differs: " + name)
    return expected


def mark_unit(args, compiler, environment, version):
    source = args.mem_source.resolve()
    source_hash = digest(source)
    header_hash = digest(args.runtime_header)
    function = mark_function(source.read_text())
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    include = out / "mark-source.inc"
    include.write_text(function)
    fixture = ROOT / "models/gambit/native/mark_array_slot_ownership.c"
    shutil.copyfile(fixture, out / fixture.name)
    receipt = {"schema": "gambit-mark-source-unit.v1", "diagnosticOnly": True,
        "scope": "unchanged mark_array with mocked representation, heap and CAS; duplicate root visitation is an injected input schedule, not proved reachable in native GC",
        "sourceSha256": source_hash, "fixtureSha256": digest(fixture),
        "functionSha256": digest(include), "compiler": version.splitlines()[0], "results": []}
    code, log, timeout, seconds = execute([compiler, "-E", "-dM", "-DHAVE_CONFIG_H",
        "-D___LIBRARY", "-I", str(args.runtime_header.resolve().parent),
        "-include", str(args.runtime_header.resolve()), "-x", "c", "/dev/null"], out, 10, env=environment)
    (out / "representation.log").write_text(log)
    receipt["representation"] = dict(exit=code, timeout=timeout, seconds=seconds, headerSha256=header_hash)
    if code != 0 or timeout:
        receipt["status"] = "DENY"
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        return 1
    try:
        receipt["representation"]["selectedMacros"] = mark_representation(log)
    except ValueError as error:
        receipt["status"] = "DENY"
        receipt["representation"]["error"] = str(error)
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        return 1
    code, log, timeout, seconds = execute([compiler, "-std=c11", "-O1", "-Wall", "-Wextra", "-Werror",
        str(out / fixture.name), "-o", str(out / "mark-unit")], out, 30, env=environment)
    (out / "compile.log").write_text(log)
    receipt["compile"] = dict(exit=code, timeout=timeout, seconds=seconds)
    if code == 0 and not timeout:
        for scenario in range(5):
            code, log, timeout, seconds = execute([str(out / "mark-unit"), str(scenario)], out, 5, env=environment)
            (out / f"scenario-{scenario}.log").write_text(log)
            try:
                state = json.loads(log)
            except ValueError:
                state = None
            receipt["results"].append(dict(scenario=scenario, expected=mark_expected(scenario), state=state,
                accepted=code == 0 and not timeout and state == mark_expected(scenario),
                exit=code, timeout=timeout, seconds=seconds))
    receipt["sourceStable"] = source_hash == digest(source) and header_hash == digest(args.runtime_header)
    receipt["status"] = "source-unit-pass" if receipt["sourceStable"] and len(receipt["results"]) == 5 and all(
        row["accepted"] for row in receipt["results"]) else "DENY"
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("MARK-SOURCE-UNIT: " + receipt["status"])
    return 0 if receipt["status"] == "source-unit-pass" else 1


def shutdown_variants(function):
    guard = "if (id == 0 && ___err != ___FIX(___NO_ERR))"
    if function.count(guard) != 1:
        raise ValueError("shutdown source condition changed; audit required")
    return {"baseline": function,
            "pr793": function.replace(guard, guard[:-1] + " && ___GSTATE->setup_state != 2)"),
            "catcher-only": function.replace(guard, guard[:-1] + " && ___ps->catcher != NULL)")}


def shutdown_expected(variant, scenario):
    if variant not in ("baseline", "pr793", "catcher-only") or scenario not in range(8):
        raise ValueError("unknown shutdown source-unit control")
    throwing = scenario in (0, 1, 2, 5, 7)
    if variant == "pr793" and scenario == 1:
        throwing = False
    if variant == "catcher-only" and scenario in (1, 2):
        throwing = False
    return dict(rounds=3 if scenario == 7 else 2, executions=int(scenario == 6),
                throws=int(throwing), invalid=int(throwing and scenario in (1, 2)),
                error=42 if throwing else 0, interrupt=int(scenario == 5))


def shutdown_unit(args, compiler, environment, version):
    source = args.setup_source.resolve()
    source_hash = digest(source)
    function = shutdown_function(source.read_text())
    args.out.mkdir(parents=True, exist_ok=False)
    fixture = ROOT / "models/gambit/native/shutdown_error_handoff.c"
    receipt = {"schema": "gambit-shutdown-source-unit.v1", "diagnosticOnly": True,
               "scope": "unchanged sync loop with mocked barriers and throws; scenario 2 is conditional pre-cleanup reachability, not a native reproduction",
               "sourceSha256": source_hash, "fixtureSha256": digest(fixture),
               "compiler": version.splitlines()[0], "results": []}
    for variant, text in shutdown_variants(function).items():
        out = args.out.resolve() / variant
        out.mkdir()
        include = out / "sync-source.inc"
        include.write_text(text)
        shutil.copyfile(fixture, out / fixture.name)
        code, log, timeout, seconds = execute([compiler, "-std=c11", "-O1", "-Wall", "-Wextra", "-Werror",
            str(out / fixture.name), "-o", str(out / "shutdown-unit")], out, 30, env=environment)
        (out / "compile.log").write_text(log)
        row = {"variant": variant, "functionSha256": digest(include),
               "compile": dict(exit=code, timeout=timeout, seconds=seconds), "runs": []}
        if code == 0 and not timeout:
            for scenario in range(8):
                code, log, timeout, seconds = execute([str(out / "shutdown-unit"), str(scenario)], out, 5, env=environment)
                (out / f"scenario-{scenario}.log").write_text(log)
                try:
                    state = json.loads(log)
                except ValueError:
                    state = None
                expected = shutdown_expected(variant, scenario)
                row["runs"].append(dict(scenario=scenario, accepted=code == 0 and not timeout and state == expected,
                    expected=expected, state=state, exit=code, timeout=timeout, seconds=seconds))
        receipt["results"].append(row)
    receipt["sourceStable"] = source_hash == digest(source)
    receipt["status"] = "source-unit-pass" if receipt["sourceStable"] and all(
        len(row["runs"]) == 8 and all(run["accepted"] for run in row["runs"]) for row in receipt["results"]) else "DENY"
    (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"SHUTDOWN-SOURCE-UNIT: {receipt['status']}")
    return 0 if receipt["status"] == "source-unit-pass" else 1


def checked_negate_unit(args, compiler, environment, version):
    source = args.runtime_header.resolve()
    if source.name != "gambit.h":
        raise ValueError("checked-negation source unit requires the actual gambit.h")
    sources = {p.relative_to(source.parent).as_posix(): digest(p)
               for p in source.parent.rglob("*") if p.is_file()}
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    header_root = out / "source"
    header_root.mkdir()
    shutil.copytree(source.parent, header_root / "include")
    receipt = {"schema": "gambit-checked-negate-source-unit.v1", "diagnosticOnly": True,
               "scope": "actual selected header macros, eighteen boundary/alias cases; not native VM acceptance",
               "sourceHeaderSha256": digest(source), "headerFiles": sources,
               "compiler": version.splitlines()[0], "status": "RUNNING"}
    if args.patch:
        from gambit_smp.check_gambit import MODELS, reuse_model_receipt
        case = next(case for case in json.loads((MODELS / "cases.json").read_text())["cases"]
                    if case["id"] == "checked_negate_return")
        reuse_model_receipt(args.model_receipt, case)
        expected_hash = checked_negate_header_hash(source.read_bytes())
        receipt["patchedFiles"] = apply_untracked_patch(header_root, args.patch.read_bytes(), {"include/gambit.h"})
        if receipt["patchedFiles"]["include/gambit.h"] != expected_hash:
            raise ValueError("checked-negation patch changes more than the audited branch")
        receipt.update(patchSha256=digest(args.patch), modelReceiptSha256=digest(args.model_receipt))
    fixture = ROOT / "models/gambit/native/checked_negate_return.c"
    shutil.copyfile(fixture, out / fixture.name)
    receipt["fixtureSha256"] = digest(fixture)
    receipt["compileFlags"] = ["-O1", "-fwrapv", "-DHAVE_CONFIG_H"]
    code, log, timed_out, seconds = execute([compiler, *receipt["compileFlags"],
        "-I", str(header_root / "include"), str(out / fixture.name),
        "-o", str(out / "checked-negate-unit")], out, 30, env=environment)
    (out / "compile.log").write_text(log)
    receipt["compile"] = dict(exit=code, timeout=timed_out, seconds=round(seconds, 3))
    accepted = False
    if code == 0 and not timed_out:
        code, log, timed_out, seconds = execute([str(out / "checked-negate-unit")], out, 5, env=environment)
        (out / "run.log").write_text(log)
        accepted = code == 0 and not timed_out and log.splitlines().count("CHECKED-NEGATE-OK 18 CASES") == 1
        receipt["run"] = dict(exit=code, timeout=timed_out, seconds=round(seconds, 3), accepted=accepted)
    stable = all((source.parent / name).is_file() and digest(source.parent / name) == sha for name, sha in sources.items())
    expected_headers = dict(sources)
    if args.patch:
        expected_headers["gambit.h"] = receipt["patchedFiles"]["include/gambit.h"]
    stable = stable and all((header_root / "include" / name).is_file()
                           and digest(header_root / "include" / name) == sha for name, sha in expected_headers.items())
    stable = stable and digest(fixture) == receipt["fixtureSha256"]
    receipt.update(sourceStable=stable, status="source-unit-pass" if accepted and stable else "DENY")
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("CHECKED-NEGATE-SOURCE-" + ("PASS" if accepted and stable else "DENY"))
    return 0 if accepted and stable else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--setup-source", type=Path)
    parser.add_argument("--source-lock")
    parser.add_argument("--native-runtime-root", type=Path,
                        help="optional exact source031 configured headers for actual activity-log object compilation")
    parser.add_argument("--mem-source", type=Path)
    parser.add_argument("--runtime-header", type=Path)
    parser.add_argument("--gcc", type=Path, required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--case", choices=("vm_activity_log_abort", "vm_resize_rollback", "shutdown_error_handoff", "mark_array_slot_ownership", "checked_negate_return", "sync_resource_retirement", "continuation_chunk_frontier", "pstate_os_mem_transaction", "pstate_setup_transaction"), default="vm_resize_rollback")
    parser.add_argument("--patch", type=Path)
    parser.add_argument("--model-receipt", type=Path)
    parser.add_argument("--candidate-receipt", type=Path)
    args = parser.parse_args()
    if args.case == "vm_activity_log_abort":
        if not args.source_lock or not args.model_receipt:
            parser.error("activity log abort requires source lock and complete model receipt")
        compiler, environment, version = gnu_compiler(args.gcc)
        return vm_actlog_abort_unit(args, compiler, environment, version)
    if args.case == "mark_array_slot_ownership" and not all((args.mem_source, args.runtime_header)):
        parser.error("mark-array source-unit requires --mem-source and --runtime-header")
    if args.case == "checked_negate_return" and not args.runtime_header:
        parser.error("checked-negation source-unit requires --runtime-header")
    if args.patch and (args.case != "checked_negate_return" or not args.model_receipt):
        parser.error("header patch requires checked-negation case and model receipt")
    if args.model_receipt and not args.patch and args.case not in ("sync_resource_retirement", "continuation_chunk_frontier", "pstate_os_mem_transaction", "pstate_setup_transaction"):
        parser.error("model receipt requires an explicit header patch")
    if args.case == "sync_resource_retirement" and not args.model_receipt:
        parser.error("sync resource source observation requires admitted model receipt")
    if args.case == "pstate_os_mem_transaction" and not args.model_receipt:
        parser.error("OS/memory source observation requires a complete setup protocol receipt")
    if args.case == "pstate_setup_transaction" and not all((args.model_receipt, args.candidate_receipt)):
        parser.error("candidate setup source unit requires model and candidate receipts")
    if args.candidate_receipt and args.case != "pstate_setup_transaction":
        parser.error("candidate receipt is only used by the candidate setup source unit")
    if args.case == "continuation_chunk_frontier" and not all((args.mem_source, args.model_receipt)):
        parser.error("continuation chunk observation requires --mem-source and admitted --model-receipt")
    if args.case not in ("mark_array_slot_ownership", "checked_negate_return", "continuation_chunk_frontier") and not args.setup_source:
        parser.error("resize/shutdown source-unit requires --setup-source")
    compiler, environment, version = gnu_compiler(args.gcc)
    if args.case == "pstate_setup_transaction":
        return pstate_setup_unit(args, compiler, environment, version)
    if args.case == "pstate_os_mem_transaction":
        return pstate_os_mem_unit(args, compiler, environment, version)
    if args.case == "continuation_chunk_frontier":
        return continuation_chunk_unit(args, compiler, environment, version)
    if args.case == "sync_resource_retirement":
        return sync_resource_unit(args, compiler, environment, version)
    if args.case == "checked_negate_return":
        return checked_negate_unit(args, compiler, environment, version)
    if args.case == "mark_array_slot_ownership":
        return mark_unit(args, compiler, environment, version)
    if args.case == "shutdown_error_handoff":
        return shutdown_unit(args, compiler, environment, version)
    source = args.setup_source.resolve()
    function = resize_function(source.read_text())
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    (out / "resize-source.inc").write_text(function)
    fixture = ROOT / "models/gambit/native/vm_resize_rollback.c"
    shutil.copyfile(fixture, out / fixture.name)
    receipt = {"schema": "gambit-source-unit.v1", "diagnosticOnly": True,
               "scope": "VM resize function with deterministic mocked dependencies; not real GC or OS threads",
               "sourceSha256": digest(source), "fixtureSha256": digest(fixture),
               "functionSha256": digest(out / "resize-source.inc"),
               "compiler": version.splitlines()[0], "results": []}
    code, log, timeout, seconds = execute(
        [compiler, "-std=c11", "-O1", "-Wall", "-Wextra", "-Werror", str(out / fixture.name),
         "-o", str(out / "resize-unit")], out, 30, env=environment)
    (out / "compile.log").write_text(log)
    receipt["compile"] = dict(exit=code, timeout=timeout, seconds=seconds)
    if code == 0 and not timeout:
        for failure in (0, 1, 2, 3):
            code, log, timeout, seconds = execute([str(out / "resize-unit"), str(failure)], out, 5, env=environment)
            (out / (f"setup-failure-{failure}.log")).write_text(log)
            summary = re.search(r"RESULT (-?\d+) PREPARED (\d+) ACTIVE (\d+) TARGET (\d+) INVALID (\d+)", log)
            accepted = code == 0 and not timeout and log.splitlines().count("SOURCE-UNIT-OK") == 1
            receipt["results"].append(dict(failureProcessor=failure, accepted=accepted,
                exit=code, timeout=timeout, seconds=seconds,
                state=dict(zip(("result", "preparedMask", "active", "target", "invalidCleanup"),
                               map(int, summary.groups()))) if summary else None))
    receipt["status"] = "source-unit-pass" if len(receipt["results"]) == 4 and all(
        row["accepted"] for row in receipt["results"]) else "DENY"
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt, indent=2))
    return 0 if receipt["status"] == "source-unit-pass" else 1


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('source-unit')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('source-unit', main))
