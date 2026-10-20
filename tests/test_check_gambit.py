import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from gambit_smp import debug_runtime
from gambit_smp import debug_capture
from gambit_smp import upstream_audit

from gambit_smp import check_gambit as gate
from gambit_smp.evidence_index import export


class GateTests(unittest.TestCase):
    def test_continuation_chunk_control_is_granularity_not_lost_objects(self):
        name = "continuation_chunk_publication"
        trace = json.loads((gate.MODELS / "counterexamples" / (name + ".json")).read_text())
        self.assertEqual(gate.digest(gate.MODELS / (name + ".qnt")), trace["modelSha256"])
        final = trace["states"][-1]["s"]
        self.assertFalse(final["fixed"])
        self.assertEqual(0, final["committed"])
        self.assertEqual(4, final["local"])
        self.assertEqual(0, final["closed"])
        self.assertGreaterEqual(final["local"], final["boundary"])

    def test_resource_users_independent_controls_and_locked_publication(self):
        model = "sync_resource_users"
        for invariant, field, fault in (("holderSafe", "badHolder", 1),
                                        ("waiterSafe", "badWaiter", 2),
                                        ("signalSafe", "badSignal", 3),
                                        ("admissionSafe", "badAdmission", 4),
                                        ("rollbackSafe", "badRollback", 5)):
            with self.subTest(invariant=invariant):
                trace = json.loads((gate.MODELS / "counterexamples" /
                                    f"{model}-{invariant}.json").read_text())
                self.assertEqual(gate.digest(gate.MODELS / (model + ".qnt")),
                                 trace["modelSha256"])
                states = [row["s"] for row in trace["states"]]
                final = states[-1]
                self.assertEqual(fault, final["fault"])
                self.assertFalse(any(row[field] for row in states[:-1]))
                self.assertTrue(final[field])
                if invariant == "holderSafe":
                    self.assertEqual(2, final["sender"])
                    self.assertTrue(final["flag"])
                    self.assertEqual(4, final["phase"])
                elif invariant == "waiterSafe":
                    self.assertEqual(2, final["waiter"])
                elif invariant == "signalSafe":
                    self.assertEqual(3, final["sender"])
                elif invariant == "admissionSafe":
                    self.assertEqual(2, final["phase"])
                    self.assertFalse(final["sealed"])
                else:
                    self.assertEqual(1, final["outcome"])
                    self.assertTrue(final["mutexLive"])
                    self.assertFalse(final["cvLive"])

    def test_resource_retirement_controls_reject_reinit_and_naive_destroy_reuse(self):
        model = "sync_resource_retirement"
        for invariant, field, policy in (("initializationSafe", "badInit", 0),
                                         ("signalSafe", "badSignal", 1),
                                         ("generationSafe", "badEpoch", 1)):
            with self.subTest(invariant=invariant):
                trace = json.loads((gate.MODELS / "counterexamples" /
                                    f"{model}-{invariant}.json").read_text())
                self.assertEqual(gate.digest(gate.MODELS / (model + ".qnt")), trace["modelSha256"])
                states = [row["s"] for row in trace["states"]]
                self.assertEqual(policy, states[-1]["policy"])
                self.assertFalse(any(row[field] for row in states[:-1]))
                self.assertTrue(states[-1][field])

    def test_gc_entry_controls_preserve_distinct_source_obligations(self):
        model = "gc_sync_membership"
        for invariant, fault in (("quiescenceSafe", 1), ("rootSafe", 2),
                                 ("membershipSafe", 3), ("startupSafe", 4)):
            with self.subTest(invariant=invariant):
                trace = json.loads((gate.MODELS / "counterexamples" /
                                    f"{model}-{invariant}.json").read_text())
                self.assertEqual(gate.digest(gate.MODELS / (model + ".qnt")),
                                 trace["modelSha256"])
                final = trace["states"][-1]["s"]
                self.assertEqual(fault, final["fault"])
                if invariant == "quiescenceSafe":
                    self.assertGreaterEqual(final["gc"], 2)
                    self.assertFalse(set(final["live"]["$integerSet"]).issubset(
                        final["parked"]["$integerSet"]))
                elif invariant == "rootSafe":
                    self.assertGreaterEqual(final["gc"], 3)
                    self.assertNotEqual(final["complete"], final["gcMembers"])
                elif invariant == "membershipSafe":
                    self.assertNotEqual(0, final["gc"])
                    self.assertNotEqual(final["gcMembers"], final["members"])
                else:
                    self.assertTrue(final["badResume"])

    def test_gc_closure_controls_are_publication_count_ownership_and_phase_faults(self):
        model = "gc_work_closure"
        for invariant, fault in (("publicationSafe", 1), ("terminationSafe", 2),
                                 ("ownershipSafe", 3), ("phaseSafe", 4)):
            with self.subTest(invariant=invariant):
                trace = json.loads((gate.MODELS / "counterexamples" /
                                    f"{model}-{invariant}-shared-contract.json").read_text())
                self.assertEqual(gate.digest(gate.MODELS / (model + ".qnt")),
                                 trace["modelSha256"])
                final = trace["states"][-1]["s"]
                self.assertEqual(fault, final["fault"])
                if invariant == "publicationSafe":
                    self.assertTrue(final["staleRead"])
                elif invariant == "terminationSafe":
                    self.assertTrue(final["done"])
                    self.assertTrue(any(stage != 6 for stage in final["work"]))
                elif invariant == "ownershipSafe":
                    self.assertGreater(max(final["scans"]), 1)
                else:
                    self.assertTrue(final["badPhase"])

    def test_serializer_counterexample_exposes_missing_and_duplicate_rooted_keys(self):
        trace = json.loads((gate.MODELS / "counterexamples/gc_table_serialization.json").read_text())
        self.assertEqual(gate.digest(gate.MODELS / "gc_table_serialization.qnt"), trace["modelSha256"])
        final = trace["states"][-1]["s"]
        seen = [final["seen0"], final["seen1"], final["seen2"]]
        self.assertEqual(2, final["phase"])
        self.assertFalse(final["fixed"])
        self.assertIn(0, seen)
        self.assertGreater(max(seen), 1)
        self.assertEqual(3, sum(seen))

    def test_pipe_read_counterexample_is_stale_deadline_not_long_idle(self):
        trace = json.loads((gate.MODELS / "counterexamples/pipe_read_deadline.json").read_text())
        self.assertEqual(gate.digest(gate.MODELS / "pipe_read_deadline.qnt"), trace["modelSha256"])
        states = [row["s"] for row in trace["states"]]
        last = states[-1]
        self.assertTrue(last["timedOut"])
        self.assertTrue(last["stale"])
        self.assertFalse(last["fixed"])
        self.assertGreaterEqual(last["now"], last["deadline"])
        self.assertLess(last["now"] - last["started"], 2)
        self.assertFalse(any(row["stale"] for row in states[:-1]))

    def test_postcopy_counterexample_preserves_actual_assignment_shortfall(self):
        trace = json.loads((gate.MODELS / "counterexamples/gc_postcopy_headroom.json").read_text())
        self.assertEqual(gate.digest(gate.MODELS / "gc_postcopy_headroom.qnt"), trace["modelSha256"])
        state = trace["states"][-1]
        self.assertFalse(state["repair"])
        self.assertEqual(0, state["cap"])
        self.assertGreater(state["assigned"], 2 * state["processors"])
        free = (state["sections"] - state["assigned"]) * 131072 - 204808
        self.assertGreaterEqual(free, 0)
        self.assertLess(free, 131072)

    def test_first_unadmitted_model_stops_remaining_checks_and_native_execution(self):
        with tempfile.TemporaryDirectory() as temporary:
            out = Path(temporary) / "attempt"
            version = json.loads((gate.MODELS / "cases.json").read_text())["quintVersion"]
            argv = ["gambit_smp.check_gambit.py", "--case", "gc_table_header_lifetime", "--out", str(out),
                    "--native-gsi", str(out / "unused-gsi"),
                    "--toolchain-receipt", str(out / "unused-identity")]
            with patch.object(sys, "argv", argv), \
                    patch.object(gate.subprocess, "check_output", return_value=version), \
                    patch.object(gate, "check_model", return_value=(
                        {"accepted": False, "exit": 1, "timeout": False, "seconds": 0.1},
                        "checker infrastructure failed", None)) as run, \
                    contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(1, gate.main())
            self.assertEqual(1, run.call_count)
            receipt = json.loads((out / "receipt.json").read_text())
            self.assertEqual(1, len(receipt["results"]))
            self.assertEqual("model-admission-failed", receipt["stoppedAfter"]["reason"])
            self.assertEqual("not-run", receipt["native"]["status"])

    def test_special_reader_controls_do_not_conflate_header_lifetime_extent_and_layout(self):
        for invariant, fault, field in (("headerSafe", 1, "badHeader"),
                ("lifetimeSafe", 2, "useAfterRetire"), ("extentSafe", 3, "badExtent"),
                ("layoutSafe", 4, "badLayout")):
            trace = json.loads((gate.MODELS / "counterexamples" /
                ("gc_table_header_lifetime-" + invariant + ".json")).read_text())
            self.assertEqual(gate.digest(gate.MODELS / "gc_table_header_lifetime.qnt"), trace["modelSha256"])
            states = [row["s"] for row in trace["states"]]
            self.assertTrue(all(s["fault"] == fault for s in states))
            self.assertFalse(any(s[field] for s in states[:-1]))
            self.assertTrue(states[-1][field])
            for other in ("badHeader", "useAfterRetire", "badExtent", "badLayout"):
                if other != field:
                    self.assertFalse(states[-1][other])

    def test_native_child_metadata_preserves_exact_pid_and_time_window(self):
        metadata = {}
        code, output, timeout, _ = gate.execute([sys.executable, "-c", "print('ok')"], gate.ROOT, 5,
                                               metadata=metadata)
        self.assertEqual(0, code)
        self.assertFalse(timeout)
        self.assertEqual("ok", output.strip())
        self.assertGreater(metadata["pid"], 0)
        self.assertLessEqual(metadata["startedAt"], metadata["endedAt"])

    def test_shutdown_controls_preserve_source_cleanup_vs_conditional_gap(self):
        for invariant, mode, phase in (("throwSafe", 0, 2), ("guardSafe", 1, 1), ("noLossSafe", 3, 2)):
            trace = json.loads((gate.MODELS / "counterexamples" /
                ("shutdown_error_handoff-" + invariant + ".json")).read_text())
            self.assertEqual(gate.digest(gate.MODELS / "shutdown_error_handoff.qnt"), trace["modelSha256"])
            states = [row["s"] for row in trace["states"]]
            self.assertTrue(all(s["mode"] == mode for s in states))
            violates = (lambda s: s["lost"]) if mode == 3 else (lambda s: s["invalidThrow"])
            self.assertFalse(any(violates(s) for s in states[:-1]))
            self.assertTrue(violates(states[-1]))
            self.assertEqual(phase, states[-1]["phase"])
            if mode == 0:
                self.assertFalse(any(s["phase"] == 1 and s["error"] == 2 for s in states))

    def test_ffi_gc_controls_separate_roots_reload_and_return_address(self):
        history = export()["facts"]["historical_frozen_negative"]
        predicates = {
            "rootsSafe": lambda s: s["badRoots"] or (s["phase"] == 7 and s["processorRoot"] != 7 + s["epoch"]),
            "reloadSafe": lambda s: s["phase"] == 7 and (s["processorFrame"] != s["epoch"] or s["processorRoot"] != 7 + s["epoch"]),
            "returnSafe": lambda s: s["phase"] >= 6 and s["returnedRA"] != 9,
        }
        for fault, (invariant, violates) in enumerate(predicates.items(), 1):
            path = gate.MODELS / "counterexamples" / ("ffi_gc_frame_protocol-" + invariant + ".json")
            trace = json.loads(path.read_text())
            bindings = [row for row in history if tuple(row[:3]) ==
                        ("ffi_gc_frame_protocol", invariant, gate.digest(path))]
            self.assertEqual(len(bindings), 1)
            self.assertEqual(gate.digest(gate.ROOT / bindings[0][3]), trace["modelSha256"])
            states = [row["s"] for row in trace["states"]]
            self.assertTrue(all(s["fault"] == fault for s in states))
            self.assertFalse(any(violates(s) for s in states[:-1]))
            self.assertTrue(violates(states[-1]))

    def test_new_publication_and_stack_controls_violate_the_named_obligation(self):
        controls = {
            "mailbox_publication-publicationSafe": lambda s: s["scenario"] == 0 and s["pc"] == [4, 4]
                and s["messages"][s["box"] - 1] != 3,
            "mailbox_publication-receiveSafe": lambda s: s["scenario"] == 1 and s["rx"] == 2
                and s["pc"][1] == 4 and s["messages"][0] != 2,
            "promise_publication-identitySafe": lambda s: s["pc"] == [4, 4]
                and (s["returned"][0] != s["cache"] or s["returned"][1] != s["cache"]),
            "promise_publication-callbackSafe": lambda s: any(s["pc"][i] == 2 and s["lock"] == i + 1
                for i in range(2)),
            "stack_undo_ownership-ownershipSafe": lambda s: s["shared"] and s["reused"],
            "stack_undo_ownership-nestedSafe": lambda s: s["nested"] and s["shared"] and s["reused"],
            "stack_undo_ownership-metadataSafe": lambda s: s["boundary"] != 72 or s["previous"] != 91,
        }
        for name, violates in controls.items():
            with self.subTest(name=name):
                trace = json.loads((gate.MODELS / "counterexamples" / (name + ".json")).read_text())
                model, invariant = name.split("-")
                self.assertEqual(invariant, trace["invariant"])
                self.assertEqual(gate.digest(gate.MODELS / (model + ".qnt")), trace["modelSha256"])
                states = [row["s"] for row in trace["states"]]
                self.assertFalse(any(violates(s) for s in states[:-1]))
                self.assertTrue(violates(states[-1]))

    def test_forward_publication_controls_decode_actual_record_states(self):
        for invariant, fault in (("publicationSafe", 1), ("terminationSafe", 2), ("destinationSafe", 3), ("payloadInputSafe", 4)):
            trace = json.loads((gate.MODELS / "counterexamples" /
                               ("gc_forward_publication-" + invariant + "-shared-contract.json")).read_text())
            self.assertEqual(gate.digest(gate.MODELS / "gc_forward_publication.qnt"), trace["modelSha256"])
            states = [row["s"] for row in trace["states"]]
            self.assertTrue(all(row["fault"] == fault for row in states))
            violates = {
                1: lambda row: row["staleRead"],
                2: lambda row: row["resumed"] and (row["copied"] != 2 or not(row["scanned"]) or row["queued"]),
                3: lambda row: row["canonicalForwarded"],
                4: lambda row: row["canonicalForwarded"],
            }[fault]
            self.assertFalse(any(violates(row) for row in states[:-1]))
            self.assertTrue(violates(states[-1]))

    def test_debug_launch_environment_excludes_inherited_sdk_overrides(self):
        with patch.dict("gambit_smp.debug_capture.os.environ", {"PATH": "/wrong", "SDKROOT": "/wrong",
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
            with patch("gambit_smp.upstream_audit.subprocess.check_output", return_value="2\t1\tlib/mem.c\n"):
                self.assertEqual("runtime-c", upstream_audit.inventory(root)[0]["role"])
            for result in ("", "3\t1\tlib/mem.c\n", "2\t1\tlib/mem.c\n2\t1\tlib/mem.c\n"):
                with patch("gambit_smp.upstream_audit.subprocess.check_output", return_value=result):
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

    def test_setup_transaction_manifest_checks_every_fault_and_progress(self):
        manifest = json.loads((gate.ROOT / "evidence/pstate-setup-protocol.json").read_text())
        case = manifest["cases"][0]
        self.assertEqual("progress", case["temporal"])
        self.assertEqual([
            ("old", "publicationSafe", "initOld"),
            ("old", "publicationOrderSafe", "initEarlyPublish"),
            ("old", "rollbackSafe", "initLeak"),
            ("old", "borrowedSafe", "initBorrowed"),
            ("old", "destroySafe", "initInvalidDestroy"),
            ("old", "helperRollbackSafe", "initHelperDuplicate"),
            ("old", "cleanupOrderSafe", "initWrongOrder"),
            ("fixed", "safe", "initFixed"),
        ], gate.model_checks(case))
        self.assertIn(".data/vector-increment-runtime-026/source/lib/setup.c",
                      manifest["contextInputs"])
        self.assertIn(".data/papers/ghc-parallel-gc-2008/paper.txt",
                      manifest["contextInputs"])

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
        with patch("gambit_smp.debug_runtime.subprocess.check_output", return_value="gcc-16 -c -o mem.o mem.c\n"):
            self.assertEqual("gcc-16", debug_runtime.make_command(Path("."), "mem.c", "mem.o")[0])
        for output in ("clang -c -o mem.o mem.c\n", "gcc-16 -c mem.c\n",
                       "echo build\ngcc-16 -c -o mem.o mem.c\n"):
            with patch("gambit_smp.debug_runtime.subprocess.check_output", return_value=output):
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
        self.assertEqual(33, len(numbers))
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
