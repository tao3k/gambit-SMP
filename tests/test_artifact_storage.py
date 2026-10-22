import ctypes
import errno
from pathlib import Path
import tempfile
import subprocess
import sqlite3
import unittest
from unittest.mock import patch

from gambit_smp.artifact_storage import clone_file, transfer_generation, transfer_tree
from gambit_smp.artifact_storage import cache_path, runtime_output
from gambit_smp.artifact_storage import database_path, migrate_database, fixture_name, fixture_path
from gambit_smp.artifact_storage import fixture_root, observation_root


class ArtifactStorageTests(unittest.TestCase):
    def repository(self, directory):
        root = Path(directory).resolve()
        subprocess.run(["git", "init", "-q", str(root)], check=True, capture_output=True)
        return root

    def test_database_migration_preserves_pending_rows_and_original(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            old = root / ".data/state.sqlite"
            old.parent.mkdir()
            db = sqlite3.connect(old)
            db.execute("CREATE TABLE requests (id TEXT, result TEXT)")
            db.execute("INSERT INTO requests VALUES ('pending', NULL)")
            db.commit()
            db.close()
            before = old.read_bytes()
            with self.assertRaisesRegex(ValueError, "explicit cache migration"):
                database_path(root, "state.sqlite", ".data/state.sqlite")
            target = migrate_database(root, "state.sqlite", ".data/state.sqlite")
            self.assertEqual(root / ".cache/state.sqlite", target)
            copied = sqlite3.connect(target)
            self.addCleanup(copied.close)
            self.assertEqual([("pending", None)], copied.execute("SELECT * FROM requests").fetchall())
            self.assertEqual(before, old.read_bytes())
            self.assertEqual(target, database_path(root, "state.sqlite", ".data/state.sqlite"))
            with self.assertRaises(ValueError):
                migrate_database(root, "state.sqlite", ".data/state.sqlite")

    def test_active_database_writer_prevents_migration_and_empty_reset(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            old = root / ".data/state.sqlite"
            old.parent.mkdir()
            db = sqlite3.connect(old)
            db.execute("CREATE TABLE state (value TEXT)")
            db.commit()
            db.execute("BEGIN IMMEDIATE")
            try:
                with self.assertRaises(sqlite3.OperationalError):
                    migrate_database(root, "state.sqlite", ".data/state.sqlite")
            finally:
                db.rollback()
                db.close()
            self.assertFalse((root / ".cache/state.sqlite").exists())
            self.assertFalse((root / ".cache/state.sqlite.migrating").exists())

    def test_fixture_references_keep_old_names_and_bind_new_cache_explicitly(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            for name in (".cache/fixtures/run", ".data/fixtures/run"):
                path = root / name
                path.mkdir(parents=True)
                ref = fixture_name(root, path)
                self.assertEqual(name if name.startswith(".cache") else "run", ref)
                self.assertEqual(path, fixture_path(root, ref))
            for name in ("../escape", ".cache/fixtures/../../src"):
                with self.subTest(name=name), self.assertRaises(ValueError):
                    fixture_path(root, name)

    def test_local_cache_path_does_not_create_evidence_or_require_reproduction(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            path = cache_path(root, "ascent/queries/run")
            self.assertEqual(root / ".cache/ascent/queries/run", path)
            self.assertFalse(path.exists())
            self.assertFalse((root / "evidence").exists())
            for name in ("../evidence", "/tmp/escape", "."):
                with self.subTest(name=name), self.assertRaises(ValueError):
                    cache_path(root, name)

    def test_receipt_cache_roundtrip_does_not_expand_source_workspace_boundary(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            run = root / ".cache/research-observations/bootstrap"
            run.mkdir(parents=True)
            self.assertEqual(root / ".cache", observation_root(root, run))
            self.assertEqual(".cache/research-observations/bootstrap", fixture_name(root, run))
            self.assertEqual(run, fixture_path(root, fixture_name(root, run)))
            with self.assertRaisesRegex(ValueError, "fixture store"):
                fixture_root(root, run)
            for path in (root / ".cache", root / "evidence/run", root.parent / "outside"):
                with self.subTest(path=path), self.assertRaises(ValueError):
                    observation_root(root, path)

    def test_in_place_receipt_root_does_not_depend_on_disposable_data_directory(self):
        import json
        from gambit_smp.framework import digest
        from gambit_smp.artifact_storage import seal_workspace_state
        from gambit_smp.recipes import tree_identity, inspect_run
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            source = root / "evidence/source.c"
            source.parent.mkdir()
            source.write_text("source fixture")
            run = root / ".cache/run"
            workspace = run / "workspace"
            workspace.mkdir(parents=True)
            (workspace / "generated.c").write_text("generated fixture")
            state = seal_workspace_state(root, workspace,
                root / ".cache/research/workspace-states/unit.json", {"evidence/source.c": digest(source)})
            tools = run / "tools.json"
            tools.write_text("{}")
            receipt = {"schema": "evidence-recipe-run.v1", "recipe": "fixture", "outcome": "DENY",
                "workspacePolicy": "in-place", "inputs": {str(source): digest(source)},
                "toolInputs": {"path": "tools.json", "sha256": digest(tools)},
                "steps": [{"id": "source", "outputs": {"source": {
                    "path": "workspace", "type": "source-tree", "identity": tree_identity(workspace),
                    "stateEvidence": state}}}]}
            (run / "receipt.json").write_text(json.dumps(receipt))
            self.assertFalse((root / ".data").exists())
            result = inspect_run(run)
            self.assertEqual(result["identityStatus"], "CURRENT")
            self.assertEqual(result["evidenceBindingStatus"], "CURRENT")
            self.assertEqual(result["recordedOutcome"], "DENY")

    def test_cache_alias_cannot_write_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            (root / "evidence").mkdir()
            (root / ".cache").symlink_to("evidence", target_is_directory=True)
            with self.assertRaisesRegex(ValueError, "alias"):
                cache_path(root, "run")
            with self.assertRaisesRegex(ValueError, "cache alias"):
                runtime_output(root, root / ".cache/run")
            with self.assertRaises(ValueError):
                observation_root(root, root / ".cache/run")

    def test_stale_custody_does_not_erase_material_observation_or_grant_reuse(self):
        from gambit_smp.framework import digest
        from gambit_smp.artifact_storage import seal_workspace_state
        from gambit_smp.recipes import inspect_outputs, tree_identity
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            source = root / "evidence/source.c"
            source.parent.mkdir()
            source.write_text("original source")
            run = root / ".cache/run"
            workspace = run / "workspace"
            workspace.mkdir(parents=True)
            generated = workspace / "generated.c"
            generated.write_text("generated fixture")
            state = seal_workspace_state(root, workspace,
                root / ".cache/research/workspace-states/unit.json",
                {"evidence/source.c": digest(source)})
            steps = [{"id": "source", "outputs": {"source": {
                "path": "workspace", "identity": tree_identity(workspace),
                "stateEvidence": state}}}]
            source.write_text("changed source")
            for expected, action in (
                ("AVAILABLE", lambda: None),
                ("MODIFIED", lambda: generated.write_text("changed material")),
                ("MISSING", lambda: (generated.unlink(), workspace.rmdir())),
            ):
                with self.subTest(material=expected):
                    action()
                    result = inspect_outputs(run, steps, root=root)
                    self.assertEqual(result["status"], "UNKNOWN")
                    row = result["outputs"][0]
                    self.assertEqual(row["status"], "UNKNOWN")
                    self.assertEqual(row["materialStatus"], expected)
                    self.assertEqual(row["custodyStatus"], "UNVERIFIED")

    def test_runtime_outputs_stay_outside_git_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            for name in (".cache/graph", ".cache/ci/artifact"):
                self.assertEqual(root / name, runtime_output(root, root / name))
            for name in (".", ".data/new-run", ".ci/new-run", "evidence/run", "src/run", "docs/graph", ".git/run", "accidental-log"):
                with self.subTest(name=name), self.assertRaisesRegex(ValueError, "runtime output"):
                    runtime_output(root, root / name)
            self.assertEqual(root.parent / "external-run", runtime_output(root, root.parent / "external-run"))

    def test_ascent_cli_rejects_git_outputs_before_query_or_execution(self):
        from gambit_smp import agent_context, ascent_review, evidence_index, review_validation
        cases = ((agent_context, ["--model", "control"]), (ascent_review, []),
                 (evidence_index, ["--validate"]), (review_validation, []))
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            from gambit_smp import workspace
            workspace.git(root,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','--allow-empty','-qm','policy')
            workspace.start(root,'artifact-policy',adopt=True)
            for module, args in cases:
                target = root / "evidence/unpublished-run"
                with self.subTest(module=module.__name__), \
                     patch.object(module, "ROOT", root, create=True), \
                     patch.object(evidence_index, "ROOT", root), \
                     patch("gambit_smp.framework.project_root",return_value=root), \
                     patch("gambit_smp.task_dependencies.default_task",return_value="artifact-policy"), \
                     patch("sys.argv", [module.__name__, *args, "--out", str(target)]), \
                     self.assertRaisesRegex(ValueError, "runtime output"):
                    module.main()
                self.assertFalse(target.exists())
                workspace.resume(root,"artifact-policy")

    def test_cache_root_is_git_toplevel_not_selected_subdirectory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(directory)
            nested = root / "src/deep"
            nested.mkdir(parents=True)
            expected = root / ".cache/ascent/run"
            self.assertEqual(expected, cache_path(root, "ascent/run"))
            with patch.dict("os.environ", {"GIT_WORK_TREE": str(nested), "GIT_DIR": str(root / ".git")}):
                self.assertEqual(expected, cache_path(nested, "ascent/run"))
            self.assertEqual(expected, runtime_output(nested, ".cache/ascent/run"))
            with self.assertRaisesRegex(ValueError, "runtime output"):
                runtime_output(nested, root / "evidence/log")

    def test_nested_repository_owns_its_cache_not_outer_project(self):
        with tempfile.TemporaryDirectory() as directory:
            outer = self.repository(directory)
            inner = outer / ".data/consumer"
            inner.mkdir(parents=True)
            self.repository(inner)
            self.assertEqual(inner / ".cache/run", cache_path(inner, "run"))
            self.assertEqual(outer / ".cache/run", cache_path(outer, "run"))

    def test_no_git_repository_does_not_fall_back_to_cwd_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(subprocess.CalledProcessError):
                cache_path(directory, "run")

    def test_linked_worktree_uses_its_own_git_toplevel(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(Path(directory) / "primary")
            subprocess.run(["git", "-C", str(root), "-c", "user.name=Storage Test",
                            "-c", "user.email=storage@example.invalid", "commit",
                            "--allow-empty", "-qm", "storage test"], check=True, capture_output=True)
            linked = Path(directory).resolve() / "linked"
            subprocess.run(["git", "-C", str(root), "worktree", "add", "--detach", str(linked)],
                           check=True, capture_output=True)
            self.assertEqual(linked / ".cache/run", cache_path(linked, "run"))
            self.assertEqual(root / ".cache/run", cache_path(root, "run"))

    def test_declared_cache_cannot_alias_an_external_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.repository(Path(directory) / "repo")
            external = Path(directory).resolve() / "external"
            external.mkdir()
            (root / ".cache").symlink_to(external, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, "cache alias"):
                runtime_output(root, ".cache/query")
            self.assertEqual(external / "query", runtime_output(root, external / "query"))

    def test_generation_source_symlink_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "bytes").write_bytes(b"generation")
            (root / "source").symlink_to("bytes")
            with self.assertRaises(ValueError):
                transfer_generation(root / "source", root / "target")
            self.assertFalse((root / "target").exists())

    def test_generation_target_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.write_bytes(b"new")
            target.write_bytes(b"retained")
            with self.assertRaises(FileExistsError):
                transfer_generation(source, target)
            self.assertEqual(b"retained", target.read_bytes())

    def test_generation_permission_error_does_not_fall_back(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.write_bytes(b"generation")
            with patch("gambit_smp.artifact_storage.os.link", side_effect=PermissionError(errno.EACCES, "denied")), patch("gambit_smp.artifact_storage.shutil.copyfile") as copy:
                with self.assertRaises(PermissionError):
                    transfer_generation(source, target)
                copy.assert_not_called()

    def test_actual_transfer_preserves_bytes_without_shared_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source.mkdir()
            (source / "file").write_bytes(b"producer")
            (source / "link").symlink_to("file")
            target = root / "consumer"
            receipt = transfer_tree(source, target)
            self.assertEqual(b"producer", (target / "file").read_bytes())
            self.assertTrue((target / "link").is_symlink())
            self.assertNotEqual((source / "file").stat().st_ino, (target / "file").stat().st_ino)
            (target / "file").write_bytes(b"consumer")
            self.assertEqual(b"producer", (source / "file").read_bytes())
            self.assertEqual(1, sum(receipt["files"].values()))
            self.assertFalse(receipt["hardlinks"])
            self.assertEqual(len(b"producer"), receipt["logicalBytes"])

    def test_empty_runtime_view_can_receive_an_isolated_copy(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.mkdir()
            target.mkdir()
            (source / "file").write_bytes(b"data")
            transfer_tree(source, target, dirs_exist_ok=True)
            self.assertEqual(b"data", (target / "file").read_bytes())

    def test_populated_workspace_is_rejected_without_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.mkdir()
            target.mkdir()
            (source / "file").write_bytes(b"new")
            (target / "file").write_bytes(b"retained")
            with self.assertRaisesRegex(ValueError, "populated workspace"):
                transfer_tree(source, target, dirs_exist_ok=True)
            self.assertEqual(b"retained", (target / "file").read_bytes())

    def test_overlapping_trees_and_destination_links_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source"
            source.mkdir()
            link = Path(directory) / "link"
            link.symlink_to(source, target_is_directory=True)
            for target in (source, source / "child", link, source.parent):
                with self.subTest(target=target), self.assertRaises(ValueError):
                    transfer_tree(source, target, dirs_exist_ok=True)

    @unittest.skipUnless(__import__('sys').platform == 'darwin', 'real APFS clone')
    def test_native_clone_preserves_modes_times_and_independent_mutation(self):
        import os
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / 'source', Path(directory) / 'target'
            source.write_bytes(b'original'); source.chmod(0o751)
            os.utime(source, ns=(1_700_000_000_123_456_789, 1_700_000_000_987_654_321))
            expected = source.stat()
            with patch('gambit_smp.artifact_storage.shutil.copystat', wraps=__import__('shutil').copystat) as metadata:
                mode = clone_file(source, target)
                if mode == 'copy-on-write':metadata.assert_not_called()
            actual = target.stat()
            self.assertEqual(expected.st_mode, actual.st_mode)
            self.assertEqual(expected.st_mtime_ns, actual.st_mtime_ns)
            self.assertEqual(expected.st_atime_ns, actual.st_atime_ns)
            self.assertNotEqual(expected.st_ino, actual.st_ino)
            target.write_bytes(b'changed')
            self.assertEqual(b'original', source.read_bytes())

    def test_cross_device_fallback_is_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "a", Path(directory) / "b"
            source.write_bytes(b"content")

            def unavailable(*args):
                ctypes.set_errno(errno.EXDEV)
                return -1

            self.assertEqual("byte-copy", clone_file(source, target, clone=unavailable))
            self.assertEqual(b"content", target.read_bytes())

    def test_permission_failure_is_not_hidden_by_fallback(self):
        def denied(*args):
            ctypes.set_errno(errno.EACCES)
            return -1

        with patch("gambit_smp.artifact_storage.shutil.copy2") as copy:
            with self.assertRaises(PermissionError):
                clone_file("source", "target", clone=denied)
            copy.assert_not_called()
