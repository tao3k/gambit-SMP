"""Archive/provenance controls; synthetic identities are not native acceptance."""
from copy import deepcopy
import hashlib
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.recipes import tree_identity
from gambit_smp.runtime_artifact import SCHEMA, checked_manifest, unpack, validate_import, export_deadline
from gambit_smp.step_checkpoint import content_id


def fixture(root):
    runtime = root / "original"
    runtime.mkdir()
    (runtime / "program").write_text("contract fixture, not a Gambit executable\n")
    (runtime / "program").chmod(0o755)
    (runtime / "alias").symlink_to("program")
    for name in ("include/gambit.h", "lib/makefile"):
        path = runtime / name
        path.parent.mkdir()
        path.write_text("synthetic configuration observation control\n")
    identity = '{"runtimeAdmitted":false}'
    rows = [
        {"id": "source", "capability": "gambit.materialize", "dependsOn": [], "outcome": "PASS",
         "arguments": {"sourceLock": "evidence/source.lock.json"},
         "outputs": {"source": {"type": "source-tree", "identity": {"original": {"sha256": "a" * 64}}}}},
        {"id": "configure", "capability": "gambit.configure", "dependsOn": ["source"], "outcome": "PASS",
         "effectiveConcurrency": {"smp": True, "multipleVMs": True, "multipleThreadedVMs": True},
         "arguments": {"source": {"step": "source", "output": "source"}}, "commands": [{
             "stage": "configure", "argv": ["./configure", "--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"],
             "log": "configure.log", "logSha256": hashlib.sha256(b"").hexdigest(),
             "stdoutPath": "configure.stdout", "stdoutSha256": hashlib.sha256(b"").hexdigest(),
             "stderrPath": "configure.stderr", "stderrSha256": hashlib.sha256(b"").hexdigest(),
             "exit": 0, "timeout": False, "parentReaped": True, "processGroupQuiescent": True}]},
        {"id": "seed", "capability": "gambit.seed-core", "dependsOn": ["configure"], "outcome": "PASS",
         "arguments": {"source": {"step": "configure", "output": "source"}},
         "claim": "pre-generated-C-seed-only", "outputs": {
             "runtime": {"type": "seed-runtime"}, "identity": {"type": "runtime-identity"}}},
        {"id": "core", "capability": "gambit.source-core", "dependsOn": ["seed"], "outcome": "PASS",
         "effectiveConcurrency": {"smp": True, "multipleVMs": True, "multipleThreadedVMs": True},
         "configurationFiles": {name: hashlib.sha256((runtime / name).read_bytes()).hexdigest()
                                for name in ("include/gambit.h", "lib/makefile")},
         "arguments": {"runtime": {"step": "seed", "output": "runtime"}},
         "claim": "source-regenerated-core-not-full-two-pass-bootstrap", "outputs": {
             "runtime": {"type": "source-runtime", "identity": tree_identity(runtime)},
             "identity": {"type": "runtime-identity", "sha256": hashlib.sha256(identity.encode()).hexdigest()}}}]
    engine = {"files": {"worker.py": "b" * 64}, "hostTools": {"gcc": {"sha256": "c" * 64}}}
    engine["engineId"] = content_id(engine)
    child = json.dumps({"schema": "evidence-recipe-run.v1", "recipe": "contract", "outcome": "PASS", "inputsStable": True, "steps": rows})
    outer = json.dumps({"schema": "sealed-research-run.v1", "executionLaunched": True, "recipe": "contract", "outcome": "PASS", "exit": 0, "timeout": False,
        "parentReaped": True, "processGroupQuiescent": True, "engineId": engine["engineId"],
        "budgetSeconds": 600, "wholeSeconds": 10, "inputs": {"evidence/source.lock.json": "d" * 64},
        "childReceiptSha256": hashlib.sha256(child.encode()).hexdigest()})
    proof = {"outerReceiptSha256": hashlib.sha256(outer.encode()).hexdigest(),
             "schema": "successful-step-checkpoint.v1", "campaignOutcome": "PASS",
             "runtimeAdmitted": False, "resumptionAuthorized": False,
             "childReceiptSha256": hashlib.sha256(child.encode()).hexdigest(), "step": "core",
             "engineId": engine["engineId"], "outputsContentId": content_id(rows[-1]["outputs"]),
             "ancestry": [{"id": row["id"], "observationContentId": content_id(row)} for row in rows]}
    return runtime, {"schema": SCHEMA, "checkpoint": proof, "outerReceipt": outer, "childReceipt": child,
        "engineManifest": engine, "compilerSha256": "c" * 64, "files": tree_identity(runtime),
        "sourceIdentity": rows[0]["outputs"]["source"]["identity"], "sourceLock": "evidence/source.lock.json",
        "sourceLockSha256": "d" * 64, "runtimeIdentity": json.loads(identity), "identityBytes": identity,
        "runtimeAdmitted": False, "resumptionAuthorized": False,
        "logs": {**{"run/configure/configure." + suffix: hashlib.sha256(b"").hexdigest()
                 for suffix in ("log", "stdout", "stderr")},
                 "receipt.json": hashlib.sha256(outer.encode()).hexdigest(),
                 "run/receipt.json": hashlib.sha256(child.encode()).hexdigest()}}


def pack(path, runtime, value, extra=None):
    with tarfile.open(path, "w", dereference=False) as archive:
        raw = json.dumps(value).encode()
        info = tarfile.TarInfo("manifest.json")
        info.size = len(raw)
        archive.addfile(info, io.BytesIO(raw))
        archive.add(runtime, arcname="runtime")
        for name in value["logs"]:
            raw = {"receipt.json": value["outerReceipt"], "run/receipt.json": value["childReceipt"]}.get(name, "").encode()
            info = tarfile.TarInfo("evidence/" + name)
            info.size = len(raw)
            archive.addfile(info, io.BytesIO(raw))
        if extra is not None:
            archive.addfile(extra)


class RuntimeArtifactContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.runtime, self.value = fixture(self.root)

    def test_same_generation_keeps_modes_links_receipts_and_false_admission(self):
        archive = self.root / "generation.tar"
        pack(archive, self.runtime, self.value)
        actual = unpack(archive, self.root / "restored")
        self.assertEqual(self.value, actual)
        self.assertEqual(tree_identity(self.runtime), tree_identity(self.root / "restored/runtime"))
        self.assertFalse(actual["runtimeAdmitted"])
        self.assertFalse(actual["resumptionAuthorized"])

    def test_changed_receipts_engine_source_and_compiler_rejected(self):
        for field, replacement in (("outerReceipt", "{}"), ("childReceipt", "{}"),
                                   ("sourceLockSha256", "e" * 64), ("compilerSha256", "e" * 64),
                                   ("sourceIdentity", {}), ("files", {}), ("runtimeAdmitted", True)):
            value = {**self.value, field: replacement}
            with self.subTest(field=field), self.assertRaises((ValueError, KeyError)):
                checked_manifest(value)

    def test_seed_is_not_promoted_by_changing_archive_label(self):
        value = deepcopy(self.value)
        value["checkpoint"]["step"] = "seed"
        with self.assertRaises(ValueError):
            checked_manifest(value)

    def test_added_deleted_changed_and_mode_drift_fail_closed(self):
        for variant in ("added", "deleted", "changed", "mode"):
            with self.subTest(variant=variant), tempfile.TemporaryDirectory() as name:
                root = Path(name)
                runtime, value = fixture(root)
                if variant == "added":
                    (runtime / "extra").write_text("unexpected")
                elif variant == "deleted":
                    (runtime / "alias").unlink()
                elif variant == "changed":
                    (runtime / "program").write_text("changed")
                else:
                    (runtime / "program").chmod(0o644)
                pack(root / "bad.tar", runtime, value)
                with self.assertRaises(ValueError):
                    unpack(root / "bad.tar", root / "out")

    def test_traversal_duplicate_hardlink_and_special_members_rejected(self):
        for name, kind in (("../escape", tarfile.REGTYPE), ("manifest.json", tarfile.REGTYPE),
                           ("runtime/hard", tarfile.LNKTYPE), ("runtime/device", tarfile.CHRTYPE)):
            with self.subTest(name=name):
                path = self.root / (str(kind) + str(len(name)) + ".tar")
                item = tarfile.TarInfo(name)
                item.type = kind
                item.linkname = "runtime/program" if kind == tarfile.LNKTYPE else ""
                pack(path, self.runtime, self.value, item)
                with self.assertRaises(ValueError):
                    unpack(path, self.root / ("out-" + str(kind) + str(len(name))))

    def test_only_declared_typed_archive_is_a_recipe_operand(self):
        value = {"source": {"step": "source", "output": "source"}, "archive": "evidence/runtime-input.json"}
        validate_import(value, ["evidence/runtime-input.json"])
        with self.assertRaises(ValueError):
            validate_import(value, [])
        with self.assertRaises(ValueError):
            validate_import({**value, "argv": ["tar", "xf"]}, ["evidence/runtime-input.json"])

    def test_export_cannot_reset_elapsed_gaps_or_cross_boot_identity(self):
        from gambit_smp.framework import digest
        header = {"clockEpoch": "boot-a", "startedMonotonic": 10, "deadlineMonotonic": 610,
                  "engineId": "fixture", "inputs": {}, "budgetSeconds": 600}
        path = self.root / "run-header.json"
        path.write_text(json.dumps(header))
        outer = {"engineId": "fixture", "inputs": {}, "budgetSeconds": 600,
                 "journal": {"path": str(path), "sha256": digest(path)}}
        with patch("gambit_smp.research_kernel.clock_epoch", return_value="boot-a"), \
             patch("gambit_smp.runtime_artifact.time.monotonic", return_value=609):
            self.assertEqual((10, 610), export_deadline(self.root, outer))
        with patch("gambit_smp.research_kernel.clock_epoch", return_value="boot-a"), \
             patch("gambit_smp.runtime_artifact.time.monotonic", return_value=611):
            with self.assertRaises(TimeoutError):
                export_deadline(self.root, outer)
        for boot in (None, "boot-b"):
            with patch("gambit_smp.research_kernel.clock_epoch", return_value=boot), self.assertRaises(ValueError):
                export_deadline(self.root, outer)
