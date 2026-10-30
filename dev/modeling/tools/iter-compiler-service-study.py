#!/usr/bin/env python3
"""Native SysML projection and conditional protocol research; no compiler implementation."""
import argparse
import importlib.util
import json
import subprocess
import textwrap
from pathlib import Path
from types import SimpleNamespace
spec=importlib.util.spec_from_file_location("formal_study",Path(__file__).with_name("formal-study.py"))
engine=importlib.util.module_from_spec(spec);spec.loader.exec_module(engine)
ROOT=engine.ROOT
stem="iter-compiler-service"
model=f"dev/architecture/toolchain/models/sysml/{stem}.sysml"
design=f"dev/architecture/toolchain/{stem}-design.org"
matrix=f"dev/architecture/toolchain/{stem}-matrix.org"
diagram=f"dev/architecture/toolchain/diagrams/{stem}.d2"
rules=f"dev/modeling/ascent/{stem}.rules.scm"
param="models/build/iter_compiler_parameters.qnt"
groups=[('chain',5,'key labelText anchor'),('chainEdge',4,'fromKey toKey contract'),('refinement',4,'key qntScope leanScope evidenceGap'),('seam', 5, 'key owner anchor input completion'), ('context', 5, 'key anchor stateSet isolation retirement'), ('retire', 5, 'key anchor condition removed retained'), ('gain', 4, 'key avoided added condition'), ('gate', 7, 'key qualified condition')]
sources=['../gerbil-gambit-bootstrap-audit/src/std/iter.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/api.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/macros.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/interface.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/iterators.ss', '../gerbil-gambit-bootstrap-audit/src/std/interface.ss', '../gerbil-gambit-bootstrap-audit/src/std/list/list-builder.ss', '../gerbil-gambit-bootstrap-audit/src/std/string/misc.ss', '../gerbil-gambit-bootstrap-audit/src/std/sync/wg.ss', '../gerbil-gambit-bootstrap-audit/src/std/make.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/base.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/expander/module.ss', 'vendor/gambit/gsc/_front.scm', 'vendor/gambit/gsc/_env.scm', 'vendor/gambit/gsc/_ptree1.scm', 'vendor/gambit/gsc/_gvm.scm', 'vendor/gambit/gsc/_back.scm', 'vendor/gambit/gsc/_t-c-1.scm', 'evidence/research/iter-compiler-service/dune-src-memo-memo.ml', 'evidence/research/iter-compiler-service/dune-src-memo-exec.ml', 'evidence/research/iter-compiler-service/dune-src-memo-invalidation.ml', 'evidence/research/iter-compiler-service/dune-src-memo-deps.ml', 'evidence/research/iter-compiler-service/dune-src-dune_engine-build_system.ml', 'evidence/research/iter-compiler-service/dune-src-memo-node.ml', 'evidence/research/iter-compiler-service/dune-upstream-commit.json', 'evidence/research/iter-compiler-service/dune-src-memo-deps_collector.ml', 'evidence/research/iter-compiler-service/dune-source-manifest.json', 'evidence/research/iter-compiler-service/dune-src-memo-parallel.ml']

def views(p):
    (ROOT/param).write_text("// Native SysML parameter projection.\nmodule iter_compiler_parameters {\n"
        +f" pure val ConsumerCount = {p['consumerCount']}\n pure val Capacity = {p['capacity']}\n pure val LastStage = {p['lastStage']}\n}}\n")
    lines=["#+TITLE: Iter Compiler Service Contracts, Retirement and Net Benefit Matrix",
      "#+SETUPFILE: ../../modeling/org/setup.org","#+PROPERTY: header-args :eval never","",
      "* RESEARCH Native SysML projection",":PROPERTIES:",":CUSTOM_ID: iter-service-matrix",
      ":AUTHORITY: IterCompilerService",":STATUS: conditional-models-source-refinement-open",":END:","",
      "Proposed contracts. All source/platform gates stay open; no native performance result."]
    for name,_,schema in groups:
        fs=schema.split();lines += ["","** "+name.capitalize(),"","| "+" | ".join(fs)+" |","|"+"+".join("---" for _ in fs)+"|"]
        lines += ["| "+" | ".join(str(v[f]) for f in fs)+" |" for v in p[name]]
    (ROOT/matrix).write_text("\n".join(lines)+"\n")
    graph=['direction: down','chain: "Real iter macro dependency chain / executable closure still under admission" {']
    graph += [v['key']+': '+json.dumps(v['labelText']) for v in p['chain']]
    graph += [v['fromKey']+' -> '+v['toKey'] for v in p['chainEdge']]
    graph += ['}', 'seams: "Proposed typed stage contracts / not current public APIs" {']
    graph += [' s'+str(i)+': '+json.dumps(v['key']+"\n"+v['owner']) for i,v in enumerate(p['seam'])]
    graph += [' s0 -> s1',' s1 -> s2',' s2 -> s3',' s3 -> s4','}',
      'context: "Owned Gambit context / source writer census remains open" {',' grid-columns: 2']
    graph += [' c'+str(i)+': '+json.dumps(v['key']+"\n"+textwrap.fill(v['stateSet'],43)) for i,v in enumerate(p['context'])]
    graph += ['}',
      'ready: "Gerbil scheduler: binding + executable support + owned fresh instance"',
      'drain: "Pause retains roots/context; failure or unknown drains; seal before release"',
      'proof: "SysML IS-H/I/S/E -> ASCENT route -> QNT histories / Lean premises"',
      'gain: "Benefit: avoided work > added work; removed critical path > added span"',
      ' chain -> ready',' ready -> seams',' seams -> context',' context -> drain',' drain -> proof',' proof -> gain']
    (ROOT/diagram).write_text("\n".join(graph)+"\n")

def source_checks(cache):
    checks=[('../gerbil-gambit-bootstrap-audit/src/std/iter.ss','(export (import: ./iter/api))'),
      ('../gerbil-gambit-bootstrap-audit/src/std/iter/api.ss','./macros'),
      ('../gerbil-gambit-bootstrap-audit/src/std/iter/macros.ss','(begin-syntax'),
      ('../gerbil-gambit-bootstrap-audit/src/std/string/misc.ss','(for (i (in-range start end))'),
      ('../gerbil-gambit-bootstrap-audit/src/std/sync/wg.ss','(for (worker wg.workers)'),
      ('../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss','(def (compile-scm-file path code (phi? #f))'),
      ('../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss','(def (gsc-compile-file path phi?)'),
      ('vendor/gambit/gsc/_env.scm',"(set! next-var-stamp (make-counter 0))"),
      ('vendor/gambit/gsc/_gvm.scm',"(set! *opnd-table-alloc* 0)"),
      ('vendor/gambit/gsc/_back.scm',"(set! target.dump              (target-dump target))")]
    for path,fragment in checks: assert fragment in (ROOT/path).read_text(),(path,fragment)
    manifest=json.loads((ROOT/f"evidence/research/{stem}/dune-source-manifest.json").read_text())
    for f in manifest['files']:
        assert engine.sha(ROOT/f"evidence/research/{stem}"/f['local'])==f['sha256']
    cohort={name:subprocess.check_output(['git','-C',path,'rev-parse','HEAD'],cwd=ROOT,text=True).strip()
      for name,path in [('research','.'),('gerbil','../gerbil-gambit-bootstrap-audit'),('gambit','vendor/gambit')]}
    engine.save(cache/'source-census.json',dict(checks=checks,duneCommit=manifest['commit'],sourceCohort=cohort,
       writerClosure='open',stageSimulation='open',nativeTests=False,performanceTests=False))
    assert (ROOT/'models/build/IterCompilerService.lean').read_text().count('theorem ')==8

def facts(p,scenario):
    out=[engine.fact('iterSeamFact',[v['key'],v['owner'],v['anchor']]) for v in p['seam']]
    out += [engine.fact('iterDependencyFact',[v['fromKey'],v['toKey']]) for v in p['chainEdge']]
    out += [engine.fact('iterRefinementFact',[v['key'],v['qntScope'],v['leanScope']]) for v in p['refinement']]
    out += [engine.fact('iterContextFact',[v['key'],v['anchor']]) for v in p['context']]
    for g in p['gate']:
        passed=scenario in {'synthetic-gates','missing-release'} and not(scenario=='missing-release' and g['key']=='context-ownership')
        out.append(engine.fact('iterGateFact',[scenario,g['key'],str(passed or g['qualified']).lower()]))
    out.append(engine.fact('iterSourceFact',[scenario,str(scenario in {'synthetic-gates','missing-release'}).lower()]))
    return out

def check_inference(p,results):
    c=results['current']
    assert sorted(c['iterSeam'])==sorted(['current',v['key'],v['owner'],v['anchor']] for v in p['seam'])
    assert sorted(c['iterContext'])==sorted(['current',v['key'],v['anchor']] for v in p['context'])
    assert sorted(c['iterRefinement'])==sorted(['current',v['key'],v['qntScope'],v['leanScope']] for v in p['refinement'])
    qnt=(ROOT/'models/build/iter_compiler_service.qnt').read_text()
    lean=(ROOT/'models/build/IterCompilerService.lean').read_text()
    for v in p['refinement']:
        assert all(('action '+n+' ' in qnt or 'action '+n+'(' in qnt or 'def '+n+'(' in qnt) for n in v['qntScope'].split(';'))
        assert all('theorem '+n+' ' in lean for n in v['leanScope'].split(';'))
    assert sorted(c['iterDependency'])==sorted(['current',v['fromKey'],v['toKey']] for v in p['chainEdge'])
    keys={v['key'] for v in p['chain']}
    assert all(v['fromKey'] in keys and v['toKey'] in keys for v in p['chainEdge'])
    assert len(c['iterMissing'])==7 and not c['iterCandidate']
    assert not results['all-scoped-control']['iterCandidate']
    assert len(results['synthetic-gates']['iterCandidate'])==1
    assert not results['missing-release']['iterCandidate']

def prepare_base():
    old=ROOT/'evidence/research/incremental-compiler-architecture'
    target=ROOT/'evidence/research/iter-service-base';target.mkdir(exist_ok=True)
    original=json.loads((old/'input.json').read_text());selected={('build-planner','IC-S')}
    while True:
        added={(d['prerequisiteComponent'],d['prerequisite']) for d in original['dependencies'] if (d['component'],d['obligation']) in selected}
        if added<=selected: break
        selected |= added
    needs=[n for n in original['needs'] if (n['component'],n['obligationId']) in selected]
    deps=[d for d in original['dependencies'] if (d['component'],d['obligation']) in selected]
    p=json.loads((old/'projection.json').read_text())
    nk={k for k,v in p['needs'].items() if (v['owner']['componentId'],v['obligationId']) in selected}
    dk={k for k,v in p['dependencies'].items() if (v['dependent']['owner']['componentId'],v['dependent']['obligationId']) in selected}
    queries=[q for q in json.loads((old/'native-queries.json').read_text()) if q[0].startswith(('components.','methods.'))
      or q[0].split('.')[0]=='needs' and q[0].split('.')[1] in nk
      or q[0].split('.')[0]=='dependencies' and q[0].split('.')[1] in dk]
    engine.save(target/'native-queries.json',queries)
    engine.save(target/'input.json',dict(original,needs=needs,dependencies=deps))
    current=json.loads((old/'current.json').read_text());current['projectionOnly']=True
    current['brief']['association']['locallyChecked']=[v for v in current['brief']['association']['locallyChecked'] if (v[1],v[2]) in selected]
    engine.save(target/'current.json',current)
    for f in ['planner-policy.ss','check-org.el']:(target/f).write_bytes((old/f).read_bytes())
    engine.save(target/'selection.json',dict(projectionOnly=True,sourceInputSha256=engine.sha(old/'input.json'),selected=sorted(selected)))
    return 'iter-service-base'

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--resume',action='store_true');args=parser.parse_args()
    study=SimpleNamespace(task=stem,parent=prepare_base(),package='IterCompilerService',prefix='IS',
      model=model,design=design,matrix=matrix,diagram=diagram,rules=rules,param=param,
      qnt='models/build/iter_compiler_service.qnt',lean='models/build/IterCompilerService.lean',
      parent_design='dev/architecture/toolchain/incremental-compiler-architecture-design.org',
      parent_matrix='dev/architecture/toolchain/incremental-compiler-architecture-matrix.org',
      groups=groups,scalars=['consumerCount','capacity','lastStage','actualAdmitted'],histories=18,controls=6,kernels=8,
      inits=['init'],views=views,source_checks=source_checks,facts=facts,check_inference=check_inference,
      outputs='iterDependency iterRefinement iterSeam iterContext iterMissing iterBlocked iterCandidate',sources=sources,
      artifacts=[model,design,matrix,diagram,rules,param,'models/build/iter_compiler_service.qnt',
        'models/build/IterCompilerService.lean','dev/modeling/tools/iter-compiler-service-study.py','dev/modeling/tools/formal-study.py'])
    engine.execute(study,resume=args.resume)
