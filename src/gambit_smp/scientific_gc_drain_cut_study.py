"""Native SysML/ASCENT projection hooks for callback root retirement research."""
from gambit_smp.research_flow import write_text as _study_write_text
import json
from types import SimpleNamespace

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.SimpleNamespace = SimpleNamespace
        _science.engine = _science.context.library('formal_study')
        _science.ROOT = _science.context.root
        _science.stem = 'gc-drain-retirement-cut'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/gc_drain_cut_parameters.qnt'
        _science.groups = [('point', 7, 'key anchor descriptor actualEdge requiredChange'), ('gate', 7, 'key qualified condition'), ('gain', 4, 'key avoided added condition')]
        _science.sources = ['vendor/gambit/' + path for path in ['lib/_kernel.scm', 'lib/_nonstd.scm', 'lib/mem.c', 'lib/_thread.scm', 'lib/_io.scm', 'lib/os_dyn.c', 'tests/mem.scm']]
        _science.sources += ['../gerbil-gambit-bootstrap-audit/src/' + path for path in ['std/text/parser/ebnf/lexer.ss', 'std/text/parser/ebnf/stream.ss', 'std/text/parser/ebnf/lang-reader.ss', 'std/text/parser/ebnf/defparser.ss', 'std/text/parser/base.ss', 'gerbil/runtime/error.ss', 'gerbil/runtime/syntax.ss', 'std/db/sqlite.ss']]
        _science.sources += ['vendor/gambit/include/gambit.h.in', 'vendor/gambit/gsc/_t-c-1.scm', 'vendor/gambit/gsc/_t-c-2.scm', 'vendor/gambit/gsc/_t-c-3.scm', 'vendor/gambit/lib/_kernel.c']
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, f"// Native GcDrainRetirementCut projection.\nmodule gc_drain_cut_parameters {{\n  pure val GvmRegisters = {p['defaultRegisters']}\n  pure val WillInternalMask = {p['willInternalMask']}\n  pure val WillReturnMask = {p['willReturnMask']}\n}}\n")
        lines = ['#+TITLE: Generated GC Drain Cuts and Net-Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: notifier-root-matrix', ':AUTHORITY: GcDrainRetirementCut', ':END:', '', 'Derived from native SysML. Proposed root-retirement protocol is not current implementation.']
        for name, _, schema in _science.groups:
            fields = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(row[field]) for field in fields)) + ' |' for row in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['# Source-bound retained generated path; proposed cuts are not current issuers.', 'direction: down', 'points: "Retained generated path / modern C" {']
        graph += [f' p{n}: ' + json.dumps(v['key'] + '\n' + v['descriptor']) for n, v in enumerate(p['point'][:6])]
        graph += ['}']
        graph += [f'points.p{n} -> points.p{n + 1}' for n in range(5)]
        graph += ['restore: "POLL -> all-register snapshot -> internal/thread restore"', 'epi: "Candidate per-action cut after VOID / not admitted"', 'batch: "Candidate explicit batch barrier before jobs / not admitted"', 'proof: "SysML DC-H/I/S/E -> ASCENT -> QNT / Lean"', 'open: "Generation provenance + root/effect closure + native publication OPEN"', 'points.p0 -> restore', 'restore -> points.p0', 'points.p1 -> epi', 'points.p4 -> batch', 'epi -> proof', 'batch -> proof', 'proof -> open']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        cohort = {name: _science.context.output(['git', '-C', path, 'rev-parse', 'HEAD'], cwd=_science.ROOT, text=True, name='source-62').strip() for name, path in [('research', '.'), ('gerbil', '../gerbil-gambit-bootstrap-audit'), ('gambit', 'vendor/gambit')]}
        _science.engine.save(cache / 'source-cohort.json', cohort)
        import re
        generated = (_science.ROOT / 'vendor/gambit/lib/_kernel.c').read_text()
        projection = json.loads((cache / 'projection.json').read_text())['detail']
        assert 'produced by Gambit v4.9.8' in generated
        hosts = {}
        names = ['will_2d_execute_21_', 'gc_2d_finalize_21_', 'gc_2d_final_2d_will_2d_registry_21_', 'handle_2d_gc_2d_interrupt_21_', 'execute_2d_jobs_21_']
        for name in names:
            host = '___H__23__23_' + name
            start = generated.index('#define ___PH_PROC ' + host + '\n')
            end = generated.index('\n#undef ___PH_PROC', start)
            body = generated[start:end]
            descriptors = re.findall('___DEF_LBL_RET\\(' + re.escape(host) + ',___IFD\\(___(RETI|RETN),(\\d+),(\\d+),(0x[0-9a-f]+)L\\)\\)', generated)
            hosts[name] = dict(startLine=generated.count('\n', 0, start) + 1, body=body, returnDescriptors=[dict(labelIndex=i + 1, kind=k, size=int(fs), link=int(link), mask=int(mask, 16)) for i, (k, fs, link, mask) in enumerate(descriptors)], writes=re.findall('___SET_R(\\d+)\\(([^\\n]*)', body), bankSavedClearingPresent='___GC_RESTORE' in body or '->saved' in body, labels=re.findall('___DEF_SLBL\\((\\d+),([^)]*)\\)', body))
        will = hosts[names[0]]
        assert will['returnDescriptors'] == [dict(labelIndex=1, kind='RETI', size=4, link=0, mask=projection['willInternalMask']), dict(labelIndex=2, kind='RETN', size=1, link=0, mask=projection['willReturnMask'])]
        assert [v['mask'] for v in hosts[names[4]]['returnDescriptors']] == [63, 3, 63, 16131]
        assert all((not hosts[n]['bankSavedClearingPresent'] for n in names))
        assert not re.search('___SET_R4\\(', hosts[names[1]]['body'] + hosts[names[2]]['body'] + hosts[names[3]]['body'])
        epilogue = will['body'].split('___DEF_SLBL(2,', 1)[1]
        assert '___SET_R1(___VOID)' in epilogue and (not re.search('___SET_R[234]\\(', epilogue))
        hdr = (_science.ROOT / 'vendor/gambit/include/gambit.h.in').read_text()
        emitter = (_science.ROOT / 'vendor/gambit/gsc/_t-c-1.scm').read_text()
        assert int(re.search('#define ___NB_GVM_REGS (\\d+)', hdr)[1]) == projection['defaultRegisters']
        assert int(re.search('\\(define targ-default-nb-gvm-regs (\\d+)\\)', emitter)[1]) == projection['defaultRegisters']
        tests = [('vendor/gambit/lib/_kernel.scm', '___PUSH_REGS /* push all GVM registers (live or not) */'), ('vendor/gambit/lib/_kernel.scm', '___POP_REGS'), ('vendor/gambit/lib/_kernel.scm', '(##execute-jobs! ##gc-interrupt-jobs)'), ('vendor/gambit/gsc/_t-c-2.scm', '; all saved GVM regs are live'), ('vendor/gambit/include/gambit.h.in', '#define ___W_ALL ___SM(___MW_ALL,___PW_ALL)'), ('vendor/gambit/include/gambit.h.in', '___GC_SAVE1(ps,___VOID))'), ('vendor/gambit/include/gambit.h.in', '___CONTINUATION_FRAME_FIELD(___THREAD_CONT_FIELD(thread)) = frame;'), ('vendor/gambit/lib/mem.c', 'mark_array (___PSP ___ps->r, sizeof(___ps->r)/sizeof(*___ps->r));')]
        for path, fragment in tests:
            assert fragment in (_science.ROOT / path).read_text(), (path, fragment)
        assert (_science.ROOT / 'models/build/GcDrainRetirementCut.lean').read_text().count('theorem ') == 8
        lines = generated.splitlines()
        assert lines[17164].strip() == '___SET_R1(___VOID)' and lines[17165].strip() == '___JUMPRET(___R0)'
        assert lines[17333].strip() == '___ADJFP(-4)' and 'execute_2d_jobs_21_' in lines[17334]
        _science.engine.save(cache / 'candidate-cuts.json', dict(perAction=dict(afterLine=17165, beforeLine=17166), preJobs=dict(afterLine=17334, beforeLine=17335), currentIssuer=False, qualified=False))
        _science.engine.save(cache / 'generated-path.json', dict(source='vendor/gambit/lib/_kernel.c', digest=_science.engine.sha(_science.ROOT / _science.sources[-1]), hosts=hosts, originalGenerationReceipt='unresolved', configuredDarwinObject='unresolved', callbackR4Postcondition='adversarial-not-observed', currentIssuer=False))
        _science.engine.save(cache / 'source-census.json', dict(checks=[dict(path=p, fragment=f) for p, f in tests], bindings={p: _science.engine.sha(_science.ROOT / p) for p in _science.sources}, originalGenerationReceipt='unresolved', exactConfiguredRootMap='unresolved', registerRestoreClosure='unresolved', actualIssuer=False))

    def facts(_science, p, scenario):
        out = [_science.engine.fact('drainPointFact', [v[k] for k in ['key', 'anchor', 'descriptor', 'actualEdge', 'requiredChange']]) for v in p['point']]
        for gate in p['gate']:
            qualified = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and gate['key'] == 'restore-closure'))
            out.append(_science.engine.fact('drainGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
        out.append(_science.engine.fact('drainSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        c = results['current']
        assert sorted(c['drainPoint']) == sorted((['current'] + [v[k] for k in ['key', 'anchor', 'descriptor', 'actualEdge', 'requiredChange']] for v in p['point']))
        assert len(c['drainMissing']) == len(p['gate']) and (not c['drainCandidate'])
        assert not results['all-scoped-control']['drainCandidate']
        assert len(results['synthetic-gates']['drainCandidate']) == 1
        assert not results['missing-release']['drainCandidate']

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent='notifier-root-retirement', package='GcDrainRetirementCut', prefix='DC', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/gc_drain_retirement_cut.qnt', lean='models/build/GcDrainRetirementCut.lean', parent_design='dev/architecture/toolchain/notifier-root-retirement-design.org', parent_matrix='dev/architecture/toolchain/notifier-root-retirement-matrix.org', groups=_science.groups, scalars=['defaultRegisters', 'willInternalMask', 'willReturnMask', 'actualAdmitted'], histories=35, controls=17, kernels=8, inits=['init', 'initCandidate'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='drainPoint drainMissing drainBlocked drainCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/gc_drain_retirement_cut.qnt', 'models/build/GcDrainRetirementCut.lean', 'src/gambit_smp/scientific_gc_drain_cut_study.py', 'src/gambit_smp/scientific_formal_study.py'])
        _science.engine.execute(study, resume=args.resume)
