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
        _science.stem = 'notifier-root-retirement'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/notifier_root_parameters.qnt'
        _science.groups = [('root', 6, 'key anchor actualEdge requiredChange'), ('gate', 7, 'key qualified condition'), ('gain', 4, 'key avoided added condition')]
        _science.sources = ['vendor/gambit/' + path for path in ['lib/_kernel.scm', 'lib/_nonstd.scm', 'lib/mem.c', 'lib/_thread.scm', 'lib/_io.scm', 'lib/os_dyn.c', 'tests/mem.scm']]
        _science.sources += ['../gerbil-gambit-bootstrap-audit/src/' + path for path in ['std/text/parser/ebnf/lexer.ss', 'std/text/parser/ebnf/stream.ss', 'std/text/parser/ebnf/lang-reader.ss', 'std/text/parser/ebnf/defparser.ss', 'std/text/parser/base.ss', 'gerbil/runtime/error.ss', 'gerbil/runtime/syntax.ss', 'std/db/sqlite.ss']]
        _science.sources += ['vendor/gambit/include/gambit.h.in', 'vendor/gambit/gsc/_t-c-1.scm', 'vendor/gambit/gsc/_t-c-2.scm']
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, f"// Native NotifierRootRetirement projection.\nmodule notifier_root_parameters {{\n  pure val ReceiptGeneration = {p['receiptGeneration']}\n}}\n")
        lines = ['#+TITLE: Callback Root Retirement and Net-Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: notifier-root-matrix', ':AUTHORITY: NotifierRootRetirement', ':END:', '', 'Derived from native SysML. Proposed root-retirement protocol is not current implementation.']
        for name, _, schema in _science.groups:
            fields = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(row[field]) for field in fields)) + ' |' for row in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['# Derived from native SysML; protocol is proposed, source/native gates remain open.', 'direction: down', 'domain: "gxi/gxc reader-session ownership / Scheme + modern C"', 'roots: "Six root/restoration boundaries" {', ' grid-columns: 2']
        graph += [f' r{n}: ' + json.dumps(v['key'] + '\n' + v['anchor']) for n, v in enumerate(p['root'])]
        graph += ['}', 'prepare: "Prepared notification / live roots"', 'returned: "Normal return / roots may remain"', 'cut: "Certified cut / no roots or restoration edges"', 'receipt: "RootRetirementReceipt / matching attempt and root domain"', 'join: "Ancestor release join / notice alone is insufficient"', 'denied: "Capture, exception, escape or unknown / retain custody"', 'proof: "SysML NR-H/I/S/E -> ASCENT -> QNT / Lean"', 'gates: "Seven source/native gates OPEN"', 'domain -> roots', 'roots -> prepare', 'prepare -> returned', 'returned -> cut', 'cut -> receipt', 'receipt -> join', 'prepare -> denied', 'returned -> denied', 'cut -> proof', 'proof -> gates']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        cohort = {name: _science.context.output(['git', '-C', path, 'rev-parse', 'HEAD'], cwd=_science.ROOT, text=True, name='source-64').strip() for name, path in [('research', '.'), ('gerbil', '../gerbil-gambit-bootstrap-audit'), ('gambit', 'vendor/gambit')]}
        _science.engine.save(cache / 'source-cohort.json', cohort)
        tests = [(_science.sources[0], '(action testator)'), (_science.sources[0], '___POP_REGS'), (_science.sources[0], '___SCMOBJ frame = ___CONTINUATION_FRAME_FIELD(cont);'), (_science.sources[0], '___SCMOBJ denv  = ___CONTINUATION_DENV_FIELD(cont);'), (_science.sources[2], 'mark_array (___PSP ___ps->r, sizeof(___ps->r)/sizeof(*___ps->r));'), (_science.sources[2], 'mark_array (___PSP ___ps->saved, sizeof(___ps->saved)/sizeof(*___ps->saved));'), (_science.sources[2], 'mark_captured_continuation (___PSP &body[___CONTINUATION_FRAME]);'), (_science.sources[2], '___RETN_GET_FS_LINK_GCMAP(ra1,fs,link,gcmap,nextgcmap)'), (_science.sources[2], 'mark_frame (___PSP fp, fs, gcmap, nextgcmap);'), (_science.sources[3], '((macro-dynwind-after src))'), (_science.sources[3], '((macro-dynwind-before dst))'), (_science.sources[12], "(unchecked-slot-set! exn 'continuation cont)"), (_science.sources[12], '(lambda (exn) (##continuation-graft cont handler exn))'), (_science.sources[-3], '(a = (ps)->saved[0],'), (_science.sources[-3], '___GC_SAVE1(ps,___VOID))'), (_science.sources[-3], '___SET_STK(-2,___THREAD_DENV_FIELD(___CURRENTTHREAD))'), (_science.sources[-3], '___CONTINUATION_FRAME_FIELD(___THREAD_CONT_FIELD(thread)) = frame;'), (_science.sources[-3], '___CONTINUATION_FRAME_FIELD(cont) = ___END_OF_CONT_MARKER;'), (_science.sources[2], 'mark_processor_scmobj (___PSPNC);'), (_science.sources[-3], '___SET_STK(-___BREAK_FRAME_NEXT,___CONTINUATION_FRAME_FIELD(cont))'), (_science.sources[-2], '(list "DEF_LBL_PROC"'), (_science.sources[-2], '"DEF_LBL_RET"'), (_science.sources[-1], '(targ-jump-inline "##continuation-capture"'), (_science.sources[-1], '(targ-jump-inline "##continuation-return-no-winding"')]
        for path, fragment in tests:
            assert fragment in (_science.ROOT / path).read_text(), (path, fragment)
        assert (_science.ROOT / 'models/build/NotifierRootRetirement.lean').read_text().count('theorem ') == 8
        _science.engine.save(cache / 'source-census.json', dict(checks=[dict(path=p, fragment=f) for p, f in tests], bindings={p: _science.engine.sha(_science.ROOT / p) for p in _science.sources}, exactGeneratedPoint='open', allRootRestoreClosure='open', transitiveEffects='open', actualIssuer='absent-proposed', runtimeAdmitted=False, externalReference=dict(url='https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-8.html', role='Scheme control semantics, not implementation refinement')))

    def facts(_science, p, scenario):
        out = [_science.engine.fact('retirementRootFact', [v[k] for k in ['key', 'anchor', 'actualEdge', 'requiredChange']]) for v in p['root']]
        for gate in p['gate']:
            qualified = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and gate['key'] == 'retirement-cut'))
            out.append(_science.engine.fact('retirementGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
        out.append(_science.engine.fact('retirementSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        c = results['current']
        assert sorted(c['retirementRoot']) == sorted((['current'] + [v[k] for k in ['key', 'anchor', 'actualEdge', 'requiredChange']] for v in p['root']))
        assert len(c['retirementMissing']) == len(p['gate']) and (not c['retirementCandidate'])
        assert not results['all-scoped-control']['retirementCandidate']
        assert len(results['synthetic-gates']['retirementCandidate']) == 1
        assert not results['missing-release']['retirementCandidate']

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent='owner-notifier-closure', package='NotifierRootRetirement', prefix='NR', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/notifier_root_retirement.qnt', lean='models/build/NotifierRootRetirement.lean', parent_design='dev/architecture/toolchain/owner-notifier-closure-design.org', parent_matrix='dev/architecture/toolchain/owner-notifier-closure-matrix.org', groups=_science.groups, scalars=['receiptGeneration', 'actualAdmitted'], histories=32, controls=15, kernels=8, inits=['init', 'initUnqualified'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='retirementRoot retirementMissing retirementBlocked retirementCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/notifier_root_retirement.qnt', 'models/build/NotifierRootRetirement.lean', 'src/gambit_smp/scientific_notifier_root_study.py', 'src/gambit_smp/scientific_formal_study.py'])
        _science.engine.execute(study, resume=args.resume)
