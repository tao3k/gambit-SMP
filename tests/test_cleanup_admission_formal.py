"""Conditional admission-work proofs through the existing bounded runner."""
from dataclasses import asdict
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.artifact_storage import cache_path
from gambit_smp.framework import ROOT, digest
from gambit_smp.process_observation import capture


class CleanupAdmissionFormalTests(unittest.TestCase):
    def test_linear_work_and_reopen_control(self):
        lean = ROOT / "models/gambit/lean"
        files = [lean / "CleanupAdmissionWork.lean",
                 lean / "controls/UnboundedAdmissionReopen.lean",
                 lean / "lean-toolchain", lean / "lakefile.toml"]
        inputs = {str(path.relative_to(ROOT)): digest(path) for path in files}
        parent = cache_path(ROOT, "cleanup-admission-formal")
        parent.mkdir(parents=True, exist_ok=True)
        out = Path(tempfile.mkdtemp(prefix="run-", dir=parent))
        environment = dict(os.environ,
            ELAN_TOOLCHAIN=(lean / "lean-toolchain").read_text().strip())
        lake = shutil.which("lake")
        self.assertIsNotNone(lake)

        def observe(name, args):
            row = capture([lake, "env", "lean", "-DmaxHeartbeats=200000",
                           "-DmaxRecDepth=512", *args], lean, 15, environment)
            (out / (name + ".json")).write_text(json.dumps(
                dict(asdict(row), inputs=inputs), indent=2) + "\n")
            self.assertFalse(row.timeout, name)
            self.assertTrue(row.group_quiescent, name)
            return row

        positive = observe("linear-work", ["CleanupAdmissionWork.lean"])
        self.assertEqual(positive.exit, 0, positive.stdout + positive.stderr)
        self.assertNotIn("sorryAx", positive.stdout + positive.stderr)
        for theorem in ("linearAdmissionWork", "singleProcessorRejectedPrefixWork",
                        "retriesPreserveAccounting", "attemptWorkSum",
                        "redundantScanViolatesSingleVisit"):
            self.assertIn(theorem, positive.stdout)
        control = observe("unbounded-reopen", ["controls/UnboundedAdmissionReopen.lean"])
        self.assertNotEqual(control.exit, 0)
        self.assertIn("false", control.stdout + control.stderr)
        self.assertNotIn("unknown module", control.stdout + control.stderr)
        self.assertEqual(inputs, {str(path.relative_to(ROOT)): digest(path) for path in files})
