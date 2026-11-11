#!/usr/bin/env python3
"""Research artifacts only: native SysML -> ASCENT / typed QNT IR -> Lean."""
import copy
import hashlib
import importlib.util
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / 'dev/refactoring/modern-c'
CACHE = ROOT / '.cache/tasks/future-frame-commit/putobjs-move-graph'
OUT = ROOT / 'evidence/research/future-frame-commit/putobjs-move-graph'
LEAN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
GROUPS = [('source', 21, ['key', 'path', 'needle', 'limit']), ('obligation', 7, ['key', 'status', 'condition']), ('route', 28, ['actionName', 'lemma', 'source', 'obligation']), ('gain', 5, ['key', 'saved', 'added', 'condition', 'status']), ('issuer', 4, ['key', 'source', 'signature', 'gap']), ('consumer', 5, ['key', 'source', 'access', 'lifetime', 'limit']), ('edge', 10, ['fromNode', 'toNode', 'contract']), ('refinement', 10, ['key', 'lemma', 'source', 'premise'])]

def module(name, path):
    spec = importlib.util.spec_from_file_location(name,path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def rel(path):
    return str(Path(path).relative_to(ROOT))

def save(path, value):
    Path(path).write_text(json.dumps(value,indent=2)+'\n')

helper = module('process',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py')
helper.CACHE = CACHE
run = helper.run

def main():
    from ascent import Engine
    CACHE.mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    model = BASE/'models/sysml/putobjs-move-graph.sysml'
    qnt = BASE/'models/quint/putobjs_move_graph.qnt'
    ast = BASE/'models/lean/PutObjsMoveGraphAst.lean'
    proof = BASE/'models/lean/PutObjsMoveGraph.lean'
    projector = ROOT/'dev/modeling/tools/putobjs-move-graph-projection.py'
    dsl = ROOT/'dev/modeling/ascent/putobjs-move-graph.rules.scm'
    parent = ROOT/'evidence/research/future-frame-commit/putobjs-custody/input.json'
    stepProofs=[BASE/'models/lean'/(n+'.lean') for n in ['PutObjsMoveGraphStepsA', 'PutObjsMoveGraphStepsB', 'PutObjsMoveGraphStepsC', 'PutObjsMoveGraphStepsD']]
    bound = [*stepProofs,model,qnt,ast,proof,projector,dsl,Path(__file__),
             ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py',
             ROOT/'dev/modeling/tools/size-family-hold-balance-study.py']
    bindings = {rel(f):sha(f) for f in bound}
    keys = [(g,i,f,'GambitPutObjsMoveGraph::'+g+str(i)+'.'+f)
            for g,n,fs in GROUPS for i in range(n) for f in fs]
    command = ['sysml','-strict','-no-record-cache','-validate','-json']
    for *_,expr in keys:
        command += ['-e',expr]
    raw = json.loads(run('sysml',command+[str(model)]))
    assert raw['exit']==0 and not raw.get('errors')
    assert not any(d['severity']=='error' for d in raw.get('diagnostics') or [])
    vals = [json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')]
    assert len(vals)==len(keys)
    projection = {}
    for (g,i,f,_),v in zip(keys,vals,strict=True):
        projection.setdefault(g,{}).setdefault(i,{})[f]=v
    p = {g:list(rows.values()) for g,rows in projection.items()}
    save(CACHE/'sysml-projection.json',p)
    sources = []
    for row in p['source']:
        f=ROOT/row['path']; text=f.read_text()
        assert row['needle'] in text, row
        digest=sha(f); bindings[row['path']]=digest
        (CACHE/('source-'+digest+'.txt')).write_text(text)
        sources.append(dict(**row,sha256=digest,lines=[text.count('\n',0,m.start())+1
            for m in re.finditer(re.escape(row['needle']),text)]))
    save(CACHE/'source-witnesses.json',sources)
    ledger=ROOT/'evidence/research/tcl-source-borrow/pinned-tcl-sources.json'
    pinned=json.loads(ledger.read_text());bindings[rel(ledger)]=sha(ledger)
    assert pinned['commit']=='cbf86d62348d6b052e1961b4df995960fb21545f'
    verified=[]
    for row in pinned['records']:
        f=ROOT/row['capturePath']; data=f.read_bytes()
        assert sha(f)==row['sha256']
        blob=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
        assert blob==row['gitBlobSha1'];bindings[rel(f)]=sha(f)
        verified.append(dict(path=rel(f),sha256=sha(f),gitBlobSha1=blob))
    save(CACHE/'pinned-tcl-verification.json',dict(commit=pinned['commit'],records=verified,loadedBinaryQualified=False))
    meta=ROOT/'evidence/research/future-frame-commit/thread-cache-tail/thread-alloc-source.json'; capture=json.loads(meta.read_text())
    assert capture['requestedCommit']=='cbf86d62348d6b052e1961b4df995960fb21545f'
    f=ROOT/capture['capturePath']; data=f.read_bytes()
    assert sha(f)==capture['sha256'] and len(data)==capture['treeEntry']['size']
    assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==capture['treeEntry']['sha']
    bindings[rel(meta)]=sha(meta);bindings[rel(f)]=sha(f)
    header=(ROOT/'evidence/research/source-references/tcl/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h').read_text()
    assert re.search(r'^#  define ALLOC_NOBJHIGH 1200$',header,re.M)
    assert re.search(r'^#define NOBJALLOC\s+800$',data.decode(),re.M)
    cases=[]
    for n in [0,1,1199,1200]:
        route='direct' if 1<=n<1200 else 'helper'; after=n+1
        moved=800 if route=='helper' and after>1200 else 0
        cases.append(dict(before=n,route=route,after=after-moved,sharedTransfer=moved,keepWalk=after-moved if moved else 0))
    save(CACHE/'source-threshold-arithmetic.json',dict(cases=cases,nativeExecution=False,linkedListShapeIsPremise=True))
    # Local retained paper;
    # No native program execution; immutable missing-source read is recorded separately.
    paper=ROOT/'evidence/research/source-references/feeley-sfp/8bb2fae8ae4b54d3a86206596f90e9cf73da39846af0f39244a476074cf81ed4.txt'
    assert sha(paper)==paper.stem
    bindings[rel(paper)]=sha(paper)
    # Bind the actual previous provider AST; do not substitute a toy provider model.
    previous=json.loads(parent.read_text())
    parent_ast=BASE/'models/lean/PutObjsCustodyAst.lean'
    assert sha(parent_ast)==previous['sourceBindings'][rel(parent_ast)]
    assert sha(LEAN)==previous['leanBinarySha256']
    bindings[rel(parent_ast)]=sha(parent_ast)
    run('typecheck',['quint','typecheck',str(qnt),'--out',str(CACHE/'typed-ir.json')])
    ir=json.loads((CACHE/'typed-ir.json').read_text())
    pr=module('projection',projector); generated,receipt=pr.generate(ir)
    assert ast.read_text()==generated
    controls={}
    for case in ['binding','field','roster','expression']:
        bad=copy.deepcopy(ir)
        ds={d['name']:d for d in bad['modules'][0]['declarations']}
        if case=='binding': bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
        if case=='field': ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
        if case=='roster': ds['step']['expr']['args'].pop(0)
        if case=='expression': ds['safe']['expr']['opcode']='unsupported'
        try: pr.generate(bad)
        except (AssertionError,KeyError): controls[case]='rejected'
        else: raise AssertionError(case)
    save(CACHE/'projection.json',dict(**receipt,controls=controls,irSha256=sha(CACHE/'typed-ir.json')))
    for name in ['PutObjsCustodyAst', 'PutObjsMoveGraphAst', 'PutObjsMoveGraphStepsA', 'PutObjsMoveGraphStepsB', 'PutObjsMoveGraphStepsC', 'PutObjsMoveGraphStepsD', 'PutObjsMoveGraph']:
        source=BASE/'models/lean'/(name+'.lean')
        assert not re.search(r'\bsorry\b|\baxiom\s',source.read_text())
        run('lean-'+name,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(name+'.olean')),str(source)])
    actions=pr.SPEC['actions']
    lemmas=['PutObjsMoveGraph.'+n for n in re.findall(r'^theorem (\w+)', '\n'.join(f.read_text() for f in [*stepProofs,proof]),re.M)]
    assert len(p['route'])==len(actions)
    assert {r['actionName'] for r in p['route']}==set(actions)
    assert all(r['lemma'] in lemmas for r in p['route'])
    run('histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953'])
    run('samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
    negatives={'initial-no-fix': ([], 'fixProducerLastGuard witness'), 'unlocked-no-borrow': (['knownProducerUnlock'], 'borrowOldTailGuard witness'), 'unknown-held-no-consumer': (['unknownStillHeld'], 'acquireConsumerGuard witness'), 'unknown-released-no-fix': (['unknownReleased'], 'fixProducerLastGuard witness'), 'unknown-no-close': (['unknownReleased'], 'closeSourceAdmissionGuard witness'), 'locked-no-detach': (['knownProducerUnlock', 'acquireConsumer', 'selectMove800', 'loadMoveHead', 'creditDestination', 'debitShared'], 'detachSharedHeadGuard witness'), 'no-pop-before-move': (['knownProducerUnlock', 'acquireConsumer'], 'loadPopHeadGuard witness'), 'no-premature-return': (['knownProducerUnlock'], 'returnTailGuard witness')}
    for case,(seq,goal) in negatives.items():
        expr='initial';defs=['initial'];guard_checks=[]
        for a in seq:
            guard_checks.append('example : '+a+'Guard ('+expr+') := by simp ['+','.join([a+'Guard']+defs)+']')
            expr=a+'Next ('+expr+')'; defs.append(a+'Next')
        simp=','.join(['Safe','witness']+defs+[a+'Guard' for a in actions])
        text='import PutObjsMoveGraph\nopen PutObjsMoveGraphAst\ndef witness : State := '+expr+'\n'+'\n'.join(guard_checks)+'\nexample : Safe witness := by simp ['+simp+']\nexample : ¬ ('+goal+') := by simp ['+simp+']\n'
        f=CACHE/(case+'-original.lean'); f.write_text(text)
        run(case+'-original',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)])
        f=CACHE/(case+'-negative.lean');f.write_text(text+'example : '+goal+' := by simp ['+simp+']\n')
        result=run(case+'-negative',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)],expected=1)
        assert result.count('error:')==1
    # Representation negatives: wrong boundary edge and wrong graph header.
    for case in ['wrong-tail-edge','wrong-shared-head']:
        edge='(fun n => if n=1201 then 0 else rawNext initial n)' if case=='wrong-tail-edge' else 'rawNext initial'
        head='402' if case=='wrong-tail-edge' else '0'
        txt='import PutObjsMoveGraph\nopen PutObjsMoveGraphAst PutObjsMoveGraph\ndef badGraph : Graph := ⟨'+edge+','+head+',0,1201⟩\n'
        txt+='example : ¬ Encodes badGraph initial := by\n intro h\n simp only [Encodes] at h\n rcases h with ⟨ha,hb,hrest,hh,hd,hp⟩\n'
        txt+=(' simp [badGraph,initial] at hb\n' if case=='wrong-tail-edge' else ' simp [badGraph,initial] at hh\n')
        f=CACHE/(case+'-original.lean');f.write_text(txt)
        run(case+'-original',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)])
        f=CACHE/(case+'-negative.lean');f.write_text(txt+'example : Encodes badGraph initial := by simp [Encodes,badGraph,initial]\n')
        result=run(case+'-negative',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)],expected=1)
        assert result.count('error:')==1
    def rows(group): return [list(row.values()) for row in p[group]]
    src=[[r['key'],r['path'],r['sha256'],r['needle']] for r in sources]
    results={}; engine=Engine()
    try:
        session=engine.open_sources(dsl.read_text())
        assert session.run(queries=['blocked'])['complete']
        for case in ['current','synthetic-all','stale-source','missing-lemma','wrong-issuer','wrong-route','unlock-is-completion','address-is-identity','missing-edge-lemma','wrong-edge-source']:
            seen=copy.deepcopy(src); ls=[[l] for l in lemmas]
            issuers=rows('issuer'); routes=rows('route'); consumers=rows('consumer')
            qualified=rows('obligation'); graphs=rows('refinement')
            if case=='current': qualified=[r for r in qualified if r[1]!='unresolved']
            if case=='stale-source': seen[0][2]='stale'
            if case=='missing-lemma': ls.remove(['PutObjsMoveGraph.publishReceiptPreserves'])
            if case=='wrong-issuer': issuers[0][2]='claim success itself protects all earlier metadata loads'
            if case=='wrong-route': routes[0][1]='PutObjsMoveGraph.publishReceiptPreserves'
            if case=='unlock-is-completion': issuers[0][2]='shared unlock itself proves local lastPtr and receipt completed'
            if case=='address-is-identity': consumers[4][2]='same raw address authorizes prior incarnation receipt'
            if case=='missing-edge-lemma': ls.remove(['PutObjsMoveGraph.physicalWalk'])
            if case=='wrong-edge-source': graphs[0][2]='prior'
            session.replace(dict(sourceNeed=src,sourceSeen=seen,obligation=rows('obligation'),qualified=qualified,
                actionName=[[a] for a in actions],lemmaName=ls,routeNeed=rows('route'),routeSeen=routes,
                issuerNeed=rows('issuer'),issuerSeen=issuers,consumerNeed=rows('consumer'),consumerSeen=consumers,graphNeed=rows('refinement'),graphSeen=graphs))
            result=session.run(queries=['blocked','candidate','routeLinked','issuerLinked','consumerLinked','graphLinked'])
            assert result['complete'];results[case]=result['relations']
    finally: engine.close()
    save(CACHE/'ascent-results.json',dict(results=results,syntheticIsNotNativeEvidence=True))
    assert [k for k,r in results.items() if r['candidate']]==['synthetic-all']
    lines=['#+TITLE: PutObjs / MoveObjs — pointer graph, source lease and retirement matrix',
           '#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en',
           '#+PROPERTY: header-args :eval never','',
           '* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitPutObjsMoveGraph',':END:',
           'Safety-model closure does not certify native caller coverage, C23 execution or performance.']
    for group in ['gain','consumer','issuer','refinement','obligation','route','source']:
        fs=list(p[group][0]); lines += ['','** '+group.capitalize(),'',
            '| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']
        lines += ['| '+' | '.join(str(row[f]).replace('|',' / ') for f in fs)+' |' for row in p[group]]
    matrix=BASE/'putobjs-move-graph-matrix.org';matrix.write_text('\n'.join(lines)+'\n')
    d2=BASE/'diagrams/putobjs-move-graph.d2'
    d2.write_text('direction: down\ntitle: "C23 PutObjs / MoveObjs graph and opaque tail"\n'+
        '\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['contract']) for r in p['edge'])+'\n')
    run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
    checks=dict(sourceAnchors=len(sources),fields=len(pr.SPEC['fields']),actions=len(actions),histories=11,
        samples=500,maxSteps=80,seed=953,leanTheorems=len(lemmas),stepInduction=True,
        guardedActualParentJoin=True,fullProductSimulation=False,typedIrNegativeControls=len(controls),
        reachableAdmissionCounterexamples=len(negatives),ascentScenarios=len(results),
        externalReaderClosure=False,domainReaderClosure=False,
        faultRecoveryImplemented=False,normalLandingIsPremise=True,rawRouteClosureIsPremise=True,loadedTclQualified=False,c23Refinement=False,nativeAdmission=False,
        runtimeImplementation=False,nativeTests=False,nativeCompilerOrPreprocessorRun=False,
        performanceTests=False,nativePathsRetired=0,
        deterministicLateGuardControls=5,moveLoopLinks=799,moveTailLinkReads=1,allocationReturns=800,selectedTotalNextLinkReads=2001,modelInvariants=73,graphRefinementLemmas=10,graphRepresentationNegativeControls=2,unresolved=[r['key'] for r in p['obligation'] if r['status']=='unresolved'])
    save(OUT/'checks.json',dict(checks,validationComplete=False))
    org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
    org=org.replace('dev/architecture/toolchain/iter-compiler-service-design.org','dev/refactoring/modern-c/putobjs-move-graph-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org','dev/refactoring/modern-c/putobjs-move-graph-matrix.org').replace('dev/architecture/toolchain/index.org','dev/refactoring/modern-c/index.org')
    (CACHE/'check-org.el').write_text(org)
    run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
    for f in [BASE/'putobjs-move-graph-design.org',matrix,BASE/'index.org',BASE/'runtime-blueprint.org',d2,d2.with_suffix('.svg')]:
        bindings[rel(f)]=sha(f)
    assert all(sha(ROOT/f)==h for f,h in bindings.items())
    save(CACHE/'input.json',dict(sourceBindings=bindings,leanBinarySha256=sha(LEAN),parentInputSha256=sha(parent),runtimeClaim=False))
    checks['validationComplete']=True;save(CACHE/'checks.json',checks)
    for f in CACHE.rglob('*'):
        if f.is_file():
            target=OUT/f.relative_to(CACHE);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,target)
    save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
    print(json.dumps(checks,indent=2))

if __name__=='__main__':
    main()
