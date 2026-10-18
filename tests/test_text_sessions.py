import copy
import json
import os
import shutil
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, Mock
from ascent import EngineError

from gambit_smp.ascent_program import close_queries, evaluate, load_catalog, load_inert_catalog, engine_api, _query_owners
from gambit_smp.native_support import observe, validate


TEXT = """(ascent-fragment
  (relation Edge ((x exact-integer?) (y exact-integer?)))
  (relation Bad ((x exact-integer?)))
  (relation Path ((x exact-integer?) (y exact-integer?)))
  (relation Safe ((x exact-integer?) (y exact-integer?)))
  ((Path x y) <-- (Edge x y))
  ((Path x z) <-- (Path x y) (Edge y z))
  ((Safe x y) <-- (Path x y) (not (Bad y))))"""

FULL = """(ascent
  (relation Seed ((n integer?)))
  (relation Marker ((n integer?)))
  (relation Packed (value) '((#(2 9)) (#(3 10)) (#(4))))
  (relation Unpacked ((x integer?) (y integer?)))
  (relation Triple ((n integer?)))
  (relation Selected ((n integer?)))
  (relation Count ((n integer?)))
  (relation Pair ((x integer?) (y integer?)))
  (relation BestSeed ((k integer?) (v integer?)) '((0 8) (0 4)))
  (lattice Best ((k integer?) (v integer?)) [] min)
  (macro emit! ((n expr)) (fact (Seed (lit n))))
  (emit! 7)
  (facts (Marker (lit 8)) (Marker (lit 9)))
  (include (ascent-fragment (relation Included ((n integer?)) '((5)))))
  ((Unpacked x y) <-- (Packed value) (match (x y) (value) (vector x y)))
  ((Triple y) <-- (Seed x) (let y (x) (* x 3)))
  ((Selected x) <-- (or (and (Seed x)) (and (Marker x))) (if (x) (odd? x)))
  ((Count n) <-- (aggregate n gerbil-ascent-count () (Selected x)))
  ((Pair x y) <-- (Seed n) (for (x y) (n) (list (vector n (+ n 1))) (vector x y)))
  ((Best k v) <-- (BestSeed k v))
  (bounds 32 64 96))"""


class TypedProofTransportTests(unittest.TestCase):
    """Actual PyO3 proof owner; transport controls, not full DSL qualification."""

    def test_typed_scalar_conclusions_are_not_decoded_as_legacy_symbols(self):
        from ascent import Engine
        from gambit_smp.native_support import close_support
        engine = Engine()
        self.addCleanup(close_support, engine)
        terms = [{"var": "x"}, {"var": "y"}]
        program = {"relations": [
            {"name": "Edge", "source": True, "columns": [{}, {}],
             "rows": [["alpha", "beta"], ["beta", "gamma"]]},
            {"name": "Path", "source": False, "columns": [{}, {}]}],
            "rules": [
                {"head": [{"relation": "Path", "terms": terms}],
                 "body": [{"relation": "Edge", "terms": terms}]}]}
        with patch("gambit_smp.native_support.assemble", return_value=program):
            packet = observe(engine, {}, {}, {"Path": [["alpha", "beta"]]})[0]
        self.assertEqual(packet["status"], "observed")
        self.assertNotIn("symbols", packet)
        conclusion = packet["observations"][0]
        self.assertEqual(conclusion["conclusion"]["atom"], ["Path", "alpha", "beta"])
        self.assertEqual(conclusion["displayAtom"], conclusion["conclusion"]["atom"])
        validate(packet)


class TextSessionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.path = Path(self.temporary.name) / "rules.ss"
        self.path.write_text(TEXT)
        self.addCleanup(close_queries, self.engine)

    def test_nonidentical_queries_retain_the_actual_session(self):
        catalog = load_catalog(self.path)
        facts = {"Edge": [[1, 2], [2, 3]], "Bad": [[3]]}
        first, fresh = evaluate(self.engine, facts, catalog, {"path": "Path"})
        second, reused = evaluate(self.engine, facts, load_catalog(self.path), {"safe": "Safe"})
        self.assertEqual([(1, 2), (1, 3), (2, 3)], first["path"])
        self.assertEqual([(1, 2)], second["safe"])
        self.assertFalse(fresh["nativeResultReused"])
        self.assertTrue(reused["nativeResultReused"])
        self.assertEqual(fresh["sourceGeneration"], reused["sourceGeneration"])
        self.assertEqual(fresh["nativeRunIndex"] + 1, reused["nativeRunIndex"])
        self.assertEqual(1, len(_query_owners.get(self.engine, {})))

    def test_explicit_inert_entry_matches_full_dsl_and_retains_withdrawal(self):
        facts = {'Edge': [[1, 2], [2, 3]], 'Bad': [[3]]}
        queries = {'path': 'Path', 'safe': 'Safe'}
        expected, _ = evaluate(self.engine, facts, load_catalog(self.path), queries)
        actual, first = evaluate(self.engine, facts, load_inert_catalog(self.path), queries)
        self.assertEqual(expected, actual)
        self.assertEqual('inert-relational-subset.v1', first['ruleSyntax'])
        repeated, second = evaluate(self.engine, facts, load_inert_catalog(self.path), queries)
        self.assertEqual(expected, repeated)
        self.assertTrue(second['nativeResultReused'])
        self.assertEqual(first['sessionOwner'], second['sessionOwner'])
        withdrawn, third = evaluate(self.engine, {'Edge': [], 'Bad': []},
                                   load_inert_catalog(self.path), queries)
        self.assertEqual({'path': [], 'safe': []}, withdrawn)
        self.assertGreater(third['sourceGeneration'], second['sourceGeneration'])
        bound = load_inert_catalog(self.path)
        self.path.write_text(TEXT + '\n; changed source\n')
        with self.assertRaisesRegex(ValueError, 'source generation changed'):
            evaluate(self.engine, facts, bound, queries,
                     reuse_program=True)

    def test_inert_source_contract_retains_recursive_answers_and_withdrawal(self):
        catalog = load_inert_catalog(self.path)
        facts = {'Edge': [[1, 2], [2, 3]], 'Bad': [[3]]}
        queries = {'path': 'Path', 'safe': 'Safe'}
        first, before = evaluate(self.engine, facts, catalog, queries)
        self.assertEqual({'path': [(1, 2), (1, 3), (2, 3)], 'safe': [(1, 2)]}, first)
        second, reused = evaluate(self.engine, facts, catalog, queries)
        self.assertEqual(first, second)
        self.assertEqual(before['sessionOwner'], reused['sessionOwner'])
        self.assertTrue(reused['nativeResultReused'])
        old_result = next(iter(_query_owners.get(self.engine, {}).values())).last_result
        withdrawn, after = evaluate(self.engine, {'Edge': [], 'Bad': []}, catalog, queries)
        self.assertEqual({'path': [], 'safe': []}, withdrawn)
        self.assertGreater(after['sourceGeneration'], reused['sourceGeneration'])
        with self.assertRaisesRegex(ValueError, 'native result released'):
            old_result.rows('Path')
        self.path.write_text(TEXT + '\n; drift\n')
        with self.assertRaisesRegex(ValueError, 'source generation changed'):
            evaluate(self.engine, facts, catalog, queries)
        self.assertEqual({}, _query_owners.get(self.engine, {}))

    def test_inert_source_contract_rejects_executable_syntax_without_downgrade(self):
        from ascent import EngineError
        self.path.write_text(FULL)
        with self.assertRaisesRegex(EngineError, 'typed ASCENT relation declaration'):
            evaluate(self.engine, {}, load_inert_catalog(self.path), {'seed': 'Seed'})
        self.assertEqual({}, _query_owners.get(self.engine, {}))

    def test_evidence_reuse_rebinds_sources_without_reexpanding(self):
        from gambit_smp.ascent_program import load_evidence_catalog
        source = """(define-evidence (make-check)
          (sources Seed) (outputs Answer)
          (relation Seed ((n integer?))) (relation Answer ((n integer?)))
          ((Answer n) <-- (Seed n)))"""
        self.path.write_text(source)
        first_catalog = load_evidence_catalog(self.path, constructor="make-check", trusted=True)
        answers, first = evaluate(self.engine, {"Seed": [[7]]}, first_catalog,
                                  {"answer": "Answer"}, reuse_program=True)
        other = self.path.with_name("rebound.ss")
        other.write_text(source)
        rebound = load_evidence_catalog(other, constructor="make-check", trusted=True)
        changed, second = evaluate(self.engine, {"Seed": []}, rebound,
                                   {"answer": "Answer"}, reuse_program=True)
        self.assertEqual([(7,)], answers["answer"])
        self.assertEqual([], changed["answer"])
        self.assertEqual(first["sessionOwner"], second["sessionOwner"])
        self.assertGreater(second["sourceGeneration"], first["sourceGeneration"])
        self.assertEqual(rebound["sourceInputs"], second["ruleSourceInputs"])
        other.write_text(source + "\n; drift\n")
        with self.assertRaisesRegex(ValueError, "source generation changed"):
            evaluate(self.engine, {"Seed": [[9]]}, rebound, {"answer": "Answer"}, reuse_program=True)

    def test_source_withdrawal_invalidates_results_and_bad_requests_release_owner(self):
        catalog = load_catalog(self.path)
        evaluate(self.engine, {"Edge": [[1, 2]], "Bad": []}, catalog, {"path": "Path"})
        withdrawn, metrics = evaluate(self.engine, {"Edge": [], "Bad": []}, catalog, {"path": "Path"})
        self.assertEqual([], withdrawn["path"])
        self.assertFalse(metrics["nativeResultReused"])
        with self.assertRaises(Exception):
            evaluate(self.engine, {"Edge": [[True, 2]], "Bad": []}, catalog, {"path": "Path"})
        self.assertEqual({}, _query_owners.get(self.engine, {}))
        evaluate(self.engine, {"Edge": [], "Bad": []}, catalog, {"path": "Path"})
        self.path.write_text(TEXT + "\n; new source generation\n")
        with self.assertRaisesRegex(ValueError, "source generation changed"):
            evaluate(self.engine, {"Edge": [], "Bad": []}, catalog, {"path": "Path"})
        self.assertEqual({}, _query_owners.get(self.engine, {}))

    def test_history_components_rebind_all_paths_and_withdraw_results(self):
        from gambit_smp.ascent_program import load_component_catalog
        from gambit_smp.framework import ROOT
        first_root = Path(self.temporary.name) / "first"
        second_root = Path(self.temporary.name) / "second"
        shutil.copytree(ROOT / "evidence/dsl", first_root)
        shutil.copytree(first_root, second_root)

        def catalog(root):
            return load_component_catalog(root / "components.json", entry="history",
                                          constructor="make-history", trusted=True)

        previous = catalog(first_root)
        current = catalog(second_root)
        rows, before = evaluate(self.engine, {"current_row": [["q", "r"]]}, previous,
                                {"added": "added", "removed": "removed"}, reuse_program=True)
        old_result = next(iter(_query_owners.get(self.engine, {}).values())).last_result
        withdrawn, after = evaluate(self.engine, {"current_row": [], "previous_row": [["q", "r"]]},
                                    current, {"added": "added", "removed": "removed"}, reuse_program=True)
        self.assertEqual([("q", "r")], rows["added"])
        self.assertEqual([], withdrawn["added"])
        self.assertEqual([("q", "r")], withdrawn["removed"])
        self.assertEqual(before["sessionOwner"], after["sessionOwner"])
        self.assertGreater(after["sourceGeneration"], before["sourceGeneration"])
        self.assertTrue(after["sourceContextRebound"])
        self.assertEqual(current["sourceInputs"], after["ruleSourceInputs"])
        with self.assertRaisesRegex(ValueError, "native result released"):
            old_result.rows("added")
        # Unselected source bytes are not support for this native history scope.
        (second_root / "catalog.ss").write_text("; drift\n")
        independent, _ = evaluate(self.engine, {}, current, {"added": "added"}, reuse_program=True)
        self.assertEqual(independent["added"], [])
        (second_root / "history.ss").write_text("; selected source drift\n")
        with self.assertRaisesRegex(ValueError, "source generation changed"):
            evaluate(self.engine, {}, current, {"added": "added"}, reuse_program=True)
        self.assertEqual({}, _query_owners.get(self.engine, {}))

    def test_explicit_program_reuse_rebinds_full_sources_and_invalidates_old_results(self):
        first_catalog = load_catalog(self.path)
        facts = {"Edge": [[1, 2]], "Bad": []}
        first, before = evaluate(self.engine, facts, first_catalog, {"path": "Path"}, reuse_program=True)
        old_proof = observe(self.engine, facts, first_catalog, {"Path": [[1, 2]]},
                            generation=before["sourceGeneration"])[0]
        old_result = next(iter(_query_owners.get(self.engine, {}).values())).last_result
        other = Path(self.temporary.name) / "other.ss"
        other.write_text(TEXT)
        current_catalog = load_catalog(other)
        second, after = evaluate(self.engine, facts, current_catalog, {"path": "Path"}, reuse_program=True)
        self.assertEqual(first, second)
        self.assertEqual(before["sessionOwner"], after["sessionOwner"])
        self.assertGreater(after["sourceGeneration"], before["sourceGeneration"])
        self.assertTrue(after["sourceContextRebound"])
        self.assertEqual(current_catalog["sourceInputs"], after["ruleSourceInputs"])
        self.assertEqual({str(self.path.resolve())}, set(first_catalog["sourceInputs"]))
        current_proof = observe(self.engine, facts, current_catalog, {"Path": [[1, 2]]},
                                generation=after["sourceGeneration"])[0]
        self.assertEqual("observed", current_proof["status"])
        self.assertFalse(current_proof["nativeResolution"]["reused"])
        self.assertNotEqual(old_proof["scope"], current_proof["scope"])
        self.assertEqual(first_catalog["sourceInputs"], old_proof["ruleSourceInputs"])
        self.assertEqual(current_catalog["sourceInputs"], current_proof["ruleSourceInputs"])
        validate(old_proof)
        validate(current_proof)
        with self.assertRaisesRegex(ValueError, "native result released"):
            old_result.rows("Path")
        other.write_text(TEXT + "\n; changed current source\n")
        with self.assertRaisesRegex(ValueError, "source generation changed"):
            evaluate(self.engine, facts, current_catalog, {"path": "Path"}, reuse_program=True)
        self.assertEqual({}, _query_owners.get(self.engine, {}))

    def test_program_reuse_is_opt_in_and_requires_identical_source_bytes(self):
        facts = {"Edge": [[1, 2]], "Bad": []}
        _, first = evaluate(self.engine, facts, load_catalog(self.path), {"path": "Path"})
        other = Path(self.temporary.name) / "other.ss"
        other.write_text(TEXT)
        _, second = evaluate(self.engine, facts, load_catalog(other), {"path": "Path"})
        self.assertNotEqual(first["sessionOwner"], second["sessionOwner"])
        close_queries(self.engine)
        _, first = evaluate(self.engine, facts, load_catalog(self.path), {"path": "Path"}, reuse_program=True)
        other.write_text(TEXT + "\n; distinct source bytes\n")
        _, second = evaluate(self.engine, facts, load_catalog(other), {"path": "Path"}, reuse_program=True)
        self.assertNotEqual(first["sessionOwner"], second["sessionOwner"])
        self.assertFalse(second["sourceContextRebound"])

    def test_native_deadline_is_incomplete_and_session_can_be_closed(self):
        pending = TEXT.replace('(relation Edge ((x exact-integer?) (y exact-integer?)))',
                               "(relation Edge ((x exact-integer?) (y exact-integer?)) '((1 2) (2 3)))")
        with self.engine.open_sources(pending) as session:
            with self.assertRaisesRegex(EngineError, "deadline"):
                session.run(0, queries=["Path"])
            result = session.run(queries=["Path"])
            self.assertTrue(result["complete"])
        with self.assertRaisesRegex(EngineError, "owner closed"):
            session.run()

    def test_full_native_lowering_without_consumer_import_or_compiler(self):
        self.path.write_text(FULL)
        with patch.dict(os.environ, {"PATH": "/unavailable", "GERBIL_PATH": "/unavailable", "GERBIL_HOME": "/unavailable"}), \
                patch("subprocess.Popen", side_effect=AssertionError("consumer launched a compiler")):
            catalog = load_catalog(self.path)
            rows, metrics = evaluate(self.engine, {}, catalog,
                {name: name for name in ("Unpacked", "Triple", "Selected", "Count", "Pair", "Best", "Included")})
        self.assertEqual([(2, 9), (3, 10)], rows["Unpacked"])
        self.assertEqual([(21,)], rows["Triple"])
        self.assertEqual([(7,), (9,)], rows["Selected"])
        self.assertEqual([(2,)], rows["Count"])
        self.assertEqual([(7, 8)], rows["Pair"])
        self.assertEqual([(0, 4)], rows["Best"])
        self.assertEqual([(5,)], rows["Included"])
        self.assertEqual("upstream-ascent-dsl.v1", metrics["ruleSyntax"])
        self.assertEqual("supported", catalog["projection"]["status"])
        # The new closed kernels must survive the actual structured projection,
        # not merely change a capability label after producing direct answers.
        with self.engine.open(catalog['projection']['program']) as projected:
            receipt = projected.run()
            result = projected.result(receipt)
            try:
                for name, expected in rows.items():
                    self.assertEqual(result.rows(name)['rows'], [list(row) for row in expected])
            finally:
                result.close()

    def test_native_ancestor_proofs_reuse_store_and_bind_generation(self):
        catalog = load_catalog(self.path)
        facts = {"Edge": [[1, 2], [2, 3]], "Bad": []}
        _, metrics = evaluate(self.engine, facts, catalog, {"path": "Path"})
        first = observe(self.engine, facts, catalog, {"Path": [[1, 3]]}, generation=metrics["sourceGeneration"])[0]
        second = observe(self.engine, facts, catalog, {"Path": [[1, 2]]}, generation=metrics["sourceGeneration"])[0]
        self.assertEqual("observed", first["status"])
        self.assertFalse(first["nativeResolution"]["reused"])
        self.assertTrue(second["nativeResolution"]["reused"])
        self.assertEqual(first["nativeResolution"]["handle"], second["nativeResolution"]["handle"])
        validate(first)
        broken = copy.deepcopy(first)
        broken["supportNodes"].pop(0)
        with self.assertRaises(ValueError):
            validate(broken)
        changed = observe(self.engine, facts, catalog, {"Path": [[1, 3]]}, generation=metrics["sourceGeneration"] + 1)[0]
        self.assertFalse(changed["nativeResolution"]["reused"])
        self.assertNotEqual(first["scope"], changed["scope"])

    def test_proof_rejection_keeps_complete_sources_and_never_retries_batch(self):
        from ascent import EngineError
        catalog = load_catalog(self.path)
        facts = {"Edge": [[1, 2], [2, 3]], "Bad": []}
        answers, _ = evaluate(self.engine, facts, catalog, {"path": "Path"})
        from gambit_smp import native_support
        native_support.close_support(self.engine)
        rejected_store = Mock()
        rejected_store.resolve.side_effect = EngineError("proof material rejected")
        with patch.dict(native_support._stores, {self.engine: rejected_store}):
            packets = observe(self.engine, facts, catalog,
                              {"Path": [[1, 3]], "Edge": [[1, 2]]}, generation=7)
        self.assertEqual(1, rejected_store.resolve.call_count)
        rejected_store.close.assert_called_once_with()
        self.assertEqual(2, len(packets))
        self.assertEqual([(1, 2), (1, 3), (2, 3)], answers["path"])
        for packet in packets:
            self.assertEqual("unknown", packet["status"])
            self.assertIn("proof material rejected", packet["nativeError"])
            self.assertEqual(7, packet["source"]["generation"])
            self.assertTrue(packet["source"]["relations"])
            self.assertFalse(packet["runtimeAdmitted"])
            self.assertFalse(packet["executionAuthorized"])
            validate(packet)
        self.assertNotIn(self.engine, native_support._stores)


if __name__ == "__main__":
    unittest.main()
