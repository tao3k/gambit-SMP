from pathlib import Path
import json
import tempfile
import unittest

from gambit_smp import runtime_identity as identity
from gambit_smp.check_gambit import digest


class RuntimeIdentityTests(unittest.TestCase):
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
