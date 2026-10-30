#!/usr/bin/env python3
"""Static source and formal research; never runs or builds native Gambit."""
import copy
import hashlib
import importlib.util
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
STEM = 'primitive-header-binding'
BASE = 'dev/refactoring/modern-c/'
CACHE = ROOT / '.cache/tasks' / STEM
OUT = ROOT / 'evidence/research' / STEM
PKG = 'GambitPrimitiveHeaderBinding'


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


h = load('primitive_research', 'dev/modeling/tools/advantage-architecture-study.py')
h.CACHE = CACHE
h.OUT = OUT
run, save, sha = h.run, h.save, h.sha


def bytes_audit(snapshots):
    path = 'vendor/gambit/lib/_kernel.c'
    raw = (ROOT / snapshots[path]['path']).read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    name = b'##get-monotonic-time!'
    encoded = b'___G__23__23_get_2d_monotonic_2d_time_21_'
    section = b'globals-s-nd'
    marker = b'( #|*/"*/"' + section + b'|#\n'
    begin = raw.index(marker) + len(marker)
    end = raw.index(b') #|*/"*/"' + section + b'|#', begin)
    records = []

    def add(key, start, stop, **fields):
        assert 0 <= start < stop <= len(raw)
        payload = raw[start:stop]
        row = dict(key=key, start=start, stop=stop, line=raw[:start].count(b'\n')+1,
                   payload=payload.decode('ascii'), payloadSha256=hashlib.sha256(payload).hexdigest(), **fields)
        records.append(row)
        return row

    header = b'"' + name + b'"\n'
    pos = raw.index(header, begin, end)
    add('header-name', pos, pos+len(header), section='globals-s-nd')
    binding = {}
    for role in ['PRM', 'GLO']:
        pattern = rb'^___DEF_MOD_' + role.encode() + rb'\((\d+),(' + re.escape(encoded) + rb'),(\d+)\)\n'
        matches = list(re.finditer(pattern, raw, re.M))
        assert len(matches) == 1
        m = matches[0]
        binding[role] = (int(m[1]), m[2].decode(), int(m[3]))
        add(role, m.start(), m.end(), slot=int(m[1]), label=int(m[3]),
            fields=[dict(start=m.start(i), stop=m.end(i), text=m[i].decode()) for i in [1, 2, 3]])
    assert binding['PRM'] == binding['GLO'] == (146, encoded.decode(), 828)
    m = re.search(rb'^___DEF_GLO\((\d+),"'+re.escape(name)+rb'"\)\n', raw, re.M)
    assert m and int(m[1]) == binding['PRM'][0]
    add('global-index', m.start(), m.end(), slot=int(m[1]))
    host = b'#define ___PH_PROC ___H__23__23_get_2d_monotonic_2d_time_21_\n'
    start = raw.index(host)
    m = re.match(rb'#define ___PH_PROC [^\n]+\n#undef ___PH_LBL0\n#define ___PH_LBL0 (\d+)\n', raw[start:])
    assert m and int(m[1]) == binding['PRM'][2]
    add('host-label', start, start+m.end(), label=int(m[1]))
    intro = b',___DEF_LBL_INTRO(___H__23__23_get_2d_monotonic_2d_time_21_,'
    pos = raw.index(intro)
    add('label-intro', pos, raw.index(b'\n', pos)+1)
    table_start=raw.index(b'___BEGIN_LBL\n')+len(b'___BEGIN_LBL\n')
    table_stop=raw.index(b'___END_LBL\n',table_start)
    entries=list(re.finditer(rb'^[ ,]___DEF_LBL_(INTRO|PROC|RET)\([^\n]+\)\n',raw[table_start:table_stop],re.M))
    assert b''.join(m[0] for m in entries)==raw[table_start:table_stop]
    entry=entries[binding['PRM'][2]]
    assert entry[0]==b',___DEF_LBL_PROC(___H__23__23_get_2d_monotonic_2d_time_21_,2,-1)\n'
    add('label-proc',table_start+entry.start(),table_start+entry.end(),label=binding['PRM'][2])
    records.sort(key=lambda x: x['start'])
    assert all(a['stop'] <= b['start'] for a, b in zip(records, records[1:]))

    def validate(rs):
        for v in rs:
            assert raw[v['start']:v['stop']].decode() == v['payload']
            assert hashlib.sha256(raw[v['start']:v['stop']]).hexdigest() == v['payloadSha256']
        by = {v['key']:v for v in rs}
        for role in ['PRM', 'GLO']:
            v = by[role]
            assert v['payload'] == f'___DEF_MOD_{role}({v["slot"]},{encoded.decode()},{v["label"]})\n'
        assert by['PRM']['slot'] == by['GLO']['slot'] and by['PRM']['label'] == by['GLO']['label']

    validate(records)
    controls = {}
    for case in ['shifted-span', 'wrong-label', 'swapped-role']:
        rs = copy.deepcopy(records)
        v = next(x for x in rs if x['key']=='PRM')
        if case == 'shifted-span': v['start'] += 1
        if case == 'wrong-label': v['label'] += 1
        if case == 'swapped-role': v['key'] = 'GLO'
        try:
            validate(rs)
        except (AssertionError, KeyError):
            controls[case] = 'rejected'
        else:
            raise AssertionError(case)
    all_bindings={role:[tuple(m.groups()) for m in re.finditer(rb'^___DEF_MOD_'+role.encode()+rb'\((\d+),([^,\n]+),(\d+)\)\n',raw,re.M)] for role in ['PRM','GLO']}
    assert all_bindings['PRM']==all_bindings['GLO'] and len(set(all_bindings['PRM']))==455
    witness = dict(source=path, sha256=digest, bytes=len(raw), intervals='zero-based-half-open-bytes',
                   records=records, selectedBinding=binding, wholeOutputCovered=False,
                   artifactPrimitiveRecords=455, artifactBindingRecords=910,
                   productionModuleSpec=False, sourceGenerationProvenance='unresolved',
                   darwinProfileProvenance='unresolved', controls=controls)
    save(OUT/'byte-witness.json', witness)
    return [[v['key'], digest, str(v['start']), str(v['stop']), v['payloadSha256']] for v in records]


def formal():
    e = load('primitive_projection', 'dev/modeling/tools/'+STEM+'-projection.py')
    cfg = e.SPEC
    qnt = BASE+'models/quint/'+cfg['module']+'.qnt'
    run('qnt-typecheck', ['quint', 'typecheck', qnt, '--out', str(CACHE/'typed-ir.json')])
    ir = json.loads((CACHE/'typed-ir.json').read_text())
    ast, receipt = e.generate(ir)
    astpath = BASE+'models/lean/PrimitiveHeaderAst.lean'
    (ROOT/astpath).write_text(ast)
    save(CACHE/'projection-receipt.json', dict(**receipt, irSha256=sha(CACHE/'typed-ir.json'), astSha256=sha(ROOT/astpath)))
    controls = {}
    for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression']:
        bad = copy.deepcopy(ir)
        ds = {d['name']:d for d in bad['modules'][0]['declarations']}
        if case=='wrong-state-binding': bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
        if case=='wrong-field-kind': ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
        if case=='missing-step': ds['step']['expr']['args'].pop(0)
        if case=='unsupported-expression': ds['safe']['expr']['opcode']='unsupported'
        try: e.generate(bad)
        except (AssertionError,KeyError): controls[case]='rejected'
        else: raise AssertionError(case)
    save(CACHE/'projection-controls.json',controls)
    proof_names=['PrimitiveHeaderAst','PrimitiveHeader','PrimitiveBindingAlgebra']
    formal_paths=[qnt,'dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py']+[BASE+'models/lean/'+n+'.lean' for n in proof_names]
    if '--reuse-formal' in sys.argv:
        cp=json.loads((CACHE/'formal-checkpoint.json').read_text())
        assert {f:sha(ROOT/f) for f in formal_paths}==cp['sourceBindings']
        assert all(sha(ROOT/f)==d for f,d in cp['logs'].items())
        lemmas=[[n+'.'+x] for n in proof_names[1:] for x in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
        return [[cfg['module']+'.'+a] for a in cfg['actions']],lemmas
    for name in ['PrimitiveHeaderAst','PrimitiveHeader','PrimitiveBindingAlgebra']:
        src=ROOT/(BASE+'models/lean/'+name+'.lean')
        assert not re.search(r'\bsorry\b|\baxiom\s',src.read_text())
        target=CACHE/(name+'.lean');target.write_bytes(src.read_bytes())
        run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(target)])
    output=run('qnt-histories',['quint','test',qnt,'--match','Test$'])
    assert output.count('ok ')==11 and output.count('ControlTest passed')==4
    run('qnt-samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','100','--seed','149','--verbosity','1'])
    # A missing close guard must break the actual inductive proof.
    neg=CACHE/'negative-close';neg.mkdir(exist_ok=True)
    bad='\n'.join(line.replace('(q.closed=true)','True') if line.startswith('def issueGuard') else line for line in ast.splitlines())+'\n'
    assert bad!=ast
    (neg/'PrimitiveHeaderAst.lean').write_text(bad)
    run('negative-ast',['lean','-o',str(neg/'PrimitiveHeaderAst.olean'),str(neg/'PrimitiveHeaderAst.lean')])
    try: run('negative-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/PrimitiveHeader.lean'])
    except RuntimeError: assert 'error' in (CACHE/'negative-proof.stdout').read_text()
    else: raise AssertionError('missing close proved')
    lemmas=[[n+'.'+x] for n in ['PrimitiveHeader','PrimitiveBindingAlgebra'] for x in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
    save(CACHE/'formal-checkpoint.json',dict(sourceBindings={f:sha(ROOT/f) for f in formal_paths},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and f.stem in proof_names+['qnt-histories','qnt-samples','negative-ast','negative-proof']}))
    return [[cfg['module']+'.'+a] for a in cfg['actions']],lemmas


def caller_audit(p, snapshots):
    path='vendor/gambit/gsc/_t-c-2.scm'
    text=(ROOT/snapshots[path]['path']).read_text()
    definitions=list(re.finditer(r'^\(define \(([^\s()]+)',text,re.M))
    rows=[]
    for m in re.finditer(r'\(targ-use-glo name (#t|#f)\)',text):
        owner=[d for d in definitions if d.start()<m.start()][-1].group(1)
        rows.append((owner,m.group(1),text[:m.start()].count('\n')+1))
    wanted={v['caller'] for v in p['caller']}
    assert len(rows)==6 and {v[0] for v in rows}==wanted
    expected={'demand false':'#f','supply true':'#t','supply then demand':'#t'}
    for v in p['caller']:
        assert [r[1] for r in rows if r[0]==v['caller']]==[expected[v['effect']]]
    # This is the second edge in the supply-then-demand source sequence.
    start=next(d.start() for d in definitions if d.group(1)=='targ-loc-opnd')
    stop=next(d.start() for d in definitions if d.start()>start)
    assert text[start:stop].index('(targ-use-glo name #t)')<text[start:stop].index('(targ-opnd loc)')
    out=[[owner,flag,str(line),snapshots[path]['sha256']] for owner,flag,line in rows]
    save(CACHE/'caller-audit.json',dict(rows=out,scope='six lexical direct callers; dynamic alias closure OPEN'))
    return out


def ascent(p, witnesses, spans, actions, lemmas, callers):
    needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
    ws=[[v['key'],v['path'],v['sha256'],v['needle']] for v in witnesses]
    migrations=[[v[k] for k in ['key','producerAnchor','consumerAnchor','actionName','lemma']] for v in p['migration']]
    results={};engine=h.Engine()
    cases=['current','synthetic-all','stale-digest','wrong-scope','missing-action','missing-lemma','missing-source','missing-migration','wrong-producer','wrong-span','wrong-span-digest','wrong-caller']
    try:
        ss=engine.open_sources((ROOT/('dev/modeling/ascent/'+STEM+'.rules.scm')).read_text())
        assert ss.run(queries=['blocked'])['complete']
        for case in cases:
            receipts=[[case,n,f,d,s] for n,k,f,d,s in needs if case!='current' or k in ['induction','interleaving','restricted-projection']]
            if case=='stale-digest': receipts[0][3]='stale'
            if case=='wrong-scope': receipts[0][4]='native-pass'
            mo=copy.deepcopy(migrations)
            if case=='missing-migration': mo=mo[1:]
            if case=='wrong-producer': mo[0][1]='unknown-producer'
            observed=copy.deepcopy(spans)
            if case=='wrong-span': observed[0][2]=str(int(observed[0][2])+1)
            if case=='wrong-span-digest': observed[0][4]='stale'
            callerObservation=copy.deepcopy(callers)
            if case=='wrong-caller':callerObservation[0][0]='unknown-caller'
            ss.replace(dict(scenario=[[case]],need=needs,receipt=receipts,
                binding=[[v['actionName'],v['lemma']] for v in p['binding']],
                actionName=actions[1:] if case=='missing-action' else actions,
                lemmaName=[v for v in lemmas if case!='missing-lemma' or v!=['PrimitiveHeader.seedSupplyPreserves']],
                witness=ws,observation=ws[1:] if case=='missing-source' else ws,
                compositionNeed=[[v['key'],v['lemma']] for v in p['proof']],refinementNeed=[],targetActionName=[],
                bridgeNeed=[],bridgeObservation=[],inventoryNeed=[],inventoryObservation=[],seamNeed=[],seamObservation=[],
                migrationNeed=migrations,migrationObservation=mo,spanNeed=spans,spanObservation=observed,callerNeed=callers,callerObservation=callerObservation))
            result=ss.run(queries=['blocked','candidate','linked','compositionLinked','observed','migrationLinked','spanLinked','callerLinked'])
            assert result['complete'];results[case]=result['relations']
        save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
        assert {v[1] for v in results['current']['blocked']}=={'PH-source','PH-emission','PH-platform'}
        assert [c for c in cases if results[c]['candidate']]==['synthetic-all']
        assert len(results['current']['linked'])==12
        assert len(results['current']['observed'])==len(witnesses)
        assert len(results['current']['migrationLinked'])==4
        assert len(results['current']['spanLinked'])==len(spans)
        assert len(results['current']['callerLinked'])==6
    finally: engine.close()
    save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))


def main():
    CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    config=json.loads((CACHE/'config.json').read_text())
    snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
    for path,v in snapshots.items(): assert sha(ROOT/path)==sha(ROOT/v['path'])==v['sha256'],path
    parent=ROOT/'evidence/research/emission-view-correspondence/input.json';parentHash=sha(parent)
    adapter=load('primitive_native_sysml','dev/modeling/tools/default-lease-admission-study.py')
    for k,v in dict(CACHE=CACHE,OUT=OUT,PKG=PKG,GROUPS=config['groups'],SLOTS=config['slots']).items(): setattr(adapter,k,v)
    adapter.h.CACHE=CACHE;adapter.h.OUT=OUT
    p,scope=adapter.project()
    views=load('primitive_views','dev/modeling/tools/copy-producer-envelope-study.py')
    for k,v in dict(ROOT=ROOT,GROUPS=config['groups'],MATRIX=BASE+STEM+'-matrix.org',D2=BASE+'diagrams/'+STEM+'.d2').items():setattr(views,k,v)
    views.views(p)
    matrix=ROOT/(BASE+STEM+'-matrix.org')
    matrix.write_text(matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Primitive Header, Native Binding and Net Benefit Matrix').replace('GambitCopyProducerEnvelope',PKG))
    witnesses=[]
    for v in p['source']:
        snap=snapshots[v['path']];text=(ROOT/snap['path']).read_text()
        assert v['needle'] in text,v
        witnesses.append(dict(**v,sha256=snap['sha256'],snapshotPath=snap['path'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
    save(CACHE/'source-witnesses.json',witnesses)
    spans=bytes_audit(snapshots)
    callers=caller_audit(p,snapshots)
    actions,lemmas=formal()
    ascent(p,witnesses,spans,actions,lemmas,callers)
    d2=BASE+'diagrams/'+STEM+'.d2'
    run('d2-svg',['d2','--layout','elk',d2,d2[:-3]+'.svg'])
    run('d2-png',['d2','--layout','elk',d2,str(CACHE/'diagram.png')])
    org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
    for old,new in [('dev/architecture/toolchain/iter-compiler-service-design.org',BASE+STEM+'-design.org'),('dev/architecture/toolchain/iter-compiler-service-matrix.org',BASE+STEM+'-matrix.org'),('dev/architecture/toolchain/index.org',BASE+'index.org')]:org=org.replace(old,new)
    (CACHE/'check-org.el').write_text(org)
    assert sha(parent)==parentHash
    assert not [path for path,v in snapshots.items() if sha(ROOT/path)!=v['sha256']]
    checks=dict(status='conditional-formal-and-selected-artifact-pass',sourceSnapshots=len(snapshots),sourceAnchors=len(witnesses),directCallerLinks=6,qntActions=len(actions),qntHistories=11,negativeHistories=4,qntSamples=500,sampleSeed=149,leanTheorems=len(lemmas),allStepInduction=True,projectionNegativeControls=4,leanNegativeControls=1,spanNegativeControls=3,ascentScenarios=12,byteSpans=len(spans),migrationLinks=4,actualCandidate=False,blockers=['PH-source','PH-emission','PH-platform'],artifactGenerationProvenance=False,fullEmissionCorrespondence=False,c11Refinement=False,nativeTestsRun=False,performanceTestsRun=False,sourceDrift=[])
    save(CACHE/'checks.json',checks)
    own=[BASE+'models/sysml/'+STEM+'.sysml',BASE+STEM+'-design.org',BASE+STEM+'-matrix.org',d2,d2[:-3]+'.svg',BASE+'index.org',
         'dev/modeling/ascent/'+STEM+'.rules.scm','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/'+STEM+'-projection.py',
         BASE+'models/quint/primitive_header_binding.qnt']
    own += [BASE+'models/lean/'+n+'.lean' for n in ['PrimitiveHeaderAst','PrimitiveHeader','PrimitiveBindingAlgebra']]
    own += ['dev/modeling/tools/'+n for n in ['advantage-architecture-study.py','default-lease-admission-study.py','copy-producer-envelope-study.py','chunk-capacity-charge-projection.py']]
    own += [v['path'] for v in snapshots.values()]+[str((CACHE/n).relative_to(ROOT)) for n in ['config.json','source-snapshots.json']]
    save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),branch=run('branch',['git','branch','--show-current']).strip(),parentInputSha256=parentHash,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snapshots,sysmlInputs=scope,logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
    for f in CACHE.iterdir():
        if f.is_file() and f.suffix in ['.json','.stdout','.stderr']: shutil.copyfile(f,OUT/f.name)
    run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
    bound=json.loads((CACHE/'input.json').read_text())
    bound['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}
    save(CACHE/'input.json',bound)
    for f in CACHE.iterdir():
        if f.is_file() and f.suffix in ['.json','.stdout','.stderr']: shutil.copyfile(f,OUT/f.name)
    for d in CACHE.glob('retained-*-failure'):
        shutil.copytree(d,OUT/d.name,dirs_exist_ok=True)
    save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
    print(json.dumps(checks))


if __name__=='__main__':
    main()
