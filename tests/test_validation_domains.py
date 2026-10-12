import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.validation_domains import check_domain, partition


class ValidationDomainTests(unittest.TestCase):
    def fixture(self, domain=None):
        class Fixture(unittest.TestCase):
            def runTest(self):
                pass
        test = Fixture()
        if domain is not None:
            test.validation_domain = domain
        return test

    def test_partition_preserves_all_original_instances(self):
        local = self.fixture()
        selected = self.fixture({"kind": "sealed-research", "budgetSeconds": 60, "workers": 3})
        ordinary, domains = partition(unittest.TestSuite([unittest.TestSuite([local, selected])]))
        self.assertEqual([local], list(ordinary))
        self.assertEqual([selected], domains[0][1])
        self.assertEqual(60, domains[0][0]["budgetSeconds"])

    def test_invalid_execution_domains_are_not_silently_local(self):
        for policy in ({}, {"kind": "editable", "budgetSeconds": 60, "workers": 3},
                       {"kind": "sealed-research", "budgetSeconds": True, "workers": 3},
                       {"kind": "sealed-research", "budgetSeconds": 60, "workers": 0}):
            with self.subTest(policy=policy), self.assertRaises(ValueError):
                partition(unittest.TestSuite([self.fixture(policy)]))

    def test_receipt_recheck_requires_complete_inventory_deadline_and_teardown(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "fixture.py"
            source.write_text("fixture\n")
            log = root / "process.log"
            log.write_text("complete raw process log\n")
            lane = root / "0"
            lane.mkdir()
            request = {"engineId": "fixture-engine", "inputs": {"fixture.py": digest(source)},
                       "testIds": ["a", "b"]}
            (lane / "request.json").write_text(json.dumps(request))
            result = {"engineId": "fixture-engine", "requestSHA": digest(lane / "request.json"),
                      "expectedTestIds": ["a", "b"]}
            (lane / "result.json").write_text(json.dumps(result))
            saved = {"schema": "sealed-validation-domain.v1", "engine": str(root / "engine"),
                     "engineId": "fixture-engine", "policy": {"budgetSeconds": 60}, "seconds": 59,
                     "inputs": {"fixture.py": digest(source)}, "expectedTestIds": ["a", "b"],
                     "outcomes": {"a": "pass", "b": "pass"}, "passed": True,
                     "lanes": [{"expectedTestIds": ["a", "b"], "exit": 0, "timeout": False,
                                "passed": True, "parentReaped": True, "processGroupQuiescent": True,
                                "result": result}],
                     "artifacts": {"process.log": digest(log)}}
            with patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "fixture-engine"}):
                self.assertTrue(check_domain(root, root, saved))
                for update in ({"seconds": 61}, {"expectedTestIds": ["a"]},
                               {"outcomes": {"a": "pass", "b": "skip"}}):
                    self.assertFalse(check_domain(root, root, {**saved, **update}))
                changed = json.loads(json.dumps(saved))
                changed["lanes"][0]["processGroupQuiescent"] = False
                self.assertFalse(check_domain(root, root, changed))
                source.write_text("different fixture\n")
                self.assertFalse(check_domain(root, root, saved))
                log.write_text("tampered\n")
                with self.assertRaisesRegex(ValueError, "artifact identity mismatch"):
                    check_domain(root, root, saved)


if __name__ == "__main__":
    unittest.main()
