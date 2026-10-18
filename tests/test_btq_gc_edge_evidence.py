"""Real Evidence DSL review of a native failure, not native qualification."""
import json
import unittest

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load, registry
from gambit_smp.framework import ROOT, digest

VIEW = "evidence/scenarios/concurrent-gc/btq-edge-integrity.view.json"


class BTQEdgeEvidenceTests(unittest.TestCase):
    def test_shared_ticket_candidate_preserves_parent_except_ownership_poll(self):
        parent = json.loads((ROOT / "evidence/fixtures/darwin-allocator-acquire/source.lock.json").read_text())
        candidate_path = ROOT / "evidence/fixtures/darwin-ticket-ownership-acquire/source.lock.json"
        candidate = json.loads(candidate_path.read_text())
        self.assertEqual(parent["revision"], candidate["revision"])
        self.assertEqual(set(parent["files"]), set(candidate["files"]))
        self.assertEqual(["include/gambit.h.in"],
                         [p for p in candidate["files"] if parent["files"][p] != candidate["files"][p]])
        observation = json.loads((ROOT / "evidence/fixtures/darwin-ticket-ownership-acquire/handoff-observation.json").read_text())
        self.assertEqual(digest(candidate_path), observation["sourceLockSha256"])
        self.assertFalse(observation["runtimeAdmitted"])
        self.assertFalse(observation["releaseAdmitted"])

    def test_ticket_selection_composition_keeps_native_failure_open(self):
        model = json.loads((ROOT / "evidence/source-results/compiled-stress-failure/ticket-selection-model.json").read_text())
        for field in ("source", "recipe"):
            self.assertEqual(model[field + "Sha256"], digest(ROOT / model[field]))
        self.assertEqual([True, False], [row["negative"] for row in model["checks"]])
        self.assertEqual(0, model["checks"][1]["queued"])
        self.assertFalse(model["sourceRefinementAdmitted"])
        native = json.loads((ROOT / "evidence/fixtures/darwin-allocator-acquire/compiled-tfib-observation.json").read_text())
        self.assertEqual("DENY", native["outcome"])
        self.assertEqual(11, native["upstreamExit"]["lo"])
        self.assertFalse(native["unchangedRetryAdmitted"])

    def evaluate(self, facts, catalog, queries):
        with engine_api() as (engine, _):
            return evaluate(engine, facts, catalog, queries)[0]

    def test_registered_source_and_model_identity_are_versioned_not_cache_inputs(self):
        self.assertIn(VIEW,registry(ROOT)[0])
        document,facts,_,inputs = load(ROOT,VIEW)
        self.assertFalse(any("/.data/" in path[len(str(ROOT)):] for path in inputs))
        model = json.loads((ROOT/"evidence/source-results/compiled-stress-failure/model-contract.json").read_text())
        self.assertEqual(model["sourceSha256"],digest(ROOT/model["source"]))
        self.assertFalse(model["sourceRefinementAdmitted"])
        self.assertEqual(3,len(facts["obligation"]))

    def test_native_deny_and_model_pass_coexist_without_closing_obligations(self):
        document,facts,catalog,_ = load(ROOT,VIEW)
        answer = self.evaluate(facts,catalog,document["queries"])
        self.assertEqual(3,len(answer["open"]))
        self.assertEqual(3,len(answer["source_gaps"]))
        self.assertEqual(7,len(answer["models"]))
        self.assertEqual({"FAULT_SITE_MAPPED","MODEL_ONLY_PASS","NATIVE_DENY",
                          "HISTORICAL_SCAN_CONTEXT","CANDIDATE_OBJECT_ONLY"},
                         {row[1] for row in answer["observed"]})

    def test_opaque_candidate_names_and_pass_labels_do_not_discharge_source_gaps(self):
        document,facts,catalog,_ = load(ROOT,VIEW)
        for name in ("source-001","source-999","semantic-candidate"):
            changed = dict(facts,candidate=[[name,facts["candidate"][0][1]]],
                           evidence=[[row[0],"PASS",row[2]] for row in facts["evidence"]])
            answer = self.evaluate(changed,catalog,document["queries"])
            self.assertEqual({name},{row[0] for row in answer["open"]})
            self.assertEqual(3,len(answer["open"]))
            self.assertEqual(3,len(answer["source_gaps"]))

    def test_model_withdrawal_does_not_withdraw_the_native_failure(self):
        document,facts,catalog,_ = load(ROOT,VIEW)
        changed = dict(facts,source=[row for row in facts["source"]
                                     if row[0] not in {"edge-model", "operations-model", "chunk-model", "ticket-model", "ticket-selection-model"}])
        answer = self.evaluate(changed,catalog,document["queries"])
        self.assertEqual([],answer["models"])
        self.assertEqual(3,len(answer["open"]))
        self.assertIn("NATIVE_DENY",{row[1] for row in answer["observed"]})

    def test_operational_model_is_bound_without_promoting_native_milestone(self):
        path = ROOT/"evidence/source-results/compiled-stress-failure/operations-model.json"
        observation = json.loads(path.read_text())
        for field in ("source", "recipe", "sourceLock", "generator", "nativeFailure"):
            self.assertEqual(observation[field + "Sha256"], digest(ROOT/observation[field]))
        self.assertEqual({"nodes":4,"rounds":2,"queueOwners":2,"independentQueueWrites":1},
                         observation["bounds"])
        self.assertEqual({"all-distinct", "all-equal"}, set(observation["priorityDomains"]))
        positive, *controls = observation["checks"]
        self.assertEqual((False, 0, "completion"),
                         (positive["negative"], positive["queued"], positive["temporal"]))
        self.assertEqual({"initMissingRotationParent", "initMissingTransplant"},
                         {row["initializer"] for row in controls})
        self.assertTrue(all(row["accepted"] and row["negative"] for row in controls))
        self.assertFalse(any(observation[field] for field in
                             ("runtimeAdmitted", "sourceRefinementAdmitted", "performanceAdmitted")))
        self.assertTrue(observation["openCompositionRequirements"])

    def test_operations_context_can_be_withdrawn_without_erasing_native_deny(self):
        document,facts,catalog,_ = load(ROOT,VIEW)
        changed = dict(facts,source=[row for row in facts["source"] if row[0]!="operations-model"])
        answer = self.evaluate(changed,catalog,document["queries"])
        self.assertEqual(6,len(answer["models"]))
        self.assertEqual(3,len(answer["open"]))
        self.assertIn("NATIVE_DENY",{row[1] for row in answer["observed"]})

    def test_chunk_cursor_component_is_bound_to_candidate_not_cache_source(self):
        path = ROOT/"evidence/source-results/compiled-stress-failure/chunk-cursor-model.json"
        observation = json.loads(path.read_text())
        for field in ("source", "recipe", "sourceLock", "overlay", "nativeFailure"):
            self.assertEqual(observation[field + "Sha256"], digest(ROOT/observation[field]))
        lock = json.loads((ROOT/observation["sourceLock"]).read_text())
        self.assertEqual(observation["candidateFileSha256"],
                         lock["files"][observation["candidateFile"]]["candidateSha256"])
        self.assertEqual({"ordinary", "captured-frame-private-segment"},
                         set(observation["copyDomains"]))
        positive, *controls = observation["checks"]
        self.assertEqual((False, 0, "completion"),
                         (positive["negative"], positive["queued"], positive["temporal"]))
        self.assertEqual({"initPublishLocal", "initLateClaim", "initRewindLocal", "initEarlyPrivatePublication",
                          "initReuseSection", "initMissingAllocationClaim"},
                         {row["initializer"] for row in controls})
        self.assertEqual({"fresh-section", "share-own-stack"}, set(observation["allocationDomains"]))
        self.assertEqual((1, 2, 1), (observation["bounds"]["payloadArenas"],
                                     observation["bounds"]["allocatingRoles"],
                                     observation["bounds"]["heapRolloversMax"]))
        self.assertTrue(all(row["accepted"] and row["negative"] for row in controls))
        self.assertFalse(any(observation[field] for field in
                             ("runtimeAdmitted", "sourceRefinementAdmitted", "performanceAdmitted")))

    def test_chunk_model_withdrawal_keeps_actual_failure_and_gaps(self):
        document,facts,catalog,_ = load(ROOT,VIEW)
        changed = dict(facts,source=[row for row in facts["source"] if row[0]!="chunk-model"])
        answer = self.evaluate(changed,catalog,document["queries"])
        self.assertEqual(6,len(answer["models"]))
        self.assertEqual(3,len(answer["open"]))
        self.assertEqual(3,len(answer["source_gaps"]))
        self.assertIn("NATIVE_DENY",{row[1] for row in answer["observed"]})

    def test_historical_scan_origins_do_not_invent_queue_owner_or_current_cause(self):
        item = json.loads((ROOT/"evidence/source-results/compiled-stress-failure/historical-scan-origin.json").read_text())
        for field in ("receipt", "log", "originDecoder"):
            self.assertEqual(item[field+"Sha256"], digest(ROOT/item[field]))
        recorded = json.loads((ROOT/item["receipt"]).read_text())
        self.assertEqual(item["sourceFileSha256"],recorded["native"]["toolchain"]["sourceFiles"][item["sourceFile"]])
        self.assertEqual((2,3,2),(item["observed"]["firstOriginCode"],
                                  item["observed"]["lastRecordedOriginCode"],item["observed"]["visits"]))
        self.assertFalse(item["observed"]["scanActiveAtAbort"])
        self.assertFalse(item["observed"]["invalidCellInsideRecordedBody"])
        self.assertFalse(item["currentSourceQualification"])
        self.assertFalse(item["unchangedRetryAdmitted"])
        self.assertTrue(item["unknown"])

    def test_allocator_object_candidate_retains_parent_and_does_not_admit_runtime(self):
        item = json.loads((ROOT/"evidence/fixtures/darwin-allocator-acquire/object-observation.json").read_text())
        for field in ("sourceLock", "recipe", "inputArchive"):
            source = (ROOT / "tests/fixtures/allocator-acquire-input-history/inputs.json"
                      if field == "inputArchive" else ROOT / item[field])
            self.assertEqual(item[field+"Sha256"], digest(source))
        parent = json.loads((ROOT/"evidence/fixtures/darwin-dynamic-modulo-scope/source.lock.json").read_text())
        candidate = json.loads((ROOT/item["sourceLock"]).read_text())
        self.assertEqual(parent["revision"],candidate["revision"])
        self.assertEqual(set(parent["files"]),set(candidate["files"]))
        for name, row in parent["files"].items():
            if name != "lib/mem.c":
                self.assertEqual(row,candidate["files"][name])
        self.assertEqual(item["candidateMemSha256"],candidate["files"]["lib/mem.c"]["candidateSha256"])
        self.assertEqual(item["parentMemSha256"],parent["files"]["lib/mem.c"]["candidateSha256"])
        self.assertTrue(item["parentReaped"] and item["processGroupQuiescent"])
        self.assertEqual("HISTORICAL_BOUND",item["evidenceBindingStatus"])
        self.assertEqual(4,len(item["branchChecks"]))
        self.assertTrue(all(row["exit"]==0 for row in item["branchChecks"]))
        self.assertFalse(any(item[field] for field in
                             ("runtimeAdmitted", "sourceRefinementAdmitted", "performanceAdmitted", "releaseAdmitted")))
