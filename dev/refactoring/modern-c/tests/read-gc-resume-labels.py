"""Reduce DEV C-return to first executed benchmark host-label samples."""
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import sys
import subprocess


def host_symbols(executable: Path) -> dict[int, str]:
    symbols = {}
    image = None
    for line in subprocess.check_output(["nm", "-an", str(executable)], text=True).splitlines():
        parts = line.split()
        if len(parts) != 3 or parts[1].lower() != "t":
            continue
        address, _, name = parts
        offset = int(address, 16)
        symbols[offset] = name
        if name == "__mh_execute_header":
            image = offset
    if image is None:
        raise ValueError("Mach-O executable image symbol missing")
    return {address - image: name for address, name in symbols.items()}


def read_labels(path: Path, symbols: dict[int, str] | None = None) -> dict:
    trace = path.read_bytes()
    lines = trace.decode().splitlines()
    if not lines or lines[-1] != "trace-invalid=0":
        raise ValueError("Missing complete pause trace")
    pending = {}
    results = defaultdict(list)
    threads = {}
    superseded = defaultdict(int)
    superseded_after_handoff = defaultdict(int)
    targets = defaultdict(list)
    entered = {}
    target_coverage = defaultdict(lambda: defaultdict(int))
    matched = defaultdict(list)
    handoff_times = defaultdict(list)
    handoff_matched = defaultdict(list)
    op_ready = {}
    op_entered = {}
    transfer_arrived = {}
    first_ops = defaultdict(list)
    transfers = {}
    transfer_results = defaultdict(lambda: defaultdict(int))
    op_kinds = {}
    first_kind_counts = defaultdict(lambda: defaultdict(int))
    hosts = {}
    mismatch_hosts = defaultdict(int)
    operation_sites = {}
    incomplete_operations = []
    completed_sites = defaultdict(lambda: defaultdict(int))
    image = next((int(line.split("=", 1)[1]) for line in lines if line.startswith("image-base=")), None)
    if symbols is not None and image is None:
        raise ValueError("Host symbol lookup requires the recorded image base")
    def record_incomplete(key, reason):
        if key in op_kinds:
            site = operation_sites.get(key, {})
            incomplete_operations.append(dict(
                carrier=key[0], kind=op_kinds.pop(key), reason=reason, **site,
            ))
        operation_sites.pop(key, None)

    for line in lines[:-1]:
        if line.startswith("image-base="):
            continue
        carrier, vm, kind, value = line.split()
        key = (carrier, vm)
        stamp = int(value)
        if kind == "T":
            threads[carrier] = stamp
        elif kind in ("U", "M"):
            if key in pending:
                superseded[carrier] += 1
                if targets.get(key):
                    superseded_after_handoff[carrier] += 1
            pending[key] = stamp
            op_ready.pop(key, None)
            record_incomplete(key, "transfer-superseded" if key in transfers else "no-completion-before-sync")
            if key in op_entered:
                if key not in transfers:
                    raise ValueError(f"First operation did not return before the next synchronization: {line}")
                op_entered.pop(key)
                transfers.pop(key)
                transfer_results[carrier]["superseded"] += 1
            targets.pop(key, None)
            entered.pop(key, None)
            hosts.pop(key, None)
            handoff_times.pop(key, None)
        elif kind == "J":
            handoff_times[key].append(stamp)
        elif kind == "P":
            hosts.setdefault(key, []).append(stamp)
        elif kind == "H":
            targets[key].append(stamp)
        elif kind == "D":
            entered[key] = stamp
        elif kind == "Y":
            if key not in op_ready or key in op_kinds:
                raise ValueError(f"First-operation category without an exact target: {line}")
            op_kinds[key] = stamp
            first_kind_counts[carrier][stamp] += 1
        elif kind == "F":
            if key not in op_ready or key in op_entered:
                raise ValueError(f"First operation without a matched target: {line}")
            resume, jump, label = op_ready.pop(key)
            if not resume <= jump <= label <= stamp:
                raise ValueError(f"Inverted first-operation start: {line}")
            op_entered[key] = resume, jump, stamp
        elif kind == "V":
            if key not in op_entered or key in transfers:
                raise ValueError(f"Transfer without a unique operation start: {line}")
            transfers[key] = stamp
        elif kind == "X":
            if key not in transfers:
                raise ValueError(f"Transfer arrival without an expected target: {line}")
            target = transfers.pop(key)
            if not stamp or stamp != target:
                op_entered.pop(key)
                record_incomplete(key, "different-or-unindexed-target")
                transfer_results[carrier]["different-or-unindexed-target"] += 1
            else:
                transfer_results[carrier]["same-target"] += 1
                transfer_arrived[key] = target
        elif kind == "G":
            if key not in op_entered:
                raise ValueError(f"First-operation end without start: {line}")
            resume, jump, start = op_entered.pop(key)
            if start > stamp:
                raise ValueError(f"Inverted first-operation completion: {line}")
            operation = dict(vm=vm, resumeNs=resume, completionNs=stamp,
                             syncToEndNs=stamp-resume, jumpToEndNs=stamp-jump,
                             operationBracketNs=stamp-start, kind=op_kinds.pop(key, None))
            if operation["kind"] == 7:
                operation["pollEdge"] = "slow-handler-entry" if key in transfer_arrived else "fallthrough"
            site = operation_sites.pop(key, None)
            if site is not None:
                completed_sites[site["host"]][site["targetImageOffset"]] += 1
                operation.update(site)
                target = transfer_arrived.get(key, 0)
                if target > 1:
                    operation["transferTargetImageOffset"] = target - image
            transfer_arrived.pop(key, None)
            first_ops[carrier].append(operation)
        elif kind == "L":
            if key not in pending or pending[key] > stamp:
                raise ValueError(f"Unmatched label observation: {line}")
            resume = pending.pop(key)
            results[carrier].append(stamp - resume)
            destination = entered.pop(key, None)
            requested = targets.pop(key, [])
            host = hosts.pop(key, [])
            jumps = handoff_times.pop(key, [])
            if destination is None:
                continue
            if len(requested) != 1:
                status = "missing-handoff" if not requested else "multiple-handoffs"
            elif not destination:
                status = "unindexed-host-label"
            elif requested[0] == destination:
                status = "same-label"
                matched[carrier].append(results[carrier][-1])
                if len(jumps) == 1:
                    if not 0 <= stamp - jumps[0] <= results[carrier][-1]:
                        raise ValueError(f"Out-of-order internal jump: {line}")
                    handoff_matched[carrier].append(stamp - jumps[0])
                    op_ready[key] = resume, jumps[0], stamp
                    if symbols is not None:
                        operation_sites[key] = dict(
                            targetImageOffset=destination - image,
                            host=symbols.get(host[0] - image, "unresolved") if len(host) == 1 else "unresolved",
                        )
            else:
                status = "different-label"
                if symbols is not None:
                    name = symbols.get(host[0] - image, "unresolved") if len(host) == 1 else "unresolved"
                    mismatch_hosts[name] += 1
            target_coverage[carrier][status] += 1
    for key in transfers:
        op_entered.pop(key)
        transfer_results[key[0]]["unobserved-at-exit"] += 1
        record_incomplete(key, "transfer-unobserved-at-exit")
    for key in list(op_kinds):
        record_incomplete(key, "no-completion-before-exit")
    if op_entered or transfer_arrived:
        raise ValueError("First-operation probe did not complete before trace exit")
    return dict(traceSha256=hashlib.sha256(trace).hexdigest(), threadIds=threads, byCarrierNs=dict(results), superseded=dict(superseded),
                unobservedAtExit=[carrier for carrier, _ in pending],
                targetCoverage={carrier: dict(counts) for carrier, counts in target_coverage.items()},
                matchedReturnToLabelNs=dict(matched), mismatchHosts=dict(mismatch_hosts),
                supersededAfterHandoff=dict(superseded_after_handoff),
                matchedHandoffToLabelNs=dict(handoff_matched),
                completedFirstOperations=dict(first_ops),
                firstOperationKinds={k: dict(v) for k, v in first_kind_counts.items()},
                incompleteOperations=incomplete_operations,
                completedSites={host: dict(counts) for host, counts in completed_sites.items()},
                transferResults={k: dict(v) for k, v in transfer_results.items()})


if __name__ == "__main__":
    symbols = host_symbols(Path(sys.argv[2])) if len(sys.argv) == 3 else None
    print(json.dumps(read_labels(Path(sys.argv[1]), symbols)))
