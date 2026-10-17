"""Transport controls; mocked certificates here do not qualify a native runtime."""
import copy
import json
from pathlib import Path
import shutil
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp import completed_producer as producer, recipes, native_capabilities
from gambit_smp.framework import digest


class CompletedProducerTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name).resolve()
        self.run = self.root / ".data/fixtures/completed-source"
        self.source = self.root / "consumer/source"
        self.source.mkdir(parents=True)
        (self.source / "input.scm").write_text("locked source")
        shutil.copytree(self.source, self.run / "run/source/source")
        self.gcc = self.root / "gcc"
        self.gcc.write_text("unit compiler identity, never executed")
        runtime = self.run / "run/bootstrap/runtime"
        shutil.copytree(self.source, runtime)
        (runtime / "gsi").write_text("unit runtime identity, never executed")
        (runtime / "bin").mkdir()
        (runtime / "bin/gsi-script").symlink_to("../gsi")
        identity = self.save(".data/fixtures/completed-source/run/bootstrap/identity.json", {})
        self.save("evidence/source.lock.json", {})
        self.bootstrap = {"id": "bootstrap", "capability": "gambit.bootstrap", "outcome": "PASS",
            "fullTwoPassBootstrapEstablished": True, "phaseCounts": {f"phase{i}": 2 for i in range(1, 5)},
            "arguments": {"runtime": {"step": "seed", "output": "runtime"},
                          "identity": {"step": "seed", "output": "identity"}},
            "outputs": {"runtime": {"path": "bootstrap/runtime", "type": "source-runtime",
                                    "identity": recipes.tree_identity(runtime)},
                        "identity": {"path": "bootstrap/identity.json", "type": "runtime-identity",
                                     "sha256": digest(identity)}}}
        self.child = {"steps": [
            {"id": "source", "capability": "gambit.materialize", "outcome": "PASS",
             "arguments": {"sourceLock": "evidence/source.lock.json"},
             "outputs": {"source": {"path": "source/source", "identity": recipes.tree_identity(self.source)}}},
            {"id": "configure", "capability": "gambit.configure", "outcome": "PASS",
             "arguments": {"source": {"step": "source"}},
             "commands": [{"stage": "configure", "exit": 0, "timeout": False, "argv": sorted(producer.FLAGS)}]},
            {"id": "seed", "capability": "gambit.seed-core", "outcome": "PASS",
             "arguments": {"source": {"step": "configure"}}}, self.bootstrap]}
        self.outer = {"root": str(self.root), "outcome": "PASS", "exit": 0, "timeout": False,
                      "parentReaped": True, "processGroupQuiescent": True,
                      "budgetSeconds": 600, "seconds": 276, "wholeSeconds": 278,
                      "engine": str(self.root / "engine"), "engineId": "unit-engine"}
        for mocked in (
                patch("gambit_smp.research_kernel.inspect", return_value={"identityStatus": "CURRENT"}),
                patch("gambit_smp.research_kernel.manifest_paths",
                      return_value={"hostTools": {"gcc": {"sha256": digest(self.gcc)}}})):
            mocked.start()
            self.addCleanup(mocked.stop)
        self.refresh()

    def save(self, name, value):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value))
        return path

    def refresh(self):
        self.save(".data/fixtures/completed-source/receipt.json", self.outer)
        self.save(".data/fixtures/completed-source/run/receipt.json", self.child)
        self.save(".data/fixtures/completed-source/run/bootstrap/step-receipt.json", self.bootstrap)

    def reference(self):
        return producer.completed(self.root, self.run, "bootstrap")[0]

    def owner_teardown_denial(self):
        final_path = "verdict/rule-evaluation/answers.json"
        answers = self.save(".data/fixtures/completed-source/run/" + final_path, {"missing": []})
        self.child.update(outcome="DENY", wholeBudgetExhausted=False, inputsStable=True)
        self.child["steps"].append({"id": "verdict", "capability": "evidence.evaluate",
            "outcome": "PASS", "dependsOn": ["bootstrap"], "budgetSeconds": 10,
            "arguments": {"expected": {"missing": []}}, "artifacts": {final_path: digest(answers)}})
        owner = self.save(".data/fixtures/completed-source/run/evaluation-owner/receipt.json", {
            "exit": 0, "forcedTermination": False, "parentReaped": True,
            "terminalIdentityError": None, "engineId": "unit-engine",
            "requests": [{"requestCompleted": True, "timeout": False,
                          "response": {"outcome": "PASS"}}]})
        self.child["evaluationOwner"] = {"path": "evaluation-owner/receipt.json", "sha256": digest(owner)}
        launch = self.run / "launch.log"
        launch.write_text("TimeoutError: research deadline exhausted during evaluation owner teardown\n")
        self.outer.update(outcome="DENY", exit=1, childOutcome="DENY",
                          timeoutPolicy={"mode": "progress"}, artifacts={"launch.log": digest(launch)})
        recipe = self.save("evidence/recovery.recipe.json", {"steps": self.child["steps"]})
        self.save(".data/fixtures/completed-source/request.json", {"recipe": "evidence/recovery.recipe.json"})
        self.child["inputs"] = {str(recipe): digest(recipe)}
        self.refresh()

    def test_completed_owner_supersedes_only_obsolete_wall_clock_decision(self):
        self.owner_teardown_denial()
        original = (self.run / "receipt.json").read_bytes()
        with patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "unit-engine"}), \
                patch("gambit_smp.step_checkpoint.observe_journal", return_value=({"verified": True}, None, None, None)):
            proof = producer.recover_retained_owner_teardown(self.root, self.run, self.outer, self.child, "bootstrap")
        self.assertTrue(proof["supersedesHistoricalDecision"])
        self.assertEqual("completed-stages-and-reaped-owner", proof["currentDecision"])
        self.assertFalse(proof["failedStagesRecovered"])
        self.assertFalse(proof["budgetExtended"])
        self.assertEqual(original, (self.run / "receipt.json").read_bytes())

    def test_owner_supersession_rejects_native_failure_or_non_progress_policy(self):
        self.owner_teardown_denial()
        for field, target, value in (("outcome", self.bootstrap, "DENY"),
                                     ("timeoutPolicy", self.outer, {"mode": "wall"}),
                                     ("inputsStable", self.child, False)):
            before = target[field]
            target[field] = value
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "quiescent"):
                producer.recover_retained_owner_teardown(self.root, self.run, self.outer, self.child, "bootstrap")
            target[field] = before

    def test_owner_supersession_rejects_unrelated_denial_and_changed_owner(self):
        self.owner_teardown_denial()
        launch = self.run / "launch.log"
        launch.write_text("unrelated framework failure\n")
        self.outer["artifacts"]["launch.log"] = digest(launch)
        with self.assertRaisesRegex(ValueError, "obsolete owner"):
            producer.recover_retained_owner_teardown(self.root, self.run, self.outer, self.child, "bootstrap")
        self.owner_teardown_denial()
        owner = self.run / "run/evaluation-owner/receipt.json"
        owner.write_text("changed")
        with self.assertRaisesRegex(ValueError, "receipt changed"):
            producer.recover_retained_owner_teardown(self.root, self.run, self.outer, self.child, "bootstrap")

    def test_context_holds_runtime_lease_before_full_inspection(self):
        context = recipes.ExecutionContext(self.root, self.run, self.run, {},
            time.monotonic() + 15, {}, {}, {})
        runtime = self.run / "run/bootstrap/runtime"
        def inspect(*args, **kwargs):
            self.assertIn(runtime, context.leased_workspaces)
            return {"identityStatus": "CURRENT"}
        try:
            with patch("gambit_smp.research_kernel.inspect", side_effect=inspect):
                first = producer.completed(self.root, self.run, "bootstrap", workspace_context=context)[0]
                second = producer.completed(self.root, self.run, "bootstrap", workspace_context=context)[0]
                self.assertEqual(first, second)
                self.assertEqual(len(context.leased_workspaces), 1)
                self.assertGreater(context.leased_tree_checks.reused, 0)
                context.leased_tree_checks.verify()
        finally:
            context.workspace_leases.close()

    def test_early_lease_does_not_admit_stale_receipt(self):
        context = recipes.ExecutionContext(self.root, self.run, self.run, {},
            time.monotonic() + 15, {}, {}, {})
        try:
            with patch("gambit_smp.research_kernel.inspect", return_value={"identityStatus": "STALE"}):
                with self.assertRaisesRegex(ValueError, "evidence or artifacts drifted"):
                    producer.completed(self.root, self.run, "bootstrap", workspace_context=context)
        finally:
            context.workspace_leases.close()

    def stale_completion(self):
        recipe = self.save("evidence/recovery.recipe.json", {"steps": self.child["steps"]})
        self.save(".data/fixtures/completed-source/request.json", {"recipe": "evidence/recovery.recipe.json"})
        self.outer.update(outcome="DENY", exit=2, childOutcome="STALE")
        self.child.update(outcome="STALE", workspacePolicy="in-place", wholeBudgetExhausted=False,
                          inputs={str(recipe): digest(recipe)})
        self.refresh()

    def test_retained_completion_preserves_original_denial(self):
        self.stale_completion()
        before = (self.run / "receipt.json").read_bytes()
        with patch("gambit_smp.step_checkpoint.observe_journal", return_value=({"checked": True}, {}, [], {})):
            reference = self.reference()
        self.assertEqual(reference["completionRevalidation"]["recordedOutcome"], "DENY")
        self.assertFalse(reference["completionRevalidation"]["failedStagesRecovered"])
        self.assertEqual((self.run / "receipt.json").read_bytes(), before)

    def expired_final_review(self):
        from gambit_smp.evidence_capabilities import facts
        for index, row in enumerate(self.child["steps"]):
            row["dependsOn"] = [prior["id"] for prior in self.child["steps"][:index]]
        last = {"id": "verdict", "capability": "evidence.evaluate", "outcome": "TIMEOUT",
                "reason": "evaluation deadline exhausted", "commands": [], "budgetSeconds": 10,
                "dependsOn": [row["id"] for row in self.child["steps"]],
                "arguments": {"rules": ["evidence/rules.ss"], "queries": {"missing": "missing_step"},
                              "expected": {"missing": []}}}
        rule = self.root / "evidence/rules.ss"
        rule.write_text("unit rule, never executed")
        request = self.save(".data/fixtures/completed-source/run/verdict/rule-evaluation/evaluation.json",
            {"facts": facts(self.child), "queries": last["arguments"]["queries"],
             "rules": [str(rule)], "engineId": "unit-engine", "output": "unused"})
        last["artifacts"] = {str(request.relative_to(self.run / "run")): digest(request)}
        self.child["steps"].append(last)
        recipe = self.save("evidence/recovery.recipe.json", {"steps": self.child["steps"]})
        self.save(".data/fixtures/completed-source/request.json", {"recipe": "evidence/recovery.recipe.json"})
        self.outer.update(outcome="DENY", exit=1, childOutcome="DENY", wholeSeconds=700,
                          timeoutPolicy={"mode": "progress"})
        self.child.update(outcome="DENY", inputs={str(recipe): digest(recipe)})
        self.refresh()

    def test_expired_final_review_rechecks_sealed_rules_without_rebuilding(self):
        self.expired_final_review()
        before = (self.run / "receipt.json").read_bytes()
        def execute(argv, cwd, budget, *, metadata):
            self.assertEqual(10, budget)
            self.assertEqual("rules", argv[-2])
            request = json.loads(Path(argv[-1]).read_text())
            output = Path(request["output"])
            output.mkdir(exist_ok=True)
            (output / "answers.json").write_text(json.dumps({"missing": []}))
            metadata.update(parentReaped=True, processGroupQuiescent=True)
            return 0, "unit transport", False, .01
        with patch("gambit_smp.framework.execute", side_effect=execute) as run, \
                patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "unit-engine", "hostTools": {"gcc": {"sha256": digest(self.gcc)}}}):
            reference = self.reference()
            self.assertEqual(reference, self.reference())
        self.assertEqual(1, run.call_count)
        self.assertFalse(reference["completionRevalidation"]["failedStagesRecovered"])
        self.assertFalse(reference["completionRevalidation"]["budgetExtended"])
        self.assertEqual(before, (self.run / "receipt.json").read_bytes())

    def test_expired_final_review_cannot_recover_native_failure(self):
        self.expired_final_review()
        self.child["steps"][-2]["outcome"] = "DENY"
        self.refresh()
        with patch("gambit_smp.framework.execute") as run:
            with self.assertRaises(ValueError):
                self.reference()
            run.assert_not_called()

    def test_retained_completion_rejects_failed_stage_and_missing_inventory(self):
        self.stale_completion()
        self.child["steps"][-1]["outcome"] = "FAIL"
        self.refresh()
        with self.assertRaises(ValueError):
            self.reference()
        self.stale_completion()
        self.child["steps"].pop()
        self.refresh()
        with self.assertRaisesRegex(ValueError, "incomplete stage"):
            self.reference()

    def test_retained_completion_requires_actual_journal_check(self):
        self.stale_completion()
        with patch("gambit_smp.step_checkpoint.observe_journal", side_effect=ValueError("journal drift")):
            with self.assertRaisesRegex(ValueError, "journal drift"):
                self.reference()

    def duplicate_context(self):
        ctx = recipes.ExecutionContext(self.root, self.root / "attempt", self.root / "attempt", {},
            float("inf"), {}, {"steps": copy.deepcopy(self.child["steps"])}, {"gcc": str(self.gcc)})
        return ctx

    def test_duplicate_bootstrap_denied_with_explicit_reuse_receipt(self):
        self.save("evidence/research/completed.json", self.reference())
        ctx = self.duplicate_context()
        with self.assertRaisesRegex(ValueError, "use gambit.completed-runtime"):
            producer.prevent_duplicate_bootstrap(self.bootstrap["arguments"], ctx)
        decision = ctx.receipt["buildReuseDecisions"][0]
        self.assertEqual("DENY_DUPLICATE_BOOTSTRAP", decision["decision"])
        self.assertEqual("evidence/research/completed.json", decision["producer"])

    def checkpoint_seed(self):
        original_seed = copy.deepcopy(self.child["steps"][2])
        original_seed["outputs"] = copy.deepcopy(self.bootstrap["outputs"])
        proof = {"unit": "checked seed proof"}
        seed = self.child["steps"][2]
        seed.update(capability="gambit.seed-checkpoint", checkpoint=proof,
                    outputs=copy.deepcopy(original_seed["outputs"]),
                    arguments={"source": {"step": "source", "output": "source"},
                               "checkpoint": "evidence/checkpoint.json",
                               "buildProfile": "evidence/profile.json"})
        self.save("evidence/checkpoint.json", {})
        mocked = patch("gambit_smp.step_checkpoint.seed_reference", return_value=(
            (proof, {}, {}, original_seed), self.child["steps"][1], self.child["steps"][0], {}))
        mocked.start()
        self.addCleanup(mocked.stop)
        self.refresh()

    def test_completed_checkpoint_uses_original_configuration_for_duplicate_guard(self):
        self.checkpoint_seed()
        self.save("evidence/research/completed.json", self.reference())
        ctx = self.duplicate_context()
        with self.assertRaisesRegex(ValueError, "use gambit.completed-runtime"):
            producer.prevent_duplicate_bootstrap(self.bootstrap["arguments"], ctx)
        self.assertEqual("bootstrap", ctx.receipt["buildReuseDecisions"][0]["stage"])

    def test_configure_guard_recognizes_completed_checkpoint_ancestry(self):
        self.checkpoint_seed()
        self.save("evidence/research/completed.json", self.reference())
        ctx = self.duplicate_context()
        with self.assertRaisesRegex(ValueError, "use gambit.completed-runtime"):
            producer.prevent_duplicate_configuration(self.child["steps"][1]["arguments"], ctx)

    def test_checkpoint_artifact_drift_cannot_become_completed_producer(self):
        self.checkpoint_seed()
        self.child["steps"][2]["outputs"]["identity"]["sha256"] = "0" * 64
        self.refresh()
        with self.assertRaisesRegex(ValueError, "checkpoint ancestry or artifacts drifted"):
            self.reference()

    def test_in_place_checkpoint_binds_seed_epoch_not_preconfigure_epoch(self):
        self.checkpoint_seed()
        seed = self.child["steps"][2]
        seed["storageTransfer"] = {"schema": "in-place-checkpoint-storage.v1"}
        self.child["steps"][0]["outputs"]["source"]["identity"] = seed["outputs"]["runtime"]["identity"]
        self.refresh()
        self.assertEqual(self.reference()["step"], "bootstrap")

    def test_materialized_source_reused_without_shared_writes(self):
        self.save("evidence/research/completed.json", self.reference())
        ctx = self.duplicate_context()
        ctx.directory.mkdir(parents=True)
        result = producer.reuse_materialized_source(self.root / "evidence/source.lock.json", ctx)
        self.assertIsNotNone(result)
        target = ctx.directory / "source/input.scm"
        target.write_text("consumer edit")
        self.assertEqual("locked source", (self.run / "run/source/source/input.scm").read_text())
        self.assertEqual("REUSE_MATERIALIZED_SOURCE", ctx.receipt["buildReuseDecisions"][0]["decision"])
        self.assertFalse((ctx.directory / "source.tar").exists())

    def test_materialized_source_drift_denied_before_copy(self):
        self.save("evidence/research/completed.json", self.reference())
        (self.run / "run/source/source/input.scm").write_text("drift")
        ctx = self.duplicate_context()
        with self.assertRaisesRegex(ValueError, "source tree drift"):
            producer.reuse_materialized_source(self.root / "evidence/source.lock.json", ctx)
        self.assertFalse((ctx.directory / "source").exists())

    def test_explicit_producer_is_not_chosen_by_filename_order(self):
        selected = "evidence/research/semantic-selected.json"
        self.save(selected, self.reference())
        stale = self.reference()
        stale["childReceiptSha256"] = "0" * 64
        self.save("evidence/research/000-stale.json", stale)
        ctx = self.duplicate_context()
        ctx.receipt["steps"].append({"id":"reuse", "capability":"gambit.completed-runtime",
            "arguments":{"source":{"step":"source","output":"source"},"producer":selected}})
        ctx.directory.mkdir(parents=True)
        self.assertIsNotNone(producer.reuse_materialized_source(self.root/"evidence/source.lock.json",ctx))
        self.assertEqual(selected,ctx.receipt["buildReuseDecisions"][0]["producer"])

    def test_explicit_invalid_or_ambiguous_producer_never_falls_back(self):
        self.save("evidence/research/valid.json", self.reference())
        selected = "evidence/research/selected.json"
        self.save(selected, {"schema":"unknown"})
        ctx = self.duplicate_context()
        ctx.receipt["steps"].append({"id":"reuse", "capability":"gambit.completed-runtime",
            "arguments":{"source":{"step":"source","output":"source"},"producer":selected}})
        with self.assertRaisesRegex(ValueError,"does not match the source lock"):
            producer.reuse_materialized_source(self.root/"evidence/source.lock.json",ctx)
        ctx.receipt["steps"].append({"id":"other", "capability":"gambit.completed-runtime",
            "arguments":{"source":{"step":"source","output":"source"},
                         "producer":"evidence/research/valid.json"}})
        with self.assertRaisesRegex(ValueError,"ambiguous"):
            producer.reuse_materialized_source(self.root/"evidence/source.lock.json",ctx)

    def test_explicit_reference_comes_from_plan_not_partial_execution_receipt(self):
        selected = "evidence/research/selected.json"
        self.save(selected,self.reference())
        ctx = self.duplicate_context()
        planned = copy.deepcopy(ctx.receipt["steps"])
        planned.append({"id":"future-consumer", "capability":"gambit.completed-runtime",
            "arguments":{"source":{"step":"source","output":"source"},"producer":selected}})
        ctx.planned_steps = tuple(planned)
        ctx.receipt["steps"] = [ctx.receipt["steps"][0]]
        ctx.directory.mkdir(parents=True)
        self.assertIsNotNone(producer.reuse_materialized_source(self.root/"evidence/source.lock.json",ctx))
        self.assertEqual(selected,ctx.receipt["buildReuseDecisions"][0]["producer"])

    def test_materialized_source_unregistered_or_different_lock_is_not_reused(self):
        ctx = self.duplicate_context()
        lock = self.root / "evidence/source.lock.json"
        self.assertIsNone(producer.reuse_materialized_source(lock, ctx))
        self.save("evidence/research/completed.json", self.reference())
        lock.write_text('{"different": true}')
        self.assertIsNone(producer.reuse_materialized_source(lock, ctx))

    def test_missing_historical_cache_does_not_block_fresh_materialization(self):
        self.save("evidence/research/completed.json", self.reference())
        shutil.rmtree(self.root / ".data")
        ctx = self.duplicate_context()
        self.assertIsNone(producer.reuse_materialized_source(self.root / "evidence/source.lock.json", ctx))

    def test_explicit_completed_producer_requires_its_runtime(self):
        selected = "evidence/research/completed.json"
        self.save(selected, self.reference())
        shutil.rmtree(self.root / ".data")
        ctx = self.duplicate_context()
        ctx.receipt["steps"].append({"id": "reuse", "capability": "gambit.completed-runtime",
            "arguments": {"source": {"step": "source", "output": "source"}, "producer": selected}})
        with self.assertRaisesRegex(ValueError, "runtime is unavailable"):
            producer.reuse_materialized_source(self.root / "evidence/source.lock.json", ctx)

    def test_materialized_source_reference_drift_cannot_trigger_rebuild(self):
        proof = self.reference()
        proof["childReceiptSha256"] = "0" * 64
        self.save("evidence/research/completed.json", proof)
        ctx = self.duplicate_context()
        with self.assertRaisesRegex(ValueError, "no silent rematerialization"):
            producer.reuse_materialized_source(self.root / "evidence/source.lock.json", ctx)
        self.assertFalse((ctx.directory / "source").exists())

    def test_distinct_configuration_or_compiler_not_a_duplicate(self):
        self.save("evidence/research/completed.json", self.reference())
        ctx = self.duplicate_context()
        ctx.receipt["steps"][1]["arguments"]["cOptimization"] = 2
        producer.prevent_duplicate_bootstrap(self.bootstrap["arguments"], ctx)
        self.assertNotIn("buildReuseDecisions", ctx.receipt)
        ctx = self.duplicate_context()
        self.gcc.write_text("different compiler identity")
        producer.prevent_duplicate_bootstrap(self.bootstrap["arguments"], ctx)

    def test_duplicate_configuration_denied_before_storage_or_tools(self):
        self.save("evidence/research/completed.json", self.reference())
        ctx = self.duplicate_context()
        args = ctx.receipt["steps"][1]["arguments"]
        # Configure must not need a seed or bootstrap in the new campaign.
        ctx.receipt["steps"] = ctx.receipt["steps"][:1]
        with patch.object(native_capabilities, "clone") as clone, \
                patch.object(native_capabilities, "compiler") as compiler:
            with self.assertRaisesRegex(ValueError, "use gambit.completed-runtime"):
                native_capabilities.configure(args, ctx)
            clone.assert_not_called()
            compiler.assert_not_called()
        self.assertEqual("configure", ctx.receipt["buildReuseDecisions"][0]["stage"])
        self.assertFalse((self.root / "attempt/source").exists())

    def test_early_guard_allows_first_or_distinct_configuration(self):
        ctx = self.duplicate_context()
        args = ctx.receipt["steps"][1]["arguments"]
        producer.prevent_duplicate_configuration(args, ctx)
        self.save("evidence/research/completed.json", self.reference())
        producer.prevent_duplicate_configuration({**args, "cOptimization": 2}, ctx)
        self.assertNotIn("buildReuseDecisions", ctx.receipt)

    def test_early_guard_rejects_drift_without_allocating_storage(self):
        proof = self.reference()
        proof["childReceiptSha256"] = "0" * 64
        self.save("evidence/research/completed.json", proof)
        ctx = self.duplicate_context()
        with patch.object(native_capabilities, "clone") as clone:
            with self.assertRaisesRegex(ValueError, "no silent duplicate rebuild"):
                native_capabilities.configure(ctx.receipt["steps"][1]["arguments"], ctx)
            clone.assert_not_called()

    def test_early_guard_respects_existing_deadline(self):
        self.save("evidence/research/completed.json", self.reference())
        ctx = self.duplicate_context()
        ctx.remaining = lambda: (_ for _ in ()).throw(TimeoutError("original deadline"))
        with self.assertRaisesRegex(TimeoutError, "original deadline"):
            producer.prevent_duplicate_configuration(ctx.receipt["steps"][1]["arguments"], ctx)

    def test_drifted_registered_producer_cannot_trigger_silent_rebuild(self):
        proof = self.reference()
        proof["outerReceiptSha256"] = "0" * 64
        self.save("evidence/research/completed.json", proof)
        with self.assertRaisesRegex(ValueError, "no silent duplicate rebuild"):
            producer.prevent_duplicate_bootstrap(self.bootstrap["arguments"], self.duplicate_context())

    def test_unregistered_or_unrelated_evidence_does_not_block_first_build(self):
        self.save("evidence/research/unrelated.json", {"schema": "not-a-producer"})
        producer.prevent_duplicate_bootstrap(self.bootstrap["arguments"], self.duplicate_context())

    def reuse(self, proof=None):
        proof = self.reference() if proof is None else proof
        path = self.save("evidence/producer.json", proof)
        directory = self.root / "consumer/handoff"
        directory.mkdir(parents=True)
        ctx = recipes.ExecutionContext(self.root, self.root / "consumer", directory, {},
            float("inf"), {}, {"steps": []}, {"gcc": str(self.gcc)})
        ctx.artifact = lambda reference, kind: self.source
        result = producer.reuse({"source": {"step": "source", "output": "source"},
                                 "producer": path.relative_to(self.root).as_posix()}, ctx)
        return result, ctx

    def test_same_source_transfer_keeps_producer_charge_without_native_admission(self):
        before = (self.run / "receipt.json").read_bytes()
        result, ctx = self.reuse()
        self.assertEqual(278, result["producerExpenditure"]["wholeSeconds"])
        self.assertEqual(600, result["producerExpenditure"]["budgetSeconds"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertEqual(before, (self.run / "receipt.json").read_bytes())
        self.assertEqual(1, len(ctx.receipt["upstreamProducerExpenditures"]))
        self.assertEqual("source-runtime", result["outputs"]["runtime"]["type"])
        self.assertEqual({"link": "../gsi"}, result["outputs"]["runtime"]["identity"]["bin/gsi-script"])

    def test_each_incomplete_or_non_quiescent_parent_is_rejected(self):
        original = copy.deepcopy(self.outer)
        for key, value in (("outcome", "DENY"), ("exit", -9), ("timeout", True),
                           ("parentReaped", False), ("processGroupQuiescent", False)):
            with self.subTest(field=key):
                self.outer = {**original, key: value}
                self.refresh()
                with self.assertRaisesRegex(ValueError, "quiescent"):
                    self.reference()

    def test_spent_or_original_budget_cannot_be_reset_or_expanded_by_certificate(self):
        for spent in (0, -1, 601, True):
            with self.subTest(spent=spent):
                self.outer["wholeSeconds"] = spent
                self.refresh()
                with self.assertRaisesRegex(ValueError, "expenditure"):
                    self.reference()

    def test_nonfinite_charge_is_rejected_by_the_strict_json_reader(self):
        self.outer["wholeSeconds"] = float("nan")
        self.refresh()
        with self.assertRaisesRegex(ValueError, "nonfinite JSON"):
            self.reference()

    def test_one_pass_is_not_full_bootstrap(self):
        self.bootstrap["phaseCounts"]["phase3"] = 1
        self.refresh()
        with self.assertRaisesRegex(ValueError, "two-pass"):
            self.reference()

    def test_missing_threaded_vm_flag_is_rejected(self):
        self.child["steps"][1]["commands"][0]["argv"].remove("--enable-multiple-threaded-vms")
        self.refresh()
        with self.assertRaisesRegex(ValueError, "three concurrency"):
            self.reference()

    def test_source_drift_cannot_load_old_binary(self):
        proof = self.reference()
        (self.source / "input.scm").write_text("different candidate")
        with self.assertRaisesRegex(ValueError, "locked source"):
            self.reuse(proof)

    def test_compiler_drift_is_rejected(self):
        proof = self.reference()
        self.gcc.write_text("different compiler")
        with self.assertRaisesRegex(ValueError, "compiler differs"):
            self.reuse(proof)

    def test_exact_reference_drift_is_rejected(self):
        proof = self.reference()
        proof["outerReceiptSha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "reference drift"):
            self.reuse(proof)

    def test_stale_observation_cannot_transfer(self):
        with patch("gambit_smp.research_kernel.inspect", return_value={"identityStatus": "STALE"}):
            with self.assertRaisesRegex(ValueError, "drifted"):
                self.reference()

    def test_source_must_be_a_typed_dependency(self):
        step = {"id": "transfer", "capability": "gambit.completed-runtime", "dependsOn": [],
                "arguments": {"source": {"step": "source", "output": "source"}}}
        source = {"id": "source", "capability": "gambit.materialize"}
        with self.assertRaisesRegex(ValueError, "explicit dependency"):
            native_capabilities.graph(step, {"source": source}, recipes.CAPABILITIES)

    def test_cache_escape_is_rejected(self):
        proof = self.reference()
        proof["run"] = "../outside"
        with self.assertRaises(ValueError):
            self.reuse(proof)
