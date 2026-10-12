import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import source_materialize as source
from gambit_smp.framework import digest


class SourceMaterializeTests(unittest.TestCase):
    def fixture(self, root, files=source.FILES):
        (root / ".data").mkdir()
        checkout = root / "vendor/gambit"
        checkout.mkdir(parents=True)
        candidate = root / ".data/candidate"
        base = {}
        for name in files:
            base[name] = b"base\n"
            target = candidate / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(b"candidate\n")
        archive = io.BytesIO()
        with tarfile.open(fileobj=archive, mode="w") as tree:
            for name, data in base.items():
                info = tarfile.TarInfo(name)
                info.size = len(data)
                tree.addfile(info, io.BytesIO(data))
        def git(command, **kwargs):
            if "ls-tree" in command:
                name = command[-1]
                return (b"100644 blob " + b"a" * 40 + b"\t" + name.encode() + b"\0"
                        if name in base else b"")
            if "show" in command:
                return base[command[-1].split(":", 1)[1]]
            if "archive" in command:
                return archive.getvalue()
            raise AssertionError(command)
        return checkout, candidate, git

    def run_fixture(self, mode):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            checkout, candidate, git = self.fixture(root)
            lock_path, patch_path = root / "lock.json", root / "snapshot.patch"
            with patch.object(source, "ROOT", root), \
                 patch.object(source, "revision", return_value="a" * 40), \
                 patch.object(source.subprocess, "check_output", side_effect=git):
                lock = source.export(checkout, candidate, lock_path, patch_path)
                if mode == "patch-drift":
                    patch_path.write_text("changed")
                    with self.assertRaisesRegex(ValueError, "overlay drift"):
                        source.materialize(lock_path, root / "restored")
                    self.assertFalse((root / "restored").exists())
                    return
                if mode == "wrong-candidate":
                    lock["files"]["lib/mem.c"]["candidateSha256"] = "0" * 64
                    lock_path.write_text(json.dumps(lock))
                    with self.assertRaisesRegex(ValueError, "differs from candidate"):
                        source.materialize(lock_path, root / "restored")
                    self.assertFalse((root / "restored").exists())
                    return
                receipt = source.materialize(lock_path, root / "restored")
                self.assertFalse(receipt["configuredToolchainReproduced"])
                self.assertFalse(receipt["runtimeAdmitted"])
                for name in source.FILES:
                    self.assertEqual(digest(candidate / name), digest(root / "restored" / name))
                with self.assertRaisesRegex(ValueError, "fresh output"):
                    source.materialize(lock_path, root / "restored")
                with self.assertRaisesRegex(ValueError, "overwrite"):
                    source.export(checkout, candidate, lock_path, patch_path)

    def test_fresh_source_reproduces_exact_slice_not_runtime(self):
        self.run_fixture("pass")

    def test_patch_drift_fails_before_publishing_output(self):
        self.run_fixture("patch-drift")

    def test_candidate_digest_mismatch_does_not_publish(self):
        self.run_fixture("wrong-candidate")

    def test_checked_in_snapshot_has_no_personal_paths(self):
        lock = json.loads(source.LOCK.read_text())
        self.assertEqual("7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882", lock["revision"])
        overlay = source.ROOT / lock["patch"]
        self.assertEqual(lock["patchSha256"], digest(overlay))
        self.assertNotIn("/Users/", overlay.read_text())
        self.assertNotIn(".data/", overlay.read_text())

    def test_candidate026_lock_restores_all_five_audited_files_without_old_cache(self):
        lock_name = "evidence/runtime-source-026.lock.json"
        lock = json.loads((source.ROOT / lock_name).read_text())
        self.assertEqual(set(lock["files"]), {*source.FILES, "configure.ac", "lib/_thread.scm"})
        self.assertEqual(lock["files"]["lib/setup.c"]["candidateSha256"],
                         "98b39f7204d1086550d2666be67f447f0f83410e941ef7f2cb3adbea3c19391f")
        with source.locked_source(source.ROOT, lock_name) as (tree, inputs):
            for name, row in lock["files"].items():
                self.assertEqual(digest(tree / name), row["candidateSha256"])
            self.assertTrue(all(".data" not in Path(name).parts for name in inputs))
            self.assertIn(lock["patch"], inputs)

    def test_export_rejects_untracked_extra_source_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            checkout, candidate, git = self.fixture(root)
            with patch.object(source, "ROOT", root), \
                 patch.object(source, "revision", return_value="a" * 40), \
                 patch.object(source.subprocess, "check_output", side_effect=git):
                with self.assertRaisesRegex(ValueError, "tracked"):
                    source.export(checkout, candidate, root / "lock.json", root / "snapshot.patch",
                                  (*source.FILES, "unknown.c"))

    def test_generic_source_inventory_reproduces_c_scheme_and_build_files(self):
        files = ("lib/runtime.c", "lib/_kernel.scm", "lib/_thread#.scm", "gsc/makefile.in")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            checkout, candidate, git = self.fixture(root, files)
            with patch.object(source, "ROOT", root), \
                 patch.object(source, "revision", return_value="a" * 40), \
                 patch.object(source.subprocess, "check_output", side_effect=git):
                source.export(checkout, candidate, root / "lock.json", root / "snapshot.patch", files)
                result = source.materialize(root / "lock.json", root / "restored", root=root)
            self.assertEqual(set(files), set(result["files"]))
            self.assertFalse(result["runtimeAdmitted"])

    def test_source_lock_rejects_noncanonical_names_hashes_and_aliases(self):
        from gambit_smp.source_capabilities import validate_source_lock, source_file
        lock = {"schema": "gambit-runtime-source-lock.v1", "revision": "a" * 40,
                "submodule": "vendor/gambit", "repository": "https://git.cons.io/mighty-gerbils/gambit.git",
                "patchSha256": "b" * 64, "runtimeAdmitted": False, "releaseAdmitted": False,
                "files": {"lib/new.scm": {"baseSha256": "c" * 64, "candidateSha256": "d" * 64}}}
        for name in ("../outside", "/outside", "lib//new.scm", "lib/./new.scm",
                     "lib/.data/new.scm", "lib/.git/config", "lib/.GIT/config",
                     "lib/new\n.scm", "materialization.json"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                validate_source_lock({**lock, "files": {name: lock["files"]["lib/new.scm"]}})
        for key, value in (("revision", "HEAD"), ("submodule", "Cache/gambit"),
                           ("patchSha256", "bad"), ("runtimeAdmitted", True)):
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate_source_lock({**lock, key: value})
        with self.assertRaises(ValueError):
            validate_source_lock({**lock, "files": {"lib/new.scm": {"baseSha256": "c" * 64,
                                                                    "candidateSha256": "bad"}}})
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "real").mkdir()
            (root / "real/new.scm").write_text("source")
            (root / "lib").symlink_to(root / "real", target_is_directory=True)
            with self.assertRaisesRegex(ValueError, "symlink"):
                source_file(root, "lib/new.scm")

    def test_export_rejects_git_symlink_and_duplicate_selection(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            checkout, candidate, git = self.fixture(root)
            def symlink_git(command, **kwargs):
                result = git(command, **kwargs)
                return result.replace(b"100644 blob", b"120000 blob") if "ls-tree" in command else result
            with patch.object(source, "ROOT", root), \
                 patch.object(source, "revision", return_value="a" * 40), \
                 patch.object(source.subprocess, "check_output", side_effect=symlink_git):
                with self.assertRaisesRegex(ValueError, "regular tracked"):
                    source.export(checkout, candidate, root / "lock.json", root / "snapshot.patch")
                with self.assertRaisesRegex(ValueError, "unique"):
                    source.export(checkout, candidate, root / "lock.json", root / "snapshot.patch",
                                  ("lib/mem.c", "lib/mem.c"))
            self.assertFalse((root / "lock.json").exists())

    def test_composed_scm_repairs_reproduce_without_generated_c_or_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            checkout, candidate, git = self.fixture(root, source.COMPOSED_FILES)
            with patch.object(source, "ROOT", root), \
                 patch.object(source, "revision", return_value="a" * 40), \
                 patch.object(source.subprocess, "check_output", side_effect=git):
                source.export(checkout, candidate, root / "lock.json", root / "snapshot.patch", source.COMPOSED_FILES)
                result = source.materialize(root / "lock.json", root / "restored", root=root)
            self.assertEqual(set(source.COMPOSED_FILES), set(result["files"]))
            self.assertFalse(result["runtimeAdmitted"])
            self.assertFalse((root / "restored/lib/_system.c").exists())

    def test_candidate031_carries_earlier_repairs_in_versioned_source_inputs(self):
        from gambit_smp.source_binding import gc_table_snapshot, shared_pipe_source_hash, vector_increment_source_hash, checked_negate_header_hash
        with source.locked_source(source.ROOT, "evidence/runtime-source-031.lock.json") as (tree, inputs):
            self.assertTrue(all(".data" not in Path(name).parts for name in inputs))
            lock = json.loads((source.ROOT / "evidence/runtime-source-031.lock.json").read_text())
            self.assertEqual(set(source.COMPOSED_FILES), set(lock["files"]))
            gc_table_snapshot((tree / "lib/_system.scm").read_text())
            for name, transform in (("lib/_io.scm", shared_pipe_source_hash),
                                    ("gsc/_prims.scm", vector_increment_source_hash)):
                base = source.subprocess.check_output(["git", "-C", str(source.ROOT / "vendor/gambit"),
                                                       "show", lock["revision"] + ":" + name])
                self.assertEqual(transform(base), digest(tree / name))
            with source.locked_source(source.ROOT, "evidence/runtime-source-029.lock.json") as (previous, _):
                self.assertEqual(checked_negate_header_hash((previous / "include/gambit.h.in").read_bytes()),
                                 digest(tree / "include/gambit.h.in"))
            body = (tree / "lib/c_intf.c").read_text().split("___EXP_FUNC(___SCMOBJ,___make_sfun_stack_marker)", 1)[1]
            self.assertLess(body.index("___GC_SAVE1(___ps, proc_or_false)"), body.index("___make_vector"))
            self.assertLess(body.index("___make_vector"), body.index("___GC_RESTORE1(___ps, proc_or_false)"))
            self.assertIn("#if defined(__APPLE__) && defined(__MACH__)", (tree / "lib/os_io.c").read_text())


if __name__ == "__main__":
    unittest.main()
