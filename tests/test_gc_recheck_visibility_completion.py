"""Finite visibility qualification and current-source handshake retention."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import bundle_facts
from gambit_smp.source_materialize import locked_source


MANIFEST = "evidence/fixtures/sfun-owned-unwind/recheck-visibility-contract.json"
RECEIPT = "evidence/model-results/fixtures/sfun-owned-unwind/recheck-visibility-registered/receipt.json"


class RecheckVisibilityCompletionTests(unittest.TestCase):
    def test_counterexamples_and_exhaustive_finite_completion(self):
        facts, _ = bundle_facts(ROOT, MANIFEST, RECEIPT)
        self.assertEqual(len(facts["protocol_control"]), 2)
        self.assertEqual(len(facts["protocol_checked"]), 1)
        receipt = json.loads((ROOT / RECEIPT).read_text())
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertFalse(receipt["releaseAdmitted"])
        positive = [r for r in receipt["results"] if r["variant"] == "protocol"]
        self.assertEqual(len(positive), 1)
        self.assertEqual(positive[0]["states"]["distinct"], 15)
        self.assertEqual(positive[0]["states"]["queued"], 0)
        self.assertEqual(positive[0]["temporal"], "completion")

    def test_import_identity_and_registered_receipt(self):
        manifest = json.loads((ROOT / MANIFEST).read_text())
        imported = "models/gambit/gc_recheck_visibility.qnt"
        self.assertEqual(manifest["contextInputs"][imported], digest(ROOT / imported))
        self.assertEqual(manifest["cases"][0]["dependencies"], ["gc_recheck_visibility.qnt"])
        self.assertEqual(manifest["cases"][0]["composes"], [])
        registry = json.loads((ROOT / "evidence/protocol-bundles.json").read_text())
        self.assertIn([MANIFEST, RECEIPT], registry["bundles"])

    def test_current_source_preserves_publication_and_registration_order(self):
        lock = "evidence/fixtures/sfun-owned-unwind/source.lock.json"
        with locked_source(ROOT, lock) as (source, _):
            text = (source / "lib/mem.c").read_text()
        publication = (
            "___SPINLOCK_UNLOCK(heap_chunks_to_scan_lock);\n"
            "      /* Match wait registration without nesting the queue lock under M. */\n"
            "      ___MUTEX_LOCK(scan_termination_mutex);\n"
            "      ___CONDVAR_SIGNAL(scan_termination_condvar);\n"
            "      ___MUTEX_UNLOCK(scan_termination_mutex);"
        )
        self.assertEqual(text.count(publication), 1)
        start = text.index("      /* Recheck every queue")
        end = text.index("\n#endif\n}", start)
        waiting = text[start:end]
        self.assertTrue(text[:start].endswith("___MUTEX_LOCK(scan_termination_mutex);\n\n"))
        decrement = waiting.index("if (--(*workers_count) == 0)")
        recheck = waiting[:decrement]
        self.assertIn("for (i=np-1; i>=0; i--)", recheck)
        self.assertIn("ps->mem.heap_chunks_to_scan_head_ !=", recheck)
        self.assertLess(recheck.index("___SPINLOCK_UNLOCK"), recheck.index("if (pending)"))
        self.assertIn("___MUTEX_UNLOCK(scan_termination_mutex);\n              goto continue_local_scan;", recheck)
        nonzero = waiting[waiting.index("/* Other processors are still actively scanning chunks */"):]
        wait = nonzero.index("___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex);")
        self.assertNotIn("___MUTEX_UNLOCK", nonzero[:wait])
        self.assertLess(nonzero.index("if (*workers_count == 0)"), nonzero.index("(*workers_count)++;"))
        restored = nonzero[nonzero.index("(*workers_count)++;"):]
        self.assertIn("___MUTEX_UNLOCK(scan_termination_mutex);", restored)


if __name__ == "__main__":
    unittest.main()
