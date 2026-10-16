"""Finite journal safety/conditional progress and decoded fault controls.

Uses the existing shared Quint/TLC backend, not a Python transition simulator.
These framework checks do not admit research or runtime/source refinement.
"""
import json
import os
from pathlib import Path
import shutil
import tempfile
import time
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.quint_backend import check


class HistoryProtocolTests(unittest.TestCase):
    def test_exhaustive_safety_temporal_and_five_decoded_negative_controls(self):
        quint = shutil.which("quint")
        self.assertIsNotNone(quint, "actual Quint required; no skipped formal qualification")
        jar = Path(os.environ.get("QUINT_TLC_JAR", str(ROOT /
                   ".data/tools/apalache-0.62.1/lib/apalache.jar")))
        self.assertTrue(jar.is_file(), "actual TLC jar required")
        sources = sorted((ROOT / "models/library").glob("HistoryJournal*.qnt"))
        inputs = {str(path): digest(path) for path in sources}
        inputs.update({str(jar): digest(jar), str(Path(quint).resolve()): digest(Path(quint).resolve())})
        archive = Path(os.environ.get("GAMBIT_SMP_TEST_ARTIFACTS", str(ROOT / ".data/history-protocol")))
        archive.mkdir(parents=True, exist_ok=True)
        out = Path(tempfile.mkdtemp(prefix="run-", dir=archive))
        print("History protocol raw archive:", out, flush=True)
        deadline = time.monotonic() + 60
        rows = []
        for variant in ("Checked", "Lost", "Failed", "Early", "ABA", "Lineage"):
            directory = out / variant
            directory.mkdir()
            model = ROOT / ("models/library/HistoryJournal" + variant + ".qnt")
            row, log, trace = check(model, initializer="init", invariant="Safe",
                                    negative=variant != "Checked", temporal="Properties" if variant == "Checked" else None,
                                    timeout=max(.001, deadline - time.monotonic()), cwd=directory,
                                    executable=quint, liveness_schedule="final", tlc_jar=jar)
            (directory / "checker.log").write_text(log)
            (directory / "receipt.json").write_text(json.dumps(dict(row, trace=trace, inputs=inputs,
                                                                     logSHA=digest(directory / "checker.log")), indent=2))
            rows.append(row)
            self.assertTrue(row["accepted"], str(directory) + "\n" + log[-3000:])
            self.assertFalse(row["timeout"])
            if variant == "Checked":
                self.assertEqual(row["states"]["queued"], 0)
                self.assertGreater(row["states"]["distinct"], 1)
            else:
                self.assertGreater(len(trace["states"]), 1)
        self.assertLess(time.monotonic(), deadline)
        self.assertTrue(all(digest(Path(path)) == sha for path, sha in inputs.items()))
        (out / "receipt.json").write_text(json.dumps(dict(inputs=inputs, controls=rows,
                                                        budgetSeconds=60, runtimeAdmitted=False), indent=2))


if __name__ == "__main__":
    unittest.main()
