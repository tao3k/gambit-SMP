import json
import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest

from gambit_smp.framework import digest
from gambit_smp import source_provision as provision


class SourceProvisionTests(unittest.TestCase):
    def fixture(self, directory):
        root = Path(directory) / "repo"
        upstream = Path(directory) / "upstream"
        root.mkdir()
        upstream.mkdir()
        def git(path, *args):
            return subprocess.check_output(["git", "-C", str(path), *args],
                stderr=subprocess.PIPE, text=True).strip()
        git(upstream, "init")
        git(upstream, "config", "user.name", "Fixture")
        git(upstream, "config", "user.email", "fixture@example.invalid")
        source = upstream / "lib/mem.c"
        source.parent.mkdir()
        source.write_text("first\n")
        git(upstream, "add", ".")
        git(upstream, "commit", "-m", "base")
        parent = git(upstream, "rev-parse", "HEAD")
        source.write_text("pinned\n")
        git(upstream, "commit", "-am", "pinned")
        revision = git(upstream, "rev-parse", "HEAD")
        (root / "evidence").mkdir()
        git(root, "init")
        (root / ".gitmodules").write_text('[submodule "vendor/gambit"]\n'
            ' path = vendor/gambit\n url = https://example.invalid/source.git\n')
        git(root, "update-index", "--add", "--cacheinfo", "160000", revision, "vendor/gambit")
        lock = {"schema": "gambit-runtime-source-lock.v1", "revision": revision,
                "submodule": "vendor/gambit", "repository": "https://example.invalid/source.git",
                "files": {"lib/mem.c": {"baseSha256": digest(source)}}}
        lock_path = root / "evidence/runtime-source.lock.json"
        lock_path.write_text(json.dumps(lock))
        def object_sha(*args):
            return hashlib.sha256(subprocess.check_output(["git", "-C", str(upstream), *args])).hexdigest()
        record = {"schema": "gambit-source-provisioning.v2", "sourceLock": str(lock_path.relative_to(root)),
            "sourceLockSha256": digest(lock_path), "revision": revision,
            "submodule": lock["submodule"], "repository": lock["repository"],
            "commitSha256": object_sha("cat-file", "commit", revision),
            "treeManifestSha256": object_sha("ls-tree", "-r", "-z", revision), "parents": [parent],
            "networkReproductionChecked": False, "configuredToolchainReproduced": False,
            "runtimeAdmitted": False, "releaseAdmitted": False}
        manifest = root / provision.MANIFEST
        manifest.write_text(json.dumps(record))
        provision.prepare_cache(root, root / provision.DEFAULT_CACHE, source=upstream)
        return root, record, manifest

    def test_offline_source_without_versioned_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, _ = self.fixture(directory)
            result = provision.initialize(root, offline=True)
            self.assertTrue(result["fsckPassed"])
            self.assertFalse(result["runtimeAdmitted"])
            self.assertFalse(result["networkReproductionChecked"])
            self.assertTrue(result["offline"])
            self.assertFalse(result["shallowHistory"])
            self.assertEqual("pinned\n", (root / "vendor/gambit/lib/mem.c").read_text())
            self.assertFalse(list((root / "evidence").glob("*.bundle")))
            self.assertEqual(record["repository"], provision.git(root / record["submodule"], "remote", "get-url", "origin"))
            with self.assertRaisesRegex(ValueError, "fresh unpopulated"):
                provision.initialize(root)

    def test_object_digest_drift_is_rejected_before_initializing(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            record["treeManifestSha256"] = "0" * 64
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "object digest drift"):
                provision.initialize(root, offline=True)
            self.assertFalse((root / "vendor/gambit").exists())

    def test_cache_cannot_be_aliased_as_locked_input(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            target = root / ".data/source.lock.json"
            target.parent.mkdir(exist_ok=True)
            target.write_bytes((root / record["sourceLock"]).read_bytes())
            (root / "alias.json").symlink_to(target)
            record["sourceLock"] = "alias.json"
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "not a cache"):
                provision.validate(root)

    def test_wrong_parent_is_rejected_before_checkout(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            record["parents"] = ["0" * 40]
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "commit parents"):
                provision.initialize(root, offline=True)
            self.assertFalse((root / "vendor/gambit").exists())

    def test_missing_offline_cache_never_attempts_fetch(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as directory:
            root, _, _ = self.fixture(directory)
            with patch.object(provision, "prepare_cache") as fetch, self.assertRaisesRegex(ValueError, "cache missing"):
                provision.initialize(root, cache=Path(directory) / "missing", offline=True)
            fetch.assert_not_called()

    def test_movable_shallow_cache_and_git_metadata(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, _ = self.fixture(directory)
            upstream = Path(directory) / "upstream"
            shallow = Path(directory) / "shallow"
            provision.git(root, "clone", "--depth=1", upstream.as_uri(), str(shallow))
            cache = Path(directory) / "portable.git"
            provision.prepare_cache(root, cache, source=shallow)
            self.assertTrue(provision.initialize(root, cache=cache, offline=True)["shallowHistory"])
            self.assertEqual(record["revision"], provision.git(root / record["submodule"], "rev-parse", "HEAD"))

    def test_wrong_url_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            root, _, _ = self.fixture(directory)
            cache = root / provision.DEFAULT_CACHE
            provision.git(cache, "remote", "set-url", "origin", "https://example.invalid/other.git")
            with self.assertRaisesRegex(ValueError, "canonical URL drift"):
                provision.initialize(root, offline=True)
            self.assertFalse((root / "vendor/gambit").exists())

    def test_transport_mirror_preserves_source_identity(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            lock_path = root / record["sourceLock"]
            original_lock = lock_path.read_bytes()
            record["transportRepository"] = (Path(directory) / "upstream").as_uri()
            manifest.write_text(json.dumps(record))
            provision.git(root, "config", "-f", ".gitmodules",
                          "submodule.vendor/gambit.url", record["transportRepository"])
            cache = Path(directory) / "mirror.git"
            with patch.object(provision, "git", wraps=provision.git) as calls:
                provision.prepare_cache(root, cache)
            fetches = [call.args[1:] for call in calls.call_args_list if "fetch" in call.args]
            self.assertEqual([( "-c", "http.sslVerify=true", "fetch", "--no-tags", "--depth=1",
                                record["transportRepository"], record["revision"])], fetches)
            self.assertTrue(provision.initialize(root, cache=cache, offline=True)["fsckPassed"])
            self.assertEqual(original_lock, lock_path.read_bytes())
            self.assertEqual(record["transportRepository"],
                             provision.git(root / record["submodule"], "remote", "get-url", "origin"))
            record["commitSha256"] = "0" * 64
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "object digest drift"):
                provision.verify_objects(cache, record)

    def test_transport_requires_explicit_matching_configuration(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            record["transportRepository"] = "https://example.invalid/mirror.git"
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "canonical submodule URL drift"):
                provision.validate(root)
            record["transportRepository"] = None
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "invalid source transport"):
                provision.validate(root)

    def test_incomplete_git_objects_fail_before_checkout(self):
        with tempfile.TemporaryDirectory() as directory:
            root, _, _ = self.fixture(directory)
            cache = root / provision.DEFAULT_CACHE
            packs = list((cache / "objects/pack").glob("*.pack"))
            self.assertTrue(packs)
            packs[0].unlink()
            with self.assertRaises(subprocess.CalledProcessError):
                provision.initialize(root, offline=True)
            self.assertFalse((root / "vendor/gambit").exists())

    def test_fetch_selects_only_the_exact_revision(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            record["repository"] = (Path(directory) / "upstream").as_uri()
            lock_path = root / record["sourceLock"]
            lock = json.loads(lock_path.read_text())
            lock["repository"] = record["repository"]
            lock_path.write_text(json.dumps(lock))
            record["sourceLockSha256"] = digest(lock_path)
            manifest.write_text(json.dumps(record))
            provision.git(root, "config", "-f", ".gitmodules", "submodule.vendor/gambit.url", record["repository"])
            real_git = provision.git
            with patch.object(provision, "git", wraps=real_git) as calls:
                result = provision.prepare_cache(root, Path(directory) / "fetched.git")
            fetches = [call.args[1:] for call in calls.call_args_list if "fetch" in call.args]
            self.assertEqual([( "-c", "http.sslVerify=true", "fetch", "--no-tags", "--depth=1",
                                record["repository"], record["revision"])], fetches)
            self.assertFalse(result["networkReproductionChecked"])
            self.assertTrue(provision.initialize(root, cache=Path(directory) / "fetched.git", offline=True)["shallowHistory"])

    def test_old_bundle_contract_is_not_a_current_source(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            record.update(schema="gambit-source-provisioning.v1", bundle="evidence/old.bundle")
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "revision binding"):
                provision.validate(root)


if __name__ == "__main__":
    unittest.main()
