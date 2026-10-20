"""Explicit Experimental checks; never part of current native qualification."""
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.artifact_storage import cache_path
from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
from gambit_smp.framework import ROOT, available_processors, digest
from gambit_smp.model_schedule import physical_memory, resources
from gambit_smp.process_observation import capture
from gambit_smp.quint_backend import check


class RetirementHandoffExperimentalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.model = ROOT / "models/experimental/retirement_root_handler_composition.qnt"
        cls.proof = ROOT / "models/experimental/lean/RetirementHandoff.lean"
        cls.lean = ROOT / "models/gambit/lean"
        directory = cache_path(ROOT, "experimental-retirement-handoff")
        directory.mkdir(parents=True, exist_ok=True)
        cls.out = Path(tempfile.mkdtemp(prefix="run-", dir=directory))
        files = [cls.model, cls.proof, Path(__file__),
                 ROOT / "evidence/research/retirement-handoff/facts.json",
                 ROOT / "models/gambit/public_vm_retirement_composition.qnt",
                 cls.lean / "WorkAccounting.lean", cls.lean / "lakefile.toml",
                 cls.lean / "lean-toolchain"]
        cls.inputs = {str(p.relative_to(ROOT)): digest(p) for p in files}
        print("Experimental model receipt:", cls.out, flush=True)

    @classmethod
    def tearDownClass(cls):
        if any(digest(ROOT / p) != sha for p, sha in cls.inputs.items()):
            raise AssertionError("experimental input changed during checks")

    def test_quint_composition_and_six_counterexamples(self):
        quint = shutil.which("quint")
        self.assertIsNotNone(quint)
        jar = Path(os.environ.get("QUINT_TLC_JAR",
                   str(ROOT / ".data/tools/apalache-0.62.1/lib/apalache.jar")))
        self.assertTrue(jar.is_file(), "existing TLC runtime required; no skip")
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
                inputs=self.inputs, experimental=True, runtimeAdmitted=False), indent=2))
            self.assertTrue(row["accepted"], initializer + "\n" + log[-2200:])
            self.assertFalse(row["timeout"])
            if negative:
                self.assertGreater(len(trace["states"]), 1)
                self.assert_counterexample(initializer, trace["states"][-1])

        verify("initFixed")
        controls = ("initDroppedRoot", "initPayloadForgotten",
                    "initHandlerForgotten", "initBorrowerForgotten",
                    "initSyncRootForgotten", "initJoinReleasedEarly")
        with ThreadPoolExecutor(max_workers=min(plan["parallelControls"], len(controls))) as pool:
            list(pool.map(verify, controls))

    def assert_counterexample(self, initializer, state):
        h, p = state["h"], state["P_s"]
        if initializer == "initSyncRootForgotten":
            self.assertFalse(p["memory"])
            self.assertFalse(h["syncRoot"] or h["syncLive"])
            self.assertTrue(h["syncLocked"])
            self.assertFalse(h["badJoinRelease"])
            return
        if initializer == "initJoinReleasedEarly":
            self.assertTrue(p["memory"])
            self.assertTrue(h["syncRoot"] and h["syncLive"])
            self.assertFalse(h["syncLocked"])
            self.assertTrue(h["badJoinRelease"])
            return
        self.assertTrue(p["memory"])
        if initializer == "initDroppedRoot":
            self.assertEqual(h["exitKind"], 2)
            self.assertTrue(h["payloadLive"])
            self.assertFalse(h["sourceRoot"] or h["destinationRoot"])
            self.assertTrue(p["resource"])
        else:
            self.assertFalse(p["resource"])
            self.assertFalse(p["lease"])
            if initializer == "initPayloadForgotten":
                self.assertTrue(h["payloadLive"] and h["destinationRoot"])
                self.assertFalse(h["borrower"] or h["publisher"])
            elif initializer == "initHandlerForgotten":
                self.assertFalse(h["installed"])
                self.assertEqual(h["handler"], 1)
            elif initializer == "initBorrowerForgotten":
                self.assertTrue(h["borrower"])
                self.assertFalse(h["payloadLive"])
                self.assertEqual(h["handler"], 2)
            else:
                self.fail("unrecognized negative control: " + initializer)

    def test_existing_scheme_exposes_proposal_not_native_acceptance(self):
        path = ROOT / "evidence/research/retirement-handoff/facts.json"
        facts = json.loads(path.read_text())["facts"]
        for _, source, sha, _ in facts["source"]:
            self.assertEqual(digest(ROOT / source), sha, source)
        for _, model, sha, coverage, gap in facts["model_scope"]:
            self.assertTrue(model.startswith("models/experimental/"))
            self.assertEqual(digest(ROOT / model), sha, model)
            self.assertEqual(coverage, "partial")
            self.assertTrue(gap)
        self.assertEqual(facts["satisfies"], [])
        catalog = load_component_catalog(ROOT / "evidence/scenarios/parallel-gc/components.json",
            entry="parallel-gc", constructor="make-parallel-gc-review", trusted=True)
        queries = {name: name for name in ("transfer_evidence", "transfer_gap",
            "transfer_unbound", "transfer_premise_evidence", "missing_requirement")}
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, queries)
            expected = {row[0] for row in facts["transfer_condition"]}
            self.assertEqual({row[0] for row in answers["transfer_evidence"]}, expected)
            self.assertEqual({row[0] for row in answers["transfer_gap"]}, expected)
            self.assertEqual(answers["transfer_unbound"], [])
            self.assertEqual(len(answers["missing_requirement"]), len(facts["obligation"]))
            repeated, reused = evaluate(engine, facts, catalog, queries)
            self.assertEqual(repeated, answers)
            self.assertTrue(reused["nativeResultReused"])
            for source in ("gambit-retirement", "chez-retirement", "ocaml-retirement",
                           "handoff-model", "handoff-proof", "ocaml-sync-storage",
                           "ocaml-join-consumer", "chez-wait-ownership", "chez-sweeper-assignment",
                           "ocaml-systhread-state", "existing-wait-model", "gambit-sync-layout",
                           "existing-cohort-model"):
                withdrawn = dict(facts, source=[r for r in facts["source"] if r[0] != source])
                missing, _ = evaluate(engine, withdrawn, catalog, queries)
                self.assertIn("premise-source-missing", {r[1] for r in missing["transfer_unbound"]})
                self.assertEqual(missing["missing_requirement"], answers["missing_requirement"])
            restored, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(restored, answers)

    def test_guarded_lean_owner_contracts(self):
        lake = shutil.which("lake")
        self.assertIsNotNone(lake)
        environment = dict(os.environ,
            ELAN_TOOLCHAIN=(self.lean / "lean-toolchain").read_text().strip())
        row = capture([lake, "env", "lean", "-DmaxHeartbeats=200000",
            "-DmaxRecDepth=512", str(self.proof)], self.lean, 15, environment)
        (self.out / "lean.json").write_text(json.dumps(dict(asdict(row),
            inputs=self.inputs, experimental=True, runtimeAdmitted=False), indent=2))
        self.assertFalse(row.timeout)
        self.assertTrue(row.group_quiescent)
        self.assertEqual(row.exit, 0, row.stdout + row.stderr)
        output = row.stdout + row.stderr
        self.assertNotIn("sorryAx", output)
        for line in output.splitlines():
            if "depends on axioms: [" in line:
                names = line.split("depends on axioms: [", 1)[1].rstrip("]").split(",")
                self.assertLessEqual({name.strip() for name in names},
                                     {"propext", "Classical.choice", "Quot.sound"})
        for theorem in ("tracedHandoffPermitsOwnerExit", "exitWithoutHandoffLosesRoot",
                        "sameVmRootDoesNotSurviveDestruction", "borrowerDrainIsNotPayloadDischarge",
                        "registryDrainIsNotHandlerQuiet", "retirementDischargesEachOwner",
                        "retainedSynchronizationRemainsLive", "removingLastSyncRootLosesProtection",
                        "notificationDoesNotReleaseJoiner", "earlyJoinReleaseViolatesOrdering",
                        "balancedExceptionalEntries"):
            self.assertIn(theorem, output)


if __name__ == "__main__":
    unittest.main()
