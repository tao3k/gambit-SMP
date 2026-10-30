"""A real sealed Evidence evaluation resumes a committed phase, not a mock executor."""
import json
import hashlib
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.research_kernel import run_sealed
from gambit_smp.step_checkpoint import recovered_resumption


@unittest.skipUnless(os.environ.get("GAMBIT_SMP_TEST_ENGINE"), "requires the actual current sealed framework engine")
class SealedCheckpointRecoveryTests(unittest.TestCase):
    validation_domain = {"kind": "sealed-research", "budgetSeconds": 60, "workers": "auto", "processesPerWorker": 2}

    def test_interrupted_supervisor_resumes_a_checked_phase_without_evaluating_it_again(self):
        engine = Path(os.environ["GAMBIT_SMP_TEST_ENGINE"]).resolve()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            subprocess.run(["git", "init", "-q", str(root)], check=True, capture_output=True)
            (root / "models/gambit").mkdir(parents=True)
            (root / "models/gambit/cases.json").write_text("{}")
            shutil.copytree(ROOT / "evidence/dsl", root / "evidence/dsl")
            declaration = root / "evidence/fixture.ss"
            declaration.write_text("(define-evidence (fixture) (sources) (outputs checked) "
                                   "(relation checked (ok) '((#t))))")
            entry = root / "evidence/fixture.json"
            entry.write_text(json.dumps({"schema": "ascent.evidence-dsl-entry.v1",
                "sources": [{"path": "evidence/fixture.ss", "sha256": digest(declaration)}],
                "constructor": "fixture", "arguments": [], "trusted": True}))
            recipe = root / "evidence/fixture.recipe.json"
            recipe.write_text(json.dumps({"schema": "evidence-recipe.v2", "id": "checkpoint-fixture",
                "scope": "Native Evidence evaluation recovery only; not Gambit runtime acceptance", "budgetSeconds": 15,
                "inputs": ["evidence/fixture.ss", "evidence/fixture.json"],
                "steps": [{"id": "linking", "capability": "evidence.evaluate", "dependsOn": [],
                           "budgetSeconds": 15, "arguments": {"dsl": "evidence/fixture.json",
                           "queries": {"checked": "checked"}, "expected": {"checked": [[True]]}}}]}))
            original = root / ".cache/original"
            continued = root / ".cache/continued"
            code = ("from pathlib import Path; import sys; "
                    "sys.path.insert(0, str(Path(sys.argv[4]) / 'python')); "
                    "from gambit_smp.research_kernel import run_sealed; "
                    "run_sealed(*map(Path, sys.argv[1:]), allow_native=True)")
            parent = subprocess.Popen([sys.executable, "-c", code, str(root), str(recipe), str(original), str(engine)],
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
            worker_pid = None
            parent_error = ""
            try:
                deadline = time.monotonic() + 20
                owner_path = original / "launch-owner.json"
                while not owner_path.is_file():
                    if parent.poll() is not None or time.monotonic() >= deadline:
                        _, error = parent.communicate(timeout=2)
                        self.fail("sealed owner did not start: " + error.decode())
                    time.sleep(.01)
                owner = json.loads(owner_path.read_text())
                worker_pid = owner["pid"]
                # Birth custody precedes exec permission. Stopping the parent
                # at birth can prevent it from delivering the environment to
                # the child; that tests launch cancellation, not phase recovery.
                planned = json.loads((original / ("process-" + owner["token"] + "-planned.json")).read_text())
                intent_path = root / planned["spawnProtocol"]["directory"] / "exec-intent.json"
                while not intent_path.is_file():
                    if parent.poll() is not None or time.monotonic() >= deadline:
                        _, error = parent.communicate(timeout=2)
                        self.fail("sealed owner did not reach exec intent: " + error.decode())
                    time.sleep(.01)
                intent = json.loads(intent_path.read_text())
                self.assertEqual(intent["token"], owner["token"])
                self.assertEqual(intent["birth"], owner["birth"])
                os.kill(parent.pid, signal.SIGSTOP)
                stage = original / "run/linking.observation.json"
                while not stage.is_file():
                    if time.monotonic() >= deadline:
                        os.kill(parent.pid, signal.SIGCONT)
                        _, error = parent.communicate(timeout=5)
                        parent_error = error.decode()
                        log = (original / "launch.log").read_text() if (original / "launch.log").exists() else "no launch log"
                        self.fail("sealed phase failed to commit: " + log[-4000:] + parent_error[-4000:])
                    time.sleep(.01)
                stage_bytes = stage.read_bytes()
                os.killpg(parent.pid, signal.SIGKILL)
                parent.communicate(timeout=5)
                self.assertFalse((original / "receipt.json").exists())
                while True:
                    state = recovered_resumption(root, original)
                    if state["resumption"]["executionQuiescence"]["observed"]:
                        break
                    self.assertLess(time.monotonic(), deadline, "recorded process groups remain active")
                    time.sleep(.02)
                self.assertEqual(state["outcome"], "INCOMPLETE")
                self.assertFalse(state["resumption"]["parentCompletionObserved"])
                self.assertEqual([row[0] for row in state["resumption"]["relations"]["reusable"]], ["linking"])
                result = run_sealed(root, recipe, continued, engine, prior=original, allow_native=True)
                self.assertEqual(result["outcome"], "PASS", result)
                child = json.loads((continued / "run/receipt.json").read_text())
                self.assertEqual(child["checkpointConsumption"]["reusedSteps"], ["linking"])
                self.assertFalse(child["steps"][0]["executionLaunched"])
                self.assertFalse((continued / "run/linking/rule-evaluation").exists())
                self.assertEqual(stage.read_bytes(), stage_bytes)
                self.assertFalse((original / "receipt.json").exists())
            finally:
                if parent.poll() is None:
                    os.killpg(parent.pid, signal.SIGKILL)
                    parent.communicate(timeout=5)
                if worker_pid is not None:
                    try:
                        os.killpg(worker_pid, 0)
                    except ProcessLookupError:
                        pass
                    else:
                        os.killpg(worker_pid, signal.SIGKILL)
                from gambit_smp.reasoning_history import read_execution_checkpoint
                audit = {"fixtureOnly": True, "prefix": read_execution_checkpoint(root, original),
                         "parentError": parent_error,
                         "childReceipt": json.loads((original / "run/receipt.json").read_text()) if (original / "run/receipt.json").exists() else None,
                         "launchLog": (original / "launch.log").read_text() if (original / "launch.log").exists() else None}
                encoded = json.dumps(audit, sort_keys=True, indent=2)
                archive = ROOT / ".cache/checkpoint-observations"
                archive.mkdir(parents=True, exist_ok=True)
                (archive / (hashlib.sha256(encoded.encode()).hexdigest() + ".json")).write_text(encoded)
