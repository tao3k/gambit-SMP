"""Source-owned library graph traversal; no alternative builder or profile."""

import hashlib
from pathlib import Path


ORIGINAL_ORDER_SHA256 = '0d6dd3894469bb36b2944cd5e87ab45ae276f489e2a6e998b3172807988b2ed9'
COMPLETION_OWNER = '''    ;; Completion belongs to this context object, not its printed module ID.
    ;; Keep aliases with different contexts distinct until the original final
    ;; ID fold. Issue a completion only after every child has returned: an
    ;; active cycle is neither skipped nor assigned a new initialization order.
    (def completed-contexts (make-hash-table-eq))
'''


def original_order(body):
    """Checked inverse of completion bookkeeping, retaining all edge semantics."""
    if body.count(COMPLETION_OWNER) != 1:
        raise ValueError('unreviewed library completion owner')
    text = body.replace(COMPLETION_OWNER, '')
    if '(def (order-modules all-modules (resolve import-module) (view #f))' in text:
        canonical=(Path(__file__).resolve().parent.parent/'gerbil_library_order.ss').read_text()
        start='  ;; Begin immutable dependency view.\n'
        end='  ;; End immutable dependency view.\n'
        view=canonical[canonical.index(start):canonical.index(end)+len(end)]
        if hashlib.sha256(view.encode()).hexdigest() != '21d3c9e8172793a15d610988faa6c964bb26801d09e85289bc56d21cb0766010':
            raise ValueError('unreviewed dependency view adapter')
        if text.count(view)!=1 or not text.endswith(')'):
            raise ValueError('dependency view scope differs')
        text=text.replace(view,'')[:-1]
        text=text.replace('(def (order-modules all-modules (resolve import-module) (view #f))',
                          '(def (order-modules all-modules (resolve import-module))')
    if '(def (order-modules all-modules (resolve import-module))' in text:
        text = text.replace('(def (order-modules all-modules (resolve import-module))',
                            '(def (order-modules all-modules)')
        text = text.replace('(resolve mod-id)', '(import-module mod-id)')
    replacements = [
        ('(module-exclude? hd)\n                   (hash-get completed-contexts hd)', '(module-exclude? hd)'),
        ('(module-exclude? hd)\n                     (hash-get completed-contexts hd)', '(module-exclude? hd)'),
    ]
    for new, old in replacements:
        if text.count(new) != 1:
            raise ValueError('library context admission changed')
        text = text.replace(new, old)
    for indent in (22, 17):
        line = ' '*indent+'(hash-put! completed-contexts hd #t)\n'
        expected = 1 if indent == 22 else 2
        if text.count(line) != expected:
            raise ValueError('library completion cut changed')
        text = text.replace(line, '')
    if hashlib.sha256(text.encode()).hexdigest() != ORIGINAL_ORDER_SHA256:
        raise ValueError('library graph semantics differ outside the owned completion cut')
    return text


def library_order_source(text, *, inverse=False):
    """Replace only the reviewed function, keeping official entrypoints intact."""
    path = Path(__file__).resolve().parent.parent/'gerbil_library_order.ss'
    canonical = path.read_text()
    new = canonical[canonical.index('(def (order-modules '):].strip()
    old = original_order(new)
    previous = new.replace('(def (order-modules all-modules (resolve import-module) (view #f))',
                           '(def (order-modules all-modules (resolve import-module))')
    start='  ;; Begin immutable dependency view.\n';end='  ;; End immutable dependency view.\n'
    previous=previous.replace(previous[previous.index(start):previous.index(end)+len(end)],'')[:-1]
    if text.count(new) == 1:
        return text.replace(new, old) if inverse else text
    if text.count(previous) == 1:
        return text.replace(previous, old if inverse else new)
    initial=previous.replace('(def (order-modules all-modules (resolve import-module))','(def (order-modules all-modules)').replace('(resolve mod-id)','(import-module mod-id)')
    if text.count(initial)==1:
        return text.replace(initial,old if inverse else new)
    if text.count(old) != 1:
        raise ValueError('pinned original library ordering function differs')
    return text if inverse else text.replace(old, new)


def library_initialization_source(text, *, inverse=False):
    """Use only issued semantic graphs; ordinary unmanaged builds stay upstream."""
    helpers=(Path(__file__).resolve().parent.parent/'gerbil_initialization_view.ss').read_text()
    helpers=';;; Begin issued initialization view.\n'+helpers+';;; End issued initialization view.\n\n'
    legacy_head='(def (build-libgerbil)\n  (when (getenv "GERBIL_COMPILE_CONTEXT" #f)\n    (gx#import-module "gerbil/compiler/driver.ss" #t #t))\n'
    catalog_head=legacy_head.replace('gerbil/compiler/driver.ss', 'gerbil/compiler/compile-product-catalog.ss')
    legacy_call='(ordered-modules\n          (if (getenv "GERBIL_COMPILE_CONTEXT" #f)\n            (order-modules stdlib-modules gxc#compile-product-initialization-context)\n            (order-modules stdlib-modules)))'
    fast_call='(ordered-modules\n          (if (getenv "GERBIL_COMPILE_CONTEXT" #f)\n            (order-modules stdlib-modules initialization-graph-resolve initialization-graph-operations)\n            (order-modules stdlib-modules)))'
    begin=';;; Begin issued initialization view.\n';end=';;; End issued initialization view.\n\n'
    if begin in text:
        if text.count(begin)!=1 or text.count(end)!=1:
            raise ValueError('initialization view ownership region differs')
        # This region is a planning consumer, never a stdlib generator input.
        # Its source is still observed; edits outside it are not normalized.
        start=text.index(begin);stop=text.index(end,start)+len(end)
        text=text[:start]+text[stop:]
    if catalog_head in text:
        text=text.replace(catalog_head,legacy_head)
    if legacy_head in text:
        call=fast_call if fast_call in text else legacy_call
        if text.count(legacy_head)!=1 or text.count(call)!=1:
            raise ValueError('checked graph reader call differs')
        text=text.replace(legacy_head,'(def (build-libgerbil)\n').replace(call,'(ordered-modules (order-modules stdlib-modules))')
    if inverse:return text
    old_head='(def (build-libgerbil)\n';old_call='(ordered-modules (order-modules stdlib-modules))'
    if text.count(old_head)!=1 or text.count(old_call)!=1:
        raise ValueError('library semantic-graph consumer boundary differs')
    return text.replace(old_head,helpers+catalog_head).replace(old_call,fast_call)


def check_library_order(ctx, source, *, first_seed=1, cases=256):
    """Native replay/shrink over actual old/new functions and expander records."""
    import json
    from gambit_smp.framework import digest
    from gambit_smp.workspace import write
    if type(first_seed) is not int or type(cases) is not int or first_seed < 1 or cases < 1:
        raise ValueError('explicit positive replay range required')
    candidate = Path(__file__).resolve().parent.parent/'gerbil_library_order.ss'
    fixture = ctx.root/'tests/fixtures/library-order.ss'
    text = candidate.read_text()
    body = text[text.index('(def (order-modules '):].strip()
    baseline = ctx.directory/'library-order-original.ss'
    baseline.write_text(original_order(body)+'\n')
    ctx.bind([candidate, fixture, baseline])
    expression = ('(import '+json.dumps(str(fixture))+') (verify-library-order '
                  +json.dumps(str(baseline))+' '+json.dumps(str(candidate))
                  +' '+str(first_seed)+' '+str(cases)+')')
    output = ctx.require('library-order-native-properties',
        [str(Path(source)/'run.sh'), 'gxi', '-:p1', '-e', expression],
        Path(source)/'src', min(30, ctx.remaining()))
    marker = f'LIBRARY-ORDER-PBT-PASS first={first_seed} cases={cases}'
    if (marker not in output or f'SEMANTIC-GRAPH-ROUNDTRIP-PASS cases={cases}' not in output
            or f'INITIALIZATION-PROJECTION-PASS cases={cases}' not in output
            or 'LIBRARY-ORDER-MUTANT-CAUGHT seed=7 minimal=' not in output
            or 'LIBRARY-ORDER-GC-DIAMOND-PASS' not in output):
        raise ValueError('native library-order property receipt missing')
    record = dict(complete=True, firstSeed=first_seed, cases=cases, forcedGcDiamond=True,
        initializationViewSha256=digest(candidate.with_name('gerbil_initialization_view.ss')),
        initializationProjection=True,
        originalBodySha256=ORIGINAL_ORDER_SHA256, candidateSha256=digest(candidate),
        fixtureSha256=digest(fixture), output=output, runtimeAdmitted=False,
        scope='Actual source functions, actual expander context types, injected root resolver only; exact finite order, aliases, prelude/phase edges, GC and bounded active-cycle nonpublication. Not whole library acceptance.')
    write(ctx.directory/'library-order-properties.json', record)
    return record


def check_library_order_root(ctx, source):
    """Replay the real singleton that previously exhausted the diagnostic bound."""
    import json
    from gambit_smp.framework import digest
    from gambit_smp.workspace import write
    source = Path(source)
    script = source/'src/build/build-libgerbil.ss'
    library_order_source(script.read_text())  # Refuse an unreviewed owner.
    ctx.bind([script])
    expression = ('(include '+json.dumps(str(script))+') '
        '(let* ((spec (build-spec)) (modules (map car (filter-map filter-build-spec spec))) '
        '(ordered (order-modules (take modules 1)))) '
        '(displayln "LIBRARY-ORDER-FIRST-ROOT " (length ordered)) (write ordered) (newline))')
    output = ctx.require('library-order-real-singleton',
        [str(source/'run.sh'), 'gxi', '-:p1', '-e', expression],
        source/'src', min(30, ctx.remaining()))
    if 'LIBRARY-ORDER-FIRST-ROOT ' not in output:
        raise ValueError('original singleton did not produce an order')
    record = dict(complete=True, scriptSha256=digest(script), output=output,
        runtimeAdmitted=False, scope='Original std/build-config root and original builder definitions; successful dependency order only, not full library/native initialization admission.')
    write(ctx.directory/'library-order-singleton.json', record)
    return record


def check_semantic_contexts(ctx, source, modules):
    """Compare real expanded source with its actual emitted SSI consumer.

    Each process uses the original evaluator; no all-phase metadata inference,
    evaluator suppression, or aggregate global-table capacity workaround.
    """
    import json
    from gambit_smp.workspace import write
    source = Path(source)
    fixture = ctx.root/'tests/fixtures/semantic-context.ss'
    candidate = Path(__file__).resolve().parent.parent/'gerbil_library_order.ss'
    ctx.bind([fixture, candidate])
    observations = []
    for name in modules:
        if not name.startswith('std/') or any(x in ('', '.', '..') for x in name.split('/')):
            raise ValueError('explicit owned standard module required')
        src, interface = source/'src'/(name+'.ss'), source/'build/lib'/(name+'.ssi')
        ctx.bind([src, interface])
        expression = ('(import '+json.dumps(str(fixture))+') (verify-semantic-context '
            +' '.join(json.dumps(str(p)) for p in (src, interface))+')')
        output = ctx.require('semantic-context-'+name.replace('/', '-'),
            [str(source/'run.sh'), 'gxi', '-:p1', '-e', expression],
            source/'src', min(30, ctx.remaining()))
        if 'SEMANTIC-CONTEXT-INTERFACE-PASS '+name+' ' not in output:
            raise ValueError('actual source/interface order comparison missing')
        observations.append(dict(module=name, output=output))
    record = dict(complete=True, observations=observations, runtimeAdmitted=False,
        scope='Actual original evaluator, source context, generated SSI context and serialized graph consumer, holding the completion-owned traversal fixed. Old-algorithm equivalence is a separate conditional source/PBT obligation. Selected modules only.')
    write(ctx.directory/'semantic-contexts.json', record)
    return record


def check_initialization_planning(ctx, source, admitted, store, key):
    """Run installed planning over an already issued dependency-closed subset.

    This issues no markers and grants no incomplete program admission. The
    complete library and its native construction remain separate checks.
    """
    import json
    from gambit_smp.gerbil_build.custody import _module_witnesses, AdmissionFiles
    from gambit_smp.framework import digest
    from gambit_smp.workspace import write
    source, admitted, store = Path(source), Path(admitted), Path(store)
    records=json.loads(admitted.read_text())
    if not records or any(r['context']!=key or not r.get('initializationGraph') for r in records):
        raise ValueError('issued same-context graph-bearing programs required')
    witnesses=_module_witnesses(ctx.root,dict(enumerate(records)),
        schema='gerbil-module-product-observation',payload_key='moduleProduct')
    files=AdmissionFiles();bound=[admitted];modules=[]
    for record in records:
        ref=record['completion'];identity=tuple(ref[k]for k in ('path','sha256','observation','scope'))
        core={k:v for k,v in record.items()if k not in ('completion','completionRun')}
        if witnesses.get(identity)!=core or not all(files.matches(p,h)for p,h in record['identities'].items()):
            raise ValueError('planning input lost its immutable complete-program witness')
        relative=Path(record['source']).relative_to(source)
        bound.append(Path(record['initializationGraph']))
        modules.append(Path(record['source']).relative_to(source/'src').with_suffix('').as_posix())
    fixture=ctx.root/'tests/fixtures/semantic-context.ss'
    script=source/'src/build/build-libgerbil.ss';driver=source/'src/gerbil/compiler/driver.ss'
    ctx.bind([*bound,fixture,script,driver,source/'src/gerbil/compiler/compile-products.ss'])
    indexed={value['source']:(p.stem,value)for p in (store/'modules').glob('*.json')
             for value in [json.loads(p.read_text())]}
    programs={}
    for record in records:
        identity,current=indexed[record['source']]
        if current!=record:raise ValueError('admitted program incarnation changed')
        programs[identity]=record
    saved=dict(ctx.env)
    try:
        ctx.env.update(GERBIL_COMPILE_PRODUCTS=str(store),GERBIL_COMPILE_CONTEXT=key,
            GERBIL_COMPILE_ATTEMPT=str(ctx.directory),GERBIL_COMPILE_REUSE='1',GERBIL_GIT=str(ctx.tools['git']))
        expression='(import '+json.dumps(str(fixture))+') (verify-initialization-plan '+json.dumps(str(script))+' '+json.dumps(str(driver))+' (list '+' '.join(json.dumps(m)for m in modules)+'))'
        from gambit_smp.gerbil_build.initialization_views import planning_views
        with planning_views(ctx,source,store,programs) as views:
            output=ctx.require('initialization-issued-data-plan',
                [str(source/'run.sh'),'gxi','-:p1','-e',expression],source/'src',min(30,ctx.remaining()))
    finally:ctx.env.clear();ctx.env.update(saved)
    line=next((x for x in output.splitlines()if x.startswith('INITIALIZATION-PLAN ')),None)
    if line is None or 'INITIALIZATION-PLAN-PASS'not in output:raise ValueError('native planning receipt missing')
    roots,ordered,before,after=json.loads(line[len('INITIALIZATION-PLAN '):])
    if roots!=len(records) or before!=after:raise ValueError('planning observation differs from issued roots')
    result=dict(complete=True,roots=roots,ordered=ordered,globalsBefore=before,globalsAfter=after,
        fixtureSha256=digest(fixture),scriptSha256=digest(script),output=output,runtimeAdmitted=False,
        scope='Installed library traversal, issued projection reader and existing gxc credential parser, over already issued complete programs only. Counter instrumentation includes observer effects; no complete library/native build or paired speedup follows.')
    ctx.bind(bound)
    write(ctx.directory/'initialization-planning.json',result)
    return result


def check_tool_resource_boundary(ctx,source):
    """An observed exception counter, not a successful tools-stage receipt."""
    import json,re
    from pathlib import Path
    from gambit_smp.workspace import write
    source=Path(source)
    fixture=ctx.root/'tests/fixtures/global-registration-state.scm'
    probe=ctx.directory/'global-registration-state.o1'
    ctx.bind([fixture])
    ctx.require('compile-global-registration-observer',
        [str(source/'build/bin/gsc'),'-o',str(probe),str(fixture)],
        source/'src/tools',min(30,ctx.remaining()))
    expression="""(load OBSERVER)
(let (previous ##primordial-exception-handler-hook)
 (##primordial-exception-handler-hook-set!
   (lambda (exception terminate)
     (display "TOOLS-RESOURCE-EXCEPTION ")
     (write (gambit.smp.globals#registration-count)) (newline) (force-output)
     (previous exception terminate))))""".replace('OBSERVER',json.dumps(str(probe)))
    code,output,timeout,_=ctx.run('tools-resource-boundary',
        [str(source/'run.sh'),'gxi','-:p1','-e',expression,
         str(source/'src/tools/build.ss')],source/'src/tools',min(30,ctx.remaining()))
    counts=[int(x)for x in re.findall(r'TOOLS-RESOURCE-EXCEPTION (\d+)',output)]
    result=dict(complete=bool(counts) and 'Implementation limit' in output,counts=counts,exit=code,timeout=timeout,
        runtimeAdmitted=False,scope='Diagnostic handler changes the observation context. Not an unmodified whole tools pass, exact baseline attribution or permission to enlarge capacity.')
    write(ctx.directory/'tools-resource-boundary.json',result)
    return result
