"""Gerbil build: frame tests."""

from gambit_smp.framework import digest, relative, available_processors
import json
import shutil


def gvm_host_witness(reference, candidate):
    """Compare emitted C tokens, not expanded macro semantics or runtime cost."""
    import re
    marker='#include "gambit.h"'
    if reference.count(marker)!=1 or candidate.count(marker)!=1:
        raise ValueError('one explicit Gambit header consumer required')
    prefix,suffix=candidate.split(marker)
    plan={k:int(v) for k,v in re.findall(r'^#define ___GVM_HOST_(\w+) (\d+)$',prefix,re.M)}
    if (set(plan)!={'LAYOUT','COUNT','MAX_LABELS','MAX_CODE_SLOTS','TOTAL_LABELS'}
            or plan['LAYOUT']!=1 or plan['COUNT']!=reference.count('___BEGIN_P_COD')
            or not 0<plan['MAX_LABELS']<=plan['TOTAL_LABELS']
            or plan['MAX_CODE_SLOTS']<plan['MAX_LABELS']):
        raise ValueError('actual GVM procedure host plan is incomplete')
    guard=('#ifndef ___GVM_HOST_LAYOUT_SUPPORTED\n'
           '#error GVM_host_plan_requires_matching_runtime_header\n#endif\n')
    if suffix.count(guard)!=1:raise ValueError('matching-header refusal is missing')
    prefix=re.sub(r'^#define ___GVM_HOST_\w+ \d+\n','',prefix,flags=re.M)
    normalized=prefix+marker+suffix.replace(guard,'',1)
    def lines(text):
        return [line for line in text.splitlines()
                if not re.match(r'^\s*#(?:line\s+\d+|\s*\d+\s+")',line)]
    before,after=lines(reference),lines(normalized)
    if before!=after:
        index=next((i for i,(a,b) in enumerate(zip(before,after)) if a!=b),min(len(before),len(after)))
        raise ValueError('GVM host C witness differs at normalized line '+str(index+1))
    return dict(plan=plan,equalLines=len(before),debugLineEquivalenceProved=False,
                macroSemanticEquivalenceProved=False)


def procedure_host_coverage(text):
    """Count canonical emitted host-label intervals, not C optimizer cost."""
    import re
    totals=re.findall(r'^#define ___LBLCOUNT ([0-9]+)$',text,re.M)
    blocks=re.findall(r'^___BEGIN_P_COD\n(.*?)^___END_P_COD$',text,re.M|re.S)
    if len(totals)!=1 or not blocks:
        raise ValueError('canonical generated procedure intervals required')
    counts=[]
    for block in blocks:
        if len(re.findall(r'^___DEF_P_HLBL_INTRO$',block,re.M))!=1:
            raise ValueError('one intro label per procedure required')
        counts.append(1+len(re.findall(r'^___DEF_P_HLBL\(',block,re.M)))
    if sum(counts)!=int(totals[0]):
        raise ValueError('procedure host labels do not cover module labels')
    return dict(procedures=len(counts),totalLabels=sum(counts),maxProcedureLabels=max(counts),
        macroSemanticEquivalenceProved=False,nativeMemoryBoundProved=False)


def configured_host_consumer(profile,ctx,runtime,source,reference,fixtures,bound):
    """Calibrate upstream's selective fallback on one retained actual C unit.

    No emitter/header overlay, old failed-job replay, or whole-package claim.
    The tiny runtime pair deliberately mixes procedure and module hosts.
    """
    limit=profile['singleHostLimit']
    coverage=procedure_host_coverage(reference.read_text())
    if (type(limit) is not int or not coverage['maxProcedureLabels']<=limit<coverage['totalLabels']
            or profile['sourceFiles']):
        raise ValueError('selective host calibration needs a covered finite limit and no source overlay')
    ctx.bind(bound)
    saved=dict(ctx.env)
    try:
        ctx.env.update(GAMBOPT=f'~~={runtime},~~bin={runtime}/bin,~~lib={runtime}/lib,~~include={runtime}/include',
            PATH=str(runtime/'bin')+':/opt/homebrew/bin:/usr/bin:/bin')
        interpreted=ctx.directory/'metadata-interpreted.scm'
        interpreted.write_text('(##meta-info cc-options "-D___SINGLE_HOST_LIMIT='+str(limit)+'")\n'
            '(define hp-metadata-value 42)\n')
        expression=('(load '+json.dumps(str(interpreted))+') '
            '(unless (= hp-metadata-value 42) (error "Interpreted metadata changed the program")) '
            '(display "SCHEME-METADATA-INTERPRETER-PASS\n")')
        ctx.require('configured-host-interpreted',[runtime/'gsi/gsi','-e',expression],ctx.directory,30)
        if 'SCHEME-METADATA-INTERPRETER-PASS' not in ctx.last_stdout.splitlines():
            raise ValueError('metadata is not compatible with interpreted source loading')
        probe=ctx.directory/'host-selection.c'
        probe.write_text('#include "gambit.h"\n')
        for name,labels,mode in (('small',limit,'SINGLE_HOST'),('large',coverage['totalLabels'],'MULTIPLE_HOSTS')):
            ctx.require('configured-host-'+name,[ctx.tools['gcc'],'-std=c23','-E','-dM',
                '-I'+str(runtime/'include'),'-D___SINGLE_HOST',
                '-D___SINGLE_HOST_LIMIT='+str(limit),'-D___LBLCOUNT='+str(labels),probe],ctx.directory,30)
            other='MULTIPLE_HOSTS' if mode=='SINGLE_HOST' else 'SINGLE_HOST'
            if ('#define ___'+mode+' ' not in ctx.last_stdout
                    or '#define ___'+other+' ' in ctx.last_stdout):
                raise ValueError('upstream selective host admission disagrees with the effective header')
        output=ctx.directory/reference.with_suffix('.o1').name
        options='-g -D___SINGLE_HOST_LIMIT='+str(limit)
        expression=('(let ((p (compile-file '+json.dumps(str(reference))+' output: '+json.dumps(str(output))+
            ' cc-options: '+json.dumps(options)+'))) (unless (equal? p '+json.dumps(str(output))+
            ') (error "Native consumer result differs" p)))')
        ctx.require('configured-host-actual-c',[runtime/'gsc/gsc','-e',expression],ctx.directory,ctx.remaining())
        if not output.is_file():raise ValueError('configured C consumer omitted its native output')
        for index,fixture in enumerate(fixtures[:2]):
            target=ctx.directory/fixture.with_suffix('.o1').name
            copied=ctx.directory/fixture.name
            flags='-D___SINGLE_HOST_LIMIT='+str(1 if index==0 else limit)
            copied.write_text('(##meta-info cc-options '+json.dumps(flags)+')\n'+fixture.read_text()+
                '\n(c-declare "#ifdef ___MULTIPLE_HOSTS\n#define HP_CONFIGURED_MULTIPLE_HOST 1\n'
                '#else\n#define HP_CONFIGURED_MULTIPLE_HOST 0\n#endif\n")\n'
                '(define hp-host-mode-'+str(index)+' (c-lambda () int "___return(HP_CONFIGURED_MULTIPLE_HOST);"))\n')
            generated=copied.with_suffix('.c')
            # Target-only emission otherwise defaults to the module name,
            # while the dynamic loader requests the output basename including .o1.
            expression=('(compile-file-to-target '+json.dumps(str(copied))+
                ' output: '+json.dumps(str(generated))+
                " options: '((linker-name "+json.dumps(target.name)+')))')
            ctx.require('configured-host-fixture-emit-'+str(index),
                [runtime/'gsc/gsc','-e',expression],ctx.directory,120)
            # No host override on this invocation: the standard Scheme metadata
            # must survive C emission and gambuild's metadata extraction.
            expression=('(compile-file '+json.dumps(str(generated))+' output: '+json.dumps(str(target))+
                        ' cc-options: "-g")')
            ctx.require('configured-host-fixture-'+str(index),[runtime/'gsc/gsc','-e',expression],ctx.directory,120)
            if not target.is_file():raise ValueError('mixed-host fixture output missing')
        expression=' '.join('(load '+json.dumps(str(p))+')' for p in (
            ctx.directory/'host-a.o1',ctx.directory/'host-b.o1'))
        expression+=(' (unless (and (= (hp-host-mode-0) 1) (= (hp-host-mode-1) 0)) '
            '(error "Scheme metadata did not select mixed host modes")) '
            '(load '+json.dumps(str(fixtures[2]))+')')
        ctx.require('configured-host-runtime',[runtime/'gsi/gsi','-e',expression],ctx.directory,60)
        if 'GVM-HOST-MODULE-GC-CONTINUATION-TAIL-PASS' not in ctx.last_stdout.splitlines():
            raise ValueError('mixed host runtime controls failed')
        observation=ctx.directory/'host-layout.json'
        observation.write_text(json.dumps(dict(componentPassed=True,consumerOnly=True,
            singleHostLimit=limit,coverage=coverage,schemeMetadataTransportPassed=True,
            sourceSha256=digest(source),referenceSha256=digest(reference),
            nativeOutputSha256=digest(output),runtimeFiles=profile['runtimeFiles'],
            fullCompilerPassed=False,bothPackagesPassed=False,packageSpeedup=None),indent=2)+'\n')
        return dict(outputs=ctx.publish('observations','gerbil-test-observations',observation))
    finally:
        ctx.env.clear();ctx.env.update(saved)


def _test_gvm_host_layout(profile,path,ctx):
    """Qualify the existing GSC host ABI using a current CI compiler's runtime.

    The old runtime is a byte-bound test input, not a completed Gerbil product.
    Only the emitter and host-selection header block enter the private view.
    """
    from gambit_smp.native_capabilities import fields,Stages
    from gambit_smp.gambit_build_primitives import regenerate_module
    fields(profile,('kind','packageRoot','gambitSource','schemeInput','referenceC',
                    'runtimeFiles','sourceFiles','fixtures'),('singleHostLimit',))
    package=(ctx.root/profile['packageRoot']).resolve(strict=True)
    candidate=(ctx.root/profile['gambitSource']).resolve(strict=True)
    runtime=package/'src/gambit'
    source=(ctx.root/profile['schemeInput']).resolve(strict=True)
    reference=(ctx.root/profile['referenceC']).resolve(strict=True)
    import os
    store=ctx.root/'.cache/tasks'/os.environ['GAMBIT_SMP_TASK_ID']
    if not all(p.is_relative_to(store) for p in (package,candidate,source,reference)):
        raise ValueError('same-task compiler and retained actual inputs required')
    required_runtime={'gsi/gsi','gsc/gsc','include/gambit.h','include/gambit.h.in',
        'include/config.h','lib/makefile','gsc/makefile','bin/gambuild-C','lib/libgambit.a'}
    if not required_runtime<=profile['runtimeFiles'].keys():
        raise ValueError('complete byte-bound runtime compiler context required')
    required={'gsc/_t-c-1.scm','gsc/igsc.scm','include/gambit.h.in'}
    if set(profile['sourceFiles'])!=required and 'singleHostLimit' not in profile:
        raise ValueError('only GVM emitter, official source entry and host template may change')
    bound=[path,source,reference]
    for root,entries in ((runtime,profile['runtimeFiles']),(candidate,profile['sourceFiles'])):
        for name,sha in entries.items():
            item=root/name
            if digest(item)!=sha:raise ValueError('host qualification input drift: '+name)
            bound.append(item)
    fixture_root=(ctx.root/profile['fixtures']).resolve(strict=True)
    if fixture_root!=ctx.root/'tests/fixtures/darwin-host-layout':
        raise ValueError('registered host/GC/continuation controls required')
    fixtures=[fixture_root/name for name in ('host-a.scm','host-b.scm','driver.scm')]
    bound+=fixtures
    if 'singleHostLimit' in profile:
        return configured_host_consumer(profile,ctx,runtime,source,reference,fixtures,bound)
    template=(candidate/'include/gambit.h.in').read_text()
    start=template.index('/* Explicit producer-owned GVM host plan.')
    end=template.index('\n#ifdef ___SINGLE_HOST',start)
    guard=template[start:end]
    if template.replace(guard+'\n','',1)!=(runtime/'include/gambit.h.in').read_text():
        raise ValueError('candidate header contains changes outside host selection')
    view=ctx.directory/'source-view';view.mkdir()
    for folder in ('gsc','gsi','lib'):
        target=view/folder;target.mkdir()
        for item in (runtime/folder).glob('*.scm'):
            shutil.copy2(item,target/item.name);bound.append(item)
        for name in ('makefile','makefile.in'):
            if (runtime/folder/name).is_file():
                shutil.copy2(runtime/folder/name,target/name)
                bound.append(runtime/folder/name)
    for name in ('makefile','makefile.in','config.status'):
        if (runtime/name).is_file():
            shutil.copy2(runtime/name,view/name);bound.append(runtime/name)
    for folder in ('include','bin'):
        (view/folder).mkdir()
    for item in (runtime/'include').iterdir():
        if item.is_file() and item.name.endswith(('.h','.h.in')):
            shutil.copy2(item,view/'include'/item.name);bound.append(item)
    (view/'include/gambit.h.in').write_text(template)
    for name in ('gsi/gsi','gsc/gsc','bin/gambuild-C'):
        (view/name).symlink_to(runtime/name);bound.append(runtime/name)
    (view/'gsc-boot').symlink_to(runtime/'gsc/gsc')
    shutil.copy2(candidate/'gsc/_t-c-1.scm',view/'gsc/_t-c-1.scm')
    shutil.copy2(candidate/'gsc/igsc.scm',view/'gsc/igsc.scm')
    configured=(runtime/'include/gambit.h').read_text()
    if '___GVM_HOST_LAYOUT' in configured:raise ValueError('reference runtime already has a host plan')
    planned=configured.replace('\n#ifdef ___SINGLE_HOST','\n'+guard+'\n#ifdef ___SINGLE_HOST',1)
    (view/'include/gambit.h').write_text(planned)
    (ctx.directory/'gambit.h').write_text(planned)
    ctx.bind(list(dict.fromkeys(bound)))
    saved=dict(ctx.env)
    ctx.env.update(GAMBIT_BOOT_GSI=str(view/'gsi/gsi'),
        GAMBOPT=f'~~={view},~~bin={runtime}/bin,~~lib={view}/lib,~~include={view}/include',
        PATH=str(runtime/'bin')+':/opt/homebrew/bin:/usr/bin:/bin')
    try:
        probe=ctx.directory/'host-header.c';probe.write_text('#include "gambit.h"\n')
        args=[ctx.tools['gcc'],'-E','-dM','-D___SINGLE_HOST','-D___GVM_HOST_LAYOUT=1',probe]
        ctx.require('planned-host-header',args,ctx.directory,20)
        if ('#define ___MULTIPLE_HOSTS' not in ctx.last_stdout
                or '#define ___GVM_HOST_LAYOUT_SUPPORTED 1' not in ctx.last_stdout
                or '#define ___SINGLE_HOST ' in ctx.last_stdout):
            raise ValueError('configured header did not select procedure hosts')
        code,_,timeout,_=ctx.run('unsupported-host-layout',
            [ctx.tools['gcc'],'-E','-D___GVM_HOST_LAYOUT=2',probe],ctx.directory,20)
        if code!=1 or timeout or 'Unsupported GVM host layout' not in ctx.last_stderr:
            raise ValueError('unsupported host layout negative failed')
        ctx.commands[-1].update(expectedExit=1,negativeControl=True)
        ok,bootstrap=regenerate_module(Stages(ctx),view,'gsc/_t-c-1.scm',180,interpreted=True)
        if not ok:raise ValueError('actual source compiler regeneration failed')
        bootstrap_c=ctx.directory/'_t-c-1.c'
        if '#define ___GVM_HOST_LAYOUT 1' not in bootstrap_c.read_text():
            raise ValueError('interpreted source compiler did not emit its host plan')
        def consume(input_file,output):
            expression=('(let ((p (compile-file '+json.dumps(str(input_file))+
                ' output: '+json.dumps(str(output))+' cc-options: "-g"))) '
                '(unless (equal? p '+json.dumps(str(output))+') (error "C consumer result" p)))')
            ctx.require('host-native-'+output.stem,[runtime/'gsc/gsc','-e',expression],ctx.directory,180)
            if not output.is_file():raise ValueError('native C product missing')
        # Keep compiler initialization coherent: never hot-load a backend into
        # an already initialized primitive table. Use the original Make owner.
        compiler_dir=view/'gsc'
        for item in (runtime/'gsc').iterdir():
            if item.is_file() and item.suffix in {'.c','.o','.a'}:
                shutil.copy2(item,compiler_dir/item.name)
                bound.append(item)
        for name in ('_gambit.c','libgambit.a'):
            (view/'lib'/name).symlink_to(runtime/'lib'/name)
            bound.append(runtime/'lib'/name)
        ctx.bind(list(dict.fromkeys(bound)))
        shutil.copy2(bootstrap_c,compiler_dir/'_t-c-1.c')
        (compiler_dir/'gsc').unlink()  # Do not link through the reference symlink.
        # The sole header delta selects hosts only for planned C. Retained
        # unplanned objects see unchanged macros and need no recompilation.
        ctx.require('host-compiler-link',['make','-j2','-o','../include/gambit.h','gsc'],
                    compiler_dir,180)
        if not (compiler_dir/'gsc').is_file() or (compiler_dir/'gsc').is_symlink():
            raise ValueError('private coherent compiler missing')
        def emit(input_file,output):
            ctx.require('host-generate-'+output.stem,[compiler_dir/'gsc','-c','-o',output,
                '-module-ref',output.stem,'-linker-name',output.stem+'.o1',
                '-cc-options','-g','-debug-source','-track-scheme','-target','C',input_file],
                ctx.directory,180)
            if '#define ___GVM_HOST_LAYOUT 1' not in output.read_text():
                raise ValueError('generated procedure-host contract missing')
        actual=ctx.directory/source.with_suffix('.c').name
        emit(source,actual)
        witness=gvm_host_witness(reference.read_text(),actual.read_text())
        old_header=ctx.directory/'old-header';old_header.mkdir()
        shutil.copy2(runtime/'include/gambit.h',old_header/'gambit.h')
        missing=old_header/'missing-host-header.c'
        missing.write_text('#define ___GVM_HOST_LAYOUT 1\n#include "gambit.h"\n'
            '#ifndef ___GVM_HOST_LAYOUT_SUPPORTED\n'
            '#error GVM_host_plan_requires_matching_runtime_header\n#endif\n')
        code,_,timeout,_=ctx.run('unqualified-host-header',
            [ctx.tools['gcc'],'-E',missing],old_header,20)
        if code!=1 or timeout or 'GVM_host_plan_requires_matching_runtime_header' not in ctx.last_stderr:
            raise ValueError('unqualified runtime header was not refused')
        ctx.commands[-1].update(expectedExit=1,negativeControl=True)
        consume(actual,actual.with_suffix('.o1'))
        for fixture in fixtures[:2]:
            copied=ctx.directory/fixture.name;shutil.copy2(fixture,copied)
            generated=copied.with_suffix('.c');emit(copied,generated)
            consume(generated,copied.with_suffix('.o1'))
        expression=' '.join('(load '+json.dumps(str(p))+')' for p in (
            ctx.directory/'host-a.o1',ctx.directory/'host-b.o1',fixtures[2]))
        ctx.require('host-runtime-controls',[runtime/'gsi/gsi','-e',expression],ctx.directory,60)
        if 'GVM-HOST-MODULE-GC-CONTINUATION-TAIL-PASS' not in ctx.last_stdout.splitlines():
            raise ValueError('real host runtime control marker missing')
        observation=ctx.directory/'host-layout.json'
        observation.write_text(json.dumps(dict(componentPassed=True,witness=witness,
            sourceFiles=profile['sourceFiles'],runtimeFiles=profile['runtimeFiles'],
            bootstrapC=dict(path=str(bootstrap_c),sha256=digest(bootstrap_c)),
            actualInput=dict(path=str(source),sha256=digest(source)),
            candidateC=dict(path=str(actual),sha256=digest(actual)),
            fullCompilerPassed=False,bothPackagesPassed=False,packageSpeedup=None),indent=2)+'\n')
        return dict(outputs=ctx.publish('observations','gerbil-test-observations',observation))
    finally:
        ctx.env.clear();ctx.env.update(saved)
