"""Real Scheme reuse policy plus immutable receipt I/O; no native SMP admission."""
import hashlib
import io
import json
from pathlib import Path
import tempfile
import sys
import subprocess
import unittest
import uuid
from contextlib import redirect_stdout
from unittest.mock import patch

from gambit_smp import research_kernel, step_checkpoint


class ResearchResumptionTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        self.run = self.root / ".cache/run"
        (self.run / "run").mkdir(parents=True)
        self.source = self.root / "source"
        self.source.write_text("source")
        self.recipe_path = self.root / "recipe.json"
        self.recipe_path.write_text('{}')
        self.child = {"recipe": "generic-work", "outcome": "DENY", "inputsStable": True,
                      "steps": [
                          {"id": "producer", "outcome": "PASS", "dependsOn": [],
                           "outputs": {"artifact": {"type": "opaque", "path": "producer/artifact"}},
                           "commands": [{"exit": 7, "expectedExit": 7, "timeout": False,
                                         "parentReaped": True, "processGroupQuiescent": True}]},
                          {"id": "validation", "outcome": "TIMEOUT", "dependsOn": ["producer"]}]}
        self.outer = {"schema": "sealed-research-run.v1", "recipe": "generic-work",
                      "root": str(self.root), "engineId": "engine", "outcome": "DENY",
                      "parentReaped": True, "processGroupQuiescent": True,
                      "stepBudgets": {"producer": 5, "validation": 5},
                      "inputs": {p.name: self.sha(p.read_bytes()) for p in (self.source, self.recipe_path)}}
        self.inspection = {"identityStatus": "CURRENT", "evidenceBindingStatus": "CURRENT",
                           "artifactAvailability": {"outputs": [
                               {"step": "producer", "output": "artifact", "status": "AVAILABLE"}]}}
        self.save()

    @staticmethod
    def sha(data):
        return hashlib.sha256(data).hexdigest()

    def save(self, *, attest=True):
        if attest:
            from gambit_smp.research_kernel import retain_run_record
            self.run = self.root / ".cache" / uuid.uuid4().hex
            (self.run / "run").mkdir(parents=True)
            header = {"schema": "research-run-header.v1", "runId": uuid.uuid4().hex,
                "recipe": self.outer["recipe"], "engineId": self.outer["engineId"],
                "inputs": dict(self.outer["inputs"]), "stepBudgets": self.outer["stepBudgets"],
                "declaration": {"id": self.outer["recipe"], "scope": "generic fixture, not native qualification",
                                "inputs": list(self.outer["inputs"]), "steps": self.child["steps"]}}
            reference = retain_run_record(self.root, self.run / "run-header.json", "resumption-fixture", header, header["inputs"])
            for row in self.child["steps"]:
                record = {"schema": "research-step-observation.v1", "runId": header["runId"],
                    "header": reference, "step": row, "toolInputs": {}, "dependencies": {}}
                record["supportInventory"] = step_checkpoint.support_inventory(self.root, header, row, {})
                retain_run_record(self.root, self.run / "run" / (row["id"] + ".observation.json"),
                                  reference["scope"], record, header["inputs"])
        data = json.dumps(self.child).encode()
        (self.run / "run/receipt.json").write_bytes(data)
        self.outer["childReceiptSha256"] = self.sha(data)
        (self.run / "receipt.json").write_text(json.dumps(self.outer))

    def state(self):
        return step_checkpoint.resumption(self.root, self.run, self.inspection)

    def supported(self, name):
        return [(name, step_checkpoint.content_id(next(row for row in self.child["steps"] if row["id"] == name)))]

    def finish(self):
        self.outer["outcome"] = self.child["outcome"] = "PASS"
        self.child["steps"][1]["outcome"] = "PASS"
        self.save()

    def test_partial_failure_reuses_success_without_admitting_campaign(self):
        state = self.state()
        self.assertEqual(state["historyStatus"], "VERIFIED")
        self.assertEqual(state["relations"]["historical_complete"], self.supported("producer"))
        self.assertEqual(state["relations"]["reusable"], self.supported("producer"))
        self.assertEqual(state["relations"]["failed"], [("validation", "TIMEOUT")])
        self.assertEqual(state["relations"]["unresolved"], [("validation",)])
        self.assertEqual(state["relations"]["campaign_reusable"], [])
        self.assertFalse(state["executionAuthorized"])
        declarations = state["relations"]["support_declaration"]
        self.assertEqual({row[2] for row in declarations}, {"generic fixture, not native qualification"})
        self.assertEqual({row[4] for row in declarations}, {self.outer["engineId"]})
        self.assertTrue(state["relations"]["support_witness"])

    def test_scheme_distinguishes_closed_failed_history_from_live_partial_and_success(self):
        self.assertEqual(self.state()['relations']['failed_attempt_history'],[()])
        self.source.write_text('changed candidate; old failure remains history')
        self.assertEqual(self.state()['relations']['failed_attempt_history'],[()])
        self.outer['processGroupQuiescent']=False
        self.save()
        self.assertEqual(self.state()['relations']['failed_attempt_history'],[])
        self.outer['processGroupQuiescent']=True
        removed=self.child['steps'].pop()
        self.save()
        self.assertEqual(self.state()['relations']['failed_attempt_history'],[])
        self.child['steps'].append(removed)
        self.finish()
        self.assertEqual(self.state()['relations']['failed_attempt_history'],[])

    def test_cleanup_does_not_erase_success_or_make_artifact_executable(self):
        self.inspection["artifactAvailability"]["outputs"][0]["status"] = "MISSING"
        state = self.state()["relations"]
        self.assertEqual(state["historical_complete"], self.supported("producer"))
        self.assertEqual(state["artifact_unavailable"], [("producer",)])
        self.assertEqual(state["reusable"], [])
        self.assertEqual(state["campaign_reusable"], [])

    def test_source_change_retains_history_but_invalidates_current_support(self):
        self.inspection["identityStatus"] = self.inspection["evidenceBindingStatus"] = "STALE"
        state = self.state()["relations"]
        self.assertEqual(state["historical_complete"], self.supported("producer"))
        self.assertEqual(state["invalidated"], [("producer",)])
        self.assertEqual(state["reusable"], [])

    def test_raw_source_digest_overrides_a_stale_aggregate_current_label(self):
        self.source.write_text("changed bytes without changing the caller label")
        state = self.state()["relations"]
        self.assertEqual(state["historical_complete"], self.supported("producer"))
        self.assertEqual(state["reusable"], [])
        producer = self.supported("producer")[0][1]
        self.assertIn((producer, producer, "binding"), state["invalidated_by"])

    def test_missing_command_observation_is_not_a_successful_empty_command(self):
        self.child["steps"][0]["commands"] = [{}]
        self.save()
        self.assertEqual(self.state()["relations"]["historical_complete"], [])

    def test_omitted_inventory_cannot_reclassify_itself_as_empty(self):
        self.outer["inputs"] = {}
        self.child["steps"][0]["commands"] = []
        self.save(attest=False)
        state = self.state()
        self.assertEqual(state["relations"]["reusable"], [])
        self.assertTrue(state["relations"]["enumeration_gap"])

    def test_caller_scope_cannot_erase_an_unfinished_declared_stage(self):
        self.outer["outcome"] = self.child["outcome"] = "PASS"
        self.outer["stepBudgets"] = {}
        self.save(attest=False)
        state = self.state()
        self.assertEqual(state["requiredSteps"], [])
        self.assertEqual(state["relations"]["campaign_reusable"], [])

    def test_equal_size_input_substitution_does_not_match_the_retained_manifest(self):
        other = self.root / "other-source"
        other.write_text("unrelated bytes")
        del self.outer["inputs"]["source"]
        self.outer["inputs"][other.name] = self.sha(other.read_bytes())
        self.save(attest=False)
        relations = self.state()["relations"]
        self.assertTrue(relations["enumeration_gap"])
        self.assertTrue(relations["binding_gap"])
        self.assertEqual(relations["reusable"], [])

    def test_scheme_checks_expected_nonzero_exit_without_python_reclassification(self):
        self.child["steps"][0]["commands"][0].update(exit=7, expectedExit=7)
        self.save()
        self.assertEqual(self.state()["relations"]["historical_complete"], self.supported("producer"))
        self.child["steps"][0]["commands"][0]["timeout"] = True
        self.save()
        self.assertEqual(self.state()["relations"]["historical_complete"], [])

    def test_retained_predecessor_does_not_force_rebuilding_complete_generation(self):
        self.finish()
        self.inspection["artifactAvailability"]["outputs"][0]["status"] = "RETAINED"
        state = self.state()["relations"]
        self.assertEqual(state["historical_only"], [("producer",)])
        self.assertEqual(state["campaign_reusable"], [()])
        self.assertNotIn(self.supported("producer")[0], state["reusable"])

    def test_corrupt_receipt_is_unknown_history_not_a_zero_progress_claim(self):
        (self.run / "run/receipt.json").write_text('{}')
        state = self.state()
        self.assertEqual(state["historyStatus"], "UNVERIFIED")
        self.assertNotIn("completedCount", state)
        self.assertEqual(state["relations"]["campaign_reusable"], [])

    def test_bad_native_teardown_cannot_be_reused_as_a_pass(self):
        self.child["steps"][0]["commands"][0]["processGroupQuiescent"] = False
        self.save()
        self.assertEqual(self.state()["relations"]["historical_complete"], [])

    def test_unknown_parent_completion_does_not_erase_committed_stage_history(self):
        self.outer["processGroupQuiescent"] = False
        self.save()
        state = self.state()
        self.assertEqual(state["historyStatus"], "VERIFIED")
        self.assertEqual(state["relations"]["historical_complete"], self.supported("producer"))
        self.assertEqual(state["relations"]["reusable"], [])
        self.assertFalse(state["parentCompletionObserved"])

    def test_checkpoint_provenance_is_not_the_requested_target_identity(self):
        state = self.state()
        self.assertEqual(state["recordedRecipe"], self.outer["recipe"])
        self.assertEqual(state["recordedEngineId"], self.outer["engineId"])
        self.assertEqual(state["recordedInputIdentity"], step_checkpoint.content_id(self.outer["inputs"]))

    def test_failed_dependency_cannot_be_hidden_by_a_passing_descendant(self):
        self.child["steps"][0]["outcome"] = "TIMEOUT"
        self.child["steps"][1]["outcome"] = "PASS"
        self.save()
        self.assertEqual(self.state()["relations"]["historical_complete"], [])

    def test_receipt_drift_during_inference_rejects_reuse(self):
        from gambit_smp.ascent_program import query

        def drift(*args, **kwargs):
            result = query(*args, **kwargs)
            (self.run / "receipt.json").write_text('{}')
            return result

        with patch("gambit_smp.ascent_program.query", side_effect=drift):
            with self.assertRaisesRegex(ValueError, "checkpoint changed"):
                self.state()

    def kernel_request(self, state):
        recipe = {"schema": research_kernel.SCHEMA, "id": "generic-work", "inputs": ["source"],
                  "budgetSeconds": 10}
        inspected = dict(self.inspection, resumption=state)
        original = (self.run / "receipt.json").read_bytes()
        steps = [{"id": name, "budgetSeconds": cap} for name, cap in self.outer["stepBudgets"].items()]
        with patch("gambit_smp.recipes.load", return_value=(recipe, steps)), \
                patch.object(research_kernel, "manifest_paths", return_value={"engineId": "engine"}), \
                patch.object(research_kernel, "inspect", return_value=inspected), \
                patch.object(research_kernel, "execute") as execute:
            result = research_kernel.run_sealed(self.root, self.recipe_path, self.run, self.root / "engine")
        execute.assert_not_called()
        self.assertEqual((self.run / "receipt.json").read_bytes(), original)
        return result

    def test_existing_completed_request_is_consumed_without_a_native_launch(self):
        self.finish()
        result = self.kernel_request(self.state())
        self.assertEqual(result["resumeStatus"], "REUSED")
        self.assertEqual(result["outcome"], "PASS")
        self.assertFalse(result["executionLaunched"])

    def test_existing_failure_returns_state_without_retry_or_history_rewrite(self):
        result = self.kernel_request(self.state())
        self.assertEqual(result["resumeStatus"], "UNRESOLVED")
        self.assertEqual(result["recordedOutcome"], "DENY")
        self.assertEqual(result["resumption"]["relations"]["reusable"], self.supported("producer"))

    def test_changed_requested_inputs_cannot_consume_a_passing_checkpoint(self):
        self.finish()
        state = self.state()
        self.source.write_text("different source")
        result = self.kernel_request(state)
        self.assertFalse(result["requestedIdentityMatches"])
        self.assertEqual(result["resumeStatus"], "UNRESOLVED")

    def test_policy_cannot_upgrade_a_failed_origin_to_a_reused_pass(self):
        state = self.state()
        state["relations"]["campaign_reusable"] = [()]
        result = self.kernel_request(state)
        self.assertEqual(result["outcome"], "DENY")
        self.assertEqual(result["recordedOutcome"], "DENY")
        self.assertEqual(result["resumeStatus"], "UNRESOLVED")

    def test_cli_exposes_checkpoint_state_instead_of_hiding_it_behind_pass(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        self.finish()
        result = self.kernel_request(self.state())
        output = io.StringIO()
        with patch.object(research_kernel, "ROOT", self.root), \
                patch("gambit_smp.recipes.source_path", return_value=self.recipe_path), \
                patch("gambit_smp.recipes.load"), \
                patch.object(research_kernel, "run_sealed", return_value=result), \
                patch.object(sys, "argv", ["research", "--run", "evidence/recipe.recipe.json",
                                          "--engine", str(self.root / "engine"), "--out", str(self.run)]), \
                redirect_stdout(output):
            # This checks adapter serialization, not the live workspace dispatcher.
            self.assertEqual(research_kernel.main.__wrapped__(), 0)
        payload = json.loads(output.getvalue())
        self.assertEqual(payload["resumeStatus"], "REUSED")
        self.assertFalse(payload["executionLaunched"])
        self.assertEqual(payload["resumption"]["receiptSha256"], result["resumption"]["receiptSha256"])


if __name__ == "__main__":
    unittest.main()
