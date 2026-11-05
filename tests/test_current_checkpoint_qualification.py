"""Audit the observer's actual invocation and fail-closed evidence boundaries."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest

spec = importlib.util.spec_from_file_location('checkpoint_observer', Path(__file__).with_name('run_current_checkpoint_qualification.py'))
observer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(observer)


class CheckpointObserverTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.runtime = self.root / 'native'
        for name in ('gsi/gsi', 'gsc/gsc', 'lib/libgambit.a', 'tests/run-unit-tests.scm', 'tests/unit-tests/#.scm', 'tests/unit-tests/03-number/_num.scm'):
            p = self.runtime / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(name)
        self.identity = {k: digest(self.runtime / name) for k, name in (
            ('binarySha256', 'gsi/gsi'), ('gscSha256', 'gsc/gsc'), ('librarySha256', 'lib/libgambit.a'))}
        self.identity['sourceFiles'] = {}
        self.out = self.root / 'observation'
        self.out.mkdir()

    def observe(self, *, code=0, quiet=True, drift=False):
        calls = []
        def execute(argv, cwd, budget, env, meta):
            calls.append((argv, cwd, budget, env))
            meta.update(parentReaped=True, processGroupQuiescent=quiet)
            if drift:
                (self.runtime / 'tests/unit-tests/03-number/_num.scm').write_text('changed during run')
            return code, 'PASSED ALL 1 UNIT TESTS\n', False, .01
        with patch.object(observer, 'RUNTIME', self.runtime), patch.object(observer, 'EXPECTED_UNIT_FILES', 1), patch.object(observer, 'execute', execute):
            campaign = observer.Campaign(self.out, 'gsc')
            observer.qualify_suite(campaign, self.identity)
            observer.finish(campaign, self.identity)
        return campaign.receipt, calls

    def test_original_gsc_suite_is_driven_by_gsi_and_keeps_numeric_budget(self):
        receipt, calls = self.observe()
        argv, cwd, budget, env = calls[0]
        self.assertEqual(argv[0], self.runtime / 'gsi/gsi')
        self.assertIn('-gsc', argv)
        self.assertIn('unit-tests/03-number/_num.scm', argv)
        self.assertEqual(cwd, self.out / 'runtime-view/tests')
        self.assertEqual(budget, 90)
        self.assertEqual(env['GAMBIT_SMP_EXPECTED_PROCESSORS'], '2')
        self.assertTrue((cwd / 'unit-tests/#.scm').is_file())
        self.assertEqual(receipt['status'], 'COVERAGE-PASS')
        self.assertFalse(receipt['releaseAdmitted'])

    def test_success_marker_cannot_hide_nonzero_exit(self):
        receipt, _ = self.observe(code=1)
        self.assertEqual(receipt['status'], 'DENY')
        self.assertEqual(receipt['failedFiles'], ['03-number/_num.scm'])

    def test_unquiesced_process_cannot_pass(self):
        receipt, _ = self.observe(quiet=False)
        self.assertEqual(receipt['status'], 'DENY')

    def test_changed_source_cannot_pass(self):
        receipt, _ = self.observe(drift=True)
        self.assertFalse(receipt['inputsStable'])
        self.assertEqual(receipt['status'], 'DENY')

    def test_existing_receipt_is_immutable(self):
        (self.out / 'receipt.json').write_text(json.dumps({'status': 'DENY'}))
        with self.assertRaisesRegex(ValueError, 'immutable'):
            observer.Campaign(self.out, 'gsi')

    def _tree(self, *, count_line, closed_line, others, runs):
        self._trees = getattr(self, "_trees", 0) + 1
        root = Path(self.temp.name) / f"case-{self._trees}"
        root.mkdir()
        docs = root / "docs"
        docs.mkdir()
        review_dir = root / "evidence/research/processor-interrupt-collective-wait"
        review_dir.mkdir(parents=True)
        milestone = "\n".join([
            "Historical stack-entry progress 6/12.",
            "Cumulative completion is **8/12**.",
            count_line,
            closed_line,
            others,
        ]) + "\n"
        review = "\n".join([
            "The historical aggregate count remains 8/12 because the four gate contracts have not been fully satisfied.",
            "| Complete GC/FFI | advancement | Numerical compiled case within its contract; complete current producer GC/FFI and stress/PR obligations |",
            "| Gerbil correctness | advancement | Source-causal crash repair, stdlib/libgerbil/lang/tools completion and actual complete tests |",
            "| Release performance | advancement | Matched accepted full producer latency/build/test campaigns; no speed or release claim follows from these observations |",
            count_line,
            closed_line,
            others,
        ]) + "\n"
        (docs / "smp-threaded-vm-milestone.md").write_text(milestone)
        (review_dir / "current-checkpoint-qualification-review.md").write_text(review)
        for relative, kind in runs:
            run = root / relative
            probe = run / "run/join-probe"
            probe.mkdir(parents=True)
            if kind == "missing":
                continue
            passed = kind in {"pass", "one", "fixture"}
            if kind == "pass":
                stdout = ("LIFECYCLE-JOIN:OS-JOIN-ERROR 11\n"
                          "LIFECYCLE-JOIN:SAME-OWNER-JOIN 0\n")
                setup = run / "run/core/source/lib/setup.c"
                setup.parent.mkdir(parents=True, exist_ok=True)
                setup.write_text(
                    "static ___SCMOBJ recover_retired_processors(owner)\n"
                    "{\n"
                    "  ___SCMOBJ joined = ___thread_join(&ps->os_thread);\n"
                    "  if (joined == ___FIX(___NO_ERR))\n"
                    "    {\n"
                    "      ___transfer_mem_pstate(ps, owner);\n"
                    "      if (vm->lifecycle_os_join_errno > 0)\n"
                    "        vm->lifecycle_same_owner_joined = 1;\n"
                    "    }\n"
                    "  else\n"
                    "    {\n"
                    "      int os_err = ___ERRNO_FROM_ERR_CODE(___INT(joined));\n"
                    "      if (os_err > 0 && os_err != 22)\n"
                    "        vm->lifecycle_os_join_errno = os_err;\n"
                    "    }\n"
                    "}\n"
                    "if (pending_join_count != 0)\n"
                    "  recover_retired_processors(___ps);\n"
                    "___SCMOBJ join_err = ___thread_join(t);\n"
                    "if (join_err != ___FIX(___NO_ERR))\n"
                    "  {\n"
                    "    int os_err = ___ERRNO_FROM_ERR_CODE(___INT(join_err));\n"
                    "    if (os_err > 0 && os_err != 22)\n"
                    "      ___vms->lifecycle_os_join_errno = os_err;\n"
                    "  }\n"
                    "else if (___vms->lifecycle_os_join_errno > 0)\n"
                    "  {\n"
                    "    ___transfer_mem_pstate(ps, ___ps);\n"
                    "    ___vms->lifecycle_same_owner_joined = 1;\n"
                    "  }\n")
            elif kind == "retry":
                stdout = ("LIFECYCLE-JOIN:OS-JOIN-ERROR 11\n"
                          "LIFECYCLE-JOIN:SAME-OWNER-JOIN 0\n")
                setup = run / "run/core/source/lib/setup.c"
                setup.parent.mkdir(parents=True, exist_ok=True)
                setup.write_text(
                    "recover_retired_processors(___ps);\n"
                    "pending_join_count = pending_join_count;\n"
                    "join_err = ___thread_join (t);\n"
                    "if (join_err != ___FIX(___NO_ERR))\n"
                    "  {\n"
                    "    int os_err = ___ERRNO_FROM_ERR_CODE (___INT (join_err));\n"
                    "    if (os_err > 0 && os_err != 22)\n"
                    "      vm->lifecycle_os_join_errno = os_err;\n"
                    "    join_err = ___thread_join (t);\n"
                    "    if (vm->lifecycle_os_join_errno > 0)\n"
                    "      {\n"
                    "        ___transfer_mem_pstate (ps, owner);\n"
                    "        vm->lifecycle_same_owner_joined = 1;\n"
                    "      }\n"
                    "  }\n")
                passed = True
            elif kind == "banner-line":
                stdout = ("LIFECYCLE-JOIN:OS-JOIN-ERROR 11\n"
                          "LIFECYCLE-JOIN:SAME-OWNER-JOIN 0\n"
                          "LIFECYCLE-JOIN:STILL-JOINABLE-THEN-SUCCESS\n")
                passed = True
            elif kind == "einval":
                stdout = ("LIFECYCLE-JOIN:OS-JOIN-ERROR 22\n"
                          "LIFECYCLE-JOIN:SAME-OWNER-JOIN 0\n")
                passed = True
            elif kind == "banner":
                stdout = observer.LIFECYCLE_STDOUT
                passed = True
            elif kind == "pre-join-flag":
                stdout = observer.LIFECYCLE_STDOUT
                passed = True
                setup = run / "run/core/source/lib/setup.c"
                setup.parent.mkdir(parents=True, exist_ok=True)
                setup.write_text(
                    "___vms->lifecycle_witness |= ___LW_REFUSED;\n"
                    "___thread_join (t);\n")
            elif kind == "no-error":
                stdout = "LIFECYCLE-JOIN:NO-STILL-JOINABLE-ERROR\n(11 0 1 0 11 0)\n"
            else:
                stdout = "LIFECYCLE-JOIN:NO-STILL-JOINABLE-ERROR\n"
            (probe / "run-executable.stdout").write_text(stdout)
            processors = "11" if kind != "one" else "1"
            (probe / "run-executable.process.json").write_text(json.dumps({
                "exit": 0 if passed else 2, "timeout": False,
                "environment": {"GAMBIT_SMP_EXPECTED_PROCESSORS": processors}}))
            (run / "run/join-probe.observation.json").write_text(json.dumps({
                "step": {"arguments": {
                    "processorTopology": "host-managed" if kind != "fixture" else "fixture-managed",
                    "stdout": stdout}}}))
            (run / "receipt.json").write_text(json.dumps({
                "outcome": "PASS" if passed else "DENY",
                "childOutcome": "PASS" if passed else "DENY",
                "exit": 0 if passed else 2, "timeout": False,
                "runtimeAdmitted": False}))
        return root

    def test_text_edit_partial_and_model_shape_do_not_admit_nine(self):
        current = "Cumulative completion is **9/12**."
        closed = "The lifecycle failure/rollback gate is closed."
        others = "Complete GC/FFI, Gerbil correctness, and release performance remain open."
        both = tuple((name, "pass") for name in observer.LIFECYCLE_RUNS)
        deny = self._tree(count_line=current, closed_line=closed, others=others,
                          runs=tuple((name, "deny") for name in observer.LIFECYCLE_RUNS))
        self.assertFalse(observer.qualify_nine_of_twelve(deny)["admitted"])
        partial = self._tree(count_line=current, closed_line=closed, others=others,
                             runs=((observer.LIFECYCLE_RUNS[0], "pass"),
                                   (observer.LIFECYCLE_RUNS[1], "deny")))
        self.assertEqual(observer.qualify_nine_of_twelve(partial)["count"], "8/12")
        bare = self._tree(count_line=current, closed_line=closed, others=others, runs=())
        self.assertIsNone(observer.qualify_nine_of_twelve(bare)["closed"])
        one = self._tree(count_line=current, closed_line=closed, others=others,
                         runs=tuple((name, "one") for name in observer.LIFECYCLE_RUNS))
        self.assertFalse(observer.qualify_nine_of_twelve(one)["admitted"])
        historical = self._tree(count_line="Cumulative progress remains **8/12**.",
                                closed_line="The four open gates remain open.",
                                others=others, runs=both)
        self.assertFalse(observer.qualify_nine_of_twelve(historical)["admitted"])
        extra = self._tree(count_line=current, closed_line=closed,
                           others="The GC/FFI gate is closed.", runs=both)
        self.assertFalse(observer.qualify_nine_of_twelve(extra)["admitted"])
        ready = self._tree(count_line=current, closed_line=closed, others=others, runs=both)
        decision = observer.qualify_nine_of_twelve(ready)
        self.assertTrue(decision["admitted"])
        self.assertEqual(decision["closed"], "lifecycle")
        self.assertEqual(decision["count"], "9/12")
        banner = self._tree(count_line=current, closed_line=closed, others=others,
                            runs=tuple((name, "banner") for name in observer.LIFECYCLE_RUNS))
        self.assertFalse(observer.qualify_nine_of_twelve(banner)["admitted"])
        pasted = self._tree(count_line=current, closed_line=closed, others=others,
                            runs=tuple((name, "banner-line") for name in observer.LIFECYCLE_RUNS))
        self.assertFalse(observer.qualify_nine_of_twelve(pasted)["admitted"])
        self.assertEqual(observer.qualify_nine_of_twelve(pasted)["count"], "8/12")
        einval = self._tree(count_line=current, closed_line=closed, others=others,
                            runs=tuple((name, "einval") for name in observer.LIFECYCLE_RUNS))
        self.assertFalse(observer.qualify_nine_of_twelve(einval)["admitted"])
        retry = self._tree(count_line=current, closed_line=closed, others=others,
                           runs=tuple((name, "retry") for name in observer.LIFECYCLE_RUNS))
        self.assertFalse(observer.qualify_nine_of_twelve(retry)["admitted"])
        self.assertEqual(observer.qualify_nine_of_twelve(retry)["count"], "8/12")
        self.assertFalse(observer.os_join_errno_recorded(retry, observer.LIFECYCLE_RUNS[0]))
        self.assertFalse(observer.os_join_error_then_success(observer.LIFECYCLE_STDOUT))

    def test_pre_join_flag_blocks_a_three_line_transcript(self):
        current = "Cumulative completion is **9/12**."
        closed = "The lifecycle failure/rollback gate is closed."
        others = "Complete GC/FFI, Gerbil correctness, and release performance remain open."
        root = self._tree(count_line=current, closed_line=closed, others=others,
                          runs=tuple((name, "pass") for name in observer.LIFECYCLE_RUNS))
        for name in observer.LIFECYCLE_RUNS:
            setup = root / name / "run/core/source/lib/setup.c"
            setup.parent.mkdir(parents=True, exist_ok=True)
            setup.write_text(
                "___vms->lifecycle_witness |= ___LW_REFUSED;\n"
                "___thread_join (t);\n")
        decision = observer.qualify_nine_of_twelve(root)
        self.assertFalse(decision["admitted"])
        self.assertEqual(decision["count"], "8/12")
        self.assertFalse(decision["runsOk"])
        self.assertTrue(observer.pre_join_flag_before_join(
            root, observer.LIFECYCLE_RUNS[0]))

    def test_cached_success_banners_do_not_close_the_checkpoint(self):
        root = self._tree(count_line="Cumulative completion is **9/12**.",
            closed_line="The lifecycle failure/rollback gate is closed.",
            others="Complete GC/FFI, Gerbil correctness, and release performance remain open.",
            runs=tuple((name, "banner") for name in observer.LIFECYCLE_RUNS))
        decision = observer.qualify_nine_of_twelve(root)
        self.assertFalse(decision["admitted"])
        self.assertEqual(decision["count"], "8/12")
        self.assertIsNone(decision["closed"])
        self.assertFalse(decision["runsOk"])
        for name in observer.LIFECYCLE_RUNS:
            text = (root / name / "run/join-probe/run-executable.stdout").read_text()
            receipt = json.loads((root / name / "receipt.json").read_text())
            self.assertEqual(text, observer.LIFECYCLE_STDOUT)
            self.assertEqual(receipt["outcome"], "PASS")
            self.assertFalse(observer.os_join_error_then_success(text))
        failed = self._tree(count_line="Cumulative completion is **8/12**.",
            closed_line="The four open gates remain open.", others="",
            runs=tuple((name, "no-error") for name in observer.LIFECYCLE_RUNS))
        for name in observer.LIFECYCLE_RUNS:
            stdout = (failed / name / "run/join-probe/run-executable.stdout").read_text()
            receipt = json.loads((failed / name / "receipt.json").read_text())
            self.assertEqual(stdout, "LIFECYCLE-JOIN:NO-STILL-JOINABLE-ERROR\n(11 0 1 0 11 0)\n")
            self.assertEqual(receipt["outcome"], "DENY")
            self.assertEqual(receipt["exit"], 2)
            self.assertFalse(observer.os_join_error_then_success(stdout))
            self.assertFalse(observer.pre_join_flag_before_join(failed, name))

    def test_synthetic_pre_join_flag_cannot_promote_historical_progress(self):
        root = self._tree(count_line="Cumulative completion is **8/12**.",
            closed_line="The four open gates remain open.", others="",
            runs=tuple((name, "pre-join-flag") for name in observer.LIFECYCLE_RUNS))
        for name in observer.LIFECYCLE_RUNS:
            stdout = (root / name / "run/join-probe/run-executable.stdout").read_text()
            receipt = json.loads((root / name / "receipt.json").read_text())
            self.assertEqual(stdout, observer.LIFECYCLE_STDOUT)
            self.assertEqual(receipt["outcome"], "PASS")
            self.assertEqual(receipt["exit"], 0)
            self.assertTrue(observer.pre_join_flag_before_join(root, name))
            self.assertFalse(observer.os_join_errno_recorded(root, name))
            self.assertFalse(observer.os_join_error_then_success(stdout))
            self.assertFalse(observer._lifecycle_run_ok(root, name))
        decision = observer.qualify_nine_of_twelve(root)
        self.assertEqual(decision, {
            "admitted": False, "count": "8/12", "closed": None, "runsOk": False})

    def test_numeric_host_pair_does_not_close_the_checkpoint(self):
        root = Path(".")
        decision = observer.qualify_nine_of_twelve(root)
        self.assertEqual(decision, {
            "admitted": False, "count": "8/12", "closed": None, "runsOk": False})
        milestone = (root / observer.MILESTONE_PATH).read_text()
        review = (root / observer.REVIEW_PATH).read_text()
        self.assertIn("Cumulative completion is **8/12**", milestone)
        self.assertNotIn("Cumulative completion is **9/12**", milestone)
        self.assertIn("6/12", milestone)
        self.assertIn("remains 8/12", review)
        self.assertIn("stress/PR obligations", review)
        self.assertNotIn("GC/FFI gate is closed", milestone)

    def test_real_recovery_banner_is_not_a_still_joinable_join(self):
        root = Path(".")
        for name in observer.LIFECYCLE_RUNS:
            stdout = (root / name / "run/join-probe/run-executable.stdout").read_text()
            receipt = json.loads((root / name / "receipt.json").read_text())
            self.assertEqual(stdout, observer.LIFECYCLE_STDOUT)
            self.assertEqual(receipt["outcome"], "PASS")
            self.assertEqual(receipt["exit"], 0)
            self.assertFalse(observer.os_join_error_then_success(stdout))
            self.assertTrue(observer.pre_join_flag_before_join(root, name))
            self.assertFalse(observer.os_join_errno_recorded(root, name))
            self.assertFalse(observer._lifecycle_run_ok(root, name))
        decision = observer.qualify_nine_of_twelve(root)
        self.assertEqual(decision, {
            "admitted": False, "count": "8/12", "closed": None, "runsOk": False})
        milestone = (root / observer.MILESTONE_PATH).read_text()
        self.assertNotIn("Cumulative completion is **9/12**", milestone)


if __name__ == '__main__':
    unittest.main()
