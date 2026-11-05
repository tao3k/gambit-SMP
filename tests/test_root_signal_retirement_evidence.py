"""Root signal formal support must not admit the pending native obligations."""
import json
import unittest

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT, digest
from gambit_smp import repository_clues


class RootSignalEvidenceTests(unittest.TestCase):
    def test_formal_receipt_matches_live_model(self):
        proof = json.loads((ROOT / "evidence/model-results/processor-interrupt-collective-wait/root-signal-retirement-grok-qualified/receipt.json").read_text())
        self.assertTrue(proof["accepted"])
        self.assertTrue(proof["contextStable"])
        self.assertEqual(proof["inputs"]["models/gambit/root_signal_retirement.qnt"],
                         digest(ROOT / "models/gambit/root_signal_retirement.qnt"))
        self.assertEqual(proof["native"]["status"], "not-run")

    def test_every_source_binding_is_required_and_native_remains_open(self):
        document, facts, catalog, _ = load(ROOT,
            "evidence/scenarios/runtime-lifecycle/root-signal-retirement.view.json")
        queries = dict(document["queries"], applicable="applicable")
        with engine_api() as (engine, _):
            result, _ = evaluate(engine, facts, catalog, queries)
            for claim in ("root-signal-terminal-inflight", "root-signal-runtime-failed-join",
                          "root-signal-direct-owner-quiescence"):
                self.assertIn((claim,), result["unclosed"])
            for witness, claim, contract, _ in facts["receipt"]:
                if witness != "root-signal-formal":
                    continue
                target = (claim, witness)
                self.assertIn(target, result["applicable"])
                self.assertNotIn((claim,), result["unclosed"])
                required = [name for c, k, name in facts["required_binding"]
                            if c == claim and k == contract]
                for name in required:
                    changed = dict(facts, current_binding=[
                        (key, "changed" if key == name else value)
                        for key, value in facts["current_binding"]])
                    after, _ = evaluate(engine, changed, catalog, queries)
                    self.assertNotIn(target, after["applicable"], name)
                    self.assertEqual(changed["receipt"], facts["receipt"])

    def test_historical_assertions_do_not_become_current_native_support(self):
        document, facts, catalog, _ = load(ROOT,
            "evidence/scenarios/runtime-lifecycle/root-signal-retirement.view.json")
        native = {"root-signal-native", "root-signal-constructor"}
        self.assertTrue(native.isdisjoint(row[0] for row in facts["verified"]))
        self.assertTrue({"native-result", "constructor-result"}.isdisjoint(
            row["id"] for row in document["references"]))
        self.assertEqual({row[2] for row in facts["binding"] if row[1] == "native-result"},
                         {"d01375c77a7289c99548cc5d718f7b96aea41f7e28ece41bc7a8a1a0f95c47cd"})
        self.assertEqual({row[2] for row in facts["binding"] if row[1] == "constructor-result"},
                         {"ee696740c867119d5a248fc566255ff8b30893891591527ae7ba9e0499dd07da"})
        queries = dict(document["queries"], applicable="applicable")
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, queries)
            for claim in ("root-signal-native-comparison", "root-signal-constructor-requalification"):
                self.assertIn((claim,), answers["unclosed"])
                self.assertFalse(any(row[0] == claim for row in answers["applicable"]))
            # Merely reinstating a verified boolean cannot manufacture the raw
            # binding, withdrawal review and runtime observation obligations.
            forged = dict(facts, verified=facts["verified"] + [(n,) for n in native])
            after, _ = evaluate(engine, forged, catalog, queries)
            self.assertEqual(answers["applicable"], after["applicable"])

    def test_checkpoint_exposes_comparison_and_keeps_join_open(self):
        bindings = (("entity", "lifecycle"),
                    ("phase", "native-before-after-pass-not-terminal-seal"))
        first = repository_clues(ROOT, bindings=bindings)
        self.assertEqual(first["brief"]["families"][0]["claim"],
                         "root-signal-native-comparison")
        again = repository_clues(ROOT, bindings=bindings, checkpoint=first["checkpoint"])
        self.assertEqual(again["brief"]["families"], [])
        joined = repository_clues(ROOT, "root-signal-runtime-failed-join",
                                  checkpoint=again["checkpoint"])
        self.assertGreater(joined["brief"]["counts"]["counter"], 0)
        self.assertFalse(joined["brief"]["runtimeAdmitted"])
