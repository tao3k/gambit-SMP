"""Storage/typing regressions; no native GC or bootstrap admission."""
import json
import copy
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import bootstrap_artifacts as a, recipes, native_capabilities as n
from gambit_smp.framework import digest


class BootstrapArtifactsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.source = self.root / 'original'
        for name in ('lib', 'gsi', 'gsc', 'include'):
            (self.source/name).mkdir(parents=True)
        for name in ('lib/a.scm', 'gsc/a.scm', 'gsi/main.scm', 'include/gambit.h'):
            (self.source/name).write_text(name)

    def test_seed_survives_destructive_rebuild_without_hardlink_alias(self):
        (self.source/'gsi/gsi').write_bytes(b'qualified executable')
        (self.source/'gsi/gsi').chmod(0o755)
        saved = self.root/'saved/source'
        storage = a.preserve(self.source, saved)
        self.assertFalse(storage['hardlinks'])
        self.assertNotEqual(os.stat(self.source/'gsi/gsi').st_ino, os.stat(saved/'gsi/gsi').st_ino)
        (self.source/'gsi/gsi').unlink()
        (self.source/'include/gambit.h').write_text('new ABI')
        self.assertEqual(b'qualified executable', (saved/'gsi/gsi').read_bytes())
        self.assertEqual('include/gambit.h', (saved/'include/gambit.h').read_text())
        self.assertEqual(0o755, (saved/'gsi/gsi').stat().st_mode & 0o777)

    def test_existing_snapshot_reuse_requires_exact_identity_and_completion(self):
        saved=self.root/'saved/source'
        a.preserve(self.source, saved)
        self.assertTrue(a.preserve(self.source, saved)['reused'])
        (saved/'include/gambit.h').write_text('drift')
        with self.assertRaisesRegex(ValueError, 'unfinished or changed'):
            a.preserve(self.source, saved)

    def test_preservation_cannot_reuse_alias_or_nested_roots(self):
        for target in (self.source, self.source/'nested', self.source.parent):
            with self.assertRaisesRegex(ValueError, 'independent disjoint'):
                a.preserve(self.source,target)
        alias=self.root/'alias';alias.symlink_to(self.source,target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'independent disjoint'):
            a.preserve(self.source,alias)

    def test_same_bytes_do_not_authorize_hardlinked_snapshot_reuse(self):
        saved=self.root/'saved/source';a.preserve(self.source,saved)
        target=saved/'include/gambit.h';target.unlink()
        os.link(self.source/'include/gambit.h',target)
        with self.assertRaisesRegex(ValueError, 'mutable file inodes'):
            a.preserve(self.source,saved)

    def test_partial_transfer_is_not_published_and_source_remains_owned(self):
        saved=self.root/'partial/source'
        saved.mkdir(parents=True)
        with self.assertRaisesRegex(ValueError, 'unfinished'):
            a.preserve(self.source, saved)
        self.assertFalse((saved.parent/'preservation.json').exists())
        self.assertTrue((self.source/'gsi/main.scm').is_file())

    def test_source_change_during_transfer_cannot_issue_completion(self):
        from gambit_smp.artifact_storage import transfer_tree
        saved=self.root/'changing/source'
        def changed(source, destination):
            result=transfer_tree(source, destination)
            (source/'gsi/main.scm').write_text('late write')
            return result
        with patch('gambit_smp.artifact_storage.transfer_tree', side_effect=changed), \
                self.assertRaisesRegex(ValueError, 'changed during'):
            a.preserve(self.source, saved)
        self.assertFalse((saved.parent/'preservation.json').exists())

    def test_host_requires_current_generator_graph_and_executable_hash(self):
        host=self.root/'host';host.write_text('AOT compiler');host.chmod(0o755)
        spec=dict(schema='gambit-bootstrap-host',kind='compiled-current-gsc',executable='host',
                  sha256=digest(host),qualification=dict(compilerSourceInputs=n.current_compiler_inputs(self.source)))
        run=self.root/'producer/run';run.mkdir(parents=True)
        identity=run/'identity.json'
        identity.write_text(json.dumps(dict(gscSha256=digest(host),sourceFiles=n.current_compiler_inputs(self.source))))
        child=run/'receipt.json'
        child.write_text(json.dumps(dict(steps=[dict(capability='gambit.bootstrap',outcome='PASS',
            fullTwoPassBootstrapEstablished=True,phaseCounts=dict(phase1=2,phase2=2,phase3=2,phase4=2),
            outputs=dict(identity=dict(path='identity.json',sha256=digest(identity))))])))
        outer=run.parent/'receipt.json'
        outer.write_text(json.dumps(dict(outcome='PASS',timeout=False,parentReaped=True,
            processGroupQuiescent=True,childReceiptSha256=digest(child))))
        spec['qualification'].update(sourceReceipt=dict(path='producer/receipt.json',sha256=digest(outer)),targetRuntimeLinked=False)
        declaration=self.root/'host.json';declaration.write_text(json.dumps(spec))
        self.assertEqual(host, a.qualified_host(self.source, declaration, self.root)[0])
        (self.source/'gsc/a.scm').write_text('different generator')
        with self.assertRaisesRegex(ValueError, 'generator graph'):
            a.qualified_host(self.source, declaration, self.root)
        spec['qualification']['compilerSourceInputs']=n.current_compiler_inputs(self.source)
        declaration.write_text(json.dumps(spec));host.write_text('different compiler')
        with self.assertRaisesRegex(ValueError, 'host bytes'):
            a.qualified_host(self.source, declaration, self.root)

    def test_compiler_input_cannot_feed_runtime_semantic_test(self):
        producer=dict(id='input',capability='gambit.bootstrap-input')
        step=dict(id='map',capability='gambit.executable-test',dependsOn=['input'],arguments={
            'runtime':dict(step='input',output='source'),'identity':dict(step='input',output='identity')})
        with self.assertRaisesRegex(ValueError, 'type mismatch'):
            n.graph(step, {'input':producer}, recipes.CAPABILITIES)

    def test_compiler_identity_cannot_claim_target_artifacts(self):
        with self.assertRaisesRegex(ValueError, 'cannot attest'):
            a.check(self.source, dict(schema='gambit-bootstrap-input-identity',
                    runtimeAdmitted=False,targetRuntimeEstablished=False,binarySha256='fake'))

    def test_prepared_reference_must_be_declared_and_cannot_reset_runtime_typing(self):
        args=dict(source=dict(step='cfg',output='source'),bootstrapHost='host.json',producer='producer.json')
        with self.assertRaisesRegex(ValueError,'declared compiler-input'):
            n.validate_bootstrap_input(args,['host.json'])
        n.validate_bootstrap_input(args,['host.json','producer.json'])
        self.test_compiler_input_cannot_feed_runtime_semantic_test()

    def test_unquiesced_prepared_producer_is_rejected_before_loading_source(self):
        from types import SimpleNamespace
        run=self.root/'unsafe';(run/'run').mkdir(parents=True)
        child=run/'run/receipt.json';child.write_text('{}')
        outer=run/'receipt.json';outer.write_text(json.dumps(dict(parentReaped=True,
            processGroupQuiescent=False,childReceiptSha256=digest(child))))
        proof=self.root/'proof.json';proof.write_text(json.dumps(dict(run='unsafe',outerSha256=digest(outer),
            step='compiler-input',profileSha256='profile',stageEvidence={})))
        with patch('gambit_smp.recipes.source_path',return_value=proof), \
                self.assertRaisesRegex(ValueError,'quiescent bound'):
            a.reuse_prepared(dict(producer='proof.json'),SimpleNamespace(root=self.root))

    def test_build_derivation_is_role_and_content_not_new_compiler_flags(self):
        from gambit_smp.workspace import validate_build_derivation
        validate_build_derivation(dict(role='completed-seed',inputSha256='a'*64))
        for value in (dict(role='attempt-123',inputSha256='a'*64),
                      dict(role='completed-seed',inputSha256='short'),
                      dict(role='completed-seed',inputSha256='a'*64,flags=['-O0'])):
            with self.assertRaises(ValueError):validate_build_derivation(value)


class ProducerActivationTests(unittest.TestCase):
    def fixture(self, root, *, step='compiler-input', run='producer'):
        from types import SimpleNamespace
        header = root / run / 'run-header.json'
        header.parent.mkdir(parents=True)
        import hashlib
        header.write_text(json.dumps(dict(schema='research-run-header.v1',
            runId=hashlib.sha256(run.encode()).hexdigest()[:32], executionCompleted=False,
            declaration=dict(steps=[dict(id='compiler-input'), dict(id='bootstrap')]),
            engineId='e' * 64, recipe='same-native-case')))
        directory = header.parent / 'run' / step
        directory.mkdir(parents=True)
        return SimpleNamespace(root=root, directory=directory, bind=lambda paths: None,
            lease_workspace=lambda path, identity: path,
            receipt=dict(engine=dict(engineId='e' * 64, path=str(root / 'engine')), recipe='same-native-case',
                         journal=dict(path=str(header), sha256=digest(header))))

    def test_actual_receipt_nests_engine_and_flat_id_cannot_override_it(self):
        with tempfile.TemporaryDirectory() as directory:
            ctx = self.fixture(Path(directory))
            self.assertNotIn('engineId', ctx.receipt)
            self.assertIsNotNone(a.private_activation(ctx))
            ctx.receipt['engineId'] = 'e' * 64
            ctx.receipt['engine']['engineId'] = 'f' * 64
            with self.assertRaisesRegex(ValueError, 'producer identity'):
                a.private_activation(ctx)

    def test_constructor_identity_is_producer_and_endpoint_not_content_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first = self.fixture(root)
            second = self.fixture(root, run='successor')
            # Real run headers contain distinct run identities even for equal inputs.
            one, two = a.private_activation(first), a.private_activation(second)
            self.assertNotEqual(one, two)
            self.assertEqual(one, a.private_activation(first))
            first.directory = first.directory.with_name('bootstrap')
            self.assertNotEqual(one, a.private_activation(first))

    def test_changed_header_and_foreign_endpoint_cannot_create_activation(self):
        with tempfile.TemporaryDirectory() as directory:
            ctx = self.fixture(Path(directory))
            ctx.directory = Path(directory) / 'another/run/compiler-input'
            with self.assertRaisesRegex(ValueError, 'bound producer'):
                a.private_activation(ctx)
            ctx = self.fixture(Path(directory), run='unregistered')
            ctx.directory = ctx.directory.with_name('not-a-declared-endpoint')
            with self.assertRaisesRegex(ValueError, 'producer identity'):
                a.private_activation(ctx)
            ctx = self.fixture(Path(directory), run='second')
            Path(ctx.receipt['journal']['path']).write_text('{}')
            with self.assertRaisesRegex(ValueError, 'bound producer'):
                a.private_activation(ctx)

    def test_only_mutable_work_roles_accept_a_producer_activation(self):
        from gambit_smp.workspace import validate_build_derivation
        activation = dict(producerSha256='b' * 64, step='bootstrap')
        value = dict(role='working-bootstrap', inputSha256='a' * 64, activation=activation)
        validate_build_derivation(value)
        for role in ('completed-runtime', 'completed-bootstrap-input', 'completed-seed'):
            with self.assertRaisesRegex(ValueError, 'mutable constructor'):
                validate_build_derivation(dict(value, role=role))
        with self.assertRaisesRegex(ValueError, 'typed build role'):
            validate_build_derivation(dict(value, flags=['-O0']))

    def test_constructor_activation_does_not_reset_native_case_history(self):
        from copy import deepcopy
        from gambit_smp.reasoning_history import _native_build_keys
        header = dict(runId='a' * 32, inputs={'source.lock.json': 'source', 'profile.json': 'profile'},
            declaration=dict(steps=[
                dict(id='source', capability='gambit.materialize', arguments={'sourceLock': 'source.lock.json'}),
                dict(id='configure', capability='gambit.configure', dependsOn=['source'],
                     arguments={'source': {'step': 'source', 'output': 'source'}, 'buildProfile': 'profile.json'}),
                dict(id='bootstrap', capability='gambit.bootstrap', dependsOn=['configure'],
                     arguments={'runtime': {'step': 'configure', 'output': 'source'}})]))
        successor = deepcopy(header)
        successor['runId'] = 'b' * 32
        self.assertTrue(_native_build_keys(header))
        self.assertEqual(_native_build_keys(header), _native_build_keys(successor))
        successor['inputs']['profile.json'] = 'different profile'
        self.assertNotEqual(_native_build_keys(header), _native_build_keys(successor))

    def test_mutation_stays_with_its_producer_and_cannot_change_the_input_or_successor(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'immutable-input'
            source.mkdir()
            (source / 'seed').write_text('qualified input')
            first = self.fixture(root)
            second = self.fixture(root, run='successor')

            def derived(ctx, incoming, role, *, activation=None):
                return (root / 'work' / activation['producerSha256'] / activation['step'] / 'source',
                        recipes.tree_identity(incoming))

            with patch.object(a, 'derived_source', side_effect=derived):
                old, _ = a.private_copy(first, source, 'working-bootstrap')
                (old / 'seed').write_text('partial failed build')
                with self.assertRaisesRegex(ValueError, 'explicit recovery'):
                    a.private_copy(first, source, 'working-bootstrap')
                successor, storage = a.private_copy(second, source, 'working-bootstrap')
            self.assertNotEqual(old, successor)
            self.assertEqual('partial failed build', (old / 'seed').read_text())
            self.assertEqual('qualified input', (source / 'seed').read_text())
            self.assertEqual('qualified input', (successor / 'seed').read_text())
            self.assertFalse(storage['priorGenerationRewritten'])


class RegisteredArtifactCustodyTests(unittest.TestCase):
    from tests.test_workspace import WorkspaceTests
    setUp = WorkspaceTests.setUp

    def test_development_reuses_one_tree_and_preserves_native_outputs_without_copy_or_clean(self):
        import shutil
        from types import SimpleNamespace
        from gambit_smp import workspace as w
        from gambit_smp.artifact_storage import transfer_tree
        w.start(self.root, 'modern-c', adopt=True)
        with w.execution_scope(self.root, 'modern-c'):
            build=w.build_output(self.root,'gambit-core',compiler=shutil.which('cc'),flags=['-O1'])
            source=build/'source';(source/'lib').mkdir(parents=True)
            (source/'lib/setup.c').write_text('/* source */')
            (source/'lib/mem.c').write_text('/* old native */')
            (source/'lib/mem.o').write_bytes(b'old object')
            ctx=SimpleNamespace(root=self.root,bind=lambda paths:None,
                lease_workspace=lambda p,identity:p)
            with patch('gambit_smp.artifact_storage.transfer_tree',wraps=transfer_tree) as copy:
                first, receipt=a.incremental_consumer(ctx,source,mutable=['lib/mem.c','lib/mem.o'])
                self.assertEqual(copy.call_count,1)
                self.assertEqual(receipt['sourceCopies'],1)
                (first/'lib/mem.c').write_text('/* current native */')
                (first/'lib/mem.o').write_bytes(b'current compiled object')
                w.checkpoint_build_source(first,nativeObjectContext={'parameters':'completed-flags-A'})
                before=(first/'lib/mem.o').stat().st_mtime_ns
                second, receipt=a.incremental_consumer(ctx,source,mutable=['lib/mem.c','lib/mem.o'])
                self.assertEqual(first,second)
                self.assertEqual(copy.call_count,1)
                self.assertEqual(receipt['sourceCopies'],0)
                self.assertFalse(receipt['automaticClean'])
                self.assertEqual((second/'lib/mem.o').stat().st_mtime_ns,before)
                self.assertEqual((second/'lib/mem.o').read_bytes(),b'current compiled object')
                self.assertEqual(json.loads((second.parent/'source-state.json').read_text())['nativeObjectContext'],
                                 {'parameters':'completed-flags-A'})
                self.assertEqual((source/'lib/mem.o').read_bytes(),b'old object')
                (source/'lib/mem.c').write_text('/* different generation origin */')
                with self.assertRaisesRegex(ValueError,'explicit fixed-workspace rebase'):
                    a.incremental_consumer(ctx,source)
                self.assertEqual(copy.call_count,1)

    def test_registered_generations_keep_flags_and_preserve_seed_under_real_lease(self):
        import shutil
        from contextlib import ExitStack
        from types import SimpleNamespace
        from gambit_smp import workspace as w
        from gambit_smp.artifact_storage import workspace_lease, fixture_root
        w.start(self.root, 'repair', adopt=True)
        with w.execution_scope(self.root, 'repair'), ExitStack() as leases:
            build=w.build_output(self.root, 'gambit-core', compiler=shutil.which('cc'), flags=['-O1'])
            source=build/'source';(source/'include').mkdir(parents=True)
            (source/'lib').mkdir();(source/'lib/setup.c').write_text('/* runtime */')
            (source/'include/gambit.h').write_text('same ABI')
            leases.enter_context(workspace_lease(self.root, source, recipes.tree_identity(source)))
            held={source}
            def lease(path, identity):
                if path in held:
                    self.assertEqual(identity,recipes.tree_identity(path))
                    return path
                held.add(path)
                return leases.enter_context(workspace_lease(self.root,path,identity))
            ctx=SimpleNamespace(root=self.root, bind=lambda paths:None,
                lease_workspace=lease)
            with patch.dict(os.environ,SDKROOT='/unrelated-sdk'), self.assertRaisesRegex(
                    ValueError,'current build environment'):
                a.freeze(ctx,source,'completed-seed')
            saved,storage=a.freeze(ctx,source,'completed-seed')
            out=self.root/'.cache/tasks/repair/runs/typed-control'
            out.mkdir(parents=True)
            location=out/'location.json'
            location.write_text(json.dumps(dict(schema='managed-workspace-location.v1',workspace=str(saved.relative_to(self.root)))))
            descriptor=dict(type='bootstrap-input',path='location.json',workspace=str(saved.relative_to(self.root)),locationSha256=digest(location))
            self.assertEqual(saved,recipes.artifact_path(out,descriptor,root=self.root))
            with self.assertRaisesRegex(ValueError,'source type'):
                recipes.artifact_path(out,{**descriptor,'type':'runtime-identity'},root=self.root)
            private,_=a.private_copy(ctx,saved,'working-bootstrap')
            self.assertEqual(fixture_root(self.root,source),fixture_root(self.root,private))
            self.assertNotEqual(saved,private)
            (private/'include/gambit.h').unlink()
            self.assertEqual('same ABI',(saved/'include/gambit.h').read_text())
            for p in (saved,private):
                config=json.loads((p.parent/'configuration.json').read_text())
                self.assertEqual(['-O1'],config['flags'])
                self.assertEqual(64,len(config['derivation']['inputSha256']))
            with self.assertRaisesRegex(ValueError,'explicit recovery'):
                a.private_copy(ctx,saved,'working-bootstrap')

class ReusedConfigurationProofTests(unittest.TestCase):
    def configuration_owner(self, root):
        from types import SimpleNamespace
        source=root/'source';source.mkdir();out=root/'step';out.mkdir()
        for name in n.CONFIGURATION_OUTPUTS:
            p=source/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(name)
        ctx=SimpleNamespace(directory=out,commands=[],remaining=lambda:90,
            tools={'aclocal':'aclocal','autoconf':'autoconf','sh':'/bin/sh'},bind=lambda p:None)
        def observe(stage,argv,cwd,budget,**kw):
            row=dict(stage=stage,argv=argv,cwd=str(cwd),state='OBSERVED',exit=0,timeout=False,
                     parentReaped=True,processGroupQuiescent=True)
            ctx.commands.append(row);(out/(stage+'.process.json')).write_text(json.dumps(row))
            if stage=='config-status':(source/'include/gambit.h').write_text('new template output')
            ctx.last_budget=budget
            return ''
        ctx.require=observe
        return source,ctx

    def test_template_change_reuses_probes_via_real_status_command_and_authenticates_receipt(self):
        with tempfile.TemporaryDirectory() as temp:
            source,ctx=self.configuration_owner(Path(temp))
            request={'inputs':{'configure.ac':'policy','include/_gambit/x.h.in':'old'},'profile':'same'}
            n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            ctx.commands.clear();request['inputs']['include/_gambit/x.h.in']='new'
            proof=n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            self.assertEqual([c['stage'] for c in ctx.commands],['config-status'])
            self.assertEqual(ctx.configuration_action,'config-status');self.assertEqual(ctx.last_budget,90)
            self.assertEqual(n.completed_configuration_proof(proof)['stage'],'configure')
            ctx.commands.clear()
            n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            self.assertEqual(ctx.commands,[])
            bad=copy.deepcopy(proof);bad['templateEmission']['receiptSha256']='0'*64
            with self.assertRaises(ValueError):n.completed_configuration_proof(bad)

    def test_policy_change_reconfigures_with_distinct_standard_cache_within_same_limit(self):
        with tempfile.TemporaryDirectory() as temp:
            source,ctx=self.configuration_owner(Path(temp))
            request={'inputs':{'configure.ac':'old','include/_gambit/x.h.in':'same'}}
            n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            first=next(c for c in ctx.commands if c['stage']=='configure')['argv'][-1]
            ctx.commands.clear();request['inputs']['configure.ac']='new'
            n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            self.assertEqual([c['stage'] for c in ctx.commands],['aclocal','autoconf','configure'])
            self.assertNotEqual(first,ctx.commands[-1]['argv'][-1]);self.assertEqual(ctx.last_budget,90)

    def test_unknown_status_does_not_replace_completed_configuration_proof(self):
        with tempfile.TemporaryDirectory() as temp:
            source,ctx=self.configuration_owner(Path(temp))
            request={'inputs':{'configure.ac':'same','include/x.in':'old'}}
            n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            before=(source.parent/'configure-proof.json').read_bytes()
            def fail(*a,**kw):raise TimeoutError('status result unknown')
            ctx.require=fail;request['inputs']['include/x.in']='new'
            with self.assertRaises(TimeoutError):n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            self.assertEqual(before,(source.parent/'configure-proof.json').read_bytes())

    def test_same_request_output_corruption_rejects_without_repair_or_reuse(self):
        with tempfile.TemporaryDirectory() as temp:
            source,ctx=self.configuration_owner(Path(temp));request={'inputs':{'configure.ac':'same'}}
            n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            (source/'include/gambit.h').write_text('unexplained mutation');ctx.commands.clear()
            with self.assertRaisesRegex(ValueError,'configuration bytes changed'):
                n.configure_owned_source(ctx,source,[],managed=True,request_identity=request)
            self.assertEqual(ctx.commands,[])

    def test_shared_owner_reuses_only_the_same_request_and_never_replays_configure(self):
        from types import SimpleNamespace
        import hashlib
        with tempfile.TemporaryDirectory() as temp:
            source=Path(temp)/'source';source.mkdir()
            output=Path(temp)/'step';output.mkdir()
            for name in n.CONFIGURATION_OUTPUTS:
                p=source/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(name)
            commands=[]
            ctx=SimpleNamespace(directory=output,commands=commands,remaining=lambda:90,
                tools={'aclocal':'aclocal','autoconf':'autoconf','sh':'/bin/sh'},bind=lambda p:None)
            def observed(stage,argv,cwd,budget,**kw):
                row=dict(stage=stage,argv=argv,state='OBSERVED',exit=0,timeout=False,
                         parentReaped=True,processGroupQuiescent=True)
                commands.append(row)
                (output/(stage+'.process.json')).write_text(json.dumps(row))
                return ''
            ctx.require=observed
            self.assertIsNone(n.configure_owned_source(ctx,source,['--enable-smp'],managed=True,
                                                      request_identity={'policy':'A'}))
            self.assertEqual([c['stage'] for c in commands],['aclocal','autoconf','configure'])
            commands.clear()
            proof=n.configure_owned_source(ctx,source,['--enable-smp'],managed=True,
                                           request_identity={'policy':'A'})
            self.assertEqual(commands,[])
            self.assertEqual(proof['requestIdentity'],{'policy':'A'})
            self.assertIsNone(n.configure_owned_source(ctx,source,['--enable-smp'],managed=True,
                                                      request_identity={'policy':'B'}))
            self.assertEqual([c['stage'] for c in commands],['aclocal','autoconf','configure'])
            commands.clear()
            def unknown(*args,**kw):raise TimeoutError('configure result unknown')
            ctx.require=unknown
            with self.assertRaises(TimeoutError):
                n.configure_owned_source(ctx,source,['--enable-smp'],managed=True,
                                         request_identity={'policy':'C'})
            self.assertEqual(json.loads((source.parent/'configure-proof.json').read_text())['requestIdentity'],{'policy':'B'})

    def fixture(self):
        from gambit_smp.native_capabilities import CONFIGURATION_OUTPUTS
        raw=dict(stage='configure',state='OBSERVED',exit=0,timeout=False,
                 parentReaped=True,processGroupQuiescent=True,
                 argv=['/bin/sh','./configure','--enable-smp'])
        text=json.dumps(raw)
        import hashlib
        files={n:'hash-'+n for n in CONFIGURATION_OUTPUTS}
        configured=dict(commands=[],configurationReuse=dict(schema='gambit-configure-reuse.v1',
            receiptBytes=text,receiptSha256=hashlib.sha256(text.encode()).hexdigest(),
            commands=[raw],flags=['--enable-smp'],files=files),
            outputs=dict(source=dict(identity={n:dict(sha256=h) for n,h in files.items()})))
        return configured,raw

    def test_actual_receipt_and_configured_bytes_are_consumed_without_new_invocation(self):
        from gambit_smp.completed_producer import configure_command
        configured,raw=self.fixture()
        self.assertEqual(raw,configure_command(Path('.'),configured))

    def test_missing_digest_or_generated_bytes_cannot_substitute_for_observation(self):
        from gambit_smp.completed_producer import configure_command
        configured,_=self.fixture();configured['configurationReuse']['receiptSha256']='wrong'
        with self.assertRaises(ValueError):configure_command(Path('.'),configured)
        configured,_=self.fixture();configured['outputs']['source']['identity']['include/gambit.h']['sha256']='drift'
        with self.assertRaises(ValueError):configure_command(Path('.'),configured)

    def test_unknown_process_cannot_issue_reuse(self):
        from gambit_smp.completed_producer import configure_command
        import hashlib
        configured,raw=self.fixture();raw['processGroupQuiescent']=False;text=json.dumps(raw)
        configured['configurationReuse'].update(receiptBytes=text,receiptSha256=hashlib.sha256(text.encode()).hexdigest(),commands=[raw])
        with self.assertRaises(ValueError):configure_command(Path('.'),configured)
