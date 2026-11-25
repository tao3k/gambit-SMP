"""Derived initializer graphs, independently owned from native module outputs."""

import hashlib
import json
from pathlib import Path
from contextlib import contextmanager

from gambit_smp.framework import digest
from gambit_smp.gerbil_build.custody import _module_witnesses, _scheme_product_data
from gambit_smp.workspace import write


def materialize_views(ctx, source, store, programs):
    """Project immutable semantic inputs through the existing native owner.

    A closed view prefix may survive a failed parent. It never grants module
    or native completion: every input already needs a complete program witness.
    """
    source, store = Path(source), Path(store)
    implementation=Path(__file__).resolve().parent.parent/'gerbil_initialization_view.ss'
    contract=digest(implementation)
    directory=store/'initialization-views';directory.mkdir(exist_ok=True)
    prior={p.stem:json.loads(p.read_text()) for p in directory.glob('*.json')}
    witnesses=_module_witnesses(ctx.root,prior,
        schema='gerbil-initialization-view-observation',payload_key='graphView')
    views={};pending=[]
    for program in programs:
        raw=Path(program['initializationGraph']);sha=digest(raw)
        if program['identities'].get(str(raw))!=sha:
            raise ValueError('semantic graph differs from completed program')
        key=hashlib.sha256((sha+':'+contract).encode()).hexdigest()
        record=prior.get(key)
        if record:
            ref=record['completion'];identity=tuple(ref[k]for k in ('path','sha256','observation','scope'))
            core={k:v for k,v in record.items()if k not in ('completion','completionRun')}
            output=Path(record['path'])
            if (witnesses.get(identity)==core and record['sourceSha256']==sha
                    and record['contractSha256']==contract and output.is_file()
                    and output.resolve()==output and output.stat().st_nlink==1
                    and digest(output)==record['sha256']):
                views[program['source']]=['initialization-view',str(output),sha,contract]
                continue
        pending.append((key,program,raw,sha))
    if pending:
        stage='initialization-view-projection-'+str(len(ctx.commands))
        staging=ctx.directory/stage;staging.mkdir()
        requests=[[str(raw),str(staging/(key+'.init')),sha,contract]
                  for key,_,raw,sha in pending]
        request=staging/'requests.scm';request.write_text(_scheme_product_data(requests)+'\n')
        ctx.bind([implementation,request,source/'run.sh',source/'build/bin/gerbil',
                  *[raw for _,_,raw,_ in pending]])
        expression=('(import :gerbil/expander) (include '+json.dumps(str(implementation))+') '
                    '(initialization-views-materialize (call-with-input-file '
                    +json.dumps(str(request))+' read))')
        code,stdout,timeout,_=ctx.run(stage,[str(source/'run.sh'),'gxi','-:p1','-e',expression],
                                    source/'src',min(30,ctx.remaining()))
        process=ctx.commands[-1]
        if not process.get('parentReaped') or not process.get('processGroupQuiescent'):
            raise ValueError('projection writer termination is unknown')
        completed=[int(line.split()[-1])for line in stdout.splitlines()
                   if line.startswith('INITIALIZATION-VIEW-COMPLETE ')]
        if completed!=list(range(len(completed))) or len(completed)>len(pending):
            raise ValueError('projection completion prefix is invalid')
        from gambit_smp.research_kernel import retain_run_record
        journal=ctx.receipt['journal'];header=json.loads(Path(journal['path']).read_text())
        for index in completed:
            key,program,raw,sha=pending[index];output=Path(requests[index][1])
            if (digest(raw)!=sha or not output.is_file() or output.resolve()!=output
                    or output.stat().st_nlink!=1):
                raise ValueError('projection input/output ownership changed')
            final=directory/(key+'.init');output.replace(final)
            record=dict(context=program['context'],moduleId=program['moduleId'],
                source=str(raw),sourceSha256=sha,contractSha256=contract,
                path=str(final),sha256=digest(final),sourceProgram=program['completion'],
                inputBytes=raw.stat().st_size,outputBytes=final.stat().st_size,
                parentExit=code,parentTimedOut=timeout,completedPrefixIndex=index,
                moduleComplete=False,runtimeAdmitted=False)
            ref=retain_run_record(ctx.root,staging/(key+'.observed.json'),journal['scope'],
                dict(schema='gerbil-initialization-view-observation',header=journal,
                     runId=header['runId'],graphView=record,runtimeAdmitted=False),header['inputs'])
            record.update(completion=ref,completionRun=str(Path(journal['path']).parent))
            write(directory/(key+'.json'),record)
            views[program['source']]=['initialization-view',str(final),sha,contract]
        ctx.bind([raw for _,_,raw,_ in pending])
        if timeout or code!=0 or len(completed)!=len(pending):
            raise ValueError('projection batch incomplete; only closed views retained')
    report=dict(programs=len(programs),reused=len(programs)-len(pending),
        materialized=len(pending),contractSha256=contract,moduleComplete=False,runtimeAdmitted=False)
    write(ctx.directory/('initialization-view-admission-'+str(len(ctx.commands))+'.json'),report)
    return views


def issue_view_markers(source, store, programs, views):
    """Derive planning transport without changing the native program witness."""
    source,store=Path(source),Path(store)
    previous={}
    for identity,program in programs.items():
        relative=Path(program['source']).relative_to(source)
        marker=store/'modules'/(str(relative)+'.ready')
        previous[marker]=marker.read_bytes()
        marker.write_text(_scheme_product_data([program['context'],program['source'],
            program['interface'],identity,[program['moduleId'],program['dependencies'],
            views[program['source']]]])+'\n')
    return previous


@contextmanager
def planning_views(ctx, source, store, programs):
    """Issue cohort-local derived transports; never free an unknown reader's view.

    Qualified markers remain valid until the next ordinary module preparation
    replaces them. Restoring old bytes here would invalidate bound input hashes.
    """
    views=materialize_views(ctx,source,store,list(programs.values()))
    previous=issue_view_markers(source,store,programs,views)
    inputs=[*previous,*[Path(view[1])for view in views.values()]]
    try:
        ctx.bind(inputs)
        yield views
        ctx.bind(inputs)
    finally:
        if ctx.commands and ctx.commands[-1].get('processGroupQuiescent') is not True:
            write(ctx.directory/'planning-view-retained.json',dict(
                reason='Reader termination unknown; immutable view and transport remain owned',
                markers=[str(p)for p in previous],runtimeAdmitted=False))
