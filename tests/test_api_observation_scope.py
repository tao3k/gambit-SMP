"""One checked API observation spans nested Library loads, never later requests."""
from contextlib import ExitStack
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

from gambit_smp import ascent_program as api
from gambit_smp.framework import digest


class ApiObservationScopeTests(unittest.TestCase):
    def setUp(self):
        stack = ExitStack()
        self.addCleanup(stack.close)
        directory = stack.enter_context(tempfile.TemporaryDirectory())
        self.source = Path(directory) / "extension"
        self.source.write_bytes(b"not executable; identity-only host fixture")
        self.files = {"ascent._core": self.source}
        build = dict(schema="ascent.rust-build.v1", rayon=True,
                     extensionSha256=digest(self.source), sourceInputs={},
                     runtimeInputs={}, installedInputs={})
        stack.enter_context(patch.object(api, "_api_inventory", return_value=(self.files, build, "receipt")))
        stack.enter_context(patch.object(api, "artifact_paths", return_value=self.files))
        stack.enter_context(patch.object(api, "_loaded_identity", None))
        self.hashes = stack.enter_context(patch.object(api, "_file_identities", wraps=api._file_identities))
        self.engine = Mock()
        self.outer_scope = api._active_api.get()

    def test_nested_loads_hash_at_outer_entry_and_exit_and_later_requests_recheck(self):
        with api.engine_api(engine=self.engine):
            with api.engine_api(engine=self.engine):
                with api.engine_api(engine=self.engine):
                    self.assertEqual(self.hashes.call_count, 1)
            self.assertEqual(self.hashes.call_count, 1)
        self.assertEqual(self.hashes.call_count, 2)
        self.assertIs(api._active_api.get(), self.outer_scope)
        with api.engine_api(engine=self.engine):
            pass
        self.assertEqual(self.hashes.call_count, 4)

    def test_nested_mutation_is_rejected_by_outer_boundary_and_context_is_released(self):
        with self.assertRaisesRegex(ValueError, "changed during audit"):
            with api.engine_api(engine=self.engine):
                with api.engine_api(engine=self.engine):
                    self.source.write_bytes(b"changed during the request")
        self.assertIs(api._active_api.get(), self.outer_scope)
        self.assertEqual(self.hashes.call_count, 2)

    def test_exception_unwinds_and_still_checks_the_outer_identity(self):
        with self.assertRaisesRegex(RuntimeError, "caller failed"):
            with api.engine_api(engine=self.engine):
                with api.engine_api(engine=self.engine):
                    raise RuntimeError("caller failed")
        self.assertIs(api._active_api.get(), self.outer_scope)
        self.assertEqual(self.hashes.call_count, 2)

    def test_inherited_scope_cannot_reuse_another_process_or_thread_observation(self):
        for field in ("pid", "thread"):
            with self.subTest(field=field):
                self.hashes.reset_mock()
                with api.engine_api(engine=self.engine):
                    target = "os.getpid" if field == "pid" else "threading.get_ident"
                    with patch("gambit_smp.ascent_program." + target, return_value=-1):
                        with api.engine_api(engine=self.engine):
                            pass
                self.assertEqual(self.hashes.call_count, 4)


if __name__ == "__main__":
    unittest.main()
