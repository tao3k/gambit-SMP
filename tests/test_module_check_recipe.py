import copy
from pathlib import Path
import tempfile
import json
import unittest
from types import SimpleNamespace
from unittest.mock import Mock, patch

from gambit_smp.research_kernel import module_check_recipe, argument_parser, execution_policy
from gambit_smp.native_capabilities import validate_regenerate


class ModuleCheckRecipeTests(unittest.TestCase):
    def setUp(self):
        self.recipe = dict(schema='evidence-recipe.v2', id='checked-import', scope='fixture',
                           inputs=['source.lock.json'], workspacePolicy='in-place',
                           timeoutPolicy={'mode': 'per-stage', 'overheadSeconds': 30}, budgetSeconds=90,
                           steps=[dict(id='source', capability='gambit.materialize', dependsOn=[],
                                       arguments={}, budgetSeconds=30),
                                  dict(id='runtime', capability='gambit.seed-checkpoint', dependsOn=['source'],
                                       arguments={}, budgetSeconds=30),
                                  dict(id='expensive', capability='gambit.source-core', dependsOn=['runtime'],
                                       arguments={}, budgetSeconds=1800)])

    def test_three_independent_checks_share_only_checked_import(self):
        before = copy.deepcopy(self.recipe)
        result = module_check_recipe(self.recipe, 'runtime')
        checks = [s for s in result['steps'] if s['capability'] == 'gambit.regenerate-module']
        self.assertEqual([s['arguments']['module'] for s in checks],
                         ['lib/_kernel.scm', 'lib/_nonstd.scm', 'lib/_system.scm'])
        for step in checks:
            self.assertEqual(step['dependsOn'], ['runtime'])
            self.assertTrue(step['arguments']['syntaxCheck'])
        self.assertNotIn('gambit.source-core', [s['capability'] for s in result['steps']])
        self.assertEqual(result['steps'][-1]['arguments']['expected'], {'missing_step': []})
        self.assertEqual(self.recipe, before)

    def test_single_module_does_not_schedule_the_other_modules(self):
        result = module_check_recipe(self.recipe, 'runtime', 'lib/_system.scm')
        self.assertEqual([s['id'] for s in result['steps']],
                         ['source', 'runtime', 'check-system', 'module-check-evidence'])
        self.assertTrue(result['steps'][2]['arguments']['phaseTrace'])
        self.assertNotIn('workTrace',result['steps'][2]['arguments'])
        traced=module_check_recipe(self.recipe,'runtime','lib/_system.scm',work_trace=True)
        self.assertTrue(traced['steps'][2]['arguments']['workTrace'])
        parsed=argument_parser().parse_args(['--module-checks','r.json','--work-trace'])
        self.assertTrue(parsed.work_trace)

    def test_native_phase_observer_is_typed_and_cannot_be_an_arbitrary_script(self):
        from gambit_smp.compiler_trace import native_observer_argv
        args=dict(runtime={'step':'runtime','output':'runtime'},module='lib/_probe.scm',phaseTrace=True)
        validate_regenerate(args,[])
        validate_regenerate(dict(args,workTrace=True),[])
        for bad in ({'workTrace':True}, {'workTrace':'yes','phaseTrace':True}):
            with self.assertRaises(ValueError):
                validate_regenerate(dict(runtime=args['runtime'],module=args['module'],**bad),[])
        for value in ['observer.scm',1,{'script':'other.scm'}]:
            with self.assertRaises(ValueError):validate_regenerate(dict(args,phaseTrace=value),[])
        with tempfile.TemporaryDirectory() as folder:
            directory=Path(folder)
            argv=['/fixed/gsc','-:~~lib=/fixed/lib','-f','-c','-prelude','(begin)','-o','out.c','_probe.scm']
            result,observer=native_observer_argv(argv,directory)
            self.assertEqual(observer['originalArgv'],argv)
            self.assertEqual(result[:4],[argv[0],argv[1],'-f','-e'])
            from gambit_smp.framework import digest
            self.assertEqual(digest(Path(observer['path'])),observer['sha256'])
            self.assertIn('##main-gsi/gsc',result[-1])
            with self.assertRaises(FileExistsError):native_observer_argv(argv,directory)
            with self.assertRaises(ValueError):native_observer_argv(['/gsc','-e','evil'],directory)

    def test_work_observer_binds_exact_selected_source_bodies(self):
        from gambit_smp.compiler_trace import native_observer_argv
        with tempfile.TemporaryDirectory() as folder:
            directory=Path(folder);source=directory/'source';out=directory/'observer';out.mkdir()
            names=('lib/_eval.scm','gsc/_env.scm','lib/gambit#.scm','lib/_gambit#.scm')
            for name in names:
                path=source/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(name)
            argv=['/gsc','-:~~lib=/lib','-f','-c','_probe.scm']
            result,observer=native_observer_argv(argv,out,work_source=source)
            self.assertEqual(set(observer['work']['sourceInputs']),
                             {str((source/name).resolve()) for name in names})
            self.assertIn('f6-work-write',result[-1])
            self.assertIn('compile-file',result[-1])
            self.assertTrue(Path(observer['work']['path']).is_file())

    def test_work_diagnostic_c_is_not_published_as_native_generated_product(self):
        from gambit_smp.native_capabilities import regenerate
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory).resolve()
            ctx=SimpleNamespace(root=root,directory=root,artifact=Mock(return_value=root),
                receipt={},remaining=lambda:60,publish=Mock())
            with patch('gambit_smp.native_capabilities.Stages'), \
                 patch('gambit_smp.gambit_build_primitives.regenerate_module',return_value=(True,{})):
                result=regenerate(dict(runtime={'step':'source','output':'runtime'},
                    module='lib/_probe.scm',phaseTrace=True,workTrace=True),ctx)
            self.assertEqual(result['outputs'],{})
            ctx.publish.assert_not_called()

    def test_model_can_choose_a_reduced_library_module_without_a_new_runner(self):
        result = module_check_recipe(self.recipe, 'runtime', 'lib/_reduced_failure.scm')
        checks = [s for s in result['steps'] if s['capability'] == 'gambit.regenerate-module']
        self.assertEqual([s['arguments']['module'] for s in checks], ['lib/_reduced_failure.scm'])
        for invalid in ('../../escape.scm', 'lib/not_a_module.scm', 'gsi/_gsi.scm'):
            with self.assertRaises(ValueError):
                module_check_recipe(self.recipe, 'runtime', invalid)

    def test_implicit_seed_build_and_reserved_acceptance_are_refused(self):
        self.recipe['steps'][1]['capability'] = 'gambit.seed-core'
        with self.assertRaisesRegex(ValueError, 'checked runtime import'):
            module_check_recipe(self.recipe, 'runtime')
        self.recipe['steps'][1]['capability'] = 'gambit.seed-checkpoint'
        self.recipe['steps'][0]['capability'] = 'gambit.source-core'
        with self.assertRaisesRegex(ValueError, 'ancestry contains'):
            module_check_recipe(self.recipe, 'runtime')
        self.recipe['steps'][0]['capability'] = 'gambit.materialize'
        self.recipe['continuationRequest'] = 'original-campaign.json'
        with self.assertRaisesRegex(ValueError, 'acceptance continuation'):
            module_check_recipe(self.recipe, 'runtime')

    def test_existing_dispatcher_exposes_data_only_entry(self):
        argv = ['--module-checks', 'import.recipe.json', '--step', 'runtime', '--module', 'lib/_kernel.scm']
        self.assertEqual(execution_policy(argv), 'read')
        self.assertIsNone(argument_parser().parse_args(argv).run)
        validate_regenerate({'runtime': {'step': 'runtime', 'output': 'runtime'},
                             'module': 'lib/_kernel.scm', 'syntaxCheck': True}, [])
        with self.assertRaises(ValueError):
            validate_regenerate({'runtime': {'step': 'runtime', 'output': 'runtime'},
                                 'module': 'lib/_kernel.scm', 'syntaxCheck': False}, [])

    def test_hosted_checks_require_configured_target_and_explicit_host(self):
        recipe = copy.deepcopy(self.recipe)
        recipe['steps'][1]['capability'] = 'gambit.configure'
        result = module_check_recipe(recipe, 'runtime', 'lib/_system.scm', bootstrap_host='host.json')
        self.assertIn('host.json', result['inputs'])
        self.assertEqual([s['capability'] for s in result['steps']],
                         ['gambit.materialize', 'gambit.configure', 'gambit.regenerate-module',
                          'evidence.evaluate'])
        args = result['steps'][2]['arguments']
        self.assertEqual(args['source'], {'step': 'runtime', 'output': 'source'})
        self.assertNotIn('runtime', args)
        validate_regenerate(args, result['inputs'])
        for changed in ({**args, 'syntaxCheck': False}, {**args, 'source': 'raw/path'},
                        {**args, 'runtime': {'step': 'runtime', 'output': 'runtime'}}):
            with self.assertRaises(ValueError):
                validate_regenerate(changed, result['inputs'])
        with self.assertRaises(ValueError):
            validate_regenerate(args, [])
        with self.assertRaises(ValueError):
            module_check_recipe(self.recipe, 'runtime', bootstrap_host='host.json')
        parsed = argument_parser().parse_args(['--module-checks', 'target.json', '--step', 'configure',
                                               '--bootstrap-host', 'host.json'])
        self.assertEqual(parsed.bootstrap_host, 'host.json')

    def test_hosted_plan_loads_without_any_target_runtime(self):
        from gambit_smp.recipes import load
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            recipe = copy.deepcopy(self.recipe)
            recipe['inputs'] = ['source.lock.json', 'profile.json']
            recipe['steps'][0]['arguments'] = {'sourceLock': 'source.lock.json', 'buildWorkspace': 'gambit-core'}
            recipe['steps'][1].update(capability='gambit.configure',
                arguments=dict(source={'step': 'source', 'output': 'source'}, buildProfile='profile.json'))
            result = module_check_recipe(recipe, 'runtime', bootstrap_host='host.json')
            for name in result['inputs']:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(Path(name).read_bytes() if name.startswith(('tests/', 'evidence/dsl/')) else b'{}')
            path = root / 'modules.recipe.json'
            path.write_text(json.dumps(result))
            _, steps = load(root, path)
            self.assertEqual([s['arguments']['sourceLock'] for s in steps if s['capability'] == 'gambit.materialize'],
                             ['source.lock.json'])
            self.assertFalse(any(s['capability'] in {'gambit.seed-core', 'gambit.source-core',
                                                  'gambit.bootstrap', 'gambit.completed-runtime'} for s in steps))

    def test_host_identity_and_target_lock_are_separate_and_drift_is_denied(self):
        from gambit_smp.framework import digest
        from gambit_smp.native_capabilities import regenerate
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            source = root / 'target'
            source.mkdir()
            host = root / 'host'
            host.write_bytes(b'fixture host, not a target producer')
            host.chmod(0o755)
            spec = dict(schema='gambit-bootstrap-host', kind='interpreted-gsc', executable='host',
                        sha256=digest(host), qualification={'scope': 'diagnostic only'})
            (root / 'host.json').write_text(json.dumps(spec))
            (root / 'target.lock.json').write_text('{"target":"current Scheme"}')
            ctx = SimpleNamespace(root=root, directory=root, artifact=Mock(return_value=source),
                receipt={'steps': [dict(id='source', capability='gambit.materialize',
                                      arguments={'sourceLock': 'target.lock.json'}),
                                 dict(id='configure', capability='gambit.configure',
                                      arguments={'source': {'step': 'source', 'output': 'source'}})]},
                bind=Mock(), remaining=lambda: 120, publish=Mock(return_value={}))
            args = dict(source={'step': 'configure', 'output': 'source'}, bootstrapHost='host.json',
                        module='lib/_system.scm', syntaxCheck=True)
            with patch('gambit_smp.native_capabilities.compiler', return_value='gcc'), \
                    patch('gambit_smp.native_capabilities.Stages'), \
                    patch('gambit_smp.gambit_build_primitives.regenerate_module',
                          return_value=(True, {'familyAdmitted': False})) as run:
                result = regenerate(args, ctx)
                self.assertEqual(result['observation']['targetBinding']['sourceLockSha256'],
                                 digest(root / 'target.lock.json'))
                self.assertEqual(run.call_args.kwargs['bootstrap_host'], host)
                self.assertEqual(run.call_args.kwargs['bootstrap_host_sha256'], spec['sha256'])
                self.assertTrue(run.call_args.kwargs['interpreted'])
                self.assertFalse(result['observation']['familyAdmitted'])
                self.assertEqual(ctx.publish.call_args.args[1], 'c-source')
                host.write_bytes(b'replaced')
                run.reset_mock()
                with self.assertRaisesRegex(ValueError, 'host executable drift'):
                    regenerate(args, ctx)
                run.assert_not_called()

    def test_generated_plan_loads_as_a_real_typed_recipe(self):
        from gambit_smp.recipes import load
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            recipe = copy.deepcopy(self.recipe)
            recipe['inputs'] = ['source.lock.json', 'seed-spec.json', 'profile.json']
            for name in recipe['inputs']:
                (root / name).write_text('{}')
            recipe['steps'][0]['arguments'] = {'sourceLock': 'source.lock.json'}
            recipe['steps'][1]['arguments'] = dict(source={'step': 'source', 'output': 'source'},
                                                   checkpoint='seed-spec.json', buildProfile='profile.json')
            result = module_check_recipe(recipe, 'runtime')
            for name in ('tests/recipes/framework-contracts/evidence-entry.json',
                         'evidence/dsl/observation-contract.ss'):
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(Path(name).read_bytes())
            path = root / 'modules.recipe.json'
            path.write_text(json.dumps(result))
            _, steps = load(root, path)
            self.assertEqual(len([s for s in steps if s['capability'] == 'gambit.regenerate-module']), 3)
