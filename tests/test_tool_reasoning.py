"""Real Library inference and real Action consumer; no tool execution claims."""
import copy
import json
from pathlib import Path
import unittest
import uuid
import tempfile
from unittest.mock import patch

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT, digest
from gambit_smp import research_actions

VIEW = "evidence/scenarios/tool-reasoning/ticket.view.json"


class ToolReasoningTests(unittest.TestCase):
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

    def test_real_gcc_receipt_allows_cross_family_inspection_not_clang_ir(self):
        answers = self.infer()
        context = answers["compiler_context"][0]
        self.assertEqual(context[1:5], ("gcc", "gcc-16 (Homebrew GCC 16.2.0) 16.2.0", "macho", "aarch64"))
        tools = {row[2] for row in answers["options"]}
        self.assertTrue({"gcc-dumps", "gnu-objdump", "llvm-objdump", "gdb", "lldb",
                         "herd7-aarch64", "herd7-c"} <= tools)
        self.assertTrue({"clang-ir", "gnu-readelf", "gnu-addr2line"}.isdisjoint(tools))
        self.assertEqual(answers["ready"], [])
        self.assertEqual({row[1] for row in answers["environment_options"]}, {"herd7-aarch64", "herd7-c"})
        self.assertEqual(self.infer(environment_hint=[])["environment_options"], [])
        self.assertEqual(len(answers["reuse"]), 1)
        self.assertTrue(all(digest(Path(path)) == sha for path, sha in self.inputs.items()))

    def test_compiler_and_format_are_evidence_not_default_or_tool_brand(self):
        build = [["ticket-codegen-audit", "clang", "test-control", "elf", "aarch64", "codegen"]]
        kinds = [*self.facts["compiler_kind"], ["clang", "clang", "policy"]]
        tools = {row[2] for row in self.infer(build=build, compiler_kind=kinds)["options"]}
        self.assertIn("clang-ir", tools)
        self.assertIn("gnu-readelf", tools)
        self.assertNotIn("gcc-dumps", tools)
        unknown = self.infer(build=[])
        self.assertEqual(unknown["options"], [])
        self.assertEqual(len(unknown["context_gaps"]), len(self.facts["question"]))
        conflict = self.infer(build=[*self.facts["build"], *build], compiler_kind=kinds)
        self.assertEqual(conflict["options"], [])
        self.assertEqual(len(conflict["conflicts"]), 1)
        self.assertEqual(self.infer(compiler_kind=[])["options"], [])

    def test_rationale_is_bound_and_choices_are_extensible_not_a_schedule(self):
        answers = self.infer()
        self.assertEqual({row[1] for row in answers["why"]},
                         {row[1] for row in self.facts["question"]})
        self.assertTrue(all(row[3] and row[4] and len(row[5]) == 64 for row in answers["why"]))
        extra = self.infer(tool=[*self.facts["tool"], ["caller-method", "Alternative inquiry",
                           "No source correctness claim", "policy"]],
                           offers=[*self.facts["offers"], ["caller-method", "weak-memory"]],
                           support=[*self.facts["support"], ["caller-method", "any", "any", "any"]])
        self.assertIn("caller-method", {row[2] for row in extra["options"]})
        self.assertEqual(self.infer(question=[])["options"], [])
        self.assertEqual(self.infer(rationale=[])["why"], [])
        self.assertEqual(self.infer(rationale=[])["options"], answers["options"])

    def test_withdrawal_and_restoration_change_only_supported_choices(self):
        before = self.infer()
        stripped = [row for row in self.facts["source"] if row[0] != "policy"]
        self.assertEqual(self.infer(source=stripped)["options"], [])
        self.assertEqual(self.infer()["options"], before["options"])
        wrong = self.infer(focus=[["ticket-codegen-audit", "codegen", "wrong"]])
        self.assertEqual(wrong["options"], [])
        sources = [row for row in self.facts["source"] if row[0] != "stress"]
        remaining = self.infer(source=sources)
        self.assertNotIn("runtime-ownership", {row[1] for row in remaining["options"]})
        self.assertIn("weak-memory", {row[1] for row in remaining["options"]})
        self.assertTrue(remaining["unbound"])

    def test_declared_readiness_does_not_remove_options_or_grant_permission(self):
        f = "ticket-codegen-audit"
        before = self.infer()
        premises = [[f, p, "codegen"] for t, p in self.facts["requirement"] if t == "herd7-aarch64"]
        answers = self.infer(available=premises)
        self.assertIn((f, "weak-memory", "herd7-aarch64"), answers["ready"])
        self.assertEqual(answers["options"], before["options"])
        broken = self.infer(available=[[f, "cat-dependency-closure", "missing-source"]])
        self.assertIn((f, "weak-memory", "herd7-aarch64", "cat-dependency-closure"), broken["missing"])
        self.assertEqual(broken["ready"], [])

    def test_empty_catalog_and_unknown_goals_do_not_close_exploration(self):
        answers = self.infer(tool=[], offers=[], support=[], requirement=[])
        self.assertEqual(answers["options"], [])
        self.assertEqual(len(answers["exploration_window"]), len(self.facts["question"]))
        self.assertIn("coverage", {row[0] for row in answers["choice_scope"]})
        novel = self.infer(question=[["ticket-codegen-audit", "caller-new-question", "codegen"]],
                           build=[], tool=[], offers=[], support=[])
        self.assertEqual(novel["options"], [])
        self.assertEqual(novel["exploration_window"][0][1], "caller-new-question")
        self.assertIn("inspect-open-investigation-space", {row[0] for row in novel["actions"]})

    def test_same_owner_source_updates_preserve_native_incremental_lifecycle(self):
        from gambit_smp.ascent_program import SourceQueryOwner
        owner = SourceQueryOwner(self.engine, self.facts, self.catalog)
        try:
            first = owner.evaluate(self.facts, self.document["queries"], 1_000_000_000)[0]
            withdrawn = dict(self.facts, question=[])
            second = owner.evaluate(withdrawn, self.document["queries"], 1_000_000_000)[0]
            restored = owner.evaluate(self.facts, self.document["queries"], 1_000_000_000)[0]
            self.assertTrue(first["options"])
            self.assertEqual(second["options"], [])
            self.assertEqual(restored["options"], first["options"])
        finally:
            owner.close()
        with self.assertRaises(ValueError):
            owner.evaluate(self.facts, self.document["queries"], 1_000_000_000)

    def test_actual_action_discover_select_observe_is_read_only(self):
        # Separate operational history, never fabricated inference or outcomes.
        with tempfile.TemporaryDirectory() as directory:
            from gambit_smp import artifact_storage
            original = artifact_storage.database_path
            def database(root, name, previous):
                return Path(directory) / "actions.sqlite" if name == "research-actions/requests.sqlite" else original(root, name, previous)
            with patch.object(artifact_storage, "database_path", side_effect=database):
                self.check_action_consumer()

    def check_action_consumer(self):
        request = json.loads((ROOT / "evidence/scenarios/tool-reasoning/action-context.json").read_text())
        snapshot = research_actions.discover(ROOT, request)
        action = next(row for row in snapshot["actions"] if row.get("query") == "options")
        self.assertEqual(action["risk"], "read-only")
        self.assertFalse(action["explanation"]["executionAuthorized"])
        identifier = str(uuid.uuid4())
        with self.assertRaisesRegex(ValueError, "authorization required"):
            research_actions.select(ROOT, snapshot, action["id"], {}, identifier,
                                    authorize_execution=False)
        chosen = research_actions.select(ROOT, snapshot, action["id"], {}, identifier,
                                         authorize_execution=True)
        self.assertEqual(chosen["result"]["outcome"], "RECORDED")
        observed = research_actions.observe(ROOT, identifier)
        self.assertEqual(observed["result"]["inspection"]["status"], "CURRENT")
        self.assertFalse(observed["executionAuthorized"])


if __name__ == "__main__":
    unittest.main()
