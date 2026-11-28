"""Gerbil build: custody."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json


def _product_observation_directory(ctx, outbox):
    """Old producer bytes stay immutable when a new issuer settles them."""
    outbox = Path(outbox)
    target = outbox if outbox.parent == ctx.directory else ctx.directory/'product-observations'
    target.mkdir(exist_ok=True)
    return target


def _module_arguments_supported(argv, context=None):
    """The fixed stdlib C role, not arbitrary compiler/evaluator capabilities."""
    import shlex
    args=list(argv[:-1]);i=0
    while i<len(args):
        flag=args[i];i+=1
        if flag in ('-debug-source','-track-scheme'):continue
        if flag not in ('-target','-cc-options','-ld-options','-e') or i==len(args):return False
        value=args[i];i+=1
        if flag=='-target':
            if value!='C':return False
        elif flag=='-e':
            if value=='(define-cond-expand-feature|enable-smp|)':continue
            if value=='(include "~~lib/_gambit#.scm")':continue
            if not (value.startswith('(include "') and value.endswith('")')):return False
            try:path=json.loads(value[len('(include '):-1])
            except (ValueError,TypeError):return False
            if not context or str(Path(path).resolve()) not in context['inputs'] or Path(path).name!='_gambit#.scm':return False
        else:
            try:words=shlex.split(value)
            except ValueError:return False
            j=0
            while j<len(words):
                word=words[j];j+=1
                if word in ('-D','-U','-I','-L'):
                    if j==len(words):return False
                    j+=1;continue
                if word in ('-g','-pthread'):continue
                if word.startswith(('-D','-U','-I','-L','-l','-Wno-')):continue
                return False
    return True


class AdmissionFiles:
    """One leased preparation's byte observations, discarded before Make.

    Repeated references share a read, not a freshness exemption. A changed
    inode or timestamp aborts the snapshot instead of reusing its old hash.
    """
    def __init__(self):
        self.observations = {}
        self.requests = self.reads = self.bytes = 0

    @staticmethod
    def stamp(path):
        s = path.stat()
        return (s.st_dev, s.st_ino, s.st_mode, s.st_nlink, s.st_size,
                s.st_mtime_ns, s.st_ctime_ns)

    def matches(self, path, expected):
        import stat
        path = Path(path)
        self.requests += 1
        try:
            stamp = self.stamp(path)
        except FileNotFoundError:
            return False
        if not stat.S_ISREG(stamp[2]):return False
        if path in self.observations:
            before, actual = self.observations[path]
            if before != stamp:raise ValueError('file changed during compiler admission')
        else:
            actual = digest(path)
            if self.stamp(path) != stamp:
                raise ValueError('file changed during compiler admission')
            self.reads += 1
            self.bytes += stamp[4]
            self.observations[path] = (stamp, actual)
        return actual == expected

    def summary(self):
        return dict(requests=self.requests, byteReads=self.reads,
                    bytesRead=self.bytes, avoidedReads=self.requests-self.reads,
                    lifetime='one preparation; released before Make')


def _files(root):
    """Exact file bytes and modes; generated aliases must stay inside the tree."""
    from gambit_smp.recipes import tree_identity
    return tree_identity(root)


def _completed_command(receipt, command):
    """The receipt adds transport metadata; every recorded command field agrees."""
    return bool(command and receipt.get('state')=='OBSERVED' and receipt.get('exit')==0
        and receipt.get('timeout') is False
        and all(receipt.get(k) is True for k in ('parentReaped','processGroupQuiescent'))
        and all(receipt.get(k)==value for k,value in command.items()))


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
        command = proof.get('command')
        if not _completed_command(receipt,command):
            return False
        if stage is not None and receipt.get('stage') != 'gerbil-'+stage:
            return False
        predecessors=proof.get('predecessors',[])
        expected={'stage1':['gerbil-stage1-driver-frontend','gerbil-stage1-driver-native',
                            'gerbil-stage1-frontend','gerbil-stage1-native'],
                  'stdlib':['gerbil-stdlib-frontend','gerbil-stdlib-native']}
        if predecessors or stage=='stdlib':
            if [p.get('command',{}).get('stage') for p in predecessors] != expected.get(stage):
                return False
            for predecessor in predecessors:
                if not _completed_command(json.loads(predecessor.get('receiptBytes','{}')),predecessor.get('command')):
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


def _module_witnesses(root, modules, *, schema='gerbil-bootstrap-module-observation.v1', payload_key='moduleProof', checkpoints=None):
    from gambit_smp.reasoning_history import read_execution_checkpoint
    result = {}
    if checkpoints is None:checkpoints={}
    for run in {proof.get('completionRun') for proof in modules.values()} - {None}:
        if run not in checkpoints:
            checkpoints[run]=read_execution_checkpoint(root,Path(run))
        for row in checkpoints[run]['records']:
            payload = row['payload']
            if payload.get('schema') != schema:continue
            raw = (json.dumps(payload,sort_keys=True,indent=2,allow_nan=False)+'\n').encode()
            key = (row['path'],hashlib.sha256(raw).hexdigest(),row['observation'],row['scope'])
            result[key] = payload[payload_key]
    return result


def _module_input(parent, name, source):
    return hashlib.sha256(json.dumps(dict(parent=parent, source=name,
        sourceSha256=digest(source), options=['-:p1', '-e', '(include "~~lib/_gambit#.scm")']),
        sort_keys=True).encode()).hexdigest()


def _module_stage(name):
    return 'stage0-module-' + hashlib.sha256(name.encode()).hexdigest()[:16]


def _is_native_product(path):
    suffix = Path(path).suffix
    return (suffix in {".o", ".a", ".so", ".dylib", ".bundle"}
            or (suffix.startswith(".o") and suffix[2:].isascii() and suffix[2:].isdecimal()))


def _stage_completion(ctx, source, stage, inputs, prefixes, *, required_marker=None):
    """Actual completed-command receipt plus the current owned output bytes."""
    from gambit_smp.recipes import tree_identity
    tree = {name:row for name,row in tree_identity(source).items()
            if any(name == prefix or name.startswith(prefix+'/') for prefix in prefixes)}
    outputs = {name:row['sha256'] for name,row in tree.items() if 'sha256' in row}
    if not outputs:
        raise ValueError('completed stage has no owned outputs: '+stage)
    command_stage = 'gerbil-'+stage
    raw = (ctx.directory/(command_stage+'.process.json')).read_text()
    command=next(row for row in ctx.commands if row['stage']==command_stage)
    if not _completed_command(json.loads(raw),command):
        raise ValueError('completed stage command differs from its actual receipt')
    if required_marker is not None:
        receipt = json.loads(raw)
        stdout = ctx.directory/receipt.get('stdoutPath','missing-stdout')
        if (not stdout.is_file() or digest(stdout) != receipt.get('stdoutSha256')
                or required_marker not in stdout.read_text().splitlines()):
            raise ValueError('completed stage lacks its actual consumer marker')
    return dict(inputsSha256=inputs, outputs=outputs,
        modes={name:row['mode'] for name,row in tree.items() if 'mode' in row},
        links={name:row['link'] for name,row in tree.items() if 'link' in row},
        command=command,
        receiptBytes=raw, receiptSha256=hashlib.sha256(raw.encode()).hexdigest())


def _git_blob(path):
    data = Path(path).read_bytes()
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()


def _scheme_product_data(value):
    """Encode only the inert cache transport subset consumed by Scheme read."""
    if isinstance(value, str):
        return '"'+''.join('\\'+c if c in '\\"' else
            ('\\x'+format(ord(c),'x')+';' if ord(c)<32 else c) for c in value)+'"'
    if type(value) is bool:
        return '#t' if value else '#f'
    if type(value) is int:
        return str(value)
    if isinstance(value, list):
        return '('+' '.join(_scheme_product_data(v) for v in value)+')'
    raise ValueError('inert compiler product data required')


def _phase_producer(root, run, progress, phase):
    """Follow only explicit sealed retention ancestry to the actual producer."""
    from gambit_smp.artifact_storage import observation_root
    from gambit_smp.step_checkpoint import recovered_resumption
    seen=set()
    while phase in progress.get('retainedPhases',[]):
        if run in seen or len(seen)>=16:raise ValueError('prepared phase ancestry cycle')
        seen.add(run)
        reference=progress.get('sourceProfilePrepared',{})
        parent=relative(root,reference.get('run',''))
        if str(parent)!=progress.get('preparedFrom'):raise ValueError('prepared phase ancestry differs')
        observation_root(root,parent)
        if recovered_resumption(root,parent)['resumption']['executionQuiescence']['observed'] is not True:
            raise ValueError('prepared ancestor is not quiescent')
        path=parent/'run/compiler/ci-stage-products.json'
        if not path.is_file() or digest(path)!=reference.get('sha256'):
            raise ValueError('prepared ancestor snapshot differs')
        previous=json.loads(path.read_text())
        comparable=lambda c:{k:v for k,v in c.items() if k!='boundInputsSha256'}
        core_phase=phase in ('configure','prepare','gambit','boot-gxi','stage0','stage1')
        phase_heads=lambda p:p.get('retainedPhaseHeads',{}).get(phase,
            ((p.get('retainedCoreHeads') or p.get('heads')) if core_phase and phase in p.get('retainedPhases',[]) else p.get('heads')))
        if (phase_heads(previous)!=phase_heads(progress) or previous.get('source')!=progress.get('source')
                or comparable(previous['configuration'])!=comparable(progress['configuration'])
                or previous.get('completed',{}).get(phase)!=progress.get('completed',{}).get(phase)):
            raise ValueError('prepared ancestor producer cohort differs')
        run,progress=parent,previous
    return run


def _failed_construction_spent(root,run,prior_spent):
    """Charge a known failed return or an exactly reconciled interruption.

    The caller independently verifies execution quiescence and completed phase
    receipts. An ordinary failed return must not enter the interruption-only
    verifier, which intentionally rejects that different supervisor state.
    """
    from datetime import datetime
    from gambit_smp.research_kernel import supervised_interruption
    parts=run.relative_to(root/'.cache/tasks').parts
    owner=root/'.state/work-process-runs'/parts[0]/parts[2]/(parts[4]+'.json')
    data=json.loads(owner.read_text())
    expected=root/'.cache/tasks'/parts[0]/'processes'/parts[2]/'runs'/parts[4]
    if (data.get('task')!=parts[0] or data.get('process')!=parts[2] or data.get('run')!=parts[4]
            or Path(data.get('output','')).resolve()!=expected.resolve()):
        raise ValueError('prepared supervisor identity differs')
    failed_return=(data.get('state')=='returned' and type(data.get('exit')) is int and data['exit']!=0
                   and data.get('parentReaped') is True
                   and data.get('registeredGroupCleanup',{}).get('unresolved')==[])
    if not failed_return and supervised_interruption(root,run) is None:
        raise ValueError('prepared phases require reconciled failed supervisor custody')
    spent=(datetime.fromisoformat(data['endedAt'])-datetime.fromisoformat(data['startedAt'])).total_seconds()+prior_spent
    if spent<=0:raise ValueError('prepared construction expenditure is unknown')
    return spent


def _prepared_ci_products(ctx, reference, heads, configuration, source_hash, producer_hash, script, *, bound_inputs=None, gerbil_checkout=None):
    """Recheck recorded completions and bytes after a reconciled interruption.

    A STARTED phase, missing completion or changed output never grants reuse.
    Older unsealed ledgers require their actual process receipts and independent
    journal birth records; the current work ledger alone is insufficient.
    """
    from gambit_smp.native_capabilities import fields
    from gambit_smp.gerbil_build.policy import STAGES
    from gambit_smp.recipes import tree_identity
    from gambit_smp.reasoning_history import read_execution_checkpoint
    from gambit_smp.step_checkpoint import recovered_resumption
    from gambit_smp.workspace import write
    from gambit_smp.artifact_storage import fixture_root, observation_root
    from datetime import datetime
    fields(reference, ('run','sha256','engine'),('sourceChanges',))
    run = relative(ctx.root,reference['run'])
    import os
    task=os.environ.get('GAMBIT_SMP_TASK_ID')
    store=ctx.root/'.cache/tasks'/task if task else None
    if store is None or not run.is_relative_to(store):
        raise ValueError('prepared phases belong to another task')
    observation_root(ctx.root,run)
    state = recovered_resumption(ctx.root,run)
    if state['resumption']['executionQuiescence']['observed'] is not True:
        raise ValueError('prepared phase producer is not quiescent')
    path = run/'run/compiler/ci-stage-products.json'
    if not path.is_file() or digest(path) != reference['sha256']:
        raise ValueError('prepared phase snapshot missing or changed')
    progress = json.loads(path.read_text())
    if progress.get('schema') != 'gerbil-ci-stage-products':
        raise ValueError('prepared phase source cohort differs')
    origin_heads=progress.get('heads')
    source_changes=reference.get('sourceChanges')
    first_invalidated=None
    if origin_heads!=heads:
        if not source_changes:raise ValueError('prepared phase source cohort differs')
        from gambit_smp.gerbil_build.bootstrap_inputs import _source_changes
        first_invalidated=_source_changes(source_changes,origin_heads,heads,progress.get('completed',{}))
        if gerbil_checkout is None:raise ValueError('stdlib update has no source provider')
    elif source_changes:
        raise ValueError('stdlib changes require a new committed revision')
    comparable = lambda c: {k:v for k,v in c.items() if k != 'boundInputsSha256'}
    if comparable(progress['configuration']) != comparable(configuration):
        raise ValueError('prepared phase effective configuration differs')
    original_key=hashlib.sha256(json.dumps(dict(heads=origin_heads,configuration=progress['configuration'],
        gambit=source_hash,producer=producer_hash),sort_keys=True).encode()).hexdigest()
    if original_key != progress['inputsSha256']:
        raise ValueError('prepared native producer or source identity changed')
    header=json.loads((run/'run-header.json').read_text())
    old_engine=relative(ctx.root,reference['engine'])
    if not old_engine.is_relative_to(store):raise ValueError('prepared engine belongs to another task')
    observation_root(ctx.root,old_engine)
    from gambit_smp.research_kernel import manifest_paths
    manifest=manifest_paths(old_engine)
    if manifest['engineId'] != header['engineId']:
        raise ValueError('prepared engine differs from the actual producer')
    # Replay the original input rollup with the old sealed Python bytes. The
    # sole profile difference allowed here is this explicit prepared reference.
    # SDK, native tools, flags and source inputs keep their current hashes.
    package=Path(__file__).resolve().parent.parent
    old_inputs={}
    later_implementation_inputs=[]
    if bound_inputs is None:raise ValueError('prepared phase configuration bindings are missing')
    for name,sha in bound_inputs.items():
        item=Path(name)
        if item.is_relative_to(package):
            prior_item=old_engine/'python/gambit_smp'/item.relative_to(package)
            if not prior_item.is_file():
                # New framework support did not produce an old completed phase.
                # Its bytes remain bound to this run. Native inputs are checked
                # separately and the complete old rollup must still match.
                later_implementation_inputs.append(name)
                continue
            old_inputs[str(prior_item)]=digest(prior_item)
        else:
            relative_name=str(item.relative_to(ctx.root)) if item.is_relative_to(ctx.root) else None
            expected=header['inputs'].get(relative_name)
            if expected and expected != sha:
                value=json.loads(item.read_text()) if item.suffix=='.json' else None
                if not isinstance(value,dict) or value.get('schema')!='gerbil-ci-source-profile':
                    raise ValueError('prepared non-profile input changed: '+name)
                value.pop('prepared',None)
                if source_changes:value['gerbil']['revision']=origin_heads['gerbil']
                if progress.get('sourceProfilePrepared') is not None:
                    value['prepared']=progress['sourceProfilePrepared']
                if hashlib.sha256((json.dumps(value,indent=2)+'\n').encode()).hexdigest()!=expected:
                    raise ValueError('prepared source profile changed beyond its reference')
                sha=expected
            old_inputs[name]=sha
    if hashlib.sha256(json.dumps(old_inputs,sort_keys=True).encode()).hexdigest()!=progress['configuration']['boundInputsSha256']:
        raise ValueError('prepared native dependency rollup differs')
    if later_implementation_inputs:
        from gambit_smp.workspace import write
        write(ctx.directory/'prepared-later-implementation-inputs.json',dict(
            inputs=later_implementation_inputs,oldNativeDependencyRollupMatched=True,
            newInputsGrantOldPhaseAuthority=False))
    source = Path(progress['source']).resolve(strict=True)
    fixture_root(ctx.root,source)
    ctx.lease_workspace(source,tree_identity(source))
    for kind,tree in (('gerbil',source),('gambit',source/'src/gambit')):
        actual=ctx.require('prepared-'+kind+'-head',[ctx.tools['git'],'-C',tree,'rev-parse','HEAD'],ctx.root,10).strip()
        expected=(heads[kind] if kind=='gerbil' and source_changes and actual==heads[kind] else origin_heads[kind])
        if actual!=expected:raise ValueError('prepared checkout identity changed: '+kind)
    dirty=ctx.require('prepared-gerbil-source',[ctx.tools['git'],'-C',source,'diff','--name-only','HEAD','--',
        ':(exclude)src/gambit',':(exclude)src/gerbil/runtime/version.ss'],ctx.root,10).strip()
    if dirty:raise ValueError('prepared Gerbil source changed: '+dirty)
    inputs = source.parent/'bazel-source-inputs.json'
    previous_input_bytes = inputs.read_bytes()
    previous_inputs = json.loads(previous_input_bytes)
    actual_hash = hashlib.sha256(json.dumps(previous_inputs['files'],sort_keys=True).encode()).hexdigest()
    if actual_hash != source_hash or previous_inputs['heads'] != origin_heads:
        raise ValueError('prepared phase Gambit inputs differ')
    for name,row in previous_inputs['files'].items():
        item=source/'src/gambit'/name
        if not item.is_file():raise ValueError('prepared Gambit input missing: '+name)
        if digest(item)!=row['sha256'] and not (len(Path(name).parts)==2
            and Path(name).parts[0] in ('lib','gsc','gsi') and Path(name).name.startswith('_') and name.endswith('.c')):
            raise ValueError('prepared Gambit semantic source changed: '+name)
    journals={}
    accepted = []
    for phase in ('configure','prepare','gambit','boot-gxi',*STAGES[1:],'install'):
        if phase==first_invalidated:
            break
        if phase not in progress['completed']:
            break
        command = progress['completed'][phase]
        if command.get('kind') == 'joined-module-products':
            proof=progress['products'].get(phase,{})
            if phase!='stage0' or not _current(source,proof,proof.get('inputsSha256'),stage=phase,root=ctx.root):
                raise ValueError('prepared module aggregate lacks complete witnesses')
            accepted.append(phase)
            continue
        producer=_phase_producer(ctx.root,run,progress,phase)
        if producer not in journals:
            rows=[r['payload'] for r in read_execution_checkpoint(ctx.root,producer)['records']]
            journals[producer]=(
                {r['token']:r for r in rows if r.get('schema')=='research-process-observation.v1' and r.get('event')=='planned'},
                {r['token']:r for r in rows if r.get('schema')=='research-process-observation.v1' and r.get('event')=='started'})
        planned,started=journals[producer]
        receipt = producer/'run/compiler'/('gerbil-'+phase+'.process.json')
        recorded=json.loads(receipt.read_text()) if receipt.is_file() else {}
        if (not _completed_command(recorded,command)
                or recorded.get('schema')!='recipe-process-observation.v1'
                or recorded.get('completionObserved') is not True or recorded.get('runtimeAdmitted') is not False):
            raise ValueError('prepared phase command receipt differs: '+phase)
        witnesses = [started[t] for t,p in planned.items() if p.get('argv') == command.get('argv')
                     and p.get('cwd') == command.get('cwd') and t in started
                     and started[t].get('pid') == command.get('pid')]
        if (len(witnesses) != 1 or command.get('exit') != 0 or command.get('timeout') is not False
                or any(command.get(k) is not True for k in ('parentReaped','processGroupQuiescent'))):
            raise ValueError('prepared phase lacks known process completion: '+phase)
        if phase in progress['products']:
            proof = progress['products'][phase]
            if not _current(source,proof,proof['inputsSha256'],stage=phase,root=ctx.root):
                raise ValueError('prepared phase product changed: '+phase)
        accepted.append(phase)
        ctx.bind([receipt])
    if accepted[:4] != ['configure','prepare','gambit','boot-gxi']:
        raise ValueError('prepared compiler lacks the completed Gambit/bootstrap cut')
    # The owned work manifest advances with the declared source generation.
    # Bind the exact bytes that were checked, not that mutable publication path.
    input_snapshot = ctx.directory/'prepared-source-inputs.json'
    input_snapshot.write_bytes(previous_input_bytes)
    ctx.bind([path,input_snapshot,script,run/'run-header.json'])
    # Charge the interrupted attempt's wall time, including its unknown tail,
    # against the original whole-construction allowance.
    spent=_failed_construction_spent(ctx.root,run,progress.get('priorSpentSeconds',0))
    if source_changes:
        from gambit_smp.gerbil_build.bootstrap_inputs import _apply_source_update
        _apply_source_update(ctx,source,gerbil_checkout,origin_heads,heads,source_changes)
    phase_heads={phase:progress.get('retainedPhaseHeads',{}).get(phase,
        (progress.get('retainedCoreHeads') or origin_heads) if phase in progress.get('retainedPhases',[]) else origin_heads)
        for phase in accepted}
    progress = dict(progress, retainedPhases=accepted, priorSpentSeconds=spent,
                    completed={p:progress['completed'][p] for p in accepted},
                    products={p:progress['products'][p] for p in accepted if p in progress['products']},
                    retainedPhaseHeads=phase_heads,firstInvalidatedPhase=first_invalidated,
                    configuration=configuration, preparedFrom=str(run),sourceProfilePrepared=reference,
                    retainedCoreHeads=(progress.get('retainedCoreHeads') or origin_heads) if source_changes else progress.get('retainedCoreHeads'),
                    sourceUpdated=bool(source_changes),
                    stdlibRecoveryFrom=str(run) if not source_changes and progress.get('active')=='stdlib' else None)
    write(ctx.directory/'prepared-ci-phases.json',dict(source=str(source),phases=accepted,
        priorSpentSeconds=spent,unknownPhase=progress.get('active'),unknownOutputsAdmitted=False))
    return progress


