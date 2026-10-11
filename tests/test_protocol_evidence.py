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
