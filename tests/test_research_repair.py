import copy
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from gambit_smp import research_kernel as kernel
from gambit_smp import research_repair as repair
from gambit_smp.framework import digest


class ResearchRepairTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name).resolve()
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        self.task = 'repair-fixture'
        self.baseline = self.root / '.cache/tasks' / self.task / 'runs/original'
        self.patch = self.root / 'candidate.patch'
        self.patch.write_text('fixture overlay')
        host = self.root / 'gsi'
        host.write_text('fixture interpreter identity')
        host.chmod(0o755)
        self.host_sha = digest(host)
        self.write(self.root / 'host.json', dict(schema='gambit-bootstrap-host', kind='interpreted-gsc',
                   executable='gsi', sha256=self.host_sha, qualification={}))
        self.revision = 'a' * 40
        self.source_sha = 'b' * 64
        self.lock = dict(schema='gambit-runtime-source-lock.v1', repository='https://git.cons.io/mighty-gerbils/gambit.git',
                         submodule='vendor/gambit', revision=self.revision, patch='candidate.patch',
                         patchSha256=digest(self.patch), runtimeAdmitted=False, releaseAdmitted=False,
                         files={'lib/_sample.scm': dict(baseSha256=None, candidateSha256=self.source_sha)})
        self.write(self.root / 'source.lock.json', self.lock)
        self.steps = [
            dict(id='source', capability='gambit.materialize', dependsOn=[], budgetSeconds=5,
                 arguments=dict(sourceLock='source.lock.json', buildWorkspace='gambit-core')),
            dict(id='configure', capability='gambit.configure', dependsOn=['source'], budgetSeconds=5,
                 arguments=dict(source=dict(step='source', output='source'))),
            dict(id='module', capability=repair.MODULE, dependsOn=['configure'], budgetSeconds=5,
                 arguments=dict(source=dict(step='configure', output='source'), bootstrapHost='host.json',
                                module='lib/_sample.scm', syntaxCheck=True)),
            dict(id='evaluate', capability='evidence.evaluate', dependsOn=['module'], budgetSeconds=5, arguments={}),
        ]
        self.recipe = dict(schema=kernel.SCHEMA, id='sample', steps=self.steps, budgetSeconds=20,
                           inputs=['source.lock.json', 'candidate.patch', 'host.json'], workspacePolicy='in-place')
        self.recipe_path = self.root / 'candidate.recipe.json'
        self.write(self.recipe_path, self.recipe)
        self.engine = dict(engineId='fixture-seal', hostTools={'python': {'path': '/fixture/python'}})
        self.old_receipt = self.record_failure()
        self.context = repair.repair_context(self.root, self.baseline, self.old_receipt)
        self.plan = dict(schema='research-repair-plan.v1', baselinePrefix=self.context['baselinePrefix'],
                         failureStep='module', targetStep='module', intent='repair',
                         hypothesis='An allocation phase probe can distinguish the failure.')
        self.plan_path = self.root / 'proposal.json'

    def write(self, path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value))
        return digest(path)

    def inputs(self):
        return {name: digest(self.root / name) for name in [self.recipe_path.name, *self.recipe['inputs']]}

    def record_failure(self):
        run = self.baseline
        source = run / 'run/source'
        source.mkdir(parents=True)
        revision = source / 'revision.stdout'
        revision.write_text(self.revision + '\n')
        log = run / 'run/module/emit.log'
        log.parent.mkdir()
        log.write_text('*** ERROR IN compiler -- Heap overflow\n')
        rows = copy.deepcopy(self.steps)
        rows[0].update(outcome='PASS', commands=[dict(stage='locked-revision', stdoutPath=revision.name,
            stdoutSha256=digest(revision))], outputs={'source': {'identity': {'lib/_sample.scm': {'sha256': self.source_sha}}}})
        obs = self.write(run / 'run/module/observation.json', {'hostSha256': self.host_sha})
        rows[2].update(outcome='DENY', artifacts={'module/observation.json': obs},
                       commands=[dict(stage='regenerate-module', log='emit.log', logSha256=digest(log),
                                      exit=0, timeout=False)])
        stream = log.with_suffix('.stdout')
        prefix = 'GAMBIT-COMPILER-TRACE\tv1\t'
        stream.write_text(
            'compiler-main\n'
            + prefix + 'parse\tenter\t0\t0\tparse\n'
            + prefix + 'parse\tmacro-requeue\t4\t16\tmacro-site\n'
            + prefix + 'parse\treturn\t0\t0\tparse\n'
            + prefix + 'beta-reduce\tinline-clone\t256\t64\tinline-site\n'
            + prefix + 'gvm-purify\tenter\t0\t0\tpurify\n'
            + prefix + 'gvm-purify\tgvm-label-revisit\t7\t3\tproc-site\n'
            + prefix + 'gvm-purify\treturn\t0\t0\tpurify'  # Interrupted record.
        )
        rows[2]['commands'][0].update(stdoutPath=stream.name, stdoutSha256=digest(stream),
                                      streamCaptureComplete=False)
        child_sha = self.write(run / 'run/receipt.json', dict(schema='evidence-recipe-run.v1',
            recipe=self.recipe['id'], steps=rows, inputsStable=True))
        outer = dict(schema='sealed-research-run.v1', recipe=self.recipe['id'], inputs=self.inputs(),
                     root=str(self.root), parentReaped=True, processGroupQuiescent=True, outcome='DENY',
                     engineId=self.engine['engineId'], budgetSeconds=20, childReceiptSha256=child_sha)
        kernel.retain_run_record(self.root, run / 'run-header.json', 'repair-fixture',
            dict(schema='research-run-header.v1', runId='original', declaration=self.recipe,
                 recipe=self.recipe['id'], engineId=self.engine['engineId'], inputs=self.inputs(),
                 request={'root': str(self.root)}), {})
        self.write(run / 'receipt.json', outer)
        kernel.retain_terminal_run(self.root, run, outer)
        return outer

    def review(self, prior=None):
        self.write(self.plan_path, self.plan)
        return repair.review_repair(self.root, prior or self.baseline, self.recipe, self.steps,
                                    self.inputs(), self.engine, self.plan_path, task=self.task)

    def test_zero_exit_diagnostic_and_unchanged_candidate(self):
        self.assertIn(['module', 'regenerate-module', 'diagnostic-in-command-log'],
                      self.context['inference']['relations']['localized'])
        self.assertIn('Heap overflow', self.context['cuts'][0]['diagnostics'][0]['diagnostics'][0]['text'])
        self.recipe['id'] = 'renamed-candidate'
        self.write(self.recipe_path, self.recipe)
        result = self.review()
        self.assertEqual(result['status'], 'blocked')
        self.assertIn(['no-causal-delta'], result['inference']['relations']['blocked'])

    def test_hosted_compiler_trace_reaches_ascent_and_rejects_changed_stream(self):
        context = self.context
        trace = context['cuts'][0]['compilerTrace']
        self.assertFalse(trace['captureComplete'])
        ref = (self.baseline / 'run' / trace['reference']).relative_to(self.root).as_posix()
        relations = context['inference']['relations']
        self.assertEqual(relations['compiler_frontier'], [['module', 'gvm-purify', 'enter', ref, 6]])
        self.assertCountEqual(relations['compiler_signal'], [
            ['module', 'parse', 'macro-requeue', 'macro-site', 4, 16, ref, 3],
            ['module', 'beta-reduce', 'inline-clone', 'inline-site', 256, 64, ref, 5],
            ['module', 'gvm-purify', 'gvm-label-revisit', 'proc-site', 7, 3, ref, 7],
        ])
        self.assertEqual(relations['compiler_unreturned_signal'], [
            ['module', 'gvm-purify', 'gvm-label-revisit', 'proc-site', 7, 3, ref, 7],
        ])
        (self.baseline / 'run' / trace['reference']).write_text('compiler-main\n')
        context = repair.repair_context(self.root, self.baseline, self.old_receipt)
        self.assertEqual(context['cuts'][0]['compilerTrace']['status'], 'UNVERIFIED')
        self.assertEqual(context['inference']['relations']['compiler_signal'], [])
        self.assertIn(['module', 'regenerate-module', 'no-bound-compiler-boundary'],
                      context['inference']['relations']['evidence_gap'])

    def native_trace_cut(self, stdout=None, stderr=None):
        child=json.loads((self.baseline/'run/receipt.json').read_text())
        step=child['steps'][2]
        step['arguments'].pop('bootstrapHost')
        command=step['commands'][0]
        for stream,text in [('stdout',stdout),('stderr',stderr)]:
            if text is not None:
                path=self.baseline/'run/module'/('native.'+stream)
                path.write_text(text)
                command[stream+'Path']=path.name
                command[stream+'Sha256']=digest(path)
        return child,step

    def test_native_gsc_trace_reaches_existing_ascent_without_host_spec(self):
        child,step=self.native_trace_cut()
        step['observation']={'phaseObserver':{'work':{'mode':'source-instantiated-diagnostic'}},
                             'diagnosticCNotReusable':True,'mode':'frontend-work-diagnostic'}
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        self.assertEqual(cuts[0]['compilerTrace']['observationStatus'],'PHASE_EVENTS_PRESENT')
        self.assertTrue(cuts[0]['compilerTrace']['diagnosticCNotReusable'])
        self.assertEqual(cuts[0]['compilerTrace']['producerMeaning'],'frontend-work-diagnostic')
        self.assertEqual(repair._project(facts)['relations']['compiler_frontier'][0][1],'gvm-purify')
        self.assertFalse(repair._hosted(step))  # Read coverage grants no hosted execution role.

    def test_native_gsc_without_phase_events_is_an_evidence_gap(self):
        child,step=self.native_trace_cut(stdout='Parsing:\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        trace=cuts[0]['compilerTrace']
        self.assertEqual(trace['observationStatus'],'NO_PHASE_EVENTS')
        self.assertIsNone(trace['frontier'])
        self.assertEqual(repair._project(facts)['relations']['compiler_frontier'],[])
        self.assertIn(['module','regenerate-module','no-bound-compiler-boundary'],
                      repair._project(facts)['relations']['evidence_gap'])

    def test_cumulative_work_and_monotonic_elapsed_survive_event_display_cap(self):
        prefix='GAMBIT-COMPILER-TRACE\tv1\t'
        rows=[prefix+'parse\tenter\t1\t0\tc#parse-program']
        rows += [prefix+f'frontend-work\tcount\t{i}\t0\tsourcify-analyze' for i in range(600)]
        rows += [prefix+'parse\treturn\t603\t0\tc#parse-program',
                 prefix+'parse\telapsed-ns\t123456\t1\tc#parse-program']
        child,step=self.native_trace_cut(stdout='Parsing:\n',stderr='\n'.join(rows)+'\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        trace=cuts[0]['compilerTrace']
        self.assertTrue(trace['eventsTruncated'])
        self.assertEqual(trace['workCounters']['sourcify-analyze']['value'],599)
        self.assertEqual(trace['phaseElapsed']['parse']['inclusiveNanoseconds'],123456)
        relations=repair._project(facts)['relations']
        signals=relations['compiler_signal']
        self.assertTrue(any(row[1:6]==['frontend-work','count','sourcify-analyze',599,0] for row in signals))
        self.assertTrue(any(row[1:6]==['parse','elapsed-ns-total','completed-wrapper-calls',123456,1] for row in signals))
        self.assertEqual(trace['frontier']['kind'],'return')

    def test_regressing_counter_is_not_admitted_to_ascent(self):
        prefix='GAMBIT-COMPILER-TRACE\tv1\tfrontend-work\tcount\t'
        child,step=self.native_trace_cut(stdout='',stderr=prefix+'9\t0\tenv-frames\n'+prefix+'8\t0\tenv-frames\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        self.assertEqual(cuts[0]['compilerTrace']['status'],'UNVERIFIED')
        self.assertEqual(repair._project(facts)['relations']['compiler_signal'],[])

    def test_elapsed_requires_a_unique_matching_wrapper_call(self):
        child,step=self.native_trace_cut(stdout='',stderr=
            'GAMBIT-COMPILER-TRACE\tv1\tparse\telapsed-ns\t100\t9\tc#parse-program\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        self.assertEqual(cuts[0]['compilerTrace']['status'],'UNVERIFIED')
        self.assertEqual(repair._project(facts)['relations']['compiler_signal'],[])

    def test_macro_build_identity_and_tail_classification_survive_display_cap(self):
        prefix='GAMBIT-COMPILER-TRACE\tv1\tmacro-cache\t'
        rows=['GAMBIT-COMPILER-TRACE\tv1\tparse\tenter\t1\t0\tc#parse-program']
        def event(kind,a,b,site='macro-list-table'):
            rows.append(prefix+f'{kind}\t{a}\t{b}\t{site}')
        def build(head,bid,cache,prior,oldcache,total,shared,novel,tail=0,owner=0,prefix_cells=0):
            event('build',head,bid)
            for kind,value in [('cache-root',cache),('prior-builds',prior),('previous-cache',oldcache),
                ('build-cells',total),('shared-cells',shared),('novel-cells',novel),
                ('shared-tail',tail),('tail-owner',owner),('prefix-cells',prefix_cells),
                ('owner-mismatches',0),('within-build-revisits',0)]:event(kind,bid,value)
            event('published',bid,1)
        for _ in range(520):event('generation-same',0,0,'env-macros-set')
        build(10,1,90,0,0,2,0,2)
        event('generation-prepend',10,11,'env-macros-set')
        event('generation-name',11,0,'new-macro')
        build(11,2,90,0,0,3,2,1,10,1,1)
        build(10,3,90,1,90,2,2,0,10,2,0)
        build(10,4,91,2,90,2,2,0,10,3,0)
        build(12,5,91,0,0,2,0,2)  # Equal content is not object identity.
        event('build',13,6)  # Interrupted build is retained, never classified as complete.
        child,step=self.native_trace_cut(stdout='',stderr='\n'.join(rows)+'\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        self.assertTrue(cuts[0]['compilerTrace']['eventsTruncated'])
        macro=cuts[0]['compilerTrace']['macroCache']
        self.assertEqual((macro['completedBuilds'],macro['incompleteBuilds']),(5,1))
        self.assertEqual([row.get('classification') for row in macro['builds'][:5]],
            ['new-key-independent','new-key-shared-tail','same-key-same-cache-rebuild',
             'same-key-new-cache-rebuild','new-key-independent'])
        self.assertEqual(macro['builds'][1]['tailOwnerBuild'],1)
        self.assertEqual(macro['builds'][1]['headNames'],['new-macro'])
        self.assertEqual(macro['builds'][1]['phase'],'parse')
        self.assertTrue(macro['builds'][1]['generationLines'])
        signals=repair._project(facts)['relations']['compiler_signal']
        self.assertTrue(any(row[2]=='same-key-same-cache-rebuild' for row in signals))
        self.assertTrue(any(row[2]=='shared-tail-owner' and row[4:6]==[2,1] for row in signals))

    def test_macro_publication_requires_consistent_cell_accounting(self):
        from gambit_smp.compiler_trace import _MacroCacheTrace
        trace=_MacroCacheTrace()
        trace.observe(dict(kind='build',first=1,second=1,line=1))
        for key in trace.fields:
            trace.observe(dict(kind=key,first=1,second=2 if key=='build-cells' else 0,line=2))
        with self.assertRaisesRegex(ValueError,'cell accounting'):
            trace.observe(dict(kind='published',first=1,second=1,line=3))

    def test_native_stderr_phase_keeps_its_own_log_reference(self):
        child,step=self.native_trace_cut(stdout='',stderr='phase parse\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        trace=cuts[0]['compilerTrace']
        self.assertEqual(trace['stream'],'stderr')
        boundary=repair._project(facts)['relations']['compiler_frontier'][0]
        self.assertEqual(boundary[1:3],['parse','legacy-enter'])
        self.assertTrue(boundary[3].endswith('/native.stderr'))

    def test_separate_phase_streams_do_not_invent_a_total_order(self):
        child,step=self.native_trace_cut(stderr='GAMBIT-COMPILER-TRACE\tv1\tparse\tenter\t1\t0\tparse\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        trace=cuts[0]['compilerTrace']
        self.assertEqual(trace['observationStatus'],'MULTIPLE_PHASE_STREAMS')
        self.assertEqual(len(trace['streams']),2)
        self.assertEqual(repair._project(facts)['relations']['compiler_frontier'],[])

    def test_protocol_stream_keeps_legacy_emission_as_unordered_auxiliary(self):
        child,step=self.native_trace_cut(stdout=';; emit-proc x\n',
            stderr='GAMBIT-COMPILER-TRACE\tv1\tparse\tenter\t1\t0\tparse\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        trace=cuts[0]['compilerTrace']
        self.assertEqual(trace['stream'],'stderr')
        self.assertEqual(trace['frontierScope'],'selected-stream-only')
        self.assertFalse(trace['crossStreamOrderEstablished'])
        self.assertEqual(trace['auxiliaryStreams'][0]['stream'],'stdout')
        self.assertEqual(repair._project(facts)['relations']['compiler_frontier'][0][1],'parse')

    def test_changed_stderr_cannot_fall_back_to_verified_stdout(self):
        child,step=self.native_trace_cut(stderr='phase parse\n')
        (self.baseline/'run/module/native.stderr').write_text('phase normalize\n')
        cuts,facts=repair._cuts(self.root,self.baseline,child)
        self.assertEqual(cuts[0]['compilerTrace']['status'],'UNVERIFIED')
        self.assertEqual(facts.get('compiler_event',[]),[])

    def test_probe_choice_does_not_verify_original_and_budgets_are_fixed(self):
        self.steps[2]['arguments']['module'] = 'lib/_reduced.scm'
        self.assertIn(['repair-requires-original-module'], self.review()['inference']['relations']['blocked'])
        self.plan['intent'] = 'probe'
        self.assertEqual(self.review()['status'], 'eligible')
        self.steps[2]['budgetSeconds'] += 1
        self.assertIn(['diagnostic-budget'], self.review()['inference']['relations']['blocked'])
        self.steps[2]['budgetSeconds'] -= 1
        self.steps.append(dict(id='core', capability='gambit.source-core', dependsOn=['configure'],
                               arguments={}, budgetSeconds=1))
        self.assertIn(['diagnostic-scope'], self.review()['inference']['relations']['blocked'])

    def test_probe_can_compose_registered_observation_inside_budget(self):
        self.plan['intent'] = 'probe'
        self.steps[2]['arguments']['module'] = 'lib/_reduced.scm'
        self.steps[2]['budgetSeconds'] -= 1
        self.steps.insert(3, dict(id='inspect', capability='source.contract', dependsOn=['module'],
                                  arguments={}, budgetSeconds=1))
        self.steps[-1]['dependsOn'].append('inspect')
        self.assertEqual(self.review()['status'], 'eligible')
        self.steps[3]['capability'] = 'gambit.suite'
        self.assertIn(['diagnostic-scope'], self.review()['inference']['relations']['blocked'])

    def run_candidate(self, out, prior, *, corrupt_patch=False, no_child=False):
        self.write(self.plan_path, self.plan)
        def execute(*args, metadata, **kwargs):
            metadata.update(parentReaped=True, processGroupQuiescent=True)
            if no_child:
                return 2, 'worker exited before producing a child receipt', False, 0.1
            rows = copy.deepcopy(self.steps)
            if corrupt_patch:
                log = out / 'run/source/patch-inventory.log'
                log.parent.mkdir(parents=True)
                log.write_text('error: corrupt patch at line 5\n')
                rows[0].update(outcome='DENY', commands=[dict(
                    stage='patch-inventory', argv=['git', '--git-dir=/dev/null', 'apply', '--numstat', '-z', str(self.patch)],
                    exit=128, parentReaped=True, processGroupQuiescent=True, log=log.name, logSha256=digest(log))])
                rows[1].update(outcome='BLOCKED')
                rows[2].update(outcome='BLOCKED')
                self.write(out / 'run/receipt.json', dict(schema='evidence-recipe-run.v1', recipe=self.recipe['id'],
                                                         steps=rows, outcome='DENY', inputsStable=True))
                return 2, '', False, 0.1
            module = out / 'run/module'
            module.mkdir(parents=True)
            selected_module = self.steps[2]['arguments']['module']
            generated = module / Path(selected_module).with_suffix('.c').name
            generated.write_text('int generated;\n')
            row = rows[2]
            source = out / 'run/source'
            source.mkdir()
            revision = source / 'revision.stdout'
            revision.write_text(self.revision + '\n')
            rows[0].update(outcome='PASS', commands=[dict(stage='locked-revision', stdoutPath=revision.name,
                stdoutSha256=digest(revision))], outputs={'source': {'identity': {
                    name: {'sha256': binding['candidateSha256']} for name, binding in self.lock['files'].items()}}})
            observation_sha = self.write(module / 'observation.json',
                dict(module=selected_module, hostSha256=self.host_sha, inputsStable=True,
                     targetBinding=dict(sourceLockSha256=digest(self.root / 'source.lock.json')),
                     generatedSha256=digest(generated), syntaxChecked=True))
            row.update(outcome='PASS', artifacts={'module/observation.json': observation_sha},
                       commands=[dict(stage=phase, exit=0, timeout=False, parentReaped=True,
                                      processGroupQuiescent=True)
                                 for phase in ('regenerate-module', 'module-syntax-check')],
                       outputs={'generated': {'type': 'c-source', 'path': 'module/' + generated.name,
                                              'sha256': digest(generated)}})
            self.write(out / 'run/receipt.json', dict(schema='evidence-recipe-run.v1', recipe=self.recipe['id'],
                                                     steps=rows, outcome='PASS', inputsStable=True))
            return 0, '', False, 0.1

        with patch.dict('os.environ', {'GAMBIT_SMP_TASK_ID': self.task}), \
                patch('gambit_smp.recipes.load', return_value=(self.recipe, self.steps)), \
                patch('gambit_smp.host_environment.observe', return_value=None), \
                patch('gambit_smp.host_environment.execution_environment', return_value={}), \
                patch.object(kernel, 'manifest_paths', return_value=self.engine), \
                patch.object(kernel, 'transport_compatibility', return_value={'current': True}), \
                patch.object(kernel, 'execute', side_effect=execute) as worker:
            receipt = kernel.run_sealed(self.root, self.recipe_path, out, self.root / 'engine',
                                        prior=prior, repair_plan=self.plan_path, allow_native=True)
        worker.assert_called_once()
        return receipt

    def test_changed_source_runs_through_sealed_entry_and_verifies_bound_product(self):
        self.lock['files']['lib/_sample.scm']['candidateSha256'] = 'c' * 64
        self.write(self.root / 'source.lock.json', self.lock)
        selection = self.review()
        self.assertEqual(selection['status'], 'eligible')
        out = self.baseline.with_name('candidate')
        receipt = self.run_candidate(out, self.baseline)
        self.assertEqual(receipt['repair']['status'], 'verified')
        self.assertFalse(receipt['runtimeAdmitted'])
        self.assertEqual(receipt['repair']['identity'], selection['identity'])
        request = json.loads((out / 'request.json').read_text())
        self.assertIsNone(request['prior'])
        self.assertEqual(json.loads((self.baseline / 'receipt.json').read_text()), self.old_receipt)
        (out / 'run/module/_sample.c').write_text('substituted')
        self.assertEqual(repair.verify_repair(out, receipt, selection)['status'], 'inconclusive')

    def test_successful_probe_can_precede_original_repair(self):
        self.recipe['id'] = 'probe-cut'
        self.steps[2]['arguments']['module'] = 'lib/_reduced.scm'
        self.plan['intent'] = 'probe'
        self.write(self.recipe_path, self.recipe)
        probe = self.baseline.with_name('probe')
        self.assertEqual(self.run_candidate(probe, self.baseline)['repair']['status'], 'probe-observed')
        self.plan.update(intent='repair', failureRun=self.baseline.relative_to(self.root).as_posix())
        self.recipe['id'] = 'sample'
        self.steps[2]['arguments']['module'] = 'lib/_sample.scm'
        self.lock['files']['lib/_sample.scm']['candidateSha256'] = 'c' * 64
        self.write(self.root / 'source.lock.json', self.lock)
        self.write(self.recipe_path, self.recipe)
        receipt = self.run_candidate(self.baseline.with_name('follow-up'), probe)
        self.assertEqual(receipt['repair']['status'], 'verified')
        self.assertEqual(receipt['repair']['lineage'], [str(self.baseline), str(probe)])

    def test_corrected_patch_can_follow_inconclusive_preparation_failure(self):
        self.lock['files']['lib/_sample.scm']['candidateSha256'] = 'c' * 64
        self.write(self.root / 'source.lock.json', self.lock)
        failed = self.baseline.with_name('malformed-patch')
        failure = self.run_candidate(failed, self.baseline, corrupt_patch=True)
        self.assertEqual(failure['repair']['status'], 'inconclusive')
        diagnostic = failure['repair']['preparationFailures'][0]['diagnostics'][0]
        self.assertEqual(diagnostic['command'], 'patch-inventory')
        self.assertEqual(diagnostic['status'], 'RECEIPT_BOUND')
        self.plan['failureRun'] = self.baseline.relative_to(self.root).as_posix()
        self.assertIn(['unchanged-predecessor'], self.review(failed)['inference']['relations']['blocked'])

        self.patch.write_text('fixture corrected overlay')
        self.lock['patchSha256'] = digest(self.patch)
        self.write(self.root / 'source.lock.json', self.lock)
        review = self.review(failed)
        self.assertEqual(review['status'], 'eligible')
        self.assertIn(['patchSha256', failure['inputs']['candidate.patch'], digest(self.patch)],
                      review['inference']['relations']['predecessor_delta'])
        result = self.run_candidate(self.baseline.with_name('corrected-patch'), failed)
        self.assertEqual(result['repair']['status'], 'verified')
        self.assertEqual(result['repair']['lineage'], [str(self.baseline), str(failed)])
        self.assertEqual(json.loads((failed / 'receipt.json').read_text()), failure)

        log = failed / 'run/source/patch-inventory.log'
        log.write_text('substituted failure evidence')
        review = self.review(failed)
        diagnostic = review['predecessorPreparationFailures'][0]['diagnostics'][0]
        self.assertEqual(diagnostic['status'], 'UNVERIFIED')
        self.assertNotIn('logExcerpt', diagnostic)

    def test_unbound_baseline_log_is_excluded_from_independently_bound_review(self):
        (self.baseline / 'run/module/emit.log').write_text('substituted')
        self.steps[2]['arguments']['module'] = 'lib/_reduced.scm'
        self.plan['intent'] = 'probe'
        result = self.review()
        self.assertEqual(result['status'], 'eligible')
        self.assertIn(['module', 'regenerate-module', 'no-bound-command-log'],
                      result['inference']['relations']['evidence_gap'])
        self.assertEqual(result['inference']['facts']['diagnostic_location'], [])

    def test_quiescent_predecessor_without_child_can_carry_custody(self):
        self.lock['files']['lib/_sample.scm']['candidateSha256'] = 'c' * 64
        self.write(self.root / 'source.lock.json', self.lock)
        stopped = self.baseline.with_name('no-child')
        failure = self.run_candidate(stopped, self.baseline, no_child=True)
        self.assertIsNone(failure['childReceiptSha256'])
        self.plan['failureRun'] = self.baseline.relative_to(self.root).as_posix()
        self.assertIn(['unchanged-predecessor'], self.review(stopped)['inference']['relations']['blocked'])
        self.patch.write_text('changed overlay')
        self.lock['patchSha256'] = digest(self.patch)
        self.write(self.root / 'source.lock.json', self.lock)
        self.assertEqual(self.review(stopped)['status'], 'eligible')
        result = self.run_candidate(self.baseline.with_name('follow-up'), stopped)
        self.assertEqual(result['repair']['status'], 'verified')
