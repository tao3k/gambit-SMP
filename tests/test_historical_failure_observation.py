"""Exact transport and native policy controls for recovered failure observations."""
import copy
import json
from pathlib import Path
import shutil
import tempfile
from types import SimpleNamespace
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.native_review import historical_observation
from gambit_smp.ascent_program import engine_api, load_catalog, query


ARCHIVE = "evidence/source-results/fixtures/thread-completion-contract/bootstrap-second-core-history"
ORIGINAL = "evidence/model-results/bootstrap-018-deny.json"
PAIRS = [("status", "/status", "/status"), ("exit", "/exit", "/steps/0/exit"),
         ("timeout", "/timeout", "/steps/0/timeout"),
         ("duration", "/seconds", "/steps/0/seconds"),
         ("budget", "/wholeBootstrapBudget", "/wholeBootstrapBudget")]


class HistoricalObservationTransportTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        shutil.copytree(ROOT / ARCHIVE, self.root / ARCHIVE)
        original = self.root / ORIGINAL
        original.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / ORIGINAL, original)
        self.original = json.loads(original.read_text())
        self.original_bytes = original.read_bytes()
        self.version = {"schema": "historical-failure-observation.v1",
            **{label: {"path": name, "sha256": digest(self.root / name)} for label, name in (
                ("original", ORIGINAL), ("archive", ARCHIVE + "/archive.json"), ("log", ARCHIVE + "/bootstrap.log"))},
            "agreements": [{"field": field, "original": before, "observed": after} for field, before, after in PAIRS]}
        self.failure = {"id": "historical", "receipt": ORIGINAL, "observation": "observation.json"}
        self.ctx = SimpleNamespace(root=self.root, bind=lambda paths: list(paths))

    def observe(self):
        (self.root / "observation.json").write_text(json.dumps(self.version))
        inputs = {ORIGINAL: digest(self.root / ORIGINAL)}
        facts = {"observation_bridge": [], "observation_equal_pointer": []}
        failure, recovered = historical_observation(self.ctx, self.failure, self.original, inputs, facts)
        return failure, recovered, inputs, facts

    def test_recovers_details_without_replacing_the_canonical_denial(self):
        failure, recovered, inputs, facts = self.observe()
        self.assertEqual(self.original_bytes, (self.root / ORIGINAL).read_bytes())
        self.assertEqual(ORIGINAL, failure["receipt"])
        self.assertEqual(-9, recovered["steps"][0]["exit"])
        self.assertEqual(600, recovered["wholeBootstrapBudget"])
        self.assertEqual(5, len(facts["observation_equal_pointer"]))
        self.assertIn(ARCHIVE + "/identity.json", inputs)

    def test_reference_drift_is_rejected(self):
        self.version["original"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "reference drift"):
            self.observe()

    def test_archive_member_drift_is_rejected(self):
        (self.root / ARCHIVE / "identity.json").write_text("{}")
        with self.assertRaises(ValueError):
            self.observe()

    def test_mismatch_is_not_emitted_as_an_agreement(self):
        self.original["exit"] = 0
        _, _, _, facts = self.observe()
        self.assertNotIn(["historical", "exit", "/exit", "/steps/0/exit"], facts["observation_equal_pointer"])

    def test_duplicate_labels_are_rejected(self):
        self.version["agreements"].append(self.version["agreements"][0])
        with self.assertRaisesRegex(ValueError, "unique"):
            self.observe()


class HistoricalObservationPolicyTests(unittest.TestCase):
    validation_domain = {"kind": "sealed-research", "budgetSeconds": 60, "workers": "auto", "processesPerWorker": 2}

    def setUp(self):
        self.catalog = load_catalog(ROOT / "evidence/research/suite-review-rules.ss")
        self.facts = {
            "retry_marker": [[True]], "known_failure": [["old", "bootstrap"]], "selected_failure": [["old"]],
            "failure_category": [["old", "budget"]], "review_present": [["old"]], "campaign_bound": [["old"]],
            "budget_regime": [["old", "build-step", "build-step"]],
            "required_budget": [["old", "suite-step"]], "original_budget": [["old", "suite-step", 600000]],
            "requested_budget": [["old", "suite-step", 600000]],
            "changed_input": [["old", "repair", "source", "lib/setup.c", "before", "after"]],
            "claim_evidence": [["old", label, "causal-review", "reviewed", "hash"] for label in
                ("failure-scope-review", "change-relevance-review", "assumptions-review", "historical-log-association-review")],
            "claim_change": [["old", "change-relevance-review", "repair"]],
            "observation_bridge": [["old", "gambit-two-pass-bootstrap-denial-summary.v1"]],
            "observation_equal_pointer": [["old", *row] for row in PAIRS]}

    def evaluate(self):
        with engine_api(retain=True) as (engine, _):
            return query(self.facts, self.catalog,
                         {"decision": "retry_decision", "denied": "retry_denied"}, engine=engine,
                         reuse_program=True)

    def test_exact_fields_and_explicit_association_allow_only_conditional_retry(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])

    def test_suite_bridge_requires_exact_scope_and_identity_roles(self):
        self.facts["observation_bridge"][0][1] = "gambit-native-suite-denial-summary.v1"
        rows = [("status", "/status", "/status"), ("exit", "/exit", "/results/0/exit"),
                ("timeout", "/timeout", "/results/0/timeout"),
                ("duration", "/seconds", "/results/0/seconds"),
                ("budget", "/wholeSuiteBudget", "/wholeSuiteBudgetPerMode"),
                ("mode", "/mode", "/results/0/mode"),
                ("denominator", "/selectedFiles", "/filesPerMode"),
                ("candidate", "/candidateReceiptSha256", "/candidateReceiptSha256")]
        self.facts["observation_equal_pointer"] = [["old", *row] for row in rows]
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
        for row in copy.deepcopy(self.facts["observation_equal_pointer"]):
            with self.subTest(field=row[1]):
                self.facts["observation_equal_pointer"].remove(row)
                self.assertIn(("old", "historical-field-unbound"), self.evaluate()["denied"])
                self.facts["observation_equal_pointer"].append(row)

    def test_each_missing_mapping_is_denied(self):
        for row in copy.deepcopy(self.facts["observation_equal_pointer"]):
            with self.subTest(field=row[1]):
                self.facts["observation_equal_pointer"].remove(row)
                self.assertIn(("old", "historical-field-unbound"), self.evaluate()["denied"])
                self.facts["observation_equal_pointer"].append(row)

    def test_same_value_under_wrong_pointer_cannot_fake_exit_binding(self):
        self.facts["observation_equal_pointer"][1] = ["old", "exit", "/status", "/status"]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_unknown_summary_schema_is_denied(self):
        self.facts["observation_bridge"][0][1] = "unknown"
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_log_association_is_not_inferred_from_equal_fields(self):
        self.facts["claim_evidence"].pop()
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_expanded_budget_remains_denied(self):
        self.facts["requested_budget"][0][2] += 1
        self.assertIn(("old", "budget-expanded"), self.evaluate()["denied"])
