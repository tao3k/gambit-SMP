"""Source-guided retirement requirements, not native RC lifetime proof."""
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp import recipes


class RetiredRcGcVisibilityTests(unittest.TestCase):
    def test_root_closure_imports_rc_protocol_without_weakening_inventory(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/vector-arity-retired-root-closure.recipe.json"
        recipes.load(ROOT, path)
        recipe = json.loads(path.read_text())
        model = (ROOT / "models/gambit/retired_root_closure.qnt").read_text()
        self.assertIn("R::transfer", model)
        self.assertIn("R::collect", model)
        self.assertIn("R::safe and accounting and stillClosure", model)
        controls = [s["arguments"]["initializer"] for s in recipe["steps"]
                    if s["capability"] == "quint.verify" and s["arguments"]["negative"]]
        self.assertEqual(["initRcOnly", "initDroppedDeferred"], controls)
        trajectories = next(s for s in recipe["steps"] if s["capability"] == "quint.test")
        names = trajectories["arguments"]["expectedTests"]
        self.assertEqual(9, len(names))
        self.assertEqual(5, sum(name.startswith("R::") for name in names))
        self.assertFalse(any(s["capability"] == "gambit.bootstrap" for s in recipe["steps"]))

    def test_native_still_closure_removes_rc_before_second_gc(self):
        program = (ROOT / "models/gambit/native/retired_root_closure.scm").read_text()
        self.assertIn("___make_pair)(___ps, ___FIX(id), ___FAL)", program)
        self.assertIn("___CDR_FIELD(still[id]) = value", program)
        self.assertIn("___release_scmobj", program)
        self.assertIn("(##current-vm-processor-count)", program)
        rc_release = program.index("    (release-rc!)")
        second_gc = program.index("    (##gc)", rc_release)
        still_check = program.index("(require (moved? id)", second_gc)
        still_release = program.index("    (release-still!)", still_check)
        self.assertLess(rc_release, second_gc)
        self.assertLess(second_gc, still_check)
        self.assertLess(still_check, still_release)
        for forbidden in ("RTLD_NEXT", "dlsym", "pthread_join", "___cleanup_owned_vmstate"):
            self.assertNotIn(forbidden, program)

    def test_locked_model_recipe_has_independent_failure_controls(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/retired-rc-gc-visibility.recipe.json"
        recipes.load(ROOT, path)
        recipe = json.loads(path.read_text())
        self.assertEqual(300, recipe["budgetSeconds"])
        controls = [row["arguments"]["initializer"] for row in recipe["steps"]
                    if row["capability"] == "quint.verify" and row["arguments"]["negative"]]
        self.assertEqual(["initCurrentRetention", "initTransferWithoutAck"], controls)
        self.assertFalse(any(row["capability"] == "gambit.bootstrap" for row in recipe["steps"]))
        self.assertEqual("gambit.materialize", recipe["steps"][0]["capability"])

    def test_current_source_keeps_transfer_conditional_on_join_success(self):
        lock = json.loads((ROOT / "evidence/fixtures/vector-increment-arity-parity/source.lock.json").read_text())
        source = (ROOT / lock["patch"]).read_text()
        self.assertIn("mark_rc (___PSPNC); /* rc_head is per processor */", source)
        self.assertIn("/* Memory ownership remains with this slot until P0 joins it. */", source)
        self.assertRegex(source, r"if \(joined == ___FIX\(___NO_ERR\)\)\s*\n\+\s*\{\s*\n\+\s*___transfer_mem_pstate")
        self.assertRegex(source, r"if \(join_err == ___FIX\(___NO_ERR\)\)\s*\n\+\s*\{\s*\n\+\s*___transfer_mem_pstate")
        base = (ROOT / "vendor/gambit/lib/mem.c").read_text()
        self.assertIn("___rc_header *h = rc_head.next;", base)
        self.assertIn("mark_array (___PSP &h->data, 1);", base)

    def test_existing_native_join_fixture_does_not_cover_postfailure_gc(self):
        fixture = (ROOT / "models/gambit/native/pending_join_errno_recovery.scm").read_text()
        tail = fixture[fixture.index('(arm!)\n      (require'):]
        self.assertNotIn("(##gc)", tail)
        self.assertIn("expected-join-error", tail)

    def test_positive_native_control_uses_standard_rc_ffi_and_adaptive_population(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/vector-arity-retired-rc-positive.recipe.json"
        recipes.load(ROOT, path)
        recipe = json.loads(path.read_text())
        native = next(row for row in recipe["steps"] if row["id"] == "retired-rc-control")
        self.assertEqual(300, recipe["budgetSeconds"])
        self.assertEqual("host-managed", native["arguments"]["processorTopology"])
        self.assertEqual(30, native["arguments"]["executionBudgetSeconds"])
        self.assertIn("rc-safe", native["dependsOn"])
        self.assertIn("rc-retention-control", native["dependsOn"])
        program = (ROOT / native["arguments"]["program"]).read_text()
        for fragment in ("___alloc_rc", "___set_data_rc", "___data_rc", "___release_rc",
                         "(##current-vm-processor-count)", "(##gc)", "(moved? index)"):
            self.assertIn(fragment, program)
        for forbidden in ("RTLD_NEXT", "dlsym", "___cleanup_owned_vmstate", "pthread_join"):
            self.assertNotIn(forbidden, program)

    def test_exit_tail_control_compiles_exact_source_projection(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/retired-rc-exit-tail.recipe.json"
        recipes.load(ROOT, path)
        recipe = json.loads(path.read_text())
        self.assertNotIn("native.c-build", [row["capability"] for row in recipe["steps"]])
        project = next(row for row in recipe["steps"] if row["id"] == "exit-tail-project")
        primitive = next(row for row in project["arguments"]["files"]
                         if row["origin"]["kind"] == "source-artifact")
        lock = json.loads((ROOT / recipe["steps"][0]["arguments"]["sourceLock"]).read_text())
        self.assertEqual("lib/os_thread.c", primitive["origin"]["path"])
        self.assertEqual(lock["files"]["lib/os_thread.c"]["candidateSha256"], primitive["sha256"])
        self.assertEqual(1, len(primitive["ranges"]))
        program = (ROOT / "models/gambit/native/pthread_exit_tail_ack.c").read_text()
        self.assertIn('#include "gambit-thread-exit.c"', program)
        self.assertIn("___thread_exit();", program)
        self.assertIn("pthread_key_create(&key, destructor)", program)
        self.assertIn('getenv("GAMBIT_SMP_AVAILABLE_CPUS")', program)
        self.assertNotIn("RTLD_NEXT", program)
        cases = next(row for row in recipe["steps"] if row["id"] == "exit-tail-controls")["arguments"]["cases"]
        self.assertEqual(1, cases[1]["expectedExit"])
        self.assertTrue(cases[1]["negativeControl"])

    def test_exit_tail_model_imports_parent_and_exact_trajectories(self):
        recipe = json.loads((ROOT / "evidence/research/vm-registry-reader-lease/retired-rc-exit-tail.recipe.json").read_text())
        sample = next(row for row in recipe["steps"] if row["capability"] == "quint.test")
        self.assertEqual(7, len(sample["arguments"]["expectedTests"]))
        self.assertEqual(5, sum(name.startswith("R::") for name in sample["arguments"]["expectedTests"]))
        model = (ROOT / "models/gambit/retired_rc_exit_tail.qnt").read_text()
        self.assertIn('import retired_rc_gc_visibility as R', model)
        self.assertIn("R::transfer", model)
        self.assertIn("R::collect", model)
