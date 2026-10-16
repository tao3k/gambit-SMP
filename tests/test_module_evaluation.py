"""Source-bound Rust DSL evaluation, including independently owned graph results."""
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.evidence_capabilities import native_evaluate
from gambit_smp.framework import ROOT, digest


class ModuleEvaluationTests(unittest.TestCase):
    def request(self, directory, source, constructor, facts, queries):
        entry = {'schema': 'ascent.evidence-dsl-entry.v1',
                 'sources': [{'path': source, 'sha256': digest(ROOT / source)}],
                 'constructor': constructor, 'arguments': [], 'trusted': True}
        path = directory / 'entry.json'
        path.write_text(json.dumps(entry))
        return {'rules': [], 'dsl': entry, 'dslInput': str(path), 'dslRoot': str(ROOT),
                'dslInputSha256': digest(path), 'facts': facts, 'queries': queries,
                'output': str(directory)}

    def test_native_program_observations_and_separate_explanation(self):
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            request = self.request(directory, 'evidence/dsl/execution.ss',
                                   'make-execution-evidence',
                                   {'required_step': [['finished'], ['missing']],
                                    'observed_step': [['finished', 'PASS', 'native.test']]},
                                   {'checked': 'checked_step', 'missing': 'missing_step'})
            native_evaluate(request)
            self.assertEqual(json.loads((directory / 'answers.json').read_text()),
                             {'checked': [['finished']], 'missing': [['missing']]})
            explanation = json.loads((directory / 'explanations.json').read_text())
            self.assertFalse(explanation['runtimeAdmitted'])
            self.assertFalse(explanation['sourceRefinementAdmitted'])
            self.assertEqual(explanation['handleLifetime'], 'native-worker-process')
            self.assertIn('dependencies', str(explanation))
            self.assertIn('source refinement', str(explanation))

    def test_non_scalar_results_remain_native_graphs(self):
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            request = self.request(directory, 'tests/fixtures/evidence/graph-values.ss',
                                   'make-graph-values', {}, {'values': 'input'})
            native_evaluate(request)
            result = json.loads((directory / 'answers.json').read_text())['values']
            self.assertEqual(result['value']['format'], 'native-value-graph.v1')
            self.assertIn('opaque', str(result))
            self.assertIn('hash-table', str(result))
            self.assertTrue(any(node.get('type') == 'symbol' and node.get('interned') is False
                                for node in result['value']['nodes']))
            explanation = json.loads((directory / 'explanations.json').read_text())
            self.assertEqual(explanation['status'], 'recorded-only')
            self.assertTrue(explanation['answers']['values'])

    def test_entry_drift_and_mixed_entry_rejected(self):
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            request = self.request(directory, 'evidence/dsl/execution.ss',
                                   'make-execution-evidence', {}, {'missing': 'missing_step'})
            request['rules'] = ['untrusted.ss']
            with self.assertRaisesRegex(ValueError, 'exclusive'):
                native_evaluate(request)
            request['rules'] = []
            Path(request['dslInput']).write_text('{}')
            with self.assertRaisesRegex(ValueError, 'entry changed'):
                native_evaluate(request)


if __name__ == '__main__':
    unittest.main()
