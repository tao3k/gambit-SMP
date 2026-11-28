"""Current and immutable model epochs keep the same native projection checks."""
import hashlib
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest

from gambit_smp.model_binding import api_binding


class ModelBindingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.out = self.root / '.cache/run'
        self.directory = self.out / 'check'
        self.directory.mkdir(parents=True)


    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path


    def binding_fixture(self):
        from unittest.mock import Mock
        path = self.write('contract.sysml', 'package Contract {}')
        values = {'Contract::target.enabled': True, 'Contract::target.count': 7}
        binding = dict(inputs={'contract.sysml': hashlib.sha256(path.read_bytes()).hexdigest()}, selection=list(values),
                       sdkObservation={'modelHash': 'native-model'},
                       projectionSha256=hashlib.sha256(json.dumps(values, sort_keys=True,
                           separators=(',', ':')).encode()).hexdigest())
        model = SimpleNamespace(hash='native-model', diagnostics=[], raise_for_errors=Mock(),
                                eval=lambda name: values[name])
        return binding, model, SimpleNamespace(parse_sources=Mock(return_value=model)), values


    def test_bounded_binding_rebuilds_values_from_native_source(self):
        binding, model, connection, values = self.binding_fixture()
        result = api_binding(connection, self.root, binding)
        self.assertEqual(values, result['expressions'])
        self.assertNotIn('expressions', binding)
        connection.parse_sources.assert_called_once_with(
            [('contract.sysml', 'package Contract {}')], strict=True, strict_conformance=True)


    def test_bounded_binding_refuses_source_drift_before_native_projection(self):
        binding, model, connection, values = self.binding_fixture()
        self.write('contract.sysml', 'package Changed {}')
        with self.assertRaisesRegex(ValueError, 'current repository model'):
            api_binding(connection, self.root, binding)
        connection.parse_sources.assert_not_called()


    def test_bounded_binding_preserves_boolean_integer_distinction(self):
        binding, model, connection, values = self.binding_fixture()
        values['Contract::target.enabled'] = 1
        with self.assertRaisesRegex(ValueError, 'projection identity'):
            api_binding(connection, self.root, binding)


    def test_bounded_binding_refuses_missing_or_ambiguous_native_values(self):
        binding, model, connection, values = self.binding_fixture()
        model.diagnostics = ['unresolved model member']
        with self.assertRaisesRegex(ValueError, 'diagnostic-free'):
            api_binding(connection, self.root, binding)
        model.diagnostics = []
        binding['selection'].append(binding['selection'][0])
        with self.assertRaisesRegex(ValueError, 'unique qualified'):
            api_binding(connection, self.root, binding)


    def immutable_binding(self):
        from gambit_smp.source_identity import git_source
        from gambit_smp.view_materialize import git
        binding, model, connection, values = self.binding_fixture()
        git(self.root, 'init', '-q')
        git(self.root, 'add', 'contract.sysml')
        git(self.root, '-c', 'user.name=Binding test', '-c',
            'user.email=binding@example.invalid', 'commit', '-qm', 'source epoch')
        revision = git(self.root, 'rev-parse', 'HEAD').decode().strip()
        identities = {'contract.sysml': git_source(self.root, '.', revision, 'contract.sysml')}
        return binding, connection, values, identities


    def test_historical_binding_rebuilds_original_bytes_without_live_fallback(self):
        binding, connection, values, identities = self.immutable_binding()
        self.write('contract.sysml', 'package Current {}')
        rebuilt = api_binding(connection, self.root, binding, source_identities=identities)
        self.assertEqual(rebuilt['expressions'], values)
        connection.parse_sources.assert_called_once_with(
            [('contract.sysml', 'package Contract {}')], strict=True, strict_conformance=True)
        with self.assertRaisesRegex(ValueError, 'current repository model'):
            api_binding(connection, self.root, binding)


    def test_historical_binding_refuses_incomplete_or_substituted_source_set(self):
        binding, connection, values, identities = self.immutable_binding()
        for replaced in [{}, dict(identities, other=identities['contract.sysml']),
                {'contract.sysml': dict(identities['contract.sysml'], sha256='0' * 64)}]:
            with self.subTest(identities=replaced), self.assertRaises(ValueError):
                api_binding(connection, self.root, binding, source_identities=replaced)
        connection.parse_sources.assert_not_called()


    def test_unavailable_historical_source_cannot_use_matching_current_bytes(self):
        binding, connection, values, identities = self.immutable_binding()
        identities['contract.sysml']['revision'] = '0' * 40
        with self.assertRaisesRegex(ValueError, 'immutable model source unavailable'):
            api_binding(connection, self.root, binding, source_identities=identities)
        connection.parse_sources.assert_not_called()

    def test_batch_source_bytes_preserve_order_and_refuse_substitution_or_truncation(self):
        from unittest.mock import patch
        from gambit_smp.source_identity import git_source, read_git_sources
        from gambit_smp.view_materialize import git
        binding, connection, values, identities = self.immutable_binding()
        binary = b'\xff\x00\r\nsecond\n'
        (self.root / 'binary').write_bytes(binary)
        git(self.root, 'add', 'binary')
        git(self.root, '-c', 'user.name=Binding test', '-c',
            'user.email=binding@example.invalid', 'commit', '-qm', 'binary source')
        revision = git(self.root, 'rev-parse', 'HEAD').decode().strip()
        first = identities['contract.sysml']
        second = git_source(self.root, '.', revision, 'binary')
        self.assertEqual(read_git_sources(self.root, [second, first, second]),
                         [binary, b'package Contract {}', binary])
        for bad in [dict(first, blob=second['blob']), dict(first, sha256='0' * 64),
                    dict(first, path='contract.sysml\nbinary')]:
            with self.subTest(identity=bad), self.assertRaises(ValueError):
                read_git_sources(self.root, [bad])
        with patch('gambit_smp.view_materialize.git', return_value=b'truncated'):
            with self.assertRaises(ValueError):
                read_git_sources(self.root, [first])
