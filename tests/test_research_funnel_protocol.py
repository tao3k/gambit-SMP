"""Real Lean proofs and exhaustive Quint controls, not a Python simulator."""
from concurrent.futures import ThreadPoolExecutor
import dataclasses
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.process_observation import capture
from gambit_smp.quint_backend import check


class ResearchFunnelProtocolTests(unittest.TestCase):
    validation_after_domains = True

    @classmethod
    def setUpClass(cls):
        from gambit_smp.artifact_storage import cache_path

        archive = cache_path(ROOT, "research-funnel")
        archive.mkdir(parents=True, exist_ok=True)
        cls.out = Path(tempfile.mkdtemp(prefix="run-", dir=archive))
        sources = list((ROOT / "models/library").glob("ResearchFunnel*.qnt"))
        sources += list((ROOT / "models/library/lean").rglob("*.lean"))
        sources += [ROOT / "models/library/lean/lean-toolchain",
                    ROOT / "tests/fixtures/research-funnel-tlc.json", Path(__file__).resolve()]
        cls.inputs = {str(p): digest(p) for p in sources}
        print("Research funnel formal archive:", cls.out, flush=True)

    @classmethod
    def tearDownClass(cls):
        if any(digest(Path(p)) != sha for p, sha in cls.inputs.items()):
            raise AssertionError("formal source/tool identity changed")

    def test_lean_proofs_and_rejected_false_claims(self):
        lean = shutil.which("lean")
        self.assertIsNotNone(lean, "actual pinned Lean required; no skip")
        env = dict(os.environ, ELAN_TOOLCHAIN=(ROOT / "models/library/lean/lean-toolchain").read_text().strip())
        env["LEAN_PATH"] = str(self.out)
        source = ROOT / "models/library/lean/ResearchFunnel.lean"
        prefix = capture([lean, "--print-prefix"], source.parent, 15, env)
        self.assertEqual(prefix.exit, 0, prefix.stderr)
        self.assertFalse(prefix.timeout)
        binary = Path(prefix.stdout.strip()) / "bin/lean"
        self.inputs[str(binary.resolve(strict=True))] = digest(binary)
        commands = [("proof", [lean, "-o", str(self.out / "ResearchFunnel.olean"), str(source)], False)]
        commands += [(name, [lean, str(source.parent / "controls" / (name + ".lean"))], True)
                     for name in ("BootstrapCredit", "StaleCredit")]
        for name, argv, negative in commands:
            row = capture(argv, source.parent, 15, env)
            (self.out / (name + ".json")).write_text(json.dumps(
                dict(dataclasses.asdict(row), argv=argv, inputs=self.inputs), indent=2))
            self.assertFalse(row.timeout)
            self.assertTrue(row.group_quiescent)
            output = row.stdout + row.stderr
            if negative:
                self.assertNotEqual(row.exit, 0)
                self.assertIn("unsolved goals", output)
            else:
                self.assertEqual(row.exit, 0, output)
                self.assertIn("nonNativeCannotChangeCount", output)
                self.assertNotIn("sorryAx", output)
                for line in output.splitlines():
                    if "depends on axioms: [" in line:
                        names = line.split("depends on axioms: [", 1)[1].rstrip("]").split(",")
                        self.assertLessEqual({name.strip() for name in names},
                                             {"propext", "Classical.choice", "Quot.sound"})

    def test_quint_safety_and_eight_decoded_counterexamples(self):
        quint = shutil.which("quint")
        self.assertIsNotNone(quint, "actual Quint required; no skip")
        jar = Path(os.environ.get("QUINT_TLC_JAR", str(ROOT / ".data/tools/apalache-0.62.1/lib/apalache.jar")))
        self.assertTrue(jar.is_file(), "actual TLC jar required")
        self.inputs.update({str(Path(quint).resolve()): digest(Path(quint).resolve()),
                            str(jar): digest(jar)})
        variants = ("Checked", "Early", "Model", "Bootstrap", "Stale", "Launch", "History",
                    "Unknown", "Authorization")

        def verify(variant):
            out = self.out / variant
            out.mkdir()
            row, log, trace = check(ROOT / ("models/library/ResearchFunnel" + variant + ".qnt"),
                initializer="init", invariant="Safe", negative=variant != "Checked",
                timeout=60, cwd=out,
                executable=quint, config=ROOT / "tests/fixtures/research-funnel-tlc.json",
                liveness_schedule="final", tlc_jar=jar)
            (out / "checker.log").write_text(log)
            (out / "receipt.json").write_text(json.dumps(dict(row, trace=trace,
                inputs=self.inputs, logSha256=digest(out / "checker.log")), indent=2))
            return variant, row, trace, log

        with ThreadPoolExecutor(max_workers=2) as pool:
            rows = list(pool.map(verify, variants))
        for variant, row, trace, log in rows:
            self.assertTrue(row["accepted"], variant + "\n" + str(row) + "\n" + log[-2500:])
            self.assertFalse(row["timeout"])
            if variant == "Checked":
                self.assertEqual(row["states"]["queued"], 0)
                self.assertGreater(row["states"]["distinct"], 1)
            else:
                self.assertGreater(len(trace["states"]), 1)


if __name__ == "__main__":
    unittest.main()
