import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

from gambit_smp.agent_context import markdown, read_bundle, recheck, write_bundle
from gambit_smp.framework import digest
from gambit_smp.review_graph import build


class AgentContextTests(unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "source.py").write_text("source\n")
        self.inputs = {"source.py": digest(self.root / "source.py")}
        self.state = {"root": str(self.root), "head": "head", "branch": "branch",
                      "files": {"source.py": {"gitStatus": "untracked", "durableAtHead": False}}}
        self.engine = {"extension": "fixture"}
        facts = {"Passed": [], "ClaimDepends": [], "ReceiptDepends": [],
                 "CurrentInput": [["validated-catalog", "snapshot"], *self.inputs.items()]}
        rows = {"Need": [["task:model", "finite-model:model"]],
                "Missing": [["task:model", "finite-model:model"]], "Reusable": [],
                "Established": [], "Unusable": [], "ReceiptPath": [], "Denial": [], "CausalEvidence": []}
        graph = build(self.root, "model", facts, rows, {}, {}, self.inputs, self.engine, git_state=self.state)
        self.result = {"inputs": self.inputs, "receiptCurrentInputs": self.inputs,
            "engineInputs": self.engine, "agentGraph": graph,
            "frameworkValidation": {"status": "not-supplied", "frameworkValidated": False},
            "taskBrief": {"task": "model", "reusable": [], "invalidated": [], "unverified": [],
                          "openPremises": ["finite-model:model"], "knownFailedRoutes": [],
                          "gates": {"sourceCorrespondence": "open"}}}
        self.out = self.root / "context"
        self.out.mkdir()

    def test_bundle_is_readable_and_hash_checks_every_artifact(self):
        manifest = write_bundle(self.out, self.result)
        self.assertEqual(manifest, read_bundle(self.out)[0])
        self.assertIn("graph.json", (self.out / "context.md").read_text())
        (self.out / "graph.mmd").write_text("changed\n")
        with self.assertRaisesRegex(ValueError, "artifact identity mismatch"):
            read_bundle(self.out)

    def test_rechecking_changed_source_never_reuses_the_old_context_as_current(self):
        from contextlib import contextmanager
        @contextmanager
        def engine():
            yield None, self.engine
        write_bundle(self.out, self.result)
        with patch("gambit_smp.ascent_program.engine_api", engine), patch("gambit_smp.review_graph.checkout", return_value=self.state):
            self.assertEqual("CURRENT", recheck(self.root, self.out)["status"])
            (self.root / "source.py").write_text("changed\n")
            checked = recheck(self.root, self.out)
        self.assertEqual("STALE", checked["status"])
        self.assertEqual(["source.py"], checked["changedInputs"])
        self.assertFalse(checked["frameworkValidated"])

    def test_context_cannot_claim_execution_authorization(self):
        write_bundle(self.out, self.result)
        path = self.out / "context.json"
        manifest = json.loads(path.read_text())
        manifest["executionAuthorized"] = True
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "admission status mismatch"):
            read_bundle(self.out)

    def test_markdown_is_only_navigation_not_a_reasoning_transcription(self):
        result = dict(self.result, evidenceViews=[{"id": "caller-view", "path": "evidence/caller.view.json",
            "queries": {"options": "options", "missing": "missing", "exploration": "exploration"},
            "answers": {"options": [["question", "method"]], "missing": [],
                        "exploration": [["unknown-method-remains-open"]]}}])
        text = markdown(result)
        self.assertIn("evidence.json", text)
        self.assertLess(len(text), 250)
        self.assertNotIn("options", text)
        self.assertNotIn("unknown-method-remains-open", text)
        self.assertNotIn("Inquiry Interface", text)

    def test_historical_v1_bundle_is_read_without_rewriting_its_identity(self):
        write_bundle(self.out, self.result)
        path = self.out / "context.json"
        manifest = json.loads(path.read_text())
        manifest["schema"] = "gambit-agent-context.v1"
        manifest.pop("entrypoint")
        manifest["artifacts"].pop("evidence.json")
        path.write_text(json.dumps(manifest))
        original = path.read_bytes()
        self.assertEqual(read_bundle(self.out)[0]["schema"], "gambit-agent-context.v1")
        self.assertEqual(path.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
