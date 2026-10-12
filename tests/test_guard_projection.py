import copy
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.generator_contract import app, name
from gambit_smp.guard_projection import free_names, project, projections, verify_generated


def choice(identifier, domain, body):
    return {"kind": "let", "opdef": {"kind": "def", "qualifier": "nondet",
        "name": identifier, "expr": app("oneOf", domain)}, "expr": body}


class GuardProjectionTests(unittest.TestCase):
    def test_independent_choices_remain_existential_and_empty_domain_remains(self):
        body = app("actionAll", app("eq", name("w"), name("o")), app("assign", name("s"), name("s")))
        expression = choice("w", name("workers"), choice("o", app("Set"), body))
        result = project(expression)
        self.assertEqual("exists", result["opcode"])
        inner = result["args"][1]["expr"]
        self.assertEqual(app("Set"), inner["args"][0])
        self.assertEqual(app("eq", name("w"), name("o")), inner["args"][1]["expr"])

    def test_unused_rhs_only_values_are_removed_not_evaluated(self):
        expression = {"kind": "let", "opdef": {"kind": "def", "qualifier": "val",
            "name": "partial", "expr": app("get", name("edge"), name("missing"))},
            "expr": app("actionAll", name("ready"), app("assign", name("s"), name("partial")))}
        self.assertEqual(name("ready"), project(expression))
        self.assertNotIn("missing", free_names(project(expression)))
        expression["expr"]["args"][0] = app("eq", name("partial"), name("s"))
        self.assertEqual("let", project(expression)["kind"])

    def test_missing_multiple_and_wrong_state_assignments_are_rejected(self):
        for body in (name("ready"), app("assign", name("other"), name("s")),
                     app("actionAll", app("assign", name("s"), name("s")),
                         app("assign", name("s"), name("s")))):
            with self.assertRaisesRegex(ValueError, "assignment"):
                project(body)

    def test_impure_guard_and_non_choice_nondeterminism_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "state predicate"):
            project(app("actionAll", app("enabled", name("step")), app("assign", name("s"), name("s"))))
        expression = choice("o", name("objects"), app("assign", name("s"), name("s")))
        expression["opdef"]["expr"] = name("objects")
        with self.assertRaisesRegex(ValueError, "oneOf"):
            project(expression)

    def test_real_original_ir_projects_all_22_branches(self):
        path = ROOT / "evidence/model-results/gc-ranking-all-components/protocol-ir.json"
        ir = json.loads(path.read_text())
        result = projections(ir)
        self.assertEqual(22, len(result))
        self.assertEqual(name("terminal"), result["finished"])
        self.assertNotIn("child", free_names(result["markTail"]))
        self.assertNotIn("fresh", free_names(result["markTail"]))
        changed = copy.deepcopy(ir)
        module = next(item for item in changed["modules"] if item["name"] == "gc_recursive_queue_wait")
        ready = next(item for item in module["declarations"] if item.get("name") == "ready")
        ready["expr"] = name("finished")
        with self.assertRaisesRegex(ValueError, "action or recursive"):
            projections(changed)

    def test_generated_projection_cannot_weaken_or_omit_original_guards(self):
        guards = {"original": name("ready")}
        ir = {"stage": "parsing", "modules": [{"name": "gc_recursive_queue_guards", "declarations": [
            {"name": "guard_original", "qualifier": "val", "expr": name("ready")},
            {"name": "guardCoverage", "expr": app("or", name("terminal"), name("guard_original"))},
            {"name": "rejectsTerminalOnly", "expr": name("terminal")}]}]}
        verify_generated(ir, guards)
        ir["modules"][0]["declarations"][0]["expr"] = {"kind": "bool", "value": True}
        with self.assertRaisesRegex(ValueError, "differs"):
            verify_generated(ir, guards)

    def test_extra_original_state_variable_is_not_silently_unassigned(self):
        path = ROOT / "evidence/model-results/gc-ranking-all-components/protocol-ir.json"
        ir = json.loads(path.read_text())
        module = next(item for item in ir["modules"] if item["name"] == "gc_recursive_queue_wait")
        module["declarations"].append({"kind": "var", "name": "unassigned"})
        with self.assertRaisesRegex(ValueError, "exactly one original state"):
            projections(ir)


if __name__ == "__main__":
    unittest.main()
