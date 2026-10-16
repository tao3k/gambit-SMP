"""Synthetic transport controls; passing these is not native SMP evidence."""
import copy
import json
import unittest

from gambit_smp.ascent_program import load_catalog, query
from gambit_smp.framework import ROOT
from gambit_smp.suite_coverage import project_suite_files


class SuiteCoverageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        recipe = json.loads((ROOT/"evidence/research/current-source-full-bootstrap/dynamic-modulo-interpreted.recipe.json").read_text())
        cls.fixtures = next(row for row in recipe["steps"] if row["capability"]=="gambit.suite")["arguments"]["additionalFixtures"]
        cls.catalog = load_catalog(
            ROOT/"evidence/research/smp-threaded-vm-native-grid/compiled-coverage-rules.ss",
            ROOT/"evidence/research/smp-threaded-vm-native-grid/pr-regression-requirements.ss")

    def receipt(self):
        files = sorted(self.fixtures)
        step = {"id":"native-gsc","capability":"gambit.suite","outcome":"PASS","mode":"gsc",
                "arguments":{"mode":"gsc","inventory":"unit","selection":["."],
                             "regime":"whole-parallel","expectedFiles":files,
                             "additionalFixtures":self.fixtures},
                "passedFiles":files,"suiteGroups":[{"files":files,"accepted":True,"exit":0,"timeout":False}],
                "artifacts":{"native-gsc/runtime/tests/unit-tests/"+file:row["sha256"]
                             for file,row in self.fixtures.items()}}
        return {"steps":[step]}

    def evaluate(self, receipt):
        return query(project_suite_files(receipt),self.catalog,
                     {"qualified":"qualified_suite_gate","missing":"pr_missing_file"})

    def test_checked_files_derive_scope_without_fabricating_observed_steps(self):
        facts = project_suite_files(self.receipt())
        self.assertNotIn("observed_step",facts)
        self.assertEqual(len(self.fixtures),len(facts["observed_suite_file"]))
        answer = self.evaluate(self.receipt())
        self.assertEqual([],answer["missing"])
        self.assertEqual({("complete-gsc","native-gsc"),("pr-regressions-gsc","native-gsc")},
                         set(answer["qualified"]))

    def test_pass_name_model_pass_and_denied_execution_do_not_qualify(self):
        for change in ({"passedFiles":None},{"capability":"quint.verify"},{"outcome":"DENY"}):
            receipt = self.receipt()
            if change=={"passedFiles":None}:
                del receipt["steps"][0]["passedFiles"]
            else:
                receipt["steps"][0].update(change)
            self.assertEqual([],self.evaluate(receipt)["qualified"])

    def test_suite_identifier_is_opaque_not_a_qualification_selector(self):
        for name in ("source-032", "source-999", "semantic-candidate"):
            receipt = self.receipt()
            step = receipt["steps"][0]
            step["id"] = name
            step["artifacts"] = {key.replace("native-gsc/", name+"/", 1): value
                                 for key, value in step["artifacts"].items()}
            self.assertEqual({("complete-gsc",name),("pr-regressions-gsc",name)},
                             set(self.evaluate(receipt)["qualified"]))

    def test_missing_pr_fixture_leaves_pr_gate_open(self):
        receipt = self.receipt()
        step = receipt["steps"][0]
        removed = step["passedFiles"][0]
        remaining = [file for file in step["passedFiles"] if file!=removed]
        step["passedFiles"] = step["arguments"]["expectedFiles"] = remaining
        step["suiteGroups"][0]["files"] = remaining
        answer = self.evaluate(receipt)
        self.assertEqual([("native-gsc",removed)],answer["missing"])
        self.assertEqual([("complete-gsc","native-gsc")],answer["qualified"])

    def test_changed_fixture_or_failed_group_rejects_projection(self):
        for fault in ("fixture","group","inventory"):
            receipt = self.receipt()
            step = receipt["steps"][0]
            if fault=="fixture":
                step["artifacts"][next(iter(step["artifacts"]))]="0"*64
            elif fault=="group":
                step["suiteGroups"][0]["timeout"]=True
            else:
                step["suiteGroups"][0]["files"] = step["passedFiles"][:-1]
            with self.subTest(fault=fault),self.assertRaises(ValueError):
                project_suite_files(receipt)

    def test_phased_case_requires_all_artifacts_original_loader_and_window(self):
        receipt = self.receipt()
        step = receipt["steps"][0]
        files = step["passedFiles"]
        step["arguments"].update(compilerPhaseFiles=[files[0]],fileBudgetSeconds={files[0]:90})
        phase_group = {"files":[files[0]],"accepted":True,"exit":0,"timeout":False,
                       "phaseInactivitySeconds":90,"assertionProtocol":"original-gsi-loader-and-unit-test-exit",
                       "compilerPhases":[{"phase":name,"accepted":True,"exit":0,"timeout":False,
                                          "artifactSha256":"a"*64 if index<2 else None}
                                         for index,name in enumerate(("scheme-to-c","c-to-dynamic-module","compiled-execution"))]}
        step["suiteGroups"] = [phase_group,{"files":files[1:],"accepted":True,"exit":0,"timeout":False}]
        self.assertTrue(project_suite_files(receipt)["observed_suite_file"])
        for fault in ("window","loader","missing","assertions"):
            mutated = copy.deepcopy(receipt)
            group = mutated["steps"][0]["suiteGroups"][0]
            if fault=="window": group["phaseInactivitySeconds"]=180
            elif fault=="loader": group["assertionProtocol"]="diagnostic-entry"
            elif fault=="missing": group["compilerPhases"][0]["artifactSha256"]=None
            else: group["compilerPhases"][2]["exit"]=1
            with self.subTest(fault=fault),self.assertRaises(ValueError):
                project_suite_files(mutated)
