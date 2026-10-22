"""Real durable start arbitration; these fixtures do not qualify an SMP build."""
import json
from pathlib import Path
import selectors
import subprocess
import sys
import unittest

from gambit_smp import reasoning_history as history
from gambit_smp.research_kernel import retain_run_record
from tests import test_workspace as fixtures


class BuildStartCustodyTests(unittest.TestCase):
    setUp = fixtures.WorkspaceTests.setUp

    def header(self, name, *, task="repair", source="source-sha", prior=None):
        run = self.root / ".cache/tasks" / task / name
        return run, {"schema": "research-run-header.v1", "runId": name,
            "recipe": "fixture-build", "engineId": "fixture-engine",
            "request": {"root": str(self.root), "prior": str(prior / "run") if prior else None},
            "inputs": {"source.lock.json": source}, "declaration": {"steps": [
                {"id": "source", "capability": "gambit.materialize", "arguments": {
                    "sourceLock": "source.lock.json"}, "dependsOn": []},
                {"id": "configure", "capability": "gambit.configure", "arguments": {
                    "source": {"step": "source", "output": "source"},
                    "cOptimization": 1, "rtsOptimization": 1}, "dependsOn": ["source"]}]}}

    def publish(self, run, header):
        run.mkdir(parents=True, exist_ok=True)
        return retain_run_record(self.root, run / "run-header.json", "build-fixture", header, header["inputs"])

    def ready(self, child, message):
        with selectors.DefaultSelector() as selector:
            selector.register(child.stdout, selectors.EVENT_READ)
            self.assertTrue(selector.select(timeout=20), "fixture producer did not reach its boundary")
        self.assertEqual(message, child.stdout.readline().strip())

    def test_new_numbered_output_cannot_repeat_a_legacy_header(self):
        first, header = self.header("runtime")
        self.publish(first, header)
        second, header = self.header("runtime-2")
        with self.assertRaisesRegex(history.CheckpointConflict, "--prior"):
            self.publish(second, header)
        self.assertFalse((second / "run-header.json").exists())
        self.assertEqual([], history.read_execution_checkpoint(self.root, second)["records"])

    def test_recipe_engine_step_names_and_budget_do_not_bypass_guard(self):
        run, header = self.header("first")
        self.publish(run, header)
        run, header = self.header("renamed")
        header.update(recipe="other-name", engineId="resealed", budgetSeconds=100)
        steps = header["declaration"]["steps"]
        steps[0]["id"] = "renamed-source"
        steps[1]["arguments"]["source"]["step"] = "renamed-source"
        steps[1]["dependsOn"] = ["renamed-source"]
        steps[1]["id"] = "renamed-configure"
        with self.assertRaisesRegex(history.CheckpointConflict, "durable attempt"):
            self.publish(run, header)

    def test_new_storage_route_cannot_hide_the_same_costly_source_build(self):
        self.publish(*self.header('old-route'))
        run, header = self.header('managed-route')
        header['recipe'] = 'renamed-managed-recipe'
        header['declaration']['steps'][0]['arguments']['buildWorkspace'] = 'gambit-core'
        with self.assertRaisesRegex(history.CheckpointConflict, 'durable attempt'):
            self.publish(run, header)

    def test_source_changes_still_require_lineage_and_another_task_is_distinct(self):
        first, header = self.header("first")
        self.publish(first, header)
        with self.assertRaisesRegex(history.CheckpointConflict, "durable attempt"):
            self.publish(*self.header("source-change", source="changed-source"))
        self.publish(*self.header("source-change", source="changed-source", prior=first))
        run, header = self.header("flags-change")
        header["declaration"]["steps"][1]["arguments"]["cOptimization"] = 2
        with self.assertRaisesRegex(history.CheckpointConflict, "durable attempt"):
            self.publish(run, header)
        # A separately named configuration is an independent build product.
        header["recipe"] = "other-configuration"
        self.publish(run, header)
        self.publish(*self.header("other-task", task="separate"))

    def test_prior_must_follow_the_latest_matching_attempt(self):
        first, header = self.header("first")
        self.publish(first, header)
        second, header = self.header("second", prior=first)
        self.publish(second, header)
        third, header = self.header("third", prior=first)
        with self.assertRaisesRegex(history.CheckpointConflict, str(second)):
            self.publish(third, header)
        third, header = self.header("third", prior=second)
        self.publish(third, header)
        # Start arbitration is not a recovered stage or runtime qualification.
        self.assertNotIn("runtimeAdmitted", history.read_execution_checkpoint(self.root, third)["records"][0]["payload"])

    def test_cache_loss_does_not_erase_the_prior_requirement(self):
        run, header = self.header("first")
        self.publish(run, header)
        (run / "run-header.json").unlink()
        run.rmdir()
        with self.assertRaisesRegex(history.CheckpointConflict, "durable attempt"):
            self.publish(*self.header("second"))

    def test_different_maintenance_roles_cannot_start_the_same_build(self):
        self.publish(*self.header("processes/audit/runs/one"))
        with self.assertRaisesRegex(history.CheckpointConflict, "durable attempt"):
            self.publish(*self.header("processes/validation/runs/two"))

    def test_killed_real_producer_retains_its_unfinished_checkpoint(self):
        run, header = self.header("killed-owner")
        code = ("import json,sys,time;from pathlib import Path;"
            "from gambit_smp.research_kernel import retain_run_record;"
            "h=json.loads(sys.argv[2]);run=Path(sys.argv[1]);run.mkdir(parents=True);"
            "retain_run_record(Path(h['request']['root']),run/'run-header.json','build-fixture',h,h['inputs']);"
            "print('COMMITTED',flush=True);time.sleep(30)")
        child = subprocess.Popen([sys.executable, "-c", code, str(run), json.dumps(header)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            self.ready(child, "COMMITTED")
            child.kill(); child.wait(timeout=5)
            retained = history.read_execution_checkpoint(self.root, run)
            with self.assertRaisesRegex(history.CheckpointConflict, "durable attempt"):
                self.publish(*self.header("restart-in-new-folder"))
            self.assertEqual(retained, history.read_execution_checkpoint(self.root, run))
            self.assertFalse((run / "receipt.json").exists())
        finally:
            if child.poll() is None:
                child.kill(); child.wait()
            child.stdout.close(); child.stderr.close()

    def test_other_builds_using_a_completed_producer_do_not_repeat_configure(self):
        self.publish(*self.header("first"))
        run, header = self.header("consume")
        header["declaration"]["steps"] = [{"id": "reuse", "capability": "gambit.completed-runtime",
            "arguments": {"producer": "existing-producer.json"}, "dependsOn": []}]
        self.publish(run, header)

    def test_real_competing_processes_commit_only_one_start(self):
        # Initialize routing before racing: the test concerns start arbitration,
        # not concurrent first-time history schema migration.
        history.read_execution_checkpoint(self.root, self.root / "unused")
        script = ("import json,sys,time;from pathlib import Path;"
            "from gambit_smp.research_kernel import retain_run_record;"
            "run=Path(sys.argv[1]);h=json.loads(sys.argv[2]);run.mkdir(parents=True);"
            "print('READY',flush=True);sys.stdin.readline();"
            "retain_run_record(Path(h['request']['root']),run/'run-header.json','build-fixture',h,h['inputs'])")
        children = []
        try:
            for name in ("codex", "grok"):
                run, header = self.header(name)
                child = subprocess.Popen([sys.executable, "-c", script, str(run), json.dumps(header)],
                    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                children.append(child)
            for child in children:
                self.ready(child, "READY")
            for child in children:
                child.stdin.write("GO\n"); child.stdin.flush()
            results = [child.communicate(timeout=20) for child in children]
            self.assertEqual([0, 1], sorted(child.returncode for child in children))
            self.assertIn("durable attempt", "".join(err for _, err in results))
            self.assertEqual(1, sum(bool(history.read_execution_checkpoint(self.root,
                self.root / ".cache/tasks/repair" / name)["records"]) for name in ("codex", "grok")))
        finally:
            for child in children:
                if child.poll() is None:
                    child.kill(); child.wait()
                for stream in (child.stdin, child.stdout, child.stderr):
                    if stream: stream.close()
