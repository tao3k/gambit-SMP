"""CI wiring/process contracts, never native runtime acceptance."""
import importlib.util
import json
import os
import re
from pathlib import Path
import sys
import shutil
import tempfile
import time
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("gambit_ci", ROOT / ".github/gambit/runner.py")
ci = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ci)


class GambitCIContracts(unittest.TestCase):
    def test_three_flags_together(self):
        self.assertEqual(("--enable-smp", "--enable-multiple-vms",
                          "--enable-multiple-threaded-vms"), ci.FLAGS)

    def test_checked_patch_reproduces_exact_context_fix_without_vendor_mutation(self):
        from gambit_smp.framework import apply_untracked_patch
        from gambit_smp.source_capabilities import validate_source_lock
        lock = json.loads(ci.LOCK.read_text())
        validate_source_lock(lock)
        self.assertEqual({"lib/setup.c"}, set(lock["files"]))
        source = ROOT / "vendor/gambit/lib/setup.c"
        before = ci.digest(source)
        self.assertEqual(before, lock["files"]["lib/setup.c"]["baseSha256"])
        patch = ROOT / lock["patch"]
        self.assertEqual(ci.digest(patch), lock["patchSha256"])
        with tempfile.TemporaryDirectory() as directory:
            copied = Path(directory)
            (copied / "lib").mkdir()
            shutil.copy2(source, copied / "lib/setup.c")
            apply_untracked_patch(copied, patch.read_bytes(), {"lib/setup.c"})
            self.assertEqual(lock["files"]["lib/setup.c"]["candidateSha256"],
                             ci.digest(copied / "lib/setup.c"))
            text = (copied / "lib/setup.c").read_text()
            self.assertIn("make_global (___MAKE_GLOBAL_PSV", text)
            self.assertIn("___P((___MAKE_GLOBAL_PSD", text)
        self.assertEqual(before, ci.digest(source))

    def test_complete_stress_inventory_has_independent_jobs(self):
        specs = json.loads(ci.CONFIG.read_text())
        upstream = sorted(path.relative_to(ROOT / "vendor/gambit/tests").as_posix()
                          for path in (ROOT / "vendor/gambit/tests/unit-tests").rglob("*_stress.scm"))
        declared = sorted(spec["selection"] for spec in specs.values() if spec.get("stress"))
        self.assertTrue(upstream)
        self.assertEqual(upstream, declared)
        for spec in specs.values():
            if spec["kind"] == "suite":
                files = ci.selected_files(ROOT / "vendor/gambit/tests/unit-tests",
                    [spec["selection"].removeprefix("unit-tests/")],
                    inventory="stress" if spec["stress"] else "unit")
                self.assertTrue(files)
                self.assertEqual(["gsi", "gsc"], spec["modes"])

    def test_identity_rejects_revision_missing_extra_and_changed_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.c"
            source.write_text("original")
            identity = {"checkout": "one", "sourceLockSha256": ci.digest(ci.LOCK),
                        "files": ci.inventory(root)}
            ci.verify(root, identity, "one")
            with self.assertRaisesRegex(ValueError, "checkout"):
                ci.verify(root, identity, "two")
            source.write_text("changed")
            with self.assertRaisesRegex(ValueError, "inventory"):
                ci.verify(root, identity, "one")
            source.unlink()
            with self.assertRaisesRegex(ValueError, "inventory"):
                ci.verify(root, identity, "one")
            source.write_text("original")
            (root / "extra").write_text("unexpected")
            with self.assertRaisesRegex(ValueError, "inventory"):
                ci.verify(root, identity, "one")

    def test_process_failure_and_timeout_retain_original_observations(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, code, seconds, expected in (
                    ("failure", "raise SystemExit(7)", 3, False),
                    ("timeout", "import time; time.sleep(3)", 0.1, True)):
                output = root / name
                with self.assertRaises(RuntimeError):
                    ci.observe([sys.executable, "-c", code], root,
                               time.monotonic() + seconds, output)
                receipt = json.loads(output.with_suffix(".json").read_text())
                self.assertEqual(expected, receipt["timeout"])
                self.assertTrue(receipt["group_quiescent"])
                self.assertEqual(-9 if expected else 7, receipt["exit"])

    def test_runtime_options_reach_actual_child_and_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            environment = dict(os.environ, GAMBOPT="p2")
            output = root / "environment"
            text = ci.observe([sys.executable, "-c", "import os; print(os.environ['GAMBOPT'])"],
                              root, time.monotonic() + 3, output, environment=environment)
            self.assertEqual("p2\n", text)
            self.assertEqual("p2", json.loads(output.with_suffix(".json").read_text())["runtimeOptions"])

    def test_modes_use_existing_suite_executor_and_one_shared_deadline(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "tests/unit-tests").mkdir(parents=True)
            (root / "tests/unit-tests/fixture.scm").write_text("(exit 0)\n")
            spec = {"selection": "unit-tests/fixture.scm", "stress": False, "modes": ["gsi", "gsc"]}
            deadline = time.monotonic() + 3
            calls = []
            def existing(context, runtime, copied, arguments, files, jobs, option):
                calls.append((arguments["mode"], context.deadline))
                return [{"accepted": arguments["mode"] == "gsc"}]
            with patch.object(ci, "run_suite_groups", side_effect=existing):
                with self.assertRaisesRegex(RuntimeError, "shared budget"):
                    ci.run_modes(root, spec, deadline, root / "logs", root / "work", {})
            self.assertEqual([("gsi", deadline), ("gsc", deadline)], calls)
            rows = json.loads((root / "logs/modes.json").read_text())
            self.assertFalse(rows[0]["rows"][0]["accepted"])
            self.assertTrue(rows[1]["rows"][0]["accepted"])
            with patch.object(ci, "run_suite_groups", side_effect=RuntimeError("unreaped group")):
                with self.assertRaisesRegex(RuntimeError, "unreaped group"):
                    ci.run_modes(root, spec, deadline, root / "error-logs", root / "error-work", {})
            rows = json.loads((root / "error-logs/modes.json").read_text())
            self.assertIsNone(rows[0]["started"])
            self.assertIs(rows[1]["started"], False)

    def test_every_module_is_required_and_uses_one_artifact(self):
        workflow = (ROOT / ".github/workflows/gambit.yml").read_text()
        self.assertIn("fail-fast: false", workflow)
        self.assertNotIn("continue-on-error", workflow)
        self.assertIn('test "$PATCHES" = success', workflow)
        self.assertIn('test "$MODULES" = success', workflow)
        self.assertEqual(2, workflow.count("gambit-runtime-${{ github.run_id }}-${{ github.run_attempt }}"))
        self.assertNotIn("module.sh", workflow)
        matrix = re.search(r"module: \[(.*)\]", workflow).group(1).split(", ")
        self.assertEqual(set(json.loads(ci.CONFIG.read_text())) - {"patch-contracts"}, set(matrix))

    def test_official_targets_are_not_replaced_with_local_fixture(self):
        specs = json.loads(ci.CONFIG.read_text())
        self.assertEqual(["check"], specs["upstream-check"]["targets"])
        self.assertEqual(["test7", "test8", "test9"], specs["gc-ffi"]["targets"])
        self.assertEqual(["test5", "test6"], specs["compile-execute"]["targets"])
