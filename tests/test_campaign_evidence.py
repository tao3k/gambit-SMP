import copy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.ascent_program import engine_api
from gambit_smp.campaign_evidence import collect, validate
from gambit_smp.framework import ROOT, digest


class CampaignEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "evidence").mkdir()
        shutil.copyfile(ROOT / "evidence/campaign-rules.ss", self.root / "evidence/campaign-rules.ss")
        self.run = self.root / "runs/one"
        self.step = self.run / "suite"
        self.step.mkdir(parents=True)
        self.input = self.root / "input.txt"
        self.input.write_text("recorded source identity\n")
        self.tools = self.run / "tools.json"
        self.tools.write_text("{}\n")
        self.retry = {"schema": "typed-suite-retry-review.v2", "decision": "RETRY_ELIGIBLE",
            "campaign": {"mode": "gsi", "regime": "whole-sequential", "suiteBudgetSeconds": 8,
                         "recipeBudgetSeconds": 12, "candidateReceiptSha256": "a" * 64},
            "answers": {"selected": [["known", "gsi"]], "eligible": [["known", "gsi"]],
                        "denied": [], "missing": [], "decision": [["RETRY_ELIGIBLE"]]},
            "inputs": {"input.txt": digest(self.input)}, "facts": {}, "knownSelectedFailures": ["known"],
            "executionAuthorized": False, "runtimeAdmitted": False, "policyProgram": "research-suite-review.v1"}
        self.command = {"stage": "suite-gsi", "exit": 0, "timeout": False, "log": "run.log",
            "parentReaped": True, "processGroupQuiescent": True,
            "stdoutPath": "run.stdout", "stderrPath": "run.stderr"}
        for name in ("run.log", "run.stdout", "run.stderr"):
            (self.step / name).write_text("observed fixture output\n" if name != "run.stderr" else "")
        for stream in ("stdout", "stderr"):
            self.command[stream + "Sha256"] = digest(self.step / self.command[stream + "Path"])

    def save(self, outcome="PASS"):
        (self.step / "retry-preflight.json").write_text(json.dumps(self.retry))
        artifacts = {str(path.relative_to(self.run)): digest(path) for path in self.step.iterdir() if path.is_file()}
        self.receipt = {"schema": "evidence-recipe-run.v1", "recipe": "controlled-campaign-fixture",
            "budgetSeconds": 12, "outcome": outcome, "inputs": {str(self.input): digest(self.input)},
            "toolInputs": {"path": "tools.json", "sha256": digest(self.tools)},
            "engine": {"path": "fixture-engine", "engineId": "b" * 64},
            "steps": [{"id": "suite", "capability": "gambit.suite", "budgetSeconds": 8,
                "arguments": {"mode": "gsi", "regime": "whole-sequential"}, "outcome": outcome,
                "commands": [self.command], "artifacts": artifacts}]}
        (self.run / "receipt.json").write_text(json.dumps(self.receipt))

    def test_native_policy_keeps_retry_eligibility_distinct_from_actual_failure(self):
        self.command.update(exit=-9, timeout=True)
        self.save("TIMEOUT")
        packets, inputs = collect(self.root, [self.run], self.engine)
        packet = packets[0]
        validate(packet)
        self.assertEqual("TIMEOUT", packet["nativeOutcome"])
        dispositions = {row[1] for row in packet["nativeAnswers"]["CampaignDisposition"]}
        self.assertIn("DENY", dispositions)
        self.assertIn("CONDITIONAL_RETRY", dispositions)
        self.assertNotIn("NATIVE_OBSERVED", dispositions)
        self.assertEqual([[packet["id"], "known"]], packet["nativeAnswers"]["CampaignKnownFailure"])
        self.assertIn("runs/one/suite/retry-preflight.json", inputs)
        self.assertFalse(packet["executionAuthorized"])

    def test_legacy_missing_teardown_metadata_stays_an_observation_gap(self):
        self.command.pop("parentReaped")
        self.command.pop("processGroupQuiescent")
        self.save()
        packet = collect(self.root, [self.run], self.engine)[0][0]
        dispositions = {row[1] for row in packet["nativeAnswers"]["CampaignDisposition"]}
        self.assertIn("OBSERVATION_REQUIRED", dispositions)
        self.assertNotIn("NATIVE_OBSERVED", dispositions)
        self.assertEqual("CURRENT", packet["identityStatus"])

    def test_retired_inputs_are_stale_and_archive_mutations_are_rejected(self):
        self.save()
        self.input.write_text("retired source generation\n")
        packet = collect(self.root, [self.run], self.engine)[0][0]
        self.assertEqual("STALE", packet["identityStatus"])
        self.assertIn([packet["id"], "STALE"], packet["nativeAnswers"]["CampaignDisposition"])
        (self.step / "run.log").write_text("changed archive\n")
        with self.assertRaisesRegex(ValueError, "archive identity drift"):
            collect(self.root, [self.run], self.engine)

    def test_topology_and_native_answer_mismatch_fail_before_inference(self):
        self.retry["campaign"]["suiteBudgetSeconds"] = 9
        self.save()
        with self.assertRaisesRegex(ValueError, "topology or budget"):
            collect(self.root, [self.run], self.engine)
        self.retry["campaign"]["suiteBudgetSeconds"] = 8
        self.retry["answers"]["decision"] = [["DENY"]]
        self.save()
        with self.assertRaisesRegex(ValueError, "disagrees with native answer"):
            collect(self.root, [self.run], self.engine)


if __name__ == "__main__":
    unittest.main()
