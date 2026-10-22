#!/usr/bin/env python3
"""Bounded original-fixture phase timings, diagnostic only, never suite admission."""
import argparse
import json
from pathlib import Path
import shutil
import time

from gambit_smp.bootstrap_runtime import compiler_binding
from gambit_smp.framework import available_processors, digest, execute, gnu_compiler, gnu_build_driver
from gambit_smp.native_suite import runtime_view, selected_files
from gambit_smp.runtime_identity import check


from gambit_smp.compiler_phase_primitives import EXECUTION_WITNESS, LOAD_PROBE, stage_accepted, phase_commands

ORIGINAL_NUMERIC_SHA = '35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158'
ORIGINAL_HEADER_SHA = 'bb224f027872315cac11d516cdca45b28446bdc626013a366f4839c1e7a8a41b'


def original_numeric_workspace(root, gcc):
    from gambit_smp import workspace as w
    return w.build_output(root, 'gambit-core', compiler=gcc,
        flags=['original-numeric-discrimination-v1', ORIGINAL_NUMERIC_SHA, ORIGINAL_HEADER_SHA])


def recover_original_numeric(root, out, *, failed_unbuffered_generation=None):
    """Prefer an authenticated task source checkpoint, otherwise rebuild C only.

    One stable registered product holds both host configurations. This reuses
    the retained generator and libraries; it does not bootstrap or clone Gambit.
    A byte mismatch is a retained failed reconstruction, never an experiment input.
    """
    from gambit_smp import workspace as w
    from gambit_smp.artifact_storage import workspace_lease
    from gambit_smp.recipes import tree_identity
    from gambit_smp.source_identity import retain_sources, read_source
    from gambit_smp.reasoning_history import read_execution_checkpoint
    from gambit_smp.compiler_phase_primitives import suite_phase_commands, numeric_generation_runtime_options
    import os
    root = Path(root).resolve(); out = Path(out); out.mkdir(parents=True, exist_ok=True)
    producer = root/'.cache/current-mutex-return-incremental-02/candidate-runtime'
    gcc = Path(json.loads((root/'evidence/source-results/model-first-followthrough/real-graph-cold-r8-03/numeric/retained-full-graph/argv.json').read_text())[0])
    build = original_numeric_workspace(root, gcc)
    source = build/'source'; source.mkdir(exist_ok=True)
    target = source/'tests/unit-tests/03-number/_num.c'
    recovery = build/'recovery.json'
    if recovery.exists():
        old = json.loads(recovery.read_text())
        retained = read_source(root, old['sourceIdentity'])
        import hashlib
        if hashlib.sha256(retained).hexdigest() != ORIGINAL_NUMERIC_SHA:
            raise ValueError('original numeric checkpoint drift')
        with workspace_lease(root, source, tree_identity(source)):
            if not target.exists():
                staged=out/'inputs'; staged.mkdir(exist_ok=True)
                for name,ref in old['plan']['inputIdentities'].items():
                    p=staged/name; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(read_source(root,ref))
                w.sync_build_source(root,build,staged,mutable=['tests/unit-tests/03-number/_num.c'])
                w.checkpoint_build_source(source,phase='building')
                target.write_bytes(retained)
                w.checkpoint_build_source(source,phase='ready',diagnostic='original-c-restored-from-checkpoint')
            if not target.is_file() or digest(target) != ORIGINAL_NUMERIC_SHA:
                raise ValueError('recovered original numeric C drift')
            if retained != target.read_bytes():
                raise ValueError('original numeric checkpoint bytes changed')
        return dict(old, reused=True)
    checkpoints = []
    task = root/'.cache/tasks/repair-9-12'
    for pattern in ('processes/*/runs/*/outputs/source-identities/'+ORIGINAL_NUMERIC_SHA+'/record.json',
                    'runs/*/outputs/source-identities/'+ORIGINAL_NUMERIC_SHA+'/record.json'):
        checkpoints.extend(task.glob(pattern))
    restored = None; source_ref = None
    for record in sorted(checkpoints):
        prefix = read_execution_checkpoint(root, record.parent)
        ref = dict(kind='task-checkpoint', run=str(record.parent.relative_to(root)),
                   identity=prefix['prefixIdentity'], sha256=ORIGINAL_NUMERIC_SHA)
        restored = read_source(root, ref); source_ref = ref
        break
    relative = ['tests/unit-tests/03-number/_num.scm', 'tests/unit-tests/03-number/#.scm',
                'tests/unit-tests/#.scm', 'include/gambit.h']
    inputs = {name: (producer/name).read_bytes() for name in relative}
    if digest(producer/relative[0]) != 'b757a18805a38f48e55055907a983d53f0e50d1acb627c462fe6d34924bd0d9d':
        raise ValueError('original numeric Scheme fixture drift')
    if digest(producer/'include/gambit.h') != ORIGINAL_HEADER_SHA:
        raise ValueError('original numeric header drift')
    staged = out/'inputs'; staged.mkdir(exist_ok=True)
    for name, data in inputs.items():
        p = staged/name; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(data)
    input_refs = retain_sources(root, inputs)
    gsc = producer/'gsc/gsc'
    plan = dict(schema='original-numeric-recovery-plan.v1', expectedSha256=ORIGINAL_NUMERIC_SHA,
        sourceCheckpointsFound=len(checkpoints), inputIdentities=input_refs,
        generator=str(gsc.relative_to(root)), generatorSha256=digest(gsc),
        producerReceiptSha256=digest(producer.parent/'receipt.json'),
        scope='Scheme-to-C only, original module/linker naming, no native compiler', budgetSeconds=60,
        fileIoPolicy='file-settings=lf; console remains io-settings=lu; original C SHA required')
    if failed_unbuffered_generation is not None:
        failure = json.loads(Path(failed_unbuffered_generation).read_text())
        if not failure['timeout'] or failure['matched'] or failure['actualSha256'] == ORIGINAL_NUMERIC_SHA:
            raise ValueError('explicit incomplete unbuffered reconstruction required')
        plan.update(changedControl='file-settings=lf overrides io-settings=lu for files only; identical C SHA required',
                    priorFailureSha256=digest(failed_unbuffered_generation))
    w.write(out/'plan.json', plan)
    with workspace_lease(root, source, tree_identity(source)):
        w.sync_build_source(root, build, staged, mutable=['tests/unit-tests/03-number/_num.c'])
        w.checkpoint_build_source(source, phase='building')
        if restored is not None:
            target.write_bytes(restored)
            observed = dict(origin='authenticated-task-checkpoint', compilerStarted=False)
        else:
            if target.exists():
                if failed_unbuffered_generation is None or digest(target) != failure['actualSha256']:
                    raise ValueError('unreceipted generated C; inspect before repeating generation')
                partial = retain_sources(root, {'incomplete-unbuffered-c': target.read_bytes()})
                w.write(out/'prior-partial-source.json', partial)
                target.unlink()
            _, _, options, _ = suite_phase_commands('03-number/_num.scm', source/'tests')[0]
            runtime_options = numeric_generation_runtime_options(producer)
            argv = [str(gsc), runtime_options, *options[1:]]
            meta = {}; env = dict(os.environ)
            code, log, timed_out, seconds = execute(argv, source/'tests', 60, env, meta)
            (out/'generation.log').write_text(log)
            observed = dict(origin='retained-generator-chain', argv=argv, exit=code, timeout=timed_out, seconds=seconds, process=meta)
        observed['actualSha256'] = digest(target) if target.is_file() else None
        observed['actualBytes'] = target.stat().st_size if target.is_file() else None
        observed['matched'] = observed['actualSha256'] == ORIGINAL_NUMERIC_SHA
        w.write(out/'generation-result.json', observed)
        if not observed['matched'] or (restored is None and (code != 0 or timed_out)):
            w.checkpoint_build_source(source, phase='ready', diagnostic='numeric-reconstruction-mismatch')
            raise ValueError('original numeric reconstruction did not match retained SHA')
        source_ref = source_ref or retain_sources(root, {'original-generated-c': target.read_bytes()})['original-generated-c']
        w.checkpoint_build_source(source, phase='ready', diagnostic='original-generated-c-authenticated')
    value = dict(schema='original-numeric-recovery.v1', workspace=str(build.relative_to(root)),
        generatedC=str(target.relative_to(root)), sourceIdentity=source_ref, expectedSha256=ORIGINAL_NUMERIC_SHA,
        plan=plan, observation=observed, reused=False, nativeAdmitted=False)
    w.write(recovery, value); w.write(out/'receipt.json', value)
    return value


def original_host_experiment(root, out, mode):
    """One instrumented original-C control, once per authenticated configuration.

    Failed/partial rows are reusable observations, never automatically retried.
    Both configurations share recovered source and a single leased build product.
    """
    from gambit_smp import workspace as w
    from gambit_smp.artifact_storage import workspace_lease
    from gambit_smp.recipes import tree_identity
    from gambit_smp.source_identity import read_source
    from gambit_smp.compiler_phase_primitives import alias_detail_census, retained_ir_representation, cfg_representation_census
    import hashlib
    if mode not in ('single', 'multiple', 'single-shared-jump'):
        raise ValueError('explicit original host configuration required')
    root=Path(root).resolve(); out=Path(out); out.mkdir(parents=True,exist_ok=True)
    recovered=recover_original_numeric(root,out/'recovery-reuse')
    build=root/recovered['workspace']; source=build/'source'
    history=root/'evidence/source-results/model-first-followthrough/real-graph-cold-r8-03/numeric/retained-full-graph/argv.json'
    old=json.loads(history.read_text()); gcc=Path(old[0]).resolve(strict=True)
    compiler,environment,version=gnu_compiler(gcc)
    flags=old[old.index('-O1'):-1]
    flags=[('-I'+str(source/'include')) if x.startswith('-I') else x for x in flags]
    if flags.count('-D___SINGLE_HOST')!=1:
        raise ValueError('original single-host configuration missing')
    if mode=='multiple':
        flags=[x.replace('-D___SINGLE_HOST','-D___MULTIPLE_HOSTS') for x in flags]
    elif mode=='single-shared-jump':
        if flags.count('-D___INLINE_JUMPS')!=1: raise ValueError('original inline-jump configuration missing')
        flags=[x.replace('-D___INLINE_JUMPS','-D___DONT_INLINE_JUMPS') for x in flags]
    directory=build/'experiments'/mode; directory.mkdir(parents=True,exist_ok=True)
    argv=[str(compiler),'-bundle','-o','_test.o1',*flags,
          '-fdump-tree-ealias-details','-fdump-tree-alias-details',
          '-fdump-tree-cfg','-fdump-tree-ssa','-ftime-report','-dumpdir','./',
          str(root/recovered['generatedC'])]
    identity=dict(source=ORIGINAL_NUMERIC_SHA,header=ORIGINAL_HEADER_SHA,compiler=digest(gcc),
                  argv=argv,budgetSeconds=60,experiment='original-numeric-host-v1')
    def file_identity(p):
        with p.open('rb') as f:
            return hashlib.file_digest(f,'sha256').hexdigest()
    with workspace_lease(root,source,tree_identity(source)):
        if digest(root/recovered['generatedC'])!=ORIGINAL_NUMERIC_SHA or digest(source/'include/gambit.h')!=ORIGINAL_HEADER_SHA:
            raise ValueError('original C/header changed before experiment')
        cached=directory/'receipt.json'
        if cached.exists():
            value=json.loads(cached.read_text())
            if value['identity']!=identity or any(file_identity(directory/p)!=sha for p,sha in value['artifacts'].items()):
                raise ValueError('original experiment observation drift')
            w.write(out/'receipt.json',dict(value,reused=True)); return dict(value,reused=True)
        if any(directory.iterdir()):
            raise ValueError('unreceipted experiment artifacts; reconcile rather than rerun')
        staged=out/'inputs'; staged.mkdir(exist_ok=True)
        for name,ref in recovered['plan']['inputIdentities'].items():
            p=staged/name; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(read_source(root,ref))
        w.sync_build_source(root,build,staged,mutable=['tests/unit-tests/03-number/_num.c'])
        plan=dict(identity=identity, predictions={
            'single':'real constraint/equivalence/solution sections distinguish PTA from SSA counts; partial sections stay unknown',
            'multiple':'more C hosts and smaller maximum per-function shared joins; total work need not improve'},
            changedControl='matched single/multiple host token; single-shared-jump instead changes only inline-jump token',
            originalCIdentity=recovered['sourceIdentity'],compilerVersion=version,
            analysisSourceSha256=digest(root/'src/gambit_smp/compiler_phase_primitives.py'))
        w.write(directory/'plan.json',plan); w.write(out/'plan.json',plan)
        w.checkpoint_build_source(source,phase='building',diagnostic='original-'+mode+'-host')
        meta={}; code,log,timed_out,seconds=execute(argv,directory,60,environment,meta)
        (directory/'compile.log').write_text(log)
        artifacts={p.name:file_identity(p) for p in directory.iterdir() if p.is_file()}
        # Persist the real outcome before parsing large or incomplete dumps.
        value=dict(schema='original-numeric-host-experiment.v1',mode=mode,identity=identity,
            exit=code,timeout=timed_out,seconds=seconds,process=meta,artifacts=artifacts,
            objectExists=(directory/'_test.o1').is_file(),reused=False,nativeAdmitted=False,performanceAdmitted=False)
        w.write(cached,value)
        phases={}
        for phase in ('alias','ealias'):
            dumps=list(directory.glob('*.'+phase))
            if len(dumps)>1: raise ValueError('ambiguous requested-pass output')
            if dumps:
                with dumps[0].open() as f: phases[phase]=alias_detail_census(f)
            else: phases[phase]=None
        cfg=list(directory.glob('*.cfg')); ssa=list(directory.glob('*.ssa'))
        census=None
        representation_error=None
        cfg_observed=None
        if len(cfg)==1:
            with cfg[0].open() as c: cfg_observed=cfg_representation_census(c)
        if len(cfg)==len(ssa)==1:
            try:
                with cfg[0].open() as c,ssa[0].open() as s:
                    census=retained_ir_representation(c,s)
            except ValueError as error:
                representation_error=str(error)
        value.update(aliasDetails=phases,representation=census,
                     representationError=representation_error,cfgObserved=cfg_observed,
                     inputsStable=digest(root/recovered['generatedC'])==ORIGINAL_NUMERIC_SHA and digest(source/'include/gambit.h')==ORIGINAL_HEADER_SHA,
                     unknownOptionWarning=any(x in log.lower() for x in ('unrecognized','unknown option','ignoring unknown')))
        w.checkpoint_build_source(source,phase='ready',diagnostic='original-'+mode+'-host-outcome-retained')
        w.write(cached,value); w.write(out/'receipt.json',value)
        return value


def _compiler_stage_profile(argv, directory, budget, env, phase, sample_at):
    """Observe only this stage owner; never renew its wall deadline."""
    from gambit_smp.compiler_phase_primitives import owned_cc1
    from gambit_smp import process_identity as pi
    import os, threading
    samples=[];events=[];errors=[];stop=threading.Event();threads=[]
    tool=Path('/usr/bin/sample');tool_sha=digest(tool)
    def observe(parent):
        started=time.monotonic();previous={};pending=list(sample_at)
        try:
            while not stop.wait(.5):
                elapsed=time.monotonic()-started
                sizes={p.name:p.stat().st_size for p in directory.iterdir() if p.suffix in ('.cfg','.ssa','.alias','.ealias','.o1','.i')}
                if sizes!=previous:events.append(dict(seconds=elapsed,bytes=sizes));previous=sizes
                if pending and elapsed>=pending[0]:
                    at=pending.pop(0);parent_now=pi.process(parent['pid'])
                    if not pi.same_birth(parent,parent_now):continue
                    children=[]
                    for pid in pi.pids(parent['uid']):
                        try:child=pi.process(pid)
                        except OSError:continue
                        if owned_cc1(parent,child):children.append(child)
                    if len(children)!=1:
                        samples.append(dict(afterSeconds=at,status='no-unique-owned-cc1'));continue
                    child=children[0]
                    if not pi.same_birth(child,pi.process(child['pid'])) or not pi.same_birth(parent,pi.process(parent['pid'])):continue
                    report=directory/(phase+'-cc1-'+str(at)+'.sample');sm={}
                    sc,sl,st,ss=execute([str(tool),str(child['pid']),'1','1','-file',str(report)],directory,5,env,sm)
                    (directory/(phase+'-sample-'+str(at)+'.log')).write_text(sl)
                    samples.append(dict(afterSeconds=at,elapsed=elapsed,parent=parent,target=child,
                        targetAfter=pi.process(child['pid']),exit=sc,timeout=st,seconds=ss,process=sm,
                        toolSha256=tool_sha,report=report.name if report.exists() else None))
        except BaseException as error:errors.append(repr(error))
    def spawned(pid):
        parent=pi.process(pid)
        if parent is None or parent['pgid']!=pid or parent['uid']!=os.getuid():raise ValueError('owned compiler birth not established')
        thread=threading.Thread(target=observe,args=(parent,),name='owned-numeric-compiler-observer')
        threads.append(thread);thread.start()
    meta={}
    try:code,log,timeout,seconds=execute(argv,directory,budget,env,meta,on_spawn=spawned)
    finally:
        stop.set()
        for thread in threads:thread.join(6)
    if any(t.is_alive() for t in threads):raise ValueError('own compiler observer not quiescent')
    return (code,log,timeout,seconds), dict(samples=samples,fileProgress=events,errors=errors,toolSha256=tool_sha), meta


def numeric_representation_profile(root, out, variant):
    """Separate preprocessing from C compilation and observe only our cc1 child.

    This is a new phase-isolated route, not a retry of the timed-out driver.
    Original and comparator-call candidates share one registered product and
    original Scheme inputs. Samples/byte progress never renew the 60s deadline.
    """
    from gambit_smp import workspace as w
    from gambit_smp.artifact_storage import workspace_lease
    from gambit_smp.recipes import tree_identity
    from gambit_smp.source_identity import read_source, retain_sources
    from gambit_smp.compiler_phase_primitives import numeric_generation_runtime_options, generated_host_census, owned_cc1, cfg_representation_census, alias_detail_census
    from gambit_smp import process_identity as pi
    import os, threading, hashlib
    if variant not in ('original','call-comparators','outline-assertions'):raise ValueError('registered numeric source variant required')
    root=Path(root).resolve();out=Path(out);out.mkdir(parents=True,exist_ok=True)
    recovered=recover_original_numeric(root,out/'original-reuse')
    build=root/recovered['workspace'];source=build/'source'
    wrapper=root/('models/gambit/native/numeric-alias/'+('outline-assertions' if variant=='outline-assertions' else 'call-comparators')+'.scm')
    revision='-'+digest(wrapper)[:12] if variant=='outline-assertions' else ''
    directory=build/'experiments'/('profile-'+variant+revision+'-multiple');directory.mkdir(parents=True,exist_ok=True)
    receipt=directory/'receipt.json'
    history=root/'evidence/source-results/model-first-followthrough/real-graph-cold-r8-03/numeric/retained-full-graph/argv.json'
    old=json.loads(history.read_text());gcc=Path(old[0]);compiler,env,version=gnu_compiler(gcc)
    identity=dict(original=ORIGINAL_NUMERIC_SHA,header=ORIGINAL_HEADER_SHA,gcc=digest(gcc),
        wrapper=digest(wrapper) if variant!='original' else None,variant=variant,version='numeric-phase-profile-v1',budgetSeconds=60)
    def sha(p):
        with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
    if receipt.exists():
        value=json.loads(receipt.read_text())
        if value['identity']!=identity or any(sha(directory/p)!=h for p,h in value['artifacts'].items()):
            raise ValueError('numeric phase observation identity drift')
        w.write(out/'receipt.json',dict(value,reused=True));return dict(value,reused=True)
    if any(directory.iterdir()):raise ValueError('unreceipted phase-profile artifacts; do not retry')
    with workspace_lease(root,source,tree_identity(source)):
        staged=out/'inputs';staged.mkdir(exist_ok=True)
        for name,ref in recovered['plan']['inputIdentities'].items():
            p=staged/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(read_source(root,ref))
        if variant=='outline-assertions':
            (staged/'tests/outline-assertions.scm').write_bytes(wrapper.read_bytes())
        else:
            (staged/'tests/call-comparators.scm').write_bytes(wrapper.read_bytes())
        w.sync_build_source(root,build,staged,mutable=['tests/unit-tests/03-number/_num.c'])
        if digest(root/recovered['generatedC'])!=ORIGINAL_NUMERIC_SHA or digest(source/'include/gambit.h')!=ORIGINAL_HEADER_SHA:
            raise ValueError('original numeric inputs changed')
        producer=root/'.cache/current-mutex-return-incremental-02/candidate-runtime'
        input_c=root/recovered['generatedC'];generation=None
        w.write(directory/'plan.json',dict(identity=identity,compilerVersion=version,
            predictions=['preprocessing separated from CFG/SSA/alias compilation',
                         'call-only harness comparators remove duplicated primitive-specialization paths without changing numeric expressions'],
            sourceIdentities=retain_sources(root,{str(p.relative_to(root)):p.read_bytes() for p in
                (wrapper,root/'src/gambit_smp/compiler_cost.py',root/'src/gambit_smp/compiler_phase_primitives.py')}),
            diagnostic='sample only direct kernel-verified cc1 in own PID/birth/group; observer perturbs timings; no native speed claim'))
        if variant!='original':
            input_c=directory/'candidate.c'
            emit='(exit (if (compile-file-to-target "call-comparators.scm" options: (quote ((module-ref _test) (linker-name "_test.o1"))) output: '+json.dumps(str(input_c))+') 0 1))'
            generation_env=dict(os.environ)
            if variant=='outline-assertions':
                emit='(load "outline-assertions.scm")'
                generation_env['GAMBIT_NUMERIC_GENERATED_C']=str(input_c)
            gm={};code,log,timeout,seconds=execute([str(producer/'gsc/gsc'),numeric_generation_runtime_options(producer),'-f','-e',emit],source/'tests',60,generation_env,gm)
            (directory/'generation.log').write_text(log)
            generation=dict(exit=code,timeout=timeout,seconds=seconds,process=gm)
            w.write(directory/'generation.json',generation)
            if code or timeout or not input_c.is_file():raise ValueError('numeric comparator candidate generation failed; outcome retained')
        input_ref=retain_sources(root,{'compiler-input':input_c.read_bytes()})['compiler-input']
        fixture_refs=retain_sources(root,{str(p.relative_to(staged)):p.read_bytes() for p in staged.rglob('*') if p.is_file()})
        w.write(directory/'generation-input-identities.json',fixture_refs)
        with input_c.open() as f:generated=generated_host_census(f)
        w.write(directory/'generated-hosts.json',generated)
        flags=old[old.index('-O1'):-1]
        flags=[('-I'+str(source/'include')) if x.startswith('-I') else x.replace('-D___SINGLE_HOST','-D___MULTIPLE_HOSTS') for x in flags]
        pp=[str(compiler),'-E',*flags,str(input_c),'-o','input.i']
        w.write(directory/'input-identity.json',input_ref)
        (code,log,timeout,seconds),pp_observation,pm=_compiler_stage_profile(pp,directory,20,env,'cpp',(5,12))
        w.write(directory/'preprocess-observations.json',pp_observation)
        (directory/'preprocess.log').write_text(log)
        preprocessing=dict(argv=pp,exit=code,timeout=timeout,seconds=seconds,process=pm)
        w.write(directory/'preprocess.json',preprocessing)
        if code or timeout:
            value=dict(schema='numeric-representation-profile.v1',identity=identity,inputCIdentity=input_ref,
                generation=generation,generated=generated,preprocessing=preprocessing,native=None,execution=None,
                aliasDetails={'alias':None,'ealias':None},cfgObserved=None,samples=pp_observation['samples'],observerErrors=pp_observation['errors'],
                inputsStable=digest(root/recovered['generatedC'])==ORIGINAL_NUMERIC_SHA and digest(source/'include/gambit.h')==ORIGINAL_HEADER_SHA,
                artifacts={p.name:sha(p) for p in directory.iterdir() if p.is_file()},reused=False,nativeAdmitted=False,performanceAdmitted=False)
            w.checkpoint_build_source(source,phase='ready',diagnostic='numeric-preprocessing-failure-retained')
            w.write(receipt,value);w.write(out/'receipt.json',value);return value
        preprocessing.update(bytes=(directory/'input.i').stat().st_size,sha256=sha(directory/'input.i'))
        native_flags=[x for x in flags if not x.startswith(('-D','-I'))]
        argv=[str(compiler),'-bundle','-o','_test.o1',*native_flags,'input.i',
              '-fdump-tree-cfg','-fdump-tree-ssa','-fdump-tree-ealias-details','-fdump-tree-alias-details',
              '-ftime-report','-ftime-report-details','-dumpdir','./']
        w.checkpoint_build_source(source,phase='building',diagnostic='numeric-phase-profile-'+variant)
        (code,log,timeout,seconds),observation,meta=_compiler_stage_profile(argv,directory,60,env,'native',(15,40))
        samples=observation['samples'];events=observation['fileProgress'];errors=observation['errors'];tool_sha=observation['toolSha256']
        (directory/'compile.log').write_text(log)
        native=dict(argv=argv,exit=code,timeout=timeout,seconds=seconds,process=meta,objectExists=(directory/'_test.o1').is_file())
        w.write(directory/'native-outcome.json',native)
        w.write(directory/'phase-observations.json',dict(samples=samples,fileProgress=events,errors=errors,toolSha256=tool_sha))
        details={};cfg=None
        for phase in ('alias','ealias'):
            paths=list(directory.glob('*.'+phase))
            if len(paths)>1:raise ValueError('ambiguous alias observation')
            if paths:
                with paths[0].open() as f:details[phase]=alias_detail_census(f)
            else:details[phase]=None
        paths=list(directory.glob('*.cfg'))
        if len(paths)==1:
            with paths[0].open() as f:cfg=cfg_representation_census(f)
        execution=None
        if code==0 and not timeout and native['objectExists']:
            witness='NUMERIC-ORIGINAL:module-initialized,assertions-passed'
            from gambit_smp.compiler_phase_primitives import numeric_execution_expression
            load=numeric_execution_expression(witness)
            em={};ec,el,et,es=execute([str(producer/'gsi/gsi'),numeric_generation_runtime_options(producer),'-f','-e',load],directory,60,metadata=em)
            (directory/'execution.log').write_text(el)
            execution=dict(exit=ec,timeout=et,seconds=es,process=em,accepted=stage_accepted(ec,et,el,None,witness))
        w.checkpoint_build_source(source,phase='ready',diagnostic='numeric-phase-profile-outcome-retained')
        value=dict(schema='numeric-representation-profile.v1',identity=identity,inputCIdentity=input_ref,
            generation=generation,generated=generated,preprocessing=preprocessing,native=native,
            execution=execution,aliasDetails=details,cfgObserved=cfg,samples=samples,observerErrors=errors,
            inputsStable=digest(root/recovered['generatedC'])==ORIGINAL_NUMERIC_SHA and digest(source/'include/gambit.h')==ORIGINAL_HEADER_SHA,
            artifacts={p.name:sha(p) for p in directory.iterdir() if p.is_file()},reused=False,nativeAdmitted=False,performanceAdmitted=False)
        w.write(receipt,value);w.write(out/'receipt.json',value);return value


def numeric_low_output_control(root, out):
    """Same grouped preprocessed program/O1, without expensive full-tree dumps.

    Keep the measured detailed-dump failure. This separate instrumentation
    control uses its exact input.i and never reruns generation/preprocessing.
    """
    from gambit_smp import workspace as w
    from gambit_smp.artifact_storage import workspace_lease
    from gambit_smp.recipes import tree_identity
    from gambit_smp.compiler_phase_primitives import assertion_group_manifest, numeric_generation_runtime_options
    from gambit_smp.source_identity import retain_sources, read_source
    import hashlib
    root=Path(root).resolve();out=Path(out);out.mkdir(parents=True,exist_ok=True)
    previous=numeric_representation_profile(root,out/'profile-reuse','outline-assertions')
    if not previous['reused']:raise ValueError('existing grouped phase receipt required')
    recovered=recover_original_numeric(root,out/'source-reuse');build=root/recovered['workspace'];source=build/'source'
    old_dir=build/'experiments'/('profile-outline-assertions-'+previous['identity']['wrapper'][:12]+'-multiple')
    directory=old_dir/'low-output';directory.mkdir(exist_ok=True);receipt=directory/'receipt.json'
    with (old_dir/'candidate.c.forms.tsv').open() as f:manifest=assertion_group_manifest(f)
    for ref in recovered['plan']['inputIdentities'].values():
        if b'smp-numeric-35f9489c4e709579-group-' in read_source(root,ref):raise ValueError('private group prefix collision')
    with (old_dir/'input.i').open('rb') as f:input_sha=hashlib.file_digest(f,'sha256').hexdigest()
    if input_sha!=previous['preprocessing']['sha256']:raise ValueError('grouped preprocessor checkpoint drift')
    argv=[x for x in previous['native']['argv'] if not x.startswith('-fdump-tree-')]
    argv=[str(old_dir/'input.i') if x=='input.i' else x for x in argv]
    identity=dict(inputSha256=input_sha,argv=argv,budgetSeconds=60,source=previous['inputCIdentity'])
    def sha(p):
        with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
    if receipt.exists():
        value=json.loads(receipt.read_text())
        if value['identity']!=identity or any(sha(directory/p)!=h for p,h in value['artifacts'].items()):raise ValueError('low-output observation drift')
        w.write(out/'receipt.json',dict(value,reused=True));return dict(value,reused=True)
    if any(directory.iterdir()):raise ValueError('unreceipted low-output control; do not retry')
    with workspace_lease(root,source,tree_identity(source)):
        for name,ref in recovered['plan']['inputIdentities'].items():
            if (source/name).read_bytes()!=read_source(root,ref):raise ValueError('original Scheme/header input changed')
        w.write(directory/'plan.json',dict(identity=identity,manifest=manifest,
            prediction='removing whole-function dumps separates observer I/O from real O1 compilation; all numeric assertions still required',
            sourceIdentity=retain_sources(root,{'adapter':Path(__file__).read_bytes()})))
        env=dict(__import__('os').environ)
        env={k:v for k,v in env.items() if k not in ('SDKROOT','LIBRARY_PATH','CPATH')}
        env['PATH']=str(Path(argv[0]).parent)+':/usr/bin:/bin:/usr/sbin:/sbin'
        (code,log,timeout,seconds),observation,meta=_compiler_stage_profile(argv,directory,60,env,'native',(15,40))
        (directory/'compile.log').write_text(log)
        native=dict(exit=code,timeout=timeout,seconds=seconds,process=meta,objectExists=(directory/'_test.o1').is_file())
        w.write(directory/'native-outcome.json',native);w.write(directory/'observations.json',observation)
        execution=None;reference=None;reader=None
        producer=root/'.cache/current-mutex-return-incremental-02/candidate-runtime'
        witness='NUMERIC-ORIGINAL:module-initialized,assertions-passed'
        if code==0 and not timeout and native['objectExists']:
            from gambit_smp.compiler_phase_primitives import numeric_execution_expression
            load=numeric_execution_expression(witness)
            em={};ec,el,et,es=execute([str(producer/'gsi/gsi'),numeric_generation_runtime_options(producer),'-f','-e',load],directory,60,metadata=em)
            (directory/'execution.log').write_text(el)
            execution=dict(exit=ec,timeout=et,seconds=es,process=em,accepted=stage_accepted(ec,et,el,None,witness))
        # Independent plain reader, then full unchanged interpreted numeric case.
        # This is a reference result, never native acceptance for a failed build.
        oracle_path=directory/'original-forms.tsv'
        expr='''(begin
          (call-with-input-file "unit-tests/03-number/_num.scm" (lambda (port)
            (call-with-output-file OUTPUT (lambda (out)
              (let loop ((i 0) (form (read port)))
                (if (not (eof-object? form))
                    (begin (display i out) (display "\\t" out)
                      (write (if (pair? form) (car form) (quote non-call)) out) (newline out)
                      (loop (+ i 1) (read port)))))))))
          (define ##failed-test? (quote numeric-reference-not-executed))
          (load "unit-tests/03-number/_num.scm")
          (if (eq? ##failed-test? #f)
              (begin (display "NUMERIC-REFERENCE:all-original-assertions-passed\\n") (exit 0)) (exit 2)))'''.replace('OUTPUT',json.dumps(str(oracle_path)))
        rm={};rc,rl,rt,rs=execute([str(producer/'gsi/gsi'),numeric_generation_runtime_options(producer),'-f','-e',expr],source/'tests',60,metadata=rm)
        (directory/'reference.log').write_text(rl)
        reference=dict(exit=rc,timeout=rt,seconds=rs,process=rm,accepted=stage_accepted(rc,rt,rl,None,'NUMERIC-REFERENCE:all-original-assertions-passed'))
        if oracle_path.exists():
            kinds=[line.rstrip('\n').split('\t')[1] for line in oracle_path.read_text().splitlines(keepends=True)]
            with (old_dir/'candidate.c.forms.tsv').open() as f:reader=assertion_group_manifest(f,kinds)
        value=dict(schema='numeric-low-output-control.v1',identity=identity,native=native,execution=execution,
            originalInterpretedReference=reference,independentManifest=reader,observations=observation,
            artifacts={p.name:sha(p) for p in directory.iterdir() if p.is_file()},reused=False,
            nativeAdmitted=False,performanceAdmitted=False)
        w.write(receipt,value);w.write(out/'receipt.json',value);return value


def retained_numeric_analysis(root, out):
    """Analyze the original retained IR; never reconstruct or recompile missing C.

    The fixed dump identities prevent substitution of a smaller/newer workload.
    Historical samples are read as stack observations, never fresh CPU timings.
    """
    from gambit_smp import workspace as w
    from gambit_smp.compiler_phase_primitives import retained_ir_representation
    import re
    root = Path(root).resolve()
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    base = root / 'evidence/source-results/model-first-followthrough/real-graph-cold-r8-03/numeric/retained-full-graph'
    cfg = base / '_test.o1-_num.c.016t.cfg'
    ssa = base / '_test.o1-_num.c.024t.ssa'
    expected = {cfg: 'cef7105de2f7825ce1f33270bb2015e5920c3c488bc9f4e8bdb0356ef2276733',
                ssa: '167b9bf14f47ce77479672067830b75c9c1511b8816a96bef9cf55806d7dd8f1'}
    for path, sha in expected.items():
        if digest(path) != sha:
            raise ValueError('original numeric IR identity drift')
    historical = root / '.cache/current-numeric-no-pta-postparse-01'
    samples = [historical / name for name in ('cc1-35.sample', 'cc1-50.sample')]
    header = root / '.cache/current-mutex-return-incremental-02/candidate-runtime/include/gambit.h'
    paths = [cfg, ssa, base/'argv.json', base/'status.json', header,
             historical/'receipt.json', *samples,
             root/'src/gambit_smp/compiler_cost.py', root/'src/gambit_smp/compiler_phase_primitives.py']
    inputs = {str(p.relative_to(root)): digest(p) for p in paths}
    w.write(out/'plan.json', dict(inputs=inputs, scope='original retained IR and historical sample discrimination',
        predictions=['shared predecessor edges repeat across live-value PHIs',
                     'no-PTA may move to non-alias passes without completing'],
        originalCompilerInvocation=False, timeBudgetChange=False))
    with cfg.open() as c, ssa.open() as s:
        census = retained_ir_representation(c, s)
    observed = []
    for sample in samples:
        hits = []
        for number, line in enumerate(sample.read_text().splitlines(), 1):
            if match := re.search(r'(\d+) .*\b(pass_\w+)::execute\(function\*\)', line):
                hits.append(dict(line=number, passName=match[2], inclusiveSamples=int(match[1])))
        observed.append(dict(path=str(sample.relative_to(root)), passStackObservations=hits))
    host = next(f for f in census['functions'] if f['function'] == '___H___test')
    shared = host['topJoins'][:2]
    if not all(j['sharedPredecessorSet'] and j['operands'] == j['phis'] * j['incomingEdges'] for j in shared):
        raise ValueError('original shared-join prediction rejected')
    history = json.loads((historical/'receipt.json').read_text())
    original = root / '.cache/current-numeric-isolated-original-control-03/runtime/tests/unit-tests/03-number/_num.c'
    result = dict(schema='original-numeric-mechanism-analysis.v1', inputs=inputs, census=census,
        sharedJoins=shared, sharedJoinOperands=sum(j['operands'] for j in shared),
        historicalNoPta=dict(exit=history['exit'], timeout=history['timeout'], seconds=history['seconds'], samples=observed),
        originalGeneratedC=dict(path=str(original.relative_to(root)), exists=original.is_file(),
            expectedSha256='35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158',
            actualSha256=digest(original) if original.is_file() else None),
        headerSha256=digest(header), inputsStable=all(digest(root/p)==sha for p,sha in inputs.items()),
        compilerStarted=False, nativeAdmitted=False, performanceAdmitted=False,
        interpretation='shared dispatcher/external-tail-call SSA representation observed; actual alias expansion and causal repair remain open')
    w.write(out/'receipt.json', result)
    return result


def alias_pass_discrimination(root, out):
    """Real, bounded GCC pass controls, reusing the task incremental workspace.

    Qualifies the failed functionless probe; never compiles the original numeric
    workload or awards native/performance credit. No new public launcher.
    """
    from gambit_smp import workspace as w
    from gambit_smp.artifact_storage import workspace_lease
    from gambit_smp.recipes import tree_identity
    from gambit_smp.source_identity import retain_sources
    from gambit_smp.task_processes import run
    from gambit_smp.compiler_phase_primitives import alias_passes_exercised
    import os
    root=Path(root).resolve();out=Path(out);out.mkdir(parents=True,exist_ok=True)
    history=root/'evidence/source-results/model-first-followthrough/grok-numeric-audit-02/retained-run/glo-inline-n1024/argv.json'
    old=json.loads(history.read_text());gcc=Path(old[0]).resolve(strict=True)
    fixture=root/'models/gambit/native/numeric-alias/probe.c'
    flags=old[4:-1]
    assert flags[0]=='-O1' and old[1]=='-c' and old[2]=='-o'
    compiler,environment,version=gnu_compiler(gcc)
    decisions=dict(schema='numeric-alias-discrimination-plan.v1',historicalCommandSha256=digest(history),
        sourceIdentity=retain_sources(root,{'probe':fixture.read_bytes()})['probe'],compiler=str(gcc),compilerSha256=digest(gcc),
        predictions={'functionless-O1':'no-function-alias-dump','functionful-O1':'requested-pass-has-function-and-constraints',
                     'functionful-O0':'phase-scheduling-control; absent alias pass is not a compiler failure'},
        scope='qualify prior dump-probe failure, not full numeric cost or runtime repair',budgetSeconds=10)
    w.write(out/'plan.json',decisions)
    build=w.build_output(root,'gambit-core',compiler=gcc,flags=['numeric-alias-discrimination-v1',digest(history),digest(fixture)])
    runtime=build/'source';runtime.mkdir(exist_ok=True)
    results=[]
    with workspace_lease(root,runtime,tree_identity(runtime)):
        # Existing source-state checkpoint governs the one authored source delta.
        w.sync_build_source(root,build,fixture.parent)
        for name,optimization,functionless in [('functionless-O1','-O1',True),('functionful-O0','-O0',False),('functionful-O1','-O1',False)]:
            directory=runtime/name;directory.mkdir(exist_ok=True)
            receipt=directory/'receipt.json'
            identity=dict(compiler=digest(gcc),source=digest(runtime/'probe.c'),historicalCommand=digest(history),experiment='numeric-alias-discrimination-v1')
            # Prior complete bytes may be reused, never counted as a new timing.
            if receipt.exists():
                previous=json.loads(receipt.read_text())
                if previous['identity']!=identity:raise ValueError('diagnostic workspace identity drift')
                if any(not (directory/p).is_file() or digest(directory/p)!=sha for p,sha in previous['artifacts'].items()):raise ValueError('diagnostic artifact drift')
                texts={phase:[(directory/p).read_text() for p in previous['artifacts'] if p.endswith('.'+phase)] for phase in ('alias','ealias')}
                results.append(dict(previous,reused=True,passExercised=alias_passes_exercised(previous['exit'],previous['unknownOptionWarning'],texts)));continue
            argv=[str(compiler),'-c','../probe.c','-o','probe.o',optimization,*flags[1:],
                  '-fdump-tree-alias-details','-fdump-tree-ealias-details','-dumpdir','./']
            if functionless:argv.append('-DFUNCTIONLESS')
            started=time.monotonic();result=run(argv,cwd=directory,env=environment,capture_output=True,text=True,timeout=10)
            log=result.stdout+result.stderr;(directory/'compile.log').write_text(log)
            dumps=[p for p in directory.iterdir() if p.is_file() and (p.name.endswith('.alias') or p.name.endswith('.ealias'))]
            text='\n'.join(p.read_text() for p in dumps)
            warning=any(x in log.lower() for x in ('unrecognized','unknown','ignoring unknown'))
            observed=dict(name=name,argv=argv,identity=identity,exit=result.returncode,seconds=time.monotonic()-started,
                dumpCount=len(dumps),functionSeen='numeric_alias_probe' in text,constraintsSeen='Constraints:' in text,
                unknownOptionWarning=warning,artifacts={p.name:digest(p) for p in directory.iterdir() if p.is_file()},reused=False)
            texts={phase:[p.read_text() for p in dumps if p.name.endswith('.'+phase)] for phase in ('alias','ealias')}
            observed['passExercised']=alias_passes_exercised(result.returncode,warning,texts)
            w.write(receipt,observed);results.append(observed)
        w.checkpoint_build_source(runtime,phase='ready',diagnostic='alias-controls-complete')
    complete=(results[0]['exit']==0 and results[0]['dumpCount']==0 and not results[0]['unknownOptionWarning'] and results[2]['passExercised'])
    value=dict(schema='numeric-alias-discrimination-result.v1',plan=str((out/'plan.json').relative_to(root)),planSha256=digest(out/'plan.json'),
        workspace=str(build.relative_to(root)),results=results,qualified=complete,
        conclusion='functionless probe omitted the function alias pass; actual compiler supports requested pass on observable function' if complete else 'predictions-not-established',
        originalNumericStarted=False,sourceRepairJustified=False,nativeAdmitted=False,performanceAdmitted=False)
    w.write(out/'receipt.json',value);return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--toolchain-receipt", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--timeout", type=float, required=True)
    parser.add_argument("selection")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("positive whole probe budget required")
    runtime, out = args.runtime.resolve(), args.out.resolve()
    identity = json.loads(args.toolchain_receipt.read_text())
    check(runtime, identity)
    compiler, environment, version = gnu_compiler(args.gcc)
    compiler_binding(runtime, compiler)
    driver = gnu_build_driver(runtime, compiler)
    files = selected_files(runtime / "tests/unit-tests", [args.selection])
    if len(files) != 1:
        parser.error("phase probe requires one original upstream fixture")
    sources = {p.relative_to(runtime / "tests").as_posix(): digest(p)
               for p in (runtime / "tests/unit-tests").rglob("*") if p.is_file()}
    out.mkdir(parents=True, exist_ok=False)
    work = runtime_view(runtime, out / "runtime")
    shutil.copytree(runtime / "tests/unit-tests", work / "unit-tests")
    processors = available_processors()
    option = f"p{processors},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    environment["GAMBOPT"] = option
    receipt = dict(schema="gambit-compiler-cost.v2", diagnosticOnly=True,
                   adapterSha256=digest(Path(__file__)),
                   executionContract="explicit probe linker, initialized original failure flag and unique witness",
                   scope="one unchanged upstream fixture, split compile/execute phases; not suite or bootstrap admission",
                   status="RUNNING", candidateReceiptSha256=digest(args.toolchain_receipt),
                   gsiSha256=identity["binarySha256"], gscSha256=identity["gscSha256"],
                   processors=processors, processorSelection="host-auto",
                   compiler=version.splitlines()[0], buildDriver=driver, sourceFiles=sources,
                   selection=str(files[0]), wholeProbeBudget=args.timeout, stages=[])
    receipt_path = out / "receipt.json"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    stages = phase_commands(files[0], work)
    start = time.monotonic()
    deadline = start + args.timeout
    for name, executable, options, artifact in stages:
        remaining = deadline - time.monotonic()
        metadata = {}
        if remaining <= 0:
            code, output, timed_out, seconds = -9, "whole probe budget exhausted\n", True, 0
        else:
            code, output, timed_out, seconds = execute(
                [str(runtime / executable), "-:" + option] + options, work,
                remaining, env=environment, metadata=metadata)
        (out / (name + ".log")).write_text(output)
        accepted = stage_accepted(code, timed_out, output, artifact,
                                  EXECUTION_WITNESS if name == "compiled-execution" else None)
        receipt["stages"].append(dict(name=name, exit=code, timeout=timed_out,
            seconds=round(seconds, 3), accepted=accepted, process=metadata,
            artifactSha256=digest(artifact) if artifact and artifact.is_file() else None))
        receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
        print(f"{name}: {'PASS' if accepted else 'DENY'}; {seconds:.3f}s", flush=True)
        if not accepted:
            break
    stable = all(digest(runtime / "tests" / name) == sha and digest(work / name) == sha
                 for name, sha in sources.items()) and gnu_build_driver(runtime, compiler) == driver
    check(runtime, identity)
    receipt.update(sourceStable=stable, seconds=round(time.monotonic() - start, 3))
    accepted = stable and len(receipt["stages"]) == len(stages) and all(row["accepted"] for row in receipt["stages"]) and receipt["seconds"] <= args.timeout
    receipt["status"] = "PASS" if accepted else "DENY"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    return 0 if accepted else 1


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('compiler-cost')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('compiler-cost', main))
