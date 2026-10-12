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
        from gambit_smp.ascent_program import load_catalog, query
        facts, _, _ = audit.retry_facts(self.root, proposal or self.proposal)
        result = query(facts, load_catalog(audit.ROOT / "evidence/research-rules.ss"),
                       {"denied": "retry_denied", "review": "retry_review_required"})
        return {r[1] for r in result["denied"]}, bool(result["review"])

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

    def test_missing_historical_driver_helper_is_unbound_not_a_crash(self):
        self.old["buildDriver"]["helperSha256"] = {"missing-cache-helper": "0" * 64}
        self.save("old.json", self.old)
        facts, inputs, _ = audit.retry_facts(self.root, self.proposal)
        self.assertIn(("num",), facts["retry_unbound"])
        self.assertFalse(any("missing-cache-helper" in name for name in inputs))

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
        manifest = json.loads((audit.ROOT / "evidence/research-audit.json").read_text())
        expected = {(issue["id"], issue["barrier"]) for issue in manifest["issues"]}
        self.assertEqual(expected, {tuple(row) for row in results["blockers"]})
        self.assertTrue(results["pr_model_source_paths"])
        self.assertTrue(results["paper_model_paths"])
        self.assertNotIn("runtimeAdmitted", results)
        self.assertTrue(all(not Path(path).is_absolute() for path in inputs))

    def test_gc_requirements_remain_unclosed_with_all_references_present(self):
        base = audit.index.export()
        facts, inputs = audit.load_audit(audit.ROOT, base)
        results = audit.query(base, facts, audit.ROOT)
        issue = "notification-component-source-refinement"
        manifest = json.loads((audit.ROOT / "evidence/research-audit.json").read_text())
        reflections = {row["id"]: row["reflection"] for row in manifest["issues"]
                       if "reflection" in row}
        self.assertIn(issue, reflections)
        expected = {(name, row["id"], row["status"], row["gap"])
                    for name, reflection in reflections.items()
                    for row in reflection["requirements"]}
        self.assertEqual(expected, set(results["unclosed_requirements"]))
        conditions = {(name, row["id"], number, text)
                      for name, reflection in reflections.items()
                      for row in reflection["requirements"]
                      for number, text in enumerate(row["conditions"])}
        self.assertEqual(conditions, set(results["pending_acceptance_conditions"]))
        references = {name: {row["id"]: row for row in reflection["references"]}
                      for name, reflection in reflections.items()}
        paths = {(name, row["id"], ref, references[name][ref]["kind"], references[name][ref]["path"],
                  references[name][ref]["locator"], references[name][ref]["scope"])
                 for name, reflection in reflections.items()
                 for row in reflection["requirements"] for ref in row["references"]}
        self.assertEqual(paths, set(results["requirement_reference_paths"]))
        self.assertTrue(all(row["path"] in inputs
                            for rows in references.values() for row in rows.values()))
        self.assertNotIn("runtimeAdmitted", results)

    def test_reference_missing_from_issue_cannot_cross_join_another_issue(self):
        facts = {name: [] for name in audit.ARITIES}
        facts["reflection_requirement"].append(("first", "payload", "open", "untraced"))
        facts["reflection_condition"].append(("first", "payload", 0, "real tracing"))
        facts["reflection_requirement_reference"].append(("first", "payload", "same-id"))
        facts["reflection_reference"].append(
            ("second", "same-id", "observation", "receipt.json", "result", "component"))
        results = audit.query(audit.index.export(), facts, audit.ROOT)
        self.assertFalse(results["requirement_reference_paths"])
        self.assertEqual(1, len(results["pending_acceptance_conditions"]))

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
