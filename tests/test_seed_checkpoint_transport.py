"""Opaque artifact transport controls, never fake compiler/runtime acceptance."""
import copy
import json
import os
from pathlib import Path
import shutil
import tempfile
import time
import subprocess
import unittest
from unittest.mock import patch

from gambit_smp.build_profile import read_profile
from gambit_smp.framework import ROOT, digest
from gambit_smp.recipes import ExecutionContext, tree_identity
from gambit_smp.step_checkpoint import import_seed, seed_ancestry, expenditures, validate_seed_reference


class SeedCheckpointTransportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        self.out = self.root / "out"
        directory = self.out / "checkpoint"
        directory.mkdir(parents=True)
        self.source = self.out / "source/tree"
        self.source.mkdir(parents=True)
        (self.source / "unit.scm").write_text("opaque source bytes")
        self.run = self.root / ".data/fixtures/producer"
        self.runtime = self.run / "run/seed/runtime"
        self.runtime.mkdir(parents=True)
        (self.runtime / "opaque.dat").write_text("opaque compiler output, not an executable")
        self.identity = self.run / "run/seed/identity.json"
        self.identity.write_text("{}")
        for path in (self.run / "receipt.json", self.run / "run/receipt.json"):
            path.write_text("{}")
        self.profile_name = "evidence/profile.json"
        profile_path = self.root / self.profile_name
        profile_path.parent.mkdir()
        shutil.copy2(ROOT / "evidence/fixtures/gerbil-bazel-build-profile/profile.json", profile_path)
        self.reference_name = "evidence/checkpoint.json"
        self.proof = {"run": "producer", "outerReceiptSha256": "a" * 64}
        self.reference = {"schema": "seed-step-checkpoint-reference.v1", "checkpoint": self.proof,
                          "expenditures": [{"run": "producer", "sha256": "a" * 64}]}
        (self.root / self.reference_name).write_text(json.dumps(self.reference))
        self.compiler = self.root / "compiler-identity"
        self.compiler.write_text("opaque compiler identity")
        receipt = {"steps": [], "budgetSeconds": 20}
        self.ctx = ExecutionContext(self.root, self.out, directory, os.environ,
            time.monotonic() + 30, {}, receipt, {"gcc": str(self.compiler)})
        descriptor = self.ctx.publish("source", "source-tree", self.source)
        receipt["steps"].append({"id": "source", "outcome": "PASS", "outputs": descriptor})
        self.args = {"source": {"step": "source", "output": "source"},
                     "checkpoint": self.reference_name, "buildProfile": self.profile_name}
        self.materialized = {"outputs": {"source": {"identity": tree_identity(self.source)}}}
        self.configured = {"arguments": {"buildProfile": self.profile_name},
            "buildProfile": read_profile(profile_path),
            "commands": [{"stage": "configure", "argv": read_profile(profile_path)["flags"]}]}
        self.seed = {"outputs": {"runtime": {"type": "seed-runtime", "path": "seed/runtime",
                                              "identity": tree_identity(self.runtime)},
                                   "identity": {"type": "runtime-identity", "path": "seed/identity.json",
                                                "sha256": digest(self.identity)}}}
        self.ledger = {"remainingSeconds": 30}
        self.observed = (self.proof, {"outcome": "DENY"}, [], self.seed,
                         {"hostTools": {"gcc": {"sha256": digest(self.compiler)}}})

    def decoded(self):
        return self.observed, self.configured, self.materialized, self.ledger

    def invoke(self):
        with patch("gambit_smp.step_checkpoint.seed_reference", return_value=self.decoded()):
            return import_seed(self.args, self.ctx)

    def test_actual_context_copy_does_not_upgrade_failed_parent_or_seed_type(self):
        result = self.invoke()
        self.assertEqual("DENY", result["campaignOutcome"])
        self.assertEqual("seed-runtime", result["outputs"]["runtime"]["type"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertFalse(result["resumptionAuthorized"])
        self.assertEqual("opaque compiler output, not an executable",
                         (self.ctx.directory / "runtime/opaque.dat").read_text())
        self.assertNotEqual((self.runtime / "opaque.dat").stat().st_ino,
                            (self.ctx.directory / "runtime/opaque.dat").stat().st_ino)
        json.dumps({"result": result, "receipt": self.ctx.receipt})

    def test_original_remaining_budget_cannot_be_reset(self):
        self.ctx.receipt["budgetSeconds"] = 31
        with self.assertRaisesRegex(ValueError, "budget"):
            self.invoke()
        self.assertFalse((self.ctx.directory / "runtime").exists())

    def fresh_progress_reference(self):
        self.reference.update(schema="seed-step-checkpoint-reference.v3", timerPolicy={
            "mode": "progress", "scope": "fresh-stage", "expenditureRole": "history-only"})
        (self.root / self.reference_name).write_text(json.dumps(self.reference))
        self.ctx.receipt["timeoutPolicy"] = {"mode": "progress"}
        self.ctx.receipt["budgetSeconds"] = 300
        self.ledger = {"controlRole": "history-only", "spentSeconds": 444}

    def test_fresh_progress_stage_reuses_seed_without_subtracting_historical_wall_time(self):
        self.fresh_progress_reference()
        validate_seed_reference(self.reference)
        result = self.invoke()
        self.assertEqual(444, result["cumulativeExpenditure"]["spentSeconds"])
        self.assertEqual("history-only", result["cumulativeExpenditure"]["controlRole"])
        self.assertEqual("DENY", result["campaignOutcome"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertFalse(result["resumptionAuthorized"])

    def test_progress_history_cannot_replace_reserved_or_wall_control(self):
        self.fresh_progress_reference()
        for key, value in (("timeoutPolicy", {"mode": "wall"}),
                           ("budgetReservation", {"reserved": True}),
                           ("continuation", {"resume": True})):
            before = self.ctx.receipt.get(key)
            self.ctx.receipt[key] = value
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, "reserved or wall"):
                self.invoke()
            if before is None:
                self.ctx.receipt.pop(key)
            else:
                self.ctx.receipt[key] = before

    def test_history_keeps_exhausted_receipt_without_upgrading_its_failure(self):
        receipt = self.run / "receipt.json"
        receipt.write_text(json.dumps({"schema": "sealed-research-run.v1", "recipe": "original",
            "outcome": "DENY", "parentReaped": True, "processGroupQuiescent": True,
            "budgetSeconds": 300, "wholeSeconds": 444, "prior": None,
            "timeoutPolicy": {"mode": "progress"}}))
        sha = digest(receipt)
        checkpoint = {"outerReceiptSha256": sha}
        records = [{"run": "producer", "sha256": sha}]
        with self.assertRaisesRegex(TimeoutError, "cumulative"):
            expenditures(self.root, checkpoint, records)
        history = expenditures(self.root, checkpoint, records, historical_only=True)
        self.assertEqual("history-only", history["controlRole"])
        self.assertEqual(444, history["spentSeconds"])
        self.assertEqual("DENY", history["observations"][0]["outcome"])
        self.assertFalse(history["producerAdmitted"])
        self.assertEqual(sha, digest(receipt))

    def in_place(self):
        self.root = self.root.resolve()
        self.runtime = self.runtime.resolve()
        self.source = self.runtime
        self.ctx.root, self.ctx.out = self.root, self.out.resolve()
        self.ctx.directory = self.ctx.directory.resolve()
        self.ctx.receipt["workspacePolicy"] = "in-place"
        self.ctx.receipt["recipe"] = "transport-fixture"
        self.ctx.receipt["inputs"] = {str(self.root / self.profile_name): digest(self.root / self.profile_name)}
        self.ctx.receipt["steps"] = []
        descriptor = {"type": "source-tree", "path": "source.json",
                      "workspace": self.source.relative_to(self.root).as_posix(),
                      "identity": tree_identity(self.source)}
        marker = self.ctx.out / "source.json"
        marker.write_text(json.dumps({"schema": "managed-workspace-location.v1",
                                      "workspace": descriptor["workspace"]}))
        descriptor["locationSha256"] = digest(marker)
        self.ctx.receipt["steps"].append({"id": "source", "outcome": "PASS",
            "capability": "gambit.materialize", "arguments": {"sourceLock": "evidence/current.lock.json"},
            "outputs": {"source": descriptor}})
        self.materialized["arguments"] = {"sourceLock": "evidence/current.lock.json"}
        self.addCleanup(self.ctx.workspace_leases.close)

    def test_in_place_seed_reuses_one_inode_without_copy(self):
        self.in_place()
        inode = self.source.stat().st_ino
        with patch("gambit_smp.artifact_storage.transfer_tree", side_effect=AssertionError("copy forbidden")):
            result = self.invoke()
        self.assertEqual(result["storageTransfer"]["copiedFiles"], 0)
        self.assertEqual(self.source.stat().st_ino, inode)
        self.assertFalse((self.ctx.directory / "runtime").exists())
        self.assertEqual(result["outputs"]["runtime"]["type"], "seed-runtime")
        self.assertFalse(result["runtimeAdmitted"])

    def test_in_place_source_lock_mismatch_rejects(self):
        self.in_place()
        self.materialized["arguments"]["sourceLock"] = "evidence/other.lock.json"
        with self.assertRaisesRegex(ValueError, "source lock"):
            self.invoke()

    def test_changed_compiler_profile_source_and_missing_flag_deny_before_copy(self):
        for name in ("compiler", "profile", "source", "flag"):
            with self.subTest(name=name):
                configured, materialized, observed = copy.deepcopy((self.configured, self.materialized, self.observed))
                if name == "compiler":
                    observed[4]["hostTools"]["gcc"]["sha256"] = "0" * 64
                elif name == "profile":
                    configured["buildProfile"]["cflags"] = "different"
                elif name == "source":
                    materialized["outputs"]["source"]["identity"] = {}
                else:
                    configured["commands"][0]["argv"].remove("--enable-multiple-threaded-vms")
                with patch("gambit_smp.step_checkpoint.seed_reference",
                           return_value=(observed, configured, materialized, self.ledger)), self.assertRaises(ValueError):
                    import_seed(self.args, self.ctx)
                self.assertFalse((self.ctx.directory / "runtime").exists())

    def test_changed_copied_bytes_are_rejected(self):
        from gambit_smp.artifact_storage import transfer_tree

        def changed_copy(source, target):
            observation = transfer_tree(source, target)
            (target / "opaque.dat").write_text("changed")
            return observation

        with patch("gambit_smp.artifact_storage.transfer_tree", side_effect=changed_copy), self.assertRaises(ValueError):
            self.invoke()

    def test_parent_or_ledger_drift_during_copy_is_rejected(self):
        first = self.decoded()
        second_observation = copy.deepcopy(self.observed)
        second_observation[0]["outerReceiptSha256"] = "b" * 64
        with patch("gambit_smp.step_checkpoint.seed_reference",
                   side_effect=[first, (second_observation, self.configured, self.materialized, self.ledger)]), self.assertRaises(ValueError):
            import_seed(self.args, self.ctx)


class SeedCheckpointTypeTests(unittest.TestCase):
    def test_full_runtime_or_missing_config_is_not_a_seed_certificate(self):
        row = {"id": "seed", "capability": "gambit.bootstrap", "outputs": {
            "runtime": {"type": "source-runtime"}, "identity": {"type": "runtime-identity"}}}
        with self.assertRaises(ValueError):
            seed_ancestry([row])


if __name__ == "__main__":
    unittest.main()
