"""Gerbil build: bootstrap observation."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import json
import shutil


def _compare_bootstrap_headers(ctx, reference_header, current_header):
    import re, shlex
    ctx.bind([Path(ctx.tools['gcc']).resolve(strict=True)])
    keys=('___SINGLE_VM','___MULTIPLE_VMS','___SINGLE_THREADED_VMS',
        '___MULTIPLE_THREADED_VMS','__STDC_VERSION__','__cplusplus')
    result={}
    for role,header in [('reference',reference_header),('current',current_header)]:
        text=ctx.require('bootstrap-'+role+'-cpp',[ctx.tools['gcc'],
            *shlex.split(ctx.env.get('CFLAGS','')),'-D___LIBRARY','-D___PRIMAL',
            '-dM','-E','-x','c','-include',header,'/dev/null'],ctx.root,min(10,ctx.remaining()))
        macros=dict(re.findall(r'^#define ([A-Za-z_][A-Za-z_0-9]*)(?:[ \t]+(.*))?$',text,re.MULTILINE))
        result[role]={k:macros.get(k) for k in keys}
    return result


def _observe_installed_bootstrap_reference(ctx, reference, current_header):
    from gambit_smp.native_capabilities import fields
    fields(reference,('header','buildReceipt','providerReceipt','gsc'))
    paths={}
    for role,row in reference.items():
        fields(row,('path','sha256'))
        path=Path(row['path']).resolve(strict=True)
        if not path.is_file() or digest(path)!=row['sha256']:
            raise ValueError('installed reference bytes differ: '+role)
        paths[role]=path;ctx.bind([path])
    header=paths['header'];receipt=json.loads(paths['buildReceipt'].read_text())
    provider=json.loads(paths['providerReceipt'].read_text())
    home=Path(provider['environment']['GERBIL_HOME']).resolve(strict=True)
    if header != (home/'include/gambit.h').resolve() or paths['gsc'] != (home/'bin/gsc').resolve():
        raise ValueError('provider does not select the observed reference files')
    folder=ctx.directory/'installed-reference-metadata';folder.mkdir()
    for source in header.parent.glob('*.h'):
        if source.is_symlink() or not source.is_file():raise ValueError('reference include alias requires explicit custody')
        ctx.bind([source]);shutil.copy2(source,folder/source.name)
    return dict(referenceKind='installed-Bazel-provider-not-published-archive',
        files=reference,producerReceipt=receipt,providerReceipt=provider,
        executedReferenceCode=False,headersUnderCurrentC23Compiler=
            _compare_bootstrap_headers(ctx,folder/'gambit.h',current_header),
        missingEvidence=['Exact published archive c53d62f2 was not acquired; local installation is a distinct cohort'])


def _failed_bootstrap_invocation(ctx, proof, record):
    """Decode only the attested original Make invocation, never caller argv."""
    import re, shlex
    command=proof['stages']['build']
    path=(record.parent/command['stdoutPath']).resolve(strict=True)
    if not path.is_relative_to(ctx.root.resolve()) or digest(path)!=command['stdoutSha256']:
        raise ValueError('original failed command stdout identity differs')
    lines=[v for v in path.read_text().splitlines()
        if v.startswith('../gsc-boot ') and v.endswith(' _io.scm')]
    if len(lines)!=1:raise ValueError('one original _io Scheme emission invocation required')
    argv=shlex.split(lines[0])
    prefix=['../gsc-boot','-:~~bin=../bin,~~lib=../lib,~~include=../include','-f','-c','-prelude']
    if (len(argv)!=7 or argv[:5]!=prefix or argv[-1]!='_io.scm'
            or not re.fullmatch(r'(?:\(define-cond-expand-feature\|[a-z0-9-]+\|\))+\(##include"../lib/header\.scm"\)',argv[5])):
        raise ValueError('failed bootstrap invocation exceeds the closed original emission contract')
    ctx.bind([path]);return argv


def observe_bazel_bootstrap(ctx, profile, evidence, *, trace=None):
    """Observe a retained failed producer, never rebuild or admit its runtime.

    Permit version/empty-source controls or one closed fatal-stack diagnostic.
    The original paths, default processor policy and fixed RSS owner stay intact.
    """
    import re
    from gambit_smp.artifact_storage import fixture_root
    from gambit_smp.workspace import task_output, write
    retained = json.loads(evidence.read_text())
    refs = [r for r in retained['rawEvidence'] if Path(r['path']).name == 'bazel-compiler-result.json']
    if len(refs) != 1:
        raise ValueError('one retained source-producer result required')
    record = (ctx.root/refs[0]['path']).resolve(strict=True)
    if not record.is_relative_to(ctx.root) or digest(record) != refs[0]['sha256']:
        raise ValueError('retained failed producer identity differs')
    proof = json.loads(record.read_text())
    expected = dict(gambit=profile['gambit']['baselineCommit'], gerbil=profile['gerbil']['revision'])
    command = proof.get('stages',{}).get('build',{})
    if (proof.get('heads') != expected or proof.get('constructionPassed') is not False
            or proof.get('blockedAt') != 'build' or command.get('exit') in (None, 0)
            or command.get('timeout') is not False or command.get('parentReaped') is not True
            or command.get('processGroupQuiescent') is not True):
        raise ValueError('matching failed, reaped and quiescent CI construction required')
    source = Path(proof['source']).resolve(strict=True)
    fixture_root(ctx.root, source)
    if task_output(ctx.root, source) != source:
        raise ValueError('bootstrap belongs to another task owner')
    runtime = source/'src/gambit'
    boot, header, features = runtime/'gsc-boot', runtime/'include/gambit.h', runtime/'lib/Makefile'
    if digest(boot) != retained.get('bootstrapSha256'):
        raise ValueError('retained bootstrap executable identity differs')
    for name, path in [('gerbil',source), ('gambit',runtime)]:
        head = ctx.require('bootstrap-'+name+'-head', [ctx.tools['git'],'-C',path,'rev-parse','HEAD'],ctx.root,10).strip()
        if head != expected[name]:raise ValueError('bootstrap checkout identity differs')
    if (digest(header) != proof['generatedProfile']['headerSha256']
            or digest(features) != proof['generatedProfile']['featuresSha256']
            or not all(proof['generatedProfile'].get(k) is True for k in ('multipleThreadedVms','multipleVms','smp'))
            or not all(re.search(r'^#define ___'+k+r'\s*$',header.read_text(),re.MULTILINE) for k in ('MULTIPLE_THREADED_VMS','MULTIPLE_VMS'))
            or not re.search(r'^PRELUDE_OPT\s*=.*\(define-cond-expand-feature\|enable-smp\|\)',features.read_text(),re.MULTILINE)):
        raise ValueError('actual retained three-switch profile differs')
    ctx.bind([evidence, record, boot, header, features])
    saved = dict(ctx.env)
    observations = []
    try:
        for key in ('GERBIL_HOME','GERBIL_PATH','GERBIL_LOADPATH','GERBIL_GSC','GAMBOPT','CPATH','LIBRARY_PATH'):
            ctx.env.pop(key,None)
        ctx.env.update(profile['environment'])
        options = '-:~~bin='+str(runtime/'bin')+',~~lib='+str(runtime/'lib')+',~~include='+str(runtime/'include')
        expression = '(begin (display "BOOT-USER-REACHED") (newline))'
        reused_entry = False
        if trace == 'header-comparison':
            from gambit_smp.native_capabilities import fields
            if 'referenceFiles' not in retained or 'entryObservation' not in retained:
                raise ValueError('header comparison requires authenticated reference and retained entry controls')
            entry=retained['entryObservation'];fields(entry,('path','sha256'))
            path=(ctx.root/entry['path']).resolve(strict=True)
            if not path.is_relative_to(ctx.root) or digest(path)!=entry['sha256']:
                raise ValueError('retained entry observation identity differs')
            prior=json.loads(path.read_text())
            if (prior.get('bootstrapSha256')!=digest(boot) or prior.get('debuggerContext') is not False
                    or {v.get('role') for v in prior.get('observations',[])}!={'version','empty-source-entry'}
                    or len(prior['observations'])!=2
                    or any(v['process'].get('timeout') is not False
                        or v['process'].get('parentReaped') is not True
                        or v['process'].get('processGroupQuiescent') is not True for v in prior['observations'])):
                raise ValueError('complete same-binary entry observations required')
            ctx.bind([path]);observations=prior['observations'];reused_entry=True;requests=[]
        elif trace:
            # A debugger changes execution context. Its stack is diagnostic,
            # never an original-run time or successful-runtime receipt.
            resolver = Path(shutil.which('xcrun',path=ctx.env['PATH']) or '/usr/bin/xcrun').resolve(strict=True)
            ctx.bind([resolver])
            debugger = Path(ctx.require('bootstrap-debugger-path',[resolver,'--find','lldb'],ctx.root,10).strip()).resolve(strict=True)
            ctx.bind([debugger])
            if trace == 'failed-command-stack':
                invocation=_failed_bootstrap_invocation(ctx,proof,record)
                requests=[('failed-command-stack',[debugger,'--batch',
                    '-o','breakpoint set --name ___fatal_error','-o','run',
                    '-o','thread backtrace all','-o','process kill','--',boot,*invocation[1:]])]
            elif trace == 'disassembly':
                requests = [('section-disassembly',[debugger,'--batch','-o','disassemble --name ___setup_mem_pstate',
                    '-o','disassemble --name ___vm_resize_pstate','--',boot])]
            elif trace == 'section-capacity':
                from gambit_smp.native_capabilities import fields
                layout = retained['bootstrapLayout']
                offsets = ('processorStack','vmCount','vmSections','vmAssigned','vmTarget','sectionNext')
                registers = ('processorRegister','vmRegister','iterationRegister','initialRegister','targetRegister')
                fields(layout,('bootstrapSha256','disassembly','processorFrame','vmFrame',*offsets,*registers))
                if digest(boot) != layout['bootstrapSha256']:
                    raise ValueError('section offset map is not qualified for this executable')
                for key in (*offsets,'processorFrame','vmFrame'):
                    if type(layout[key]) is not int or not 0 <= layout[key] <= (32 if key.endswith('Frame') else 1<<24):
                        raise ValueError('bounded numeric section layout required')
                if any(not re.fullmatch(r'x(?:[0-9]|[12][0-9]|30)',layout[key]) for key in registers):
                    raise ValueError('closed arm64 register map required')
                disassembly = (ctx.root/layout['disassembly']['path']).resolve(strict=True)
                if not disassembly.is_relative_to(ctx.root) or digest(disassembly) != layout['disassembly']['sha256']:
                    raise ValueError('section layout lacks its retained disassembly')
                ctx.bind([disassembly])
                ps = '$'+layout['processorRegister'];vm = '$'+layout['vmRegister']
                address = lambda base,key:base+'+'+hex(layout[key])
                sections = '*(unsigned long*)('+address(vm,'vmSections')+')'
                commands = ['breakpoint set --name ___fatal_error','run','thread backtrace all',
                    'frame select '+str(layout['processorFrame']),'register read '+layout['processorRegister'],
                    'memory read --format x --size 8 --count 7 '+address(ps,'processorStack'),
                    'frame select '+str(layout['vmFrame']),
                    'register read '+' '.join(layout[k] for k in registers[1:]),
                    'memory read --format u --size 4 --count 1 '+address(vm,'vmCount'),
                    'memory read --format x --size 8 --count 2 '+address(vm,'vmSections'),
                    'memory read --format u --size 4 --count 2 '+address(vm,'vmAssigned'),
                    'memory read --format u --size 4 --count 1 '+address(vm,'vmTarget'),
                    'memory read --format u --size 4 --count 2 `'+sections+'`',
                    'memory read --format x --size 8 --count 1 `*(unsigned long*)('+address(vm,'vmSections')+'+8)+'+str(layout['sectionNext'])+'`',
                    'process kill']
                requests = [('section-capacity',[debugger,'--batch',
                    *[item for command in commands for item in ('-o',command)],
                    '--',boot,options,'-f','-e',expression])]
            else:
                requests = [('fatal-stack',[debugger,'--batch','-o','breakpoint set --name ___fatal_error',
                    '-o','run','-o','thread backtrace all','-o','process kill','--',boot,options,'-f','-e',expression])]
        else:
            requests = [('version',[boot,'-v']), ('empty-source-entry',[boot,options,'-f','-e',expression])]
        for role, argv in requests:
            code, _, timeout, seconds = ctx.run('bootstrap-'+role,argv,runtime/'lib',10)
            process = dict(ctx.commands[-1])
            if (timeout or process.get('parentReaped') is not True
                    or process.get('processGroupQuiescent') is not True):
                raise ValueError('bootstrap observation completion unknown')
            observations.append(dict(role=role,exit=code,seconds=seconds,
                userMarker='BOOT-USER-REACHED' in ctx.last_stdout,process=process))
        reference = (_observe_installed_bootstrap_reference(ctx,retained['referenceFiles'],header)
            if 'referenceFiles' in retained else None)
        output = ctx.directory/'bootstrap-observation.json'
        write(output,dict(referenceComparison=reference,source=str(source),bootstrapSha256=digest(boot),observations=observations,entryEvidenceReused=reused_entry,debuggerContext=bool(trace and trace!='header-comparison'),traceMode=trace,
            originalBuildSeconds=command['seconds'],constructionPassed=False,packageReady=False,
            runtimeAdmitted=False,packageSpeedup=None,mergeAllowed=False))
        return dict(outputs=ctx.publish('observations','gerbil-build-observations',output))
    finally:
        ctx.env.clear();ctx.env.update(saved)
