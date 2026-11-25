"""Study schema/projection hooks; architecture values come from native SysML."""
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
        _science.stem = 'span-storage-handoff'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/span_storage_parameters.qnt'
        _science.groups = [('contract', 6, 'key anchor rule openDuty'), ('gate', 5, 'key qualified condition'), ('gain', 4, 'key avoided added condition')]
        _science.sources = ['../gerbil-gambit-bootstrap-audit/src/' + path for path in ['std/error.ss', 'gerbil/runtime/error.ss', 'gerbil/runtime/syntax.ss', 'std/text/parser/base.ss', 'std/text/parser/ebnf/lexer.ss', 'std/text/parser/ebnf/deflexer.ss']]
        _science.sources += ['vendor/gambit/lib/_thread.scm', 'vendor/gambit/lib/_io.scm']
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, f"// Native SpanStorageHandoff projection.\nmodule span_storage_parameters {{\n  pure val MaximumResumptions = {p['maximumResumptions']}\n}}\n")
        lines = ['#+TITLE: Span Storage, Multi-shot Custody and Net-Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: span-storage-matrix', ':AUTHORITY: SpanStorageHandoff', ':END:', '', 'Derived by Python from native SysML. No source/native gate is closed by this view.']
        for name, _, schema in _science.groups:
            fields = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(row[field]) for field in fields)) + ' |' for row in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['# Native SysML containment and proof-duty view; not execution ordering.', 'direction: down', 'domain: "SpanStorageHandoff / modern C baseline"', 'contracts: "Storage and control contracts" {', '  grid-columns: 2']
        graph += [f' c{n}: ' + json.dumps(v['key'] + '\n' + v['anchor']) for n, v in enumerate(p['contract'])]
        graph += ['}', 'proof: "SH-H QNT / SH-I Lean; SH-S source / SH-E native"', 'ascent: "ASCENT exact scopes / ancestor RS-S dependencies"', 'gates: "Five qualification gates remain open"', 'domain -> contracts', 'contracts -> proof', 'proof -> ascent', 'ascent -> gates']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        tests = [(_science.sources[0], "#'(deferror-class (Class Error) slots predicate-alias Error:::init!)"), (_science.sources[1], '(defclass (Error StackTrace Exception)'), (_science.sources[1], '(unless (&StackTrace-continuation exn)'), (_science.sources[1], '(lambda (exn) (##continuation-graft cont handler exn))'), (_science.sources[2], '(defclass (SyntaxError Exception StackTrace)'), (_science.sources[3], '(defstruct token (t e loc)'), (_science.sources[3], '(deferror-class ParseError () parse-error?)'), (_science.sources[5], "(action #'(lambda (@@ @loc) $))")]
        for path, fragment in tests:
            assert fragment in (_science.ROOT / path).read_text(), (path, fragment)
        _science.engine.save(cache / 'source-census.json', dict(checks=[dict(path=p, fragment=f) for p, f in tests], bindings={p: _science.engine.sha(_science.ROOT / p) for p in _science.sources}, frameReachability='open', aliasClosure='open'))

    def facts(_science, p, scenario):
        out = [_science.engine.fact('storageContractFact', [v['key'], v['anchor'], v['rule']]) for v in p['contract']]
        for gate in p['gate']:
            qualified = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and gate['key'] == 'reclamation-adapter'))
            out.append(_science.engine.fact('storageGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
        out.append(_science.engine.fact('storageSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        current = results['current']
        assert sorted(current['storageDuty']) == sorted((['current', v['key'], v['anchor'], v['rule']] for v in p['contract']))
        assert len(current['storageMissing']) == len(p['gate']) and (not current['storageCandidate'])
        assert not results['all-scoped-control']['storageCandidate']
        assert len(results['synthetic-gates']['storageCandidate']) == 1
        assert not results['missing-release']['storageCandidate']

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent='reader-span-custody', package='SpanStorageHandoff', prefix='SH', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/span_storage_handoff.qnt', lean='models/build/SpanStorageHandoff.lean', parent_design='dev/architecture/toolchain/reader-span-custody-design.org', parent_matrix='dev/architecture/toolchain/reader-span-custody-matrix.org', groups=_science.groups, scalars=['maximumResumptions', 'actualAdmitted'], histories=21, controls=9, kernels=8, inits=['init', 'initBeforeRead'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='storageDuty storageMissing storageBlocked storageCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/span_storage_handoff.qnt', 'models/build/SpanStorageHandoff.lean', 'src/gambit_smp/scientific_span_storage_study.py', 'src/gambit_smp/scientific_formal_study.py'])
        _science.engine.execute(study, resume=args.resume)
