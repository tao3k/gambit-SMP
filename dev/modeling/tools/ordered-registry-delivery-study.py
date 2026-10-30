#!/usr/bin/env python3
"""Native-model research orchestration; no compiler/runtime implementation."""
import hashlib
import json
import subprocess
import textwrap
from pathlib import Path
from ascent import Engine
from gambit_smp import repository_clues
ROOT=Path(__file__).resolve().parents[3]
STEM='ordered-registry-delivery'
PACKAGE='OrderedRegistryDelivery'
CACHE=ROOT/'.cache/tasks'/STEM
EVIDENCE=ROOT/'evidence/research'/STEM
MODEL=f'dev/architecture/toolchain/models/sysml/{STEM}.sysml'
DESIGN=f'dev/architecture/toolchain/{STEM}-design.org'
MATRIX=f'dev/architecture/toolchain/{STEM}-matrix.org'
DIAGRAM=f'dev/architecture/toolchain/diagrams/{STEM}.d2'
RULES=f'dev/modeling/ascent/{STEM}.rules.scm'
QNT='models/build/ordered_registry_delivery.qnt'
LEAN='models/build/OrderedRegistryDelivery.lean'
PARAM='models/build/ordered_delivery_parameters.qnt'
GROUPS=[('caller',5,'key anchor condition'),('delivery',5,'key anchor condition'),('route',5,'key anchor qntAction leanLemma condition'),('gain',3,'key avoided added condition'),('refinement',4,'key qntScope leanScope sourceDuty'),('gate',7,'key qualified condition')]

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):Path(p).write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n')
def run(name,argv):
    p=subprocess.run(argv,cwd=ROOT,text=True,capture_output=True,timeout=60)
    (CACHE/(name+'.stdout')).write_text(p.stdout);(CACHE/(name+'.stderr')).write_text(p.stderr)
    save(CACHE/(name+'.command.json'),argv)
    if p.returncode:
        failure=dict(argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr)
        save(CACHE/(name+'.failure-'+hashlib.sha256(json.dumps(failure,sort_keys=True).encode()).hexdigest()[:16]+'.json'),failure)
        raise RuntimeError(name+' failed; retained diagnostics in '+str(CACHE))
    return p.stdout

def project():
    keys=[]
    for group,count,schema in GROUPS:
        keys += [(group,str(i),f,f'{PACKAGE}::{group}{i}.{f}') for i in range(count) for f in schema.split()]
    for key in ['workspaceCount','actualAdmitted']: keys.append(('scalar','',key,f'{PACKAGE}::{key}'))
    for slot in ['history','induction','source','platform']:
        keys += [('need',slot,f,f'{PACKAGE}::{slot}.{f}') for f in ['obligationId','kind','subjectPath','subjectScope','owner.componentId']]
    for i in range(4):
        keys += [('dependency',str(i),f,f'{PACKAGE}::dependency{i}.{f}') for f in ['dependent.obligationId','prerequisite.obligationId']]
    argv=['sysml','-strict','-no-record-cache','-validate','-json']
    for _,_,_,expr in keys:argv+=['-e',expr]
    native=json.loads(run('sysml',argv+['dev']))
    assert native['exit']==0 and not native.get('errors') and not any(d['severity']=='error' for d in native.get('diagnostics',[]))
    vals=[json.loads(line[4:]) for line in native['output'] if line.startswith('  = ')]
    assert len(vals)==len(keys)
    p={}
    for (group,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(group,{}).setdefault(i,{})[f]=v
    for group,_,_ in GROUPS:p[group]=list(p[group].values())
    save(CACHE/'native-queries.json',keys);save(CACHE/'projection.json',p)
    return p,native

def views(p):
    (ROOT/PARAM).write_text('// Native SysML projection.\nmodule ordered_delivery_parameters {\n pure val WorkspaceCount = '+str(p['scalar']['']['workspaceCount'])+'\n}\n')
    lines=['#+TITLE: Ordered Registry Effects, Retry and Semantic Activation Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+PROPERTY: header-args :eval never','',
      '* RESEARCH Canonical native SysML projection',':PROPERTIES:',':CUSTOM_ID: ordered-registry-delivery-matrix',':AUTHORITY: OrderedRegistryDelivery',':STATUS: conditional-models-source-open',':END:','',
      'Local formal checks are separate from host registration and native/source qualification.']
    graph=['direction: down']
    for group,field in [('caller','condition'),('delivery','condition'),('gain','condition')]:
        graph += [group+': '+json.dumps(group.capitalize()+' / native SysML')+' {',' grid-columns: 2']
        graph += [' n'+str(i)+': '+json.dumps(v['key']+'\n'+textwrap.fill(v[field],54)) for i,v in enumerate(p[group])]
        graph+=['}']
    graph+=['proof: "OD-H/I/S/E -> local ASCENT -> QNT / Lean; source and native gates OPEN"',
      'caller -> delivery','delivery -> proof','proof -> gain']
    (ROOT/DIAGRAM).write_text('\n'.join(graph)+'\n')
    for group,_,schema in GROUPS:
        fs=schema.split();lines+=['','** '+group.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']
        lines += ['| '+' | '.join(str(v[f]) for f in fs)+' |' for v in p[group]]
    (ROOT/MATRIX).write_text('\n'.join(lines)+'\n')

def ascent(p):
    needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
    deps=[[v['dependent.obligationId'],v['prerequisite.obligationId']] for v in p['dependency'].values()]
    results={};native=Engine()
    try:
        session=native.open_sources((ROOT/RULES).read_text());queries=['checked','missing','route','blocked','candidate','aligned']
        assert session.run(queries=queries)['complete']
        for case in ['current','missing-qnt','stale-subject','wrong-scope','synthetic-all','unqualified-chain','missing-source-anchor','missing-model-step']:
            all_checked=case in {'synthetic-all','unqualified-chain','missing-source-anchor','missing-model-step'}
            receipts=[[case,n,path,digest,scope] for n,kind,path,digest,scope in needs if all_checked or kind in {'interleaving','induction'}]
            if case=='missing-qnt':receipts=[x for x in receipts if x[1]!='OD-H']
            if case=='stale-subject':receipts=[x[:3]+['stale']+x[4:] if x[1]=='OD-H' else x for x in receipts]
            if case=='wrong-scope':receipts=[x[:4]+['wrong'] if x[1]=='OD-I' else x for x in receipts]
            gates=[[case,v['key'],str(all_checked and not(case=='unqualified-chain' and v['key']=='atomic-owner')).lower()] for v in p['gate']]
            inputs=dict(scenario=[[case]],need=needs,method=[['interleaving','quint'],['induction','lean'],['source-refinement','source-audit'],['environment-refinement','platform']],
              receipt=receipts,dependency=deps,external=[[case,'SC-S',str(all_checked).lower()]],gate=gates,anchor=[[v['key'],v['anchor']] for v in p['route'] if not(case=='missing-source-anchor' and v['key']=='deduplicated-delivery')],
              binding=[[v['key'],v['qntAction'],v['leanLemma'],v['anchor']] for v in p['route']],
              modelstep=[[v['qntAction'],v['leanLemma']] for v in p['route'] if not(case=='missing-model-step' and v['key']=='parse-boundary')])
            session.replace(inputs);v=session.run(queries=queries);assert v['complete'];results[case]=v['relations']
        assert len(results['current']['aligned'])==5
        assert len(results['missing-source-anchor']['aligned'])==4
        assert len(results['missing-model-step']['aligned'])==4
        assert len(results['current']['checked'])==2 and len(results['current']['missing'])==2 and len(results['current']['route'])==4
        for case in ['missing-qnt','stale-subject','wrong-scope']:assert len(results[case]['checked'])==1
        assert len(results['synthetic-all']['candidate'])==1
        assert all(not v['candidate'] for k,v in results.items() if k!='synthetic-all')
    finally:native.close()
    save(CACHE/'ascent-model-results.json',dict(results=results,hostAttested=False,repositoryRegistered=False))

def main():
    CACHE.mkdir(parents=True,exist_ok=True);EVIDENCE.mkdir(parents=True,exist_ok=True)
    p,native=project();views(p)
    sources=['vendor/gambit/gsc/'+v for v in ['_back.scm','_gvm.scm','_prims.scm','_t-c-1.scm','_t-c-2.scm','_front.scm','_env.scm','_ptree1.scm','_ptree2.scm']]
    sources += ['../gerbil-gambit-bootstrap-audit/src/'+v for v in ['gerbil/compiler/base.ss','gerbil/compiler/driver.ss','gerbil/compiler/compile.ss','std/iter/macros.ss','std/iter/api.ss','std/iter.ss','std/string/misc.ss','std/sync/wg.ss']]
    sources += ['vendor/gambit/gsc/_host.scm','vendor/gambit/gsc/_utils.scm',
      '../gerbil-gambit-bootstrap-audit/src/gerbil/expander/core.ss']
    checks=[('vendor/gambit/gsc/_ptree1.scm','(cons (macro-expand source env) (cdr exprs))'),
      ('vendor/gambit/gsc/_ptree1.scm','(add-macro source env)'),
      ('vendor/gambit/gsc/_ptree1.scm','(cons (macro-expand (car exprs) env)'),
      ('vendor/gambit/gsc/_ptree1.scm','(add-macro (car exprs) env)'),
      ('vendor/gambit/gsc/_ptree1.scm','(add-declarations (car exprs) env)'),
      ('vendor/gambit/gsc/_ptree1.scm','(pt (macro-expand source env) env use)'),
      ('vendor/gambit/gsc/_ptree1.scm','(env-decl-set env save)'),
      ('vendor/gambit/gsc/_ptree1.scm','(scheme-global-eval (source->expression proc)'),
      ('vendor/gambit/gsc/_env.scm','(set! namable-declarations (cons (cons name type) namable-declarations))'),
      ('vendor/gambit/gsc/_utils.scm','(set! throw-to-exception-handler old-exception-handler)'),
      ('vendor/gambit/gsc/_utils.scm','(throw-to-exception-handler #f)'),
      ('../gerbil-gambit-bootstrap-audit/src/gerbil/expander/core.ss','(let (mark (make-expander-mark #f ctx phi stx))'),
      ('../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss','(compile-top-module (with-driver-mutex (import-module srcpath)))')]
    census={}
    for name,pattern,scope in [
      ('gambit-callers',r'macro-expand|add-macro|add-declarations|throw-to-exception-handler','vendor/gambit/gsc/_ptree1.scm'),
      ('gerbil-callers',r'core-apply-expander|core-apply-user-macro|apply-macro-expander|make-expander-mark','../gerbil-gambit-bootstrap-audit/src/gerbil/expander/core.ss')]:
        out=run(name,['rg','--json',pattern,scope])
        matches=[json.loads(line)['data'] for line in out.splitlines() if json.loads(line)['type']=='match']
        save(CACHE/(name+'-census.json'),dict(matches=matches,scope=scope,closure='syntactic call families; not proof of actual registry effects in iter'))
        census[name]=len(matches)
    for path,frag in checks:assert frag in (ROOT/path).read_text(),(path,frag)
    q=(ROOT/QNT).read_text();l=(ROOT/LEAN).read_text()
    for v in p['route']:
        assert 'action '+v['qntAction']+'=' in q
        assert 'theorem '+v['leanLemma']+' ' in l
    for v in p['refinement']:
        assert all('action '+n+'(' in q or 'action '+n+'=' in q for n in v['qntScope'].split(';'))
        assert all('theorem '+n+' ' in l for n in v['leanScope'].split(';'))
    save(CACHE/'source-census.json',dict(counts=census,checks=checks,files={s:sha(ROOT/s) for s in sources},aliasClosure='open',nativeTests=False))
    tests=run('quint-tests',['quint','test',QNT,'--match','Test$']);assert tests.count('ok ')==20 and tests.count('ControlTest passed')==8
    run('quint-samples',['quint','run',QNT,'--init','init','--invariant','safe','--max-samples','100','--max-steps','80','--seed','17','--verbosity','1'])
    run('quint-other',['quint','run',QNT,'--init','initOther','--invariant','safe','--max-samples','100','--max-steps','80','--seed','17','--verbosity','1'])
    run('lean',['lean',LEAN]);ascent(p)
    run('d2-svg',['d2',DIAGRAM,DIAGRAM[:-3]+'.svg']);run('d2-png',['d2',DIAGRAM,str(CACHE/'diagram.png')])
    org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('iter-compiler-service-design.org',STEM+'-design.org').replace('iter-compiler-service-matrix.org',STEM+'-matrix.org')
    save(EVIDENCE/'checks.json',dict(status='pending-local-checks',runtimeAdmitted=False))
    (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
    parent=ROOT/'evidence/research/stable-copy-publication/input.json'
    bindings=json.loads(parent.read_text())['sourceBindings']
    assert all(sha(ROOT/path)==h for path,h in bindings.items()),'Parent drift'
    artifacts=[MODEL,DESIGN,MATRIX,DIAGRAM,RULES,QNT,LEAN,PARAM,'dev/modeling/tools/'+STEM+'-study.py']
    for path in artifacts+sources:bindings[path]=sha(ROOT/path)
    save(CACHE/'input.json',dict(sourceBindings=bindings,parentLocalInputSha256=sha(parent),parentHostRegistered=False,
      sysmlSha256=sha(CACHE/'sysml.stdout'),logs={str(path.relative_to(ROOT)):sha(path) for path in CACHE.iterdir() if path.suffix in {'.stdout','.stderr'}}))
    checks=dict(status='conditional-local-models-pass',qntHistories=20,negativeControls=8,sampledRuns=200,maxSteps=80,leanBoundaryLemmas=8,
      ascentLocalScenarios=8,gatesOpen=7,aliasClosure='open',sourceRefinement='open',hostRegistration='unresolved inherited attestation failure; not retried',runtimeAdmitted=False,nativeTestsRun=False,performanceTestsRun=False)
    save(CACHE/'checks.json',checks)
    for path in CACHE.iterdir():
        if path.is_file() and path.suffix not in {'.png','.stdout','.stderr','.txt','.log'}:(EVIDENCE/path.name).write_bytes(path.read_bytes())
    save(EVIDENCE/'artifacts.json',{str(p.relative_to(ROOT)):sha(p) for p in EVIDENCE.iterdir() if p.is_file() and p.name!='artifacts.json'})
    print(json.dumps(checks))
if __name__=='__main__':main()
