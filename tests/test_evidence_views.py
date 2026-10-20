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
    def test_scoped_archive_remains_readable_after_original_sources_are_removed(self):
        from gambit_smp import evidence_interface
        from gambit_smp.framework import digest
        for packaged in (False, True):
            with self.subTest(packaged=packaged), tempfile.TemporaryDirectory() as directory:
                root = Path(directory).resolve()
                folder, out = root / "evidence", root / "archive"
                folder.mkdir()
                out.mkdir()
                source = "(define-evidence (make) (sources input) (outputs input) (relation input (value)))"
                components = [{"id": "chosen", "source": "chosen.ss", "exports": ["make"], "dependencies": []},
                              {"id": "unused", "source": "unused.ss", "exports": [], "dependencies": []}]
                facts, queries = {"input": [[7]]}, {"checked": "input"}
                if packaged:
                    source = "(define-evidence (make) (sources requirement) (outputs unclosed) (include evidence-checkpoint-fragment))"
                    components[0]["dependencies"] = [{"component": "library", "bindings": ["evidence-checkpoint-fragment"]}]
                    components.append({"id": "library", "source": "package:ascent/checkpoint_rules.ss",
                                       "exports": ["evidence-checkpoint-fragment"], "dependencies": []})
                    facts, queries = {"requirement": [["open"]]}, {"checked": "unclosed"}
                (folder / "chosen.ss").write_text(source)
                (folder / "unused.ss").write_text("(malformed unused source")
                (folder / "components.json").write_text(json.dumps({"schema": "ascent.evidence-components.v1", "components": components}))
                (folder / "view.json").write_text(json.dumps({"schema": "ascent.evidence-view.v1", "id": "archive-fixture",
                    "manifest": "evidence/components.json", "entry": "chosen", "constructor": "make",
                    "facts": facts, "queries": queries, "references": []}))
                with engine_api() as (engine, _):
                    view = view_query(root, "evidence/view.json", engine)
                bound = {str(Path(path).relative_to(root)) if Path(path).is_relative_to(root) else path: sha
                         for path, sha in view["inputs"].items()}
                artifacts = evidence_interface.write(root, out, [view], bound)
                for name in ("review.json", "graph.json", "context.md", "graph.mmd"):
                    path = out / name
                    path.write_text("fixture outer envelope")
                    artifacts[name] = {"path": name, "sha256": digest(path)}
                review = {"evidenceViews": [view], "agentGraph": {"checkout": {"root": str(root)}}}
                import shutil
                shutil.rmtree(folder)
                restored = evidence_interface.read(out, artifacts, review)
                self.assertEqual(restored["views"][0]["entry"], "chosen")
                self.assertNotIn("unused", {item["declaration"]["id"] for item in restored["views"][0]["components"]})

    def test_native_stress_witnesses_keep_the_positive_qualification_contract(self):
        registry = json.loads((ROOT / "evidence/views.json").read_text())
        checked = 0
        for name in registry["views"]:
            view = json.loads((ROOT / name).read_text())
            # Relation names are local to their Evidence component. The Zig
            # observation relation references citations in a different column.
            if view["entry"] != "stack-entry-clues":
                continue
            references = {row["id"]: row for row in view["references"]}
            for _, claim, polarity, reference in view["facts"].get("observation", []):
                path = ROOT / references[reference]["path"]
                if path.suffix != ".json":
                    continue
                observation = json.loads(path.read_text())
                if observation.get("schema") != "gambit.native-stress-observation.v1":
                    continue
                checked += 1
                self.assertTrue(claim.endswith("-stress-qualified"), (name, claim))
                self.assertEqual(polarity,
                                 "support" if observation["nativeStressEstablished"] else "counter",
                                 (name, claim))

        self.assertGreater(checked, 0)

    def test_executed_declarations_do_not_project_obsolete_unexecuted_status(self):
        registry = json.loads((ROOT / "evidence/views.json").read_text())
        for name in registry["views"]:
            facts = json.loads((ROOT / name).read_text())["facts"]
            executed = {row[0] for row in facts.get("edge", [])
                        if row[2] == "declared-route-executed"}
            for identity, attribute, value in facts.get("attribute", []):
                if identity in executed and attribute == "outcome":
                    self.assertNotEqual(value, "DECLARED_NOT_EXECUTED", (name, identity))

    def test_registered_repository_views_do_not_require_local_cache_artifacts(self):
        document = json.loads((ROOT / "evidence/views.json").read_text())
        for name in document["views"]:
            view = json.loads((ROOT / name).read_text())
            for reference in view["references"]:
                self.assertNotIn(Path(reference["path"]).parts[0], (".cache", ".data"),
                                 (name, reference["path"]))

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
        with self.assertRaisesRegex(ValueError, "regular observed artifact required|Evidence view reference changed"):
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

    def test_retired_model_snapshot_is_exact_and_cannot_admit_current_source(self):
        from gambit_smp.framework import digest
        archive = ROOT / "models/gambit/history/vm_registry_cross_vm_progress.qnt"
        self.assertEqual(digest(archive), "a73d3cb1ba57383689b5780b6671210efec2fbb99e37192cfafc4ad06ff50a3d")
        self.assertNotEqual(digest(archive), digest(ROOT / "models/gambit/vm_registry_cross_vm_progress.qnt"))
        with self.assertRaisesRegex(ValueError, "historical Evidence view"):
            load(ROOT, VIEW)
        original = digest
        with patch("tests.historical_view.digest",
                   side_effect=lambda path: "0" * 64 if path == archive else original(path)):
            with self.assertRaisesRegex(ValueError, "historical reference changed"):
                projection(ROOT, VIEW)

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
        from gambit_smp.artifact_storage import cache_path
        parent = cache_path(ROOT, 'tests')
        parent.mkdir(parents=True, exist_ok=True)
        scratch = tempfile.TemporaryDirectory(prefix='evidence-actions-', dir=parent)
        self.addCleanup(scratch.cleanup)
        isolation = patch('gambit_smp.research_actions._request_database_path',
                          return_value=Path(scratch.name) / 'requests.sqlite')
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
