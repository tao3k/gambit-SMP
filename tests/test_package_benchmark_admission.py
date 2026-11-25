"""Synthetic policy controls; no fixture is a measured package speedup."""
from copy import deepcopy
from hashlib import sha256
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
import json
from types import SimpleNamespace

from gambit_smp.scientific_package_development_benchmark_study import paired_elapsed_values


class CompilerConstructionBoundaryTests(unittest.TestCase):
    def test_bootstrap_replacement_requires_an_owned_prior(self):
        from gambit_smp.gerbil_build import build_bazel_compiler
        with self.assertRaisesRegex(ValueError, 'explicit owned prior'):
            build_bazel_compiler(None, '.', '.', '.', multiple_threaded_vms=True,
                budgets=dict(prepare=1,build=1,verify=1),rebuild_bootstrap=True)

    def test_source_change_and_foreign_head_cannot_reuse_old_bootstrap(self):
        from gambit_smp.gerbil_build.bazel_build import _continue_bazel_compiler
        with TemporaryDirectory() as temp:
            path=Path(temp)/'prior.json'
            path.write_text(json.dumps(dict(heads={'gambit':'a'},gambitInputSha256='old')))
            ctx=SimpleNamespace(bind=lambda paths:None)
            for heads,replace in (({'gambit':'a'},False),({'gambit':'b'},True)):
                with self.subTest(heads=heads,replace=replace), self.assertRaisesRegex(
                        ValueError,'source cohort differs'):
                    _continue_bazel_compiler(ctx,path,None,heads,{},'new',{}, {},'stage1',
                                             rebuild_bootstrap=replace)

    def test_unquiescent_timeout_never_authorizes_continuation(self):
        from gambit_smp.gerbil_build.bazel_build import _continue_bazel_compiler
        with TemporaryDirectory() as temp:
            path=Path(temp)/'prior.json'
            path.write_text(json.dumps(dict(heads={'gambit':'a'},gambitInputSha256='input',
                stages={'build':dict(exit=-9,timeout=True,parentReaped=True,processGroupQuiescent=False)})))
            ctx=SimpleNamespace(bind=lambda paths:None)
            with self.assertRaisesRegex(ValueError,'reaped, quiescent timeout'):
                _continue_bazel_compiler(ctx,path,None,{'gambit':'a'},{},'input',{}, {},'stage1')

    def test_stage_reuse_needs_receipt_and_unchanged_output_not_a_label(self):
        from gambit_smp.gerbil_build.custody import _stage_completion, _current
        with TemporaryDirectory() as temp:
            root=Path(temp);source=root/'source';output=source/'build/core.o1'
            output.parent.mkdir(parents=True);output.write_bytes(b'synthetic output')
            row=dict(stage='gerbil-stage1',exit=0,timeout=False,parentReaped=True,
                     processGroupQuiescent=True)
            (root/'gerbil-stage1.process.json').write_text(json.dumps(dict(state='OBSERVED',**row)))
            ctx=SimpleNamespace(directory=root,commands=[row])
            proof=_stage_completion(ctx,source,'stage1','inputs',['build'])
            self.assertTrue(_current(source,proof,'inputs',stage='stage1'))
            output.write_bytes(b'late or modified output')
            self.assertFalse(_current(source,proof,'inputs',stage='stage1'))
            self.assertFalse(_current(source,{'label':'BUILD stage1'},'inputs',stage='stage1'))

    def test_exit_zero_cannot_replace_actual_bootstrap_consumer_marker(self):
        from gambit_smp.gerbil_build.custody import _stage_completion
        with TemporaryDirectory() as temp:
            root=Path(temp);source=root/'source';output=source/'build/core.o1'
            output.parent.mkdir(parents=True);output.write_bytes(b'synthetic object')
            stdout=root/'native.stdout';stdout.write_text('unrelated successful output\n')
            row=dict(stage='gerbil-stage1',exit=0,timeout=False,parentReaped=True,
                     processGroupQuiescent=True)
            receipt=dict(state='OBSERVED',stdoutPath=stdout.name,
                         stdoutSha256=sha256(stdout.read_bytes()).hexdigest(),**row)
            (root/'gerbil-stage1.process.json').write_text(json.dumps(receipt))
            ctx=SimpleNamespace(directory=root,commands=[row])
            with self.assertRaisesRegex(ValueError,'actual consumer marker'):
                _stage_completion(ctx,source,'stage1','inputs',['build'],
                                  required_marker='building gerbil in expected-source/lib')

    def test_implicit_historical_profile_cannot_be_silently_changed(self):
        from gambit_smp.gerbil_build import build_bazel_compiler
        with self.assertRaisesRegex(ValueError, 'explicit runtime profile'):
            build_bazel_compiler(None, '.', '.', '.', multiple_threaded_vms=False,
                                 budgets=dict(prepare=1, build=1, verify=1))

    def test_standard_runtime_profile_requires_explicit_disabled_smp_and_single_vm_header(self):
        from gambit_smp.gerbil_build import build_bazel_compiler
        with TemporaryDirectory() as temp:
            root=Path(temp);(root/'include').mkdir();(root/'lib').mkdir()
            (root/'include/gambit.h').write_text('#define ___SINGLE_THREADED_VMS\n#define ___SINGLE_VM\n')
            def admitted(paths):raise RuntimeError('profile admitted before producer')
            ctx=SimpleNamespace(bind=admitted)
            for feature,accepted in (('(define-cond-expand-feature|disable-smp|)',True),('',False),
                                     ('(define-cond-expand-feature|enable-smp|)',False)):
                (root/'lib/Makefile').write_text('PRELUDE_OPT = '+feature+'\n')
                with self.subTest(feature=feature), self.assertRaisesRegex(RuntimeError if accepted else ValueError,
                        'profile admitted' if accepted else 'explicit runtime profile'):
                    build_bazel_compiler(ctx,root,root,root,multiple_threaded_vms=False,
                        runtime_profile=dict(multipleThreadedVms=False,multipleVms=False,smp=False),
                        budgets=dict(prepare=1,build=1,verify=1))

    def test_incomplete_compiler_cannot_even_start_package_cleanup(self):
        from gambit_smp.gerbil_build import execute_package
        with TemporaryDirectory() as temp:
            home = Path(temp)/'compiler'; home.mkdir()
            package = Path(temp)/'package'; package.mkdir()
            # A missing context is deliberate: rejection must precede any
            # process, source mutation, lease or fallback to a global tool.
            with self.assertRaisesRegex(ValueError, 'complete compiled package-tool prefix'):
                execute_package(None, home, package, kind='mcp',
                                budgets=dict(clean=1, build=1, test=1))

    def test_vm_profile_mismatch_is_rejected_before_producer_execution(self):
        from gambit_smp.gerbil_build import build_bazel_compiler
        with TemporaryDirectory() as temp:
            root = Path(temp)
            source = root/'gambit'; (source/'include').mkdir(parents=True)
            (source/'include/gambit.h').write_text('#define ___SINGLE_THREADED_VMS\n')
            with self.assertRaisesRegex(ValueError, 'differs from the Darwin source configuration'):
                build_bazel_compiler(None, source, root, root,
                    multiple_threaded_vms=True, budgets=dict(prepare=1, build=1, verify=1))

    def test_header_threading_alone_cannot_authorize_the_profile(self):
        from gambit_smp.gerbil_build import build_bazel_compiler
        for missing in ('multiple-vms', 'smp'):
            with self.subTest(missing=missing), TemporaryDirectory() as temp:
                root = Path(temp)
                source = root/'gambit'; (source/'include').mkdir(parents=True)
                (source/'include/gambit.h').write_text('#define ___MULTIPLE_THREADED_VMS\n'+
                    ('' if missing == 'multiple-vms' else '#define ___MULTIPLE_VMS\n'))
                (source/'lib').mkdir()
                (source/'lib/Makefile').write_text('PRELUDE_OPT = -prelude "'+
                    ('' if missing == 'smp' else '(define-cond-expand-feature|enable-smp|)')+'"\n')
                with self.assertRaisesRegex(ValueError, 'explicit runtime profile'):
                    build_bazel_compiler(None, source, root, root,
                        multiple_threaded_vms=True, budgets=dict(prepare=1, build=1, verify=1))

    def test_smp_is_read_from_active_prelude_not_config_header_or_comments(self):
        from gambit_smp.gerbil_build import build_bazel_compiler
        feature = '(define-cond-expand-feature|enable-smp|)'
        with TemporaryDirectory() as temp:
            root = Path(temp); (root/'include').mkdir(); (root/'lib').mkdir()
            (root/'include/gambit.h').write_text(
                '#define ___MULTIPLE_THREADED_VMS\n#define ___MULTIPLE_VMS\n')
            (root/'include/config.h').write_text('/* not a Scheme prelude */\n')
            def reached_binding(paths):
                self.assertIn((root/'lib/Makefile').resolve(), paths)
                raise RuntimeError('profile admitted before native producer')
            ctx = SimpleNamespace(bind=reached_binding)
            for prelude, accepted in (('PRELUDE_OPT = -prelude "'+feature+'"\n', True),
                                      ('# PRELUDE_OPT = '+feature+'\n', False),
                                      ('OTHER = '+feature+'\nPRELUDE_OPT = ""\n', False)):
                (root/'lib/Makefile').write_text(prelude)
                with self.subTest(prelude=prelude), self.assertRaisesRegex(
                        RuntimeError if accepted else ValueError,
                        'profile admitted' if accepted else 'explicit runtime profile'):
                    build_bazel_compiler(ctx, root, root, root,
                        multiple_threaded_vms=True, budgets=dict(prepare=1, build=1, verify=1))


def stamp(value):
    return sha256(value.encode()).hexdigest()


class PairedElapsedTests(unittest.TestCase):
    def setUp(self):
        self.cases = ['package-clean', 'no-change', 'leaf-edit', 'macro-edit',
                      'required-correctness']
        self.policy = dict(repositories=['mcp', 'poo'], cases=self.cases,
            coldCase='package-clean', targetFactor=2, profile=stamp('common profile'),
            compilers={arm: stamp(arm) for arm in ('reference', 'candidate')},
            requests={repo: dict(package=stamp(repo), graph=stamp(repo+' graph'),
                inputs={case: stamp(repo+case) for case in self.cases},
                budgetsNs={case: 1000 for case in self.cases}) for repo in ('mcp', 'poo')})
        self.rows = []
        for repo, request in self.policy['requests'].items():
            for arm, compiler in self.policy['compilers'].items():
                for case in self.cases:
                    self.rows.append(dict(repo=repo, arm=arm, case=case,
                        profile=self.policy['profile'], compiler=compiler,
                        package=request['package'], graph=request['graph'],
                        input=request['inputs'][case], elapsedNs=100 if arm=='reference' else 50,
                        receipt=stamp(repo+arm+case), exit=0, timeout=False,
                        parentReaped=True, processGroupQuiescent=True,
                        completeRequest=True, semanticPass=True, negativeControlsPass=True,
                        preparationPass=True))

    def compare(self):
        return paired_elapsed_values(self.policy, self.rows)

    def test_exact_twofold_boundary_is_per_package_not_an_average(self):
        result = self.compare()
        self.assertTrue(result['pairedValuesComplete'])
        self.assertTrue(result['targetReached'])
        self.assertFalse(result['nativeAdmitted'])
        self.assertFalse(result['mergeAllowed'])
        for row in self.rows:
            if row['repo']=='poo' and row['arm']=='candidate' and row['case']=='package-clean':
                row['elapsedNs']=51
        result = self.compare()
        self.assertFalse(result['targetReached'])
        self.assertTrue(all(r['allCasesNonRegressing'] for r in result['repositories']))

    def test_incremental_regression_blocks_target_despite_fast_cold_build(self):
        next(r for r in self.rows if r['arm']=='candidate' and r['case']=='macro-edit')['elapsedNs']=101
        self.assertFalse(self.compare()['targetReached'])

    def test_missing_case_and_unknown_completion_never_become_elapsed_credit(self):
        self.rows.pop()
        result=self.compare()
        self.assertEqual(1,len(result['missing']))
        self.assertEqual(19,len(result['observedCells']))
        self.assertFalse(result['pairedValuesComplete'])
        self.assertEqual([],result['repositories'])

    def test_duplicate_cells_and_receipt_reuse_are_not_best_sample_selection(self):
        self.rows.append(deepcopy(self.rows[0]))
        with self.assertRaisesRegex(ValueError,'duplicate'):self.compare()
        self.rows.pop()
        self.rows[1]['receipt']=self.rows[0]['receipt']
        with self.assertRaisesRegex(ValueError,'multiple executions'):self.compare()

    def test_censoring_and_all_completion_controls_are_required(self):
        original=deepcopy(self.rows)
        for key, value in (('exit',70),('exit',False),('timeout',True),
                ('parentReaped',False),('processGroupQuiescent',False),
                ('completeRequest',False),('semanticPass',False),
                ('negativeControlsPass',False),('preparationPass',False)):
            with self.subTest(key=key,value=value):
                self.rows=deepcopy(original);self.rows[0][key]=value
                result=self.compare()
                self.assertFalse(result['pairedValuesComplete'])
                self.assertTrue(result['censored'])

    def test_time_beyond_original_budget_remains_censored(self):
        self.rows[0]['elapsedNs']=1001
        self.assertFalse(self.compare()['pairedValuesComplete'])

    def test_all_source_profile_and_request_identities_must_match(self):
        original=deepcopy(self.rows)
        for key in ('profile','compiler','package','graph','input'):
            with self.subTest(key=key):
                self.rows=deepcopy(original);self.rows[0][key]=stamp('wrong')
                with self.assertRaisesRegex(ValueError,'mismatch'):self.compare()

    def test_values_use_exact_positive_integer_nanoseconds(self):
        for value in (True,0,-1,1.5,float('nan'),float('inf')):
            with self.subTest(value=value):
                self.rows[0]['elapsedNs']=value
                with self.assertRaises(ValueError):self.compare()

    def test_workload_cannot_be_shrunk_to_a_fast_component(self):
        self.policy['cases']=['package-clean']
        with self.assertRaisesRegex(ValueError,'five cases'):self.compare()

    def test_target_cannot_be_weakened_to_net_positive(self):
        self.policy['targetFactor']=1
        with self.assertRaisesRegex(ValueError,'twofold'):self.compare()


class AscentPackageGateTests(unittest.TestCase):
    def test_measurement_positive_gain_and_twofold_have_distinct_authority(self):
        from ascent import Engine
        root=Path(__file__).resolve().parents[1]
        rules=(root/'dev/modeling/ascent/package-development-benchmark.rules.scm').read_text()
        engine=Engine()
        try:
            session=engine.open_sources(rules)
            self.assertTrue(session.run(queries=['measurementReady'])['complete'])
            repos=('mcp','poo')
            cases=('package-clean','leaf-edit','macro-edit','no-change','required-correctness')
            needs=[[r,'head','graph','toolchain','budget','cache','clock'] for r in repos]
            pairs=[[r,'before','after'] for r in repos]
            facts=dict(requested=[['both']],requiredRepository=[['both',r] for r in repos],
                benchmarkNeed=needs,
                benchmarkObserved=[r+['yes','yes','no','yes'] for r in needs],
                caseNeed=[[r,c] for r in repos for c in cases],
                caseSeen=[[r,c,'matched-semantic-pass'] for r in repos for c in cases],
                candidatePairNeed=pairs,
                candidatePairSeen=[r+['same-work-full-context'] for r in pairs],
                performanceWitness=[[r,'net-positive-or-required-nonregression'] for r in repos],
                measurementNeed=[r+['profile'] for r in pairs],
                measurementBinding=[r+['profile'] for r in pairs])
            queries=['measurementReady','optimizationAccepted','twofoldAccepted']
            session.replace(facts)
            result=session.run(queries=queries)
            self.assertTrue(result['complete'])
            self.assertEqual(2,len(result['relations']['measurementReady']))
            self.assertTrue(result['relations']['optimizationAccepted'])
            self.assertFalse(result['relations']['twofoldAccepted'])
            witnesses=[r+['profile','twofold-all-cases-nonregressing'] for r in pairs]
            for variant in ('one-repo','wrong-pair','wrong-profile','weaker-status','complete'):
                amended=deepcopy(facts);rows=deepcopy(witnesses)
                if variant=='one-repo':rows=rows[:1]
                if variant=='wrong-pair':rows[0][2]='other-candidate'
                if variant=='wrong-profile':rows[0][3]='other-profile'
                if variant=='weaker-status':rows[0][4]='net-positive'
                amended['pairedElapsedWitness']=rows
                session.replace(amended)
                result=session.run(queries=queries)
                self.assertTrue(result['complete'])
                self.assertEqual(variant=='complete',bool(result['relations']['twofoldAccepted']))
            # Formal-route gaps block release acceptance, not safe measurement.
            amended=deepcopy(facts)
            amended['routeNeed']=[['open','source','evidence','qnt','test','lean','lemma','scope']]
            amended['pairedElapsedWitness']=witnesses
            session.replace(amended)
            result=session.run(queries=queries)
            self.assertEqual(2,len(result['relations']['measurementReady']))
            self.assertFalse(result['relations']['optimizationAccepted'])
            self.assertFalse(result['relations']['twofoldAccepted'])
        finally:
            engine.close()
