"""Native planning-policy controls; synthetic observations are not SMP passes."""
import copy
import json
import os
from pathlib import Path
import shutil
import unittest

from ascent import Engine
from gambit_smp.task_processes import run


ROOT = Path(__file__).resolve().parents[1]
MODELS = ["dev/modeling/models/sysml/commit-gates.sysml",
          "dev/refactoring/modern-c/models/sysml/revision-delivery.sysml",
          "dev/refactoring/modern-c/models/sysml/delivery-plan.sysml",
          "dev/refactoring/modern-c/models/sysml/pending-cuts.sysml",
          "dev/refactoring/modern-c/models/sysml/delivery-outcomes.sysml"]


class ModernCOutcomesTests(unittest.TestCase):
    def test_native_sysml_integration_and_review_units_are_distinct(self):
        argv = [shutil.which(os.environ.get("SYSML", "sysml")),
                "-strict", "-validate", "-json"]
        fields = ["roots.id", "collector.id", "lifetime.id", "execution.id",
                  "rootsNeed0.id", "route0.unit.id", "route0.target",
                  "route9.unit.id", "route9.target", "route9.disposition"]
        for field in fields:
            argv += ["-e", "GambitModernCOutcomes::" + field]
        result = run([*argv, *MODELS], cwd=ROOT, capture_output=True,
                     text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        values = [json.loads(line[4:]) for line in json.loads(result.stdout)["output"]
                  if line.startswith("  = ")]
        self.assertEqual(values[:4], ["frozen-roots", "independent-collector",
                                     "owned-lifetime", "request-product"])
        self.assertEqual(values[4:9], ["ROOT-SOURCE-UNION", "header-layout", "support",
                                      "entry-write-authority", "frozen-roots"])
        self.assertIn("result3", values[9])

    def test_leaf_results_families_and_dependencies_cannot_promote_each_other(self):
        results = ["roots", "collector", "lifetime", "execution"]
        needs = [[r, r + "-" + str(i)] for r in results for i in range(3)]
        facts = dict(source=[["tree", "profile"]], result=[[r] for r in results],
                     needs=needs, observed=[], dependency=[["roots", "collector"],
                     ["collector", "lifetime"], ["lifetime", "execution"]],
                     path=[["a.c"], ["b.c"]], unit=[["runtime"], ["headers"], ["generated"]],
                     owns=[["a.c", "runtime"], ["b.c", "headers"]],
                     route=[["runtime", "roots"], ["headers", "support"], ["generated", "support"]],
                     support=[["support"]], different=[[a, b] for a in
                     [*results, "support", "runtime", "headers", "generated"] for b in
                     [*results, "support", "runtime", "headers", "generated"] if a != b],
                     generated=[["generated"]], submitAlone=[], leafRevision=[],
                     family=[["bootstrap"], ["gsi"]],
                     familyObserved=[["bootstrap", "tree", "profile"], ["gsi", "tree", "profile"]],
                     familyFailure=[["gsi", "retained-failure"]], impact=[["roots", "gsi"]])
        engine = Engine()
        try:
            session = engine.open_sources(
                (ROOT / "dev/modeling/ascent/modern-c-outcomes.rules.scm").read_text())
            session.run(queries=["planGap", "resultClosed", "familyClosed"])

            def evaluate(data):
                session.replace(data)
                value = session.run(queries=["planGap", "resultClosed", "familyClosed"])
                self.assertTrue(value["complete"])
                return value["relations"]

            current = evaluate(facts)
            self.assertFalse(current["resultClosed"])
            self.assertEqual(current["familyClosed"], [["bootstrap", "tree", "profile"]])
            complete = copy.deepcopy(facts)
            complete["observed"] = [[n, "tree", "profile"] for _, n in needs]
            self.assertEqual(len(evaluate(complete)["resultClosed"]), 4)
            # Even all four integration controls do not manufacture a family pass.
            self.assertEqual(evaluate(complete)["familyClosed"], current["familyClosed"])
            leaves = copy.deepcopy(facts)
            leaves["leafRevision"] = [["rev" + str(i), "tree", "profile"] for i in range(100)]
            self.assertFalse(evaluate(leaves)["resultClosed"])
            partial = copy.deepcopy(complete)
            partial["observed"] = partial["observed"][1:]
            self.assertFalse(evaluate(partial)["resultClosed"])
            for field in ["tree", "profile"]:
                wrong = copy.deepcopy(complete)
                wrong["observed"] = [[n, "wrong" if field == "tree" else "tree",
                                      "wrong" if field == "profile" else "profile"] for _, n in needs]
                self.assertFalse(evaluate(wrong)["resultClosed"])
            for mutation in ["cycle", "unowned", "duplicate-owner", "unknown-unit",
                             "missing-route", "duplicate-route", "unknown-route", "generated-alone"]:
                bad = copy.deepcopy(complete)
                if mutation == "cycle": bad["dependency"].append(["execution", "roots"])
                elif mutation == "unowned": bad["owns"] = bad["owns"][1:]
                elif mutation == "duplicate-owner": bad["owns"].append(["a.c", "headers"])
                elif mutation == "unknown-unit": bad["owns"][0][1] = "unknown"
                elif mutation == "missing-route": bad["route"] = bad["route"][1:]
                elif mutation == "duplicate-route": bad["route"].append(["runtime", "support"])
                elif mutation == "unknown-route": bad["route"][0][1] = "unknown"
                else: bad["submitAlone"] = [["generated"]]
                with self.subTest(mutation=mutation):
                    answer = evaluate(bad)
                    self.assertTrue(answer["planGap"])
                    self.assertFalse(answer["resultClosed"])
        finally:
            engine.close()
