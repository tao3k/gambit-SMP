import copy
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.ascent_program import close_queries, evaluate, load_catalog, engine_api
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
        self.assertEqual(1, len(self.engine._gambit_query_owners))

    def test_source_withdrawal_invalidates_results_and_bad_requests_release_owner(self):
        catalog = load_catalog(self.path)
        evaluate(self.engine, {"Edge": [[1, 2]], "Bad": []}, catalog, {"path": "Path"})
        withdrawn, metrics = evaluate(self.engine, {"Edge": [], "Bad": []}, catalog, {"path": "Path"})
        self.assertEqual([], withdrawn["path"])
        self.assertFalse(metrics["nativeResultReused"])
        with self.assertRaises(Exception):
            evaluate(self.engine, {"Edge": [[True, 2]], "Bad": []}, catalog, {"path": "Path"})
        self.assertEqual({}, self.engine._gambit_query_owners)
        evaluate(self.engine, {"Edge": [], "Bad": []}, catalog, {"path": "Path"})
        self.path.write_text(TEXT + "\n; new source generation\n")
        with self.assertRaisesRegex(ValueError, "source generation changed"):
            evaluate(self.engine, {"Edge": [], "Bad": []}, catalog, {"path": "Path"})
        self.assertEqual({}, self.engine._gambit_query_owners)

    def test_native_deadline_is_incomplete_and_session_can_be_closed(self):
        pending = TEXT.replace('(relation Edge ((x exact-integer?) (y exact-integer?)))',
                               "(relation Edge ((x exact-integer?) (y exact-integer?)) '((1 2) (2 3)))")
        with self.engine.open_sources(pending) as session:
            result = session.run(0, queries=["Path"])
            self.assertFalse(result["complete"])
            self.assertFalse(result["nativeResultReused"])
        with self.assertRaisesRegex(ValueError, "session closed"):
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
        self.assertEqual("unsupported", catalog["projection"]["status"])

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


if __name__ == "__main__":
    unittest.main()
