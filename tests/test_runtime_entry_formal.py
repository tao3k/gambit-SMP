"""Experimental contracts use the existing guarded process and Scheme engine."""
from dataclasses import asdict
import json
import os
from pathlib import Path
import re
import shutil
import tempfile
import unittest

from gambit_smp.artifact_storage import cache_path
from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
from gambit_smp.framework import ROOT, digest
from gambit_smp.process_observation import capture


class RuntimeEntryFormalTests(unittest.TestCase):
    def test_guarded_lean_contracts_and_false_controls(self):
        lean = ROOT / "models/gambit/lean"
        files = [lean / name for name in (
            "RuntimeEntryContracts.lean", "WorkAccounting.lean",
            "controls/RuntimeEntryFalseClaims.lean", "lean-toolchain",
            "lakefile.toml", "lake-manifest.json")]
        inputs = {str(path.relative_to(ROOT)): digest(path) for path in files}
        parent = cache_path(ROOT, "runtime-entry-formal")
        parent.mkdir(parents=True, exist_ok=True)
        out = Path(tempfile.mkdtemp(prefix="run-", dir=parent))
        environment = dict(os.environ,
            ELAN_TOOLCHAIN=(lean / "lean-toolchain").read_text().strip())
        lake = shutil.which("lake")
        self.assertIsNotNone(lake, "pinned Lean and LeanPoo required; no skip")

        def observe(name, args, timeout):
            row = capture([lake, *args], lean, timeout, environment)
            (out / (name + ".json")).write_text(json.dumps(
                dict(asdict(row), inputs=inputs), indent=2) + "\n")
            self.assertFalse(row.timeout, name)
            self.assertTrue(row.group_quiescent, name)
            return row

        built = observe("build", ["build", "RuntimeEntryContracts"], 120)
        self.assertEqual(built.exit, 0, built.stdout + built.stderr)
        guarded = ["env", "lean", "-DmaxHeartbeats=200000", "-DmaxRecDepth=512"]
        checked = observe("axioms", [*guarded, "RuntimeEntryContracts.lean"], 15)
        self.assertEqual(checked.exit, 0, checked.stdout + checked.stderr)
        output = checked.stdout + checked.stderr
        for theorem in ("sequentialReservationsDisjoint", "staleCursorOverlap",
                        "ownedProcessorEntriesCompatible", "leasesDoNotGiveExecutionOwnership",
                        "distinctProcessorsPermitIndependentOwners",
                        "retainedHeadDoesNotPreserveLookup", "lookupWithStableTopology",
                        "ownedNestedExitAccounting", "rewindAcrossLaterReservationUnsafe",
                        "revalidatedCopyIndexBound", "staleLocalAfterMove",
                        "nestedTracedSuffix", "serviceCycleCannotHaveStrictRanks",
                        "slotReadinessDoesNotGiveRecordReadiness",
                        "registryMetadataOrderExcludesReverse", "alignedSuccessorDisjoint",
                        "bindingCoverageComposes", "localCoverageWithoutBindingBridge",
                        "checkedBucketAfterWait", "inBoundsBucketMayMiss",
                        "replayedSuffixMembership", "explicitReplayMayRepeat",
                        "canonicalRecheckAgrees", "rehashMembershipPreserved",
                        "vmCellWriteFrame", "descriptorRetirementExcludesConsumers",
                        "generatedMapRelocation"):
            self.assertIn(theorem, output)
        self.assertNotIn("sorryAx", output)
        for line in output.splitlines():
            if "depends on axioms: [" in line:
                names = line.split("depends on axioms: [", 1)[1].rstrip("]").split(",")
                self.assertLessEqual({name.strip() for name in names},
                                     {"propext", "Classical.choice", "Quot.sound"})
        control = observe("false-claims", [*guarded, "controls/RuntimeEntryFalseClaims.lean"], 15)
        self.assertNotEqual(control.exit, 0)
        errors = control.stdout + control.stderr
        self.assertEqual(errors.count("Tactic `decide` proved"), 17)
        self.assertEqual(errors.count("is false"), 17)
        self.assertNotIn("failed to synthesize", errors)
        self.assertNotIn("unknown module", errors)
        self.assertEqual(inputs, {str(path.relative_to(ROOT)): digest(path) for path in files})

    def test_experimental_links_and_checker_context(self):
        directory = ROOT / "docs/experimental"
        self.assertTrue((directory / "README.md").is_file())
        for document in directory.glob("*.md"):
            self.assertFalse(document.name.startswith("experimental-"))
            for target in re.findall(r"\]\(([^)]+)\)", document.read_text()):
                if "://" not in target:
                    path = target.split("#", 1)[0]
                    if path:
                        self.assertTrue((document.parent / path).exists(), str(document) + ": " + target)
        for name in ("runtime-entry.manifest.json", "runtime-entry-wait.manifest.json",
                     "runtime-entry-replay.manifest.json", "runtime-entry-canonical.manifest.json",
                     "runtime-entry-cells.manifest.json", "runtime-entry-descriptor.manifest.json"):
            manifest = json.loads((ROOT / "evidence/scenarios/parallel-gc" / name).read_text())
            for path, sha in manifest["contextInputs"].items():
                self.assertEqual(digest(ROOT / path), sha, path)

    def test_existing_scheme_relations_keep_experimental_limits(self):
        directory = ROOT / "evidence/scenarios/parallel-gc"
        facts = json.loads((directory / "runtime-entry-facts.json").read_text())["facts"]
        for _, path, sha, _ in facts["source"]:
            self.assertFalse({".data", ".cache"}.intersection(path.split("/")))
            self.assertEqual(digest(ROOT / path), sha)
        for _, path, sha, status, gap in facts["model_scope"]:
            self.assertEqual(digest(ROOT / path), sha)
            self.assertEqual(status, "partial")
            self.assertTrue(gap)
        catalog = load_component_catalog(directory / "components.json", entry="parallel-gc",
            constructor="make-parallel-gc-review", trusted=True)
        queries = {key: key for key in ("transfer_evidence", "transfer_gap",
            "transfer_unbound", "transfer_premise_evidence", "missing_requirement")}
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, queries)
            conditions = {row[0] for row in facts["transfer_condition"]}
            self.assertEqual({row[0] for row in answers["transfer_evidence"]}, conditions)
            self.assertEqual({row[0] for row in answers["transfer_gap"]}, conditions)
            self.assertEqual(answers["transfer_unbound"], [])
            self.assertEqual({(row[0], row[1]) for row in answers["transfer_premise_evidence"]},
                             {(row[0], row[1]) for row in facts["transfer_premise"]})
            self.assertEqual(len(answers["missing_requirement"]), len(facts["obligation"]))
            repeated, reused = evaluate(engine, facts, catalog, queries)
            self.assertEqual(repeated, answers)
            self.assertTrue(reused["nativeResultReused"])
            for source in ("entry-audit", "entry-lean", "metadata-transaction", "entry-validation",
                           "entry-callers", "ocaml-slow-lock", "gambit-repl",
                           "entry-callers-validation", "metadata-recipe", "capture-protocol",
                           "ffi-root-protocol", "retry-root-protocol", "chez-oom", "ocaml-allocation",
                           "metadata-validation", "wait-root-exit-audit", "ocaml-local-roots",
                           "ocaml-native-raise", "ocaml-bytecode-raise", "ocaml-blocking-effects",
                           "chez-lock-order", "existing-nested-unwind", "wait-root-validation",
                           "entry-closure-audit", "gambit-tty-reader", "gambit-geiser-reader",
                           "gambit-generator-lock", "ocaml-root-scanner", "existing-constructor-roots",
                           "existing-module-fixup", "existing-linker-generation", "entry-closure-validation",
                           "metadata-package", "backend-compatibility", "gambit-design-readme",
                           "gambit-design-manual", "ocaml-startup-contract",
                           "stage-one-integration", "metadata-vm-composition", "integration-validation",
                           "implementation-milestone", "handoff-recipe", "handoff-validation", "chez-rendezvous",
                           "ocaml-wait-contract", "ocaml-systhread-hooks", "gambit-native-allocation",
                           "reader-resumption", "reader-validation", "chez-continuation-lowering", "chez-control-entry",
                           "ocaml-continuation-use", "canonical-recipe", "canonical-validation", "canonical-protocol",
                           "ocaml-named-registry", "vm-cell-recipe", "vm-cell-validation", "chez-symbol-payload",
                           "ocaml-root-classification", "root-map-recipe", "root-map-validation", "ocaml-frame-descriptors",
                           "chez-generated-tracer", "gambit-dynamic-lifetime",
                           "existing-reader-retirement", "existing-callback-retirement",
                           "gambit-return-map-generator", "gambit-slot-map-encoder",
                           "gambit-label-map-emitter", "chez-root-collector"):
                withdrawn = dict(facts, source=[row for row in facts["source"] if row[0] != source])
                missing, _ = evaluate(engine, withdrawn, catalog, queries)
                self.assertIn("premise-source-missing", {row[1] for row in missing["transfer_unbound"]})
                self.assertEqual(missing["missing_requirement"], answers["missing_requirement"])
            restored, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(restored, answers)
        self.assertEqual(facts["satisfies"], [])
