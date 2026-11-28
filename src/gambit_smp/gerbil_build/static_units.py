"""Per-unit custody for the original libgerbil Scheme producer, not a runner."""

import hashlib
import json
from pathlib import Path
from contextlib import contextmanager

from gambit_smp.framework import digest
from gambit_smp.workspace import write
from gambit_smp.gerbil_build.custody import _git_blob, _module_witnesses, _scheme_product_data


def library_static_source(text, *, inverse=False):
    """A checked consumer-only cut; official Make and work-group calls remain."""
    helper=(Path(__file__).resolve().parent.parent/'gerbil_static_products.ss').read_text()
    begin=';;; Begin static unit custody.\n';end=';;; End static unit custody.\n'
    old='  (invoke-process +gerbil-gsc+ args))'
    new='''  (if (getenv "GERBIL_COMPILE_CONTEXT" #f)
    (static-unit-invoke +gerbil-gsc+ args)
    (invoke-process +gerbil-gsc+ args)))'''
    if begin in text:
        if text.count(begin)!=1 or text.count(end)!=1 or text.count(new)!=1:
            raise ValueError('static producer ownership cut changed')
        a=text.index(begin);z=text.index(end,a)+len(end)
        plain=text[:a]+text[z:];plain=plain.replace(new,old)
        expected=library_static_source(plain)
        if text!=expected:raise ValueError('static producer contract differs')
        return plain if inverse else text
    if inverse:return text
    if text.count(old)!=1:raise ValueError('original libgerbil compiler boundary differs')
    contract=hashlib.sha256((text+helper).encode()).hexdigest()
    region=begin+'(def static-unit-contract "'+contract+'")\n'+helper+end
    return text.replace('(def +gerbil-gsc+ #f)',region+'(def +gerbil-gsc+ #f)').replace(old,new)


def validate_completion(source, key, value, request):
    """Reject malformed, escaped or changed outputs before any receipt is issued."""
    source=Path(source).resolve()
    if (not isinstance(value,list) or len(value)!=4 or value[0]!=request
            or not isinstance(request,list) or len(request)!=9 or request[0]!=key
            or request[1]not in ('-c','-obj')
            or request[2]!=str(source/'build/bin/gsc')
            or Path(request[4])!=source/'src'
            or not isinstance(request[3],list) or not request[3]
            or request[3][0]!=request[1] or request[3][-1]!=request[5]
            or value[3]not in ('executed','reused')):
        raise ValueError('static completion differs from its original invocation')
    inp,out=Path(request[5]),Path(request[7]);role=request[1]
    if (inp.parent!=source/'build/lib/static' or inp.resolve()!=inp
            or inp.suffix!=('.scm'if role=='-c'else'.c')
            or out!=inp.with_suffix('.c'if role=='-c'else'.o')
            or not out.is_file() or out.resolve()!=out or out.stat().st_nlink!=1
            or not inp.is_file() or inp.stat().st_nlink!=1
            or _git_blob(inp)!=request[6] or _git_blob(out)!=value[1]):
        raise ValueError('static completion lacks exact input/output ownership')
    return inp,out


def _qualify_sources(ctx, source, inputs):
    """Use the existing native Scheme effect predicate, never a Python reader."""
    canonical=Path(__file__).resolve().parent.parent/'gerbil_compile_products.ss'
    text=canonical.read_text()
    first='(def (compile-product-plain-source?';last='(def (compile-product-shell-word'
    if text.count(first)!=1 or text.count(last)!=1:
        raise ValueError('native source-effect predicate ownership changed')
    predicate=text[text.index(first):text.index(last)]
    memo=getattr(ctx,'static_source_qualification',{})
    contract=digest(canonical)
    pending={p:h for p,h in inputs.items()if (p,h,contract)not in memo}
    if pending:
        stage='static-source-qualification-'+str(len(ctx.commands))
        output=ctx.directory/(stage+'.json')
        expression=('(import :gerbil/expander '+json.dumps(str(source/'src/gerbil/compiler/compile-product-catalog.ss'))+') '
          +predicate+' (call-with-output-file '+json.dumps(str(output))
          +' (lambda (port) (gxc#compile-product-json (map (lambda (path) '
          +'(list path (compile-product-plain-source? path #t))) '
          +"'"+_scheme_product_data(list(pending))+') port)))')
        ctx.bind([canonical,*[Path(p)for p in pending]])
        ctx.require(stage,[str(source/'run.sh'),'gxi','-:p1','-e',expression],
                    source/'src',min(30,ctx.remaining()))
        rows=json.loads(output.read_text())
        if (not isinstance(rows,list)or len(rows)!=len(pending)
                or any(not isinstance(row,list)or len(row)!=2 or type(row[1])is not bool for row in rows)
                or [row[0]for row in rows]!=list(pending)):
            raise ValueError('source-effect result differs from its input inventory')
        for path,approved in rows:
            if digest(Path(path))!=pending[path]:raise ValueError('source changed during qualification')
            memo[path,pending[path],contract]=approved
        ctx.static_source_qualification=memo
    return {p for p,h in inputs.items()if memo[p,h,contract]}


def prepare_static_units(ctx, store, key, source):
    """One authenticated owner for transports and preserved live static outputs."""
    store=Path(store);store.mkdir(exist_ok=True)
    records={p.stem:json.loads(p.read_text())for p in store.glob('*.json')}
    witnesses=_module_witnesses(ctx.root,records,schema='gerbil-static-unit-observation',payload_key='unit')
    valid={}
    for identity,record in records.items():
        marker=store/(identity+'.scm');ref=record['completion']
        wk=tuple(ref[k]for k in ('path','sha256','observation','scope'))
        core={k:v for k,v in record.items()if k not in ('completion','completionRun')}
        if (witnesses.get(wk)==core and record['data'][0][0]==key
                and all(Path(p).is_file()and Path(p).resolve()==Path(p)
                        and Path(p).stat().st_nlink==1 and digest(Path(p))==sha
                        for p,sha in record['identities'].items())):
            valid[identity]=record

        elif marker.exists():marker.unlink()
    inputs={unit['data'][0][5]:unit['identities'][unit['data'][0][5]]
            for unit in valid.values()if unit['data'][0][1]=='-c'}
    eligible=_qualify_sources(ctx,Path(source),inputs)if inputs else set()
    valid={identity:unit for identity,unit in valid.items()
           if unit['data'][0][1]!='-c' or unit['data'][0][5]in eligible}
    for marker in store.glob('*.scm'):
        if marker.stem not in valid:marker.unlink()
    for identity,unit in valid.items():
        (store/(identity+'.scm')).write_text(_scheme_product_data(unit['data'])+'\n')
    return valid


@contextmanager
def static_unit_products(ctx, work, source, completed):
    """Requalify journal-backed units, then observe the original Make producer.

    This context never executes a compiler. The existing invoke-process must
    return before Scheme closes a unit. Unknown physical writers retain custody.
    """
    if completed.get('stageComplete')is not True:
        raise ValueError('static units require completed stdlib')
    key=completed['context'];source=Path(source);store=Path(work)/'compile-products'/key/'static-units'
    store.mkdir(exist_ok=True)
    valid=prepare_static_units(ctx,store,key,source)
    header=json.loads((ctx.directory/'compile-product-context.json').read_text())
    snapshot=dict(header['inputs'])
    snapshot.update({str(p):digest(p)for p in (source/'build/lib/static').glob('*.h')if p.is_file()})
    outbox=ctx.directory/'static-unit-attempt';outbox.mkdir()
    previous=ctx.env.get('GERBIL_COMPILE_ATTEMPT');ctx.env['GERBIL_COMPILE_ATTEMPT']=str(outbox)
    command_count=len(ctx.commands)
    try:
        yield dict(admitted=len(valid),moduleComplete=False,runtimeAdmitted=False)
    finally:
        if previous is None:ctx.env.pop('GERBIL_COMPILE_ATTEMPT',None)
        else:ctx.env['GERBIL_COMPILE_ATTEMPT']=previous
        producer=ctx.commands[-1]if len(ctx.commands)>command_count else None
        if producer is not None:
            retain_static_units(ctx,source,key,store,outbox,producer,valid,snapshot)


def retain_static_units(ctx,source,key,store,outbox,producer,valid,snapshot):
    from gambit_smp.research_kernel import retain_run_record
    from gambit_smp.gerbil_build.dependencies import _compiler_dependencies
    if not producer.get('parentReaped')or not producer.get('processGroupQuiescent'):
        write(ctx.directory/'static-unit-custody.json',dict(unknownWriters=True,issued=0,runtimeAdmitted=False))
        return
    rows=[]
    for path in sorted(outbox.glob('*.static-completed.json')):
        identity=path.name.removesuffix('.static-completed.json');value=json.loads(path.read_text())
        request=json.loads((outbox/(identity+'.static-request.json')).read_text())
        inp,out=validate_completion(source,key,value,request)
        if value[3]=='reused':
            prior=valid.get(identity)
            if prior is None or prior['data']!=value[:3]:raise ValueError('static hit has no admitted owner')
            deps=[Path(p)for p,_ in value[2]]
        elif request[1]=='-obj':
            deps=_compiler_dependencies(value[2],out.parent,inp)
        else:deps=[]
        identities={str(p):digest(p)for p in [inp,out,*deps]}
        if value[3]=='reused'and identities!=prior['identities']:
            raise ValueError('static hit changed after admission')
        supported=all(str(p)in snapshot and identities[str(p)]==snapshot[str(p)]for p in deps)
        if any(str(p)in snapshot and identities[str(p)]!=snapshot[str(p)]for p in deps):
            raise ValueError('static dependency changed during invocation')
        data=[request,value[1],[[str(p),_git_blob(p)]for p in deps]]
        record=dict(context=key,data=data,identities=identities,producerStage=producer['stage'],
                    producerExit=producer.get('exit'),producerTimedOut=producer.get('timeout'),runtimeAdmitted=False)
        if supported and value[3]=='executed':
            journal=ctx.receipt['journal'];h=json.loads(Path(journal['path']).read_text())
            ref=retain_run_record(ctx.root,outbox/(identity+'.observed.json'),journal['scope'],
                dict(schema='gerbil-static-unit-observation',header=journal,runId=h['runId'],unit=record,runtimeAdmitted=False),h['inputs'])
            record.update(completion=ref,completionRun=str(Path(journal['path']).parent))
            write(store/(identity+'.json'),record)
            (store/(identity+'.scm')).write_text(_scheme_product_data(data)+'\n')
        rows.append(dict(source=str(inp),role=request[1],outcome=value[3],reusable=supported))
    write(ctx.directory/'static-unit-observations.json',dict(units=rows,
        executed=sum(x['outcome']=='executed'for x in rows),reused=sum(x['outcome']=='reused'for x in rows),
        unfinishedRequests=len(list(outbox.glob('*.static-request.json')))-len(rows),
        parentComplete=producer.get('exit')==0 and producer.get('timeout')is False,runtimeAdmitted=False))
