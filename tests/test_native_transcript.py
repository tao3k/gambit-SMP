import json
import unittest

from gambit_smp.ascent_program import load_catalog, query
from gambit_smp.framework import ROOT
from gambit_smp.native_transcript import project


class TranscriptTests(unittest.TestCase):
    def setUp(self):
        folder = ROOT / "evidence/research/vm-kernel-entry-lifecycle"
        self.contract = json.loads((folder / "resize-transcript.contract.json").read_text())
        self.catalog = load_catalog(folder / "transcript-rules.ss")

    def output(self, population):
        rows = [f"(resize-enter {population} 1 caller 0)", "(resize-return 1)"]
        for i in range(population):
            rows += [f"(resize-enter 1 {population} caller 0)", f"(resize-return {population})",
                     f"(resize-enter {population} 1 caller {i})", "(resize-return 1)"]
        rows += [f"(resize-enter 1 {population} caller 0)", f"(resize-return {population})",
                 "NATIVE-OK:resize_gc_lifecycle"]
        return "\n".join(rows) + "\n"

    def evaluate(self, output, cpu=3):
        return query(project(self.contract, output, cpu), self.catalog,
                     {"bad": "unexpected_token", "missing": "missing_cell"})

    def test_complete_host_derived_sequences_and_all_legal_callers(self):
        for cpu in (2, 3, 11):
            with self.subTest(cpu=cpu):
                self.assertEqual({"bad": [], "missing": []}, self.evaluate(self.output(cpu), cpu))

    def test_missing_extra_wrong_order_wrong_population_and_invalid_caller_fail(self):
        output = self.output(3)
        rows = output.splitlines()
        cases = ["\n".join(rows[1:]) + "\n", output + "warning\n",
                 "\n".join([rows[1], rows[0], *rows[2:]]) + "\n",
                 output.replace("resize-return 3", "resize-return 2", 1),
                 output.replace("caller 2", "caller 3", 1),
                 output + "NATIVE-OK:resize_gc_lifecycle\n"]
        for value in cases:
            with self.subTest(value=value):
                answer = self.evaluate(value)
                self.assertTrue(answer["bad"] or answer["missing"])

    def test_grammar_and_completion_are_not_scheme_evaluation(self):
        for value in ("", "((eval malicious))\n", "(resize-enter '3)\n",
                      "(resize-enter 3) trailing\n", self.output(3).rstrip("\n")):
            with self.subTest(value=value), self.assertRaises(ValueError):
                project(self.contract, value, 3)
