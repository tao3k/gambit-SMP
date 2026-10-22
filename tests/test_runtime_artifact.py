"""Archive/provenance controls; synthetic identities are not native acceptance."""
from copy import deepcopy
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import tarfile
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp.recipes import tree_identity
from gambit_smp.runtime_artifact import SCHEMA, checked_manifest, unpack, validate_import, export_deadline
from gambit_smp.step_checkpoint import content_id


def fixture(root):
    runtime = root / "original"
    runtime.mkdir()
    (runtime / "program").write_text("contract fixture, not a Gambit executable\n")
    (runtime / "program").chmod(0o755)
    (runtime / "alias").symlink_to("program")
    for name in ("include/gambit.h", "lib/makefile", "lib/setup.c"):
        path = runtime / name
        path.parent.mkdir(exist_ok=True)
        path.write_text("synthetic configuration observation control\n")
    identity = '{"runtimeAdmitted":false}'
    rows = [
        {"id": "source", "capability": "gambit.materialize", "dependsOn": [], "outcome": "PASS",
         "arguments": {"sourceLock": "evidence/source.lock.json"},
         "outputs": {"source": {"type": "source-tree", "identity": {"original": {"sha256": "a" * 64}}}}},
        {"id": "configure", "capability": "gambit.configure", "dependsOn": ["source"], "outcome": "PASS",
         "effectiveConcurrency": {"smp": True, "multipleVMs": True, "multipleThreadedVMs": True},
         "arguments": {"source": {"step": "source", "output": "source"}}, "commands": [{
             "stage": "configure", "argv": ["./configure", "--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"],
             "log": "configure.log", "logSha256": hashlib.sha256(b"").hexdigest(),
             "stdoutPath": "configure.stdout", "stdoutSha256": hashlib.sha256(b"").hexdigest(),
             "stderrPath": "configure.stderr", "stderrSha256": hashlib.sha256(b"").hexdigest(),
             "exit": 0, "timeout": False, "parentReaped": True, "processGroupQuiescent": True}]},
        {"id": "seed", "capability": "gambit.seed-core", "dependsOn": ["configure"], "outcome": "PASS",
         "arguments": {"source": {"step": "configure", "output": "source"}},
         "claim": "pre-generated-C-seed-only", "outputs": {
             "runtime": {"type": "seed-runtime"}, "identity": {"type": "runtime-identity"}}},
        {"id": "core", "capability": "gambit.source-core", "dependsOn": ["seed"], "outcome": "PASS",
         "effectiveConcurrency": {"smp": True, "multipleVMs": True, "multipleThreadedVMs": True},
         "configurationFiles": {name: hashlib.sha256((runtime / name).read_bytes()).hexdigest()
                                for name in ("include/gambit.h", "lib/makefile")},
         "arguments": {"runtime": {"step": "seed", "output": "runtime"}},
         "claim": "source-regenerated-core-not-full-two-pass-bootstrap", "outputs": {
             "runtime": {"type": "source-runtime", "identity": tree_identity(runtime)},
             "identity": {"type": "runtime-identity", "sha256": hashlib.sha256(identity.encode()).hexdigest()}}}]
    engine = {"files": {"worker.py": "b" * 64}, "hostTools": {"gcc": {"sha256": "c" * 64}}}
    engine["engineId"] = content_id(engine)
    child = json.dumps({"schema": "evidence-recipe-run.v1", "recipe": "contract", "outcome": "PASS", "inputsStable": True, "steps": rows})
    outer = json.dumps({"schema": "sealed-research-run.v1", "executionLaunched": True, "recipe": "contract", "outcome": "PASS", "exit": 0, "timeout": False,
        "parentReaped": True, "processGroupQuiescent": True, "engineId": engine["engineId"],
        "budgetSeconds": 600, "wholeSeconds": 10, "inputs": {"evidence/source.lock.json": "d" * 64},
        "childReceiptSha256": hashlib.sha256(child.encode()).hexdigest()})
    proof = {"outerReceiptSha256": hashlib.sha256(outer.encode()).hexdigest(),
             "schema": "successful-step-checkpoint.v1", "campaignOutcome": "PASS",
             "runtimeAdmitted": False, "resumptionAuthorized": False,
             "childReceiptSha256": hashlib.sha256(child.encode()).hexdigest(), "step": "core",
             "engineId": engine["engineId"], "outputsContentId": content_id(rows[-1]["outputs"]),
             "ancestry": [{"id": row["id"], "observationContentId": content_id(row)} for row in rows]}
    return runtime, {"schema": SCHEMA, "checkpoint": proof, "outerReceipt": outer, "childReceipt": child,
        "engineManifest": engine, "compilerSha256": "c" * 64, "files": tree_identity(runtime),
        "sourceIdentity": rows[0]["outputs"]["source"]["identity"], "sourceLock": "evidence/source.lock.json",
        "sourceLockSha256": "d" * 64, "runtimeIdentity": json.loads(identity), "identityBytes": identity,
        "runtimeAdmitted": False, "resumptionAuthorized": False,
        "logs": {**{"run/configure/configure." + suffix: hashlib.sha256(b"").hexdigest()
                 for suffix in ("log", "stdout", "stderr")},
                 "receipt.json": hashlib.sha256(outer.encode()).hexdigest(),
                 "run/receipt.json": hashlib.sha256(child.encode()).hexdigest()}}


def pack(path, runtime, value, extra=None, *, logs=None):
    with tarfile.open(path, "w", dereference=False) as archive:
        raw = json.dumps(value).encode()
        info = tarfile.TarInfo("manifest.json")
        info.size = len(raw)
        archive.addfile(info, io.BytesIO(raw))
        archive.add(runtime, arcname="runtime")
        for name in value["logs"]:
            raw = {"receipt.json": value["outerReceipt"], "run/receipt.json": value["childReceipt"],
                   **(logs or {})}.get(name, "").encode()
            info = tarfile.TarInfo("evidence/" + name)
            info.size = len(raw)
            archive.addfile(info, io.BytesIO(raw))
        if extra is not None:
            archive.addfile(extra)


class RuntimeArtifactContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.runtime, self.value = fixture(self.root)

    def warm_manifest(self, *, observed_exit=0, observed_argv=None):
        value = deepcopy(self.value)
        child = json.loads(value['childReceipt'])
        configured = child['steps'][1]
        command = configured['commands'].pop()
        observed = dict(command, state='OBSERVED', exit=observed_exit)
        if observed_argv is not None:observed['argv'] = observed_argv
        raw = json.dumps(observed)
        configured['configurationFiles'] = child['steps'][-1]['configurationFiles']
        configured['configurationReuse'] = dict(schema='gambit-configure-reuse.v1',
            files=configured['configurationFiles'], commands=[command], receiptBytes=raw,
            receiptSha256=hashlib.sha256(raw.encode()).hexdigest())
        value['childReceipt'] = json.dumps(child)
        child_sha = hashlib.sha256(value['childReceipt'].encode()).hexdigest()
        outer = json.loads(value['outerReceipt']);outer['childReceiptSha256'] = child_sha
        value['outerReceipt'] = json.dumps(outer)
        outer_sha = hashlib.sha256(value['outerReceipt'].encode()).hexdigest()
        value['checkpoint'].update(childReceiptSha256=child_sha, outerReceiptSha256=outer_sha,
            ancestry=[dict(id=row['id'], observationContentId=content_id(row)) for row in child['steps']])
        value['logs'].update({'receipt.json':outer_sha, 'run/receipt.json':child_sha})
        return value

    def test_warm_configuration_requires_the_original_successful_process_not_a_success_summary(self):
        outer, child, rows = checked_manifest(self.warm_manifest())
        self.assertEqual('PASS', outer['outcome'])
        self.assertEqual(child['steps'], rows)
        with self.assertRaisesRegex(ValueError, 'actual process observation'):
            checked_manifest(self.warm_manifest(observed_exit=-9))
        with self.assertRaisesRegex(ValueError, 'differs from its process observation'):
            checked_manifest(self.warm_manifest(observed_argv=['./configure', '--different']))

    def test_same_generation_keeps_modes_links_receipts_and_false_admission(self):
        archive = self.root / "generation.tar"
        pack(archive, self.runtime, self.value)
        actual = unpack(archive, self.root / "restored")
        self.assertEqual(self.value, actual)
        self.assertEqual(tree_identity(self.runtime), tree_identity(self.root / "restored/runtime"))
        self.assertFalse(actual["runtimeAdmitted"])
        self.assertFalse(actual["resumptionAuthorized"])

    def test_retained_runtime_extracts_only_metadata_and_checks_every_original_byte(self):
        archive = self.root / 'generation.tar';pack(archive,self.runtime,self.value)
        (self.runtime/'generated.o').write_bytes(b'additional actual builder output')
        actual=unpack(archive,self.root/'warm',retained_runtime=self.runtime)
        self.assertEqual(self.value,actual);self.assertFalse((self.root/'warm/runtime').exists())
        (self.runtime/'program').write_bytes(b'changed original input')
        with self.assertRaisesRegex(ValueError,'runtime path, mode, link or content drift'):
            unpack(archive,self.root/'changed',retained_runtime=self.runtime)

    def test_different_consumer_requires_the_exact_explicit_original_seal(self):
        from gambit_smp.runtime_artifact import producer_generation
        value=self.value;current=dict(engineId='new-consumer',files={'different.py':'f'*64})
        with self.assertRaisesRegex(ValueError,'explicit sealed generation'):
            producer_generation(self.root,{},value,current)
        slot=dict(producerEngine=dict(path='.cache/original-seal',engineId=value['engineManifest']['engineId']))
        (self.root/'.cache/original-seal').mkdir(parents=True)
        with patch('gambit_smp.research_kernel.manifest_paths',return_value=value['engineManifest']):
            actual=producer_generation(self.root,slot,value,current)
            self.assertEqual('pinned-completed-generation',actual['kind'])
            self.assertFalse(actual['runtimeAdmitted']);self.assertFalse(actual['resumptionAuthorized'])
            slot['producerEngine']['engineId']='wrong'
            with self.assertRaisesRegex(ValueError,'original producer generation differs'):
                producer_generation(self.root,slot,value,current)

    def test_changed_receipts_engine_source_and_compiler_rejected(self):
        for field, replacement in (("outerReceipt", "{}"), ("childReceipt", "{}"),
                                   ("sourceLockSha256", "e" * 64), ("compilerSha256", "e" * 64),
                                   ("sourceIdentity", {}), ("files", {}), ("runtimeAdmitted", True)):
            value = {**self.value, field: replacement}
            with self.subTest(field=field), self.assertRaises((ValueError, KeyError)):
                checked_manifest(value)

    def test_seed_is_not_promoted_by_changing_archive_label(self):
        value = deepcopy(self.value)
        value["checkpoint"]["step"] = "seed"
        with self.assertRaises(ValueError):
            checked_manifest(value)

    def test_added_deleted_changed_and_mode_drift_fail_closed(self):
        for variant in ("added", "deleted", "changed", "mode"):
            with self.subTest(variant=variant), tempfile.TemporaryDirectory() as name:
                root = Path(name)
                runtime, value = fixture(root)
                if variant == "added":
                    (runtime / "extra").write_text("unexpected")
                elif variant == "deleted":
                    (runtime / "alias").unlink()
                elif variant == "changed":
                    (runtime / "program").write_text("changed")
                else:
                    (runtime / "program").chmod(0o644)
                pack(root / "bad.tar", runtime, value)
                with self.assertRaises(ValueError):
                    unpack(root / "bad.tar", root / "out")

    def test_traversal_duplicate_hardlink_and_special_members_rejected(self):
        for name, kind in (("../escape", tarfile.REGTYPE), ("manifest.json", tarfile.REGTYPE),
                           ("runtime/hard", tarfile.LNKTYPE), ("runtime/device", tarfile.CHRTYPE)):
            with self.subTest(name=name):
                path = self.root / (str(kind) + str(len(name)) + ".tar")
                item = tarfile.TarInfo(name)
                item.type = kind
                item.linkname = "runtime/program" if kind == tarfile.LNKTYPE else ""
                pack(path, self.runtime, self.value, item)
                with self.assertRaises(ValueError):
                    unpack(path, self.root / ("out-" + str(kind) + str(len(name))))

    def test_only_declared_typed_archive_is_a_recipe_operand(self):
        value = {"source": {"step": "source", "output": "source"}, "archive": "evidence/runtime-input.json"}
        validate_import(value, ["evidence/runtime-input.json"])
        with self.assertRaises(ValueError):
            validate_import(value, [])
        with self.assertRaises(ValueError):
            validate_import({**value, "argv": ["tar", "xf"]}, ["evidence/runtime-input.json"])

    def test_export_cannot_reset_elapsed_gaps_or_cross_boot_identity(self):
        from gambit_smp.framework import digest
        header = {"clockEpoch": "boot-a", "startedMonotonic": 10, "deadlineMonotonic": 610,
                  "engineId": "fixture", "inputs": {}, "budgetSeconds": 600}
        path = self.root / "run-header.json"
        path.write_text(json.dumps(header))
        outer = {"engineId": "fixture", "inputs": {}, "budgetSeconds": 600,
                 "journal": {"path": str(path), "sha256": digest(path)}}
        with patch("gambit_smp.research_kernel.clock_epoch", return_value="boot-a"), \
             patch("gambit_smp.runtime_artifact.time.monotonic", return_value=609):
            self.assertEqual((10, 610), export_deadline(self.root, outer))
        with patch("gambit_smp.research_kernel.clock_epoch", return_value="boot-a"), \
             patch("gambit_smp.runtime_artifact.time.monotonic", return_value=611):
            with self.assertRaises(TimeoutError):
                export_deadline(self.root, outer)
        for boot in (None, "boot-b"):
            with patch("gambit_smp.research_kernel.clock_epoch", return_value=boot), self.assertRaises(ValueError):
                export_deadline(self.root, outer)


class MaintainedRuntimeImportTests(unittest.TestCase):
    from tests.test_workspace import WorkspaceTests
    setUp = WorkspaceTests.setUp

    def test_review_dependency_is_not_confused_with_mutable_source_consumption(self):
        from types import SimpleNamespace
        from gambit_smp.runtime_artifact import import_steps
        imported = dict(id='runtime', capability='gambit.runtime-import',
                        arguments={'source': {'step':'candidate','output':'source'}})
        reviewed = dict(id='review', capability='evidence.evaluate', dependsOn=['candidate'], arguments={})
        ctx = SimpleNamespace(directory=Path('candidate'), receipt={'plannedSteps':[imported, reviewed]})
        self.assertEqual([imported], import_steps(ctx))
        reviewed.update(capability='source.project', arguments={'source': {'step':'candidate','output':'source'}})
        with self.assertRaisesRegex(ValueError, 'mutable source consumer'):
            import_steps(ctx)

    def test_launch_returns_actual_observation_path_and_bound_failure_without_cache_search(self):
        from gambit_smp.research_kernel import launch_summary
        out = self.root/'.cache/tasks/repair/runs/example/outputs/diagnostic'
        (out/'run').mkdir(parents=True)
        child = out/'run/receipt.json'
        child.write_text(json.dumps({'steps':[
            dict(id='candidate', capability='gambit.materialize', outcome='DENY', reason='pinned producer required'),
            dict(id='sample', capability='gambit.executable-test', outcome='BLOCKED')]}))
        receipt = dict(outcome='DENY', childReceiptSha256=hashlib.sha256(child.read_bytes()).hexdigest())
        result = launch_summary(receipt, out)
        self.assertEqual(str(out), result['out'])
        self.assertEqual(str(out/'receipt.json'), result['receipt'])
        self.assertEqual('pinned producer required', result['stepFailures'][0]['reason'])
        self.assertEqual(1, len(result['stepFailures']))
        child.write_text('{"steps": []}')
        with self.assertRaisesRegex(ValueError, 'child receipt identity changed'):
            launch_summary(receipt, out)

    def generation(self):
        from gambit_smp import workspace as w
        from gambit_smp.framework import digest
        original, value = fixture(self.root / '.cache/tasks/repair')
        compiler = Path(shutil.which('cc')).resolve()
        product = w.build_output(self.root, 'gambit-core', compiler=compiler)
        runtime = product / 'source'
        original.rename(runtime)
        for name in ('gsi/gsi', 'gsc/gsc', 'lib/libgambit.a'):
            path = runtime / name
            path.parent.mkdir(exist_ok=True)
            path.write_bytes(b'synthetic runtime identity fixture, not native acceptance')
        value['runtimeIdentity'] = dict(sourceFiles={'program': digest(runtime/'program')},
            binarySha256=digest(runtime/'gsi/gsi'), gscSha256=digest(runtime/'gsc/gsc'),
            librarySha256=digest(runtime/'lib/libgambit.a'))
        value['identityBytes'] = json.dumps(value['runtimeIdentity'])
        lock = self.root / value['sourceLock']; lock.parent.mkdir(exist_ok=True)
        lock.write_text('{}')
        value['sourceLockSha256'] = digest(lock)
        value['compilerSha256'] = digest(compiler)
        value['engineManifest']['hostTools']['gcc']['sha256'] = digest(compiler)
        engine = value['engineManifest']
        engine['engineId'] = content_id({key: item for key, item in engine.items() if key != 'engineId'})
        child = json.loads(value['childReceipt'])
        tools = json.dumps({str(compiler): digest(compiler)})
        location = json.dumps(dict(schema='managed-workspace-location.v1', workspace=str(runtime.relative_to(self.root))))
        logs = {'run/tools.json': tools, 'run/core/runtime-workspace.json': location}
        value['logs'].update({name: hashlib.sha256(raw.encode()).hexdigest() for name, raw in logs.items()})
        child['toolInputs'] = dict(path='tools.json', count=1, sha256=value['logs']['run/tools.json'])
        core = child['steps'][-1]
        value['files'] = tree_identity(runtime)
        core['outputs']['runtime'].update(identity=value['files'], workspace=str(runtime.relative_to(self.root)),
            path='core/runtime-workspace.json', locationSha256=value['logs']['run/core/runtime-workspace.json'])
        core['outputs']['identity']['sha256'] = hashlib.sha256(value['identityBytes'].encode()).hexdigest()
        value['childReceipt'] = json.dumps(child)
        outer = json.loads(value['outerReceipt'])
        outer.update(inputs={value['sourceLock']: digest(lock)}, engineId=engine['engineId'],
                     childReceiptSha256=hashlib.sha256(value['childReceipt'].encode()).hexdigest())
        value['outerReceipt'] = json.dumps(outer)
        value['checkpoint'].update(engineId=engine['engineId'], outputsContentId=content_id(core['outputs']),
            outerReceiptSha256=hashlib.sha256(value['outerReceipt'].encode()).hexdigest(),
            childReceiptSha256=outer['childReceiptSha256'],
            ancestry=[dict(id=row['id'], observationContentId=content_id(row)) for row in child['steps']])
        value['logs'].update({'receipt.json': value['checkpoint']['outerReceiptSha256'],
                              'run/receipt.json': outer['childReceiptSha256']})
        archive = self.root/'.cache/tasks/repair/ci/runtime.tar'; archive.parent.mkdir(parents=True)
        pack(archive, runtime, value, logs=logs)
        descriptor = self.root/'evidence/input.json'
        descriptor.write_text(json.dumps(dict(schema='runtime-artifact-input.v1', path=str(archive.relative_to(self.root)))))
        return runtime, value, compiler, archive

    def context(self, value, compiler):
        from gambit_smp.recipes import ExecutionContext, WorkspaceValidationScope
        out = self.root/'.cache/tasks/repair/runs'/os.environ['GAMBIT_SMP_TASK_RUN']/'probe'
        directory = out/'candidate'; directory.mkdir(parents=True)
        steps = [dict(id='candidate', capability='gambit.materialize', dependsOn=[], arguments={'sourceLock':value['sourceLock']}),
                 dict(id='runtime', capability='gambit.runtime-import', dependsOn=['candidate'],
                      arguments={'source':{'step':'candidate','output':'source'}, 'archive':'evidence/input.json'})]
        receipt = dict(workspacePolicy='in-place', engine={'path':str(self.root)}, recipe='import-control',
                       steps=[], plannedSteps=steps, inputs={str(self.root/value['sourceLock']): value['sourceLockSha256']})
        scope = WorkspaceValidationScope()
        ctx = ExecutionContext(self.root, out, directory, os.environ, time.monotonic()+30, {}, receipt,
                               {'gcc':str(compiler)}, workspace_scope=scope)
        self.addCleanup(ctx.workspace_leases.close)
        self.addCleanup(scope.close)
        return ctx, scope

    def test_materializer_and_import_resume_same_inode_without_unpacking_or_native_commands(self):
        from gambit_smp import workspace as w
        from gambit_smp.runtime_artifact import reuse_import_source, consume
        w.start(self.root, 'repair', adopt=True)
        with w.execution_scope(self.root, 'repair'):
            runtime, value, compiler, _ = self.generation()
        inode = (runtime/'gsi/gsi').stat().st_ino
        for provider in ('codex', 'grok'):
            with w.execution_scope(self.root, 'repair', provider=provider):
                ctx, scope = self.context(value, compiler)
                with patch('gambit_smp.research_kernel.manifest_paths', return_value=value['engineManifest']), \
                     patch('gambit_smp.runtime_artifact.unpack', side_effect=AssertionError('unnecessary unpack')):
                    source = reuse_import_source({'sourceLock':value['sourceLock']}, ctx)
                    row = dict(ctx.receipt['plannedSteps'][0], **source, outcome='PASS')
                    ctx.receipt['steps'].append(row)
                    ctx.directory = ctx.out/'runtime'; ctx.directory.mkdir()
                    result = consume(ctx.receipt['plannedSteps'][1]['arguments'], ctx)
                    self.assertEqual('same-producer-workspace', result['workspaceReuse']['mode'])
                    self.assertEqual(0, result['workspaceReuse']['copiedFiles'])
                    self.assertEqual(inode, (runtime/'gsi/gsi').stat().st_ino)
                    self.assertFalse((ctx.out/'candidate/source').exists())
                    self.assertFalse((ctx.directory/'generation').exists())
                    self.assertEqual([], ctx.commands)
                    self.assertFalse(result['runtimeAdmitted'])
                    from gambit_smp.evidence_capabilities import facts
                    observed = dict(ctx.receipt['plannedSteps'][1], **result, outcome='PASS')
                    projected = facts({'steps':[observed]})['runtime_storage_observation']
                    self.assertEqual([['runtime', 'same-producer-workspace', content_id(value['files']), 0]], projected)
                ctx.workspace_leases.close(); scope.close()

    def test_existing_producer_drift_is_not_hidden_by_an_import_or_bootstrap(self):
        from gambit_smp import workspace as w
        from gambit_smp.runtime_artifact import prepare_import
        w.start(self.root, 'repair', adopt=True)
        with w.execution_scope(self.root, 'repair'):
            runtime, value, compiler, _ = self.generation()
            (runtime/'program').write_text('unexpected producer mutation')
            ctx, scope = self.context(value, compiler)
            with patch('gambit_smp.research_kernel.manifest_paths', return_value=value['engineManifest']):
                with self.assertRaisesRegex(ValueError, 'no duplicate fallback'):
                    prepare_import('evidence/input.json', ctx)
            self.assertFalse((ctx.directory/'import-staging').exists())
            self.assertEqual([], ctx.commands)
            ctx.workspace_leases.close(); scope.close()

    def phase_fixture(self):
        from gambit_smp.framework import digest
        runtime, value, compiler, _ = self.generation()
        rows = json.loads(value['childReceipt'])['steps']
        run = self.root/'.cache/tasks/repair/runs/completed-phase/outputs/failed-stress'
        for name in ('core',):
            (run/'run'/name).mkdir(parents=True)
        core = rows[-1]
        (run/'run/core/runtime-workspace.json').write_text(json.dumps(dict(
            schema='managed-workspace-location.v1', workspace=str(runtime.relative_to(self.root)))))
        (run/'run/core/identity.json').write_text(value['identityBytes'])
        core['outputs']['identity']['path'] = 'core/identity.json'
        for row in rows:
            for output in row.get('outputs', {}).values():
                if 'identity' in output:
                    state = run/('state-' + row['id'] + '.json')
                    state.write_text('{}')
                    output['stateEvidence'] = dict(path=str(state.relative_to(self.root)), sha256=digest(state))
        header = dict(inputs={value['sourceLock']: value['sourceLockSha256']}, budgetSeconds=3600)
        (run/'run-header.json').write_text(json.dumps(header))
        path = run/'run/core.observation.json'
        path.write_text('{}')
        seal = self.root/'.cache/tasks/repair/ci/producer'; seal.mkdir()
        (seal/'engine.json').write_text(json.dumps(value['engineManifest']))
        descriptor = self.root/'evidence/input.json'
        descriptor.write_text(json.dumps(dict(schema='runtime-artifact-input.v1', path=str(path.relative_to(self.root)),
            producerEngine=dict(path=str(seal.relative_to(self.root)), engineId=value['engineManifest']['engineId']))))
        proof = dict(prefixIdentity='fixture-prefix', step='core', parentCompletionObserved=False,
                     campaignOutcome='INCOMPLETE', runtimeAdmitted=False)
        return runtime, value, compiler, path, proof, header, rows, run

    def test_completed_phase_uses_existing_import_without_copy_or_full_bootstrap_claim(self):
        from gambit_smp import workspace as w
        from gambit_smp.runtime_artifact import reuse_import_source, consume
        w.start(self.root, 'repair', adopt=True)
        with w.execution_scope(self.root, 'repair'):
            runtime, value, compiler, path, proof, header, rows, run = self.phase_fixture()
            inode = (runtime/'gsi/gsi').stat().st_ino
            ctx, _ = self.context(value, compiler)
            with patch('gambit_smp.research_kernel.manifest_paths', return_value=value['engineManifest']), \
                    patch('gambit_smp.step_checkpoint.observe_stage_record', return_value=(proof, header, rows, run)), \
                    patch('gambit_smp.reasoning_history.read_execution_checkpoint', return_value={'records': []}), \
                    patch('gambit_smp.reasoning_history.execution_checkpoint_head', return_value='fixture-prefix'), \
                    patch('gambit_smp.artifact_storage.checked_workspace_state'), \
                    patch('gambit_smp.runtime_artifact.unpack', side_effect=AssertionError('unnecessary copy')):
                source = reuse_import_source({'sourceLock': value['sourceLock']}, ctx)
                self.assertIn('checkpointSha256', source['sourceReuse'])
                self.assertNotIn('archiveSha256', source['sourceReuse'])
                ctx.receipt['steps'].append(dict(ctx.receipt['plannedSteps'][0], **source, outcome='PASS'))
                ctx.directory = ctx.out/'runtime'; ctx.directory.mkdir()
                result = consume(ctx.receipt['plannedSteps'][1]['arguments'], ctx)
            self.assertEqual(inode, (runtime/'gsi/gsi').stat().st_ino)
            self.assertEqual('pinned-completed-stage', result['producerGeneration']['kind'])
            self.assertEqual('INCOMPLETE', result['producerCheckpoint']['campaignOutcome'])
            self.assertFalse(result['producerCheckpoint']['parentCompletionObserved'])
            self.assertEqual(0, result['workspaceReuse']['copiedFiles'])
            self.assertEqual([], ctx.commands)
            self.assertFalse(result['runtimeAdmitted'])
            self.assertFalse((run/'receipt.json').exists())

    def test_phase_type_and_runtime_drift_are_not_repaired_by_rebuild_or_copy(self):
        from gambit_smp import workspace as w
        from gambit_smp.runtime_artifact import prepare_import
        w.start(self.root, 'repair', adopt=True)
        with w.execution_scope(self.root, 'repair'):
            runtime, value, compiler, path, proof, header, rows, run = self.phase_fixture()
            ctx, _ = self.context(value, compiler)
            with patch('gambit_smp.research_kernel.manifest_paths', return_value=value['engineManifest']), \
                    patch('gambit_smp.step_checkpoint.observe_stage_record', return_value=(proof, header, rows, run)), \
                    patch('gambit_smp.reasoning_history.read_execution_checkpoint', return_value={'records': []}), \
                    patch('gambit_smp.artifact_storage.checked_workspace_state'):
                capability = rows[-1]['capability']
                rows[-1]['capability'] = 'gambit.seed-core'
                with self.assertRaisesRegex(ValueError, 'cannot be replaced by a seed'):
                    prepare_import('evidence/input.json', ctx)
                rows[-1]['capability'] = capability
                (runtime/'gsi/gsi').write_bytes(b'different producer')
                with self.assertRaisesRegex(ValueError, 'no duplicate fallback'):
                    prepare_import('evidence/input.json', ctx)
            self.assertEqual([], ctx.commands)

    def test_missing_local_producer_installs_once_and_archive_envelopes_do_not_multiply_products(self):
        from gambit_smp import workspace as w
        from gambit_smp.runtime_artifact import prepare_import
        w.start(self.root, 'repair', adopt=True)
        with w.execution_scope(self.root, 'repair'):
            original, value, compiler, archive = self.generation()
            original.rename(original.with_name('retained-fixture-input'))
            ctx, scope = self.context(value, compiler)
            ctx.tools.update(tar=shutil.which('tar'), sh=shutil.which('sh'))
            with patch('gambit_smp.research_kernel.manifest_paths', return_value=value['engineManifest']):
                runtime, _, _, storage = prepare_import('evidence/input.json', ctx)
            self.assertEqual('installed-import-workspace', storage['mode'])
            inode = (runtime/'gsi/gsi').stat().st_ino
            self.assertEqual(['runtime-install'], [row['stage'] for row in ctx.commands])
            ctx.workspace_leases.close(); scope.close()
        with tarfile.open(archive) as stream:
            logs = {name:stream.extractfile('evidence/'+name).read().decode() for name in value['logs']}
        outer = json.loads(value['outerReceipt']);outer['wholeSeconds'] += 1
        value['outerReceipt'] = json.dumps(outer)
        value['checkpoint']['outerReceiptSha256'] = hashlib.sha256(value['outerReceipt'].encode()).hexdigest()
        value['logs']['receipt.json'] = value['checkpoint']['outerReceiptSha256']
        logs['receipt.json'] = value['outerReceipt']
        replacement = archive.with_name('repacked.tar')
        pack(replacement, runtime, value, logs=logs)
        (self.root/'evidence/input.json').write_text(json.dumps(dict(
            schema='runtime-artifact-input.v1', path=str(replacement.relative_to(self.root)))))
        with w.execution_scope(self.root, 'repair'):
            ctx, scope = self.context(value, compiler)
            with patch('gambit_smp.research_kernel.manifest_paths', return_value=value['engineManifest']):
                resumed, _, _, storage = prepare_import('evidence/input.json', ctx)
            self.assertEqual(runtime, resumed)
            self.assertEqual(inode, (resumed/'gsi/gsi').stat().st_ino)
            self.assertEqual('retained-import-workspace', storage['mode'])
            self.assertEqual(0, storage['copiedFiles'])
            self.assertEqual([], ctx.commands)
            ctx.workspace_leases.close(); scope.close()
