"""Durable SMP attempt transport and non-authorizing upstream projection."""
from contextlib import closing
import json
import sqlite3
from pathlib import Path
import subprocess
import sys
import tempfile
import types
import unittest
import uuid
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.reasoning_history import (append_trajectory_attempt,
                                          read_trajectory_attempts)
from gambit_smp.trajectory_exploration import candidate, context, inspect, record


class TrajectoryExplorationTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        source = self.root / "source.txt"
        source.write_text("source-a")
        self.source = source
        self.snapshot = {
            "executionAuthorized": False,
            "revision": "revision",
            "inputs": {str(source): digest(source)},
            "sourceIdentity": "source-a",
            "backend": {"name": "ascent-rust"},
            "engine": {"source": "model"},
            "actions": [{"id": "question", "study": "study", "operation": "inspect",
                         "hypothesis": "none", "explanation": {"sameInputFailures": []}}],
            "research": {"openPredictions": [["hypothesis", "observation", "expected"]],
                         "discriminators": []},
        }

    def completed_action(self, *, authorized=True):
        from gambit_smp.research_actions import _database

        handle = str(uuid.uuid4())
        request = {"action": "question", "sourceIdentity": self.snapshot["sourceIdentity"],
                   "revision": self.snapshot["revision"], "authorization": authorized}
        result = {"status": "COMPLETED", "outcome": "RECORDED", "runtimeAdmitted": False}
        with closing(_database(self.root)) as db:
            db.execute("INSERT INTO requests VALUES (?,?,?)",
                       (handle, json.dumps(request), json.dumps(result)))
            db.commit()
        return handle

    def test_candidate_accepts_discovered_view_and_recipe_shapes(self):
        view = {"id": "view:gc:inspect-header", "operation": "evidence-view",
                "view": "evidence/scenarios/concurrent-gc/working-modeling.view.json"}
        recipe = {"id": "recipe:gc-stress", "recipe": "evidence/research/gc/stress.recipe.json",
                  "scope": "concurrent-gc"}
        snapshot = dict(self.snapshot, actions=[view, recipe])
        observed = candidate(snapshot, view["id"])
        self.assertEqual(observed["scopeIdentity"], view["view"])
        self.assertEqual(observed["operationIdentity"], "evidence-view")
        self.assertNotIn("proposalIdentity", observed)
        observed = candidate(snapshot, recipe["id"])
        self.assertEqual(observed["scopeIdentity"], "concurrent-gc")
        self.assertEqual(observed["operationIdentity"], "recipe:" + recipe["recipe"])

        snapshot.update(engine=None, context={"views": [view["view"]]},
                        evidenceViews=[{"id": "gc", "source": "bound"}])
        first = candidate(snapshot, view["id"])
        self.assertIn("modelIdentity", first)
        snapshot["revision"] = "next-outcome"
        self.assertEqual(candidate(snapshot, view["id"]), first)
        snapshot["evidenceViews"] = [{"id": "gc", "source": "changed"}]
        self.assertNotEqual(candidate(snapshot, view["id"]), first)

    def test_duplicate_attempts_survive_restart_and_v1_migration(self):
        handle = self.completed_action()
        first = record(self.root, "scope", self.snapshot, "question", handle)
        self.assertEqual(record(self.root, "scope", self.snapshot, "question", handle), first)
        with self.assertRaisesRegex(ValueError, "handle changed identity"):
            record(self.root, "scope", self.snapshot, "question", handle,
                   purpose="different meaning")
        second = record(self.root, "scope", self.snapshot, "question", self.completed_action(),
                        purpose="replication")
        self.assertNotEqual(first["id"], second["id"])
        self.assertEqual([row["id"] for row in read_trajectory_attempts(self.root, "scope")],
                         [first["id"], second["id"]])
        self.assertEqual(len(read_trajectory_attempts(self.root, "scope")), 2)
        with tempfile.TemporaryDirectory() as directory:
            older = Path(directory)
            subprocess.run(["git", "init", "-q", str(older)], check=True, capture_output=True)
            database = older / ".cache/reasoning/history.sqlite3"
            database.parent.mkdir(parents=True)
            with closing(sqlite3.connect(database)) as connection:
                connection.execute("PRAGMA user_version=1")
            self.assertEqual(read_trajectory_attempts(older, "scope"), [])
            with closing(sqlite3.connect(database)) as connection:
                self.assertEqual(connection.execute("PRAGMA user_version").fetchone()[0], 5)
                self.assertEqual(connection.execute("SELECT COUNT(*) FROM clue_read_checkpoints").fetchone()[0], 0)
        self.source.write_text("source-b")
        with self.assertRaisesRegex(ValueError, "source changed"):
            candidate(self.snapshot, "question")

    def test_reinspection_does_not_rewrite_observed_result_identity(self):
        handle = self.completed_action()
        from gambit_smp.research_actions import observe

        original = observe(self.root, handle)
        with patch("gambit_smp.research_actions.observe", return_value=original):
            first = record(self.root, "scope", self.snapshot, "question", handle)
        rechecked = json.loads(json.dumps(original))
        rechecked["result"]["inspection"] = {"status": "STALE", "runtimeAdmitted": False}
        with patch("gambit_smp.research_actions.observe", return_value=rechecked):
            self.assertEqual(record(self.root, "scope", self.snapshot, "question", handle), first)
        self.assertEqual(len(read_trajectory_attempts(self.root, "scope")), 1)

    def test_replay_crosses_source_generation_without_authorizing_action(self):
        record(self.root, "scope", self.snapshot, "question", self.completed_action())
        changed = dict(self.snapshot, sourceIdentity="source-b")
        calls = []

        class Ledger:
            def __init__(self, _engine, _scope, source):
                self.source_identity = source

            def __enter__(self):
                return self

            def __exit__(self, *_args):
                pass

            def invalidate(self, source):
                calls.append(("invalidate", source))
                self.source_identity = source

            def append(self, kind, **fields):
                calls.append((kind, fields["questionIdentity"]))

            def explore(self, proposed):
                calls.append(("explore", proposed["inputIdentity"]))
                return {"comparisons": [{"earlierEvent": "observed", "relation": "historical"}]}

        with patch.dict(sys.modules, {"ascent.trajectory": types.SimpleNamespace(Trajectory=Ledger)}), \
                patch("gambit_smp.ascent_program.query", return_value={}):
            packet = inspect(self.root, "scope", changed, "question", object())
        self.assertEqual(calls, [("attempt", "question"), ("invalidate", "source-b"),
                                 ("explore", "source-b")])
        self.assertEqual(packet["comparisons"][0]["relation"], "historical")
        self.assertFalse(packet["executionAuthorized"])
        self.assertFalse(packet["runtimeAdmitted"])
        self.assertEqual(packet["openPredictions"], [["hypothesis", "observation", "expected"]])

    def test_projection_uses_research_root_not_implementation_location(self):
        from gambit_smp.framework import ROOT
        from ascent import Engine
        from gambit_smp.ascent_program import load_component_catalog

        record(self.root, "scope", self.snapshot, "question", self.completed_action())
        with Engine() as engine, \
                patch("gambit_smp.trajectory_exploration.__file__", "/unavailable/site-packages/trajectory_exploration.py"), \
                patch("gambit_smp.ascent_program.load_component_catalog", wraps=load_component_catalog) as load:
            packet = inspect(self.root, "scope", self.snapshot, "question", engine)
        self.assertEqual(load.call_args.args[0], ROOT / "evidence/dsl/trajectory-review.components.json")
        self.assertFalse(packet["runtimeAdmitted"])

    def test_source_drift_during_projection_does_not_publish_advice(self):
        def mutate(*_args, **_kwargs):
            self.source.write_text("source-b")
            return {}

        with patch("gambit_smp.trajectory_exploration._replay",
                   return_value=({"comparisons": []}, [])), \
                patch("gambit_smp.ascent_program.query", side_effect=mutate):
            with self.assertRaisesRegex(ValueError, "source changed"):
                inspect(self.root, "scope", self.snapshot, "question", object())
        self.source.write_text("source-a")

        def mutate_replay(*_args, **_kwargs):
            self.source.write_text("source-b")
            return {"attempts": []}, []

        with patch("gambit_smp.trajectory_exploration._replay", side_effect=mutate_replay):
            with self.assertRaisesRegex(ValueError, "source changed"):
                context(self.root, "scope", self.snapshot, object())

    def test_unbound_or_unexpected_attempts_are_not_admitted(self):
        with self.assertRaises(ValueError):
            append_trajectory_attempt(self.root, "scope", "source", {"questionIdentity": "q"},
                                      observation={"handle": "x", "status": "COMPLETED",
                                                   "outcome": "RECORDED", "resultIdentity": "y"},
                                      snapshot_identity="0" * 64)
        with self.assertRaises(ValueError):
            candidate(self.snapshot, "different-action")
        with self.assertRaisesRegex(ValueError, "observed action differs"):
            record(self.root, "scope", self.snapshot, "question",
                   self.completed_action(authorized=False))

    def test_real_upstream_replay_after_restart(self):
        from ascent import Engine

        self.snapshot["sourceIdentity"] = digest(self.source)
        record(self.root, "scope", self.snapshot, "question", self.completed_action())
        record(self.root, "scope", self.snapshot, "question", self.completed_action(),
               purpose="intentional replication")
        record(self.root, "scope", self.snapshot, "question", self.completed_action())
        with Engine() as engine:
            open_context = context(self.root, "scope", self.snapshot, engine)
            self.assertEqual(len(open_context["attempts"]), 3)
            self.assertNotIn("action", open_context)
            self.assertNotIn("next", open_context)
            self.assertNotIn("resultReference", open_context["attempts"][0])
            self.assertFalse(open_context["executionAuthorized"])
            packet = inspect(self.root, "scope", self.snapshot, "question", engine)
            self.assertEqual([row["relation"] for row in packet["comparisons"]],
                             ["exact-current"] * 3)
            self.assertEqual(len(packet["review"]["repeatedObservation"]), 2)
            self.assertEqual(len(packet["review"]["repeatCandidates"]), 1)
            self.assertNotIn("actions", packet["review"])
            self.assertNotIn("next", packet)
            self.assertEqual(len(packet["review"]["intentionalReplication"]), 1)
            self.assertFalse(packet["executionAuthorized"])
            incomplete = dict(self.snapshot)
            incomplete.pop("engine")
            packet = inspect(self.root, "scope", incomplete, "question", engine)
            self.assertEqual([row["relation"] for row in packet["comparisons"]],
                             ["comparison-unknown"] * 3)
            self.assertEqual(packet["review"]["repeatedObservation"], [])
            self.assertEqual(packet["review"]["repeatCandidates"], [])
            changed = dict(self.snapshot, backend={"name": "different-tool"})
            packet = inspect(self.root, "scope", changed, "question", engine)
            self.assertEqual([row["relation"] for row in packet["comparisons"]],
                             ["changed-premise"] * 3)
            self.source.write_text("source-b")
            self.snapshot["inputs"] = {str(self.source): digest(self.source)}
            self.snapshot["sourceIdentity"] = digest(self.source)
            packet = inspect(self.root, "scope", self.snapshot, "question", engine)
            self.assertEqual([row["relation"] for row in packet["comparisons"]],
                             ["historical"] * 3)
            self.assertEqual(packet["review"]["repeatedObservation"], [])
            record(self.root, "scope", self.snapshot, "question", self.completed_action())
            self.source.write_text("source-a")
            self.snapshot["inputs"] = {str(self.source): digest(self.source)}
            self.snapshot["sourceIdentity"] = digest(self.source)
            packet = inspect(self.root, "scope", self.snapshot, "question", engine)
            self.assertEqual([row["relation"] for row in packet["comparisons"]],
                             ["historical"] * 4)
            self.assertEqual(packet["review"]["repeatedObservation"], [])
            self.assertFalse(packet["executionAuthorized"])
            self.assertFalse(packet["runtimeAdmitted"])

    def test_repeat_candidates_count_attempts_not_pairs(self):
        from ascent import Engine

        self.snapshot["sourceIdentity"] = digest(self.source)
        attempts = [record(self.root, "scope", self.snapshot, "question",
                           self.completed_action()) for _ in range(5)]
        with Engine() as engine:
            prefix = inspect(self.root, "scope", self.snapshot, "question", engine,
                             through=attempts[1]["id"])
            packet = inspect(self.root, "scope", self.snapshot, "question", engine)
            with self.assertRaisesRegex(ValueError, "prefix endpoint"):
                inspect(self.root, "scope", self.snapshot, "question", engine,
                        through="missing")
        self.assertEqual(prefix["replayedAttempts"], 2)
        self.assertEqual(prefix["historyThrough"], attempts[1]["id"])
        self.assertEqual(len(prefix["prefixIdentity"]), 64)
        self.assertNotEqual(prefix["prefixIdentity"], packet["prefixIdentity"])
        self.assertEqual(len(prefix["review"]["repeatCandidates"]), 1)
        self.assertEqual({row["earlierEvent"] for row in prefix["comparisons"]},
                         {attempts[0]["id"], attempts[1]["id"]})
        self.assertEqual(len(packet["review"]["repeatedObservation"]), 10)
        self.assertEqual(len(packet["review"]["repeatCandidates"]), 4)
        self.assertFalse(packet["executionAuthorized"])

    def test_historical_prefix_requires_its_recorded_snapshot(self):
        from ascent import Engine

        self.snapshot["sourceIdentity"] = digest(self.source)
        observed = record(self.root, "scope", self.snapshot, "question",
                          self.completed_action())
        with Engine() as engine:
            first = context(self.root, "scope", self.snapshot, engine,
                            through=observed["id"])
        with Engine() as engine:
            resumed = context(self.root, "scope", self.snapshot, engine,
                              through=observed["id"])
            self.assertEqual(first["prefixIdentity"], resumed["prefixIdentity"])
            later = json.loads(json.dumps(self.snapshot))
            later["research"]["openPredictions"].append(["new", "later", "idea"])
            with self.assertRaisesRegex(ValueError, "prefix snapshot identity mismatch"):
                context(self.root, "scope", later, engine, through=observed["id"])
            self.assertEqual(len(context(self.root, "scope", later, engine)["attempts"]), 1)

        from gambit_smp.reasoning_history import _database, canonical, fingerprint

        with _database(self.root) as db:
            row = db.execute("SELECT id,body FROM trajectory_attempts WHERE scope='scope'").fetchone()
            legacy = json.loads(row[1])
            legacy.pop("snapshotIdentity")
            db.execute("UPDATE trajectory_attempts SET id=?,body=? WHERE id=?",
                       (fingerprint(legacy), canonical(legacy), row[0]))
            db.commit()
        self.assertEqual(len(read_trajectory_attempts(self.root, "scope")), 1)
        with Engine() as engine:
            with self.assertRaisesRegex(ValueError, "prefix snapshot identity mismatch"):
                context(self.root, "scope", self.snapshot, engine, through=observed["id"])
