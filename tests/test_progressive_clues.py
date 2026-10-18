"""Real Scheme queries across current failure, historical evidence and new hypotheses."""
import json
from contextlib import redirect_stdout, redirect_stderr
import io
import subprocess
import sys
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from concurrent.futures import ThreadPoolExecutor

from gambit_smp.ascent_program import engine_api
from gambit_smp.framework import ROOT, digest
from gambit_smp.reasoning_history import read_trajectory_clues
from gambit_smp.research_actions import discover
from gambit_smp.trajectory_exploration import (argument_parser, catalog, clue_journal,
                                              clues, context as trajectory_context,
                                              repository_clues, read_view, submit)

FACTOR_QUERY = '''(define-evidence (query)
 (sources clue factor binding) (outputs question associated unknown_binding)
 (relation clue (id digest claim polarity role source))
 (relation factor (id digest name value))
 (relation binding (name value))
 (relation associated (name value claim id digest))
 (relation has_match (name value))
 (relation unknown_binding (name value))
 (relation question (claim))
 ((associated N V C I D) <-- (clue I D C _ _ _) (factor I D N V) (binding N V))
 ((question C) <-- (associated _ _ C _ _))
 ((has_match N V) <-- (associated N V _ _ _))
 ((unknown_binding N V) <-- (binding N V) (not (has_match N V))))'''


class EvidenceCacheTestCase(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = ROOT
        storage = patch("gambit_smp.artifact_storage.database_path",
                        side_effect=lambda _root, name, _legacy: Path(self.temporary.name) / name)
        storage.start()
        self.addCleanup(storage.stop)


class ProgressiveClueTests(EvidenceCacheTestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = json.loads((ROOT / "evidence/scenarios/stack-header/action-context.json").read_text())
        cls.snapshot = discover(ROOT, cls.context)

    def query(self, question, *, bindings=(), snapshot=None):
        with engine_api() as (engine, _):
            return clues(self.root, "case", snapshot or self.snapshot,
                         question, engine, bindings=bindings)

    def hypothesis(self, identity="new-producer-hypothesis"):
        return dict(id=identity, claim="terminal-return-slot-never-initialized",
                    polarity="support", source="agent:local-investigation",
                    factors=[["entity", "stack-entry"], ["mechanism", "terminal-slot-initialization"]])

    def test_three_rounds_follow_evidence_then_retain_new_hypothesis(self):
        first = self.query("stack-entry", bindings=[
            ["entity", "stack-entry"], ["candidate", "current-formal"]])
        self.assertEqual({row[0] for row in first["support"]}, {
            "current-label-base-bootstrap-denied", "first-return-address-producer-unidentified"})
        self.assertTrue(any(row[2] == "common-cause-unproved"
                            for row in first["neighbor"]))
        second = self.query("manual-label-base-mismatch-is-unexplored")
        self.assertEqual(len(second["counterevidence"]), 1)
        self.assertEqual(second["support"], [])
        self.assertIn("historical-diagnostic", {row[4] for row in second["relevant_factor"]})
        row = self.hypothesis()
        before = clue_journal(self.root, "case")
        accepted = submit(self.root, "case", self.snapshot, [row], before["prefix"])
        self.assertNotEqual(accepted["prefix"], before["prefix"])
        third = self.query("new mechanism", bindings=[["mechanism", "terminal-slot-initialization"]])
        self.assertEqual([r[0] for r in third["conditional"]], [row["claim"]])
        self.assertEqual(third["support"], [])
        self.assertEqual(third["unknown"], [[row["claim"]]])
        self.assertEqual(third["clueJournal"]["retainedClues"], 1)
        self.assertFalse(third["runtimeAdmitted"])

    def test_scope_conjunction_unknown_and_open_factor(self):
        mixed = self.query("no common clue", bindings=[
            ["candidate", "current-formal"], ["scope", "historical-diagnostic"]])
        self.assertEqual(mixed["selection"]["question"], [])
        self.assertEqual(mixed["support"], [])
        empty = self.query("novel", bindings=[["new-factor", "unlisted"]])
        self.assertEqual(empty["selection"]["unknown_binding"], [["new-factor", "unlisted"]])
        row = self.hypothesis()
        row["factors"].append(["new-factor", "unlisted"])
        submit(self.root, "case", self.snapshot, [row], clue_journal(self.root, "case")["prefix"])
        found = self.query("novel", bindings=[["new-factor", "unlisted"]])
        self.assertEqual(found["selection"]["unknown_binding"], [])
        self.assertEqual(len(found["conditional"]), 1)

    def test_call_boundary_candidate_separates_model_and_native_status(self):
        selector = '''(define-evidence (query)
 (sources clue factor) (outputs question)
 (include clue-selection-schema)
 (relation question (claim))
 ((question C) <-- (clue I D C _ _ _)
  (factor I D (lit "candidate") (lit "call-boundary-reserve"))))'''
        result = repository_clues(ROOT, selector=selector)
        self.assertEqual({family["claim"] for family in result["brief"]["families"]}, {
            "disabled-call-stack-check-candidate",
            "call-boundary-finite-controls-pass",
            "call-boundary-native-acceptance-unverified",
            "call-boundary-two-pass-bootstrap-completed",
            "call-boundary-stress-runtime-qualified",
            "compiler-inserted-check-preserves-kernel-handler-abi"})
        self.assertEqual(result["brief"]["counts"]["counter"], 2)
        self.assertFalse(result["brief"]["runtimeAdmitted"])
        mismatched = repository_clues(ROOT, selector=selector.replace(
            '(lit "call-boundary-reserve"))))',
            '(lit "call-boundary-reserve"))'
            ' (factor I D (lit "stage") (lit "finite-model"))'
            ' (factor I D (lit "outcome") (lit "UNVERIFIED"))))'))
        self.assertEqual(mismatched["brief"]["association"]["question"], [])

    def test_entry_contract_candidate_is_queryable_without_inheriting_native_pass(self):
        selector = '''(define-evidence (query)
 (sources clue factor) (outputs question)
 (include clue-selection-schema)
 (relation question (claim))
 ((question C) <-- (clue I D C _ _ _)
  (factor I D (lit "candidate") (lit "stack-entry-contract"))))'''
        first = repository_clues(ROOT, selector=selector)
        expected = {
            "stable-continuation-partition-candidate",
            "entry-contract-finite-controls-pass",
            "entry-contract-native-acceptance-unverified",
            "entry-contract-complete-compiled-stress",
            "entry-contract-complete-interpreted-stress",
            "entry-contract-manual-ordinals-aligned",
            "entry-contract-debug-label-mapping-consistent",
            "entry-contract-interpreter-local-environment-valid"}
        seen, page = set(), first
        while True:
            self.assertFalse(page["brief"]["runtimeAdmitted"])
            for row in page["brief"]["families"]:
                self.assertIn(row["claim"], expected)
                self.assertNotIn(row["claim"], seen)
                seen.add(row["claim"])
            if page["brief"]["presentationComplete"]:
                break
            self.assertTrue(page["brief"]["families"])
            page = repository_clues(ROOT, selector=selector,
                                    checkpoint=page["checkpoint"])
        self.assertEqual(seen, expected)
        repeated = repository_clues(ROOT, selector=selector,
                                    checkpoint=page["checkpoint"])
        self.assertEqual(repeated["brief"]["families"], [])
        self.assertEqual(repeated["brief"]["counts"], first["brief"]["counts"])

    def test_project_authored_navigation_reuses_registered_native_counterevidence(self):
        selector = (ROOT / "evidence/scenarios/stack-header/clues.ss").read_text()
        result = repository_clues(ROOT, selector=selector,
            constructor="make-stack-entry-navigation",
            bindings=[("mechanism", "debug-control-point-id-remapping"),
                      ("candidate", "stack-entry-contract")])
        brief = result["brief"]
        self.assertEqual(brief["association"]["unknown_binding"], [])
        self.assertEqual(brief["association"]["question"], [
            ["entry-contract-debug-label-mapping-consistent"]])
        self.assertEqual(len(brief["families"]), 1)
        observation = brief["families"][0]["observations"][0]
        self.assertEqual(observation["polarity"], "counter")
        self.assertEqual(observation["digest"], digest(
            ROOT / "evidence/research/stack-entry-contract/interpreter-crash.json"))
        self.assertFalse(brief["executionAuthorized"])

    def test_new_scope_does_not_present_repository_evidence_as_empty(self):
        with engine_api() as (engine, _):
            result = trajectory_context(self.root, "new-investigation", self.snapshot, engine)
        self.assertEqual(result["eventCount"], 0)
        self.assertEqual(result["scope"], "new-investigation")
        inventory = {view["id"]: view for view in result["repositoryEvidence"]}
        self.assertEqual(inventory["stack-entry-source-locked-failed-paths"]["rows"]["denied"], 5)
        self.assertFalse(result["runtimeAdmitted"])

    def test_view_read_requires_no_empty_scope_or_internal_claim_construction(self):
        with patch("gambit_smp.trajectory_exploration.read_trajectory_attempts") as attempts, \
                patch("gambit_smp.trajectory_exploration.read_trajectory_clues") as journal, \
                engine_api() as (engine, _):
            result = read_view(self.root, self.snapshot, "stack-entry-source-locked-failed-paths", "denied", engine)
        attempts.assert_not_called()
        journal.assert_not_called()
        self.assertEqual(len(result["answers"]), 5)
        self.assertNotIn("clueJournal", result)

    def test_journal_cas_restart_source_change_and_no_attestation(self):
        row = self.hypothesis()
        prefix = clue_journal(self.root, "case")["prefix"]
        accepted = submit(self.root, "case", self.snapshot, [row], prefix)
        with self.assertRaisesRegex(ValueError, "stale trajectory clue prefix"):
            submit(self.root, "case", self.snapshot, [self.hypothesis("other")], prefix)
        with self.assertRaisesRegex(ValueError, "already retained"):
            submit(self.root, "case", self.snapshot, [row], accepted["prefix"])
        rows, restored = read_trajectory_clues(self.root, "case")
        self.assertEqual(restored, accepted["prefix"])
        self.assertEqual(rows[0]["clues"], [row])
        changed = dict(self.snapshot, sourceIdentity="new-source-generation")
        withdrawn = self.query(row["claim"], snapshot=changed)
        self.assertEqual(withdrawn["historicalClues"], [row["id"]])
        self.assertEqual(withdrawn["conditional"], [])
        self.assertEqual(withdrawn["clueJournal"]["retainedClues"], 1)
        row["attested"] = "forged"
        with self.assertRaisesRegex(ValueError, "authority fields"):
            submit(self.root, "case", self.snapshot, [row], accepted["prefix"])

    def test_current_portable_observation_matches_raw_receipt_when_available(self):
        observation = json.loads((ROOT / "evidence/fixtures/darwin-stack-call-preflight-label-base/native-observation.json").read_text())
        self.assertEqual(digest(ROOT / observation["sourceLock"]), observation["sourceLockSha256"])
        self.assertEqual(observation["bootstrapOutcome"], "DENY")
        raw = ROOT / ".cache/stack-call-preflight-label-base-001/run/receipt.json"
        if raw.exists():
            self.assertEqual(digest(raw), observation["bootstrapStepReceiptSha256"])
            saved = json.loads(raw.read_text())
            self.assertEqual([{k: step[k] for k in ("id", "outcome")} for step in saved["steps"]],
                             observation["stages"])
            step = next(row for row in saved["steps"] if row["id"] == "bootstrap")
            self.assertEqual(step["commands"][-1]["exit"], observation["failedCommand"]["exit"])
            self.assertEqual(step["artifacts"]["bootstrap/from-scratch.stderr"],
                             observation["failedCommand"]["stderrSha256"])

    def test_concurrent_submissions_preserve_one_cas_winner(self):
        prefix = clue_journal(self.root, "case")["prefix"]
        proposals = [self.hypothesis("writer-a"), self.hypothesis("writer-b")]

        def write(row):
            try:
                return submit(self.root, "case", self.snapshot, [row], prefix)
            except ValueError as error:
                return str(error)

        with ThreadPoolExecutor(max_workers=len(proposals)) as workers:
            results = list(workers.map(write, proposals))
        self.assertEqual(sum(isinstance(row, dict) for row in results), 1)
        self.assertEqual(sum(isinstance(row, str) and "stale trajectory clue prefix" in row
                             for row in results), 1)
        rows, _ = read_trajectory_clues(self.root, "case")
        self.assertEqual(len(rows), 1)
        self.assertEqual(len(rows[0]["clues"]), 1)

    def test_missing_navigator_does_not_invent_a_default_policy(self):
        snapshot = dict(self.snapshot, context={})
        with self.assertRaisesRegex(ValueError, "caller-declared navigator"):
            self.query("stack-entry", bindings=[["entity", "stack-entry"]], snapshot=snapshot)


class TrajectoryCliTests(EvidenceCacheTestCase):
    def help(self, *arguments):
        output = io.StringIO()
        with redirect_stdout(output), self.assertRaises(SystemExit) as stopped:
            argument_parser().parse_args([*arguments, "--help"])
        self.assertEqual(stopped.exception.code, 0)
        return output.getvalue()

    def test_help_is_specific_to_operation(self):
        root = self.help()
        query = self.help("clues")
        hypothesis = self.help("submit")
        inventory = self.help("catalog")
        self.assertIn("catalog", root)
        self.assertNotIn("--clues-json", root)
        self.assertIn("Scheme request", query)
        self.assertIn("(checkpoint", query)
        self.assertIn("not automatic continuation", query)
        self.assertIn("relational anchors", query)
        self.assertIn("inert Scheme data", query)
        self.assertNotIn("Result shape:", query)
        self.assertNotIn("list[dict]", query)
        self.assertNotIn("pathlib.Path", query)
        self.assertNotIn("--context", query)
        self.assertNotIn("--request", query)
        self.assertNotIn("--clues-json", query)
        self.assertIn("--clues-json", hypothesis)
        self.assertNotIn("--question", hypothesis)
        self.assertIn("--factor", inventory)
        self.assertNotIn("--scope", inventory)

    def test_scheme_selector_uses_the_existing_native_query_and_checkpoint(self):
        from gambit_smp.trajectory_exploration import main
        from gambit_smp import trajectory_exploration as module
        output = io.StringIO()
        path = "evidence/scenarios/stack-header/clues.ss"
        from ascent.trajectory import ClueExchange
        declaration = ClueExchange.render(dict(selector=(ROOT / path).read_text(),
            constructor="make-stack-entry-navigation",
            bindings=[["mechanism", "debug-control-point-id-remapping"]]))
        argv = ["trajectory", "clues", declaration]
        with patch.object(sys, "argv", argv), redirect_stdout(output), \
                patch.object(module, "repository_clues", wraps=repository_clues) as query:
            main()
        self.assertEqual(query.call_args.kwargs["selector"], (ROOT / path).read_text())
        self.assertIn("entry-contract-debug-label-mapping-consistent", output.getvalue())
        self.assertIn("clue-read:", output.getvalue())

    def test_query_has_one_declaration_and_no_optional_investigation_flags(self):
        parser = argument_parser()
        operations = next(action for action in parser._actions if action.dest == "operation")
        query = operations.choices["clues"]
        options = [option for action in query._actions for option in action.option_strings]
        self.assertEqual(options, ["-h", "--help"])

    def test_registered_anchors_hit_without_context_or_constructor_discovery(self):
        first = repository_clues(ROOT, bindings=[
            ["candidate", "c-continuation-debug-projection"]])
        self.assertTrue(first["brief"]["families"])
        self.assertIn("debug-projection-source-integrated",
                      first["brief"]["scopeReference"]["claims"])
        self.assertIn("debug-projection-bootstrap-complete",
                      first["brief"]["scopeReference"]["claims"])
        second = repository_clues(ROOT, bindings=[
            ["candidate", "c-continuation-debug-projection"]],
            checkpoint=first["checkpoint"])
        old = {row["claim"] for row in first["brief"]["families"]}
        self.assertTrue(old.isdisjoint(row["claim"] for row in second["brief"]["families"]))
        self.assertEqual(first["brief"]["sourceIdentity"], second["brief"]["sourceIdentity"])

    def test_registered_anchors_leave_unknown_factors_explicit(self):
        result = repository_clues(ROOT, bindings=[["unlisted-factor", "new-hypothesis"]])
        self.assertFalse(result["brief"]["families"])
        self.assertIn("new-hypothesis", json.dumps(result))
        self.assertFalse(result["brief"]["executionAuthorized"])

    def test_explicit_selector_replaces_registered_policy(self):
        result = repository_clues(ROOT, selector=FACTOR_QUERY, bindings=[
            ["candidate", "c-continuation-debug-projection"],
            ["unlisted-factor", "new-hypothesis"]])
        # This caller chooses disjunction instead of the registered conjunction.
        self.assertTrue(result["brief"]["families"])

    def test_exact_question_cannot_silently_drop_anchor_bindings(self):
        with self.assertRaisesRegex(ValueError, "not both"):
            repository_clues(ROOT, "claim", bindings=[["candidate", "candidate"]])

    def test_cli_anchor_uses_registered_dsl(self):
        from gambit_smp.trajectory_exploration import main
        output = io.StringIO()
        argv = ["trajectory", "clues",
                '((bindings (("candidate" "c-continuation-debug-projection"))))']
        with patch.object(sys, "argv", argv), redirect_stdout(output):
            main()
        self.assertIn("debug-projection-source-integrated", output.getvalue())
        self.assertIn("clue-read:", output.getvalue())

    def test_scheme_stdin_uses_the_same_request_reader(self):
        from gambit_smp.trajectory_exploration import main
        output = io.StringIO()
        declaration = '((questions ("manual-label-base-mismatch-is-unexplored")))'
        with patch.object(sys, "argv", ["trajectory", "clues"]), \
                patch.object(sys, "stdin", io.StringIO(declaration)), redirect_stdout(output):
            main()
        self.assertIn("manual-label-base-mismatch-is-unexplored", output.getvalue())

    def test_unscoped_catalog_reads_only_context_declarations(self):
        with patch("gambit_smp.research_actions.discover", side_effect=AssertionError("no inference")):
            result = catalog(ROOT)
        paths = {row["path"] for row in result["contexts"]}
        self.assertIn("evidence/scenarios/stack-header/action-context.json", paths)
        self.assertIn("evidence/scenarios/stack-header/historical-action-context.json", paths)
        for row in result["contexts"]:
            self.assertEqual(set(row), {"path", "sha256", "declaredViews"})
            self.assertEqual(digest(ROOT / row["path"]), row["sha256"])
        self.assertFalse(result["runtimeAdmitted"])

    def test_scoped_catalog_is_partial_vocabulary_not_evidence_dump(self):
        result = catalog(ROOT, "evidence/scenarios/stack-header/action-context.json")
        self.assertIn("catalogIdentity", result)
        self.assertNotIn("sourceIdentity", result)
        self.assertIn("mechanism", result["factorNames"])
        self.assertNotIn("values", result)
        self.assertTrue(result["factors"])
        self.assertNotIn("answers", result)
        self.assertFalse(result["inventoryComplete"])
        self.assertTrue(all(set(view) == {"id", "path", "queries"} for view in result["views"]))

    def test_factor_values_are_dsl_projected_and_unknown_is_not_rejected(self):
        path = "evidence/scenarios/stack-header/action-context.json"
        mechanism = catalog(ROOT, path, factor="mechanism")
        self.assertEqual(mechanism["values"], ["first-invalid-return-producer", "manual-label-base"])
        novel = catalog(ROOT, path, factor="previously-unlisted-factor")
        self.assertEqual(novel["values"], [])
        self.assertFalse(novel["inventoryComplete"])

    def test_historical_catalog_without_clue_projection_still_lists_views(self):
        with patch("gambit_smp.research_actions.discover", side_effect=AssertionError("catalog is not native admission")):
            result = catalog(ROOT, "evidence/scenarios/stack-header/historical-action-context.json")
        self.assertFalse(result["clueExchangeAvailable"])
        self.assertTrue(result["views"])
        self.assertEqual(result["factors"], [])
        self.assertFalse(result["inventoryComplete"])

    def test_history_help_explains_its_scope_requirement(self):
        self.assertIn("--scope required with --context", self.help("context"))

    def test_catalog_context_and_projected_source_have_distinct_identity_scopes(self):
        context = "evidence/scenarios/stack-header/action-context.json"
        metadata = catalog(ROOT, context)
        declaration = json.loads((ROOT / context).read_text())
        snapshot = discover(ROOT, declaration)
        with engine_api() as (engine, _):
            result = clues(ROOT, None, snapshot, "current-label-base-bootstrap-denied", engine)
            raw = read_view(ROOT, snapshot, "stack-entry-progressive-clues", "clue", engine)
        self.assertEqual(result["contextIdentity"], snapshot["sourceIdentity"])
        self.assertEqual(raw["contextIdentity"], result["contextIdentity"])
        self.assertIn("sourceIdentity", result)
        self.assertNotIn("sourceIdentity", raw)
        self.assertNotEqual(metadata["catalogIdentity"], result["sourceIdentity"])

    def test_first_relation_query_hits_without_context_or_discovery_sequence(self):
        import gambit_smp
        self.assertIn("repository_clues", dir(gambit_smp))
        self.assertIs(gambit_smp.repository_clues, repository_clues)
        self.assertIs(gambit_smp.engine_api, engine_api)
        with patch("gambit_smp.research_actions.discover", side_effect=AssertionError("no action graph")), \
                gambit_smp.engine_api() as (engine, _):
            result = gambit_smp.repository_clues(ROOT, None, engine,
                bindings=[["entity", "stack-entry"]], selector=FACTOR_QUERY)
        evidence = result["brief"]
        self.assertGreater(evidence["counts"]["support"], 0)
        self.assertGreater(evidence["counts"]["counter"], 0)
        self.assertTrue(evidence["families"] or evidence["deferred"])
        self.assertTrue(evidence["explorationOpen"])
        self.assertNotIn("Next", evidence)
        for family in [*evidence["families"], *evidence["deferred"]]:
            self.assertEqual(family["reference"]["sourceIdentity"], evidence["sourceIdentity"])

    def test_public_discovery_does_not_bind_checkout_before_cli_root_selection(self):
        result = subprocess.run([sys.executable, "-c",
            "import gambit_smp, sys; "
            "assert 'repository_clues' in dir(gambit_smp); "
            "assert 'gambit_smp.framework' not in sys.modules"],
            capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_managed_public_reads_resume_after_engine_close_without_inventory(self):
        from gambit_smp import repository_clues as query
        claim = "manual-label-base-mismatch-is-unexplored"
        first = query(str(ROOT), claim)
        second = query(ROOT, claim, checkpoint=first["checkpoint"])
        self.assertTrue(first["brief"]["presentationComplete"])
        self.assertGreater(first["brief"]["counts"]["counter"], 0)
        self.assertEqual(first["brief"]["sourceIdentity"], second["brief"]["sourceIdentity"])
        self.assertEqual(second["brief"]["families"], [])
        self.assertEqual(set(first), {"brief", "checkpoint"})
        self.assertFalse(first["brief"]["runtimeAdmitted"])
        self.assertRegex(first["checkpoint"], r"^clue-read:[0-9a-f]{64}$")
        self.assertIsInstance(first["brief"]["families"], list)
        self.assertIsInstance(first["brief"]["deferred"], list)
        for family in first["brief"]["families"]:
            self.assertIsInstance(family["observations"], list)
            self.assertIsInstance(family["links"], list)
            self.assertIsInstance(family["reference"], dict)

    def test_checkpoint_token_resumes_in_another_python_process(self):
        claim = "manual-label-base-mismatch-is-unexplored"
        first = repository_clues(ROOT, claim)
        script = '''import json, sys
from pathlib import Path
from unittest.mock import patch
from gambit_smp import repository_clues
with patch("gambit_smp.artifact_storage.database_path",
           side_effect=lambda root, name, previous: Path(sys.argv[1]) / name):
    result = repository_clues(sys.argv[2], sys.argv[3], checkpoint=sys.argv[4])
print(json.dumps(result))'''
        process = subprocess.run([sys.executable, "-c", script, self.temporary.name,
                                  str(ROOT), claim, first["checkpoint"]],
                                 capture_output=True, text=True, timeout=30)
        self.assertEqual(process.returncode, 0, process.stderr)
        second = json.loads(process.stdout)
        self.assertEqual(second["brief"]["mode"], "incremental")
        self.assertEqual(second["brief"]["families"], [])
        self.assertEqual(second["checkpoint"], first["checkpoint"])

    def test_cli_uses_the_same_token_without_checkpoint_file_transport(self):
        from gambit_smp.trajectory_exploration import main
        claim = "manual-label-base-mismatch-is-unexplored"
        first = repository_clues(ROOT, claim)
        output = io.StringIO()
        from ascent.trajectory import ClueExchange
        declaration = ClueExchange.render(dict(questions=[claim], checkpoint=first["checkpoint"]))
        with patch("sys.argv", ["trajectory", "clues", declaration]), redirect_stdout(output):
            main()
        rendered = output.getvalue()
        self.assertIn(first["checkpoint"], rendered)
        self.assertIn('"incremental"', rendered)
        self.assertIn("checkpoint", rendered)

    def test_token_cache_loss_replays_and_corruption_is_not_accepted(self):
        from gambit_smp.reasoning_history import _database
        claim = "manual-label-base-mismatch-is-unexplored"
        first = repository_clues(ROOT, claim)
        identity = first["checkpoint"].removeprefix("clue-read:")
        with _database(ROOT) as db:
            db.execute("DELETE FROM clue_read_checkpoints WHERE id=?", (identity,))
        replay = repository_clues(ROOT, claim, checkpoint=first["checkpoint"])
        self.assertEqual(replay["brief"]["checkpointStatus"], "cache-miss")
        self.assertGreater(replay["brief"]["counts"]["counter"], 0)
        self.assertTrue(replay["brief"]["families"])
        with _database(ROOT) as db:
            db.execute("UPDATE clue_read_checkpoints SET body='{}' WHERE id=?", (identity,))
        with self.assertRaisesRegex(ValueError, "cache identity mismatch"):
            repository_clues(ROOT, claim, checkpoint=first["checkpoint"])

    def test_folded_scope_read_finishes_without_redisplaying_families(self):
        source = '''(define-evidence (query)
          (sources clue attested) (outputs question)
          (include clue-selection-schema)
          (relation question (claim))
          ((question C) <-- (clue I D C _ _ _) (attested I D _)))'''
        packet = repository_clues(ROOT, selector=source, display_bytes=8192)
        self.assertFalse(packet["brief"]["presentationComplete"])
        seen = set()
        expected = set(packet["brief"]["scopeReference"]["claims"])
        for _ in range(len(expected) + 1):
            brief = packet["brief"]
            shown = {family["claim"] for family in brief["families"]}
            self.assertFalse(shown & seen)
            self.assertTrue(shown or brief["presentationComplete"])
            seen.update(shown)
            if brief["presentationComplete"]:
                break
            packet = repository_clues(ROOT, selector=source, display_bytes=8192,
                                      checkpoint=packet["checkpoint"])
        self.assertEqual(seen, expected)
        claim = next(iter(expected))
        smaller = repository_clues(ROOT, claim, checkpoint=packet["checkpoint"])
        self.assertEqual(smaller["brief"]["mode"], "rescope")
        self.assertEqual(smaller["brief"]["delta"]["removed"], 0)
        self.assertEqual(smaller["brief"]["families"], [])
        wider = repository_clues(ROOT, selector=source, checkpoint=smaller["checkpoint"])
        self.assertEqual(wider["brief"]["families"], [])
        novel = repository_clues(ROOT, "unexplored-caller-owned-hypothesis",
                                 checkpoint=wider["checkpoint"])
        self.assertTrue(novel["brief"]["explorationOpen"])
        self.assertTrue(novel["brief"]["families"][0]["unknown"])

    def test_managed_folded_read_does_not_acknowledge_unshown_evidence(self):
        first = repository_clues(ROOT, selector=FACTOR_QUERY,
                                 bindings=(("entity", "stack-entry"),))
        self.assertFalse(first["brief"]["presentationComplete"])
        second = repository_clues(ROOT, selector=FACTOR_QUERY,
            bindings=(("entity", "stack-entry"),), checkpoint=first["checkpoint"])
        self.assertTrue(second["brief"]["families"] or second["brief"]["deferred"])

    def test_managed_public_read_rejects_source_writes_and_remains_usable(self):
        from ascent import EngineError
        invalid = FACTOR_QUERY[:-1] + '\n ((clue I D C P R S) <-- (clue I D C P R S)))'
        with self.assertRaisesRegex(EngineError, "source relation"):
            repository_clues(ROOT, selector=invalid)
        recovered = repository_clues(ROOT, selector=FACTOR_QUERY,
                                     bindings=(("entity", "stack-entry"),))
        self.assertGreater(recovered["brief"]["counts"]["support"], 0)

    def test_library_input_schema_matches_explicit_consumer_declarations(self):
        source = '''(define-evidence (consumer-query)
          (sources clue factor binding) (outputs question)
          (include clue-selection-schema)
          (relation question (claim))
          ((question C) <-- (clue I D C _ _ _) (factor I D N V) (binding N V)))'''
        bindings = (("mechanism", "manual-label-base"),)
        explicit = repository_clues(ROOT, selector=FACTOR_QUERY, bindings=bindings)
        shared = repository_clues(ROOT, selector=source, constructor="consumer-query", bindings=bindings)
        for field in ("counts", "families", "deferred"):
            self.assertEqual(shared["brief"][field], explicit["brief"][field])
        self.assertGreater(shared["brief"]["counts"]["counter"], 0)

    def test_first_variable_query_needs_no_prior_claim_or_factor_identifiers(self):
        source = '''(define-evidence (query)
          (sources clue attested) (outputs question)
          (include clue-selection-schema)
          (relation question (claim))
          ((question C) <-- (clue I D C _ _ _) (attested I D _)))'''
        with patch("gambit_smp.trajectory_exploration.catalog",
                   side_effect=AssertionError("no vocabulary discovery prerequisite")):
            result = repository_clues(ROOT, selector=source)
        brief = result["brief"]
        self.assertGreater(brief["counts"]["support"], 0)
        self.assertGreater(brief["counts"]["counter"], 0)
        self.assertTrue(brief["families"] or brief["deferred"])
        self.assertTrue(brief["explorationOpen"])
        self.assertFalse(brief["runtimeAdmitted"])

    def test_repository_logical_query_can_join_source_lock_and_failed_premise(self):
        query = '''(define-evidence (query)
          (sources clue factor link attested binding) (outputs question trace)
          (relation clue (id digest claim polarity role source))
          (relation factor (id digest name value))
          (relation link (from to label id digest))
          (relation attested (id digest receipt))
          (relation binding (name value))
          (relation question (claim))
          (relation trace (claim lock premise path digest receipt))
          ((trace C Lock Premise Path D R) <--
            (clue I D C (lit "support") (lit "observation") Path)
            (attested I D R) (factor I D (lit "candidate") (lit "poll-kind"))
            (factor I D (lit "sourceLock") Lock)
            (factor I D (lit "unresolved-premise") Premise))
          ((question C) <-- (trace C _ _ _ _ _)))'''
        with engine_api() as (engine, _):
            result = repository_clues(ROOT, None, engine, selector=query)
            first = result["brief"]
            second = repository_clues(ROOT, None, engine, selector=query,
                                      checkpoint=result["checkpoint"])
        self.assertEqual(first["counts"]["support"], 1)
        self.assertTrue(first["association"]["trace"])
        self.assertEqual(first["families"][0]["claim"], "poll-kind-failed-under-recorded-lock")
        self.assertEqual(second["brief"]["families"], [])

    def test_repository_unmapped_anchor_is_a_declared_gap_not_absence(self):
        with engine_api() as (engine, _):
            result = repository_clues(ROOT, None, engine, bindings=[["mechanism", "novel-unlisted-mechanism"]],
                                      selector=FACTOR_QUERY)
        evidence = result["brief"]
        self.assertEqual(evidence["association"]["unknown_binding"], [["mechanism", "novel-unlisted-mechanism"]])
        self.assertEqual(evidence["families"], [])
        self.assertTrue(evidence["explorationOpen"])

    def test_root_progress_failure_is_visible_without_inventing_a_gc_cause(self):
        result = repository_clues(ROOT, selector=FACTOR_QUERY,
            bindings=[["failure", "complete-root-progress-window-exhausted"]])
        brief = result["brief"]
        self.assertEqual(brief["counts"]["support"], 1)
        family = brief["families"][0]
        self.assertEqual(family["claim"], "partial-root-completion-before-progress-timeout")
        observation = family["observations"][0]
        record = json.loads((ROOT / observation["source"]).read_text())
        self.assertEqual(observation["digest"], digest(ROOT / observation["source"]))
        self.assertEqual(record["completedRoots"], 503)
        self.assertEqual(record["incompleteRoots"], 4497)
        self.assertEqual(observation["factors"]["sourceLock"], [record["sourceLockSha256"]])
        self.assertFalse(record["causeEstablished"])
        self.assertIn("root-dependency-liveness", {link["claim"] for link in family["links"]})
        cause = repository_clues(ROOT, "root-progress-timeout-establishes-gc-deadlock")
        self.assertEqual(cause["brief"]["counts"]["counter"], 1)
        self.assertEqual(cause["brief"]["counts"]["support"], 0)
        remaining = repository_clues(ROOT, "root-dependency-liveness")
        self.assertTrue(remaining["brief"]["families"][0]["unknown"])
        self.assertFalse(remaining["brief"]["runtimeAdmitted"])

    def test_compact_source_binding_does_not_require_scoped_history(self):
        with patch("gambit_smp.trajectory_exploration.read_trajectory_clues") as journal, \
                engine_api() as (engine, _):
            result = repository_clues(ROOT, "manual-label-base-mismatch-is-unexplored", engine)
        journal.assert_not_called()
        self.assertEqual(result["brief"]["counts"]["counter"], 1)
        self.assertFalse(result["brief"]["runtimeAdmitted"])

    def test_reviewed_pointer_unit_counterexample_does_not_establish_native_origin(self):
        result = repository_clues(ROOT, "half-section-word-count-is-a-byte-offset")
        brief = result["brief"]
        self.assertEqual(brief["counts"]["counter"], 1)
        self.assertEqual(brief["counts"]["support"], 0)
        observation = brief["families"][0]["observations"][0]
        self.assertEqual(observation["factors"]["scope"],
                         ["source-semantics-conditional-not-native-origin"])
        self.assertEqual(observation["digest"], digest(ROOT / observation["source"]))
        origin = repository_clues(ROOT, "same-image-pointer-origin-and-instruction-binding")
        self.assertTrue(origin["brief"]["families"][0]["unknown"])
        self.assertFalse(origin["brief"]["runtimeAdmitted"])

    def test_same_claim_does_not_join_conditions_from_different_observations(self):
        selector = '''(define-evidence (query)
          (sources clue factor binding) (outputs question witness)
          (include clue-selection-schema)
          (relation question (claim))
          (relation witness (claim id digest stage outcome))
          ((witness C I D S O) <-- (clue I D C _ _ _)
            (factor I D (lit "candidate") (lit "prepare-origin"))
            (factor I D (lit "stage") S) (binding (lit "stage") S)
            (factor I D (lit "outcome") O) (binding (lit "outcome") O))
          ((question C) <-- (witness C _ _ _ _)))'''
        claim = "first-return-address-producer-unidentified"
        cases = (
            ("compiled-stress", "DENY", "prepare-origin-native-failure",
             "evidence/fixtures/darwin-stack-prepare-origin/native-observation-20261018.json"),
            ("bootstrap-publication", "STALE", "prepare-origin-not-admitted",
             "evidence/fixtures/darwin-stack-prepare-origin/bootstrap-input-drift-20261016.json"),
        )
        with engine_api() as (engine, _):
            for stage, outcome, identity, path in cases:
                result = repository_clues(ROOT, engine=engine, selector=selector,
                    bindings=[["stage", stage], ["outcome", outcome]])
                self.assertEqual(result["brief"]["association"]["witness"],
                    [[claim, identity, digest(ROOT / path), stage, outcome]])
            mixed = repository_clues(ROOT, engine=engine, selector=selector,
                bindings=[["stage", "compiled-stress"], ["outcome", "STALE"]])
        self.assertEqual(mixed["brief"]["association"]["question"], [])
        self.assertEqual(mixed["brief"]["association"]["witness"], [])
        self.assertEqual(mixed["brief"]["families"], [])
        self.assertTrue(mixed["brief"]["explorationOpen"])

    def test_preparation_chain_preserves_stale_bootstrap_and_unresolved_producer(self):
        stale = repository_clues(ROOT, "first-return-address-producer-unidentified")
        observation = next(row for row in stale["brief"]["families"][0]["observations"]
                           if row["id"] == "prepare-origin-not-admitted")
        self.assertEqual(observation["factors"]["producer-admitted"], ["false"])
        self.assertEqual(observation["factors"]["applicability"], ["historical-input-drift-run-only"])
        successor = ROOT / observation["factors"]["superseded-by-reference"][0]
        self.assertEqual(observation["factors"]["superseded-by-digest"], [digest(successor)])
        qualified = json.loads(successor.read_text())
        self.assertEqual(qualified["completionRevalidation"]["recordedOutcome"], "DENY")
        self.assertFalse(qualified["completionRevalidation"]["failedStagesRecovered"])
        self.assertEqual(observation["factors"]["outcome"], ["STALE"])
        self.assertEqual(observation["factors"]["changed-input"],
                         ["evidence/research/suite-review-rules.ss"])
        record = json.loads((ROOT / observation["source"]).read_text())
        self.assertEqual(record["nativeCommand"]["exit"], 0)
        self.assertFalse(record["publication"]["producerExported"])
        self.assertIn("last-preparation-call-and-return-label",
                      observation["factors"]["unresolved-premise"])
        self.assertIn("stable-source-bound-producer",
                      observation["factors"]["unresolved-premise"])
        self.assertFalse(stale["brief"]["runtimeAdmitted"])

    def test_native_preparation_site_preserves_failed_stress_and_ra_role(self):
        result = repository_clues(ROOT, "first-return-address-producer-unidentified")
        row = next(item for item in result["brief"]["families"][0]["observations"]
                   if item["id"] == "prepare-origin-native-failure")
        record = json.loads((ROOT / row["source"]).read_text())
        self.assertEqual(row["factors"]["last-preparation-line"], ["8078"])
        self.assertEqual(row["factors"]["ra-role"], ["write-time-register-not-preparation-caller"])
        stress = record["compiledStress"]
        self.assertEqual((stress["passedFiles"], stress["abortedFiles"], stress["timedOutFiles"]), (2, 1, 1))
        for path, sha in stress["retainedLogs"].items():
            self.assertEqual(digest(ROOT / path), sha)
        stderr = ROOT / "evidence/fixtures/darwin-stack-prepare-origin/native-stress-20261018/suite-0-0.stderr"
        self.assertIn("prepare_line=" + str(record["record"]["prepareLine"]), stderr.read_text())
        self.assertFalse(stress["unchangedRetryAdmitted"])
        self.assertFalse(result["brief"]["runtimeAdmitted"])


if __name__ == "__main__":
    unittest.main()
