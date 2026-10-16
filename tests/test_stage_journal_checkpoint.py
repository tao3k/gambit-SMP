"""Stage closure and tool custody; fixtures do not represent native acceptance."""
import json
from pathlib import Path
import tempfile
import subprocess
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.reasoning_history import normalized
from gambit_smp.step_checkpoint import content_id, journal_closure, observe_journal


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

    def retained_run(self, *, workspace=False):
        from gambit_smp.research_kernel import retain_run_record
        engine = self.root / "engine"
        engine.mkdir()
        inputs = {"source.c": digest(self.source)}
        header = {"schema": "research-run-header.v1", "runId": "fixture-run",
                  "recipe": "fixture", "engineId": "fixture-engine", "inputs": inputs}
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
