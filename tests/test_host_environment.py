import copy
import errno
import unittest
from unittest.mock import patch, MagicMock

from gambit_smp import host_environment as host


class HostEnvironmentTests(unittest.TestCase):
    def setUp(self):
        self.old = {"schema": host.SCHEMA, "operation": "ipv4-loopback-bind",
                    "epoch": "boot", "available": False, "errno": errno.EPERM}
        self.current = {**self.old, "available": True, "errno": None}
        self.outer = {"schema": "sealed-research-run.v1", "outcome": "DENY",
                      "executionLaunched": False, "childReceiptSha256": None,
                      "denial": host.ERROR, "hostEnvironment": self.old}

    def test_only_observed_prelaunch_denial_can_repair(self):
        self.assertTrue(host.repaired(self.outer, self.current))
        child = {"schema": "evidence-recipe-run.v1", "outcome": "DENY",
                 "steps": [], "error": host.ERROR, "hostEnvironment": self.old}
        self.assertTrue(host.repaired(child, self.current))
        child["steps"] = [{"outcome": "FAIL"}]
        self.assertFalse(host.repaired(child, self.current))

    def test_unknown_cause_started_child_or_missing_proof_is_not_repair(self):
        for change in ({"denial": "[Errno 1] Operation not permitted"},
                       {"executionLaunched": True}, {"childReceiptSha256": "child"},
                       {"outcome": "PASS"}, {"hostEnvironment": None}):
            self.assertFalse(host.repaired({**self.outer, **change}, self.current))

    def test_reboot_unavailable_probe_and_shape_drift_fail_closed(self):
        for change in ({"epoch": "new-boot"}, {"epoch": None}, {"available": False},
                       {"available": 1}, {"errno": errno.EPERM}, {"extra": True},
                       {"operation": "unrelated"}):
            self.assertFalse(host.repaired(self.outer, {**self.current, **change}))
        changed = copy.deepcopy(self.outer)
        changed["hostEnvironment"]["errno"] = True
        self.assertFalse(host.repaired(changed, self.current))

    def test_probe_is_real_fixed_loopback_operation_not_caller_claim(self):
        socket = MagicMock()
        with patch.object(host.socket, "socket", return_value=socket), \
                patch("gambit_smp.research_kernel.clock_epoch", return_value="boot"):
            row = host.observe([{"capability": "quint.verify"}])
        socket.__enter__.return_value.bind.assert_called_once_with(("127.0.0.1", 0))
        self.assertEqual(self.current, row)

    def test_fresh_prelaunch_attempt_has_no_old_clock_but_must_retain_cost(self):
        old = copy.deepcopy(self.outer)
        old["hostEnvironment"]["epoch"] = None
        old.update(wholeSeconds=.4, budgetSeconds=90)
        current = {**self.current, "epoch": "new-boot"}
        self.assertTrue(host.repaired(old, current, fresh_attempt=True))
        self.assertFalse(host.repaired(old, current))
        for spent in (None, 0, True, float("nan"), float("inf"), 91):
            self.assertFalse(host.repaired({**old, "wholeSeconds": spent}, current, fresh_attempt=True))
        self.assertFalse(host.repaired({**old, "executionLaunched": True}, current, fresh_attempt=True))

    def test_refusal_records_actual_errno_and_non_tlc_does_not_probe(self):
        socket = MagicMock()
        socket.__enter__.return_value.bind.side_effect = PermissionError(errno.EPERM, "denied")
        with patch.object(host.socket, "socket", return_value=socket), \
                patch("gambit_smp.research_kernel.clock_epoch", return_value="boot"):
            self.assertEqual(self.old, host.observe([{"capability": "quint.verify"}]))
            socket.reset_mock()
            self.assertIsNone(host.observe([{"capability": "gambit.suite"}]))
            socket.assert_not_called()


if __name__ == "__main__":
    unittest.main()
