"""Repair interfaces are source-bound research, never native closure."""
import unittest
from pathlib import Path
import tempfile
import json

from gambit_smp.framework import ROOT, digest
from gambit_smp.verify_protocols import retain_reused_artifacts
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load

from tests import test_host_root_publication_evidence as contracts


class RepairConsumerInterfaceTests(unittest.TestCase):
    def test_published_model_controls_have_complete_checked_closures(self):
        from gambit_smp.protocol_evidence import checked_rows, bundle_facts
        imports_name = "evidence/research/host-root-publication/imports.manifest.json"
        imports = json.loads((ROOT / imports_name).read_text())
        declaration_receipt = "evidence/model-results/current-repair-consumer-interfaces/imports-declaration-only/receipt.json"
        self.assertFalse((ROOT / declaration_receipt).exists())
        self.assertTrue(all(c["registrationOnly"] for c in imports["cases"]))
        imported, _ = bundle_facts(ROOT, imports_name, declaration_receipt)
        self.assertEqual(imported["protocol_checked"], [])
        known = {c["id"] for c in imports["cases"]}
        pairs = (("handler-return-tail", "handler-admitted-tail-qualified", 6),
                 ("last-access", "last-access-declaration-bound", 4))
        for manifest_name, receipt_name, count in pairs:
            with self.subTest(model=manifest_name):
                manifest = json.loads((ROOT / "evidence/research/host-root-publication" /
                    (manifest_name + ".manifest.json")).read_text())
                receipt = ROOT / "evidence/model-results/current-repair-consumer-interfaces" / receipt_name / "receipt.json"
                rows = checked_rows(ROOT, manifest, receipt)
                self.assertEqual(len(rows), 1)
                self.assertEqual(len(rows[0][1]), count)
                self.assertTrue(all(row["accepted"] for row in rows[0][1]))
                projected, _ = bundle_facts(ROOT,
                    "evidence/research/host-root-publication/" + manifest_name + ".manifest.json",
                    str(receipt.relative_to(ROOT)))
                self.assertEqual(projected["protocol_checked"], [(manifest["cases"][0]["id"], digest(receipt))])
                self.assertTrue(projected["protocol_composes"])
                self.assertTrue(projected["protocol_source"])
                self.assertTrue(all(parent in known for _, parent in projected["protocol_composes"]))
                if manifest_name == "handler-return-tail":
                    control = next(row for row in rows[0][1]
                                   if row["invariant"] == "noPostReleaseTail")
                    trace = json.loads((receipt.parent / control["trace"]).read_text())
                    tail = trace["states"][-1]["h"]
                    self.assertTrue(tail["admitted"])
                    self.assertEqual((tail["stage"], tail["cReaders"]), (4, 0))

    def test_source_correspondence_stays_open_when_models_are_checked(self):
        doc, facts, catalog, _ = load(ROOT, "evidence/scenarios/runtime-lifecycle/current-repair.view.json")
        queries = {q: q for q in ("model_gaps", "revision_gaps", "applicability_gaps",
            "assumption_deltas", "current_scope_review", "applicable", "unclosed")}
        with engine_api() as (engine, _):
            original, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(len(original["model_gaps"]), 3)
            self.assertEqual({r[3] for r in original["applicability_gaps"]}, {
                "handler-delivery-before-c", "handler-post-release-tail",
                "inflight-last-access-source", "consumer-census-source",
                "tty-last-consumer-source"})
            self.assertEqual(len(original["assumption_deltas"]), 5)
            self.assertEqual(original["revision_gaps"], [])
            self.assertEqual(original["current_scope_review"], [])
            self.assertEqual(original["applicable"], [])
            self.assertEqual({r[0] for r in original["unclosed"]},
                             {r[0] for r in facts["requirement"]})
            changed = dict(facts, source=[(i, p, "changed" if i == "handler-model" else h)
                                         for i, p, h in facts["source"]])
            stale, _ = evaluate(engine, changed, catalog, queries)
            self.assertTrue(stale["revision_gaps"])
            self.assertEqual(stale["applicable"], [])
            self.assertEqual(stale["unclosed"], original["unclosed"])
            restored, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(restored, original)

    def test_registered_first_related_query_and_continuation_expose_the_mechanism_gap(self):
        from gambit_smp import repository_clues
        first = repository_clues(ROOT, bindings=[("mechanism", "saved-stack-last-access")],
                                 display_bytes=16384)
        self.assertIn("inflight-last-access-source", {f["claim"] for f in first["brief"]["families"]})
        family = next(f for f in first["brief"]["families"]
                      if f["claim"] == "inflight-last-access-source")
        factors = family["observations"][0]["factors"]
        self.assertEqual(factors["model-source-path"], ["models/gambit/saved_stack_last_access.qnt"])
        self.assertEqual(factors["model-source-sha"], [digest(ROOT / factors["model-source-path"][0])])
        self.assertIn("models/gambit/saved_stack_retirement_window.qnt",
                      factors["related-model-reference"])
        self.assertNotIn("model-reference", factors)
        self.assertFalse(first["brief"]["runtimeAdmitted"])
        continued = repository_clues(ROOT, checkpoint=first["checkpoint"], display_bytes=16384)
        self.assertEqual(continued["brief"]["delta"]["added"], 0)
        self.assertEqual(continued["brief"]["families"], [])

    def test_tty_census_query_preserves_outer_caller_counterevidence(self):
        from gambit_smp import repository_clues
        first = repository_clues(ROOT, bindings=[("mechanism", "tty-device-last-access")],
                                 display_bytes=16384)
        family = next(f for f in first["brief"]["families"]
                      if f["claim"] == "tty-last-consumer-source")
        factors = family["observations"][0]["factors"]
        self.assertEqual(factors["model-source-path"],
                         ["models/gambit/lean/RepairConsumerInterfaces.lean"])
        self.assertEqual(factors["model-source-sha"],
                         [digest(ROOT / factors["model-source-path"][0])])
        self.assertIn("outer-cleanup-attempts-handler-removal-before-io-cleanup",
                      factors["counterevidence"])
        self.assertIn("root-vm-lease-is-not-a-tty-consumer-census", factors["reuse-boundary"])
        self.assertFalse(first["brief"]["runtimeAdmitted"])
        continued = repository_clues(ROOT, checkpoint=first["checkpoint"], display_bytes=16384)
        self.assertEqual(continued["brief"]["delta"]["added"], 0)
        self.assertEqual(continued["brief"]["families"], [])

    def test_reused_checker_artifacts_remain_hash_bound_and_publishable(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "old", Path(directory) / "resumed"
            original = source / "checks/model/spec.tla"
            original.parent.mkdir(parents=True)
            original.write_text("source-bound checker artifact")
            expected = digest(original)
            row = {"checker": {"artifacts": {"checks/model/spec.tla": expected}}}
            inputs = retain_reused_artifacts(source, target, row)
            self.assertEqual(inputs, {str(original.resolve()): expected})
            self.assertEqual(digest(target / "checks/model/spec.tla"), expected)
            original.write_text("changed")
            with self.assertRaisesRegex(ValueError, "artifact changed"):
                retain_reused_artifacts(source, target, row)

    def test_reused_artifact_collision_and_escape_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "old", Path(directory) / "resumed"
            source.mkdir()
            target.mkdir()
            original = source / "spec.tla"
            original.write_text("checked")
            collision = target / "spec.tla"
            collision.write_text("other history")
            row = {"checker": {"artifacts": {"spec.tla": digest(original)}}}
            with self.assertRaisesRegex(ValueError, "collision"):
                retain_reused_artifacts(source, target, row)
            self.assertEqual(collision.read_text(), "other history")
            for name in ("../outside", "/absolute"):
                with self.subTest(name=name), self.assertRaises(ValueError):
                    retain_reused_artifacts(source, target,
                        {"checker": {"artifacts": {name: digest(original)}}})

    def test_guarded_parameterized_consumer_contracts(self):
        contracts.HostRootPublicationEvidenceTests()._check_lean(
            "RepairConsumerInterfaces.lean", "repair-interfaces.manifest.json", (
                "unfinishedInvocationBlocksDrain", "emptyEntryCensusDoesNotProveDrain",
                "declaredAndPrivateConsumersCompose", "omittedPrivateConsumerDefeatsPublicCompletion",
                "newEntryEpochDoesNotRestoreDeliveryEpoch", "lastResourceAccessCanPrecedeInvocationReturn"))


if __name__ == "__main__":
    unittest.main()
