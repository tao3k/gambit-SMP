import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from ascent import Engine, EngineError, FactLimits
from gambit_smp import ascent_program as api

DSL = """(def (make-test)
  (make-recorded-module (ascent-fragment
    (relation input ((x exact-integer?)))
    (relation output ((x exact-integer?)))
    ((output X) <-- (input X))) '(input)))"""


class RetainedEngineApiTests(unittest.TestCase):
    def setUp(self):
        api.close_retained_queries()
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.addCleanup(api.close_retained_queries)
        self.path = Path(self.temp.name) / "rules.ss"
        self.path.write_text(DSL)

    def catalog(self, path=None, limits=None):
        return api.load_evidence_catalog(path or self.path, constructor="make-test",
                                         trusted=True, limits=limits)

    def query(self, facts=None, catalog=None):
        metrics = {}
        answers = api.query(facts if facts is not None else {"input": [[1], [2]]},
                            catalog or self.catalog(), {"answer": "output"}, metrics=metrics)
        return answers, metrics

    def test_default_calls_reuse_actual_engine_and_session(self):
        first, before = self.query()
        owner = next(iter(api._query_owners[api._retained_engine].values()))
        second, after = self.query()
        self.assertEqual(first, second)
        self.assertIs(owner, next(iter(api._query_owners[api._retained_engine].values())))
        self.assertEqual(before["sessionOwner"], after["sessionOwner"])
        self.assertTrue(after["nativeResultReused"])
        self.assertEqual(before["investigationRound"] + 1, after["investigationRound"])

    def test_withdrawal_and_restoration_use_same_session(self):
        _, first = self.query()
        reduced, second = self.query({"input": [[2]]})
        restored, third = self.query()
        self.assertEqual({"answer": [(2,)]}, reduced)
        self.assertEqual({"answer": [(1,), (2,)]}, restored)
        self.assertEqual(first["sessionOwner"], third["sessionOwner"])
        self.assertEqual(first["sourceGeneration"] + 1, second["sourceGeneration"])
        self.assertEqual(second["sourceGeneration"] + 1, third["sourceGeneration"])

    def test_explicit_release_reopens_without_runtime_shutdown(self):
        _, first = self.query()
        engine = api._retained_engine
        api.close_retained_queries()
        self.assertFalse(engine.closed)
        self.assertNotIn(engine, api._query_owners)
        _, second = self.query()
        self.assertIs(engine, api._retained_engine)
        self.assertNotEqual(first["sessionOwner"], second["sessionOwner"])

    def test_exception_releases_retained_query_owners(self):
        self.query()
        with self.assertRaisesRegex(RuntimeError, "caller failed"):
            with api.engine_api(retain=True):
                raise RuntimeError("caller failed")
        self.assertNotIn(api._retained_engine, api._query_owners)
        self.assertEqual({"answer": [(1,), (2,)]}, self.query()[0])

    def test_source_same_size_and_restored_mtime_still_rejects(self):
        catalog = self.catalog()
        self.query(catalog=catalog)
        state = self.path.stat()
        self.path.write_text(DSL.replace("input", "inPut"))
        os.utime(self.path, ns=(state.st_atime_ns, state.st_mtime_ns))
        with self.assertRaisesRegex(ValueError, "source generation changed"):
            self.query(catalog=catalog)
        self.assertEqual({}, api._query_owners.get(api._retained_engine, {}))

    def test_changed_definition_gets_fresh_hygienic_scope(self):
        _, first = self.query()
        self.path.write_text(DSL + "\n(def marker 42)\n")
        result, second = self.query()
        self.assertEqual({"answer": [(1,), (2,)]}, result)
        self.assertNotEqual(first["sessionOwner"], second["sessionOwner"])

    def test_caller_policy_is_not_reused_across_ceilings(self):
        self.query()
        with self.assertRaises(EngineError):
            self.query(catalog=self.catalog(limits=FactLimits(input=1)))
        answers, metrics = self.query()
        self.assertEqual({"answer": [(1,), (2,)]}, answers)
        self.assertEqual("unlimited", metrics["nativeFactLimits"]["input"])

    def test_owner_cache_is_bounded_and_recently_used_survives(self):
        paths = []
        handles = []
        for index in range(4):
            path = Path(self.temp.name) / (str(index) + ".ss")
            path.write_text(DSL)
            paths.append(path)
            handles.append(self.query(catalog=self.catalog(path))[1]["sessionOwner"])
        self.query(catalog=self.catalog(paths[0]))
        fifth = Path(self.temp.name) / "4.ss"
        fifth.write_text(DSL)
        self.query(catalog=self.catalog(fifth))
        self.assertEqual(4, len(api._query_owners[api._retained_engine]))
        self.assertEqual(handles[0], self.query(catalog=self.catalog(paths[0]))[1]["sessionOwner"])
        self.assertNotEqual(handles[1], self.query(catalog=self.catalog(paths[1]))[1]["sessionOwner"])

    def test_api_boundary_hashes_content_even_with_restored_metadata(self):
        self.query()
        files, build, receipt_sha = api._api_inventory()
        marker = Path(self.temp.name) / "backend"
        marker.write_text("aaaa")
        files["test-backend"] = marker
        with patch.object(api, "_api_inventory", return_value=(files, build, receipt_sha)), \
                patch.object(api, "_loaded_identity", None):
            with self.assertRaisesRegex(ValueError, "implementation changed during audit"):
                with api.engine_api(engine=api._retained_engine):
                    state = marker.stat()
                    marker.write_text("bbbb")
                    os.utime(marker, ns=(state.st_atime_ns, state.st_mtime_ns))

    def test_inventory_cache_reuses_metadata_not_file_hashes_or_mutable_paths(self):
        first = api.artifact_paths()
        second = api.artifact_paths()
        self.assertEqual(first, second)
        self.assertIn('ascent._core', second)
        first.clear()
        self.assertEqual(second, api.artifact_paths())

    def test_retain_flag_is_explicit_boolean(self):
        with self.assertRaisesRegex(ValueError, "retain must be a boolean"):
            with api.engine_api(retain="yes"):
                self.fail("invalid retention policy entered")


if __name__ == "__main__":
    unittest.main()
