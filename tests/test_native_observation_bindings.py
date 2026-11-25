import copy
import contextlib
import io
import json
from pathlib import Path
import tempfile
import subprocess
import unittest
from unittest.mock import patch

from gambit_smp import evidence_index as index
from gambit_smp.ascent_program import load_catalog, query
from gambit_smp.framework import digest


class ObservationBindingsTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        (self.root / "evidence").mkdir()
        self.receipt = {"accepted": False, "fixture": "fixture.scm", "fixtureSha256": "a" * 64,
                        "identitySha256": "b" * 64,
                        "run": {"exit": -9, "timeout": True, "seconds": 30.01,
                                "group_quiescent": True, "stdout": "incomplete", "stderr": ""}}
        self.rows = [{"id": "retained", "category": "budget", "status": "open",
                      "file": "fixture.scm", "receipt": "evidence/receipt.json", "models": []}]
        self.entry = {"recordPointer": "", "eventPointer": "/run", "scope": "fixture",
                      "fields": {"accepted": "/accepted", "exit": "/run/exit", "timeout": "/run/timeout",
                                 "fixture": "/fixture", "fixture-sha": "/fixtureSha256",
                                 "runtime-identity-sha": "/identitySha256", "teardown": "/run/group_quiescent"}}
        self.write()

    def write(self):
        path = self.root / "evidence/receipt.json"
        path.write_text(json.dumps(self.receipt))
        self.inventory = self.root / "evidence/native-failures.json"
        self.inventory.write_text(json.dumps({"failures": self.rows}))
        self.entry["receiptSha256"] = digest(path)
        self.document = {"schema": "gambit-native-observation-bindings.v1",
                         "inventorySha256": digest(self.inventory), "bindings": {"retained": self.entry}}
        self.save()

    def save(self):
        (self.root / "evidence/native-observation-bindings.json").write_text(json.dumps(self.document))

    def bindings(self):
        return index.observation_bindings(self.root, self.inventory, self.rows, lambda path: None)

    def test_missing_budget_stays_missing_and_original_bytes_stay_unchanged(self):
        original = (self.root / "evidence/receipt.json").read_bytes()
        facts = self.bindings()["retained"]
        self.assertEqual([["retained", -9, True, False]], facts["observed_process"])
        self.assertNotIn("original-budget", {row[1] for row in facts["observed_field"]})
        self.assertEqual(original, (self.root / "evidence/receipt.json").read_bytes())

    def test_duration_is_not_an_original_budget(self):
        self.entry["fields"]["original-budget"] = "/run/seconds"
        self.save()
        with self.assertRaisesRegex(ValueError, "original event"):
            self.bindings()

    def test_flat_process_record_binds_only_its_own_fixture_and_event(self):
        self.receipt.update(self.receipt.pop("run"))
        self.receipt["runtimeIdentitySha256"] = self.receipt.pop("identitySha256")
        self.receipt["budgetSeconds"] = 30
        self.entry["eventPointer"] = ""
        self.entry["fields"] = {
            "accepted": "/accepted", "exit": "/exit", "timeout": "/timeout",
            "fixture": "/fixture", "fixture-sha": "/fixtureSha256",
            "runtime-identity-sha": "/runtimeIdentitySha256", "teardown": "/group_quiescent",
            "original-budget": "/budgetSeconds"}
        self.write()
        self.assertEqual([["retained", -9, True, False]], self.bindings()["retained"]["observed_process"])
        self.entry["fields"]["timeout"] = "/other/timeout"
        self.save()
        with self.assertRaisesRegex(ValueError, "share one event"):
            self.bindings()

    def test_sibling_process_event_cannot_supply_flat_record_outcome(self):
        self.entry["recordPointer"] = "/results/0"
        self.entry["eventPointer"] = "/results/1"
        self.save()
        with self.assertRaisesRegex(ValueError, "outside bound record"):
            self.bindings()

    def test_inventory_and_receipt_drift_are_rejected(self):
        self.document["inventorySha256"] = "0" * 64
        self.save()
        with self.assertRaisesRegex(ValueError, "inventory"):
            self.bindings()
        self.write()
        (self.root / "evidence/receipt.json").write_text("{}")
        with self.assertRaisesRegex(ValueError, "receipt"):
            self.bindings()

    def test_event_mixing_and_fixture_substitution_are_rejected(self):
        self.entry["fields"]["exit"] = "/accepted"
        self.save()
        with self.assertRaisesRegex(ValueError, "share one event"):
            self.bindings()
        self.entry["fields"]["exit"] = "/run/exit"
        self.receipt["fixture"] = "other.scm"
        self.write()
        with self.assertRaisesRegex(ValueError, "fixture"):
            self.bindings()

    def test_wrong_types_and_missing_pointers_are_rejected(self):
        self.receipt["run"]["exit"] = False
        self.write()
        with self.assertRaisesRegex(ValueError, "typed observation"):
            self.bindings()
        self.receipt["run"]["exit"] = -9
        del self.receipt["run"]["timeout"]
        self.write()
        with self.assertRaises(ValueError):
            self.bindings()

    def test_identity_field_alias_is_not_source_identity(self):
        self.entry["fields"]["source-lock-sha"] = "/identitySha256"
        self.save()
        with self.assertRaisesRegex(ValueError, "original named"):
            self.bindings()

    def test_unknown_binding_identity_is_rejected(self):
        self.document["bindings"]["omitted-inventory"] = copy.deepcopy(self.entry)
        self.save()
        with self.assertRaisesRegex(ValueError, "unknown"):
            self.bindings()

    def test_normalized_receipts_cannot_bypass_strict_control_admission(self):
        self.receipt["status"] = "DENY"
        self.write()
        with self.assertRaisesRegex(ValueError, "strict admission"):
            self.bindings()

    def test_validate_output_is_not_a_mutually_exclusive_mode(self):
        from gambit_smp import workspace
        self.root = self.root.resolve()
        workspace.git(self.root, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                      'commit', '--allow-empty', '-qm', 'fixture')
        workspace.start(self.root, 'validation', adopt=True)
        (self.root / "evidence/dsl").mkdir()
        (self.root / "evidence/dsl/components.json").write_bytes(
            (Path(__file__).parent / "fixtures/catalog-components.json").read_bytes())
        (self.root / "evidence/dsl/catalog.ss").write_text(
            "(def (make-catalog) (make-recorded-module "
            "(ascent-fragment (relation input ((value symbol?)))) '(input)))")
        out = self.root / ".cache/tasks/validation/runs/retained-query"
        with workspace.execution_scope(self.root, 'validation'), \
                patch.object(index, "ROOT", self.root), \
                patch.object(index, "export", return_value={"facts": {}, "inputs": {}}), \
                patch.object(index, "query", return_value={}), \
                patch("gambit_smp.reasoning_history.record", return_value={}), \
                patch("sys.argv", ["evidence", "--validate", "--out", str(out)]), \
                contextlib.redirect_stdout(io.StringIO()):
            index.main()
        self.assertTrue(json.loads((out / "receipt.json").read_text())["diagnosticOnly"])

    def test_external_log_requires_its_original_event_digest(self):
        log = self.root / "evidence/raw.log"
        log.write_text("retained log")
        self.rows[0]["log"] = "evidence/raw.log"
        self.receipt["run"]["rawLogSha256"] = digest(log)
        self.entry["logSha256Pointer"] = "/run/rawLogSha256"
        self.write()
        self.assertEqual(1, len(self.bindings()["retained"]["observed_log_attachment"]))
        log.write_text("changed log")
        with self.assertRaisesRegex(ValueError, "recorded output observation"):
            self.bindings()

    def _multi_observation_fixture(self):
        """Build a clean-checkout multi-record fixture covering budget, signal and controls."""
        core_receipt = {
            "accepted": False, "fixture": "seed-core.scm", "fixtureSha256": "c" * 64,
            "identitySha256": "d" * 64, "wholeBudgetSeconds": 180,
            "run": {"stage": "seed-core", "budgetSeconds": 180,
                    "exit": -9, "timeout": True, "seconds": 180.02, "group_quiescent": True}}
        sig_receipt = {
            "accepted": False, "fixture": "interrupt.scm", "fixtureSha256": "e" * 64,
            "identitySha256": "f" * 64, "processBudgetSeconds": 30,
            "run": {"exit": -11, "timeout": False, "seconds": 1.2, "group_quiescent": True}}
        (self.root / "evidence/core-receipt.json").write_text(json.dumps(core_receipt))
        (self.root / "evidence/sig-receipt.json").write_text(json.dumps(sig_receipt))
        (self.root / "evidence/control-ref.json").write_text(json.dumps({"outcome": "PASS"}))
        self.rows = [
            {"id": "retained-timeout", "category": "budget", "status": "open",
             "file": "fixture.scm", "receipt": "evidence/receipt.json", "models": []},
            {"id": "core-budget", "category": "budget", "status": "open",
             "file": "seed-core.scm", "receipt": "evidence/core-receipt.json", "models": []},
            {"id": "concurrent-interrupt-signal", "category": "signal", "status": "open",
             "file": "interrupt.scm", "receipt": "evidence/sig-receipt.json",
             "signal": 11,
             "controls": [{"kind": "local-control", "mode": "gsi", "receipt": "evidence/control-ref.json"}],
             "models": []}]
        self.write()
        self.document["bindings"] = {
            "retained-timeout": {
                **copy.deepcopy(self.entry),
                "receiptSha256": digest(self.root / "evidence/receipt.json")},
            "core-budget": {
                "recordPointer": "", "eventPointer": "/run", "scope": "fixture",
                "receiptSha256": digest(self.root / "evidence/core-receipt.json"),
                "fields": {
                    "accepted": "/accepted", "exit": "/run/exit", "timeout": "/run/timeout",
                    "fixture": "/fixture", "fixture-sha": "/fixtureSha256",
                    "runtime-identity-sha": "/identitySha256", "teardown": "/run/group_quiescent",
                    "operation": "/run/stage", "original-budget": "/run/budgetSeconds",
                    "whole-budget": "/wholeBudgetSeconds"}},
            "concurrent-interrupt-signal": {
                "recordPointer": "", "eventPointer": "/run", "scope": "fixture",
                "receiptSha256": digest(self.root / "evidence/sig-receipt.json"),
                "fields": {
                    "accepted": "/accepted", "exit": "/run/exit", "timeout": "/run/timeout",
                    "fixture": "/fixture", "fixture-sha": "/fixtureSha256",
                    "runtime-identity-sha": "/identitySha256", "teardown": "/run/group_quiescent",
                    "original-budget": "/processBudgetSeconds"}}}
        self.save()
        return self.bindings()

    def test_checked_in_bindings_cover_all_raw_observations_without_control_admission(self):
        # Verify the immutable checked-in inventory/bindings header stays consistent
        # without requiring retired legacy cache receipt files.
        inventory_path = index.ROOT / "evidence/native-failures.json"
        bindings_doc = json.loads((index.ROOT / "evidence/native-observation-bindings.json").read_text())
        self.assertEqual(digest(inventory_path), bindings_doc["inventorySha256"])
        self.assertEqual(12, len(bindings_doc["bindings"]))

        bound = self._multi_observation_fixture()
        self.assertEqual({"retained-timeout", "core-budget", "concurrent-interrupt-signal"}, set(bound))
        self.assertEqual(1, sum(len(v["observed_control_reference"]) for v in bound.values()))
        core = bound["core-budget"]
        values = {r[1]: json.loads(r[4]) for r in core["observed_field"]}
        self.assertEqual("seed-core", values["operation"])
        self.assertEqual(180, values["original-budget"])
        self.assertEqual(180, values["whole-budget"])
        self.assertFalse(any("local_control_pass" in v for v in bound.values()))
        sig = bound["concurrent-interrupt-signal"]
        self.assertIn(["concurrent-interrupt-signal", "original-budget",
                       digest(self.root / "evidence/sig-receipt.json"),
                       "/processBudgetSeconds", "30"], sig["observed_field"])

    def test_native_failure_classification_and_gaps_preserve_negative_controls(self):
        bound = self._multi_observation_fixture()
        facts = {name: [] for name in ("observed_failure", "observed_process", "observed_field",
                 "observed_signal", "observed_control_reference", "observed_model_reference",
                 "local_native_failure", "local_control_pass", "model", "protocol_model", "observed_log_attachment")}
        for observation in bound.values():
            for name, values in observation.items():
                facts[name].extend(values)
        queries = {"failures": "local_failure_record", "gaps": "observed_gap",
                   "mismatches": "observed_unmatched", "controls": "local_control_pass",
                   "references": "observed_control_reference", "unregistered": "observed_model_unregistered"}
        rules = load_catalog(index.ROOT / "evidence/catalog.ss")
        backend = {}
        result = query(facts, rules, queries, metrics=backend)
        self.assertEqual("ascent-rust", backend["name"])
        self.assertEqual(set(bound), {r[0] for r in result["failures"]})
        self.assertEqual([], result["mismatches"])
        self.assertEqual([], result["controls"])
        self.assertEqual(1, len(result["references"]))
        self.assertIn(("retained-timeout", "original-budget"), result["gaps"])
        self.assertTrue(all((name, "runtime-tree") in result["gaps"] for name in bound))
        changed = copy.deepcopy(facts)
        changed["observed_process"] = [[name, 0, False, True] for name in bound]
        rejected = query(changed, rules, queries)
        self.assertEqual([], rejected["failures"])
        self.assertEqual(set(bound), {r[0] for r in rejected["mismatches"]})
        changed = copy.deepcopy(facts)
        changed["observed_signal"] = [[row[0], 12] for row in changed["observed_signal"]]
        for row in changed["observed_field"]:
            if row[1] == "teardown":
                row[4] = "false"
        contradicted = query(changed, rules, queries)
        self.assertIn(("concurrent-interrupt-signal",), contradicted["mismatches"])
        self.assertTrue(all((row[0], "teardown") in contradicted["gaps"]
                            for row in changed["observed_field"] if row[1] == "teardown"))
        self.assertNotIn("runtime_admitted", result)
        self.assertNotIn("retry_eligible", result)


if __name__ == "__main__":
    unittest.main()
