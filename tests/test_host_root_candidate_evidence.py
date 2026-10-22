"""Current candidate research bindings, not native qualification."""
import json
from pathlib import Path
import unittest

from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
from gambit_smp.framework import ROOT, digest
from tests import test_host_root_publication_evidence as contracts


class HostRootCandidateEvidenceTests(unittest.TestCase):
    def test_multiline_axioms_preserve_rejection_controls(self):
        guard = contracts.HostRootPublicationEvidenceTests()
        guard._check_axioms("proof depends on axioms: [propext,\n Classical.choice,\n Quot.sound]\n")
        for output in (
            "proof depends on axioms: [propext,\n unknownAx]\n",
            "proof depends on axioms: [propext,\n Classical.choice\n",
            "proof depends on axioms: [propext,\n sorryAx]\n",
        ):
            with self.subTest(output=output), self.assertRaises(AssertionError):
                guard._check_axioms(output)

    def test_guarded_source_census_contracts(self):
        contracts.HostRootPublicationEvidenceTests()._check_lean(
            "HostRootSourceCensus.lean", "candidate.manifest.json", (
                "partitionedCoverage", "listSpliceDoesNotDischargeActivation",
                "absentSlotsPermitRestrictedTransfer",
                "emptyPublicQueuesStillNeedProducerLifetime"))

    def test_current_source_bindings_do_not_grant_complete_census(self):
        path = ROOT / "evidence/research/host-root-publication/candidate-facts.json"
        facts = json.loads(path.read_text())["facts"]
        inputs = {row[1]: row[2] for row in facts["source"]}
        inputs[str(path.relative_to(ROOT))] = digest(path)
        inputs[str(Path(__file__).relative_to(ROOT))] = digest(Path(__file__))
        for name, sha in inputs.items():
            self.assertEqual(digest(ROOT / name), sha, name)
        sources = {row[0]: row[1] for row in facts["source"]}
        lock = json.loads((ROOT / sources[facts["composition_profile"][0][1]]).read_text())
        self.assertEqual(digest(ROOT / lock["patch"]), lock["patchSha256"])
        catalog = load_component_catalog(ROOT / "evidence/scenarios/parallel-gc/components.json",
            entry="parallel-gc", constructor="make-parallel-gc-review", trusted=True)
        queries = {key: key for key in ("transfer_evidence", "transfer_unbound",
            "composition_gap", "composition_requirement", "composition_link", "missing_requirement",
            "clue", "factor", "link")}
        with engine_api() as (engine, _):
            baseline, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(baseline["transfer_unbound"], [])
            self.assertEqual({row[0] for row in baseline["transfer_evidence"]},
                             {row[0] for row in facts["transfer_condition"]})
            self.assertEqual({row[4]: row[5] for row in baseline["composition_gap"]}, {
                "saved-stack-source-disposition": "source-composition-unbound",
                "prior-callback-and-queue-closure": "source-composition-unbound",
                "channel-final-consumer": "source-composition-unbound"})
            self.assertEqual(baseline["composition_link"], [])
            self.assertEqual({row[0] for row in baseline["clue"]},
                             {row[0] for row in facts["composition_edge"]})
            self.assertTrue(baseline["factor"])
            self.assertTrue(baseline["link"])
            self.assertEqual(len(baseline["missing_requirement"]), len(facts["obligation"]))
            for source in {row[1] for row in facts["source_section"]}:
                withdrawn, _ = evaluate(engine, dict(facts,
                    source=[row for row in facts["source"] if row[0] != source]), catalog, queries)
                self.assertTrue(withdrawn["transfer_unbound"], source)
                self.assertEqual(withdrawn["missing_requirement"], baseline["missing_requirement"])
                self.assertEqual(withdrawn["composition_requirement"], baseline["composition_requirement"])
            unchecked, _ = evaluate(engine, dict(facts, interface_check=[]), catalog, queries)
            self.assertEqual({row[5] for row in unchecked["composition_gap"]},
                             {"model-check-unbound-or-stale"})
            self.assertEqual(unchecked["composition_link"], [])
            restored, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(restored, baseline)
        self.assertEqual(facts["satisfies"], [])
        self.assertEqual(facts["composition_binding"], [])
        self.assertTrue(all(row[3] == "partial" for row in facts["model_scope"]))
        self.assertEqual(inputs, {name: digest(ROOT / name) for name in inputs})
