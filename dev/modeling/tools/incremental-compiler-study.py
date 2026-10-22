#!/usr/bin/env python3
"""Native SysML/ASCENT projection hooks for callback root retirement research."""
import argparse
import importlib.util
import json
import subprocess
import textwrap
from pathlib import Path
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("formal_study", Path(__file__).with_name("formal-study.py"))
engine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
ROOT = engine.ROOT
stem = "incremental-compiler-architecture"
model = f"dev/architecture/toolchain/models/sysml/{stem}.sysml"
design = f"dev/architecture/toolchain/{stem}-design.org"
matrix = f"dev/architecture/toolchain/{stem}-matrix.org"
diagram = f"dev/architecture/toolchain/diagrams/{stem}.d2"
rules = f"dev/modeling/ascent/{stem}.rules.scm"
param = "models/build/incremental_compiler_parameters.qnt"
groups = [("component",6,"key anchor responsibility replacement"),
          ("stage",8,"key role inputs result"), ("node",8,"key number dependencySet anchor contract"),
          ("gate",7,"key qualified condition"), ("gain",6,"key avoided added condition")]


def views(p):
    (ROOT / param).write_text("// Native IncrementalCompilerArchitecture projection.\nmodule incremental_compiler_parameters {\n"
        f"  pure val NodeCount = {p['nodeCount']}\n  pure val Capacity = {p['capacity']}\n"
        + "  pure val Parents = Map(" + ", ".join(str(v['number'])+" -> "+v['dependencySet'] for v in p['node']) + ")\n}\n")
    lines = ["#+TITLE: Incremental Compiler Architecture, Retirement and Benefit Matrix",
        "#+SETUPFILE: ../../modeling/org/setup.org", "#+PROPERTY: header-args :eval never", "",
        "* RESEARCH Native SysML projection", ":PROPERTIES:", ":CUSTOM_ID: incremental-compiler-matrix",
        ":AUTHORITY: IncrementalCompilerArchitecture", ":END:", "",
        "Derived from native SysML. Proposed root-retirement protocol is not current implementation."]
    for name, _, schema in groups:
        fields = schema.split()
        lines += ["", "** " + name.capitalize(), "", "| " + " | ".join(fields) + " |", "|" + "+".join("---" for _ in fields) + "|"]
        lines += ["| " + " | ".join(str(row[field]) for field in fields) + " |" for row in p[name]]
    (ROOT / matrix).write_text("\n".join(lines) + "\n")
    graph=["# Native SysML owns responsibilities/stages/graph; arrows denote logical contracts, not implementation.","direction: down",
        'components: "Replacement architecture / modern C + Scheme" {',' grid-columns: 2']
    graph += [f" c{n}: "+json.dumps(v['key']+"\n"+textwrap.fill(v['responsibility'],45)) for n,v in enumerate(p['component'])]
    graph += ['}', 'stages: "Typed results / live session instances are separately owned" {', ' grid-columns: 2']
    graph += [f" s{n}: "+json.dumps(v['key']) for n,v in enumerate(p['stage'])]
    graph += ['}', 'dag: "Bounded formal graph / not the full production graph" {']
    graph += [f" n{v['number']}: "+json.dumps(v['key']) for v in p['node']]
    graph += ['}']
    # Native dependencySet strings already drive Quint; numeric edges below are view-only values of that projection.
    import re
    for v in p['node']:
        for dep in re.findall(r"\d+",v['dependencySet']): graph.append(f"dag.n{dep} -> dag.n{v['number']}")
    graph += ['dag.n7 -> dag.n2: "dynamic / suspended demand" {style.stroke-dash: 4}',
        'proof: "SysML IC-H/I/S/E -> ASCENT -> QNT / Lean"',
        'benefit: "Separate work W, span S, overhead H and retained memory M"',
        'gate: "Seven source/platform gates OPEN; no measured speedup"',
        'components -> stages', 'stages -> dag','dag -> proof','proof -> benefit','benefit -> gate']
    (ROOT/diagram).write_text("\n".join(graph)+"\n")


sources=["../gerbil-gambit-bootstrap-audit/src/"+v for v in ["std/make.ss","gerbil/compiler/driver.ss","gerbil/compiler/base.ss",
    "gerbil/compiler/optimize.ss","gerbil/compiler/optimize-base.ss","gerbil/expander/module.ss","gerbil/expander/core.ss",
    "gerbil/runtime/loader.ss","std/iter/macros.ss","std/string/misc.ss","std/sync/wg.ss"]]
sources += ["vendor/gambit/"+v for v in ["include/gambit.h.in","lib/setup.c","lib/mem.c","gsc/_t-c-3.scm"]]
sources += ["../gerbil-gambit-bootstrap-audit/build/"+v for v in ["lib/std/db/sqlite~0.o1","lib/std/db/sqlite~0.o1.dSYM/Contents/Resources/DWARF/sqlite~0.o1","include/gambit.h"]]
sources += ["/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/mach-o/fixup-chains.h",
    "../../patches/gerbil-v19-darwin/receipts/d884-patched-staging-bootstrap-coverage.md",
    "../../patches/gerbil-v19-darwin/receipts/d881-gvm-live-block-budget-source-probe.md","vendor/ocaml/typing/persistent_env.ml"]


def source_checks(cache):
    cohort={name:subprocess.check_output(["git","-C",path,"rev-parse","HEAD"],cwd=ROOT,text=True).strip()
        for name,path in [("research","."),("gerbil","../gerbil-gambit-bootstrap-audit"),("gambit","vendor/gambit")]}
    engine.save(cache/'source-cohort.json',cohort)
    tests=[(sources[0],'(getenv "GERBIL_BUILD_CORES" "0")'),(sources[0],'(def import-mx (make-mutex'),
        (sources[0],'(completion-wait! completion)'),(sources[0],';; TODO: split that'),
        (sources[1],'(with-driver-mutex (optimize! ctx))'),(sources[1],'(with-driver-mutex (import-module srcpath))'),
        (sources[1],'(compile-runtime-code ctx)'),(sources[1],'(inexact->exact (floor (time->seconds (current-time))))'),
        (sources[2],'(make-symbol "__" sym "__" (current-compile-timestamp))'),(sources[1],'(compile-meta-code ctx)'),
        ('vendor/gambit/lib/setup.c','hlbl_ptr++; /* skip INTRO label */'),
        ('vendor/gambit/include/gambit.h.in','#define ___IFD_FS_WIDTH 5'),
        ('vendor/gambit/include/gambit.h.in','#define ___KIND_WIDTH 2'),
        ('/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/mach-o/fixup-chains.h','DYLD_CHAINED_PTR_64_OFFSET')]
    for path,fragment in tests:assert fragment in (ROOT/path).read_text(),(path,fragment)
    helper=importlib.util.spec_from_file_location('descriptor_reader',ROOT/'dev/modeling/tools/inspect-action-descriptors.py')
    module=importlib.util.module_from_spec(helper);helper.loader.exec_module(module)
    recovered=module.inspect(ROOT,cache)
    assert recovered['returnDescriptorsRecovered']==3 and recovered['deadRegisterMasksQualified']==0
    assert (ROOT/'models/build/IncrementalCompilerArchitecture.lean').read_text().count('theorem ')==8
    engine.save(cache/'source-census.json',dict(checks=[dict(path=p,fragment=f) for p,f in tests],
        bindings={p:engine.sha(ROOT/p) for p in sources}, fullCompilerRefinement='open', nativeTests=False,
        descriptorRecovery='static-read-only', deadRegisters='unresolved', originalActionGeneration='unresolved',
        primaryReferences=["https://simon.peytonjones.org/assets/pdfs/build-systems-original.pdf",
          "https://raw.githubusercontent.com/ocaml/dune/main/src/memo/memo.ml",
          "https://raw.githubusercontent.com/ocaml/dune/main/src/dune_engine/build_system.ml",
          "https://ocaml.org/manual/5.5/comp.html"]))


def facts(p,scenario):
    out=[engine.fact('compilerComponentFact',[v[k] for k in ['key','anchor']]) for v in p['component']]
    for gate in p['gate']:
        qualified=scenario in {'synthetic-gates','missing-release'} and not(scenario=='missing-release' and gate['key']=='tracked-inputs')
        out.append(engine.fact('compilerGateFact',[scenario,gate['key'],str(qualified or gate['qualified']).lower()]))
    out.append(engine.fact('compilerSourceFact',[scenario,str(scenario in {'synthetic-gates','missing-release'}).lower()]))
    return out


def check_inference(p,results):
    c=results['current']
    assert sorted(c['compilerComponent'])==sorted(['current',v['key'],v['anchor']] for v in p['component'])
    assert len(c['compilerMissing'])==7 and not c['compilerCandidate']
    assert not results['all-scoped-control']['compilerCandidate']
    assert len(results['synthetic-gates']['compilerCandidate'])==1
    assert not results['missing-release']['compilerCandidate']


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    study = SimpleNamespace(task=stem, parent="will-action-admission", package="IncrementalCompilerArchitecture", prefix="IC",
        model=model, design=design, matrix=matrix, diagram=diagram, rules=rules, param=param,
        qnt="models/build/incremental_compiler_architecture.qnt", lean="models/build/IncrementalCompilerArchitecture.lean",
        parent_design="dev/architecture/toolchain/will-action-admission-design.org",
        parent_matrix="dev/architecture/toolchain/will-action-admission-matrix.org",
        groups=groups, scalars=["nodeCount", "capacity", "actualAdmitted"], histories=26, controls=11, kernels=8, inits=["init", "initOpaque"],
        views=views, source_checks=source_checks, facts=facts, check_inference=check_inference,
        outputs="compilerComponent compilerMissing compilerBlocked compilerCandidate", sources=sources,
        artifacts=[model, design, matrix, diagram, rules, param, "models/build/incremental_compiler_architecture.qnt",
            "models/build/IncrementalCompilerArchitecture.lean", "dev/modeling/tools/incremental-compiler-study.py", "dev/modeling/tools/formal-study.py", "dev/modeling/tools/inspect-action-descriptors.py"])
    engine.execute(study, resume=args.resume)
