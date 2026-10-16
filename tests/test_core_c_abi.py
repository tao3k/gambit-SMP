"""Actual consumer DSL through the installed fixed Core C ABI, not bridge mocks."""
import unittest
from ascent import Engine
from gambit_smp.framework import ROOT


class CoreCAbiConsumerTests(unittest.TestCase):
    def test_real_mainpath_answers_match_direct_library(self):
        engine = Engine(backend="rust", workers=2)
        try:
            for files, constructor in [
                (("catalog.ss", "catalog/reports.ss", "catalog/observations.ss", "catalog/protocols.ss"), "make-catalog"),
                (("review.ss", "review/receipts.ss"), "make-review"),
                (("history.ss",), "make-history"),
            ]:
                source = "\n".join((ROOT / "evidence/dsl" / name).read_text() for name in files)
                foreign = engine.core_evidence(source, constructor, trusted=True)
                direct = engine.evidence(source, constructor, trusted=True)
                try:
                    receipt = direct.run()
                    result = direct.result(receipt)
                    actual = foreign.run().value()
                    self.assertTrue(actual["complete"])
                    self.assertEqual(actual["relations"], {
                        name: result.graph(name) for name in receipt["relations"]
                    })
                    result.close()
                finally:
                    foreign.close()
                    direct.close()
        finally:
            engine.close()

    def test_rayon_worker_answers_and_withdrawal_are_identical(self):
        source = (ROOT / "evidence/dsl/history.ss").read_text()
        answers = []
        for workers in (1, 4):
            engine = Engine(backend="rust", workers=workers)
            owner = engine.core_evidence(source, trusted=True, diagnostics=True)
            try:
                self.assertEqual(owner.runtime().value()["workers"], workers)
                owner.run().value()
                owner.replace({"previous_row": [["q", "old"]], "current_row": [["q", "new"]]}).value()
                first = owner.run().value()
                self.assertTrue(first["complete"])
                answers.append(first["relations"])
                owner.replace({"current_row": [["q", "old"]]}).value()
                second = owner.run().value()
                self.assertEqual(second["relations"]["added"]["root"], {"type": "null"})
                self.assertEqual(second["relations"]["removed"]["root"], {"type": "null"})
                self.assertTrue(owner.diagnose().value()["enabled"])
            finally:
                owner.close()
                engine.close()
        self.assertEqual(answers[0], answers[1])
