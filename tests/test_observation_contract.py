"""Two real mechanism inventories through the same Scheme contract and ABI."""
import copy
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.ascent_program import engine_api
from gambit_smp.observation_contract import evaluate, bind_execution, project, encoded


class ObservationContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.owner = engine_api(retain=True)
        cls.engine, cls.identity = cls.owner.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.owner.__exit__(None, None, None)

    def declared(self, name):
        path = "evidence/research/observation-contract/" + name + ".contract.json"
        return path, json.loads((ROOT / path).read_text())["cases"]

    def answers(self, path, rows):
        return evaluate(ROOT, path, rows, engine=self.engine)[0]

    def test_two_mechanisms_share_exact_contract(self):
        for mechanism in ("schedule", "vm-log"):
            with self.subTest(mechanism=mechanism):
                path, rows = self.declared(mechanism)
                self.assertTrue(rows)
                self.assertTrue(all(not values for values in self.answers(path, rows).values()))
                self.assertIn("WrongField", self.answers(path, rows))

    def test_missing_duplicate_and_foreign_inventory(self):
        path, rows = self.declared("schedule")
        self.assertEqual(len(self.answers(path, rows[:-1])["MissingCase"]), 1)
        self.assertEqual(len(self.answers(path, rows + [rows[0]])["DuplicateCase"]), 1)
        changed = copy.deepcopy(rows)
        changed[0]["id"] = "foreign-control"
        answers = self.answers(path, changed)
        self.assertEqual(len(answers["UnknownCase"]), 1)
        self.assertEqual(len(answers["MissingCase"]), 1)

    def test_exit_timeout_and_full_stdout_identity_are_not_waived(self):
        path, rows = self.declared("vm-log")
        for field, value in (("exit", -9), ("timeout", True), ("stdoutSha256", "0" * 64)):
            changed = copy.deepcopy(rows)
            changed[0][field] = value
            self.assertEqual(self.answers(path, changed)["WrongField"], [(encoded([rows[0]["id"]]), 0, field)])

    def test_source_withdrawal_and_restore_reuse_owner(self):
        path, rows = self.declared("vm-log")
        before, _, first = evaluate(ROOT, path, rows, engine=self.engine)
        removed, _, middle = evaluate(ROOT, path, rows[1:], engine=self.engine)
        after, _, last = evaluate(ROOT, path, rows, engine=self.engine)
        self.assertEqual(before, after)
        self.assertTrue(removed["MissingCase"])
        self.assertEqual(first["sessionOwner"], last["sessionOwner"])
        self.assertGreater(last["sourceGeneration"], middle["sourceGeneration"])

    def test_receipt_binding_does_not_accept_absent_or_terminal_step(self):
        name = "evidence/research/observation-contract/vm-log.binding.json"
        with self.assertRaisesRegex(ValueError, "prior-step"):
            bind_execution(ROOT, name, [])
        with self.assertRaisesRegex(ValueError, "prior-step"):
            bind_execution(ROOT, name, [{"id": "test-posix", "capability": "evidence.evaluate"}])

    def test_missing_field_and_nonfinite_data_rejected(self):
        path, rows = self.declared("vm-log")
        changed = copy.deepcopy(rows)
        del changed[0]["stdoutSha256"]
        self.assertTrue(self.answers(path, changed)["MissingField"])
        changed[0]["exit"] = float("nan")
        with self.assertRaises(ValueError):
            project(ROOT, path, changed)


if __name__ == "__main__":
    unittest.main()
