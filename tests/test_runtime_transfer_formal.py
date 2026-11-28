"""Bounded interface proofs through existing checker/process libraries."""
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.framework import ROOT, available_processors, digest
from gambit_smp.process_observation import capture
from gambit_smp.quint_backend import check


class RuntimeTransferFormalTests(unittest.TestCase):
    validation_after_domains = True

    @classmethod
    def setUpClass(cls):
        from gambit_smp.artifact_storage import cache_path
        archive = cache_path(ROOT, "runtime-transfer-formal")
        archive.mkdir(parents=True, exist_ok=True)
        cls.out = Path(tempfile.mkdtemp(prefix="run-", dir=archive))
        cls.lean = ROOT / "models/gambit/lean"
        sources = [ROOT / "models/gambit/runtime_transfer_boundary.qnt",
                   ROOT / "models/library/gc/WorkObligations.qnt",
                   cls.lean / "WorkAccounting.lean", cls.lean / "lakefile.toml",
                   cls.lean / "lean-toolchain", Path(__file__)]
        sources += list((cls.lean / "controls").glob("*.lean"))
        cls.inputs = {str(p.relative_to(ROOT)): digest(p) for p in sources}
        cls.environment = dict(os.environ, ELAN_TOOLCHAIN=(cls.lean / "lean-toolchain").read_text().strip())
        print("Runtime transfer formal archive:", cls.out, flush=True)

    @classmethod
    def tearDownClass(cls):
        if any(digest(ROOT / name) != sha for name, sha in cls.inputs.items()):
            raise AssertionError("formal input changed during qualification")

    def observe(self, name, argv, cwd, budget):
        row = capture(argv, cwd, budget, self.environment)
        (self.out / (name + ".json")).write_text(json.dumps(
            dict(asdict(row), argv=argv, inputs=self.inputs), indent=2) + "\n")
        self.assertFalse(row.timeout, name)
        self.assertTrue(row.group_quiescent, name)
        return row

    def test_lean_conditional_proofs_and_false_controls(self):
        lake = shutil.which("lake")
        self.assertIsNotNone(lake, "fixed Lean/Lake and pinned LeanPoo required; no skip")
        built = self.observe("lean-build", [lake, "build", "WorkAccounting"], self.lean, 120)
        self.assertEqual(built.exit, 0, built.stdout + built.stderr)
        row = self.observe("lean-axioms", [lake, "env", "lean", "-DmaxHeartbeats=200000",
            "-DmaxRecDepth=512", "WorkAccounting.lean"], self.lean, 15)
        self.assertEqual(row.exit, 0, row.stdout + row.stderr)
        output = row.stdout + row.stderr
        for theorem in ("zeroCountExcludesActive", "zeroCountAndEmptyQueuesExcludeHiddenWork",
                        "missingLifetimeCounterexample", "stageCostsStayWithinComposedBudget",
                        "announcementWithoutAcknowledgementIsNotReady", "rootsDoNotPermitConcurrentMutation",
                        "reopenedWorkRevokesZeroCount", "reuseRevokesOldIdentity", "balancedNestedExitsCompose"):
            self.assertIn(theorem, output)
        self.assertNotIn("sorryAx", output)
        for line in output.splitlines():
            if "depends on axioms: [" in line:
                names = line.split("depends on axioms: [", 1)[1].rstrip("]").split(",")
                self.assertLessEqual({name.strip() for name in names},
                                     {"propext", "Classical.choice", "Quot.sound"})
        controls = ("UnacknowledgedService", "MutatingInactiveRoot", "ReopenedWork",
                    "ReusedIdentity", "UnownedExit", "OmittedLifetime")

        def reject(name):
            row = self.observe(name, [lake, "env", "lean", "-DmaxHeartbeats=200000",
                "-DmaxRecDepth=512", "controls/" + name + ".lean"], self.lean, 15)
            self.assertNotEqual(row.exit, 0)
            self.assertIn("decide", row.stdout + row.stderr)
            self.assertIn("false", row.stdout + row.stderr)
            self.assertNotIn("failed to synthesize", row.stdout + row.stderr)

        with ThreadPoolExecutor(max_workers=min(available_processors(), len(controls))) as pool:
            list(pool.map(reject, controls))
        incomplete = self.observe("SorryWitness", [lake, "env", "lean", "-DmaxHeartbeats=200000",
            "-DmaxRecDepth=512", "controls/SorryWitness.lean"], self.lean, 15)
        self.assertEqual(incomplete.exit, 0)
        self.assertIn("sorryAx", incomplete.stdout + incomplete.stderr)

    def test_quint_boundary_revocation_and_decoded_controls(self):
        quint = shutil.which("quint")
        self.assertIsNotNone(quint, "actual Quint required; no skip")
        jar = Path(os.environ.get("QUINT_TLC_JAR", str(ROOT / ".data/tools/apalache-0.62.1/lib/apalache.jar")))
        self.assertTrue(jar.is_file(), "actual TLC jar required")
        variants = ("init", "initAnnouncedOnly", "initRootsOnly", "initCachedReady",
                    "initAddressOnly", "initUnbalancedExit")
        jobs = min(available_processors(), len(variants))
        config = self.out / "tlc-config.json"
        config.write_text(json.dumps({"workers": max(1, available_processors() // jobs),
                                      "maxHeap": "-Xmx1G", "stackSize": "-Xss8m"}) + "\n")

        def verify(initializer):
            out = self.out / initializer
            out.mkdir()
            row, log, trace = check(ROOT / "models/gambit/runtime_transfer_boundary.qnt",
                initializer=initializer, invariant="safe", negative=initializer != "init",
                temporal="completion" if initializer == "init" else None,
                timeout=30, cwd=out, config=config, executable=quint,
                liveness_schedule="final", tlc_jar=jar)
            (out / "checker.log").write_text(log)
            (out / "receipt.json").write_text(json.dumps(dict(row, trace=trace,
                inputs=self.inputs, logSha256=digest(out / "checker.log")), indent=2) + "\n")
            self.assertTrue(row["accepted"], initializer + "\n" + log[-2500:])
            self.assertFalse(row["timeout"])
            if initializer != "init":
                self.assertGreater(len(trace["states"]), 1)

        with ThreadPoolExecutor(max_workers=jobs) as pool:
            list(pool.map(verify, variants))


if __name__ == "__main__":
    unittest.main()
