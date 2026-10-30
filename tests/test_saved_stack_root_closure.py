"""Current root-closure research; no native qualification or runtime edits."""
import json
import unittest

from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
from gambit_smp.framework import ROOT, digest

from tests import test_host_root_publication_evidence as contracts


class SavedStackRootClosureTests(unittest.TestCase):
    def test_guarded_root_closure_contracts(self):
        contracts.HostRootPublicationEvidenceTests()._check_lean(
            "SavedStackRootClosure.lean", "root-closure.manifest.json", (
                "explicitEdgesPreserveReachability", "pointerToPermanentIsNotPayloadScan",
                "declaredClosureCoversActualConsumers", "headClosureDoesNotCloseTail",
                "twoCyclesDoNotRestoreIdentity"))

    def test_root_origin_and_phase_gaps_remain_source_bound(self):
        directory = ROOT / "evidence/research/host-root-publication"
        path = directory / "root-closure-facts.json"
        facts = json.loads(path.read_text())["facts"]
        inputs = dict(json.loads((directory / "root-closure.manifest.json").read_text())["contextInputs"])
        inputs.update({row[1]: row[2] for row in facts["source"]})
        inputs[str(path.relative_to(ROOT))] = digest(path)
        self.assertEqual(inputs, {name: digest(ROOT / name) for name in inputs})
        catalog = load_component_catalog(ROOT / "evidence/scenarios/parallel-gc/components.json",
            entry="parallel-gc", constructor="make-parallel-gc-review", trusted=True)
        queries = {name: name for name in ("transfer_evidence", "transfer_unbound",
            "composition_gap", "composition_link", "composition_requirement",
            "missing_requirement", "clue", "factor", "link")}
        with engine_api() as (engine, _):
            baseline, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(baseline["transfer_unbound"], [])
            self.assertEqual({row[0] for row in baseline["transfer_evidence"]},
                             {row[0] for row in facts["transfer_condition"]})
            self.assertEqual({row[4]: row[5] for row in baseline["composition_gap"]}, {
                "explicit-permanent-payload-root-closure": "source-composition-unbound",
                "complete-raw-origin-discharge": "source-composition-unbound",
                "phase-specific-last-consumer": "source-composition-unbound"})
            self.assertEqual(baseline["composition_link"], [])
            self.assertEqual(len(baseline["missing_requirement"]), 3)
            self.assertEqual({row[0] for row in baseline["clue"]},
                             {row[0] for row in facts["composition_edge"]})
            self.assertTrue(baseline["factor"])
            self.assertTrue(baseline["link"])
            for source in {row[1] for row in facts["source_section"]}:
                withdrawn, _ = evaluate(engine, dict(facts,
                    source=[row for row in facts["source"] if row[0] != source]), catalog, queries)
                self.assertTrue(withdrawn["transfer_unbound"], source)
                self.assertEqual(withdrawn["missing_requirement"], baseline["missing_requirement"])
                self.assertEqual(withdrawn["composition_requirement"], baseline["composition_requirement"])
            unchecked, _ = evaluate(engine, dict(facts, interface_check=[]), catalog, queries)
            self.assertEqual({row[5] for row in unchecked["composition_gap"]},
                             {"model-check-unbound-or-stale"})
            restored, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(restored, baseline)
        self.assertEqual(facts["satisfies"], [])
        self.assertEqual(facts["composition_binding"], [])
        self.assertTrue(all(row[3] == "partial" for row in facts["model_scope"]))
        self.assertEqual(inputs, {name: digest(ROOT / name) for name in inputs})
