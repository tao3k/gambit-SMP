import json
import tempfile
import unittest
import uuid
from pathlib import Path

from gambit_smp.grok_acp import AcpOutcomeUnknown
from gambit_smp.grok_control import send, serve


class Connection:
    def __init__(self):
        self.calls = []
        self.unknown = False

    def interject(self, session, text, *, interjection_id, timeout):
        self.calls.append((session, text, interjection_id))
        if self.unknown:
            raise AcpOutcomeUnknown("unconfirmed", interjection_id=interjection_id)


class ControlTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.descriptor = self.root / "state" / "control.json"
        self.attempt = self.root / "attempt"
        self.attempt.mkdir()
        self.connection = Connection()
        self.binding = dict(task="task", owner="owner", run="run", session="session", authorization="consent")

    def request(self, message_id, text="instruction", **changes):
        binding = self.binding | changes
        return send(self.descriptor, **binding, message_id=message_id, text=text)

    def test_binding_and_idempotent_delivery(self):
        message_id = str(uuid.uuid4())
        with serve(self.connection, descriptor=self.descriptor, attempt=self.attempt, **self.binding):
            with self.assertRaisesRegex(ValueError, "authorization"):
                self.request(message_id, authorization="wrong")
            with self.assertRaisesRegex(ValueError, "binding"):
                self.request(message_id, session="wrong")
            first = self.request(message_id)
            second = self.request(message_id)
            self.assertEqual(first["status"], "queued")
            self.assertEqual(first, second)
            self.assertEqual(len(self.connection.calls), 1)
            record = json.loads((self.attempt / "interjections" / (message_id + ".json")).read_text())
            self.assertEqual(record, first)
        self.assertFalse(self.descriptor.exists())

    def test_unknown_is_retained_without_resend(self):
        self.connection.unknown = True
        message_id = str(uuid.uuid4())
        with serve(self.connection, descriptor=self.descriptor, attempt=self.attempt, **self.binding):
            self.assertEqual(self.request(message_id)["status"], "unknown")
            self.assertEqual(self.request(message_id)["status"], "unknown")
            self.assertEqual(len(self.connection.calls), 1)


if __name__ == "__main__":
    unittest.main()
