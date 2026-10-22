"""Gerbil's real build driver over the existing owned incremental workspace."""
import json
import hashlib
from pathlib import Path
import shutil
import tarfile

from gambit_smp.framework import digest, relative, available_processors

STAGES = ('boot-gxi', 'stage0', 'stage1', 'stdlib', 'libgerbil', 'lang', 'tools')


def validate(args, inputs):
    from gambit_smp.native_capabilities import fields, reference
    fields(args, ('sourceLock', 'runtime', 'identity'))
    if args['sourceLock'] not in inputs:
        raise ValueError('declared pinned Gerbil source lock required')
    reference(args['runtime']); reference(args['identity'])
    if args['runtime']['step'] != args['identity']['step']:
        raise ValueError('Gerbil must consume one same-producer Gambit runtime and identity')


def _files(root):
    """Exact file bytes and modes; generated aliases must stay inside the tree."""
    from gambit_smp.recipes import tree_identity
    return tree_identity(root)


def _current(source, proof, inputs, *, stage=None, root=None, witnesses=None):
    if not proof or not proof.get('outputs'):
        return False
    if proof.get('inputsSha256') != inputs:
        return False
    if stage == 'stage0':
        if proof.get('kind') != 'completed-stage0-modules.v1':return False
        originals = source/'src/bootstrap/gerbil'
        names = {path.relative_to(originals).as_posix() for path in originals.rglob('*.scm') if path.is_file()}
        if not names or names != set(proof.get('modules',{})):return False
        if root is None:return False
        witnesses = _module_witnesses(root,proof['modules'])
        for name, child in proof['modules'].items():
            if not _current(source,child,_module_input(inputs,name,originals/name),stage=_module_stage(name),
                            root=root,witnesses=witnesses):
                return False
    else:
        raw = proof.get('receiptBytes', '')
        if hashlib.sha256(raw.encode()).hexdigest() != proof.get('receiptSha256'):
            return False
        receipt = json.loads(raw)
        if (receipt.get('state') != 'OBSERVED' or receipt.get('exit') != 0
                or receipt.get('timeout') is not False or receipt.get('parentReaped') is not True
                or receipt.get('processGroupQuiescent') is not True):
            return False
        command = proof.get('command')
        if not command or any(receipt.get(key) != item for key,item in command.items()):
            return False
        if stage is not None and receipt.get('stage') != 'gerbil-' + stage:
            return False
    if stage is not None and stage.startswith('stage0-module-'):
        if root is None or witnesses is None:return False
        ref = proof.get('completion',{})
        key = tuple(ref.get(name) for name in ('path','sha256','observation','scope'))
        core = {key:value for key,value in proof.items() if key not in {'completion','completionRun'}}
        if witnesses.get(key) != core:return False
    for name, expected in proof['outputs'].items():
        path = source / name
        if (not path.is_file() or path.is_symlink() or digest(path) != expected
                or name in proof.get('modes',{}) and path.stat().st_mode & 0o777 != proof['modes'][name]):
            return False
    for name, expected in proof.get('links', {}).items():
        path = source / name
        if not path.is_symlink() or str(path.readlink()) != expected:
            return False
        try:target = path.resolve(strict=True)
        except (OSError, RuntimeError):return False
        if not target.is_relative_to(source) or not target.is_file():return False
    return True


def _install_runtime(runtime, source):
    # Same payloads as upstream src/build.sh build_gambit; never invoke that
    # function's unconditional bootstrap/from-scratch a second time.
    copies = [('gsi/gsi', 'bootstrap/bin/gsi'), ('gsc/gsc', 'build/bin/gsc'),
              ('bin/gambuild-C', 'build/bin/gambuild-C')]
    for folder, pattern, target in (
        ('include', 'gambit*.h', 'build/include'), ('lib', '*#.scm', 'build/lib'),
        ('gsc', '*#.scm', 'build/lib'), ('lib', '_define-syntax.scm', 'build/lib'),
        ('lib', '_gambit.c', 'build/lib')):
        copies.extend((str(path.relative_to(runtime)), target + '/' + path.name)
                      for path in (runtime / folder).glob(pattern))
    for folder, stem in (('lib', 'libgambit'), ('gsi', 'libgambitgsi'), ('gsc', 'libgambitgsc')):
        copies.extend((str(path.relative_to(runtime)), 'build/lib/' + path.name)
                      for suffix in ('.a', '.so', '.dylib')
                      if (path := runtime / folder / (stem + suffix)).is_file())
    for origin, destination in copies:
        target, original = source / destination, runtime / origin
        if not original.is_file():
            raise ValueError('required completed Gambit payload missing: ' + origin)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_file() and digest(target) == digest(original):
            continue
        shutil.copy2(original, target)
    return {destination: digest(source / destination) for _, destination in copies}


def _module_witnesses(root, modules):
    from gambit_smp.reasoning_history import read_execution_checkpoint
    result = {}
    for run in {proof.get('completionRun') for proof in modules.values()} - {None}:
        for row in read_execution_checkpoint(root,Path(run))['records']:
            payload = row['payload']
            if payload.get('schema') != 'gerbil-bootstrap-module-observation.v1':continue
            raw = (json.dumps(payload,sort_keys=True,indent=2,allow_nan=False)+'\n').encode()
            key = (row['path'],hashlib.sha256(raw).hexdigest(),row['observation'],row['scope'])
            result[key] = payload['moduleProof']
    return result


def _module_input(parent, name, source):
    return hashlib.sha256(json.dumps(dict(parent=parent, source=name,
        sourceSha256=digest(source), options=['-:p1', '-e', '(include "~~lib/_gambit#.scm")']),
        sort_keys=True).encode()).hexdigest()


def _module_stage(name):
    return 'stage0-module-' + hashlib.sha256(name.encode()).hexdigest()[:16]


def _stage0_modules(ctx, work, source, parent):
    """Compile through actual GSC processes; retain completed modules individually."""
    from gambit_smp.workspace import write
    from gambit_smp.artifact_storage import clone_file
    journal = ctx.receipt.get('journal')
    if not journal:raise ValueError('bootstrap modules require an actual execution journal')
    originals = source / 'src/bootstrap/gerbil'
    if not originals.is_dir():raise ValueError('pinned bootstrap module sources missing')
    module_files = sorted(path for path in originals.rglob('*.scm') if path.is_file())
    if not module_files:raise ValueError('bootstrap module inventory is empty')
    store = work / 'gerbil-stage0-modules.json'
    retained = json.loads(store.read_text()) if store.is_file() else {}
    witnesses = _module_witnesses(ctx.root,retained)
    entries = {}
    target_root = source / 'bootstrap/lib/gerbil'
    copy_sources = [path for path in originals.rglob('*') if path.is_file()]
    copy_sources.extend((source/'src/gerbil/boot').glob('*.scm'))
    copy_sources.append(source/'src/gerbil/boot-gxi')
    plan = dict(configuration=parent,inputs={path.relative_to(source).as_posix():
        dict(sha256=digest(path),mode=path.stat().st_mode & 0o777) for path in copy_sources})
    plan_path = work/'gerbil-stage0-inputs.json'
    if plan_path.exists() and json.loads(plan_path.read_text()) != plan:
        raise ValueError('retained bootstrap input-copy plan changed')
    if not plan_path.exists():write(plan_path,plan)
    def copy_current(origin, target):
        if origin.is_symlink():raise ValueError('bootstrap input aliases are unsupported')
        if target.is_symlink():raise ValueError('bootstrap output aliases are unsupported')
        if target.exists():
            if (target.is_file() and digest(origin) == digest(target)
                    and origin.stat().st_mode & 0o777 == target.stat().st_mode & 0o777):return
            raise ValueError('bootstrap input target has unreviewed drift')
        target.parent.mkdir(parents=True,exist_ok=True)
        pending = target.with_name(target.name+'.module-pending')
        if pending.exists() or pending.is_symlink():
            expected = plan['inputs'][origin.relative_to(source).as_posix()]
            if (pending.is_symlink() or not pending.is_file() or digest(pending) != expected['sha256']
                    or pending.stat().st_mode & 0o777 != expected['mode']):
                raise ValueError('unreconciled bootstrap copy')
        else:clone_file(origin,pending)
        if digest(pending) != digest(origin):raise ValueError('bootstrap input changed during transfer')
        pending.replace(target)
    # Match upstream preparation without refreshing every unchanged timestamp.
    for origin in sorted(originals.rglob('*')):
        target = target_root / origin.relative_to(originals)
        if origin.is_dir():target.mkdir(parents=True,exist_ok=True)
        elif origin.is_file():copy_current(origin,target)
        else:raise ValueError('unsupported bootstrap input')
    flags = 'p1,~~bin='+str(source/'build/bin')+',~~lib='+str(source/'build/lib')+',~~include='+str(source/'build/include')
    argv0 = [source/'build/bin/gsc', '-:'+flags]
    count = ctx.require('gerbil-stage0-processors', [*argv0, '-e', '(write (##current-vm-processor-count))'],
                        source/'src', min(10,ctx.remaining())).strip()
    if count != '1':raise ValueError('actual bootstrap compiler processor budget differs')
    for origin in module_files:
        name = origin.relative_to(originals).as_posix()
        target = target_root/name
        inputs = _module_input(parent,name,origin)
        stage = _module_stage(name)
        previous = retained.get(name,{})
        if _current(source,previous,inputs,stage=stage,root=ctx.root,witnesses=witnesses):
            entries[name] = previous
            continue
        # A STARTED record exists before GSC overwrites any unproved partial .o1.
        output = target.with_suffix('.o1')
        ctx.require('gerbil-'+stage, [*argv0,'-o',output,'-e','(include "~~lib/_gambit#.scm")',target],
                    source/'src', ctx.remaining())
        if _module_input(parent,name,origin) != inputs or digest(target) != digest(origin):
            raise ValueError('bootstrap module input changed during actual compilation')
        command = ctx.commands[-1]
        if (command.get('parentReaped') is not True or command.get('processGroupQuiescent') is not True
                or not output.is_file() or output.is_symlink()):
            raise ValueError('bootstrap module has no completed process/output proof: '+name)
        raw = (ctx.directory/('gerbil-'+stage+'.process.json')).read_text()
        relative_name = output.relative_to(source).as_posix()
        entries[name] = dict(inputsSha256=inputs,outputs={relative_name:digest(output)},
            modes={relative_name:output.stat().st_mode & 0o777},links={},command=command,
            receiptBytes=raw,receiptSha256=hashlib.sha256(raw.encode()).hexdigest())
        from gambit_smp.research_kernel import retain_run_record
        header = json.loads(Path(journal['path']).read_text())
        payload = dict(schema='gerbil-bootstrap-module-observation.v1',header=journal,
            runId=header['runId'],moduleProof=entries[name],runtimeAdmitted=False)
        reference = retain_run_record(ctx.root,ctx.directory/(stage+'.completed.json'),journal['scope'],payload,header['inputs'])
        entries[name].update(completion=reference,completionRun=str(Path(journal['path']).parent))
        retained[name] = entries[name]
        write(store,retained)
    # Match upstream finalize_stage0 after every requested module really closes.
    for origin in (source/'src/gerbil/boot').glob('*.scm'):
        copy_current(origin,source/'bootstrap/lib'/origin.name)
    copy_current(source/'src/gerbil/boot-gxi',source/'bootstrap/bin/boot-gxi')
    return entries


def build(args, ctx):
    from gambit_smp.recipes import read_json, source_path, tree_identity
    from gambit_smp.workspace import build_output, sync_build_source, checkpoint_build_source, write
    from gambit_smp.source_capabilities import source_name
    from gambit_smp.native_capabilities import compiler
    if ctx.receipt.get('workspacePolicy') != 'in-place':
        raise ValueError('Gerbil builds require the shared in-place workspace policy')
    lock_path = source_path(ctx.root, args['sourceLock'])
    lock = read_json(lock_path)
    if (lock.get('schema') != 'gerbil-source-lock.v1' or lock.get('runtimeAdmitted') is not False
            or len(lock.get('revision', '')) != 40):
        raise ValueError('non-admitting pinned Gerbil source revision required')
    checkout = relative(ctx.root, lock['checkout'])
    runtime = ctx.artifact(args['runtime'], 'source-runtime')
    identity = ctx.artifact(args['identity'], 'runtime-identity')
    from gambit_smp.suite_primitives import check_runtime
    check_runtime(runtime, read_json(identity))
    ctx.bind([identity])
    compiler(ctx)
    # The Git revision binds unmodified core inputs. Only declared core overlay
    # bytes alter the compiler namespace; stdlib edits stay incremental.
    core = {name: value for name, value in lock.get('files', {}).items()
            if name.startswith(('src/gerbil/', 'src/bootstrap/', 'src/build/'))
            or name in {'src/build.sh', 'build.sh', 'configure'}}
    configuration = dict(revision=lock['revision'], runtimeSha256=digest(identity),
        compilerInputs={path: sha for path, sha in ctx.extra_inputs.items() if path != str(identity)}, coreInputs=core,
        tools={name: digest(Path(path)) for name, path in ctx.tools.items() if name in {'gcc', 'as', 'ld', 'sh', 'make'}})
    work = build_output(ctx.root, 'gerbil', compiler=ctx.tools['gcc'],
                        flags=[json.dumps(configuration, sort_keys=True)])
    source = work / 'source'
    source.mkdir(exist_ok=True)
    ctx.lease_workspace(source, tree_identity(source))
    state_path = work / 'source-state.json'
    previous = read_json(state_path) if state_path.is_file() else {}
    partial = bool(previous.get('inputs')) and 'overlayFiles' in previous
    selected = sorted(set(lock.get('files', {})) | set(previous.get('overlayFiles', []))
                      | set(previous.get('pendingOverlayFiles', []))) if partial else []
    for name in selected:source_name(name)
    archive = ctx.directory / 'gerbil-source.tar'
    ctx.require('gerbil-archive', [ctx.tools['git'], '-C', checkout, 'archive',
        '--output=' + str(archive), lock['revision'], '--', *selected], ctx.root, min(30, ctx.remaining()))
    staged = ctx.directory / 'gerbil-inputs'
    from gambit_smp.artifact_storage import extract_archive
    extract_archive(archive,staged,ctx,stage='gerbil-extract',preserve_modes=False)
    archive.unlink()
    if 'patch' in lock:
        if lock['patch'] not in ctx.receipt['declaredInputs']:
            raise ValueError('Gerbil overlay must be a declared input')
        patch = source_path(ctx.root, lock['patch'])
        if digest(patch) != lock.get('patchSha256'):
            raise ValueError('Gerbil overlay drift')
        inventory = ctx.require('gerbil-overlay-inventory', [ctx.tools['git'], '--git-dir=/dev/null',
            'apply', '--numstat', '-z', patch], staged, min(10, ctx.remaining()))
        for line in inventory.split('\0'):
            if line and line.split('\t', 2)[-1] not in lock.get('files', {}):
                raise ValueError('Gerbil overlay exceeds its declared source files')
        ctx.require('gerbil-overlay', [ctx.tools['git'], '--git-dir=/dev/null', 'apply',
            '--whitespace=error', patch], staged, min(10, ctx.remaining()))
    for name, sha in lock.get('files', {}).items():
        source_name(name)
        if digest(staged / name) != sha:
            raise ValueError('Gerbil candidate differs from source lock: ' + name)
    incoming = dict(previous['inputs'], **tree_identity(staged)) if partial else tree_identity(staged)
    delta = sync_build_source(ctx.root, work, staged, mutable=['src/gerbil/runtime/version.ss'],
                             inventory=incoming, overlay_files=sorted(lock.get('files', {})), consume_staged=True)
    shutil.rmtree(staged)
    # Idempotent initialization replaces upstream prepare's rm -rf operations.
    for prefix in ('bootstrap', 'build'):
        for folder in ('bin', 'lib', 'include'):
            (source / prefix / folder).mkdir(parents=True, exist_ok=True)
    payloads = _install_runtime(runtime, source)
    ctx.env.update(GERBIL_PREFIX=str(work / 'prefix'), GERBIL_VERSION=lock['revision'],
        GERBIL_VERSION_STRING=lock['revision'], GERBIL_BUILD_CORES='1',
        GERBIL_PATH=str(work / 'user'),
        CC=str(ctx.tools['gcc']), GERBIL_GCC=str(ctx.tools['gcc']))
    proofs_path = work / 'gerbil-stages.json'
    proofs = read_json(proofs_path) if proofs_path.is_file() else {}
    reuse = []
    for stage in STAGES:
        # Only actual completed bootstrap stages with current exact artifacts
        # can be consumed. The downstream dependency-aware builders always run.
        dependencies = {name: proofs[name]['outputs'] for name in ('boot-gxi', 'stage0')
                        if name in proofs and STAGES.index(name) < STAGES.index(stage)}
        inputs = hashlib.sha256(json.dumps(dict(configuration=digest(work / 'configuration.json'),
            runtime=payloads, dependencies=dependencies), sort_keys=True).encode()).hexdigest()
        if stage in {'boot-gxi', 'stage0', 'stage1'} and _current(source, proofs.get(stage), inputs, stage=stage, root=ctx.root):
            reuse.append(stage)
            continue
        modules = None
        if stage == 'stage0':
            modules = _stage0_modules(ctx,work,source,inputs)
        else:
            ctx.require('gerbil-' + stage, [ctx.tools['sh'], './build.sh', stage],
                        source / 'src', ctx.remaining())
            if (ctx.commands[-1].get('parentReaped') is not True
                    or ctx.commands[-1].get('processGroupQuiescent') is not True):
                raise ValueError('Gerbil stage has no completed quiescent process observation: ' + stage)
        if stage in {'boot-gxi', 'stage0', 'stage1'}:
            roots = {'boot-gxi': ['src/gerbil/boot-gxi'],
                     'stage0': ['bootstrap'], 'stage1': ['build/bin', 'build/lib/gerbil', 'build/lib/static']}[stage]
            outputs, links = {}, {}
            for name in roots:
                target = source / name
                paths = list(target.rglob('*')) if target.is_dir() else [target]
                outputs.update({str(path.relative_to(source)): digest(path) for path in paths
                                if path.is_file() and not path.is_symlink()})
                links.update({str(path.relative_to(source)): str(path.readlink()) for path in paths
                              if path.is_symlink()})
            if not outputs:
                raise ValueError('Gerbil stage has no actual output inventory: ' + stage)
            modes = {name:(source/name).stat().st_mode & 0o777 for name in outputs}
            if modules is not None:
                proofs[stage] = dict(kind='completed-stage0-modules.v1',modules=modules,
                    outputs=outputs,links=links,modes=modes,inputsSha256=inputs)
            else:
                raw = (ctx.directory / ('gerbil-' + stage + '.process.json')).read_text()
                proofs[stage] = dict(outputs=outputs, links=links, modes=modes,command=ctx.commands[-1], receiptBytes=raw,
                                    receiptSha256=hashlib.sha256(raw.encode()).hexdigest(), inputsSha256=inputs)
            write(proofs_path, proofs)
        checkpoint_build_source(source)
    executable = source / 'build/bin/gerbil'
    if not executable.is_file():
        raise ValueError('Gerbil build did not produce its executable')
    checkpoint_build_source(source, phase='ready')
    check_runtime(runtime, read_json(identity))
    observation = dict(workspace=str(source), sourceDelta=delta, bootstrapReused=reuse,
        compilerResourcePlan=dict(workers=1,stage0CompilerProcessors=1,hostCpuCapacity=available_processors()),
        runtimePayloads=payloads, executableSha256=digest(executable), runtimeAdmitted=False,
        configurationSha256=digest(work / 'configuration.json'),
        workspaceIdentitySha256=hashlib.sha256(json.dumps(tree_identity(source),sort_keys=True).encode()).hexdigest())
    output = ctx.directory / 'gerbil-build.json'
    output.write_text(json.dumps(observation, indent=2) + '\n')
    return {'outputs': ctx.publish('observations', 'gerbil-build-observations', output),
            'observation': observation, 'claim': 'incremental-Gerbil-build-not-runtime-acceptance'}


def validate_test(args, inputs):
    from gambit_smp.native_capabilities import fields, reference
    fields(args, ('build',));reference(args['build'])


def test(args, ctx):
    """The upstream default recursive gxtest selection, over the actual build."""
    from gambit_smp.recipes import read_json, tree_identity
    from gambit_smp.workspace import task_output, checkpoint_build_source
    if ctx.receipt.get('workspacePolicy') != 'in-place':
        raise ValueError('Gerbil tests require the managed build workspace')
    proof = read_json(ctx.artifact(args['build'],'gerbil-build-observations'))
    source = Path(proof['workspace']).resolve(strict=True)
    from gambit_smp.artifact_storage import fixture_root
    fixture_root(ctx.root,source)
    if task_output(ctx.root,source) != source:
        raise ValueError('Gerbil test workspace belongs to another owner')
    current = tree_identity(source)
    if (hashlib.sha256(json.dumps(current,sort_keys=True).encode()).hexdigest() != proof.get('workspaceIdentitySha256')
            or digest(source.parent/'configuration.json') != proof.get('configurationSha256')
            or digest(source/'build/bin/gerbil') != proof['executableSha256']):
        raise ValueError('Gerbil build changed before its full test selection')
    ctx.lease_workspace(source,current)
    files = sorted(str(path.relative_to(source/'src')) for path in (source/'src').rglob('*-test.ss') if path.is_file())
    if not files:raise ValueError('full Gerbil source test inventory is empty')
    def payloads():
        if any(digest(source/name) != sha for name,sha in proof['runtimePayloads'].items()):
            raise ValueError('same-producer Gambit payload changed during Gerbil tests')
    payloads()
    ctx.env.update(GERBIL_PREFIX=str(source.parent/'prefix'),GERBIL_HOME=str(source/'build'),
                   GERBIL_PATH=str(source.parent/'user'))
    observation=dict(testFiles=files,workspace=str(source),outcome='PENDING',runtimeAdmitted=False)
    output=ctx.directory/'gerbil-tests.json'
    output.write_text(json.dumps(observation,indent=2)+'\n')
    code,log,timeout,seconds=ctx.run('gerbil-tests',
        [ctx.tools['sh'],'./build.sh','env','gxtest','./...'],source/'src',ctx.remaining())
    completed = (code == 0 and not timeout and ctx.last_stdout.rstrip().splitlines()[-1:] == ['OK']
                 and ctx.commands[-1].get('parentReaped') is True
                 and ctx.commands[-1].get('processGroupQuiescent') is True)
    observation.update(exit=code,timeout=timeout,seconds=seconds,
        parentReaped=ctx.commands[-1].get('parentReaped'),
        processGroupQuiescent=ctx.commands[-1].get('processGroupQuiescent'),
        outcome='PASS' if completed else 'DENY')
    output.write_text(json.dumps(observation,indent=2)+'\n')
    payloads()
    if (observation['outcome'] != 'PASS' or observation['parentReaped'] is not True
            or observation['processGroupQuiescent'] is not True):
        raise ValueError('full upstream Gerbil tests did not complete successfully; see actual streams')
    checkpoint_build_source(source,phase='ready')
    return dict(outputs=ctx.publish('observations','gerbil-test-observations',output),observation=observation)
