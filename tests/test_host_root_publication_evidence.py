"""Source-bound research relations and Lean, without native acceptance."""
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


class HostRootPublicationEvidenceTests(unittest.TestCase):
    def test_guarded_lean_contracts(self):
        self._check_lean("HostRootPublicationLifetime.lean", "manifest.json", (
            "allLiveConsumersHaveVisibleRoots", "reclaimedStorageExcludesEveryConsumer",
            "collectorDoneCanLeaveHostConsumer", "publishedStorageCanAlreadyBeDead",
            "inactiveRootsDoNotGrantMutation"))

    def test_guarded_participation_lean_contracts(self):
        self._check_lean("HostRootParticipation.lean", "participation.manifest.json", (
            "recordPublicationIsNotParticipation", "frozenHandoffComposesRelocation",
            "earlyObservationCanMissLastStore", "equalValueDoesNotSupplyAcknowledgement",
            "inactivePublicationStillExcludesMutation"))

    def _check_lean(self, proof, manifest, declarations):
        directory = ROOT / "models/gambit/lean"
        paths = [directory / name for name in (
            proof, "WorkAccounting.lean",
            "lakefile.toml", "lean-toolchain")]
        paths.append(ROOT / "evidence/research/host-root-publication" / manifest)
        paths.append(Path(__file__))
        inputs = {str(path.relative_to(ROOT)): digest(path) for path in paths}
        lake = shutil.which("lake")
        self.assertIsNotNone(lake, "pinned Lean/LeanPoo required; no skip")
        parent = cache_path(ROOT, "host-root-publication")
        parent.mkdir(parents=True, exist_ok=True)
        out = Path(tempfile.mkdtemp(prefix="lean-", dir=parent))
        environment = dict(os.environ,
            ELAN_TOOLCHAIN=(directory / "lean-toolchain").read_text().strip())
        row = capture([lake, "env", "lean", "-DmaxHeartbeats=200000",
            "-DmaxRecDepth=512", proof], directory, 15, environment)
        (out / "receipt.json").write_text(json.dumps(dict(asdict(row),
            inputs=inputs, researchTrack="current-repair", runtimeAdmitted=False), indent=2))
        print("Host root Lean receipt:", out, flush=True)
        self.assertFalse(row.timeout)
        self.assertTrue(row.group_quiescent)
        self.assertEqual(row.exit, 0, row.stdout + row.stderr)
        output = row.stdout + row.stderr
        for name in declarations:
            self.assertIn(name, output)
        self._check_axioms(output)
        self.assertEqual(inputs, {str(path.relative_to(ROOT)): digest(path) for path in paths})

    def _check_axioms(self, output):
        self.assertNotIn("sorryAx", output)
        lists = re.findall(r"depends on axioms: \[([^\]]*)\]", output)
        self.assertEqual(len(lists), output.count("depends on axioms:"))
        for axioms in lists:
            self.assertLessEqual({name.strip() for name in axioms.split(",")},
                                {"propext", "Classical.choice", "Quot.sound"})

    def test_participation_source_edges_remain_unqualified(self):
        path = ROOT / "evidence/research/host-root-publication/participation-facts.json"
        facts = json.loads(path.read_text())["facts"]
        inputs = {row[1]: row[2] for row in facts["source"]}
        inputs[str(path.relative_to(ROOT))] = digest(path)
        for name, sha in inputs.items():
            self.assertEqual(digest(ROOT / name), sha, name)
        catalog = load_component_catalog(ROOT / "evidence/scenarios/parallel-gc/components.json",
            entry="parallel-gc", constructor="make-parallel-gc-review", trusted=True)
        names = ("transfer_evidence", "transfer_unbound", "composition_gap",
                 "composition_link", "composition_requirement", "missing_requirement")
        queries = {name: name for name in names}
        with engine_api() as (engine, _):
            baseline, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(baseline["transfer_unbound"], [])
            self.assertEqual({row[0] for row in baseline["transfer_evidence"]},
                             {row[0] for row in facts["transfer_condition"]})
            self.assertEqual({row[4]: row[5] for row in baseline["composition_gap"]}, {
                "final-root-state-handoff": "source-composition-unbound",
                "complete-supported-root-graph": "source-composition-unbound"})
            self.assertEqual(baseline["composition_link"], [])
            self.assertEqual(len(baseline["missing_requirement"]), len(facts["obligation"]))
            for source in {row[1] for row in facts["source_section"]}:
                withdrawn, _ = evaluate(engine, dict(facts,
                    source=[row for row in facts["source"] if row[0] != source]), catalog, queries)
                self.assertTrue(withdrawn["transfer_unbound"], source)
                self.assertEqual(withdrawn["missing_requirement"], baseline["missing_requirement"])
                self.assertEqual(withdrawn["composition_requirement"], baseline["composition_requirement"])
            stale, _ = evaluate(engine, dict(facts, interface_check=[]), catalog, queries)
            self.assertEqual({row[5] for row in stale["composition_gap"]},
                             {"model-check-unbound-or-stale"})
            self.assertEqual(stale["composition_link"], [])
            self.assertEqual(stale["missing_requirement"], baseline["missing_requirement"])
            restored, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(restored, baseline)
        self.assertEqual(facts["satisfies"], [])
        self.assertEqual(facts["composition_binding"], [])
        self.assertTrue(all(row[3] == "partial" for row in facts["model_scope"]))
        self.assertEqual(inputs, {name: digest(ROOT / name) for name in inputs})

    def test_source_composition_and_redesign_are_distinct(self):
        path = ROOT / "evidence/research/host-root-publication/facts.json"
        facts = json.loads(path.read_text())["facts"]
        inputs = {row[1]: row[2] for row in facts["source"]}
        inputs[str(path.relative_to(ROOT))] = digest(path)
        for name, sha in inputs.items():
            self.assertEqual(digest(ROOT / name), sha, name)
        catalog = load_component_catalog(ROOT / "evidence/scenarios/parallel-gc/components.json",
            entry="parallel-gc", constructor="make-parallel-gc-review", trusted=True)
        queries = {key: key for key in ("transfer_evidence", "transfer_unbound",
            "composition_gap", "composition_requirement", "composition_link", "missing_requirement")}
        expected = {"root-census-and-observed-publication": "source-composition-unbound",
                    "collector-and-host-last-use": "source-composition-unbound",
                    "general-host-registry-root-epoch-closure": "model-interface-unbound"}
        with engine_api() as (engine, _):
            baseline, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(baseline["transfer_unbound"], [])
            self.assertEqual({row[0] for row in baseline["transfer_evidence"]},
                             {row[0] for row in facts["transfer_condition"]})
            self.assertEqual({row[4]: row[5] for row in baseline["composition_gap"]}, expected)
            self.assertEqual(baseline["composition_link"], [])
            self.assertEqual(len(baseline["missing_requirement"]), len(facts["obligation"]))
            # Preserve the actual initial integration failure as a relation
            # control: target sections need their own baseline design owners.
            missing_design, _ = evaluate(engine, dict(facts, design=[row for row in facts["design"]
                if row[3] not in {"gambit-root-consumer", "gambit-call-origin"}]), catalog, queries)
            self.assertEqual(set(missing_design["transfer_unbound"]), {
                (condition[0], "gambit-design-missing") for condition in facts["transfer_condition"]})
            self.assertEqual(missing_design["missing_requirement"], baseline["missing_requirement"])
            for source in {row[1] for row in facts["source_section"]}:
                withdrawn, _ = evaluate(engine, dict(facts,
                    source=[row for row in facts["source"] if row[0] != source]), catalog, queries)
                self.assertTrue(withdrawn["transfer_unbound"], source)
                self.assertEqual(withdrawn["missing_requirement"], baseline["missing_requirement"])
                self.assertEqual(withdrawn["composition_requirement"], baseline["composition_requirement"])
            current, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(current, baseline)
            tracks = {condition: value for condition, name, value in facts["composition_attribute"]
                      if name == "research-track"}
            for condition, model, sha, status, gap in facts["model_scope"]:
                prefix = "models/gambit/" if tracks[condition] == "current-repair" else "models/experimental/"
                self.assertTrue(model.startswith(prefix), model)
                self.assertEqual(digest(ROOT / model), sha)
                self.assertEqual(status, "partial")
                self.assertTrue(gap)
        self.assertEqual(facts["satisfies"], [])
        self.assertEqual(facts["composition_binding"], [])
        self.assertEqual(inputs, {name: digest(ROOT / name) for name in inputs})
