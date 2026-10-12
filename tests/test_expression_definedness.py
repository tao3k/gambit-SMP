import json
import unittest

from gambit_smp.expression_definedness import Definedness, TRUE, sufficient_projections
from gambit_smp.framework import ROOT
from gambit_smp.generator_contract import app, name
from gambit_smp.guard_projection import free_names, projections, verify_generated


class ExpressionDefinednessTests(unittest.TestCase):
    def test_missing_map_keys_and_list_bounds_cannot_be_erased(self):
        checker = Definedness({})
        bound = frozenset(("values", "index"))
        expected = app("contains", app("keys", name("values")), name("index"))
        self.assertEqual(expected, checker.defined(app("get", name("values"), name("index")), bound))
        self.assertEqual(expected, checker.defined(app("set", name("values"), name("index"), TRUE), bound))
        result = checker.defined(app("nth", name("values"), name("index")), bound)
        self.assertEqual("ite", result["opcode"])
        self.assertEqual({"get", "set", "nth"}, checker.partial_operations)

    def test_helper_substitution_does_not_capture_outer_arguments(self):
        checker = Definedness({})
        function = {"kind": "lambda", "qualifier": "def", "params": [{"name": "o"}],
                    "expr": app("eq", name("o"), name("w"))}
        result = checker.substitute(function, {"w": name("o")})
        self.assertEqual({"o"}, free_names(result))
        self.assertNotEqual("o", result["params"][0]["name"])
        self.assertEqual(name("o"), result["expr"]["args"][1])

    def test_unused_partial_value_is_still_required_by_conservative_rule(self):
        checker = Definedness({"s": {"kind": "var"}, "values": {"kind": "var"}})
        expression = {"kind": "let", "opdef": {"kind": "def", "qualifier": "val",
            "name": "unused", "expr": app("get", name("values"), {"kind": "int", "value": 9})},
            "expr": app("assign", name("s"), name("s"))}
        result = checker.action(expression)
        self.assertEqual("ite", result["opcode"])
        self.assertEqual("contains", result["args"][0]["opcode"])

    def test_unknown_operations_recursion_and_dynamic_map_keys_fail_closed(self):
        checker = Definedness({})
        for expression in (app("mystery"), app("idiv", {"kind": "int", "value": 1}, {"kind": "int", "value": 0}),
                           app("Map", app("Tup", name("key"), TRUE))):
            with self.assertRaises(ValueError):
                checker.defined(expression, frozenset(("key",)))
        checker.declarations["cycle"] = {"qualifier": "val", "expr": name("cycle")}
        with self.assertRaisesRegex(ValueError, "unsupported definedness value"):
            checker.defined(name("cycle"))

    def test_real_original_actions_include_update_definedness(self):
        path = ROOT / "evidence/model-results/gc-ranking-all-components/protocol-ir.json"
        ir = json.loads(path.read_text())
        necessary = projections(ir)
        sufficient, partial = sufficient_projections(ir, necessary)
        self.assertEqual(list(necessary), list(sufficient))
        self.assertEqual(["get", "nth", "set"], partial)
        self.assertNotEqual(necessary["markTail"], sufficient["markTail"])
        self.assertNotEqual(necessary["probeEmptyQueue"], sufficient["probeEmptyQueue"])

    def test_current_kernel_reproduces_archived_sufficient_expressions(self):
        archive = ROOT / "evidence/model-results/gc-defined-transition-coverage"
        ir = json.loads((archive / "protocol-ir.json").read_text())
        sufficient, _ = sufficient_projections(ir, projections(ir))
        verify_generated(json.loads((archive / "proof-ir.json").read_text()), sufficient)


if __name__ == "__main__":
    unittest.main()
