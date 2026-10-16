import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.framework import ROOT, digest
from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify
from gambit_smp import quint_backend as backend
from tests.support import protocol_fixture


class ProtocolEvidenceTests(unittest.TestCase):
    def test_budget_ledger_parent_is_registered_without_admission(self):
        manifest_name = "evidence/research/continuation-retained-seed-bootstrap/budget-ledger-contract.json"
        receipt_name = "evidence/model-results/research/checkpoint-budget-ledger/receipt.json"
        manifest = json.loads((ROOT / manifest_name).read_text())
        parent = manifest["cases"][0]
        self.assertTrue(parent["registrationOnly"])
        self.assertNotIn("temporal", parent)
        self.assertEqual(parent["id"], "checkpoint_budget_ledger")
        rows, bound = evidence.bundle_facts(ROOT, manifest_name, receipt_name)
        self.assertEqual(rows["protocol_checked"], [])
        self.assertEqual(rows["protocol_composes"], [])
        self.assertEqual(bound["models/gambit/checkpoint_budget_ledger.qnt"],
                         digest(ROOT / "models/gambit/checkpoint_budget_ledger.qnt"))
        child = json.loads((ROOT / "evidence/research/continuation-retained-seed-bootstrap/charged-consumption-contract.json").read_text())
        self.assertEqual(child["cases"][0]["composes"], [parent["id"]])
        self.assertIn((manifest_name, receipt_name), evidence.load_bundles(ROOT))

    def test_log_processor_composition_has_real_control_and_complete_check(self):
        manifest = json.loads((ROOT / "evidence/fixtures/pstate-log-owned-rollback/processor-log-contract.json").read_text())
        receipt = ROOT / "evidence/model-results/fixtures/pstate-log-owned-rollback/processor-log-contract/receipt.json"
        rows = evidence.checked_rows(ROOT, manifest, receipt)[0][1]
        old = next(row for row in rows if row["variant"] == "old")
        positive = next(row for row in rows if row["variant"] == "protocol")
        self.assertEqual(1, old["exit"])
        self.assertEqual(0, positive["exit"])
        self.assertEqual(428, positive["states"]["distinct"])
        self.assertEqual(0, positive["states"]["queued"])
        self.assertEqual(3, len(rows))

    def test_vm_constructor_composition_has_complete_state_and_source_closure(self):
        manifest_name = "evidence/vm-constructor-rollback-composition.json"
        receipt_name = "evidence/model-results/fixtures/pstate-log-owned-rollback/vm-constructor-contract/receipt.json"
        manifest = json.loads((ROOT / manifest_name).read_text())
        rows = evidence.checked_rows(ROOT, manifest, ROOT / receipt_name)[0][1]
        self.assertEqual(4, len(rows))
        positive = next(row for row in rows if row["variant"] == "protocol")
        self.assertEqual("initConstructor", positive["initializer"])
        self.assertEqual("constructorStep", positive["step"])
        self.assertEqual("constructorSafe", positive["invariant"])
        self.assertEqual(282122, positive["states"]["distinct"])
        self.assertEqual(0, positive["states"]["queued"])
        text = (ROOT / Path(receipt_name).parent / positive["log"]).read_text()
        self.assertIn("15360 distinct states generated", text)
        saved = json.loads((ROOT / receipt_name).read_text())
        self.assertEqual(5, len(saved["modelSources"]))
        _, bound = evidence.bundle_facts(ROOT, manifest_name, receipt_name)
        for name, sha in saved["modelSources"].items():
            self.assertEqual(sha, bound[(Path(receipt_name).parent / name).as_posix()])

    def test_model_source_inventory_rejects_drift_and_basename_collisions(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            model = source / "member.qnt"
            model.write_text("module member {}\n")
            sha = digest(model)
            self.assertEqual({"source/member.qnt": model.resolve()},
                evidence.model_snapshot_files(source, {"models/gambit/member.qnt": sha}))
            with self.assertRaisesRegex(ValueError, "collision"):
                evidence.model_snapshot_files(source, {"models/gambit/member.qnt": sha,
                    "models/gambit/other/member.qnt": sha})
            model.write_text("module changed {}\n")
            with self.assertRaisesRegex(ValueError, "differs"):
                evidence.model_snapshot_files(source, {"models/gambit/member.qnt": sha})

    def test_portable_proof_rejects_changed_dependency_snapshot(self):
        import shutil
        name = "evidence/model-results/fixtures/pstate-log-owned-rollback/vm-constructor-contract/receipt.json"
        manifest = json.loads((ROOT / "evidence/vm-constructor-rollback-composition.json").read_text())
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "proof"
            shutil.copytree((ROOT / name).parent, target)
            (target / "source/pstate_setup_transaction.qnt").write_text("changed\n")
            with self.assertRaisesRegex(ValueError, "inventory"):
                evidence.checked_rows(ROOT, manifest, target / "receipt.json")

    def test_delayed_log_cleanup_violates_return_even_before_final_leak(self):
        directory = ROOT / "evidence/model-results/pstate-log-return-handoff-source032"
        trace = json.loads((directory /
            "pstate_log_rollback_composition-old-returnOwnershipSafe.trace.json").read_text())
        state = trace["states"][-1]
        self.assertEqual(2, state["phase"])
        self.assertEqual(7, state["P_s"]["phase"])
        self.assertFalse(state["innerCleanup"])
        self.assertFalse(state["vmOnly"])
        self.assertTrue({2, 3}.issubset(state["L_logState"]["owned"]["$integerSet"]))

    def test_previous_log_composition_receipt_does_not_prove_stronger_model(self):
        manifest = json.loads((ROOT / "evidence/pstate-log-rollback-composition.json").read_text())
        receipt = ROOT / "evidence/model-results/pstate-log-rollback-composition/receipt.json"
        with self.assertRaises(ValueError):
            evidence.checked_rows(ROOT, manifest, receipt)

    def test_declarative_bundle_registry_rejects_duplicates_and_cache_paths(self):
        for rows in ([["a", "b"], ["a", "c"]], [[".data/a", "b"]],
                     [["../a", "b"]], [["a"]]):
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                path = root / evidence.BUNDLE_REGISTRY
                path.parent.mkdir()
                path.write_text(json.dumps({"schema": "gambit-protocol-bundles.v1", "bundles": rows}))
                with self.subTest(rows=rows), self.assertRaises(ValueError):
                    evidence.load_bundles(root)

    def test_pstate_composition_binds_import_and_selected_transition(self):
        manifest = json.loads((ROOT / "evidence/pstate-failure-composition.json").read_text())
        path = ROOT / "evidence/model-results/pstate-failure-composition/receipt.json"
        rows = evidence.checked_rows(ROOT, manifest, path)
        self.assertEqual(4, len(rows[0][1]))
        positive = next(row for row in rows[0][1] if row["variant"] == "protocol")
        self.assertEqual("composedStep", positive["step"])
        self.assertEqual(0, positive["states"]["queued"])
        self.assertEqual(125, positive["states"]["distinct"])
        self.assertIn("models/gambit/pstate_setup_transaction.qnt", manifest["contextInputs"])
        with tempfile.TemporaryDirectory() as directory:
            changed = Path(directory) / "receipt.json"
            saved = json.loads(path.read_text())
            for row in saved["results"]:
                row["step"] = "step"
            changed.write_text(json.dumps(saved))
            from gambit_smp.check_gambit import reuse_model_receipt
            with self.assertRaisesRegex(ValueError, "another model"):
                reuse_model_receipt(changed, manifest["cases"][0])

    def test_protocol_manifest_rejects_escaping_import_and_invalid_step(self):
        data = json.loads((ROOT / "evidence/pstate-failure-composition.json").read_text())
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.json"
            for delta in ({"dependencies": ["../outside.qnt"]}, {"step": "composedStep;ignore"}):
                changed = copy.deepcopy(data)
                changed["cases"][0].update(delta)
                path.write_text(json.dumps(changed))
                with self.assertRaisesRegex(ValueError, "protocol"):
                    verify.load_manifest(path)

    def test_matrix_archive_retains_public_ir_and_rejects_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            source = root / "raw"
            source.mkdir()
            irs = []
            for name in ("proof-ir.json", "protocol-ir.json"):
                path = source / name
                path.write_text(json.dumps({"stage": "parsing", "errors": [], "modules": []}))
                irs.append(path)
            saved = {"schema": "gambit-induction-matrix-result.v1", "accepted": False,
                "native": {"status": "not-run"}, "results": [],
                "protocolIrSha256": digest(irs[1]), "generatorContract": {"proofIrSha256": digest(irs[0])}}
            (source / "receipt.json").write_text(json.dumps(saved))
            with patch.object(evidence, "ROOT", root):
                evidence.archive_attempt(source, root / "archive")
                for artifact in irs:
                    self.assertEqual(artifact.read_bytes(), (root / "archive" / artifact.name).read_bytes())
                irs[0].write_text("changed")
                with self.assertRaisesRegex(ValueError, "public IR differs"):
                    evidence.archive_attempt(source, root / "bad")
                self.assertFalse((root / "bad").exists())

    def test_legacy_symbolic_archive_preserves_receipt_and_checks_log(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            source = root / "raw"
            source.mkdir()
            model = source / "gc_recursive_queue_induction.qnt"
            model.write_text("module gc_recursive_queue_induction {}\n")
            log = source / "closure.log"
            log.write_text("diagnostic\n")
            saved = {"schema": "gc-induction-obligation.v1", "accepted": False,
                "scope": "safety-candidate-one-step-closure-only-not-complete-proof",
                "runtimeAdmitted": False, "releaseAdmitted": False, "temporalProved": False,
                "modelInputs": {model.name: digest(model)}, "log": log.name,
                "logSha256": digest(log)}
            receipt = source / "receipt.json"
            receipt.write_text(json.dumps(saved))
            with patch.object(evidence, "ROOT", root):
                evidence.archive_attempt(source, root / "archive")
                self.assertEqual(receipt.read_bytes(), (root / "archive/receipt.json").read_bytes())
                log.write_text("changed\n")
                with self.assertRaisesRegex(ValueError, "log differs"):
                    evidence.archive_attempt(source, root / "bad")
                self.assertFalse((root / "bad").exists())

    def test_diagnostic_archive_retains_imported_model_and_rejects_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            source = root / "raw"
            source.mkdir()
            parent, child = source / "parent.qnt", source / "child.qnt"
            parent.write_text('module parent { import child.* from "./child" }\n')
            child.write_text("module child {}\n")
            (source / "check.log").write_text("diagnostic only\n")
            saved = {"accepted": False, "native": {"status": "not-run"},
                "modelInputs": {child.name: digest(child)}, "results": [
                    {"case": "parent", "variant": "diagnostic", "modelSha256": digest(parent),
                     "log": "check.log"}]}
            (source / "receipt.json").write_text(json.dumps(saved))
            with patch.object(evidence, "ROOT", root):
                evidence.archive_attempt(source, root / "archive")
                self.assertEqual(child.read_bytes(), (root / "archive/child.qnt").read_bytes())
                self.assertFalse(json.loads((root / "archive/archive.json").read_text())["accepted"])
                child.write_text("changed\n")
                with self.assertRaisesRegex(ValueError, "additional model snapshot differs"):
                    evidence.archive_attempt(source, root / "bad-archive")
                self.assertFalse((root / "bad-archive").exists())

    def test_compiled_checker_artifacts_retain_hashes_and_temporal_configuration(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tla, cfg = root / "model.tla", root / "model.cfg"
            tla.write_text("---- MODULE model ----\n====\n")
            expected = "INIT q_init\nNEXT q_step\nINVARIANT q_inv\nPROPERTY q_temporalProps\n"
            cfg.write_text(expected)
            row = {"modelSha256": "identity", "temporal": "progress", "checker": {
                "backend": "quint-compile-tlc", "livenessSchedule": "final",
                "inputsStable": True, "phase": "tlc", "modelSha256": "identity",
                "artifacts": {tla.name: digest(tla), cfg.name: digest(cfg)}}}
            self.assertEqual(2, len(evidence.checked_artifacts(root, row)))
            cfg.write_text(expected.replace("PROPERTY q_temporalProps\n", ""))
            with self.assertRaisesRegex(ValueError, "digest mismatch"):
                evidence.checked_artifacts(root, row)
            row["checker"]["artifacts"][cfg.name] = digest(cfg)
            with self.assertRaisesRegex(ValueError, "omitted or changed properties"):
                evidence.checked_artifacts(root, row)
            cfg.write_text(expected)
            row["checker"]["artifacts"][cfg.name] = digest(cfg)
            tla.unlink()
            with self.assertRaises(OSError):
                evidence.checked_artifacts(root, row)

    def test_shared_backend_keeps_admission_classes_and_cli_options(self):
        success = ("Finished checking temporal properties\n"
                   "Model checking completed. No error has been found.\n"
                   "2 states generated, 2 distinct states found, 0 states left on queue.\n")
        with patch.object(backend, "isolated_endpoint", return_value="127.0.0.1:1234"), \
                patch.object(backend, "execute", return_value=(0, success, False, 0.25)) as run:
            row, _, trace = backend.check(Path("model.qnt"), initializer="init",
                invariant="safe", negative=False, timeout=7, cwd=ROOT,
                step="step", temporal="progress", config=Path("config.json"))
            self.assertTrue(row["accepted"])
            self.assertIsNone(trace)
            command = run.call_args.args[0]
            for option, setting in (("--step", "step"), ("--temporal", "progress"),
                                    ("--tlc-config", "config.json")):
                self.assertEqual(setting, command[command.index(option) + 1])
            self.assertEqual(7, run.call_args.args[2])
        for code, output, timeout, negative, temporal in (
                (0, success, True, False, "progress"),
                (1, "TLC internal exception", False, True, None),
                (1, "Error: Invariant q_inv is violated.", False, True, None),
                (0, success.replace("Finished checking temporal properties", ""), False, False, "progress")):
            with self.subTest(code=code, output=output, timeout=timeout):
                self.assertFalse(backend.interpret(code, output, timeout,
                    negative=negative, temporal=temporal)[0])

    def test_manifest_covers_three_distinct_gaps_and_twelve_controls(self):
        manifest = verify.load_manifest(ROOT / evidence.MANIFEST)
        self.assertEqual(3, len(manifest["cases"]))
        self.assertEqual(12, sum(len(case["oldInvariants"]) for case in manifest["cases"]))
        for case in manifest["cases"]:
            self.assertEqual("progress", case["temporal"])
            self.assertEqual(set(case["oldInvariants"]), set(case["oldInitializers"]))
            self.assertTrue(case["source"])
            self.assertEqual(2, len(case["composes"]))

    def test_invalid_or_duplicate_case_rejected(self):
        original = verify.load_manifest(ROOT / evidence.MANIFEST)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "manifest.json"
            for bad in ("../outside", "has space"):
                changed = copy.deepcopy(original)
                changed["cases"][0]["id"] = bad
                path.write_text(json.dumps(changed))
                with self.assertRaisesRegex(ValueError, "invalid case"):
                    verify.load_manifest(path)
            changed = copy.deepcopy(original)
            changed["cases"].append(changed["cases"][0])
            path.write_text(json.dumps(changed))
            with self.assertRaisesRegex(ValueError, "unique"):
                verify.load_manifest(path)

    def test_exhaustion_summary_not_confused_with_partial_progress(self):
        self.assertEqual({"generated": 1234, "distinct": 245, "queued": 0},
                         verify.summarize("1,234 states generated, 245 distinct states found, 0 states left on queue."))
        self.assertEqual({}, verify.summarize("timeout"))
        progress = ("Progress(29): 9,431,403 states generated (9,073,808 s/min), "
                    "2,271,137 distinct states found (2,168,572 ds/min), 469,341 states left on queue.")
        self.assertEqual({"generated": 9431403, "distinct": 2271137, "queued": 469341},
                         verify.summarize(progress))
        self.assertFalse(backend.admitted_model(0, progress, False, False))
        self.assertEqual(0, verify.summarize(
            "10 states generated, 8 distinct states found, 2 states left on queue.\n"
            "20 states generated, 12 distinct states found, 0 states left on queue.")["queued"])

    def test_accepted_same_model_receipt_reused_but_changed_identity_denied(self):
        manifest = verify.load_manifest(ROOT / evidence.MANIFEST)
        case = manifest["cases"][0]
        sha = digest(ROOT / "models/gambit" / (case["id"] + ".qnt"))
        directory = (ROOT / evidence.RECEIPT).parent
        result = verify.reusable_check(directory, manifest, case, "fixed", "safe", "initFixed", sha)
        self.assertTrue(result[0]["accepted"])
        self.assertIsNone(result[2])
        for init, identity in (("initOther", sha), ("initFixed", "wrong")):
            with self.assertRaisesRegex(ValueError, "differs"):
                verify.reusable_check(directory, manifest, case, "fixed", "safe", init, identity)

    def test_configuration_manifest_retains_all_flag_dimensions(self):
        manifest = verify.load_manifest(ROOT / "evidence/configuration-model.json")
        self.assertEqual(1, len(manifest["cases"]))
        case = manifest["cases"][0]
        self.assertEqual(3, len(case["oldInvariants"]))
        for flag in ("ENABLE_MULTIPLE_VMS", "ENABLE_MULTIPLE_THREADED_VMS", "ENABLE_SMP"):
            self.assertIn("configure.ac:" + flag, case["source"])

    def test_reparse_only_recovers_valid_same_model_negative_controls(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            log = directory / "negative.log"
            log.write_text('Error: Invariant q_inv is violated.\n'
                'State 1: <Init>\ns = [stage |-> "published"]\n\n'
                'State 2: <Destroy>\ns = [stage |-> "destroyed"]\n\n')
            row = {"case": "small", "variant": "old", "invariant": "safe",
                   "accepted": False, "modelSha256": "same", "initializer": "initOld",
                   "sourceStable": True, "exit": 1, "timeout": False, "log": log.name}
            saved = {"quintVersion": "test", "contextStable": True, "results": [row]}
            path = directory / "receipt.json"
            manifest = {"quintVersion": "test", "contextInputs": {}}
            def attempt():
                path.write_text(json.dumps(saved))
                return verify.reusable_check(directory, manifest, {"id": "small"},
                                             "old", "safe", "initOld", "same")
            recovered, _, trace = attempt()
            self.assertTrue(recovered["recoveredCounterexampleParse"])
            self.assertEqual("destroyed", trace["states"][-1]["s"]["stage"])
            self.assertFalse(json.loads(path.read_text())["results"][0]["accepted"])
            row["timeout"] = True
            self.assertIsNone(attempt())
            row["timeout"] = False
            row["sourceStable"] = False
            with self.assertRaisesRegex(ValueError, "differs"):
                attempt()
            row["sourceStable"] = True
            row["modelSha256"] = "changed"
            with self.assertRaisesRegex(ValueError, "differs"):
                attempt()
            row["modelSha256"] = "same"
            log.write_text("TLC internal exception\n")
            self.assertIsNone(attempt())

    def test_source_characterization_does_not_claim_a_repair(self):
        name = "evidence/continuation-origin-model.json"
        manifest = verify.load_manifest(ROOT / name)
        case = manifest["cases"][0]
        self.assertEqual([("protocol", "guardSound", "init")], verify.model_checks(case))
        receipt = "evidence/model-results/continuation-origin-model/receipt.json"
        with protocol_fixture(ROOT, name, receipt) as (root, context, saved):
            rows = evidence.checked_rows(root, context, saved)
            self.assertEqual("protocol", rows[0][1][0]["variant"])
        self.assertNotIn("readiness", case["invariants"])

    def test_tree_retirement_rejects_both_unsafe_destruction_sites(self):
        manifest = verify.load_manifest(ROOT / "evidence/sync-tree-retirement-model.json")
        checks = verify.model_checks(manifest["cases"][0])
        self.assertIn(("old", "signalSafe", "initOld"), checks)
        self.assertIn(("old", "safe", "initJoinOnly"), checks)
        self.assertIn(("fixed", "safe", "initFixed"), checks)

    def test_public_logs_have_no_personal_paths(self):
        text = f"{ROOT}/model.qnt {Path.home()}/cache /private/var/folders/ab/private/tmp/file"
        result = evidence.portable(text)
        self.assertNotIn(str(Path.home()), result)
        self.assertNotIn("/private/var/folders", result)
        self.assertIn("<REPO>", result)

    def test_path_escape_rejected(self):
        with self.assertRaises(ValueError):
            evidence.relative(ROOT, "../outside")
        with self.assertRaises(ValueError):
            evidence.relative(ROOT, "/absolute")

    def test_no_missing_progress_property(self):
        changed = verify.load_manifest(ROOT / evidence.MANIFEST)
        changed["cases"][0].pop("temporal")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "manifest.json"
            path.write_text(json.dumps(changed))
            with self.assertRaisesRegex(ValueError, "progress"):
                verify.load_manifest(path)

    def test_receipt_rejects_stale_models_partial_checks_and_missing_temporal_proof(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            model = root / "models/gambit/small.qnt"
            model.parent.mkdir(parents=True)
            model.write_text("module small {}")
            source = root / "source.c"
            source.write_text("reviewed source")
            manifest = {"quintVersion": "0.33.0", "contextInputs": {"source.c": digest(source)},
                        "cases": [{"id": "small", "temporal": "progress"}]}
            rows = []
            for variant in ("old", "fixed"):
                log = root / (variant + ".log")
                log.write_text("Error: Invariant q_inv is violated." if variant == "old" else
                    "Finished checking temporal properties\n"
                    "Model checking completed. No error has been found.\n"
                    "2 states generated, 2 distinct states found, 0 states left on queue.\n")
                row = {"case": "small", "variant": variant, "invariant": "safe",
                       "modelSha256": digest(model), "sourceStable": True, "accepted": True,
                       "evidence": "finite-state-TLC", "exit": 1 if variant == "old" else 0,
                       "timeout": False, "log": log.name, "logSha256": digest(log),
                       "temporal": None if variant == "old" else "progress", "states": {"queued": 0}}
                if variant == "old":
                    trace = root / "old.trace.json"
                    trace.write_text("{}")
                    row.update(trace=trace.name, traceSha256=digest(trace))
                rows.append(row)
            saved = {"accepted": True, "contextStable": True, "runtimeAdmitted": False,
                     "native": {"status": "not-run"}, "quintVersion": "0.33.0",
                     "inputs": manifest["contextInputs"], "results": rows}
            path = root / "receipt.json"
            path.write_text(json.dumps(saved))
            self.assertEqual(1, len(evidence.checked_rows(root, manifest, path)))
            variants = []
            changed = copy.deepcopy(saved)
            changed["results"].pop()
            variants.append(changed)
            changed = copy.deepcopy(saved)
            changed["results"][1]["temporal"] = None
            variants.append(changed)
            changed = copy.deepcopy(saved)
            changed["results"][1]["sourceStable"] = False
            variants.append(changed)
            for invalid in variants:
                path.write_text(json.dumps(invalid))
                with self.assertRaises(ValueError):
                    evidence.checked_rows(root, manifest, path)
            path.write_text(json.dumps(saved))
            model.write_text("changed model")
            with self.assertRaises(ValueError):
                evidence.checked_rows(root, manifest, path)
            model.write_text("module small {}")
            (root / "fixed.log").write_text("unbound green")
            with self.assertRaisesRegex(ValueError, "log digest"):
                evidence.checked_rows(root, manifest, path)


if __name__ == "__main__":
    unittest.main()
