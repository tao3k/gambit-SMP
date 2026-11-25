"""Join sampled DEV condition calls to same-TID Darwin scheduler events."""
from bisect import bisect_left, bisect_right
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def read_kdebug(trace: Path, stream) -> dict:
    """Reduce an xctrace kdebug table to carrier events and raw clock anchors."""
    carriers = {}
    marks = set()
    for line in trace.read_text().splitlines():
        fields = line.split()
        if len(fields) != 4:
            continue
        carrier, _, kind, value = fields
        if kind == "T":
            carriers[int(value)] = int(carrier)
        elif kind == "K":
            marks.add((int(carrier), int(value)))

    lookup = {}
    events = defaultdict(list)
    anchors = []
    publication_markers = []
    signal_markers = []
    runnable_emitters = []
    thread_ids = {}
    anchor_header_matches = Counter()
    first_stamp = last_stamp = None
    row_count = 0
    container = None
    signature_fields = ("kdebug-class", "kdebug-subclass", "kdebug-code", "kdebug-func")
    wanted = {"event-time", "kdebug-arg", *signature_fields}
    for action, elem in ET.iterparse(stream, events=("start", "end")):
        if action == "start" and elem.tag == "node":
            container = elem
        if action != "end" or elem.tag != "row":
            continue
        row = defaultdict(list)
        for node in elem:
            if node.tag not in wanted:
                continue
            if node.get("id") and node.text and node.text.isdecimal():
                lookup[node.get("id")] = int(node.text)
            row[node.tag].append(lookup.get(node.get("id") or node.get("ref")))
        thread = elem.find("thread")
        emitter = None
        if thread is not None:
            tid = thread.find("tid")
            if tid is not None and tid.text and tid.text.isdecimal():
                emitter = int(tid.text)
                if thread.get("id"):
                    thread_ids[thread.get("id")] = emitter
            elif thread.get("ref"):
                emitter = thread_ids.get(thread.get("ref"))
        sig = tuple((row[tag] or [None])[0] for tag in signature_fields)
        stamp = (row["event-time"] or [None])[0]
        args = row["kdebug-arg"]
        if stamp is not None:
            first_stamp = stamp if first_stamp is None else min(stamp, first_stamp)
            last_stamp = stamp if last_stamp is None else max(stamp, last_stamp)
            row_count += 1
        if stamp is not None and len(args) == 4:
            if sig == (33, 10, 1140, 0) and args[3] == 0x47434C4B:
                user_ns, carrier, tid, _ = args
                if (carrier, user_ns) in marks and carriers.get(tid) == carrier:
                    anchors.append(dict(eventNs=stamp, carrier=carrier, tid=tid, userNs=user_ns))
                    anchor_header_matches["matched" if emitter == tid else
                                          "unavailable" if emitter is None else "mismatched"] += 1
            if sig == (33, 10, 1140, 0) and args[3] == 0x47435042:
                after, sender, identity, _ = args
                publication_markers.append(dict(eventNs=stamp, sender=sender, identity=identity, after=after))
            if sig == (33, 10, 1140, 0) and args[3] == 0x47435347 and emitter is not None:
                token, recipient, end, _ = args
                signal_markers.append(dict(eventNs=stamp, emitterTid=emitter, token=token,
                                           recipient=recipient, end=end))
            if sig[:2] == (1, 64) and sig[2] in (0, 2, 6):
                tid = args[0 if sig[2] == 6 else 1]
                if tid in carriers:
                    events[str(tid)].append([stamp, sig[2], sig[3]])
                    if sig[2] == 6 and sig[3] == 0 and emitter is not None:
                        runnable_emitters.append(dict(targetTid=tid, eventNs=stamp, emitterTid=emitter))
        if container is not None:
            container.remove(elem)
    return dict(
        carriers=carriers, anchors=anchors, events=dict(events), publicationMarkers=publication_markers,
        exportCoverage=dict(rows=row_count, firstNs=first_stamp, lastNs=last_stamp),
        runnableEmitters=runnable_emitters, anchorHeaderMatches=dict(anchor_header_matches),
        signalMarkers=signal_markers,
    )


TAIL_BUCKETS = {
    2: "capacity-plan", 3: "copy-scan", 4: "steal-search", 5: "idle-condition",
    6: "barrier", 7: "allocator-gate", 8: "allocator-call", 9: "resize",
    10: "local-take", 12: "barrier-condition",
}


def summarize_tail(trace: Path, selected_returns: set | None = None) -> dict:
    lines = trace.read_text().splitlines()
    if not lines or lines[-1] != "trace-invalid=0":
        raise ValueError("Collector tail requires a complete DEV trace")
    rounds = defaultdict(list)
    totals = Counter()
    selected_spans = defaultdict(list)
    exclusive = Counter()
    overlaps = Counter()
    for line in lines[:-1]:
        fields = line.split()
        if len(fields) != 4 or fields[2] not in ("A", "B", "C", "U", "M", "w", "e", "i", "j", "k"):
            continue
        carrier, vm, kind, stamp = fields
        key = carrier, vm
        if kind == "A":
            rounds[key] = []
        if key not in rounds:
            continue
        rounds[key].append((kind, int(stamp)))
        if kind not in ("U", "M"):
            continue
        events = rounds.pop(key)
        if kind != "U" or [event for event, _ in events if event in ("B", "C")] != ["B", "C"]:
            continue
        boundaries = dict(events)
        intervals = []
        triplet = []
        for event, value in events:
            if event not in ("i", "j", "k"):
                continue
            triplet.append((event, value))
            if len(triplet) == 3:
                if [tag for tag, _ in triplet] != ["i", "j", "k"]:
                    raise ValueError("Invalid collector interval sequence")
                bucket, start, end = [item for _, item in triplet]
                if not boundaries["B"] <= start <= end <= boundaries["C"]:
                    raise ValueError("Collector interval crosses local collector boundary")
                intervals.append((start, end, TAIL_BUCKETS[bucket]))
                triplet.clear()
        if triplet:
            raise ValueError("Incomplete collector interval")
        condition_ends = [value for event, value in events if event == "e"]
        if not condition_ends or not intervals:
            continue
        # Standalone summaries count one tail per round. A scheduler join
        # clips each accepted call at its own condition return.
        starts = condition_ends[:1]
        if selected_returns is not None:
            starts = [end for end in condition_ends if (carrier, vm, end, int(stamp)) in selected_returns]
        for start in starts:
            end = boundaries["C"]
            if not boundaries["B"] <= start <= end <= boundaries["U"]:
                raise ValueError("Inverted collector tail")
            covered_end = start
            totals["rounds"] += 1
            totals["tailNs"] += end - start
            if selected_returns is not None:
                selected_spans[vm].append((start, end))
            boundaries_by_time = defaultdict(Counter)
            for left, right, bucket in sorted(intervals):
                left = max(start, left)
                if right <= left:
                    continue
                totals[bucket] += right - left
                if selected_returns is not None:
                    boundaries_by_time[left][bucket] += 1
                    boundaries_by_time[right][bucket] -= 1
                totals["unionNs"] += max(0, right - max(left, covered_end))
                covered_end = max(covered_end, right)
            active = Counter()
            previous = start
            for stamp, changes in sorted(boundaries_by_time.items()):
                names = sorted(name for name, count in active.items() if count > 0)
                if stamp > previous:
                    if len(names) == 1:
                        exclusive[names[0]] += stamp - previous
                    elif len(names) > 1:
                        overlaps[" + ".join(names)] += stamp - previous
                active.update(changes)
                previous = stamp
    totals["unattributedNs"] = totals["tailNs"] - totals["unionNs"]
    if selected_returns is not None:
        distinct_wall = 0
        for spans in selected_spans.values():
            covered_until = 0
            for start, end in sorted(spans):
                distinct_wall += max(0, end - max(start, covered_until))
                covered_until = max(covered_until, end)
        totals["perVmTailUnionNs"] = distinct_wall
        totals["overlappingTailNs"] = totals["tailNs"] - distinct_wall
        if sum(exclusive.values()) + sum(overlaps.values()) != totals["unionNs"]:
            raise ValueError("Collector phase partition does not reconstruct union")
        return dict(totals, exclusivePhaseNs=dict(exclusive), overlappingPhaseNs=dict(overlaps))
    return dict(totals)


def summarize(trace: Path, scheduler: dict, first_operations: dict | None = None) -> dict:
    lines = trace.read_text().splitlines()
    if not lines or lines[-1] != "trace-invalid=0":
        raise ValueError("Condition join requires a complete DEV trace")
    open_calls = {}
    calls = defaultdict(list)
    arrivals = {}
    collector_edges = defaultdict(list)
    resume_by_call = {}
    epoch_calls = defaultdict(list)
    for carrier, operations in (first_operations or {}).items():
        for operation in operations:
            key = carrier, operation["vm"], operation["resumeNs"]
            if key in resume_by_call:
                raise ValueError("Duplicate completion for one resume")
            resume_by_call[key] = operation
    operation_by_call = {}
    latest_wait_return = {}
    wait_sites = {}
    for line in lines[:-1]:
        fields = line.split()
        if len(fields) != 4 or fields[2] not in ("w", "e", "v", "A", "B", "C", "U", "M"):
            continue
        carrier, vm, kind, stamp = fields
        key = carrier, vm
        stamp = int(stamp)
        if kind == "v":
            last_return = latest_wait_return.pop(key, None)
            if last_return is None or stamp <= 0:
                raise ValueError("Barrier site lacks a completed wait")
            wait_sites[carrier, vm, last_return] = stamp
        elif kind == "A":
            arrivals[key] = stamp
            epoch_calls.pop(key, None)
            collector_edges.pop(key, None)
        elif kind in ("B", "C"):
            collector_edges[key].append((kind, stamp))
        elif kind in ("U", "M"):
            arrival = arrivals.pop(key, None)
            witness = resume_by_call.get((carrier, vm, stamp))
            completed = witness["completionNs"] if witness is not None else None
            intervals = epoch_calls.pop(key, [])
            edges = collector_edges.pop(key, [])
            if kind == "U" and arrival is not None and completed is not None:
                for start, end in intervals:
                    if arrival <= start <= end <= stamp <= completed:
                        collector_end = None
                        if [kind for kind, _ in edges] == ["B", "C"]:
                            begin, finish = edges[0][1], edges[1][1]
                            if arrival <= begin <= start <= end <= finish <= stamp:
                                collector_end = finish
                        operation_by_call[carrier, vm, start, end] = stamp, witness, collector_end
        elif kind == "w":
            if key in open_calls:
                raise ValueError("Overlapping condition call")
            open_calls[key] = stamp
        else:
            start = open_calls.pop(key)
            latest_wait_return[key] = stamp
            if stamp < start:
                raise ValueError("Inverted condition interval")
            calls[carrier].append((vm, start, stamp))
            epoch_calls[key].append((start, stamp))

    identities = {str(tid): str(carrier) for tid, carrier in scheduler["carriers"].items()}
    if len(set(identities.values())) != len(identities):
        raise ValueError("Carrier TID changed within condition trace")
    anchors = defaultdict(list)
    for row in scheduler["anchors"]:
        if identities.get(str(row["tid"])) != str(row["carrier"]):
            raise ValueError("Clock anchor does not belong to the carrier")
        anchors[str(row["carrier"])].append((row["userNs"], row["eventNs"] - row["userNs"]))
    all_offsets = [offset for rows in anchors.values() for _, offset in rows]
    if not all_offsets:
        raise ValueError("Missing shared-clock calibration")
    lo, hi = min(all_offsets), max(all_offsets)
    results = {}
    selected_returns = set()
    call_outcomes = []
    for tid, carrier in identities.items():
        offsets = sorted(set(anchors[carrier]))
        events = sorted((ts, code) for ts, code, qual in scheduler["events"].get(tid, []) if qual == 0)
        times = [ts for ts, _ in events]
        reasons = Counter()
        joined = []
        to_operation = []
        same_epoch_stages = Counter()
        same_epoch_returns = set()
        local_collector_returns = set()
        same_epoch_kinds = defaultdict(Counter)
        for vm, start, end in calls[carrier]:
            site = wait_sites.get((carrier, vm, end))
            if len(offsets) < 2 or start < offsets[0][0] or end > offsets[-1][0]:
                reasons["outside-anchor-bracket"] += 1
                call_outcomes.append((start, end, site, "outside-anchor-bracket"))
                continue
            possible = events[bisect_left(times, start + lo):bisect_right(times, end + hi)]
            if any(ts < start + hi or ts > end + lo for ts, _ in possible):
                reasons["clock-boundary-ambiguous"] += 1
                call_outcomes.append((start, end, site, "clock-boundary-ambiguous"))
                continue
            if len(possible) != 2 or possible[0][1] != 6 or possible[1][1] not in (0, 2):
                reasons["missing-or-nonunique-event-chain"] += 1
                call_outcomes.append((start, end, site, "missing-or-nonunique-event-chain"))
                continue
            wake, dispatch = possible[0][0], possible[1][0]
            if wake >= dispatch:
                reasons["unordered-event-chain"] += 1
                call_outcomes.append((start, end, site, "unordered-event-chain"))
                continue
            joined.append((wake - start - hi, dispatch - wake, end + lo - dispatch))
            operation = operation_by_call.get((carrier, vm, start, end))
            call_outcomes.append((start, end, site, "scheduler-only" if operation is None
                                  else "without-collector-exit" if operation[2] is None else "full-join"))
            if operation is not None:
                resume, witness, collector_end = operation
                completed = witness["completionNs"]
                same_epoch_returns.add((vm, resume))
                to_operation.append((completed + lo - wake, completed + hi - wake))
                same_epoch_stages["runnableToSwitchNs"] += dispatch - wake
                same_epoch_stages["switchToConditionReturnLowerNs"] += end + lo - dispatch
                same_epoch_stages["switchToConditionReturnUpperNs"] += end + hi - dispatch
                same_epoch_stages["conditionReturnToGcResumeNs"] += resume - end
                same_epoch_stages["gcResumeToOperationNs"] += completed - resume
                if "jumpToEndNs" in witness and "operationBracketNs" in witness:
                    handoff = completed - witness["jumpToEndNs"]
                    operation_start = completed - witness["operationBracketNs"]
                    if not resume <= handoff <= operation_start <= completed:
                        raise ValueError("Inverted first-operation bracket")
                    same_epoch_stages["operationStartSplitCalls"] += 1
                    same_epoch_stages["gcResumeToHandoffNs"] += handoff - resume
                    same_epoch_stages["handoffToOperationStartNs"] += operation_start - handoff
                    same_epoch_stages["operationBracketNs"] += completed - operation_start
                    kind = witness.get("pollEdge") or {1: "straight-line", 2: "predicate", 4: "transfer"}.get(
                        witness.get("kind"), "unclassified")
                    same_epoch_kinds[kind]["calls"] += 1
                    same_epoch_kinds[kind]["bracketNs"] += completed - operation_start
                    same_epoch_kinds[kind]["resumeToStartNs"] += operation_start - resume
                if collector_end is not None:
                    selected_returns.add((carrier, vm, end, resume))
                    local_collector_returns.add((vm, collector_end, resume, end, start, wake, dispatch, completed))
                    same_epoch_stages["collectorReturnSplitCalls"] += 1
                    same_epoch_stages["conditionReturnToLocalCollectorExitNs"] += collector_end - end
                    same_epoch_stages["localCollectorExitToGcResumeNs"] += resume - collector_end
        delays = sorted(v[1] for v in joined)
        anchor_times = [user + offset for user, offset in offsets]
        results[carrier] = dict(
            anchorCount=len(offsets),
            kernelAnchorRangeNs=[min(anchor_times), max(anchor_times)] if anchor_times else None,
            userAnchorRangeNs=[offsets[0][0], offsets[-1][0]] if offsets else None,
            kernelEventRangeNs=[times[0], times[-1]] if times else None,
            userCallRangeNs=[min(v[1] for v in calls[carrier]), max(v[2] for v in calls[carrier])]
            if calls[carrier] else None,
            anchorSpanNs=offsets[-1][0]-offsets[0][0] if offsets else 0,
            calls=len(calls[carrier]), rejected=dict(reasons), matched=len(joined),
            beforeRunnableLowerNs=sum(v[0] for v in joined),
            runnableToSwitchNs=sum(delays),
            sameEpochFirstOperationMatches=len(to_operation),
            distinctSameEpochReturns=len(same_epoch_returns),
            localCollectorReturns=[
                dict(vm=vm, collectorExitNs=exit_stamp, resumeNs=resume, conditionReturnNs=condition_return,
                     conditionStartNs=start, runnableKernelNs=wake, switchKernelNs=dispatch,
                     runnableToSwitchNs=dispatch-wake, firstOperationCompletionNs=completed,
                     barrierSiteLine=wait_sites.get((carrier, vm, condition_return)))
                for vm, exit_stamp, resume, condition_return, start, wake, dispatch, completed
                in sorted(local_collector_returns)
            ],
            sameEpochStagesNs=dict(same_epoch_stages),
            sameEpochOperationKinds=dict(same_epoch_kinds),
            runnableToOperationLowerSumNs=sum(lower for lower, _ in to_operation),
            runnableToOperationUpperSumNs=sum(upper for _, upper in to_operation),
            runnableToSwitchP95Ns=delays[(95*len(delays)+99)//100-1] if delays else None,
            afterSwitchLowerNs=sum(v[2] for v in joined),
        )
    return dict(
        conditionCallOutcomes=call_outcomes,
        conditionSites=[(carrier, vm, start, end, wait_sites[carrier, vm, end])
                        for carrier, records in calls.items() for vm, start, end in records
                        if (carrier, vm, end) in wait_sites],
        exportCoverage=scheduler.get("exportCoverage"), offsetSpreadNs=hi-lo, byCarrier=results, unfinishedAtExit=len(open_calls),
        sameEpochTailPhases=summarize_tail(trace, selected_returns) if selected_returns else None,
        callsWithoutCarrierTid=sum(len(calls[carrier]) for carrier in calls.keys() - results.keys()),
    )


def summarize_slow_user_tails(trace: Path, rounds: list[dict]) -> dict:
    """Attribute instrumented local tails independently of kernel coverage."""
    starts = [row["collectorBeginNs"] for row in rounds]
    active = {}
    selected = set()
    covered = set()
    for line in trace.read_text().splitlines():
        fields = line.split()
        if len(fields) != 4 or fields[2] not in ("A", "B", "C", "e", "U", "M"):
            continue
        carrier, vm, kind, stamp = fields
        stamp = int(stamp)
        key = carrier, vm
        if kind == "A":
            active[key] = []
        if key not in active:
            continue
        active[key].append((kind, stamp))
        if kind not in ("U", "M"):
            continue
        events = active.pop(key)
        if kind != "U" or [tag for tag, _ in events if tag in ("B", "C")] != ["B", "C"]:
            continue
        boundaries = dict(events)
        begin, end = boundaries["B"], boundaries["C"]
        index = bisect_right(starts, begin) - 1
        if index < 0 or end > rounds[index]["collectorEndNs"] or stamp > rounds[index]["resumeNs"]:
            continue
        wait_end = next((ts for tag, ts in events if tag == "e" and begin <= ts <= end), None)
        if wait_end is not None:
            selected.add((carrier, vm, wait_end, stamp))
            covered.add(index)
    return dict(slowRounds=len(rounds), withLocalWait=len(covered),
                phases=summarize_tail(trace, selected))


def read_barrier_publications(trace: Path) -> dict:
    pending = defaultdict(list)
    publications = defaultdict(list)
    for line in trace.read_text().splitlines():
        fields = line.split()
        if len(fields) != 4 or fields[2] not in ("b", "c", "f"):
            continue
        carrier, vm, kind, stamp = fields
        key = carrier, vm
        pending[key].append((kind, int(stamp)))
        if kind == "f":
            fields = pending.pop(key)
            if [tag for tag, _ in fields] != ["b", "c", "f"]:
                raise ValueError("Malformed barrier publication")
            before, after, identity = (value for _, value in fields)
            if not 0 < before <= after:
                raise ValueError("Invalid barrier publication clock bracket")
            site, recipient = divmod(identity, 1 << 32)
            publications[vm, str(recipient), site].append(
                dict(sender=carrier, releaseBeforeNs=before, releaseAfterNs=after))
    if pending:
        raise ValueError("Incomplete barrier publication")
    return publications


def summarize_slow_call_coverage(round_data: dict, calls: list[dict]) -> dict:
    """Bound measured dispatch intervals without adding overlapping carriers."""
    def union_ns(intervals):
        total = 0
        end = 0
        for left, right in sorted(intervals):
            total += max(0, right - max(left, end))
            end = max(end, right)
        return total

    intervals = [(call["runnableKernelNs"], call["switchKernelNs"]) for call in calls]
    last_carrier = str(round_data["lastResumeProcessor"])
    last_intervals = [interval for call, interval in zip(calls, intervals)
                      if call["carrier"] == last_carrier]
    operation_completions = {
        (call["carrier"], call["resumeNs"], call["firstOperationCompletionNs"])
        for call in calls
    }
    return dict(
        matchedRunnableSumNs=sum(right-left for left, right in intervals),
        matchedRunnableUnionNs=union_ns(intervals),
        lastResumingCarrierMatchedRunnableUnionNs=union_ns(last_intervals) if last_intervals else None,
        distinctOperationCompletions=len(operation_completions),
        maxResumeToFirstOperationNs=max(end-resume for _, resume, end in operation_completions),
    )


def audit_whole_rounds(trace: Path, join: dict, scheduler: dict, whole: dict,
                       first_operations: dict | None = None) -> dict:
    carriers = {str(tid): carrier for tid, carrier in scheduler["carriers"].items()}
    if whole["vmCount"] != 1 or whole["collectorOverlapNs"]:
        raise ValueError("Round coverage requires one VM and disjoint collector envelopes")
    rounds = sorted(whole["rounds"], key=lambda row: row["collectorBeginNs"])
    if not rounds:
        raise ValueError("No whole rounds for scheduler coverage")
    starts = [row["collectorBeginNs"] for row in rounds]
    slowest = set(sorted(range(len(rounds)), key=lambda i: rounds[i]["requestToLastResume"],
                         reverse=True)[:(len(rounds)+99)//100])
    offsets = [anchor["eventNs"]-anchor["userNs"] for anchor in scheduler["anchors"]]
    first = scheduler["exportCoverage"]["firstNs"]
    last = scheduler["exportCoverage"]["lastNs"]
    overlapping = {
        i for i in slowest
        if rounds[i]["requestNs"]+min(offsets) <= last and rounds[i]["resumeNs"]+max(offsets) >= first
    }
    selected = set()
    unmatched = 0
    slow_returns = set()
    slow_call_witnesses = defaultdict(list)
    for carrier, data in join["byCarrier"].items():
        for local in data["localCollectorReturns"]:
            i = bisect_right(starts, local["collectorExitNs"])-1
            if (i >= 0 and local["collectorExitNs"] <= rounds[i]["collectorEndNs"]
                    and local["resumeNs"] <= rounds[i]["resumeNs"]):
                selected.add(i)
                if i in slowest:
                    slow_returns.add((carrier, local["vm"], local["conditionReturnNs"], local["resumeNs"]))
                    slow_call_witnesses[i].append(dict(carrier=carrier, **local))
            else:
                unmatched += 1
    # A scheduler-only observation is distinct from an exact condition join.
    # Restrict to event pairs wholly inside the round for every calibrated offset.
    kernel_events = {
        str(carriers[str(tid)]): sorted(
            (stamp, code) for stamp, code, qualifier in events if qualifier == 0
        )
        for tid, events in scheduler["events"].items()
    }
    resumes = sorted(
        (int(stamp), carrier, vm)
        for carrier, vm, kind, stamp in (
            line.split() for line in trace.read_text().splitlines() if len(line.split()) == 4
        )
        if kind == "U"
    )
    resume_times = [stamp for stamp, _, _ in resumes]
    witnesses = {
        (carrier, op["vm"], op["resumeNs"]): op
        for carrier, operations in (first_operations or {}).items() for op in operations
    }
    overlap_diagnostics = []
    for i in sorted(overlapping):
        row = rounds[i]
        outcomes = Counter(
            outcome for start, end, _, outcome in join["conditionCallOutcomes"]
            if row["requestNs"] <= start <= end <= row["resumeNs"]
        )
        crossing = sum(
            start <= row["resumeNs"] and end >= row["requestNs"]
            and not (row["requestNs"] <= start <= end <= row["resumeNs"])
            for start, end, _, _ in join["conditionCallOutcomes"]
        )
        outcomes_by_site = defaultdict(Counter)
        for start, end, site, outcome in join["conditionCallOutcomes"]:
            if site is not None and row["collectorBeginNs"] <= start <= end <= row["collectorEndNs"]:
                outcomes_by_site[site][outcome] += 1
        scheduler_pairs = []
        bracketed_carriers = []
        for carrier, events in kernel_events.items():
            anchors = [a["userNs"] for a in scheduler["anchors"] if str(a["carrier"]) == carrier]
            if len(anchors) < 2 or not min(anchors) <= row["requestNs"] <= row["resumeNs"] <= max(anchors):
                continue
            bracketed_carriers.append(carrier)
            lower = row["requestNs"] + max(offsets)
            upper = row["resumeNs"] + min(offsets)
            for (wake, wake_code), (dispatch, dispatch_code) in zip(events, events[1:]):
                if lower <= wake < dispatch <= upper and wake_code == 6 and dispatch_code in (0, 2):
                    within_collector = (wake >= row["collectorBeginNs"] + max(offsets)
                                        and dispatch <= row["collectorEndNs"] + min(offsets))
                    scheduler_pairs.append(dict(carrier=carrier, runnableNs=wake, dispatchNs=dispatch,
                                                runnableToSwitchNs=dispatch-wake,
                                                withinCollectorEnvelope=within_collector))
        round_resumes = resumes[bisect_left(resume_times, row["collectorBeginNs"]):
                                bisect_right(resume_times, row["resumeNs"])]
        last_resume = str(row["lastResumeProcessor"])
        if (len({carrier for _, carrier, _ in round_resumes}) != len(round_resumes)
                or not round_resumes or round_resumes[-1][:2] != (row["resumeNs"], last_resume)):
            raise ValueError("Ambiguous carrier resume in slow round")
        resume_evidence = [
            dict(carrier=carrier, resumeNs=stamp, firstOperation=witnesses.get((carrier, vm, stamp)))
            for stamp, carrier, vm in round_resumes
        ]
        overlap_diagnostics.append(dict(requestNs=row["requestNs"],
                                        pauseNs=row["requestToLastResume"], outcomes=dict(outcomes),
                                        crossingConditionCalls=crossing,
                                        conditionOutcomesBySite=dict(outcomes_by_site),
                                        lastResumeCarrier=last_resume,
                                        carrierResumes=resume_evidence,
                                        bracketedCarriers=sorted(bracketed_carriers),
                                        schedulerOnlyPairCount=len(scheduler_pairs),
                                        longestSchedulerOnlyPair=max(
                                            scheduler_pairs, key=lambda pair: pair["runnableToSwitchNs"],
                                            default=None)))
    resume_cohorts = {row["requestNs"]: row["carrierResumes"] for row in overlap_diagnostics}
    publications = read_barrier_publications(trace)
    publication_sites = {site for _, _, site in publications}
    publication_counts = Counter()
    publication_matches = {}
    ordered_publication_calls = []
    kernel_publications = defaultdict(list)
    for marker in scheduler.get("publicationMarkers", []):
        kernel_publications[str(marker["sender"]), marker["identity"], marker["after"]].append(marker["eventNs"])
    for carrier, data in join["byCarrier"].items():
        for call in data["localCollectorReturns"]:
            site = call["barrierSiteLine"]
            if site not in publication_sites:
                continue
            candidates = [p for p in publications[call["vm"], carrier, site]
                          if call["conditionStartNs"] <= p["releaseBeforeNs"]
                          <= p["releaseAfterNs"] <= call["conditionReturnNs"]]
            if len(candidates) != 1:
                publication_counts["missing-or-nonunique"] += 1
                continue
            candidate = candidates[0]
            lower = call["runnableKernelNs"] - candidate["releaseAfterNs"] - max(offsets)
            upper = call["runnableKernelNs"] - candidate["releaseBeforeNs"] - min(offsets)
            identity = (site << 32) | int(carrier)
            markers = kernel_publications[candidate["sender"], identity, candidate["releaseAfterNs"]]
            if len(markers) == 1 and markers[0] < call["runnableKernelNs"]:
                publication_counts["kernel-order-matched"] += 1
                witness = dict(candidate, publicationMarkerKernelNs=markers[0],
                               markerToRunnableNs=call["runnableKernelNs"]-markers[0])
                publication_matches[carrier, call["vm"], call["conditionReturnNs"]] = witness
                ordered_publication_calls.append(dict(call, carrier=carrier, publication=witness))
                continue
            if lower < 0:
                publication_counts["runnable-precedes-release" if upper < 0 else "ordering-unproven"] += 1
                continue
            publication_counts["matched"] += 1
            publication_matches[carrier, call["vm"], call["conditionReturnNs"]] = dict(
                candidate, releaseToRunnableLowerNs=lower, releaseToRunnableUpperNs=upper)
    waits_by_carrier = defaultdict(list)
    for carrier, _, start, end, site in join["conditionSites"]:
        waits_by_carrier[carrier].append((start, end, site))
    resume_scopes = defaultdict(list)
    collector_exits = defaultdict(list)
    open_scopes = {}
    scope_kinds = {"[": "sync-tree", "(": "lifecycle-drain"}
    for line in trace.read_text().splitlines():
        fields = line.split()
        if len(fields) != 4 or fields[2] not in "C[]()":
            continue
        carrier, vm, tag, stamp = fields
        key = carrier, vm
        if tag == "C":
            collector_exits[key].append(int(stamp))
        elif tag in scope_kinds:
            if key in open_scopes:
                raise ValueError("Overlapping resume scopes")
            open_scopes[key] = tag, int(stamp)
        else:
            begin_tag, begin = open_scopes.pop(key)
            if (begin_tag, tag) not in (("[", "]"), ("(", ")")) or begin > int(stamp):
                raise ValueError("Invalid resume scope")
            resume_scopes[key].append((scope_kinds[begin_tag], begin, int(stamp)))
    if open_scopes:
        raise ValueError("Unclosed resume scope")

    emitter_by_event = defaultdict(set)
    for event in scheduler.get("runnableEmitters", []):
        target = str(carriers[str(event["targetTid"])])
        emitter_by_event[target, event["eventNs"]].add(event["emitterTid"])

    signal_groups = defaultdict(list)
    for marker in scheduler.get("signalMarkers", []):
        signal_groups[marker["emitterTid"], marker["recipient"], marker["token"]].append(
            (marker["eventNs"], marker["end"]))
    signal_intervals = defaultdict(list)
    for (tid, recipient, token), events in signal_groups.items():
        events.sort()
        if len(events) == 2 and [tag for _, tag in events] == [0, 1]:
            signal_intervals[tid, recipient].append((events[0][0], events[1][0], token))

    def resume_dispatch(call):
        carrier = call["carrier"]
        start, end = call["collectorExitNs"], call["resumeNs"]
        anchors = [a["userNs"] for a in scheduler["anchors"] if str(a["carrier"]) == carrier]
        if len(anchors) < 2 or not min(anchors) <= start <= end <= max(anchors):
            return None
        lo, hi = min(offsets), max(offsets)
        possible = [(ts, code) for ts, code in kernel_events.get(carrier, [])
                    if start + lo <= ts <= end + hi]
        if any(ts < start + hi or ts > end + lo for ts, _ in possible):
            return None
        if len(possible) != 2 or possible[0][1] != 6 or possible[1][1] not in (0, 2):
            return None
        wake, dispatch = possible[0][0], possible[1][0]
        if wake >= dispatch:
            return None
        matched_scopes = [
            dict(kind=kind, beginNs=begin, endNs=finish)
            for kind, begin, finish in resume_scopes[carrier, call["vm"]]
            if start <= begin <= finish <= end and begin + hi <= wake < dispatch <= finish + lo
        ]
        emitter_tids = sorted(emitter_by_event[carrier, wake])
        emitter_scopes = []
        if len(emitter_tids) == 1:
            emitter = carriers.get(str(emitter_tids[0]))
            index = bisect_right(starts, start) - 1
            if emitter is not None and index >= 0:
                row = rounds[index]
                key = str(emitter), call["vm"]
                exits = [ts for ts in collector_exits[key]
                         if row["collectorBeginNs"] <= ts <= row["collectorEndNs"]]
                emitter_resumes = [
                    ts for ts, carrier_id, vm in resumes[
                        bisect_left(resume_times, row["collectorBeginNs"]):
                        bisect_right(resume_times, row["resumeNs"])
                    ] if (carrier_id, vm) == key
                ]
                if (len(exits) == len(emitter_resumes) == 1
                        and start <= row["collectorEndNs"] and end <= row["resumeNs"]):
                    emitter_scopes = [
                        dict(kind=kind, carrier=str(emitter), beginNs=begin, endNs=finish)
                        for kind, begin, finish in resume_scopes[key]
                        if exits[0] <= begin <= finish <= emitter_resumes[0]
                        and begin + hi <= wake <= finish + lo
                    ]
        matching_signals = []
        if len(emitter_scopes) == len(emitter_tids) == 1:
            scope = emitter_scopes[0]
            matching_signals = [
                dict(beginKernelNs=begin, endKernelNs=finish, token=token)
                for begin, finish, token in signal_intervals[emitter_tids[0], int(carrier)]
                if scope["kind"] == "sync-tree" and scope["beginNs"] + hi <= begin
                <= wake <= finish <= scope["endNs"] + lo
            ]
        return dict(runnableKernelNs=wake, switchKernelNs=dispatch, runnableToSwitchNs=dispatch-wake,
                    exitToRunnableNs=[wake-start-hi, wake-start-lo],
                    switchToResumeNs=[end+lo-dispatch, end+hi-dispatch],
                    containingScopes=matched_scopes,
                    runnableEventEmitterTids=emitter_tids, emitterScopes=emitter_scopes,
                    signalCall=matching_signals[0] if len(matching_signals) == 1 else None)

    # A final resume can have a kernel wake even when its earlier collector
    # condition wait or publication was never sampled.
    post_collector_by_resume = {}
    for resume, carrier, vm in resumes:
        op = witnesses.get((carrier, vm, resume))
        index = bisect_right(starts, resume) - 1
        if op is None or index < 0:
            continue
        row = rounds[index]
        if resume > row["resumeNs"]:
            continue
        exits = collector_exits[carrier, vm]
        first = bisect_left(exits, row["collectorBeginNs"])
        last = bisect_right(exits, min(row["collectorEndNs"], resume))
        if last - first != 1:
            continue
        call = dict(carrier=carrier, vm=vm, resumeNs=resume,
                    collectorExitNs=exits[first],
                    firstOperationCompletionNs=op["completionNs"])
        post_collector_by_resume[carrier, vm, resume] = call, resume_dispatch(call)
    post_collector_counts = Counter()
    sync_tree_emitter_classes = Counter()
    sync_tree_emitter_carriers = Counter()
    sync_tree_emitter_scopes = Counter()
    sync_tree_signal_witnesses = []
    scoped_delays = defaultdict(list)
    scoped_rounds = defaultdict(lambda: defaultdict(list))
    for call, dispatch in post_collector_by_resume.values():
        if dispatch is not None:
            scopes = dispatch["containingScopes"]
            kind = scopes[0]["kind"] if len(scopes) == 1 else "unresolved"
            post_collector_counts[kind] += 1
            if kind == "sync-tree":
                emitters = dispatch["runnableEventEmitterTids"]
                if len(emitters) == 1:
                    emitter_carrier = carriers.get(str(emitters[0]))
                    if emitter_carrier is not None:
                        sync_tree_emitter_carriers[emitter_carrier] += 1
                    emitter_class = ("external-tid" if emitter_carrier is None else
                                     "receiver" if str(emitter_carrier) == call["carrier"] else
                                     "peer-carrier")
                else:
                    emitter_class = "missing-or-nonunique"
                sync_tree_emitter_classes[emitter_class] += 1
                sender_scopes = dispatch["emitterScopes"]
                sender_kind = sender_scopes[0]["kind"] if len(sender_scopes) == 1 else "unresolved"
                sync_tree_emitter_scopes[sender_kind] += 1
                if dispatch["signalCall"] is not None:
                    sync_tree_signal_witnesses.append(dict(
                        carrier=call["carrier"], vm=call["vm"], resumeNs=call["resumeNs"],
                        firstOperationCompletionNs=call["firstOperationCompletionNs"],
                        **dispatch,
                    ))
            index = bisect_right(starts, call["collectorExitNs"]) - 1
            if (index >= 0 and call["collectorExitNs"] <= rounds[index]["collectorEndNs"]
                    and call["resumeNs"] <= rounds[index]["resumeNs"]):
                scoped_rounds[kind][index].append(call | dispatch)
            scoped_delays[kind].append((
                dispatch["runnableToSwitchNs"],
                call["firstOperationCompletionNs"] - call["resumeNs"],
            ))
    post_collector_timings = {}
    for kind, pairs in scoped_delays.items():
        dispatch, first_operation = (sorted(values) for values in zip(*pairs))
        rank = (95*len(pairs)+99)//100-1
        post_collector_timings[kind] = dict(
            runnableToSwitchP95Ns=dispatch[rank],
            runnableToSwitchMaxNs=dispatch[-1],
            resumeToFirstOperationP95Ns=first_operation[rank],
            resumeToFirstOperationMaxNs=first_operation[-1],
            dispatchExceedsOperationCount=sum(delay > operation for delay, operation in pairs),
        )

    post_collector_round_coverage = {}
    for kind, groups in scoped_rounds.items():
        summaries = [summarize_slow_call_coverage(rounds[index], calls)
                     for index, calls in groups.items()]
        post_collector_round_coverage[kind] = dict(
            rounds=len(groups),
            multiCarrierRounds=sum(len(calls) > 1 for calls in groups.values()),
            unmatchedCalls=post_collector_counts[kind]-sum(map(len, groups.values())),
            summedDispatchNs=sum(row["matchedRunnableSumNs"] for row in summaries),
            summedRoundUnionsNs=sum(row["matchedRunnableUnionNs"] for row in summaries),
            roundsWithFinalCarrier=sum(row["lastResumingCarrierMatchedRunnableUnionNs"] is not None
                                       for row in summaries),
            summedFinalCarrierDispatchNs=sum(row["lastResumingCarrierMatchedRunnableUnionNs"] or 0
                                             for row in summaries),
        )

    def downstream_waits(call):
        downstream = Counter()
        for start, end, site in waits_by_carrier[call["carrier"]]:
            if call["conditionReturnNs"] <= start < end <= call["collectorExitNs"]:
                downstream[site] += end - start
        return dict(
            untilCollectorExitNs=call["collectorExitNs"]-call["conditionReturnNs"],
            collectorExitToResumeNs=call["resumeNs"]-call["collectorExitNs"],
            observedLaterBarrierWaitNsBySite=dict(downstream),
        )

    for index, calls in slow_call_witnesses.items():
        row = rounds[index]
        cohort = resume_cohorts.get(row["requestNs"], [])
        for call in calls:
            key = call["carrier"], call["vm"], call["conditionReturnNs"]
            if key in publication_matches:
                publication = publication_matches[key]
                call["precedingPublication"] = publication
                call["conditionReleaseSplit"] = dict(
                    beforeReleaseNs=[
                        publication["releaseBeforeNs"]-call["conditionStartNs"],
                        publication["releaseAfterNs"]-call["conditionStartNs"],
                    ],
                    afterReleaseNs=[
                        call["conditionReturnNs"]-publication["releaseAfterNs"],
                        call["conditionReturnNs"]-publication["releaseBeforeNs"],
                    ],
                )
                call["afterConditionReturn"] = downstream_waits(call)
                after_exit = resume_dispatch(call)
                if after_exit is not None:
                    call["postCollectorDispatch"] = after_exit
                peers = [resume["resumeNs"] for resume in cohort if resume["carrier"] != call["carrier"]]
                if peers:
                    slack = max(0, call["resumeNs"] - max(peers))
                    call["fixedPeerResumeSensitivity"] = dict(
                        peerLastResumeNs=max(peers),
                        receiverIsLastCollectorExit=call["collectorExitNs"] == row["collectorEndNs"],
                        receiverIsLastResume=call["resumeNs"] == row["resumeNs"],
                        resumeSlackNs=slack,
                        maximumReductionNs=min(slack, call["runnableToSwitchNs"]),
                    )
    slow_by_site = defaultdict(Counter)
    slow_rounds = [rounds[i] for i in sorted(slowest)]
    slow_starts = [row["collectorBeginNs"] for row in slow_rounds]
    for carrier, vm, start, end, site in join["conditionSites"]:
        index = bisect_right(slow_starts, start) - 1
        if index >= 0 and end <= slow_rounds[index]["collectorEndNs"]:
            slow_by_site[site]["calls"] += 1
            slow_by_site[site]["inclusiveWaitNs"] += end - start
            candidates = [p for p in publications[vm, carrier, site]
                          if start <= p["releaseBeforeNs"] <= p["releaseAfterNs"] <= end]
            if len(candidates) == 1:
                candidate = candidates[0]
                site_totals = slow_by_site[site]
                site_totals["uniquePublicationCandidates"] += 1
                site_totals["beforeCandidateLowerNs"] += candidate["releaseBeforeNs"] - start
                site_totals["beforeCandidateUpperNs"] += candidate["releaseAfterNs"] - start
                site_totals["afterCandidateLowerNs"] += end - candidate["releaseAfterNs"]
                site_totals["afterCandidateUpperNs"] += end - candidate["releaseBeforeNs"]
    def fixed_suffix_sensitivity(index, calls):
        row = rounds[index]
        cohort = resumes[bisect_left(resume_times, row["collectorBeginNs"]):
                         bisect_right(resume_times, row["resumeNs"])]
        if len(cohort) != 3 or {carrier for _, carrier, _ in cohort} != {"0", "1", "2"}:
            raise ValueError("Incomplete R3 resume cohort")
        by_carrier = {carrier: stamp for stamp, carrier, _ in cohort}
        advance = Counter()
        for call in calls:
            carrier = call["carrier"]
            if by_carrier[carrier] != call["resumeNs"]:
                raise ValueError("Dispatch call belongs to a different resume")
            advance[carrier] += call["runnableToSwitchNs"]
        return row["resumeNs"] - max(stamp - advance[carrier] for carrier, stamp in by_carrier.items())

    signal_slow_sensitivity = []
    for index, calls in sorted(slow_call_witnesses.items()):
        matched = list({
            (call["carrier"], call["resumeNs"]): call | call["postCollectorDispatch"]
            for call in calls if call.get("postCollectorDispatch", {}).get("signalCall") is not None
        }.values())
        if matched:
            earliest_wait = {}
            for call in calls:
                key = call["carrier"], call["vm"], call["resumeNs"]
                earliest_wait[key] = min(call["conditionReturnNs"],
                                         earliest_wait.get(key, call["conditionReturnNs"]))
            same_round_tails = summarize_tail(trace, {
                (carrier, vm, wait_end, resume)
                for (carrier, vm, resume), wait_end in earliest_wait.items()
            })
            signal_slow_sensitivity.append(dict(
                recordedCollectorTails=same_round_tails,
                requestNs=rounds[index]["requestNs"],
                pauseNs=rounds[index]["requestToLastResume"],
                matchedCarriers=sorted({call["carrier"] for call in matched}),
                jointAdvanceNs=fixed_suffix_sensitivity(index, matched),
                individualAdvanceNs={
                    carrier: fixed_suffix_sensitivity(index, [call for call in matched
                                                             if call["carrier"] == carrier])
                    for carrier in sorted({call["carrier"] for call in matched})
                },
            ))

    dispatch_by_site = defaultdict(list)
    for call in ordered_publication_calls:
        dispatch_by_site[call["barrierSiteLine"]].append(call)
    publication_dispatch = {}
    for site, calls in dispatch_by_site.items():
        ordered = sorted(calls, key=lambda call: call["runnableToSwitchNs"])
        samples = [call["runnableToSwitchNs"] for call in ordered]
        count = len(samples)
        long_calls_by_round = defaultdict(list)
        for call in ordered:
            if call["runnableToSwitchNs"] < 100_000:
                continue
            index = bisect_right(starts, call["collectorExitNs"]) - 1
            if (index >= 0 and call["collectorExitNs"] <= rounds[index]["collectorEndNs"]
                    and call["resumeNs"] <= rounds[index]["resumeNs"]):
                long_calls_by_round[index].append(call)
        longest = ordered[-1]
        index = bisect_right(starts, longest["collectorExitNs"]) - 1
        round_witness = None
        if (index >= 0 and longest["collectorExitNs"] <= rounds[index]["collectorEndNs"]
                and longest["resumeNs"] <= rounds[index]["resumeNs"]):
            row = rounds[index]
            round_witness = dict(pauseNs=row["requestToLastResume"],
                                 receiverResumeBeforeLastNs=row["resumeNs"]-longest["resumeNs"],
                                 resumeToOperationNs=longest["firstOperationCompletionNs"]-longest["resumeNs"])
        publication_dispatch[site] = dict(
            count=count, medianNs=(samples[(count-1)//2]+samples[count//2])/2,
            p95Ns=samples[(95*count+99)//100-1], maxNs=samples[-1],
            atLeast100Us=sum(value >= 100_000 for value in samples),
            topFourShare=sum(samples[-4:])/sum(samples),
            longestCallRound=round_witness,
            longCallRounds=[
                dict(requestNs=rounds[index]["requestNs"], pauseNs=rounds[index]["requestToLastResume"],
                     lastResumeCarrier=rounds[index]["lastResumeProcessor"], count=len(group),
                     fixedSuffixSensitivityNs=fixed_suffix_sensitivity(index, group),
                     downstreamByCall=[
                         dict(carrier=call["carrier"], conditionReturnNs=call["conditionReturnNs"],
                              **downstream_waits(call))
                         for call in group
                     ],
                     **summarize_slow_call_coverage(rounds[index], group))
                for index, group in sorted(long_calls_by_round.items())
            ],
        )
    return dict(publicationJoinCounts=dict(publication_counts),
                kernelAnchorHeaderMatches=scheduler.get("anchorHeaderMatches", {}),
                postCollectorDispatchScopes=dict(post_collector_counts),
                syncTreeRunnableEmitterClasses=dict(sync_tree_emitter_classes),
                syncTreeRunnableEmitterCarriers=dict(sync_tree_emitter_carriers),
                syncTreeRunnableEmitterScopes=dict(sync_tree_emitter_scopes),
                syncTreeSignalCalls=len(sync_tree_signal_witnesses),
                syncTreeSignalWitnesses=sync_tree_signal_witnesses,
                syncTreeSlowSignalSensitivity=signal_slow_sensitivity,
                postCollectorDispatchTimings=post_collector_timings,
                postCollectorRoundCoverage=post_collector_round_coverage,
                orderedPublicationDispatchBySite=publication_dispatch,
                orderedPublicationCalls=ordered_publication_calls,
                slowWaitSites=dict(slow_by_site), slowUserTails=summarize_slow_user_tails(trace, [rounds[i] for i in sorted(slowest)]),
                slowOverlapDiagnostics=overlap_diagnostics, wholeRounds=len(rounds), slowestRounds=len(slowest),
                slowestIntersectingRawExport=len(overlapping), joinedWholeRounds=len(selected),
                joinedSlowestRounds=[dict(rounds[i], exactCalls=slow_call_witnesses[i],
                                         observedDispatch=summarize_slow_call_coverage(
                                             rounds[i], slow_call_witnesses[i]))
                                     for i in sorted(selected & slowest)],
                unmatchedLocalReturns=unmatched,
                joinedSlowTailPhases=summarize_tail(trace, slow_returns) if slow_returns else None)


if __name__ == "__main__":
    trace = Path(sys.argv[1])
    if sys.argv[2] == "--collector-tail":
        print(json.dumps(summarize_tail(trace), indent=2))
        sys.exit(0)
    if sys.argv[2] == "--kdebug-xml":
        scheduler = read_kdebug(trace, sys.stdin.buffer)
    else:
        scheduler = json.loads(Path(sys.argv[2]).read_text())
    first_operations = None
    if len(sys.argv) > 3:
        decoded = json.loads(Path(sys.argv[3]).read_text())
        if decoded["traceSha256"] != hashlib.sha256(trace.read_bytes()).hexdigest():
            raise ValueError("First-operation witness belongs to a different trace")
        first_operations = decoded["completedFirstOperations"]
    result = summarize(trace, scheduler, first_operations)
    if len(sys.argv) > 4:
        result["wholeRoundCoverage"] = audit_whole_rounds(
            trace, result, scheduler, json.loads(Path(sys.argv[4]).read_text()), first_operations)
    del result["conditionCallOutcomes"], result["conditionSites"]
    print(json.dumps(result, indent=2))
