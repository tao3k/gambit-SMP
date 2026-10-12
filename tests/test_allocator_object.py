from pathlib import Path
import unittest
from unittest.mock import patch

from gambit_smp.allocator_object import command


class AllocatorObjectTests(unittest.TestCase):
    def setUp(self):
        self.compiler = Path("/compiler")
        self.source = Path("/isolated/mem.c")
        self.output = Path("/isolated/mem.o")
        self.plan = "/compiler -O3 -c -o /isolated/mem.o -D___PRIMAL /isolated/mem.c -D___LIBRARY\n"

    def check(self, plan):
        with patch.object(Path, "resolve", return_value=self.compiler):
            return command(plan, str(self.compiler), self.source, self.output)

    def test_actual_rule_keeps_production_flags_and_explicit_output(self):
        args = self.check(self.plan)
        self.assertIn("-O3", args)
        self.assertEqual(str(self.output), args[args.index("-o") + 1])
        self.assertEqual(str(self.source), args[-2])

    def test_setup_or_multiple_recipes_are_denied(self):
        for plan in ("", self.plan + "./config.status\n", "./config.status\n" + self.plan):
            with self.assertRaisesRegex(ValueError, "single compilation recipe"):
                self.check(plan)

    def test_wrong_outputs_duplicate_inputs_missing_definitions_are_denied(self):
        for plan in (self.plan.replace("/isolated/mem.o", "/original/mem.o"),
                     self.plan + " /isolated/mem.c",
                     self.plan.replace("-D___PRIMAL", ""),
                     self.plan.replace("-D___LIBRARY", ""),
                     self.plan.replace("-c", ""), self.plan + " ; echo unsafe"):
            with self.subTest(plan=plan), self.assertRaises(ValueError):
                self.check(plan)


if __name__ == "__main__":
    unittest.main()
