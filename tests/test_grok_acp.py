import json
import socket
import unittest
from contextlib import suppress
from concurrent.futures import ThreadPoolExecutor

from gambit_smp.grok_acp import AcpConnection, AcpError, AcpOutcomeUnknown


class AcpConnectionTests(unittest.TestCase):
    def setUp(self):
        local, self.provider = socket.socketpair()
        self.local = local
        self.reader = local.makefile("r", encoding="utf-8")
        self.writer = local.makefile("w", encoding="utf-8")
        self.provider_reader = self.provider.makefile("r", encoding="utf-8")
        self.provider_writer = self.provider.makefile("w", encoding="utf-8")
        self.connection = AcpConnection(self.reader, self.writer)

    def tearDown(self):
        with suppress(OSError):
            self.local.shutdown(socket.SHUT_RDWR)
        self.reader.close()
        self.writer.close()
        self.provider_reader.close()
        self.provider_writer.close()
        self.local.close()
        self.provider.close()

    def read_request(self):
        return json.loads(self.provider_reader.readline())

    def reply(self, message):
        self.provider_writer.write(json.dumps(message) + "\n")
        self.provider_writer.flush()

    def test_interjection_does_not_wait_for_prompt_response(self):
        with ThreadPoolExecutor(max_workers=2) as pool:
            prompt = pool.submit(self.connection.request, "session/prompt", {"sessionId": "s"}, timeout=5)
            first = self.read_request()
            steer = pool.submit(self.connection.interject, "s", "new task", interjection_id="i", timeout=5)
            second = self.read_request()
            self.assertEqual(second["method"], "_x.ai/interject")
            self.assertEqual(second["params"], {"sessionId": "s", "text": "new task", "interjectionId": "i"})
            self.reply({"jsonrpc": "2.0", "id": second["id"], "result": {"status": "queued"}})
            self.assertEqual(steer.result()["status"], "queued")
            self.assertFalse(prompt.done())
            self.reply({"jsonrpc": "2.0", "id": first["id"], "result": {"stopReason": "end_turn"}})
            self.assertEqual(prompt.result()["stopReason"], "end_turn")

    def test_provider_permission_is_denied(self):
        self.reply({"jsonrpc": "2.0", "id": "permission", "method": "session/request_permission", "params": {}})
        response = self.read_request()
        self.assertEqual(response["result"], {"outcome": {"outcome": "cancelled"}})

    def test_provider_nested_extension_result_is_accepted(self):
        with ThreadPoolExecutor(max_workers=1) as pool:
            request = pool.submit(self.connection.interject, "s", "instruction", timeout=5)
            outgoing = self.read_request()
            self.reply({"jsonrpc": "2.0", "id": outgoing["id"],
                        "result": {"result": {"status": "queued"}}})
            self.assertEqual(request.result()["status"], "queued")

    def test_rejection_and_ambiguous_timeout_are_distinct(self):
        with ThreadPoolExecutor(max_workers=1) as pool:
            request = pool.submit(self.connection.interject, "s", "instruction", timeout=5)
            outgoing = self.read_request()
            self.reply({"jsonrpc": "2.0", "id": outgoing["id"], "error": {"code": -32601}})
            with self.assertRaises(AcpError):
                request.result()
        with self.assertRaises(AcpOutcomeUnknown) as raised:
            self.connection.interject("s", "do not resend", interjection_id="uncertain", timeout=0.01)
        outstanding = self.read_request()
        self.assertEqual(outstanding["method"], "_x.ai/interject")
        self.assertEqual(raised.exception.request_id, outstanding["id"])
        self.assertEqual(raised.exception.interjection_id, "uncertain")

    def test_late_response_does_not_settle_a_later_request(self):
        with self.assertRaises(AcpOutcomeUnknown):
            self.connection.interject("s", "first", interjection_id="first", timeout=0.01)
        first = self.read_request()
        with ThreadPoolExecutor(max_workers=1) as pool:
            second = pool.submit(self.connection.interject, "s", "second", interjection_id="second", timeout=5)
            request = self.read_request()
            self.reply({"jsonrpc": "2.0", "id": first["id"], "result": {"status": "queued"}})
            self.reply({"jsonrpc": "2.0", "id": request["id"], "result": {"status": "queued"}})
            self.assertEqual(second.result()["interjectionId"], "second")

    def test_disconnect_leaves_outstanding_outcome_unknown(self):
        with ThreadPoolExecutor(max_workers=1) as pool:
            request = pool.submit(self.connection.interject, "s", "instruction", timeout=5)
            self.read_request()
            self.provider.shutdown(socket.SHUT_WR)
            with self.assertRaises(AcpOutcomeUnknown):
                request.result()



if __name__ == "__main__":
    unittest.main()
