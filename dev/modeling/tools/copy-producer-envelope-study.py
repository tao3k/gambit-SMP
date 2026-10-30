#!/usr/bin/env python3
"""Source/formal research only; no native Gambit execution or runtime mutation."""
import copy
import importlib.util
import json
import re
import shutil
import sys
import textwrap
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
STEM='copy-producer-envelope';BASE='dev/refactoring/modern-c/'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml'
DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org'
D2=BASE+'diagrams/'+STEM+'.d2';RULES='dev/modeling/ascent/'+STEM+'.rules.scm'
EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
GROUPS=[['source', 32, 'key path needle obligation'], ['inventory', 4, 'key path pattern count scope'], ['claim', 5, 'key mechanism condition result gap'], ['memory', 5, 'key publication consumer gap'], ['gain', 5, 'key avoided added condition'], ['contract', 12, 'fromNode toNode custody'], ['binding', 15, 'actionName lemma scope'], ['proof', 22, 'key lemma']]
SLOTS=['history','induction','composition','projection','source','platform']

def load(name,path):
    s=importlib.util.spec_from_file_location(name,ROOT/path)
    m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m

h=load('restore_research_helper','dev/modeling/tools/advantage-architecture-study.py')
h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha

def project():
    # The preceding native SysML query adapter preserves independent model failures.
    p=load('restore_native_queries','dev/modeling/tools/default-lease-admission-study.py')
    for k,v in dict(CACHE=CACHE,OUT=OUT,PKG='GambitCopyProducerEnvelope',GROUPS=GROUPS,SLOTS=SLOTS).items():setattr(p,k,v)
    p.h.CACHE=CACHE;p.h.OUT=OUT
    return p.project()

def views(p):
    lines=['#+TITLE: Copy Producer Envelope — FrameSpec and Source Budget Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitCopyProducerEnvelope',':STATUS: conditional-model; source-and-C11-open',':END:']
    for g,_,schema in GROUPS:
        fs=schema.split();lines+=['','** '+g.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']
        lines+=['| '+' | '.join(str(v[f]).replace('|',r'\vert{}').replace('\n',r'\n') for f in fs)+' |' for v in p[g]]
    lines+=['','** Model routing','','| ID | kind | path | scope |','|---+---+---+---|']
    lines+=['| '+' | '.join(v[f] for f in ['obligationId','kind','subjectPath','subjectScope'])+' |' for v in p['need'].values()]
    (ROOT/MATRIX).write_text('\n'.join(lines)+'\n')
    graph=['direction: down']
    for n in sorted({v[f] for v in p['contract'] for f in ['fromNode','toNode']}):graph+=[json.dumps(n)+': '+json.dumps(n)]
    graph += [json.dumps(v['fromNode'])+' -> '+json.dumps(v['toNode'])+': '+json.dumps(textwrap.fill(v['custody'],27)) for v in p['contract']]
    graph+=['proof: '+json.dumps('SysML -> ASCENT -> actual QNT / Lean\nConditional model; legal-input and C11 OPEN')]
    (ROOT/D2).write_text('\n'.join(graph)+'\n')

def formals():
    e=load('restore_projection',EMITTER);cfg=e.SPEC
    ir=json.loads((CACHE/'copy_producer_envelope.json').read_text());ast,receipt=e.generate(ir)
    assert ast==(ROOT/(BASE+'models/lean/ProducerEnvelopeAst.lean')).read_text()
    save(CACHE/'projection-receipt.json',dict(**receipt,typedIrSha256=sha(CACHE/'copy_producer_envelope.json'),astSha256=sha(ROOT/(BASE+'models/lean/ProducerEnvelopeAst.lean'))))
    controls={}
    for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression']:
        bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
        if case=='wrong-state-binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
        if case=='wrong-field-kind':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
        if case=='missing-step':ds['step']['expr']['args'].pop(0)
        if case=='unsupported-expression':ds['safe']['expr']['opcode']='unsupported'
        try:e.generate(bad)
        except (AssertionError,KeyError):controls[case]='rejected'
        else:raise AssertionError(case)
    save(CACHE/'projection-controls.json',controls)
    if '--reuse-formal' in sys.argv:
        cp=json.loads((CACHE/'formal-checkpoint.json').read_text())
        for f,d in cp['sourceBindings'].items():assert sha(ROOT/f)==d,f
        for f,d in cp['logs'].items():assert sha(ROOT/f)==d,f
        actions=[['copy_producer_envelope.'+a] for a in cfg['actions']]
        lemmas=[[n+'.'+v] for n in ['ProducerEnvelope','ProducerCapacity'] for v in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
        return actions,lemmas
    parent=json.loads((ROOT/'evidence/research/dedicated-copy-capacity/input.json').read_text())
    names=['ProducerEnvelopeAst','ProducerEnvelope','ProducerCapacity']
    for n in ['DedicatedCopyAst','DedicatedCopy','ContinuationRestoreAst','ContinuationRestore','CapacityCollectiveAst','CapacityCollective','CopyCapacityComposition']:
        f=BASE+'models/lean/'+n+'.lean';assert sha(ROOT/f)==parent['sourceBindings'][f]
        assert (CACHE/(n+'.lean')).read_bytes()==(ROOT/f).read_bytes() and (CACHE/(n+'.olean')).is_file()
    for n in names:
        orig=ROOT/(BASE+'models/lean/'+n+'.lean');f=CACHE/(n+'.lean')
        assert not re.search(r'\bsorry\b|\baxiom\s',orig.read_text())
        if n.startswith(('CapacityCollective','ContinuationRestore')):assert sha(orig)==parent['sourceBindings'][str(orig.relative_to(ROOT))]
        if '--reuse-compiled' in sys.argv:
            assert f.read_bytes()==orig.read_bytes() and (CACHE/(n+'.olean')).is_file() and 'error:' not in (CACHE/(n+'.stdout')).read_text(),n
        else:
            f.write_bytes(orig.read_bytes());run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(f)])
    test=run('planner-histories',['quint','test',BASE+'models/quint/copy_producer_envelope.qnt','--match','Test$'])
    assert test.count('ok ')==13 and test.count('ControlTest passed')==5
    run('planner-samples',['quint','run',BASE+'models/quint/copy_producer_envelope.qnt','--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','103','--verbosity','1'])
    neg=CACHE/'negative-share';neg.mkdir(exist_ok=True)
    bad='\n'.join(l.replace('(q.cap≥q.objectMax)','True') if l.startswith('def issueGuard') else l for l in ast.splitlines())+'\n';assert bad!=ast
    f=neg/'ProducerEnvelopeAst.lean';f.write_text(bad);run('negative-share-ast',['lean','-o',str(neg/'ProducerEnvelopeAst.olean'),str(f)])
    try:run('negative-share-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/ProducerEnvelope.lean'])
    except RuntimeError:assert 'error:' in (CACHE/'negative-share-proof.stdout').read_text()
    else:raise AssertionError('mutant proved')
    neg=CACHE/'negative-publication';neg.mkdir(exist_ok=True)
    orig=(ROOT/(BASE+'models/lean/ProducerCapacity.lean')).read_text()
    bad=orig.replace('internalFs fs 5+2≤16395','internalFs fs 5+2≤8194');assert bad!=orig
    f=neg/'ProducerCapacity.lean';f.write_text(bad)
    try:run('negative-publication-proof',['env','LEAN_PATH='+str(CACHE),'lean',str(f)])
    except RuntimeError:assert re.search(r'\berror(?:\([^)]*\))?:',(CACHE/'negative-publication-proof.stdout').read_text())
    else:raise AssertionError('bad gate proved')
    actions=[['copy_producer_envelope.'+a] for a in cfg['actions']]
    lemmas=[[n+'.'+v] for n in ['ProducerEnvelope','ProducerCapacity'] for v in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
    return actions,lemmas

def ascend(p,w,actions,lemmas,inventory):
    needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
    bindings=[[v['actionName'],v['lemma']] for v in p['binding']];proofs=[[v['key'],v['lemma']] for v in p['proof']]
    witnesses=[[v['key'],v['path'],v['sha256'],v['needle']] for v in w]
    cases=['current','synthetic-all','stale-hash','wrong-scope','missing-action','missing-geometry','missing-source','missing-platform','missing-witness','wrong-packing-digest','wrong-inventory-count','missing-inventory']
    parentPath='evidence/research/dedicated-copy-capacity/input.json'
    bridges=[['prior-collective',parentPath,sha(ROOT/parentPath),'ProducerCapacity.packingHandoff']]
    engine=h.Engine();results={}
    try:
        session=engine.open_sources((ROOT/RULES).read_text())
        assert session.run(queries=['blocked'])['complete']
        for case in cases:
            receipts=[[case,n,f,d,s] for n,k,f,d,s in needs if case!='current' or k in ['induction','interleaving','restricted-projection']]
            if case=='stale-hash':receipts[0][3]='stale'
            if case=='wrong-scope':receipts[0][4]='native-pass'
            if case in ['missing-source','missing-platform']:receipts=[r for r in receipts if r[1]!='PE-'+case.removeprefix('missing-')]
            observedInventory=copy.deepcopy(inventory)
            if case=='wrong-inventory-count':observedInventory[0][2]='999'
            if case=='missing-inventory':observedInventory=observedInventory[1:]
            observedBridge=copy.deepcopy(bridges)
            if case=='wrong-packing-digest':observedBridge[0][2]='stale'
            session.replace(dict(scenario=[[case]],need=needs,receipt=receipts,binding=bindings,actionName=[a for a in actions if case!='missing-action' or a!=['copy_producer_envelope.issue']],lemmaName=[v for v in lemmas if case!='missing-geometry' or v!=['ProducerCapacity.defaultInternalCap']],witness=witnesses,observation=witnesses[1:] if case=='missing-witness' else witnesses,compositionNeed=proofs,refinementNeed=[],targetActionName=[],bridgeNeed=bridges,bridgeObservation=observedBridge,inventoryNeed=inventory,inventoryObservation=observedInventory))
            result=session.run(queries=['checked','blocked','candidate','linked','compositionLinked','observed','bridgeLinked','inventoryLinked']);assert result['complete'];results[case]=result['relations']
        assert {r[1] for r in results['current']['blocked']}=={'PE-source','PE-platform'}
        assert [len(results['current'][k]) for k in ['linked','compositionLinked','observed','bridgeLinked']]==[15,22,32,1]
        assert len(results['current']['inventoryLinked'])==4
        assert [c for c in cases if results[c]['candidate']]==['synthetic-all']
    finally:engine.close()
    save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))

def main():
    CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    parent=ROOT/'evidence/research/dedicated-copy-capacity/input.json';parentHash=sha(parent)
    snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
    for v in snapshots.values():assert sha(ROOT/v['path'])==v['sha256']
    p,scope=project();views(p)
    w=[]
    for v in p['source']:
        s=snapshots[v['path']];t=(ROOT/s['path']).read_text();assert v['needle'] in t,v['key']
        w.append(dict(**v,snapshotPath=s['path'],sha256=s['sha256'],lines=[t[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),t)]))
    save(CACHE/'source-witnesses.json',w);save(OUT/'source-witnesses.json',w)
    inventory=[]
    for v in p['inventory']:
        sv=snapshots[v['path']];text=(ROOT/sv['path']).read_text();hits=list(re.finditer(v['pattern'],text,re.M));assert len(hits)==int(v['count']),v
        inventory.append([v['key'],v['path'],str(len(hits)),sv['sha256'],v['scope']])
    save(CACHE/'producer-inventory.json',inventory);save(OUT/'producer-inventory.json',inventory)
    actions,lemmas=formals();ascend(p,w,actions,lemmas,inventory)
    run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
    org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org',DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org',MATRIX).replace('dev/architecture/toolchain/index.org',BASE+'index.org')
    org=org.replace('(missing nil))','(missing nil) (external-missing nil))')
    org=org.replace('(unless (file-exists-p target) (push (list file target) missing))','(unless (file-exists-p target) (if (and (string-suffix-p "/index.org" file) (not (string-match-p "copy[-_]producer[-_]envelope\\\\|ProducerEnvelope\\\\|RestoreAdmission" target))) (push (list file target) external-missing) (push (list file target) missing)))')
    org=org.replace('missing=%S; no Babel executed" (length files) links missing','missing=%S; concurrent-index-missing=%S; no Babel executed" (length files) links missing external-missing')
    (CACHE/'check-org.el').write_text(org)
    assert sha(parent)==parentHash
    checks=dict(status='conditional-copy-producer-envelope-model-pass',sourceAnchors=len(w),qntModels=1,qntActions=len(actions),qntHistories=13,negativeHistories=5,samples=500,leanTheorems=len(lemmas),allStepInduction=True,conditionalPackingHandoff=True,projectionControls=4,negativeLeanControls=2,ascentScenarios=12,actualCandidate=False,localFrameArithmeticProved=True,sourceChargeInjection=False,grantCapQualified=False,producerClosureComplete=False,metadataImmutabilityQualified=False,legalSchemeFallbackTotal=False,nativeC11Refinement=False,globalCopyCapacityProved=False,nativeTestsRun=False,performanceTestsRun=False,liveSourceDrift=[f for f,v in snapshots.items() if sha(ROOT/f)!=v['sha256']],sysmlScopeDrift=[f for f,d in scope.items() if sha(ROOT/f)!=d])
    save(CACHE/'checks.json',checks)
    files={MODEL,DESIGN,MATRIX,D2,D2[:-3]+'.svg',RULES,EMITTER,BASE+'index.org','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/default-lease-admission-study.py','dev/modeling/tools/advantage-architecture-study.py','dev/modeling/tools/chunk-capacity-charge-projection.py',BASE+'models/quint/copy_producer_envelope.qnt'}|{BASE+'models/lean/'+n+'.lean' for n in ['ProducerEnvelopeAst','ProducerEnvelope','ProducerCapacity','DedicatedCopyAst','DedicatedCopy','CopyCapacityComposition','ContinuationRestoreAst','ContinuationRestore','CapacityCollectiveAst','CapacityCollective']}|{v['path'] for v in snapshots.values()}
    save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentHash,sourceBindings={f:sha(ROOT/f) for f in sorted(files)},sourceSnapshots=snapshots,logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
    for name in ['checks.json','input.json']:shutil.copyfile(CACHE/name,OUT/name)
    run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
    identity=json.loads((CACHE/'input.json').read_text())
    identity['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}
    save(CACHE/'input.json',identity)
    for f in CACHE.iterdir():
        if f.is_file() and f.suffix in ['.json','.el','.lean']:shutil.copyfile(f,OUT/f.name)
    save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name not in ['artifacts.json','final-audit.json']})
    print(json.dumps(checks))

if __name__=='__main__':main()
