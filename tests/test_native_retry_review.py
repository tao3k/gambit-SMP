import copy
from contextlib import nullcontext
import json
import os
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp import native_review as review, recipes, research_kernel
from gambit_smp.framework import digest


class TypedRetryReviewTests(unittest.TestCase):
    # These independent fixtures require the actual sealed implementation.
    validation_domain = {"kind": "sealed-research", "budgetSeconds": 60, "workers": "auto", "processesPerWorker": 2}

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        if "GAMBIT_SMP_TEST_ARTIFACTS" in os.environ:
            import shutil
            target = Path(os.environ["GAMBIT_SMP_TEST_ARTIFACTS"]) / self.id()
            self.addCleanup(lambda: shutil.copytree(self.root, target))
        self.runtime = self.root / "runtime"
        for name in ("lib/mem.c", "gsi/gsi", "gsc/gsc", "lib/libgambit.a", "tests/unit-tests/control.scm"):
            path = self.runtime / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("current bytes: " + name)
        old_source = self.root / "old.c"
        old_source.write_text("old source")
        self.before, self.after = digest(old_source), digest(self.runtime / "lib/mem.c")
        self.baseline = self.save("evidence/baseline.json", {"sourceFiles": {"lib/mem.c": self.before}})
        self.candidate = self.save("evidence/current.json", {
            "sourceFiles": {"lib/mem.c": self.after}, "binarySha256": digest(self.runtime / "gsi/gsi"),
            "gscSha256": digest(self.runtime / "gsc/gsc"), "librarySha256": digest(self.runtime / "lib/libgambit.a")})
        self.prior = self.save("evidence/failed.json", {
            "candidateReceiptSha256": digest(self.baseline), "wholeSuiteBudgetPerMode": 8,
            "atomicBatchBudgetPerMode": 2, "sourceFiles": {}, "selectedFiles": ["control.scm"],
            "results": [{"mode": "gsi", "accepted": False, "exit": -9, "timeout": True}]})
        log = self.root / "evidence/failed.log"
        log.write_text("actual archived failure fixture, not native acceptance")
        self.failure = {"id": "known", "category": "assertion", "receipt": "evidence/failed.json", "log": "evidence/failed.log", "file": "control.scm"}
        self.save("evidence/native-failures.json", {"schema": "gambit-local-native-failures.v1", "failures": [self.failure]})
        self.directory = self.root / "suite"
        self.directory.mkdir()
        self.engine = Path(os.environ["GAMBIT_SMP_TEST_ENGINE"]) if "GAMBIT_SMP_TEST_ENGINE" in os.environ else self.root / "engine"
        if "GAMBIT_SMP_TEST_ENGINE" in os.environ:
            policy = (self.engine / "policy/suite-review-rules.ss").read_text()
        else:
            policy = (research_kernel.ROOT / review.POLICY).read_text()
        self.rules = self.root / "evidence/rules.ss"
        self.rules.write_text(policy)
        self.receipt = {"steps": [{"id": "suite", "budgetSeconds": 8}], "budgetSeconds": 20,
                        "engine": {"path": str(self.engine), "engineId": research_kernel.manifest_paths(self.engine)["engineId"]
                                   if "GAMBIT_SMP_TEST_ENGINE" in os.environ else "unit-seal"}}
        self.ctx = recipes.ExecutionContext(self.root, self.root, self.directory,
                                            {"PATH": "/usr/bin:/bin", "GAMBIT_SMP_ROOT": str(research_kernel.ROOT)},
                                            time.monotonic() + 10, {}, self.receipt, {})
        self.args = {"mode": "gsi", "regime": "whole-sequential", "failures": "evidence/native-failures.json",
                     "reviewRules": "evidence/rules.ss", "retryReview": "evidence/review.json"}
        self.files, self.unit = [Path("control.scm")], self.runtime / "tests/unit-tests"
        self.current = review.campaign(self.ctx, self.args, self.runtime, self.candidate, self.files, self.unit)
        self.evidence = {"schema": "typed-causal-review-evidence.v1", "claims": [
            {"claim": name, "domain": "causal-review", "status": "reviewed",
             "failureReceiptSha256": digest(self.prior), "candidateReceiptSha256": digest(self.candidate),
             "changes": ["repair"], "premises": [], "reasoning": "Synthetic source relevance review for transport tests only.",
             "references": [{"path": "evidence/failed.log", "sha256": digest(log)}]}
            for name in ("failure-scope-review", "change-relevance-review", "assumptions-review")]}
        self.doc = {"schema": review.SCHEMA, "campaign": self.current, "failures": [{
            "id": "known", "receiptSha256": digest(self.prior),
            "baselineIdentity": {"path": "evidence/baseline.json", "sha256": digest(self.baseline)},
            "failurePointer": "/results/0/accepted", "log": {"path": "evidence/failed.log", "sha256": digest(log)},
            "budget": {"regime": "whole-sequential", "pointer": "/wholeSuiteBudgetPerMode"},
            "changes": [{"id": "repair", "kind": "source", "path": "lib/mem.c", "before": self.before, "after": self.after}],
            "claims": []}]}
        self.save_review()

    def save(self, name, value):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + "\n")
        return path

    def save_review(self):
        evidence = self.save("evidence/causal.json", self.evidence)
        self.doc["failures"][0]["claims"] = [
            {"id": row["claim"], "pointer": "/claims/" + str(index),
             "evidence": {"path": "evidence/causal.json", "sha256": digest(evidence)}}
            for index, row in enumerate(self.evidence["claims"])]
        self.save("evidence/review.json", self.doc)

    def preflight(self):
        real = "GAMBIT_SMP_TEST_ENGINE" in os.environ
        manifest = nullcontext() if real else patch.object(research_kernel, "manifest_paths",
            return_value={"files": {"policy/suite-review-rules.ss": digest(self.rules)}})
        # Unit transport checks use a fixed response, never a Python inference substitute.
        evaluation = nullcontext() if real else patch("gambit_smp.evidence_capabilities.evaluate_observations",
            return_value={"selected": [["known", self.args["mode"]]], "eligible": [["known", self.args["mode"]]],
                          "denied": [], "missing": [], "review": [], "need": [],
                          "decision": [["RETRY_ELIGIBLE"]]})
        with manifest, evaluation:
            return review.preflight(self.ctx, self.args, self.runtime, self.candidate, self.files, self.unit)

    def test_review_requires_original_git_log_bytes_after_cache_cleanup(self):
        from gambit_smp import workspace as w
        from gambit_smp.source_identity import git_source
        from gambit_smp.output_observations import observe, REGISTRY
        name = 'evidence/failed.log'
        path = self.root / name
        data = path.read_bytes()
        w.git(self.root, 'init', '-q')
        w.git(self.root, 'add', '-f', name)
        w.git(self.root, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
              'commit', '-qm', 'original failure log')
        source = git_source(self.root, '.', w.git(self.root, 'rev-parse', 'HEAD'), name)
        output = dict(observe(data), origins=[name], sources={name: source})
        registry = self.save(REGISTRY, dict(schema='published-evidence-inputs.v1', records={},
                                          observations={output['sha256']: output}))
        path.unlink()
        before = self.prior.read_bytes()
        result = self.preflight()
        self.assertEqual('RETRY_ELIGIBLE', result['decision'])
        self.assertFalse(result['executionAuthorized'])
        self.assertFalse(result['runtimeAdmitted'])
        self.assertEqual(before, self.prior.read_bytes())
        self.assertEqual(digest(registry), result['inputs'][REGISTRY])
        self.assertFalse(path.exists())
        output.pop('sources')
        registry.write_text(json.dumps(dict(schema='published-evidence-inputs.v1', records={},
                                           observations={output['sha256']: output})))
        with self.assertRaisesRegex(ValueError, 'original Git output bytes unavailable'):
            self.preflight()

    def test_exact_review_preserves_failure_identity_and_conditional_boundary(self):
        before = self.prior.read_bytes()
        result = self.preflight()
        self.assertEqual("RETRY_ELIGIBLE", result["decision"])
        self.assertFalse(result["executionAuthorized"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertEqual(before, self.prior.read_bytes())
        self.assertEqual(digest(self.prior), result["inputs"]["evidence/failed.json"])
        self.assertEqual([["known", "suite-step", 8000]], result["facts"]["original_budget"])

    def test_current_producer_marker_cannot_enter_literal_review(self):
        for row in self.evidence["claims"]:
            row["candidateReceiptSha256"] = {"binding": "current-producer"}
        self.save_review()
        with self.assertRaisesRegex(ValueError, "exact current candidate"):
            self.preflight()

    def check_whole_inventory_correspondence(self, inventory, bound):
        self.args["regime"] = "whole-parallel"
        self.doc["campaign"] = review.campaign(self.ctx, self.args, self.runtime,
                                               self.candidate, self.files, self.unit)
        previous = json.loads(self.prior.read_text())
        previous["selectedFiles"] = inventory
        self.save("evidence/failed.json", previous)
        self.doc["failures"][0]["receiptSha256"] = digest(self.prior)
        for row in self.evidence["claims"]:
            row["failureReceiptSha256"] = digest(self.prior)
        self.save_review()
        result = self.preflight()
        self.assertEqual([["known"]] if bound else [], result["facts"]["exact_whole_inventory"])

    def test_whole_topology_correspondence_binds_exact_inventory(self):
        self.check_whole_inventory_correspondence(["control.scm"], True)

    def test_compiler_probe_binds_real_stage_and_nested_cap_without_suite_projection(self):
        previous = json.loads(self.prior.read_text())
        previous.pop("results")
        previous.pop("selectedFiles")
        previous.update(schema="gambit-compiler-cost.v1", diagnosticOnly=True,
                        sourceStable=True, status="DENY", selection="control.scm",
                        wholeProbeBudget=90, stages=[
                            {"name": "scheme-to-c", "exit": 0, "timeout": False, "accepted": True},
                            {"name": "c-to-dynamic-module", "exit": -9, "timeout": True, "accepted": False}])
        self.save("evidence/failed.json", previous)
        self.args.update(mode="gsc", fileBudgetSeconds={"control.scm": 90})
        self.doc["campaign"] = review.campaign(self.ctx, self.args, self.runtime,
                                               self.candidate, self.files, self.unit)
        entry = self.doc["failures"][0]
        entry.update(receiptSha256=digest(self.prior), failurePointer="/stages/1/accepted",
                     budget={"regime": "compiler-probe", "pointer": "/wholeProbeBudget", "file": "control.scm"})
        for claim in self.evidence["claims"]:
            claim["failureReceiptSha256"] = digest(self.prior)
        self.save_review()
        result = self.preflight()
        self.assertEqual([["known", "c-to-dynamic-module"]], result["facts"]["compiler_probe_failure"])
        self.assertEqual([["known", "file-step", 90000]], result["facts"]["original_budget"])
        self.assertNotIn("results", json.loads(self.prior.read_text()))
        entry["budget"]["regime"] = "whole-sequential"
        entry["budget"]["pointer"] = "/wholeSuiteBudgetPerMode"
        self.save_review()
        with self.assertRaisesRegex(ValueError, "cannot be relabeled"):
            self.preflight()

    def test_whole_topology_correspondence_does_not_bind_changed_inventory(self):
        self.check_whole_inventory_correspondence(["other.scm"], False)

    def test_whole_topology_correspondence_does_not_bind_duplicate_inventory(self):
        self.check_whole_inventory_correspondence(["control.scm", "control.scm"], False)

    def test_atomic_correspondence_requires_exact_inventory(self):
        self.args["regime"] = "atomic-coverage"
        self.doc["campaign"] = review.campaign(self.ctx, self.args, self.runtime,
                                               self.candidate, self.files, self.unit)
        self.doc["failures"][0]["budget"] = {
            "regime": "atomic-coverage", "pointer": "/atomicBatchBudgetPerMode"}
        for index, (inventory, bound) in enumerate(((["control.scm"], True), (["other.scm"], False),
                                                    (["control.scm", "control.scm"], False))):
            with self.subTest(inventory=inventory):
                previous = json.loads(self.prior.read_text())
                previous["selectedFiles"] = inventory
                self.save("evidence/failed.json", previous)
                self.doc["failures"][0]["receiptSha256"] = digest(self.prior)
                for row in self.evidence["claims"]:
                    row["failureReceiptSha256"] = digest(self.prior)
                self.save_review()
                directory = self.directory / ("atomic-case-" + str(index)) / "suite"
                directory.mkdir(parents=True)
                self.ctx = recipes.ExecutionContext(
                    self.root, self.root, directory, self.ctx.env, self.ctx.deadline,
                    {}, self.receipt, {})
                result = self.preflight()
                self.assertEqual([["known"]] if bound else [],
                                 result["facts"]["exact_atomic_inventory"])
                self.assertEqual([], result["facts"]["exact_whole_inventory"])

    def test_whole_topology_correspondence_does_not_bind_unknown_inventory(self):
        self.check_whole_inventory_correspondence(None, False)

    def bind_group_budget(self, cap):
        for name in ("second.scm", "extra.scm"):
            (self.unit / name).write_text("synthetic group fixture")
        self.files = [Path(name) for name in ("control.scm", "second.scm", "extra.scm")]
        self.args.update(regime="whole-parallel", groupBudgetSeconds={"thread-completion": {
            "files": ["control.scm", "second.scm"], "budgetSeconds": cap}})
        previous = json.loads(self.prior.read_text())
        previous["selectedFiles"] = ["control.scm", "second.scm"]
        self.save("evidence/failed.json", previous)
        self.doc["campaign"] = review.campaign(self.ctx, self.args, self.runtime,
                                               self.candidate, self.files, self.unit)
        entry = self.doc["failures"][0]
        entry["receiptSha256"] = digest(self.prior)
        entry["budget"]["group"] = "thread-completion"
        for row in self.evidence["claims"]:
            row["failureReceiptSha256"] = digest(self.prior)
        self.save_review()

    def test_group_correspondence_binds_original_inventory_and_budget(self):
        self.bind_group_budget(8)
        result = self.preflight()
        self.assertEqual([["known", "thread-completion"]], result["facts"]["scoped_file_group"])
        self.assertEqual([["known", "group-step", 8000]], result["facts"]["original_budget"])
        self.assertEqual([["known", "group-step", 8000]], result["facts"]["requested_budget"])

    def test_group_correspondence_rejects_scope_omission(self):
        self.bind_group_budget(8)
        self.args["groupBudgetSeconds"]["thread-completion"]["files"] = ["control.scm"]
        self.doc["campaign"] = review.campaign(self.ctx, self.args, self.runtime,
                                               self.candidate, self.files, self.unit)
        self.save_review()
        with self.assertRaisesRegex(ValueError, "exact original whole-group"):
            self.preflight()

    def bind_current_review(self):
        for row in self.evidence["claims"]:
            row["candidateReceiptSha256"] = {"binding": "current-producer"}
        self.save_review()
        intent = self.save("evidence/intent.json", {"schema": "current-producer-review-intent.v1",
                                                    "failures": self.doc["failures"]})
        bound = self.save("bound-review.json", {
            "schema": "bound-native-review.v1", "candidateReceiptSha256": digest(self.candidate),
            "intent": {"path": "evidence/intent.json", "sha256": digest(intent)}, "document": self.doc})
        self.receipt["steps"].append({"id": "binding", "outcome": "PASS", "outputs": {
            "review": {"type": "bound-native-review", "path": "bound-review.json", "sha256": digest(bound)}}})
        self.args["retryReview"] = {"step": "binding", "output": "review"}
        return bound, intent

    def test_bound_current_review_reaches_same_causal_policy(self):
        self.bind_current_review()
        result = self.preflight()
        self.assertEqual("RETRY_ELIGIBLE", result["decision"])
        self.assertFalse(result["runtimeAdmitted"])

    def test_bound_review_rejects_changed_intent_before_inference(self):
        _, intent = self.bind_current_review()
        intent.write_text("{}\n")
        with self.assertRaisesRegex(ValueError, "bound review intent changed"):
            self.preflight()

    def test_bound_review_rejects_artifact_drift_before_inference(self):
        bound, _ = self.bind_current_review()
        bound.write_text("{}\n")
        with self.assertRaisesRegex(ValueError, "artifact dependency drift"):
            self.preflight()

    def test_review_target_budget_is_not_binding_step_budget(self):
        self.receipt["steps"][0]["budgetSeconds"] = 1
        current = review.campaign(self.ctx, self.args, self.runtime, self.candidate,
                                  self.files, self.unit, suite_budget=8)
        self.assertEqual(8, current["suiteBudgetSeconds"])
        self.assertEqual(20, current["recipeBudgetSeconds"])
        self.assertEqual(1, self.receipt["steps"][0]["budgetSeconds"])

    def test_campaign_candidate_inventory_topology_and_budget_drift_fail_before_inference(self):
        original = copy.deepcopy(self.doc)
        for field, value in (("candidateReceiptSha256", "0" * 64), ("selectedFiles", {}), ("processors", 4),
                             ("suiteBudgetSeconds", 9), ("recipeBudgetSeconds", 21)):
            self.doc = copy.deepcopy(original)
            self.doc["campaign"][field] = value
            self.save_review()
            with self.assertRaisesRegex(ValueError, "exact candidate"):
                self.preflight()

    def test_failure_and_baseline_identity_cannot_be_substituted(self):
        self.doc["failures"][0]["receiptSha256"] = "0" * 64
        self.save_review()
        with self.assertRaisesRegex(ValueError, "failure receipt"):
            self.preflight()

    def test_reduced_alternate_inventory_cannot_hide_known_failures(self):
        self.save("evidence/empty.json", {"schema": "gambit-local-native-failures.v1", "failures": []})
        self.args["failures"] = "evidence/empty.json"
        with self.assertRaisesRegex(ValueError, "complete canonical"):
            self.preflight()

    def test_raw_log_drift_fails_closed(self):
        (self.root / "evidence/failed.log").write_text("modified")
        with self.assertRaisesRegex(ValueError, "identity drift"):
            self.preflight()

    def test_runtime_binary_drift_fails_closed(self):
        (self.runtime / "gsi/gsi").write_text("changed binary")
        with self.assertRaisesRegex(ValueError, "artifact changed"):
            self.preflight()

    def test_configuration_change_cannot_reuse_the_same_binary_review(self):
        (self.runtime / "config.status").write_text("changed configuration")
        with self.assertRaisesRegex(ValueError, "exact candidate"):
            self.preflight()

    def test_unknown_baseline_change_and_model_pass_cannot_be_projected(self):
        self.doc["failures"][0]["changes"][0]["before"] = "0" * 64
        self.save_review()
        with self.assertRaisesRegex(ValueError, "baseline and current"):
            self.preflight()

    def test_unaccepted_pointer_cannot_point_to_an_unrelated_false_field(self):
        self.doc["failures"][0]["failurePointer"] = "/runtimeAdmitted"
        self.save_review()
        with self.assertRaisesRegex(ValueError, "actual unaccepted"):
            self.preflight()

    def test_elapsed_time_cannot_be_used_as_original_budget(self):
        self.doc["failures"][0]["budget"]["pointer"] = "/seconds"
        self.save_review()
        with self.assertRaisesRegex(ValueError, "original native budget"):
            self.preflight()

    def test_json_pointer_escaping_and_exact_millisecond_budget(self):
        self.assertEqual(7, review.pointer({"a/b": {"~": [7]}}, "/a~1b/~0/0"))
        self.assertEqual(25, review.milliseconds(0.025))
        for value in (True, 0, -1, float("inf"), float("nan"), 0.0001):
            with self.assertRaises(ValueError):
                review.milliseconds(value)

    def bind_single_file_budget(self, cap):
        data = json.loads(self.prior.read_text())
        data["selectedFiles"] = ["control.scm"]
        self.save("evidence/failed.json", data)
        self.args.update(regime="whole-parallel", fileBudgetSeconds={"control.scm": cap})
        self.current = review.campaign(self.ctx, self.args, self.runtime, self.candidate, self.files, self.unit)
        self.doc["campaign"] = self.current
        entry = self.doc["failures"][0]
        entry["receiptSha256"] = digest(self.prior)
        entry["budget"]["file"] = "control.scm"
        for row in self.evidence["claims"]:
            row["failureReceiptSha256"] = digest(self.prior)
        self.save_review()

    def test_single_file_budget_binds_independent_cap_not_containing_suite(self):
        self.bind_single_file_budget(8)
        result = self.preflight()
        self.assertEqual([["known", "file-step", 8000]], result["facts"]["original_budget"])
        self.assertEqual([["known", "file-step", 8000]], result["facts"]["requested_budget"])

    def test_single_file_scope_cannot_be_invented_for_multi_file_history(self):
        self.bind_single_file_budget(8)
        self.doc["failures"][0]["budget"]["file"] = "other.scm"
        self.save_review()
        with self.assertRaisesRegex(ValueError, "original single-file"):
            self.preflight()


@unittest.skipUnless("GAMBIT_SMP_TEST_ENGINE" in os.environ, "run inside an actual sealed native engine")
class NativeRetryInferenceTests(TypedRetryReviewTests):
    def test_expanded_group_cap_is_native_denial(self):
        self.bind_group_budget(9)
        result = self.preflight()
        self.assertEqual("DENY", result["decision"])
        self.assertIn(["known", "budget-expanded"], result["answers"]["denied"])

    def test_same_regime_scope_change_is_native_denial(self):
        previous = json.loads(self.prior.read_text())
        previous["selectedFiles"] = ["other.scm"]
        self.save("evidence/failed.json", previous)
        self.doc["failures"][0]["receiptSha256"] = digest(self.prior)
        for row in self.evidence["claims"]:
            row["failureReceiptSha256"] = digest(self.prior)
        self.save_review()
        result = self.preflight()
        self.assertEqual([], result["facts"]["exact_whole_inventory"])
        self.assertEqual("DENY", result["decision"])
        self.assertIn(["known", "budget-regime-changed"], result["answers"]["denied"])

    def test_nested_budget_remains_native_denial_when_enlarged(self):
        self.bind_single_file_budget(9)
        result = self.preflight()
        self.assertEqual("DENY", result["decision"])
        self.assertIn(["known", "budget-expanded"], result["answers"]["denied"])

    def test_missing_nested_cap_cannot_be_authorized_by_whole_cap(self):
        self.bind_single_file_budget(8)
        self.args["fileBudgetSeconds"] = {}
        self.doc["campaign"] = review.campaign(self.ctx, self.args, self.runtime, self.candidate, self.files, self.unit)
        self.save_review()
        result = self.preflight()
        self.assertEqual("DENY", result["decision"])
        self.assertIn(["known", "budget-unbound"], result["answers"]["denied"])

    def test_build_step_uses_the_same_policy_and_original_budget(self):
        (self.runtime / "Makefile").write_text("synthetic makefile, never executed")
        self.files, self.unit = [Path("Makefile")], self.runtime
        self.args.update(mode="bootstrap", regime="build-step", operation="from-scratch")
        self.failure.update(category="budget", file="Makefile:from-scratch")
        self.save("evidence/native-failures.json", {"schema": "gambit-local-native-failures.v1", "failures": [self.failure]})
        self.prior = self.save("evidence/failed.json", {
            "seedReceiptSha256": digest(self.baseline), "wholeBootstrapBudget": 8,
            "steps": [{"name": "from-scratch", "exit": -9, "timeout": True}]})
        self.current = review.campaign(self.ctx, self.args, self.runtime, self.candidate, self.files, self.unit)
        self.doc["campaign"] = self.current
        entry = self.doc["failures"][0]
        entry.update(receiptSha256=digest(self.prior), failurePointer="/steps/0/exit",
                     budget={"regime": "build-step", "pointer": "/wholeBootstrapBudget"})
        for row in self.evidence["claims"]:
            row["failureReceiptSha256"] = digest(self.prior)
        self.save_review()
        result = self.preflight()
        self.assertEqual("RETRY_ELIGIBLE", result["decision"])
        self.assertEqual([["known", "suite-step", 8000]], result["facts"]["original_budget"])

    def test_source_change_cannot_waive_an_environment_failure(self):
        self.failure["category"] = "environment"
        self.save("evidence/native-failures.json", {"schema": "gambit-local-native-failures.v1", "failures": [self.failure]})
        self.current["failureInventorySha256"] = digest(self.root / "evidence/native-failures.json")
        self.save_review()
        result = self.preflight()
        self.assertEqual("DENY", result["decision"])
        self.assertIn(["known", "change-not-causally-reviewed"], result["answers"]["denied"])
    def test_missing_transitive_claim_is_inferred_by_native_ascent(self):
        self.evidence["claims"][2]["premises"] = ["source-lifetime-review"]
        self.save_review()
        result = self.preflight()
        self.assertEqual("DENY", result["decision"])
        self.assertIn(["known", "source-lifetime-review"], result["answers"]["missing"])

    def test_unchanged_input_is_native_denial_not_directory_retry(self):
        self.doc["failures"][0]["changes"] = []
        for row in self.evidence["claims"]:
            row["changes"] = []
        self.save_review()
        result = self.preflight()
        self.assertIn(["known", "unchanged-inputs"], result["answers"]["denied"])
        self.assertEqual("DENY", result["decision"])

    def test_budget_expansion_is_native_denial_even_when_campaign_is_bound(self):
        self.receipt["steps"][0]["budgetSeconds"] = 9
        self.current["suiteBudgetSeconds"] = 9
        self.save_review()
        result = self.preflight()
        self.assertIn(["known", "budget-expanded"], result["answers"]["denied"])
        self.assertEqual("DENY", result["decision"])

    def test_regime_change_is_not_an_atomic_to_whole_waiver(self):
        self.doc["failures"][0]["budget"] = {"regime": "atomic-coverage", "pointer": "/atomicBatchBudgetPerMode"}
        self.save_review()
        result = self.preflight()
        self.assertIn(["known", "budget-regime-changed"], result["answers"]["denied"])

    def test_finite_model_or_local_test_cannot_satisfy_causal_review(self):
        self.evidence["claims"][1]["domain"] = "finite-model"
        self.save_review()
        result = self.preflight()
        self.assertIn(["known", "change-relevance-review"], result["answers"]["missing"])
        self.assertEqual("DENY", result["decision"])

    def test_circular_claims_do_not_establish_a_review(self):
        self.evidence["claims"][0]["premises"] = ["assumptions-review"]
        self.evidence["claims"][2]["premises"] = ["failure-scope-review"]
        self.save_review()
        result = self.preflight()
        self.assertIn(["known", "circular-review"], result["answers"]["denied"])

    def test_no_review_remains_review_required(self):
        del self.args["retryReview"]
        self.assertEqual("REVIEW_REQUIRED", self.preflight()["decision"])

    def test_missing_second_failure_review_cannot_be_hidden(self):
        second = {**self.failure, "id": "second"}
        self.save("evidence/native-failures.json", {"schema": "gambit-local-native-failures.v1", "failures": [self.failure, second]})
        self.current["failureInventorySha256"] = digest(self.root / "evidence/native-failures.json")
        self.save_review()
        result = self.preflight()
        self.assertEqual("REVIEW_REQUIRED", result["decision"])
        self.assertIn(["second", "gsi"], result["answers"]["review"])
