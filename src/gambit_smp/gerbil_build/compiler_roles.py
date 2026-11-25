"""Separate compiler host inputs from downstream language/tool outputs."""

import hashlib
import json
import re
from pathlib import Path
from gambit_smp.framework import digest
from gambit_smp.workspace import write
from gambit_smp.gerbil_build.custody import _scheme_product_data


def material(record):
    """Recover the exact observed fingerprint, including checked source roles."""
    result={k:record[k]for k in ('inputs','environment','system','producerEntry',
            'unmanagedInitialization','providerLoaderSupported','reuseAllowed')}
    result['inputs']=dict(result['inputs'])
    for path,projection in record.get('inputProjections',{}).items():
        value=projection['producerSha256']
        if value is None:result['inputs'].pop(path,None)
        else:result['inputs'][path]=value
    return result


def fingerprint(value):
    return hashlib.sha256(json.dumps(value,sort_keys=True).encode()).hexdigest()


def module_roles(ctx,source):
    """Query the actual header/package reader; unknown identities grant nothing."""
    source=Path(source)
    paths=sorted(p for role in ('gerbil','lang','tools')
                 for p in(source/'src'/role).rglob('*.ss'))
    make=source/'src/std/make.ss';text=make.read_text()
    first=text.index('(def (read-module-header-id path)')
    last=text.index('(def (module-generation-plan source)',first)
    reader=text[first:last]
    canonical=Path(__file__).resolve().parent.parent/'gerbil_compile_products.ss'
    helper=canonical.read_text();json_code=helper[helper.index('(def (compile-product-json'):helper.index('(def (compile-product-record')]
    output=ctx.directory/'compiler-module-roles.json'
    expression=('(import :gerbil/expander) '+reader+json_code
       +' (call-with-output-file '+json.dumps(str(output))
       +' (lambda (port) (compile-product-json (map (lambda (path) '
       +'(let (id (read-module-id path)) (list path (and id (symbol->string id))))) '
       +"'"+_scheme_product_data([str(p)for p in paths])+') port)))')
    before={str(p):digest(p)for p in [make,canonical,*paths]};ctx.bind([make,canonical,*paths])
    ctx.require('compiler-module-role-reader',[str(source/'run.sh'),'gxi','-:p1','-e',expression],
                source/'src',min(30,ctx.remaining()))
    rows=json.loads(output.read_text())
    if (not isinstance(rows,list)or len(rows)!=len(paths)
            or any(not isinstance(row,list)or len(row)!=2 or not(row[1]is False or isinstance(row[1],str))for row in rows)
            or [row[0]for row in rows]!=[str(p)for p in paths]
            or any(digest(Path(p))!=sha for p,sha in before.items())):
        raise ValueError('module role identities differ from their source snapshot')
    host={name for path,name in rows if Path(path).is_relative_to(source/'src/gerbil')}
    if False in host:raise ValueError('unknown compiler host identity cannot be erased')
    targets={name for path,name in rows if name is not False and not Path(path).is_relative_to(source/'src/gerbil')}
    if host&targets:raise ValueError('downstream writer overlaps a compiler host module')
    return dict(host=sorted(host),targets=sorted(targets),sources=before,nativeReaderSha256=digest(output))


def project_inputs(value,source,roles):
    """Erase only exact declared downstream artifacts, never a whole namespace."""
    source=Path(source);result=dict(value);result['inputs']=dict(value['inputs']);erased={}
    patterns=[re.compile(re.escape(name)+r'(?:~(?:[0-9]+|_extern_))?\.(?:ssi|ssxi(?:\.ss)?|scm|c|init|o[0-9]+)(?:\.dSYM/.*)?\Z')for name in roles['targets']]
    for path,sha in value['inputs'].items():
        p=Path(path)
        if p.is_relative_to(source/'build/lib'):
            relative=p.relative_to(source/'build/lib').as_posix()
            if any(pattern.fullmatch(relative)for pattern in patterns):
                erased[path]=sha;result['inputs'].pop(path)
    return result,erased


def bind_retained_context(ctx,work,source,expected,observed,record):
    """Retain a producer's identity only after an explicit semantic-input proof.

    No old file is restored and no product is stamped with a new context.
    Every ordinary byte/witness/dependency check still follows this proof.
    """
    roles=module_roles(ctx,source);current,removed=project_inputs(material(record),source,roles)
    reference=None;original=None;seen=set()
    store=Path(work)/'compile-products'/expected
    for path in sorted(store.glob('*.json')):
        unit=json.loads(path.read_text());folder=unit.get('completionRun')
        if not folder:continue
        candidate=Path(folder)/'compile-product-context.json'
        if candidate in seen:continue
        seen.add(candidate)
        if not candidate.is_file()or not candidate.resolve().is_relative_to(ctx.root):continue
        old=json.loads(candidate.read_text());old_material=material(old)
        if fingerprint(old_material)==expected:
            projected,old_removed=project_inputs(old_material,source,roles)
            reference=dict(path=str(candidate),sha256=digest(candidate),erased=old_removed)
            original=projected
            break
    equal=original is not None and original==current
    proof=dict(retainedProducerContext=expected,observedContext=observed,
        effectiveInputSignature=fingerprint(current),reference=reference,
        sourceRoles=roles,erasedCurrent=removed,equalEffectiveInputs=equal,
        productsRelabeled=False,oldFilesRestored=False,runtimeAdmitted=False)
    write(ctx.directory/'compiler-context-role-proof.json',proof)
    if not equal:return None
    from gambit_smp.research_kernel import retain_run_record
    journal=ctx.receipt['journal'];header=json.loads(Path(journal['path']).read_text())
    proof['observation']=retain_run_record(ctx.root,ctx.directory/'compiler-context-role-observed.json',journal['scope'],
        dict(schema='gerbil-compiler-context-role-observation',header=journal,runId=header['runId'],contextBinding=proof,runtimeAdmitted=False),header['inputs'])
    return proof
