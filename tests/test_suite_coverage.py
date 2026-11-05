"""Synthetic transport controls; passing these is not native SMP evidence."""
import copy
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.ascent_program import load_catalog, query
from gambit_smp.framework import ROOT
from gambit_smp.suite_coverage import project_suite_files


class AcceptedSmpProgressTests(unittest.TestCase):
    def test_smp_status_uses_accepted_history_and_rejects_drift(self):
        from gambit_smp.suite_coverage import SMP_LEDGER_FOLDER, accepted_smp_status

        path = SMP_LEDGER_FOLDER / "accepted-smp-progress.json"
        recorded = accepted_smp_status(ROOT)
        self.assertEqual((recorded["originPassed"], recorded["passed"], recorded["remaining"]),
                         (1, 3, 9))
        self.assertTrue(recorded["sourceTree"].startswith("65a4a2e2"))
        self.assertEqual(recorded["closed"], ["bootstrap", "gsi", "gsc"])
        with TemporaryDirectory() as directory:
            root = Path(directory)
            refs = [recorded[key]["path"] for key in ("origin", "accepted", "originalInventory")]
            refs.extend(ref["path"] for ref in recorded["receipts"].values())
            for name in [path, *refs]:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes((ROOT / name).read_bytes())
            self.assertEqual(accepted_smp_status(root), recorded)
            (root / path).write_text(json.dumps(dict(recorded, passed=0, closed=[], remaining=12)))
            with self.assertRaisesRegex(ValueError, "disagrees"):
                accepted_smp_status(root)
            (root / path).write_text(json.dumps(recorded))
            (root / recorded["receipts"]["gsi"]["path"]).write_text("{}")
            with self.assertRaisesRegex(ValueError, "identity changed"):
                accepted_smp_status(root)

    def test_numeric_window_requires_three_real_phases_and_original_assertions(self):
        from gambit_smp.suite_coverage import require_numeric_smp_evidence

        names = ("scheme-to-c", "c-to-dynamic-module", "compiled-execution")
        phases = [dict(phase=name, accepted=True, exit=0, timeout=False,
                       artifactSha256="a" * 64) for name in names]
        phases[-1]["originalAssertionsWitness"] = True
        group = dict(files=["03-number/_num.scm"], batch=0, shard=1,
                     sharedPhaseBudgetSeconds=90, compilerPhases=phases,
                     assertionProtocol="original-gsi-loader-and-assertion-witness")
        processes = [dict(stage="suite-0-1-" + name, effectiveBudgetSeconds=cap, seconds=seconds)
                     for name, cap, seconds in zip(names, (90, 70, 30), (20, 40, 1))]
        require_numeric_smp_evidence([group], processes)
        with self.assertRaisesRegex(ValueError, "budget"):
            require_numeric_smp_evidence([group], [dict(row, effectiveBudgetSeconds=90) for row in processes])
        with self.assertRaisesRegex(ValueError, "budget"):
            require_numeric_smp_evidence([group], [*processes[:2], dict(processes[2], seconds=31)])
        with self.assertRaisesRegex(ValueError, "process records"):
            require_numeric_smp_evidence([group], processes[:-1])
        phases[-1]["originalAssertionsWitness"] = False
        with self.assertRaisesRegex(ValueError, "assertion witness"):
            require_numeric_smp_evidence([group], processes)

    def test_current_projection_keeps_origin_and_refuses_regression(self):
        from gambit_smp.framework import digest
        from gambit_smp.suite_coverage import accepted_smp_progress, accepted_smp_status

        origin = "evidence/research/retained/modern-c/delivery-plan/current/smp-acceptance.json"
        historical = "evidence/research/retained/modern-c/frozen-568e0276-smp/indexed-acceptance.json"
        diagnostic = "evidence/research/retained/modern-c/frozen-568e0276-smp/env-index-acceptance.json"
        result = accepted_smp_status(ROOT)
        self.assertEqual((result["originPassed"], result["passed"], result["remaining"]), (1, 3, 9))
        self.assertEqual(result["closed"], ["bootstrap", "gsi", "gsc"])
        accepted = result["accepted"]["path"]
        self.assertFalse(result["wholeSmpAdmitted"])
        with self.assertRaisesRegex(ValueError, "cannot replace the accepted prefix"):
            accepted_smp_progress(ROOT, origin, diagnostic, result)
        with self.assertRaisesRegex(ValueError, "cannot regress"):
            accepted_smp_progress(ROOT, origin, historical, result)
        with self.assertRaisesRegex(ValueError, "cannot regress"):
            accepted_smp_progress(ROOT, origin, accepted, dict(result, passed=4))
        packet = json.loads((ROOT / accepted).read_text())
        if all(digest(ROOT / name) == expected for name, expected in packet["modelInputs"].items()):
            self.assertEqual(accepted_smp_progress(ROOT, origin, accepted, result), result)
        else:
            with self.assertRaisesRegex(ValueError, "SMP model input changed"):
                accepted_smp_progress(ROOT, origin, accepted, result)


class SuiteCoverageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        recipe = json.loads((ROOT/".cache/research/legacy-evidence/evidence/research/current-source-full-bootstrap/dynamic-modulo-interpreted.recipe.json").read_text())
        cls.fixtures = next(row for row in recipe["steps"] if row["capability"]=="gambit.suite")["arguments"]["additionalFixtures"]
        cls.catalog = load_catalog(
            ROOT/".cache/research/legacy-evidence/evidence/research/smp-threaded-vm-native-grid/compiled-coverage-rules.ss",
            ROOT/".cache/research/legacy-evidence/evidence/research/smp-threaded-vm-native-grid/pr-regression-requirements.ss")

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
