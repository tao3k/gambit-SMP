"""Constructor custody rejection tests; no native product is qualified here."""
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
from gambit_smp.gerbil_build.cli_tests import retained_cli_constructor
from gambit_smp.step_checkpoint import content_id

class ConstructorCustodyTests(unittest.TestCase):
    def test_debug_target_gets_explicit_original_environment_heap_and_cwd(self):
        import json
        from gambit_smp.gerbil_build.package import observe_package_failure
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);out=root/'out';out.mkdir();roots={k:root/k for k in ('mcp','poo')}
            program=roots['poo']/'.gerbil/bin/test-program';program.parent.mkdir(parents=True)
            program.write_bytes(b'unit product, never launched');calls=[]
            original=dict(PATH='/usr/bin',SDKROOT='original-unset-by-just',GERBIL_BUILD_PREFIX='build-context')
            environments={kind:dict(PATH='/usr/bin',SDKROOT='original-unset-by-just',
                GERBIL_HOME=str(root/'compiler'),GERBIL_PATH=str(roots[kind]/'.gerbil')) for kind in roots}
            ctx=SimpleNamespace(root=root,directory=out,env=dict(original),tools={'gcc':'/usr/bin/cc'},
                commands=[],bind=lambda paths:None,remaining=lambda:1000,
                require=lambda *args:'/usr/bin/true',publish=lambda *args:{},last_stdout='',last_stderr='')
            def run(role,argv,cwd,cap):
                calls.append(dict(role=role,argv=argv,cwd=cwd,cap=cap,env=dict(ctx.env)))
                ctx.commands.append(dict(stage=role,exit=0))
                ctx.last_stdout={'poo-compiled-interface-dependencies':'PROVIDER-PROCEDURE #t',
                    'poo-original-program-compiled-view':'MODULE-OK original\nHARNESS-OK original\nOK\n'}.get(role,'')
            ctx.run=run
            with patch('gambit_smp.gerbil_build.package.failed_package_inputs',return_value=(roots,program,environments)):
                observe_package_failure(ctx,dict(environment={'GERBIL_BUILD_CORES':'12'},failedRun={}),root/'compiler')
            target=next(c for c in calls if c['role']=='poo-original-program-stack');commands=target['argv']
            self.assertEqual(target['role'],'poo-original-program-stack')
            self.assertEqual(target['cap'],300)
            self.assertIn('process launch --working-dir '+json.dumps(str(roots['poo']))+' -- -:max-heap=1G,debug=q t',commands)
            env_command=next(c for c in commands if isinstance(c,str) and c.startswith('settings set target.env-vars'))
            self.assertIn(json.dumps('GERBIL_PATH='+str(roots['poo']/'.gerbil')),env_command)
            self.assertIn(json.dumps('GERBIL_HOME='+str(root/'compiler')),env_command)
            self.assertNotIn('GERBIL_BUILD_PREFIX',target['env'])
            self.assertNotIn('GERBIL_BUILD_PREFIX',env_command)
            self.assertIn('settings set target.inherit-env false',commands)
            crash_commands=[commands[i+1] for i,value in enumerate(commands)
                            if value=='--one-line-on-crash']
            self.assertIn('register read',crash_commands)
            self.assertIn('image list -f',crash_commands)
            self.assertEqual(crash_commands[-1],'process kill')
            self.assertNotIn('SDKROOT',target['env'])
            positive=calls[-1]
            self.assertEqual(positive['argv'],[program,'-:max-heap=1G,debug=q','t'])
            self.assertEqual(positive['env']['GERBIL_LOADPATH'],
                str(roots['poo']/'.gerbil/lib')+':'+str(root/'compiler/lib'))
            self.assertEqual(positive['cap'],300)
            self.assertEqual(ctx.env,original)
            self.assertTrue(json.loads((out/'package-failure-observations.json').read_text())['diagnosticOnly'])

    def test_real_mcp_probe_requests_build_without_running_native_code(self):
        from gambit_smp.gerbil_build.package import mcp_child_service_probes
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);ctx=SimpleNamespace(env={});calls=[]
            mcp_child_service_probes(ctx,{'mcp':root/'mcp'},root/'compiler',lambda *args:calls.append(args))
            self.assertEqual([c[0] for c in calls],['mcp-empty-child','mcp-first-verify-batch'])
            self.assertEqual(calls[0][1][:2],[root/'compiler/bin/gxi','-e'])
            self.assertIn('run-verify-batch batch',calls[1][1][-1])
            self.assertEqual(calls[1][2:],(root/'mcp',90))

    def test_package_failure_debugger_requires_its_exclusive_mode(self):
        from gambit_smp.gerbil_build.consumer_tests import validate_test
        for extra in ({}, {'startupProbe':False}, {'startupProbe':True,'stackSampleAfterSeconds':2},
                      {'startupProbe':True,'startupCompilerServices':True}):
            with self.assertRaises(ValueError):
                validate_test(dict(sourceLock='profile',startupPackageFailure=True,**extra),['profile'])
        validate_test(dict(sourceLock='profile',startupPackageFailure=True,startupProbe=True),['profile'])

    def test_package_failure_rejects_foreign_run_or_unreaped_children(self):
        from gambit_smp.gerbil_build.package import failed_package_inputs
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp).resolve();run=root/'.cache/tasks/darwin/processes/validation/runs/x/outputs/result'
            run.mkdir(parents=True);ctx=SimpleNamespace(root=root,env={'GAMBIT_SMP_TASK_ID':'darwin'})
            step=dict(id='packages',outcome='DENY',commands=[dict(parentReaped=True,processGroupQuiescent=False)])
            ref=dict(run=str(run.relative_to(root)),receipt=content_id(step))
            checkpoint={'records':[{'payload':dict(schema='research-step-observation.v1',step=step)}]}
            with patch('gambit_smp.artifact_storage.observation_root'),patch(
                    'gambit_smp.reasoning_history.read_execution_checkpoint',return_value=checkpoint):
                with self.assertRaisesRegex(ValueError,'unknown child custody'):
                    failed_package_inputs(ctx,dict(failedRun=ref),root/'home')
                step['outcome']='PASS';ref['receipt']=content_id(step)
                with self.assertRaisesRegex(ValueError,'identity/outcome drift'):
                    failed_package_inputs(ctx,dict(failedRun=ref),root/'home')
                ref['run']='.cache/tasks/other/run'
                with self.assertRaisesRegex(ValueError,'outside task'):
                    failed_package_inputs(ctx,dict(failedRun=ref),root/'home')

    def test_component_view_does_not_copy_runtime_checkout_or_share_mutable_products(self):
        from gambit_smp.gerbil_build.batches import component_source_view
        with tempfile.TemporaryDirectory() as tmp:
            parent=Path(tmp)/'parent';parent.mkdir()
            for name in ('src/gambit','src/tools','build/bin','build/lib/static','build/lib/gerbil','build/lib/std','.git'):
                (parent/name).mkdir(parents=True,exist_ok=True)
            for name in ('src/gambit/runtime.c','src/tools/build.ss','build/bin/gerbil',
                         'build/lib/static/tool.c','build/lib/gerbil/core.ssi','build/lib/std/make.ssi'):
                (parent/name).write_text(name)
            (parent/'build/bin/gxi').symlink_to('gerbil')
            (parent/'build/bin/gsc').symlink_to('../../src/gambit/runtime.c')
            view=Path(tmp)/'view';receipt=component_source_view(parent,view)
            self.assertFalse((view/'.git').exists())
            self.assertFalse((view/'src/gambit').exists())
            self.assertFalse(receipt['gambitCheckoutCopied'])
            self.assertFalse((view/'build/bin/gsc').is_symlink())
            from gambit_smp.recipes import tree_identity
            self.assertTrue(tree_identity(view))
            self.assertEqual((view/'build/bin/gxi').read_bytes(),(parent/'build/bin/gerbil').read_bytes())
            target=view/'build/lib/static/tool.c';target.write_text('new owned output')
            self.assertEqual('build/lib/static/tool.c',(parent/'build/lib/static/tool.c').read_text())
            with self.assertRaisesRegex(ValueError,'must be fresh'):
                component_source_view(parent,view)

    def test_compiler_service_probe_cannot_enter_package_acceptance(self):
        from gambit_smp.gerbil_build.consumer_tests import validate_test
        for extra in ({}, {'startupProbe':False}, {'startupProbe':True,'startupFirstLoad':True}):
            with self.subTest(extra=extra), self.assertRaisesRegex(ValueError,'exclusive diagnostic'):
                validate_test(dict(sourceLock='profile',startupCompilerServices=True,**extra),['profile'])

    def test_native_consumer_cannot_skip_module_emission(self):
        from gambit_smp.gerbil_build.source_tests import _test_source_check
        profile=dict(kind='gerbil-source-check',compilerHome='unused',compilerSha256='unused',
            packageRoot='unused',source='unused',phase='before',consumerSource='unused')
        with self.assertRaisesRegex(ValueError,'completed module emission'):
            _test_source_check(profile,Path('unused'),None)

    def check_rejected(self, message, commands, *, wrong_receipt=False, source_hashes=None):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp).resolve();store=root/'.cache/tasks/darwin';run=store/'processes/validation/runs/test/outputs/product'
            run.mkdir(parents=True)
            step=dict(id='packages',commands=commands,artifacts={})
            reference=dict(run=str(run.relative_to(root)),receipt='0'*64 if wrong_receipt else content_id(step))
            ctx=SimpleNamespace(root=root,bind=lambda paths:None)
            checkpoint={'records':[{'payload':dict(schema='research-step-observation.v1',step=step)}]}
            with patch('gambit_smp.artifact_storage.observation_root'),patch(
                    'gambit_smp.reasoning_history.read_execution_checkpoint',return_value=checkpoint):
                with self.assertRaisesRegex(ValueError,message):
                    retained_cli_constructor(ctx,reference,source_hashes or {}, {},store)

    def commands(self):
        return [dict(stage=name,exit=0,timeout=False,parentReaped=True,processGroupQuiescent=True)
                for name in ('official-compiler-driver-build','official-package-manager-build',
                             'official-bach-build','official-package-manager-executable',
                             'official-executable-runtime-help')]

    def test_changed_committed_receipt_is_rejected(self):
        self.check_rejected('receipt drift',self.commands(),wrong_receipt=True)

    def test_incomplete_constructor_is_not_reusable(self):
        self.check_rejected('did not complete',self.commands()[:-1])

    def test_unknown_child_custody_blocks_reuse(self):
        commands=self.commands();commands[-1]['processGroupQuiescent']=False
        self.check_rejected('unknown child custody',commands)

    def test_executor_delta_requires_its_actual_producer(self):
        self.check_rejected('did not complete: official-compiler-base-build',self.commands(),
                            source_hashes={'compilerBaseSourceSha256':'changed'})

    def test_make_delta_requires_its_actual_producer(self):
        self.check_rejected('did not complete: official-make-build',self.commands(),
                            source_hashes={'makeSourceSha256':'changed'})

    def test_gambuild_delta_requires_actual_shell_check(self):
        self.check_rejected('did not complete: official-gambuild-script-check',self.commands(),
                            source_hashes={'gambuildTemplateSha256':'changed'})

    def test_missing_product_observation_is_not_success(self):
        self.check_rejected('observation missing or changed',self.commands())

    def test_ancestry_cycle_and_depth_budget_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp).resolve();ctx=SimpleNamespace(root=root)
            ref=dict(run='run',receipt='r');key=('run','r')
            for seen in ((key,),tuple((str(i),'r') for i in range(8))):
                with self.assertRaisesRegex(ValueError,'ancestry cycle or budget exceeded'):
                    retained_cli_constructor(ctx,ref,{}, {},root,seen)


class CliConsumerAdmissionTests(unittest.TestCase):
    def test_package_controls_require_exact_completed_cli_qualification(self):
        import json
        from gambit_smp.framework import digest
        from gambit_smp.gerbil_build.consumer_tests import _test_installed_reference
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp).resolve();home=root/'compiler/build';(home/'bin').mkdir(parents=True)
            (home/'bin/gerbil').write_bytes(b'unit input; never executed')
            out=root/'out';out.mkdir();proof=root/'proof.json'
            base=dict(kind='installed-gerbil-reference',compilerHome=str(home),
                compilerSha256=digest(home/'bin/gerbil'),packageSources=dict(mcp='mcp',poo='poo'),
                packageBudgets=dict(clean=30,build=300,test=300),environment=dict(GERBIL_BUILD_CORES='12'))
            stages={}
            for role in ('runtimeWithoutCore','runtimeAbsentSearchRoot','runtime-executable-rejection','unsupported-interface-fallback',
                         'shadow-provider-fallback','optionalBindings','interpreter','compiler',
                         'executor','executor-single-permit','coldLibrary','coldLibraryConsumer',
                         'objectClosure','objectClosureConsumer','object-closure-rejection',
                         'sharedRuntimeObjects','sharedFirst','sharedSecond'):
                negative=role.endswith(('rejection','fallback'))
                stages[role]=dict(exit=70 if negative else 0,timeout=False,parentReaped=True,
                    processGroupQuiescent=True,expectedExit=70 if negative else 0,negativeControl=negative)
            stages['runtimeWithoutCore']['argv']=[str(home/'bin/gerbil'),'help','clean']
            complete=dict(phasePassed=True,buildCores=12,compilerHome=str(home),compilerSha256=base['compilerSha256'],
                          stages=stages,sourceTreeSha256='0'*64)
            cases=[({},dict(type='gerbil-test-observations'),'committed CLI qualification'),
                   (dict(complete,phasePassed=False),None,'does not match installed compiler'),
                   (dict(complete,diagnosticOnly=True),None,'does not match installed compiler'),
                   (dict(complete,stages={}),None,'required managed CLI control missing'),
                   (dict(complete,nativeToolProducts={'gxtest':'0'*64}),None,
                    'required managed CLI control missing: embeddedTest'),
                   (dict(complete,stages={k:v for k,v in stages.items() if k!='runtimeAbsentSearchRoot'}),
                    None,'required managed CLI control missing: runtimeAbsentSearchRoot'),
                   (complete,None,'qualified compiler tree changed')]
            for data,descriptor,message in cases:
                proof.write_text(json.dumps(data))
                qualification=descriptor if descriptor is not None else dict(
                    type='gerbil-test-observations',origin={},sha256=digest(proof))
                (root/'profile.json').write_text(json.dumps(dict(base,qualification=qualification)))
                ctx=SimpleNamespace(root=root,directory=out,bind=lambda paths:None)
                with patch('gambit_smp.recipes.artifact_path',return_value=proof),patch(
                        'gambit_smp.gerbil_build.consumer_tests.execute_package') as execute:
                    with self.assertRaisesRegex(ValueError,message):
                        _test_installed_reference(dict(sourceLock='profile.json'),ctx)
                    execute.assert_not_called()


class CurrentPathReferenceTests(unittest.TestCase):
    def test_missing_current_launcher_cannot_fall_back_to_a_cellar_path(self):
        import json
        from gambit_smp.gerbil_build.consumer_tests import _test_installed_reference
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            profile=dict(kind='installed-gerbil-reference',pathReference=True,
                packageSources=dict(mcp='mcp',poo='poo'),
                packageBudgets=dict(clean=30,build=300,test=300),environment=dict(PATH=str(root)))
            (root/'profile.json').write_text(json.dumps(profile))
            ctx=SimpleNamespace(root=root,env={})
            with self.assertRaisesRegex(ValueError,'current-PATH Gerbil launcher missing'):
                _test_installed_reference(dict(sourceLock='profile.json'),ctx)

    def test_current_path_and_fixed_home_cannot_be_mixed(self):
        import json
        from gambit_smp.gerbil_build.consumer_tests import _test_installed_reference
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            profile=dict(kind='installed-gerbil-reference',pathReference=True,
                compilerHome='/old/cellar',compilerSha256='0'*64,
                packageSources=dict(mcp='mcp',poo='poo'),
                packageBudgets=dict(clean=30,build=300,test=300))
            (root/'profile.json').write_text(json.dumps(profile))
            with self.assertRaises(ValueError):
                _test_installed_reference(dict(sourceLock='profile.json'),SimpleNamespace(root=root))
