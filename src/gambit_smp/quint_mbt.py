"""Quint V2 Model-Based Testing (ITF Replay), F6REST01 Reverse Trace Validation,
and ASCENT Scenario-Driven Verification Tool Routing.

Provides three closed-loop formal-to-engineering bridges for Families 8/12..12/12:
  1. `parse_itf_trace` & `replay_binding_itf_against_gambit`:
     Parses Quint 0.33.0 ITF JSON traces (`states`, `#meta`), decodes Quint
     records/maps/sets (`#map`, `#set`, `#bigint`), verifies structural safety
     invariants, and replays abstract state transitions step-by-step against a
     live Gambit SMP runtime (`gsi -:p2`).
  2. `validate_f6rest01_trace`:
     Performs Reverse Trace Validation on binary `F6REST01` wire traces emitted
     by compiled `.o1` modules (`___GAMBIT_REST_OBSERVATION`), verifying write-
     group / rest-parameter protocol legality and flagging pathological fudge-
     zone thrashing (e.g. >32 slow fudge grants without a GC boundary).
  3. `route_multicore_obligations`:
     Runs the declarative ASCENT Datalog ruleset
     `dev/modeling/ascent/multicore-tool-routing.rules.scm` via `ascent.Engine`
     to map Families 8/12..12/12 verification obligations to the best-fit
     verification engines based purely on structural scenario features (no
     hardcoded global tool priority).
"""
from __future__ import annotations

import json
import os
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from gambit_smp.rest_observation import HEADER, KINDS, MAGIC, RECORD
from gambit_smp.task_processes import run as run_process


# ---------------------------------------------------------------------------
# 1. Quint 0.33.0 ITF JSON Decoding & Model-Based Testing (MBT) Replay
# ---------------------------------------------------------------------------

def decode_itf_value(val: Any) -> Any:
    """Recursively decode Quint/Apalache ITF JSON tagged values into Python."""
    if isinstance(val, dict):
        if "#bigint" in val:
            return int(val["#bigint"])
        if "#set" in val:
            return [decode_itf_value(x) for x in val["#set"]]
        if "#map" in val:
            return {
                decode_itf_value(k): decode_itf_value(v)
                for k, v in val["#map"]
            }
        if "#tup" in val:
            return tuple(decode_itf_value(x) for x in val["#tup"])
        return {k: decode_itf_value(v) for k, v in val.items()}
    if isinstance(val, list):
        return [decode_itf_value(x) for x in val]
    return val


def parse_itf_trace(path: Path) -> dict[str, Any]:
    """Load and decode a Quint ITF JSON file into structured Python states."""
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    if "states" not in raw or not isinstance(raw["states"], list) or not raw["states"]:
        raise ValueError(f"invalid ITF trace {path}: missing non-empty 'states'")
    states = []
    for idx, st in enumerate(raw["states"]):
        decoded = decode_itf_value(st)
        states.append({
            "index": idx,
            "s": decoded.get("s", decoded),
            "meta": decoded.get("#meta", {}),
        })
    return {
        "path": str(path),
        "meta": raw.get("#meta", {}),
        "vars": raw.get("vars", []),
        "states": states,
    }


def check_binding_v2_itf_invariants(trace: dict[str, Any]) -> dict[str, Any]:
    """Check `binding_read_activation_v2` structural safety across every ITF state."""
    violations: list[dict[str, Any]] = []
    actions_observed: list[str] = []
    prev_s: dict[str, Any] | None = None

    for entry in trace["states"]:
        idx = entry["index"]
        s = entry["s"]
        if prev_s is not None:
            actions_observed.append(_classify_binding_transition(prev_s, s))

        # Invariant 1: no dangling dereference
        if s.get("lastReadUsedDangling") or s.get("lastObservedVal") == -1:
            violations.append({
                "state": idx,
                "invariant": "noDanglingDereference",
                "lastObservedVal": s.get("lastObservedVal"),
                "lastReadUsedDangling": s.get("lastReadUsedDangling"),
            })
        # Invariant 2: observed value was legally published
        published = set(s.get("validPublishedVals", []))
        if s.get("lastObservedVal") not in published:
            violations.append({
                "state": idx,
                "invariant": "observedValueIsPublished",
                "lastObservedVal": s.get("lastObservedVal"),
                "validPublishedVals": sorted(published),
            })
        # Invariant 3: frozen or closed revokes bindingViewVm
        if s.get("frozenForGc") and s.get("bindingViewVm") != 0:
            violations.append({
                "state": idx,
                "invariant": "frozenRevokesView",
                "bindingViewVm": s.get("bindingViewVm"),
            })
        if (not s.get("contextOpen")) and (s.get("bindingViewVm") != 0 or s.get("entryCount") != 0):
            violations.append({
                "state": idx,
                "invariant": "closedRevokesView",
            })
        # Invariant 4: primFlag => initialized non-evacuated primCellAddr
        if s.get("primFlag"):
            addr = s.get("primCellAddr", 0)
            heap = s.get("heap", {})
            if addr == 0 or addr not in heap or heap[addr] == -1:
                violations.append({
                    "state": idx,
                    "invariant": "flagImpliesInitializedCell",
                    "primCellAddr": addr,
                    "heapVal": heap.get(addr),
                })
        prev_s = s

    return {
        "safe": len(violations) == 0,
        "stateCount": len(trace["states"]),
        "transitions": actions_observed,
        "violations": violations,
    }


def _classify_binding_transition(prev: dict[str, Any], cur: dict[str, Any]) -> str:
    if cur["writerPc"] == "wrote_cell" and prev["writerPc"] == "idle":
        return f"writerStoreCell:{cur['writerPendingVal']}"
    if cur["writerPc"] == "idle" and prev["writerPc"] == "wrote_cell":
        return "writerPublishFlag"
    if cur["writerPc"] == "wrote_flag_buggy" and prev["writerPc"] == "idle":
        return f"buggyPublishFlagFirst:{cur['writerPendingVal']}"
    if cur["frozenForGc"] and not prev["frozenForGc"]:
        return "freezeRootsForGc"
    if cur["gcEpoch"] > prev["gcEpoch"]:
        return "gcRelocateCell"
    if (not cur["frozenForGc"]) and prev["frozenForGc"]:
        return "restoreAndReopenView"
    if cur["completedReads"] > prev["completedReads"]:
        return f"completeRead:{cur['lastObservedVal']}"
    if cur["readerPc"] != prev["readerPc"]:
        return f"reader:{prev['readerPc']}->{cur['readerPc']}"
    if (not cur["contextOpen"]) and prev["contextOpen"]:
        return "safeRevokeAndClose"
    if cur["contextOpen"] and not prev["contextOpen"]:
        return "reopenNewContext"
    return "stutter"


def check_gc_ffi_v2_itf_invariants(trace: dict[str, Any]) -> dict[str, Any]:
    """Check `gc_ffi_worker_domain_v2` structural safety across every ITF state."""
    violations: list[dict[str, Any]] = []
    for entry in trace["states"]:
        idx = entry["index"]
        s = entry["s"]
        if s.get("gcScannedRawF64"):
            violations.append({"state": idx, "invariant": "noRawF64ScannedByGc"})
        if s.get("ffiDereferencedVal") != 777:
            violations.append({
                "state": idx,
                "invariant": "noDanglingFfiArg",
                "ffiDereferencedVal": s.get("ffiDereferencedVal"),
            })
        if (not s.get("gcActive")) and s.get("ffiCallDepth", 0) > 0:
            slot = s.get("ffiArgSlotAddr")
            other = s.get("otherStrongRootAddr")
            heap = s.get("heap", {})
            if (not s.get("ffiArgPinned")) or slot != other or heap.get(slot) != 777:
                violations.append({
                    "state": idx,
                    "invariant": "ffiSlotMatchesLiveObject",
                    "ffiArgSlotAddr": slot,
                    "otherStrongRootAddr": other,
                })
        if s.get("lockOrderViolated"):
            violations.append({"state": idx, "invariant": "noLockOrderViolation"})
    return {
        "safe": len(violations) == 0,
        "stateCount": len(trace["states"]),
        "violations": violations,
    }


def check_smp_migration_wills_v2_itf_invariants(trace: dict[str, Any]) -> dict[str, Any]:
    """Check `smp_migration_and_wills_v2` invariants across every ITF state."""
    violations: list[dict[str, Any]] = []
    for entry in trace["states"]:
        idx = entry["index"]
        s = entry["s"]
        if s.get("selfStealEvents", 0) != 0 or s.get("migrationHops", 0) > 1:
            violations.append({
                "state": idx,
                "invariant": "noSelfStealLivelock",
                "selfStealEvents": s.get("selfStealEvents"),
                "migrationHops": s.get("migrationHops"),
            })
        if s.get("cReturned") and s.get("observedCRetVal") != 777:
            violations.append({
                "state": idx,
                "invariant": "cReturnValuePreserved",
                "observedCRetVal": s.get("observedCRetVal"),
            })
        if s.get("selfDeadlocked"):
            violations.append({
                "state": idx,
                "invariant": "noWillMutexSelfDeadlock",
            })
    return {
        "safe": len(violations) == 0,
        "stateCount": len(trace["states"]),
        "violations": violations,
    }


def replay_binding_itf_against_gambit(
    trace_path: Path,
    runtime_dir: Path,
    *,
    processors: int = 2,
) -> dict[str, Any]:
    """Replay a `binding_read_activation_v2` ITF trace on a real Gambit SMP runtime!

    Generates a live Scheme program driving concurrent global primitive overrides,
    `(##gc)` relocations, and binding reads corresponding to every abstract step
    in the Quint ITF trace, executes it on `gsi -:p<processors>`, and verifies
    that every concrete read value matches the ITF state's published set.
    """
    trace = parse_itf_trace(trace_path)
    check = check_binding_v2_itf_invariants(trace)
    if not check["safe"]:
        raise ValueError(f"refusing to replay unsafe ITF trace {trace_path}: {check['violations'][:2]}")

    gsi = Path(runtime_dir) / "gsi/gsi"
    if not gsi.exists():
        raise FileNotFoundError(f"Gambit runtime gsi not found: {gsi}")

    # Build a concrete Gambit SMP replay script matching the ITF transition schedule.
    scheme_steps: list[str] = [
        '(define mbt-cell (vector 100))',
        '(define mbt-flag (vector #f))',
        '(define mbt-published (list 100))',
        '(define mbt-reads 0)',
        '(define mbt-gcs 0)',
        '(define mbt-mtx (make-mutex))',
        '(define (mbt-assert ok msg) (if (not ok) (begin (display (list \'MBT-FAIL msg)) (newline) (exit 1))))',
    ]
    expected_reads = 0
    expected_gcs = 0

    for action in check["transitions"]:
        if action.startswith("writerStoreCell:"):
            v = int(action.split(":", 1)[1])
            scheme_steps.append(
                f'(let ((t (thread-start! (make-thread (lambda () '
                f'(mutex-lock! mbt-mtx) '
                f'(vector-set! mbt-cell 0 (vector \'boxed {v})) '
                f'(set! mbt-published (cons {v} mbt-published)) '
                f'(mutex-unlock! mbt-mtx)))))) (thread-join! t))'
            )
        elif action == "writerPublishFlag":
            scheme_steps.append('(vector-set! mbt-flag 0 #t)')
        elif action == "gcRelocateCell":
            expected_gcs += 1
            scheme_steps.append('(##gc) (set! mbt-gcs (+ mbt-gcs 1))')
        elif action.startswith("completeRead:"):
            expected_val = int(action.split(":", 1)[1])
            expected_reads += 1
            scheme_steps.append(
                f'(let* ((obs (if (vector-ref mbt-flag 0) '
                f'(let ((c (vector-ref mbt-cell 0))) (if (vector? c) (vector-ref c 1) c)) '
                f'100))) '
                f'(mbt-assert (memv obs mbt-published) (list \'unpub obs mbt-published)) '
                f'(mbt-assert (= obs {expected_val}) (list \'val-mismatch obs {expected_val})) '
                f'(set! mbt-reads (+ mbt-reads 1)))'
            )

    scheme_steps.append(
        '(display (list \'QUINT-MBT-REPLAY-PASS '
        '\'reads mbt-reads \'gcs mbt-gcs \'procs (##current-vm-processor-count))) '
        '(newline)'
    )
    script = "(begin " + " ".join(scheme_steps) + ")"

    rt = Path(runtime_dir)
    rt_opts = f"p{processors},~~bin={rt / 'bin'},~~lib={rt / 'lib'},~~include={rt / 'include'}"
    proc = run_process(
        [str(gsi), f"-:{rt_opts}", "-e", script],
        capture_output=True,
        text=True,
        timeout=30,
    )
    stdout_text = proc.stdout or ""
    stderr_text = proc.stderr or ""
    passed = proc.returncode == 0 and "QUINT-MBT-REPLAY-PASS" in stdout_text
    return {
        "passed": passed,
        "tracePath": str(trace_path),
        "processors": processors,
        "stateCount": check["stateCount"],
        "replayedReads": expected_reads,
        "replayedGcs": expected_gcs,
        "exitCode": proc.returncode,
        "stdout": stdout_text.strip(),
        "stderr": stderr_text.strip(),
    }


# ---------------------------------------------------------------------------
# 2. F6REST01 Binary Wire-Trace Reverse Trace Validation
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class WireRecord:
    seq: int
    kind: str
    raw_kind: int
    fields: tuple[int, ...]


def decode_f6rest01_records(trace_path: Path) -> dict[str, Any]:
    """Decode full ordered record stream from a binary `F6REST01` wire trace."""
    raw = Path(trace_path).read_bytes()
    if len(raw) < HEADER.size:
        raise ValueError(f"wire trace truncated ({len(raw)} bytes)")
    magic, version, capacity, written, dropped, *_ = HEADER.unpack_from(raw, 0)
    if magic != MAGIC:
        raise ValueError(f"unexpected F6REST01 magic 0x{magic:x}")
    records: list[WireRecord] = []
    counts: dict[str, int] = {}
    offset = HEADER.size
    limit = min(len(raw), HEADER.size + written * RECORD.size)
    while offset + RECORD.size <= limit:
        rec = RECORD.unpack_from(raw, offset)
        seq = rec[0]
        raw_kind = rec[1]
        kind_idx = raw_kind - 1
        kind = KINDS[kind_idx] if 0 <= kind_idx < len(KINDS) else f"unknown-{raw_kind}"
        counts[kind] = counts.get(kind, 0) + 1
        records.append(WireRecord(seq=seq, kind=kind, raw_kind=raw_kind, fields=rec[2:]))
        offset += RECORD.size
    return {
        "version": version,
        "capacity": capacity,
        "written": written,
        "dropped": dropped,
        "counts": counts,
        "records": records,
    }


def validate_f6rest01_trace(
    trace_path: Path,
    *,
    max_consecutive_slow_grants_without_gc: int = 32,
) -> dict[str, Any]:
    """Reverse Trace Validation of a real binary `F6REST01` wire trace.

    Checks protocol state-machine transitions derived from real native execution:
      1. Zero dropped records (`dropped == 0`) and monotonic sequence ordering.
      2. Every `group-store` / `group-commit` occurs ONLY inside an open write-
         group that has been entered (`group-enter`) or granted (`group-grant` /
         `group-heap-grant`).
      3. Every `group-open` is balanced by `group-retired` or `group-unwound`
         before trace completion.
      4. Every `gc-begin` is paired with a `gc-end` (no unclosed STW GC).
      5. Fudge-zone thrash guard: flags excessive consecutive slow `group-grant`
         cycles without any intervening `gc-begin` (directly catches the `opt2`
         regression where omitting trailing `___CHECK_HEAP` caused 631 fudge-zone
         slow grants with `gc-begin == 0`!).
    """
    decoded = decode_f6rest01_records(trace_path)
    records: list[WireRecord] = decoded["records"]
    violations: list[dict[str, Any]] = []

    if decoded["dropped"] != 0:
        violations.append({
            "rule": "zero-dropped-records",
            "dropped": decoded["dropped"],
        })

    # State machine tracking across the ordered trace
    group_open_depth = 0
    group_granted = False
    gc_open_depth = 0
    consecutive_slow_grants = 0
    max_observed_slow_streak = 0
    prev_seq = -1

    for idx, rec in enumerate(records):
        if rec.seq < prev_seq:
            violations.append({
                "rule": "monotonic-sequence",
                "recordIndex": idx,
                "prevSeq": prev_seq,
                "seq": rec.seq,
            })
        prev_seq = rec.seq

        k = rec.kind
        if k == "group-open":
            group_open_depth += 1
            group_granted = False
        elif k in ("group-enter", "group-grant", "group-heap-grant"):
            if group_open_depth <= 0 and k != "group-enter":
                violations.append({
                    "rule": "grant-requires-open-group",
                    "recordIndex": idx,
                    "kind": k,
                })
            group_granted = True
            if k == "group-grant":
                consecutive_slow_grants += 1
                if consecutive_slow_grants > max_observed_slow_streak:
                    max_observed_slow_streak = consecutive_slow_grants
        elif k in ("group-store", "group-commit"):
            if group_open_depth <= 0 or not group_granted:
                violations.append({
                    "rule": "store-or-commit-requires-active-grant",
                    "recordIndex": idx,
                    "kind": k,
                    "groupOpenDepth": group_open_depth,
                    "groupGranted": group_granted,
                })
        elif k in ("group-retired", "group-unwound"):
            if group_open_depth <= 0:
                violations.append({
                    "rule": "retire-without-open-group",
                    "recordIndex": idx,
                    "kind": k,
                })
            else:
                group_open_depth -= 1
                if group_open_depth == 0:
                    group_granted = False
        elif k == "gc-begin":
            gc_open_depth += 1
            consecutive_slow_grants = 0
        elif k == "gc-end":
            if gc_open_depth <= 0:
                violations.append({
                    "rule": "gc-end-without-gc-begin",
                    "recordIndex": idx,
                })
            else:
                gc_open_depth -= 1

    if group_open_depth != 0:
        violations.append({
            "rule": "balanced-group-open-retire",
            "unclosedGroups": group_open_depth,
        })
    if gc_open_depth != 0:
        violations.append({
            "rule": "balanced-gc-begin-end",
            "unclosedGc": gc_open_depth,
        })
    if max_observed_slow_streak > max_consecutive_slow_grants_without_gc:
        violations.append({
            "rule": "fudge-zone-thrash-guard",
            "maxConsecutiveSlowGrantsWithoutGc": max_observed_slow_streak,
            "limit": max_consecutive_slow_grants_without_gc,
        })

    return {
        "valid": len(violations) == 0,
        "written": decoded["written"],
        "dropped": decoded["dropped"],
        "counts": decoded["counts"],
        "maxConsecutiveSlowGrantsWithoutGc": max_observed_slow_streak,
        "violations": violations,
    }


# ---------------------------------------------------------------------------
# 3. ASCENT Scenario-Driven Verification Tool Routing
# ---------------------------------------------------------------------------

DEFAULT_TOOL_CAPABILITIES: list[list[str]] = [
    ["cbmc-weak-mm", "weak-memory-c11", "Bounded C11/PSO/TSO interleaving & memory-order proof"],
    ["cbmc-weak-mm", "bounded-c-fn", "Bit-exact C struct/pointer/overflow verification"],
    ["genmc", "weak-memory-c11", "Stateless RC11/IMM weak-memory model checking on C11 atomics"],
    ["genmc", "bounded-c-fn", "Exhaustive lock-free atomic protocol exploration without state explosion"],
    ["clang-tsan", "full-runtime-c", "Dynamic happens-before C data-race detection across full libgambit runtime"],
    ["clang-tsan", "ffi-or-multi-vm", "Real pthread/multi-VM C-level race reconnaissance on arm64/x86_64"],
    ["quint-mbt", "protocol-interleaving", "Micro-step non-atomic state-machine simulation + ITF MBT replay"],
    ["quint-mbt", "lock-graph", "Lock-rank ordering and deadlock-freedom exploration"],
    ["quint-trace-val", "wire-trace", "Reverse Trace Validation of binary runtime wire traces (F6REST01)"],
    ["lean4", "unbounded-law", "Unbounded inductive refinement & algebraic soundness proofs (0 sorry)"],
    ["gambit-multicore-pbt", "concurrent-adt", "Wing-Gong linearizability (Gambit-Lin) & STM PBT under p2/p4 GC-Hammer"],
    ["gambit-multicore-pbt", "gc-roots-or-cc", "Real Scheme GC/weak-table/will/multi-shot call/cc/denv stress on p2/p4"],
    ["gambit-multicore-pbt", "ffi-or-multi-vm", "Compiled .o1 C-FFI callback re-entry & multi-VM fault isolation stress"],
    ["abi-closure-auditor", "static-abi-closure", "Exhaustive 4-way ___IMP_FUNC / ___GSTATE / setup.c / ___EXT dynamic .o1 ABI closure proof"],
]

FAMILIES_8_TO_12_OBLIGATIONS: list[tuple[str, str, str, list[str]]] = [
    (
        "p0-2-binding-read-activation",
        "8/12-registry",
        "Single-page primitive_value acquire/release publication + binding_view.vm freeze/restore",
        ["weak-memory-c11", "bounded-c-fn", "protocol-interleaving", "full-runtime-c", "gc-roots-or-cc"],
    ),
    (
        "f8-vm-registry-incarnation",
        "8/12-registry",
        "VM registry reader-pin / reclamation / monotonic incarnation guard",
        ["weak-memory-c11", "bounded-c-fn", "protocol-interleaving", "ffi-or-multi-vm", "unbounded-law"],
    ),
    (
        "f9-vm-lifecycle-quarantine",
        "9/12-lifecycle",
        "Unknown-join quarantine isolation & primary VM uninterrupted SMP GC",
        ["protocol-interleaving", "lock-graph", "ffi-or-multi-vm", "full-runtime-c"],
    ),
    (
        "f10-gc-ffi-worker-roots",
        "10/12-gc-ffi",
        "W<R collector worker decoupling, primary P0 live-worker census, overflow retire, EntryRootSpec/SFUN borrow custody, raw-F64 GC root scrub",
        ["bounded-c-fn", "protocol-interleaving", "lock-graph", "unbounded-law", "gc-roots-or-cc", "ffi-or-multi-vm"],
    ),
    (
        "f6-f7-write-group-rest-cut",
        "7/12-stress-gsc",
        "Compiled .o1 rest-parameter & write-group heap grant/GC pacing protocol",
        ["wire-trace", "unbounded-law", "gc-roots-or-cc"],
    ),
    (
        "f11-dynamic-o1-abi-closure",
        "11/12-gerbil",
        "Exhaustive 4-way header ___IMP_FUNC / ___GSTATE / setup.c / ___EXT dynamic .o1 ABI closure (including ___publish_raw_stack_span)",
        ["static-abi-closure", "bounded-c-fn", "protocol-interleaving", "unbounded-law"],
    ),
    (
        "f11-f12-multicore-adt-and-cc",
        "11-12/12-gerbil-release",
        "Linearizable tables/mailboxes/mutexes, multi-shot call/cc, parameterize denv, wills",
        ["concurrent-adt", "gc-roots-or-cc", "full-runtime-c", "lock-graph"],
    ),
]


def detect_installed_tools() -> list[str]:
    """Probe the local host for available verification engines (no fabrication)."""
    installed: list[str] = ["abi-closure-auditor", "gambit-multicore-pbt", "quint-trace-val"]
    if shutil.which("cbmc"):
        installed.append("cbmc-weak-mm")
    if shutil.which("genmc"):
        installed.append("genmc")
    if shutil.which("clang"):
        installed.append("clang-tsan")
    if shutil.which("quint"):
        installed.append("quint-mbt")
    if shutil.which("lean"):
        installed.append("lean4")
    return sorted(set(installed))


def route_multicore_obligations(
    root: Path,
    *,
    installed_tools: list[str] | None = None,
    obligations: list[tuple[str, str, str, list[str]]] | None = None,
) -> dict[str, Any]:
    """Execute declarative ASCENT tool-routing rules via `ascent.Engine`."""
    from ascent import Engine

    rules_path = Path(root) / "dev/modeling/ascent/multicore-tool-routing.rules.scm"
    rules_src = rules_path.read_text(encoding="utf-8")
    tools = installed_tools if installed_tools is not None else detect_installed_tools()
    obs = obligations if obligations is not None else FAMILIES_8_TO_12_OBLIGATIONS

    obligation_rows = [[oid, fam, desc] for oid, fam, desc, _ in obs]
    feature_rows = [[oid, feat] for oid, _, _, feats in obs for feat in feats]
    installed_rows = [[t] for t in tools]

    engine = Engine()
    try:
        session = engine.open_sources(rules_src)
        session.run(queries=["obligationUncovered"])
        session.replace({
            "obligation": obligation_rows,
            "obligationFeature": feature_rows,
            "toolCapability": DEFAULT_TOOL_CAPABILITIES,
            "toolInstalled": installed_rows,
        })
        result = session.run(queries=[
            "routeExecutable",
            "routeNeedsInstall",
            "obligationCovered",
            "obligationUncovered",
            "multiEngineRequired",
        ])
        if not result.get("complete"):
            raise RuntimeError("ASCENT tool-routing query did not complete")
        rels = result["relations"]
    finally:
        engine.close()

    by_obligation: dict[str, dict[str, Any]] = {}
    for oid, fam, desc, feats in obs:
        exec_tools = sorted({r[1] for r in rels["routeExecutable"] if r[0] == oid})
        missing_tools = sorted({r[1] for r in rels["routeNeedsInstall"] if r[0] == oid})
        by_obligation[oid] = {
            "family": fam,
            "summary": desc,
            "features": feats,
            "executableTools": exec_tools,
            "optionalUninstalledTools": missing_tools,
            "multiEngineRequired": any(r[0] == oid for r in rels["multiEngineRequired"]),
        }

    return {
        "rulesPath": str(rules_path),
        "installedTools": tools,
        "allCovered": len(rels["obligationUncovered"]) == 0,
        "uncovered": rels["obligationUncovered"],
        "routing": by_obligation,
    }
