"""Research classification through existing native Scheme relations, not admission."""
import json
import unittest

from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
from gambit_smp.framework import ROOT, digest


class RepairRedesignEvidenceTests(unittest.TestCase):
    expected_gaps = {
        "release-error-disposition": "model-interface-unbound",
        "participant-exit-handshake": "source-composition-unbound",
        "post-exit-publication-exclusion": "source-composition-unbound",
        "rc-record-last-use-and-root-handoff": "model-interface-unbound",
        "scanner-owned-delete": "source-composition-unbound",
        "registry-slot-last-use": "source-composition-unbound",
        "root-payload-update-barrier": "model-interface-unbound",
        "global-root-scan-before-resume": "source-composition-unbound"}

    def setUp(self):
        self.path = ROOT / "evidence/research/repair-and-redesign/facts.json"
        self.facts = json.loads(self.path.read_text())["facts"]
        self.inputs = {row[1]: row[2] for row in self.facts["source"]}
        self.inputs[str(self.path.relative_to(ROOT))] = digest(self.path)
        for path, sha in self.inputs.items():
            self.assertEqual(digest(ROOT / path), sha, path)
        self.catalog = load_component_catalog(
            ROOT / "evidence/scenarios/parallel-gc/components.json",
            entry="parallel-gc", constructor="make-parallel-gc-review", trusted=True)
        self.queries = {name: name for name in (
            "transfer_evidence", "transfer_gap", "transfer_unbound",
            "transfer_premise_evidence", "composition_requirement",
            "composition_gap", "composition_link", "missing_requirement")}

    def tearDown(self):
        for path, sha in self.inputs.items():
            self.assertEqual(digest(ROOT / path), sha, "changed research input: " + path)

    def test_both_lines_expose_unproved_interfaces_without_native_credit(self):
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, self.facts, self.catalog, self.queries)
            self.assertEqual(answers["transfer_unbound"], [])
            expected = {row[0] for row in self.facts["transfer_condition"]}
            self.assertEqual({row[0] for row in answers["transfer_evidence"]}, expected)
            self.assertEqual({row[0] for row in answers["transfer_gap"]}, expected)
            self.assertEqual(set(answers["composition_gap"]), {
                (*edge[1:], self.expected_gaps[edge[-1]]) for edge in self.facts["composition_edge"]})
            self.assertEqual(answers["composition_link"], [])
            self.assertEqual(len(answers["missing_requirement"]), len(self.facts["obligation"]))
            self.assertEqual(self.facts["satisfies"], [])
            tracks = {condition: value for condition, name, value in self.facts["composition_attribute"]
                      if name == "research-track"}
            for condition, model, sha, coverage, gap in self.facts["model_scope"]:
                prefix = {"experimental": "models/experimental/",
                          "current-repair": "models/gambit/"}[tracks[condition]]
                self.assertTrue(model.startswith(prefix), model)
                self.assertEqual(digest(ROOT / model), sha)
                self.assertEqual(coverage, "partial")
                self.assertTrue(gap)
            repeated, reused = evaluate(engine, self.facts, self.catalog, self.queries)
            self.assertEqual(repeated, answers)
            self.assertTrue(reused["nativeResultReused"])
            withheld = dict(self.facts, interface_check=[
                row for row in self.facts["interface_check"]
                if not (row[0] == "participant-exit-proof" and
                        row[2] == "participant-exit-handshake")])
            partial, _ = evaluate(engine, withheld, self.catalog, self.queries)
            expected_partial = dict(self.expected_gaps,
                                    **{"participant-exit-handshake": "model-check-unbound-or-stale"})
            self.assertEqual({row[4]: row[5] for row in partial["composition_gap"]}, expected_partial)
            self.assertEqual(partial["missing_requirement"], answers["missing_requirement"])
            historical_sha = next(row[2] for row in self.facts["source"]
                                  if row[0] == "registry-continuation-validation")
            stale_checks = [row[:4] + [historical_sha]
                            if row[2] == "global-root-scan-before-resume" else row
                            for row in self.facts["interface_check"]]
            stale, _ = evaluate(engine, dict(self.facts, interface_check=stale_checks),
                                self.catalog, self.queries)
            self.assertEqual({row[4]: row[5] for row in stale["composition_gap"]},
                dict(self.expected_gaps,
                     **{"global-root-scan-before-resume": "model-check-unbound-or-stale"}))
            self.assertEqual(stale["missing_requirement"], answers["missing_requirement"])

    def test_even_checked_relation_cannot_cross_research_scope_or_imply_native_pass(self):
        # A synthetic relation control, not a newly checked QNT/Lean property.
        edge = self.facts["composition_edge"][0][1:]
        condition, scope, source, target, prop = edge
        shas = {row[0]: row[2] for row in self.facts["source"]}
        facts = dict(self.facts,
            model_interface=[["current-handoff", prop]],
            interface_check=[["current-handoff", shas["current-handoff"], prop,
                              "program-boundary", shas["repair-program"]]])
        binding = [condition, scope, source, target, prop,
                   shas["gambit-release"], shas["gambit-memory"],
                   "current-handoff", shas["current-handoff"],
                   "program-boundary", shas["repair-program"]]
        with engine_api() as (engine, _):
            fixture = dict(facts, composition_binding=[binding])
            linked, _ = evaluate(engine, fixture, self.catalog, self.queries)
            self.assertEqual(len(linked["composition_link"]), 1)
            for changed_scope in ("experimental", "another-current-scope"):
                changed = [*binding]
                changed[1] = changed_scope
                wrong, _ = evaluate(engine, dict(facts, composition_binding=[changed]),
                                    self.catalog, self.queries)
                self.assertEqual(wrong["composition_link"], [])
                self.assertIn((*edge, "source-composition-unbound"), wrong["composition_gap"])
                self.assertEqual(wrong["missing_requirement"], linked["missing_requirement"])
            self.assertEqual(len(linked["missing_requirement"]), len(self.facts["obligation"]))

    def test_source_withdrawal_preserves_owed_requirements(self):
        with engine_api() as (engine, _):
            baseline, _ = evaluate(engine, self.facts, self.catalog, self.queries)
            for source in ("gambit-release", "gambit-memory", "ocaml-participation",
                           "chez-owner", "current-handoff", "architectural-handoff",
                           "repair-program", "gambit-explicit-release", "chez-owner-consumer",
                           "participant-exit-validation", "participant-exit-design",
                           "ocaml-root-registry", "ocaml-root-api", "ocaml-root-lock-platform", "ocaml-foreign-effects",
                           "chez-collector-entry", "chez-context-effects", "rc-root-projection",
                           "reader-lifetime-projection", "registry-callback-model",
                           "registry-callback-proof", "registry-phase-validation",
                           "registry-source-design", "gambit-dynamic-closure",
                           "gambit-tcl-example", "ocaml-parallel-entry",
                           "ocaml-global-scan", "ocaml-minor-scan"):
                facts = dict(self.facts, source=[row for row in self.facts["source"] if row[0] != source])
                withdrawn, _ = evaluate(engine, facts, self.catalog, self.queries)
                self.assertTrue(withdrawn["transfer_unbound"], source)
                self.assertEqual(withdrawn["composition_requirement"], baseline["composition_requirement"])
                self.assertEqual(withdrawn["missing_requirement"], baseline["missing_requirement"])
            restored, _ = evaluate(engine, self.facts, self.catalog, self.queries)
            self.assertEqual(restored, baseline)
            # A previous receipt is retained history, not a prerequisite for
            # the independently rechecked current model/source identities.
            without_history = dict(self.facts, source=[row for row in self.facts["source"]
                if row[0] != "registry-continuation-validation"])
            current, _ = evaluate(engine, without_history, self.catalog, self.queries)
            self.assertEqual(current, baseline)
