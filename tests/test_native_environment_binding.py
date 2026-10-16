"""Transport identity controls, not native acceptance or causal inference."""
import copy
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest

from gambit_smp.framework import digest
from gambit_smp.native_review import environment_change
from gambit_smp.native_capabilities import graph
from gambit_smp.recipes import CAPABILITIES


class EnvironmentBindingTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name).resolve()
        self.program = self.root / "models/gambit/native/host_environment_probe.scm"
        self.program.parent.mkdir(parents=True)
        self.program.write_text("(exit 0)\n")
        self.observation = self.root / "observation.json"
        self.reference = {"step": "probe", "output": "observation"}
        self.record = {"schema": "current-producer-observation.v1", "candidateReceiptSha256": "a" * 64,
                       "complete": True, "runtimeAdmitted": False, "nativeGcPassed": False,
                       "program": "models/gambit/native/host_environment_probe.scm",
                       "programSha256": digest(self.program), "processors": 4, "operations": ["udp-open"]}
        self.current = {"environmentProbe": self.reference, "candidateReceiptSha256": "a" * 64,
                        "hostCpuCapacity": 5}
        self.change = {"after": self.reference, "path": "udp-open"}
        self.ctx = SimpleNamespace(root=self.root, artifact=lambda ref, kind: self.observation,
                                   bind=lambda paths: list(paths))

    def run_binding(self):
        self.observation.write_text(json.dumps(self.record))
        self.current["environmentObservationSha256"] = digest(self.observation)
        facts = {"environment_observation": [], "environment_control": []}
        environment_change(self.ctx, self.change, self.current, {"id": "old"}, {}, facts, {})
        return facts

    def test_bound_current_observation_is_only_a_fact(self):
        self.assertEqual([["old", "udp-open"]], self.run_binding()["environment_observation"])

    def test_wrong_identity_completion_capacity_operation_and_admission_are_rejected(self):
        original = copy.deepcopy(self.record)
        for key, value in (("candidateReceiptSha256", "b" * 64), ("complete", False),
                           ("processors", 5), ("operations", []), ("runtimeAdmitted", True),
                           ("nativeGcPassed", True), ("programSha256", "b" * 64)):
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.record = {**original, key: value}
                self.run_binding()

    def test_foreign_probe_reference_is_not_a_permission_lease(self):
        self.change["after"] = {"step": "previous-run", "output": "observation"}
        with self.assertRaises(ValueError):
            self.run_binding()

    def test_graph_requires_same_producer_and_explicit_dependency(self):
        runtime = {"step": "producer", "output": "runtime"}
        identity = {"step": "producer", "output": "identity"}
        producer = {"id": "producer", "capability": "gambit.completed-runtime", "arguments": {}}
        probe = {"id": "probe", "capability": "gambit.probe", "arguments": {"runtime": runtime, "identity": identity}}
        suite = {"id": "suite", "capability": "gambit.suite", "dependsOn": ["producer", "probe"],
                 "arguments": {"runtime": runtime, "identity": identity, "environmentProbe": self.reference}}
        by_id = {row["id"]: row for row in (producer, probe, suite)}
        graph(suite, by_id, CAPABILITIES)
        suite["dependsOn"] = ["producer"]
        with self.assertRaises(ValueError):
            graph(suite, by_id, CAPABILITIES)
        suite["dependsOn"] = ["producer", "probe"]
        probe["arguments"]["identity"] = {"step": "foreign", "output": "identity"}
        with self.assertRaises(ValueError):
            graph(suite, by_id, CAPABILITIES)
