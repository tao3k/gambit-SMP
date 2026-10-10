import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import debug_runtime
import debug_capture
import upstream_audit

sys.path.insert(0, str(Path(__file__).parent))
SPEC = importlib.util.spec_from_file_location("check_gambit", Path(__file__).with_name("check_gambit.py"))
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)


class GateTests(unittest.TestCase):
    def test_debug_launch_environment_excludes_inherited_sdk_overrides(self):
        with patch.dict("debug_capture.os.environ", {"PATH": "/wrong", "SDKROOT": "/wrong",
                        "CPATH": "/wrong", "LIBRARY_PATH": "/wrong", "KEEP": "yes"}, clear=True):
            environment = dict(item.split("=", 1) for item in debug_capture.launch_environment())
        self.assertEqual("yes", environment["KEEP"])
        self.assertEqual("/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin", environment["PATH"])
        self.assertFalse(set(environment) & {"SDKROOT", "CPATH", "LIBRARY_PATH"})

    def test_upstream_inventory_rejects_partial_or_mismatched_diff(self):
        files = [{"filename": "lib/mem.c", "additions": 2, "deletions": 1, "sha": "blob"}]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "files.json").write_text(json.dumps(files))
            with patch("upstream_audit.subprocess.check_output", return_value="2\t1\tlib/mem.c\n"):
                self.assertEqual("runtime-c", upstream_audit.inventory(root)[0]["role"])
            for result in ("", "3\t1\tlib/mem.c\n", "2\t1\tlib/mem.c\n2\t1\tlib/mem.c\n"):
                with patch("upstream_audit.subprocess.check_output", return_value=result):
                    with self.assertRaises(ValueError):
                        upstream_audit.inventory(root)

    def test_pr988_frozen_alias_and_ownership_controls_are_distinct(self):
        predicates = {
            "lockSafe": lambda s: s["stage"] == 2 and s["nested"] and s["alias"],
            "ownershipSafe": lambda s: s["stage"] == 4 and s["writerDone"] and s["destinationValue"] != 2,
        }
        for invariant, violates in predicates.items():
            trace = json.loads((gate.MODELS / "counterexamples" /
                                ("rehash_lock_ownership-" + invariant + ".json")).read_text())
            self.assertEqual(gate.digest(gate.MODELS / "rehash_lock_ownership.qnt"), trace["modelSha256"])
            self.assertEqual(invariant, trace["invariant"])
            self.assertFalse(any(violates(s) for s in trace["states"][:-1]))
            self.assertTrue(violates(trace["states"][-1]))
            self.assertEqual(invariant == "lockSafe", trace["states"][0]["exclusive"])

    def test_headroom_binding_rejects_floor_only_and_max_heap_bypass(self):
        source = ("#define compute_nb_msections_allocation_headroom() "
                  "(___CEILING_DIV(normal_overflow_reserve,___MSECTION_SIZE)+1)\n"
                  "___SCMOBJ ___setup_mem_vmstate\n"
                  "SET_MAX(init_nb_sections,(compute_nb_msections_min(___vms->processor_count)+"
                  "compute_nb_msections_allocation_headroom()));\n"
                  "___SCMOBJ ___setup_mem ___PVOID\n"
                  "___HIDDEN ___BOOL resize_heap\n"
                  "SET_MAX(lower_bound_nb_sections,(compute_nb_msections_needed(occupied_words_movable)+"
                  "nb_msections_stacks));"
                  "lower_bound_nb_sections+=compute_nb_msections_allocation_headroom();"
                  "SET_MIN(target_nb_sections,upper_bound_nb_sections);\n"
                  "___HIDDEN void mark_registers\n")
        self.assertEqual("passed", gate.heap_headroom(source)["heapHeadroomSourceBinding"])
        for invalid in (source.replace("+1)", ")", 1),
                        source.replace("SET_MIN(target_nb_sections,upper_bound_nb_sections);", "")):
            with self.assertRaises(ValueError):
                gate.heap_headroom(invalid)

    def test_capture_requires_actual_complete_nonduplicate_snapshots(self):
        samples = [{"stopId": i, "threads": [{"mailboxes": {}}]} for i in (1, 2)]
        output = "SNAPSHOT-RECEIPT " + json.dumps({"diagnosticOnly": True, "samples": samples}) + "\nSNAPSHOT-CAPTURE-OK\n"
        self.assertEqual(2, len(debug_capture.admitted_capture(output, 2)["samples"]))
        for invalid in (output.replace("SNAPSHOT-CAPTURE-OK", ""), output + "Traceback (most recent call last)",
                        output.replace('"stopId": 2', '"stopId": 1')):
            with self.assertRaises(ValueError):
                debug_capture.admitted_capture(invalid, 2)

    def test_wait_source_binding_rejects_wrong_mutex_and_signal_order(self):
        source = ("#define SYNC_GET_MSG(expr) ___MUTEX_LOCK(___ps->sync_mut);"
                  "if((expr)==SYNC_WAITING) ___sync_wait(___ps);"
                  "___MUTEX_UNLOCK(___ps->sync_mut);\n"
                  "#define SYNC_SEND_MSG(ps,field,val) ___MUTEX_LOCK(ps->sync_mut);"
                  "ps->field=val; ___MUTEX_UNLOCK(ps->sync_mut);"
                  "___CONDVAR_SIGNAL(ps->sync_cv);\n"
                  "___HIDDEN void ___sync_wait\n"
                  "___CONDVAR_WAIT(___ps->sync_cv,___ps->sync_mut);\n"
                  "___HIDDEN int barrier_sync_op\n")
        self.assertEqual("passed", gate.sync_protocol(source)["syncWaitSourceBinding"])
        invalids = (source.replace("___ps->sync_cv,___ps->sync_mut", "___ps->sync_cv,other"),
                    source.replace("___MUTEX_UNLOCK(ps->sync_mut);___CONDVAR_SIGNAL(ps->sync_cv);",
                                   "___CONDVAR_SIGNAL(ps->sync_cv);___MUTEX_UNLOCK(ps->sync_mut);"))
        for invalid in invalids:
            with self.assertRaises(ValueError):
                gate.sync_protocol(invalid)

    def test_characterization_is_not_a_fabricated_old_fixed_repair(self):
        case = {"mode": "characterization", "invariants": ["safe", "channelsDrained"]}
        self.assertEqual([("protocol", "safe", "init"),
                          ("protocol", "channelsDrained", "init")], gate.model_checks(case))
        self.assertEqual([("old", "safe", "initOld"), ("fixed", "safe", "initFixed")],
                         gate.model_checks({}))

    def test_characterization_receipt_requires_every_declared_invariant(self):
        case = {"id": "sync_tree_rounds", "mode": "characterization",
                "invariants": ["safe", "channelsDrained"]}
        rows = [{"case": case["id"], "variant": "protocol", "invariant": inv,
                 "initializer": "init", "accepted": True, "evidence": "finite-state-TLC",
                 "modelSha256": gate.digest(gate.MODELS / "sync_tree_rounds.qnt")}
                for inv in case["invariants"]]
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / "receipt.json"
            receipt.write_text(json.dumps({"results": rows}))
            self.assertEqual(rows, gate.reuse_model_receipt(receipt, case))
            for invalid in (rows[:1], rows + [rows[0]],
                            [{**row, "variant": "fixed"} for row in rows]):
                receipt.write_text(json.dumps({"results": invalid}))
                with self.assertRaises(ValueError):
                    gate.reuse_model_receipt(receipt, case)

    def test_sync_binding_rejects_single_sided_and_misordered_fences(self):
        fence = "___SHARED_MEMORY_BARRIER();"
        source = ("#define SYNC_GET_MSG(expr) do { while ((expr)==SYNC_WAITING) {} "
                  + fence + " } while (0)\n#define SYNC_SEND_MSG(ps,field,val) do { "
                  + fence + " ps->field=val; " + fence
                  + " } while (0)\n___HIDDEN void ___sync_wait")
        self.assertEqual("passed", gate.sync_messages(source)["syncMessageSourceBinding"])
        for invalid in (source.replace(fence, "", 1),
                        source.replace(fence + " ps->field=val;", "ps->field=val; " + fence)):
            with self.assertRaises(ValueError):
                gate.sync_messages(invalid)

    def test_debug_build_requires_one_gnu_compiler_command(self):
        with patch("debug_runtime.subprocess.check_output", return_value="gcc-16 -c -o mem.o mem.c\n"):
            self.assertEqual("gcc-16", debug_runtime.make_command(Path("."), "mem.c", "mem.o")[0])
        for output in ("clang -c -o mem.o mem.c\n", "gcc-16 -c mem.c\n",
                       "echo build\ngcc-16 -c -o mem.o mem.c\n"):
            with patch("debug_runtime.subprocess.check_output", return_value=output):
                with self.assertRaises(ValueError):
                    debug_runtime.make_command(Path("."), "mem.c", "mem.o")

    def test_stack_binding_rejects_the_observed_wrong_function_edit(self):
        null = "___CAST(___WORD,___CAST(___msection*,NULL))"
        slot = "-___FIRST_BREAK_FRAME_STACK_MSECTION"
        init = "___FP_SET_STK(alloc_stack_ptr," + slot + "," + null + ")"
        copy = "___FP_SET_STK(___ps->stack_break," + slot + "," + null + ")"
        source = ("___SCMOBJ ___setup_mem_pstate\n" + init
                  + "___ps->stack_break=alloc_stack_ptr;\n___SCMOBJ ___setup_mem_vmstate\n"
                  + "___HIDDEN void move_continuation\n" + copy
                  + "\n___HIDDEN void determine_occupied_words\n"
                  + "___BOOL ___stack_limit_debug\n" + init
                  + "\n___WORD ___stack_overflow_undo_if_possible\n")
        self.assertEqual("passed", gate.stack_markers(source)["stackMarkerSourceBinding"])
        with self.assertRaisesRegex(ValueError, "unassigned"):
            gate.stack_markers(source.replace(init, copy, 1))
        with self.assertRaisesRegex(ValueError, "copied marker"):
            gate.stack_markers(source.replace(copy, init))
        with self.assertRaisesRegex(ValueError, "boundary"):
            gate.stack_markers(source.replace("___SCMOBJ ___setup_mem_vmstate\n", ""))

    def test_frozen_counterexamples_match_models_and_violate_safety(self):
        unsafe = {
            "table_decode": lambda s: not s["lookupOK"] or s["invalidRehasher"],
            "pipe_wait": lambda s: s["waiting"] and s["data"],
            "heap_floor": lambda s: s["sections"] < 2 * s["processors"],
            "root_marker": lambda s: s["phase"] == 4 and s["markerAddress"] != s["objectAddress"],
            "gc_scan_barrier": lambda s: s["badScan"],
            "gc_rc_roots": lambda s: not(s["retained0"] and s["retained1"]),
            "gc_key_tags": lambda s: s["keyTag"] or (s["phase"] == 2 and not(s["needRehash"] and s["fallback"])),
            "gc_stack_marker": lambda s: s["restoredSection"] != 0,
            "gc_hash_policy": lambda s: not s["found"],
            "gc_stack_lifecycle": lambda s: s["invalidWrite"] or s["currentTouched"] or (s["phase"] == 3 and s["restored"] != 0),
            "gc_rehash_protocol": lambda s: not(s["keyIntact"] and s["found"]),
            "gc_key_reference": lambda s: not s["found"],
            "serial_number_transaction": lambda s: s["result0"] != 0 and s["result1"] != 0 and
                ((s["result0"] != s["result1"]) if s["sameObject"] else (s["result0"] == s["result1"])),
            "sync_message_acquire": lambda s: s["phase"] == 2 and s["consumedPayload"] != 1,
            "sync_wait_handshake": lambda s: s["receiver"] == 4 and s["sender"] == 4 and not s["wakePending"],
            "heap_allocation_headroom": lambda s: s["phase"] == 1 and
                (s["sections"] - s["assigned"]) * 131072 - 204808 < 131072,
            "exec_gc_polling": lambda s: s["phase"] == 2 and s["pendingGC"] and
                not(s["nonblocking"] or s["joinedGC"]),
            "lazy_vm_startup": lambda s: s["returnedReady"] and s["processors"] != 4,
        }
        for name, violates in unsafe.items():
            with self.subTest(case=name):
                trace = json.loads((gate.MODELS / "counterexamples" / (name + ".json")).read_text())
                self.assertEqual(gate.digest(gate.MODELS / (trace["case"] + ".qnt")), trace["modelSha256"])
                self.assertFalse(any(violates(s) for s in trace["states"][:-1]))
                self.assertTrue(violates(trace["states"][-1]))

        for suffix, predicate in (("decodeSafe", lambda s: s["decoding"]),
                                  ("uniformSafe", lambda s: s["kind"] == 1),
                                  ("gcSafe", lambda s: s["gcRounds"] > 0)):
            trace = json.loads((gate.MODELS / "counterexamples" / ("gc_rehash_protocol-" + suffix + ".json")).read_text())
            self.assertEqual(gate.digest(gate.MODELS / "gc_rehash_protocol.qnt"), trace["modelSha256"])
            self.assertEqual(suffix, trace["invariant"])
            violates = lambda s: predicate(s) and not(s["keyIntact"] and s["found"])
            self.assertFalse(any(violates(s) for s in trace["states"][:-1]))
            self.assertTrue(violates(trace["states"][-1]))
            if suffix == "gcSafe":
                self.assertTrue(trace["states"][-1]["decoderRepair"])
                self.assertTrue(trace["states"][-1]["decoding"])

        for suffix, acquire, release in (("acquireSafe", False, True), ("releaseSafe", True, False)):
            trace = json.loads((gate.MODELS / "counterexamples" / ("sync_message_acquire-" + suffix + ".json")).read_text())
            self.assertEqual(gate.digest(gate.MODELS / "sync_message_acquire.qnt"), trace["modelSha256"])
            self.assertEqual(acquire, trace["states"][0]["acquire"])
            self.assertEqual(release, trace["states"][0]["release"])
            violates = lambda s: s["phase"] == 2 and s["consumedPayload"] != 1
            self.assertFalse(any(violates(s) for s in trace["states"][:-1]))
            self.assertTrue(violates(trace["states"][-1]))

        trace = json.loads((gate.MODELS / "counterexamples" / "exec_gc_polling-configSafe.json").read_text())
        self.assertEqual(gate.digest(gate.MODELS / "exec_gc_polling.qnt"), trace["modelSha256"])
        self.assertTrue(trace["states"][0]["polling"])
        self.assertFalse(trace["states"][0]["checkConfig"])
        self.assertTrue(unsafe["exec_gc_polling"](trace["states"][-1]))

    def test_report_catalog_has_no_duplicate_candidates(self):
        catalog = json.loads((gate.MODELS / "report_catalog.json").read_text())
        numbers = [report["number"] for report in catalog["reports"]]
        self.assertEqual(25, len(numbers))
        self.assertEqual(len(numbers), len(set(numbers)))
        reports = {report["number"]: report for report in catalog["reports"]}
        self.assertEqual(reports[1024]["headRefOid"], reports[1026]["headRefOid"])
        self.assertEqual([1022, 1041], reports[1050]["dependencies"])
        self.assertFalse(reports[988]["allGreenVerified"])
        self.assertEqual(0, reports[988]["exactHeadChecks"]["checkRuns"])

    def test_reused_model_receipt_requires_matching_successful_variants(self):
        case = {"id": "gc_hash_policy"}
        rows = [{"case": case["id"], "variant": variant, "accepted": True,
                 "evidence": "finite-state-TLC",
                 "modelSha256": gate.digest(gate.MODELS / "gc_hash_policy.qnt")}
                for variant in ("old", "fixed")]
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / "receipt.json"
            receipt.write_text(json.dumps({"results": rows}))
            self.assertEqual(rows, gate.reuse_model_receipt(receipt, case))
            for field, bad_value in (("accepted", False), ("variant", "old"),
                                     ("modelSha256", "stale"), ("evidence", "simulation")):
                invalid = json.loads(json.dumps(rows))
                invalid[1][field] = bad_value
                receipt.write_text(json.dumps({"results": invalid}))
                with self.assertRaises(ValueError):
                    gate.reuse_model_receipt(receipt, case)

    def test_each_reported_failure_requires_its_own_counterexample(self):
        case = {"id": "gc_rehash_protocol", "oldInvariants": ["safe", "decodeSafe", "uniformSafe", "gcSafe"],
                "oldInitializers": {"gcSafe": "initDecodedOld"}}
        rows = [{"case": case["id"], "variant": variant, "invariant": invariant,
                 "accepted": True, "evidence": "finite-state-TLC",
                 "initializer": case["oldInitializers"].get(invariant, "initOld") if variant == "old" else "initFixed",
                 "modelSha256": gate.digest(gate.MODELS / "gc_rehash_protocol.qnt")}
                for variant, invariant in [("old", inv) for inv in case["oldInvariants"]] + [("fixed", "safe")]]
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / "receipt.json"
            receipt.write_text(json.dumps({"results": rows}))
            self.assertEqual(rows, gate.reuse_model_receipt(receipt, case))
            for invalid in (rows[1:], rows + [rows[0]], rows[:-1]):
                receipt.write_text(json.dumps({"results": invalid}))
                with self.assertRaises(ValueError):
                    gate.reuse_model_receipt(receipt, case)
            invalid = json.loads(json.dumps(rows))
            invalid[3]["initializer"] = "initOld"
            receipt.write_text(json.dumps({"results": invalid}))
            with self.assertRaises(ValueError):
                gate.reuse_model_receipt(receipt, case)

    def test_expected_counterexample_is_not_any_failure(self):
        self.assertFalse(gate.admitted_model(1, "typechecking failed", False, True))
        self.assertFalse(gate.admitted_model(0, "Error: Invariant q_inv is violated.", False, True))
        self.assertFalse(gate.admitted_model(1, "Error: Invariant q_inv is violated.", True, True))
        self.assertTrue(gate.admitted_model(1, "Error: Invariant q_inv is violated.", False, True))

    def test_counterexample_decoder_fails_closed(self):
        output = "State 1: <init>\n/\\ x = FALSE\n/\\ n = 1\n\nState 2: <step>\n/\\ x = TRUE\n/\\ n = 2\n"
        self.assertEqual([{"x": False, "n": 1}, {"x": True, "n": 2}], gate.counterexample(output)["states"])
        for malformed in ("error", output.replace("TRUE", "<<1, 2>>"), output.replace("/\\ n = 2\n", "")):
            with self.assertRaises(ValueError):
                gate.counterexample(malformed)

    def test_positive_requires_exhausted_state_queue(self):
        output = "Model checking completed. No error has been found.\n4 distinct states found, 0 states left on queue."
        self.assertTrue(gate.admitted_model(0, output, False, False))
        self.assertFalse(gate.admitted_model(1, output, False, False))
        self.assertFalse(gate.admitted_model(0, output.replace("0 states", "3 states"), False, False))
        self.assertFalse(gate.admitted_model(0, "[ok] No violation found", False, False))

    def test_timeout_is_reaped(self):
        code, _, timed_out, _ = gate.execute([sys.executable, "-c", "import time; time.sleep(10)"], gate.ROOT, 0.05)
        self.assertTrue(timed_out)
        self.assertNotEqual(0, code)

    def test_native_binary_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            binary = Path(directory) / "gsi"
            binary.write_bytes(b"fixture, not executable")
            receipt = Path(directory) / "identity.json"
            identity = {"sourceRevision": json.loads((gate.MODELS / "cases.json").read_text())["sourceRevision"],
                        "binarySha256": gate.digest(binary), "multipleThreadedVms": True, "patches": []}
            receipt.write_text(json.dumps(identity))
            self.assertEqual(identity, gate.native_identity(binary, receipt))
            with self.assertRaisesRegex(ValueError, "baseline rerun denied"):
                gate.native_identity(binary, receipt, {"pr": 1038})
            binary.write_bytes(b"changed")
            with self.assertRaisesRegex(ValueError, "digest mismatch"):
                gate.native_identity(binary, receipt)


if __name__ == "__main__":
    unittest.main()
