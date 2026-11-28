"""Check clock anchors against a carrier identity and a measured call interval."""
from bisect import bisect_right
from collections import defaultdict
import json
import math
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def read_clock(trace: Path, exported: Path) -> dict:
    lines = trace.read_text().splitlines()
    if not lines or lines[-1] != "trace-invalid=0":
        raise ValueError("Missing complete DEV trace")
    tids = {}
    starts = {}
    brackets = {}
    for line in lines[:-1]:
        fields = line.split()
        if len(fields) != 4:
            continue
        carrier, vm, kind, value = fields
        carrier, value = int(carrier), int(value)
        key = (carrier, vm)
        if kind == "T":
            tids[value] = carrier
        elif kind == "S":
            starts[key] = value
        elif kind == "Z":
            begin = starts.pop(key)
            if value < begin:
                raise ValueError("Inverted signpost call interval")
            brackets[carrier, begin] = value

    root = ET.parse(exported)
    refs = {node.get("id"): node for node in root.iter() if node.get("id")}

    def resolve(node):
        return refs.get(node.get("ref"), node)

    groups = defaultdict(dict)
    for node in root.iter("node"):
        schema = node.find("schema")
        if schema is None or schema.get("name") != "os-signpost-arg":
            continue
        for row in node.findall("row"):
            fields = {field.tag: field for item in row for field in [resolve(item)]}
            if fields["signpost-name"].text != "GambitGCClock" or fields["subsystem"].text != "org.gambit.dev.gc":
                continue
            tid = int(resolve(fields["thread"].find("tid")).text)
            stamp = int(fields["event-time"].text)
            groups[tid, stamp][fields["string"].text] = int(fields["uint64"].text)

    anchors = defaultdict(list)
    for (tid, stamp), values in groups.items():
        if set(values) != {"arg0", "arg1"} or tids.get(tid) != values["arg1"]:
            continue
        begin, carrier = values["arg0"], values["arg1"]
        end = brackets.get((carrier, begin))
        anchors[carrier].append(dict(tid=tid, eventNs=stamp, beginNs=begin, endNs=end))

    bounds = {}
    for carrier, values in anchors.items():
        limited = [x for x in values if x["endNs"] is not None]
        if limited:
            lower = max(x["eventNs"] - x["endNs"] for x in limited)
            upper = min(x["eventNs"] - x["beginNs"] for x in limited)
            bounds[carrier] = dict(count=len(limited), minOffsetNs=lower, maxOffsetNs=upper,
                                   consistent=lower <= upper)
    common = None
    if bounds and len(bounds) == len(tids):
        lower = max(x["minOffsetNs"] for x in bounds.values())
        upper = min(x["maxOffsetNs"] for x in bounds.values())
        common = dict(minOffsetNs=lower, maxOffsetNs=upper, consistent=lower <= upper)
    return dict(threadIds=tids, anchors=dict(anchors), bounds=bounds, common=common)


def locate_runnable(trace: Path, clock: dict, scheduler: dict) -> dict:
    common = clock["common"]
    if common is None or not common["consistent"]:
        return {"reason": "no consistent bracketed offset"}
    lo, hi = common["minOffsetNs"], common["maxOffsetNs"]
    pending = {}
    windows = defaultdict(list)
    for line in trace.read_text().splitlines():
        fields = line.split()
        if len(fields) != 4:
            continue
        carrier, vm, kind, value = fields
        key = int(carrier), vm
        if kind == "A":
            pending[key] = int(value)
        elif kind in ("U", "M"):
            start = pending.pop(key, None)
            if kind == "U" and start is not None:
                windows[key[0]].append((start, int(value)))

    result = {}
    for tid, carrier in clock["threadIds"].items():
        if scheduler["carriers"].get(str(tid)) != carrier:
            raise ValueError("Scheduler carrier identity differs")
        anchors = [x["beginNs"] for x in clock["anchors"].get(carrier, []) if x["endNs"] is not None]
        if len(anchors) < 2:
            continue
        complete = sorted((a, u) for a, u in windows[carrier] if min(anchors) <= a <= u <= max(anchors))
        starts = [a for a, _ in complete]
        matches = defaultdict(int)
        delays = []
        overwritten = 0
        wake = None

        def window(t):
            i = bisect_right(starts, t - hi) - 1
            return i if i >= 0 and t - lo <= complete[i][1] else None

        for t, code, qualifier in sorted(scheduler["events"].get(str(tid), [])):
            if qualifier != 0:
                continue
            if code == 6:  # MACH_MAKE_RUNNABLE, target TID in arg1.
                i = window(t)
                if wake is not None:
                    overwritten += 1
                wake = (i, t) if i is not None else None
                if i is not None:
                    matches[i] += 1
            elif code in (0, 2) and wake is not None:
                # MACH_SCHED / MACH_STACK_HANDOFF, destination TID in arg2.
                if window(t) == wake[0] and t > wake[1]:
                    delays.append(t - wake[1])
                wake = None
        delays.sort()
        result[carrier] = dict(
            completeWindows=len(complete), windowsWithRunnable=len(matches),
            runnableRecords=sum(matches.values()), overwrittenBeforeSwitch=overwritten,
            matchedSwitchRecords=len(delays),
            wakeToRecordedSwitchP95Ns=delays[math.ceil(.95 * len(delays)) - 1] if delays else None,
        )
    return result


if __name__ == "__main__":
    trace = Path(sys.argv[1])
    result = read_clock(trace, Path(sys.argv[2]))
    if len(sys.argv) == 4:
        result["runnableWithinGc"] = locate_runnable(trace, result, json.loads(Path(sys.argv[3]).read_text()))
    print(json.dumps(result))
