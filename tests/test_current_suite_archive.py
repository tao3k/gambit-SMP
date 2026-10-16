"""Failed current campaigns retain real child results, never invented parents."""
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import digest
from gambit_smp.native_archive import archive_current_suite, archive_interrupted_suite


class CurrentSuiteArchiveTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.source = self.root / "source"
        self.source.mkdir()
        self.identity = self.root / "identity.json"
        self.identity.write_text('{"sourceFiles":{}}')
        self.row = {"batch": 0, "shard": 0, "files": ["control.scm"], "accepted": False,
                    "exit": 1, "timeout": False, "seconds": .1}
        self.process = {"exit": 1, "timeout": False, "seconds": .1,
                        "parentReaped": True, "processGroupQuiescent": True}
        self.save("retry-preflight.json", {"schema": "typed-suite-retry-review.v2", "decision": "RETRY_ELIGIBLE",
            "campaign": {"candidateReceiptSha256": digest(self.identity), "mode": "gsi",
                         "regime": "whole-parallel", "selectedFiles": {"control.scm": "a" * 64},
                         "suiteBudgetSeconds": 20}})
        (self.source / "suite-0-0.log").write_text("actual failed fixture log\n")

    def save(self, name, data):
        (self.source / name).write_text(json.dumps(data))

    def run_archive(self):
        self.save("suite-progress.json", [self.row])
        self.save("suite-0-0.process.json", self.process)
        return archive_current_suite(self.source, self.root / "archive", self.identity)

    def test_actual_denial_and_complete_selection_are_retained(self):
        record = self.run_archive()
        self.assertEqual("DENY", record["status"])
        self.assertFalse(record["results"][0]["accepted"])
        self.assertEqual(["control.scm"], record["selectedFiles"])
        self.assertNotIn("exit", record["results"][0])
        self.assertFalse(record["runtimeAdmitted"])

    def test_result_mismatch_unfinished_teardown_and_partial_inventory_are_rejected(self):
        original_row, original_process = dict(self.row), dict(self.process)
        for change in ("exit", "teardown", "inventory", "pass"):
            self.row, self.process = dict(original_row), dict(original_process)
            if change == "exit":
                self.process["exit"] = 0
            elif change == "teardown":
                self.process["processGroupQuiescent"] = False
            elif change == "inventory":
                self.row["files"] = []
            else:
                self.row["accepted"] = True
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.run_archive()


class InterruptedSuiteArchiveTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.source = self.root / "run/native-gsc"
        self.source.mkdir(parents=True)
        self.identity = self.root / "identity.json"
        self.identity.write_text('{}')
        self.parent = self.root / "receipt.json"
        self.parent_data = dict(schema="sealed-research-run.v1", outcome="DENY", executionLaunched=True,
            timeout=True, exit=-9, parentReaped=True, processGroupQuiescent=True,
            childReceiptSha256=None, runtimeAdmitted=False, budgetSeconds=300, wholeSeconds=300.1,
            engineId="a" * 64, recipe="complete-grid")
        self.parent.write_text(json.dumps(self.parent_data))
        (self.source / "retry-preflight.json").write_text(json.dumps({
            "schema": "typed-suite-retry-review.v2", "decision": "RETRY_ELIGIBLE",
            "campaign": {"candidateReceiptSha256": digest(self.identity), "mode": "gsc",
                         "suiteBudgetSeconds": 300, "selectedFiles": {"control.scm": "b" * 64}}}))
        self.started = {"state": "STARTED", "completionObserved": False,
                        "argv": ["/Users/private/.data/compiler"]}
        (self.source / "suite-0-1.process.json").write_text(json.dumps(self.started))
        (self.source / "suite-0-0.process.json").write_text(json.dumps({
            "state": "OBSERVED", "completionObserved": True, "exit": 0, "timeout": False,
            "seconds": 1, "parentReaped": True, "processGroupQuiescent": True}))

    def archive(self):
        return archive_interrupted_suite(self.source, self.root / "archive", self.identity, self.parent)

    def test_partial_process_success_never_becomes_suite_acceptance(self):
        record = self.archive()
        self.assertEqual("DENY", record["status"])
        self.assertFalse(record["suiteCompletionObserved"])
        self.assertFalse(record["runtimeAdmitted"])
        self.assertEqual([True, False], [row["completionObserved"] for row in record["processObservations"]])
        self.assertTrue(all(row["suiteAccepted"] is None for row in record["processObservations"]))
        text = (self.root / "archive/receipt.json").read_text()
        self.assertNotIn("/Users/", text)
        self.assertNotIn(".data/", text)
        with self.assertRaises(FileExistsError):
            self.archive()

    def test_parent_teardown_identity_and_invented_child_outcomes_are_rejected(self):
        for key, value in (("timeout", False), ("outcome", "PASS"), ("processGroupQuiescent", False),
                           ("budgetSeconds", 301), ("childReceiptSha256", "c" * 64)):
            with self.subTest(key=key):
                self.parent.write_text(json.dumps(dict(self.parent_data, **{key: value})))
                with self.assertRaises(ValueError):
                    self.archive()
        self.parent.write_text(json.dumps(self.parent_data))
        self.started["exit"] = 0
        (self.source / "suite-0-1.process.json").write_text(json.dumps(self.started))
        with self.assertRaises(ValueError):
            self.archive()
