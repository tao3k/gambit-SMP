import copy
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.generator_contract import app, audit, name


def fixture():
    domain = app("to", {"kind": "int", "value": 0}, {"kind": "int", "value": 2})
    key = {"kind": "str", "value": "count"}
    candidate = {"kind": "let", "opdef": {"name": "candidate", "qualifier": "val",
        "expr": app("Rec", key, name("count"))},
        "expr": app("actionAll", app("predicate", name("candidate")),
                    app("assign", name("s"), name("candidate")))}
    initializer = {"kind": "let", "opdef": {"name": "count", "qualifier": "nondet",
        "expr": app("oneOf", copy.deepcopy(domain))}, "expr": candidate}
    return {"stage": "parsing", "modules": [{"name": "proof", "declarations": [
        {"name": "s", "kind": "var", "typeAnnotation": {"kind": "const", "name": "State"}},
        {"name": "State", "kind": "typedef", "type": {"kind": "rec", "fields": {
            "kind": "row", "fields": [{"fieldName": "count", "fieldType": {"kind": "int"}}],
            "other": {"kind": "empty"}}}},
        {"name": "predicate", "qualifier": "puredef"},
        {"name": "initI", "qualifier": "action", "expr": initializer},
        {"name": "shape", "expr": app("in", app("field", name("s"), key), domain)},
        {"name": "I", "expr": app("and", name("shape"), app("predicate", name("s")))}]}]}


class GeneratorContractTests(unittest.TestCase):
    def test_archived_real_gc_ir_contract_matches_receipt(self):
        archive = ROOT / "evidence/model-results/gc-induction-cartesian-contract-ir"
        receipt = json.loads((archive / "receipt.json").read_text())
        proof_ir = archive / "proof-ir.json"
        self.assertEqual(receipt["generatorContract"]["proofIrSha256"], digest(proof_ir))
        contract = audit(json.loads(proof_ir.read_text()), "gc_recursive_queue_induction",
                         "initSafetyCandidate", "candidateInvariant")
        self.assertEqual(25, len(contract["stateFields"]))
        self.assertEqual(22, contract["independentChoices"])
        self.assertEqual(receipt["generatorContract"]["stateFields"], contract["stateFields"])
        self.assertTrue(receipt["preservationComplete"])
        self.assertFalse(receipt["inductiveSafetyAdmitted"])

    def test_closed_cartesian_contract(self):
        result = audit(fixture(), "proof", "initI", "I")
        self.assertTrue(result["contractVerified"])
        self.assertFalse(result["solverCoverageProved"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertEqual(["count"], result["stateFields"])

    def test_missing_values_and_narrow_generator_are_rejected(self):
        ir = fixture()
        ir["modules"][0]["declarations"][3]["expr"]["opdef"]["expr"]["args"][0]["args"][1]["value"] = 1
        with self.assertRaisesRegex(ValueError, "domains differ"):
            audit(ir, "proof", "initI", "I")

    def test_hidden_filter_cannot_remove_candidate_states(self):
        ir = fixture()
        ir["modules"][0]["declarations"][3]["expr"]["expr"]["expr"]["args"].insert(0, app("eq", name("count"), {"kind": "int", "value": 0}))
        with self.assertRaises(ValueError):
            audit(ir, "proof", "initI", "I")

    def test_missing_record_field_is_rejected(self):
        ir = fixture()
        ir["modules"][0]["declarations"][1]["type"]["fields"]["fields"].append({"fieldName": "extra"})
        with self.assertRaisesRegex(ValueError, "entire closed"):
            audit(ir, "proof", "initI", "I")

    def test_state_dependent_domain_is_rejected(self):
        ir = fixture()
        ir["modules"][0]["declarations"][3]["expr"]["opdef"]["expr"]["args"][0] = name("s")
        with self.assertRaisesRegex(ValueError, "closed and independent"):
            audit(ir, "proof", "initI", "I")

    def test_impure_filter_and_wrong_state_type_are_rejected(self):
        for index, key, value in ((2, "qualifier", "def"), (0, "typeAnnotation", {"name": "Other"})):
            ir = fixture()
            ir["modules"][0]["declarations"][index][key] = value
            with self.assertRaises(ValueError):
                audit(ir, "proof", "initI", "I")


if __name__ == "__main__":
    unittest.main()
