"""Gerbil build: stage0."""

from concurrent.futures import ThreadPoolExecutor, as_completed
from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import shutil
import time

from gambit_smp.gerbil_build.custody import _current, _module_input, _module_stage, _module_witnesses
from gambit_smp.gerbil_build.policy import _compiler_jobs

def _install_runtime(runtime, source):
    # Same payloads as upstream src/build.sh build_gambit; never invoke that
    # function's unconditional bootstrap/from-scratch a second time.
    copies = [('gsi/gsi', 'bootstrap/bin/gsi'), ('gsc/gsc', 'build/bin/gsc'),
              ('bin/gambuild-C', 'build/bin/gambuild-C')]
    for folder, pattern, target in (
        ('include', 'gambit*.h', 'build/include'),
        ('lib', '*#.scm', 'build/lib'),
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


def _compile_c_arguments(program, cfile, output):
    # CLI C operands are linker inputs. The documented compiler procedure
    # explicitly compiles a target-language file into a dynamic object.
    expression='(if (compile-file '+json.dumps(str(cfile),ensure_ascii=False)+' output: '+json.dumps(str(output),ensure_ascii=False)+') (void) (exit 1))'
    return [*program,'-e',expression]


def stage0_retirement_control(ctx, source, deadline):
    """Compare real GSC output and load both sides before admitting the split."""
    directory=ctx.directory/'stage0-retirement-control';directory.mkdir()
    saved=directory/'saved';saved.mkdir()
    unit=directory/'retirement.scm'
    unit.write_text('(define (retirement-answer) (call-with-current-continuation (lambda (k) (##gc) (k 42))))\n')
    program=[source/'build/bin/gsc','-:~~bin='+str(source/'build/bin')+',~~lib='+str(source/'build/lib')+',~~include='+str(source/'build/include')]
    output=directory/'retirement.o1';cfile=directory/'retirement.c'
    options=['-e','(include "~~lib/_gambit#.scm")']
    def budget():
        value=min(60,ctx.remaining(),deadline-time.monotonic())
        if value<=0:raise TimeoutError('stage0 control exhausted the construction deadline')
        return value
    ctx.require('stage0-direct-control',[*program,'-keep-temp','-o',output,*options,unit],source/'src',budget())
    expected=digest(cfile)
    output.rename(saved/output.name)
    ctx.require('stage0-frontend-control',[*program,'-c','-o',cfile,
        '-module-ref',output.stem,'-linker-name',output.name,*options,unit],source/'src',budget())
    if digest(cfile)!=expected:raise ValueError('GSC split changed generated C bytes')
    ctx.require('stage0-native-control',_compile_c_arguments(program,cfile,output),source/'src',budget())
    if not output.is_file() or output.is_symlink():raise ValueError('GSC native control did not produce its object')
    for name,item in (('direct',saved/output.name),('split',output)):
        expression='(load '+json.dumps(str(item))+') (if (= (retirement-answer) 42) (display "RETIREMENT-OK") (exit 1))'
        ctx.require('stage0-load-'+name,[source/'bootstrap/bin/gsi','-f','-e',expression],source/'src',budget())
        if 'RETIREMENT-OK' not in ctx.last_stdout:raise ValueError('GSC split consumer missing')
    return dict(generatedCEqual=True,consumersPassed=True,packageReady=False)


def _stage0_modules(ctx, work, source, parent, *, stage_budget_seconds=600, retire_frontend=False):
    """Compile through actual GSC processes; retain completed modules individually."""
    from gambit_smp.workspace import write
    from gambit_smp.artifact_storage import clone_file
    deadline = time.monotonic() + min(stage_budget_seconds, ctx.remaining())
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
    previous_plan = json.loads(plan_path.read_text()) if plan_path.is_file() else {}
    def copy_current(origin, target):
        if origin.is_symlink():raise ValueError('bootstrap input aliases are unsupported')
        if target.is_symlink():raise ValueError('bootstrap output aliases are unsupported')
        if target.exists():
            if (target.is_file() and digest(origin) == digest(target)
                    and origin.stat().st_mode & 0o777 == target.stat().st_mode & 0o777):return
            prior = previous_plan.get('inputs',{}).get(origin.relative_to(source).as_posix(),{})
            if (not target.is_file() or digest(target) != prior.get('sha256')
                    or target.stat().st_mode & 0o777 != prior.get('mode')):
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
    # Copy-plan completion is independent of the compiler action context. Keep
    # the previous plan until every input replacement finishes; an interrupted
    # replacement may then match either the new source or the witnessed old
    # target, never arbitrary drift. No Scheme code consumes these boot files
    # before the completed stage0 proof is published.
    for origin in (source/'src/gerbil/boot').glob('*.scm'):
        copy_current(origin,source/'bootstrap/lib'/origin.name)
    copy_current(source/'src/gerbil/boot-gxi',source/'bootstrap/bin/boot-gxi')
    write(plan_path,plan)
    flags = ('' if retire_frontend else 'p1,')+'~~bin='+str(source/'build/bin')+',~~lib='+str(source/'build/lib')+',~~include='+str(source/'build/include')
    argv0 = [source/'build/bin/gsc', '-:'+flags]
    count = ctx.require('gerbil-stage0-processors', [*argv0, '-e', '(write (##current-vm-processor-count))'],
                        source/'src', min(10,ctx.remaining())).strip()
    if count != '1':raise ValueError('actual bootstrap compiler processor budget differs')
    pending = []
    for origin in module_files:
        name = origin.relative_to(originals).as_posix()
        target = target_root/name
        inputs = _module_input(parent,name,origin)
        stage = _module_stage(name)
        previous = retained.get(name,{})
        if _current(source,previous,inputs,stage=stage,root=ctx.root,witnesses=witnesses):
            entries[name] = previous
            continue
        pending.append((origin,name,inputs,stage))
    # Each bootstrap GSC uses one Scheme processor and can invoke one native
    # compiler. The worker budget is not a quota on OS threads created by tools.
    jobs = min(len(pending), _compiler_jobs(ctx.env))
    generated={}
    if retire_frontend and pending:
        control=stage0_retirement_control(ctx,source,deadline)
        def emit(item):
            origin,name,inputs,stage=item
            target=target_root/name;output=target.with_suffix('.o1');cfile=target.with_suffix('.c')
            if cfile.is_symlink() or (cfile.exists() and (not cfile.is_file() or cfile.stat().st_nlink!=1)):
                raise ValueError('stage0 generated C has an unowned alias')
            if output.exists():
                retired=ctx.directory/'retired-stage0'/name
                retired=retired.with_suffix('.o1');retired.parent.mkdir(parents=True,exist_ok=True)
                output.rename(retired)
            remaining=min(ctx.remaining(),deadline-time.monotonic())
            if remaining<=0:raise TimeoutError('stage0 generation budget exhausted')
            ctx.require('gerbil-'+stage+'-frontend',
                [*argv0,'-c','-o',cfile,'-module-ref',output.stem,'-linker-name',output.name,
                 '-e','(include "~~lib/_gambit#.scm")',target],source/'src',remaining)
            command=next(row for row in ctx.commands if row['stage']=='gerbil-'+stage+'-frontend')
            if any(command.get(k) is not True for k in ('parentReaped','processGroupQuiescent')):
                raise ValueError('stage0 frontend has not retired')
            return name,dict(path=cfile,sha256=digest(cfile),command=command)
        failure=None
        with ThreadPoolExecutor(max_workers=jobs) as pool:
            futures=[pool.submit(emit,item) for item in pending]
            for future in as_completed(futures):
                try:
                    name,row=future.result();generated[name]=row
                except Exception as error:
                    if failure is None:failure=error
        if failure is not None:raise failure
        if len(generated)!=len(pending):raise ValueError('stage0 frontend barrier is incomplete')
    def compile_module(item):
        origin,name,inputs,stage = item
        target = target_root/name
        # A STARTED record exists before GSC overwrites any unproved partial .o1.
        output = target.with_suffix('.o1')
        remaining = min(ctx.remaining(), deadline - time.monotonic())
        if remaining <= 0:
            raise TimeoutError('Gerbil stage0 budget exhausted before module launch')
        if retire_frontend:
            row=generated[name]
            if digest(row['path'])!=row['sha256']:raise ValueError('stage0 generated C changed before native consumption')
            arguments=_compile_c_arguments(argv0,row['path'],output)
        else:
            arguments=[*argv0,'-o',output,'-e','(include "~~lib/_gambit#.scm")',target]
        code,log,timeout,_ = ctx.run('gerbil-'+stage,arguments,source/'src',remaining)
        if timeout:raise TimeoutError('gerbil-'+stage+' timed out')
        if code != 0:raise ValueError('gerbil-'+stage+' failed with exit '+str(code))
        if _module_input(parent,name,origin) != inputs or digest(target) != digest(origin):
            raise ValueError('bootstrap module input changed during actual compilation')
        # A sibling may finish between run() and this check. Never borrow the
        # shared last command/stdout as this module's completion authority.
        command = next(row for row in ctx.commands if row['stage'] == 'gerbil-'+stage)
        if (command.get('parentReaped') is not True or command.get('processGroupQuiescent') is not True
                or not output.is_file() or output.is_symlink()):
            raise ValueError('bootstrap module has no completed process/output proof: '+name)
        raw = (ctx.directory/('gerbil-'+stage+'.process.json')).read_text()
        relative_name = output.relative_to(source).as_posix()
        proof = dict(inputsSha256=inputs,outputs={relative_name:digest(output)},
            modes={relative_name:output.stat().st_mode & 0o777},links={},command=command,
            receiptBytes=raw,receiptSha256=hashlib.sha256(raw.encode()).hexdigest())
        if retire_frontend:
            row=generated[name];relative_c=row['path'].relative_to(source).as_posix()
            proof['outputs'][relative_c]=row['sha256']
            proof['modes'][relative_c]=row['path'].stat().st_mode & 0o777
            proof['frontendCommand']=row['command']
        return name,stage,proof
    def retain_completed(name,stage,proof):
        from gambit_smp.research_kernel import retain_run_record
        header = json.loads(Path(journal['path']).read_text())
        payload = dict(schema='gerbil-bootstrap-module-observation.v1',header=journal,
            runId=header['runId'],moduleProof=proof,runtimeAdmitted=False)
        reference = retain_run_record(ctx.root,ctx.directory/(stage+'.completed.json'),journal['scope'],payload,header['inputs'])
        proof.update(completion=reference,completionRun=str(Path(journal['path']).parent))
        entries[name] = proof
        retained[name] = proof
        write(store,retained)
    if pending:
        # Serialize publication while preserving every completed sibling even
        # when another module fails. Queued work still uses the original whole
        # stage deadline; a partial object never acquires a completion witness.
        failure = None
        with ThreadPoolExecutor(max_workers=1 if retire_frontend else jobs) as pool:
            futures = [pool.submit(compile_module,item) for item in pending]
            for future in as_completed(futures):
                try:retain_completed(*future.result())
                except Exception as error:
                    if failure is None:failure = error
        if failure is not None:raise failure
    marker=source/'src/.build.stage0'
    if retire_frontend and marker.is_file():marker.unlink()
    return entries,dict(modules=len(module_files),reused=len(module_files)-len(pending),
                        compiled=len(pending),jobs=jobs,compilerProcessors=1,
                        frontendRetiredBeforeNative=retire_frontend,
                        unqualifiedNativeLane='exclusive' if retire_frontend else None,
                        schedulingEnvelope=2*jobs+1 if jobs else 1)
