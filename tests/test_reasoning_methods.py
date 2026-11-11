"""Real declarative method inference, source withdrawal and Action consumption."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import uuid

from gambit_smp.ascent_program import SourceQueryOwner, engine_api, evaluate
from gambit_smp.evidence_views import load, registry
from gambit_smp.framework import ROOT, digest
from gambit_smp import research_actions

VIEW = "evidence/scenarios/concurrent-gc/reasoning-methods.view.json"
FOCUS = "working-gc-chunk"


class ReasoningMethodTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document, cls.facts, cls.catalog, cls.inputs = load(ROOT, VIEW)
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def infer(self, **changes):
        return evaluate(self.engine, dict(copy.deepcopy(self.facts), **changes),
                        self.catalog, self.document["queries"])[0]

    def test_real_questions_have_reasons_limits_and_missing_premises(self):
        answers = self.infer()
        self.assertEqual({row[2] for row in answers["options"]},
                         {"Lean", "Quint/QNT", "modify-evidence-dsl", "add-evidence-component"})
        self.assertTrue(all(row[3] and row[4] and row[5] and len(row[7]) == len(row[9]) == 64
                            for row in answers["options"]))
        self.assertEqual(len(answers["missing"]), 9)
        self.assertEqual(answers["supported"], [])
        self.assertEqual(answers["unbound"], [])
        self.assertEqual(len(answers["reused"]), 1)
        self.assertTrue(all(digest(Path(p)) == sha for p, sha in self.inputs.items()))

    def test_unknown_methods_questions_and_empty_catalog_remain_open(self):
        empty = self.infer(method=[], serves=[])
        self.assertEqual(empty["options"], [])
        self.assertEqual(len(empty["exploration"]), 4)
        self.assertEqual(len(empty["choice_scope"]), 4)
        extra = self.infer(method=[*self.facts["method"], ["unlisted-method", "Other inquiry", "No proof", "policy"]],
                           serves=[*self.facts["serves"], ["unlisted-method", "transition-coverage", "Caller alternative"]])
        self.assertIn("unlisted-method", {row[2] for row in extra["options"]})
        novel = self.infer(question=[[FOCUS, "novel-question", "unknown-kind", "policy"]])
        self.assertEqual(novel["options"], [])
        self.assertEqual(novel["exploration"][0][1], "novel-question")

    def test_bound_declared_premises_never_grant_proof_or_authority(self):
        q = "copying-root-closure"
        premises = [[FOCUS, q, p, "policy"] for m, p in self.facts["requirement"] if m == "Lean"]
        answers = self.infer(premise=premises)
        self.assertIn((FOCUS, q, "Lean"), answers["supported"])
        self.assertEqual(answers["options"], self.infer()["options"])
        self.assertEqual(self.infer(premise=[[FOCUS, q, p, "absent"] for _, _, p, _ in premises])["supported"], [])
        # A premise for a different question must not satisfy this one.
        self.assertEqual(self.infer(premise=[[FOCUS, "other", p, "policy"] for _, _, p, _ in premises])["supported"], [])

    def test_existing_and_new_components_are_nonexclusive_alternatives(self):
        methods = self.infer(serves=[*self.facts["serves"],
            ["add-evidence-component", "existing-component-extension", "An independently reviewed extraction alternative"]])
        self.assertEqual({row[2] for row in methods["options"] if row[1] == "method-explanation-contract"},
                         {"modify-evidence-dsl", "add-evidence-component"})
        self.assertEqual(self.infer(focus=[[FOCUS, "candidate", "wrong"]])["options"], [])

    def test_retained_session_withdraws_and_restores_without_inherited_support(self):
        owner = SourceQueryOwner(self.engine, self.facts, self.catalog)
        try:
            before = owner.evaluate(self.facts, self.document["queries"], 1_000_000_000)[0]
            changed = dict(self.facts, source=[r for r in self.facts["source"] if r[0] != "policy"])
            withdrawn = owner.evaluate(changed, self.document["queries"], 1_000_000_000)[0]
            self.assertEqual(withdrawn["options"], [])
            self.assertTrue(withdrawn["unbound"])
            self.assertEqual(owner.evaluate(self.facts, self.document["queries"], 1_000_000_000)[0], before)
        finally:
            owner.close()
        with self.assertRaises(ValueError):
            owner.evaluate(self.facts, self.document["queries"], 1_000_000_000)

    def test_registered_actual_action_context_discovers_selects_and_observes(self):
        self.assertIn(VIEW, registry(ROOT)[0])
        # This current declaration must not reactivate the historical native views.
        context = {"views": [VIEW]}
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(research_actions, "_request_database_path",
                              return_value=Path(directory) / "actions.sqlite"):
                snapshot = research_actions.discover(ROOT, context)
                action = next(row for row in snapshot["actions"] if row.get("view") == VIEW and row.get("query") == "options")
                self.assertEqual(action["risk"], "read-only")
                self.assertFalse(action["explanation"]["executionAuthorized"])
                identifier = str(uuid.uuid4())
                with self.assertRaisesRegex(ValueError, "authorization required"):
                    research_actions.select(ROOT, snapshot, action["id"], {}, identifier, authorize_execution=False)
                result = research_actions.select(ROOT, snapshot, action["id"], {}, identifier, authorize_execution=True)
                self.assertEqual(result["result"]["outcome"], "RECORDED")
                observed = research_actions.observe(ROOT, identifier)
                self.assertEqual(observed["result"]["inspection"]["status"], "CURRENT")
                self.assertFalse(observed["executionAuthorized"])


if __name__ == "__main__":
    unittest.main()
