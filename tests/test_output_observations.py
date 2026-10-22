"""Cache availability is not historical result identity or applicability."""
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.output_observations import observe, recorded, check_model, binding, validate, REGISTRY, ObservationUnavailable


class OutputObservationTests(unittest.TestCase):
    def test_source_component_uses_numeric_observations_without_raw_files(self):
        from unittest.mock import patch
        from gambit_smp.source_evidence import checked
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            actual = {'point': 1, 'count': 0, 'joined': True}
            output = observe(json.dumps(actual).encode())
            saved = dict(compile=dict(log='compile.log', logSha256=output['sha256']),
                         results=[dict(log='point-1.log', logSha256=output['sha256'], actual=actual)],
                         outputs={'compile.log': output, 'point-1.log': output})
            receipt = root/'receipt.json'
            receipt.write_text(json.dumps(saved))
            # This exercises output custody only; semantic/source validation is
            # independent and remains mandatory in the real publisher.
            with patch('gambit_smp.source_evidence.validate'):
                self.assertEqual(saved, checked(root, receipt))
                saved['results'][0]['actual']['count'] = 4
                receipt.write_text(json.dumps(saved))
                with self.assertRaisesRegex(ValueError, 'differs from recorded output'):
                    checked(root, receipt)

    def test_real_protocol_receipts_survive_cache_cleanup_but_not_source_drift(self):
        from gambit_smp.framework import ROOT
        from gambit_smp.protocol_evidence import checked_rows, MANIFEST, RECEIPT
        from tests.support import protocol_fixture
        with protocol_fixture(ROOT, MANIFEST, RECEIPT) as (root, manifest, receipt):
            before = checked_rows(root, manifest, receipt)
            cache = root/'.cache/run'; cache.mkdir(parents=True)
            (cache/'checker.log').write_text('disposable diagnostic output')
            shutil.rmtree(root/'.cache')
            self.assertEqual(before, checked_rows(root, manifest, receipt))
            source = root/next(iter(manifest['contextInputs']))
            source.write_text('changed source premise')
            with self.assertRaises(ValueError): checked_rows(root, manifest, receipt)

    def test_cache_collection_preserves_success_failure_and_binding(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cache = root/'.cache/run'
            cache.mkdir(parents=True)
            positive = b'Model checking completed. No error has been found.\n2 states generated, 2 distinct states found, 0 states left on queue.\n'
            negative = b'Error: Invariant q_inv is violated.\n'
            outputs = {}
            rows = []
            for label, data, code in (('pass', positive, 0), ('counterexample', negative, 1)):
                raw = cache/(label+'.log'); raw.write_bytes(data)
                name = 'evidence/model-results/'+label+'.log'
                observation = observe(data)
                outputs[observation['sha256']] = dict(observation, origins=[name])
                rows.append((name, dict(variant='old' if code else 'protocol', exit=code,
                                       timeout=False, logSha256=hashlib.sha256(data).hexdigest())))
            registry = root/REGISTRY; registry.parent.mkdir(parents=True)
            registry.write_text(json.dumps(dict(schema='published-evidence-inputs.v1', records={}, observations=outputs)))
            before = [binding(root, root/name, row['logSha256']) for name, row in rows]
            shutil.rmtree(root/'.cache')
            for (name, row), expected in zip(rows, before):
                self.assertFalse((root/name).exists())
                check_model(recorded(root, root/name, row['logSha256']), row)
                self.assertEqual(expected, binding(root, root/name, row['logSha256']))

    def test_missing_or_changed_observation_never_invents_a_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(ObservationUnavailable):
                recorded(root, root/'evidence/missing.log')
            incomplete = observe(b'configuration failed\n')
            row = dict(variant='protocol', exit=0, timeout=False, logSha256=incomplete['sha256'])
            with self.assertRaises(ValueError): check_model(incomplete, row)
            with self.assertRaises(ValueError):
                recorded(root, root/'a.log', '0'*64, outputs={'a.log': incomplete})

    def test_timeout_and_nonterminal_checker_output_remain_denied(self):
        output = observe(b'Model checking completed. No error has been found.\n2 states generated, 2 distinct states found, 1 states left on queue.\n')
        row = dict(variant='protocol', exit=0, timeout=False)
        with self.assertRaises(ValueError): check_model(output, row)
        complete = observe(b'Model checking completed. No error has been found.\n2 states generated, 2 distinct states found, 0 states left on queue.\n')
        with self.assertRaises(ValueError): check_model(complete, dict(row, timeout=True))
        with self.assertRaises(ValueError): check_model(complete, dict(row, exit=1, variant='old'))
        with self.assertRaises(ValueError): check_model(complete, dict(row, temporal='progress'), temporal='progress')

    def test_no_raw_text_or_json_log_wrapping_is_published(self):
        raw = b'{"privatePath":"/Users/example/private", "message":"full log body"}'
        output = observe(raw)
        self.assertNotIn('structured', output)
        self.assertNotIn('/Users/', json.dumps(output))
        self.assertNotIn('full log body', json.dumps(output))
        self.assertEqual(observe(b'{"checks":3,"arrayLive":0}')['structured'], {'checks':3,'arrayLive':0})
        for key in ('text', 'stdout', 'stderr', 'rawText', 'lines'):
            with self.assertRaises(ValueError):
                validate(dict(output, **{key: raw.decode()}))
        with self.assertRaises(ValueError):
            validate(dict(output, structured={'message': raw.decode()}))
