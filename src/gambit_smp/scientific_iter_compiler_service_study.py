"""Native SysML projection and conditional protocol research; no compiler implementation."""
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import json
import textwrap
from types import SimpleNamespace

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.textwrap = textwrap
        _science.SimpleNamespace = SimpleNamespace
        _science.engine = _science.context.library('formal_study')
        _science.ROOT = _science.context.root
        _science.stem = 'iter-compiler-service'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/iter_compiler_parameters.qnt'
        _science.groups = [('chain', 5, 'key labelText anchor'), ('chainEdge', 4, 'fromKey toKey contract'), ('refinement', 4, 'key qntScope leanScope evidenceGap'), ('seam', 5, 'key owner anchor input completion'), ('context', 5, 'key anchor stateSet isolation retirement'), ('retire', 5, 'key anchor condition removed retained'), ('gain', 4, 'key avoided added condition'), ('gate', 7, 'key qualified condition')]
        _science.sources = ['../gerbil-gambit-bootstrap-audit/src/std/iter.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/api.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/macros.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/interface.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/iterators.ss', '../gerbil-gambit-bootstrap-audit/src/std/interface.ss', '../gerbil-gambit-bootstrap-audit/src/std/list/list-builder.ss', '../gerbil-gambit-bootstrap-audit/src/std/string/misc.ss', '../gerbil-gambit-bootstrap-audit/src/std/sync/wg.ss', '../gerbil-gambit-bootstrap-audit/src/std/make.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/base.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/expander/module.ss', 'vendor/gambit/gsc/_front.scm', 'vendor/gambit/gsc/_env.scm', 'vendor/gambit/gsc/_ptree1.scm', 'vendor/gambit/gsc/_gvm.scm', 'vendor/gambit/gsc/_back.scm', 'vendor/gambit/gsc/_t-c-1.scm', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-src-memo-memo.ml', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-src-memo-exec.ml', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-src-memo-invalidation.ml', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-src-memo-deps.ml', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-src-dune_engine-build_system.ml', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-src-memo-node.ml', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-upstream-commit.json', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-src-memo-deps_collector.ml', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-source-manifest.json', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/dune-src-memo-parallel.ml']
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, '// Native SysML parameter projection.\nmodule iter_compiler_parameters {\n' + f" pure val ConsumerCount = {p['consumerCount']}\n pure val Capacity = {p['capacity']}\n pure val LastStage = {p['lastStage']}\n}}\n")
        lines = ['#+TITLE: Iter Compiler Service Contracts, Retirement and Net Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: iter-service-matrix', ':AUTHORITY: IterCompilerService', ':STATUS: conditional-models-source-refinement-open', ':END:', '', 'Proposed contracts. All source/platform gates stay open; no native performance result.']
        for name, _, schema in _science.groups:
            fs = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fs)) + ' |' for v in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['direction: down', 'chain: "Real iter macro dependency chain / executable closure still under admission" {']
        graph += [v['key'] + ': ' + json.dumps(v['labelText']) for v in p['chain']]
        graph += [v['fromKey'] + ' -> ' + v['toKey'] for v in p['chainEdge']]
        graph += ['}', 'seams: "Proposed typed stage contracts / not current public APIs" {']
        graph += [' s' + str(i) + ': ' + json.dumps(v['key'] + '\n' + v['owner']) for i, v in enumerate(p['seam'])]
        graph += [' s0 -> s1', ' s1 -> s2', ' s2 -> s3', ' s3 -> s4', '}', 'context: "Owned Gambit context / source writer census remains open" {', ' grid-columns: 2']
        graph += [' c' + str(i) + ': ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['stateSet'], 43)) for i, v in enumerate(p['context'])]
        graph += ['}', 'ready: "Gerbil scheduler: binding + executable support + owned fresh instance"', 'drain: "Pause retains roots/context; failure or unknown drains; seal before release"', 'proof: "SysML IS-H/I/S/E -> ASCENT route -> QNT histories / Lean premises"', 'gain: "Benefit: avoided work > added work; removed critical path > added span"', ' chain -> ready', ' ready -> seams', ' seams -> context', ' context -> drain', ' drain -> proof', ' proof -> gain']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        checks = [('../gerbil-gambit-bootstrap-audit/src/std/iter.ss', '(export (import: ./iter/api))'), ('../gerbil-gambit-bootstrap-audit/src/std/iter/api.ss', './macros'), ('../gerbil-gambit-bootstrap-audit/src/std/iter/macros.ss', '(begin-syntax'), ('../gerbil-gambit-bootstrap-audit/src/std/string/misc.ss', '(for (i (in-range start end))'), ('../gerbil-gambit-bootstrap-audit/src/std/sync/wg.ss', '(for (worker wg.workers)'), ('../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss', '(def (compile-scm-file path code (phi? #f))'), ('../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss', '(def (gsc-compile-file path phi?)'), ('vendor/gambit/gsc/_env.scm', '(set! next-var-stamp (make-counter 0))'), ('vendor/gambit/gsc/_gvm.scm', '(set! *opnd-table-alloc* 0)'), ('vendor/gambit/gsc/_back.scm', '(set! target.dump              (target-dump target))')]
        for path, fragment in checks:
            assert fragment in (_science.ROOT / path).read_text(), (path, fragment)
        manifest = json.loads((_science.ROOT / f'evidence/research/{_science.stem}/dune-source-manifest.json').read_text())
        for f in manifest['files']:
            assert _science.engine.sha(_science.ROOT / f'evidence/research/{_science.stem}' / f['local']) == f['sha256']
        cohort = {name: _science.context.output(['git', '-C', path, 'rev-parse', 'HEAD'], cwd=_science.ROOT, text=True, name='source-66').strip() for name, path in [('research', '.'), ('gerbil', '../gerbil-gambit-bootstrap-audit'), ('gambit', 'vendor/gambit')]}
        _science.engine.save(cache / 'source-census.json', dict(checks=checks, duneCommit=manifest['commit'], sourceCohort=cohort, writerClosure='open', stageSimulation='open', nativeTests=False, performanceTests=False))
        assert (_science.ROOT / 'models/build/IterCompilerService.lean').read_text().count('theorem ') == 8

    def facts(_science, p, scenario):
        out = [_science.engine.fact('iterSeamFact', [v['key'], v['owner'], v['anchor']]) for v in p['seam']]
        out += [_science.engine.fact('iterDependencyFact', [v['fromKey'], v['toKey']]) for v in p['chainEdge']]
        out += [_science.engine.fact('iterRefinementFact', [v['key'], v['qntScope'], v['leanScope']]) for v in p['refinement']]
        out += [_science.engine.fact('iterContextFact', [v['key'], v['anchor']]) for v in p['context']]
        for g in p['gate']:
            passed = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and g['key'] == 'context-ownership'))
            out.append(_science.engine.fact('iterGateFact', [scenario, g['key'], str(passed or g['qualified']).lower()]))
        out.append(_science.engine.fact('iterSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        c = results['current']
        assert sorted(c['iterSeam']) == sorted((['current', v['key'], v['owner'], v['anchor']] for v in p['seam']))
        assert sorted(c['iterContext']) == sorted((['current', v['key'], v['anchor']] for v in p['context']))
        assert sorted(c['iterRefinement']) == sorted((['current', v['key'], v['qntScope'], v['leanScope']] for v in p['refinement']))
        qnt = (_science.ROOT / 'models/build/iter_compiler_service.qnt').read_text()
        lean = (_science.ROOT / 'models/build/IterCompilerService.lean').read_text()
        for v in p['refinement']:
            assert all(('action ' + n + ' ' in qnt or 'action ' + n + '(' in qnt or 'def ' + n + '(' in qnt for n in v['qntScope'].split(';')))
            assert all(('theorem ' + n + ' ' in lean for n in v['leanScope'].split(';')))
        assert sorted(c['iterDependency']) == sorted((['current', v['fromKey'], v['toKey']] for v in p['chainEdge']))
        keys = {v['key'] for v in p['chain']}
        assert all((v['fromKey'] in keys and v['toKey'] in keys for v in p['chainEdge']))
        assert len(c['iterMissing']) == 7 and (not c['iterCandidate'])
        assert not results['all-scoped-control']['iterCandidate']
        assert len(results['synthetic-gates']['iterCandidate']) == 1
        assert not results['missing-release']['iterCandidate']

    def prepare_base(_science):
        old = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/incremental-compiler-architecture'
        target = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-service-base'
        target.mkdir(exist_ok=True)
        original = json.loads((old / 'input.json').read_text())
        selected = {('build-planner', 'IC-S')}
        while True:
            added = {(d['prerequisiteComponent'], d['prerequisite']) for d in original['dependencies'] if (d['component'], d['obligation']) in selected}
            if added <= selected:
                break
            selected |= added
        needs = [n for n in original['needs'] if (n['component'], n['obligationId']) in selected]
        deps = [d for d in original['dependencies'] if (d['component'], d['obligation']) in selected]
        p = json.loads((old / 'projection.json').read_text())
        nk = {k for k, v in p['needs'].items() if (v['owner']['componentId'], v['obligationId']) in selected}
        dk = {k for k, v in p['dependencies'].items() if (v['dependent']['owner']['componentId'], v['dependent']['obligationId']) in selected}
        queries = [q for q in json.loads((old / 'native-queries.json').read_text()) if q[0].startswith(('components.', 'methods.')) or (q[0].split('.')[0] == 'needs' and q[0].split('.')[1] in nk) or (q[0].split('.')[0] == 'dependencies' and q[0].split('.')[1] in dk)]
        _science.engine.save(target / 'native-queries.json', queries)
        _science.engine.save(target / 'input.json', dict(original, needs=needs, dependencies=deps))
        current = json.loads((old / 'current.json').read_text())
        current['projectionOnly'] = True
        current['brief']['association']['locallyChecked'] = [v for v in current['brief']['association']['locallyChecked'] if (v[1], v[2]) in selected]
        _science.engine.save(target / 'current.json', current)
        for f in ['planner-policy.ss', 'check-org.el']:
            _study_write_bytes(target / f, (old / f).read_bytes())
        _science.engine.save(target / 'selection.json', dict(projectionOnly=True, sourceInputSha256=_science.engine.sha(old / 'input.json'), selected=sorted(selected)))
        return 'iter-service-base'

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent=_science.prepare_base(), package='IterCompilerService', prefix='IS', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/iter_compiler_service.qnt', lean='models/build/IterCompilerService.lean', parent_design='dev/architecture/toolchain/incremental-compiler-architecture-design.org', parent_matrix='dev/architecture/toolchain/incremental-compiler-architecture-matrix.org', groups=_science.groups, scalars=['consumerCount', 'capacity', 'lastStage', 'actualAdmitted'], histories=18, controls=6, kernels=8, inits=['init'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='iterDependency iterRefinement iterSeam iterContext iterMissing iterBlocked iterCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/iter_compiler_service.qnt', 'models/build/IterCompilerService.lean', 'src/gambit_smp/scientific_iter_compiler_service_study.py', 'src/gambit_smp/scientific_formal_study.py'])
        _science.engine.execute(study, resume=args.resume)
