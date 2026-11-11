import importlib.util
import io
import json
import shutil
import signal
from pathlib import Path
import sys
import subprocess
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

from gambit_smp.framework import ROOT, digest
from gambit_smp.review_validation import load, run_suite, supervise, ValidationProgress


class ReviewValidationTests(unittest.TestCase):
    def test_watchdog_counts_only_unique_complete_typed_test_records(self):
        epoch = "test-attempt"
        inventory = {"schema": "gambit-validation-inventory.v1", "epoch": epoch,
                     "actor": "123", "tests": ["one", "two"], "source": digest(self.source)}
        (self.root / "inventory.json").write_text(json.dumps(inventory))
        path = self.root / "tests.log"
        count = ValidationProgress(ROOT, self.root, {"pid": 123}, epoch)
        self.addCleanup(count.close)
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
        self.assertTrue((self.root / "progress.jsonl").is_file())
        self.assertIn(["one", "123", epoch, "completed-test", digest(self.source), 1],
                      count.witness["cursorAfter"])
        for line in (self.root / "progress.jsonl").read_text().splitlines():
            record = json.loads(line)
            self.assertEqual(record["cursorProjection"], "changed-keys")
            self.assertEqual(record["cursorBefore"], [row[:6] for row in record["advanced"]])
            self.assertEqual(record["cursorAfter"],
                             [[*row[:5], row[6]] for row in record["advanced"]])

    def test_unknown_test_and_wrong_incarnation_do_not_renew(self):
        epoch = "test-attempt"
        inventory = {"schema": "gambit-validation-inventory.v1", "epoch": epoch,
                     "actor": "123", "tests": ["known"], "source": digest(self.source)}
        path = self.root / "inventory.json"
        path.write_text(json.dumps(inventory))
        (self.root / "tests.log").write_text('  elapsed {"test":"unknown","seconds":0.1}\n')
        count = ValidationProgress(ROOT, self.root, {"pid": 123}, epoch)
        self.addCleanup(count.close)
        self.assertEqual(count("", ""), 0)
        self.assertTrue(count.witness["rejected"])
        wrong = ValidationProgress(ROOT, self.root, {"pid": 456}, epoch)
        self.addCleanup(wrong.close)
        with self.assertRaisesRegex(ValueError, "identity mismatch"):
            wrong("", "")

    def test_registered_policy_does_not_classify_inactivity_as_deadlock(self):
        progress = ValidationProgress(ROOT, self.root, {}, "policy-only")
        self.addCleanup(progress.close)
        self.assertGreater(progress.policy(), 0)
        self.assertEqual(progress.observe("inactivity-expired"),
                         [["no-admitted-progress-within-window"]])
        self.assertEqual(progress.observe("external-interruption"), [["externally-interrupted"]])

    def test_window_is_configured_in_registered_scheme_not_python(self):
        directory = self.root / "evidence/dsl"
        shutil.copytree(ROOT / "evidence/dsl", directory)
        source = (ROOT / "evidence/dsl/validation-progress.ss").read_text()
        (directory / "validation-progress.ss").write_text(source.replace("(lit 300)", "(lit 7)"))
        progress = ValidationProgress(self.root, self.root, {}, "configured-policy")
        self.addCleanup(progress.close)
        self.assertEqual(progress.policy(), 7)

    def test_real_scheme_admitted_journal_can_outlive_its_inactivity_window(self):
        from gambit_smp.framework import execute
        metadata, epoch = {}, "actual-journal"
        progress = ValidationProgress(ROOT, self.root, metadata, epoch)
        self.addCleanup(progress.close)
        progress.policy()
        program = ("import json,os,time\nfrom pathlib import Path\np=Path('.')\n"
                   "inventory={'schema':'gambit-validation-inventory.v1','epoch':'actual-journal',"
                   "'actor':str(os.getpid()),'tests':['a','b','c','d'],'source':'fixture'}\n"
                   "(p/'inventory.json').write_text(json.dumps(inventory))\n"
                   "with (p/'tests.log').open('w') as f:\n"
                   " for name in inventory['tests']:\n"
                   "  f.write('  elapsed '+json.dumps({'test':name,'seconds':.1})+'\\n');f.flush();time.sleep(.35)\n")
        code, _, expired, seconds = execute([sys.executable, "-u", "-c", program],
            self.root, .8, metadata=metadata, progress_check=progress)
        self.assertEqual(code, 0)
        self.assertFalse(expired)
        self.assertGreater(seconds, .8)
        self.assertTrue(metadata["parentReaped"])
        self.assertTrue(metadata["processGroupQuiescent"])
        self.assertTrue(progress.witness["advanced"])

    def test_real_repeated_journal_records_do_not_prevent_inactivity_stop(self):
        from gambit_smp.framework import execute
        metadata, epoch = {}, "actual-replay"
        progress = ValidationProgress(ROOT, self.root, metadata, epoch)
        self.addCleanup(progress.close)
        progress.policy()
        program = ("import json,os,time\nfrom pathlib import Path\np=Path('.')\n"
                   "inventory={'schema':'gambit-validation-inventory.v1','epoch':'actual-replay',"
                   "'actor':str(os.getpid()),'tests':['a'],'source':'fixture'}\n"
                   "(p/'inventory.json').write_text(json.dumps(inventory))\n"
                   "with (p/'tests.log').open('w') as f:\n"
                   " for _ in range(100):\n"
                   "  f.write('  elapsed '+json.dumps({'test':'a','seconds':.1})+'\\n');f.flush();time.sleep(.05)\n")
        _, _, expired, _ = execute([sys.executable, "-u", "-c", program],
            self.root, .8, metadata=metadata, progress_check=progress)
        self.assertTrue(expired)
        self.assertEqual(progress.progress.renewals, 1)
        self.assertTrue(progress.witness["rejected"])
        self.assertTrue(metadata["parentReaped"])
        self.assertTrue(metadata["processGroupQuiescent"])

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

    def test_failure_traceback_is_retained_before_suite_finalization(self):
        from gambit_smp.review_validation import Outcomes, ValidationOutput
        journal = io.StringIO()
        stream = unittest.runner._WritelnDecorator(ValidationOutput(journal))
        result = Outcomes(stream, descriptions=True, verbosity=2)
        class Failing(unittest.TestCase):
            def runTest(self):
                with self.subTest(branch='failed-observation'):
                    self.fail('retained assertion')
                raise RuntimeError('retained exception')
        Failing().run(result)
        # No runner.printErrors()/stopTestRun() has happened yet.
        text = journal.getvalue()
        self.assertIn('AssertionError: retained assertion', text)
        self.assertIn('RuntimeError: retained exception', text)
        self.assertIn('failed-observation', text)
        self.assertEqual(len(result.errors), 1)
        self.assertEqual(len(result.failures), 1)
        self.assertFalse(result.wasSuccessful())

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

    def test_progress_delta_identity_is_checked_before_reuse(self):
        path = self.receipt()
        progress = path.parent / "progress.jsonl"
        progress.write_text('{"cursorProjection":"changed-keys"}\n')
        saved = json.loads(path.read_text())
        saved["producer"]["progressLog"] = {"path": progress.name, "sha256": digest(progress)}
        path.write_text(json.dumps(saved))
        self.assertTrue(load(self.root, path, self.inputs, self.engine)["frameworkValidated"])
        progress.write_text('{"changed":true}\n')
        with self.assertRaisesRegex(ValueError, "progress log identity mismatch"):
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
        with patch("gambit_smp.review_validation.execute", side_effect=failed_worker), \
                patch.object(ValidationProgress, "policy", return_value=10):
            path, receipt = supervise(self.root, "evidence-review", "model", out, 10)
        self.assertEqual("PASS", receipt["childStatus"])
        self.assertEqual(-11, receipt["producer"]["exit"])
        self.assertFalse(receipt["frameworkValidated"])
        self.assertEqual("DENY", load(self.root, path, self.inputs, self.engine)["status"])

    def test_timeout_without_a_completed_result_is_preserved(self):
        with patch("gambit_smp.review_validation.execute", return_value=(-9, "incomplete\n", True, 10)), \
                patch.object(ValidationProgress, "policy", return_value=10), \
                patch.object(ValidationProgress, "observe", return_value=[["no-admitted-progress-within-window"]]):
            path, _ = supervise(self.root, "full", "model", self.root / ".cache/timeout", 10)
        checked = load(self.root, path, self.inputs, self.engine)
        self.assertEqual("TIMEOUT", checked["status"])
        self.assertFalse(checked["frameworkValidated"])

    def test_external_interruption_retains_journal_without_timeout_or_pass(self):
        out = self.root / ".cache/interrupted"
        def interrupted(*args, **kwargs):
            (out / "tests.log").write_text("completed before interruption\n")
            raise KeyboardInterrupt()
        with patch("gambit_smp.review_validation.execute", side_effect=interrupted), \
                patch.object(ValidationProgress, "policy", return_value=10), \
                patch.object(ValidationProgress, "observe", return_value=[["externally-interrupted"]]):
            path, receipt = supervise(self.root, "full", "model", out, 10)
        self.assertFalse(receipt["producer"]["timeout"])
        self.assertIsNotNone(receipt["producer"]["interruptionSignal"])
        self.assertFalse(receipt["frameworkValidated"])
        self.assertEqual((out / "tests.log").read_text(), "completed before interruption\n")
        self.assertEqual(load(self.root, path, self.inputs, self.engine)["status"], "INTERRUPTED")

    def test_actual_sigterm_preserves_partial_journal_and_reaps_owned_child(self):
        from gambit_smp.framework import execute as actual_execute
        out = self.root / ".cache/signal-interrupted"
        program = ("import os,signal,time\nfrom pathlib import Path\n"
                   + "Path(" + repr(str(out / "tests.log")) + ").write_text('partial actual journal\\n')\n"
                   + "os.kill(os.getppid(),signal.SIGTERM)\ntime.sleep(10)\n")
        def execute_fixture(_command, cwd, window, **kwargs):
            return actual_execute([sys.executable, "-u", "-c", program], cwd, window, **kwargs)
        with patch("gambit_smp.review_validation.execute", side_effect=execute_fixture), \
                patch.object(ValidationProgress, "policy", return_value=10), \
                patch.object(ValidationProgress, "observe", return_value=[["externally-interrupted"]]):
            path, receipt = supervise(self.root, "full", "model", out, 10)
        self.assertEqual(receipt["producer"]["interruptionSignal"], signal.SIGTERM)
        self.assertFalse(receipt["producer"]["timeout"])
        self.assertIsNone(receipt["producer"]["exit"])
        self.assertFalse(receipt["frameworkValidated"])
        self.assertEqual((out / "tests.log").read_text(), "partial actual journal\n")
        self.assertEqual(load(self.root, path, self.inputs, self.engine)["status"], "INTERRUPTED")
        import os
        with self.assertRaises(ProcessLookupError):
            os.killpg(receipt["producer"]["pid"], 0)

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
        with patch("gambit_smp.review_validation.execute", side_effect=unsettled_worker), \
                patch.object(ValidationProgress, "policy", return_value=10):
            path, receipt = supervise(self.root, "evidence-review", "model", out, 10)
        self.assertEqual("PASS", receipt["childStatus"])
        self.assertEqual("DENY", receipt["status"])
        self.assertFalse(receipt["frameworkValidated"])
        self.assertEqual("DENY", load(self.root, path, self.inputs, self.engine)["status"])


if __name__ == "__main__":
    unittest.main()
