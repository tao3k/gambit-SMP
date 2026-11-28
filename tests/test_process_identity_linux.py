"""Linux /proc TOCTOU resilience unit tests for process_identity.pids."""
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp import process_identity


class _FakeProcEntry:
    def __init__(self, name: str, uid: int | None = None, exc: type[BaseException] | None = None):
        self.name = name
        self._uid = uid
        self._exc = exc

    def stat(self):
        if self._exc is not None:
            raise self._exc(f"/proc/{self.name}")
        return SimpleNamespace(st_uid=self._uid)


class LinuxProcCensusResilienceTests(unittest.TestCase):
    def test_vanishing_proc_entry_during_uid_census_does_not_abort(self):
        entries = [
            _FakeProcEntry("101", uid=1000),
            _FakeProcEntry("102", exc=FileNotFoundError),
            _FakeProcEntry("103", exc=ProcessLookupError),
            _FakeProcEntry("104", exc=PermissionError),
            _FakeProcEntry("105", uid=0),
            _FakeProcEntry("106", uid=1000),
            _FakeProcEntry("self", uid=1000),
        ]
        with patch.object(process_identity.sys, "platform", "linux"), \
             patch.object(Path, "iterdir", return_value=iter(entries)):
            self.assertEqual([101, 106], process_identity.pids(uid=1000))


if __name__ == "__main__":
    unittest.main()
