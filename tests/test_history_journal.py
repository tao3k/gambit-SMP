"""Journal transport faults paired with actual Library Evidence inference."""
import json
from pathlib import Path
import tempfile
import subprocess
import unittest
from unittest.mock import patch

from gambit_smp import reasoning_history as history
from gambit_smp.ascent_program import load_component_catalog, query


class HistoryJournalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = load_component_catalog(history.RULES.parent / "components.json",
                                             entry="history", constructor="make-history", trusted=True)
        cls.backend = {}
        query({}, cls.catalog, history.QUERIES, metrics=cls.backend)

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)

    def append(self, value, scope="task"):
        return history.append_observation(self.root, scope, {"fixture": value},
                                          {"claim": [[value]]}, self.backend)

    def bodies(self, table):
        with history._database(self.root) as db:
            return [json.loads(row[0]) for row in db.execute("SELECT body FROM " + table)]

    def test_append_survives_restart_without_analysis_or_head(self):
        observation = self.append("known-failure")
        with history._database(self.root) as db:
            self.assertIsNone(history._head(db, "task"))
        self.assertEqual(self.bodies("observations")[0]["queries"],
                         {"claim": ['["known-failure"]']})
        result = history.analyze_observation(self.root, observation)
        self.assertEqual(result["delta"]["added"], [("claim", ["known-failure"])])
        self.assertFalse(result["runtimeAdmitted"])

    def test_real_finite_denial_retains_new_observation_and_prior_head(self):
        from ascent import FactLimits, EngineError
        first = history.analyze_observation(self.root, self.append("before"))
        observation = self.append("after")
        with self.assertRaises(EngineError):
            history.analyze_observation(self.root, observation, limits=FactLimits(input=1))
        with history._database(self.root) as db:
            self.assertEqual(history._head(db, "task"), first["observation"])
        self.assertEqual(len(self.bodies("observations")), 2)
        failed = self.bodies("analysis_results")[-1]
        self.assertEqual(failed["observation"], observation)
        self.assertEqual(failed["status"], "failed")
        self.assertNotIn("exit", failed)
        self.assertNotIn("timeout", failed)
        journal = history.read_journal(self.root, "task")
        self.assertEqual(len(journal["observations"]), 2)
        self.assertEqual(len(journal["events"]), 2)
        self.assertEqual(journal["head"], first["observation"])

    def test_failed_loading_is_retained_and_interrupted_request_stays_pending(self):
        observation = self.append("load-failure")
        with patch.object(history, "load_component_catalog", side_effect=OSError("unavailable source")):
            with self.assertRaises(OSError):
                history.analyze_observation(self.root, observation)
        pending, _ = history._prepare(self.root, observation, None, None)
        with history._database(self.root) as db:
            self.assertIsNone(history._head(db, "task"))
            self.assertIsNone(db.execute("SELECT id FROM analysis_results WHERE attempt=?", (pending,)).fetchone())
        self.assertEqual(len(self.bodies("analysis_requests")), 2)
        self.assertEqual(len(self.bodies("analysis_results")), 1)
        self.assertEqual(history.read_journal(self.root, "task")["pendingAttempts"], [pending])

    def test_sql_cas_rejects_competing_publication_after_native_eligibility(self):
        first = self.append("first")
        second = self.append("competitor")
        publish = history._publish
        winner = []
        def competing(root, attempt, request, analysis):
            with patch.object(history, "_publish", publish):
                winner.append(history.analyze_observation(root, second))
            publish(root, attempt, request, analysis)
        with patch.object(history, "_publish", competing):
            with self.assertRaisesRegex(ValueError, "concurrent"):
                history.analyze_observation(self.root, first)
        with history._database(self.root) as db:
            self.assertEqual(history._head(db, "task"), winner[0]["observation"])
        self.assertEqual({row["status"] for row in self.bodies("analysis_results")}, {"failed", "published"})

    def test_same_observation_republication_changes_cas_generation(self):
        observation = self.append("same")
        history.analyze_observation(self.root, observation)
        publish = history._publish
        def competing(root, attempt, request, analysis):
            with patch.object(history, "_publish", publish):
                history.analyze_observation(root, observation)
            publish(root, attempt, request, analysis)
        with patch.object(history, "_publish", competing):
            with self.assertRaisesRegex(ValueError, "concurrent"):
                history.analyze_observation(self.root, observation)
        journal = history.read_journal(self.root, "task")
        self.assertEqual(journal["head"], observation)
        self.assertEqual(len(journal["results"]), 3)

    def test_legacy_fork_preserves_original_identity_and_inventory_growth_lineage(self):
        old = dict(schema="gambit-reasoning-observation.v1", scope="inventory-v1",
                   inputs={"fixture": "old"}, backendInputs=self.backend["inputs"],
                   queries={"claim": ['["old"]']})
        identity = history.fingerprint(old)
        encoded = history.canonical(old)
        with history._database(self.root) as db:
            db.execute("INSERT INTO observations VALUES (?,?)", (identity, encoded))
            db.execute("INSERT INTO heads VALUES (?,?)", (old["scope"], identity))
        scope = history.lineage("review", task="task", branch="branch")
        first = history.analyze_observation(self.root, self.append("one", scope), legacy_scope=old["scope"])
        second = history.analyze_observation(self.root, self.append("two", scope), legacy_scope="inventory-v2")
        self.assertEqual(first["previousObservation"], identity)
        self.assertEqual(second["previousObservation"], first["observation"])
        self.assertEqual(second["lineage"], scope)
        with history._database(self.root) as db:
            self.assertEqual(history._head(db, old["scope"]), identity)
            self.assertEqual(db.execute("SELECT body FROM observations WHERE id=?", (identity,)).fetchone()[0], encoded)

    def test_explicit_fork_can_read_non_head_published_parent(self):
        first = history.analyze_observation(self.root, self.append("first"))
        newer = history.analyze_observation(self.root, self.append("new-head"))
        history.fork_lineage(self.root, "fork", parent_scope="task", parent_observation=first["observation"])
        result = history.analyze_observation(self.root, self.append("fork-value", "fork"))
        self.assertEqual(result["previousObservation"], first["observation"])
        self.assertEqual(result["delta"]["removed"], [("claim", ["first"])])
        with self.assertRaisesRegex(ValueError, "different parent"):
            history.fork_lineage(self.root, "fork", parent_scope="task", parent_observation=newer["observation"])

    def test_fork_keeps_exact_analysis_generation_after_parent_republication(self):
        observation = self.append("same-parent")
        first = history.analyze_observation(self.root, observation)
        history.fork_lineage(self.root, "fork", parent_scope="task", parent_observation=observation)
        newer = history.analyze_observation(self.root, observation)
        child = history.analyze_observation(self.root, self.append("child", "fork"))
        self.assertNotEqual(first["attempt"], newer["attempt"])
        self.assertEqual(child["previousAnalysis"], first["attempt"])
        self.assertEqual(history.read_journal(self.root, "task")["headAnalysis"], newer["attempt"])

    def test_unbound_observation_is_recorded_only_and_failed_analysis_is_not_a_pass(self):
        observation = history.append_observation(self.root, "task", {}, {"claim": [["reported"]]}, {})
        with self.assertRaisesRegex(ValueError, "identity-bound"):
            history.analyze_observation(self.root, observation)
        self.assertEqual(len(self.bodies("observation_events")), 1)
        self.assertFalse(self.bodies("analysis_results")[0]["runtimeAdmitted"])

    def test_actual_dsl_rejects_each_missing_publication_premise(self):
        facts = dict(proposal=[("attempt", "observation")], expected_parent=[("attempt", "parent")],
                     observed_parent=[("parent",)], completed=[("attempt",)],
                     source_checked=[("attempt",)], backend_checked=[("attempt",)])
        for source, gap in (("completed", "comparison-incomplete"), ("source_checked", "source-unchecked"),
                            ("backend_checked", "backend-unchecked"), ("observed_parent", "parent-changed")):
            answer = query({**facts, source: []}, self.catalog, history.POLICY_QUERIES)
            self.assertEqual(answer["eligible"], [])
            self.assertIn(("attempt", gap), answer["gaps"])
        answer = query(facts, self.catalog, history.POLICY_QUERIES)
        self.assertEqual(answer["eligible"], [("attempt", "observation")])
        self.assertEqual(answer["gaps"], [])

    def test_repeat_retains_each_raw_metrics_event_without_unstable_content_identity(self):
        first = self.append("same")
        second = history.append_observation(self.root, "task", {"fixture": "same"}, {"claim": [["same"]]},
                                            {**self.backend, "seconds": 999, "reportedExit": -9})
        self.assertEqual(first, second)
        events = self.bodies("observation_events")
        self.assertEqual(len(events), 2)
        self.assertEqual(events[-1]["backend"]["reportedExit"], -9)

    def test_actual_bound_source_drift_is_retained_without_publication(self):
        from gambit_smp.framework import digest
        source = self.root / "fixture.json"
        source.write_text('{"actual":"before"}')
        inputs = {source.name: digest(source)}
        with self.assertRaisesRegex(ValueError, "differs from observation"):
            history.append_observation(self.root, "task", inputs, {}, self.backend,
                                       bound_inputs={source.name: "invented"})
        observation = history.append_observation(self.root, "task", inputs, {"claim": [["before"]]},
                                                  self.backend, bound_inputs=inputs)
        source.write_text('{"actual":"after"}')
        with self.assertRaisesRegex(ValueError, "source inputs changed"):
            history.analyze_observation(self.root, observation)
        journal = history.read_journal(self.root, "task")
        self.assertIsNone(journal["head"])
        self.assertEqual(journal["observations"][observation]["boundInputs"], inputs)
        self.assertEqual(next(iter(journal["results"].values()))["body"]["status"], "failed")

    def test_lineage_change_after_inference_cannot_publish(self):
        publish = history._publish
        def drift(root, attempt, request, analysis):
            with history._database(root) as db:
                changed = {**request["lineage"], "parentScope": "tampered"}
                db.execute("UPDATE lineages SET body=? WHERE scope=?",
                           (history.canonical(changed), request["scope"]))
            publish(root, attempt, request, analysis)
        with patch.object(history, "_publish", drift):
            with self.assertRaisesRegex(ValueError, "lineage changed"):
                history.analyze_observation(self.root, self.append("retained"))
        journal = history.read_journal(self.root, "task")
        self.assertIsNone(journal["head"])
        self.assertEqual(len(journal["observations"]), 1)
        self.assertEqual(next(iter(journal["results"].values()))["body"]["status"], "failed")

    def test_readback_rejects_missing_or_mismatched_head_analysis(self):
        result = history.analyze_observation(self.root, self.append("published"))
        with history._database(self.root) as db:
            db.execute("UPDATE head_analyses SET attempt='missing' WHERE scope='task'")
        with self.assertRaisesRegex(ValueError, "head analysis mismatch"):
            history.read_journal(self.root, "task")
        with history._database(self.root) as db:
            db.execute("DELETE FROM head_analyses WHERE scope='task'")
        with self.assertRaisesRegex(ValueError, "lacks published analysis"):
            history.read_journal(self.root, "task")
        with self.assertRaisesRegex(ValueError, "distinct"):
            history.fork_lineage(self.root, "task", parent_scope="task", parent_observation=result["observation"])


if __name__ == "__main__":
    unittest.main()
