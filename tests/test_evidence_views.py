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
from tests.historical_view import projection, captured_source


VIEW = "evidence/scenarios/runtime-lifecycle/continuation-source-015.view.json"


class EvidenceViewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import opensysml
        from gambit_smp.model_binding import api_binding
        from gambit_smp.source_identity import read_source
        captures = json.loads((ROOT / 'tests/fixtures/historical-view-pointers.json').read_text())
        captured = captures['evidence/scenarios/modern-c/request-product.view.json']
        record = json.loads(read_source(ROOT, captured['binding']))
        # The service is needed only for these two projections, not while
        # later native ASCENT/Git consumers execute their own subprocesses.
        with opensysml.connect(
            version=record['sdkObservation']['serverVersion'],
            require_capabilities=['parse_sources', 'strict_conformance']) as connection:
            cls.model_binding = api_binding(connection, ROOT, record,
                source_identities=captured['modelSources'])
            current = json.loads((ROOT / 'evidence/research/retained/modern-c/post-delivery/current-model-binding.json').read_text())
            cls.current_model_binding = api_binding(connection, ROOT, current)

    def test_current_plan_and_frozen_binding_have_distinct_native_source_epochs(self):
        key = 'dev/refactoring/modern-c/models/sysml/pending-cuts.sysml'
        self.assertNotEqual(self.model_binding['inputs'][key],
                            self.current_model_binding['inputs'][key])
        fields = self.current_model_binding['expressions']
        self.assertEqual(len(fields['GambitPendingCuts::currentPackages'].split(';')), 9)
        self.assertEqual(len(fields['GambitPendingCuts::currentRoutes'].split(';')), 12)
        self.assertIn('1/12', fields['GambitPendingCuts::independentSmpProgress'])
        self.assertIn('not', fields['GambitPendingCuts::snapshotBoundary'])

    def test_modern_c_candidate_uses_real_library_without_branch_admission(self):
        name = 'evidence/scenarios/modern-c/request-product.view.json'
        with engine_api() as (engine, _):
            result = view_query(ROOT, name, engine)
        claims = {(row[2], row[3]) for row in result['answers']['clue']}
        self.assertIn(('modern-c-retained-candidate-bootstrap-complete', 'support'), claims)
        for claim in ('modern-c-current-working-tree-native-qualified',
                      'modern-c-fourth-whole-delivery-admitted',
                      'modern-c-retained-candidate-cold-monolithic-check-passed'):
            self.assertIn((claim, 'counter'), claims)
            self.assertNotIn((claim, 'support'), claims)
        self.assertIn(('modern-c-original-profile-independently-reconstructible', 'support'), claims)
        self.assertFalse(result['runtimeAdmitted'])
        self.assertFalse(result['executionAuthorized'])
        assurance = result['assurance']
        self.assertEqual(assurance['inference']['status'], 'native-ascent-completed')
        from gambit_smp.branch_evidence import content_digest
        self.assertEqual(assurance['references']['inputIdentity'], content_digest(result['inputs']))
        self.assertEqual(assurance['references']['inputCount'], len(result['inputs']))
        self.assertEqual(assurance['assertions']['status'],
                         'caller-declared-not-semantically-validated')
        self.assertEqual(assurance['nativeExecution']['status'], 'not-established-by-query')
        checked = next(row['assessment'] for row in assurance['evidence']
                       if row['referenceId'] == 'priority-cases')
        self.assertEqual(checked['outcomes'], dict(PASS=39, FAIL=2, UNRESOLVED=0))
        self.assertEqual(checked['expectedCounterexamplesMatched'], 2)
        self.assertFalse(checked['runtimeAdmitted'])

    def test_modern_c_incomplete_inference_cannot_issue_query_assurance(self):
        name = 'evidence/scenarios/modern-c/request-product.view.json'
        with patch('gambit_smp.ascent_program.evaluate',
                   side_effect=ValueError('native ASCENT investigation deadline incomplete')):
            with self.assertRaisesRegex(ValueError, 'deadline incomplete'):
                view_query(ROOT, name, None)

    def test_modern_c_changed_working_reference_blocks_the_recorded_view(self):
        from gambit_smp.framework import digest
        from gambit_smp.evidence_views import ReferenceUnavailable
        name = 'evidence/scenarios/modern-c/request-product.view.json'
        document = json.loads((ROOT / name).read_text())
        working = next(row for row in document['references']
                       if row.get('origin') == 'observed-artifact')
        changed = ROOT / working['path']
        read_bytes = Path.read_bytes
        with patch.object(Path, 'read_bytes',
                   lambda path: b'changed input' if path == changed else read_bytes(path)):
            with self.assertRaises(ReferenceUnavailable):
                load(ROOT, name)

    def test_modern_c_failed_record_validation_blocks_inference(self):
        from gambit_smp.evidence_views import ReferenceUnavailable
        with patch('gambit_smp.branch_evidence.validate_recorded_cases',
                   side_effect=ValueError('forged passing verdict')):
            with self.assertRaises(ReferenceUnavailable) as rejected:
                load(ROOT, 'evidence/scenarios/modern-c/request-product.view.json')
        self.assertTrue(any(row['reason'] == 'record-validation-failed'
                            for row in rejected.exception.references))

    def test_modern_c_profile_summary_does_not_impersonate_original_bytes(self):
        from gambit_smp.framework import digest
        folder = ROOT / 'evidence/research/retained/modern-c/request-product'
        source = json.loads((folder / 'source.json').read_text())
        observed = json.loads((ROOT / source['profileSource']).read_text())
        self.assertEqual(source['profileSourceKind'], 'parsed-observation-not-original-input')
        self.assertEqual(source['profileReconstruction'], 'exact-input-from-existing-committed-fixture')
        self.assertEqual(source['profileSha256'], observed['inputSha256'])
        prior = observed['priorMisassociation']
        self.assertEqual(digest(ROOT / prior['path']), prior['sha256'])
        self.assertNotEqual(prior['sha256'], observed['inputSha256'])
        self.assertNotEqual(digest(ROOT / source['profileSource']), observed['inputSha256'])
        import hashlib
        recipe = observed['reconstruction']
        fixture_bytes = (ROOT / recipe['fixture']).read_bytes()
        self.assertEqual(hashlib.sha256(fixture_bytes).hexdigest(), recipe['identity']['sha256'])
        fixture = json.loads(fixture_bytes)
        encoded = (json.dumps({**fixture, **recipe['overlay']}, indent=2) + '\n').encode()
        self.assertEqual(hashlib.sha256(encoded).hexdigest(), observed['inputSha256'])

    def test_modern_c_metrics_replay_existing_normalizer_without_speedup_credit(self):
        from gambit_smp.framework import digest
        from gambit_smp.revision_matrix import normalize_matrix
        folder = ROOT / 'evidence/research/retained/modern-c/request-product'
        source = json.loads((folder / 'source.json').read_text())
        raw = json.loads((folder / 'metric-observations.json').read_text())
        for reference in raw['sourceReferences']:
            self.assertEqual(digest(ROOT / reference['path']), reference['sha256'])
        producer = json.loads((folder / 'current-producer.json').read_text())
        for metric, stage in [('bootstrap', 'source-bootstrap'), ('core', 'stock-core')]:
            observation = next(row for row in producer['checks'] if row['stage'] == stage)
            self.assertEqual(raw[metric], observation['seconds'])
        result = normalize_matrix(ROOT,
            json.loads((folder / 'metric-input.json').read_text()),
            dict(baseRevision=source['vendorBase'], tree=source['candidateTree'],
                 profileSha256=source['profileSha256']),
            'id,kind,metric,unit,direction,baseline,candidate,workload,method,evidence,limitation'.split(','),
            'measurement,control,accounted-cost,structural,unmeasured'.split(','))
        self.assertEqual(result, json.loads((folder / 'metric-audit.json').read_text()))
        self.assertEqual([row['outcome'] for row in result['rows']],
                         ['candidate-only-observation', 'candidate-only-observation', 'not-measured'])

    def test_modern_c_navigation_requires_branch_and_source_on_same_observation(self):
        from gambit_smp import repository_clues
        name = 'evidence/research/retained/modern-c/request-product/source.json'
        tree = json.loads((ROOT / name).read_text())['candidateTree']
        with engine_api() as (engine, _):
            for source, expected in [(tree, True), ('0' * 40, False)]:
                result = repository_clues(ROOT, engine=engine,
                    bindings=[('branch', 'modern-c'), ('source-tree', source)],
                    display_bytes=24000)
                claims = {row['claim'] for row in result['brief']['families']}
                self.assertEqual('modern-c-unpublished-candidate-source-observed' in claims, expected)
                self.assertFalse(result['brief']['runtimeAdmitted'])
                self.assertFalse(result['brief']['executionAuthorized'])
                assurance = result['brief']['assurance']
                self.assertEqual(assurance['inference']['entry'], 'native-clue-exchange')
                self.assertEqual(assurance['inference']['sourceIdentity'],
                                 result['brief']['inputIdentity'])
                self.assertFalse(assurance['runtimeAdmitted'])
                if not expected:
                    self.assertEqual(assurance['evidence'], [])
                self.assertEqual(assurance['references']['status'],
                    'partial-reference-coverage' if assurance['references']['unavailableViews']
                    else 'byte-identities-checked')

    def test_modern_c_python_entry_exposes_only_selected_case_validation(self):
        from gambit_smp import repository_clues
        from gambit_smp.branch_evidence import validate_recorded_cases
        packet = json.loads((ROOT / 'evidence/research/retained/modern-c/request-product/priority-native-cases.json').read_text())
        with engine_api() as (engine, _):
            result = repository_clues(ROOT, engine=engine,
                bindings=[('branch', 'modern-c'), ('source-tree', packet['sourceTree'])],
                display_bytes=24000)
        checked = result['brief']['assurance']['evidence']
        row = next(item for item in checked if item['referenceId'] == 'priority-cases')
        self.assertEqual(row['assessment'], validate_recorded_cases(packet))
        self.assertFalse(result['brief']['assurance']['runtimeAdmitted'])

    def test_modern_c_native_sysml_bindings_resolve_actual_evidence_obligations(self):
        from gambit_smp.framework import digest
        name = 'evidence/scenarios/modern-c/request-product.view.json'
        view = json.loads((ROOT / name).read_text())
        from gambit_smp.source_identity import read_git_sources
        record = self.model_binding
        captured = json.loads((ROOT / 'tests/fixtures/historical-view-pointers.json').read_text())[name]
        import hashlib
        for path, data in zip(record['inputs'], read_git_sources(ROOT,
                [captured['modelSources'][path] for path in record['inputs']])):
            self.assertEqual(hashlib.sha256(data).hexdigest(), record['inputs'][path])
        observations = {row[0] for row in view['facts']['observation']}
        for component in ('priorityEvidence', 'resourceEvidence', 'propagationEvidence'):
            prefix = 'GambitRequestProduct::' + component + '.'
            self.assertEqual(record['expressions'][prefix + 'evidenceView'], name)
            self.assertLessEqual(set(record['expressions'][prefix + 'observation'].split(';')),
                                 observations)
            self.assertTrue(record['expressions'][prefix + 'component.path'].startswith('vendor/gambit/'))
        history = 'GambitRequestProduct::ownerPropagationHistory.'
        model = json.loads((ROOT / 'evidence/research/retained/modern-c/request-product/owner-closure-model.json').read_text())
        self.assertEqual(record['expressions'][history + 'source'], model['model'])
        self.assertEqual(digest(ROOT / model['model']), model['modelSha256'])
        self.assertIn('initCyclic', record['expressions'][history + 'obligation'])
        self.assertIn('Existing spatial/frame', record['expressions'][history + 'leanBoundary'])

    def test_modern_c_terminal_cases_refine_ascent_without_whole_admission(self):
        from gambit_smp.branch_evidence import terminal_status
        from gambit_smp.ascent_program import load_catalog
        folder = ROOT / 'evidence/research/retained/modern-c/request-product'
        native = json.loads((folder / 'priority-native-cases.json').read_text())
        record = json.loads((folder / 'priority-acceptance.json').read_text())
        self.assertEqual(native['sourceTree'], record['sourceTree'])
        for case in native['cases']:
            complete = case['role'] != 'historical-counterexample' and all(case['markers'].values())
            self.assertEqual(terminal_status(case['process'], contract_complete=complete),
                             case['terminalStatus'])
            if case['role'] == 'historical-counterexample':
                self.assertNotEqual(case['terminalStatus'], 'PASS')
                self.assertTrue(case['acceptedByScenario'])
            self.assertTrue(case['streamIdentitiesChecked'])
        self.assertFalse(native['branchQualified'])
        self.assertFalse(native['runtimeAdmitted'])
        catalog = load_catalog(ROOT / record['policy'])
        queries = dict(closed='acceptanceClosed', open='acceptanceOpen', ready='deliveryReady', blocked='deliveryBlocked', gap='gap')
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, record['facts'], catalog, queries)
            self.assertEqual(len(answers['closed']), len(native['cases']))
            self.assertFalse(answers['ready'])
            declared = json.loads(json.dumps(record['facts']))
            declared['deliveryGate'] = [[record['facts']['deliveryRequiresAcceptance'][0][0], gate,
                                         record['sourceTree'], record['profileSha256']]
                                       for gate in ('tests', 'learning', 'process', 'models', 'questions')]
            still_blocked, _ = evaluate(engine, declared, catalog, queries)
            self.assertFalse(still_blocked['ready'])
            self.assertEqual({row[1] for row in still_blocked['blocked']},
                             set(record['requiredFamilies']))
            wrong = json.loads(json.dumps(record['facts']))
            wrong['acceptanceObservation'][0][2] = '0' * 40
            case_id = wrong['acceptanceObservation'][0][0]
            changed, _ = evaluate(engine, wrong, catalog, queries)
            self.assertNotIn((case_id,), changed['closed'])
            self.assertIn((case_id,), changed['open'])

    def test_modern_c_owner_cycle_failure_blocks_the_whole_candidate(self):
        from gambit_smp.ascent_program import load_catalog
        from gambit_smp.framework import digest
        folder = ROOT / 'evidence/research/retained/modern-c/request-product'
        record = json.loads((folder / 'owner-plan-acceptance.json').read_text())
        self.assertEqual(digest(ROOT / record['policy']), record['policySha256'])
        self.assertEqual(digest(folder / 'owner-plan-model-binding.json'), record['modelBindingSha256'])
        with engine_api() as (engine, _):
            result = view_query(ROOT, 'evidence/scenarios/modern-c/request-product.view.json', engine)
            checked = {x['referenceId']: x['assessment'] for x in result['assurance']['evidence']}
            self.assertEqual(checked['owner-plan-cases']['positiveScenarioPasses'], 39)
            self.assertEqual(checked['owner-cycle']['outcomes'], dict(PASS=0, FAIL=1, UNRESOLVED=0))
            self.assertFalse(checked['owner-cycle']['allExpectedOutcomes'])
            from gambit_smp import repository_clues
            selected = repository_clues(ROOT, engine=engine,
                bindings=[('branch', 'modern-c'), ('source-tree', record['sourceTree'])],
                display_bytes=24000)
            selected_records = {x['referenceId']: x['assessment']
                                for x in selected['brief']['assurance']['evidence']}
            self.assertEqual(selected_records['owner-cycle']['outcomes']['FAIL'], 1)
            self.assertFalse(selected['brief']['assurance']['runtimeAdmitted'])
            facts = json.loads(json.dumps(record['facts']))
            unit = facts['deliveryRequiresAcceptance'][0][0]
            facts['deliveryGate'] = [[unit, gate, record['sourceTree'], record['profileSha256']]
                for gate in ('tests', 'learning', 'process', 'models', 'questions')]
            answers, _ = evaluate(engine, facts, load_catalog(ROOT / record['policy']),
                dict(closed='acceptanceClosed', open='acceptanceOpen', ready='deliveryReady'))
        self.assertEqual(len(answers['closed']), 41)
        self.assertIn(('cyclic-owner-gc-progress',), answers['open'])
        self.assertIn(('PRIORITY-PROPAGATION-EXIT',), answers['open'])
        self.assertFalse(answers['ready'])
        self.assertFalse(result['runtimeAdmitted'])

    def test_modern_c_owner_matrix_retains_the_failed_gc_control(self):
        from gambit_smp.revision_matrix import normalize_matrix
        folder = ROOT / 'evidence/research/retained/modern-c/request-product'
        proof = json.loads((folder / 'owner-plan.json').read_text())
        binding = self.model_binding['expressions']
        result = normalize_matrix(ROOT,
            json.loads((folder / 'owner-plan-matrix-input.json').read_text()),
            dict(baseRevision=proof['baseRevision'], tree=proof['sourceTree'],
                 profileSha256=proof['profileSha256']),
            binding['GambitCommitGates::revisionAudit.matrixFields'].split(','),
            binding['GambitCommitGates::revisionAudit.matrixKinds'].split(','))
        self.assertEqual(result, json.loads((folder / 'owner-plan-matrix.json').read_text()))
        control = next(row for row in result['rows'] if row['id'] == 'gc-cycle')
        self.assertEqual((control['baseline_value'], control['candidate_value']), ('1', '0'))
        self.assertFalse(control['generalized_performance_claim'])

    def test_modern_c_least_closure_keeps_historical_failure_and_whole_gates_separate(self):
        from gambit_smp.ascent_program import load_catalog
        from gambit_smp.framework import digest
        folder = ROOT / 'evidence/research/retained/modern-c/request-product'
        record = json.loads((folder / 'owner-closure-acceptance.json').read_text())
        historical = json.loads((folder / 'owner-plan-acceptance.json').read_text())
        self.assertNotEqual(record['sourceTree'], historical['sourceTree'])
        self.assertEqual(digest(folder / 'model-binding.json'), record['modelBindingSha256'])
        with engine_api() as (engine, _):
            result = view_query(ROOT, 'evidence/scenarios/modern-c/request-product.view.json', engine)
            checked = {x['referenceId']: x['assessment'] for x in result['assurance']['evidence']}
            self.assertEqual(checked['owner-closure-cases']['outcomes'], dict(PASS=41, FAIL=2, UNRESOLVED=0))
            self.assertEqual(checked['owner-cycle']['outcomes']['FAIL'], 1)
            facts = json.loads(json.dumps(record['facts']))
            unit = facts['deliveryUnit'][0][0]
            facts['deliveryGate'] = [[unit, gate, record['sourceTree'], record['profileSha256']]
                for gate in ('tests', 'learning', 'process', 'models', 'questions')]
            answers, _ = evaluate(engine, facts, load_catalog(ROOT / record['policy']),
                dict(closed='acceptanceClosed', open='acceptanceOpen', ready='deliveryReady'))
            self.assertIn(('PRIORITY-PROPAGATION-EXIT',), answers['closed'])
            # The published epoch has subsequently closed these two scoped
            # families. Remove their premises to retain the original refusal
            # obligation, rather than relabeling old facts as current gaps.
            self.assertIn(('WHOLE-PRODUCT',), answers['closed'])
            self.assertIn(('MATCHED-RELEASE',), answers['closed'])
            withheld = {'WHOLE-PRODUCT', 'MATCHED-RELEASE'}
            facts['acceptanceObservation'] = [row for row in facts['acceptanceObservation']
                if row[0] not in withheld]
            refused, _ = evaluate(engine, facts, load_catalog(ROOT / record['policy']),
                dict(closed='acceptanceClosed', open='acceptanceOpen', ready='deliveryReady'))
            self.assertEqual(set(refused['open']), {(name,) for name in withheld})
            self.assertFalse(refused['ready'])
            facts = json.loads(json.dumps(record['facts']))
            facts['deliveryGate'] = [[unit, gate, record['sourceTree'], record['profileSha256']]
                for gate in ('tests', 'learning', 'process', 'models')]
            incomplete, _ = evaluate(engine, facts, load_catalog(ROOT / record['policy']),
                dict(ready='deliveryReady'))
            self.assertFalse(incomplete['ready'])
        self.assertEqual(answers['ready'], [('request-product',)])
        self.assertFalse(result['runtimeAdmitted'])
        control = json.loads((folder / 'owner-closure-control.json').read_text())
        self.assertEqual({x['caseSha256'] for x in control['observations']}, {control['sameCaseSha256']})
        self.assertEqual([(x['setterReturned'], x['gcDone']) for x in control['observations']],
                         [(False, True), (False, False), (True, True)])
        self.assertTrue(control['observations'][-1]['joined'])
        self.assertFalse(control['observations'][-1]['timeout'])

    def test_modern_c_closure_matrix_is_not_a_general_speedup(self):
        from gambit_smp.revision_matrix import normalize_matrix
        folder = ROOT / 'evidence/research/retained/modern-c/request-product'
        proof = json.loads((folder / 'owner-closure.json').read_text())
        binding = self.model_binding['expressions']
        result = normalize_matrix(ROOT,
            json.loads((folder / 'owner-closure-matrix-input.json').read_text()),
            dict(baseRevision=proof['baseRevision'], tree=proof['sourceTree'], profileSha256=proof['profileSha256']),
            binding['GambitCommitGates::revisionAudit.matrixFields'].split(','),
            binding['GambitCommitGates::revisionAudit.matrixKinds'].split(','))
        self.assertEqual(result, json.loads((folder / 'owner-closure-matrix.json').read_text()))
        control = next(row for row in result['rows'] if row['id'] == 'setter-cycle')
        self.assertEqual((control['baseline_value'], control['candidate_value']), ('0', '1'))
        self.assertFalse(control['generalized_performance_claim'])
        peak = next(row for row in result['rows'] if row['id'] == 'whole-performance')
        self.assertEqual(peak['kind'], 'unmeasured')

    def test_modern_c_product_scope_and_matched_statistics_do_not_admit_whole_delivery(self):
        import statistics
        folder = ROOT / 'evidence/research/retained/modern-c/request-product'
        coverage = json.loads((folder / 'compiled-coverage.json').read_text())
        self.assertEqual(coverage['counts'], dict(PASS=407, FAIL=1))
        self.assertEqual(len(coverage['fixturePropertyCoverage']), 408)
        self.assertFalse(coverage['fullColdInvocationPassed'])
        self.assertFalse(coverage['ordinaryNumericWhole90Passed'])
        matched = json.loads((folder / 'release-matched.json').read_text())
        for name, quantity in matched['summaryMeasurements'].items():
            rows = [matched['samples'][i] for i in quantity['sampleIndices']]
            self.assertEqual(len(rows), quantity['samples'])
            self.assertEqual(len(rows), 4)
            self.assertTrue(all(row['accepted'] and row['process']['exit'] == 0
                                and not row['process']['timeout'] for row in rows))
            key = name.split('-', 2)[2]
            self.assertEqual(quantity['value'], statistics.median(row['metrics'][key] for row in rows))
        control = json.loads((folder / 'release-observations.json').read_text())
        self.assertNotEqual(matched['workloadSha256'], control['workloadSha256'])
        self.assertTrue(any(row['role'] == 'baseline' and row['processors'] == 2
                            and not row['accepted'] for row in control['samples']))
        self.assertFalse(matched['runtimeAdmitted'])
        binding = self.model_binding['expressions']
        view = json.loads((ROOT / 'evidence/scenarios/modern-c/request-product.view.json').read_text())
        observations = {row[0] for row in view['facts']['observation']}
        for component in ['productEvidence', 'releaseEvidence']:
            prefix = 'GambitRequestProduct::' + component + '.'
            self.assertLessEqual(set(binding[prefix + 'observation'].split(';')), observations)
            self.assertEqual(binding[prefix + 'evidenceView'], 'evidence/scenarios/modern-c/request-product.view.json')

    def test_current_execution_blocks_do_not_requalify_historical_summaries(self):
        name = 'evidence/scenarios/tool-reasoning/framework-execution.view.json'
        with engine_api() as (engine, _):
            result = view_query(ROOT, name, engine)
        changed = {row[0] for row in result['answers']['summary_changed']}
        current = {row[0] for row in result['answers']['summary_current']}
        for identity in ('regeneration', 'interpretation'):
            self.assertIn(identity, changed)
            self.assertNotIn(identity, current)
        self.assertFalse(result['runtimeAdmitted'])
        self.assertFalse(result['executionAuthorized'])

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
                from gambit_smp.source_identity import reference_bytes
                observation = json.loads(reference_bytes(ROOT, references[reference]))
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
            for origins in ({"references": True},
                            [["record", {"reference": "record", "field": "label"},
                              {"reference": "record"}]]):
                document["facts"]["origin"] = origins
                path.write_text(json.dumps(document))
                with engine_api() as (engine, _):
                    result = view_query(root, "evidence/view.json", engine)
                self.assertEqual(result["answers"]["origins"],
                                 [("record", "evidence/record.json", digest(record))])
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
        document = json.loads((ROOT / VIEW).read_text())
        prior = next(row for row in document['references'] if row['id'] == 'historical-view-bytes')
        import hashlib
        self.assertEqual(hashlib.sha256(captured_source(ROOT, VIEW, prior)).hexdigest(),
                         history["priorViewSha256"])
        self.assertEqual(history["outcome"], "DENY")
        self.assertEqual(len(history["missingReferences"]), 6)
        with self.assertRaisesRegex(ValueError, "regular observed artifact required|Evidence view reference changed|view references must not be Cache aliases"):
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


    def test_modern_c_native_ledger_recomputes_hits_and_preserves_parent_failure(self):
        import copy
        from gambit_smp.branch_evidence import validate_recorded_cases
        document=json.loads((ROOT/'evidence/research/retained/modern-c/request-product/gerbil-compiler-completion.json').read_text())
        result=validate_recorded_cases(document)
        self.assertEqual(result['compilerProducts']['admitted'],88)
        self.assertEqual(result['compilerProducts']['reused'],10)
        self.assertEqual(result['compilerProducts']['inputChanges'],78)
        self.assertFalse(result['compilerProducts']['wholeProducerPassed'])
        self.assertFalse(result['runtimeAdmitted'])
        self.assertFalse(result['allExpectedOutcomes'])
        continuation=document['compilerProductContract']['continuation']
        for mutation in ('hits','misses','producer','frontend','parent'):
            changed=copy.deepcopy(document)
            history=next(h for h in changed['histories'] if h['id']==continuation)
            if mutation=='hits':history['nativeProducts']['reused']=88
            elif mutation=='misses':changed['reuseReasons']['counts']['source-changed']=77
            elif mutation=='producer':history['nativeProducts']['stageComplete']=True
            elif mutation=='frontend':changed['warmAdmission']['frontendReuse']=True
            else:history['commands'][0]['process']['processGroupQuiescent']=False
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):
                validate_recorded_cases(changed)


if __name__ == "__main__":
    unittest.main()
