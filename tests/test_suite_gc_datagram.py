"""Real loopback transport controls; not original stress acceptance."""
import socket
import struct
import select
import subprocess
import tempfile
from pathlib import Path
from unittest.mock import patch
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.suite_progress import ChildGCDatagramProgress, child_cookie, instrument, LOAD, READ


class DatagramProgressTests(unittest.TestCase):
    def test_colliding_file_cookies_reject_before_driver_write(self):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            (work / "lib").mkdir()
            reporter = work / "lib/_nonstd.scm"
            reporter.write_text("reporter")
            runner = work / "run-unit-tests.scm"
            original = '(define (run path . args) ' + READ + ')\n' + LOAD
            runner.write_text(original)
            module = work / "observer.o1"
            module.write_bytes(b"module")
            config = {"runnerSha256": digest(runner), "reporterSha256": digest(reporter),
                      "files": ["first.scm", "second.scm"], "transport": "native-datagram",
                      "forwarder": "models/gambit/native/child_gc_datagram_driver.scm"}
            with patch("gambit_smp.suite_progress.child_cookie", return_value=bytes(16)):
                with self.assertRaisesRegex(ValueError, "distinct child file cookies"):
                    instrument(work, work, config["files"], config, root=ROOT,
                               endpoint=12345, module=module)
            self.assertEqual(runner.read_text(), original)

    def setUp(self):
        receiver = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        receiver.bind(("127.0.0.1", 0))
        receiver.setblocking(False)
        self.endpoint = receiver.getsockname()
        self.sender = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.addCleanup(self.sender.close)
        config = {"kind": "completed-child-gc", "transport": "native-datagram",
                  "manifest": "evidence/dsl/components.json", "entry": "checkpoint-state",
                  "constructor": "make-checkpoint-state"}
        source = {"files": {"unit-tests/first.scm": "first", "unit-tests/second.scm": "second"}}
        self.observed = ChildGCDatagramProgress(ROOT, config, "nonce", source, 2, receiver=receiver)
        self.addCleanup(self.observed.close)
        self.begin = "SMP-CHILD nonce 123 unit-tests/first.scm\n"

    def send(self, sequence, *, pid=123, file="first.scm", nonce="nonce", suffix=b""):
        packet = struct.pack("!8s16sQQ", b"SMPGC001", child_cookie(nonce, "unit-tests/" + file), pid, sequence)
        self.sender.sendto(packet + suffix, self.endpoint)
        self.assertTrue(select.select([self.observed.receiver], [], [], 1)[0])

    def test_atomic_records_replay_reorder_and_loss(self):
        self.send(2)
        self.assertEqual(self.observed("", self.begin), 1)
        self.send(2)
        self.send(1)
        self.assertEqual(self.observed("", self.begin), 1)
        self.assertTrue(self.observed.witness["rejected"])
        self.send(4)
        self.assertEqual(self.observed("", self.begin), 2)
        self.assertFalse(self.observed.observation()["mutatorProgressEstablished"])

    def test_corrupted_boundaries_are_rejected_not_repaired(self):
        self.send(1, suffix=b"extra")
        self.sender.sendto(b"SMPGC001", self.endpoint)
        self.assertEqual(self.observed("", self.begin), 0)
        self.assertEqual(self.observed.rejected_packets, 2)

    def test_pid_cookie_and_file_epoch_are_all_required(self):
        self.send(1, pid=456)
        self.send(1, nonce="old")
        self.send(1, file="second.scm")
        self.assertEqual(self.observed("", self.begin), 0)
        self.send(1)
        self.assertEqual(self.observed("", self.begin), 1)
        second = self.begin + "SMP-CHILD nonce 123 unit-tests/second.scm\n"
        self.send(99)  # A reused PID cannot transfer the previous file's cookie.
        self.assertEqual(self.observed("", second), 1)
        self.send(1, file="second.scm")
        self.assertEqual(self.observed("", second), 2)

    def test_unattested_begin_and_text_cannot_replace_datagrams(self):
        self.assertEqual(self.observed("", self.begin), 0)
        text = self.begin + "SMP-GC nonce 123 unit-tests/first.scm 1 *** GC: 1ms, 1M alloc, 1M heap, 1M live (1% 1+1)\n"
        self.assertEqual(self.observed("", text), 0)
        self.assertIn("unexpected-text-gc-record", self.observed.errors)

    def test_silent_streams_still_poll_the_datagram_receiver(self):
        from gambit_smp.process_observation import communicate_progress
        fixture, clock = self, [0.0]
        class SilentProcess:
            args = ["silent-transport-control"]
            calls = 0
            def communicate(self, timeout):
                self.calls += 1
                clock[0] += .2
                if self.calls <= 3:
                    fixture.send(self.calls)
                    raise subprocess.TimeoutExpired(self.args, timeout)
                return "", ""
        self.observed("", self.begin)
        def receive(stdout, stderr):
            self.assertEqual((stdout, stderr), ("", ""))
            return self.observed(stdout, self.begin)
        with patch("gambit_smp.process_observation.time.monotonic", side_effect=lambda: clock[0]):
            self.assertEqual(communicate_progress(SilentProcess(), .3, receive), ("", ""))
        self.assertEqual(self.observed.renewals, 3)
