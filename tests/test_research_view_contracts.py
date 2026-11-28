"""Source-view generation cannot require or certify historical run cache."""
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch
import json

from gambit_smp.architecture_views import ArchitectureViews,check_views
from types import SimpleNamespace
import hashlib

views=ArchitectureViews(Path(__file__).resolve().parents[1],Path('/tmp/unused-view-output'))


class ResearchViewContractTests(unittest.TestCase):
    def contract_elements(self):
        elements = [{'@id': 'package', '@type': 'Package'},
            {'@id': 'interface-type', '@type': 'PartDefinition',
             'qualifiedName': 'GambitRuntimeComposition::BlueprintInterface'},
            {'@id': 'contract-type', '@type': 'PartDefinition',
             'qualifiedName': 'GambitRuntimeInterfaces::InterfaceContract'}]

        def instance(identity, type_id, owner, attributes):
            features = []
            for name, value in attributes.items():
                feature = identity + '-' + name
                literal = feature + '-value'
                elements.append({'@id': feature, '@type': 'AttributeUsage',
                    'declaredName': name, 'value': {'@id': literal}})
                elements.append({'@id': literal, '@type': 'LiteralString', 'value': value})
                features.append({'@id': feature})
            elements.append({'@id': identity, '@type': 'PartUsage', 'owner': {'@id': owner},
                             'type': [{'@id': type_id}], 'ownedFeature': features})

        instance('interface', 'interface-type', 'package', {'interfaceId': 'fixture'})
        names = ('identityScope', 'callerRequires', 'supplierEnsures', 'frameCondition',
            'environmentAssumption', 'interferenceGuarantee', 'invalidation', 'failureCustody',
            'progressObligation', 'synchronization', 'sourceObligation', 'modelObligation',
            'nativeObligation', 'status')
        instance('contract', 'contract-type', 'interface',
                 {name: 'OPEN' if name == 'status' else name for name in names})
        return elements

    def test_shared_contract_projects_without_unrelated_c_source_checks(self):
        rows = views.runtime_interface_contracts(self.contract_elements())
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['interfaceId'], 'fixture')
        self.assertEqual(rows[0]['contract']['status'], 'OPEN')
        self.assertEqual(len(rows[0]['contract']), 14)

    def test_missing_contract_obligation_remains_a_projection_gap(self):
        elements = self.contract_elements()
        next(x for x in elements if x['@id'] == 'contract-callerRequires-value')['value'] = ''
        with self.assertRaisesRegex(ValueError, 'Incomplete blueprint interface contract'):
            views.runtime_interface_contracts(elements)

    def test_native_redefined_contract_inherits_its_declared_type(self):
        elements = self.contract_elements()
        elements.append({'@id': 'contract-declaration', '@type': 'PartUsage',
                         'owner': {'@id': 'interface-type'},
                         'type': [{'@id': 'contract-type'}]})
        contract = next(x for x in elements if x['@id'] == 'contract')
        del contract['type']
        contract['redefines'] = {'@id': 'contract-declaration'}
        rows = views.runtime_interface_contracts(elements)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['contract']['status'], 'OPEN')
        elements.append({'@id': 'interface-reference', '@type': 'PartUsage',
                         'owner': {'@id': 'package'},
                         'redefines': {'@id': 'interface'}})
        self.assertEqual(len(views.runtime_interface_contracts(elements)), 1)
        contract['redefines'] = {'@id': 'contract'}
        with self.assertRaisesRegex(ValueError, 'Cyclic interface feature redefinition'):
            views.runtime_interface_contracts(elements)

    def test_duplicate_or_unowned_contract_cannot_disappear_from_projection(self):
        for owner, error in [('interface', 'Multiple contracts'), ('package', 'Unowned')]:
            elements = self.contract_elements()
            contract = next(x for x in elements if x['@id'] == 'contract')
            elements.append({**contract, '@id': 'another', 'owner': {'@id': owner}})
            with self.subTest(owner=owner), self.assertRaisesRegex(ValueError, error):
                views.runtime_interface_contracts(elements)

    def test_cache_layout_text_is_allowed_but_ephemeral_file_links_are_not(self):
        views.require_reproducible_org('design.org', 'Outputs use =.cache/tasks/TASK/runs/RUN/=.')
        for text in ['[[file:../../.cache/run/checks.json][PASS]]', '[[file:.state/owner.json]]']:
            with self.subTest(text=text), self.assertRaisesRegex(ValueError, 'inert text'):
                views.require_reproducible_org('design.org', text)
        locator = views.file_link('dev/modeling/index.org', '.cache/tasks/example/receipt.json', 'Old receipt')
        self.assertNotIn('[[file:', locator)
        self.assertIn('availability not asserted', locator)

    def test_historical_presence_is_neither_a_source_prerequisite_nor_an_acceptance(self):
        with TemporaryDirectory() as directory:
            local=ArchitectureViews(Path(directory),Path(directory)/'run')
            rows=[]
            self.assertFalse(local.require_source_or_observe('.cache/tasks/old/receipt.json',rows))
            self.assertEqual('unavailable',rows[0]['state'])
            self.assertFalse(rows[0]['accepted'])
            with self.assertRaisesRegex(ValueError,'Missing maintained source'):
                local.require_source_or_observe('models/missing.qnt',rows)

    def test_native_definition_parameters_are_not_metadata_instances(self):
        by = {'package': {'@type':'Package'},
              'definition': {'@type':'PartDefinition', 'owner':{'@id':'package'}},
              'instance': {'@type':'PartUsage', 'owner':{'@id':'package'}}}
        parameter = {'owner':{'@id':'definition'}}
        self.assertFalse(views.concrete_usage(parameter, by))
        self.assertTrue(views.concrete_usage({'owner':{'@id':'instance'}}, by))
        # An empty concrete instance is still inspected; missing fields cannot
        # be hidden by dropping rows merely because they have no attributes.
        self.assertTrue(views.concrete_usage({'owner':{'@id':'package'}}, by))

    def test_source_view_failure_cannot_publish_or_reuse_another_context(self):
        with TemporaryDirectory() as directory:
            root=Path(directory);model=root/'dev/m.sysml';model.parent.mkdir();model.write_text('package M {}')
            projection=root/'projection.json';prepared=root/'prepared.json'
            projection.write_text(json.dumps(dict(schema='sysml-structure-projection',runtimeAdmitted=False,
                modelInputs={'dev/m.sysml':hashlib.sha256(model.read_bytes()).hexdigest()},elements=[])))
            prepared.write_text(json.dumps(dict(schema='architecture-view-inputs',runtimeAdmitted=False,sources={})))
            for number in range(2):
                out=root/('run-'+str(number));out.mkdir()
                context=SimpleNamespace(root=root,directory=out,receipt=dict(declaredInputs=['dev/m.sysml']),
                    artifact=lambda ref,kind:prepared if kind=='architecture-view-inputs' else projection,
                    bind=lambda paths:None,publish=lambda *args: self.fail('failure cannot publish'))
                with patch.object(ArchitectureViews,'derive',side_effect=ValueError('Invalid descriptor source')):
                    with self.assertRaisesRegex(ValueError,'Invalid descriptor source'):
                        check_views(dict(projection={},prepared={}),context)
                self.assertFalse((out/'view-check.json').exists())


if __name__ == '__main__':
    unittest.main()
