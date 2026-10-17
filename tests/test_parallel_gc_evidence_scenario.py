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
            if path.startswith(".data/papers/"):
                paper = papers[path.split("/")[2]]
                self.assertEqual(paper["pdfSha256"], sha)
                self.assertTrue((ROOT / paper["notes"]).is_file())
                if (ROOT / path).is_file():
                    self.assertEqual(digest(ROOT / path), sha)
            else:
                self.assertEqual(digest(ROOT / path), sha)
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
            "missing_requirement", "model_observation", "counterexample", "obligation_count")}
        with engine_api() as (engine, identity):
            answers, first = evaluate(engine, facts, catalog, queries)
            self.assertEqual(len(answers["comparison"]), 4)
            self.assertEqual(len(answers["reference_requirement"]), 4)
            self.assertEqual(len(answers["missing_requirement"]), 5)
            self.assertEqual(len(answers["counterexample"]), 2)
            self.assertEqual(len(answers["model_observation"]), 1)
            self.assertEqual(answers["obligation_count"], [(5,)])
            repeated, second = evaluate(engine, facts, catalog, queries)
            self.assertEqual(repeated, answers)
            self.assertTrue(second["nativeResultReused"])
            withdrawn = dict(facts, source=[row for row in facts["source"] if row[0] != "chez-gc"])
            changed, third = evaluate(engine, withdrawn, catalog, queries)
            self.assertEqual(len(changed["comparison"]), 2)
            self.assertEqual(len(changed["reference_requirement"]), 2)
            self.assertEqual(changed["missing_requirement"], answers["missing_requirement"])
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
