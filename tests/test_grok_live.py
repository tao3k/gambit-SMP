"""ACP launch, active instruction custody, and task-bound control."""
import json
import os
from pathlib import Path
import tempfile
import time
import unittest
import uuid
from dataclasses import replace
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch

from gambit_smp.grok_control import send
from gambit_smp.grok_session import run
from test_grok_session import GrokSessionTests, provider_path


FAKE_PROVIDER = r'''
import json, sys

def respond(id, result):
    print(json.dumps({"jsonrpc": "2.0", "id": id, "result": result}), flush=True)

prompt_id = None
for line in sys.stdin:
    msg = json.loads(line)
    method = msg.get("method")
    if method == "initialize":
        respond(msg["id"], {"protocolVersion": 1, "authMethods": []})
    elif method == "session/new":
        respond(msg["id"], {"sessionId": "01a15562-916b-7da0-b55e-5d85db65485a"})
    elif method == "session/load":
        respond(msg["id"], {})
    elif method == "session/prompt":
        prompt_id = msg["id"]
        print(json.dumps({"jsonrpc":"2.0", "method":"session/update",
                          "params":{"update":{"sessionUpdate":"agent_thought_chunk"}}}), flush=True)
    elif method == "_x.ai/interject":
        respond(msg["id"], {"result": {"status": "queued"}})
        respond(prompt_id, {"stopReason": "end_turn"})
'''


class LiveSessionTests(unittest.TestCase):
    def test_unverified_permission_boundary_blocks_before_lease(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            launch = GrokSessionTests().make_launch(root)
            with self.assertRaisesRegex(ValueError, "read permissions are not verified"):
                run(launch, execute=True, wall_seconds=20, acp=True)
            self.assertFalse((root / ".state/provider-control").exists())

    def test_supervised_live_instruction_preserves_custody_and_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            launch = GrokSessionTests().make_launch(root)
            executable = root / "grok"
            executable.write_text("#!" + os.sys.executable + "\n" + FAKE_PROVIDER)
            executable.chmod(0o700)
            descriptor = root / ".state/provider-control/repair/diagnostic.json"
            with patch.dict(os.environ, PATH=provider_path(root)), patch(
                    'gambit_smp.grok_live.permission_boundary_verified', return_value=True), patch(
                    'gambit_smp.grok_live.supervisor_sources', return_value={'test': 'fixture'}):
                with ThreadPoolExecutor(max_workers=1) as pool:
                    pending = pool.submit(run, launch, execute=True, wall_seconds=20, acp=True)
                    deadline = time.monotonic() + 10
                    while not descriptor.is_file() and not pending.done() and time.monotonic() < deadline:
                        time.sleep(.02)
                    self.assertTrue(descriptor.is_file(), pending.result() if pending.done() else "not ready")
                    binding = json.loads(descriptor.read_text())
                    message_id = str(uuid.uuid4())
                    receipt = send(descriptor, task="repair", owner="diagnostic", run=binding["run"],
                                   session=binding["sessionId"], authorization=launch.authorization,
                                   message_id=message_id, text="change priority")
                    self.assertEqual(receipt["status"], "queued")
                    result = pending.result(timeout=15)
            self.assertTrue(result["sessionCompleted"], result)
            self.assertTrue(result["parentReaped"])
            self.assertFalse(result["nativeAdmitted"])
            self.assertFalse(descriptor.exists())
            record = Path(result["attempt"]) / "interjections" / (message_id + ".json")
            self.assertEqual(json.loads(record.read_text())["status"], "queued")
            binding = json.loads((root / ".state/provider-sessions/repair/diagnostic.json").read_text())
            self.assertEqual(binding["sessionId"], result["completion"]["sessionId"])

    def test_resume_reuses_original_context_and_policy(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            launch = GrokSessionTests().make_launch(root)
            executable = root / "grok"
            executable.write_text("#!" + os.sys.executable + "\n" + FAKE_PROVIDER)
            executable.chmod(0o700)
            descriptor = root / ".state/provider-control/repair/diagnostic.json"
            with patch.dict(os.environ, PATH=provider_path(root)), patch(
                    'gambit_smp.grok_live.permission_boundary_verified', return_value=True), patch(
                    'gambit_smp.grok_live.supervisor_sources', return_value={'test': 'fixture'}):
                with ThreadPoolExecutor(max_workers=1) as pool:
                    def deliver(launch):
                        pending = pool.submit(run, launch, execute=True, wall_seconds=20, acp=True)
                        deadline = time.monotonic() + 10
                        while not descriptor.is_file() and not pending.done() and time.monotonic() < deadline:
                            time.sleep(.02)
                        self.assertTrue(descriptor.is_file(), pending.result() if pending.done() else 'not ready')
                        binding = json.loads(descriptor.read_text())
                        send(descriptor, task='repair', owner='diagnostic', run=binding['run'],
                             session=binding['sessionId'], authorization=launch.authorization,
                             message_id=str(uuid.uuid4()), text='continue')
                        return pending.result(timeout=15)
                    first = deliver(launch)
                    resumed = deliver(replace(launch, resume=first['completion']['sessionId']))
                    self.assertEqual(first['sessionCwd'], resumed['sessionCwd'])
                    self.assertEqual(first['policySha256'], resumed['policySha256'])
                    (Path(first['sessionCwd']) / '.grok/config.toml').write_text('[permission]\nallow = ["Read"]\n')
                    with self.assertRaisesRegex(ValueError, 'resume policy changed'):
                        run(replace(launch, resume=first['completion']['sessionId']),
                            execute=True, wall_seconds=20, acp=True)


if __name__ == "__main__":
    unittest.main()
