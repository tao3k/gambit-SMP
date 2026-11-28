"""Check native write-group events from an exact Gate 2 Make generation."""

from pathlib import Path
import re

from gambit_smp.framework import digest, relative
from gambit_smp.gate2_evidence import SITES, require, sha_bytes, span
from gambit_smp.recipes import fields, read_json, source_path
from gambit_smp.rest_observation import HEADER, RECORD, create_trace, decode_trace

KIND = "native-frame"
TRACE = "gate2-frame.bin"
OBLIGATIONS = ("oldFrameBacking", "savedHandlerFp", "unwoundCallerFp",
               "firstWrite", "noCommittedReplay")
OLD_FRAME, GRANTED = 1, 3  # Observer phases from rest-observation.inc.


def validate_spec(spec):
    fields(spec, ("schema", "sourceLockSha256", "sites"))
    require(spec["schema"] == "family6-gate2-native.v1"
            and re.fullmatch("[0-9a-f]{64}", spec["sourceLockSha256"]),
            "Gate 2 native witness needs the selected source lock")
    fields(spec["sites"], (), SITES)
    for site in spec["sites"].values():
        fields(site, ("program", "openToEnter", "capacity", "emission", "gvmSpan"))
        fields(site["emission"], ("run", "receiptSha256", "step"))
        require(isinstance(site["program"], str) and site["program"].endswith(".scm")
                and type(site["capacity"]) is int and 1 <= site["capacity"] <= 1000000,
                "bounded Gate 2 recorder capacity required")
    return spec


def gap(reason):
    return {check: dict(status="MISSING", reason=reason) for check in OBLIGATIONS}


def checked_source(root, recorded, selected, inputs):
    from gambit_smp.ordered_stress_audit import checked_json
    from gambit_smp.source_capabilities import validate_source_lock

    require(recorded == selected and inputs[selected["path"]] == selected["sha256"],
            "native witness belongs to another source lock")
    lock = checked_json(relative(root, selected["path"]), selected["sha256"])
    validate_source_lock(lock)
    require(digest(relative(root, lock["patch"])) == lock["patchSha256"] == inputs[lock["patch"]],
            "source lock patch bytes differ")
    return lock


def replay(root, runtime, origin, graph, args, witness, directory, review):
    spec = validate_spec(read_json(witness))
    bootstrap = origin["bootstrap"]
    selected_lock = dict(path=origin["lock"], sha256=spec["sourceLockSha256"])
    lock = checked_source(root, review["sourceLock"], selected_lock, origin["producerInputs"])
    require(accounted_lock(lock, origin["lockedFiles"]) and
            review.get("lockedPatch", {}).get("status") == "PASS", "materialized source differs from the lock")
    site = args["subject"]
    unit, image, procedure, _, _ = SITES[site]
    config = spec["sites"].get(site)
    require(config, "native witness did not declare this site")
    require(review["correspondenceReview"]["receiptSha256"] == digest(relative(root, args["correspondence"])),
            "native correspondence declaration changed")
    checked = next(row for row in review["correspondenceReview"]["sites"] if row["id"] == site)
    require(checked["status"] == "PASS" and checked["schemeGvm"]["status"] == "PASS" and
            all(review["linkSelection"][image]["handlerCompileInputs"][name]["status"] == "PASS"
                for name in ("lib/_kernel.o", "lib/mem.o")),
            checked.get("reason", "selected correspondence or handler compile lineage is open"))
    from gambit_smp.gate2_collection import EMISSION, collection_origin, read_collection
    from gambit_smp.item12_retained import emission_locator
    from gambit_smp.ordered_stress_audit import checked_json

    ref = config["emission"]
    emission = relative(root, ref["run"])
    producer = relative(root, args["run"])
    require(emission != directory.parent.parent, "native witness cannot reference its own collection")
    receipt = checked_json(emission / "receipt.json", ref["receiptSha256"])
    origin_run = collection_origin(root, emission, args["gsiSha256"], review["bootstrapStep"])
    require(origin_run == (producer, review["bootstrapStep"]),
            "native witness GVM observation selects another bootstrap")
    collection = read_collection(root, emission, outer=receipt, expected_run=producer,
                                 expected_gsi=args["gsiSha256"], expected_step=review["bootstrapStep"],
                                 kinds={EMISSION})
    matches = [row for row in collection["steps"] if row["step"] == ref["step"] and row["kind"] == EMISSION
               and row["subject"] == unit + ".scm" and row["status"] == "PASS"]
    require(len(matches) == 1, "no verified same-invocation GVM/C pair for the selected site")
    pair, = matches
    emission_locator(runtime, emission, pair, dict(id=site, schemeSource=unit + ".scm", procedure=procedure),
                     dict(gvmSpan=config["gvmSpan"], **{name: checked[name]
                         for name in ("schemeSpan", "gvmEdge", "regions")}))
    c_name = unit + ".c"
    source = relative(runtime, c_name)
    c_sha = digest(source)
    require(c_sha == graph["actions"]["emit", c_name]["outputSha256"],
            "native witness generated C differs from its Make action")
    raw = source.read_bytes()
    require(sha_bytes(raw) == c_sha, "generated C changed during native plan")
    c_lines = raw.splitlines(keepends=True)
    selected = b"".join(span(c_lines, config["openToEnter"]))
    def note(op):
        return re.compile(rb'^\s*___GATE2_' + op + rb'\(___ps,"' + re.escape(procedure.encode())
                          + rb'",(\d+),___LBL\(\1\),___fp\);\s*$')

    open_pattern = note(b"OPEN")
    lines = selected.splitlines()
    require(len(lines) >= 3 and (opening := open_pattern.fullmatch(lines[0])) is not None
            and (entering := note(b"ENTER").fullmatch(lines[-1])) is not None
            and opening[1] == entering[1], "generated C lacks the selected old-view and entry hooks")
    label = int(opening[1])
    require(sum(match[1] == opening[1] for line in c_lines if (match := open_pattern.fullmatch(line))) == 1,
            "procedure and retry label do not identify a unique generated group")
    enter_line = config["openToEnter"]["end"]
    require(any(region["start"] <= enter_line < region["end"] for region in checked["regions"])
            and b"___group_demand_enter" in c_lines[enter_line]
            and b"___LBL(" + str(label).encode() + b")" in c_lines[enter_line],
            "native markers do not lead to the checked site's admission")
    require(any(re.search(rb"___DEF_SLBL\(" + opening[1] + rb",___L" + opening[1] + rb"_"
                          + re.escape(SITES[site][3].encode()) + rb"\)", line) for line in lines),
            "entry markers do not enclose the selected procedure's retry label")
    # The scope is the actual emitter's pre-enter interval. An unknown effect
    # in this interval needs its own decoder before negative coverage can pass.
    body = [line.strip() for line in lines[1:-1] if line.strip()]
    spills = []
    for line in body:
        if match := re.match(rb"___SET_STK\((-?\d+),___CAST\(___WORD,___F64_TO_U64\(", line):
            spills.append(int(match[1]))
        else:
            require(re.fullmatch(rb"___DEF_[A-Z]+\([^;]*\)|___SET_(?:R[0-9]+|F64)\([^;]*\)", line),
                    "unknown pre-enter effect in selected generated C")
    exe = relative(runtime, image)
    inventory = bootstrap["outputs"]["runtime"]["identity"]
    preserved_sources = {"gsc/_t-c-2.scm", "lib/_kernel.scm", "lib/mem.c", "lib/rest-observation.h",
                         "lib/_mem/allocation-limits.inc", "lib/_mem/rest-observation.inc",
                         "lib/_mem/memory-lifecycle.inc", "include/_gambit/runtime_protocols.h.in"}
    require(all(name in origin["lockedFiles"] and
                inventory[name]["sha256"] == origin["lockedFiles"][name]["sha256"]
                for name in preserved_sources),
            "source lock does not bind the observer, generated contract and handler source inputs")
    memory_inputs = ("lib/mem.c", "lib/_mem/allocation-limits.inc", "lib/_mem/rest-observation.inc",
                     "lib/_mem/memory-lifecycle.inc", "lib/rest-observation.h")
    names = (c_name, unit + ".o", image, "lib/_kernel.o", "lib/mem.o", "lib/_kernel.c",
             "include/gambit.h", *memory_inputs)
    sources = {name: digest(relative(runtime, name)) for name in names}
    require(all(sha == inventory[name]["sha256"] for name, sha in sources.items())
            and sources[c_name] == c_sha,
            "native observer input differs from retained Make inventory")
    for name in (unit + ".o", "lib/_kernel.o"):
        compiled = graph["actions"]["object", name]["headersAndSources"]
        require(compiled[str(graph["workspace"] / "include/gambit.h")] == sources["include/gambit.h"],
                "native object did not compile against the checked observer header")
    compiled = graph["actions"]["object", "lib/mem.o"]["headersAndSources"]
    for name in memory_inputs:
        require(compiled[str(graph["workspace"] / name)] == sources[name],
                "memory object did not compile the checked observer implementation")
    check_kernel = relative(runtime, "lib/_kernel.c").read_bytes()
    require(b"___gate2_unwound(___ps, gate2_handler_fp, ___fp, fs)" in check_kernel
            and b"#define ___GATE2_OPEN" in relative(runtime, "include/gambit.h").read_bytes()
            and all(any(flag in {"-D___GAMBIT_REST_OBSERVATION", "-D___GAMBIT_REST_OBSERVATION=1"}
                        for flag in graph["actions"]["object", name]["executedArgv"])
                    for name in (unit + ".o", "lib/_kernel.o", "lib/mem.o")),
            "linked producer has no independent Gate 2 unwind or entry instrumentation")
    program = source_path(root, config["program"])
    require(program.is_file() and program.suffix == ".scm", "native-frame workload must be a Scheme file")
    family = f"-:p1,~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    argv = [str(exe), family, "-f"]
    if image == "gsc/gsc":
        argv += ["-c", "-o", str(directory / "gate2-drive.c")]
    argv.append(str(program))
    env = dict(GAMBIT_REST_OBSERVATION=str(directory / TRACE), GAMBIT_GATE2_PROCEDURE=procedure,
               GAMBIT_GATE2_LABEL=str(label), GAMBIT_GATE2_CASE=str(tuple(SITES).index(site) + 1))
    return argv, env, dict(site=site, sourceLockSha256=origin["sha"], image=image, sources=sources,
                           executableSha256=inventory[image]["sha256"], generatedCSha256=c_sha,
                           correspondenceSha256=review["correspondenceReview"]["receiptSha256"],
                           emission=ref, gvmSha256=pair["evidence"]["gvmSha256"],
                           programSha256=digest(program), label=label, preEnterSpills=spills,
                           capacity=config["capacity"], settlementScope="through-next-write-group")


def accounted_lock(lock, inventory):
    return all(inventory.get(name, {}).get("sha256") == row["candidateSha256"]
               for name, row in lock["files"].items())


def measure(binding, trace, command, case):
    def check(status, reason):
        return dict(status=status, reason=reason)

    missing = "selected phase-1 group event is absent"
    kinds = {name: [] for name in ("open", "enter", "backing", "demand", "saved", "unwound",
                                  "grant", "heap-grant", "store", "adjust", "commit", "retired")}
    windows = {}
    for event in trace["events"]:
        if not event["kind"].startswith("group-"):
            continue
        require(event["case"] == case, "native frame recorder selected another case")
        key = (event["actor"], event["activation"], event["attempt"], *event["values"][:2])
        require(all(key), "unbound group actor, activation, invocation, context or label")
        windows.setdefault(key, []).append(event)
    framed = (trace["complete"] and trace["events"] and trace["events"][0]["kind"] == "case-begin"
              and trace["events"][-1]["kind"] == "case-end"
              and sum(e["kind"] in {"case-begin", "case-end"} for e in trace["events"]) == 2
              and all(e["case"] == case for e in trace["events"]))
    require(all(e["values"][6] == binding["label"] for rows in windows.values()
                for e in rows if e["kind"] in {"group-open", "group-enter"}),
            "trace names another generated retry label")
    terminal = (command.get("exit") == 0 and command.get("timeout") is False
                and all(command.get(k) is True for k in ("parentReaped", "processGroupQuiescent",
                                                          "streamCaptureComplete")))
    if not framed or not terminal:
        return {key: check("MISSING", "a naturally completed lossless case stream is required")
                for key in OBLIGATIONS}
    result = {key: check("MISSING", missing) for key in OBLIGATIONS}
    runs = []
    for events in windows.values():
        rows = {name: [] for name in kinds}
        for e in events:
            rows[e["kind"][6:]].append(e)
        if not rows["demand"]:
            continue
        checks = {name: check("MISSING", missing) for name in OBLIGATIONS}
        if rows["enter"] and rows["demand"]:
            entry = rows["enter"][0]["seq"]
            bound = rows["backing"][0]["seq"] if rows["backing"] else rows["demand"][0]["seq"]
            early = [e for e in rows["store"] + rows["adjust"] if entry < e["seq"] < bound]
            if rows["unwound"]:
                unwind = rows["unwound"][0]["seq"]
                grant = rows["grant"][0]["seq"] if rows["grant"] else events[-1]["seq"] + 1
                early.extend(e for e in rows["store"] + rows["adjust"] if unwind < e["seq"] < grant)
        else:
            early = []

        def verify(name, needed, predicate, reason):
            if any(not rows[k] for k in needed):
                return
            selected = [rows[k] for k in needed]
            checks[name] = check("PASS" if predicate(*selected) else "MISMATCH", reason)
            ids = sorted({e["seq"] for group in selected for e in group})
            checks[name]["events"] = ids[:64]
            checks[name]["eventCount"] = len(ids)
            if checks[name]["status"] == "MISMATCH":
                checks[name]["witness"] = (events if len(events) <= 32 else events[:16] + events[-16:])

        def old(opens, entries, backing, demand):
            if len(opens) != len(backing) or len(opens) != len(demand) or len(opens) != 1:
                return False
            o, b, d, e = opens[0], backing[0], demand[0], entries[0]
            fp, lo, hi, limit, label, _ = o["values"][2:]
            bfp, blo, bhi, words, extent, live = b["values"][2:]
            dfp, soft, phase, dt, _, _ = d["values"][2:]
            stores = [s for s in rows["store"] if o["seq"] < s["seq"] < e["seq"]]
            offsets = []
            for s in stores:
                sfp, address, phase_n, _, _, _ = s["values"][2:]
                if sfp != fp or not lo <= address < hi or (fp - address) % 8 or phase_n != OLD_FRAME:
                    return False
                offsets.append((fp - address) // 8)
            return (0 < lo <= fp <= hi and fp >= max(soft, limit) and o["epoch"] == e["epoch"] == d["epoch"]
                    and label == binding["label"] == e["values"][6]
                    and e["values"][2] == fp == bfp == dfp and (blo, bhi) == (lo, hi)
                    and 0 < extent <= 65 and phase == 1 and dt > 0 and 0 < words <= (fp - lo) // 8
                    and offsets == binding["preEnterSpills"]
                    and all(0 <= -offset < extent - 1 and not (live & (1 << -offset)) for offset in offsets)
                    and not any(o["seq"] < a["seq"] < e["seq"] for a in rows["adjust"])
                    and o["seq"] < e["seq"] < b["seq"] < d["seq"])

        def saved(demand, saves):
            d, s = demand[0], saves[0]
            return (len(demand) == len(saves) == 1 and d["seq"] < s["seq"]
                    and d["values"][5] == s["values"][3] > 0 and s["values"][2] > 0
                    and s["values"][4] == 0)

        def unwound(saves, unwinds, grants):
            s, u, g = saves[0], unwinds[0], grants[0]
            handler, caller, cfs, align, overhead, attempt = u["values"][2:]
            return (len(saves) == len(unwinds) == len(grants) == 1 and s["seq"] < u["seq"] < g["seq"]
                    and s["values"][2] == handler and s["values"][3] == attempt == g["values"][6]
                    and g["values"][7] == 8 and align == 4 and overhead == 12 and cfs < 2**31
                    and caller == handler + 8 * ((-cfs) % align + overhead)
                    and caller == g["values"][2] and s["values"][5] == u["epoch"] == g["epoch"])

        def first(grants, heaps, stores):
            g = grants[0]
            cursor, lo, hi, words, attempt, word = g["values"][2:]
            effects = [e for e in stores if g["seq"] < e["seq"]]
            if len(grants) != 1 or len(heaps) != 1 or not effects or word != 8 or not 0 < lo <= cursor <= hi:
                return False
            h = heaps[0]
            hp, heap_words, heap_attempt = h["values"][2:5]
            if not (g["seq"] < h["seq"] < effects[0]["seq"] and 0 < hp and heap_attempt == attempt
                    and h["epoch"] == g["epoch"]):
                return False
            if not effects[0]["values"][2]:
                e = effects[0]
                if not (e["epoch"] == g["epoch"] and e["values"][4:6] == [GRANTED, attempt]
                        and hp <= e["values"][3] < hp + 8 * heap_words and e["values"][3] % 8 == 0):
                    return False
            effects = [e for e in effects if e["values"][2]]
            if not effects:
                return False
            s = effects[0]
            for a in rows["adjust"]:
                if g["seq"] < a["seq"] < s["seq"]:
                    old_fp, new_fp, delta, phase, observed, _ = a["values"][2:]
                    delta = delta if delta < 2**63 else delta - 2**64
                    if old_fp != cursor or new_fp != cursor - 8*delta or phase != GRANTED or observed != attempt:
                        return False
                    cursor = new_fp
            fp, address, phase, observed, _, _ = s["values"][2:]
            return (s["epoch"] == g["epoch"] and fp == cursor and observed == attempt and phase == GRANTED
                    and lo <= cursor <= hi and lo <= g["values"][2] - words * 8 <= address < hi
                    and address % 8 == 0)

        def commit(grants, commits, retired):
            g, c, end = grants[0], commits[0], retired[0]
            observed = c["values"][2]
            return (len(grants) == len(commits) == len(retired) == 1 and g["seq"] < c["seq"] < end["seq"]
                    and observed == g["values"][6] == end["values"][2] > 0
                    and c["epoch"] == g["epoch"] and events[-1] == end
                    and any(g["seq"] < e["seq"] < c["seq"] and e["values"][4:6] == [GRANTED, observed]
                            for e in rows["store"])
                    and not any(c["seq"] < s["seq"] for kind in ("store", "adjust", "enter", "open", "demand")
                                for s in rows[kind]))

        verify("oldFrameBacking", ("open", "enter", "backing", "demand"), old,
               "pre-enter spills and phase-1 read must use backed old slots before handler displacement")
        verify("savedHandlerFp", ("demand", "saved"), saved, "independent handler save for the same demand")
        verify("unwoundCallerFp", ("saved", "unwound", "grant"), unwound,
               "handler view decodes to the independently sampled caller and new grant")
        verify("firstWrite", ("unwound", "grant", "heap-grant", "store"),
               lambda unwinds, grants, heaps, stores: (
                   len(unwinds) == 1 and unwinds[0]["values"][3] == grants[0]["values"][2]
                   and unwinds[0]["seq"] < grants[0]["seq"] and first(grants, heaps, stores)),
               "first physical effect and first stack store use the independently repaired grant")
        if rows["grant"] and not any(s["seq"] > rows["grant"][0]["seq"] and s["values"][2]
                                     for s in rows["store"]):
            checks["firstWrite"] = check("MISSING", "no independently observed stack store after retry grant")
        if early:
            checks["firstWrite"] = dict(check("MISMATCH",
                "an effect ran between old entry and handler backing, or between unwind and fresh grant"),
                witness=early[:32])
        verify("noCommittedReplay", ("grant", "commit", "retired"), commit,
               "one settlement followed by a bounded effects-free interval through retirement")
        runs.append(checks)
    if runs:
        for name in OBLIGATIONS:
            result[name] = next((r[name] for r in runs if r[name]["status"] == "MISMATCH"),
                                next((r[name] for r in runs if r[name]["status"] != "PASS"), runs[0][name]))
    elif windows:
        result = gap("the selected generated group ran without a phase-1 demand")
    else:
        result = gap("workload did not reach the selected procedure and retry label")
    return result


def run(ctx, argv, env, binding):
    directory = ctx.directory
    path = directory / TRACE
    inode = create_trace(path, binding["capacity"])
    ctx.env = dict(ctx.env, **env)
    ctx.run(KIND, argv, directory, ctx.remaining())
    stat = path.lstat()
    require([stat.st_dev, stat.st_ino] == inode and not path.is_symlink(), "native trace file was replaced")
    evidence = report(path, binding, ctx.commands[-1], int(env["GAMBIT_GATE2_CASE"]))
    if binding["image"] == "gsc/gsc":
        product = directory / "gate2-drive.c"
        evidence["driveCSha256"] = digest(product) if product.is_file() and not product.is_symlink() else None
        require(evidence["status"] != "PASS" or evidence["driveCSha256"],
                "compiler witness did not finish emitting its workload")
    return evidence


def report(path, binding, command, case):
    trace = decode_trace(path.read_bytes())
    require(path.stat().st_size == HEADER.size + RECORD.size * binding["capacity"],
            "native observer changed recorder geometry")
    checks = measure(binding, trace, command, case)
    states = {c["status"] for c in checks.values()}
    status = "MISMATCH" if "MISMATCH" in states else "PASS" if states == {"PASS"} else "MISSING"
    return dict(binding, checks=checks, status=status, traceSha256=trace["digest"],
                transport={key: trace[key] for key in ("reserved", "dropped", "holes", "closed", "complete")},
                runtimeAdmitted=False)
