import unittest
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from gambit_smp.ascent_review import project


def current_review(facts):
    from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
    from gambit_smp.ascent_review import REVIEW_OUTPUTS
    from gambit_smp.framework import ROOT
    catalog = load_component_catalog(ROOT / "evidence/dsl/components.json", entry="review",
                                     constructor="make-review", trusted=True)
    with engine_api() as (engine, _):
        rows, _ = evaluate(engine, facts, catalog, {name: name for name in REVIEW_OUTPUTS})
    return {name: [list(row) for row in values] for name, values in rows.items()}


class EvidenceProjectionTest(unittest.TestCase):
    def setUp(self):
        self.base = {"facts": {"model_receipt": [["parent", "hash", "finite-state-TLC"]],
                               "model_contract": [["parent", "child", "precondition"]],
                               "protocol_obligation": [["parent", "native-origin"]]}}
        self.failures = [{"id": "f", "file": "group/example.scm", "receipt": "failed.json", "models": ["parent"]}]

    def test_models_keep_finite_scope_and_open_native_obligations(self):
        facts = project(self.base, self.failures, "snapshot")
        self.assertEqual(facts["Passed"], [["parent:hash", "finite-model:parent"]])
        self.assertIn(["finite-model:parent", "finite-model:child"], facts["ClaimDepends"])
        self.assertIn(["finite-model:parent", "native-obligation:native-origin"], facts["ClaimDepends"])
        self.assertEqual(facts["Candidate"][0][2], facts["Failure"][0][2])

    def test_changed_binary_and_text_hypothesis_never_create_causal_evidence(self):
        facts = project(self.base, self.failures, "snapshot", {"hypothesis": "fixed"}, ["binarySha256"])
        self.assertNotEqual(facts["Candidate"][0][2], facts["Failure"][0][2])
        self.assertEqual(facts["Cause"], [])
        self.assertIn(["f", "reviewed-causal-link:f"], facts["Requires"])

    def test_recorded_observation_does_not_become_a_causal_link_or_native_pass(self):
        facts = project(self.base, self.failures, "snapshot", observations=[{"id": "upstream-report"}])
        self.assertIn(["audit:upstream-report", "recorded-observation:upstream-report"], facts["Passed"])
        self.assertEqual(facts["Cause"], [])

    def test_native_invalidation_preserves_independent_receipt(self):
        from gambit_smp.ascent_program import engine_api
        from gambit_smp.review_brief import render

        base = {"facts": {"protocol_checked": [["a", "ha"], ["b", "hb"], ["c", "hc"]],
                          "protocol_composes": [["b", "a"]],
                          "protocol_obligation": [["b", "source-refinement"]]}}
        specs = {
            "a:ha": {"path": "a.json", "inputs": {"a.json": "ha", "a.c": "old"},
                     "binding": "recorded", "depends": []},
            "b:hb": {"path": "b.json", "inputs": {"b.json": "hb"},
                     "binding": "recorded", "depends": ["a:ha"]},
            "c:hc": {"path": "c.json", "inputs": {"c.json": "hc"},
                     "binding": "recorded", "depends": []}}
        facts = project(base, [], "snapshot", bindings=specs,
                        current_inputs={"validated-catalog": "snapshot", "a.json": "ha",
                                        "a.c": "new", "b.json": "hb", "c.json": "hc"},
                        task_model="b")
        rows = current_review(facts)
        self.assertIn(["a:ha", "stale-or-missing-input"], rows["Unusable"])
        self.assertIn(["b:hb", "invalid-dependency"], rows["Unusable"])
        self.assertIn(["c:hc", "finite-model:c"], rows["Reusable"])
        brief = render("b", facts, rows, specs, [], [], base["facts"])
        self.assertEqual({row["receipt"] for row in brief["invalidated"]}, {"a:ha", "b:hb"})
        self.assertEqual(brief["reusable"], [])
        self.assertIn("native-obligation:source-refinement", brief["openPremises"])
        self.assertEqual(brief["gates"]["nativeGcAndLifecycle"], "open")
        from gambit_smp.review_graph import build
        with TemporaryDirectory() as directory:
            graph = build(Path(directory), "b", facts, rows, specs, base["facts"], {}, {},
                          git_state={"root": directory, "head": "fixture", "branch": "fixture", "files": {}})
        self.assertFalse(any(edge["relation"] == "supports-in-snapshot" for edge in graph["edges"]))
        self.assertEqual({"a:ha", "b:hb"}, {node["key"] for node in graph["nodes"] if node["kind"] == "receipt"})

    def test_revalidated_output_replaces_only_verifier_identity(self):
        from gambit_smp.framework import digest
        from gambit_smp.review_inputs import VERIFIER_MODULES, _record

        with TemporaryDirectory() as directory:
            root = Path(directory)
            for name in VERIFIER_MODULES:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("current verifier\n")
            (root / "source.c").write_text("changed runtime source\n")
            receipt = root / "receipt.json"
            receipt.write_text(json.dumps({"inputs": {
                "source.c": "old-source-hash",
                "tools/model/check_gambit.py": "old-verifier-hash"}}))
            bound, level, superseded = _record(root, "receipt.json", digest(receipt),
                                                rechecked=True)
            self.assertEqual(level, "revalidated-output")
            self.assertEqual(superseded, ["tools/model/check_gambit.py"])
            self.assertEqual(bound["source.c"], "old-source-hash")
            self.assertNotEqual(bound["source.c"], digest(root / "source.c"))
            self.assertNotIn("tools/model/check_gambit.py", bound)
            self.assertEqual(bound[VERIFIER_MODULES[0]], digest(root / VERIFIER_MODULES[0]))

    def test_audit_observation_depends_on_referenced_receipt(self):
        from gambit_smp.framework import digest
        from gambit_smp.review_inputs import bindings

        with TemporaryDirectory() as directory:
            root = Path(directory)
            model = root / "models/gambit"
            model.mkdir(parents=True)
            (model / "m.qnt").write_text("module m {}\n")
            (model / "cases.json").write_text(json.dumps({"cases": [
                {"id": "m", "modelReceipt": "evidence/m.json"}]}))
            evidence = root / "evidence"
            evidence.mkdir()
            (evidence / "research-audit.json").write_text("{}")
            receipt = evidence / "m.json"
            receipt.write_text("{}")
            expected = digest(receipt)
            base = {"facts": {"model_receipt": [["m", expected, "finite-state-TLC"]]}}
            observation = {"id": "observed", "evidence": [
                {"path": "evidence/m.json", "sha256": expected}]}
            specs, current = bindings(root, base, [observation], "snapshot")
            self.assertEqual(specs["audit:observed"]["depends"], ["m:" + expected])
            self.assertEqual(current["evidence/m.json"], expected)
            self.assertTrue(specs["m:" + expected]["rawLogEvidencePending"])
            facts = project(base, [], "snapshot", observations=[observation],
                            bindings=specs, current_inputs=current, task_model="m")
            from gambit_smp.ascent_program import engine_api
            rows = current_review(facts)
            self.assertIn(["m:" + expected, "stale-or-missing-input"], rows["Unusable"])
            self.assertIn(["audit:observed", "invalid-dependency"], rows["Unusable"])
            self.assertIn(["task:m", "finite-model:m"], rows["Missing"])

    def test_modern_receipt_binds_its_rechecked_log_and_trace(self):
        from gambit_smp.framework import digest
        from gambit_smp.review_inputs import VERIFIER_MODULES, _record, _checks
        with TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            for name in VERIFIER_MODULES:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("verifier\n")
            model = root / "models/gambit/m.qnt"
            model.parent.mkdir(parents=True)
            model.write_text("model\n")
            source = root / "source.c"
            source.write_text("source\n")
            out = root / "evidence/model-results/m"
            out.mkdir(parents=True)
            log, trace = out / "m.log", out / "m.trace.json"
            log.write_text("verified log\n")
            trace.write_text("{}")
            receipt = out / "receipt.json"
            receipt.write_text(json.dumps({"inputs": {"source.c": digest(source)}, "results": [{
                "case": "m", "log": log.name, "logSha256": digest(log),
                "trace": trace.name, "traceSha256": digest(trace)}]}))
            path = str(receipt.relative_to(root))
            bound, _, _ = _record(root, path, digest(receipt), "m", rechecked=True)
            self.assertEqual(digest(log), bound[str(log.relative_to(root))])
            self.assertEqual(digest(trace), bound[str(trace.relative_to(root))])
            bound["local/m.log"] = "historical-input"
            checks = _checks(root, path, "m", bound)
            self.assertEqual(str(log.relative_to(root)), checks[0]["artifacts"]["log"])
            trace.write_text("changed trace\n")
            with self.assertRaisesRegex(ValueError, "artifact identity mismatch"):
                _record(root, path, digest(receipt), "m", rechecked=True)

    def test_archived_raw_log_is_rechecked_and_bound(self):
        from gambit_smp.framework import digest
        from gambit_smp.review_inputs import VERIFIER_MODULES, bindings

        with TemporaryDirectory() as directory:
            root = Path(directory)
            model = root / "models/gambit"
            model.mkdir(parents=True)
            (model / "m.qnt").write_text("module m {}\n")
            (model / "cases.json").write_text(json.dumps({"quintVersion": "0.33.0",
                "cases": [{"id": "m", "modelReceipt": "evidence/m.json"}]}))
            for name in VERIFIER_MODULES:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("current verifier\n")
            evidence = root / "evidence"
            evidence.mkdir()
            (evidence / "research-audit.json").write_text("{}")
            (evidence / "m.qnt").write_bytes((model / "m.qnt").read_bytes())
            log = evidence / "m-fixed.log"
            log.write_text("Model checking completed. No error has been found.\n"
                           "1 states generated, 1 distinct states found, 0 states left on queue.\n")
            receipt = evidence / "m.json"
            receipt.write_text(json.dumps({"quintVersion": "0.33.0", "results": [{
                "case": "m", "variant": "fixed", "log": "m-fixed.log",
                "modelSha256": digest(model / "m.qnt"),
                "exit": 0, "timeout": False}]}))
            manifest = evidence / "model-raw-log-attestations.json"
            manifest.write_text(json.dumps({"schema": "gambit-model-raw-log-attestations.v1",
                "receipts": [{"model": "m", "receipt": "evidence/m.json",
                              "receiptSha256": digest(receipt),
                              "modelSnapshot": {"path": "evidence/m.qnt",
                                                "sha256": digest(evidence / "m.qnt")},
                              "logs": [{
                                  "name": "m-fixed.log", "path": "evidence/m-fixed.log",
                                  "sha256": digest(log)}]}]}))
            base = {"facts": {"model_receipt": [["m", digest(receipt), "finite-state-TLC"]]}}
            specs, _ = bindings(root, base, [], "snapshot")
            self.assertFalse(specs["m:" + digest(receipt)]["rawLogEvidencePending"])
            self.assertEqual(specs["m:" + digest(receipt)]["binding"], "raw-log-revalidated")
            (evidence / "m.qnt").write_text("different model\n")
            with self.assertRaisesRegex(ValueError, "model snapshot identity mismatch"):
                bindings(root, base, [], "snapshot")
            (evidence / "m.qnt").write_bytes((model / "m.qnt").read_bytes())
            log.write_text("missing completion evidence\n")
            with self.assertRaisesRegex(ValueError, "raw log identity mismatch"):
                bindings(root, base, [], "snapshot")


if __name__ == "__main__":
    unittest.main()
