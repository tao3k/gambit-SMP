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
STEM='root-producer-census'
PACKAGE='RootProducerCensus'
CACHE=ROOT/'.cache/tasks'/STEM
EVIDENCE=ROOT/'evidence/research'/STEM
MODEL=f'dev/architecture/toolchain/models/sysml/{STEM}.sysml'
DESIGN=f'dev/architecture/toolchain/{STEM}-design.org'
MATRIX=f'dev/architecture/toolchain/{STEM}-matrix.org'
DIAGRAM=f'dev/architecture/toolchain/diagrams/{STEM}.d2'
RULES=f'dev/modeling/ascent/{STEM}.rules.scm'
QNT='models/build/root_producer_census.qnt'
LEAN='models/build/RootProducerCensus.lean'
PARAM='models/build/root_census_parameters.qnt'
GROUPS=[('census',12,'key anchor condition status qntAction leanLemma'),('settle',7,'key anchor condition status qntAction leanLemma'),('caller',5,'key anchor condition'),('protocol',5,'key anchor condition'),('route',5,'key anchor qntAction leanLemma condition'),('gain',3,'key avoided added condition'),('refinement',4,'key qntScope leanScope sourceDuty'),('prior',3,'key path invariant qntAction leanLemma condition'),('gate',7,'key qualified condition')]

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
    for key in ['workspaceCount','familyCount','actualAdmitted']: keys.append(('scalar','',key,f'{PACKAGE}::{key}'))
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
    (ROOT/PARAM).write_text('// Native SysML projection.\nmodule root_census_parameters {\n pure val FamilyCount = '+str(p['scalar']['']['familyCount'])+'\n}\n')
    lines=['#+TITLE: Root Producer Census, FFI Admission and Idle Duty Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+PROPERTY: header-args :eval never','',
      '* RESEARCH Canonical native SysML projection',':PROPERTIES:',':CUSTOM_ID: root-producer-census-matrix',':AUTHORITY: RootProducerCensus',':STATUS: conditional-models-source-open',':END:','',
      'Local formal checks are separate from host registration and native/source qualification.']
    graph=['direction: down']
    for group,field in [('census','condition'),('protocol','condition'),('settle','condition'),('gain','condition')]:
        graph += [group+': '+json.dumps(group.capitalize()+' / native SysML')+' {',' grid-columns: 2']
        graph += [' n'+str(i)+': '+json.dumps(v['key']+'\n'+textwrap.fill(v[field],54)) for i,v in enumerate(p[group])]
        graph+=['}']
    graph+=['proof: "RPC-H/I/S/E -> local ASCENT -> QNT / Lean; source and native gates OPEN"',
      'census -> protocol','protocol -> proof','settle -> proof','proof -> gain']
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
        session=native.open_sources((ROOT/RULES).read_text());queries=['checked','missing','route','blocked','candidate','aligned','prioraligned','componentmapped']
        assert session.run(queries=queries)['complete']
        for case in ['current','missing-qnt','stale-subject','wrong-scope','synthetic-all','unqualified-chain','missing-source-anchor','missing-model-step','missing-prior','missing-root-family']:
            all_checked=case in {'synthetic-all','unqualified-chain','missing-source-anchor','missing-model-step','missing-prior','missing-root-family'}
            receipts=[[case,n,path,digest,scope] for n,kind,path,digest,scope in needs if all_checked or kind in {'interleaving','induction'}]
            if case=='missing-qnt':receipts=[x for x in receipts if x[1]!='RPC-H']
            if case=='stale-subject':receipts=[x[:3]+['stale']+x[4:] if x[1]=='RPC-H' else x for x in receipts]
            if case=='wrong-scope':receipts=[x[:4]+['wrong'] if x[1]=='RPC-I' else x for x in receipts]
            gates=[[case,v['key'],str(all_checked and not(case=='unqualified-chain' and v['key']=='gc-seal')).lower()] for v in p['gate']]
            components=[[g+':'+v['key'],v['anchor'],v['qntAction'],v['leanLemma']] for g in ['census','settle'] for v in p[g]]
            steps=sorted({(v['qntAction'],v['leanLemma']) for g in ['route','prior','census','settle'] for v in p[g]})
            if case=='missing-model-step':steps.remove(('scanFamily','scanPreserves'))
            inputs=dict(scenario=[[case]],need=needs,method=[['interleaving','quint'],['induction','lean'],['source-refinement','source-audit'],['environment-refinement','platform']],
              receipt=receipts,dependency=deps,external=[[case,'SR-S',str(all_checked).lower()]],gate=gates,anchor=[[v['key'],v['anchor']] for v in p['route'] if not(case=='missing-source-anchor' and v['key']=='registration')],
              binding=[[v['key'],v['qntAction'],v['leanLemma'],v['anchor']] for v in p['route']],
              modelstep=[list(v) for v in steps],component=components,componentbinding=[v for v in components if not(case=='missing-root-family' and v[0]=='census:rc-payload')],
              prior=[[v['key'],v['path'],sha(ROOT/v['path']),v['invariant'],v['qntAction'],v['leanLemma']] for v in p['prior']],
              priorbinding=[[v['key'],v['path'],sha(ROOT/v['path']),v['invariant'],v['qntAction'],v['leanLemma']] for v in p['prior'] if not(case=='missing-prior' and v['key']=='strong-receipt')])
            session.replace(inputs);v=session.run(queries=queries);assert v['complete'];results[case]=v['relations']
        assert len(results['current']['componentmapped'])==19
        assert len(results['missing-root-family']['componentmapped'])==18
        assert len(results['current']['prioraligned'])==3
        assert len(results['missing-prior']['prioraligned'])==2
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
    p,native=project();assert p['scalar']['']['workspaceCount']==2 and p['scalar']['']['familyCount']==12;views(p)
    sources=['vendor/gambit/gsc/'+v for v in ['_back.scm','_gvm.scm','_prims.scm','_t-c-1.scm','_t-c-2.scm','_front.scm','_env.scm','_ptree1.scm','_ptree2.scm']]
    sources += ['../gerbil-gambit-bootstrap-audit/src/'+v for v in ['gerbil/compiler/base.ss','gerbil/compiler/driver.ss','gerbil/compiler/compile.ss','std/iter/macros.ss','std/iter/api.ss','std/iter.ss','std/string/misc.ss','std/sync/wg.ss']]
    sources += ['vendor/gambit/gsc/_host.scm','vendor/gambit/gsc/_utils.scm',
      '../gerbil-gambit-bootstrap-audit/src/gerbil/expander/core.ss','vendor/gambit/lib/_thread.scm']
    sources += ['vendor/gambit/lib/mem.c','vendor/gambit/lib/c_intf.c','vendor/gambit/lib/setup.c','vendor/gambit/lib/os_dyn.c',
      'vendor/gambit/examples/tcltk/tcltk.scm','vendor/gambit/include/gambit.h.in','vendor/gambit/lib/_kernel.scm','vendor/gambit/lib/_nonstd.scm','vendor/gambit/lib/srfi/124/124.scm','../gerbil-gambit-bootstrap-audit/src/std/db/sqlite.ss','vendor/gambit/doc/gambit.txi']
    checks=[('vendor/gambit/lib/mem.c','scan_workers_count[0] = np;'),
      ('vendor/gambit/lib/mem.c','___WORD *alloc = alloc_heap_ptr;'),
      ('vendor/gambit/lib/mem.c','alloc_heap_ptr = alloc;'),
      ('vendor/gambit/lib/mem.c','heap_chunks_to_scan_tail = new_tail;'),
      ('vendor/gambit/lib/mem.c','scan_complete_heap_chunk (___PSP ptr+1);'),
      ('vendor/gambit/lib/mem.c','while (ptr != alloc_heap_ptr)'),
      ('vendor/gambit/lib/mem.c','if (--(*workers_count) == 0)'),
      ('vendor/gambit/lib/mem.c','if (*workers_count == 0)'),
      ('vendor/gambit/lib/mem.c','(*workers_count)++;'),
      ('vendor/gambit/lib/mem.c','mark_reachable_from_marked (___PSPNC);'),
      ('vendor/gambit/lib/mem.c','mark_rc (___PSPNC);'),
      ('vendor/gambit/lib/mem.c','mark_captured_continuation (___PSP &body[___CONTINUATION_FRAME]);')]
    census={}
    for name,pattern,scope in [
      ('publication',r'start_heap_chunk|end_heap_chunk|heap_chunks_to_scan|SHARED_MEMORY_BARRIER|alloc_heap_ptr = alloc','vendor/gambit/lib/mem.c'),
      ('termination',r'scan_workers_count|workers_count|scan_termination|mark_reachable_from_marked|continue_local_scan','vendor/gambit/lib/mem.c'),
      ('ffi-rc-writers',r'set_data_rc|register_rc|release_rc|data_rc|make_sfun_stack_marker|kill_sfun_stack_marker','vendor/gambit'),
      ('root-producers',r'mark_vm_scmobj|mark_symkey_tables|mark_rc|mark_global_variables|mark_continuation|mark_registers|mark_saved|mark_type_cache|mark_processor_scmobj|mark_captured_continuation','vendor/gambit/lib/mem.c')]:
        out=run(name,['rg','--json','-g','*.c','-g','*.scm','-g','*.in','-g','*.h',pattern,scope])
        matches=[json.loads(line)['data'] for line in out.splitlines() if json.loads(line)['type']=='match']
        save(CACHE/(name+'-census.json'),dict(matches=matches,scope=scope,closure='syntactic real caller/scan seams; native configuration, root/FFI closure and teardown remain open'))
        census[name]=len(matches)
    for path,frag in checks:assert frag in (ROOT/path).read_text(),(path,frag)
    import re
    mem=(ROOT/'vendor/gambit/lib/mem.c').read_text()
    strong=mem[mem.index('___HIDDEN void garbage_collect_mark_strong_phase'):mem.index('___HIDDEN void garbage_collect_mark_weak_phase')]
    actual=re.findall(r'\b(mark_\w+) \(.*',strong)
    expected=['mark_vm_scmobj','mark_symkey_tables','mark_rc','mark_global_variables','mark_continuation','mark_registers','mark_saved','mark_type_cache','mark_processor_scmobj','mark_reachable_from_marked']
    assert actual==expected
    assert 'mark_rc (___PSPNC);' in strong[strong.index('if (___PROCESSOR_ID'):strong.index('  mark_global_variables')]
    assert re.search(r'#define rc_head\s+___PSTATE_MEM\(rc_head_\)',mem)
    assert '#define ___PSTATE_MEM(var) ___ps->mem.var' in mem
    assert '___rc_header *head = &rc_head;' in mem and 'h->data = val;' in mem
    writers=[]
    for folder in ['lib','examples','include','gsc']:
        for file in sorted((ROOT/'vendor/gambit'/folder).rglob('*')):
            if not file.is_file() or file.suffix not in {'.c','.scm','.in','.h'}:continue
            for no,line in enumerate(file.read_text(errors='replace').splitlines(),1):
                if re.search(r'(?:___EXT\(___set_data_rc\)|___set_data_rc)\s*\(',line):
                    writers.append(dict(path=str(file.relative_to(ROOT)),line=no,text=line.strip()))
    assert [(v['path'],v['line']) for v in writers]==[('vendor/gambit/lib/os_dyn.c',769),('vendor/gambit/examples/tcltk/tcltk.scm',326)]
    save(CACHE/'root-contract-facts.json',dict(strongEntryOrder=actual,setupStillEntry='mem.c:6800',
      directPayloadWriters=writers,scope='Inspected in-tree C/Scheme/headers only; exported consumers and arbitrary aliases remain open',
      asymmetry='Registration uses current PSTATE, strong mark_rc called only on processor zero',
      fullRootCertificate=False,structuralOnly=True))
    q=(ROOT/QNT).read_text();l=(ROOT/LEAN).read_text()
    for v in p['route']+p['census']+p['settle']:
        assert 'action '+v['qntAction']+'=' in q or 'action '+v['qntAction']+'(' in q
        assert 'theorem '+v['leanLemma']+' ' in l
    for v in p['refinement']:
        assert all('action '+n+'(' in q or 'action '+n+'=' in q for n in v['qntScope'].split(';'))
        assert all('theorem '+n+' ' in l for n in v['leanScope'].split(';'))
    prior=[]
    for item in p['prior']:
        path=ROOT/item['path']; text=path.read_text()
        assert any(prefix+item['invariant']+suffix in text for prefix in ['val ','def '] for suffix in [' =','='])
        assert 'action '+item['qntAction']+'=' in q or 'action '+item['qntAction']+'(' in q
        assert 'theorem '+item['leanLemma']+' ' in l
        sources.append(item['path']); prior.append(dict(**item,sha256=sha(path),refinementProved=False,rerun=False))
    save(CACHE/'prior-model-alignment.json',prior)
    save(CACHE/'source-census.json',dict(counts=census,checks=checks,files={s:sha(ROOT/s) for s in sources},aliasClosure='open: external RC writers and generated maps',nativeTests=False))
    tests=run('quint-tests',['quint','test',QNT,'--match','Test$']);assert tests.count('ok ')==21 and tests.count('ControlTest passed')==11
    run('quint-samples',['quint','run',QNT,'--init','init','--invariant','safe','--max-samples','100','--max-steps','80','--seed','17','--verbosity','1'])
    run('quint-other',['quint','run',QNT,'--init','initUnknown','--invariant','safe','--max-samples','100','--max-steps','80','--seed','17','--verbosity','1'])
    run('lean',['lean',LEAN]);ascent(p)
    run('d2-svg',['d2',DIAGRAM,DIAGRAM[:-3]+'.svg']);run('d2-png',['d2',DIAGRAM,str(CACHE/'diagram.png')])
    org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('iter-compiler-service-design.org',STEM+'-design.org').replace('iter-compiler-service-matrix.org',STEM+'-matrix.org')
    save(EVIDENCE/'checks.json',dict(status='pending-local-checks',runtimeAdmitted=False))
    (EVIDENCE/'prior-model-alignment.json').write_bytes((CACHE/'prior-model-alignment.json').read_bytes())
    (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
    parent=ROOT/'evidence/research/strong-closure-receipt/input.json'
    bindings=json.loads(parent.read_text())['sourceBindings']
    assert all(sha(ROOT/path)==h for path,h in bindings.items()),'Parent drift'
    artifacts=[MODEL,DESIGN,MATRIX,DIAGRAM,RULES,QNT,LEAN,PARAM,'dev/modeling/tools/'+STEM+'-study.py']
    for path in artifacts+sources:bindings[path]=sha(ROOT/path)
    identity={'task':STEM,'head':run('head',['git','rev-parse','HEAD']).strip(),
      'vendorHead':run('vendor-head',['git','-C','vendor/gambit','rev-parse','HEAD']).strip(),
      'identityBoundary':'Worktree file hashes, not HEAD alone, identify inspected dirty source'}
    save(CACHE/'input.json',dict(sourceBindings=bindings,checkout=identity,parentLocalInputSha256=sha(parent),parentHostRegistered=False,
      sysmlSha256=sha(CACHE/'sysml.stdout'),logs={str(path.relative_to(ROOT)):sha(path) for path in CACHE.iterdir() if path.suffix in {'.stdout','.stderr'}}))
    checks=dict(status='conditional-local-models-pass',qntHistories=21,negativeControls=11,sampledRuns=200,maxSteps=80,leanBoundaryLemmas=11,
      ascentLocalScenarios=10,gatesOpen=7,aliasClosure='open: external RC writers and generated maps',sourceRefinement='open',hostRegistration='unresolved inherited attestation failure; not retried',runtimeAdmitted=False,nativeTestsRun=False,performanceTestsRun=False)
    save(CACHE/'checks.json',checks)
    for path in CACHE.iterdir():
        if path.is_file() and path.suffix not in {'.png','.stdout','.stderr','.txt','.log'}:(EVIDENCE/path.name).write_bytes(path.read_bytes())
    save(EVIDENCE/'artifacts.json',{str(p.relative_to(ROOT)):sha(p) for p in EVIDENCE.iterdir() if p.is_file() and p.name!='artifacts.json'})
    print(json.dumps(checks))
if __name__=='__main__':main()
