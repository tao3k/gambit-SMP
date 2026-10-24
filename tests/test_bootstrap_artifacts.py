"""Storage/typing regressions; no native GC or bootstrap admission."""
import json
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


class RegisteredArtifactCustodyTests(unittest.TestCase):
    from tests.test_workspace import WorkspaceTests
    setUp = WorkspaceTests.setUp

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
