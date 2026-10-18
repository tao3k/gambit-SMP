"""Real lifecycle inference and action transport; no native repair admission."""
import json
from pathlib import Path
import tempfile
import unittest
import uuid
from unittest.mock import patch

from gambit_smp.framework import ROOT
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load, evaluate as view_query
from gambit_smp import research_actions
from tests.historical_view import projection


VIEW = "evidence/scenarios/runtime-lifecycle/continuation-source-015.view.json"


class EvidenceViewTests(unittest.TestCase):
    def test_checked_reference_metadata_is_a_configurable_native_source(self):
        from gambit_smp.framework import digest
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            folder = root / "evidence"
            folder.mkdir()
            record = folder / "record.json"
            record.write_text('{"observation":"retained"}')
            (folder / "sources.ss").write_text('''(define-evidence (make)
              (sources origin) (outputs origin)
              (relation origin ((id string?) (path string?) (digest string?))))''')
            (folder / "components.json").write_text(json.dumps({
                "schema": "ascent.evidence-components.v1", "components": [
                    {"id": "sources", "source": "sources.ss", "exports": ["make"], "dependencies": []}]}))
            document = {"schema": "ascent.evidence-view.v1", "id": "metadata",
                        "manifest": "evidence/components.json", "entry": "sources", "constructor": "make",
                        "facts": {"origin": {"references": True}}, "queries": {"origins": "origin"},
                        "references": [{"id": "record", "path": "evidence/record.json",
                                        "sha256": digest(record), "pointer": None}]}
            path = folder / "view.json"
            path.write_text(json.dumps(document))
            with engine_api() as (engine, _):
                result = view_query(root, "evidence/view.json", engine)
            self.assertEqual(result["answers"]["origins"], [("record", "evidence/record.json", digest(record))])
            record.write_text('{"observation":"changed"}')
            with self.assertRaisesRegex(ValueError, "reference changed"):
                load(root, "evidence/view.json")

    def test_registered_selection_is_byte_bound_without_loading_code(self):
        from gambit_smp.evidence_views import registry
        from gambit_smp.framework import digest
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "evidence/selection.ss"
            source.parent.mkdir()
            source.write_text("not executable during registry discovery")
            declaration = {"schema": "ascent.evidence-views.v1", "views": [],
                           "selection": {"source": "evidence/selection.ss", "constructor": "query"}}
            path = root / "evidence/views.json"
            path.write_text(json.dumps(declaration))
            _, first = registry(root)
            self.assertEqual(first[str(source.resolve())], digest(source))
            source.write_text("different declaration")
            _, changed = registry(root)
            self.assertNotEqual(first, changed)
            declaration["selection"]["source"] = "../outside.ss"
            path.write_text(json.dumps(declaration))
            with self.assertRaises(ValueError):
                registry(root)

    def test_retired_view_is_never_current_even_with_local_observations(self):
        from gambit_smp.framework import digest
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            view_name = "evidence/scenarios/retired.view.json"
            view = root / view_name
            view.parent.mkdir(parents=True)
            view.write_text('{"schema":"retired-example"}')
            observed = root / "evidence/observed.json"
            observed.write_text('{"status":"recorded"}')
            registry = root / "evidence/views.json"
            registry.write_text(json.dumps({"schema": "ascent.evidence-views.v1",
                "views": [], "historical": [{"path": view_name, "sha256": digest(view)}]}))
            with self.assertRaisesRegex(ValueError, "historical Evidence view is not current"):
                load(root, view_name)
            with self.assertRaisesRegex(ValueError, "historical Evidence view is not a current action input"):
                research_actions.discover(root, {"views": [view_name]})
            view.write_text('{"schema":"changed"}')
            with self.assertRaisesRegex(ValueError, "historical Evidence view changed"):
                load(root, view_name)

    def test_historical_views_are_bound_but_not_current(self):
        from gambit_smp.evidence_views import registry
        from gambit_smp.framework import digest
        names, inputs = registry(ROOT)
        document = json.loads((ROOT / "evidence/views.json").read_text())
        self.assertTrue(document["historical"])
        for row in document["historical"]:
            source = ROOT / row["path"]
            self.assertNotIn(row["path"], names)
            self.assertEqual(inputs[str(source)], digest(source))
        changed = ROOT / document["historical"][0]["path"]
        original = digest
        with patch("gambit_smp.evidence_views.digest",
                   side_effect=lambda path: "0" * 64 if path == changed else original(path)):
            with self.assertRaisesRegex(ValueError, "historical Evidence view changed"):
                registry(ROOT)

    def test_historical_view_and_missing_sources_remain_denied(self):
        from gambit_smp.framework import digest
        history = json.loads((ROOT / "evidence/scenarios/runtime-lifecycle/history-015.json").read_text())
        self.assertEqual(digest(ROOT / history["priorView"]), history["priorViewSha256"])
        self.assertEqual(history["outcome"], "DENY")
        self.assertEqual(len(history["missingReferences"]), 6)
        with self.assertRaisesRegex(ValueError, "regular observed artifact required"):
            load(ROOT, history["priorView"])
        with self.assertRaisesRegex(ValueError, "historical Evidence view"):
            load(ROOT, VIEW)
        document, facts, _, inputs = projection(ROOT, VIEW)
        self.assertEqual(facts["satisfies"], [])
        observation = next(ref for ref in document["references"] if ref["id"] == "candidate-identity")
        self.assertEqual(facts["satisfies"], [])
        if (ROOT / observation["path"]).is_file():
            self.assertEqual(digest(ROOT / observation["path"]), observation["sha256"])
        self.assertIn(str(ROOT / observation["path"]), inputs)

    def test_delegated_api_boundary_checks_before_after_and_resets(self):
        from gambit_smp.ascent_program import sealed_api_boundary, _verified_api
        with tempfile.TemporaryDirectory() as directory:
            with patch("gambit_smp.research_kernel.execution_identity",
                       side_effect=[{"engineId": "first"}, {"engineId": "changed"}]) as checked:
                with self.assertRaisesRegex(ValueError, "seal changed"):
                    with sealed_api_boundary(Path(directory)):
                        self.assertIsNotNone(_verified_api.get())
                self.assertEqual(checked.call_count, 2)
                self.assertIsNone(_verified_api.get())
            with patch("gambit_smp.research_kernel.execution_identity",
                       return_value={"engineId": "first"}) as checked:
                with self.assertRaisesRegex(RuntimeError, "body failure"):
                    with sealed_api_boundary(Path(directory)):
                        raise RuntimeError("body failure")
                self.assertEqual(checked.call_count, 2)
                self.assertIsNone(_verified_api.get())

    def test_shared_qnt_import_is_bound_and_drift_rejected(self):
        from gambit_smp import review_inputs
        from gambit_smp.framework import digest
        manifest = json.loads((ROOT / review_inputs.RAW_LOG_MANIFEST).read_text())
        entry = next(row for row in manifest["receipts"] if row["model"] == "gc_work_closure")
        receipt = json.loads((ROOT / entry["receipt"]).read_text())
        bound = review_inputs.checked_model_input_closure(ROOT, receipt)
        shared = "models/library/gc/WorkObligations.qnt"
        self.assertEqual(bound[shared], digest(ROOT / shared))
        def changed(path):
            return "0" * 64 if path == ROOT / shared else digest(path)
        with patch.object(review_inputs, "digest", side_effect=changed):
            with self.assertRaisesRegex(ValueError, "input closure identity mismatch"):
                review_inputs.checked_model_input_closure(ROOT, receipt)

    def test_three_flags_lifecycle_and_withdrawal(self):
        document, facts, catalog, inputs = projection(ROOT, VIEW)
        with engine_api() as (engine, _):
            before, first = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(len(before["configured"]), 1)
            self.assertEqual(before["missing_flag"], [])
            self.assertEqual(len(before["missing"]), 10)
            self.assertEqual(len(before["missing_metric"]), 6)
            self.assertIn(("vm-destruction", "work-publication"), before["dependency_path"])
            self.assertEqual(len(before["comparison"]), 4)
            changed, _ = evaluate(engine, dict(facts, flag=facts["flag"][:-1]), catalog, document["queries"])
            self.assertEqual(changed["configured"], [])
            self.assertEqual(len(changed["missing_flag"]), 1)
            restored, last = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(before, restored)
            self.assertEqual(first["sessionOwner"], last["sessionOwner"])
            self.assertGreater(last["sourceGeneration"], first["sourceGeneration"])
        self.assertGreater(len(inputs), 950)

    def test_real_actions_select_and_observe(self):
        from gambit_smp.artifact_storage import cache_path, database_path
        parent = cache_path(ROOT, 'tests')
        parent.mkdir(parents=True, exist_ok=True)
        scratch = tempfile.TemporaryDirectory(prefix='evidence-actions-', dir=parent)
        self.addCleanup(scratch.cleanup)
        def isolated_database(root, name, previous):
            if name == 'research-actions/requests.sqlite':
                return Path(scratch.name) / 'requests.sqlite'
            return database_path(root, name, previous)
        isolation = patch('gambit_smp.artifact_storage.database_path', side_effect=isolated_database)
        isolation.start()
        self.addCleanup(isolation.stop)
        with self.assertRaisesRegex(ValueError, "historical Evidence view"):
            research_actions.discover(ROOT, {"views": [VIEW]})
        context = {"views": ["evidence/scenarios/concurrent-gc/darwin-source-032.view.json"]}
        first = research_actions.discover(ROOT, context)
        repeated = research_actions.discover(ROOT, context)
        self.assertEqual(first["revision"], repeated["revision"])
        initial_owner = next(iter(first["viewExplanations"].values()))["sessionOwner"]
        reused_owner = next(iter(repeated["viewExplanations"].values()))["sessionOwner"]
        self.assertEqual(initial_owner, reused_owner)
        self.assertEqual(len(first["actions"]), 11)
        chosen = next(row for row in first["actions"] if row["query"] == "missing_metric")
        self.assertEqual(chosen["risk"], "read-only")
        self.assertFalse(chosen["explanation"]["executionAuthorized"])
        handle = str(uuid.uuid4())
        result = research_actions.select(ROOT, first, chosen["id"], {}, handle, authorize_execution=True)
        self.assertEqual(result["result"]["outcome"], "RECORDED")
        observation = research_actions.observe(ROOT, handle)
        self.assertEqual(observation["result"]["inspection"]["status"], "CURRENT")
        receipt = json.loads(Path(result["result"]["receipt"]).read_text())
        self.assertEqual(len(receipt["answers"]), 6)
        self.assertFalse(receipt["runtimeAdmitted"])

    def test_digest_failure_precedes_inference(self):
        document = json.loads((ROOT / VIEW).read_text())
        document["references"][0]["sha256"] = "0" * 64
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", dir=ROOT / "evidence") as file:
            json.dump(document, file)
            file.flush()
            with self.assertRaisesRegex(ValueError, "reference changed"):
                load(ROOT, str(Path(file.name).relative_to(ROOT)))


if __name__ == "__main__":
    unittest.main()
