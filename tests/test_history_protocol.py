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
from unittest.mock import patch
from concurrent.futures import ThreadPoolExecutor

from gambit_smp.framework import ROOT, digest
from gambit_smp.quint_backend import check


class HistoryProtocolTests(unittest.TestCase):
    validation_after_domains = True

    def test_exhaustive_safety_temporal_and_five_decoded_negative_controls(self):
        engine = os.environ.get("GAMBIT_SMP_TEST_ENGINE")
        if engine:
            from gambit_smp.research_kernel import manifest_paths
            manifest = manifest_paths(Path(engine).resolve(strict=True))
            quint = manifest["hostTools"]["quint"]["path"]
            node = Path(manifest["hostTools"]["node"]["path"]).resolve(strict=True)
            context = patch.dict(os.environ, {"PATH": str(node.parent) + os.pathsep + "/usr/bin:/bin"})
        else:
            from contextlib import nullcontext
            quint = shutil.which("quint")
            context = nullcontext()
        with context:
            self.check_protocol(quint)

    def check_protocol(self, quint):
        self.assertIsNotNone(quint, "actual Quint required; no skipped formal qualification")
        jar = Path(os.environ.get("QUINT_TLC_JAR", str(ROOT /
                   ".data/tools/apalache-0.62.1/lib/apalache.jar")))
        self.assertTrue(jar.is_file(), "actual TLC jar required")
        sources = sorted((ROOT / "models/library").glob("HistoryJournal*.qnt"))
        inputs = {str(path): digest(path) for path in sources}
        config = ROOT / "tests/fixtures/history-protocol-tlc.json"
        inputs[str(config)] = digest(config)
        inputs.update({str(jar): digest(jar), str(Path(quint).resolve()): digest(Path(quint).resolve())})
        from gambit_smp.artifact_storage import cache_path
        archive = Path(os.environ.get("GAMBIT_SMP_TEST_ARTIFACTS", str(cache_path(ROOT, "history-protocol"))))
        archive.mkdir(parents=True, exist_ok=True)
        out = Path(tempfile.mkdtemp(prefix="run-", dir=archive))
        print("History protocol raw archive:", out, flush=True)
        deadline = time.monotonic() + 60
        variants = ("Checked", "Lost", "Failed", "Early", "ABA", "Lineage")

        def check_variant(variant):
            directory = out / variant
            directory.mkdir()
            model = ROOT / ("models/library/HistoryJournal" + variant + ".qnt")
            row, log, trace = check(model, initializer="init", invariant="Safe",
                                    negative=variant != "Checked", temporal="Properties" if variant == "Checked" else None,
                                    timeout=max(.001, deadline - time.monotonic()), cwd=directory,
                                    executable=quint, config=config, liveness_schedule="final", tlc_jar=jar)
            (directory / "checker.log").write_text(log)
            (directory / "receipt.json").write_text(json.dumps(dict(row, trace=trace, inputs=inputs,
                                                                     logSHA=digest(directory / "checker.log")), indent=2))
            return variant, directory, row, trace

        # Independent controls share one deadline, never six renewed budgets.
        with ThreadPoolExecutor(max_workers=2) as pool:
            checked = list(pool.map(check_variant, variants))
        rows = []
        for variant, directory, row, trace in checked:
            log = (directory / "checker.log").read_text()
            rows.append(row)
            self.assertTrue(row["accepted"], str(directory) + "\n" + log[-3000:])
            self.assertFalse(row["timeout"])
            self.assertEqual(row["checker"]["workers"], 1)
            if variant == "Checked":
                self.assertEqual(row["states"]["queued"], 0)
                self.assertGreater(row["states"]["distinct"], 1)
                self.assertEqual(row["states"]["distinct"], 736)
                self.assertEqual(row["states"]["generated"], 4811)
            else:
                self.assertGreater(len(trace["states"]), 1)
        self.assertLess(time.monotonic(), deadline)
        self.assertTrue(all(digest(Path(path)) == sha for path, sha in inputs.items()))
        (out / "receipt.json").write_text(json.dumps(dict(inputs=inputs, controls=rows, controlWorkers=2,
                                                        budgetSeconds=60, runtimeAdmitted=False), indent=2))


if __name__ == "__main__":
    unittest.main()
