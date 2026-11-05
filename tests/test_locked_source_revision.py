import json
import subprocess
import unittest
from pathlib import Path

from gambit_smp.native_capabilities import (
    assert_head_unchanged, assert_locked_source, head_command, locked_revision_command)

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "evidence/research/processor-interrupt-collective-wait/handler-quiet-while-pending.lock.json"
CHECKOUT = ROOT / "vendor/gambit"


class LockedSourceRevisionTests(unittest.TestCase):
    def test_locked_commit_is_reachable_without_moving_head(self):
        lock = json.loads(LOCK.read_text())
        before = subprocess.check_output(head_command("git", CHECKOUT), text=True, timeout=10).strip()
        resolved = subprocess.check_output(
            locked_revision_command("git", CHECKOUT, lock["revision"]), text=True, timeout=10).strip()
        assert_locked_source(resolved, lock["revision"])
        after = subprocess.check_output(head_command("git", CHECKOUT), text=True, timeout=10).strip()
        assert_head_unchanged(before, after, "source revision changed during materialization")
        self.assertNotEqual(after, lock["revision"])

    def test_drift_and_head_movement_stay_rejected(self):
        with self.assertRaises(ValueError):
            assert_locked_source("a" * 40, "b" * 40)
        with self.assertRaises(ValueError):
            assert_head_unchanged("a" * 40, "b" * 40, "source revision changed during materialization")


if __name__ == "__main__":
    unittest.main()
