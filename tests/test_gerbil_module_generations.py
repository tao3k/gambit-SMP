"""Generation issuer/refusal controls; these are not native compiler admission."""

import json
import hashlib
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from gambit_smp.gerbil_build.custody import AdmissionFiles, _git_blob
from gambit_smp.gerbil_build.module_generations import prepare_generations, retain_generations
from gambit_smp.gerbil_build.compiler_products import settle_compile_products, _prepare_compile_products, _settled_borrows
from gambit_smp.gerbil_build.custody import _product_observation_directory
from gambit_smp.framework import digest


class ModuleGenerationTests(unittest.TestCase):
    def settlement_fixture(self):
        prior = self.root/'.cache/prior'
        prior.mkdir(parents=True)
        for name in ('stdout', 'stderr'):
            (prior/name).write_text('')
        command = dict(stage='gerbil-stdlib', argv=['make','stdlib'], cwd=str(self.source),
                       environment={}, exit=-9, timeout=True, parentReaped=True,
                       processGroupQuiescent=True, stdoutPath='stdout', stderrPath='stderr',
                       stdoutSha256=digest(prior/'stdout'), stderrSha256=digest(prior/'stderr'))
        (prior/'result.json').write_text(json.dumps(dict(complete=False, commands=[command])))
        (prior/'compile-product-context.json').write_text(json.dumps(dict(context='context')))
        (prior/'gerbil-stdlib.process.json').write_text(json.dumps(dict(command, state='OBSERVED')))
        self.ctx.leased_workspaces = {self.source}
        self.ctx.tools = {'make': 'make'}
        self.ctx.env = {}
        self.ctx.bind = lambda paths: None
        return prior

    def test_settlement_preserves_failed_parent_and_checks_original_observation(self):
        prior = self.settlement_fixture()
        original = (prior/'result.json').read_bytes()
        with patch('gambit_smp.gerbil_build.compiler_products._compile_product_context',
                   return_value=('context', {})), \
             patch('gambit_smp.gerbil_build.compiler_products._retain_compile_products',
                   return_value=dict(stageComplete=False, products=[])) as retain:
            result = settle_compile_products(self.ctx, self.store, self.source, self.source, prior)
        self.assertFalse(result['stageComplete'])
        self.assertEqual(original, (prior/'result.json').read_bytes())
        self.assertTrue(retain.call_args.args[-1]['timeout'])
        self.assertFalse(json.loads((self.root/'settled-compile-products.json').read_text())['originalStagePassed'])

    def test_settlement_refuses_mutated_stream_before_context_or_retention(self):
        prior = self.settlement_fixture()
        (prior/'stdout').write_text('changed')
        with patch('gambit_smp.gerbil_build.compiler_products._compile_product_context') as context:
            with self.assertRaisesRegex(ValueError, 'stream identity'):
                settle_compile_products(self.ctx, self.store, self.source, self.source, prior)
            context.assert_not_called()

    def test_settlement_never_grants_whole_stage_completion(self):
        prior = self.settlement_fixture()
        with patch('gambit_smp.gerbil_build.compiler_products._compile_product_context',
                   return_value=('context', {})), \
             patch('gambit_smp.gerbil_build.compiler_products._retain_compile_products',
                   return_value=dict(stageComplete=True, products=[])):
            result = settle_compile_products(self.ctx, self.store, self.source, self.source, prior)
        self.assertFalse(result['stageComplete'])
        self.assertTrue(result['settlementOnly'])
        receipt = json.loads((self.root/'settled-compile-products.json').read_text())
        self.assertTrue(receipt['originalStagePassed'])
        self.assertFalse(receipt['runtimeAdmitted'])

    def test_settlement_refuses_borrowed_module_from_another_context(self):
        prior = self.settlement_fixture()
        outbox = prior/'compile-products'
        outbox.mkdir()
        (outbox/'unit.module-used.json').write_text(json.dumps(['context', 'source', 'interface']))
        (prior/'admitted-module-programs.json').write_text(json.dumps([
            dict(context='other', source='source', interface='interface')]))
        with patch('gambit_smp.gerbil_build.compiler_products._module_witnesses', return_value={}):
            with self.assertRaisesRegex(ValueError, 'original admission snapshot'):
                _settled_borrows(self.ctx, prior, 'context', self.store)

    def test_settlement_refuses_borrowed_generation_from_another_context(self):
        prior = self.settlement_fixture()
        outbox = prior/'compile-products'
        outbox.mkdir()
        (outbox/'unit.generation-used.json').write_text('[]')
        generations = self.store/'generations'
        generations.mkdir(parents=True, exist_ok=True)
        (generations/'unit.json').write_text(json.dumps(dict(data=['other'])))
        with patch('gambit_smp.gerbil_build.compiler_products._module_witnesses', return_value={}):
            with self.assertRaisesRegex(ValueError, 'another context'):
                _settled_borrows(self.ctx, prior, 'context', self.store)

    def test_settlement_refuses_context_change_without_new_generation(self):
        prior = self.settlement_fixture()
        with patch('gambit_smp.gerbil_build.compiler_products._compile_product_context',
                   return_value=('different', {})), \
             patch('gambit_smp.gerbil_build.compiler_products._retain_compile_products') as retain:
            with self.assertRaisesRegex(ValueError, 'cannot migrate'):
                settle_compile_products(self.ctx, self.store, self.source, self.source, prior)
            retain.assert_not_called()

    def test_new_settlement_keeps_original_observation_immutable(self):
        old = self.outbox/'unit.observed.json'
        old.write_text('original receipt')
        self.ctx.directory = self.root/'new-attempt'
        self.ctx.directory.mkdir()
        target = _product_observation_directory(self.ctx, self.outbox)/old.name
        target.write_text('new issuer')
        self.assertEqual('original receipt', old.read_text())
        self.assertNotEqual(target, old)

    def context_handoff_fixture(self):
        self.settlement_fixture()
        driver = self.source/'src/gerbil/compiler/driver.ss'
        driver.parent.mkdir(parents=True)
        driver.write_text('(compile-product-invoke input)')
        self.ctx.tools['git'] = 'git'
        self.ctx.env['GERBIL_GIT'] = 'git'
        self.ctx.compiler_settled_context = (self.source, self.source, dict(self.ctx.env),
            dict(self.ctx.tools), 'context', {'inputs': {str(self.src): digest(self.src)}})

    def test_preparation_consumes_verified_context_without_duplicate_tool_queries(self):
        self.context_handoff_fixture()
        with patch('gambit_smp.gerbil_build.compiler_products._compile_product_context') as query:
            # A deliberately incompatible requested cohort stops after the
            # handoff check, before any product withdrawal or native execution.
            with self.assertRaisesRegex(ValueError, 'requested compiler cohort'):
                _prepare_compile_products(self.ctx, self.store, self.source, self.source,
                                          expected_context='other')
            query.assert_not_called()
        self.assertFalse(hasattr(self.ctx, 'compiler_settled_context'))

    def test_context_handoff_rejects_input_drift_without_requery_or_withdrawal(self):
        self.context_handoff_fixture()
        self.src.write_text('changed since settlement')
        with patch('gambit_smp.gerbil_build.compiler_products._compile_product_context') as query:
            with self.assertRaisesRegex(ValueError, 'settled producer context changed'):
                _prepare_compile_products(self.ctx, self.store, self.source, self.source)
            query.assert_not_called()
        self.assertFalse(hasattr(self.ctx, 'compiler_settled_context'))

    def late_settlement_fixture(self):
        prior = self.settlement_fixture()
        result = json.loads((prior/'result.json').read_text())
        command = result['commands'][0]
        command.update(pid=1234, processGroupQuiescent=None, streamCaptureComplete=False,
            environment={'GAMBIT_SMP_TASK_ID': 'task', 'GAMBIT_SMP_TASK_RUN': 'run'})
        (prior/'result.json').write_text(json.dumps(result))
        (prior/'gerbil-stdlib.process.json').write_text(json.dumps(dict(command, state='OBSERVED')))
        record = self.root/'.state/task-processes/task/run/token.json'
        record.parent.mkdir(parents=True)
        data = dict(pid=1234, cwd=str(self.source), birth={'bootId': 'boot'},
                    argvSha256=hashlib.sha256(json.dumps(command['argv']).encode()).hexdigest(),
                    groupObservation={'result': 'present'}, sessionObservation={'result': 'present'})
        record.write_text(json.dumps(data))
        return prior, record

    def test_later_kernel_stop_does_not_rewrite_incomplete_original_observation(self):
        prior, record = self.late_settlement_fixture()
        original = (prior/'gerbil-stdlib.process.json').read_bytes()
        def stopped(*args, **kwargs):
            data = json.loads(record.read_text())
            data.update(groupObservation={'result': 'absent'}, sessionObservation={'result': 'absent'})
            record.write_text(json.dumps(data))
        with patch('gambit_smp.process_identity.boot_id', return_value='boot'), \
             patch('gambit_smp.task_processes.check', side_effect=stopped), \
             patch('gambit_smp.gerbil_build.compiler_products._compile_product_context',
                   return_value=('context', {})), \
             patch('gambit_smp.gerbil_build.compiler_products._retain_compile_products',
                   return_value=dict(stageComplete=False)) as retain:
            settle_compile_products(self.ctx, self.store, self.source, self.source, prior)
        self.assertEqual(original, (prior/'gerbil-stdlib.process.json').read_bytes())
        self.assertTrue(retain.call_args.args[-1]['processGroupQuiescent'])
        data = json.loads((self.root/'settled-compile-products.json').read_text())
        self.assertFalse(data['originalStagePassed'])
        self.assertFalse(data['lateCustody']['originalStreamComplete'])

    def test_unknown_or_cross_boot_late_stop_cannot_retain_products(self):
        prior, record = self.late_settlement_fixture()
        with patch('gambit_smp.process_identity.boot_id', return_value='different'), \
             patch('gambit_smp.task_processes.check') as check:
            with self.assertRaisesRegex(ValueError, 'producer identity'):
                settle_compile_products(self.ctx, self.store, self.source, self.source, prior)
            check.assert_not_called()
        with patch('gambit_smp.process_identity.boot_id', return_value='boot'), \
             patch('gambit_smp.task_processes.check'), \
             patch('gambit_smp.gerbil_build.compiler_products._retain_compile_products') as retain:
            with self.assertRaisesRegex(ValueError, 'stop remains unresolved'):
                settle_compile_products(self.ctx, self.store, self.source, self.source, prior)
            retain.assert_not_called()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root/'source'
        self.src = self.source/'src/std/unit.ss'
        self.scm = self.source/'build/lib/std/unit.scm'
        self.ssi = self.scm.with_suffix('.ssi')
        self.outbox = self.root/'attempt'
        self.private = self.outbox/'interface-unit.ssi'
        self.store = self.root/'store'
        (self.store/'modules').mkdir(parents=True)
        for path in (self.src, self.scm, self.private):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(path.name)
        self.header = self.root/'header.json'
        self.header.write_text(json.dumps(dict(runId='run', inputs={})))
        self.ctx = SimpleNamespace(root=self.root, directory=self.root,
                                  receipt={'journal': {'path': str(self.header), 'scope': 'scope'}})
        self.prepared = ('context', {'reuseAllowed': True}, self.store, self.outbox)
        self.producer = dict(parentReaped=True, processGroupQuiescent=True)
        self.value = ['context', str(self.src), _git_blob(self.src), 'std/unit', [],
                      [[str(self.source/'build/bin/gsc'), [str(self.scm)], str(self.scm)]],
                      [[str(self.scm), str(self.scm), _git_blob(self.scm)],
                       [str(self.ssi), str(self.private), _git_blob(self.private)]], [], True,
                      str(self.source/'src/std')]
        self.addCleanup(patch.stopall)
        patch('gambit_smp.research_kernel.retain_run_record', return_value={
            'path': 'proof', 'sha256': 'sha', 'observation': 'observation', 'scope': 'scope'}).start()

    def retain(self):
        (self.outbox/'unit.module-request.json').write_text(json.dumps(self.value[:3]))
        (self.outbox/'unit.module-generated.json').write_text(json.dumps(self.value))
        return retain_generations(self.ctx, self.source, self.prepared, self.producer)

    def prepare(self, modules=None):
        record = json.loads((self.store/'generations/unit.json').read_text())
        core = {k: v for k, v in record.items() if k not in ('completion', 'completionRun')}
        with patch('gambit_smp.gerbil_build.module_generations._module_witnesses',
                   return_value={('proof', 'sha', 'observation', 'scope'): core}):
            return prepare_generations(self.ctx, self.source, 'context', self.store,
                                       modules or {}, AdmissionFiles(), {}, reuse_allowed=True)

    def test_files_alone_are_not_closed_generation(self):
        report = retain_generations(self.ctx, self.source, self.prepared, self.producer)
        self.assertEqual(report['closed'], [])
        self.assertFalse(self.ssi.exists())

    def test_native_pending_can_resume_without_publishing_interface(self):
        self.assertEqual(self.retain()['closed'], ['std/unit'])
        self.assertEqual(self.prepare()['admitted'], 1)
        self.assertTrue((self.store/'modules/src/std/unit.ss.ready.generation').is_file())
        self.assertFalse((self.store/'modules/src/std/unit.ss.ready').exists())
        self.assertFalse(self.ssi.exists())

    def test_unknown_writer_stop_cannot_issue(self):
        self.producer['processGroupQuiescent'] = None
        with self.assertRaisesRegex(ValueError, 'quiescence'):
            self.retain()

    def test_renamed_interface_recovers_only_private_generation_after_writer_stop(self):
        self.private.rename(self.ssi)
        expected = self.ssi.read_bytes()
        self.assertEqual(self.retain()['closed'], ['std/unit'])
        record = json.loads((self.store/'generations/unit.json').read_text())
        self.assertTrue(record['files'][1]['recoveredPublishedBytes'])
        self.assertFalse(record['moduleComplete'])
        self.ssi.unlink()
        self.assertEqual(self.prepare()['admitted'], 1)
        self.assertFalse(self.ssi.exists())
        self.assertEqual(expected, Path(record['files'][1]['frozen']).read_bytes())
        self.assertFalse((self.store/'modules/src/std/unit.ss.ready').exists())

    def test_renamed_interface_recovery_rejects_unknown_writer_and_changed_bytes(self):
        self.private.rename(self.ssi)
        self.producer['processGroupQuiescent'] = None
        with self.assertRaisesRegex(ValueError, 'quiescence'):
            self.retain()
        self.producer['processGroupQuiescent'] = True
        self.ssi.write_text('different interface')
        with self.assertRaisesRegex(ValueError, 'writer custody'):
            self.retain()

    def test_renamed_interface_recovery_does_not_follow_alias_or_mask_corruption(self):
        self.private.rename(self.ssi)
        saved = self.root/'saved.ssi'
        self.ssi.rename(saved)
        self.ssi.symlink_to(saved)
        with self.assertRaisesRegex(ValueError, 'writer custody'):
            self.retain()
        self.ssi.unlink()
        saved.rename(self.ssi)
        self.private.write_text('corrupted private output')
        with self.assertRaisesRegex(ValueError, 'writer custody'):
            self.retain()

    def test_changed_source_revokes_existing_continuation(self):
        self.retain()
        self.prepare()
        self.src.write_text('changed source')
        self.assertEqual(self.prepare()['admitted'], 0)
        self.assertFalse((self.store/'modules/src/std/unit.ss.ready.generation').exists())

    def test_mutated_bundle_is_not_replayed(self):
        self.retain()
        record = json.loads((self.store/'generations/unit.json').read_text())
        Path(record['files'][0]['frozen']).write_text('changed')
        self.assertEqual(self.prepare()['admitted'], 0)

    def test_missing_owned_code_restores_exact_bytes_without_ssi(self):
        original = self.scm.read_bytes()
        self.retain()
        self.scm.unlink()
        self.assertEqual(self.prepare()['admitted'], 1)
        self.assertEqual(self.scm.read_bytes(), original)
        self.assertFalse(self.ssi.exists())

    def test_dependency_requires_complete_program_not_just_file(self):
        dep = self.scm.with_name('provider.ssi')
        dep.write_text('dependency')
        self.value[4] = ['std/provider']
        self.value[7] = [[str(dep), _git_blob(dep)]]
        self.retain()
        self.assertEqual(self.prepare()['admitted'], 0)
        self.assertEqual(self.prepare({'provider': {'moduleId': 'std/provider'}})['admitted'], 1)
        dep.write_text('different dependency incarnation')
        self.assertEqual(self.prepare({'provider': {'moduleId': 'std/provider'}})['admitted'], 0)

    def test_duplicate_native_writer_is_refused(self):
        self.value[5].append(self.value[5][0])
        with self.assertRaisesRegex(ValueError, 'managed C role'):
            self.retain()

    def test_eval_cannot_enter_generation_continuation(self):
        self.value[5][0][1][:0] = ['-e', '(arbitrary-eval)']
        with self.assertRaisesRegex(ValueError, 'managed C role'):
            self.retain()

    def test_wrong_cwd_is_refused(self):
        self.value[9] = str(self.root)
        with self.assertRaisesRegex(ValueError, 'source/cwd'):
            self.retain()

    def test_private_interface_must_belong_to_this_attempt(self):
        other = self.root/'other.ssi'
        other.write_text('other')
        self.value[6][1][1:] = [str(other), _git_blob(other)]
        with self.assertRaisesRegex(ValueError, 'writer custody'):
            self.retain()

    def test_replay_use_requires_preissued_marker(self):
        (self.outbox/'unit.generation-used.json').write_text(json.dumps(['context', str(self.src), 'oid', 'fake']))
        with self.assertRaisesRegex(ValueError, 'admitted continuation'):
            retain_generations(self.ctx, self.source, self.prepared, self.producer)

    def test_graph_output_is_frozen_but_does_not_grant_native_completion(self):
        graph=self.scm.with_suffix('.init');graph.write_text('owned semantic graph')
        self.value[6].append([str(graph),str(graph),_git_blob(graph)])
        self.assertEqual(self.retain()['closed'],['std/unit'])
        graph.unlink()
        self.assertEqual(self.prepare()['admitted'],1)
        self.assertEqual(graph.read_text(),'owned semantic graph')
        self.assertFalse((self.store/'modules/src/std/unit.ss.ready').exists())
        self.assertFalse(self.ssi.exists())

    def test_graph_writer_cannot_claim_a_different_module(self):
        graph=self.scm.with_name('other.init');graph.write_text('other graph')
        self.value[6].append([str(graph),str(graph),_git_blob(graph)])
        with self.assertRaisesRegex(ValueError,'writer custody'):
            self.retain()
