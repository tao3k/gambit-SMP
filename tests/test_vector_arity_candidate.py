"""Immutable candidate checks; these do not qualify an SMP runtime."""
import json
import unittest

from gambit_smp.framework import ROOT, digest


class VectorArityCandidateTests(unittest.TestCase):
    def read(self, relative):
        return json.loads((ROOT / relative).read_text())

    def test_busy_delay_observation_is_not_stress_acceptance(self):
        from gambit_smp import recipes
        path = "evidence/research/smp-threaded-vm-native-grid/vector-arity-busy-delay-observation.recipe.json"
        recipes.load(ROOT, ROOT / path)
        recipe = self.read(path)
        source = next(step for step in recipe["steps"] if step["id"] == "source")
        lock = self.read(source["arguments"]["sourceLock"])
        self.assertIn(lock["patch"], recipe["inputs"])
        observation = next(step for step in recipe["steps"] if step["id"] == "busy-delay-gsi")
        self.assertEqual("gsi", observation["arguments"]["mode"])
        self.assertNotIn("processors", observation["arguments"])
        self.assertNotIn("jobs", observation["arguments"])
        self.assertEqual(["diagnostics/busy_delay_calibration.scm"], observation["arguments"]["expectedFiles"])
        original = (ROOT / "vendor/gambit/tests/unit-tests/06-thread/tfib_stress.scm").read_text()
        sample = (ROOT / "models/gambit/native/busy_delay_calibration.scm").read_text()
        for body in ("(define (busy-sleep n) (if (> n 0) (busy-sleep (- n 1)) #f))",
                     "(define (short-delay) (busy-sleep 6000))"):
            self.assertIn(body, original)
            self.assertIn(body, sample)
        self.assertIn("(go 15 5000)", original)
        self.assertNotIn("RTLD_NEXT", sample)
        self.assertNotIn("c-declare", sample)

    def test_pending_join_campaign_keeps_corrected_errno_fixture_and_controls(self):
        folder = "evidence/research/vm-registry-reader-lease/"
        old = self.read(folder + "pending-join-errno-native-recovery.recipe.json")
        current = self.read(folder + "vector-arity-pending-join-errno.recipe.json")
        self.assertEqual(old["budgetSeconds"], current["budgetSeconds"])
        before = {step["id"]: step for step in old["steps"]}
        self.assertEqual(set(before), {step["id"] for step in current["steps"]})
        for step in current["steps"]:
            if step["id"] not in {"source", "producer"}:
                self.assertEqual(before[step["id"]], step)
        self.assertFalse(any(step["capability"] == "gambit.bootstrap" for step in current["steps"]))

    def test_root_fault_campaign_keeps_owner_recovery_and_original_whole_budget(self):
        from gambit_smp import recipes
        folder = "evidence/research/vm-registry-reader-lease/"
        recipes.load(ROOT, ROOT / (folder + "vector-arity-root-sticky.recipe.json"))
        previous = self.read(folder + "vector-arity-pending-join-errno.recipe.json")
        current = self.read(folder + "vector-arity-root-sticky.recipe.json")
        self.assertEqual(previous["budgetSeconds"], current["budgetSeconds"])
        rows = {step["id"]: step for step in current["steps"]}
        for step in previous["steps"]:
            if step["id"] != "verdict":
                self.assertEqual(step, rows[step["id"]])
        native = rows["root-sticky-native"]
        self.assertEqual(120, native["budgetSeconds"])
        self.assertTrue({"independent-vms", "root-safe", "root-reset-control",
                         "root-overwrite-control", "root-trajectories"} <= set(native["dependsOn"]))
        self.assertIn("root-sticky-native", rows["verdict"]["dependsOn"])

    def test_terminal_observation_successor_only_adds_checks(self):
        from gambit_smp import recipes
        folder = "evidence/research/vm-registry-reader-lease/"
        previous = self.read(folder + "vector-arity-root-sticky.recipe.json")
        current = self.read(folder + "vector-arity-root-terminal-observation.recipe.json")
        recipes.load(ROOT, ROOT / (folder + "vector-arity-root-terminal-observation.recipe.json"))
        self.assertEqual(previous["budgetSeconds"], current["budgetSeconds"])
        after = {step["id"]: step for step in current["steps"]}
        for old in previous["steps"]:
            new = after[old["id"]]
            self.assertEqual(old["capability"], new["capability"])
            self.assertEqual(old["arguments"], new["arguments"])
            self.assertEqual(old["budgetSeconds"], new["budgetSeconds"])
            self.assertTrue(set(old["dependsOn"]) <= set(new["dependsOn"]))
        self.assertTrue({"group-safe", "group-guess-control", "group-unreaped-control",
                         "group-trajectories"} <= set(after["root-sticky-native"]["dependsOn"]))

    def test_constructor_fault_plan_preserves_model_domains_and_unsafe_policies(self):
        from gambit_smp import recipes
        path = "evidence/research/vm-constructor-owned-rollback/vector-arity-runtime-sync.recipe.json"
        recipes.load(ROOT, ROOT / path)
        recipe = self.read(path)
        source = next(step for step in recipe["steps"] if step["id"] == "source")
        self.assertIn(self.read(source["arguments"]["sourceLock"])["patch"], recipe["inputs"])
        self.assertEqual(300, recipe["budgetSeconds"])
        self.assertFalse(any(step["capability"] == "gambit.bootstrap" for step in recipe["steps"]))
        rows = {step["id"]: step for step in recipe["steps"]}
        native = rows["constructor-native"]
        self.assertEqual(120, native["budgetSeconds"])
        controls = {"memory-init-old", "memory-init-roots", "memory-init-sections",
                    "memory-init-blanket", "memory-init-unlocked", "memory-init-invalid",
                    "publication-init-early", "publication-init-deferred",
                    "publication-init-unchecked", "publication-init-split"}
        self.assertTrue(controls <= set(native["dependsOn"]))
        for name in controls:
            self.assertTrue(rows[name]["arguments"]["negative"])
        self.assertIn("memory-init-fixed", native["dependsOn"])
        self.assertIn("publication-init-fixed", native["dependsOn"])
        self.assertEqual(15, rows["memory-init-fixed"]["budgetSeconds"])

    def test_topology_population_review_keeps_native_workload_and_budgets(self):
        folder = "evidence/research/vm-registry-reader-lease/"
        old = self.read(folder + "btq-retry-topology.recipe.json")
        current = self.read(folder + "vector-arity-topology.recipe.json")
        reviewed = self.read(folder + "vector-arity-topology-reviewed.recipe.json")
        select = lambda recipe: next(s for s in recipe["steps"] if s["id"] == "independent-vms")
        self.assertEqual(select(old), select(current))
        self.assertEqual(300, reviewed["budgetSeconds"])
        self.assertEqual(120, select(reviewed)["budgetSeconds"])
        enhanced = dict(select(reviewed)["arguments"])
        latency = dict(enhanced["latency"])
        plan = latency.pop("populationPlan")
        enhanced["latency"] = latency
        self.assertEqual(select(current)["arguments"], enhanced)
        self.assertEqual({"reservedPositions": 2, "minimumPopulation": 2,
                          "minimumProcessorsPerOwner": 2}, plan)
        self.assertTrue({"population-safe", "population-header-only-control",
                         "retirement-safe", "retirement-early-control",
                         "resize-safe-progress", "resize-count-control", "resize-early-control"}
                        <= set(select(reviewed)["dependsOn"]))

    def test_full_scope_pr_campaign_contains_all_declared_regressions(self):
        folder = "evidence/research/smp-threaded-vm-native-grid/"
        full = self.read(folder + "vector-arity-pr-full-scope.recipe.json")
        declared = self.read(folder + "vector-arity-pr-interpreted.recipe.json")
        select = lambda recipe: next(s for s in recipe["steps"] if s["id"] == "pr-regressions-gsi")
        complete, subset = select(full), select(declared)
        self.assertTrue(set(subset["arguments"]["expectedFiles"]).issubset(
            complete["arguments"]["expectedFiles"]))
        self.assertEqual(380, len(complete["arguments"]["expectedFiles"]))
        self.assertEqual(["."], complete["arguments"]["selection"])
        self.assertEqual(300, full["budgetSeconds"])

    def test_independent_vm_successor_preserves_native_and_model_contracts(self):
        folder = "evidence/research/vm-kernel-entry-lifecycle/"
        old = self.read(folder + "native.recipe.json")
        new = self.read(folder + "vector-arity-native.recipe.json")
        self.assertEqual(old["budgetSeconds"], new["budgetSeconds"])
        before = {s["id"]: s for s in old["steps"]}
        for step in new["steps"]:
            if step["id"] not in {"source", "producer"}:
                self.assertEqual(before[step["id"]], step)
        producer = next(s for s in new["steps"] if s["id"] == "producer")
        proof = self.read(producer["arguments"]["producer"])
        self.assertEqual("evidence/fixtures/vector-increment-arity-parity/source.lock.json", proof["sourceLock"])

    def test_only_vector_primitive_added_to_inherited_closure(self):
        old = self.read("evidence/fixtures/btq-retry-sync-participation/source.lock.json")
        new = self.read("evidence/fixtures/vector-increment-arity-parity/source.lock.json")
        self.assertEqual(old["revision"], new["revision"])
        self.assertEqual(22, len(new["files"]))
        for path, identity in old["files"].items():
            self.assertEqual(identity, new["files"][path])
        self.assertEqual({"lib/gambit/vector/vector.scm"}, new["files"].keys() - old["files"].keys())
        self.assertEqual(new["patchSha256"], digest(ROOT / new["patch"]))

    def test_bootstrap_flags_and_budgets_not_relaxed(self):
        folder = "evidence/research/vm-registry-reader-lease/"
        old = self.read(folder + "btq-retry-bootstrap.recipe.json")
        new = self.read(folder + "vector-arity-bootstrap.recipe.json")
        self.assertEqual(old["budgetSeconds"], new["budgetSeconds"])
        before = {step["id"]: step for step in old["steps"]}
        after = {step["id"]: step for step in new["steps"]}
        for name in ("configure", "seed", "review", "bootstrap"):
            self.assertEqual(before[name]["arguments"], after[name]["arguments"])
            self.assertEqual(before[name]["budgetSeconds"], after[name]["budgetSeconds"])
        self.assertIn("arity-parity", after["configure"]["dependsOn"])
        self.assertIn("arity-old-control", after["configure"]["dependsOn"])

    def test_old_failed_fixture_is_preserved(self):
        self.assertEqual(
            "70638536be2d9058ee886f97743e591157e31421356a8f4371a67b860155acde",
            digest(ROOT / "models/gambit/native/vector_increment_arity.scm"),
        )
        fixture = (ROOT / "models/gambit/native/vector_increment_arity_contract.scm").read_text()
        self.assertIn("(test-equal 2 (##vector-inc! value 0))", fixture)
        self.assertIn("(test-equal 3 (vector-ref value 0))", fixture)
        self.assertIn("(test-equal 3 (##vector-inc! value 0 -2))", fixture)

    def test_complete_inventory_and_stress_workload_are_unchanged(self):
        folder = "evidence/research/smp-threaded-vm-native-grid/"
        for suffix, step_name in (("interpreted", "native-gsi"), ("stress-interpreted", "stress-gsi")):
            before = self.read(folder + "btq-retry-" + suffix + ".recipe.json")
            after = self.read(folder + "vector-arity-" + suffix + ".recipe.json")
            self.assertEqual(before["budgetSeconds"], after["budgetSeconds"])
            select = lambda recipe: next(step for step in recipe["steps"] if step["id"] == step_name)
            self.assertEqual(select(before), select(after))

    def test_pr_campaign_uses_locked_source_without_fixture_replacement(self):
        recipe = self.read("evidence/research/smp-threaded-vm-native-grid/vector-arity-pr-interpreted.recipe.json")
        lock = self.read("evidence/fixtures/vector-increment-arity-parity/source.lock.json")
        case = next(step for step in recipe["steps"] if step["id"] == "pr-regressions-gsi")
        args = case["arguments"]
        path = "06-thread/thread_interrupt.scm"
        self.assertEqual(lock["files"]["tests/unit-tests/" + path]["candidateSha256"],
                         digest(ROOT / "models/gambit/native/pr988/thread_interrupt_completion.scm"))
        self.assertNotIn(path, args["additionalFixtures"])
        self.assertEqual(args["expectedFiles"], args["selection"])
        self.assertEqual(7, len(args["expectedFiles"]))
        self.assertEqual(300, recipe["budgetSeconds"])
        self.assertFalse(any(step["capability"] in {"gambit.seed-core", "gambit.bootstrap"} for step in recipe["steps"]))

    def test_pr_review_is_exact_projection_not_new_failure_claims(self):
        folder = "evidence/research/smp-threaded-vm-native-grid/"
        original = self.read(folder + "btq-retry-gsi-intent.json")
        projection = self.read(folder + "vector-arity-pr-gsi-intent.json")
        expected = {"018-thread-interrupt", "018-write-shared", "018-table-search",
                    "020-ended-interrupt-lock", "022-pr1038-serialization-gc"}
        self.assertEqual(expected, {row["id"] for row in projection["failures"]})
        originals = {row["id"]: row for row in original["failures"]}
        for row in projection["failures"]:
            self.assertEqual(originals[row["id"]], row)
        all_failures = {row["id"] for row in self.read("evidence/native-failures.json")["failures"]}
        self.assertIn("018-gc-table-iteration", all_failures)
        self.assertTrue(expected <= all_failures)

    def test_table_counterexample_keeps_original_bytes_and_case_budget(self):
        folder = "evidence/research/smp-threaded-vm-native-grid/"
        intent = self.read(folder + "vector-arity-table-iteration-review-intent.json")
        recipe = self.read(folder + "vector-arity-table-iteration-reviewed.recipe.json")
        prior = self.read("evidence/model-results/native-table-iteration-018-deny.json")
        case = next(step for step in recipe["steps"] if step["id"] == "table-iteration-gsi")
        path = prior["selectedFiles"][0]
        self.assertEqual("current-producer-review-intent.v1", intent["schema"])
        self.assertEqual(prior["selectedFiles"], case["arguments"]["expectedFiles"])
        self.assertEqual(prior["wholeSuiteBudgetPerMode"], case["budgetSeconds"])
        self.assertEqual(prior["wholeSuiteBudgetPerMode"], case["arguments"]["fileBudgetSeconds"][path])
        fixture = case["arguments"]["additionalFixtures"][path]
        self.assertEqual(prior["extraFixtures"][path]["sha256"], fixture["sha256"])
        self.assertEqual(fixture["sha256"], digest(ROOT / fixture["source"]))
        entry = intent["failures"][0]
        self.assertEqual(entry["receiptSha256"], digest(ROOT / "evidence/model-results/native-table-iteration-018-deny.json"))
        self.assertEqual(prior["candidateReceiptSha256"], entry["baselineIdentity"]["sha256"])
        for claim in entry["claims"]:
            self.assertEqual(claim["evidence"]["sha256"], digest(ROOT / claim["evidence"]["path"]))
