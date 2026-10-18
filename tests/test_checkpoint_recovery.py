"""Real process/store/Session recovery. Fixture receipts are not SMP acceptance."""
import json
import os
from pathlib import Path
import shutil
import signal
import selectors
import subprocess
import sys
import tempfile
import unittest

from gambit_smp.framework import digest
from gambit_smp import reasoning_history as history


def fixture_producer(root, terminal=False, omit_witness=False):
    from gambit_smp.research_kernel import retain_run_record, retain_terminal_run
    root = Path(root)
    run = root / ".cache/qualification"
    (run / "run/committed").mkdir(parents=True)
    source = root / "source"
    source.write_text("fixture support, not Gambit code")
    inputs = {"source": digest(source)}
    header = {"schema": "research-run-header.v1", "runId": "controlled-process-fixture",
              "recipe": "fixture", "engineId": "fixture-only", "inputs": inputs,
              "stepBudgets": {"committed": 5} if terminal else {"committed": 5, "unfinished": 5}}
    header["declaration"] = {"id": "fixture", "scope": "process recovery fixture, not native qualification",
        "inputs": list(inputs), "steps": [{"id": "committed", "dependsOn": []}]}
    ref = retain_run_record(root, run / "run-header.json", "process-fixture", header, inputs)
    command = subprocess.run([sys.executable, "-c", "print('actual fixture child completed')"],
                             check=True, capture_output=True, text=True)
    artifact = run / "run/committed/value"
    artifact.write_text(command.stdout)
    step = {"id": "committed", "outcome": "PASS", "dependsOn": [],
            "commands": [{"exit": command.returncode, "timeout": False,
                          "parentReaped": True, "processGroupQuiescent": True}],
            "outputs": {"value": {"type": "fixture", "path": "committed/value", "sha256": digest(artifact)}}}
    record = {"schema": "research-step-observation.v1", "runId": header["runId"], "header": ref,
              "step": step, "toolInputs": {str(Path(sys.executable).resolve()): digest(Path(sys.executable).resolve())},
              "dependencies": {}}
    from gambit_smp.step_checkpoint import support_inventory
    record["supportInventory"] = support_inventory(root, header, step, record["toolInputs"])
    if omit_witness:
        del record["supportInventory"]
    retain_run_record(root, run / "run/committed.observation.json", "process-fixture", record, inputs)
    if terminal:
        child_path = run / "run/receipt.json"
        child_path.write_text(json.dumps({"recipe": "fixture", "outcome": "PASS", "inputsStable": True, "steps": [step]}))
        outer = {"schema": "sealed-research-run.v1", "recipe": "fixture", "engineId": "fixture-only",
                 "outcome": "PASS", "parentReaped": True, "processGroupQuiescent": True,
                 "root": str(root), "inputs": inputs, "stepBudgets": header["stepBudgets"],
                 "childReceiptSha256": digest(child_path)}
        (run / "receipt.json").write_text(json.dumps(outer))
        retain_terminal_run(root, run, outer)
    print("COMMITTED", flush=True)
    if not terminal:
        signal.pause()


class CheckpointProcessRecoveryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        self.run = self.root / ".cache/qualification"

    def producer(self, terminal=False, omit_witness=False):
        code = "from tests.test_checkpoint_recovery import fixture_producer; fixture_producer(" + repr(str(self.root)) + ", " + repr(terminal) + ", " + repr(omit_witness) + ")"
        return subprocess.Popen([sys.executable, "-c", code], stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, text=True, start_new_session=True)

    def recover_in_fresh_process(self):
        code = "import json; from pathlib import Path; from gambit_smp.research_kernel import inspect; print(json.dumps(inspect(Path(" + repr(str(self.run)) + "))))"
        result = subprocess.run([sys.executable, "-c", code], check=True, capture_output=True, text=True, timeout=20)
        return json.loads(result.stdout)

    def test_killed_producer_recovers_committed_history_after_entire_cache_removal(self):
        process = self.producer()
        try:
            with selectors.DefaultSelector() as ready:
                ready.register(process.stdout, selectors.EVENT_READ)
                self.assertTrue(ready.select(20), "fixture producer made no committed progress")
            self.assertEqual(process.stdout.readline().strip(), "COMMITTED")
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate(timeout=5)
            self.assertEqual(process.returncode, -signal.SIGKILL)
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate(timeout=5)
        before = history.read_execution_checkpoint(self.root, self.run)
        shutil.rmtree(self.root / ".cache")
        recovered = self.recover_in_fresh_process()
        state = recovered["resumption"]
        self.assertEqual(state["prefixIdentity"], before["prefixIdentity"])
        self.assertEqual([row[0] for row in state["relations"]["historical_complete"]], ["committed"])
        self.assertEqual(state["relations"]["unresolved"], [["unfinished"]])
        self.assertEqual(state["relations"]["reusable"], [])
        self.assertFalse(state["parentCompletionObserved"])
        self.assertFalse(state["executionAuthorized"])
        self.assertFalse(self.run.exists())

    def test_recorded_terminal_pass_is_retained_but_deleted_material_is_not_reusable(self):
        process = self.producer(terminal=True)
        output, error = process.communicate(timeout=20)
        self.assertEqual(process.returncode, 0, error)
        self.assertEqual(output.strip(), "COMMITTED")
        shutil.rmtree(self.root / ".cache")
        recovered = self.recover_in_fresh_process()
        self.assertEqual(recovered["recordedOutcome"], "PASS")
        state = recovered["resumption"]
        self.assertTrue(state["parentCompletionObserved"])
        self.assertEqual([row[0] for row in state["relations"]["historical_complete"]], ["committed"])
        self.assertEqual(state["relations"]["artifact_unavailable"], [["committed"]])
        self.assertEqual(state["relations"]["campaign_reusable"], [])
        self.assertFalse(self.run.exists())

    def test_missing_enumeration_witness_stays_unknown_after_cache_cleanup_and_restart(self):
        process = self.producer(terminal=True, omit_witness=True)
        _, error = process.communicate(timeout=20)
        self.assertEqual(process.returncode, 0, error)
        from gambit_smp.step_checkpoint import recovered_resumption
        before = recovered_resumption(self.root, self.run)
        self.assertEqual(before["recordedOutcome"], "PASS")
        self.assertEqual(before["resumption"]["relations"]["reusable"], [])
        self.assertTrue(before["resumption"]["relations"]["enumeration_gap"])
        shutil.rmtree(self.root / ".cache")
        after = self.recover_in_fresh_process()
        self.assertEqual(after["recordedOutcome"], "PASS")
        self.assertEqual(after["resumption"]["relations"]["historical_complete"], [])
        self.assertEqual(after["resumption"]["relations"]["reusable"], [])
        self.assertEqual(after["resumption"]["relations"]["enumeration_gap"],
                         json.loads(json.dumps(before["resumption"]["relations"]["enumeration_gap"])))
        self.assertFalse(self.run.exists())

    def test_consistent_migration_keeps_legacy_bytes_and_replays_the_same_prefix(self):
        process = self.producer(terminal=True)
        _, error = process.communicate(timeout=20)
        self.assertEqual(process.returncode, 0, error)
        before = history.read_execution_checkpoint(self.root, self.run)
        durable = self.root / ".state/reasoning/history.sqlite3"
        legacy = self.root / ".cache/reasoning/history.sqlite3"
        legacy.parent.mkdir(parents=True)
        durable.rename(legacy)
        original = digest(legacy)
        self.assertEqual(history.read_execution_checkpoint(self.root, self.run), before)
        self.assertEqual(digest(legacy), original)
        self.assertTrue(durable.is_file())

    def test_competing_processes_cannot_publish_over_the_same_prefix(self):
        history.append_observation(self.root, "process-fixture", {}, {"run_record": [{"label": "open-prefix"}]}, {},
            checkpoint=dict(run=str(self.run), runId="controlled-process-fixture", path=str(self.run / "open"),
                            scope="process-fixture", expectedPrefix=None))
        prefix = history.read_execution_checkpoint(self.root, self.run)
        expected = prefix["prefixIdentity"]
        code = """import sys
from pathlib import Path
from gambit_smp import reasoning_history as h
root, run, expected, label = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
checkpoint = dict(run=run, runId='controlled-process-fixture', path=run+'/'+label, scope='process-fixture', expectedPrefix=expected)
try:
 h.append_observation(root, 'process-fixture', {}, {'run_record': [{'label':label}]}, {}, checkpoint=checkpoint)
except h.CheckpointConflict:
 sys.exit(2)
"""
        workers = [subprocess.Popen([sys.executable, "-c", code, str(self.root), str(self.run), expected, label],
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE) for label in ("left", "right")]
        results = []
        for worker in workers:
            _, error = worker.communicate(timeout=20)
            self.assertIn(worker.returncode, (0, 2), error.decode())
            results.append(worker.returncode)
        self.assertEqual(sorted(results), [0, 2])
        after = history.read_execution_checkpoint(self.root, self.run)
        self.assertEqual(len(after["records"]), len(prefix["records"]) + 1)

    def test_terminal_execution_cannot_be_poisoned_by_another_append(self):
        process = self.producer(terminal=True)
        _, error = process.communicate(timeout=20)
        self.assertEqual(process.returncode, 0, error)
        prefix = history.read_execution_checkpoint(self.root, self.run)
        with self.assertRaisesRegex(history.CheckpointConflict, "terminal execution"):
            history.append_observation(self.root, "process-fixture", {}, {"run_record": [{"label": "too-late"}]}, {},
                checkpoint=dict(run=str(self.run), runId=prefix["runId"], path=str(self.run / "late"),
                                scope="process-fixture", expectedPrefix=prefix["prefixIdentity"]))
        self.assertEqual(history.read_execution_checkpoint(self.root, self.run), prefix)
        self.assertEqual(self.recover_in_fresh_process()["recordedOutcome"], "PASS")


if __name__ == "__main__":
    unittest.main()
