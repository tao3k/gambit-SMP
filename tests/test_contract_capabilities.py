import hashlib
import copy
import json
import os
from pathlib import Path
import tempfile
import time
import unittest
from types import SimpleNamespace
from unittest.mock import patch

from gambit_smp import contract_capabilities as caps, recipes, research_kernel


class ContractTests(unittest.TestCase):
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

    def context(self, values, texts):
        for name, text in texts.items():
            self.write(name, text)
        values = dict(values, identities=json.dumps({n: hashlib.sha256(t.encode()).hexdigest()
                                                   for n, t in texts.items()}))
        projection = self.write('.cache/run/project/projection.json', json.dumps({
            'schema': 'sysml-source-contract-projection', 'values': values}))
        descriptor = {'type': 'sysml-source-contract', 'path': 'project/projection.json',
                      'sha256': hashlib.sha256(projection.read_bytes()).hexdigest()}
        receipt = {'declaredInputs': list(texts), 'steps': [dict(id='project', outcome='PASS',
                    outputs={'projection': descriptor})], 'runtimeAdmitted': False}
        return recipes.ExecutionContext(self.root, self.out, self.directory, os.environ,
                    time.monotonic() + 10, {}, receipt, {})

    def header(self):
        values = dict(kind='modular-header', dispatcher='include/gambit.h.in',
                      modules=json.dumps(['include/_gambit/module.h.in']), owner='include/_gambit/module.h.in',
                      begin='typedef struct module', endDelimiter='} module;', tokens='["roots"]')
        texts = {'include/gambit.h.in': '#include "_gambit/module.h.in"\n',
                 'include/_gambit/module.h.in': '/* owner */\ntypedef struct module { int roots; } module;\n'}
        return values, texts

    def execute(self, ctx):
        return caps.check({'projection': {'step': 'project', 'output': 'projection'}}, ctx)

    def test_header_real_context_publication_and_scope(self):
        values, texts = self.header()
        result = self.execute(self.context(values, texts))
        self.assertEqual('matched', result['status'])
        self.assertEqual(2, result['observed']['firstLine'])
        self.assertFalse(result['runtimeAdmitted'])
        self.assertEqual('source-contract-observation', result['outputs']['observation']['type'])

    def test_missing_source_is_not_pass(self):
        values, texts = self.header()
        ctx = self.context(values, texts)
        (self.root / values['owner']).unlink()
        with self.assertRaises(ValueError):
            self.execute(ctx)

    def test_source_drift_is_not_resigned(self):
        values, texts = self.header()
        ctx = self.context(values, texts)
        self.write(values['owner'], texts[values['owner']] + '/* drift */')
        with self.assertRaisesRegex(ValueError, 'byte identity drift'):
            self.execute(ctx)

    def test_undeclared_input_rejected(self):
        values, texts = self.header()
        ctx = self.context(values, texts)
        ctx.receipt['declaredInputs'].remove(values['owner'])
        with self.assertRaisesRegex(ValueError, 'declared Recipe inputs'):
            self.execute(ctx)

    def test_duplicate_owner_rejected(self):
        values, texts = self.header()
        texts[values['dispatcher']] += texts[values['owner']]
        with self.assertRaisesRegex(ValueError, 'unique declaration owner'):
            self.execute(self.context(values, texts))

    def test_unlisted_include_rejected(self):
        values, texts = self.header()
        texts[values['dispatcher']] += '#include "_gambit/late.h.in"\n'
        with self.assertRaisesRegex(ValueError, 'include closure'):
            self.execute(self.context(values, texts))

    def test_missing_member_rejected(self):
        values, texts = self.header()
        texts[values['owner']] = texts[values['owner']].replace('roots', 'other')
        with self.assertRaisesRegex(ValueError, 'member tokens'):
            self.execute(self.context(values, texts))

    def test_changed_during_observation_rejected(self):
        values, texts = self.header()
        ctx = self.context(values, texts)
        original = caps.header_observation
        def change(v, t):
            result = original(v, t)
            self.write(values['owner'], texts[values['owner']] + '/* late */')
            return result
        with patch.object(caps, 'header_observation', side_effect=change), self.assertRaisesRegex(ValueError, 'changed'):
            self.execute(ctx)

    def test_budget_is_not_renewed(self):
        values, texts = self.header()
        ctx = self.context(values, texts)
        ctx.deadline = time.monotonic() - 1
        with self.assertRaises(TimeoutError):
            self.execute(ctx)

    def make(self):
        old = 'check: core\ncore other:\n'
        current = 'check: core test-new\ncore other:\ntest-new:\n'
        contract = dict(schema='upstream-make-test-contract.v1',
            template=dict(sha256=caps.digest_bytes(old.encode())),
            targets=dict(check=dict(headers=['check: core']), core=dict(headers=['core:'])), unitModes={})
        texts = {'old.in': old, 'current.in': current, 'contract.json': json.dumps(contract)}
        values = dict(kind='make-delta', template='current.in', priorTemplate='old.in',
            priorContract='contract.json', changedHeaders='{"check":["check: core test-new"]}',
            addedHeaders='{"test-new":["test-new:"]}', priorHeaderDefects='{"core":["core other:"]}')
        return values, texts

    def test_known_prior_defect_remains_denied(self):
        values, texts = self.make()
        result = self.execute(self.context(values, texts))
        self.assertFalse(result['observed']['priorContractUsable'])
        self.assertFalse(result['observed']['executionContractReplaced'])
        self.assertEqual(['test-new'], result['observed']['addedTargets'])

    def test_hidden_prior_defect_cannot_pass(self):
        values, texts = self.make()
        values['priorHeaderDefects'] = '{}'
        with self.assertRaisesRegex(ValueError, 'defect inventory'):
            self.execute(self.context(values, texts))

    def test_lost_dependency_cannot_pass(self):
        values, texts = self.make()
        texts['current.in'] = texts['current.in'].replace('check: core test-new', 'check: test-new')
        with self.assertRaisesRegex(ValueError, 'target delta differs'):
            self.execute(self.context(values, texts))

    def test_unlisted_added_target_cannot_pass(self):
        values, texts = self.make()
        texts['current.in'] += 'late:\n'
        with self.assertRaisesRegex(ValueError, 'complete added/removed'):
            self.execute(self.context(values, texts))

    def test_existing_target_outside_prior_scope_cannot_change_unobserved(self):
        values, texts = self.make()
        texts['current.in'] = texts['current.in'].replace('core other:', 'core:') + 'other: late\n'
        with self.assertRaisesRegex(ValueError, 'target delta differs'):
            self.execute(self.context(values, texts))

    def test_expressions_and_undeclared_models_rejected(self):
        for args in [dict(models=['model.sysml'], attributes={'x': 'P::p.x + 1'}),
                     dict(models=['missing.sysml'], attributes={'x': 'P::p.x'})]:
            with self.assertRaises(ValueError):
                caps.validate_project(args, ['model.sysml'])

    def test_typed_producer_and_dependency_required(self):
        step = dict(id='check', arguments={'projection': {'step': 'project', 'output': 'projection'}}, dependsOn=[])
        with self.assertRaises(ValueError):
            caps.check_graph(step, {'project': {'capability': 'sysml.project'}}, recipes.CAPABILITIES)

    def test_source_graph_does_not_admit_unreviewed_executor(self):
        steps = [dict(id='project', capability='sysml.project'), dict(id='check', capability='source.contract'),
                 dict(id='evidence', capability='evidence.evaluate', arguments={})]
        research_kernel.validate_graph({'inputs': []}, steps)
        steps[0]['capability'] = 'python.run'
        with self.assertRaisesRegex(ValueError, 'historical producer'):
            research_kernel.validate_graph({'inputs': []}, steps)

    def test_five_checkouts_share_one_source_binding_path(self):
        import shutil
        values, texts = self.header()
        values['sourcePrefix'] = 'include'
        ctx = self.context(values, texts)
        for index in range(5):
            source = self.root / ('checkout-' + str(index))
            for name, text in texts.items():
                target = source / name.removeprefix('include/')
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(text)
            ctx.source_bindings = {'include': source}
            self.assertEqual('matched', self.execute(ctx)['status'])
        shutil.rmtree(self.root / 'include')
        # The original logical path is absent; the selected source is used.
        self.assertEqual('matched', self.execute(ctx)['status'])
        (source / '_gambit/module.h.in').unlink()
        with self.assertRaises(ValueError):
            self.execute(ctx)

    def test_python_api_uses_typed_model_instances(self):
        from unittest.mock import Mock
        instance = {'sourcePrefix': 'vendor/gambit', 'kind': 'modular-header'}
        members = [SimpleNamespace(name=name, kind='AttributeUsage') for name in instance]
        model = SimpleNamespace(hash='model-content-identity', raise_for_errors=Mock(),
                                instantiate=Mock(return_value=instance),
                                find=Mock(return_value=SimpleNamespace(children=lambda: members)))
        connection = SimpleNamespace(parse_sources=Mock(return_value=model))
        documents = [('contract.sysml', 'package Contract {}')]
        result = caps.api_values(connection, documents, 'Contract::target')
        connection.parse_sources.assert_called_once_with(documents, strict=True, strict_conformance=True)
        model.instantiate.assert_called_once_with('Contract::target')
        self.assertEqual('model-content-identity', result['modelHash'])
        self.assertFalse(result['runtimeAdmitted'])
        instance['unset'] = object()
        members.append(SimpleNamespace(name='unset', kind='AttributeUsage'))
        with self.assertRaisesRegex(ValueError, 'unset/error'):
            caps.api_values(connection, documents, 'Contract::target')

    def test_api_selection_has_no_external_service_or_stdout_fallback(self):
        args = dict(models=['contract.sysml'], part='Contract::target')
        inputs = ['contract.sysml', caps.SERVICE_ENTRY, caps.SERVICE_RULES]
        caps.validate_project(args, inputs)
        for extra in [dict(service='127.0.0.1:50123'), dict(attributes={'x':'P::p.x'})]:
            with self.assertRaises(ValueError):
                caps.validate_project(dict(args, **extra), inputs)
        with self.assertRaises(ValueError):
            caps.validate_project(args, ['contract.sysml'])
        for address in ['', 'remote.example:50123', '127.0.0.1:0']:
            with self.assertRaises(ValueError):
                caps.validate_service(address)










    def test_shared_header_closure_handles_monolithic_and_modular_sources(self):
        from gambit_smp.source_capabilities import modular_header_files
        values, texts = self.header()
        for name, text in texts.items():
            self.write(name, text)
        self.assertEqual(('include/gambit.h.in', 'include/_gambit/module.h.in'), modular_header_files(self.root))
        self.write('include/_gambit/module.h.in', '#include "_gambit/module.h.in"\n')
        with self.assertRaisesRegex(ValueError, 'cyclic'):
            modular_header_files(self.root)
        self.write('include/gambit.h.in', '/* historical monolithic source */\n')
        self.assertEqual(('include/gambit.h.in',), modular_header_files(self.root))

    def test_native_projection_requires_complete_successful_observation(self):
        tool = self.write('tools/sysml', 'native tool identity fixture')
        self.write('model.sysml', 'package Model {}')
        ctx = recipes.ExecutionContext(self.root, self.out, self.directory, os.environ,
                    time.monotonic() + 10, {}, {}, {})
        args = dict(models=['model.sysml'], attributes={'kind': 'Model::contract.kind'})
        for response in [dict(status='unresolved', exit=0, errors=None, output=['  = "x"']),
                         dict(status='holds', exit=0, errors=None, output=[])]:
            with patch.object(ctx, 'require', return_value=json.dumps(response)), self.assertRaises(ValueError):
                caps.project(args, ctx)

    def test_missing_native_tool_is_not_success(self):
        ctx = recipes.ExecutionContext(self.root, self.out, self.directory, os.environ,
                    time.monotonic() + 10, {}, {}, {})
        with self.assertRaises(FileNotFoundError):
            caps.project(dict(models=['model.sysml'], part='P::p'), ctx)

    def test_cold_gitlink_does_not_restore_or_admit_source(self):
        from gambit_smp.research_flow import inventory
        (self.root / '.git').mkdir()
        self.write('tests/recipes/example.recipe.json', json.dumps(dict(
            schema='evidence-recipe.v2', id='missing-source', scope='source test', budgetSeconds=10,
            inputs=['vendor/gambit/include/test.h.in'], steps=[])))
        listing = b'160000 ' + b'a' * 40 + b' 0\tvendor/gambit\0'
        with patch('gambit_smp.research_flow.run_process', return_value=SimpleNamespace(stdout=listing)), \
                patch('gambit_smp.evidence_views.registry', return_value=([], {})):
            report = inventory(self.root)
        self.assertFalse(report['requiredInputsAvailable'])
        self.assertEqual([], report['violations'])
        self.assertEqual('unavailable', report['unavailableRecipes'][0]['outcome'])
        self.assertFalse(report['unavailableRecipes'][0]['executable'])
        self.assertFalse((self.root / 'vendor/gambit').exists())

    def test_missing_project_source_is_a_violation(self):
        from gambit_smp.research_flow import inventory
        self.write('tests/recipes/example.recipe.json', json.dumps(dict(
            schema='evidence-recipe.v2', id='missing-source', scope='source test', budgetSeconds=10,
            inputs=['models/missing.sysml'], steps=[])))
        with patch('gambit_smp.evidence_views.registry', return_value=([], {})):
            report = inventory(self.root)
        self.assertFalse(report['requiredInputsAvailable'])
        self.assertTrue(report['violations'])
        self.assertEqual([], report['unavailableRecipes'])


class ManagedSdkTests(unittest.TestCase):
    def test_structural_projection_and_lossless_oracle_refusals(self):
        from unittest.mock import Mock
        elements=[{'@id':'x','@type':'PartUsage','declaredName':'a'}]
        model=SimpleNamespace(hash='model',diagnostics=[],raise_for_errors=Mock(),to_api_json=lambda:json.dumps(elements))
        connection=SimpleNamespace(parse_sources=Mock(return_value=model))
        result=caps.api_structure(connection,[('m.sysml','source')])
        canonical=json.dumps(elements,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode()
        data=dict(referenceSha256='fixed',reference=dict(schema='sysml-structural-reference',
            modelInputs=result['modelInputs'],elementCount=1,elementGraphSha256=hashlib.sha256(canonical).hexdigest()))
        self.assertTrue(caps.structural_equivalence(data,result)['matched'])
        changed=copy.deepcopy(result);changed['elements'][0]['declaredName']='changed'
        with self.assertRaises(ValueError):caps.structural_equivalence(data,changed)
        for bad in ([],[{'@type':'PartUsage'}],elements+elements):
            model.to_api_json=lambda bad=bad:json.dumps(bad)
            with self.assertRaises(ValueError):caps.api_structure(connection,[('m.sysml','source')])
        model.diagnostics=['warning']
        with self.assertRaisesRegex(ValueError,'diagnostic-free'):caps.api_structure(connection,[('m.sysml','source')])

    def test_field_selection_keeps_literal_paths_order_and_exact_types(self):
        from unittest.mock import Mock
        documents=[('m.sysml','package M {}')]
        plan=dict(schema='sysml-field-selection',queries=[
            dict(path=['rows','0','enabled'],expression='M::x.enabled',kind='boolean'),
            dict(path=['rows','0','owner.id'],expression='M::x.owner.id',kind='integer')],
            listGroups=['rows'],modelInputs={'m.sysml':caps.digest_bytes(documents[0][1].encode())},
            expected={'rows':[{'enabled':True,'owner.id':7}]})
        model=SimpleNamespace(hash='model',raise_for_errors=Mock(),eval=Mock(side_effect=[True,7]))
        connection=SimpleNamespace(parse_sources=Mock(return_value=model))
        result=caps.api_selection(connection,documents,plan)
        self.assertEqual(plan['expected'],result['values'])
        self.assertEqual([True,7],result['orderedValues'])
        self.assertEqual(['M::x.enabled','M::x.owner.id'],[c.args[0] for c in model.eval.call_args_list])
        for values in ([1,7],[True,False],[True], [True,7,0]):
            with self.assertRaises(ValueError):caps.selected_values(plan,values)
        for mutation in ('duplicate','expression','list-order','unknown-kind'):
            bad=copy.deepcopy(plan)
            if mutation=='duplicate':bad['queries'].append(bad['queries'][0])
            if mutation=='expression':bad['queries'][0]['expression']='M::x.enabled()'
            if mutation=='list-order':bad['queries'][0]['path'][1]='1'
            if mutation=='unknown-kind':bad['queries'][0]['kind']='unknown'
            with self.assertRaises(ValueError):caps.selected_values(bad,[True,7])
        with self.assertRaisesRegex(ValueError,'source closure'):
            caps.api_selection(connection,[('m.sysml','changed')],plan)

    def test_typed_equivalence_cannot_conflate_bool_integer_and_float(self):
        self.assertFalse(caps.typed_equal({'v':True},{'v':1}))
        self.assertFalse(caps.typed_equal({'v':1},{'v':1.0}))
        self.assertFalse(caps.typed_equal([1,True],[True,1]))
        source='package P {}'
        data=dict(reference=dict(schema='sysml-frontend-equivalence',source=source,
            modelSha256=caps.digest_bytes(source.encode()),model='m.sysml',parts={'P::x':{'v':True}}),
            part='P::x',referenceSha256='fixed')
        with patch.object(caps,'api_values',return_value={'values':{'v':1}}):
            with self.assertRaisesRegex(ValueError,'field set differs'):
                caps.frontend_equivalence(None,data,{'values':{'v':True}})

    def test_policy_audit_refuses_missing_oracle_and_incomplete_bundle(self):
        from gambit_smp.framework import ROOT
        from gambit_smp.research_flow import audit_contract
        oracle=json.loads((ROOT/'tests/fixtures/sysml-api/research-policy-baseline.json').read_text())
        with tempfile.TemporaryDirectory() as name:
            path=Path(name)/'projection.json'
            parts=copy.deepcopy(oracle['parts'])
            parts['ScientificStudies::catalog']={}
            parts['GambitResearchStorage::audit']=dict(oracle='missing.json',publicationEntry='p.json',flowEntry='f.json')
            context=SimpleNamespace(artifact=lambda *args:path,receipt=dict(declaredInputs=[]))
            for values,reason in ((parts,'declared inputs'),({},'part inventory')):
                path.write_text(json.dumps(dict(schema='sysml-source-contract-projection',runtimeAdmitted=False,values=values)))
                with self.assertRaisesRegex(ValueError,reason):
                    audit_contract(dict(projection=dict(step='model',output='projection')),context)

    def test_generated_policy_is_in_the_static_seal_closure(self):
        from gambit_smp.framework import ROOT
        names={p.name for p in research_kernel.implementation_paths(ROOT/'src/gambit_smp')}
        self.assertIn('research_storage_rules.py',names)
        self.assertIn('cli.py',names)  # Shared task transport is byte-bound too.
        self.assertIn('gerbil_compile_products.ss', names)
        self.assertIn('gerbil_library_order.ss', names)
        self.assertIn('gerbil_semantic_graph.ss', names)
        for name in ('research-flow-study.py','research-storage-policy.py'):
            self.assertFalse((ROOT/'dev/modeling/tools'/name).exists())

    def test_batch_parameters_parse_once_and_reject_ambiguous_selection(self):
        from unittest.mock import Mock
        part=SimpleNamespace(children=lambda:[SimpleNamespace(name='x',kind='AttributeUsage')])
        model=SimpleNamespace(hash='identity',raise_for_errors=Mock(),find=Mock(return_value=part),
                              instantiate=lambda name:{'x':name})
        connection=SimpleNamespace(parse_sources=Mock(return_value=model))
        result=caps.api_values(connection,[('m.sysml','package P {}')],['P::a','P::b'])
        self.assertEqual({'P::a':{'x':'P::a'},'P::b':{'x':'P::b'}},result['values'])
        connection.parse_sources.assert_called_once()
        inputs=['m.sysml',caps.SERVICE_ENTRY,caps.SERVICE_RULES]
        caps.validate_project(dict(models=['m.sysml'],parts=['P::a','P::b']),inputs)
        for extra in (dict(part='P::a',parts=['P::b']),dict(parts=[]),dict(parts=['P::a','P::a'])):
            with self.assertRaises(ValueError):caps.validate_project(dict(models=['m.sysml'],**extra),inputs)

    def test_exact_oracle_and_complete_fields(self):
        from gambit_smp.framework import ROOT
        reference = json.loads((ROOT/'tests/fixtures/sysml-api/frontend-baseline.json').read_text())
        part = next(iter(reference['parts']))
        data = dict(reference=reference, referenceSha256='fixed', part=part)
        current = dict(values=reference['parts'][part])
        with patch.object(caps, 'api_values', return_value=current):
            self.assertEqual(dict(matched=True, referenceSha256='fixed'), caps.frontend_equivalence(None, data, current))
            for fields in ({}, dict(current['values'], unexpected=True)):
                with self.subTest(fields=fields), self.assertRaises(ValueError):
                    caps.frontend_equivalence(None, data, dict(values=fields))
            changed = copy.deepcopy(data)
            changed['reference']['source'] += '\n'
            with self.assertRaisesRegex(ValueError, 'identity'):
                caps.frontend_equivalence(None, changed, current)
            with patch.object(caps, 'api_values', return_value=dict(values={})):
                with self.assertRaises(ValueError):
                    caps.frontend_equivalence(None, data, current)

    def test_child_births_cannot_be_replayed_or_substituted(self):
        state = dict(serviceToken='s', clientToken='c', servicePid=41,
                     births={'s':dict(process=dict(pid=41)), 'c':dict(process=dict(pid=42))})
        self.assertTrue(caps.children_bound(state))
        for change in (dict(servicePid=40), dict(clientToken='s'), dict(births={}),
                       dict(births=dict(state['births'], foreign={})),
                       dict(births={'s':dict(process=dict(pid=41)), 'c':dict(process=dict(pid=0))})):
            self.assertFalse(caps.children_bound(dict(state, **change)))

    def test_sealed_provider_byte_and_executable_role_refusal(self):
        with tempfile.TemporaryDirectory() as name:
            engine = Path(name); binary = engine/'service'; binary.write_bytes(b'x'); binary.chmod(0o555)
            provider = dict(profile='connected-model-projection', binary='service',
                            executableFiles=['service'], runtimeFiles={'service':'hash'})
            manifest = dict(sysmlProvider=provider, files={'service':'hash'})
            with patch.object(research_kernel, 'execution_identity', return_value=manifest):
                self.assertEqual(provider, caps.sealed_sdk(engine)[1])
                provider['runtimeFiles']['service'] = 'changed'
                with self.assertRaisesRegex(ValueError, 'identity'):
                    caps.sealed_sdk(engine)
                provider['runtimeFiles']['service'] = 'hash'
                binary.chmod(0o444)
                with self.assertRaisesRegex(ValueError, 'executable'):
                    caps.sealed_sdk(engine)
            with patch.object(research_kernel, 'execution_identity', return_value={}):
                with self.assertRaises(FileNotFoundError):
                    caps.sealed_sdk(engine)

    def test_no_budget_or_unknown_birth_never_manufactures_client_reap(self):
        import subprocess
        for remaining in (1, 40):
            with tempfile.TemporaryDirectory() as name:
                directory=Path(name); binary=directory/'service'; binary.write_bytes(b'fixed')
                provider=dict(binary='service', binarySha256=caps.digest(binary))
                with patch('gambit_smp.task_processes.spawn', side_effect=subprocess.TimeoutExpired('birth', 1)) as spawn:
                    self.assertEqual(2, caps.managed_projection(dict(deadline=time.monotonic()+remaining,
                        engine=name, nonce='fixed'), provider, directory))
                state=json.loads((directory/'sdk-lifecycle.json').read_text())
                self.assertEqual('retained', state['phase'])
                self.assertFalse(state['clientReaped'])
                self.assertFalse(state['clientTimeout'])
                self.assertEqual(remaining==40, spawn.called)

    def test_owner_cleanup_and_unknown_custody(self):
        import io
        import subprocess
        from unittest.mock import MagicMock
        for mode in ('normal', 'timeout', 'interrupt', 'unknown-stop', 'early-exit', 'bad-exit'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as name:
                directory = Path(name)
                binary = directory/'tools/sysml-grpc'
                binary.parent.mkdir(); binary.write_bytes(b'fixed')
                service = MagicMock(pid=41, returncode=0)
                service.stdout = io.BytesIO(b'127.0.0.1:4222\n')
                service.stdin = io.BytesIO()
                service.poll.return_value = 1 if mode == 'early-exit' else None
                if mode == 'bad-exit':
                    service.returncode = 9
                if mode == 'unknown-stop':
                    service.wait.side_effect = subprocess.TimeoutExpired('service', 1)
                def spawn(*args, **kw):
                    kw['observer']('started', kw['spawn_token'], dict(birth=dict(process=dict(pid=41))))
                    return service
                def run(*args, **kw):
                    kw['observer']('started', kw['spawn_token'], dict(birth=dict(process=dict(pid=42))))
                    self.assertLessEqual(kw['timeout'], 35)
                    if mode == 'timeout':
                        raise subprocess.TimeoutExpired('client', kw['timeout'])
                    if mode == 'interrupt':
                        raise KeyboardInterrupt()
                    (directory/'sdk-result.json').write_text('{}')
                    return subprocess.CompletedProcess([], 0, b'', b'')
                selector = MagicMock(); selector.__enter__.return_value.select.return_value = [True]
                data = dict(deadline=time.monotonic()+40, engine=name, nonce='request')
                provider = dict(binary='tools/sysml-grpc', binarySha256=caps.digest(binary))
                with patch('gambit_smp.task_processes.spawn', side_effect=spawn), \
                     patch('gambit_smp.task_processes.run', side_effect=run), \
                     patch('selectors.DefaultSelector', return_value=selector):
                    status = caps.managed_projection(data, provider, directory)
                state = json.loads((directory/'sdk-lifecycle.json').read_text())
                self.assertEqual(status == 0, mode == 'normal')
                self.assertEqual(state['phase'] == 'retained', mode in ('interrupt', 'unknown-stop'))
                self.assertEqual('task-process-registry', state['custody'])
                if mode == 'timeout':
                    self.assertTrue(state['clientTimeout'])
                if mode == 'unknown-stop':
                    self.assertTrue(state['forcedStop'])
                    self.assertFalse(state['serviceReaped'])


class NativeContractTransportTests(unittest.TestCase):
    """The maintained four-row contract, without historical cache fixtures."""
    @classmethod
    def setUpClass(cls):
        from gambit_smp.ascent_program import engine_api
        cls.owner = engine_api(retain=True)
        cls.engine, _ = cls.owner.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.owner.__exit__(None, None, None)

    def answers(self, mutate=None):
        from gambit_smp.framework import ROOT
        from gambit_smp.observation_contract import evaluate
        name = 'tests/recipes/framework-contracts/observations.json'
        rows = json.loads((ROOT / name).read_text())['cases']
        if mutate:
            rows = mutate(copy.deepcopy(rows))
        return evaluate(ROOT, name, rows, engine=self.engine)[0]

    def test_native_exact_inventory(self):
        self.assertTrue(all(not rows for rows in self.answers().values()))

    def test_native_missing_duplicate_foreign_and_false_refusal_controls(self):
        self.assertTrue(self.answers(lambda rows: rows[:-1])['MissingCase'])
        self.assertTrue(self.answers(lambda rows: rows + [rows[0]])['DuplicateCase'])
        def foreign(rows):
            rows[0]['chain'] = 'foreign'
            return rows
        self.assertTrue(self.answers(foreign)['UnknownCase'])
        def false_acceptance(rows):
            rows[2]['status'] = True
            return rows
        self.assertTrue(self.answers(false_acceptance)['WrongField'])

    def test_retired_policy_and_flow_oracles_match_shared_native_rules(self):
        from gambit_smp.framework import ROOT
        from gambit_smp.ascent_program import load_evidence_catalog, query
        from gambit_smp.research_publication import publication_facts
        from gambit_smp.research_flow import flow_facts
        oracle=json.loads((ROOT/'tests/fixtures/sysml-api/research-policy-baseline.json').read_text())
        self.assertEqual(21,len(oracle['publicationCases']))
        self.assertEqual(7,len(oracle['flowCases']))
        policy=load_evidence_catalog(ROOT/'evidence/dsl/research-publication.ss',
            constructor='make-research-storage',trusted=True)
        categories=[oracle['parts']['GambitResearchStorage::category'+str(i)] for i in range(6)]
        actual=query(publication_facts(oracle['publicationCases'],categories),policy,
            {n:n for n in oracle['publicationExpected']},engine=self.engine)
        def normalize(answers):return {k:sorted(map(tuple,v)) for k,v in answers.items()}
        self.assertEqual(normalize(oracle['publicationExpected']),normalize(actual))
        flow=load_evidence_catalog(ROOT/'evidence/dsl/research-flow.ss',
            constructor='make-research-flow',trusted=True)
        for case in oracle['flowCases']:
            result=query(flow_facts([case['input']],[['unscoped','guarded','legacy-cache']],
                [['unknown','completed','unresolved'],['missing','unavailable','verified']]),
                flow,{n:n for n in case['expected']},engine=self.engine)
            self.assertEqual(normalize(case['expected']),normalize(result))

    def test_service_admission_negative_controls(self):
        from gambit_smp.framework import ROOT
        from gambit_smp.ascent_program import load_evidence_catalog, query
        catalog = load_evidence_catalog(ROOT/caps.SERVICE_RULES, constructor='make-sysml-service', trusted=True)
        good = ('one','provider','provider','nonce','nonce','closed',0,True,True,True,False,True,True,0)
        def answers(rows):
            return query({'sdk_observation': rows}, catalog,
                {'qualified':'sdk_qualified','denied':'sdk_denied'}, engine=self.engine)
        self.assertEqual([('one',)], answers([good])['qualified'])
        self.assertEqual([], answers([])['qualified'])
        for index, bad in [(2,'foreign'),(4,'old'),(5,'retained'),(6,1),(7,False),(8,False),
                           (9,False),(10,True),(11,False),(12,False),(13,9)]:
            row = list(good); row[index] = bad
            for rows in ([row], [good,row]):
                with self.subTest(index=index, conflicting=len(rows)>1):
                    result = answers(rows)
                    self.assertFalse(result['qualified'])
                    self.assertEqual([('one',)], result['denied'])
        terminated = list(good); terminated[-1] = -15
        self.assertEqual([('one',)], answers([terminated])['qualified'])

    def test_new_make_contract_includes_recursive_helpers_without_widening_unit_modes(self):
        from gambit_smp.framework import ROOT
        from gambit_smp.upstream_tests import validate_scope_definition, infer_scope
        from gambit_smp.ascent_program import load_evidence_catalog, query
        contract = json.loads((ROOT/'tests/recipes/ci/modern-c-upstream-tests.json').read_text())
        template = ROOT/'evidence/research/source-references/upstream-make'/(contract['template']['sha256']+'.in')
        source = template.read_text()
        validate_scope_definition(contract, source)
        configured = source.replace('@srcdir@', '.').replace('@srcdirpfx@', '')
        validate_scope_definition(contract, source, configured)
        with self.assertRaisesRegex(ValueError, 'recursive Make'):
            validate_scope_definition(contract, source, configured.replace('$(MAKE) ut\n', '$(MAKE) hidden\n'))
        with self.assertRaisesRegex(ValueError, 'variable closure'):
            validate_scope_definition(contract, source.replace('SUBDIRS =\n', 'SUBDIRS = extra\n'))
        with self.assertRaisesRegex(ValueError, 'out-of-tree'):
            validate_scope_definition(contract, source, configured.replace('srcdir = .\n','srcdir = ../other\n'))
        facts = {
            'selected_make_target': [('check',)],
            'make_dependency': [(name, child) for name, row in contract['targets'].items()
                for child in [*row['dependencies'], *contract['execution']['recipeCalls'].get(name, [])]],
            'make_unit_selection': [(name, selection) for name, row in contract['targets'].items()
                                    for selection in row['unitSelections']],
            'make_unit_mode': [(name, mode) for name, modes in contract['unitModes'].items() for mode in modes]}
        catalog = load_evidence_catalog(ROOT/'evidence/dsl/upstream-test-scope.ss',
                                        constructor='make-upstream-test-scope', trusted=True)
        result = query(facts, catalog, {'scope':'review_make_scope','mode':'review_unit_mode','cycle':'scope_cycle'},
                       engine=self.engine)
        self.assertEqual(set(contract['targets']), {row[0] for row in result['scope']})
        self.assertEqual([('gsi',)], result['mode'])
        self.assertFalse(result['cycle'])


if __name__ == '__main__':
    unittest.main()
