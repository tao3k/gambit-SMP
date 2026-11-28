"""A receipt read shares observations while retaining every binding obligation."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.step_checkpoint import (
    _BindingRead, _observe_bindings, _resumption_relations, content_id, resumption, support_inventory,
)
from gambit_smp.evidence_views import load


class ResearchReadBindingTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name).resolve()
        self.source = self.root / "source.scm"
        self.tool = self.root / "tool"
        self.source.write_bytes(b"source")
        self.tool.write_bytes(b"tool")

    def retained_run(self, count=20):
        run = self.root / "run"
        (run / "run").mkdir(parents=True)
        inputs = {"source.scm": digest(self.source)}
        tools = {str(self.tool): digest(self.tool)}
        rows = [dict(id="stage-" + str(index), capability="quint.test", outcome="PASS",
                     dependsOn=[], arguments={}, budgetSeconds=10, commands=[])
                for index in range(count)]
        header = dict(engineId="fixture", inputs=inputs,
                      declaration=dict(scope="model fixture", inputs=list(inputs), steps=rows))
        records = [dict(payload=header)]
        for row in rows:
            inventory = support_inventory(self.root, header, row, tools, inputs)
            records.append(dict(inputs=inputs, payload=dict(schema="research-step-observation.v1",
                step=row, toolInputs=tools, supportInventory=inventory)))
        child = dict(recipe="fixture", inputsStable=True, outcome="PASS", steps=rows)
        raw = json.dumps(child).encode()
        (run / "run/receipt.json").write_bytes(raw)
        outer = dict(schema="sealed-research-run.v1", root=str(self.root), recipe="fixture",
                     engineId="fixture", outcome="PASS", parentReaped=True,
                     processGroupQuiescent=True, inputs=inputs,
                     stepBudgets={row["id"]: 10 for row in rows},
                     childReceiptSha256=hashlib.sha256(raw).hexdigest())
        (run / "receipt.json").write_text(json.dumps(outer))
        return run, records

    def test_support_inventory_enumerates_without_hashing_live_bytes(self):
        header = dict(engineId="fixture", inputs={"source.scm": "recorded"},
                      declaration=dict(scope="fixture", inputs=["source.scm"],
                                       steps=[dict(id="stage", dependsOn=[])]))
        with patch("gambit_smp.step_checkpoint.digest", side_effect=AssertionError("unexpected read")):
            result = support_inventory(self.root, header, dict(id="stage"), {str(self.tool): "tool"})
        self.assertEqual(result["bindings"], {str(self.source): "recorded", str(self.tool): "tool"})

    def test_shared_stage_support_hashes_each_file_once(self):
        run, records = self.retained_run()
        with patch("gambit_smp.reasoning_history.read_execution_checkpoint", return_value={"records": records}), \
                patch("gambit_smp.step_checkpoint._resumption_relations", return_value=({}, {})), \
                patch("gambit_smp.step_checkpoint.digest", wraps=digest) as hashed:
            result = resumption(self.root, run, {})
        self.assertEqual(hashed.call_count, 2)
        self.assertEqual(result["historyStatus"], "VERIFIED")
        self.assertEqual(len(result["requiredSteps"]), 20)
        self.assertFalse(result["executionAuthorized"])

    def test_source_change_during_inference_rejects_the_read(self):
        run, records = self.retained_run()

        def changed(*args, **kwargs):
            self.source.write_bytes(b"changed during inference")
            return {}, {}

        with patch("gambit_smp.reasoning_history.read_execution_checkpoint", return_value={"records": records}), \
                patch("gambit_smp.step_checkpoint._resumption_relations", side_effect=changed), \
                self.assertRaisesRegex(ValueError, "binding changed during inspection"):
            resumption(self.root, run, {})

    def test_observations_are_fresh_on_each_read(self):
        recorded = digest(self.source)
        expected, before = _observe_bindings(self.root, [{"source.scm": recorded}])
        self.source.write_bytes(b"later source")
        same_expected, after = _observe_bindings(self.root, [{"source.scm": recorded}])
        self.assertEqual(expected, same_expected)
        self.assertEqual(before, [(str(self.source), recorded)])
        self.assertEqual(after, [(str(self.source), digest(self.source))])
        self.assertNotEqual(before, after)

    def test_changed_alias_and_deleted_file_reject_snapshot(self):
        alias = self.root / "alias"
        alias.symlink_to(self.source)
        observation = _BindingRead(self.root)
        observation.read([{"alias": digest(self.source)}])
        alias.unlink()
        alias.symlink_to(self.tool)
        with self.assertRaisesRegex(ValueError, "binding path changed"):
            observation.verify()
        observation = _BindingRead(self.root)
        observation.read([{"source.scm": digest(self.source)}])
        self.source.unlink()
        with self.assertRaisesRegex(ValueError, "binding changed"):
            observation.verify()

    def test_conflicting_expected_digests_survive_deduplication(self):
        rows = [dict(id=name, outcome="PASS", dependsOn=[]) for name in ("first", "second")]
        support = {row["id"]: ([("key", "old"), ("key", "old"), ("key", "current")],
                                [("key", "current"), ("key", "current")]) for row in rows}
        with patch("gambit_smp.ascent_program.load_component_catalog", return_value={"sourceInputs": {}}), \
                patch("gambit_smp.ascent_program.query", return_value={}) as infer, \
                patch("gambit_smp.ascent_program._api_inventory", return_value=({}, {})):
            _resumption_relations(rows, [row["id"] for row in rows], {}, checked=True,
                campaign_pass=True, quiescent=True, support=support, inventories={})
        facts = infer.call_args.args[0]
        self.assertEqual(facts["current_binding"], [("key", "current")])
        self.assertEqual(len(facts["receipt_binding_group"]), 2)
        self.assertEqual(len(facts["binding_group"]), 2)
        self.assertEqual({value for _, _, value in facts["binding_group"]}, {"old", "current"})

    def view_document(self, *, immutable=False):
        (self.root / "evidence").mkdir()
        (self.root / "evidence/components.json").write_text("{}")
        ref = dict(id="source", path="source.scm", sha256=digest(self.source), pointer=None)
        if immutable:
            ref['identity'] = dict(kind='git', repository='.', revision='0' * 40,
                                   path='source.scm', blob='1' * 40, sha256=ref['sha256'])
        document = dict(schema="ascent.evidence-view.v1", id="fixture",
            manifest="evidence/components.json", entry="fixture", constructor="query",
            facts={"reference": {"references": True}}, queries={"reference": "reference"},
            references=[ref])
        (self.root / "evidence/view.json").write_text(json.dumps(document))
        return document

    def test_shared_binding_transport_grows_with_unique_members(self):
        rows = [dict(id="stage-" + str(index), outcome="PASS", dependsOn=[])
                for index in range(20)]
        pairs = [("tool-" + str(index), "digest-" + str(index)) for index in range(500)]
        support = {row['id']: (pairs + pairs, pairs) for row in rows}
        inventories = {row['id']: dict(contract="contract", scope="scope", checker="checker",
            bindings=dict(pairs), commands=[], dependencies=[], receipt=content_id(row)) for row in rows}
        with patch("gambit_smp.ascent_program.load_component_catalog", return_value={"sourceInputs": {}}), \
                patch("gambit_smp.ascent_program.query", return_value={}) as infer, \
                patch("gambit_smp.ascent_program._api_inventory", return_value=({}, {})):
            _resumption_relations(rows, [row['id'] for row in rows], {}, checked=True,
                campaign_pass=True, quiescent=True, support=support, inventories=inventories)
        facts = infer.call_args.args[0]
        self.assertEqual(len(facts['binding_group']), 500)
        self.assertEqual(len(facts['current_binding']), 500)
        self.assertEqual(len(facts['receipt_binding_group']), 20)
        self.assertEqual(len(facts['support_binding_group']), 20)

    def test_view_witness_reuses_the_checked_immutable_bytes(self):
        self.view_document(immutable=True)
        with patch("gambit_smp.source_identity.read_git_sources", return_value=[b"source"]) as read, \
                patch("gambit_smp.ascent_program.load_component_catalog", return_value={"sourceInputs": {}}):
            _, facts, catalog, _ = load(self.root, "evidence/view.json")
        self.assertEqual(read.call_count, 1)
        self.assertEqual(facts['reference'][0][2], digest(self.source))
        self.assertEqual(catalog['referenceWitnesses']['source']['digest'], digest(self.source))

    def test_view_rechecks_live_inputs_after_witness_construction(self):
        self.view_document()
        from gambit_smp.evidence_views import _reference_witnesses

        def changed(*args):
            result = _reference_witnesses(*args)
            self.source.write_bytes(b"changed after byte capture")
            return result

        with patch("gambit_smp.evidence_views._reference_witnesses", side_effect=changed), \
                patch("gambit_smp.ascent_program.load_component_catalog", return_value={"sourceInputs": {}}), \
                self.assertRaisesRegex(ValueError, "view changed during loading"):
            load(self.root, "evidence/view.json")

    def test_read_local_declaration_avoids_reloading_but_rechecks_sources(self):
        from gambit_smp.trajectory_exploration import _native_exchange
        inputs = {str(self.source): digest(self.source)}
        snapshot = dict(repositoryRoot=self.root, executionAuthorized=False, inputs=inputs,
            evidenceViews=[dict(path="fixture", inputs=inputs, queries={name: name for name in
                ('clue', 'factor', 'link')})])
        declarations = {"fixture": (dict(constructor="query"), {}, [], inputs, {})}
        with patch("gambit_smp.trajectory_exploration._declaration",
                   side_effect=AssertionError("duplicate declaration load")), \
                patch("ascent.trajectory.ClueExchange") as exchange:
            owner = _native_exchange(self.root, snapshot, object(), declarations=declarations)
            self.assertIs(owner, exchange.return_value)
            exchange.assert_called_once()
        with patch("ascent.trajectory.ClueExchange", side_effect=lambda *args:
                   self.source.write_bytes(b"changed during exchange")), \
                self.assertRaisesRegex(ValueError, "action source changed"):
            _native_exchange(self.root, snapshot, object(), declarations=declarations)


if __name__ == "__main__":
    unittest.main()
