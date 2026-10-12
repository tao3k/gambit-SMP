from contextlib import ExitStack
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.source_materialize import locked_source


class NotificationSourceCandidateTests(unittest.TestCase):
    def test_candidate_delta_preserves_count_and_scan_body(self):
        with ExitStack() as stack:
            baseline, _ = stack.enter_context(locked_source(ROOT, "evidence/runtime-source-026.lock.json"))
            candidate, _ = stack.enter_context(locked_source(ROOT, "evidence/runtime-source-029.lock.json"))
            old = (baseline / "lib/mem.c").read_text()
            new = (candidate / "lib/mem.c").read_text()
            signal = "      ___CONDVAR_SIGNAL(scan_termination_condvar);\n#endif"
            self.assertEqual(old.count(signal), 1)
            revised = old.replace(signal,
                "      /* Match wait registration without nesting the queue lock under M. */\n"
                "      ___MUTEX_LOCK(scan_termination_mutex);\n"
                "      ___CONDVAR_SIGNAL(scan_termination_condvar);\n"
                "      ___MUTEX_UNLOCK(scan_termination_mutex);\n#endif")
            start = new.index("      /* Recheck every queue before relinquishing active-scanner ownership. */")
            end = new.index("      if (--(*workers_count) == 0)", start)
            recheck = new[start:end]
            self.assertIn("for (i=np-1; i>=0; i--)", recheck)
            self.assertIn("___PSTATE_FROM_PROCESSOR_ID(i,___vms)", recheck)
            self.assertLess(recheck.index("___SPINLOCK_UNLOCK"), recheck.index("if (pending)"))
            self.assertIn("___MUTEX_UNLOCK(scan_termination_mutex);\n              goto continue_local_scan;", recheck)
            marker = "      if (--(*workers_count) == 0)"
            self.assertEqual(revised.count(marker), 1)
            self.assertEqual(new, revised.replace(marker, recheck + marker))
            for name in ("configure.ac", "lib/_thread.scm", "lib/setup.c", "include/gambit.h.in"):
                self.assertEqual((baseline / name).read_bytes(), (candidate / name).read_bytes())
            self.assertEqual((candidate / "lib/mem.h").read_text(),
                (baseline / "lib/mem.h").read_text().replace(
                    "extern void ___glo_list_add", "extern ___SCMOBJ ___glo_list_add"))


if __name__ == "__main__":
    unittest.main()
