"""Graph and custody controls; synthetic files do not grant native admission."""
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import hashlib
import json
import unittest
from unittest.mock import Mock, patch

from gambit_smp.framework import digest
from gambit_smp.gerbil_build import stdlib_batch_prefixes
from gambit_smp.gerbil_build.batches import _withdraw_stdlib_batch, _stdlib_outputs, _stdlib_stage, _stdlib_checkpoint_current


class CompilerBuildGraphTests(unittest.TestCase):
    def test_stdlib_outer_handoff_join_and_completion_controls(self):
        from gambit_smp.gerbil_build.batches import stdlib_products
        import time
        for mode in ('complete', 'unjoined', 'missing-output', 'changed-output', 'missing-completion'):
            with self.subTest(mode=mode), TemporaryDirectory() as temp:
                root = Path(temp).resolve()
                source = root/'source'
                (source/'src/std').mkdir(parents=True)
                (source/'src/build.sh').write_text('build_stdlib () {\n'
                    '  feedback_low "Building stdlib"\n  (cd std && gxi ./build.ss) || die\n}\n')
                (source/'src/std/build-std.ss').write_text('(def (build . args) (make separate-compiler: #f))')
                output = root/'evidence'
                output.mkdir()
                handoff = output/'stdlib-compilation-output.scm'
                commands, expressions = [], []
                environment = {'GERBIL_BUILD_CORES': '12'}
                def require(name, argv, cwd, budget):
                    expressions.append(argv[-1])
                    self.assertEqual(source/'src/std', cwd)
                    self.assertEqual([source/'run.sh', 'gxi', '-e'], argv[:-1])
                    self.assertEqual('12', environment['GERBIL_BUILD_CORES'])
                    if name.endswith('frontend') and mode != 'missing-output':
                        handoff.write_text('synthetic sealed output')
                    if name.endswith('native'):
                        self.assertTrue((output/'stdlib-frontend-retired.json').is_file())
                        if mode == 'changed-output':handoff.write_text('changed')
                        if mode != 'missing-completion':
                            marker = Path(str(handoff)+'.native/complete')
                            marker.parent.mkdir();marker.write_text('synthetic completion')
                    command = dict(stage=name, exit=0, timeout=False, parentReaped=True,
                        startedAt='2026-11-02T00:00:00+00:00', endedAt='2026-11-02T00:00:01+00:00',
                        processGroupQuiescent=mode != 'unjoined')
                    commands.append(command)
                    (output/(name+'.process.json')).write_text(json.dumps(dict(command,state='OBSERVED')))
                    ctx.last_stdout='STDLIB-CURRENT-OUTPUT-IMAGE-PASS\n' if name=='gerbil-stdlib' else ''
                ctx = SimpleNamespace(directory=output, env=environment,
                    leased_workspaces={source}, remaining=lambda:30,
                    commands=commands, require=require, bind=Mock(), last_stdout='')
                def negative_run(name,argv,cwd,budget):
                    ctx.commands.append(dict(stage=name,exit=70,parentReaped=True,processGroupQuiescent=True))
                    return 70,'.missing-native-output',False,0
                ctx.run=negative_run
                if mode == 'complete':
                    result = stdlib_products(ctx, source, time.monotonic()+30)
                    self.assertTrue(result['frontendRetiredBeforeNative'])
                    self.assertEqual(2, len(result['dependencies']))
                    self.assertIn('call-with-compilation-output', expressions[0])
                    self.assertIn('build.ss', expressions[0])
                    self.assertIn('execute-compilation-output', expressions[1])
                    self.assertTrue(expressions[1].endswith(' #f)'))
                    self.assertIn('read-compilation-output',expressions[2])
                    # Exercise the real rollup: mocking this collector hid the
                    # old missing gerbil-stdlib terminal receipt in native runs.
                    from gambit_smp.gerbil_build.custody import _stage_completion, _current
                    proof=_stage_completion(ctx,source,'stdlib','bound-inputs',['src'])
                    proof['predecessors']=result['dependencies']
                    self.assertTrue(_current(source,proof,'bound-inputs',stage='stdlib'))
                    proof['predecessors']=proof['predecessors'][1:]
                    self.assertFalse(_current(source,proof,'bound-inputs',stage='stdlib'))

                else:
                    with self.assertRaises(ValueError):
                        stdlib_products(ctx, source, time.monotonic()+30)
                    if mode in ('unjoined', 'missing-output'):
                        self.assertEqual(1, len(commands))
                self.assertEqual({'GERBIL_BUILD_CORES': '12'}, environment)

    def test_stdlib_recovery_never_reexecutes_unknown_native_work(self):
        from gambit_smp.gerbil_build.batches import stdlib_products
        import time
        for fault in (None,'missing-command','unknown-exit','changed-handoff','missing-marker'):
            with self.subTest(fault=fault),TemporaryDirectory() as temporary:
                root=Path(temporary).resolve();source=root/'source';(source/'src/std').mkdir(parents=True)
                (source/'src/build.sh').write_text('build_stdlib () {\n'
                    '  feedback_low "Building stdlib"\n  (cd std && gxi ./build.ss) || die\n}\n')
                (source/'src/std/build-std.ss').write_text('(def (build . args) (make separate-compiler: #f))')
                prior=root/'prior';old=prior/'run/compiler';old.mkdir(parents=True)
                handoff=old/'stdlib-compilation-output.scm';handoff.write_text('retained output')
                marker=Path(str(handoff)+'.native/complete');marker.parent.mkdir();marker.write_text('complete')
                commands=[]
                for name in ('gerbil-stdlib-frontend','gerbil-stdlib-native'):
                    c=dict(stage=name,exit=0,timeout=False,parentReaped=True,processGroupQuiescent=True,
                           startedAt='2026-11-02T00:00:00+00:00',endedAt='2026-11-02T00:00:01+00:00')
                    commands.append(c);(old/(name+'.process.json')).write_text(json.dumps(dict(c,state='OBSERVED')))
                (old/'stdlib-frontend-retired.json').write_text(json.dumps(dict(sha256=digest(handoff),command=commands[0])))
                (prior/'run-header.json').write_text('{}')
                if fault=='missing-command':commands.pop()
                if fault=='unknown-exit':
                    p=old/'gerbil-stdlib-native.process.json';v=json.loads(p.read_text());v['exit']=None;p.write_text(json.dumps(v))
                if fault=='changed-handoff':handoff.write_text('changed')
                if fault=='missing-marker':marker.unlink()
                output=root/'new';output.mkdir();calls=[]
                ctx=SimpleNamespace(root=root,directory=output,env={},leased_workspaces={source},
                    remaining=lambda:30,commands=[],bind=Mock(),last_stdout='')
                def require(stage,argv,cwd,budget):
                    calls.append(stage);self.assertEqual('gerbil-stdlib',stage)
                    self.assertIn('read-compilation-output',argv[-1]);self.assertNotIn('execute-compilation-output',argv[-1])
                    ctx.commands.append(dict(stage=stage,parentReaped=True,processGroupQuiescent=True))
                    ctx.last_stdout='STDLIB-CURRENT-OUTPUT-IMAGE-PASS\n'
                ctx.require=require
                def negative_run(name,argv,cwd,budget):
                    ctx.commands.append(dict(stage=name,exit=70,parentReaped=True,processGroupQuiescent=True))
                    return 70,'.missing-native-output',False,0
                ctx.run=negative_run
                records=[dict(payload=dict(schema='research-step-observation.v1',step=dict(id='compiler',outcome='DENY',commands=commands)))]
                with patch('gambit_smp.artifact_storage.observation_root'),patch(
                    'gambit_smp.reasoning_history.read_execution_checkpoint',return_value={'records':records}):
                    if fault:
                        with self.assertRaises(ValueError):stdlib_products(ctx,source,time.monotonic()+30,prior=prior)
                        self.assertEqual([],calls)
                    else:
                        result=stdlib_products(ctx,source,time.monotonic()+30,prior=prior)
                        self.assertEqual(['gerbil-stdlib'],calls)
                        self.assertEqual(2,len(result['dependencies']))
                        self.assertFalse(result['historicalByteCustodyProved'])

    def test_stdlib_source_drift_refuses_before_launch(self):
        from gambit_smp.gerbil_build.batches import stdlib_products
        with TemporaryDirectory() as temp:
            root = Path(temp)
            (root/'src').mkdir()
            (root/'src/build.sh').write_text('changed producer')
            with self.assertRaisesRegex(ValueError, 'contract drift'):
                stdlib_products(SimpleNamespace(), root, 0)

    def test_stage1_contract_drift_is_refused_before_product_withdrawal(self):
        from gambit_smp.gerbil_build.batches import stage1_products
        with TemporaryDirectory() as temp:
            root=Path(temp);(root/'src').mkdir();(root/'src/build.sh').write_text('changed producer')
            with patch('gambit_smp.gerbil_build.batches._withdraw_stage1_outputs') as withdraw:
                with self.assertRaisesRegex(ValueError,'contract drift'):
                    stage1_products(SimpleNamespace(directory=root),root,0)
                withdraw.assert_not_called()

    def test_stage1_unknown_frontend_cannot_start_native_consumption(self):
        from gambit_smp.gerbil_build.batches import stage1_products
        import time
        with TemporaryDirectory() as temp:
            root=Path(temp);src=root/'src';(src/'gerbil').mkdir(parents=True)
            # This is a synthetic orchestration contract, not native evidence.
            (src/'build.sh').write_text('\n'.join(['build_stage1 () {',
                '"${GERBIL_STAGE0}/bin/boot-gxi" ./build/build1.ss',
                '"${GERBIL_STAGE0}/bin/boot-gxi" ./build/build-bach.ss',
                '}', 'finalize_stage1 () {',
                'cp -v gerbil/interactive/*.ss',
                '(cd "${target_bin}" && ln -sf gerbil gxi)',
                '(cd "${target_bin}" && ln -sf gerbil gxc)', '}',
                'debug_stage1 () {',
                'gdb "${GERBIL_STAGE0}/bin/boot-gxi" ./build/build1.ss', '}', '']))
            for name in ('builtin.ssxi.ss','builtin-inline-rules.ssxi.ss'):(src/'gerbil'/name).write_text('fixture')
            env={'GERBIL_BUILD_CORES':'12'};commands=[];domains=[]
            def require(name,argv,cwd,budget):
                domains.append(env.get('GERBIL_LOADPATH'))
                if name=='gerbil-stage1-driver-frontend':
                    path=ctx.directory/'stage1-source-driver/gerbil/compiler/driver~0.scm'
                    path.parent.mkdir(parents=True);path.write_text('synthetic driver output')
                if name=='gerbil-stage1-driver-native':
                    Path(argv[argv.index('-o')+1]).write_text('synthetic native output')
                commands.append(dict(stage=name,parentReaped=True,
                    processGroupQuiescent=name!='gerbil-stage1-frontend'))
            ctx=SimpleNamespace(directory=root/'evidence',env=env,commands=commands,
                tools={'gcc':'gcc'},require=require,remaining=lambda:20)
            ctx.directory.mkdir()
            with self.assertRaisesRegex(ValueError,'has not retired'):
                stage1_products(ctx,root,time.monotonic()+20)
            self.assertEqual(['gerbil-stage1-version','gerbil-stage1-driver-frontend',
                'gerbil-stage1-driver-native','gerbil-stage1-frontend'],[x['stage'] for x in commands])
            self.assertEqual([str(root/'bootstrap/lib')]*len(commands),domains)
            self.assertEqual({'GERBIL_BUILD_CORES':'12'},env)

    def test_stopped_withdrawal_restores_inodes_without_granting_reuse(self):
        from gambit_smp.gerbil_build.batches import restore_withdrawn_stdlib
        with TemporaryDirectory() as temp:
            root=Path(temp).resolve();source=root/'source';source.mkdir()
            prior=root/'attempts/prior';current=root/'attempts/current'
            prior.mkdir(parents=True);current.mkdir()
            name='build/lib/std/example.ssi'
            retained=prior/'unpublished-stdlib-batch'/name
            retained.parent.mkdir(parents=True);retained.write_text('retained interface')
            inode=retained.stat().st_ino
            (prior/'stdlib-batch-withdrawal.json').write_text(json.dumps(dict(moved=[name])))
            producer=dict(stage='gerbil-stdlib',parentReaped=True,processGroupQuiescent=True)
            (prior/'result.json').write_text(json.dumps(dict(complete=False,commands=[producer])))
            ctx=SimpleNamespace(directory=current,leased_workspaces={source})
            self.assertEqual(1,restore_withdrawn_stdlib(ctx,source,prior))
            self.assertEqual(inode,(source/name).stat().st_ino)
            proof=json.loads((current/'stdlib-withdrawal-restoration.json').read_text())
            self.assertFalse(proof['reuseAdmitted'])
            self.assertEqual(0,proof['sourceCopies'])

    def test_unknown_producer_cannot_restore_withdrawn_outputs(self):
        from gambit_smp.gerbil_build.batches import restore_withdrawn_stdlib
        with TemporaryDirectory() as temp:
            root=Path(temp).resolve();source=root/'source';source.mkdir()
            prior=root/'attempts/prior';current=root/'attempts/current'
            prior.mkdir(parents=True);current.mkdir()
            (prior/'result.json').write_text(json.dumps(dict(complete=False,commands=[
                dict(stage='gerbil-stdlib',parentReaped=True,processGroupQuiescent=False)])))
            ctx=SimpleNamespace(directory=current,leased_workspaces={source})
            with self.assertRaisesRegex(ValueError,'quiescent'):
                restore_withdrawn_stdlib(ctx,source,prior)

    def test_explicit_workers_survive_host_default_policy(self):
        from gambit_smp.gerbil_build.policy import _compiler_jobs
        with patch('gambit_smp.gerbil_build.policy.available_processors', return_value=12):
            self.assertEqual(12, _compiler_jobs({'GERBIL_BUILD_CORES': '12'}))
            self.assertEqual(5, _compiler_jobs({}))
        for value in ('0', '-1', 'auto', '', '1.5', '１２', 12):
            with self.subTest(value=value), self.assertRaises(ValueError):
                _compiler_jobs({'GERBIL_BUILD_CORES': value})

    def test_stage_budget_rejection_precedes_native_admission(self):
        from gambit_smp.gerbil_build import build_owned_compiler
        for value in (None, 0, 601, True, 1.5):
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, 'at most 600'):
                build_owned_compiler(None, '.', '.', '.', '.', revision='0'*40,
                                     core={}, delta=[], archive_skipped=False,
                                     stage_budget_seconds=value)

    def test_complete_plan_is_preserved_and_every_prefix_is_closed(self):
        graph = [[3], [], [0, 1], [1], [2]]
        prefixes = stdlib_batch_prefixes(graph, 2)
        self.assertEqual([1, 3], prefixes[0])
        self.assertEqual(list(range(len(graph))), prefixes[-1])
        for prefix in prefixes:
            self.assertTrue(all(set(graph[i]) <= set(prefix) for i in prefix))

    def test_cycle_is_rejected_even_with_an_independent_ready_node(self):
        with self.assertRaisesRegex(ValueError, 'cycle'):
            stdlib_batch_prefixes([[], [2], [1]], 1)

    def test_invalid_identity_and_resource_parameters_are_rejected(self):
        for graph in ([], [[True]], [[-1]], [[1]], [[0, 0]], ['not-an-edge-list']):
            with self.subTest(graph=graph), self.assertRaises(ValueError):
                stdlib_batch_prefixes(graph, 2)
        for size in (None, True, 0, 129, 1.5):
            with self.subTest(size=size), self.assertRaises(ValueError):
                stdlib_batch_prefixes([[]], size)

    def test_wide_frontier_is_bounded_without_dropping_nodes(self):
        prefixes = stdlib_batch_prefixes([[] for _ in range(9)], 4)
        self.assertEqual([4, 8, 9], list(map(len, prefixes)))

    def test_chain_is_packed_across_ready_frontiers(self):
        self.assertEqual([[0, 1, 2], [0, 1, 2, 3]],
                         stdlib_batch_prefixes([[], [0], [1], [2]], 3))

    def test_sealed_prefix_survives_a_different_batch_partition(self):
        self.assertEqual([[0, 1, 2, 3]],
                         stdlib_batch_prefixes([[], [0], [1], []], 2, [0, 3]))
        self.assertEqual([], stdlib_batch_prefixes([[]], 1, [0]))
        with self.assertRaisesRegex(ValueError, 'not dependency closed'):
            stdlib_batch_prefixes([[], [0]], 1, [1])


class CompilerBatchCustodyTests(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root/'source'
        self.output = self.source/'build/lib/std'
        self.output.mkdir(parents=True)
        self.ctx = SimpleNamespace(directory=self.root/'attempt')
        self.ctx.directory.mkdir()

    def test_failed_batch_keeps_sealed_prefix_and_withdraws_unknown_outputs(self):
        old, new = self.output/'old.o1', self.output/'new.ssi'
        old.write_bytes(b'synthetic sealed file')
        qualified = _stdlib_outputs(self.source)
        stamp = old.stat().st_mtime_ns
        new.write_bytes(b'unconfirmed frontend output')
        _withdraw_stdlib_batch(self.ctx, self.source, qualified)
        self.assertEqual(qualified, _stdlib_outputs(self.source))
        self.assertEqual(stamp, old.stat().st_mtime_ns)
        self.assertTrue((self.ctx.directory/'unpublished-stdlib-batch/build/lib/std/new.ssi').is_file())

    def test_changed_sealed_prefix_is_rejected_without_destroying_custody(self):
        old = self.output/'old.o1'
        old.write_bytes(b'synthetic sealed file')
        qualified = _stdlib_outputs(self.source)
        old.write_bytes(b'changed during unknown completion')
        with self.assertRaisesRegex(ValueError, 'sealed stdlib prefix changed'):
            _withdraw_stdlib_batch(self.ctx, self.source, qualified)
        self.assertTrue(old.is_file())
        self.assertNotEqual(qualified['build/lib/std/old.o1'], digest(old))

    def test_alias_cannot_become_a_compiler_artifact(self):
        outside = self.root/'outside'
        outside.write_bytes(b'synthetic external payload')
        (self.output/'borrowed.o1').symlink_to(outside)
        with self.assertRaisesRegex(ValueError, 'aliases'):
            _stdlib_outputs(self.source)

    def checkpoint(self, *, quiescent=True):
        path = self.output/'old.o1'
        path.write_bytes(b'synthetic receipt control, not a Scheme binary')
        stage = _stdlib_stage([0])
        command = dict(stage='gerbil-'+stage, exit=0, timeout=False,
                       parentReaped=True, processGroupQuiescent=quiescent)
        raw = json.dumps(dict(state='OBSERVED', **command))
        proof = dict(inputsSha256='input-key', outputs=_stdlib_outputs(self.source),
                     modes={}, links={}, command=command, receiptBytes=raw,
                     receiptSha256=hashlib.sha256(raw.encode()).hexdigest())
        return dict(inputsSha256='input-key', completed=[0], stage=stage, proof=proof)

    def test_smaller_receipt_cannot_settle_an_enlarged_completion_claim(self):
        checkpoint = self.checkpoint()
        self.assertTrue(_stdlib_checkpoint_current(self.source, checkpoint, 'input-key', self.root))
        checkpoint['completed'] = [0, 1]
        self.assertFalse(_stdlib_checkpoint_current(self.source, checkpoint, 'input-key', self.root))

    def test_zero_exit_without_quiescence_does_not_seal_a_batch(self):
        self.assertFalse(_stdlib_checkpoint_current(
            self.source, self.checkpoint(quiescent=False), 'input-key', self.root))
