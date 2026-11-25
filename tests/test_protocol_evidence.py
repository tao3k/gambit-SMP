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
    def _write_bundle(self, root, case_id, *, step="step", initializer="init",
                      old_invariants=("safe",), old_initializers=None,
                      temporal=None, distinct=428, include_model_sources=False,
                      extra_model=None, context_files=None, registration_only=False):
        from gambit_smp.output_observations import observe
        model = root / "models/gambit" / (case_id + ".qnt")
        model.parent.mkdir(parents=True, exist_ok=True)
        model.write_text(f"module {case_id} {{}}\n")
        context = {}
        for rel, body in (context_files or {}).items():
            p = root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(body)
            context[rel] = digest(p)
        if extra_model is not None:
            dep_name, dep_body = extra_model
            dep = root / "models/gambit" / dep_name
            dep.parent.mkdir(parents=True, exist_ok=True)
            dep.write_text(dep_body)
            context["models/gambit/" + dep_name] = digest(dep)
        old_inits = old_initializers if old_initializers is not None else {inv: "initOld" for inv in old_invariants}
        case = {
            "id": case_id,
            "mode": "characterization",
            "composes": [],
            "source": sorted(context),
            "papers": [],
            "invariants": ["safe"],
            "temporal": temporal,
        }
        if registration_only:
            case["registrationOnly"] = True
        else:
            if initializer != "init":
                case["protocolInitializers"] = {"safe": initializer}
            if step != "step":
                case["step"] = step
            if old_invariants:
                case["oldInvariants"] = list(old_invariants)
                case["oldInitializers"] = old_inits
        manifest = {
            "schema": "gambit-protocol-extensions.v1",
            "quintVersion": "0.33.0",
            "contextInputs": context,
            "cases": [case],
        }
        manifest_rel = f"evidence/{case_id}.json"
        manifest_path = root / manifest_rel
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(json.dumps(manifest))
        rdir = root / f"evidence/{case_id}-receipt"
        rdir.mkdir(parents=True, exist_ok=True)
        pos_prefix = "Finished checking temporal properties\n" if temporal else ""
        pos = observe((pos_prefix +
                       "Model checking completed. No error has been found.\n"
                       f"{distinct} states generated, {distinct} distinct states found, 0 states left on queue.\n").encode())
        neg = observe(b"Error: Invariant q_inv is violated.\n")
        results = []
        outputs = {}
        for inv in old_invariants:
            tname = f"old-{inv}.trace.json"
            tpath = rdir / tname
            tpath.write_text("{}\n")
            lname = f"old-{inv}.log"
            row = {"case": case_id, "variant": "old", "invariant": inv,
                   "initializer": old_inits[inv], "modelSha256": digest(model),
                   "sourceStable": True, "accepted": True, "exit": 1,
                   "timeout": False, "evidence": "finite-state-TLC", "log": lname,
                   "logSha256": neg["sha256"], "states": neg["tlc"]["states"],
                   "trace": tname, "traceSha256": digest(tpath)}
            if step != "step":
                row["step"] = step
            results.append(row)
            outputs[lname] = neg
        pos_row = {"case": case_id, "variant": "protocol", "invariant": "safe",
                   "initializer": initializer, "modelSha256": digest(model),
                   "sourceStable": True, "accepted": True, "exit": 0,
                   "timeout": False, "evidence": "finite-state-TLC", "log": "protocol.log",
                   "logSha256": pos["sha256"], "states": pos["tlc"]["states"],
                   "temporal": temporal}
        if step != "step":
            pos_row["step"] = step
        results.append(pos_row)
        outputs["protocol.log"] = pos
        saved = {
            "schema": "gambit-protocol-extension-receipt.v1",
            "accepted": True,
            "contextStable": True,
            "runtimeAdmitted": False,
            "native": {"status": "not-run"},
            "quintVersion": "0.33.0",
            "inputs": dict(context),
            "results": results,
            "outputs": outputs,
        }
        if include_model_sources:
            saved["inputs"][f"models/gambit/{case_id}.qnt"] = digest(model)
            (rdir / "source").mkdir(parents=True, exist_ok=True)
            model_sources = {}
            for name, sha in saved["inputs"].items():
                if name.startswith("models/gambit/") and name.endswith(".qnt"):
                    snap = rdir / "source" / Path(name).name
                    snap.write_bytes((root / name).read_bytes())
                    model_sources["source/" + Path(name).name] = digest(snap)
            saved["modelSources"] = model_sources
        receipt_rel = f"evidence/{case_id}-receipt/receipt.json"
        receipt_path = root / receipt_rel
        receipt_path.write_text(json.dumps(saved))
        return manifest, manifest_rel, receipt_path, receipt_rel, model

    def test_budget_ledger_parent_is_registered_without_admission(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            _, manifest_rel, _, receipt_rel, model = self._write_bundle(
                root, "checkpoint_budget_ledger", old_invariants=(), registration_only=True)
            rows, bound = evidence.bundle_facts(root, manifest_rel, receipt_rel)
            self.assertEqual(rows["protocol_checked"], [])
            self.assertEqual(rows["protocol_composes"], [])
            self.assertEqual(bound["models/gambit/checkpoint_budget_ledger.qnt"], digest(model))

    def test_log_processor_composition_has_real_control_and_complete_check(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            manifest, _, receipt, _, _ = self._write_bundle(
                root, "processor_log", distinct=428,
                context_files={"docs/processor-log.md": "processor log premise\n"})
            rows = evidence.checked_rows(root, manifest, receipt)[0][1]
            old = next(row for row in rows if row["variant"] == "old")
            positive = next(row for row in rows if row["variant"] == "protocol")
            self.assertEqual(1, old["exit"])
            self.assertEqual(0, positive["exit"])
            self.assertEqual(428, positive["states"]["distinct"])
            self.assertEqual(0, positive["states"]["queued"])
            self.assertEqual(2, len(rows))

    def test_vm_constructor_composition_has_complete_state_and_source_closure(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            manifest, manifest_rel, receipt, receipt_rel, model = self._write_bundle(
                root, "vm_constructor", initializer="initConstructor",
                step="constructorStep", distinct=120, include_model_sources=True)
            rows = evidence.checked_rows(root, manifest, receipt)[0][1]
            self.assertEqual(2, len(rows))
            positive = next(row for row in rows if row["variant"] == "protocol")
            self.assertEqual("initConstructor", positive["initializer"])
            self.assertEqual("constructorStep", positive["step"])
            self.assertEqual(120, positive["states"]["distinct"])
            _, bound = evidence.bundle_facts(root, manifest_rel, receipt_rel)
            self.assertEqual(digest(model), bound["evidence/vm_constructor-receipt/source/vm_constructor.qnt"])

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
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            manifest, _, receipt, _, _ = self._write_bundle(
                root, "vm_constructor", include_model_sources=True,
                extra_model=("pstate_setup_transaction.qnt", "module pstate_setup_transaction {}\n"))
            self.assertEqual(1, len(evidence.checked_rows(root, manifest, receipt)))
            (receipt.parent / "source/pstate_setup_transaction.qnt").write_text("changed\n")
            with self.assertRaisesRegex(ValueError, "inventory"):
                evidence.checked_rows(root, manifest, receipt)

    def test_delayed_log_cleanup_violates_return_even_before_final_leak(self):
        manifest = json.loads((ROOT / "evidence/pstate-log-rollback-composition.json").read_text())
        case = manifest["cases"][0]
        self.assertEqual("pstate_log_rollback_composition", case["id"])
        self.assertIn("failureOwnershipSafe", case["oldInvariants"])
        self.assertTrue((ROOT / "models/gambit/pstate_log_rollback_composition.qnt").is_file())

    def test_previous_log_composition_receipt_does_not_prove_stronger_model(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            manifest, _, receipt, _, model = self._write_bundle(root, "pstate_log_rollback_composition")
            self.assertEqual(1, len(evidence.checked_rows(root, manifest, receipt)))
            model.write_text("module pstate_log_rollback_composition { /* stronger model */ }\n")
            with self.assertRaises(ValueError):
                evidence.checked_rows(root, manifest, receipt)

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
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            manifest, _, path, _, _ = self._write_bundle(
                root, "pstate_failure_composition", step="composedStep",
                old_invariants=("safeA", "safeB", "safeC"), distinct=125,
                extra_model=("pstate_setup_transaction.qnt", "module pstate_setup_transaction {}\n"))
            rows = evidence.checked_rows(root, manifest, path)
            self.assertEqual(4, len(rows[0][1]))
            positive = next(row for row in rows[0][1] if row["variant"] == "protocol")
            self.assertEqual("composedStep", positive["step"])
            self.assertEqual(0, positive["states"]["queued"])
            self.assertEqual(125, positive["states"]["distinct"])
            self.assertIn("models/gambit/pstate_setup_transaction.qnt", manifest["contextInputs"])
            changed = root / "changed-receipt.json"
            saved = json.loads(path.read_text())
            for row in saved["results"]:
                row["step"] = "step"
            changed.write_text(json.dumps(saved))
            from gambit_smp.check_gambit import reuse_model_receipt
            with self.assertRaisesRegex(ValueError, "another model"):
                reuse_model_receipt(changed, manifest["cases"][0], root / "models/gambit")

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
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            manifest, _, receipt, _, model = self._write_bundle(
                root, "reuse_case", initializer="initFixed", temporal="progress")
            case = manifest["cases"][0]
            sha = digest(model)
            directory = receipt.parent
            saved = json.loads(receipt.read_text())
            saved["results"][-1]["variant"] = "fixed"
            (directory / "protocol.log").write_text(
                "Finished checking temporal properties\n"
                "Model checking completed. No error has been found.\n"
                "428 states generated, 428 distinct states found, 0 states left on queue.\n")
            receipt.write_text(json.dumps(saved))
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
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            context, _, receipt, _, _ = self._write_bundle(
                root, "continuation_origin_model", old_invariants=())
            rows = evidence.checked_rows(root, context, receipt)
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
                       "temporal": None if variant == "old" else "progress",
                       "states": {} if variant == 'old' else {'generated': 2, 'distinct': 2, 'queued': 0}}
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
            with self.assertRaisesRegex(ValueError, "output observation"):
                evidence.checked_rows(root, manifest, path)


if __name__ == "__main__":
    unittest.main()
