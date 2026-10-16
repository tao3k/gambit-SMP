"""Actual custody/ledger I/O with opaque fixtures, not native SMP acceptance."""
import json
import os
from pathlib import Path
import shutil
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp.build_profile import read_profile
from gambit_smp.framework import ROOT, digest
from gambit_smp.recipe_continuation import continuation_request, initialize_budget_ledger, reserve_budget, settle_budget
from gambit_smp.recipes import ExecutionContext, tree_identity
from gambit_smp.research_kernel import retain_run_record
from gambit_smp.step_checkpoint import import_seed, observe_journal


class StageCheckpointPipelineTests(unittest.TestCase):
    def test_journal_settlement_and_same_workspace_consumption(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            evidence = root / "evidence"
            evidence.mkdir()
            lock = evidence / "source.lock.json"
            lock.write_text('{"fixture":"opaque; not a native source lock"}')
            profile = evidence / "profile.json"
            shutil.copy2(ROOT / "evidence/fixtures/gerbil-bazel-build-profile/profile.json", profile)
            compiler = root / "compiler-fixture"
            compiler.write_bytes(b"opaque compiler identity; never executed")
            origin = evidence / "original.json"
            origin.write_text(json.dumps({"schema": "sealed-research-run.v1", "outcome": "DENY",
                "wholeSeconds": 10, "budgetSeconds": 60, "parentReaped": True,
                "processGroupQuiescent": True}))
            originals = [(origin, digest(origin))]
            ledger = initialize_budget_ledger(root, 60, originals)

            def request(name):
                recipe = evidence / (name + ".json")
                recipe.write_text('{"budgetSeconds":20}')
                return continuation_request(root, 60, originals, "evidence/source.lock.json",
                                            recipe.relative_to(root).as_posix())

            producer_reservation = reserve_budget(root, ledger, request("producer"), "producer")
            run = root / ".data/fixtures/producer"
            out = run / "run"
            out.mkdir(parents=True)
            workspace = root / ".data/fixtures/workspace"
            workspace.mkdir()
            (workspace / "source.scm").write_text("opaque source fixture")
            inputs = {"evidence/source.lock.json": digest(lock), "evidence/profile.json": digest(profile)}
            header = {"schema": "research-run-header.v1", "runId": "fixture-run", "recipe": "producer",
                      "engineId": "fixture-engine", "inputs": inputs}
            journal = retain_run_record(root, run / "run-header.json", "pipeline-fixture", header, inputs)
            receipt = {"recipe": "producer", "workspacePolicy": "in-place", "steps": [],
                       "inputs": {str(root / name): value for name, value in inputs.items()}}
            references = {}
            for name, capability, dependency in (("source", "gambit.materialize", None),
                                                  ("configure", "gambit.configure", "source"),
                                                  ("seed", "gambit.seed-core", "configure")):
                directory = out / name
                directory.mkdir()
                context = ExecutionContext(root, out, directory, os.environ,
                    time.monotonic() + 10, {}, receipt, {"gcc": str(compiler)})
                try:
                    context.lease_workspace(workspace, tree_identity(workspace))
                    if name == "configure":
                        (workspace / "configured.dat").write_text("opaque configuration")
                    if name == "seed":
                        (workspace / "object.dat").write_text("opaque object; not executable")
                        identity = directory / "identity.json"
                        identity.write_text('{"fixture":"not a runtime identity"}')
                        outputs = {**context.publish("runtime", "seed-runtime", workspace),
                                   **context.publish("identity", "runtime-identity", identity)}
                        arguments = {"source": {"step": dependency, "output": "source"}}
                    else:
                        outputs = context.publish("source", "source-tree" if name == "source" else "configured-tree", workspace)
                        arguments = ({"sourceLock": "evidence/source.lock.json"} if name == "source" else
                                     {"source": {"step": dependency, "output": "source"}, "buildProfile": "evidence/profile.json"})
                finally:
                    context.workspace_leases.close()
                row = {"id": name, "capability": capability, "outcome": "PASS", "outputs": outputs,
                       "dependsOn": [dependency] if dependency else [], "arguments": arguments}
                if name == "configure":
                    row.update(buildProfile=read_profile(profile), commands=[{"stage": "configure",
                        "argv": read_profile(profile)["flags"], "exit": 0, "timeout": False,
                        "parentReaped": True, "processGroupQuiescent": True}])
                if name == "seed":
                    row["claim"] = "pre-generated-C-seed-only"
                receipt["steps"].append(row)
                record = {"schema": "research-step-observation.v1", "runId": header["runId"],
                          "header": journal, "step": row, "toolInputs": {str(compiler): digest(compiler)},
                          "dependencies": {dependency: references[dependency]} if dependency else {}}
                references[name] = retain_run_record(root, out / (name + ".observation.json"),
                                                     "pipeline-fixture", record, receipt["inputs"])
            engine = root / "engine"
            engine.mkdir()
            outer = {"schema": "sealed-research-run.v1", "outcome": "DENY", "root": str(root),
                     "recipe": "producer", "engine": str(engine), "engineId": "fixture-engine", "journal": journal,
                     "inputs": inputs, "executionLaunched": True, "parentReaped": True,
                     "processGroupQuiescent": True, "budgetSeconds": 20, "wholeSeconds": 2,
                     "budgetReservation": producer_reservation}
            outer_path = run / "receipt.json"
            outer_path.write_text(json.dumps(outer))
            settle_budget(root, producer_reservation, outer_path, digest(outer_path))
            manifest = {"engineId": "fixture-engine", "hostTools": {"gcc": {"sha256": digest(compiler)}}}
            with patch("gambit_smp.research_kernel.manifest_paths", return_value=manifest):
                proof, _, _, _ = observe_journal(root, run, "seed")
                reference = evidence / "checkpoint.json"
                reference.write_text(json.dumps({"schema": "seed-step-checkpoint-reference.v2",
                                                  "checkpoint": proof, "ledger": ledger}))
                continuation = request("consumer")
                reservation = reserve_budget(root, ledger, continuation, "consumer")
                consumer_out = root / ".data/fixtures/consumer/run"
                consumer_dir = consumer_out / "seed"
                consumer_dir.mkdir(parents=True)
                consumer_receipt = {"recipe": "consumer", "workspacePolicy": "in-place", "budgetSeconds": 20,
                    "budgetReservation": reservation, "continuation": continuation, "inputs": receipt["inputs"], "steps": []}
                context = ExecutionContext(root, consumer_out, consumer_dir, os.environ, time.monotonic() + 10,
                                           {}, consumer_receipt, {"gcc": str(compiler)})
                try:
                    context.lease_workspace(workspace, receipt["steps"][-1]["outputs"]["runtime"]["identity"])
                    source_output = context.publish("source", "source-tree", workspace)
                    context.workspace_leases.close()
                    context.leased_workspaces.clear()
                    consumer_receipt["steps"].append({"id": "source", "outcome": "PASS", "outputs": source_output,
                        "capability": "gambit.materialize", "arguments": {"sourceLock": "evidence/source.lock.json"}})
                    inode = workspace.stat().st_ino
                    result = import_seed({"source": {"step": "source", "output": "source"},
                        "checkpoint": "evidence/checkpoint.json", "buildProfile": "evidence/profile.json"}, context)
                    self.assertEqual(workspace.stat().st_ino, inode)
                    self.assertEqual(result["storageTransfer"]["copiedFiles"], 0)
                    self.assertEqual(result["cumulativeExpenditure"]["producerChargedSeconds"], 2)
                    self.assertFalse(result["runtimeAdmitted"])
                    self.assertFalse((out / "receipt.json").exists())
                finally:
                    context.workspace_leases.close()
