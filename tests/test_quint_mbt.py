"""Unit & integration tests for Quint V2 ITF MBT replay, F6REST01 Reverse Trace
Validation, and ASCENT scenario-driven multicore tool routing.
"""
from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from gambit_smp.quint_mbt import (
    check_binding_v2_itf_invariants,
    check_gc_ffi_v2_itf_invariants,
    check_smp_migration_wills_v2_itf_invariants,
    parse_itf_trace,
    replay_binding_itf_against_gambit,
    route_multicore_obligations,
    validate_f6rest01_trace,
)
from gambit_smp.rest_observation import HEADER, KINDS, MAGIC, RECORD

ROOT = Path(__file__).resolve().parents[1]
ITF_DIR = ROOT / ".cache/tasks/family7-gambit-opt/quint-v2-itf"
OPT_RUNTIME = ROOT / ".cache/tasks/family7-gambit-opt/runtime"


def _write_synthetic_f6rest01(path: Path, event_kinds: list[str], *, dropped: int = 0) -> None:
    kind_to_id = {name: idx + 1 for idx, name in enumerate(KINDS)}
    capacity = max(64, len(event_kinds) + 8)
    header = HEADER.pack(MAGIC, 1, capacity, len(event_kinds), dropped, 0, 16, 0)
    buf = bytearray(header)
    for seq, name in enumerate(event_kinds, start=1):
        buf.extend(RECORD.pack(seq, kind_to_id[name], *([0] * 14)))
    path.write_bytes(bytes(buf))


class QuintV2MbtAndAscentRoutingTest(unittest.TestCase):
    def test_quint_v2_safe_itf_traces_pass_invariants(self) -> None:
        for seed in (101, 202, 303):
            b_trace = parse_itf_trace(ITF_DIR / f"binding_v2_seed{seed}.itf.json")
            b_res = check_binding_v2_itf_invariants(b_trace)
            self.assertTrue(b_res["safe"], f"binding seed {seed} failed: {b_res['violations']}")
            self.assertGreater(b_res["stateCount"], 5)

            g_trace = parse_itf_trace(ITF_DIR / f"gc_ffi_v2_seed{seed}.itf.json")
            g_res = check_gc_ffi_v2_itf_invariants(g_trace)
            self.assertTrue(g_res["safe"], f"gc_ffi seed {seed} failed: {g_res['violations']}")
            self.assertGreater(g_res["stateCount"], 5)

    def test_quint_v2_mutant_counterexample_traces_detected(self) -> None:
        # Mutant 1: writer publishes primFlag before primCellAddr
        t1 = parse_itf_trace(ITF_DIR / "mutant_reorder_cex.itf.json")
        r1 = check_binding_v2_itf_invariants(t1)
        self.assertFalse(r1["safe"])
        invs1 = {v["invariant"] for v in r1["violations"]}
        self.assertTrue(
            "flagImpliesInitializedCell" in invs1 or "noDanglingDereference" in invs1,
            invs1,
        )

        # Mutant 2: unscrubbed RawF64 scanned by GC (v10 thread_state.scm bug)
        t2 = parse_itf_trace(ITF_DIR / "mutant_raw_f64_cex.itf.json")
        r2 = check_gc_ffi_v2_itf_invariants(t2)
        self.assertFalse(r2["safe"])
        invs2 = {v["invariant"] for v in r2["violations"]}
        self.assertIn("noRawF64ScannedByGc", invs2)

        # Mutant 3: missed FFI root slot while object stays alive via other root
        t3 = parse_itf_trace(ITF_DIR / "mutant_missed_ffi_cex.itf.json")
        r3 = check_gc_ffi_v2_itf_invariants(t3)
        self.assertFalse(r3["safe"])
        invs3 = {v["invariant"] for v in r3["violations"]}
        self.assertTrue(
            "ffiSlotMatchesLiveObject" in invs3 or "noDanglingFfiArg" in invs3,
            invs3,
        )

    def test_quint_v2_smp_migration_and_wills_safe_and_mutants(self) -> None:
        safe_trace = parse_itf_trace(ITF_DIR / "smp_mig_wills_v2.itf.json")
        r_safe = check_smp_migration_wills_v2_itf_invariants(safe_trace)
        self.assertTrue(r_safe["safe"], r_safe["violations"])

        expected_kills = [
            ("smp_buggy_unpinned_migration_cex.itf.json", "noSelfStealLivelock"),
            ("smp_buggy_clobber_r1_cex.itf.json", "cReturnValuePreserved"),
            ("smp_buggy_reentrant_will_mutex_cex.itf.json", "noWillMutexSelfDeadlock"),
        ]
        for fname, inv_name in expected_kills:
            cex = parse_itf_trace(ITF_DIR / fname)
            res = check_smp_migration_wills_v2_itf_invariants(cex)
            self.assertFalse(res["safe"], f"{fname} should violate {inv_name}")
            self.assertIn(inv_name, {v["invariant"] for v in res["violations"]})

    def test_live_itf_mbt_replay_against_gambit_smp_p2(self) -> None:
        replay = replay_binding_itf_against_gambit(
            ITF_DIR / "binding_v2_seed101.itf.json",
            OPT_RUNTIME,
            processors=2,
        )
        self.assertTrue(replay["passed"], replay)
        self.assertIn("QUINT-MBT-REPLAY-PASS", replay["stdout"])

    def test_f6rest01_reverse_trace_validation_positive_and_negative(self) -> None:
        with tempfile.TemporaryDirectory(prefix="f6rest-tv-") as td:
            d = Path(td)
            # Positive legal trace: fast group + slow grant with GC boundary
            good = d / "good.trace"
            _write_synthetic_f6rest01(
                good,
                [
                    "group-open", "group-enter", "group-store", "group-commit", "group-retired",
                    "group-open", "group-demand", "gc-begin", "gc-end", "group-grant",
                    "group-store", "group-commit", "group-retired",
                ],
            )
            res_good = validate_f6rest01_trace(good)
            self.assertTrue(res_good["valid"], res_good)
            self.assertEqual(res_good["maxConsecutiveSlowGrantsWithoutGc"], 1)

            # Negative 1: group-store before grant/enter
            bad_store = d / "bad_store.trace"
            _write_synthetic_f6rest01(bad_store, ["group-open", "group-store", "group-retired"])
            res_bad_store = validate_f6rest01_trace(bad_store)
            self.assertFalse(res_bad_store["valid"])
            self.assertIn(
                "store-or-commit-requires-active-grant",
                {v["rule"] for v in res_bad_store["violations"]},
            )

            # Negative 2: fudge-zone thrashing (simulating opt2 631 slow grants with 0 GC!)
            bad_thrash = d / "bad_thrash.trace"
            thrash_events: list[str] = []
            for _ in range(40):
                thrash_events.extend(["group-open", "group-grant", "group-store", "group-commit", "group-retired"])
            _write_synthetic_f6rest01(bad_thrash, thrash_events)
            res_thrash = validate_f6rest01_trace(bad_thrash, max_consecutive_slow_grants_without_gc=32)
            self.assertFalse(res_thrash["valid"])
            self.assertIn("fudge-zone-thrash-guard", {v["rule"] for v in res_thrash["violations"]})
            self.assertEqual(res_thrash["maxConsecutiveSlowGrantsWithoutGc"], 40)

    def test_f6rest01_reverse_trace_validation_on_live_native_o1_trace(self) -> None:
        # Capture a genuine binary F6REST01 wire trace directly from compiled 45d83511 runtime!
        from gambit_smp.stress_gsc_link4 import _init_wire_trace_file

        with tempfile.TemporaryDirectory(prefix="f6rest-live-") as td:
            d = Path(td)
            trace_file = d / "live_control_a.trace"
            _init_wire_trace_file(trace_file, capacity=65536)
            src = d / "probe.scm"
            src.write_text(
                "(declare (standard-bindings) (extended-bindings))\n"
                "(define (mk n) (let loop ((i 0) (acc '())) "
                "(if (< i n) (loop (+ i 1) (cons (vector i (+ i 1) (+ i 2)) acc)) (length acc))))\n"
                "(display (list 'LIVE-TRACE-OK (mk 6000))) (newline)\n",
                encoding="utf-8",
            )
            o1 = d / "probe.o1"
            rt_opts = f"~~bin={OPT_RUNTIME / 'bin'},~~lib={OPT_RUNTIME / 'lib'},~~include={OPT_RUNTIME / 'include'}"
            env = dict(os.environ)
            env["PATH"] = f"/usr/bin:/bin:/opt/homebrew/bin:{env.get('PATH', '')}"
            env["___GAMBIT_REST_OBSERVATION"] = str(trace_file)
            c_res = subprocess.run(
                [str(OPT_RUNTIME / "gsc/gsc"), f"-:p1,{rt_opts}", "-o", str(o1), str(src)],
                capture_output=True, text=True, env=env, timeout=60,
            )
            self.assertEqual(c_res.returncode, 0, c_res.stderr)
            r_res = subprocess.run(
                [str(OPT_RUNTIME / "gsi/gsi"), f"-:p2,{rt_opts}", str(o1)],
                capture_output=True, text=True, env=env, timeout=60,
            )
            self.assertEqual(r_res.returncode, 0, r_res.stderr)
            self.assertIn("LIVE-TRACE-OK", r_res.stdout)
            tv = validate_f6rest01_trace(trace_file)
            self.assertTrue(tv["valid"], tv)
            self.assertEqual(tv["dropped"], 0)

    def test_ascent_scenario_driven_tool_routing(self) -> None:
        # 1. Host environment routing
        plan = route_multicore_obligations(ROOT)
        self.assertTrue(plan["allCovered"], plan["uncovered"])
        self.assertEqual(plan["uncovered"], [])

        # Weak-memory C11 obligations MUST match BOTH cbmc-weak-mm AND genmc as candidates
        # (no hardcoded precedence: installed goes to executableTools, uninstalled to optionalUninstalledTools)
        p02 = plan["routing"]["p0-2-binding-read-activation"]
        all_p02_tools = set(p02["executableTools"]) | set(p02["optionalUninstalledTools"])
        self.assertTrue({"cbmc-weak-mm", "genmc", "clang-tsan", "quint-mbt", "gambit-multicore-pbt"} <= all_p02_tools)
        self.assertTrue(p02["multiEngineRequired"])

        # Wire-trace obligation routes to quint-trace-val
        f67 = plan["routing"]["f6-f7-write-group-rest-cut"]
        self.assertIn("quint-trace-val", f67["executableTools"])
        self.assertIn("lean4", f67["executableTools"])

        # 2. Simulated environment WITH genmc installed: genmc moves automatically to executableTools
        with_genmc = route_multicore_obligations(
            ROOT,
            installed_tools=["cbmc-weak-mm", "genmc", "clang-tsan", "quint-mbt", "quint-trace-val", "lean4", "gambit-multicore-pbt"],
        )
        self.assertIn("genmc", with_genmc["routing"]["p0-2-binding-read-activation"]["executableTools"])
        self.assertEqual(with_genmc["routing"]["p0-2-binding-read-activation"]["optionalUninstalledTools"], [])


if __name__ == "__main__":
    unittest.main()
