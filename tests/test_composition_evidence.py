"""Real Scheme inference; synthetic bindings never certify native refinement."""
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest

from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
from gambit_smp.artifact_storage import cache_path
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT, digest
from gambit_smp.process_observation import capture


class CompositionEvidenceTests(unittest.TestCase):
    def test_registered_clue_query_and_cross_process_resume(self):
        name = "evidence/scenarios/parallel-gc/retirement-exit-handoff.view.json"
        document, facts, _, _ = load(ROOT, name)
        profile = json.loads((ROOT / "evidence/scenarios/parallel-gc/runtime-entry-facts.json").read_text())["facts"]
        for relation in ("composition_edge", "composition_attribute", "model_interface",
                         "interface_check", "composition_binding"):
            self.assertEqual(facts[relation], profile[relation])
        parent = cache_path(ROOT, "retirement-clue-session")
        parent.mkdir(parents=True, exist_ok=True)
        # A metadata-only isolated registration leaves the active native
        # registry untouched. Read-only references are hardlinks, not builds.
        with tempfile.TemporaryDirectory(prefix="session-", dir=parent) as directory:
            root = Path(directory)
            selection = json.loads((ROOT / "evidence/views.json").read_text())["selection"]
            paths = {name, document["manifest"], selection["source"],
                "evidence/scenarios/parallel-gc/design.ss"}
            paths.update(ref["path"] for ref in document["references"])
            for path in paths:
                target = root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                os.link(ROOT / path, target)
            (root / "evidence/views.json").write_text(json.dumps({
                "schema": "ascent.evidence-views.v1", "views": [name], "selection": selection}))
            script = "\n".join(("import json, sys",
                "from gambit_smp import repository_clues",
                "print(json.dumps(repository_clues(sys.argv[1], **json.loads(sys.argv[2]))))"))

            def read(request):
                row = capture([sys.executable, "-c", script, str(root), json.dumps(request)],
                              ROOT, 30, dict(os.environ))
                self.assertFalse(row.timeout)
                self.assertTrue(row.group_quiescent)
                self.assertEqual(row.exit, 0, row.stdout + row.stderr)
                result = json.loads(row.stdout)
                self.assertFalse(result["brief"]["runtimeAdmitted"])
                return result

            bindings = [["mechanism", "retirement-exit-handoff"],
                        ["property", "origin-tail-before-collective"]]
            first = read({"bindings": bindings})
            self.assertEqual(len(first["brief"]["families"]), 1)
            observation = first["brief"]["families"][0]["observations"][0]
            self.assertEqual(observation["factors"]["scope"], ["pinned-entry-return"])
            self.assertEqual(observation["factors"]["unresolved-premise"], ["source-composition-unbound"])
            self.assertTrue(first["brief"]["presentationComplete"])
            resumed = read({"bindings": bindings, "checkpoint": first["checkpoint"]})
            self.assertEqual(resumed["brief"]["families"], [])
            self.assertEqual(resumed["brief"]["counts"], first["brief"]["counts"])
            wider = read({"bindings": bindings[:1], "checkpoint": resumed["checkpoint"]})
            self.assertEqual(len(wider["brief"]["families"]), 2)
            self.assertTrue(wider["brief"]["presentationComplete"])

    def test_new_edges_stale_checks_and_scope_specific_links(self):
        directory = ROOT / "evidence/scenarios/parallel-gc"
        base = json.loads((directory / "runtime-entry-facts.json").read_text())["facts"]
        catalog = load_component_catalog(directory / "components.json", entry="parallel-gc",
            constructor="make-parallel-gc-review", trusted=True)
        model = ROOT / "models/gambit/retirement_exit_handoff.qnt"
        model_sha = digest(model)
        prop = "origin-tail-before-collective"
        edge = ["runtime-host-entry", "fixture-scope", "current-generated-entry-cleanup",
                "current-marker-error-tail", prop]
        source = ["fixture-model", str(model.relative_to(ROOT)), model_sha, "fixture-only"]
        fixture = ["fixture-source", str(Path(__file__).relative_to(ROOT)),
                   digest(Path(__file__)), "synthetic-binding-relation-not-native-proof"]
        section = ["fixture-receipt", "fixture-source", "synthetic-relation-fixture",
                   "unit fixture for inference identity; not runtime refinement"]
        source_shas = {row[0]: row[2] for row in base["source"]}
        facts = dict(base, source=[*base["source"], source, fixture],
            source_section=[*base["source_section"], section], composition_edge=[["fixture-edge", *edge]],
            model_interface=[], interface_check=[], composition_binding=[],
            composition_profile=[["runtime-host-entry", "fixture-source"]])
        queries = {key: key for key in ("composition_requirement", "composition_model_evidence",
            "composition_link", "composition_gap", "transfer_gap", "missing_requirement", "clue", "factor")}

        with engine_api() as (engine, _):
            def run(value):
                answers, _ = evaluate(engine, value, catalog, queries)
                self.assertEqual(len(answers["missing_requirement"]), len(base["obligation"]))
                return answers

            old = run(facts)
            self.assertEqual(len(old["clue"]), 1)
            self.assertEqual(old["composition_requirement"], [tuple(edge)])
            self.assertEqual(old["composition_gap"], [(*edge, "model-interface-unbound")])
            # Existing finite passes and unrelated interfaces cannot cover a new edge.
            unrelated = dict(facts, model_interface=[["fixture-model", "different-property"]])
            self.assertEqual(run(unrelated)["composition_gap"], old["composition_gap"])
            interface = dict(facts, model_interface=[["fixture-model", prop]])
            self.assertEqual(run(interface)["composition_gap"],
                [(*edge, "model-check-unbound-or-stale")])
            checked = dict(interface, interface_check=[
                ["fixture-model", model_sha, prop, "fixture-receipt", fixture[2]]])
            before_binding = run(checked)
            self.assertEqual(len(before_binding["composition_model_evidence"]), 1)
            self.assertEqual(before_binding["composition_gap"],
                [(*edge, "source-composition-unbound")])
            binding = [*edge, source_shas["gambit-header"], source_shas["gambit-module-exposure"],
                       "fixture-model", model_sha, "fixture-receipt", fixture[2]]
            linked = dict(checked, composition_binding=[binding])
            supported = run(linked)
            self.assertEqual(supported["composition_gap"], [])
            self.assertEqual(len(supported["composition_link"]), 1)
            self.assertEqual(supported["missing_requirement"], old["missing_requirement"])

            stale_check = dict(linked, interface_check=[
                ["fixture-model", "old-model-sha", prop, "fixture-receipt", fixture[2]]])
            self.assertEqual(run(stale_check)["composition_gap"],
                [(*edge, "model-check-unbound-or-stale")])
            for index, replacement in ((1, "other-scope"), (2, "other-source-event"),
                                       (4, "different-property"), (5, "old-from-source"),
                                       (6, "old-to-source"), (8, "old-model-sha"),
                                       (10, "old-refinement")):
                changed_binding = list(binding)
                changed_binding[index] = replacement
                changed = dict(linked, composition_binding=[changed_binding])
                self.assertEqual(run(changed)["composition_gap"],
                    [(*edge, "source-composition-unbound")])

            stale_receipt = dict(linked, interface_check=[
                ["fixture-model", model_sha, prop, "fixture-receipt", "old-receipt-sha"]])
            self.assertEqual(run(stale_receipt)["composition_gap"],
                [(*edge, "model-check-unbound-or-stale")])
            incomplete_bundle = dict(linked,
                model_interface=[["fixture-model", prop], ["unavailable-second-check", prop]])
            self.assertEqual(run(incomplete_bundle)["composition_gap"],
                [(*edge, "model-check-unbound-or-stale")])

            # Withdrawing a premise must expose a gap, not erase the obligation.
            without_source = dict(linked, source=[row for row in linked["source"]
                if row[0] != "gambit-header"])
            lost = run(without_source)
            self.assertEqual(lost["composition_requirement"], [tuple(edge)])
            self.assertEqual(lost["composition_gap"], [(*edge, "source-composition-unbound")])
            without_receipt = dict(linked, source_section=[row for row in linked["source_section"]
                if row[0] != "fixture-receipt"])
            self.assertEqual(run(without_receipt)["composition_gap"],
                [(*edge, "model-check-unbound-or-stale")])

            # Incremental evidence introduces a new scoped edge without revoking
            # the old valid relation or pretending it covers the new scope.
            new_edge = list(edge)
            new_edge[1] = "new-scope"
            expanded = dict(linked, composition_edge=[["fixture-edge", *edge], ["new-edge", *new_edge]])
            more = run(expanded)
            self.assertEqual(len(more["composition_link"]), 1)
            self.assertEqual(more["composition_gap"], [(*new_edge, "source-composition-unbound")])
            self.assertIn((new_edge[0], new_edge[1], prop, "source-composition-unbound"),
                          more["transfer_gap"])
            repeated, reuse = evaluate(engine, expanded, catalog, queries)
            self.assertEqual(repeated, more)
            self.assertTrue(reuse["nativeResultReused"])
            collision = run(dict(linked, composition_edge=[
                ["collision", *edge], ["collision", *new_edge]]))
            self.assertEqual(collision["clue"], [])
            self.assertIn((*edge, "ambiguous-clue-identity"), collision["composition_gap"])
            empty = run(dict(facts, composition_edge=[]))
            self.assertEqual(empty["composition_requirement"], [])
            self.assertEqual(empty["missing_requirement"], old["missing_requirement"])
        self.assertEqual(base["satisfies"], [])
