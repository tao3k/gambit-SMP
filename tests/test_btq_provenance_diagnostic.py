"""Source custody and admission boundaries for the field-origin diagnostic."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load


class BTQProvenanceDiagnosticTests(unittest.TestCase):
    def test_complete_probe_round_is_darwin_only_and_not_runtime_admission(self):
        directory = ROOT / "evidence/fixtures/darwin-gc-complete-probe-round"
        candidate = json.loads((directory / "source.lock.json").read_text())
        parent = json.loads((ROOT / "evidence/fixtures/darwin-stack-selection-origin-baseline/source.lock.json").read_text())
        self.assertEqual(["lib/mem.c"], [name for name in candidate["files"]
            if candidate["files"][name] != parent["files"][name]])
        model = json.loads((directory / "model-observation.json").read_text())
        self.assertEqual(model["modelSha256"], digest(ROOT / model["model"]))
        positive = model["checks"]["completeRoundAndHandshake"]
        negative = model["checks"]["legacySingleRoundControl"]
        self.assertTrue(positive["accepted"])
        self.assertEqual(0, positive["states"]["queued"])
        self.assertTrue(negative["accepted"] and negative["negative"])
        patch = (ROOT / candidate["patch"]).read_text()
        self.assertIn("+      for (i = np-1; i>=0; i--)", patch)
        self.assertIn("+          ___processor_state ps = ___PSTATE_FROM_PROCESSOR_ID((id + i) % np,___vms);", patch)
        self.assertIn("!defined(__clang__)", patch)
        self.assertIn("for (i = (np-1) * ___GC_SCAN_STEAL_WORK_CYCLES - 1; i>=0; i--)", patch)
        self.assertFalse(model["fullGcProved"])
        self.assertFalse(model["runtimeAdmitted"])

    def test_stack_pool_model_keeps_exact_native_invalid_entry_open(self):
        directory = ROOT / "evidence/fixtures/darwin-heap-frame-identity"
        model = json.loads((directory / "stack-pool-model.json").read_text())
        # The earlier observation is immutable; retain its exact model bytes.
        self.assertEqual(model["sourceSha256"], digest(ROOT /
            "models/gambit/history/stack_allocator_frame_lifetime.qnt"))
        for key in ("recipe", "sourceLock", "incident", "mapping", "nativeObservation"):
            self.assertEqual(model[key + "Sha256"], digest(ROOT / model[key]))
        self.assertEqual(5, len(model["checks"]))
        self.assertTrue(all(row["accepted"] for row in model["checks"]))
        self.assertEqual(6048, model["checks"][0]["states"]["distinct"])
        self.assertEqual(0, model["checks"][0]["states"]["queued"])
        self.assertEqual(4, sum(row["negative"] for row in model["checks"]))
        for row in model["checks"][1:]:
            self.assertIn("counterexampleSha256", row)
        native = json.loads((directory / "native-observation.json").read_text())
        mapped = json.loads((directory / "stack-allocation-symbolization.json").read_text())
        self.assertEqual(native["binarySha256"], mapped["binarySha256"])
        self.assertEqual(140, mapped["hostRelativeOffset"])
        self.assertEqual(1, mapped["stackStartAlignmentRemainder"])
        self.assertEqual(int(mapped["stackStartWordHex"], 16) - 16,
                         int(mapped["effectiveAddressHex"], 16))
        self.assertEqual((4, 3, 1, 0), tuple(native["compiledStress"][key]
            for key in ("files", "passed", "failed", "timedOut")))
        self.assertFalse(model["causeEstablished"])
        self.assertFalse(model["sourceRefinementAdmitted"])
        self.assertFalse(native["runtimeAdmitted"])

    def test_pool_metadata_separation_is_a_bounded_hypothesis_not_native_green(self):
        directory = ROOT / "evidence/fixtures/darwin-section-pool-metadata"
        result = json.loads((directory / "model-observation.json").read_text())
        for key in ("source", "recipe", "sourceLock", "incident", "mapping",
                    "nativeObservation", "predecessorSource", "candidateLock"):
            source = (ROOT / "models/gambit/history/stack_allocator_metadata_envelope.qnt"
                      if key == "source" else ROOT / result[key])
            self.assertEqual(result[key + "Sha256"], digest(source))
        self.assertEqual(7, len(result["checks"]))
        self.assertTrue(all(row["accepted"] for row in result["checks"]))
        self.assertEqual(5, sum(row["negative"] for row in result["checks"]))
        checks = {row["id"]: row for row in result["checks"]}
        self.assertIn("counterexampleSha256", checks["payload-alias-control"])
        self.assertFalse(checks["metadata-separation"]["negative"])
        self.assertEqual(0, checks["metadata-separation"]["states"]["queued"])
        parent = json.loads((ROOT / result["sourceLock"]).read_text())
        candidate = json.loads((ROOT / result["candidateLock"]).read_text())
        self.assertEqual(["include/gambit.h.in", "lib/mem.c"], [name
            for name in candidate["files"] if candidate["files"][name] != parent["files"][name]])
        review = json.loads((directory / "review-contract.json").read_text())
        self.assertEqual(digest(directory / "source.lock.json"), review["sourceLockSha256"])
        self.assertEqual(result["sourceSha256"], review["modelSha256"])
        for key in ("causeEstablished", "runtimeAdmitted", "sourceRefinementAdmitted"):
            self.assertFalse(result[key])
        patch = (ROOT / candidate["patch"]).read_text()
        self.assertIn("+    struct ___msect *pool_next;", patch)
        self.assertEqual(2, patch.count("msection_free_list = MSECTION_POOL_NEXT(ms);"))

    def test_separated_native_failure_is_not_erased_by_model_positive(self):
        directory = ROOT / "evidence/fixtures/darwin-section-pool-metadata"
        model = json.loads((directory / "selected-entry-model.json").read_text())
        native = json.loads((directory / "native-observation.json").read_text())
        for key in ("source", "recipe", "nativeObservation", "predecessorSource"):
            source = (ROOT / "models/gambit/history/stack_allocator_selected_entry.qnt"
                      if key == "source" else ROOT / model[key])
            self.assertEqual(model[key + "Sha256"], digest(source))
        self.assertEqual((3, 1, 0), tuple(native["compiledStress"][key]
                         for key in ("passed", "failed", "timedOut")))
        self.assertEqual(11, native["results"][0]["signal"])
        self.assertEqual("DENY", native["compiledStress"]["outcome"])
        self.assertTrue(model["checks"][0]["negative"])
        self.assertFalse(model["checks"][1]["negative"])
        self.assertFalse(native["unchangedRetryAdmitted"])
        for key in ("causeEstablished", "runtimeAdmitted", "sourceRefinementAdmitted"):
            self.assertFalse(model[key])
            self.assertFalse(native[key])

    def test_owned_undo_candidate_preserves_model_and_linux_boundary(self):
        directory = ROOT / "evidence/fixtures/darwin-section-owned-undo"
        model = json.loads((directory / "model-observation.json").read_text())
        review = json.loads((directory / "review-contract.json").read_text())
        candidate = json.loads((directory / "source.lock.json").read_text())
        parent = json.loads((ROOT / review["parent"]).read_text())
        for key in ("source", "recipe", "sourceLock", "predecessorSource"):
            self.assertEqual(model[key + "Sha256"], digest(ROOT / model[key]))
        self.assertEqual({"include/gambit.h.in", "lib/mem.c"}, {
            name for name in candidate["files"]
            if candidate["files"][name] != parent["files"][name]})
        checks = {row["id"]: row for row in model["checks"]}
        self.assertEqual(6048, checks["ownership"]["states"]["distinct"])
        self.assertEqual("completion", checks["ownership"]["temporal"])
        self.assertTrue(checks["undo-payload-control"]["negative"])
        self.assertFalse(checks["owned-undo-metadata"]["negative"])
        patch = (ROOT / candidate["patch"]).read_text()
        self.assertIn("+    struct ___msect *stack_previous;", patch)
        self.assertIn("+      (ms = current_ms->stack_previous)", patch)
        self.assertIn("+      alloc_stack_ptr = current_ms->stack_previous_fp;", patch)
        self.assertNotIn("pool_next", patch)
        self.assertIn("!defined(__clang__)", patch)
        self.assertEqual(review["modelSha256"], model["sourceSha256"])
        for key in ("causeEstablished", "runtimeAdmitted", "sourceRefinementAdmitted"):
            self.assertFalse(model[key])
            self.assertFalse(review[key])

    def test_frame_ra_diagnostic_preserves_parent_and_native_failure(self):
        directory = ROOT / "evidence/fixtures/darwin-frame-ra-boundary"
        current = json.loads((directory / "source.lock.json").read_text())
        parent = json.loads((ROOT / "evidence/fixtures/darwin-btq-public-provenance/source.lock.json").read_text())
        review = json.loads((directory / "review-contract.json").read_text())
        observed = json.loads((directory / "native-observation.json").read_text())
        self.assertEqual(set(parent["files"]), set(current["files"]))
        self.assertEqual(["include/gambit.h.in"], [name for name in current["files"]
            if current["files"][name] != parent["files"][name]])
        self.assertEqual(digest(directory / "source.lock.json"), review["sourceLockSha256"])
        self.assertEqual(review["sourceLockSha256"], observed["sourceLockSha256"])
        self.assertEqual(digest(ROOT / current["patch"]), current["patchSha256"])
        patch = (ROOT / current["patch"]).read_text()
        self.assertEqual(7, patch.count("+{ ___WORD descr = ___FRAME_RA_DESCR(ra);"))
        self.assertIn("+  if (___TYP(ra) != ___tRETURN)", patch)
        self.assertIn("+      abort ();", patch)
        self.assertEqual("PASS", observed["bootstrap"]["outcome"])
        self.assertEqual("DENY", observed["compiledStress"]["outcome"])
        self.assertEqual((4, 3, 1, 0), tuple(observed["compiledStress"][key]
            for key in ("files", "passed", "failed", "timedOut")))
        self.assertEqual(("0x12800", 0), (observed["frameRAObservation"]["raHex"],
                                       observed["frameRAObservation"]["tag"]))
        for key in ("causeEstablished", "runtimeAdmitted", "sourceRefinementAdmitted",
                    "performanceAdmitted", "releaseAdmitted", "unchangedRetryAdmitted"):
            self.assertFalse(observed[key])
        base = ROOT / "evidence/research/current-source-full-bootstrap"
        self.check_recipe(json.loads((base / "darwin-btq-public-bootstrap.recipe.json").read_text()),
                          json.loads((base / "darwin-frame-ra-current-workspace-bootstrap.recipe.json").read_text()))

    def test_model_pass_does_not_close_native_heap_frame_requirement(self):
        document, facts, catalog, _ = load(ROOT, "evidence/scenarios/concurrent-gc/captured-heap-return.view.json")
        with engine_api() as (engine, _):
            answer = evaluate(engine, facts, catalog, document["queries"])[0]
            withdrawn = dict(facts, source=[row for row in facts["source"]
                                          if row[0] not in {"frame-operations", "stack-pool"}])
            after = evaluate(engine, withdrawn, catalog, document["queries"])[0]
        self.assertEqual(1, len(answer["open"]))
        self.assertEqual(2, len(answer["model_context"]))
        self.assertEqual([], after["model_context"])
        self.assertEqual(answer["open"], after["open"])
        self.assertEqual(answer["source_gap"], after["source_gap"])
        self.assertEqual(4, len(answer["source_gap"]))
        self.assertIn("NATIVE_DENY", {row[1] for row in answer["observed"]})
        self.assertIn("RA_TAG_REJECTED", {row[1] for row in answer["observed"]})
        self.assertIn("ALLOCATOR_ENTRY_INVALID", {row[1] for row in answer["observed"]})
        for row in answer["actions"]:
            self.assertIn(row[1], document["queries"])

    def test_captured_frame_model_and_coordinate_fixture_bind_current_inputs(self):
        result = json.loads((ROOT / "evidence/fixtures/darwin-btq-public-provenance/captured-frame-model.json").read_text())
        for key in ("source", "recipe", "sourceLock", "incident"):
            self.assertEqual(result[key + "Sha256"], digest(ROOT / result[key]))
        native = result["nativeCoordinates"]
        for key in ("source", "recipe"):
            self.assertEqual(native[key + "Sha256"], digest(ROOT / native[key]))
        self.assertEqual(18496, native["shapePairs"])
        self.assertEqual("PASS", native["outcome"])
        self.assertEqual(6, sum(row["negative"] for row in result["checks"]))
        self.assertTrue(all(row["accepted"] for row in result["checks"]))
        self.assertEqual(0, result["checks"][0]["queued"])
        for key in ("runtimeAdmitted", "sourceRefinementAdmitted", "performanceAdmitted", "unchangedNativeRetryAdmitted"):
            self.assertFalse(result[key])

    def test_symbolization_matches_actual_incident_not_a_btq_writer_claim(self):
        directory = ROOT / "evidence/fixtures/darwin-btq-public-provenance"
        mapped = json.loads((directory / "kernel-heap-frame-symbolization.json").read_text())
        self.assertEqual(digest(ROOT / mapped["incident"]), mapped["incidentSha256"])
        incident = json.loads((ROOT / mapped["incident"]).read_text())
        fault = next(row for row in incident["threads"] if row["faulting"])
        self.assertEqual("___H___kernel", fault["frames"][0]["symbol"])
        self.assertEqual(mapped["hostRelativeOffset"], fault["frames"][0]["symbolLocation"])
        self.assertEqual(int(mapped["returnWordHex"], 16), fault["registers"]["x"][28])
        self.assertFalse(incident["pidBoundToNativeReceipt"])
        observed = json.loads((directory / "native-observation.json").read_text())
        self.assertEqual(4, sum(observed["compiledStress"][key] for key in ("passed", "failed", "timedOut")))
        self.assertEqual("DENY", observed["compiledStress"]["outcome"])
        self.assertFalse(observed["causeEstablished"])
        self.assertFalse(observed["unchangedRetryAdmitted"])

    def test_only_active_thread_macro_source_changes_from_diagnostic_parent(self):
        for fixture in ("darwin-btq-edge-provenance", "darwin-btq-public-provenance"):
            with self.subTest(fixture=fixture):
                self.check_source_contract(fixture)

    def check_source_contract(self, fixture):
        path = ROOT / "evidence/fixtures" / fixture / "source.lock.json"
        current = json.loads(path.read_text())
        parent = json.loads((ROOT / "evidence/fixtures/darwin-ffi-return-premise/source.lock.json").read_text())
        review = json.loads((path.parent / "review-contract.json").read_text())
        self.assertEqual(digest(path), review["sourceLockSha256"])
        self.assertEqual(parent["revision"], current["revision"])
        self.assertEqual(set(parent["files"]), set(current["files"]))
        changed = [name for name in current["files"]
                   if parent["files"][name] != current["files"][name]]
        self.assertEqual(["lib/_thread#.scm"], changed)
        self.assertEqual(digest(ROOT / current["patch"]), current["patchSha256"])
        self.assertEqual([4, 5, 6, 7, 17], review["fields"])
        self.assertEqual(digest(ROOT / review["model"]), review["modelSha256"])
        for name in ("runtimeAdmitted", "sourceRefinementAdmitted", "performanceAdmitted",
                     "releaseAdmitted", "injectionHooks", "normalPathLogging", "privateLoader"):
            self.assertFalse(review[name])

    def test_recipe_keeps_profile_and_original_bootstrap_stage_limits(self):
        base = ROOT / "evidence/research/current-source-full-bootstrap"
        parent = json.loads((base / "darwin-ffi-premise-bootstrap.recipe.json").read_text())
        for name in ("darwin-btq-provenance-bootstrap.recipe.json", "darwin-btq-public-bootstrap.recipe.json"):
            with self.subTest(recipe=name):
                self.check_recipe(parent, json.loads((base / name).read_text()))

    def check_recipe(self, parent, recipe):
        before = {row["id"]: row for row in parent["steps"]}
        after = {row["id"]: row for row in recipe["steps"]}
        self.assertEqual(set(before), set(after))
        for name in before:
            self.assertEqual(before[name]["budgetSeconds"], after[name]["budgetSeconds"])
        self.assertEqual(before["configure"]["arguments"]["buildProfile"],
                         after["configure"]["arguments"]["buildProfile"])
