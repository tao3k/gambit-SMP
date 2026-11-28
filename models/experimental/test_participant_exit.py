"""Explicit research campaign using the existing checkers and resource scheduler."""
from dataclasses import asdict
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.artifact_storage import cache_path
from gambit_smp.framework import ROOT, available_processors, digest
from gambit_smp.model_schedule import physical_memory, resources, run_batch
from gambit_smp.process_observation import capture
from gambit_smp.quint_backend import check


class _ExperimentalChecks:
    @classmethod
    def setUpClass(cls):
        cls.model = ROOT / "models/experimental" / cls.model_name
        cls.proof = ROOT / "models/experimental/lean" / cls.proof_name
        cls.lean = ROOT / "models/gambit/lean"
        parent = cache_path(ROOT, cls.cache_name)
        parent.mkdir(parents=True, exist_ok=True)
        cls.out = Path(tempfile.mkdtemp(prefix="run-", dir=parent))
        paths = [cls.model, cls.proof, Path(__file__),
                 cls.lean / "WorkAccounting.lean", cls.lean / "lakefile.toml",
                 cls.lean / "lean-toolchain"]
        paths += [ROOT / "models/gambit" / path for path in cls.dependencies]
        cls.inputs = {str(path.relative_to(ROOT)): digest(path) for path in paths}
        print(cls.model_name, "research receipts:", cls.out, flush=True)

    @classmethod
    def tearDownClass(cls):
        for path, sha in cls.inputs.items():
            if digest(ROOT / path) != sha:
                raise AssertionError("research input changed: " + path)

    def test_composition_counterexamples_and_reachable_request_orders(self):
        executable = shutil.which("quint")
        self.assertIsNotNone(executable)
        jar = Path(os.environ.get("QUINT_TLC_JAR",
            str(ROOT / ".data/tools/apalache-0.62.1/lib/apalache.jar")))
        self.assertTrue(jar.is_file(), "fixed TLC required; no skip")
        plan = resources(available_processors(), physical_memory(), None)
        config = self.out / "tlc-config.json"
        config.write_text(json.dumps({"workers": plan["controlTlcWorkers"],
                                      "maxHeap": "-Xmx1G", "stackSize": "-Xss8m"}))
        cases = self.cases

        def verify(case):
            initializer, invariant, negative, temporal = case
            out = self.out / (initializer + "-" + invariant)
            out.mkdir()
            row, log, trace = check(self.model, initializer=initializer,
                invariant=invariant, negative=negative, timeout=30, cwd=out,
                config=config, executable=executable, temporal=temporal,
                liveness_schedule="final", tlc_jar=jar)
            (out / "checker.log").write_text(log)
            (out / "receipt.json").write_text(json.dumps(dict(row, trace=trace,
                inputs=self.inputs, resources=plan, experimental=True,
                purpose="counterexample-or-reachability" if negative else invariant,
                runtimeAdmitted=False), indent=2))
            self.assertTrue(row["accepted"], str(case) + "\n" + log[-2200:])
            self.assertFalse(row["timeout"])
            if negative:
                self.assert_trace(initializer, invariant, trace["states"][-1])

        # Keep the exhaustive positive check's result separate from controls.
        verify(cases[0])
        for offset in range(1, len(cases), plan["parallelControls"]):
            run_batch(cases[offset:offset + plan["parallelControls"]], verify)

    def test_guarded_lean_obligations(self):
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
        for theorem in self.theorems:
            self.assertIn(theorem, output)
        for line in output.splitlines():
            if "depends on axioms: [" in line:
                names = line.split("depends on axioms: [", 1)[1].rstrip("]").split(",")
                self.assertLessEqual({name.strip() for name in names},
                                    {"propext", "Classical.choice", "Quot.sound"})


class ParticipantExitExperimentalTests(_ExperimentalChecks, unittest.TestCase):
    model_name = "participant_exit_publication.qnt"
    proof_name = "ParticipantExitPublication.lean"
    cache_name = "experimental-participant-exit"
    dependencies = ("public_vm_retirement_composition.qnt",)
    cases = (("initFixed", "safe", False, "completion"),
             ("initSnapshotWithoutGate", "safe", True, None),
             ("initOrphanWithoutRecheck", "safe", True, None),
             ("initCleanupAsStwProtected", "safe", True, None),
             ("initFixed", "noParticipatingRequest", True, None),
             ("initFixed", "noExcludedRequest", True, None))
    theorems = ("emptyWorkDoesNotExcludeRequest", "orphaningRevokesEmptyCensus",
                "removedMemberDoesNotExcludeReader", "guardedPublicationExcludesReader",
                "rootAndParticipationAreIndependent")

    def assert_trace(self, initializer, invariant, state):
        state = state["e"]
        if initializer == "initSnapshotWithoutGate":
            self.assertTrue(state["badCut"] and state["enlisted"])
            self.assertFalse(state["member"])
        elif initializer == "initOrphanWithoutRecheck":
            self.assertTrue(state["badCut"] and state["work"])
        elif initializer == "initCleanupAsStwProtected":
            self.assertFalse(state["member"])
            self.assertEqual((state["cleanup"], state["request"]), (1, 2))
        else:
            self.assertEqual((state["cleanup"], state["request"]), (2, 3))
            self.assertEqual(state["enlisted"], invariant == "noParticipatingRequest")


class RootRegistryExperimentalTests(_ExperimentalChecks, unittest.TestCase):
    model_name = "root_registry_callback.qnt"
    proof_name = "RootRegistryCallback.lean"
    cache_name = "experimental-root-registry"
    dependencies = ("vm_list_reader_retirement.qnt",)
    cases = (("initFixed", "safe", False, "completion"),
             ("initRelockInsideScan", "noStall", True, None),
             ("initForeignDepthBypass", "safe", True, None),
             ("initUnlinkAsLastUse", "safe", True, None),
             ("initFixed", "noOwnerCompletion", True, None),
             ("initFixed", "noExternalCompletion", True, None),
             ("initScanPhaseFixed", "safe", False, "completion"),
             ("initLocalScanAsGlobalCompletion", "safe", True, None),
             ("initScanPhaseFixed", "noPostScanMutation", True, None))
    theorems = ("ownerMayDelete", "foreignOwnerCannotBorrowDepth",
                "deletionDoesNotAuthorizeInsertion", "unlinkedRegistryDoesNotDischargeReader",
                "rootAvailabilityDoesNotAuthorizeMutation", "localRootsDoNotReleaseGlobalScan",
                "domainOwnershipDoesNotSerializeGlobalWriters", "releasedMutatorHasGlobalCompletion")

    def assert_trace(self, initializer, invariant, state):
        registry, reader = state["r"], state["R_s"]
        if initializer == "initRelockInsideScan":
            self.assertEqual(registry["phase"], 5)
            self.assertTrue(registry["locked"])
            self.assertEqual(reader["reader"], "use")
        elif initializer == "initForeignDepthBypass":
            self.assertTrue(registry["external"] and registry["badAuthority"])
            self.assertTrue(registry["locked"])
        elif initializer == "initUnlinkAsLastUse":
            self.assertFalse(reader["alive"])
            self.assertEqual(reader["reader"], "use")
        elif initializer == "initLocalScanAsGlobalCompletion":
            self.assertTrue(registry["phaseStudy"])
            self.assertEqual(registry["payload"]["phase"], 1)
            self.assertTrue(registry["payload"]["overlap"])
        elif initializer == "initScanPhaseFixed":
            self.assertEqual(registry["payload"]["phase"], 2)
            self.assertTrue(registry["payload"]["lateWrite"])
            self.assertFalse(registry["payload"]["overlap"])
            self.assertEqual(set(registry["payload"]["updated"]["$integerSet"]), {0, 1})
        else:
            self.assertEqual(reader["writer"], "done")
            self.assertEqual(reader["reader"], "done")
            self.assertEqual(registry["external"], invariant == "noExternalCompletion")
