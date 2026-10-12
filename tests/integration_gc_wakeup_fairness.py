"""Real TLC fairness controls; focused scheduling, never native admission."""
import json
import os
from pathlib import Path
import re
import subprocess
import time
import unittest

from gambit_smp.framework import ROOT, available_processors, digest, parallel_jobs
from gambit_smp.quint_backend import check, counterexample


class WakeupFairnessIntegration(unittest.TestCase):
    def test_bounded_and_unbounded_wakeup_fairness(self):
        out = Path(os.environ["GAMBIT_SMP_FAIRNESS_OUT"]).resolve()
        jar = Path(os.environ["GAMBIT_SMP_TLC_JAR"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        sources = ("gc_wakeup_fairness", "gc_recursive_queue_wait")
        for name in sources:
            (out / (name + ".qnt")).write_bytes((ROOT / "models/gambit" / (name + ".qnt")).read_bytes())
        snapshot = out / "gc_wakeup_fairness.qnt"
        cases = [(policy, kind) for policy in ("Source", "Combined")
                 for kind in ("bounded", "unbounded", "copy-fair")]
        jobs = min(available_processors(), len(cases))
        config = out / "runtime.json"
        config.write_text(json.dumps({"workers": max(1, available_processors() // jobs),
                                      "maxHeap": "-Xmx1G"}))
        receipt = {"schema": "gc-wakeup-fairness-audit.v1", "accepted": False,
            "native": {"status": "not-run"}, "runtimeAdmitted": False,
            "releaseAdmitted": False, "temporalProved": False, "auditPassed": False,
            "scope": "original-init-focused-first-copy-not-whole-gc-progress-or-source-fairness",
            "modelInputs": {name + ".qnt": digest(out / (name + ".qnt")) for name in sources},
            "tlcJarSha256": digest(jar), "configSha256": digest(config),
            "quintVersion": subprocess.check_output(["quint", "--version"], text=True, timeout=10).strip(),
            "frameworkInputs": {name: digest(ROOT / name) for name in (
                "src/gambit_smp/quint_backend.py", "src/gambit_smp/tlc_execution.py",
                "src/gambit_smp/framework.py", "tests/integration_gc_wakeup_fairness.py")},
            "results": []}

        def run(case, deadline):
            policy, kind = case
            name = policy.lower() + "-" + kind
            directory = out / name
            directory.mkdir()
            temporal = {"bounded": "boundedAggregate", "unbounded": "unboundedAggregate",
                        "copy-fair": "unboundedCopyFair"}[kind]
            remaining = min(30, deadline - time.monotonic())
            self.assertGreater(remaining, 0)
            row, log, _ = check(snapshot, initializer="init" + policy, invariant="focusSafe",
                step="stepBounded" if kind == "bounded" else "stepUnbounded",
                negative=False, temporal=temporal, timeout=remaining, cwd=directory, config=config,
                liveness_schedule="final", tlc_jar=jar)
            log_path = out / (name + ".log")
            log_path.write_text(log)
            row.update(case=snapshot.stem, variant="diagnostic", kind=kind,
                       initializer="init" + policy, modelSha256=digest(snapshot),
                       log=log_path.name, logSha256=digest(log_path))
            row["checker"]["artifacts"] = {str((directory / name).relative_to(out)): sha
                                             for name, sha in row["checker"]["artifacts"].items()}
            temporal_failure = (not row["timeout"] and row["exit"] != 0 and
                "Temporal property q_temporalProps was violated" in log and
                "Invariant q_inv is violated" not in log)
            if temporal_failure:
                trace = counterexample(log)
                back = re.search(r"Back to state (\d+)", log)
                trace["loopStart"] = int(back.group(1)) if back else None
                trace_path = log_path.with_suffix(".trace.json")
                trace_path.write_text(json.dumps(trace, indent=2) + "\n")
                row.update(trace=trace_path.name, traceSha256=digest(trace_path))
            row["counterexample"] = temporal_failure
            row["expectedOutcomeMatched"] = temporal_failure if kind == "unbounded" else row["accepted"]
            return row

        try:
            receipt["results"] = parallel_jobs(cases, run, jobs, 45)
            for row in receipt["results"]:
                self.assertFalse(row["timeout"], row["log"])
                self.assertTrue(row["expectedOutcomeMatched"], row["log"])
            receipt["contextStable"] = (digest(jar) == receipt["tlcJarSha256"] and
                digest(config) == receipt["configSha256"] and
                all(digest(ROOT / name) == sha for name, sha in receipt["frameworkInputs"].items()) and
                all(digest(ROOT / "models/gambit" / name) == sha
                    for name, sha in receipt["modelInputs"].items()))
            self.assertTrue(receipt["contextStable"])
            receipt["auditPassed"] = True
        finally:
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")


if __name__ == "__main__":
    unittest.main()
