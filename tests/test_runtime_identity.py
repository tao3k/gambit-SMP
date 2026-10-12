from pathlib import Path
import json
import tempfile
import unittest

from gambit_smp import runtime_identity as identity
from gambit_smp.check_gambit import digest


class RuntimeIdentityTests(unittest.TestCase):
    def test_source_build_uses_final_not_seed_artifacts_and_rejects_drift(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            runtime = root / "runtime"
            names = ("configure.ac", "include/gambit.h", "lib/makefile", "lib/_test.scm",
                     "lib/_test.c", "gsi/gsi", "gsc/gsc", "lib/libgambit.a")
            for name in names:
                path = runtime / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(name)
            patch = root / "overlay.patch"
            patch.write_text("locked overlay")
            lock = root / "lock.json"
            lock.write_text(json.dumps({"revision": "pinned", "patch": patch.name,
                "patchSha256": digest(patch), "files": {"configure.ac": {
                    "candidateSha256": digest(runtime / "configure.ac")}}}))
            receipt = root / "receipt.json"
            record = {"schema": "gambit-locked-object.v1", "status": "source-core-rebuilt",
                "contextStable": True, "inputs": {lock.name: digest(lock)}, "sourceLock": lock.name,
                "artifacts": {"gsi/gsi": "seed-not-final"},
                "generatedHeaderSha256": digest(runtime / "include/gambit.h"),
                "configuredMakefileSha256": digest(runtime / "lib/makefile"),
                "results": [{"stage": name, "exit": 0, "timeout": False, "argv": [
                    "--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"]}
                    for name in ("autoconf", "configure", "seed-core", "bootclean", "source-core")],
                "sourceRegeneration": {"scmRegenerationEstablished": True, "schemeInputsStable": True,
                    "schemeInputs": {"lib/_test.scm": digest(runtime / "lib/_test.scm")},
                    "generatedHashes": {"lib/_test.c": digest(runtime / "lib/_test.c")},
                    "artifacts": {name: digest(runtime / name) for name in
                        ("gsi/gsi", "gsc/gsc", "lib/libgambit.a")}}}
            receipt.write_text(json.dumps(record))
            result = identity.create_from_source_build(runtime, receipt, root)
            identity.check(runtime, result)
            self.assertEqual(digest(runtime / "gsi/gsi"), result["binarySha256"])
            self.assertFalse(result["runtimeAdmitted"])
            self.assertFalse(result["fullTwoPassBootstrapEstablished"])
            self.assertEqual([], result["modeledCases"])
            (runtime / "lib/_test.c").write_text("stale generated source")
            with self.assertRaisesRegex(ValueError, "input drift"):
                identity.create_from_source_build(runtime, receipt, root)

    def test_source_build_rejects_seed_or_unstable_receipt(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            receipt = root / "receipt.json"
            for fields in ({}, {"schema": "gambit-locked-object.v1", "status": "seed-core-built"},
                           {"schema": "gambit-locked-object.v1", "status": "source-core-rebuilt",
                            "contextStable": False}):
                receipt.write_text(json.dumps(fields))
                with self.assertRaisesRegex(ValueError, "stable regenerated"):
                    identity.create_from_source_build(root, receipt, root)

    def test_export_source_delta_requires_exact_baseline_and_unique_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "lib").mkdir()
            baseline = root / "before.c"
            baseline.write_text("before\n")
            (root / "lib/mem.c").write_text("after\n")
            prior = root / "prior.json"
            prior.write_text(json.dumps({"sourceFiles": {"lib/mem.c": digest(baseline)}}))
            patch = root / "delta.patch"
            identity.export_source_delta(root, prior, patch, "lib/mem.c", baseline)
            self.assertIn("--- a/lib/mem.c\n", patch.read_text())
            with self.assertRaisesRegex(ValueError, "overwrite"):
                identity.export_source_delta(root, prior, patch, "lib/mem.c", baseline)
            baseline.write_text("unadmitted\n")
            with self.assertRaisesRegex(ValueError, "baseline"):
                identity.export_source_delta(root, prior, root / "other.patch", "lib/mem.c", baseline)
            with self.assertRaisesRegex(ValueError, "inventoried"):
                identity.export_source_delta(root, prior, root / "escape.patch", "../mem.c", baseline)

    def test_diagnostic_delta_is_exact_and_does_not_admit_other_source_drift(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name in ("lib/mem.c", "lib/setup.c", "gsi/gsi", "gsc/gsc", "lib/libgambit.a"):
                path = root / name
                path.parent.mkdir(exist_ok=True)
                path.write_text("before\n")
            prior = root / "prior.json"
            prior.write_text(json.dumps({"sourceFiles": {
                name: digest(root / name) for name in ("lib/mem.c", "lib/setup.c")},
                "patches": [], "modeledCases": []}))
            patch = root / "delta.patch"
            patch.write_text("--- a/lib/mem.c\n+++ b/lib/mem.c\n@@ -1 +1 @@\n-before\n+after\n")
            (root / "lib/mem.c").write_text("after\n")
            result = identity.create_delta(root, prior, patch)
            identity.check(root, result)
            self.assertEqual(result["modeledCases"], [])
            self.assertEqual(result["diagnosticSourceFiles"], ["lib/mem.c"])
            (root / "lib/setup.c").write_text("unadmitted\n")
            with self.assertRaisesRegex(ValueError, "unadmitted"):
                identity.create_delta(root, prior, patch)

    def test_diagnostic_delta_rejects_uninventoried_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            prior = root / "prior.json"
            prior.write_text(json.dumps({"sourceFiles": {}}))
            patch = root / "delta.patch"
            patch.write_text("--- a/lib/mem.c\n+++ b/lib/mem.c\n@@ -1 +1 @@\n-before\n+after\n")
            with self.assertRaisesRegex(ValueError, "inventory"):
                identity.create_delta(root, prior, patch)

    def test_current_source_and_all_selected_artifacts_must_remain_stable(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name in ("lib/setup.c", "gsi/gsi", "gsc/gsc", "lib/libgambit.a"):
                path = root / name
                path.parent.mkdir(exist_ok=True)
                path.write_text(name)
            receipt = {"sourceFiles": {"lib/setup.c": digest(root / "lib/setup.c")},
                       "binarySha256": digest(root / "gsi/gsi"),
                       "gscSha256": digest(root / "gsc/gsc"),
                       "librarySha256": digest(root / "lib/libgambit.a")}
            identity.check(root, receipt)
            for name in ("lib/setup.c", "gsi/gsi", "gsc/gsc", "lib/libgambit.a"):
                path = root / name
                original = path.read_text()
                path.write_text("changed")
                with self.assertRaises(ValueError):
                    identity.check(root, receipt)
                path.write_text(original)


if __name__ == "__main__":
    unittest.main()
