"""Stage closure and tool custody; fixtures do not represent native acceptance."""
import json
from pathlib import Path
import tempfile
import subprocess
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.reasoning_history import normalized
from gambit_smp.step_checkpoint import content_id, journal_closure, observe_journal, observe_stage_record


class StageJournalCheckpointTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        subprocess.run(["git", "init", "--quiet", str(self.root)], check=True, capture_output=True)
        self.run = self.root / ".data/fixtures/run"
        (self.run / "run").mkdir(parents=True)
        self.tool = self.root / "compiler-fixture"
        self.tool.write_bytes(b"fixture only")
        self.source = self.root / "source.c"
        self.source.write_bytes(b"source fixture")
        self.header = {"runId": "fixture-run"}
        self.outer = {"journal": {"scope": "fixture", "sha256": "fixture", "path": "fixture"}}
        self.observations = {}

    def stage(self, name, dependencies=None, **changes):
        dependencies = dependencies or {}
        record = {"schema": "research-step-observation.v1", "runId": self.header["runId"],
                  "header": self.outer["journal"], "toolInputs": {str(self.tool): digest(self.tool)},
                  "step": {"id": name, "outcome": "PASS", "dependsOn": list(dependencies)},
                  "dependencies": dependencies}
        record.update(changes)
        path = self.run / "run" / (name + ".observation.json")
        path.write_text(json.dumps(record))
        identity = content_id(record)
        self.observations[identity] = {"scope": "fixture", "queries": normalized({"run_record": [record]}),
                                      "inputs": {str(self.source): digest(self.source)}}
        return {"path": str(path), "sha256": digest(path), "observation": identity, "scope": "fixture"}

    def read(self, target="seed"):
        return journal_closure(self.root, self.run, self.outer, self.header, self.observations, target)

    def test_successful_stages_survive_absent_aggregate_receipt(self):
        source = self.stage("source")
        self.stage("seed", {"source": source})
        rows, references = self.read()
        self.assertEqual([row["id"] for row in rows], ["source", "seed"])
        self.assertEqual(set(references), {"source", "seed"})
        self.assertFalse((self.run / "run/receipt.json").exists())

    def test_record_canonicalization_does_not_repeat_for_every_historical_observation(self):
        source = self.stage('source')
        self.stage('seed', {'source': source})
        for index in range(30):
            self.observations[str(index)] = {'scope': 'fixture',
                'queries': normalized({'run_record': [{'unrelated': index}]}), 'inputs': {}}
        with patch('gambit_smp.reasoning_history.normalized', wraps=normalized) as canonicalize:
            rows, _ = self.read()
        self.assertEqual(['source', 'seed'], [row['id'] for row in rows])
        self.assertEqual(2, canonicalize.call_count)

    def test_unbound_legacy_tools_do_not_become_qualified(self):
        self.stage("seed", toolInputs={})
        with self.assertRaisesRegex(ValueError, "tool bindings"):
            self.read()

    def test_tool_and_source_drift_reject(self):
        for path in (self.tool, self.source):
            with self.subTest(path=path):
                self.observations.clear()
                self.stage("seed")
                before = path.read_bytes()
                path.write_bytes(b"changed")
                with self.assertRaises(ValueError):
                    self.read()
                path.write_bytes(before)

    def test_record_without_durable_observation_rejects(self):
        self.stage("seed")
        self.observations.clear()
        with self.assertRaisesRegex(ValueError, "immutable observation"):
            self.read()

    def test_dependency_hash_and_missing_record_reject(self):
        source = self.stage("source")
        self.stage("seed", {"source": {**source, "sha256": "0" * 64}})
        with self.assertRaisesRegex(ValueError, "prerequisite identity"):
            self.read()
        (self.run / "run/source.observation.json").unlink()
        with self.assertRaises(FileNotFoundError):
            self.read()

    def test_failed_step_and_cross_run_record_reject(self):
        reference = self.stage("seed")
        path = Path(reference["path"])
        record = json.loads(path.read_text())
        record["step"]["outcome"] = "TIMEOUT"
        path.write_text(json.dumps(record))
        self.observations = {content_id(record): {"scope": "fixture",
            "queries": normalized({"run_record": [record]}), "inputs": {}}}
        with self.assertRaisesRegex(ValueError, "not successful"):
            self.read()
        self.stage("seed", runId="another-run")
        with self.assertRaisesRegex(ValueError, "another producer"):
            self.read()

    def retained_run(self, *, workspace=False, step_budgets=None):
        from gambit_smp.research_kernel import retain_run_record
        engine = self.root / "engine"
        engine.mkdir()
        inputs = {"source.c": digest(self.source)}
        header = {"schema": "research-run-header.v1", "runId": "fixture-run",
                  "recipe": "fixture", "engineId": "fixture-engine", "inputs": inputs}
        header["declaration"] = {"id": "fixture", "scope": "stage journal fixture, not native qualification",
            "inputs": list(inputs), "steps": [{"id": name, "dependsOn": []}
                for name in (step_budgets if step_budgets is not None else ["seed"])]}
        if step_budgets is not None:
            header["stepBudgets"] = step_budgets
        reference = retain_run_record(self.root, self.run / "run-header.json", "stage-fixture", header, inputs)
        artifact = self.run / "run/result.o"
        artifact.write_bytes(b"fixture artifact, not native code")
        row = {"id": "seed", "outcome": "PASS", "dependsOn": [],
               "outputs": {"object": {"path": "result.o", "sha256": digest(artifact),
                                        "mode": artifact.stat().st_mode & 0o777, "type": "native-object"}}}
        if workspace:
            from gambit_smp.artifact_storage import seal_workspace_state
            from gambit_smp.recipes import tree_identity
            artifact = self.run / "run/workspace"
            artifact.mkdir()
            (artifact / "generated.c").write_text("seed generation")
            state = seal_workspace_state(self.root, artifact, self.root / "evidence/seed-state.json", inputs)
            row["outputs"] = {"runtime": {"path": "workspace", "type": "seed-runtime",
                                          "identity": tree_identity(artifact), "stateEvidence": state}}
        record = {"schema": "research-step-observation.v1", "runId": header["runId"],
                  "header": reference, "toolInputs": {str(self.tool): digest(self.tool)},
                  "step": row, "dependencies": {}}
        from gambit_smp.step_checkpoint import support_inventory
        record["supportInventory"] = support_inventory(self.root, header, row, record["toolInputs"], inputs)
        retain_run_record(self.root, self.run / "run/seed.observation.json", "stage-fixture", record,
                          {str(self.source): digest(self.source)})
        outer = {"schema": "sealed-research-run.v1", "outcome": "DENY", "executionLaunched": True,
                 "parentReaped": True, "processGroupQuiescent": True, "root": str(self.root),
                 "engine": str(engine), "engineId": "fixture-engine", "recipe": "fixture",
                 "inputs": inputs, "journal": reference}
        (self.run / "receipt.json").write_text(json.dumps(outer))
        return artifact

    def test_actual_persistent_journal_reads_without_reconstructing_child(self):
        self.retained_run()
        with patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "fixture-engine"}):
            proof, outer, rows, _ = observe_journal(self.root, self.run, "seed")
        self.assertEqual(outer["outcome"], "DENY")
        self.assertEqual([row["id"] for row in rows], ["seed"])
        self.assertFalse(proof["runtimeAdmitted"])
        self.assertFalse(proof["resumptionAuthorized"])
        self.assertFalse(proof["missingChildReceiptReconstructed"])
        self.assertTrue(all(not Path(ref["path"]).is_absolute()
                            for ref in proof["stageReferences"].values()))
        self.assertFalse((self.run / "run/receipt.json").exists())

    def phase_without_parent(self):
        from gambit_smp.research_kernel import process_recorder
        self.retained_run(step_budgets={"seed": 5, "bootstrap": 5})
        (self.run / 'receipt.json').unlink()
        path = self.run / 'run/seed.observation.json'
        record = process_recorder(self.root, self.run, json.loads(path.read_text())['header'])
        with patch('gambit_smp.research_kernel.clock_epoch', return_value='fixture-boot'):
            record('planned', 'fixture-process', {'cwd': str(self.run/'run/bootstrap'), 'argv': ['fixture']})
            record('started', 'fixture-process', {'pid': 12345})
        return path

    def test_completed_phase_is_consumable_without_inventing_parent_completion(self):
        path = self.phase_without_parent()
        with patch('gambit_smp.research_kernel.clock_epoch', return_value='fixture-boot'), \
                patch('gambit_smp.process_observation.probe_group', return_value=(True, ())):
            proof, header, rows, run = observe_stage_record(self.root, path, {'engineId': 'fixture-engine'})
        self.assertEqual(['seed'], [row['id'] for row in rows])
        self.assertEqual('INCOMPLETE', proof['campaignOutcome'])
        self.assertFalse(proof['parentCompletionObserved'])
        self.assertFalse(proof['missingChildReceiptReconstructed'])
        self.assertFalse(proof['runtimeAdmitted'])
        self.assertFalse((run/'receipt.json').exists())
        self.assertEqual('fixture-engine', header['engineId'])

    def test_live_or_unknown_producer_cannot_lend_a_phase(self):
        path = self.phase_without_parent()
        for present in (False, None):
            with self.subTest(probe=present), \
                    patch('gambit_smp.research_kernel.clock_epoch', return_value='fixture-boot'), \
                    patch('gambit_smp.process_observation.probe_group', return_value=(present, ())):
                with self.assertRaisesRegex(ValueError, 'Scheme checkpoint'):
                    observe_stage_record(self.root, path, {'engineId': 'fixture-engine'})

    def test_phase_record_drift_and_wrong_engine_reject_before_reuse(self):
        path = self.phase_without_parent()
        with self.assertRaisesRegex(ValueError, 'pinned seal'):
            observe_stage_record(self.root, path, {'engineId': 'different'})
        row = json.loads(path.read_text())
        row['step']['outcome'] = 'PASS-WITHOUT-AUTHENTICATION'
        path.write_text(json.dumps(row))
        with self.assertRaisesRegex(ValueError, 'committed observation'):
            observe_stage_record(self.root, path, {'engineId': 'fixture-engine'})

    def test_omitted_original_input_cannot_become_a_checkpoint(self):
        self.outer["inputs"] = {"source.c": digest(self.source), "compiler-fixture": digest(self.tool)}
        self.stage("seed")
        with self.assertRaisesRegex(ValueError, "omits original"):
            self.read()

    def test_missing_live_artifact_rejects_even_with_retained_journal(self):
        artifact = self.retained_run()
        artifact.unlink()
        with patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "fixture-engine"}), \
                self.assertRaisesRegex(ValueError, "artifact inventory"):
            observe_journal(self.root, self.run, "seed")

    def test_historical_seed_state_is_not_permission_to_import_changed_runtime(self):
        workspace = self.retained_run(workspace=True)
        with patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "fixture-engine"}):
            original, *_ = observe_journal(self.root, self.run, "seed")
            (workspace / "generated.c").write_text("completed bootstrap generation")
            with self.assertRaisesRegex(ValueError, "artifact inventory"):
                observe_journal(self.root, self.run, "seed")
            historical, *_ = observe_journal(self.root, self.run, "seed", historical=True)
            self.assertEqual(original, historical)
            self.assertFalse(historical["runtimeAdmitted"])
            (self.root / "evidence/seed-state.json").write_text("tampered")
            with self.assertRaises(ValueError):
                observe_journal(self.root, self.run, "seed", historical=True)

    def test_historical_mode_still_rejects_missing_unarchived_artifact(self):
        artifact = self.retained_run()
        artifact.unlink()
        with patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "fixture-engine"}), \
                self.assertRaisesRegex(ValueError, "historical artifact"):
            observe_journal(self.root, self.run, "seed", historical=True)

    def test_nonquiescent_outer_does_not_authorize_stage_reuse(self):
        self.retained_run()
        path = self.run / "receipt.json"
        outer = json.loads(path.read_text())
        outer["processGroupQuiescent"] = False
        path.write_text(json.dumps(outer))
        with self.assertRaisesRegex(ValueError, "quiescent"):
            observe_journal(self.root, self.run, "seed")

    def test_restart_reads_committed_prefix_without_a_final_receipt(self):
        from gambit_smp.research_kernel import inspect
        self.retained_run(step_budgets={"seed": 5, "bootstrap": 5})
        (self.run / "receipt.json").unlink()
        before = {str(path): path.read_bytes() for path in self.run.rglob("*") if path.is_file()}
        result = inspect(self.run)
        state = result["resumption"]
        self.assertEqual(result["outcome"], "INCOMPLETE")
        self.assertEqual(state["historyStatus"], "COMMITTED_PREFIX")
        self.assertEqual(state["relations"]["historical_complete"], [("seed", content_id(json.loads((self.run / "run/seed.observation.json").read_text())["step"]))])
        self.assertEqual(state["relations"]["unresolved"], [("bootstrap",)])
        self.assertEqual(state["relations"]["campaign_reusable"], [])
        self.assertEqual(state["relations"]["reusable"], [])
        self.assertFalse(state["parentCompletionObserved"])
        self.assertFalse(state["executionAuthorized"])
        self.assertEqual(before, {str(path): path.read_bytes() for path in self.run.rglob("*") if path.is_file()})

    def test_prefix_history_survives_source_drift_without_admitting_old_artifacts(self):
        from gambit_smp.research_kernel import inspect
        self.retained_run(step_budgets={"seed": 5, "bootstrap": 5})
        (self.run / "receipt.json").unlink()
        self.source.write_text("changed source")
        state = inspect(self.run)["resumption"]
        self.assertEqual(state["historyStatus"], "COMMITTED_PREFIX")
        self.assertEqual(state["relations"]["historical_complete"], [("seed", content_id(json.loads((self.run / "run/seed.observation.json").read_text())["step"]))])
        self.assertEqual(state["relations"]["invalidated"], [("seed",)])
        self.assertEqual(state["relations"]["reusable"], [])
        self.assertFalse((self.run / "receipt.json").exists())

    def test_live_native_progress_is_projected_without_reconstructing_a_pass(self):
        from gambit_smp.research_kernel import inspect, process_recorder
        self.retained_run(step_budgets={"seed": 5, "bootstrap": 5})
        (self.run / 'receipt.json').unlink()
        reference = json.loads((self.run / 'run/seed.observation.json').read_text())['header']
        record = process_recorder(self.root, self.run, reference)
        with patch('gambit_smp.research_kernel.clock_epoch', return_value='fixture-boot'):
            record('planned', 'fixture-process', {'cwd': str(self.run/'run/bootstrap/tests'), 'argv': ['fixture']})
            record('started', 'fixture-process', {'pid': 12345})
            record('progress', 'fixture-process', {'count': 1, 'observedMonotonic': 10., 'witness': None})
            record('progress', 'fixture-process', {'count': 2, 'observedMonotonic': 20., 'witness': None})
            with patch('gambit_smp.process_observation.probe_group', return_value=(False, ('present',))):
                with patch('gambit_smp.step_checkpoint.execution_owner', return_value=dict(
                        provider='grok', recordedTaskState='returned', reference='owner-snapshot')):
                    state = inspect(self.run)['resumption']
        self.assertEqual([('bootstrap', 'fixture-process', 12345, 'present-unattributed')],
                         state['relations']['execution_pending'])
        self.assertEqual(2, state['relations']['execution_frontier'][0][2])
        self.assertEqual([('bootstrap', 'grok', 'returned', 'owner-snapshot')],
                         state['relations']['execution_detached'])
        self.assertEqual(1, len(state['executionObservation']['progress']))
        self.assertIsNone(state['executionObservation']['progress'][0]['witness'])
        self.assertEqual([], state['relations']['campaign_reusable'])
        self.assertFalse(state['parentCompletionObserved'])
        self.assertFalse(state['executionAuthorized'])
        self.assertFalse(state['executionObservation']['completionCountsArePasses'])
        self.assertFalse((self.run/'receipt.json').exists())

    def test_unknown_host_probe_and_reboot_never_become_active_or_reusable(self):
        from gambit_smp.step_checkpoint import execution_observations
        records = [{'payload': {'schema': 'research-process-observation.v1', 'token': 'p',
                    'event': 'planned', 'cwd': str(self.run/'run/seed')}},
                   {'payload': {'schema': 'research-process-observation.v1', 'token': 'p',
                    'event': 'started', 'clockEpoch': 'old-boot', 'pid': 12345}}]
        with patch('gambit_smp.research_kernel.clock_epoch', return_value='new-boot'), \
                patch('gambit_smp.process_observation.probe_group') as probe:
            facts, _ = execution_observations(self.run, records, ['seed'])
        probe.assert_not_called()
        self.assertEqual([('p', 12345, 'unknown')], facts['execution_process'])
        with patch('gambit_smp.research_kernel.clock_epoch', return_value='old-boot'), \
                patch('gambit_smp.process_observation.probe_group', return_value=(None, ('permission-denied',))):
            facts, _ = execution_observations(self.run, records, ['seed'])
        self.assertEqual([('p', 12345, 'unknown')], facts['execution_process'])

    def test_provider_custody_is_a_bound_snapshot_not_session_or_native_completion(self):
        from gambit_smp.step_checkpoint import execution_owner
        output = self.root/'.cache/tasks/repair/runs/attempt'
        owner = self.root/'.state/task-runs/repair/attempt.json'
        owner.parent.mkdir(parents=True)
        value = dict(task='repair', provider='grok', state='returned', output=str(output))
        owner.write_text(json.dumps(value))
        result = execution_owner(self.root, output/'outputs/native')
        self.assertEqual('returned', result['recordedTaskState'])
        self.assertFalse(result['sessionCompletionObserved'])
        self.assertEqual(digest(owner), result['reference'])
        value['output'] = str(self.root/'other')
        owner.write_text(json.dumps(value))
        unknown = execution_owner(self.root, output/'outputs/native')
        self.assertEqual('MISMATCH', unknown['bindingStatus'])
        self.assertEqual('unknown', unknown['recordedTaskState'])
        self.assertFalse(unknown['sessionCompletionObserved'])
    def test_existing_incomplete_run_returns_prefix_without_launching(self):
        from gambit_smp.research_kernel import run_sealed
        self.retained_run(step_budgets={"seed": 5, "bootstrap": 5})
        (self.run / "receipt.json").unlink()
        recipe = self.root / "recipe.json"
        recipe.write_text('{}')
        definition = {"schema": "evidence-recipe.v2", "id": "fixture", "inputs": ["source.c"], "budgetSeconds": 10}
        steps = [{"id": name, "budgetSeconds": 5} for name in ("seed", "bootstrap")]
        with patch("gambit_smp.recipes.load", return_value=(definition, steps)), \
                patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "fixture-engine"}), \
                patch("gambit_smp.research_kernel.execute") as execute:
            result = run_sealed(self.root, recipe, self.run, self.root / "engine")
        execute.assert_not_called()
        self.assertEqual(result["resumeStatus"], "INCOMPLETE")
        self.assertEqual(result["resumption"]["relations"]["historical_complete"], [("seed", content_id(json.loads((self.run / "run/seed.observation.json").read_text())["step"]))])
        self.assertFalse(result["executionLaunched"])
        self.assertFalse((self.run / "receipt.json").exists())
