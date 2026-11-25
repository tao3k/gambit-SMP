"""Gerbil build: batches."""

from gambit_smp.framework import digest, relative, available_processors
import hashlib
import json
import time
from pathlib import Path
import shutil

from gambit_smp.gerbil_build.custody import _current
from gambit_smp.gerbil_build.policy import _batch_size


def _stage1_contract(text):
    """Check the selected build and finalization functions, not debug callers."""
    def body(name):
        header=name+' () {\n'
        if text.count(header)!=1:raise ValueError('official stage1 preparation/finalization contract drift')
        return text.split(header,1)[1].split('\n}\n',1)[0]
    build=body('build_stage1');finalize=body('finalize_stage1')
    calls=('"${GERBIL_STAGE0}/bin/boot-gxi" ./build/build1.ss',
           '"${GERBIL_STAGE0}/bin/boot-gxi" ./build/build-bach.ss')
    final=('cp -v gerbil/interactive/*.ss',
           '(cd "${target_bin}" && ln -sf gerbil gxi)',
           '(cd "${target_bin}" && ln -sf gerbil gxc)')
    if any(build.count(s)!=1 for s in calls) or any(s not in finalize for s in final):
        raise ValueError('official stage1 preparation/finalization contract drift')


def stage1_products(ctx, source, deadline):
    """Retire the real core frontend before consuming its official output.

    Bootstrap objects precede source expansion. The source driver supplies its
    public handoff API; the original build1 and build-bach programs still own
    module order, declarations, optimization and the executable link.
    """
    from gambit_smp.workspace import write
    source=Path(source)
    build=source/'build';bootstrap=source/'bootstrap';src=source/'src'
    _stage1_contract((src/'build.sh').read_text())
    if deadline<=time.monotonic():raise TimeoutError('stage1 construction allowance already spent')
    handoff=ctx.directory/'stage1-compilation-output.scm'
    saved=dict(ctx.env)
    commands=[]
    def run(name, argv):
        remaining=min(ctx.remaining(),deadline-time.monotonic())
        if remaining<=0:raise TimeoutError('stage1 handoff exhausted the construction deadline')
        ctx.require(name,argv,src,remaining)
        command=ctx.commands[-1]
        if any(command.get(k) is not True for k in ('parentReaped','processGroupQuiescent')):
            raise ValueError('stage1 owner has not retired: '+name)
        commands.append(command)
    try:
        _withdraw_stage1_outputs(ctx,source)
        ctx.env.update(GERBIL_HOME=str(bootstrap),GERBIL_STAGE0=str(bootstrap),
            GERBIL_SOURCE=str(src),GERBIL_BUILD_PREFIX=str(build),
            GERBIL_GSC=str(build/'bin/gsc'),GERBIL_GCC=str(ctx.tools['gcc']),GERBIL_LOADPATH=str(bootstrap/'lib'),
            GAMBOPT='~~bin='+str(build/'bin')+',~~lib='+str(build/'lib')+',~~include='+str(build/'include'),
            PATH=str(build/'bin')+':'+str(bootstrap/'bin')+':'+saved.get('PATH',''),
            LD_LIBRARY_PATH=str(build/'lib'),DYLD_LIBRARY_PATH=str(build/'lib'),
            DYLD_FALLBACK_LIBRARY_PATH=str(build/'lib'))
        (build/'lib/gerbil').mkdir(parents=True)
        (build/'lib/static').mkdir(parents=True)
        for name in ('builtin.ssxi.ss','builtin-inline-rules.ssxi.ss'):
            shutil.copy2(src/'gerbil'/name,build/'lib/gerbil'/name)
        run('gerbil-stage1-version',[bootstrap/'bin/gsi',src/'build/build-version.scm'])
        # Compile the new driver with the completed bootstrap. Evaluating its
        # source recursively evaluates the expander and breaks active imports.
        # Native loading below changes the driver procedures without rebuilding
        # the expander's live initialization graph.
        initialize=('(set-load-path! \'('+json.dumps(str(bootstrap/'lib'))+' '+json.dumps(str(src))+')) '
            '(import :gerbil/compiler) '
            '(eval \'(begin-foreign (include '+json.dumps(str(build/'lib/_gambit#.scm'))+'))) ')
        driver=ctx.directory/'stage1-source-driver';driver.mkdir()
        emit=(initialize+'(compile-module '+json.dumps(str(src/'gerbil/compiler/driver.ss'))+
            ' (list output-dir: '+json.dumps(str(driver))+
            ' invoke-gsc: #f keep-scm: #t optimize: #f debug: #f generate-ssxi: #t target: \'C))')
        run('gerbil-stage1-driver-frontend',[bootstrap/'bin/boot-gxi','-e',emit])
        runtime_source=driver/'gerbil/compiler/driver~0.scm'
        if not runtime_source.is_file() or runtime_source.is_symlink():
            raise ValueError('bootstrap did not emit the source driver runtime')
        runtime_object=runtime_source.with_suffix('.o1')
        run('gerbil-stage1-driver-native',[build/'bin/gsc','-o',runtime_object,
            '-e','(include "~~lib/_gambit#.scm")',runtime_source])
        if not runtime_object.is_file() or runtime_object.is_symlink():
            raise ValueError('source driver has no native runtime product')
        initialize+='(load '+json.dumps(str(runtime_object))+') '
        frontend=initialize+('(gxc#call-with-compilation-output '+json.dumps(str(handoff))+
            ' (lambda () (gx#import-module '+json.dumps(str(src/'build/build1.ss'))+' #t #t)))')
        run('gerbil-stage1-frontend',[bootstrap/'bin/boot-gxi','-e',frontend])
        if not handoff.is_file() or handoff.is_symlink():
            raise ValueError('stage1 frontend did not seal its official output')
        frontend_sha=digest(handoff)
        write(ctx.directory/'stage1-frontend-retired.json',dict(
            output=str(handoff),sha256=frontend_sha,command=commands[-1],
            nativeConsumptionStarted=False,compilerReady=False,packageReady=False))
        # Unqualified whole-module jobs reserve the native class exclusively;
        # this is independent of the caller's CPU-worker envelope. No queued
        # Scheme frontend or expansion context survives in this consumer.
        native=initialize+'(gxc#execute-compilation-output '+json.dumps(str(handoff))+' #f)'
        run('gerbil-stage1-native',[bootstrap/'bin/boot-gxi','-e',native])
        if digest(handoff)!=frontend_sha or not Path(str(handoff)+'.native/complete').is_file():
            raise ValueError('stage1 native consumption lacks its completion marker')
        # Boot initialization precedes every -e expression. Never expose target
        # interfaces to it until their native execution support is complete.
        ctx.env['GERBIL_LOADPATH']=str(build/'lib')
        run('gerbil-stage1',[bootstrap/'bin/boot-gxi',src/'build/build-bach.ss'])
        for path in (src/'gerbil/interactive').glob('*.ss'):
            shutil.copy2(path,build/'lib'/path.name)
        for name in ('gxi','gxc'):
            path=build/'bin'/name
            if path.exists() or path.is_symlink():raise ValueError('unexpected stage1 executable alias')
            path.symlink_to('gerbil')
        return dict(kind='retired-frontend-products',commands=commands,
            dependencies=[dict(command=c,receiptBytes=(ctx.directory/(c['stage']+'.process.json')).read_text())
                          for c in commands if c['stage'] not in ('gerbil-stage1-version','gerbil-stage1')],
            outputSha256=frontend_sha,frontendRetiredBeforeNative=True,
            nativeClass='exclusive-unqualified-unit',exit=0,timeout=False,
            parentReaped=True,processGroupQuiescent=True)
    finally:
        ctx.env.clear();ctx.env.update(saved)

def stdlib_products(ctx, source, deadline, *, prior=None):
    """Join the entire official stdlib frontend before native consumption.

    A nested make handoff leaves its importing build.ss process resident. The
    stage owner instead runs build-std's original specification and options in
    one disposable process, then consumes only the driver's scalar file output.
    Unknown whole-module jobs use the same exclusive class as stage1; the
    caller's CPU capacity and the runtime GC/SMP configuration are unchanged.
    """
    from gambit_smp.workspace import write
    source = Path(source)
    src, build = source/'src', source/'build'
    script = (src/'build.sh').read_text()
    header = 'build_stdlib () {\n'
    if (script.count(header) != 1 or
            script.split(header, 1)[1].split('\n}', 1)[0].strip() !=
            'feedback_low "Building stdlib"\n  (cd std && gxi ./build.ss) || die'):
        raise ValueError('official stdlib entry contract drift')
    entry = (src/'std/build-std.ss').read_text()
    if '(def (build . args)' not in entry or 'separate-compiler: #f' not in entry:
        raise ValueError('stdlib entry cannot delegate the outer phase owner')
    if source.resolve() not in ctx.leased_workspaces:
        raise ValueError('stdlib handoff requires the exclusive source lease')
    handoff = ctx.directory/'stdlib-compilation-output.scm'
    commands = []
    predecessor_receipts = []
    saved = dict(ctx.env)
    def run(name, expression):
        remaining = min(ctx.remaining(), deadline-time.monotonic())
        if remaining <= 0:
            raise TimeoutError('stdlib handoff exhausted the construction deadline')
        ctx.require(name, [source/'run.sh', 'gxi', '-e', expression], src/'std', remaining)
        command = ctx.commands[-1]
        if any(command.get(k) is not True for k in ('parentReaped', 'processGroupQuiescent')):
            raise ValueError('stdlib owner has not retired: '+name)
        commands.append(command)
    try:
        ctx.env.update(GERBIL_PATH=str(source/'ci-gerbil-path'),
            GERBIL_BUILD_AOT_TOOLS='yes')
        # run.sh owns its build-local runtime environment. The original build
        # program owns macro initialization, srcdir/libdir, debug and target.
        frontend = ('(import :gerbil/compiler) '
            '(call-with-compilation-output '+json.dumps(str(handoff))+
            ' (lambda () (load '+json.dumps(str(src/'std/build.ss'))+')))' )
        if prior is None:
            run('gerbil-stdlib-frontend', frontend)
            if not handoff.is_file() or handoff.is_symlink():
                raise ValueError('stdlib frontend did not seal its official output')
            sha = digest(handoff)
            write(ctx.directory/'stdlib-frontend-retired.json', dict(
                output=str(handoff), sha256=sha, command=commands[-1],
                nativeConsumptionStarted=False, compilerReady=False, packageReady=False))
            ctx.bind([handoff,ctx.directory/'stdlib-frontend-retired.json'])
            native = ('(import :gerbil/compiler) '
                '(execute-compilation-output '+json.dumps(str(handoff))+' #f)')
            run('gerbil-stdlib-native', native)
            predecessor_receipts=[dict(command=c,receiptBytes=(ctx.directory/(c['stage']+'.process.json')).read_text())
                                  for c in commands]
        else:
            from gambit_smp.reasoning_history import read_execution_checkpoint
            from gambit_smp.gerbil_build.custody import _completed_command
            from gambit_smp.artifact_storage import observation_root
            prior=Path(prior).resolve(strict=True)
            observation_root(ctx.root,prior)
            records=read_execution_checkpoint(ctx.root,prior)['records']
            steps=[r['payload']['step'] for r in records
                   if r['payload'].get('schema')=='research-step-observation.v1'
                   and r['payload']['step']['id']=='compiler']
            if len(steps)!=1 or steps[0].get('outcome')!='DENY':
                raise ValueError('stdlib recovery requires its known failed collector')
            for stage in ('gerbil-stdlib-frontend','gerbil-stdlib-native'):
                matches=[c for c in steps[0]['commands'] if c['stage']==stage]
                path=prior/'run/compiler'/(stage+'.process.json')
                if len(matches)!=1 or not path.is_file():
                    raise ValueError('stdlib recovery lacks an attested actual command')
                raw=path.read_text();receipt=json.loads(raw)
                if not _completed_command(receipt,matches[0]):
                    raise ValueError('stdlib recovery command is unknown or incomplete')
                predecessor_receipts.append(dict(command=matches[0],receiptBytes=raw))
                ctx.bind([path])
            retired=prior/'run/compiler/stdlib-frontend-retired.json'
            state=json.loads(retired.read_text())
            handoff=prior/'run/compiler/stdlib-compilation-output.scm'
            sha=state['sha256']
            if state['command']!=predecessor_receipts[0]['command'] or digest(handoff)!=sha:
                raise ValueError('stdlib recovery handoff or producer differs')
            ctx.bind([handoff,retired,prior/'run-header.json'])
        marker=Path(str(handoff)+'.native/complete')
        if digest(handoff)!=sha or not marker.is_file() or marker.is_symlink():
            raise ValueError('stdlib native consumption lacks its unchanged completion marker')
        from datetime import datetime
        start=datetime.fromisoformat(predecessor_receipts[1]['command']['startedAt']).timestamp()
        end=datetime.fromisoformat(predecessor_receipts[1]['command']['endedAt']).timestamp()
        # A real terminal consumer validates the official handoff and the current
        # output image. Recovered bytes receive a new snapshot, never a forged
        # historical byte hash. The private-workspace/no-forged-mtime assumption
        # is the same as read-compilation-output's documented trust boundary.
        verify=('(import :gerbil/compiler) (let* ((data (read-compilation-output '+json.dumps(str(handoff))+')) '
            '(jobs (cdr (caddr data))) (done (call-with-input-file '+json.dumps(str(marker))+' read))) '
            '(unless (equal? done (list \'native-compilation-complete (length jobs))) '
            '(error "Native completion count differs")) '
            '(for-each (lambda (job) (let* ((input (list-ref job 2)) (args (list-ref job 4)) '
            '(target (string-append (path-strip-extension input) ".o1")) '
            '(info (file-info target #f)) (stamp (time->seconds (file-info-last-modification-time info)))) '
            '(unless (and (not (member "-o" args)) (not (member "-c" args)) '
            '(eq? (file-info-type info) \'regular) (> (file-info-size info) 0) '
            '(<= '+str(start-0.01)+' stamp '+str(end+0.01)+')) '
            '(error "Native output identity or interval differs" target)))) jobs) '
            '(displayln "STDLIB-CURRENT-OUTPUT-IMAGE-PASS"))')
        remaining=min(ctx.remaining(),deadline-time.monotonic())
        negative=verify.replace('".o1"','".missing-native-output"')
        if negative==verify:raise ValueError('stdlib missing-output control was not constructed')
        code,text,timeout,_=ctx.run('stdlib-output-missing-control',
            [source/'run.sh','gxi','-e',negative],src/'std',min(60,remaining))
        control=ctx.commands[-1]
        if (code!=70 or timeout or '.missing-native-output' not in text
                or any(control.get(k) is not True for k in ('parentReaped','processGroupQuiescent'))):
            raise ValueError('stdlib missing-output negative control failed')
        control.update(expectedExit=70,negativeControl=True)
        run('gerbil-stdlib',verify)
        if 'STDLIB-CURRENT-OUTPUT-IMAGE-PASS' not in ctx.last_stdout.splitlines():
            raise ValueError('stdlib terminal verification marker missing')
        ctx.bind([marker,handoff])
        return dict(kind='retired-frontend-products', commands=commands,
            dependencies=predecessor_receipts, outputSha256=sha,
            recoveredFrom=str(prior) if prior else None, historicalByteCustodyProved=False,
            frontendRetiredBeforeNative=True, nativeClass='exclusive-unqualified-unit',
            exit=0, timeout=False, parentReaped=True, processGroupQuiescent=True)
    finally:
        ctx.env.clear()
        ctx.env.update(saved)


def _withdraw_stage1_outputs(ctx, source):
    """Unpublished core outputs must not shadow the completed bootstrap.

    build.sh puts build/lib first in GERBIL_LOADPATH. A failed stage1 can
    leave .ssi/.scm files there before their queued native jobs have run.
    Move those owned outputs out of lookup, retaining their actual bytes in
    this attempt's evidence directory. This is an inode move, not a new source
    checkout, and is called only after the owned workspace is leased.
    """
    from gambit_smp.workspace import write
    targets = ['build/lib/gerbil', 'build/lib/static',
               'build/bin/gerbil', 'build/bin/gxi', 'build/bin/gxc']
    retained = ctx.directory / 'unpublished-stage1'
    moved = []
    for name in targets:
        path = source / name
        if not path.exists() and not path.is_symlink():
            continue
        destination = retained / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() or destination.is_symlink():
            raise ValueError('unpublished stage1 custody already exists: ' + name)
        path.rename(destination)
        moved.append(name)
    write(ctx.directory / 'stage1-output-withdrawal.json', dict(
        schema='gerbil.unpublished-stage1-custody.v1', moved=moved,
        completedBootstrapPreserved=True, sourceCopies=0,
        reason='Unqualified frontend files must not shadow completed bootstrap modules',
        runtimeAdmitted=False))


def stdlib_batch_prefixes(graph, size, completed=()):
    """Complete graph validation precedes execution; every prefix is closed."""
    _batch_size(size)
    if size is None or not isinstance(graph, list) or not graph:
        raise ValueError('a nonempty compiler build graph and batch size are required')
    for row in graph:
        if (not isinstance(row, list) or any(type(i) is not int or not 0 <= i < len(graph) for i in row)
                or len(set(row)) != len(row)):
            raise ValueError('invalid compiler dependency ordinal')
    ordered, visited = [], set()
    while len(visited) < len(graph):
        ready = [i for i, deps in enumerate(graph) if i not in visited and set(deps) <= visited]
        if not ready:
            raise ValueError('compiler build dependency cycle')
        visited.add(ready[0])
        ordered.append(ready[0])
    if (any(type(i) is not int or not 0 <= i < len(graph) for i in completed)
            or len(set(completed)) != len(completed)):
        raise ValueError('invalid completed compiler prefix')
    sealed = set(completed)
    if any(not set(graph[i]) <= sealed for i in sealed):
        raise ValueError('completed compiler prefix is not dependency closed')
    remaining = [i for i in ordered if i not in sealed]
    prefixes = []
    for offset in range(0, len(remaining), size):
        sealed.update(remaining[offset:offset+size])
        prefixes.append(sorted(sealed))
    return prefixes


def _stdlib_outputs(source):
    """Only owned library artifacts, never a restored native runtime."""
    paths = list((source/'build/lib/std').rglob('*'))
    paths.extend((source/'build/lib/static').glob('std__*'))
    outputs = {}
    for path in paths:
        if path.is_symlink():
            raise ValueError('stdlib artifacts cannot contain aliases')
        if path.is_file():
            outputs[path.relative_to(source).as_posix()] = digest(path)
    return outputs


def _withdraw_stdlib_batch(ctx, source, previous):
    """Unknown work stays retained. A changed sealed prefix is never reused."""
    outputs = _stdlib_outputs(source)
    if any(outputs.get(name) != sha for name, sha in previous.items()):
        raise ValueError('sealed stdlib prefix changed; retained workspace requires reconciliation')
    moved = []
    for name in outputs.keys() - previous.keys():
        path, target = source/name, ctx.directory/'unpublished-stdlib-batch'/name
        target.parent.mkdir(parents=True, exist_ok=True)
        path.rename(target)
        moved.append(name)
    from gambit_smp.workspace import write
    write(ctx.directory/'stdlib-batch-withdrawal.json', dict(
        moved=sorted(moved), sealedPrefixPreserved=True, runtimeAdmitted=False))


def _stdlib_stage(selected):
    return 'stdlib-batch-'+hashlib.sha256(json.dumps(selected).encode()).hexdigest()[:16]


def restore_withdrawn_stdlib(ctx, source, prior):
    """Reverse a stopped attempt's inode moves, without granting reuse.

    The next preparation must still authenticate every complete module and
    its dependency closure. Conflicting new outputs stay in this attempt's
    custody; no saved compiler input is copied or synthesized.
    """
    from pathlib import Path
    from gambit_smp.workspace import write
    source, prior = Path(source).resolve(), Path(prior).resolve()
    if source not in ctx.leased_workspaces:
        raise ValueError('withdrawal restoration requires the exclusive source lease')
    if prior.parent != ctx.directory.resolve().parent or prior == ctx.directory.resolve():
        raise ValueError('withdrawal must belong to another attempt in the same run store')
    result = json.loads((prior/'result.json').read_text())
    commands = [c for c in result['commands'] if c['stage'] == 'gerbil-stdlib']
    if (result.get('complete') is not False or len(commands) != 1
            or commands[0].get('parentReaped') is not True
            or commands[0].get('processGroupQuiescent') is not True):
        raise ValueError('withdrawal restoration requires a stopped quiescent producer')
    names = json.loads((prior/'stdlib-batch-withdrawal.json').read_text())['moved']
    if len(names) != len(set(names)):
        raise ValueError('duplicate withdrawal entries')
    paths = []
    for name in names:
        if (not name.startswith(('build/lib/std/', 'build/lib/static/std__'))
                or '..' in Path(name).parts or Path(name).is_absolute()):
            raise ValueError('withdrawal is outside stdlib products')
        retained, target = prior/'unpublished-stdlib-batch'/name, source/name
        if (retained.is_symlink() or not retained.is_file()
                or retained.stat().st_nlink != 1 or target.is_symlink()
                or retained.resolve() != retained or target.resolve() != target):
            raise ValueError('withdrawn product is missing or aliased')
        paths.append((name, retained, target))
    restored = []
    for name, retained, target in paths:
        stamp = retained.stat()
        if target.exists():
            conflict = ctx.directory/'superseded-stdlib'/name
            conflict.parent.mkdir(parents=True, exist_ok=True)
            if conflict.exists():raise ValueError('conflicting custody already exists')
            target.rename(conflict)
        target.parent.mkdir(parents=True, exist_ok=True)
        retained.rename(target)
        restored.append(dict(path=name, sha256=digest(target), inode=stamp.st_ino,
                             device=stamp.st_dev))
    write(ctx.directory/'stdlib-withdrawal-restoration.json', dict(
        restored=restored, reuseAdmitted=False, sourceCopies=0,
        requires='fresh exact-context module/native admission before Make'))
    return len(restored)


def _stdlib_checkpoint_current(source, previous, inputs, root):
    # Bind the completion claim to the actual process's immutable selection.
    # A genuine smaller-batch receipt cannot settle a larger declared prefix.
    return bool(previous and previous.get('inputsSha256') == inputs
        and previous.get('stage') == _stdlib_stage(previous.get('completed'))
        and _current(source, previous.get('proof'), inputs,
                     stage=previous.get('stage'), root=root))


def _stdlib_batches(ctx, work, source, parent, size, *, stage_budget_seconds=600):
    """Use the existing make/drain boundary, not stdout or partial files."""
    from gambit_smp.workspace import write
    deadline = time.monotonic() + min(stage_budget_seconds, ctx.remaining())
    def remaining():
        value = min(ctx.remaining(), deadline - time.monotonic())
        if value <= 0:
            raise TimeoutError('Gerbil stdlib stage budget exhausted')
        return value
    if source.resolve() not in ctx.leased_workspaces:
        raise ValueError('compiler batches require the current exclusive source lease')
    if ('(def (make-build-batch ' not in (source/'src/std/make.ss').read_text()
            or 'GERBIL_BUILD_PLAN' not in (source/'src/std/build-std.ss').read_text()):
        raise ValueError('source compiler does not provide the staged build contract')
    def source_inputs():
        return {p.relative_to(source).as_posix(): digest(p)
                for p in (source/'src').rglob('*') if p.is_file()}
    sources = source_inputs()
    environment = {key:value for key,value in ctx.env.items() if key in {
        'PATH', 'CC', 'CFLAGS', 'CPPFLAGS', 'LDFLAGS', 'SDKROOT', 'COMPILER_PATH',
        'CPATH', 'LIBRARY_PATH', 'LD_LIBRARY_PATH', 'DYLD_LIBRARY_PATH', 'DYLD_FALLBACK_LIBRARY_PATH'}
        or key.startswith(('GERBIL_', 'GAMBOPT', 'PKG_CONFIG'))}
    inputs = hashlib.sha256(json.dumps(dict(parent=parent, sources=sources,
        environment=environment, batchSize=size), sort_keys=True).encode()).hexdigest()
    store = work/'gerbil-stdlib-batches.json'
    previous = json.loads(store.read_text()) if store.is_file() else {}
    proof = previous.get('proof')
    if previous and not _stdlib_checkpoint_current(source, previous, inputs, ctx.root):
        raise ValueError('compiler batch checkpoint is missing or has changed inputs/artifacts')
    qualified = proof['outputs'] if proof else {}
    if _stdlib_outputs(source) != qualified:
        raise ValueError('unqualified stdlib artifacts must be reconciled before planning')
    saved = {key:ctx.env.get(key) for key in ('GERBIL_BUILD_PLAN', 'GERBIL_BUILD_SELECTION')}
    try:
        plan_path = ctx.directory/'stdlib-plan.json'
        ctx.env['GERBIL_BUILD_PLAN'] = str(plan_path)
        ctx.env.pop('GERBIL_BUILD_SELECTION', None)
        if previous:
            graph = previous['graph']
        else:
            ctx.require('gerbil-stdlib-plan', [ctx.tools['sh'], './build.sh', 'stdlib'],
                        source/'src', remaining())
            graph = json.loads(plan_path.read_text())
        completed = previous.get('completed', [])
        prefixes = stdlib_batch_prefixes(graph, size, completed)
        reused = len(completed)
        write(ctx.directory/'stdlib-batch-admission.json', dict(
            reusedNodes=reused, totalNodes=len(graph), remainingBatches=len(prefixes),
            completedProcessProofChecked=bool(proof), sourceInputsSha256=inputs,
            sourceRefinementAdmitted=False, fullCompilerComplete=False))
        for selected in prefixes:
            # Observed cost is a scheduling estimate, never a guaranteed bound.
            # Defer before launching another process rather than knowingly give
            # a whole planning pass only the final fragment of this deadline.
            if proof and remaining() < proof['command']['seconds']:
                write(ctx.directory/'stdlib-batch-deferred.json', dict(
                    completed=len(completed), total=len(graph),
                    remainingSeconds=remaining(),
                    previousBatchSeconds=proof['command']['seconds'],
                    nativeProcessStarted=False, fullCompilerComplete=False))
                raise TimeoutError('next compiler batch deferred; sealed prefix remains available')
            stage = _stdlib_stage(selected)
            selection = ctx.directory/(stage+'.selection.scm')
            with selection.open('x') as stream:
                stream.write('('+' '.join(map(str, selected))+')\n')
            ctx.bind([selection])
            ctx.env['GERBIL_BUILD_SELECTION'] = str(selection)
            batch_plan = ctx.directory/(stage+'.plan.json')
            ctx.env['GERBIL_BUILD_PLAN'] = str(batch_plan)
            cap = remaining()
            try:
                ctx.require('gerbil-'+stage, [ctx.tools['sh'], './build.sh', 'stdlib'],
                            source/'src', cap)
            except (TimeoutError, ValueError):
                command = ctx.commands[-1]
                if command.get('parentReaped') is True and command.get('processGroupQuiescent') is True:
                    _withdraw_stdlib_batch(ctx, source, qualified)
                raise
            if json.loads(batch_plan.read_text()) != graph or source_inputs() != sources:
                raise ValueError('compiler dependency plan/source changed during the batch')
            outputs = _stdlib_outputs(source)
            if not outputs or not any(name.endswith('.o1') for name in outputs):
                raise ValueError('compiler batch returned without native library artifacts')
            if any(outputs.get(name) != sha for name, sha in qualified.items()):
                raise ValueError('completed compiler batch changed its sealed dependency prefix')
            raw = (ctx.directory/('gerbil-'+stage+'.process.json')).read_text()
            command = ctx.commands[-1]
            proof = dict(inputsSha256=inputs, outputs=outputs, links={},
                modes={name:(source/name).stat().st_mode & 0o777 for name in outputs},
                command=command, receiptBytes=raw,
                receiptSha256=hashlib.sha256(raw.encode()).hexdigest())
            if not _current(source, proof, inputs, stage=stage, root=ctx.root):
                raise ValueError('compiler batch has no quiescent successful completion')
            completed, qualified = selected, outputs
            write(store, dict(inputsSha256=inputs, graph=graph, completed=completed,
                stage=stage, proof=proof, fullLibraryComplete=len(completed)==len(graph),
                runtimeAdmitted=False, sourceRefinementAdmitted=False))
        return dict(nodes=len(graph), reused=reused, completed=len(completed),
                    batchSize=size, fullLibraryComplete=True)
    finally:
        for key,value in saved.items():
            if value is None:ctx.env.pop(key, None)
            else:ctx.env[key]=value


def component_source_view(parent, view):
    """Assemble closed runtime products and sources, not a compiler checkout."""
    from gambit_smp.artifact_storage import clone_file
    parent, view = Path(parent).resolve(strict=True), Path(view)
    if view.exists():
        raise ValueError('component source view must be fresh')
    counts={"copy-on-write":0,"byte-copy":0}
    def copy(source, destination, source_root, target_root):
        if source.is_symlink():
            resolved=source.resolve(strict=True)
            if resolved.is_relative_to(source_root):
                relative=resolved.relative_to(source_root)
                excluded=(source_root.name=='build' and relative.parts[:1]==('src',)
                          or source_root.name=='src' and relative.parts[:1]==('gambit',)
                          or source_root==parent and relative.parts[:1] in (('.git',),('bootstrap',)))
                if not excluded:
                    destination.symlink_to(target_root/relative,target_is_directory=resolved.is_dir())
                    return
            copy(resolved,destination,source_root,target_root)
        elif source.is_dir():
            destination.mkdir()
            for child in source.iterdir():copy(child,destination/child.name,source_root,target_root)
        else:
            counts[clone_file(source,destination)]+=1
    view.mkdir(parents=True)
    for item in parent.iterdir():
        target=view/item.name
        if item.name in {'.git','bootstrap'}:continue
        if item.name in {'src','build'}:
            target.mkdir()
            for child in item.iterdir():
                if item.name=='src' and child.name=='gambit':continue
                if item.name=='build' and child.name=='src':
                    (target/'src').mkdir()
                else:copy(child,target/child.name,item,target)
        elif item.is_file():copy(item,target,parent,view)
    return dict(mode='component-products',privateTransfers=counts,
                gambitCheckoutCopied=False,bootstrapCopied=False,gitCopied=False,
                claim='closed writable runtime prefix and Gerbil sources; no full source/compiler checkout')


def tools_products(ctx, home, view, proof, observed):
    """Build declared official tools and check a real unchanged consumer pass."""
    ctx.require('official-tools-shell-check',['/bin/sh','-n',view/'src/build.sh'],view,10)
    budget=proof['budgets']['build']
    ctx.require('official-tools-products',[home/'bin/gxi','./build.ss'],view/'src/tools',
                min(budget,ctx.remaining()))
    observed('nativeToolsBuild')
    products={name:home/'bin'/name for name in ('gxpkg','gxtags','gxtest')}
    if any(not p.is_file() or p.is_symlink() for p in products.values()):
        raise ValueError('declared native tool product missing or an alias')
    before={name:(digest(p),p.stat().st_mtime_ns) for name,p in products.items()}
    ctx.require('official-tools-no-change',[home/'bin/gxi','./build.ss'],view/'src/tools',
                min(budget,ctx.remaining()))
    observed('nativeToolsNoChange')
    if before!={name:(digest(p),p.stat().st_mtime_ns) for name,p in products.items()}:
        raise ValueError('no-change tools build replaced a native product')
    if '... compile exe ' in ctx.last_stdout:
        raise ValueError('no-change tools entry repeated executable compilation')
    return dict(nativeToolProducts={name:digest(p) for name,p in products.items()},
                packageManagerExecutablePath='bin/gxpkg',nativeToolNoChangePreserved=True)
