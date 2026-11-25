"""Reduce DEV-only rendezvous traces and retain excluded rounds."""
from bisect import bisect_right
from collections import defaultdict
import gzip
import hashlib
import json
from pathlib import Path
import sys


def summarize(path: Path) -> dict:
    lines = path.read_text().splitlines()
    if not lines or lines[-1] != "trace-invalid=0":
        raise ValueError("Missing terminal trace receipt or probe overflow")
    requests = defaultdict(list)
    groups = defaultdict(list)
    for line in lines[:-1]:
        processor, vm, event, timestamp = line.split()
        timestamp = int(timestamp)
        if event == "Q":
            requests[vm].append(timestamp)
        else:
            groups[vm, int(processor)].append((event, timestamp))

    if any(id not in (0, 1, 2) for _, id in groups):
        raise ValueError("Trace contains a processor outside the R=3 envelope")

    records = {}
    for key, events in groups.items():
        rounds = []
        pending = {}
        for event, t in events:
            if event == "A" and pending:
                rounds.append(pending)
                pending = {}
            if event in pending:
                raise ValueError(f"Duplicate stage {event} at {key}")
            pending[event] = t
            if event in ("U", "M"):
                rounds.append(pending)
                pending = {}
        if pending:
            rounds.append(pending)
        records[key] = rounds

    accepted = []
    excluded = defaultdict(int)
    for (vm, processor), primary in records.items():
        if processor != 0:
            continue
        secondary = [records.get((vm, i), []) for i in (1, 2)]
        begins = [[r.get("B", 0) for r in seq] for seq in secondary]
        qs = sorted(requests[vm])
        previous = -1
        for root in primary:
            if not set("ABC") <= root.keys():
                excluded["incomplete-primary"] += 1
                continue
            cohort = [root]
            for seq, clocks in zip(secondary, begins):
                i = bisect_right(clocks, root["C"]) - 1
                if i >= 0 and "A" in seq[i] and seq[i].get("C", 0) >= root["B"]:
                    cohort.append(seq[i])
            arrival = max(r["A"] for r in cohort)
            q = qs[bisect_right(qs, previous):bisect_right(qs, arrival)]
            previous = arrival
            if len(cohort) != 3:
                excluded["outside-R3-or-unmatched"] += 1
                continue
            required = set("ABCU")
            optional = set("[]()")
            if any(not required <= r.keys() or r.keys() - required - optional
                   for r in cohort):
                excluded["multiple-or-incomplete-rounds"] += 1
                continue
            if any(
                (r.keys() & optional)
                and (not optional <= r.keys()
                     or not r["C"] <= r["["] <= r["]"] <= r["("] <= r[")"] <= r["U"])
                for r in cohort
            ):
                excluded["unordered-post-collector-stages"] += 1
                continue
            if not q:
                excluded["missing-request"] += 1
                continue
            begin = min(r["B"] for r in cohort)
            finish = max(r["C"] for r in cohort)
            resume = max(r["U"] for r in cohort)
            if not q[0] <= arrival <= begin <= finish <= resume:
                excluded["unordered-stages"] += 1
                continue
            accepted.append(dict(
                requests=len(q),
                requestNs=q[0],
                resumeNs=resume,
                collectorBeginNs=begin,
                collectorEndNs=finish,
                lastArrivalProcessor=max(range(3), key=lambda i: cohort[i]["A"]),
                lastResumeProcessor=max(range(3), key=lambda i: cohort[i]["U"]),
                rendezvous=arrival-q[0],
                dispatch=begin-arrival,
                collector=finish-begin,
                resume=resume-finish,
                earliestParkToLastResume=resume-min(r["A"] for r in cohort),
                requestToLastResume=resume-q[0],
            ))
    def overlap(start_key: str, end_key: str) -> int:
        end = total = 0
        for r in sorted(accepted, key=lambda r: r[start_key]):
            total += max(0, min(end, r[end_key]) - r[start_key])
            end = max(end, r[end_key])
        return total

    return dict(
        rounds=accepted,
        excluded=dict(excluded),
        vmCount=len(requests),
        overlapNs=overlap("requestNs", "resumeNs"),
        collectorOverlapNs=overlap("collectorBeginNs", "collectorEndNs"),
    )


def summarize_final_epochs(path: Path, *, require_wait_exposure: bool = False) -> dict:
    """Join final tree events by VM and exact frozen epoch."""
    return _summarize_final_lines(path.read_text().splitlines(), require_wait_exposure)


def _summarize_final_lines(lines: list[str], require_wait_exposure: bool) -> dict:
    if not lines or lines[-1] != "trace-invalid=0":
        raise ValueError("Missing terminal trace receipt or probe overflow")
    current = {}
    events = {}
    for line in lines[:-1]:
        processor, vm, kind, raw = line.split()
        if kind not in "@<>=#{}%qlstwz":
            continue
        carrier = int(processor)
        value = int(raw)
        key = (vm, carrier)
        if kind == "@":
            if key in current:
                raise ValueError("Final barrier epoch began before prior exit")
            current[key] = value
            row = events.setdefault((vm, value), {})
            if carrier in row:
                raise ValueError("Duplicate final barrier epoch entry")
            row[carrier] = []
        elif key not in current:
            raise ValueError("Final barrier event without an epoch")
        else:
            events[vm, current[key]][carrier].append((kind, value))
            if kind == ">":
                del current[key]

    accepted = []
    excluded = defaultdict(int)
    for (vm, epoch), carriers in sorted(events.items()):
        if set(carriers) != {0, 1, 2}:
            excluded["incomplete-roster"] += 1
            continue
        exposure = {id: [(k, v) for k, v in entries if k in "qlstwz"]
                    for id, entries in carriers.items()}
        observed_waits = require_wait_exposure or any(exposure.values())
        carriers = {id: [(k, v) for k, v in entries if k not in "qlstwz"]
                    for id, entries in carriers.items()}
        if observed_waits and "".join(k for k, _ in exposure[0]) != "qlstqlst":
            excluded["incomplete-signal-exposure"] += 1
            continue
        sequences = {id: "".join(k for k, _ in entries)
                     for id, entries in carriers.items()}
        reported = None
        if sequences.get(0) == "%<#{}#{}>":
            reported = carriers[0][0][1]
            carriers[0] = carriers[0][1:]
            sequences[0] = "<#{}#{}>"
        if sequences != {0: "<#{}#{}>", 1: "<=>", 2: "<=>"}:
            excluded["incomplete-tree-exchange"] += 1
            continue
        start, id1, before1, after1, id2, before2, after2, end = [
            value for _, value in carriers[0]
        ]
        receivers = {id: [value for _, value in carriers[id]] for id in (1, 2)}
        if (id1, id2) != (1, 2):
            excluded["unexpected-tree-recipients"] += 1
            continue
        last_arrival = max(start, *(row[0] for row in receivers.values()))
        if not last_arrival <= before1 <= after1 <= before2 <= after2 <= end:
            excluded["unordered-publisher"] += 1
            continue
        edges = []
        for id, before, after in ((1, before1, after1), (2, before2, after2)):
            arrive, acquire, leave = receivers[id]
            if not arrive <= before <= acquire <= leave:
                excluded["unordered-receiver"] += 1
                break
            detail = {}
            if observed_waits:
                target, locked, signal_start, signal_end = [
                    value for _, value in exposure[0][(id-1)*4:id*4]
                ]
                if (target != id or locked not in (0, 1) or
                        not after <= signal_start <= signal_end <= end):
                    excluded["invalid-signal-exposure"] += 1
                    break
                calls = exposure[id]
                if ("".join(k for k, _ in calls) != "wz" * (len(calls)//2) or
                        any(not arrive <= t <= acquire for _, t in calls) or
                        any(a > b for (_, a), (_, b) in zip(calls, calls[1:]))):
                    excluded["incomplete-condition-wait"] += 1
                    break
                intervals = [(a, b) for (_, a), (_, b) in zip(calls[::2], calls[1::2])]
                detail["notificationExposure"] = dict(
                    signalLocked=bool(locked),
                    signalBracketNs=[signal_start, signal_end],
                    waitCallIntervalsNs=intervals,
                    signalWithinWaitCall=any(a <= signal_start <= signal_end <= b
                                             for a, b in intervals),
                )
            edges.append(dict(
                carrier=id,
                arrivalToLastArrivalNs=last_arrival-arrive,
                lastArrivalToReleaseLowerNs=before-last_arrival,
                lastArrivalToReleaseUpperNs=after-last_arrival,
                releaseToAcquireLowerNs=max(0, acquire-after),
                releaseToAcquireUpperNs=acquire-before,
                acquireToExitNs=leave-acquire,
                arriveToExitNs=leave-arrive,
                **detail,
            ))
        else:
            arrivals = [start, *(row[0] for row in receivers.values())]
            exits = {0: end, **{id: row[2] for id, row in receivers.items()}}
            last_exit = max(exits.values())
            exit_detail = {}
            if observed_waits:
                ordered_exits = sorted(exits.values())
                exit_detail = dict(
                    lastExitCarriers=[id for id, stamp in exits.items() if stamp == last_exit],
                    lastExitLeadNs=last_exit-ordered_exits[-2],
                    exitLagFromLastNs={id: last_exit-stamp for id, stamp in exits.items()},
                )
            accepted.append(dict(
                vm=vm, epoch=epoch, edges=edges, reportedGcNs=reported,
                firstArrivalToLastExitNs=last_exit-min(arrivals),
                lastArrivalToLastExitNs=last_exit-last_arrival,
                **exit_detail,
            ))
    return dict(rounds=accepted, excluded=dict(excluded))


def summarize_adjacent_epochs(path: Path) -> dict:
    """Keep sampled epoch pairs without borrowing another VM or skipping a round."""
    trace = summarize_final_epochs(path)
    rounds = {(r["vm"], r["epoch"]): r for r in trace["rounds"]}
    pairs = []
    missing = 0
    for (vm, epoch), current in rounds.items():
        if epoch % 16:
            continue
        following = rounds.get((vm, epoch + 1))
        if (following is None or current["reportedGcNs"] is None
                or following["reportedGcNs"] is None):
            missing += 1
            continue
        pairs.append(dict(
            vm=vm,
            epoch=epoch,
            finalBarrierNs=current["firstArrivalToLastExitNs"],
            receiverReleaseToAcquireUpperNs=max(
                edge["releaseToAcquireUpperNs"] for edge in current["edges"]),
            currentReportedGcNs=current["reportedGcNs"],
            followingReportedGcNs=following["reportedGcNs"],
        ))
    return dict(pairs=pairs, missingSuccessor=missing, excluded=trace["excluded"])


def replay_final_archives(packet: Path, repository: Path) -> dict:
    """Verify repository trace bytes and replay their declared epoch scope."""
    campaigns = json.loads(packet.read_text())["historicalFinalWakeIntervention"]
    repository = repository.resolve()
    results = []
    for name, campaign in campaigns.items():
        if not isinstance(campaign, dict) or "rawTraceArchive" not in campaign:
            continue
        receipt = campaign["rawTraceArchive"]
        archive = (repository / receipt["path"]).resolve()
        if not archive.is_relative_to(repository):
            raise ValueError("Trace archive escapes the repository")
        compressed = archive.read_bytes()
        if hashlib.sha256(compressed).hexdigest() != receipt["sha256"]:
            raise ValueError(f"{name}: archive digest mismatch")
        payload = gzip.decompress(compressed)
        if hashlib.sha256(payload).hexdigest() != receipt["uncompressedSha256"]:
            raise ValueError(f"{name}: payload digest mismatch")
        records = json.loads(payload)
        if records["campaign"] != name or len(records["rows"]) != receipt["rows"]:
            raise ValueError(f"{name}: archive scope mismatch")
        expected = {(r["role"], r["block"], r["mode"]): r for r in campaign["rows"]}
        seen = set()
        for record in records["rows"]:
            key = (record["role"], record["block"], record["mode"])
            if key not in expected or key in seen:
                raise ValueError(f"{name}: duplicate or unknown trace identity")
            seen.add(key)
            raw = record["trace"].encode()
            digest = hashlib.sha256(raw).hexdigest()
            if digest != record["traceSha256"] or digest != expected[key]["traceSha256"]:
                raise ValueError(f"{name}: trace digest mismatch")
            result = _summarize_final_lines(record["trace"].splitlines(), True)
            if result["excluded"] != expected[key]["excluded"]:
                raise ValueError(f"{name}: exclusions changed")
            count = expected[key].get("acceptedEpochs", expected[key].get("epochs"))
            if not isinstance(count, int):
                edges = expected[key].get("counts", {}).get("edges")
                count = edges // 2 if edges is not None else None
            actual = len(result["rounds"])
            if count is not None and actual != count:
                raise ValueError(f"{name}: accepted epoch count changed")
            results.append(dict(campaign=name, role=key[0], block=key[1], mode=key[2],
                                epochs=actual, epochCountDeclared=count is not None,
                                excluded=result["excluded"]))
        if seen != set(expected):
            raise ValueError(f"{name}: missing trace identity")
    if not results:
        raise ValueError("Packet contains no final trace archives")
    return dict(traces=len(results), rows=results)


if __name__ == "__main__":
    if sys.argv[1] == "--replay-final-archives":
        print(json.dumps(replay_final_archives(Path(sys.argv[2]), Path.cwd())))
    else:
        print(json.dumps(summarize(Path(sys.argv[1]))))
