"""Gerbil build: cli tests."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import shutil


def configure_gambuild_commands(template, original_template, configured):
    """Replace command construction only; retain the admitted configuration/ABI."""
    import re
    def split(text):
        starts=list(re.finditer(r'^substitute_common(?:_portable)?\(\)\n',text,re.M))
        if len(starts)!=1:raise ValueError('unique gambuild command section required')
        start=starts[0].start()
        end=text.find('\ncase "$1" in\n',start)
        if end<0:raise ValueError('gambuild dispatch boundary missing')
        return text[:start],text[start:end],text[end:]
    before,body,after=split(template)
    old_before,old_body,old_after=split(original_template)
    header,configured_body,dispatch=split(configured)
    if (before,after)!=(old_before,old_after):
        raise ValueError('gambuild source delta changes configuration or dispatch')
    if old_body!=configured_body:
        raise ValueError('configured gambuild command source identity drift')
    if re.search(r'@[A-Za-z_][A-Za-z_0-9]*@',body):
        raise ValueError('unconfigured gambuild command token')
    return header+body+dispatch


def retained_cli_constructor(ctx, reference, source_hashes, parent_descriptor, store, _seen=()):
    """Revalidate completed products without promoting an enclosing failed control."""
    from gambit_smp.native_capabilities import fields
    from gambit_smp.recipes import tree_identity
    from gambit_smp.reasoning_history import read_execution_checkpoint
    from gambit_smp.step_checkpoint import content_id
    from gambit_smp.artifact_storage import observation_root
    fields(reference, ('run', 'receipt'))
    key=(reference['run'],reference['receipt'])
    if key in _seen or len(_seen)>=8:raise ValueError('prepared constructor ancestry cycle or budget exceeded')
    seen=(*_seen,key)
    run=relative(ctx.root,reference['run'])
    if not run.is_relative_to(store):raise ValueError('prepared constructor outside task')
    observation_root(ctx.root,run)
    rows=[r['payload']['step'] for r in read_execution_checkpoint(ctx.root,run)['records']
          if r['payload'].get('schema')=='research-step-observation.v1'
          and r['payload']['step']['id']=='packages']
    if len(rows)!=1 or content_id(rows[0])!=reference['receipt']:
        raise ValueError('prepared constructor receipt drift')
    step=rows[0]
    commands=step.get('commands',[])
    if not commands or any(c.get(k) is not True for c in commands
            for k in ('parentReaped','processGroupQuiescent')):
        raise ValueError('prepared constructor has unknown child custody')
    name='packages/cli-startup-check.json';artifact=run/'run'/name
    valid_artifact=artifact.is_file() and digest(artifact)==step.get('artifacts',{}).get(name)
    data=json.loads(artifact.read_text()) if valid_artifact else None
    incomplete=None
    stages=['official-compiler-driver-build','official-package-manager-build',
            'official-bach-build','official-package-manager-executable','official-executable-runtime-help']
    if 'compilerBaseSourceSha256' in source_hashes:stages.append('official-compiler-base-build')
    if 'makeSourceSha256' in source_hashes:stages.append('official-make-build')
    if 'gambuildTemplateSha256' in source_hashes:stages.append('official-gambuild-script-check')
    stages.extend('official-tool-'+name+'-build' for name in source_hashes.get('toolSourceSha256',{}))
    for stage in stages:
        hits=[c for c in commands if c.get('stage')==stage]
        if len(hits)!=1 or hits[0].get('exit')!=0 or hits[0].get('timeout') is not False:
            incomplete=stage;break
    if incomplete:
        if data is None or not isinstance(data.get('constructorReuse'),dict):
            raise ValueError('prepared constructor did not complete: '+incomplete)
        _,ancestor,_=retained_cli_constructor(ctx,data['constructorReuse']['origin'],
            source_hashes,parent_descriptor,store,seen)
        if any(data.get(k)!=ancestor.get(k) for k in
               ('sourceTreeSha256','compilerSha256','packageManagerExecutableSha256')):
            raise ValueError('prepared descendant changed the constructor product')
    if data is None:
        raise ValueError('prepared constructor observation missing or changed')
    if data.get('parentCompiler')!=parent_descriptor or any(data.get(k)!=v for k,v in source_hashes.items()):
        raise ValueError('prepared constructor source cohort differs')
    origin=Path(data['compilerHome']).parent
    if origin.is_symlink() or not origin.resolve(strict=True).is_relative_to(store):
        raise ValueError('prepared compiler outside task')
    origin=origin.resolve(strict=True)
    identity=tree_identity(origin)
    actual=hashlib.sha256(json.dumps(identity,sort_keys=True).encode()).hexdigest()
    if actual!=data.get('sourceTreeSha256'):
        raise ValueError('prepared constructor product tree drift')
    if (digest(origin/'build/bin/gerbil')!=data.get('compilerSha256') or
            digest(origin/'build/lib/gerbil/tools/gxpkg')!=data.get('packageManagerExecutableSha256')):
        raise ValueError('prepared executable identity drift')
    ctx.bind([artifact])
    return origin, data, identity


def _test_cli_startup(profile,path,ctx, *, diagnostic_after_seconds=None):
    """Derive the official BACH entry from an admitted complete compiler.

    Reuse the original build-bach.ss, loader and package executor. The parent
    compiler is immutable; declared source deltas are built in a separately owned copy.
    """
    from gambit_smp.recipes import artifact_path,read_json,tree_identity
    from gambit_smp.native_capabilities import fields
    from gambit_smp.artifact_storage import transfer_tree
    fields(profile,('kind','compiler','syntax','mainSource','mainSha256','fixtures'),('packageManager','compilerDriver','compilerBase','makeSource','buildCores','prepared','toolSources','gambuildTemplate','toolsBuild'))
    def retained(key,kind,descriptor=None):
        descriptor=profile[key] if descriptor is None else descriptor
        if descriptor.get('type')!=kind or 'origin' not in descriptor:
            raise ValueError('committed typed CLI input required: '+key)
        item=artifact_path(ctx.directory,descriptor,root=ctx.root)
        if digest(item)!=descriptor['sha256']:
            raise ValueError('CLI input receipt drift: '+key)
        ctx.bind([item]);return read_json(item)
    proof=retained('compiler','gerbil-build-observations')
    syntax=retained('syntax','gerbil-test-observations')
    if proof.get('constructionPassed') is not True or proof.get('packageReady') is not True:
        raise ValueError('CLI derivation requires the admitted complete compiler')
    if any(proof['configuration'][k] for k in ('smp','multipleVms','multipleThreadedVms')):
        raise ValueError('CLI study does not admit GC/SMP runtime changes')
    parent=Path(proof['source']).resolve(strict=True)
    def tree_sha(folder):
        return hashlib.sha256(json.dumps(tree_identity(folder),sort_keys=True).encode()).hexdigest()
    expected=proof['workspaceOutputs'].get(str(parent),{}).get('sha256')
    if not expected or tree_sha(parent)!=expected:
        raise ValueError('admitted parent compiler tree changed')
    source=(ctx.root/profile['mainSource']).resolve(strict=True)
    import os
    store=ctx.root/'.cache/tasks'/os.environ['GAMBIT_SMP_TASK_ID']
    if not parent.is_relative_to(store) or not source.is_relative_to(store):
        raise ValueError('CLI derivation inputs must remain in the same task')
    if (digest(source)!=profile['mainSha256'] or syntax.get('phase')!='syntax'
            or not syntax.get('checks') or any(c.get('passed') is not True for c in syntax['checks'])
            or syntax.get('source')!=str(source)
            or any(c.get('sourceSha256')!=digest(source) for c in syntax['checks'])):
        raise ValueError('matching full-module source syntax receipt required')
    sources={}
    for key,filename in (('packageManager','gxpkg.ss'),('compilerDriver','driver.ss'),
                         ('compilerBase','base.ss'),('makeSource','make.ss')):
        if key not in profile:continue
        entry=profile[key];fields(entry,('source','sha256','syntax'))
        item=(ctx.root/entry['source']).resolve(strict=True)
        checked=retained(key+'-syntax','gerbil-test-observations',entry['syntax'])
        if (not item.is_relative_to(store) or item.name!=filename
                or digest(item)!=entry['sha256'] or checked.get('source')!=str(item)
                or checked.get('phase') not in ('after','syntax') or not checked.get('checks')
                or any(c.get('passed') is not True or c.get('sourceSha256')!=digest(item)
                       for c in checked['checks'])):
            raise ValueError('matching source syntax receipt required: '+key)
        ctx.bind([item]);sources[key]=item
    package_manager=sources.get('packageManager')
    compiler_driver=sources.get('compilerDriver')
    compiler_base=sources.get('compilerBase')
    make_source=sources.get('makeSource')
    tools_build = None
    if 'toolsBuild' in profile:
        if 'prepared' in profile or any(name in profile for name in ('compilerDriver','compilerBase','makeSource','packageManager','gambuildTemplate','toolSources')):
            raise ValueError('tools product constructor is one exact source delta')
        from gambit_smp.gerbil_build.source_tests import tools_build_source
        tools_build,shell=tools_build_source(ctx,profile['toolsBuild'],retained,store)
    tool_sources={}
    for name,entry in profile.get('toolSources',{}).items():
        if not __import__('re').fullmatch(r'[a-z][a-z0-9-]*',name) or name=='gxpkg':
            raise ValueError('official non-package-manager tool name required')
        fields(entry,('source','sha256','syntax'))
        item=(ctx.root/entry['source']).resolve(strict=True)
        checked=retained('tool-'+name,'gerbil-test-observations',entry['syntax'])
        if (not item.is_relative_to(store) or item.name!=name+'.ss'
                or digest(item)!=entry['sha256'] or checked.get('source')!=str(item)
                or checked.get('phase') not in ('after','syntax') or not checked.get('checks')
                or any(c.get('passed') is not True or c.get('sourceSha256')!=digest(item)
                       for c in checked['checks'])):
            raise ValueError('matching official tool syntax receipt required: '+name)
        ctx.bind([item]);tool_sources[name]=item
    gambuild_template=None
    if 'gambuildTemplate' in profile:
        entry=profile['gambuildTemplate'];fields(entry,('source','sha256'))
        gambuild_template=(ctx.root/entry['source']).resolve(strict=True)
        if (not gambuild_template.is_relative_to(store) or gambuild_template.name!='gambuild-C.unix.in'
                or digest(gambuild_template)!=entry['sha256']):
            raise ValueError('same-task gambuild template identity required')
        ctx.bind([gambuild_template,parent/'src/gambit/bin/gambuild-C.unix.in'])
    build_cores=profile.get('buildCores',int(proof['packageEnvironment']['GERBIL_BUILD_CORES']))
    if type(build_cores) is not int or build_cores<1:
        raise ValueError('positive explicit compiler build capacity required')
    if compiler_base is not None and compiler_driver is None:
        raise ValueError('executor and its driver must be built together')
    if make_source is not None and compiler_base is None:
        raise ValueError('cold-library retirement requires its matching executor')
    fixtures=ctx.root/profile['fixtures']
    if fixtures!=ctx.root/'tests/fixtures/darwin-compiler':
        raise ValueError('registered actual macro fixture closure required')
    fixture_files=[fixtures/name for name in ('leaf.ss','consumer.ss','gerbil.pkg')]
    control_files=[fixtures/name for name in ('executor.ss','cold-library.ss','executable.ss','executable-other.ss','foreign.ss','failing-executable.ss')] if compiler_base is not None or tools_build is not None else []
    ctx.bind([path,source,*fixture_files,*control_files])
    prepared_data=None
    if 'prepared' in profile:
        if package_manager is None or compiler_driver is None:
            raise ValueError('prepared managed CLI requires the complete source cohort')
        hashes=dict(mainSourceSha256=digest(source),packageManagerSourceSha256=digest(package_manager),
                    compilerDriverSourceSha256=digest(compiler_driver))
        if compiler_base is not None:hashes['compilerBaseSourceSha256']=digest(compiler_base)
        if make_source is not None:hashes['makeSourceSha256']=digest(make_source)
        if 'buildCores' in profile:hashes['buildCores']=build_cores
        if tool_sources:hashes['toolSourceSha256']={n:digest(p) for n,p in tool_sources.items()}
        if gambuild_template is not None:hashes['gambuildTemplateSha256']=digest(gambuild_template)
        view,prepared_data,prepared_identity=retained_cli_constructor(ctx,profile['prepared'],
            hashes,profile['compiler'],store)
        transfer=dict(mode='exclusive-revalidation',claim='stable input products; no prior phase result admission')
        ctx.lease_workspace(view,prepared_identity)
        for item,relative_source in ((source,'src/gerbil/main.ss'),
                (package_manager,'src/tools/gxpkg.ss'),(compiler_driver,'src/gerbil/compiler/driver.ss'),
                (compiler_base,'src/gerbil/compiler/base.ss'),(make_source,'src/std/make.ss')):
            if item is not None and digest(view/relative_source)!=digest(item):
                raise ValueError('prepared source bytes differ')
    else:
        from gambit_smp.workspace import build_output
        work=build_output(ctx.root,'gerbil',compiler=ctx.tools['gcc'],
            flags=['official-bach-cli',expected,digest(source),str(ctx.directory)])
        view=work/'source'
        from gambit_smp.gerbil_build.batches import component_source_view
        transfer=(component_source_view(parent,view) if tools_build is not None else transfer_tree(parent,view))
        ctx.lease_workspace(view,tree_identity(view))
        shutil.copy2(source,view/'src/gerbil/main.ss')
        if tools_build is not None:
            shutil.copy2(tools_build,view/'src/tools/build.ss')
            shutil.copy2(shell,view/'src/build.sh')
        if package_manager is not None:shutil.copy2(package_manager,view/'src/tools/gxpkg.ss')
        if compiler_driver is not None:shutil.copy2(compiler_driver,view/'src/gerbil/compiler/driver.ss')
        if compiler_base is not None:shutil.copy2(compiler_base,view/'src/gerbil/compiler/base.ss')
        if make_source is not None:shutil.copy2(make_source,view/'src/std/make.ss')
        for name,item in tool_sources.items():shutil.copy2(item,view/('src/tools/'+name+'.ss'))
        if gambuild_template is not None:
            script=view/'build/bin/gambuild-C'
            updated=configure_gambuild_commands(gambuild_template.read_text(),
                (parent/'src/gambit/bin/gambuild-C.unix.in').read_text(),script.read_text())
            script.write_text(updated)
            shutil.copy2(gambuild_template,view/'src/gambit/bin/gambuild-C.unix.in')
    home=view/'build'
    saved=dict(ctx.env)
    observations={}
    result=dict(parentCompiler=profile['compiler'],mainSourceSha256=digest(source),
        compilerHome=str(home),storageTransfer=transfer,stages=observations,
        phasePassed=False,bothPackagesPassed=False,packageSpeedup=None,mergeAllowed=False,buildCores=build_cores)
    result['diagnosticOnly']=diagnostic_after_seconds is not None
    if gambuild_template is not None:result['gambuildTemplateSha256']=digest(gambuild_template)
    output=ctx.directory/'cli-startup-check.json'
    if prepared_data is not None:
        result['constructorReuse']=dict(origin=profile['prepared'],
            originalPhasePassed=prepared_data['phasePassed'],newControlsRequired=True)
        result['packageManagerSourceSha256']=digest(package_manager)
        result['compilerDriverSourceSha256']=digest(compiler_driver)
        result['packageManagerExecutableSha256']=prepared_data['packageManagerExecutableSha256']
        for key in ('compilerBaseSourceSha256','makeSourceSha256'):
            if key in prepared_data:result[key]=prepared_data[key]
        if tool_sources:result['toolSourceSha256']={n:digest(p) for n,p in tool_sources.items()}
    executable=home/('bin/gxpkg' if tools_build is not None else 'lib/gerbil/tools/gxpkg')
    prior=ctx.directory/'prior-package-manager-products'
    def package_products():
        return sorted(p for p in (home/'lib/gerbil/tools').iterdir()
                      if p.is_file() and p.name.startswith(('gxpkg.','gxpkg~')))
    def quiescent():
        return (not ctx.commands or all(ctx.commands[-1].get(k) is True
                for k in ('parentReaped','processGroupQuiescent')))
    def observed(role):
        if not quiescent():raise ValueError('CLI child completion unknown; retain private generation')
        observations[role]=dict(ctx.commands[-1])
    def negative(role,argv,needle,expected_exits=(1,70)):
        code,_,timeout,_=ctx.run(role,argv,ctx.directory,60)
        if not quiescent() or timeout or code not in expected_exits or needle not in ctx.last_stdout+ctx.last_stderr:
            raise ValueError('expected CLI rejection not established: '+role)
        ctx.commands[-1].update(expectedExit=code,negativeControl=True)
        observed(role)
    try:
        ctx.env.update(proof['packageEnvironment'])
        ctx.env['GERBIL_BUILD_CORES']=str(build_cores)
        ctx.env.update(GERBIL_HOME=str(home),GERBIL_BUILD_PREFIX=str(home),
            GERBIL_PREFIX=str(home),GERBIL_SOURCE=str(view/'src'),
            GERBIL_GSC=str(home/'bin/gsc'),GERBIL_GCC=str(ctx.tools['gcc']),
            GERBIL_PATH=str(ctx.directory/'user'),GERBIL_LOADPATH=str(home/'lib'),
            PATH=str(home/'bin')+':'+ctx.env['PATH'],
            GAMBOPT=f'~~bin={home}/bin,~~lib={home}/lib,~~include={home}/include',
            LD_LIBRARY_PATH=str(home/'lib'),DYLD_LIBRARY_PATH=str(home/'lib'),
            DYLD_FALLBACK_LIBRARY_PATH=str(home/'lib'))
        # Mirror install.sh's source publication in the new owned generation.
        # Revalidation may read an existing product, never repair it in place.
        if prepared_data is None:
            source_home=home/'src';source_home.mkdir(exist_ok=True)
            (source_home/'gerbil.pkg').touch()
            roots=('gerbil/core','gerbil/runtime','gerbil/expander','gerbil/compiler',
                   'std','tools','lang/gerbil','lang/scheme','r7rs-large/scheme','srfi','tutorial')
            paths=[p for name in roots for p in (view/'src'/name).rglob('*')
                   if p.is_file() and p.suffix in ('.ss','.ssi','.scm','.c')
                   and p.name!='build.ss' and '.gerbil' not in p.parts]
            paths.extend((view/'src/gerbil').glob('*.ss'))
            for item in paths:
                destination=source_home/item.relative_to(view/'src')
                destination.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(item,destination)
        if not all((home/'src'/name).is_file() for name in ('std/encoding/json.ss','std/list/list.ss')):
            raise ValueError('matching official source publication is missing')
        result['sourcePublication']=dict(root=str(home/'src'),policy='install.sh source selection')
        if prepared_data is None:
            if tools_build is not None:
                from gambit_smp.gerbil_build.batches import tools_products
                result.update(tools_products(ctx,home,view,proof,observed))
                result['toolsBuildSourceSha256']=digest(tools_build)
            if gambuild_template is not None:
                ctx.require('official-gambuild-script-check',['/bin/sh','-n',str(home/'bin/gambuild-C')],view,10)
                observed('gambuildScriptCheck')
            if compiler_base is not None:
                result['compilerBaseSourceSha256']=digest(compiler_base)
                ctx.require('official-compiler-base-build',
                    [str(home/'bin/gxc'),'-O','-s','-d',str(home/'lib'),str(view/'src/gerbil/compiler/base.ss')],view/'src',180)
                observed('compilerBaseBuild')
            if compiler_driver is not None:
                result['compilerDriverSourceSha256']=digest(compiler_driver)
                ctx.require('official-compiler-driver-build',
                    [str(home/'bin/gxc'),'-O','-s','-d',str(home/'lib'),str(view/'src/gerbil/compiler/driver.ss')],view/'src',180)
                observed('compilerDriverBuild')
            if make_source is not None:
                result['makeSourceSha256']=digest(make_source)
                ctx.require('official-make-build',
                    [str(home/'bin/gxc'),'-O','-s','-d',str(home/'lib'),str(view/'src/std/make.ss')],view/'src',180)
                observed('makeBuild')
            if tool_sources:result['toolSourceSha256']={n:digest(p) for n,p in tool_sources.items()}
            for name in tool_sources:
                ctx.require('official-tool-'+name+'-build',
                    [str(home/'bin/gxc'),'-O','-s','-d',str(home/'lib'),str(view/('src/tools/'+name+'.ss'))],view/'src',180)
                observed('tool-'+name+'-build')
            if package_manager is not None:
                prior.mkdir()
                result['packageManagerSourceSha256']=digest(package_manager)
                result['priorPackageManagerProducts']={p.name:digest(p) for p in package_products()}
                for item in package_products():item.rename(prior/item.name)
                ctx.require('official-package-manager-build',
                    [str(home/'bin/gxc'),'-O','-s','-d',str(home/'lib'),str(view/'src/tools/gxpkg.ss')],view/'src',180)
                observed('packageManagerBuild')
                for name in ('gxpkg.o1','gxpkg~request.o1','gxpkg~template.o1'):
                    if not (home/'lib/gerbil/tools'/name).is_file():
                        raise ValueError('lifted feature loader missing: '+name)
                loader=(home/'lib/gerbil/tools/gxpkg.scm').read_text()
                if any('"'+name+'"' in loader for name in ('std/net/request','std/text/template')):
                    raise ValueError('base package loader still demands optional providers')
                result['baseLoaderSha256']=digest(home/'lib/gerbil/tools/gxpkg.scm')
            ctx.require('official-bach-build',[str(home/'bin/gxi'),'build/build-bach.ss'],view/'src',900)
            observed('build')
            if tools_build is not None:
                ctx.require('official-executable-runtime-help',[str(executable),'help','clean'],ctx.directory,30)
                if 'clean' not in ctx.last_stdout:
                    raise ValueError('native package manager help missing')
                observed('packageManagerExecutableHelp')
                result['packageManagerExecutableSha256']=digest(executable)
            if compiler_driver is not None:
                # A separate executable is an independent product, not a substitute
                # for the literal gerbil positive and negative controls below.
                executable=home/'lib/gerbil/tools/gxpkg'
                ctx.require('official-package-manager-executable',
                    [str(home/'bin/gxc'),'-O','-exe','-o',str(executable),str(view/'src/tools/gxpkg.ss')],view/'src',180)
                observed('packageManagerExecutableBuild')
                result['packageManagerExecutableSha256']=digest(executable)
                ctx.require('official-executable-runtime-help',[str(executable),'help','clean'],ctx.directory,30)
                if 'clean' not in ctx.last_stdout or not ctx.last_stdout.strip():
                    raise ValueError('official executable did not print requested clean help')
                observed('packageManagerExecutableHelp')
        result['compilerSha256']=digest(home/'bin/gerbil')
        if compiler_base is not None or tools_build is not None:
            for cores,role in ((build_cores,'executor'),(1,'executor-single-permit')):
                ctx.env['GERBIL_BUILD_CORES']=str(cores)
                try:
                    ctx.require('official-'+role,[str(home/'bin/gxi'),str(fixtures/'executor.ss')],ctx.directory,60)
                    if 'EXECUTOR-DEPENDENCIES-DRAIN-OK' not in ctx.last_stdout.splitlines():
                        raise ValueError('real executor dependency/failure-drain marker absent')
                    observed(role)
                finally:ctx.env['GERBIL_BUILD_CORES']=str(build_cores)
        # The source builder must not mutate the parent's installed compiler.
        if tree_sha(parent)!=expected:raise ValueError('CLI derivation mutated its parent')
        withheld={}
        for name in ('gerbil/core.ssi','gerbil/core.scm'):
            item=home/'lib'/name
            if item.is_file():withheld[item]=ctx.directory/'withheld-providers'/name
        if package_manager is not None:
            for name in ('std/net/request','std/text/template'):
                stem=home/'lib'/name
                for item in stem.parent.iterdir():
                    suffix=item.name.removeprefix(stem.name)
                    if item.is_file() and item.name.startswith(stem.name) and (
                            suffix=='.scm' or (suffix.startswith('.o') and suffix[2:].isdigit())):
                        withheld[item]=ctx.directory/'withheld-providers'/item.relative_to(home/'lib')
        for item,target in withheld.items():target.parent.mkdir(parents=True,exist_ok=True);item.rename(target)
        interface=home/'lib/gerbil/tools/gxpkg.ssi';original=interface.read_bytes()
        try:
            ctx.require('runtime-command-without-core-interface',
                [str(home/'bin/gerbil'),'help','clean'],ctx.directory,60)
            if 'clean' not in ctx.last_stdout:raise ValueError('runtime command help absent')
            observed('runtimeWithoutCore')
            # A clean package has not created GERBIL_PATH/lib yet. The normal
            # resolver skips absent search roots; dispatch must do the same.
            absent=ctx.directory/'absent-package'/'lib'
            if absent.exists():raise ValueError('fresh load-path control already exists')
            ctx.env['GERBIL_LOADPATH']=str(absent)+':'+str(home/'lib')
            try:
                ctx.require('runtime-command-with-absent-search-root',
                    [str(home/'bin/gerbil'),'help','clean'],ctx.directory,60)
                if 'clean' not in ctx.last_stdout:raise ValueError('fresh package help absent')
                observed('runtimeAbsentSearchRoot')
            finally:ctx.env['GERBIL_LOADPATH']=str(home/'lib')
            if compiler_driver is not None or tools_build is not None:
                held=ctx.directory/'held-runtime-executable'
                executable.rename(held)
                try:
                    executable.write_bytes(b'not an executable\n')
                    executable.chmod(0o755)
                    negative('runtime-executable-rejection',
                        [str(home/'bin/gerbil'),'help','clean'],'runtime command handoff failed')
                finally:
                    if quiescent():
                        executable.unlink(missing_ok=True);held.rename(executable)
                    else:result['unresolvedRuntimeExecutable']=str(held)
            if package_manager is not None and compiler_driver is None:
                current=ctx.directory/'current-package-manager-products';current.mkdir()
                for item in package_products():item.rename(current/item.name)
                for item in sorted(prior.iterdir()):shutil.copy2(item,home/'lib/gerbil/tools'/item.name)
                hidden=ctx.directory/'runtime-executable-before-old-provider-control'
                if compiler_driver is not None:executable.rename(hidden)
                try:
                    negative('old-package-manager-demand',
                        [str(home/'bin/gerbil'),'help','clean'],'std/net/request')
                finally:
                    if quiescent():
                        if compiler_driver is not None:hidden.rename(executable)
                        for item in package_products():item.unlink()
                        for item in sorted(current.iterdir()):item.rename(home/'lib/gerbil/tools'/item.name)
                    else:result['unresolvedPackageGeneration']='baseline remains active; candidate retained separately'
            changed=original.replace(b'(spec: 0 main main)',b'(spec: 0 main private-main)',1)
            if changed==original:raise ValueError('actual main export countercontrol absent')
            interface.write_bytes(changed)
            negative('unsupported-interface-fallback',
                [str(home/'bin/gerbil'),'help','clean'],'cannot find library module')
        finally:
            if quiescent():
                interface.write_bytes(original)
                for item,target in withheld.items():target.rename(item)
            else:result['withheldProvidersRetained']=list(map(str,withheld.values()))
        # A user-supplied standard provider keeps the original expander route.
        shadow=ctx.directory/'shadow';(shadow/'std').mkdir(parents=True)
        (shadow/'std/format.ssi').write_text('prelude: :darwin-shadow-provider-missing\n(%#begin)\n')
        ctx.env['GERBIL_LOADPATH']=str(shadow)+':'+str(home/'lib')
        try:
            negative('shadow-provider-fallback',
                [str(home/'bin/gerbil'),'help','clean'],'darwin-shadow-provider-missing')
        finally:ctx.env['GERBIL_LOADPATH']=str(home/'lib')
        if package_manager is not None or tools_build is not None:
            aliases='(import :std/net/request :std/text/template)\n(load-module "gerbil/tools/gxpkg~request")\n(load-module "gerbil/tools/gxpkg~template")\n(for-each\n (lambda (entry)\n   (unless (eq? (##global-var-ref (##make-global-var (car entry))) (cdr entry))\n     (error "feature binding mismatch" (car entry))))\n (list (cons \'gerbil/tools/gxpkg~request#http-get http-get)\n       (cons \'gerbil/tools/gxpkg~request#request-status request-status)\n       (cons \'gerbil/tools/gxpkg~request#request-status-text request-status-text)\n       (cons \'gerbil/tools/gxpkg~request#request-url request-url)\n       (cons \'gerbil/tools/gxpkg~request#request-text request-text)\n       (cons \'gerbil/tools/gxpkg~template#write-template write-template)))\n(displayln "CLI-OPTIONAL-BINDINGS-OK")'
            diagnostic=None
            if diagnostic_after_seconds is not None:
                tool=ctx.tools.get('darwinSample')
                if tool is None:raise ValueError('sealed Darwin sampling tool required')
                sample_directory=ctx.directory/'optional-provider-observation';sample_directory.mkdir()
                diagnostic=dict(tool=tool,toolSha256=digest(Path(tool)),
                    directory=str(sample_directory),afterSeconds=diagnostic_after_seconds)
            ctx.require('optional-provider-binding-identities',
                [str(home/'bin/gxi'),'-e',aliases],ctx.directory,180,diagnostic=diagnostic)
            if 'CLI-OPTIONAL-BINDINGS-OK' not in ctx.last_stdout.splitlines():
                raise ValueError('optional binding identity marker missing')
            observed('optionalBindings')
        expression=("(import :gerbil/base) (defrule (answer) 42) "
            "(unless (= (answer) 42) (error \"macro mismatch\")) "
            "(unless (eq? (with-catch (lambda (_) 'caught) (lambda () (error \"expected\"))) 'caught) "
            "(error \"exception mismatch\")) "
            "(let ((saved #f) (n 0)) (let ((value (call/cc (lambda (k) (set! saved k) 0)))) "
            "(set! n (+ n 1)) (if (< n 3) (saved n) (unless (= value 2) (error \"continuation mismatch\"))))) "
            '(displayln "CLI-INTERPRETER-SEMANTICS-OK")')
        ctx.require('interpreter-macro-exception-continuation',
            [str(home/'bin/gxi'),'-e',expression],ctx.directory,180)
        if 'CLI-INTERPRETER-SEMANTICS-OK' not in ctx.last_stdout.splitlines():
            raise ValueError('interpreter semantic marker missing')
        observations['interpreter']=dict(ctx.commands[-1])
        library=ctx.directory/'library';library.mkdir()
        inputs=ctx.directory/'library-source';inputs.mkdir()
        for item in fixture_files:shutil.copy2(item,inputs/item.name)
        shutil.copy2(fixtures/'foreign.ss',inputs/'foreign.ss')
        ctx.env['GERBIL_LOADPATH']=str(library)+':'+str(home/'lib')
        ctx.require('compiler-macro-provider-consumer',
            [str(home/'bin/gxc'),'-O','-s','-d',str(library),str(inputs/'leaf.ss'),str(inputs/'consumer.ss')],ctx.directory,180)
        if not all((library/('compiler-handoff/'+m+'.o1')).is_file() for m in ('leaf','consumer')):
            raise ValueError('macro provider/consumer native closure missing')
        ctx.require('compiled-macro-consumer', [str(home/'bin/gxi'),'-e',
            '(import :compiler-handoff/consumer) (unless (= (consumer-answer) 42) (error "binding mismatch")) (displayln "CLI-NATIVE-MACRO-OK")'],ctx.directory,180)
        if 'CLI-NATIVE-MACRO-OK' not in ctx.last_stdout.splitlines():
            raise ValueError('compiled binding consumer marker missing')
        observations['compiler']=dict(ctx.commands[-1])
        if compiler_base is not None or tools_build is not None:
            executable_source=inputs/'executable.ss'
            failing_source=inputs/'failing-executable.ss'
            shutil.copy2(fixtures/'executable.ss',executable_source)
            shutil.copy2(fixtures/'failing-executable.ss',failing_source)
            def executable_expression(source,output):
                # Public make owns module emission before executable assembly.
                return ('(import :std/make) '
                    '(eval \'(begin-foreign (include '+json.dumps(str(home/'lib/_gambit#.scm'))+'))) '
                    '(make (list (list exe: '+json.dumps(source.stem)+' bin: '+json.dumps(output.name)+')) '
                    'srcdir: '+json.dumps(str(inputs))+' libdir: '+json.dumps(str(library))+
                    ' bindir: '+json.dumps(str(output.parent))+')')
            program=ctx.directory/'object-closure-executable'
            ctx.require('official-parallel-object-closure',
                [str(home/'bin/gxi'),'-e',executable_expression(executable_source,program)],ctx.directory,180)
            if 'compile-executable-object' not in ctx.last_stdout or not program.is_file():
                raise ValueError('real parallel object closure did not produce its executable')
            observed('objectClosure')
            ctx.require('official-object-closure-consumer',[str(program)],ctx.directory,30)
            if 'OBJECT-CLOSURE-EXECUTABLE-OK' not in ctx.last_stdout.splitlines():
                raise ValueError('linked executable binding consumer failed')
            observed('objectClosureConsumer')
            shared=ctx.directory/'shared-object-library';shared.mkdir()
            second=ctx.directory/'shared-object-second'
            first=ctx.directory/'shared-object-first'
            shutil.copy2(fixtures/'executable-other.ss',inputs/'executable-other.ss')
            ctx.env['GERBIL_LOADPATH']=str(shared)+':'+str(home/'lib')
            expression=('(import :std/make) (make (list "leaf" "consumer" '
                '(list exe: "executable" bin: '+json.dumps(first.name)+') '
                '(list exe: "executable-other" bin: '+json.dumps(second.name)+')) '
                'srcdir: '+json.dumps(str(inputs))+' libdir: '+json.dumps(str(shared))+
                ' bindir: '+json.dumps(str(ctx.directory))+')')
            ctx.require('official-shared-runtime-objects',[str(home/'bin/gxi'),'-e',expression],ctx.directory,180)
            for name in ('leaf','consumer'):
                runtime_c=shared/('compiler-handoff/'+name+'~0.c')
                static_c=shared/('static/compiler-handoff__'+name+'.c')
                if not runtime_c.is_file() or not static_c.is_file() or digest(runtime_c)!=digest(static_c):
                    raise ValueError('runtime/static C identity not preserved: '+name)
                if any('generate-executable-c' in line and 'compiler-handoff__'+name+'.c' in line
                       for line in ctx.last_stdout.splitlines()):
                    raise ValueError('eligible shared runtime product was regenerated: '+name)
            observed('sharedRuntimeObjects')
            for role,program,marker in (('sharedFirst',first,'OBJECT-CLOSURE-EXECUTABLE-OK'),
                                        ('sharedSecond',second,'SHARED-OBJECT-SECOND-EXECUTABLE-OK')):
                ctx.require('official-'+role,[str(program)],ctx.directory,30)
                if marker not in ctx.last_stdout.splitlines():raise ValueError('shared object executable failed: '+role)
                observed(role)
            ctx.env['GERBIL_LOADPATH']=str(library)+':'+str(home/'lib')
            failed_program=ctx.directory/'object-closure-refused'
            negative('object-closure-rejection',
                [str(home/'bin/gxi'),'-e',executable_expression(failing_source,failed_program)],
                'DARWIN_EXPECTED_OBJECT_FAILURE')
            if failed_program.exists() or list(ctx.directory.rglob('*.lock')):
                raise ValueError('failed object closure published output or retained a live lock')
        if make_source is not None or tools_build is not None:
            cold=ctx.directory/'cold-library';cold.mkdir()
            before=set((ctx.directory/'user/.compiler').glob('phase*'))
            ctx.env['GERBIL_LOADPATH']=str(cold)+':'+str(home/'lib')
            ctx.require('official-cold-library',
                [str(home/'bin/gxi'),'-:max-heap=1G,debug=q',str(fixtures/'cold-library.ss'),str(inputs),str(cold)],ctx.directory,180)
            if 'COLD-LIBRARY-HANDOFF-OK' not in ctx.last_stdout.splitlines():
                raise ValueError('ordinary make cold-library marker absent')
            phases=set((ctx.directory/'user/.compiler').glob('phase*'))-before
            if len(phases)!=1 or not all((p/'output.native/complete').is_file() for p in phases):
                raise ValueError('ordinary cold library did not join its frontend and native handoff')
            if not all((cold/('compiler-handoff/'+m+'.o1')).is_file() for m in ('leaf','consumer','foreign')):
                raise ValueError('cold-library native closure missing')
            observed('coldLibrary')
            previous=ctx.env['GERBIL_LOADPATH']
            ctx.env['GERBIL_LOADPATH']=str(cold)+':'+str(home/'lib')
            try:
                ctx.require('official-cold-library-consumer',[str(home/'bin/gxi'),'-e',
                    '(import :compiler-handoff/consumer :compiler-handoff/foreign) (unless (and (= (consumer-answer) 42) (= (foreign-answer) 42)) (error "Cold binding mismatch")) (displayln "COLD-LIBRARY-CONSUMER-OK")'],ctx.directory,60)
                if 'COLD-LIBRARY-CONSUMER-OK' not in ctx.last_stdout.splitlines():
                    raise ValueError('cold-library consumer marker absent')
                observed('coldLibraryConsumer')
            finally:ctx.env['GERBIL_LOADPATH']=previous
        if 'gxtest' in tool_sources or tools_build is not None:
            entry=ctx.directory/'embedded-gxtest.ss'
            entry.write_text('(import (only-in :gerbil/runtime/gambit eval) (only-in :gerbil/runtime/loader load-module))\n'
                '(export main)\n(def (main target) (load-module "gerbil/tools/gxtest")\n'
                ' (exit ((eval \'gerbil/tools/gxtest#main) target)))\n')
            program=ctx.directory/'embedded-gxtest'
            ctx.require('embedded-gxtest-build',[home/'bin/gxc','-exe','-o',program,entry],ctx.directory,180)
            for label,value in (('positive',42),('negative',0)):
                target=ctx.directory/('embedded-'+label+'-test.ss')
                target.write_text('(import :std/test (only-in :gerbil/runtime/hash HashTable))\n'
                    '(export embedded-test)\n(def embedded-test (test-suite "embedded" '
                    '(test-case "original source import" (check 42 => '+str(value)+'))))\n')
                if label=='positive':
                    ctx.require('embedded-gxtest-source',[program,target],ctx.directory,60)
                    if ctx.last_stdout.splitlines()[-1:]!=['OK']:
                        raise ValueError('embedded official gxtest source consumer marker missing')
                    observed('embeddedTest')
                else:
                    negative('embedded-test-rejection',[program,target],'ERROR CHECK',expected_exits=(42,))
        result['phasePassed']=diagnostic_after_seconds is None
        result.update(packageSources=proof['packageSources'],packageBudgets=proof['packageBudgets'],
            packageEnvironment=proof['packageEnvironment'])
    finally:
        ctx.env.clear();ctx.env.update(saved)
        # Keep failure products and exact current ownership; no failed result
        # becomes an admitted compiler or a package performance measurement.
        if view.exists():result['sourceTreeSha256']=tree_sha(view)
        output.write_text(json.dumps(result,indent=2)+'\n')
    return dict(outputs=ctx.publish('observations','gerbil-test-observations',output))
