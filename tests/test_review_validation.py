import importlib.util
import io
import json
from pathlib import Path
import sys
import subprocess
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.review_validation import load, run_suite, supervise


class ReviewValidationTests(unittest.TestCase):
    def test_watchdog_counts_only_unique_complete_typed_test_records(self):
        from gambit_smp.review_validation import _completed_test_progress
        path = self.root / "progress.log"
        count = _completed_test_progress(path)
        self.assertEqual(count("heartbeat", ""), 0)
        path.write_text('heartbeat\n  elapsed {"test":"one","seconds":0.1}')
        self.assertEqual(count("", ""), 0)
        with path.open("a") as stream:
            stream.write('\n  elapsed {"test":"one","seconds":0.2}\n'
                         '  elapsed {"test":"two","seconds":true}\n'
                         '  elapsed {"test":"two","seconds":-1}\n'
                         '  elapsed not-json\n')
        self.assertEqual(count("", ""), 1)
        with path.open("a") as stream:
            stream.write('  elapsed {"test":"two","seconds":0.2}\n')
        self.assertEqual(count("", ""), 2)
        self.assertEqual(count("repeated heartbeat", ""), 2)

    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        (self.root / "tests").mkdir()
        (self.root / "src").mkdir()
        self.source = self.root / "src/source.py"
        self.source.write_text("original\n")
        self.module_path = self.root / "tests/test_fixture.py"
        self.module_path.write_text("import unittest\nclass Fixture(unittest.TestCase):\n"
                                    "    def test_pass(self):\n        self.assertTrue(True)\n")
        spec = importlib.util.spec_from_file_location("review_validation_fixture", self.module_path)
        self.module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = self.module
        self.addCleanup(sys.modules.pop, spec.name, None)
        spec.loader.exec_module(self.module)
        self.inputs = {"src/source.py": digest(self.source), "tests/test_fixture.py": digest(self.module_path)}
        self.engine = {"extension": "fixture-engine"}

    def result(self):
        return run_suite(self.root, unittest.defaultTestLoader.loadTestsFromModule(self.module),
                         self.inputs, self.engine, "evidence-review")

    def receipt(self, result=None):
        result, output = result or self.result()
        out = self.root / "run"
        out.mkdir()
        (out / "tests.log").write_text(output)
        (out / "process.log").write_text("worker exited zero\n")
        result["log"] = {"path": "tests.log", "sha256": digest(out / "tests.log")}
        child = out / "test-result.json"
        child.write_text(json.dumps(result))
        parent = dict(result, testResultSha256=digest(child), producer={"exit": 0, "timeout": False,
            "parentReaped": True, "processGroupQuiescent": True,
            "log": {"path": "process.log", "sha256": digest(out / "process.log")}})
        path = out / "receipt.json"
        path.write_text(json.dumps(parent))
        return path

    def test_reuse_requires_coverage_inputs_and_the_same_native_backend(self):
        path = self.receipt()
        checked = load(self.root, path, self.inputs, self.engine)
        self.assertTrue(checked["frameworkValidated"])
        self.assertEqual(["tests/test_fixture.py"], checked["testFiles"])
        self.assertFalse(load(self.root, path, self.inputs, {"extension": "changed"})["frameworkValidated"])
        self.assertEqual("INCOMPLETE_PROFILE", load(self.root, path, self.inputs, self.engine, "full")["status"])
        self.source.write_text("changed\n")
        changed = load(self.root, path, self.inputs, self.engine)
        self.assertEqual("STALE", changed["status"])
        self.assertIn("src/source.py", changed["changedInputs"])

    def test_live_journal_retains_exact_output_without_admitting_partial_results(self):
        journal = io.StringIO()
        result, output = run_suite(self.root,
            unittest.defaultTestLoader.loadTestsFromModule(self.module),
            self.inputs, self.engine, "evidence-review", journal=journal)
        self.assertEqual(journal.getvalue(), output)
        self.assertTrue(result["frameworkValidated"])
        from gambit_smp.review_validation import ValidationOutput
        partial = io.StringIO()
        buffered = ValidationOutput(partial)
        buffered.write("test_actual (Fixture) ... ")
        self.assertEqual(partial.getvalue(), "test_actual (Fixture) ... ")
        self.assertNotIn("PASS", partial.getvalue())

    def test_new_python_module_invalidates_an_old_test_inventory(self):
        path = self.receipt()
        (self.root / "src/new.py").write_text("new module\n")
        checked = load(self.root, path, self.inputs, self.engine)
        self.assertFalse(checked["frameworkValidated"])
        self.assertIn("src/new.py", checked["changedPythonInventory"])

    def test_json_and_scheme_asset_changes_invalidate_saved_validation(self):
        asset = self.root / "tests/fixtures/relations.ss"
        asset.parent.mkdir()
        asset.write_text("(ascent-fragment)\n")
        name = str(asset.relative_to(self.root))
        self.inputs[name] = digest(asset)
        path = self.receipt()
        self.assertTrue(load(self.root, path, self.inputs, self.engine)["frameworkValidated"])
        added = asset.with_name("components.json")
        added.write_text("{}\n")
        checked = load(self.root, path, self.inputs, self.engine)
        self.assertEqual("STALE", checked["status"])
        self.assertIn(str(added.relative_to(self.root)), checked["changedAssetInventory"])
        added.unlink()
        asset.write_text("(ascent-fragment (relation changed (value)))\n")
        checked = load(self.root, path, self.inputs, self.engine)
        self.assertIn(name, checked["changedInputs"])
        asset.unlink()
        self.assertIn(name, load(self.root, path, self.inputs, self.engine)["changedAssetInventory"])

    def test_actual_collection_binds_executed_native_dsl_before_validation(self):
        from gambit_smp.ascent_review import collect
        from gambit_smp.framework import ROOT
        inputs = collect(ROOT.resolve(), task_model="gc_recursive_queue_wait")[1]
        for name in ("catalog", "review", "history"):
            path = "evidence/dsl/" + name + ".ss"
            self.assertEqual(digest(ROOT / path), inputs[path])
        from gambit_smp.ascent_program import load_component_catalog
        catalog = load_component_catalog(ROOT / "evidence/dsl/components.json", entry="catalog",
                                         constructor="make-catalog", trusted=True)
        for path, sha in catalog["sourceInputs"].items():
            self.assertEqual(inputs[str(Path(path).relative_to(ROOT))], sha)

    def test_uncovered_or_changed_dsl_is_not_a_current_validation(self):
        dsl = self.root / "evidence/dsl/catalog.ss"
        dsl.parent.mkdir(parents=True)
        dsl.write_text("(def (make-catalog) original)\n")
        name = str(dsl.relative_to(self.root))
        path = self.receipt()
        required = {**self.inputs, name: digest(dsl)}
        checked = load(self.root, path, required, self.engine)
        self.assertEqual("STALE", checked["status"])
        self.assertEqual([name], checked["uncoveredInputs"])
        self.assertFalse(checked["frameworkValidated"])

    def test_tampered_output_or_parent_cannot_be_reused(self):
        path = self.receipt()
        saved = json.loads(path.read_text())
        saved["testsRun"] = 9
        path.write_text(json.dumps(saved))
        with self.assertRaisesRegex(ValueError, "parent differs"):
            load(self.root, path, self.inputs, self.engine)
        (path.parent / "tests.log").write_text("different output\n")
        with self.assertRaisesRegex(ValueError, "log identity mismatch"):
            load(self.root, path, self.inputs, self.engine)

    def test_skips_and_empty_suites_do_not_validate_the_chain(self):
        self.module.Fixture.test_pass = unittest.skip("fixture skip")(self.module.Fixture.test_pass)
        result, _ = self.result()
        self.assertEqual(1, result["skipped"])
        self.assertFalse(result["frameworkValidated"])
        empty, _ = run_suite(self.root, unittest.TestSuite(), self.inputs, self.engine, "evidence-review")
        self.assertFalse(empty["completeTestInventory"])

    def test_source_change_during_tests_denies_the_receipt(self):
        source = self.source
        def mutate(self):
            source.write_text("changed in test\n")
        self.module.Fixture.test_pass = mutate
        result, _ = self.result()
        self.assertFalse(result["frameworkValidated"])
        self.assertEqual(["src/source.py"], result["changedInputs"])

    def test_parent_retains_cleanup_failure_after_a_passing_test_result(self):
        child, output = self.result()
        out = self.root / ".cache/supervised"
        def failed_worker(*args, **kwargs):
            (out / "tests.log").write_text(output)
            child["log"] = {"path": "tests.log", "sha256": digest(out / "tests.log")}
            (out / "test-result.json").write_text(json.dumps(child))
            return -11, "test output completed; native teardown failed\n", False, 0.1
        with patch("gambit_smp.review_validation.execute", side_effect=failed_worker):
            path, receipt = supervise(self.root, "evidence-review", "model", out, 10)
        self.assertEqual("PASS", receipt["childStatus"])
        self.assertEqual(-11, receipt["producer"]["exit"])
        self.assertFalse(receipt["frameworkValidated"])
        self.assertEqual("DENY", load(self.root, path, self.inputs, self.engine)["status"])

    def test_timeout_without_a_completed_result_is_preserved(self):
        with patch("gambit_smp.review_validation.execute", return_value=(-9, "incomplete\n", True, 10)):
            path, _ = supervise(self.root, "full", "model", self.root / ".cache/timeout", 10)
        checked = load(self.root, path, self.inputs, self.engine)
        self.assertEqual("TIMEOUT", checked["status"])
        self.assertFalse(checked["frameworkValidated"])

    def test_readmission_requires_explicit_reaping_and_group_quiescence(self):
        path = self.receipt()
        original = json.loads(path.read_text())
        for field in ("parentReaped", "processGroupQuiescent"):
            for observed in (None, False, 1, "true"):
                with self.subTest(field=field, observed=observed):
                    saved = json.loads(json.dumps(original))
                    saved["producer"][field] = observed
                    path.write_text(json.dumps(saved))
                    checked = load(self.root, path, self.inputs, self.engine)
                    self.assertEqual("DENY", checked["status"])
                    self.assertFalse(checked["frameworkValidated"])

    def test_zero_exit_does_not_admit_an_unsettled_process_group(self):
        child, output = self.result()
        out = self.root / ".cache/unsettled"
        def unsettled_worker(*args, **kwargs):
            kwargs["metadata"].update(parentReaped=True, processGroupQuiescent=False)
            (out / "tests.log").write_text(output)
            child["log"] = {"path": "tests.log", "sha256": digest(out / "tests.log")}
            (out / "test-result.json").write_text(json.dumps(child))
            return 0, "worker exited; descendant remains\n", False, 0.1
        with patch("gambit_smp.review_validation.execute", side_effect=unsettled_worker):
            path, receipt = supervise(self.root, "evidence-review", "model", out, 10)
        self.assertEqual("PASS", receipt["childStatus"])
        self.assertEqual("DENY", receipt["status"])
        self.assertFalse(receipt["frameworkValidated"])
        self.assertEqual("DENY", load(self.root, path, self.inputs, self.engine)["status"])


if __name__ == "__main__":
    unittest.main()
