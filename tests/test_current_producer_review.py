import copy
from pathlib import Path
import unittest
from unittest.mock import patch

from gambit_smp import native_capabilities as native, recipes


class CurrentProducerReviewTests(unittest.TestCase):
    def test_operation_scope_does_not_invent_unit_runner_coverage(self):
        from gambit_smp.native_review import selected_scope
        self.assertFalse(selected_scope("tests/run-unit-tests.scm", {"Makefile:core"}, []))
        self.assertTrue(selected_scope("tests/run-unit-tests.scm", {"control.scm"}, [Path("control.scm")]))

    def setUp(self):
        runtime = {"step": "core", "output": "runtime"}
        identity = {"step": "core", "output": "identity"}
        self.review = {"id": "review", "capability": "gambit.review", "dependsOn": ["core"],
                       "arguments": {"runtime": runtime, "identity": identity, "intent": "intent.json", "target": "suite"}}
        self.suite = {"id": "suite", "capability": "gambit.suite", "dependsOn": ["core", "review"],
                      "arguments": {"runtime": runtime, "identity": identity,
                                    "retryReview": {"step": "review", "output": "review"}}}
        self.steps = {"core": {"capability": "gambit.source-core"}, "review": self.review, "suite": self.suite}

    def test_same_producer_and_downstream_target_are_required(self):
        native.graph(self.review, self.steps, recipes.CAPABILITIES)
        native.graph(self.suite, self.steps, recipes.CAPABILITIES)
        for change in (lambda x: x["suite"]["dependsOn"].remove("review"),
                       lambda x: x["suite"]["arguments"]["identity"].update(step="old"),
                       lambda x: x["review"]["arguments"].update(target="unknown"),
                       lambda x: x["suite"]["arguments"]["retryReview"].update(output="runtime")):
            steps = copy.deepcopy(self.steps)
            change(steps)
            with self.subTest(change=change), self.assertRaises(ValueError):
                native.graph(steps["review"], steps, recipes.CAPABILITIES)

    def test_node_path_cannot_preempt_system_native_tools(self):
        searches = []
        def which(name, path=None):
            searches.append(path.split(":") if path else [])
            return "/usr/bin/" + name
        with patch("gambit_smp.native_capabilities.shutil.which", side_effect=which):
            tools, environment = native.host_tools(Path("/usr/bin/cc"), [], {"PATH": "/unrelated/node/bin"})
        self.assertTrue(all(row.index("/usr/bin") < row.index("/unrelated/node/bin") for row in searches))
        self.assertLess(environment["PATH"].split(":").index("/usr/bin"),
                        environment["PATH"].split(":").index("/unrelated/node/bin"))
        self.assertEqual(Path("/usr/bin/ld").resolve(), tools["ld"])
