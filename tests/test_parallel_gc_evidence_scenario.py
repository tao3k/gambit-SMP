"""Python transports real reference facts; Scheme derives repair obligations."""
import json
import unittest

from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
from gambit_smp.framework import ROOT, digest


class ParallelGCScenario(unittest.TestCase):
    def test_reference_comparison_does_not_admit_gambit(self):
        directory = ROOT / "evidence/scenarios/parallel-gc"
        facts = json.loads((directory / "facts.json").read_text())["facts"]
        papers = {row["id"]: row for row in json.loads(
            (ROOT / "evidence/papers.lock.json").read_text())["papers"]}
        for _, path, sha, _ in facts["source"]:
            self.assertFalse({".data", ".cache"}.intersection(path.split("/")))
            self.assertEqual(digest(ROOT / path), sha)
        self.assertEqual(papers["ghc-parallel-gc-2008"]["notes"],
                         next(row[1] for row in facts["source"] if row[0] == "ghc-paper"))
        for _, path, sha, coverage, gap in facts["model_scope"]:
            self.assertEqual(digest(ROOT / path), sha)
            self.assertEqual(coverage, "partial")
            self.assertTrue(gap)
        receipt = json.loads((ROOT / facts["control"][0][3]).read_text())
        controls = {item["name"]: item for item in receipt["results"]}
        for name, _, outcome, _ in facts["control"]:
            self.assertTrue(controls[name]["accepted"])
            self.assertEqual(controls[name]["negative"], outcome == "decoded-counterexample")
            if controls[name]["negative"]:
                self.assertGreater(controls[name]["decodedStates"], 0)
        catalog = load_component_catalog(directory / "components.json", entry="parallel-gc",
            constructor="make-parallel-gc-review", trusted=True)
        queries = {name: name for name in ("comparison", "reference_requirement",
            "missing_requirement", "model_observation", "counterexample", "obligation_count",
            "transfer_evidence", "transfer_gap", "transfer_unbound")}
        with engine_api() as (engine, identity):
            answers, first = evaluate(engine, facts, catalog, queries)
            self.assertEqual(len(answers["comparison"]), 9)
            self.assertEqual(len(answers["reference_requirement"]), 4)
            self.assertEqual(len(answers["missing_requirement"]), 5)
            self.assertEqual(len(answers["counterexample"]), 2)
            self.assertEqual(len(answers["model_observation"]), 1)
            self.assertEqual(answers["obligation_count"], [(5,)])
            transfer = {row[0]: row for row in answers["transfer_evidence"]}
            self.assertEqual(set(transfer), {row[0] for row in facts["transfer_condition"]})
            self.assertEqual({row[0] for row in answers["transfer_gap"]}, set(transfer))
            self.assertEqual(answers["transfer_unbound"], [])
            for row in transfer.values():
                self.assertEqual(row[2], "vendor/gambit/lib/setup.c")
                self.assertEqual(row[11], "partial")
                self.assertTrue(row[12])
            repeated, second = evaluate(engine, facts, catalog, queries)
            self.assertEqual(repeated, answers)
            self.assertTrue(second["nativeResultReused"])
            withdrawn = dict(facts, source=[row for row in facts["source"] if row[0] != "chez-gc"])
            changed, third = evaluate(engine, withdrawn, catalog, queries)
            self.assertEqual(len(changed["comparison"]), 7)
            self.assertEqual(len(changed["reference_requirement"]), 2)
            self.assertEqual(changed["missing_requirement"], answers["missing_requirement"])
            self.assertEqual(changed["transfer_evidence"], answers["transfer_evidence"])
            without_domain = dict(facts, source=[row for row in facts["source"] if row[0] != "ocaml-domain"])
            unbound, _ = evaluate(engine, without_domain, catalog, queries)
            self.assertEqual({row[0] for row in unbound["transfer_evidence"]},
                             set(transfer) - {"backup-service-ownership", "retirement-work-fixed-point"})
            self.assertEqual(set(unbound["transfer_unbound"]), {
                ("backup-service-ownership", "reference-source-missing"),
                ("retirement-work-fixed-point", "reference-source-missing")})
            without_model = dict(facts, model_scope=[row for row in facts["model_scope"]
                                                   if row[0] != "retained-descriptor-reuse"])
            unsupported, _ = evaluate(engine, without_model, catalog, queries)
            self.assertNotIn("retained-descriptor-reuse", {row[0] for row in unsupported["transfer_evidence"]})
            self.assertEqual(unsupported["transfer_unbound"],
                             [("retained-descriptor-reuse", "model-scope-missing")])
            self.assertEqual(unsupported["missing_requirement"], answers["missing_requirement"])
            without_section = dict(facts, source_section=[row for row in facts["source_section"]
                                                         if row[0] != "chez-inactive-transition"])
            no_section, _ = evaluate(engine, without_section, catalog, queries)
            self.assertIn(("inactive-root-readiness", "reference-section-missing"),
                          no_section["transfer_unbound"])
            without_gambit = dict(facts, source=[row for row in facts["source"] if row[0] != "gambit-sync"])
            no_gambit, _ = evaluate(engine, without_gambit, catalog, queries)
            self.assertEqual(no_gambit["transfer_evidence"], [])
            self.assertEqual({row[0] for row in no_gambit["transfer_unbound"]}, set(transfer))
            for relation, omitted, condition, reason in (
                ("source_section", lambda row: row[0] == "gambit-startup-service",
                 "backup-service-ownership", "gambit-section-missing"),
                ("design", lambda row: row[0] == "ocaml" and row[1] == "blocking-service",
                 "backup-service-ownership", "reference-design-missing"),
                ("design", lambda row: row[0] == "gambit-baseline" and row[1] == "inactive-roots",
                 "inactive-root-readiness", "gambit-design-missing"),
                ("mechanism", lambda row: row == ["retirement-debt", "ocaml"],
                 "retirement-work-fixed-point", "mechanism-association-missing"),
            ):
                with self.subTest(relation=relation, reason=reason):
                    incomplete = dict(facts, **{relation: [row for row in facts[relation] if not omitted(row)]})
                    missing, _ = evaluate(engine, incomplete, catalog, queries)
                    self.assertNotIn(condition, {row[0] for row in missing["transfer_evidence"]})
                    self.assertIn((condition, reason), missing["transfer_unbound"])
                    self.assertEqual(missing["missing_requirement"], answers["missing_requirement"])
            restored, fourth = evaluate(engine, facts, catalog, queries)
            self.assertEqual(restored, answers)
            self.assertEqual(first["sessionOwner"], fourth["sessionOwner"])
            self.assertGreater(fourth["sourceGeneration"], third["sourceGeneration"])
            from gambit_smp.ascent_program import _query_owners
            owner = next(iter(_query_owners[engine].values()))
            explanation = owner.last_result.explanation("missing_requirement")
            owner.last_result.close()
            self.assertIn("source refinement", json.dumps(explanation.graph))
            explanation.close()
            self.assertTrue(identity)
        with self.assertRaises(ValueError):
            owner.session.run()


if __name__ == "__main__":
    unittest.main()
