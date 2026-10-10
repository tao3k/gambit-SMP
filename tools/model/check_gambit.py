#!/usr/bin/env python3
"""Check finite SMP models; run native regressions only on explicit admission."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time
from source_binding import stack_markers, sync_messages, sync_protocol, heap_headroom

ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / "models/gambit"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def execute(argv, cwd, timeout):
    start = time.monotonic()
    process = subprocess.Popen(
        argv, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, start_new_session=True,
    )
    timed_out = False
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        os.killpg(process.pid, signal.SIGKILL)
        output, _ = process.communicate()
    return process.returncode, output, timed_out, time.monotonic() - start


def admitted_model(code, output, timed_out, old):
    if timed_out:
        return False
    if old:
        return code != 0 and "Error: Invariant q_inv is violated." in output
    return all((
        code == 0,
        "Model checking completed. No error has been found." in output,
        re.search(r"\b0 states left on queue\.", output) is not None,
    ))


def counterexample(output):
    """Decode only the Boolean/integer TLC state format used by these models."""
    states = []
    for block in re.findall(r"^State \d+:.*\n((?:/\\ .*\n)+)", output, re.MULTILINE):
        state = {}
        for line in block.splitlines():
            match = re.fullmatch(r"/\\ (\w+) = (TRUE|FALSE|-?\d+)", line)
            if not match:
                raise ValueError("unsupported TLC counterexample value")
            name, value = match.groups()
            state[name] = (value == "TRUE") if value in ("TRUE", "FALSE") else int(value)
        states.append(state)
    if len(states) < 2 or any(set(s) != set(states[0]) for s in states):
        raise ValueError("missing or inconsistent TLC states")
    return {"schema": "gambit-smp-counterexample.v1", "states": states}


def native_identity(gsi, receipt, case=None, gsc=None):
    identity = json.loads(receipt.read_text())
    if identity.get("sourceRevision") != json.loads((MODELS / "cases.json").read_text())["sourceRevision"]:
        raise ValueError("native source revision does not match the model evidence")
    if identity.get("binarySha256") != digest(gsi):
        raise ValueError("native binary digest mismatch")
    if identity.get("multipleThreadedVms") is not True:
        raise ValueError("native receipt must attest multipleThreadedVms=true")
    if not isinstance(identity.get("patches"), list):
        raise ValueError("native receipt must list applied patch identities")
    if case is not None and case.get("id", case["pr"]) not in identity.get("modeledCases", []):
        raise ValueError("native receipt does not attest this modeled repair; baseline rerun denied")
    if gsc is not None and identity.get("gscSha256") != digest(gsc):
        raise ValueError("native compiler digest mismatch")
    return identity


def model_checks(case):
    if case.get("mode") == "characterization":
        return [("protocol", inv, "init") for inv in case["invariants"]]
    return [("old", inv, case.get("oldInitializers", {}).get(inv, "initOld"))
            for inv in case.get("oldInvariants", ["safe"])] + [("fixed", "safe", "initFixed")]


def reuse_model_receipt(path, case):
    receipt = json.loads(path.read_text())
    rows = [r for r in receipt["results"] if r["case"] == case["id"]]
    model_hash = digest(MODELS / (case["id"] + ".qnt"))
    checks = model_checks(case)
    expected = {(variant, inv) for variant, inv, _ in checks}
    initializers = {(variant, inv): init for variant, inv, init in checks}
    observed = {(r["variant"], r.get("invariant", "safe")) for r in rows}
    initializers_match = all(
        r.get("initializer", "initOld" if r["variant"] == "old" else "initFixed")
        == initializers.get((r["variant"], r.get("invariant", "safe"))) for r in rows)
    if not (len(rows) == len(expected) and observed == expected
            and initializers_match
            and all(r["accepted"] and r["evidence"] == "finite-state-TLC"
                    and r["modelSha256"] == model_hash for r in rows)):
        raise ValueError("model receipt is missing admission or belongs to another model")
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--case", choices=[c["id"] for c in json.loads((MODELS / "cases.json").read_text())["cases"]])
    parser.add_argument("--quint", default="quint")
    parser.add_argument("--timeout", type=float, default=90)
    parser.add_argument("--native-gsi", type=Path)
    parser.add_argument("--native-gsc", type=Path)
    parser.add_argument("--runtime-root", type=Path)
    parser.add_argument("--processors", type=int, choices=(1, 2, 4), default=4)
    parser.add_argument("--model-receipt", type=Path)
    parser.add_argument("--source-model-receipt", type=Path,
                        help="TLC admission for the stack lifecycle/source binding")
    parser.add_argument("--rehash-model-receipt", type=Path,
                        help="TLC admission for all three rehash protocol failures")
    parser.add_argument("--sync-model-receipt", type=Path,
                        help="TLC admission for paired message publication/receive fences")
    parser.add_argument("--headroom-model-receipt", type=Path,
                        help="TLC admission for reserve and next-section headroom")
    parser.add_argument("--toolchain-receipt", type=Path)
    parser.add_argument("--sync-source", type=Path,
                        help="bind the wait-handshake model to audited setup.c")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("timeout must be positive")
    if bool(args.native_gsi) != bool(args.toolchain_receipt):
        parser.error("native gsi and its toolchain receipt must be supplied together")
    if args.native_gsc and not args.native_gsi:
        parser.error("native compiler requires the interpreter and receipt")
    if args.runtime_root and not args.native_gsi:
        parser.error("runtime root is only meaningful with an explicit native toolchain")
    if args.model_receipt and not args.case:
        parser.error("reusing model evidence requires one explicit case")
    if args.sync_source and args.case != "sync_wait_handshake":
        parser.error("sync source binding currently covers sync_wait_handshake only")
    if args.native_gsi and not args.case:
        parser.error("native tests require an explicit --case; no blanket rerun")
    args.out.mkdir(parents=True, exist_ok=False)
    manifest = json.loads((MODELS / "cases.json").read_text())
    version = subprocess.check_output([args.quint, "--version"], text=True).strip()
    if version != manifest["quintVersion"]:
        parser.error(f"expected Quint {manifest['quintVersion']}, got {version}")
    receipt = {"schema": "gambit-smp-model-receipt.v1", "quintVersion": version,
               "manifestSha256": digest(MODELS / "cases.json"), "results": [],
               "native": {"status": "not-run"}, "unresolved": manifest["unresolved"]}
    ok = True
    if args.sync_source:
        receipt["sourceBinding"] = sync_protocol(args.sync_source.read_text())
        receipt["sourceBinding"]["setupCSha256"] = digest(args.sync_source)
    for case in manifest["cases"]:
        if args.case and case["id"] != args.case:
            continue
        if args.model_receipt:
            try:
                receipt["results"].extend(reuse_model_receipt(args.model_receipt, case))
                receipt["reusedModelReceiptSha256"] = digest(args.model_receipt)
            except (ValueError, KeyError, OSError) as error:
                receipt["modelError"] = str(error)
                ok = False
            continue
        model = MODELS / (case["id"] + ".qnt")
        for variant, invariant, initializer in model_checks(case):
            old = variant == "old"
            name = f"{case['id']}-{variant}" + ("-" + invariant if invariant != "safe" else "")
            code, output, timed_out, seconds = execute(
                [args.quint, "verify", str(model), "--init", initializer,
                 "--invariant", invariant, "--backend", "tlc"],
                args.out.resolve(), args.timeout,
            )
            (args.out / (name + ".log")).write_text(output)
            accepted = admitted_model(code, output, timed_out, old)
            if old:
                try:
                    trace = counterexample(output)
                    trace.update({"case": case["id"], "invariant": invariant, "modelSha256": digest(model)})
                    (args.out / (name + ".trace.json")).write_text(json.dumps(trace, indent=2) + "\n")
                except ValueError:
                    accepted = False
            receipt["results"].append({"case": case["id"], "variant": variant,
                "invariant": invariant,
                "initializer": initializer,
                "modelSha256": digest(model), "accepted": accepted, "exit": code,
                "timeout": timed_out, "seconds": round(seconds, 3),
                "evidence": "finite-state-TLC", "log": name + ".log"})
            ok = ok and accepted
            print(f"{name}: {'OK' if accepted else 'DENY'} ({seconds:.3f}s)", flush=True)
    if args.native_gsi and ok:
        case = next(c for c in manifest["cases"] if c["id"] == args.case)
        try:
            identity = native_identity(args.native_gsi.resolve(), args.toolchain_receipt, case,
                                       args.native_gsc.resolve() if args.native_gsc else None)
            if "heap_allocation_headroom" in identity.get("modeledCases", []):
                if args.headroom_model_receipt is None or args.runtime_root is None:
                    raise ValueError("headroom candidate requires TLC admission and audited source")
                model = next(c for c in manifest["cases"] if c["id"] == "heap_allocation_headroom")
                reuse_model_receipt(args.headroom_model_receipt, model)
                source = args.runtime_root / "lib/mem.c"
                if identity.get("sourceFiles", {}).get("lib/mem.c") != digest(source):
                    raise ValueError("headroom source digest mismatch")
                receipt["headroomSourceBinding"] = heap_headroom(source.read_text())
                receipt["headroomModelReceiptSha256"] = digest(args.headroom_model_receipt)
            if "sync_message_acquire" in identity.get("modeledCases", []):
                if args.sync_model_receipt is None or args.runtime_root is None:
                    raise ValueError("sync-message candidate requires TLC admission and audited source")
                sync = next(c for c in manifest["cases"] if c["id"] == "sync_message_acquire")
                reuse_model_receipt(args.sync_model_receipt, sync)
                receipt["syncModelReceiptSha256"] = digest(args.sync_model_receipt)
                source = args.runtime_root / "lib/setup.c"
                if identity.get("sourceFiles", {}).get("lib/setup.c") != digest(source):
                    raise ValueError("sync-message source digest mismatch")
                receipt["syncSourceBinding"] = sync_messages(source.read_text())
            if "gc_rehash_protocol" in identity.get("modeledCases", []):
                if args.rehash_model_receipt is None:
                    raise ValueError("rehash candidate requires full protocol TLC admission")
                protocol = next(c for c in manifest["cases"] if c["id"] == "gc_rehash_protocol")
                reuse_model_receipt(args.rehash_model_receipt, protocol)
                receipt["rehashModelReceiptSha256"] = digest(args.rehash_model_receipt)
                if args.runtime_root is None:
                    raise ValueError("rehash candidate requires its audited source tree")
                for filename in ("lib/mem.c", "lib/_system.scm", "lib/_system.c"):
                    if identity.get("sourceFiles", {}).get(filename) != digest(args.runtime_root / filename):
                        raise ValueError("rehash source digest mismatch: " + filename)
            if "gc_stack_marker" in identity.get("modeledCases", []):
                if args.source_model_receipt is None:
                    raise ValueError("stack-marker candidate requires lifecycle TLC admission")
                lifecycle = next(c for c in manifest["cases"] if c["id"] == "gc_stack_lifecycle")
                reuse_model_receipt(args.source_model_receipt, lifecycle)
                receipt["sourceModelReceiptSha256"] = digest(args.source_model_receipt)
                if args.runtime_root is None:
                    raise ValueError("stack-marker candidate requires its audited source tree")
                source = args.runtime_root / "lib/mem.c"
                if identity.get("sourceFiles", {}).get("lib/mem.c") != digest(source):
                    raise ValueError("stack-marker source digest mismatch")
                receipt["sourceBinding"] = stack_markers(source.read_text())
            if case["native"] is None:
                raise ValueError("native C/FFI adapter not implemented for this case")
            script = MODELS / "native" / case["native"]
            runtime_option = f"-:p{args.processors}"
            if args.runtime_root:
                runtime = args.runtime_root.resolve()
                if not all((runtime / directory).is_dir() for directory in ("lib", "bin", "include")):
                    raise ValueError("runtime root must contain lib, bin, and include")
                runtime_option += f",~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
            code, output, timed_out, seconds = execute(
                [str(args.native_gsi.resolve()), runtime_option, str(script)], args.out.resolve(), args.timeout)
            (args.out / "native.log").write_text(output)
            accepted = code == 0 and not timed_out and f"NATIVE-OK:{args.case}" in output.splitlines()
            receipt["native"] = {"status": "passed" if accepted else "denied", "exit": code,
                "timeout": timed_out, "seconds": round(seconds, 3),
                "processors": args.processors,
                "scriptSha256": digest(script), "toolchain": identity}
            ok = ok and accepted
            if accepted and args.native_gsc:
                executable = (args.out / "native-regression").resolve()
                code, output, timed_out, seconds = execute(
                    [str(args.native_gsc.resolve()), runtime_option, "-exe", "-o", str(executable), str(script)],
                    args.out.resolve(), args.timeout)
                (args.out / "native-compile.log").write_text(output)
                compiled = code == 0 and not timed_out and executable.is_file()
                receipt["native"]["compile"] = {"accepted": compiled, "exit": code,
                    "timeout": timed_out, "seconds": round(seconds, 3)}
                if compiled:
                    code, output, timed_out, seconds = execute(
                        [str(executable), runtime_option], args.out.resolve(), args.timeout)
                    (args.out / "native-compiled-test.log").write_text(output)
                    compiled = code == 0 and not timed_out and f"NATIVE-OK:{args.case}" in output.splitlines()
                    receipt["native"]["compiledTest"] = {"accepted": compiled, "exit": code,
                        "timeout": timed_out, "seconds": round(seconds, 3)}
                ok = ok and compiled
                receipt["native"]["status"] = "passed" if ok else "denied"
            elif accepted:
                receipt["native"]["compiledTest"] = {"status": "not-run"}
        except (ValueError, OSError) as error:
            receipt["native"] = {"status": "denied", "error": str(error)}
            ok = False
    (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
