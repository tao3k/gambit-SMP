"""Explicit real-checker parity campaign; not part of the offline unit profile."""
import json
import os
from pathlib import Path
import subprocess
import unittest

from gambit_smp.framework import ROOT, available_processors, digest
from gambit_smp.quint_backend import check


class QuintBackendIntegration(unittest.TestCase):
    def test_same_model_safety_and_pure_temporal_verdicts(self):
        jar = Path(os.environ["GAMBIT_SMP_TLC_JAR"])
        out = Path(os.environ["GAMBIT_SMP_PARITY_OUT"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        fixture = ROOT / "tests/fixtures/tlc_liveness_gate.qnt"
        snapshot = out / fixture.name
        snapshot.write_bytes(fixture.read_bytes())
        config = out / "runtime.json"
        config.write_text(json.dumps({"workers": available_processors(), "maxHeap": "-Xmx8G"}))
        receipt = {"schema": "quint-tlc-scheduling-parity.v1", "accepted": False,
            "scope": "checker-only-not-runtime-admission", "parityPassed": False,
            "native": {"status": "not-run"}, "runtimeAdmitted": False,
            "releaseAdmitted": False, "modelSha256": digest(fixture),
            "tlcJarSha256": digest(jar), "configSha256": digest(config),
            "quintVersion": subprocess.check_output(["quint", "--version"], text=True,
                                                     timeout=10).strip(),
            "frameworkInputs": {name: digest(ROOT / name) for name in (
                "src/gambit_smp/quint_backend.py", "src/gambit_smp/tlc_execution.py",
                "src/gambit_smp/framework.py", "tests/integration_quint_backend.py")},
            "results": []}
        verdicts, state_counts = {}, {}
        try:
            for policy in ("default", "final"):
                for kind, initializer, invariant, negative, temporal in (
                    ("termination", "initTerminating", "safe", False, "progress"),
                    ("safety-fault", "initTerminating", "zero", True, None),
                    ("fair-cycle", "initCycle", "safe", False, "progress")):
                    directory = out / (policy + "-" + kind)
                    directory.mkdir()
                    row, log, trace = check(snapshot, initializer=initializer, invariant=invariant,
                        negative=negative, temporal=temporal, timeout=30, cwd=directory,
                        config=config, liveness_schedule=policy, tlc_jar=jar if policy == "final" else None)
                    log_path = out / (policy + "-" + kind + ".log")
                    log_path.write_text(log)
                    if trace:
                        log_path.with_suffix(".trace.json").write_text(json.dumps(trace, indent=2) + "\n")
                    if "checker" in row:
                        row["checker"]["artifacts"] = {
                            str((directory / name).relative_to(out)): sha
                            for name, sha in row["checker"]["artifacts"].items()}
                    receipt["results"].append(dict(row, case="tlc_liveness_gate",
                        modelSha256=digest(snapshot), policy=policy, kind=kind,
                        initializer=initializer, invariant=invariant,
                        log=log_path.name, logSha256=digest(log_path)))
                    self.assertFalse(row["timeout"], policy + ":" + kind)
                    self.assertEqual(kind != "fair-cycle", row["accepted"], policy + ":" + kind)
                    if kind == "fair-cycle":
                        self.assertNotEqual(0, row["exit"])
                        self.assertIn("Temporal property q_temporalProps was violated", log)
                        self.assertNotIn("Invariant q_inv is violated", log)
                    verdicts[policy, kind] = row["accepted"]
                    if kind == "termination":
                        state_counts[policy] = row["states"]["distinct"]
            self.assertEqual(state_counts["default"], state_counts["final"])
            for kind in ("termination", "safety-fault", "fair-cycle"):
                self.assertEqual(verdicts["default", kind], verdicts["final", kind])
            stable = (digest(fixture) == receipt["modelSha256"] == digest(snapshot) and
                      digest(jar) == receipt["tlcJarSha256"] and
                      digest(config) == receipt["configSha256"] and all(
                          digest(ROOT / name) == sha for name, sha in receipt["frameworkInputs"].items()))
            receipt["contextStable"] = stable
            self.assertTrue(stable)
            receipt["parityPassed"] = True
        finally:
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")


if __name__ == "__main__":
    unittest.main()
