"""Gerbil build: package."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import os
import shutil


def observe_runtime(ctx, program, output, *, stage, diagnostic_after_seconds=None):
    """Read public runtime identity as native JSON, never infer it from a path."""
    expression=('(begin (import :std/encoding/json) (call-with-output-file '
        +json.dumps(str(output),ensure_ascii=False)
        +' (lambda (port) (write-json port (hash ("home" (gerbil-home)) '
        '("bin" (path-expand "~~bin")) ("version" (system-version-string)) '
        '("configure" (configure-command-string)) ("smp" (gerbil-runtime-smp?)))))))')
    options={}
    if diagnostic_after_seconds is not None:
        tool=ctx.tools.get('darwinSample')
        if tool is None:raise ValueError('sealed Darwin runtime sampler required')
        directory=output.parent/'runtime-observation';directory.mkdir()
        files=ctx.tools.get('darwinOpenFiles')
        if files is None:raise ValueError('sealed Darwin open-file observer required')
        options['diagnostic']=dict(tool=tool,toolSha256=digest(Path(tool)),
            directory=str(directory),afterSeconds=diagnostic_after_seconds,
            openFilesTool=files,openFilesToolSha256=digest(Path(files)))
    ctx.require(stage,[program,'-e',expression],ctx.directory,min(30,ctx.remaining()),**options)
    data=json.loads(output.read_text())
    if (set(data)!={'home','bin','version','configure','smp'}
            or any(type(data[key]) is not str for key in ('home','bin','version','configure'))
            or type(data['smp']) is not bool):
        raise ValueError('complete native runtime identity required')
    if Path(data['bin']).resolve(strict=True)!=Path(data['home']).resolve(strict=True)/'bin':
        raise ValueError('launcher runtime home/bin identity mismatch')
    return data


def observe_compiler_services(ctx, profile, home, launchers, identity):
    """Discriminate retained package failures without rebuilding either package.

    These are fixed, source-bound probes in the existing test capability.
    They never qualify a compiler, package, performance result or retry budget.
    """
    import os
    roots={key:(ctx.root/value).resolve(strict=True)
           for key,value in profile['packageSources'].items()}
    store=ctx.root/'.cache/tasks'/os.environ['GAMBIT_SMP_TASK_ID']
    if not all(root.is_relative_to(store) for root in roots.values()):
        raise ValueError('diagnostics require retained same-task package workspaces')
    inputs=[p for root in roots.values() for name in ('gerbil.pkg','.gerbil/lib','data')
            for p in ([root/name] if (root/name).is_file() else (root/name).rglob('*'))
            if p.is_file()]
    ctx.bind(inputs+[p for name in ('bin','lib','include') for p in (home/name).rglob('*') if p.is_file()])
    logical=Path(identity['home']) if identity is not None else home
    if logical.resolve(strict=True)!=home:raise ValueError('diagnostic runtime home drift')
    saved=dict(ctx.env);rows={}
    def observe(role,argv,cwd,cap):
        ctx.run(role,argv,cwd,min(cap,ctx.remaining()))
        command=ctx.commands[-1]
        if (role=='expander-cold' and command.get('exit')==70
                and 'Bad syntax; illegal import' in ctx.last_stdout+ctx.last_stderr):
            command.update(expectedExit=70,negativeControl=True)
        if (role=='linker-build-ambient' and command.get('exit')==1
                and 'Undefined symbols' in ctx.last_stdout+ctx.last_stderr):
            command.update(expectedExit=1,negativeControl=True)
        rows[role]=dict(ctx.commands[-1],stdout=ctx.last_stdout,stderr=ctx.last_stderr)
        return rows[role]
    try:
        ctx.env.update(profile.get('environment',{}))
        ctx.env.update(GERBIL_HOME=str(logical),GERBIL_BUILD_PREFIX=str(logical),
            GERBIL_PATH=str(ctx.directory/'user'),GERBIL_LOADPATH=str(logical/'lib'),
            GERBIL_GSC=str(logical/'bin/gsc'),GERBIL_GCC=str(ctx.tools['gcc']),
            GERBIL_MCP_GXI_PATH=str(logical/'bin/gxi'),
            GAMBOPT=f'~~={logical},~~bin={logical}/bin,~~lib={logical}/lib,~~include={logical}/include')
        if not launchers:ctx.env['PATH']=str(logical/'bin')+os.pathsep+ctx.env['PATH']
        source=ctx.directory/'linker.c'
        source.write_text('#include <stdio.h>\nint main(void) { return puts("LINKER-CONSUMER-OK") < 0; }\n')
        for label,compiler_path in (('ambient',ctx.env.get('COMPILER_PATH')),('apple','/usr/bin')):
            if compiler_path is None:ctx.env.pop('COMPILER_PATH',None)
            else:ctx.env['COMPILER_PATH']=compiler_path
            observe('linker-search-'+label,[ctx.tools['gcc'],'-print-prog-name=ld'],ctx.directory,10)
            binary=ctx.directory/('linker-'+label)
            linked=observe('linker-build-'+label,[ctx.tools['gcc'],'-v','-Wl,-v',source,'-o',binary],ctx.directory,20)
            if linked.get('exit')==0 and not linked.get('timeout'):
                observe('linker-consumer-'+label,[binary],ctx.directory,10)
        ctx.env['COMPILER_PATH']='/usr/bin'
        fixture=ctx.directory/'expander-consumer.ss'
        fixture.write_text('(import :gerbil/expander (only-in :gerbil/runtime/init gerbil-load-expander!))\n'
            '(export main)\n(def (main mode target)\n'
            ' (when (equal? mode "ready") (gerbil-load-expander!))\n'
            ' (import-module target #f #f)\n (displayln "EXPANDER-CONSUMER-OK"))\n')
        target=ctx.directory/'import-target.ss'
        target.write_text('(import (only-in :gerbil/runtime/hash HashTable))\n(export answer)\n(def answer 42)\n')
        program=ctx.directory/'expander-consumer'
        gxc=launchers.get('gxc',{}).get('path',str(logical/'bin/gxc'))
        built=observe('expander-consumer-build',[gxc,'-exe','-o',program,fixture],ctx.directory,120)
        if built.get('exit')==0 and not built.get('timeout'):
            for mode in ('cold','ready'):
                observe('expander-'+mode,[program,mode,str(target)],ctx.directory,30)
            ctx.env['GERBIL_LOADPATH']=str(roots['poo']/'.gerbil/lib')+os.pathsep+str(logical/'lib')
            real=roots['poo']/'.gerbil/lib/clan/poo/t/variant-validation-test.ssi'
            if not real.is_file():
                rows['pooInterface']=dict(status='MISSING_INPUT',path=str(real),passed=False)
            else:
                for mode in ('cold','ready'):
                    observe('poo-interface-'+mode,[program,mode,str(real)],roots['poo'],90)
        observe('gambit-version',[logical/'bin/gsc','-v'],ctx.directory,10)
        mcp_child_service_probes(ctx,roots,logical,observe)
    finally:
        ctx.env.clear();ctx.env.update(saved)
        output=ctx.directory/'compiler-service-observations.json'
        output.write_text(json.dumps(dict(observations=rows,diagnosticOnly=True,
            compilerHome=str(home),runtimeHome=str(logical),packageSources={k:str(v) for k,v in roots.items()},
            wholePackagePassed=False,packageSpeedup=None,targetCompilerAdmitted=False),indent=2)+'\n')
    if any(row.get('status')=='MISSING_INPUT' for row in rows.values()):
        raise ValueError('independent probes retained; missing POO interface is not a passed control')
    return dict(outputs=ctx.publish('observations','gerbil-test-observations',output))


def package_test_scope(source,kind,budgets):
    """Keep original leaf limits; account for just test's build prerequisite."""
    import re
    if kind=='mcp':
        source=Path(source);path=source/'scripts/run-tests.sh';text=path.read_text()
        required=('N="${TEST_JOBS:-2}"','timeout 240 "$GERBIL" test "$file"',
                  '[ $((i % N)) -eq 0 ] && wait','run_test_file test/unit',
                  'run_test_file test/protocol-test.ss')
        chunks=len(list((source/'test').glob('chunk-*-test.ss')))
        if chunks==0 or not all(token in text for token in required):
            raise ValueError('original MCP batch scope changed; refuse guessed watchdog')
        tail=any((source/name).exists() for name in ('test/unit','test/protocol-test.ss'))
        batches=(chunks+1)//2+int(tail)
        return dict(totalSeconds=batches*240+budgets['clean'],perFileSeconds=240,
            parallelJobs=2,chunkFiles=chunks,batches=batches,
            coordinationSeconds=budgets['clean'],sourceSha256=digest(path),
            entry='scripts/run-tests.sh',termination='Original SIGTERM policy; outer supervisor owns forced drain')
    if kind!='poo':raise ValueError('original package test scope required')
    path=Path(source)/'justfile';text=path.read_text()
    build=re.search(r'(?m)^build \*selection:\n((?:[ \t].*\n|\n)+)',text)
    if (not re.search(r'(?m)^test: build\n    just _test t '+str(budgets['test'])+r'\s*$',text)
            or build is None or '--signal=TERM --kill-after=3s 1200s gxi' not in build[1]
            or '--signal=TERM --kill-after=5s {{ max-seconds }}s "${test_command[@]}"' not in text):
        raise ValueError('original POO prerequisite/runtime budget scope changed; refuse guessed watchdog')
    return dict(totalSeconds=1200+3+budgets['test']+5+budgets['clean'],
        prerequisiteBuildSeconds=1200,runtimeSeconds=budgets['test'],
        prerequisiteKillGraceSeconds=3,runtimeKillGraceSeconds=5,
        coordinationSeconds=budgets['clean'],sourceSha256=digest(path),entry='just test')


def execute_package(ctx, compiler_home, checkout, *, kind, budgets, diagnostic_after_seconds=None, launchers=None,
                    expected_smp=None, runtime_home=None):
    """Run a complete package request in the existing owned build workspace.

    This is one shared executor, not a new runner or a performance-admission
    shortcut. Callers own the bound compiler/runtime profile and fixed budgets.
    Working source bytes are snapshotted, never replaced by HEAD-only archives.
    """
    import os
    import re
    import time
    import traceback
    from gambit_smp.recipes import tree_identity
    from gambit_smp.workspace import build_output, sync_build_source, checkpoint_build_source, write
    from gambit_smp.source_capabilities import source_name
    from gambit_smp.native_capabilities import fields
    fields(budgets, ('clean', 'build', 'test'))
    if expected_smp is not None and type(expected_smp) is not bool:
        raise ValueError('explicit boolean runtime profile required')
    if kind not in ('mcp', 'poo') or any(type(v) is not int or v <= 0 for v in budgets.values()):
        raise ValueError('declared package and positive fixed stage budgets required')
    compiler_home, checkout = Path(compiler_home).resolve(), Path(checkout).resolve()
    # A read-only compiler prefix is a tool input, not a writable source lease.
    # Core readiness and copied Scheme tools must never qualify a package CLI.
    required = ['bin/gerbil', 'bin/gxi', 'bin/gxc', 'bin/gsc', 'bin/gxpkg',
                'bin/gxtest', 'include/gambit.h']
    for tool in ('gxpkg', 'gxtest'):
        required.extend('lib/gerbil/tools/'+tool+suffix for suffix in ('.ssi', '~0.o1'))
    if any(not (compiler_home/name).is_file() for name in required):
        raise ValueError('complete compiled package-tool prefix required; core/source fallback is not qualified')
    executable = compiler_home/'bin/gerbil'
    launchers = launchers or {}
    if launchers and set(launchers) != {'gerbil', 'gxi', 'gxc'}:
        raise ValueError('complete current-PATH Gerbil launcher identity required')
    def launcher_inputs_current():
        try:
            return all(Path(row['path']).resolve(strict=True) == Path(row['resolved'])
                       and digest(Path(row['resolved'])) == row['sha256']
                       for row in launchers.values())
        except OSError:
            return False
    if not launcher_inputs_current():
        raise ValueError('current-PATH Gerbil launcher changed before package entry')
    ctx.bind([Path(row['resolved']) for row in launchers.values()])
    compiler_files = sorted(path for base in ('bin', 'lib', 'include', 'src')
                            for path in (compiler_home/base).rglob('*') if path.is_file())
    compiler_inputs = {str(path.relative_to(compiler_home)): digest(path) for path in compiler_files}
    ctx.bind(compiler_files)
    profile = hashlib.sha256(json.dumps(compiler_inputs,sort_keys=True).encode()).hexdigest()
    runtime_home = Path(runtime_home) if runtime_home is not None else compiler_home
    if runtime_home.resolve(strict=True) != compiler_home:
        raise ValueError('logical runtime home differs from selected compiler identity')
    directory = ctx.directory/(kind+'-package')
    directory.mkdir()
    saved_environment = dict(ctx.env)
    effective_environment={key:saved_environment.get(key) for key in (
        'PATH','COMPILER_PATH','LIBRARY_PATH','CFLAGS','CPPFLAGS','LDFLAGS','SDKROOT',
        'MACOSX_DEPLOYMENT_TARGET','PKG_CONFIG_PATH','GERBIL_BUILD_CORES')}
    effective_environment.update(GERBIL_HOME=str(runtime_home),GERBIL_GCC=str(ctx.tools['gcc']))
    process_profile=hashlib.sha256(json.dumps(dict(compiler=profile,environment=effective_environment),
                                             sort_keys=True).encode()).hexdigest()
    result = dict(package=kind, wholePackagePassed=False, packageSpeedup=None,
                  mergeAllowed=False, sourceClosureAdmitted=False,
                  stages={}, declaredBudgets=budgets, pathLaunchers=launchers)
    source = None
    def command(stage, argv, cwd, cap):
        diagnostic=None
        if stage=='clean' and diagnostic_after_seconds is not None:
            tool=ctx.tools.get('darwinSample')
            if tool is None:raise ValueError('sealed Darwin sampling tool required')
            target=directory/'clean-observation';target.mkdir()
            diagnostic=dict(tool=tool,toolSha256=digest(Path(tool)),directory=str(target),
                            afterSeconds=diagnostic_after_seconds)
            result['cleanStackObservationRequested']=True
            result['timingAdmitted']=False
        code, log, timed_out, seconds = ctx.run(kind+'-'+stage, argv, cwd, min(cap,ctx.remaining()),
            **({'diagnostic':diagnostic} if diagnostic is not None else {}))
        observed = ctx.commands[-1]
        complete = (type(code) is int and code == 0 and not timed_out
                    and observed.get('parentReaped') is True
                    and observed.get('processGroupQuiescent') is True)
        result['stages'][stage] = dict(exit=code,timeout=timed_out,seconds=seconds,
            parentReaped=observed.get('parentReaped'),
            processGroupQuiescent=observed.get('processGroupQuiescent'),complete=complete)
        return complete
    try:
        names=ctx.require(kind+'-source-list',
            [ctx.tools['git'],'-C',checkout,'ls-files','--cached','--others','--exclude-standard','-z'],
            ctx.root,min(10,ctx.remaining())).split('\0')
        names=sorted({name for name in names if name and (checkout/name).exists()})
        if not names or 'build.ss' not in names or 'gerbil.pkg' not in names:
            raise ValueError('complete package source inventory required')
        staged=directory/'inputs';staged.mkdir()
        manifest={}
        for name in names:
            source_name(name)
            origin=checkout/name
            if origin.is_symlink() or not origin.is_file():
                raise ValueError('package alias/submodule requires an explicit source closure: '+name)
            target=staged/name;target.parent.mkdir(parents=True,exist_ok=True)
            manifest[name]=dict(sha256=digest(origin),mode=origin.stat().st_mode&0o777)
            shutil.copy2(origin,target)
        if any(digest(checkout/name)!=row['sha256'] or digest(staged/name)!=row['sha256']
               for name,row in manifest.items()):
            raise ValueError('package source changed during snapshot')
        head=ctx.require(kind+'-source-head',
            [ctx.tools['git'],'-C',checkout,'rev-parse','HEAD'],ctx.root,min(3,ctx.remaining())).strip()
        if not re.fullmatch('[0-9a-f]{40}',head):
            raise ValueError('actual source revision required')
        work=build_output(ctx.root,'gerbil',compiler=executable,
            flags=['package',kind,str(checkout),profile,process_profile],
            derivation=dict(role='working-consumer',inputSha256=profile))
        source=work/'source';source.mkdir(exist_ok=True)
        ctx.lease_workspace(source,tree_identity(source))
        delta=sync_build_source(ctx.root,work,staged,consume_staged=True)
        shutil.rmtree(staged)
        # Local metadata preserves Git-aware package/test behavior. Reset is
        # mixed: it updates only the private index, never the snapshotted bytes.
        if not (source/'.git').exists():
            ctx.require(kind+'-git-init',[ctx.tools['git'],'init','--initial-branch=darwin',source],
                        ctx.root,min(5,ctx.remaining()))
        ctx.require(kind+'-git-fetch',[ctx.tools['git'],'-C',source,'fetch','--no-tags',
                    '--depth=1',str(checkout),head],ctx.root,min(10,ctx.remaining()))
        ctx.require(kind+'-git-index',[ctx.tools['git'],'-C',source,'reset','--mixed','FETCH_HEAD'],
                    ctx.root,min(5,ctx.remaining()))
        if any(digest(source/name)!=row['sha256'] for name,row in manifest.items()):
            raise ValueError('private Git setup changed package source')
        ctx.bind([source/name for name in names])
        write(directory/'source.json',dict(checkout=str(checkout),head=head,
              files=manifest,work=str(source),delta=delta))
        ctx.env.update(GERBIL_HOME=str(runtime_home),
            GERBIL_GSC=str(runtime_home/'bin/gsc'),
            GERBIL_GCC=str(ctx.tools['gcc']),
            GAMBOPT=','.join('~~'+key+'='+str(runtime_home/path) for key,path in
                           (('','.'),('bin','bin'),('lib','lib'),('include','include'))),
            GERBIL_PATH=str(source/'.gerbil'),
            GERBIL_LOADPATH=str(source)+':'+str(runtime_home/'lib'),
            GERBIL=launchers.get('gerbil', {}).get('path', str(executable)),
            GERBIL_MCP_GXI_PATH=str(runtime_home/'bin/gxi'),
            GERBIL_MCP_GXC_PATH=str(runtime_home/'bin/gxc'),
            GERBIL_MCP_GERBIL_PATH=str(executable),
            GERBIL_MCP_GXPKG_PATH=str(runtime_home/'bin/gxpkg'),
            PATH=(saved_environment.get('PATH','') if launchers else
                  str(runtime_home/'bin')+os.pathsep+saved_environment.get('PATH','')))
        result.update(workspace=str(source),sourceSnapshotSha256=
            hashlib.sha256(json.dumps(manifest,sort_keys=True).encode()).hexdigest(),
            sourceHead=head,compilerSha256=digest(executable),compilerInputsSha256=profile,
            compilerHome=str(compiler_home),compilerFileCount=len(compiler_inputs),
            processProfileSha256=process_profile,effectiveBuildEnvironment=effective_environment,
            sourceClosureAdmitted=False)
        write(directory/'compiler-inputs.json',compiler_inputs)
        result['runtimeIdentity']=observe_runtime(ctx,
            launchers.get('gxi',{}).get('path',str(compiler_home/'bin/gxi')),
            directory/'runtime-identity.json',stage=kind+'-runtime-identity',
            diagnostic_after_seconds=diagnostic_after_seconds)
        if (Path(result['runtimeIdentity']['home']).resolve(strict=True)!=compiler_home
                or (expected_smp is not None and result['runtimeIdentity']['smp'] is not expected_smp)):
            result['blockedAt']='runtime-identity'
            raise ValueError('selected runtime differs from the admitted home/profile')
        package_entry = launchers.get('gerbil', {}).get('path', executable)
        before=time.monotonic()
        if not command('clean',[package_entry,'clean'],source,budgets['clean']):
            result['blockedAt']='clean'
            return result
        if not command('build',[package_entry,'build'],source,budgets['build']):
            result['blockedAt']='build'
            return result
        result['cleanBuildSeconds']=time.monotonic()-before
        # Capture GSC provenance after the literal cold clean/build request.
        # This must not warm its compiler before the measured build.
        code, _, timed_out, seconds = ctx.run(kind+'-compiler-version',
            [compiler_home/'bin/gsc', '-v'], source, min(10, ctx.remaining()))
        result['compilerVersion'] = dict(exit=code, timeout=timed_out, seconds=seconds,
            stdout=ctx.last_stdout, stderr=ctx.last_stderr)
        # Source lookup belongs to the build frontend. Compiled consumers must
        # resolve dependency interfaces from the same produced library tree:
        # interpreting a source override cannot supply optimizer-generated ABI
        # entry points referenced by a compiled consumer.
        ctx.env['GERBIL_LOADPATH']=str(source/'.gerbil/lib')+os.pathsep+str(runtime_home/'lib')
        result['testLibraryView']=ctx.env['GERBIL_LOADPATH']
        if kind=='mcp':
            ctx.env['TEST_JOBS']='2'
            argv=[Path('/bin/bash'),'scripts/run-tests.sh']
        else:
            just=shutil.which('just',path=ctx.env['PATH'])
            if just is None:raise FileNotFoundError('official just test entry is unavailable')
            ctx.bind([Path(just).resolve(strict=True)])
            argv=[Path(just),'test']
        result['originalTestScope']=package_test_scope(source,kind,budgets)
        complete=command('test',argv,source,result['originalTestScope']['totalSeconds'])
        text=(ctx.last_stdout or '')+'\n'+(ctx.last_stderr or '')
        if kind=='mcp':
            expected=len(list((source/'test').glob('chunk-*-test.ss')))+sum(
                (source/name).exists() for name in ('test/unit','test/protocol-test.ss'))
            markers=(expected>0 and ('files='+str(expected)+'  failed-checks=0') in text
                     and 'crashed:\n' in text and 'files-with-failures:\n' in text)
            result['stages']['test']['expectedTestEntries']=expected
        else:
            markers=(any(line.startswith('MODULE-OK ') for line in text.splitlines())
                and any(line.startswith('HARNESS-OK ') for line in text.splitlines())
                and 'OK' in text.splitlines())
        result['stages']['test']['requiredMarkersPresent']=markers
        result['wholePackagePassed']=complete and markers
        if not result['wholePackagePassed']:result['blockedAt']='test'
        return result
    except Exception as error:
        result['failure']=dict(type=type(error).__name__,detail=str(error),
                               traceback=traceback.format_exc())
        return result
    finally:
        if 'runtimeIdentity' in result:
            try:
                home_current=Path(result['runtimeIdentity']['home']).resolve(strict=True)==compiler_home
            except OSError:
                home_current=False
            if not home_current:
                result['wholePackagePassed']=False
                result['runtimeHomeDrift']=True
        if not launcher_inputs_current():
            result['wholePackagePassed']=False
            result['launcherInputDrift']=True
        if any(not (compiler_home/name).is_file() or digest(compiler_home/name)!=sha
               for name,sha in compiler_inputs.items()):
            result['wholePackagePassed']=False
            result['compilerInputDrift']=True
        if source is not None:
            checkpoint_build_source(source,phase='ready' if result['wholePackagePassed'] else 'building')
        ctx.env.clear();ctx.env.update(saved_environment)
        write(directory/'result.json',result)


def mcp_child_service_probes(ctx, roots, logical, observe):
    """Observe the real package subprocess and first recipe batch, not substitutes."""
    import os
    ctx.env['GERBIL_LOADPATH']=str(roots['mcp']/'.gerbil/lib')+os.pathsep+str(logical/'lib')
    empty=('(import :gerbil-mcp/proc) (let* ((start (real-time)) '
        '(result (run-gxi (list '+json.dumps('(displayln "GXI-EMPTY-OK")')+')))) '
        '(write (list (- (real-time) start) (gxi-result-exit-code result) '
        '(gxi-result-timed-out result) (gxi-result-stdout result) (gxi-result-stderr result))) (newline))')
    observe('mcp-empty-child',[logical/'bin/gxi','-e',empty],roots['mcp'],60)
    expression=('(import :gerbil-mcp/util/cookbook :gerbil-mcp/util/verify (only-in :gerbil-mcp/mcp/toolkit take*)) '
        '(let* ((recipes (load-recipes)) (batch (take* recipes +default-batch-size+)) '
        '(start (real-time)) (results (run-verify-batch batch))) '
        '(write (list (length recipes) (- (real-time) start) '
        '(map (lambda (r) (list (verify-result-id r) (verify-result-passed r) (verify-result-error r))) results))) (newline))')
    observe('mcp-first-verify-batch',[logical/'bin/gxi','-e',expression],roots['mcp'],90)


def failed_package_inputs(ctx, profile, home):
    """Bind a failed, reaped package producer; never qualify it for reuse."""
    from gambit_smp.work_items import context_task
    from gambit_smp.native_capabilities import fields
    from gambit_smp.artifact_storage import observation_root
    from gambit_smp.reasoning_history import read_execution_checkpoint
    from gambit_smp.step_checkpoint import content_id
    reference=profile.get('failedRun',{})
    fields(reference,('run','receipt'))
    task=context_task(ctx)
    if not task:raise ValueError('failed package task context required')
    store=ctx.root/'.cache/tasks'/task
    run=relative(ctx.root,reference['run'])
    if not run.is_relative_to(store):raise ValueError('failed package run outside task')
    observation_root(ctx.root,run)
    rows=[r['payload']['step'] for r in read_execution_checkpoint(ctx.root,run)['records']
          if r['payload'].get('schema')=='research-step-observation.v1'
          and r['payload']['step']['id']=='packages']
    if len(rows)!=1 or content_id(rows[0])!=reference['receipt'] or rows[0].get('outcome')!='DENY':
        raise ValueError('failed package producer identity/outcome drift')
    step=rows[0]
    if not step.get('commands') or any(c.get(k) is not True for c in step['commands']
            for k in ('parentReaped','processGroupQuiescent')):
        raise ValueError('failed package producer has unknown child custody')
    roots={};environments={}
    for kind in ('mcp','poo'):
        name='packages/'+kind+'-package/result.json';path=run/'run'/name
        if not path.is_file() or digest(path)!=step.get('artifacts',{}).get(name):
            raise ValueError('failed package observation missing or changed: '+kind)
        result=json.loads(path.read_text());source=relative(ctx.root,profile['packageSources'][kind])
        if (not source.is_relative_to(store) or result.get('workspace')!=str(source)
                or result.get('compilerHome')!=str(home)
                or result.get('compilerSha256')!=digest(home/'bin/gerbil')
                or result.get('wholePackagePassed') is not False
                or result.get('blockedAt')!='test'):
            raise ValueError('failed package source/compiler cohort differs: '+kind)
        if kind=='poo' and result.get('stages',{}).get('test',{}).get('exit')!=139:
            raise ValueError('native package signal failure required')
        command_name='packages/'+kind+'-test.process.json';command_path=run/'run'/command_name
        if not command_path.is_file() or digest(command_path)!=step.get('artifacts',{}).get(command_name):
            raise ValueError('failed package process context missing or changed: '+kind)
        command=json.loads(command_path.read_text());environment=command.get('environment')
        if (command.get('cwd')!=str(source) or not isinstance(environment,dict)
                or any(type(k) is not str or type(v) is not str or k.startswith('GAMBIT_SMP_TASK_')
                       for k,v in environment.items())):
            raise ValueError('closed recorded application environment required')
        ctx.bind([path,command_path]);roots[kind]=source;environments[kind]=environment
    program=roots['poo']/'.gerbil/bin/test-program'
    if program.is_symlink() or not program.is_file():raise ValueError('original linked test program missing')
    ctx.bind([program,*(p for root in roots.values() for p in (root/'.gerbil/lib').rglob('*') if p.is_file()),
              *(root/name for root in roots.values() for name in ('justfile',) if (root/name).is_file())])
    return roots,program,environments


def observe_package_failure(ctx, profile, home):
    """Inspect actual failed package consumers with the original heap and bounds."""
    roots,program,environments=failed_package_inputs(ctx,profile,home)
    saved=dict(ctx.env);rows={};program_sha=digest(program)
    def observe(role,argv,cwd,cap):
        ctx.run(role,argv,cwd,min(cap,ctx.remaining()))
        rows[role]=dict(ctx.commands[-1],stdout=ctx.last_stdout,stderr=ctx.last_stderr)
    try:
        # A build-prefix variable changes the runtime loader's search policy.
        # Replay recorded application context; never synthesize a build context.
        ctx.env.clear();ctx.env.update(environments['mcp'])
        mcp_child_service_probes(ctx,roots,home,observe)
        # Match the original just _test environment, program and heap options.
        ctx.env.clear();ctx.env.update(environments['poo'])
        ctx.env.setdefault('GERBIL_BUILD_VERBOSE','3')
        ctx.env['COMPILER_PATH']='/usr/bin'
        for key in ('SDKROOT','CPATH','LIBRARY_PATH','C_INCLUDE_PATH','CPLUS_INCLUDE_PATH','MACOSX_DEPLOYMENT_TARGET'):
            ctx.env.pop(key,None)
        # Compare the same retained interface through the ordinary initialized
        # interpreter. This observes dependency evaluation, not a replacement test.
        interface=roots['poo']/'.gerbil/lib/clan/poo/t/union-inference-test.ssi'
        expression='''(import :gerbil/expander)
(def original-eval (current-expander-module-eval))
(parameterize ((current-expander-module-eval
  (lambda (ctx)
    (displayln "DEPENDENCY-EVAL " (expander-context-id ctx))
    (original-eval ctx))))
  (import-module INTERFACE #f #t))
(displayln "PROVIDER-LOAD " (assoc "clan/poo/examples/polymorphic-services~0" (list-modules)))
(displayln "PROVIDER-PROCEDURE "
  (procedure? (##global-var-ref (##make-global-var
    'clan/poo/examples/polymorphic-services#infer-callback-directory-service__%))))
'''.replace('INTERFACE',json.dumps(str(interface)))
        observe('poo-retained-interface-dependencies',
            [home/'bin/gxi','-:max-heap=1G,debug=q','-e',expression],roots['poo'],90)
        resolver=Path('/usr/bin/xcrun');ctx.bind([resolver])
        debugger=Path(ctx.require('package-debugger-path',[resolver,'--find','lldb'],ctx.root,10).strip()).resolve(strict=True)
        ctx.bind([debugger])
        target_environment=' '.join(json.dumps(key+'='+value) for key,value in sorted(ctx.env.items()))
        commands=['settings set target.disable-aslr false',
            'settings set target.inherit-env false',
            'settings set target.env-vars '+target_environment,'breakpoint set --name main',
            'process launch --working-dir '+json.dumps(str(roots['poo']))+' -- -:max-heap=1G,debug=q t',
            'process handle SIGALRM --stop false --notify false --pass true',
            'process handle SIGSEGV --stop true --notify true --pass false',
            'breakpoint disable 1','continue']
        argv=[debugger,'--no-lldbinit','--batch','--file',program]
        for command in commands:argv+=['-o',command]
        # Batch mode stops its ordinary command list on a crash. Use LLDB's
        # explicit crash hooks so registers and loaded-provider paths survive.
        for command in ('thread backtrace all','register read','image list -f',
                'image lookup -v -a $pc','disassemble --start-address $pc-32 --count 24','process kill'):
            argv+=['--one-line-on-crash',command]
        observe('poo-original-program-stack',argv,roots['poo'],300)
        if digest(program)!=program_sha:raise ValueError('diagnosed program changed')
        # The negative context above is retained verbatim. Change only the
        # phase lookup view, keeping all program bytes and original limits.
        ctx.env['GERBIL_LOADPATH']=str(roots['poo']/'.gerbil/lib')+os.pathsep+str(home/'lib')
        observe('poo-compiled-interface-dependencies',
            [home/'bin/gxi','-:max-heap=1G,debug=q','-e',expression],roots['poo'],90)
        if 'PROVIDER-PROCEDURE #t' not in ctx.last_stdout:
            raise ValueError('compiled dependency view did not initialize the provider entry')
        observe('poo-original-program-compiled-view',
            [program,'-:max-heap=1G,debug=q','t'],roots['poo'],300)
        text=ctx.last_stdout+'\n'+ctx.last_stderr
        if rows['poo-original-program-compiled-view'].get('exit')!=0 or not (
                'OK' in text.splitlines() and 'HARNESS-OK ' in text and 'MODULE-OK ' in text):
            raise ValueError('original linked program failed with compiled dependency view')
    finally:
        ctx.env.clear();ctx.env.update(saved)
        output=ctx.directory/'package-failure-observations.json'
        output.write_text(json.dumps(dict(observations=rows,diagnosticOnly=True,
            failedRun=profile['failedRun'],program=str(program),programSha256=program_sha,
            originalHeap='1G',originalProgramRequest='t',debuggerContext=True,
            targetCompilerAdmitted=False,wholePackagePassed=False,packageSpeedup=None),indent=2)+'\n')
    return dict(outputs=ctx.publish('observations','gerbil-test-observations',output))
