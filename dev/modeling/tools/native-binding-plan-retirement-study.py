#!/usr/bin/env python3
"""Source/formal research only. Native SysML owns routing. No native builds."""
import copy
import hashlib
import importlib.util
import json
import re
import shutil
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
STEM='native-binding-plan-retirement'
BASE='dev/refactoring/modern-c/'
PKG='GambitNativeBindingPlanRetirement'
CACHE=ROOT/'.cache/tasks'/STEM
OUT=ROOT/'evidence/research'/STEM


def load(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


h=load('binding_research','dev/modeling/tools/advantage-architecture-study.py')
h.CACHE=CACHE;h.OUT=OUT
run,save,sha=h.run,h.save,h.sha


def ascend(p,witnesses,inventory,actions,lemmas,parent):
    needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
    ws=[[v['key'],v['path'],v['sha256'],v['needle']] for v in witnesses]
    migrations=[[v[k] for k in ['key','producerAnchor','consumerAnchor','actionName','lemma']] for v in p['migration']]
    bridges=[['prior-value-algebra',str(parent.relative_to(ROOT)),sha(parent),'NativeBindingRefinement.normalizationCanBePlannedOnce']]
    cases=['current','synthetic-all','stale-digest','wrong-scope','missing-action','missing-lemma','missing-source','missing-migration','wrong-producer','wrong-inventory','wrong-parent']
    results={};engine=h.Engine()
    try:
        ss=engine.open_sources((ROOT/('dev/modeling/ascent/'+STEM+'.rules.scm')).read_text())
        assert ss.run(queries=['blocked'])['complete']
        for case in cases:
            receipts=[[case,n,f,d,s] for n,k,f,d,s in needs if case!='current' or k in ['induction','interleaving','restricted-projection']]
            if case=='stale-digest':receipts[0][3]='stale'
            if case=='wrong-scope':receipts[0][4]='native-pass'
            mo=copy.deepcopy(migrations)
            if case=='missing-migration':mo=mo[1:]
            if case=='wrong-producer':mo[0][1]='unknown-producer'
            io=copy.deepcopy(inventory)
            if case=='wrong-inventory':io[0][2]='999'
            bo=copy.deepcopy(bridges)
            if case=='wrong-parent':bo[0][2]='stale'
            ss.replace(dict(scenario=[[case]],need=needs,receipt=receipts,
                binding=[[v['actionName'],v['lemma']] for v in p['binding']],
                actionName=actions[1:] if case=='missing-action' else actions,
                lemmaName=[v for v in lemmas if case!='missing-lemma' or v!=['NativeBindingPlan.discoverPreserves']],
                witness=ws,observation=ws[1:] if case=='missing-source' else ws,
                compositionNeed=[[v['key'],v['lemma']] for v in p['proof']],refinementNeed=[],targetActionName=[],
                bridgeNeed=bridges,bridgeObservation=bo,inventoryNeed=inventory,inventoryObservation=io,
                seamNeed=[],seamObservation=[],migrationNeed=migrations,migrationObservation=mo,
                spanNeed=[],spanObservation=[],callerNeed=[],callerObservation=[]))
            result=ss.run(queries=['blocked','candidate','linked','compositionLinked','observed','migrationLinked','bridgeLinked','inventoryLinked'])
            assert result['complete'];results[case]=result['relations']
        save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
        assert {v[1] for v in results['current']['blocked']}=={'NB-source','NB-exceptions','NB-platform','NB-emission'}
        assert [c for c in cases if results[c]['candidate']]==['synthetic-all']
        assert len(results['current']['linked'])==22
        assert len(results['current']['observed'])==36
        assert len(results['current']['migrationLinked'])==6
        assert len(results['current']['inventoryLinked'])==4
        assert len(results['current']['bridgeLinked'])==1
    finally:engine.close()


def formal():
    e = load('primitive_projection', 'dev/modeling/tools/'+STEM+'-projection.py')
    cfg = e.SPEC
    qnt = BASE+'models/quint/'+cfg['module']+'.qnt'
    run('qnt-typecheck', ['quint', 'typecheck', qnt, '--out', str(CACHE/'typed-ir.json')])
    ir = json.loads((CACHE/'typed-ir.json').read_text())
    ast, receipt = e.generate(ir)
    astpath = BASE+'models/lean/NativeBindingPlanAst.lean'
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
    proof_names=['NativeBindingPlanAst','NativeBindingPlan','NativeBindingRefinement']
    formal_paths=[qnt,'dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py']+[BASE+'models/lean/'+n+'.lean' for n in proof_names]
    if '--reuse-formal' in sys.argv:
        cp=json.loads((CACHE/'formal-checkpoint.json').read_text())
        assert {f:sha(ROOT/f) for f in formal_paths}==cp['sourceBindings']
        assert all(sha(ROOT/f)==d for f,d in cp['logs'].items())
        lemmas=[[n+'.'+x] for n in proof_names[1:] for x in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
        return [[cfg['module']+'.'+a] for a in cfg['actions']],lemmas
    for name in ['NativeBindingPlanAst','NativeBindingPlan','NativeBindingRefinement']:
        src=ROOT/(BASE+'models/lean/'+name+'.lean')
        assert not re.search(r'\bsorry\b|\baxiom\s',src.read_text())
        target=CACHE/(name+'.lean');target.write_bytes(src.read_bytes())
        run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(target)])
    output=run('qnt-histories',['quint','test',qnt,'--match','Test$'])
    assert output.count('ok ')==13 and output.count('ControlTest passed')==5
    run('qnt-samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','100','--seed','157','--verbosity','1'])
    # A missing close guard must break the actual inductive proof.
    neg=CACHE/'negative-close';neg.mkdir(exist_ok=True)
    bad='\n'.join(line.replace('(q.closed=true)','True') if line.startswith('def issueGuard') else line for line in ast.splitlines())+'\n'
    assert bad!=ast
    (neg/'NativeBindingPlanAst.lean').write_text(bad)
    run('negative-ast',['lean','-o',str(neg/'NativeBindingPlanAst.olean'),str(neg/'NativeBindingPlanAst.lean')])
    try: run('negative-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/NativeBindingPlan.lean'])
    except RuntimeError: assert 'error' in (CACHE/'negative-proof.stdout').read_text()
    else: raise AssertionError('missing close proved')
    lemmas=[[n+'.'+x] for n in ['NativeBindingPlan','NativeBindingRefinement'] for x in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
    save(CACHE/'formal-checkpoint.json',dict(sourceBindings={f:sha(ROOT/f) for f in formal_paths},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and f.stem in proof_names+['qnt-histories','qnt-samples','negative-ast','negative-proof']}))
    return [[cfg['module']+'.'+a] for a in cfg['actions']],lemmas


def main():
    CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    cfg=json.loads((CACHE/'config.json').read_text())
    snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
    for path,v in snapshots.items():assert sha(ROOT/path)==sha(ROOT/v['path'])==v['sha256'],path
    parent=ROOT/'evidence/research/primitive-header-binding/input.json';parentHash=sha(parent)
    prior=json.loads(parent.read_text())
    imported=BASE+'models/lean/PrimitiveBindingAlgebra.lean'
    assert sha(ROOT/imported)==prior['sourceBindings'][imported]
    old=ROOT/'.cache/tasks/primitive-header-binding'
    assert (old/'PrimitiveBindingAlgebra.lean').read_bytes()==(ROOT/imported).read_bytes()
    for ext in ['lean','olean']:shutil.copyfile(old/('PrimitiveBindingAlgebra.'+ext),CACHE/('PrimitiveBindingAlgebra.'+ext))
    adapter=load('binding_native_sysml','dev/modeling/tools/default-lease-admission-study.py')
    for k,v in dict(CACHE=CACHE,OUT=OUT,PKG=PKG,GROUPS=cfg['groups'],SLOTS=cfg['slots']).items():setattr(adapter,k,v)
    adapter.h.CACHE=CACHE;adapter.h.OUT=OUT
    p,scope=adapter.project()
    view=load('binding_views','dev/modeling/tools/copy-producer-envelope-study.py')
    for k,v in dict(ROOT=ROOT,GROUPS=cfg['groups'],MATRIX=BASE+STEM+'-matrix.org',D2=BASE+'diagrams/'+STEM+'.d2').items():setattr(view,k,v)
    view.views(p)
    matrix=ROOT/(BASE+STEM+'-matrix.org')
    matrix.write_text(matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Readonly NativeBindingPlan — Retirement and Net Benefit Matrix').replace('GambitCopyProducerEnvelope',PKG).replace('source-and-C11-open','source-exception-C23-platform-open'))
    d2=ROOT/(BASE+'diagrams/'+STEM+'.d2')
    d2.write_text(d2.read_text().replace('legal-input and C11 OPEN','source / exceptions / C23 qualification OPEN'))
    witnesses=[]
    for v in p['source']:
        snap=snapshots[v['path']];text=(ROOT/snap['path']).read_text();assert v['needle'] in text,v
        witnesses.append(dict(**v,sha256=snap['sha256'],snapshotPath=snap['path'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
    save(CACHE/'source-witnesses.json',witnesses)
    inventory=[];occurrences=[]
    for v in p['inventory']:
        snap=snapshots[v['path']];text=(ROOT/snap['path']).read_text()
        hits=list(re.finditer(v['pattern'],text));assert len(hits)==int(v['count'])
        inventory.append([v['key'],v['path'],str(len(hits)),snap['sha256'],v['scope']])
        definitions=list(re.finditer(r'^\(define (?:\()?([^\s()]+)',text,re.M))
        for hit in hits:
            owners=[d for d in definitions if d.start()<=hit.start()]
            occurrences.append(dict(key=v['key'],path=v['path'],line=text[:hit.start()].count('\n')+1,identifier=hit[0],precedingTopLevelDefinition=owners[-1].group(1) if owners else None))
    save(CACHE/'resource-footprint.json',dict(rows=inventory,occurrences=occurrences,scope='lexical source occurrences, includes definitions; indirect alias closure OPEN'))
    actions,lemmas=formal()
    ascend(p,witnesses,inventory,actions,lemmas,parent)
    d2=BASE+'diagrams/'+STEM+'.d2'
    run('d2-svg',['d2','--layout','elk',d2,d2[:-3]+'.svg'])
    run('d2-png',['d2','--layout','elk',d2,str(CACHE/'diagram.png')])
    org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
    for oldpath,new in [('dev/architecture/toolchain/iter-compiler-service-design.org',BASE+STEM+'-design.org'),('dev/architecture/toolchain/iter-compiler-service-matrix.org',BASE+STEM+'-matrix.org'),('dev/architecture/toolchain/index.org',BASE+'index.org')]:org=org.replace(oldpath,new)
    org=org.replace("(files '","(files '")
    # Include the baseline in the same native Org parse/link check.
    org=org.replace('"'+BASE+STEM+'-design.org"','"'+BASE+STEM+'-design.org" "'+BASE+'language-baseline-design.org"')
    (CACHE/'check-org.el').write_text(org)
    assert sha(parent)==parentHash
    assert not [f for f,v in snapshots.items() if sha(ROOT/f)!=v['sha256']]
    checks=dict(status='conditional-binding-retirement-formal-pass',languageBaseline='C23 / ISO IEC 9899:2024',sourceSnapshots=len(snapshots),sourceAnchors=len(witnesses),lexicalFootprints=len(inventory),qntActions=len(actions),qntHistories=13,negativeHistories=5,qntSamples=500,sampleSeed=157,leanTheorems=len(lemmas),allStepInduction=True,projectionNegativeControls=4,leanNegativeControls=1,ascentScenarios=11,migrationLinks=6,actualCandidate=False,blockers=['NB-source','NB-exceptions','NB-platform','NB-emission'],sourceAliasClosure=False,exceptionPrefixEquivalence=False,c23PlatformQualified=False,fullEmissionFidelity=False,nativeTestsRun=False,performanceTestsRun=False,sourceDrift=[])
    save(CACHE/'checks.json',checks)
    own=[BASE+'models/sysml/'+STEM+'.sysml',BASE+STEM+'-design.org',BASE+STEM+'-matrix.org',BASE+'language-baseline-design.org',BASE+'index.org',d2,d2[:-3]+'.svg',
         BASE+'models/quint/native_binding_plan_retirement.qnt','dev/modeling/ascent/'+STEM+'.rules.scm','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/'+STEM+'-projection.py',imported]
    own += [BASE+'models/lean/'+n+'.lean' for n in ['NativeBindingPlanAst','NativeBindingPlan','NativeBindingRefinement']]
    own += ['dev/modeling/tools/'+n for n in ['advantage-architecture-study.py','default-lease-admission-study.py','copy-producer-envelope-study.py','chunk-capacity-charge-projection.py']]
    own += [v['path'] for v in snapshots.values()]+[str((CACHE/n).relative_to(ROOT)) for n in ['config.json','source-snapshots.json','standards-references.json']]
    save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),branch=run('branch',['git','branch','--show-current']).strip(),parentInputSha256=parentHash,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snapshots,sysmlInputs=scope,logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
    for f in CACHE.iterdir():
        if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
    run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
    bound=json.loads((CACHE/'input.json').read_text());bound['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']};save(CACHE/'input.json',bound)
    for f in CACHE.iterdir():
        if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
    for d in CACHE.glob('retained-*-failure'):shutil.copytree(d,OUT/d.name,dirs_exist_ok=True)
    neg=OUT/'negative-close';neg.mkdir(exist_ok=True);shutil.copyfile(CACHE/'negative-close/NativeBindingPlanAst.lean',neg/'NativeBindingPlanAst.lean')
    save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
    print(json.dumps(checks))


if __name__=='__main__':
    main()
