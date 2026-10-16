"""The ordinary rule path must dispatch without module-only local state."""
import json
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

from gambit_smp import evidence_capabilities as evidence
from gambit_smp.native_capabilities import validate_materialize


class ContinuationReviewDispatchTests(unittest.TestCase):
    def test_nonmodule_rules_dispatch_uses_current_python(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            directory = root / "review"
            directory.mkdir()
            rule = root / "rules.ss"
            rule.write_text("(def rules '())\n")
            calls = []

            def require(stage, argv, cwd, budget):
                calls.append(argv)
                (directory / "retry/answers.json").write_text(json.dumps({"decision": [["DENY"]]}))

            ctx = types.SimpleNamespace(root=root, directory=directory,
                receipt={"engine": {"path": str(root / "engine"), "engineId": "fixture"}},
                extra_inputs={}, require=require, remaining=lambda: 1)
            with patch("gambit_smp.research_kernel.execution_identity"), \
                    patch.object(evidence, "_evaluation_owner", None):
                result = evidence.evaluate_observations(ctx, ["rules.ss"], {},
                                                       {"decision": "retry_decision"}, "retry")
            self.assertEqual(result, {"decision": [["DENY"]]})
            self.assertEqual(calls[0][0], sys.executable)

    def test_state_reference_requires_declared_exclusive_workspace(self):
        args = {"sourceLock": "evidence/source.lock.json", "workspaceState": "evidence/state.json"}
        with self.assertRaises(ValueError):
            validate_materialize(args, list(args.values()))
        args["workspace"] = ".data/fixtures/current"
        validate_materialize(args, ["evidence/source.lock.json", "evidence/state.json"])
        args["cacheReceipt"] = "evidence/cache.json"
        with self.assertRaises(ValueError):
            validate_materialize(args, ["evidence/source.lock.json", "evidence/state.json", "evidence/cache.json"])
