"""Shared workspace custody/accounting, not SMP runtime admission."""
import json
import hashlib
import io
from pathlib import Path
import shutil
import subprocess
import tempfile
import tarfile
import time
import unittest

from gambit_smp.artifact_storage import adopt_source_archive, checked_workspace_state, quarantine_workspace, repair_interrupted_build_links, seal_workspace_state, workspace_lease
from gambit_smp.framework import digest
from gambit_smp.recipes import ExecutionContext, inspect_outputs, tree_identity
from gambit_smp.recipe_continuation import continuation_request, revalidate_continuation_request


class WorkspaceCustodyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        self.source = self.root / ".data/fixtures/current/source"
        self.source.mkdir(parents=True)
        (self.source / "unit.c").write_text("int x;\n")
        self.lock = self.root / "evidence/source.lock.json"
        self.lock.parent.mkdir()
        self.lock.write_text('{"revision":"fixed"}\n')

    def test_exclusive_lease_reuses_one_tree(self):
        identity = tree_identity(self.source)
        with workspace_lease(self.root, self.source, identity) as path:
            self.assertEqual(path, self.source)
            with self.assertRaisesRegex(ValueError, "already leased"):
                with workspace_lease(self.root, self.source, identity):
                    self.fail("two simultaneous owners")
        with workspace_lease(self.root, self.source, identity):
            pass

    def repair_input(self, quiescent=True):
        self.lock.write_text(json.dumps({"files": {"unit.c": {"candidateSha256": digest(self.source / "unit.c")}}}))
        receipt = self.root / "failed.json"
        receipt.write_text(json.dumps({"schema": "sealed-research-run.v1", "outcome": "DENY",
            "root": str(self.root), "parentReaped": True, "processGroupQuiescent": quiescent,
            "inputs": {self.lock.relative_to(self.root).as_posix(): digest(self.lock)}}))
        return receipt

    def test_interrupted_build_link_repair_keeps_source_and_inode(self):
        receipt = self.repair_input()
        link = self.source / "bin/gsc-script"
        link.parent.mkdir()
        link.symlink_to("../gsc/gsc")
        inode = self.source.stat().st_ino
        with self.assertRaises(ValueError):
            tree_identity(self.source)
        result = repair_interrupted_build_links(self.root, self.source, self.lock, receipt,
            digest(receipt), self.root / "evidence/repair.json")
        self.assertFalse(link.is_symlink())
        self.assertEqual(self.source.stat().st_ino, inode)
        self.assertEqual((self.source / "unit.c").read_text(), "int x;\n")
        self.assertFalse(result["historicalProgressReset"])

    def test_unknown_link_or_unquiescent_failure_cannot_repair(self):
        receipt = self.repair_input(False)
        link = self.source / "unknown-link"
        link.symlink_to("absent")
        with self.assertRaises(ValueError):
            repair_interrupted_build_links(self.root, self.source, self.lock, receipt,
                digest(receipt), self.root / "evidence/repair.json")
        receipt = self.repair_input(True)
        with self.assertRaises(ValueError):
            repair_interrupted_build_links(self.root, self.source, self.lock, receipt,
                digest(receipt), self.root / "evidence/repair.json")
        self.assertTrue(link.is_symlink())

    def test_lease_rejects_drift_and_outside_paths(self):
        original = tree_identity(self.source)
        (self.source / "unit.c").write_text("changed")
        with self.assertRaisesRegex(ValueError, "state differs"):
            with workspace_lease(self.root, self.source, original):
                self.fail("drift accepted")
        with self.assertRaisesRegex(ValueError, "fixture store"):
            with workspace_lease(self.root, self.root / "evidence", {}):
                pass

    def test_unquiesced_process_quarantine_survives_lease_release(self):
        identity = tree_identity(self.source)
        with workspace_lease(self.root, self.source, identity):
            quarantine_workspace(self.root, self.source, [{"pid": 1, "parentReaped": True,
                                                         "processGroupQuiescent": False}])
        with self.assertRaisesRegex(ValueError, "unquiesced"):
            with workspace_lease(self.root, self.source, identity):
                self.fail("unquiesced workspace reused")

    def test_real_executor_reuse_keeps_prior_state_and_checks_final_bytes(self):
        from gambit_smp.native_capabilities import clone
        out = self.source.parent
        initial = out / "materialize"
        initial.mkdir()
        receipt = {"recipe": "custody", "workspacePolicy": "in-place",
                   "inputs": {str(self.lock): digest(self.lock)}, "steps": []}
        context = ExecutionContext(self.root, out, initial, {}, time.monotonic() + 10, {}, receipt, {})
        first = context.publish("source", "source-tree", self.source)
        receipt["steps"].append({"id": "materialize", "outcome": "PASS", "outputs": first})
        next_directory = out / "configure"
        next_directory.mkdir()
        context = ExecutionContext(self.root, out, next_directory, {}, time.monotonic() + 10, {}, receipt, {})
        try:
            reused = clone(context, {"step": "materialize", "output": "source"}, "source-tree")
            self.assertEqual(reused, self.source)
            (reused / "unit.c").write_text("int configured;\n")
            second = context.publish("source", "configured-tree", reused)
        finally:
            context.workspace_leases.close()
        receipt["steps"].append({"id": "configure", "outcome": "PASS", "outputs": second})
        state = inspect_outputs(out, receipt["steps"], root=self.root)
        self.assertEqual([row["status"] for row in state["outputs"]], ["RETAINED", "AVAILABLE"])
        self.assertFalse((next_directory / "source").exists())
        (self.source / "unit.c").write_text("unreviewed mutation")
        self.assertEqual(inspect_outputs(out, receipt["steps"], root=self.root)["status"], "MODIFIED")

    def test_existing_pool_is_referenced_without_moving_or_copying(self):
        from gambit_smp.native_capabilities import clone
        out = self.root / ".data/fixtures/new-run"
        directory = out / "adopt"
        directory.mkdir(parents=True)
        receipt = {"recipe": "external-custody", "workspacePolicy": "in-place",
                   "inputs": {str(self.lock): digest(self.lock)}, "steps": []}
        context = ExecutionContext(self.root, out, directory, {}, time.monotonic() + 10, {}, receipt, {})
        inode = self.source.stat().st_ino
        try:
            context.lease_workspace(self.source, tree_identity(self.source))
            output = context.publish("source", "source-tree", self.source)
        finally:
            context.workspace_leases.close()
        receipt["steps"].append({"id": "adopt", "outcome": "PASS", "outputs": output})
        directory = out / "configure"
        directory.mkdir()
        context = ExecutionContext(self.root, out, directory, {}, time.monotonic() + 10, {}, receipt, {})
        try:
            self.assertEqual(clone(context, {"step": "adopt", "output": "source"}, "source-tree"), self.source)
            self.assertEqual(self.source.stat().st_ino, inode)
        finally:
            context.workspace_leases.close()
        self.assertFalse((directory / "source").exists())
        self.assertEqual(inspect_outputs(out, receipt["steps"], root=self.root)["status"], "AVAILABLE")

    def test_distinct_runs_with_same_recipe_do_not_collide_or_overwrite(self):
        references = []
        for run in ("producer", "consumer"):
            out = self.root / ".data/fixtures" / run / "run"
            directory = out / "source"
            directory.mkdir(parents=True)
            receipt = {"recipe": "shared-recipe", "workspacePolicy": "in-place",
                       "inputs": {str(self.lock): digest(self.lock)}, "steps": []}
            context = ExecutionContext(self.root, out, directory, {}, time.monotonic() + 10, {}, receipt, {})
            try:
                context.lease_workspace(self.source, tree_identity(self.source))
                references.append(context.publish("source", "source-tree", self.source)["source"]["stateEvidence"])
            finally:
                context.workspace_leases.close()
        self.assertNotEqual(references[0]["path"], references[1]["path"])
        for reference in references:
            self.assertTrue(reference["path"].startswith(".cache/research/workspace-states/"))
            self.assertEqual(digest(self.root / reference["path"]), reference["sha256"])
        self.assertFalse((self.root / "evidence/research/workspace-states").exists())

    def test_cached_state_loss_is_unknown_not_an_admitted_runtime(self):
        out = self.source.parent
        directory = out / "step"
        directory.mkdir()
        receipt = {"recipe": "cache-custody", "workspacePolicy": "in-place",
                   "inputs": {str(self.lock): digest(self.lock)}, "steps": []}
        context = ExecutionContext(self.root, out, directory, {}, time.monotonic() + 10, {}, receipt, {})
        outputs = context.publish("source", "source-tree", self.source)
        receipt["steps"].append({"id": "step", "outcome": "PASS", "outputs": outputs})
        (self.root / outputs["source"]["stateEvidence"]["path"]).unlink()
        self.assertEqual("UNKNOWN", inspect_outputs(out, receipt["steps"], root=self.root)["status"])
        self.assertTrue(self.source.is_dir())

    def archive(self, extra=None):
        archive = self.root / "archive.tar"
        entries = {"unit.c": b"int original;\n", "missing.c": b"int missing;\n"}
        entries.update(extra or {})
        with tarfile.open(archive, "w") as tree:
            for name, data in entries.items():
                member = tarfile.TarInfo(name)
                member.size, member.mode = len(data), 0o644
                tree.addfile(member, io.BytesIO(data))
        rows = {"unit.c": {"baseSha256": hashlib.sha256(entries["unit.c"]).hexdigest(),
                           "candidateSha256": digest(self.source / "unit.c")}}
        return archive, rows

    def test_adoption_fills_same_inode_and_clears_only_bound_cache(self):
        archive, rows = self.archive()
        cache = self.source / "generated.o"
        cache.write_bytes(b"diagnostic")
        inode = self.source.stat().st_ino
        adopt_source_archive(self.source, archive, rows, {"generated.o": digest(cache)})
        self.assertEqual(self.source.stat().st_ino, inode)
        self.assertEqual((self.source / "unit.c").read_text(), "int x;\n")
        self.assertEqual((self.source / "missing.c").read_text(), "int missing;\n")
        self.assertFalse(cache.exists())

    def test_adoption_removes_only_bound_cache_directories(self):
        archive, rows = self.archive()
        cache = self.source / "autom4te.cache/nested/trace"
        cache.parent.mkdir(parents=True)
        cache.write_bytes(b"diagnostic")
        adopt_source_archive(self.source, archive, rows,
                             {"autom4te.cache/nested/trace": digest(cache)})
        self.assertFalse((self.source / "autom4te.cache").exists())

    def test_cache_directory_unknown_child_denies_before_mutation(self):
        archive, rows = self.archive()
        cache = self.source / "autom4te.cache/trace"
        cache.parent.mkdir()
        cache.write_bytes(b"diagnostic")
        unknown = cache.parent / "user.scm"
        unknown.write_bytes(b"user source")
        with self.assertRaisesRegex(ValueError, "untracked workspace file"):
            adopt_source_archive(self.source, archive, rows,
                                 {"autom4te.cache/trace": digest(cache)})
        self.assertTrue(cache.exists())
        self.assertEqual(unknown.read_bytes(), b"user source")
        self.assertFalse((self.source / "missing.c").exists())

    def test_adoption_denies_unknown_edits_before_mutation(self):
        archive, rows = self.archive()
        unknown = self.source / "unknown.scm"
        unknown.write_text("user code")
        with self.assertRaisesRegex(ValueError, "untracked workspace file"):
            adopt_source_archive(self.source, archive, rows, {})
        self.assertEqual(unknown.read_text(), "user code")
        self.assertFalse((self.source / "missing.c").exists())

    def test_adoption_rejects_path_escape_and_source_as_cache(self):
        archive, rows = self.archive()
        with self.assertRaises(ValueError):
            adopt_source_archive(self.source, archive, rows, {"unit.c": digest(self.source / "unit.c")})
        archive, rows = self.archive({"../escape": b"bad"})
        with self.assertRaisesRegex(ValueError, "bounded paths"):
            adopt_source_archive(self.source, archive, rows, {})
        self.assertFalse((self.root / "escape").exists())

    def seal(self):
        return seal_workspace_state(self.root, self.source,
            self.root / "evidence/state.json", {"evidence/source.lock.json": digest(self.lock)})

    def test_cache_removal_preserves_state_not_runtime_admission(self):
        identity, reference = tree_identity(self.source), self.seal()
        shutil.rmtree(self.source)
        state = checked_workspace_state(self.root, reference, identity)
        self.assertTrue(state["recordedStateBound"])
        self.assertFalse(state["currentBytesEstablished"])
        self.assertFalse(state["runtimeAdmitted"])

    def test_explicit_git_archive_resolves_original_reference_without_changing_sha(self):
        reference = self.seal()
        identity = tree_identity(self.source)
        original = (self.root / reference["path"]).read_bytes()
        subprocess.run(["git", "-C", str(self.root), "add", "evidence"], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.root), "-c", "user.name=Storage Test",
                        "-c", "user.email=storage@example.invalid", "commit", "-qm", "record"],
                       check=True, capture_output=True)
        def git(*args):
            return subprocess.check_output(["git", "-C", str(self.root), *args], text=True).strip()
        revision = git("rev-parse", "HEAD")
        index = {"schema": "git-record-archive.v1", "revision": revision, "records": {
            reference["path"]: {"sha256": reference["sha256"],
                                "gitBlob": git("rev-parse", revision + ":" + reference["path"])}}}
        (self.root / "evidence/storage-history.json").write_text(json.dumps(index))
        (self.root / reference["path"]).unlink()
        state = checked_workspace_state(self.root, reference, identity)
        self.assertTrue(state["recordedStateBound"])
        self.assertFalse(state["runtimeAdmitted"])
        cache = self.root / ".cache/history/git" / reference["sha256"] / "record.json"
        self.assertEqual(original, cache.read_bytes())
        cache.unlink()
        self.assertEqual(state, checked_workspace_state(self.root, reference, identity))
        cache.write_text("not the original bytes")
        with self.assertRaisesRegex(ValueError, "cache changed"):
            checked_workspace_state(self.root, reference, identity)

    def test_all_migrated_repository_records_keep_pinned_git_bytes(self):
        from gambit_smp.artifact_storage import archived_record
        from gambit_smp.framework import ROOT
        index = json.loads((ROOT / "evidence/storage-history.json").read_bytes())
        self.assertEqual(54, sum(name.startswith("evidence/research/workspace-states/")
                                 for name in index["records"]))
        for name, row in index["records"].items():
            with self.subTest(path=name):
                raw = archived_record(ROOT, {"path": name, "sha256": row["sha256"]})
                self.assertEqual(row["sha256"], hashlib.sha256(raw).hexdigest())

    def test_state_cannot_be_overwritten_or_rebound(self):
        identity, reference = tree_identity(self.source), self.seal()
        with self.assertRaises(FileExistsError):
            self.seal()
        with self.assertRaisesRegex(ValueError, "match producer"):
            checked_workspace_state(self.root, reference, {})
        self.lock.write_text("changed")
        with self.assertRaisesRegex(ValueError, "input drift"):
            checked_workspace_state(self.root, reference, identity)

    def test_state_rejects_cache_inputs(self):
        with self.assertRaises(ValueError):
            seal_workspace_state(self.root, self.source, self.root / "evidence/state.json",
                                 {".data/fixtures/current/source/unit.c": digest(self.source / "unit.c")})

    def request(self, seconds=45):
        path = self.root / "evidence/attempt.json"
        path.write_text(json.dumps({"schema": "sealed-research-run.v1", "parentReaped": True,
            "processGroupQuiescent": True, "outcome": "DENY", "wholeSeconds": 10,
            "budgetSeconds": 60}))
        recipe = self.root / "evidence/recipe.json"
        recipe.write_text(json.dumps({"budgetSeconds": seconds}))
        return continuation_request(self.root, 60, [(path, digest(path))],
                                    "evidence/source.lock.json", "evidence/recipe.json")

    def test_request_is_bound_but_not_authorized(self):
        request = self.request()
        self.assertEqual(request["remainingSeconds"], 50)
        self.assertFalse(request["executionAuthorized"])
        self.assertEqual(request, revalidate_continuation_request(self.root, request))

    def test_request_rejects_expansion_and_post_review_drift(self):
        with self.assertRaisesRegex(ValueError, "remaining original budget"):
            self.request(51)
        request = self.request()
        self.lock.write_text("changed")
        with self.assertRaisesRegex(ValueError, "changed after review"):
            revalidate_continuation_request(self.root, request)
