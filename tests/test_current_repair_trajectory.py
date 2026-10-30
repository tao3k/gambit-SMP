"""Real domain declarations and discovery; no runtime admission or native runs."""
import unittest

from gambit_smp.ascent_program import engine_api, evaluate, load_evidence_catalog
from gambit_smp.evidence_views import load, registry
from gambit_smp.framework import ROOT


VIEW = "evidence/scenarios/runtime-lifecycle/current-repair.view.json"


class CurrentRepairTrajectoryTests(unittest.TestCase):
    def test_registered_contracts_expose_specific_unclosed_clauses(self):
        self.assertIn(VIEW, registry(ROOT)[0])
        doc, facts, catalog, _ = load(ROOT, VIEW)
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, doc["queries"])
        gates = {"repair-lifecycle", "repair-gc-ffi", "repair-gerbil", "repair-performance"}
        self.assertTrue(gates <= {row[0] for row in answers["unclosed"]})
        self.assertEqual(answers["applicable"], [])
        self.assertEqual(answers["reusable"], [])
        self.assertTrue(gates <= {row[2] for row in answers["clue"]})
        self.assertTrue(all(row[3] == "counter" for row in answers["clue"]))
        self.assertIn(["repair-lifecycle", "repair-join-identity"], facts["dependency"])
        self.assertIn(["repair-gc-ffi", "repair-retirement-census"], facts["dependency"])
        self.assertNotIn(["repair-gerbil", "repair-retirement-census"], facts["dependency"])
        self.assertEqual(facts.get("receipt", []), [])

    def test_navigation_misses_expose_vocabulary_without_selecting_evidence(self):
        catalog = load_evidence_catalog(ROOT / "evidence/scenarios/stack-header/clues.ss",
            constructor="make-stack-entry-navigation", trusted=True)
        facts = {
            "clue": [["a", "one", "first", "counter", "observation", "audit"],
                     ["b", "two", "second", "counter", "observation", "audit"]],
            "factor": [["a", "one", "contract", "lifecycle"],
                       ["a", "one", "worker", "A"],
                       ["b", "two", "contract", "gc"],
                       ["b", "two", "worker", "B"]],
            "binding": [["SUBJECT", "lifecycle"]],
        }
        queries = {name: name for name in ("question", "unknown_binding", "conjunction_gap",
            "available_factor", "available_value", "nearby_observation")}
        with engine_api() as (engine, _):
            unknown, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(unknown["question"], [])
            self.assertEqual(set(unknown["available_factor"]), {("contract",), ("worker",)})
            self.assertEqual(unknown["nearby_observation"], [])
            scoped, _ = evaluate(engine, dict(facts, binding=[
                ["contract", "lifecycle"], ["worker", "unknown"]]), catalog, queries)
            self.assertEqual(scoped["question"], [])
            self.assertEqual(scoped["available_value"], [("worker", "A")])
            self.assertTrue(all(row[:3] == ("first", "a", "one")
                                for row in scoped["nearby_observation"]))
            mixed, _ = evaluate(engine, dict(facts, binding=[
                ["contract", "lifecycle"], ["worker", "B"]]), catalog, queries)
            self.assertEqual(mixed["question"], [])
            self.assertTrue(mixed["conjunction_gap"])
            corrected, _ = evaluate(engine, dict(facts, binding=[
                ["contract", "lifecycle"], ["worker", "A"]]), catalog, queries)
            self.assertEqual(corrected["question"], [("first",)])
            self.assertEqual(corrected["nearby_observation"], [])
            self.assertEqual(corrected["available_factor"], [])

    def test_existing_observation_contract_rejects_vm_wide_and_cross_worker_witnesses(self):
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/observation-contract.ss",
            constructor="make-observation-contract", trusted=True)
        identities = {"worker": "A", "owner": "host-owner", "incarnation": "current"}
        required = [[case, field, value] for case in ("join-error", "join-success")
                    for field, value in identities.items()]
        facts = {"RequiredCase": [["join-error"], ["join-success"]],
                 "RequiredField": required,
                 "ObservedCase": [["join-error", 0], ["join-success", 1]]}
        queries = {name: name for name in ("MissingCase", "MissingField", "WrongField")}
        exact = [[case, i, field, value] for i, case in enumerate(("join-error", "join-success"))
                 for field, value in identities.items()]
        with engine_api() as (engine, _):
            aggregate, _ = evaluate(engine, dict(facts, ObservedField=[]), catalog, queries)
            self.assertEqual(len(aggregate["MissingField"]), len(required))
            for field in identities:
                crossed = [row[:3] + ["other"] if row[0] == "join-success" and row[2] == field
                           else row for row in exact]
                invalid, _ = evaluate(engine, dict(facts, ObservedField=crossed), catalog, queries)
                self.assertIn(("join-success", 1, field), invalid["WrongField"])
            valid, _ = evaluate(engine, dict(facts, ObservedField=exact), catalog, queries)
            self.assertTrue(all(not rows for rows in valid.values()))


if __name__ == "__main__":
    unittest.main()
