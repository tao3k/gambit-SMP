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
CACHE = ROOT / '.cache/tasks/future-frame-commit/runtime-tls-ready'
OUT = ROOT / 'evidence/research/future-frame-commit/runtime-tls-ready'
LEAN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
GROUPS = [['source', 25, ['key', 'path', 'needle', 'limit']], ['obligation', 8, ['key', 'status', 'condition']], ['route', 39, ['actionName', 'lemma', 'source', 'obligation']], ['gain', 5, ['key', 'saved', 'added', 'condition', 'status']], ['issuer', 5, ['key', 'source', 'signature', 'gap']], ['consumer', 6, ['key', 'source', 'access', 'lifetime', 'limit']], ['edge', 12, ['fromNode', 'toNode', 'contract']], ['refinement', 8, ['key', 'lemma', 'source', 'premise']], ['writer', 6, ['key', 'source', 'access', 'closure', 'limit']]]

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
    model = BASE/'models/sysml/runtime-tls-ready.sysml'
    qnt = BASE/'models/quint/runtime_tls_ready.qnt'
    ast = BASE/'models/lean/RuntimeTlsReadyAst.lean'
    proof = BASE/'models/lean/RuntimeTlsReady.lean'
    projector = ROOT/'dev/modeling/tools/runtime-tls-ready-projection.py'
    dsl = ROOT/'dev/modeling/ascent/runtime-tls-ready.rules.scm'
    parent = ROOT/'evidence/research/future-frame-commit/cache-ready-publication/input.json'
    stepProofs=[BASE/'models/lean'/(n+'.lean') for n in ['RuntimeTlsReadyInitialization', 'RuntimeTlsReadyBindings', 'RuntimeTlsReadyFinalization']]
    bound = [*stepProofs,model,qnt,ast,proof,projector,dsl,Path(__file__),
             ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py',
             ROOT/'dev/modeling/tools/size-family-hold-balance-study.py']
    bindings = {rel(f):sha(f) for f in bound}
    keys = [(g,i,f,'GambitRuntimeTlsReady::'+g+str(i)+'.'+f)
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
    parent_ast=BASE/'models/lean/CacheReadyPublicationAst.lean'
    assert sha(parent_ast)==previous['sourceBindings'][rel(parent_ast)]
    assert sha(LEAN)==previous['leanBinarySha256']
    bindings[rel(parent_ast)]=sha(parent_ast)
    parent_art=json.loads((parent.parent/'artifacts.json').read_text());reused=[]
    name='CacheReadyPublicationAst';source=BASE/'models/lean'/(name+'.lean');obj=parent.parent/(name+'.olean')
    assert sha(source)==previous['sourceBindings'][rel(source)] and sha(obj)==parent_art[rel(obj)]
    bindings[rel(source)]=sha(source);bindings[rel(obj)]=sha(obj);shutil.copyfile(obj,CACHE/(name+'.olean'))
    reused.append(dict(module=name,sourceSha256=sha(source),objectSha256=sha(obj)))
    save(CACHE/'prior-lean-reuse.json',dict(leanBinarySha256=sha(LEAN),modules=reused,sourceChecked=True,objectManifestChecked=True))
    cpp=ROOT/'evidence/research/source-references/tcl/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclThreadAlloc.c'
    text=cpp.read_text();start=text.index('\nGetCache(void)');end=text.index('\nTclFreeAllocCache(',start);body=text[start:end]
    order=['cachePtr = TclpGetAllocCache();','cachePtr = TclpSysAlloc(sizeof(Cache), 0);','memset(cachePtr, 0, sizeof(Cache));','cachePtr->nextPtr = firstCachePtr;','firstCachePtr = cachePtr;','Tcl_MutexUnlock(listLockPtr);','cachePtr->owner = Tcl_GetCurrentThread();','TclpSetAllocCache(cachePtr);','return cachePtr;']
    positions=[body.index(x) for x in order];assert positions==sorted(positions)
    ds=text[text.index('\nTcl_GetMemoryInfo('):text.index('\nMoveObjs(')]
    assert ds.index('Tcl_MutexLock(listLockPtr);')<ds.index('Tcl_DStringStartSublist(dsPtr);')<ds.index('Tcl_MutexUnlock(listLockPtr);')
    header=(ROOT/'evidence/research/source-references/tcl/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h').read_text()
    assert 'MODULE_SCOPE void\tTclpSetAllocCache(void *);' in header
    save(CACHE/'constructor-diagnostic-source-order.json',dict(sourceSha256=sha(cpp),constructor=[dict(operation=o,line=text.count('\n',0,start+pos)+1) for o,pos in zip(order,positions)],tlsSetterReturnsVoid=True,diagnosticDStringCallsPerCache='B+3',diagnosticScalarsPerBucket=7,platformImplementationQualified=False,nativeExecution=False))
    ledger=OUT/'platform-sources.json';platform=json.loads(ledger.read_text());bindings[rel(ledger)]=sha(ledger)
    assert platform['commit']=='cbf86d62348d6b052e1961b4df995960fb21545f'
    for rec in platform['records']:
        f=ROOT/rec['path'];d=f.read_bytes();e=rec['treeEntry']
        assert sha(f)==rec['sha256'] and len(d)==e['size']
        assert hashlib.sha1(b'blob '+str(len(d)).encode()+b'\0'+d).hexdigest()==e['sha']
        bindings[rel(f)]=sha(f)
    ux=(ROOT/'evidence/research/source-references/tcl/cbf86d62348d6b052e1961b4df995960fb21545f/unix/tclUnixThrd.c').read_text()
    un=['pthread_key_create(&key, NULL);','pthread_setspecific(key, arg);','pthread_setspecific(key, NULL);','pthread_key_delete(key);']
    assert all(any(line.strip()==needle for line in ux.splitlines()) for needle in un)
    free=ux[ux.index('\nTclpFreeAllocCache('):ux.index('\nTclpGetAllocCache(')]
    assert free.index('TclFreeAllocCache(ptr);')<free.index('pthread_setspecific(key, NULL);')
    win=(ROOT/'evidence/research/source-references/tcl/cbf86d62348d6b052e1961b4df995960fb21545f/win/tclWinThrd.c').read_text()
    wfree=win[win.index('\nTclpFreeAllocCache('):win.index('\nTclpThreadCreateKey(')]
    assert wfree.index('TclFreeAllocCache(ptr);')<wfree.index('TlsSetValue(tlsKey, NULL);')
    assert 'Tcl_Panic("TlsSetValue failed from TclpSetAllocCache");' in win
    tlsfast=[line.strip() for line in text.splitlines() if re.search(r'\btcachePtr\s*=',line)]
    assert len(tlsfast)==1 and re.fullmatch(r'tcachePtr\s*=\s*GetCache\(\);\s*\\',tlsfast[0])
    save(CACHE/'platform-operation-witnesses.json',dict(uncheckedUnixSites=un,uncheckedUnixSiteCount=4,unixDestructor='NULL',bothPlatformsFreeBeforeClear=True,windowsCheckedSetter=True,fastAssignmentLines=tlsfast,explicitFastResetSeen=False,loadedBinaryQualified=False))
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
    for name in ['RuntimeTlsReadyAst', 'RuntimeTlsReadyInitialization', 'RuntimeTlsReadyBindings', 'RuntimeTlsReadyFinalization', 'RuntimeTlsReady']:
        source=BASE/'models/lean'/(name+'.lean')
        assert not re.search(r'\bsorry\b|\baxiom\s',source.read_text())
        run('lean-'+name,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(name+'.olean')),str(source)])
    actions=pr.SPEC['actions']
    lemmas=['RuntimeTlsReady.'+n for n in re.findall(r'^theorem (\w+)', '\n'.join(f.read_text() for f in [*stepProofs,proof]),re.M)]
    assert len(p['route'])==len(actions)
    assert {r['actionName'] for r in p['route']}==set(actions)
    assert all(r['lemma'] in lemmas for r in p['route'])
    run('histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953'])
    run('samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
    negatives={'partial-not-ready': (['reserveRuntime', 'initializeLocks'], 'publishRuntimeGuard witness'), 'bootstrap-not-full': (['reserveRuntime', 'initializeLocks', 'bootstrapBorrow'], 'beginCacheInstallGuard witness'), 'unknown-key-no-ready': (['reserveRuntime', 'createAllocKeyUnknown'], 'publishRuntimeGuard witness'), 'raw-return-not-receipt': (['reserveRuntime', 'initializeLocks', 'initializeTables', 'createGenericKey', 'createAllocKeyKnown', 'publishRuntime', 'observeRuntime', 'beginCacheInstall', 'rawSetterReturned'], 'publishCacheGuard witness'), 'unknown-clear-no-free': (['reserveRuntime', 'initializeLocks', 'initializeTables', 'createGenericKey', 'createAllocKeyKnown', 'publishRuntime', 'observeRuntime', 'beginCacheInstall', 'recordKnownInstall', 'publishCache', 'beginGlobalClose', 'closeCache', 'clearTlsUnknown'], 'freeCacheKnownGuard witness'), 'fast-alias-no-free': (['reserveRuntime', 'initializeLocks', 'initializeTables', 'createGenericKey', 'createAllocKeyKnown', 'publishRuntime', 'observeRuntime', 'beginCacheInstall', 'recordKnownInstall', 'publishCache', 'publishFast', 'beginGlobalClose', 'closeCache', 'clearTlsKnown'], 'freeCacheKnownGuard witness'), 'late-work-no-close': (['reserveRuntime', 'initializeLocks', 'initializeTables', 'createGenericKey', 'createAllocKeyKnown', 'publishRuntime', 'observeRuntime', 'beginCacheInstall', 'recordKnownInstall', 'publishCache', 'admitFinalizer', 'beginGlobalClose', 'deriveLateTsdWork'], 'closeCacheGuard witness'), 'unknown-delete-no-provider-free': (['reserveRuntime', 'initializeLocks', 'initializeTables', 'createGenericKey', 'createAllocKeyKnown', 'publishRuntime', 'observeRuntime', 'beginCacheInstall', 'recordKnownInstall', 'publishCache', 'publishFast', 'beginGlobalClose', 'closeCache', 'clearFastKnown', 'clearTlsKnown', 'freeCacheKnown', 'attestRosterClosed', 'deleteGenericKey', 'deleteAllocKeyUnknown'], 'freeGlobalLocksGuard witness')}
    for case,(seq,goal) in negatives.items():
        expr='initial';defs=['initial'];guard_checks=[]
        for a in seq:
            guard_checks.append('example : '+a+'Guard ('+expr+') := by simp ['+','.join([a+'Guard']+defs)+']')
            expr=a+'Next ('+expr+')'; defs.append(a+'Next')
        simp=','.join(['Safe','witness']+defs+[a+'Guard' for a in actions])
        text='import RuntimeTlsReady\nopen RuntimeTlsReadyAst\ndef witness : State := '+expr+'\n'+'\n'.join(guard_checks)+'\nexample : Safe witness := by simp ['+simp+']\nexample : ¬ ('+goal+') := by simp ['+simp+']\n'
        f=CACHE/(case+'-original.lean'); f.write_text(text)
        run(case+'-original',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)])
        f=CACHE/(case+'-negative.lean');f.write_text(text+'example : '+goal+' := by simp ['+simp+']\n')
        result=run(case+'-negative',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)],expected=1)
        assert result.count('error:')==1
    # Forged state controls are distinct from reachable guard counterexamples.
    forged={'ready-without-key':"{initial with g:=2,locks:=1,tables:=1,genericKey:=1}",'freed-with-fast-alias':"{initial with g:=3,locks:=1,tables:=1,genericKey:=1,allocKey:=1,cache:=4,fast:=1,fastEpoch:=1,observed:=1}"}
    for case,state in forged.items():
        txt='import RuntimeTlsReady\nopen RuntimeTlsReadyAst\ndef badState : State := '+state+'\nexample : ¬ Safe badState := by simp [Safe,badState,initial]\n'
        f=CACHE/(case+'-original.lean');f.write_text(txt);run(case+'-original',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)])
        f=CACHE/(case+'-negative.lean');f.write_text(txt+'example : Safe badState := by simp [Safe,badState,initial]\n')
        result=run(case+'-negative',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)],expected=1)
        assert result.count('error:')==1
    def rows(group): return [list(row.values()) for row in p[group]]
    src=[[r['key'],r['path'],r['sha256'],r['needle']] for r in sources]
    results={}; engine=Engine()
    try:
        session=engine.open_sources(dsl.read_text())
        assert session.run(queries=['blocked'])['complete']
        for case in ['current','synthetic-all','stale-source','missing-lemma','wrong-issuer','wrong-route','unix-return-is-success','fast-auto-reset','missing-edge-lemma','wrong-edge-source','comment-is-roster','volatile-is-acquire']:
            seen=copy.deepcopy(src); ls=[[l] for l in lemmas]
            issuers=rows('issuer'); routes=rows('route'); consumers=rows('consumer')
            qualified=rows('obligation'); graphs=rows('refinement'); writers=rows('writer')
            if case=='current': qualified=[r for r in qualified if r[1]!='unresolved']
            if case=='stale-source': seen[0][2]='stale'
            if case=='missing-lemma': ls.remove(['RuntimeTlsReady.publishRuntimePreserves'])
            if case=='wrong-issuer': issuers[0][2]='claim success itself protects all earlier metadata loads'
            if case=='wrong-route': routes[0][1]='RuntimeTlsReady.publishRuntimePreserves'
            if case=='unix-return-is-success': issuers[1][2]='Unix void setter normal return proves installation succeeded'
            if case=='fast-auto-reset': consumers[3][2]='Tcl_FinalizeThread return automatically clears native fast TLS'
            if case=='missing-edge-lemma': ls.remove(['RuntimeTlsReady.runtimeReadyHasServices'])
            if case=='wrong-edge-source': graphs[0][2]='prior'
            if case=='comment-is-roster': issuers[3][2]='all-threads source comment is an all-owner completion receipt'
            if case=='volatile-is-acquire': issuers[4][2]='volatile initialized flag supplies a same-epoch acquire edge'
            session.replace(dict(sourceNeed=src,sourceSeen=seen,obligation=rows('obligation'),qualified=qualified,
                actionName=[[a] for a in actions],lemmaName=ls,routeNeed=rows('route'),routeSeen=routes,
                issuerNeed=rows('issuer'),issuerSeen=issuers,consumerNeed=rows('consumer'),consumerSeen=consumers,graphNeed=rows('refinement'),graphSeen=graphs,writerNeed=rows('writer'),writerSeen=writers))
            result=session.run(queries=['blocked','candidate','routeLinked','issuerLinked','consumerLinked','graphLinked','writerLinked'])
            assert result['complete'];results[case]=result['relations']
    finally: engine.close()
    save(CACHE/'ascent-results.json',dict(results=results,syntheticIsNotNativeEvidence=True))
    assert [k for k,r in results.items() if r['candidate']]==['synthetic-all']
    lines=['#+TITLE: Runtime / TLS — bootstrap, checked status, epoch and shutdown matrix',
           '#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en',
           '#+PROPERTY: header-args :eval never','',
           '* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitRuntimeTlsReady',':END:',
           'Safety-model closure does not certify native caller coverage, C23 execution or performance.']
    for group in ['gain','consumer','issuer','writer','refinement','obligation','route','source']:
        fs=list(p[group][0]); lines += ['','** '+group.capitalize(),'',
            '| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']
        lines += ['| '+' | '.join(str(row[f]).replace('|',' / ') for f in fs)+' |' for row in p[group]]
    matrix=BASE/'runtime-tls-ready-matrix.org';matrix.write_text('\n'.join(lines)+'\n')
    d2=BASE/'diagrams/runtime-tls-ready.d2'
    d2.write_text('direction: down\ntitle: "C23 runtime services, platform TLS and cache epochs"\n'+
        '\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['contract']) for r in p['edge'])+'\n')
    run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
    checks=dict(sourceAnchors=len(sources),fields=len(pr.SPEC['fields']),actions=len(actions),histories=22,
        samples=500,maxSteps=80,seed=953,leanTheorems=len(lemmas),stepInduction=True,
        guardedActualParentJoin=True,fullProductSimulation=False,typedIrNegativeControls=len(controls),
        reachableAdmissionCounterexamples=len(negatives),ascentScenarios=len(results),
        externalReaderClosure=False,domainReaderClosure=False,
        faultRecoveryImplemented=False,normalLandingIsPremise=True,rawRouteClosureIsPremise=True,loadedTclQualified=False,c23Refinement=False,nativeAdmission=False,
        runtimeImplementation=False,nativeTests=False,nativeCompilerOrPreprocessorRun=False,
        performanceTests=False,nativePathsRetired=0,
        deterministicLateGuardControls=10,modelInvariants=50,contractRefinementLemmas=8,forgedStateNegativeControls=2,verifiedPriorLeanModules=len(reused),globalReaderClosure=False,unresolved=[r['key'] for r in p['obligation'] if r['status']=='unresolved'])
    save(OUT/'checks.json',dict(checks,validationComplete=False))
    org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
    org=org.replace('dev/architecture/toolchain/iter-compiler-service-design.org','dev/refactoring/modern-c/runtime-tls-ready-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org','dev/refactoring/modern-c/runtime-tls-ready-matrix.org').replace('dev/architecture/toolchain/index.org','dev/refactoring/modern-c/index.org')
    (CACHE/'check-org.el').write_text(org)
    run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
    for f in [BASE/'runtime-tls-ready-design.org',matrix,BASE/'index.org',BASE/'runtime-blueprint.org',d2,d2.with_suffix('.svg')]:
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
