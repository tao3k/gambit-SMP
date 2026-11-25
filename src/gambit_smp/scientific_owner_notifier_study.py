"""Native SysML/ASCENT projection hooks for owner/notifier closure research."""
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
        _science.stem = 'owner-notifier-closure'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/owner_notifier_parameters.qnt'
        _science.groups = [('holder', 7, 'key anchor actualEdge requiredChange'), ('gate', 7, 'key qualified condition'), ('gain', 4, 'key avoided added condition')]
        _science.sources = ['vendor/gambit/' + path for path in ['lib/_kernel.scm', 'lib/_nonstd.scm', 'lib/mem.c', 'lib/_thread.scm', 'lib/_io.scm', 'lib/os_dyn.c', 'tests/mem.scm']]
        _science.sources += ['../gerbil-gambit-bootstrap-audit/src/' + path for path in ['std/text/parser/ebnf/lexer.ss', 'std/text/parser/ebnf/stream.ss', 'std/text/parser/ebnf/lang-reader.ss', 'std/text/parser/ebnf/defparser.ss', 'std/text/parser/base.ss', 'gerbil/runtime/error.ss', 'gerbil/runtime/syntax.ss', 'std/db/sqlite.ss']]
        _science.sources += ['vendor/gambit/include/gambit.h.in']
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, f"// Native OwnerNotifierClosure projection.\nmodule owner_notifier_parameters {{\n  pure val OwnerGeneration = {p['ownerGeneration']}\n}}\n")
        lines = ['#+TITLE: Owner Holders, Notifier Closure and Net-Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: owner-notifier-matrix', ':AUTHORITY: OwnerNotifierClosure', ':END:', '', 'Derived from native SysML. Proposed owner/notifier protocol is not current implementation.']
        for name, _, schema in _science.groups:
            fields = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(row[field]) for field in fields)) + ' |' for row in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['# Native SysML holder containment and proof obligations; no runtime ordering implied.', 'direction: down', 'domain: "Owner token coverage / restricted notifier / modern C"', 'holders: "Actual holder shapes to be covered" {', '  grid-columns: 2']
        graph += [f' h{n}: ' + json.dumps(v['key'] + '\n' + v['anchor']) for n, v in enumerate(p['holder'])]
        graph += ['}', 'proof: "NC-H QNT / NC-I Lean; NC-S source / NC-E native"', 'ascent: "ASCENT exact scopes / ancestor RA-S dependencies"', 'gates: "Seven source/native gates remain open"', 'domain -> holders', 'holders -> proof', 'proof -> ascent', 'ascent -> gates']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        cohort = {name: _science.context.output(['git', '-C', path, 'rev-parse', 'HEAD'], cwd=_science.ROOT, text=True, name='source-56').strip() for name, path in [('research', '.'), ('gerbil', '../gerbil-gambit-bootstrap-audit'), ('gambit', 'vendor/gambit')]}
        _science.engine.save(cache / 'source-cohort.json', cohort)
        tests = [(_science.sources[0], '(##will-testator-set! will #f)'), (_science.sources[0], '(action testator)'), (_science.sources[0], '(##declare (interrupts-enabled))'), (_science.sources[0], '(let loop ((lst (macro-fifo->list jobs)))'), (_science.sources[0], '(##execute-jobs! ##gc-interrupt-jobs)'), (_science.sources[1], '(macro-check-will will 1 (will-execute! will)'), (_science.sources[1], '(##will-execute! will))))'), (_science.sources[6], '(lambda (o) (p o) (set! obj9 o))'), (_science.sources[7], '(defstruct token-stream (cs buf Ls Rs $$)'), (_science.sources[8], '(defstruct char-stream (port buf loc lines)'), (_science.sources[12], '(unless (&StackTrace-continuation exn)'), (_science.sources[14], '(make-will driver __sqlite-driver-close)'), (_science.sources[2], '___RETN_GET_FS_LINK_GCMAP(ra1,fs,link,gcmap,nextgcmap)'), (_science.sources[2], 'mark_array (___PSP ___ps->r, sizeof(___ps->r)/sizeof(*___ps->r));'), (_science.sources[-1], '#define ___RETI_GET_FS_LINK_GCMAP')]
        for path, fragment in tests:
            assert fragment in (_science.ROOT / path).read_text(), (path, fragment)
        _science.engine.save(cache / 'source-census.json', dict(checks=[dict(path=p, fragment=f) for p, f in tests], bindings={p: _science.engine.sha(_science.ROOT / p) for p in _science.sources}, holderCoverage='open', closureCallGraph='open', dispatcherRootMap='open', upstreamResurrectionTest='source-read-only'))

    def facts(_science, p, scenario):
        out = [_science.engine.fact('notifierHolderFact', [v[k] for k in ['key', 'anchor', 'actualEdge', 'requiredChange']]) for v in p['holder']]
        for gate in p['gate']:
            qualified = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and gate['key'] == 'callback-frame-exit'))
            out.append(_science.engine.fact('notifierGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
        out.append(_science.engine.fact('notifierSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        c = results['current']
        assert sorted(c['notifierHolder']) == sorted((['current'] + [v[k] for k in ['key', 'anchor', 'actualEdge', 'requiredChange']] for v in p['holder']))
        assert len(c['notifierMissing']) == len(p['gate']) and (not c['notifierCandidate'])
        assert not results['all-scoped-control']['notifierCandidate']
        assert len(results['synthetic-gates']['notifierCandidate']) == 1
        assert not results['missing-release']['notifierCandidate']

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent='stream-release-authority', package='OwnerNotifierClosure', prefix='NC', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/owner_notifier_closure.qnt', lean='models/build/OwnerNotifierClosure.lean', parent_design='dev/architecture/toolchain/stream-release-authority-design.org', parent_matrix='dev/architecture/toolchain/stream-release-authority-matrix.org', groups=_science.groups, scalars=['ownerGeneration', 'actualAdmitted'], histories=27, controls=13, kernels=8, inits=['init', 'initPublic'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='notifierHolder notifierMissing notifierBlocked notifierCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/owner_notifier_closure.qnt', 'models/build/OwnerNotifierClosure.lean', 'src/gambit_smp/scientific_owner_notifier_study.py', 'src/gambit_smp/scientific_formal_study.py'])
        _science.engine.execute(study, resume=args.resume)
