import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.research_kernel import bound_execution_summary, execution_summary, inspect, native_failure_diagnostics


class ExecutionSummaryTests(unittest.TestCase):
    def setUp(self):
        self.outer = dict(recipe='transport', outcome='DENY', wholeSeconds=42,
                          childReceiptSha256='bound-by-caller')
        self.child = dict(schema='evidence-recipe-run.v1', recipe='transport', steps=[
            dict(id='core', capability='gambit.source-core', outcome='PASS', stageSeconds=30,
                 outputs={'runtime': {'path': 'retained-source', 'identity': {'gsi/gsi': 'sha'}}},
                 commands=[dict(stage='source-core', seconds=28, exit=0, timeout=False,
                                log='core.log', logSha256='log-sha')]),
            dict(id='review', capability='gambit.review', outcome='DENY', reason='source mismatch'),
            dict(id='bootstrap', capability='gambit.bootstrap', outcome='BLOCKED')])

    def test_completed_core_survives_failed_review_as_candidate_not_permission(self):
        result = execution_summary(self.outer, self.child)
        self.assertEqual(result['nextBoundary'], 'FAILED_STAGE')
        self.assertEqual(result['failures'][0]['reason'], 'source mismatch')
        self.assertEqual(len(result['retainedBuildCandidates']), 1)
        core = result['retainedBuildCandidates'][0]
        self.assertEqual(core['capability'], 'gambit.runtime-import')
        self.assertFalse(core['transportAdmitted'])
        self.assertEqual(result['stages'][0]['commands'][0]['seconds'], 28)
        self.assertFalse(result['runtimeAdmitted'])
        self.assertFalse(result['executionAuthorized'])

    def test_completed_recipe_does_not_imply_native_acceptance(self):
        self.outer['outcome'] = 'PASS'
        self.child['steps'] = self.child['steps'][:1]
        result = execution_summary(self.outer, self.child)
        self.assertEqual(result['nextBoundary'], 'DECLARED_RECIPE_COMPLETE')
        self.assertFalse(result['runtimeAdmitted'])
        self.assertNotIn('pythonOverheadSeconds', result)

    def test_aggregate_read_retains_c_properties_and_actual_ascent_answers(self):
        raw='growth/cbmc.json'
        self.child['steps']=[dict(id='growth',capability='c.cbmc',outcome='PASS',
            cVerification=dict(verdict='INCONCLUSIVE',rawReport='cbmc.json',
                runtimeAdmitted=False,properties=[dict(property='ptr.1',status='FAILURE',
                    description='same object',sourceLocation={'file':'actual.c','line':'40','pragma':['large']},
                    trace=[{'stepType':'failure'}]),dict(property='next',status='UNKNOWN')]),
            artifacts={raw:'raw-sha'},outputs={'verification':{'path':'growth/verification.json'}}),
            dict(id='evidence',capability='evidence.evaluate',outcome='PASS',
                 dependsOn=['growth'],answers={'verified':[],'unresolved':[['growth']]})]
        result=execution_summary(self.outer,self.child)
        observed=result['stages'][0]['cVerification']
        self.assertEqual(observed['verdict'],'INCONCLUSIVE')
        self.assertEqual([p['status'] for p in observed['properties']],['FAILURE','UNKNOWN'])
        self.assertEqual(observed['rawReport'],dict(path=raw,sha256='raw-sha'))
        self.assertTrue(observed['properties'][0]['traceAvailable'])
        self.assertNotIn('trace',observed['properties'][0])
        self.assertEqual(observed['properties'][0]['sourceLocation'],{'file':'actual.c','line':'40'})
        self.assertEqual(result['cContractEvidence'][0]['answers']['unresolved'],[['growth']])
        self.assertFalse(result['runtimeAdmitted'])

    def test_substituted_or_foreign_child_cannot_supply_guidance(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            (out / 'run').mkdir()
            child = out / 'run/receipt.json'
            raw = json.dumps(self.child).encode()
            child.write_bytes(raw)
            self.outer['childReceiptSha256'] = hashlib.sha256(raw).hexdigest()
            self.assertEqual(bound_execution_summary(out, self.outer)['nextBoundary'], 'FAILED_STAGE')
            child.write_bytes(raw + b' ')
            with self.assertRaisesRegex(ValueError, 'identity changed'):
                bound_execution_summary(out, self.outer)
            child.write_bytes(raw)
            self.outer['recipe'] = 'foreign'
            with self.assertRaisesRegex(ValueError, 'matching recipe'):
                bound_execution_summary(out, self.outer)

    def test_current_source_drift_names_bytes_without_revoking_historical_record(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            (out / 'run').mkdir()
            source = out / 'source.patch'
            source.write_bytes(b'new source')
            self.child['inputs'] = {str(source): hashlib.sha256(b'old source').hexdigest()}
            child = out / 'run/receipt.json'
            raw = json.dumps(self.child).encode()
            child.write_bytes(raw)
            self.outer['childReceiptSha256'] = hashlib.sha256(raw).hexdigest()
            result = bound_execution_summary(out, self.outer)
            drift, = result['currentDeclaredInputDifferences']
            self.assertEqual(drift['path'], str(source))
            self.assertEqual(drift['observedSha256'], hashlib.sha256(b'new source').hexdigest())
            self.assertEqual(result['retainedBuildCandidates'][0]['step'], 'core')
            self.assertFalse(result['retainedBuildCandidates'][0]['transportAdmitted'])

    def test_failed_inspection_reports_its_cause_without_qualifying_recorded_build(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            (out / 'run').mkdir()
            raw = json.dumps(self.child).encode()
            (out / 'run/receipt.json').write_bytes(raw)
            outer = dict(self.outer, schema='sealed-research-run.v1', root=str(out),
                         engine=str(out / 'engine'), engineId='prior-engine',
                         childReceiptSha256=hashlib.sha256(raw).hexdigest())
            (out / 'receipt.json').write_text(json.dumps(outer))
            with patch('gambit_smp.research_kernel.manifest_paths', side_effect=ValueError('producer support changed')):
                result = inspect(out)
            self.assertEqual(result['inspectionFailure']['reason'], 'producer support changed')
            self.assertEqual(result['executionSummary']['evidenceBindingStatus'], 'STALE')
            self.assertEqual(result['executionSummary']['artifactAvailabilityStatus'], 'UNKNOWN')
            self.assertFalse(result['runtimeAdmitted'])

    def test_native_error_is_read_from_bound_log_and_tampering_is_not_presented(self):
        with tempfile.TemporaryDirectory() as directory:
            run = Path(directory)
            (run / 'core').mkdir()
            raw = (b'*** ERROR -- Compiler internal error detected\n'
                   b'*** in procedure targ-dump-prc, unknown label type\n'
                   b'make: *** [core-pre] Error 2\n')
            log = run / 'core/source-core.log'
            log.write_bytes(raw)
            rows = [dict(id='core', commands=[dict(stage='source-core', exit=2, timeout=False,
                log=log.name, logSha256=hashlib.sha256(raw).hexdigest())])]
            result, = native_failure_diagnostics(run, rows)
            self.assertEqual(result['status'], 'RECEIPT_BOUND')
            self.assertEqual(result['diagnostics'][1]['line'], 2)
            self.assertIn('unknown label type', result['diagnostics'][1]['text'])
            log.write_text('unrelated error: replaced log')
            result, = native_failure_diagnostics(run, rows)
            self.assertEqual(result['status'], 'UNVERIFIED')
            self.assertNotIn('diagnostics', result)
            rows[0]['commands'][0]['log'] = '../../outside.log'
            result, = native_failure_diagnostics(run, rows)
            self.assertEqual(result['status'], 'UNVERIFIED')

    def test_zero_exit_with_missing_output_exposes_raw_evidence_to_the_model(self):
        with tempfile.TemporaryDirectory() as directory:
            run = Path(directory)
            (run / 'module').mkdir()
            log = run / 'module/emission.log'
            raw = b'*** ERROR IN ##repl-exception-handler-hook -- Heap overflow\n> \n'
            log.write_bytes(raw)
            rows = [dict(id='module', outcome='DENY', commands=[dict(stage='emission', exit=0,
                timeout=False, log=log.name, logSha256=hashlib.sha256(raw).hexdigest())])]
            result, = native_failure_diagnostics(run, rows)
            self.assertEqual(result['commandExit'], 0)
            self.assertIn('Heap overflow', result['logExcerpt'][0]['text'])
            self.assertFalse(result['excerptTruncated'])
            # Unknown messages remain available without inventing a classifier
            # or prescribing a fixed repair sequence.
            raw = b'an unfamiliar runtime diagnostic\n'
            log.write_bytes(raw)
            rows[0]['commands'][0]['logSha256'] = hashlib.sha256(raw).hexdigest()
            result, = native_failure_diagnostics(run, rows)
            self.assertEqual(result['diagnostics'], [])
            self.assertIn('unfamiliar', result['logExcerpt'][0]['text'])

    def test_current_ascent_projection_requires_the_bound_original_declaration(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            (out / 'run').mkdir()
            raw = json.dumps(self.child).encode()
            (out / 'run/receipt.json').write_bytes(raw)
            header = out / 'run-header.json'
            header.write_text(json.dumps(dict(recipe=self.outer['recipe'], engineId='prior-engine',
                                             declaration={'steps': []})))
            outer = dict(self.outer, schema='sealed-research-run.v1', root=str(out),
                engine=str(out / 'engine'), engineId='prior-engine',
                childReceiptSha256=hashlib.sha256(raw).hexdigest(),
                artifacts={'run-header.json': hashlib.sha256(header.read_bytes()).hexdigest()})
            (out / 'receipt.json').write_text(json.dumps(outer))
            with patch('gambit_smp.research_kernel.manifest_paths', side_effect=ValueError('fixture')), \
                    patch('gambit_smp.reasoning_history.read_execution_checkpoint', return_value={'records': []}), \
                    patch('gambit_smp.reasoning_history.build_start_analysis',
                          return_value=dict(backend='ASCENT', executionAuthorized=False)) as project:
                result = inspect(out)
                self.assertEqual(result['currentBuildStartAnalysis']['backend'], 'ASCENT')
                self.assertFalse(result['currentBuildStartAnalysis']['executionAuthorized'])
                project.assert_called_once()
                project.reset_mock()
                header.write_text('{}')
                result = inspect(out)
                self.assertNotIn('currentBuildStartAnalysis', result)
                project.assert_not_called()
