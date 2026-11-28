"""Separating controls for the native write-group evidence join."""
import unittest

from gambit_smp.gate2_native import OBLIGATIONS, measure
from gambit_smp.gate2_evidence import IMAGE_OBJECTS, SITES, investigation
from test_observation import event, trace, wire
from gambit_smp.rest_observation import decode_trace


def group(kind, *payload, invocation=1, epoch=7):
    return event("group-" + kind, values=(0x80, 0x100, *payload),
                 activation=2, attempt=invocation, epoch=epoch)


def sample():
    return [
        group("open", 1024, 512, 1280, 768, 100, 1),
        group("store", 1024, 1040, 1, 0, 0, 0),
        group("enter", 1024, 512, 1280, 768, 100, 1),
        group("backing", 1024, 512, 1280, 15, 33, 0),
        group("demand", 1024, 768, 1, 5, 20, 8),
        group("saved", 928, 5, 0, 8, 0, 0),
        group("unwound", 928, 1024, 32, 4, 12, 5, epoch=8),
        group("enter", 1024, 512, 1280, 768, 100, 2, epoch=8),
        group("grant", 1024, 512, 1280, 20, 5, 8, epoch=8),
        group("heap-grant", 2048, 8, 5, 0, 0, 0, epoch=8),
        group("store", 0, 2048, 3, 5, 0, 0, epoch=8),
        group("adjust", 1024, 1016, 1, 3, 5, 0, epoch=8),
        group("store", 1016, 1008, 3, 5, 0, 0, epoch=8),
        group("commit", 5, 0, 0, 0, 0, 0, epoch=8),
        group("retired", 5, 0, 0, 0, 0, 0, epoch=8),
    ]


class Gate2NativeTests(unittest.TestCase):
    def statuses(self, rows, **terminal):
        command = dict(exit=0, timeout=False, parentReaped=True, processGroupQuiescent=True,
                       streamCaptureComplete=True) | terminal
        report = measure(dict(label=100, preEnterSpills=[-2]), decode_trace(wire(trace(rows))), command, 1)
        return {name: check["status"] for name, check in report.items()}

    def test_complete_stream_and_old_slot_classification(self):
        self.assertEqual(self.statuses(sample()), dict.fromkeys(OBLIGATIONS, "PASS"))
        rows = sample()
        rows[3]["values"][-1] = 1 << 2
        self.assertEqual(self.statuses(rows)["oldFrameBacking"], "MISMATCH")

    def test_saved_cursor_injection_and_first_store(self):
        rows = sample()
        rows[8]["values"][2] = rows[5]["values"][2]
        statuses = self.statuses(rows)
        self.assertEqual(statuses["unwoundCallerFp"], "MISMATCH")
        self.assertEqual(statuses["firstWrite"], "MISMATCH")
        rows = sample()
        rows[10]["values"][3] = 4096
        self.assertEqual(self.statuses(rows)["firstWrite"], "MISMATCH")
        rows = sample()
        rows.insert(8, group("store", 1024, 1016, 2, 5, 0, 0, epoch=8))
        self.assertEqual(self.statuses(rows)["firstWrite"], "MISMATCH")

    def test_replay_and_substituted_invocation(self):
        rows = sample()
        rows.insert(-1, group("store", 1016, 1008, 4, 5, 0, 0, epoch=8))
        self.assertEqual(self.statuses(rows)["noCommittedReplay"], "MISMATCH")
        rows = sample()
        rows[6]["attempt"] = 2
        self.assertEqual(self.statuses(rows)["unwoundCallerFp"], "MISSING")
        self.assertEqual(self.statuses(rows)["firstWrite"], "MISSING")
        self.assertEqual(self.statuses(sample(), timeout=True), dict.fromkeys(OBLIGATIONS, "MISSING"))

    def test_ascent_keeps_partial_runs_and_counterevidence_local(self):
        def row(state, missing):
            return {name: dict(status=missing if name == "firstWrite" else state) for name in OBLIGATIONS}

        def project(observations):
            result = investigation(dict(
                linkSelection={image: dict(status="PASS", objects={name: dict(status="PASS") for name in names})
                               for image, names in IMAGE_OBJECTS.items()},
                sites=[dict(id=name, status="PASS", schemeGvm=dict(status="PASS")) for name in SITES],
                nativeFrame={"F6-20-7": observations}, collectionReady=True))
            self.assertEqual(result["status"], "PROJECTED")
            return result, {x["check"]: x["status"] for x in result["sites"]["F6-20-7"]["checks"]}

        projection, checks = project([row("PASS", "MISSING"), row("MISSING", "PASS")])
        self.assertEqual(checks["nativeFrameComplete"], "MISSING")
        self.assertIn(dict(kind="native-frame", subject="F6-20-7"), projection["collectionOptions"])
        _, checks = project([row("PASS", "PASS")])
        self.assertEqual(checks["nativeFrameComplete"], "PASS")
        _, checks = project([row("PASS", "PASS"), row("MISSING", "MISMATCH")])
        self.assertEqual(checks["firstWrite"], "MISMATCH")
        self.assertEqual(checks["nativeFrameComplete"], "MISSING")
