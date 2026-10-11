import json
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
        shallow = Path(directory) / "shallow"
        git(root, "clone", "--depth", "1", upstream.as_uri(), str(shallow))
        (root / "evidence").mkdir()
        bundle = root / "evidence/source.bundle"
        git(shallow, "bundle", "create", str(bundle), "HEAD")
        git(root, "init")
        (root / ".gitmodules").write_text('[submodule "vendor/gambit"]\n'
            ' path = vendor/gambit\n url = https://example.invalid/source.git\n')
        git(root, "update-index", "--add", "--cacheinfo", "160000", revision, "vendor/gambit")
        lock = {"schema": "gambit-runtime-source-lock.v1", "revision": revision,
                "submodule": "vendor/gambit", "repository": "https://example.invalid/source.git",
                "files": {"lib/mem.c": {"baseSha256": digest(source)}}}
        lock_path = root / "evidence/runtime-source.lock.json"
        lock_path.write_text(json.dumps(lock))
        record = {"schema": "gambit-source-provisioning.v1", "sourceLock": str(lock_path.relative_to(root)),
            "sourceLockSha256": digest(lock_path), "revision": revision,
            "submodule": lock["submodule"], "repository": lock["repository"],
            "bundle": "evidence/source.bundle", "bundleSha256": digest(bundle),
            "shallowBoundary": revision, "omittedParents": [parent],
            "networkReproductionChecked": False, "configuredToolchainReproduced": False,
            "runtimeAdmitted": False, "releaseAdmitted": False}
        manifest = root / provision.MANIFEST
        manifest.write_text(json.dumps(record))
        return root, record, manifest

    def test_offline_source_and_explicit_shallow_history(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, _ = self.fixture(directory)
            result = provision.initialize(root)
            self.assertTrue(result["fsckPassed"])
            self.assertFalse(result["runtimeAdmitted"])
            self.assertFalse(result["networkReproductionChecked"])
            self.assertEqual("true", provision.git(root / record["submodule"], "rev-parse", "--is-shallow-repository"))
            self.assertEqual("pinned\n", (root / "vendor/gambit/lib/mem.c").read_text())
            self.assertFalse((root / ".data").exists())
            with self.assertRaisesRegex(ValueError, "fresh unpopulated"):
                provision.initialize(root)

    def test_bundle_drift_is_rejected_before_initializing(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, _ = self.fixture(directory)
            (root / record["bundle"]).write_bytes(b"tampered")
            with self.assertRaisesRegex(ValueError, "bundle digest drift"):
                provision.initialize(root)
            self.assertFalse((root / "vendor/gambit").exists())

    def test_cache_alias_and_wrong_boundary_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            record["shallowBoundary"] = record["omittedParents"][0]
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "capsule binding"):
                provision.validate(root)
            (root / ".data").mkdir()
            (root / ".data/source.bundle").write_bytes((root / record["bundle"]).read_bytes())
            (root / "alias.bundle").symlink_to(".data/source.bundle")
            record["shallowBoundary"] = record["revision"]
            record["bundle"] = "alias.bundle"
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "not a cache"):
                provision.validate(root)

    def test_wrong_parent_keeps_failed_checkout_non_admitted(self):
        with tempfile.TemporaryDirectory() as directory:
            root, record, manifest = self.fixture(directory)
            record["omittedParents"] = ["0" * 40]
            manifest.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "commit parents"):
                provision.initialize(root)
            self.assertTrue((root / "vendor/gambit/.git").exists())


if __name__ == "__main__":
    unittest.main()
