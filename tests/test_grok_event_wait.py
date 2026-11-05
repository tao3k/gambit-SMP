import json
import os
import sys
import tempfile
import threading
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from gambit_smp.grok_event_wait import _file_notifications, classify, event_path, wait_for_event


class GrokEventWaitTest(unittest.TestCase):
    def test_permission_is_not_reported_after_resolution(self):
        pending = []
        self.assertIsNone(classify([
            {"type": "permission_requested", "tool_name": "read_file"},
            {"type": "permission_resolved", "tool_name": "read_file"},
        ], pending))
        self.assertEqual(pending, [])

    def test_native_result_and_turn_end_are_supervision_events(self):
        pending = []
        self.assertIsNone(classify([{
            "type": "tool_completed", "tool_name": "read_file", "outcome": "success"
        }], pending))
        self.assertEqual(classify([{
            "type": "tool_completed", "tool_name": "run_terminal_command",
            "outcome": "success"
        }], pending)["tool_name"], "run_terminal_command")
        self.assertEqual(classify([{"type": "turn_ended"}], pending)["type"], "turn_ended")

    def test_exact_session_path_is_workspace_scoped(self):
        path = event_path(
            "01a149f9-3af5-7803-8b71-8ac73fc8834c",
            Path("/tmp/example workspace"),
            Path("/tmp/grok-home"),
        )
        self.assertEqual(path.parent.name, "01a149f9-3af5-7803-8b71-8ac73fc8834c")
        self.assertIn("%2Ftmp%2Fexample%20workspace", str(path))

    def test_waits_for_kernel_file_notification(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "events.jsonl"
            path.write_text("", encoding="utf-8")

            def append():
                with path.open("a", encoding="utf-8") as stream:
                    stream.write(json.dumps({
                        "ts": "2026-10-17T00:00:00Z",
                        "type": "permission_requested",
                        "tool_name": "run_terminal_command",
                    }) + "\n")

            timer = threading.Timer(0.05, append)
            timer.start()
            try:
                event = wait_for_event(path, 2)
            finally:
                timer.join()
            self.assertEqual(event["type"], "permission_requested")
            self.assertEqual(event["tool_name"], "run_terminal_command")

    def test_historical_unresolved_permission_returns_immediately(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "events.jsonl"
            path.write_text(json.dumps({
                "type": "permission_requested",
                "tool_name": "run_terminal_command",
            }) + "\n", encoding="utf-8")
            self.assertEqual(wait_for_event(path, 2)["type"], "permission_requested")

    def test_immediately_resolved_permission_does_not_wake_supervisor(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "events.jsonl"
            path.write_text("", encoding="utf-8")

            def append():
                with path.open("a", encoding="utf-8") as stream:
                    stream.write(json.dumps({
                        "type": "permission_requested", "tool_name": "grep"
                    }) + "\n")
                    stream.flush()
                    stream.write(json.dumps({
                        "type": "permission_resolved", "tool_name": "grep"
                    }) + "\n")

            timer = threading.Timer(0.05, append)
            timer.start()
            try:
                event = wait_for_event(path, 0.2)
            finally:
                timer.join()
            self.assertEqual(event["type"], "supervision_quiet")

    def test_backend_setup_failure_closes_the_log_descriptor(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "events.jsonl"
            path.touch()
            with patch("gambit_smp.grok_event_wait._file_notifications", side_effect=OSError("watch")), \
                    patch("gambit_smp.grok_event_wait.os.close", wraps=os.close) as close:
                with self.assertRaisesRegex(OSError, "watch"):
                    wait_for_event(path, 1)
                descriptor = close.call_args.args[0]
            with self.assertRaises(OSError):
                os.fstat(descriptor)

    def test_linux_watch_failure_releases_the_notification_descriptor(self):
        libc = MagicMock()
        libc.inotify_init1.return_value = 137
        libc.inotify_add_watch.return_value = -1
        with patch("gambit_smp.grok_event_wait.sys.platform", "linux"), \
                patch("ctypes.CDLL", return_value=libc), \
                patch("ctypes.get_errno", return_value=13), \
                patch("os.O_CLOEXEC", 0x80000, create=True), \
                patch("gambit_smp.grok_event_wait.os.close") as close:
            with self.assertRaisesRegex(OSError, "inotify_add_watch"):
                with _file_notifications(Path("events.jsonl"), 0):
                    self.fail("failed watch must not be usable")
            close.assert_called_once_with(137)


if __name__ == "__main__":
    unittest.main()
