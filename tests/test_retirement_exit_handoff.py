"""Current repair composition through existing guarded formal backends."""
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.artifact_storage import cache_path
from gambit_smp.framework import ROOT, available_processors, digest
from gambit_smp.model_schedule import physical_memory, resources
from gambit_smp.process_observation import capture
from gambit_smp.quint_backend import check


class RetirementExitHandoffTests(unittest.TestCase):
    validation_after_domains = True

    @classmethod
    def setUpClass(cls):
        cls.model = ROOT / "models/gambit/retirement_exit_handoff.qnt"
        cls.lean = ROOT / "models/gambit/lean"
        parent = cache_path(ROOT, "retirement-exit-handoff")
        parent.mkdir(parents=True, exist_ok=True)
        cls.out = Path(tempfile.mkdtemp(prefix="run-", dir=parent))
        paths = [cls.model, cls.lean / "RetirementExitHandoff.lean",
                 cls.lean / "WorkAccounting.lean", cls.lean / "lakefile.toml",
                 cls.lean / "lean-toolchain", Path(__file__)]
        paths += [ROOT / "models/gambit" / name for name in (
            "callback_return_owned_result.qnt", "resize_saved_stack_retirement_isolated.qnt",
            "sync_slot_retained_resources.qnt")]
        paths.append(ROOT / "models/library/gc/WorkObligations.qnt")
        cls.inputs = {str(p.relative_to(ROOT)): digest(p) for p in paths}
        print("Current repair model receipt:", cls.out, flush=True)

    @classmethod
    def tearDownClass(cls):
        if any(digest(ROOT / p) != sha for p, sha in cls.inputs.items()):
            raise AssertionError("formal input changed during checks")

    def test_quint_composition_and_decoded_counterexamples(self):
        quint = shutil.which("quint")
        self.assertIsNotNone(quint)
        jar = Path(os.environ.get("QUINT_TLC_JAR",
            str(ROOT / ".data/tools/apalache-0.62.1/lib/apalache.jar")))
        self.assertTrue(jar.is_file(), "fixed TLC required; no skip")
        plan = resources(available_processors(), physical_memory(), None)
        config = self.out / "tlc-config.json"
        config.write_text(json.dumps({"workers": plan["controlTlcWorkers"],
            "maxHeap": "-Xmx1G", "stackSize": "-Xss8m"}))

        def verify(initializer):
            out = self.out / initializer
            out.mkdir()
            negative = initializer != "initFixed"
            row, log, trace = check(self.model, initializer=initializer,
                invariant="safe", negative=negative, timeout=30, cwd=out,
                config=config, executable=quint, temporal=None if negative else "completion",
                liveness_schedule="final", tlc_jar=jar)
            (out / "checker.log").write_text(log)
            (out / "receipt.json").write_text(json.dumps(dict(row, trace=trace,
                inputs=self.inputs, resources=plan, runtimeAdmitted=False), indent=2))
            self.assertTrue(row["accepted"], initializer + "\n" + log[-2400:])
            self.assertFalse(row["timeout"])
            if negative:
                self.assert_counterexample(initializer, trace["states"][-1])

        verify("initFixed")
        controls = ("initMarkerAsExit", "initMissingRoot", "initQueueOnlyWork",
            "initStaleCensus", "initReleaseCallAsDone", "initRetryReleasedCallback",
            "initJoinOnlyBorrowers")
        with ThreadPoolExecutor(max_workers=min(plan["parallelControls"], len(controls))) as pool:
            list(pool.map(verify, controls))

    def assert_counterexample(self, initializer, state):
        h = state["h"]
        if initializer == "initMarkerAsExit":
            self.assertEqual(h["tail"], 1)
            self.assertTrue(h["quiesced"])
        elif initializer == "initMissingRoot":
            self.assertTrue(h["handed"])
            self.assertNotEqual(h["targetRoots"], {"$stringSet": ["activation", "foreign-result"]})
            self.assertEqual(h["sourceRoots"], {"$integerSet": []})
        elif initializer == "initQueueOnlyWork":
            self.assertTrue(h["reclaimed"])
            self.assertTrue(next(iter(h["privateWork"].values())))
        elif initializer == "initStaleCensus":
            self.assertTrue(h["handed"] and h["badSnapshot"])
        elif initializer == "initReleaseCallAsDone":
            self.assertTrue(h["reclaimed"])
            self.assertEqual(h["releasePhase"], 2)
        elif initializer == "initRetryReleasedCallback":
            self.assertEqual(h["releaseCalls"], 2)
            self.assertFalse(h["releaseFn"])
            self.assertEqual(h["releaseError"], 9)
        elif initializer == "initJoinOnlyBorrowers":
            self.assertTrue(h["reclaimed"])
            remote = [r for r in state.values() if isinstance(r, dict) and "sender" in r]
            self.assertEqual(len(remote), 1)
            self.assertLess(dict(remote[0]["sender"]["$integerMap"])[0], 4)
        else:
            self.fail("unregistered counterexample")

    def test_success_and_retained_failure_are_reachable(self):
        plan = resources(available_processors(), physical_memory(), None)
        config = self.out / "witness-config.json"
        config.write_text(json.dumps({"workers": plan["controlTlcWorkers"],
            "maxHeap": "-Xmx1G", "stackSize": "-Xss8m"}))
        jar = Path(os.environ.get("QUINT_TLC_JAR",
            str(ROOT / ".data/tools/apalache-0.62.1/lib/apalache.jar")))

        def witness(invariant):
            out = self.out / invariant
            out.mkdir()
            row, log, trace = check(self.model, initializer="initFixed",
                invariant=invariant, negative=True, timeout=30, cwd=out,
                config=config, executable=shutil.which("quint"),
                liveness_schedule="final", tlc_jar=jar)
            (out / "checker.log").write_text(log)
            (out / "receipt.json").write_text(json.dumps(dict(row, trace=trace,
                inputs=self.inputs, purpose="reachable-positive-witness",
                runtimeAdmitted=False), indent=2))
            self.assertTrue(row["accepted"], log[-2000:])
            h = trace["states"][-1]["h"]
            self.assertEqual(h["joinCalls"], 1)
            if invariant == "noSuccessfulHandoff":
                self.assertTrue(h["reclaimed"] and h["joined"] and h["handed"])
                self.assertTrue(next(iter(h["targetWork"].values())))
                self.assertEqual(h["releasePhase"], 4)
            else:
                self.assertTrue(h["joinFailed"])
                self.assertFalse(h["reclaimed"] or h["handed"])
                self.assertEqual(h["sourceRoots"], {"$stringSet": ["activation", "foreign-result"]})

        with ThreadPoolExecutor(max_workers=min(plan["parallelControls"], 2)) as pool:
            list(pool.map(witness, ("noSuccessfulHandoff", "noRetainedFailure")))

    def test_guarded_lean_contracts(self):
        lake = shutil.which("lake")
        self.assertIsNotNone(lake)
        environment = dict(os.environ,
            ELAN_TOOLCHAIN=(self.lean / "lean-toolchain").read_text().strip())
        row = capture([lake, "env", "lean", "-DmaxHeartbeats=200000",
            "-DmaxRecDepth=512", "RetirementExitHandoff.lean"], self.lean, 15, environment)
        (self.out / "lean.json").write_text(json.dumps(dict(asdict(row),
            inputs=self.inputs, runtimeAdmitted=False), indent=2))
        self.assertFalse(row.timeout)
        self.assertTrue(row.group_quiescent)
        self.assertEqual(row.exit, 0, row.stdout + row.stderr)
        output = row.stdout + row.stderr
        self.assertNotIn("sorryAx", output)
        for theorem in ("invalidMarkerCanRetainTail", "joinDoesNotDischargeRemoteTail",
            "invokedReleaseIsNotReturned", "publicQueuesDoNotExcludePrivateWork",
            "destinationCoveragePermitsDonorRelease", "unfinishedRecipientWorkCanSurviveDonor",
            "oneInvocationConsumesBudget", "releasedFunctionCannotBeRetried",
            "changedScopeRevokesBinding", "changedModelRevokesBinding",
            "unrelatedPropertyDoesNotCoverEdge", "changedSourcesRevokeBinding",
            "changedRefinementRevokesBinding", "oneCheckedInterfaceDoesNotCoverBundle"):
            self.assertIn(theorem, output)
        for line in output.splitlines():
            if "depends on axioms: [" in line:
                names = line.split("depends on axioms: [", 1)[1].rstrip("]").split(",")
                self.assertLessEqual({name.strip() for name in names},
                    {"propext", "Classical.choice", "Quot.sound"})
