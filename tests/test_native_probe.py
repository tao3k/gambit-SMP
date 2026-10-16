"""Probe transport controls; mocks are not native execution evidence."""
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.native_capabilities import probe, validate_probe


class NativeProbeTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name).resolve()
        self.runtime = self.root / "runtime"
        self.runtime.mkdir()
        self.identity = self.root / "identity.json"
        self.identity.write_text("{}")
        (self.root / "probe.scm").write_text("(exit 0)\n")
        self.directory = self.root / "step"
        self.directory.mkdir()
        self.args = {"runtime": {"step": "producer", "output": "runtime"},
                     "identity": {"step": "producer", "output": "identity"},
                     "program": "probe.scm", "operations": ["udp-open", "process-pipe-sort"]}
        self.output = "ENVIRONMENT:udp-open:PASS\nENVIRONMENT:process-pipe-sort:PASS\nPROCESSORS:4\n"
        self.stderr = 0
        self.ctx = SimpleNamespace(root=self.root, directory=self.directory, env={}, commands=[],
            artifact=lambda ref, kind: self.runtime if ref["output"] == "runtime" else self.identity,
            bind=lambda paths: list(paths), remaining=lambda: 10,
            publish=lambda name, kind, path: {name: {"type": kind, "sha256": digest(path)}})

        def require(stage, argv, cwd, budget):
            self.ctx.commands.append({"stderrBytes": self.stderr})
            return self.output

        self.ctx.require = require

    def execute(self):
        with patch("gambit_smp.framework.available_processors", return_value=5), \
             patch("gambit_smp.suite_primitives.check_runtime"):
            return probe(self.args, self.ctx)

    def test_current_identity_and_host_capacity_are_observed_without_admission(self):
        validate_probe(self.args, ["probe.scm"])
        result = self.execute()
        observation = json.loads((self.directory / "observation.json").read_text())
        self.assertEqual(4, observation["processors"])
        self.assertEqual(digest(self.identity), observation["candidateReceiptSha256"])
        self.assertFalse(observation["runtimeAdmitted"])
        self.assertFalse(observation["nativeGcPassed"])
        self.assertEqual("current-producer-observation", result["outputs"]["observation"]["type"])

    def test_wrong_processor_or_missing_operation_is_rejected(self):
        self.output = "ENVIRONMENT:udp-open:PASS\nPROCESSORS:4\n"
        with self.assertRaises(ValueError):
            self.execute()
        self.output = "ENVIRONMENT:udp-open:PASS\nENVIRONMENT:process-pipe-sort:PASS\nPROCESSORS:5\n"
        with self.assertRaises(ValueError):
            self.execute()

    def test_stderr_is_not_a_success(self):
        self.stderr = 1
        with self.assertRaises(ValueError):
            self.execute()

    def test_unknown_duplicate_and_untyped_operations_are_rejected(self):
        for value in (["udp-open", "udp-open"], ["unreviewed"], [{}], []):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate_probe({**self.args, "operations": value}, ["probe.scm"])
