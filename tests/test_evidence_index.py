import json
import copy
import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.ascent_program import load_catalog
from gambit_smp import evidence_index as index
from tests.support import protocol_fixture


class EvidenceTests(unittest.TestCase):
    def test_portable_validation_does_not_refresh_or_accept_a_stale_saved_index(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "evidence").mkdir()
            saved = root / "evidence/relations.json"
            saved.write_text("stale\n")
            (root / "evidence/dsl").mkdir()
            (root / "evidence/dsl/components.json").write_bytes(
                (Path(__file__).parent / "fixtures/catalog-components.json").read_bytes())
            (root / "evidence/dsl/catalog.ss").write_text(
                "(def (make-catalog) (make-recorded-module "
                "(ascent-fragment (relation input ((value symbol?)))) '(input) 4096 32768 32768))\n")
            with patch.object(index, "ROOT", root), patch.object(index, "export", return_value={"facts": {}, "inputs": {}}), \
                    patch.object(index, "query", return_value={"pending": ["source"]}), \
                    patch("gambit_smp.reasoning_history.record", return_value={}), \
                    contextlib.redirect_stdout(io.StringIO()):
                with patch("sys.argv", ["evidence", "--validate"]):
                    index.main()
                self.assertEqual("stale\n", saved.read_text())
                with patch("sys.argv", ["evidence", "--check"]):
                    with self.assertRaisesRegex(ValueError, "stale fact export"):
                        index.main()

    def test_setup_protocol_keeps_temporal_and_context_receipt_fail_closed(self):
        from gambit_smp.protocol_evidence import bundle_facts
        manifest = "evidence/pstate-setup-protocol.json"
        receipt = "evidence/model-results/pstate-setup-helper-owned/receipt.json"
        with protocol_fixture(index.ROOT, manifest, receipt) as (root, context, _):
            facts, inputs = bundle_facts(root, manifest, receipt)
            self.assertEqual(["pstate_setup_transaction"],
                             [row[0] for row in facts["protocol_checked"]])
            self.assertEqual(7, len(facts["protocol_control"]))
            self.assertTrue(set(context["contextInputs"]).issubset(inputs))
            for name in context["contextInputs"]:
                (root / name).unlink()
            rejected, _ = bundle_facts(root, manifest, receipt)
            self.assertEqual([], rejected["protocol_checked"])
            self.assertEqual(facts["protocol_model"], rejected["protocol_model"])

    def test_progress_and_extension_queries_do_not_upgrade_safety_or_native_evidence(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts["model_progress_obligation"] = [["resource", "source", "conditional completion"]]
        facts["protocol_model"] = [["composition", "source"]]
        facts["model_receipt"] = [["resource", "safety-receipt", "finite-state-TLC"]]
        facts["native_adapter"] = [["resource", "fixture.scm"]]
        result = index.query(facts, load_catalog(index.ROOT / "evidence/catalog.ss"))
        self.assertEqual([("resource",)], result["progress_obligations_without_checks"])
        self.assertEqual([("composition",)], result["protocol_extensions_without_checks"])
        facts["model_progress_checked"] = [["resource", "progress-receipt"]]
        facts["protocol_checked"] = [["composition", "composition-receipt"]]
        result = index.query(facts, load_catalog(index.ROOT / "evidence/catalog.ss"))
        self.assertEqual([], result["progress_obligations_without_checks"])
        self.assertEqual([], result["protocol_extensions_without_checks"])
        self.assertNotIn("runtime_admitted", result)

    def test_paper_contract_queries_keep_assumptions_separate_from_native_admission(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts.update(model=[["entry", "a", "composition"], ["closure", "b", "composition"],
                            ["queue", "c", "protocol"]],
                     paper=[["ghc", "https://example.org/paper.pdf"]],
                     model_paper=[["entry", "ghc", "3.5"]],
                     model_contract=[["entry", "closure", "work-complete"],
                                     ["closure", "queue", "acquire-visible"]])
        rules = load_catalog(index.ROOT / "evidence/catalog.ss")
        result = index.query(facts, rules)
        self.assertEqual([("closure", "queue"), ("entry", "closure"), ("entry", "queue")],
                         result["model_contract_dependencies"])
        self.assertEqual([("entry",)], result["paper_guided_models_without_native_adapters"])
        facts["native_adapter"] = [["queue", "queue.scm"]]
        facts["model_receipt"] = [["closure", "receipt", "finite-state-TLC"]]
        facts["source_unit_observation"] = [["closure", "mock", "receipt", "log"]]
        result = index.query(facts, rules)
        self.assertEqual([("entry", "closure")],
                         result["contract_dependencies_without_native_adapters"])
        self.assertEqual([("closure", "queue"), ("entry", "queue")],
                         result["contract_dependencies_without_model_receipts"])

    def test_control_requires_unchanged_artifacts_source_budget_and_native_pass(self):
        directory = index.ROOT / "evidence/model-results"
        denied = json.loads((directory / "native-prim-port-019-deny.json").read_text())
        control = json.loads((directory / "native-prim-port-019-unsandboxed-pass.json").read_text())
        output = (directory / "native-prim-port-019-unsandboxed-pass.log").read_text()
        file = "13-modules/prim_port.scm"
        self.assertTrue(index.admitted_control(denied, control, file, "gsi", output))
        for field, value in (("gsiSha256", "other"), ("wholeSuiteBudgetPerMode", 200),
                             ("selectedFiles", ["different.scm"]), ("sourceFiles", {})):
            changed = copy.deepcopy(control)
            changed[field] = value
            self.assertFalse(index.admitted_control(denied, changed, file, "gsi", output))
        changed = copy.deepcopy(control)
        changed["buildDriver"] = {"sha256": "different-driver"}
        self.assertFalse(index.admitted_control(denied, changed, file, "gsi", output))
        changed = copy.deepcopy(control)
        changed["adapterSources"] = {"gambit_smp.native_suite.py": "different-runner"}
        self.assertFalse(index.admitted_control(denied, changed, file, "gsi", output))
        changed = copy.deepcopy(control)
        changed["results"][0]["timeout"] = True
        self.assertFalse(index.admitted_control(denied, changed, file, "gsi", output))
        self.assertFalse(index.admitted_control(denied, control, file, "gsi", "no completion marker"))
    def test_export_is_complete_portable_and_digest_bound(self):
        exported = index.export()
        self.assertEqual(33, len(exported["facts"]["pr"]))
        cases = json.loads((index.ROOT / "models/gambit/cases.json").read_text())["cases"]
        self.assertEqual({case["id"] for case in cases},
                         {row[0] for row in exported["facts"]["model"]})
        self.assertIn("gc_work_closure", {row[0] for row in exported["facts"]["model"]})
        from gambit_smp.check_gambit import reuse_model_receipt
        from gambit_smp.review_inputs import _raw_log_attestations, _checked_raw_logs
        expected_models = {case["id"]: case for case in cases if "modelReceipt" in case}
        actual_models = exported["facts"]["model_receipt"]
        self.assertEqual(len(expected_models), len(actual_models))
        self.assertEqual(set(expected_models), {row[0] for row in actual_models})
        attestations = _raw_log_attestations(index.ROOT)
        self.assertTrue({key[0] for key in attestations}.issubset(expected_models))
        for name, receipt, sha in attestations:
            self.assertEqual(expected_models[name]["modelReceipt"], receipt)
            self.assertEqual(index.digest(index.ROOT / receipt), sha)
        for name, sha, evidence in actual_models:
            case = expected_models[name]
            self.assertEqual("finite-state-TLC", evidence)
            path = index.ROOT / case["modelReceipt"]
            self.assertEqual(index.digest(path), sha)
            rows = reuse_model_receipt(path, case, index.ROOT / "models/gambit")
            self.assertTrue(rows)
            self.assertTrue(all(row["sourceStable"] is True for row in rows))
            entry = attestations.get((name, case["modelReceipt"], sha))
            if entry is not None:
                bound = _checked_raw_logs(index.ROOT, name, case["modelReceipt"], sha, entry)
                self.assertTrue(all(index.digest(index.ROOT / source) == expected for source, expected in bound.items()))
        self.assertEqual(33, len(exported["facts"]["report_snapshot"]))
        self.assertEqual(127, len(exported["facts"]["window_disposition"]))
        self.assertEqual(21, len(exported["facts"]["reported_failure"]))
        self.assertEqual(5, len(exported["facts"]["source_unit_fixture"]))
        self.assertEqual(30, len(exported["facts"]["native_observation"]))
        inventory = json.loads((index.ROOT / "evidence/native-failures.json").read_text())["failures"]
        observed = json.loads((index.ROOT / "evidence/native-observation-bindings.json").read_text())["bindings"]
        expected_failures = {row["id"]: row for row in inventory if row["id"] not in observed}
        actual_failures = exported["facts"]["local_native_failure"]
        self.assertEqual(len(expected_failures), len(actual_failures))
        self.assertEqual(set(expected_failures), {row[0] for row in actual_failures})
        self.assertEqual({row["id"] for row in inventory},
                         {row[0] for row in actual_failures} |
                         {row[0] for row in exported["facts"]["observed_failure"]})
        for name, category, status, sha in actual_failures:
            expected = expected_failures[name]
            self.assertEqual((expected["category"], expected["status"], index.digest(index.ROOT / expected["receipt"])),
                             (category, status, sha))
        self.assertEqual(1, len(exported["facts"]["local_control_pass"]))
        self.assertNotIn("/Users/", json.dumps(exported))
        self.assertNotIn("release_admitted", exported["facts"])
        self.assertGreater(len(exported["facts"]["frozen_negative"]), 20)

    def test_catalog_merge_status_matches_snapshot(self):
        catalog = json.loads((index.ROOT / "models/gambit/report_catalog.json").read_text())
        reports = {r["number"]: r for r in catalog["reports"]}
        self.assertTrue(reports[788]["upstreamMerged"])
        self.assertEqual("merged-historical-source-reference-model-open", reports[788]["status"])
        self.assertFalse(reports[793]["upstreamMerged"])
        self.assertEqual("unmerged-source-lifecycle-obligation-native-open", reports[793]["status"])
        for report in reports.values():
            saved = json.loads((index.ROOT / report["snapshot"]).read_text())
            self.assertEqual(saved["merged"], report["upstreamMerged"])
            self.assertEqual(saved["state"], report["upstreamState"])

    def test_queries_expose_missing_evidence_and_recursive_dependencies(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts.update(pr=[[1, "head", "unknown"], [2, "head", "reported"]],
                     pr_model=[[2, "m"]], model=[["m", "hash", "repair"]],
                     report_kind=[[1, "runtime-repair"], [2, "runtime-repair"]],
                     dependency=[[1, 2], [2, 3]])
        rules = load_catalog(index.ROOT / "evidence/catalog.ss")
        result = index.query(facts, rules)
        self.assertEqual([(1,)], result["reports_without_models"])
        self.assertEqual([(1,), (2,)], result["reports_without_snapshots"])
        self.assertEqual([("m",)], result["models_without_native_adapters"])
        facts["source_unit_fixture"] = [["m", "mock.c", "hash"]]
        self.assertEqual([("m",)], index.query(facts, rules)["models_without_native_adapters"])
        self.assertEqual([(1, 2), (1, 3), (2, 3)], result["dependency_closure"])
        facts["native_adapter"] = [["m", "fixture.scm"]]
        self.assertEqual([], index.query(facts, rules)["models_without_native_adapters"])

    def test_context_is_not_model_coverage_and_test_pr_is_not_runtime_repair(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts.update(pr=[[1, "head", "unknown"], [2, "head", "tests"]],
                     report_kind=[[1, "runtime-repair"], [2, "supporting-tests"]],
                     model_context_pr=[["context-only", 1]])
        result = index.query(facts, load_catalog(index.ROOT / "evidence/catalog.ss"))
        self.assertEqual([(1,)], result["reports_without_models"])

    def test_cyclic_dependency_is_rejected_before_engine_execution(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts["dependency"] = [[1, 2], [2, 1]]
        with self.assertRaisesRegex(ValueError, "cyclic PR dependency"):
            index.query(facts, "")

    def test_environment_and_budget_are_not_gc_model_failures(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts["local_native_failure"] = [["a", "assertion", "open", "hash"],
            ["e", "environment", "open", "hash"], ["b", "budget", "open", "hash"]]
        rules = load_catalog(index.ROOT / "evidence/catalog.ss")
        result = index.query(facts, rules)
        self.assertEqual([("a",)], result["local_assertions_without_models"])
        self.assertEqual([("e",)], result["local_environment_failures"])
        self.assertEqual([("b",)], result["local_budget_denials"])
        self.assertEqual([("b",)], result["local_budget_without_passing_controls"])
        facts["local_control_pass"] = [["b", "outside-sandbox", "gsi", "hash"]]
        controlled = index.query(facts, rules)
        self.assertEqual([], controlled["local_budget_without_passing_controls"])
        self.assertEqual([("b",)], controlled["local_budget_denials"])
        facts["local_failure_model"] = [["a", "audited-model"]]
        self.assertEqual([], index.query(facts, rules)["local_assertions_without_models"])

    def test_unknown_report_model_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "models/gambit"
            directory.mkdir(parents=True)
            (directory / "cases.json").write_text(json.dumps({"cases": []}))
            (directory / "report_catalog.json").write_text(json.dumps({"reports": [
                {"number": 1, "headRefOid": "head", "status": "unknown", "models": ["missing"]}]}))
            with self.assertRaisesRegex(ValueError, "unknown report model"):
                index.export(root)

    def test_unknown_cyclic_duplicate_contracts_and_unknown_papers_fail_closed(self):
        mutations = [
            ([{"model": "missing", "obligation": "x"}], [], "unknown model contract"),
            ([{"model": "a", "obligation": "x"}], [], "cyclic model contracts"),
            ([{"model": "a", "obligation": "x"}, {"model": "a", "obligation": "y"}], [],
             "duplicate or unknown model contract"),
            ([], [{"paper": "missing", "sections": ["3.5"]}], "unknown paper"),
        ]
        for contracts, references, message in mutations:
            with self.subTest(message=message), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                directory = root / "models/gambit"
                directory.mkdir(parents=True)
                case = {"id": "a", "pr": 1, "source": [], "native": None,
                        "contracts": contracts, "paperSections": references}
                (directory / "cases.json").write_text(json.dumps(
                    {"sourceRevision": "revision", "cases": [case], "unresolved": []}))
                (directory / "report_catalog.json").write_text(json.dumps({"reports": []}))
                (directory / "a.qnt").write_text("module a {}\n")
                with self.assertRaisesRegex(ValueError, message):
                    index.export(root)

    def test_model_receipt_requires_current_model_exact_checks_and_stable_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "models/gambit"
            directory.mkdir(parents=True)
            evidence = root / "evidence"
            evidence.mkdir()
            case = {"id": "a", "pr": 1, "source": [], "native": None,
                    "mode": "characterization", "invariants": ["safe"],
                    "modelReceipt": "evidence/proof.json"}
            (directory / "cases.json").write_text(json.dumps(
                {"sourceRevision": "revision", "cases": [case], "unresolved": []}))
            (directory / "report_catalog.json").write_text(json.dumps({"reports": []}))
            model = directory / "a.qnt"
            model.write_text("module a {}\n")
            row = {"case": "a", "variant": "protocol", "invariant": "safe",
                   "initializer": "init", "accepted": True, "sourceStable": True,
                   "evidence": "finite-state-TLC", "modelSha256": index.digest(model)}
            path = evidence / "proof.json"
            path.write_text(json.dumps({"results": [row]}))
            self.assertEqual([("a", index.digest(path), "finite-state-TLC")],
                             index.export(root)["facts"]["model_receipt"])
            for field, wrong in (("modelSha256", "old"), ("initializer", "different"),
                                 ("accepted", False), ("sourceStable", False),
                                 ("evidence", "mocked")):
                with self.subTest(field=field):
                    path.write_text(json.dumps({"results": [{**row, field: wrong}]}))
                    with self.assertRaises(ValueError):
                        index.export(root)


if __name__ == "__main__":
    unittest.main()
