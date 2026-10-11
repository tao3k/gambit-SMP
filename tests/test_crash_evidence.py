import json
import unittest

from gambit_smp import crash_evidence as evidence


class CrashEvidenceTests(unittest.TestCase):
    def test_compiler_binding_requires_real_failed_child_and_exact_toolchain(self):
        identity = {"gscSha256": "sha"}
        receipt = {"native": {"toolchain": identity, "compile": {
            "accepted": False, "timeout": False, "exit": -10, "process": {"pid": 42}}}}
        self.assertEqual(42, evidence.compiler_child(receipt, identity))
        for field, value in (("accepted", True), ("timeout", True), ("exit", 0)):
            changed = json.loads(json.dumps(receipt))
            changed["native"]["compile"][field] = value
            with self.assertRaises(ValueError):
                evidence.compiler_child(changed, identity)
        with self.assertRaises(ValueError):
            evidence.compiler_child(receipt, {"gscSha256": "other"})

    def report(self):
        return {"pid": 42, "captureTime": "time", "faultingThread": 0,
                "procPath": "/private/personal/gsc", "hardwareIdentifier": "secret",
                "exception": {"type": "EXC_BAD_ACCESS", "signal": "SIGBUS"},
                "usedImages": [{"uuid": "uuid", "size": 100, "path": "/private/personal/gsc"}],
                "threads": [{"frames": [{"symbol": "function", "imageIndex": 0}],
                             "threadState": {"x": [{"value": 123}], "pc": {"value": 10}}}]}

    def test_exact_image_and_optional_child_pid_binding_fail_closed(self):
        report = self.report()
        result = evidence.normalize(report, "UUID", 42)
        self.assertTrue(result["pidBoundToNativeReceipt"])
        self.assertFalse(evidence.normalize(report, "UUID")["pidBoundToNativeReceipt"])
        self.assertNotIn("personal", json.dumps(result))
        self.assertNotIn("secret", json.dumps(result))
        for uuid, pid in (("different", 42), ("uuid", 99)):
            with self.assertRaises(ValueError):
                evidence.normalize(report, uuid, pid)

    def test_multi_object_incident_parser_rejects_trailing_or_missing_data(self):
        text = '{}\n' + json.dumps(self.report())
        self.assertEqual(self.report(), evidence.incident(text))
        for invalid in (text + "trailing", "{}", text + "\n{}"):
            with self.assertRaises(ValueError):
                evidence.incident(invalid)
