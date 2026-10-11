import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp import research_audit as audit
from gambit_smp.framework import digest


class ResearchAuditTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "evidence").mkdir()
        (self.root / "models/gambit").mkdir(parents=True)
        self.runtime = self.root / "runtime"
        for name, text in {"gsi/gsi": "gsi", "gsc/gsc": "gsc",
                           "bin/gambuild-C": "GNU driver",
                           "tests/unit-tests/03-number/_num.scm": "original assertion"}.items():
            path = self.runtime / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        self.candidate = {"binarySha256": digest(self.runtime / "gsi/gsi"),
                          "gscSha256": digest(self.runtime / "gsc/gsc")}
        self.old = {"status": "DENY", "gsiSha256": self.candidate["binarySha256"],
                    "gscSha256": self.candidate["gscSha256"],
                    "sourceFiles": {"unit-tests/03-number/_num.scm":
                        digest(self.runtime / "tests/unit-tests/03-number/_num.scm")},
                    "results": [{"mode": "gsc", "accepted": False}],
                    "atomicBatchBudgetPerMode": 300,
                    "buildDriver": {"relativePath": "bin/gambuild-C",
                                    "sha256": digest(self.runtime / "bin/gambuild-C")}}
        self.save("old.json", self.old)
        self.save("candidate.json", self.candidate)
        self.save("evidence/native-failures.json", {"failures": [
            {"id": "num", "receipt": "old.json", "file": "03-number/_num.scm"}]})
        self.proposal = {"schema": "gambit-retry-proposal.v1", "failure": "num",
                         "candidateReceipt": "candidate.json", "runtime": "runtime",
                         "fixture": "03-number/_num.scm", "mode": "gsc",
                         "budgetSeconds": 300,
                         "hypothesis": {"cause": "diagnosed transition", "expectedObservation": "counterexample absent"}}

    def save(self, path, value):
        (self.root / path).write_text(json.dumps(value))

    def decisions(self, proposal=None):
        from pyDatalog import pyDatalog
        facts, _, _ = audit.retry_facts(self.root, proposal or self.proposal)
        pyDatalog.clear()
        # Seed base predicates referenced by the standalone research rules.
        arities = {**audit.ARITIES, "source_obligation": 2,
                   "has_model_receipt": 1, "contract_path": 2}
        for name, arity in arities.items():
            sentinel = ("__empty__",) * arity
            pyDatalog.assert_fact(name, *sentinel)
            pyDatalog.retract_fact(name, *sentinel)
            for row in facts.get(name, []):
                pyDatalog.assert_fact(name, *row)
        pyDatalog.load((audit.ROOT / "evidence/research-rules.dl").read_text())
        result = pyDatalog.ask("retry_denied(R, Reason)")
        review = pyDatalog.ask("retry_review_required(R)")
        return {r[1] for r in result.answers} if result else set(), bool(review)

    def change_compiler(self):
        (self.runtime / "gsc/gsc").write_text("changed compiler")
        self.candidate["gscSha256"] = digest(self.runtime / "gsc/gsc")
        self.save("candidate.json", self.candidate)

    def test_unchanged_failure_cannot_be_retried_by_renaming_attempt(self):
        proposal = {**self.proposal, "out": "new-attempt", "jobs": 1}
        self.assertEqual(({"unchanged-tested-inputs"}, False), self.decisions(proposal))

    def test_changed_bound_compiler_requires_review_not_runtime_admission(self):
        self.change_compiler()
        self.assertEqual((set(), True), self.decisions())

    def test_changed_driver_requires_review(self):
        (self.runtime / "bin/gambuild-C").write_text("changed GNU compiler flags")
        self.assertEqual((set(), True), self.decisions())

    def test_unbound_binary_fails_closed(self):
        (self.runtime / "gsc/gsc").write_text("unrecorded compiler")
        reasons, review = self.decisions()
        self.assertIn("unreviewed-artifact-identity", reasons)
        self.assertFalse(review)

    def test_budget_expansion_does_not_admit_changed_candidate(self):
        self.change_compiler()
        self.assertEqual(({"budget-expanded"}, False),
                         self.decisions({**self.proposal, "budgetSeconds": 600}))

    def test_interpreted_result_cannot_replace_compiled_failure(self):
        reasons, review = self.decisions({**self.proposal, "mode": "gsi"})
        self.assertIn("failure-scope-mismatch", reasons)
        self.assertFalse(review)

    def test_changed_fixture_is_review_only_and_original_patched_bytes_are_used(self):
        fixture = self.runtime / "tests/unit-tests/03-number/_num.scm"
        fixture.write_text("model-bound fixture assertion")
        self.assertEqual((set(), True), self.decisions())
        self.old["fixturePatches"] = [{"derivedFiles": {
            "unit-tests/03-number/_num.scm": digest(fixture)}}]
        self.save("old.json", self.old)
        self.assertEqual(({"unchanged-tested-inputs"}, False), self.decisions())

    def test_missing_hypothesis_still_denies_changed_inputs(self):
        self.change_compiler()
        self.assertEqual(({"missing-causal-hypothesis"}, False),
                         self.decisions({**self.proposal, "hypothesis": {}}))

    def test_unknown_failure_and_path_escape_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "known failure"):
            audit.retry_facts(self.root, {**self.proposal, "failure": "unknown"})
        with self.assertRaises(ValueError):
            audit.local(self.root, "../outside")
        with self.assertRaisesRegex(ValueError, "relative"):
            audit.local(self.root, "/absolute")

    def test_nonfinite_and_boolean_budgets_rejected(self):
        for invalid in (True, 0, -1, float("nan"), float("inf")):
            with self.assertRaisesRegex(ValueError, "budget"):
                audit.retry_facts(self.root, {**self.proposal, "budgetSeconds": invalid})

    def test_stale_review_model_is_not_silently_reapproved(self):
        path = self.root / "models/gambit/model.qnt"
        path.write_text("reviewed model")
        self.save("evidence/papers.json", {"papers": []})
        self.save("evidence/research-audit.json", {"schema": "gambit-research-audit.v1", "issues": [
            {"id": "i", "priority": 1, "barrier": "b", "next": "next",
             "models": ["model"], "prs": [], "papers": [],
             "evidence": [{"path": "models/gambit/model.qnt", "sha256": digest(path)}]}]})
        base = {"facts": {"model": [["model", digest(path), "scope"]], "pr": []}}
        audit.load_audit(self.root, base)
        path.write_text("model changed by Working")
        with self.assertRaisesRegex(ValueError, "stale audit evidence"):
            audit.load_audit(self.root, base)

    def test_real_audit_has_no_implicit_runtime_admission(self):
        base = audit.index.export()
        facts, inputs = audit.load_audit(audit.ROOT, base)
        audit.reusable_receipts(audit.ROOT, base, facts, inputs)
        results = audit.query(base, facts, audit.ROOT)
        self.assertEqual(6, len(results["blockers"]))
        self.assertTrue(results["pr_model_source_paths"])
        self.assertTrue(results["paper_model_paths"])
        self.assertNotIn("runtimeAdmitted", results)
        self.assertTrue(all(not Path(path).is_absolute() for path in inputs))

    def test_reusable_receipts_do_not_need_another_model_run(self):
        base = audit.index.export()
        facts, inputs = audit.load_audit(audit.ROOT, base)
        audit.reusable_receipts(audit.ROOT, base, facts, inputs)
        self.assertTrue(facts["audit_reusable_receipt"])
        results = audit.query(base, facts, audit.ROOT)
        recovered = {row[0] for row in facts["audit_reusable_receipt"]}
        self.assertFalse(recovered & {row[1] for row in results["missing_model_receipts"]})

    def test_legacy_receipts_are_review_not_missing_or_admitted(self):
        base = audit.index.export()
        facts, inputs = audit.load_audit(audit.ROOT, base)
        audit.reusable_receipts(audit.ROOT, base, facts, inputs)
        facts["audit_legacy_receipt"].append(("table_decode", "legacy.json", "digest"))
        facts["audit_reusable_receipt"] = [row for row in facts["audit_reusable_receipt"]
                                           if row[0] != "table_decode"]
        base["facts"]["model_receipt"] = [row for row in base["facts"].get("model_receipt", [])
                                            if row[0] != "table_decode"]
        results = audit.query(base, facts, audit.ROOT)
        self.assertIn(("table_decode", "legacy.json", "digest"), results["legacy_evidence_review"])
        self.assertNotIn("table_decode", {row[1] for row in results["missing_model_receipts"]})
