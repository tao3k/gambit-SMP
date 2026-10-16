#!/usr/bin/env python3
"""Whitelist a macOS incident into portable evidence; never infer a root cause."""
import argparse
import json
from pathlib import Path
import re
import subprocess

from gambit_smp.framework import digest


def incident(text):
    decoder = json.JSONDecoder()
    rows = []
    remaining = text.strip()
    while remaining:
        row, end = decoder.raw_decode(remaining)
        rows.append(row)
        remaining = remaining[end:].lstrip()
    if len(rows) != 2 or not all(isinstance(row, dict) for row in rows):
        raise ValueError("expected macOS metadata and incident objects")
    return rows[1]


def normalize(report, binary_uuid, pid=None):
    images = report["usedImages"]
    matches = [i for i, item in enumerate(images) if item["uuid"].lower() == binary_uuid.lower()]
    if len(matches) != 1:
        raise ValueError("incident does not bind one selected binary image")
    index = matches[0]
    if pid is not None and report["pid"] != pid:
        raise ValueError("incident PID differs from native child PID")
    fault = report["faultingThread"]
    threads = []
    for number, thread in enumerate(report["threads"]):
        state = thread.get("threadState", {})
        threads.append({"index": number, "faulting": number == fault,
            "frames": [{k: frame.get(k) for k in ("symbol", "symbolLocation", "imageIndex", "imageOffset")}
                       for frame in thread.get("frames", [])[:16]],
            "registers": {"x": [item["value"] for item in state.get("x", [])],
                          "pc": state.get("pc", {}).get("value"), "far": state.get("far", {}).get("value")}})
    return {"schema": "gambit-native-incident.v1", "diagnosticOnly": True,
            "scope": "selected binary image match; native-child attribution requires PID; no causal or source repair claim",
            "pid": report["pid"], "pidBoundToNativeReceipt": pid is not None,
            "captureTime": report["captureTime"], "exception": {k: report["exception"].get(k)
                for k in ("type", "signal", "subtype", "rawCodes")},
            "binaryImage": {"index": index, "uuid": binary_uuid.lower(), "size": images[index]["size"]},
            "threads": threads}


def compiler_child(receipt, identity):
    native = receipt["native"]
    compile_run = native["compile"]
    if native["toolchain"] != identity:
        raise ValueError("native receipt differs from selected candidate identity")
    if compile_run["accepted"] or compile_run["timeout"] or compile_run["exit"] >= 0:
        raise ValueError("incident binding requires a signaled, non-timeout compiler failure")
    pid = compile_run["process"]["pid"]
    if not isinstance(pid, int) or isinstance(pid, bool) or pid <= 0:
        raise ValueError("native compiler child PID is invalid")
    return pid


def binary_hash(identity, role):
    if role not in {"compiler", "interpreter"}:
        raise ValueError("compiler or interpreter binary role required")
    return identity["gscSha256" if role == "compiler" else "binarySha256"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--binary", type=Path, required=True)
    parser.add_argument("--identity", type=Path, required=True)
    parser.add_argument("--binary-role", choices=("compiler", "interpreter"), default="compiler")
    parser.add_argument("--pid", type=int)
    parser.add_argument("--native-receipt", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error("new evidence output required")
    identity = json.loads(args.identity.read_text())
    pid = None
    if args.native_receipt:
        if args.binary_role != "compiler":
            parser.error("compiler receipt cannot attribute an interpreter child PID")
        pid = compiler_child(json.loads(args.native_receipt.read_text()), identity)
        if args.pid is not None and args.pid != pid:
            raise ValueError("supplied PID differs from native compiler receipt")
    elif args.pid is not None:
        parser.error("--pid requires the actual --native-receipt")
    if digest(args.binary) != binary_hash(identity, args.binary_role):
        raise ValueError("selected binary identity mismatch")
    output = subprocess.check_output(["xcrun", "dwarfdump", "--uuid", str(args.binary)], text=True, timeout=30)
    uuids = re.findall(r"^UUID: ([0-9a-fA-F-]+) ", output, re.MULTILINE)
    if len(uuids) != 1:
        raise ValueError("exactly one Mach-O binary UUID required")
    result = normalize(incident(args.report.read_text()), uuids[0], pid)
    result.update(binarySha256=digest(args.binary), sourceReportSha256=digest(args.report),
                  candidateIdentitySha256=digest(args.identity), binaryRole=args.binary_role)
    if args.native_receipt:
        result["nativeReceiptSha256"] = digest(args.native_receipt)
        result["nativeStage"] = "compile"
    args.out.write_text(json.dumps(result, indent=2) + "\n")
    print("INCIDENT-IMAGE-BOUND; PID-BOUND=" + str(pid is not None))


if __name__ == "__main__":
    main()
