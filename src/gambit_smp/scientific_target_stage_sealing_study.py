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
        _science.stem = 'target-stage-sealing'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/target_sealing_parameters.qnt'
        _science.groups = [('writer', 8, 'key anchor writes owner closure'), ('fidelity', 4, 'key anchor mustPreserve counterexample admission'), ('seal', 4, 'key inputGraph sealCondition consumer cost'), ('gain', 4, 'key avoided added condition'), ('refinement', 4, 'key qntScope leanScope evidenceGap'), ('gate', 7, 'key qualified condition')]
        _science.sources = ['vendor/gambit/gsc/_arm#.scm', 'vendor/gambit/gsc/_arm.scm', 'vendor/gambit/gsc/_asm#.scm', 'vendor/gambit/gsc/_asm.scm', 'vendor/gambit/gsc/_assert#.scm', 'vendor/gambit/gsc/_assert.scm', 'vendor/gambit/gsc/_back.scm', 'vendor/gambit/gsc/_codegen#.scm', 'vendor/gambit/gsc/_codegen.scm', 'vendor/gambit/gsc/_cpuadt.scm', 'vendor/gambit/gsc/_env.scm', 'vendor/gambit/gsc/_envadt.scm', 'vendor/gambit/gsc/_front.scm', 'vendor/gambit/gsc/_gsc.scm', 'vendor/gambit/gsc/_gscdebug.scm', 'vendor/gambit/gsc/_gsclib.scm', 'vendor/gambit/gsc/_gvm.scm', 'vendor/gambit/gsc/_gvmadt.scm', 'vendor/gambit/gsc/_host.scm', 'vendor/gambit/gsc/_parms.scm', 'vendor/gambit/gsc/_prims.scm', 'vendor/gambit/gsc/_ptree1.scm', 'vendor/gambit/gsc/_ptree2.scm', 'vendor/gambit/gsc/_ptreeadt.scm', 'vendor/gambit/gsc/_riscv#.scm', 'vendor/gambit/gsc/_riscv.scm', 'vendor/gambit/gsc/_source.scm', 'vendor/gambit/gsc/_sourceadt.scm', 'vendor/gambit/gsc/_t-c-1.scm', 'vendor/gambit/gsc/_t-c-2.scm', 'vendor/gambit/gsc/_t-c-3.scm', 'vendor/gambit/gsc/_t-cpu-abstract-machine.scm', 'vendor/gambit/gsc/_t-cpu-backend-arm.scm', 'vendor/gambit/gsc/_t-cpu-backend-riscv.scm', 'vendor/gambit/gsc/_t-cpu-backend-x86.scm', 'vendor/gambit/gsc/_t-cpu-object-desc.scm', 'vendor/gambit/gsc/_t-cpu-primitives.scm', 'vendor/gambit/gsc/_t-cpu-utils.scm', 'vendor/gambit/gsc/_t-cpu.scm', 'vendor/gambit/gsc/_t-univ-1.scm', 'vendor/gambit/gsc/_t-univ-2.scm', 'vendor/gambit/gsc/_t-univ-3.scm', 'vendor/gambit/gsc/_t-univ-4.scm', 'vendor/gambit/gsc/_t-x86.scm', 'vendor/gambit/gsc/_univadt.scm', 'vendor/gambit/gsc/_utils.scm', 'vendor/gambit/gsc/_x86#.scm', 'vendor/gambit/gsc/_x86.scm', 'vendor/gambit/gsc/fixnum.scm', 'vendor/gambit/gsc/generic.scm', 'vendor/gambit/gsc/igsc.scm', 'vendor/gambit/gsc/runtests.scm', '../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/base.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/compile.ss', '../gerbil-gambit-bootstrap-audit/src/gerbil/expander/module.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/macros.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/api.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter.ss', '../gerbil-gambit-bootstrap-audit/src/std/string/misc.ss', '../gerbil-gambit-bootstrap-audit/src/std/sync/wg.ss']
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, '// Native SysML projection.\nmodule target_sealing_parameters {\n pure val Capacity = ' + str(p['capacity']) + '\n}\n')
        lines = ['#+TITLE: Target Writers, Stage Sealing and Handoff Net Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: target-sealing-matrix', ':AUTHORITY: TargetStageSealing', ':STATUS: source-platform-refinement-open', ':END:', '', 'Syntactic writer census is not alias/callback closure. All seven admission gates remain open.']
        for name, _, schema in _science.groups:
            fs = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fs)) + ' |' for v in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['direction: down', 'writers: "Target writer owners / census scope and gaps recorded" {', ' grid-columns: 2']
        graph += [' w' + str(i) + ': ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['owner'], 48)) for i, v in enumerate(p['writer'])]
        graph += ['}', 'fidelity: "GeneratedSchemeResult observations" {', ' grid-columns: 2']
        graph += [' f' + str(i) + ': ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['mustPreserve'], 48)) for i, v in enumerate(p['fidelity'])]
        graph += ['}', 'seal: "Two distinct delivery modes / no shared destructive input" {', ' grid-columns: 2']
        graph += [' s' + str(i) + ': ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['sealCondition'], 48)) for i, v in enumerate(p['seal'])]
        graph += ['}', 'proof: "SysML TS-H/I/S/E -> ASCENT -> QNT / Lean; source refinement OPEN"', 'benefit: "Repeated use must repay freezing + private copies + validation + retained memory"', 'writers -> fidelity', 'fidelity -> seal', 'seal -> proof', 'proof -> benefit']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        scopes = ['vendor/gambit/gsc']
        patterns = {'named-stores': '\\(set!\\s+(?:targ-[^\\s()]+|target(?:\\.[^\\s()]+)?|\\*\\*[^\\s()]+)(?:\\s|$)', 'setter-sites': '\\((?:target-[^\\s()]*-set!|proc-obj-[^\\s()]*-set!|c-intf-[^\\s()]*-set!|targ-[^\\s()]*-set!)', 'interior-mutators': '\\((?:table-set!|queue-put!|queue-get!|stretchable-vector-set!|ordered-table[^\\s()]*!|set-car!|set-cdr!|vector-set!)'}
        census = {}
        for key, pattern in patterns.items():
            argv = ['rg', '--json', '--glob', '*.scm', pattern] + scopes
            run = _science.context.process(argv, cwd=_science.ROOT, capture_output=True, text=True, check=True, name='source-54')
            matches = [json.loads(line)['data'] for line in run.stdout.splitlines() if json.loads(line)['type'] == 'match']
            _science.engine.save(cache / (key + '.json'), dict(argv=argv, matches=matches, classification='syntactic-candidates-not-lexical-alias-proof'))
            census[key] = len(matches)
        checks = [('vendor/gambit/gsc/_t-c-1.scm', "(c-intf-decls-set! c-intf '())"), ('vendor/gambit/gsc/_t-c-1.scm', '(define (end!)'), ('vendor/gambit/gsc/_t-c-1.scm', '(close-output-port targ-port)'), ('vendor/gambit/gsc/_prims.scm', '(setup-prim-specializers target)'), ('vendor/gambit/gsc/_t-c-2.scm', '(proc-obj-inlinable?-set! prim'), ('../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss', '(extended-bindings)'), ('../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/compile.ss', '(append decls (current-compile-decls))'), ('../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss', 'Compilation error; process exit with nonzero status')]
        for path, fragment in checks:
            assert fragment in (_science.ROOT / path).read_text(), (path, fragment)
        _science.engine.save(cache / 'source-census.json', dict(counts=census, checks=checks, files={p: _science.engine.sha(_science.ROOT / p) for p in _science.sources}, completeness='all rg matches in recorded corpus; generated setters, shadowing, higher-order and alias reachability unresolved', sourceCohort={k: _science.context.output(['git', '-C', v, 'rev-parse', 'HEAD'], cwd=_science.ROOT, text=True, name='source-68').strip() for k, v in [('research', '.'), ('gambit', 'vendor/gambit'), ('gerbil', '../gerbil-gambit-bootstrap-audit')]}, nativeTests=False, performanceTests=False))
        evidence = _science.ROOT / '.cache/tasks' / _science.stem / 'runs/research'
        for name in ['named-stores.json', 'setter-sites.json', 'interior-mutators.json', 'source-census.json']:
            _study_write_bytes(evidence / name, (cache / name).read_bytes())
        assert (_science.ROOT / 'models/build/TargetStageSealing.lean').read_text().count('theorem ') == 8

    def facts(_science, p, scenario):
        out = [_science.engine.fact('targetWriterFact', [v['key'], v['anchor']]) for v in p['writer']]
        out += [_science.engine.fact('targetRefinementFact', [v['key'], v['qntScope'], v['leanScope']]) for v in p['refinement']]
        for g in p['gate']:
            passed = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and g['key'] == 'graph-seal'))
            out.append(_science.engine.fact('targetGateFact', [scenario, g['key'], str(passed or g['qualified']).lower()]))
        out.append(_science.engine.fact('targetSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        c = results['current']
        assert sorted(c['targetWriter']) == sorted((['current', v['key'], v['anchor']] for v in p['writer']))
        assert sorted(c['targetRefinement']) == sorted((['current', v['key'], v['qntScope'], v['leanScope']] for v in p['refinement']))
        qnt = (_science.ROOT / 'models/build/target_stage_sealing.qnt').read_text()
        lean = (_science.ROOT / 'models/build/TargetStageSealing.lean').read_text()
        for v in p['refinement']:
            assert all(('action ' + n + '=' in qnt or 'action ' + n + '(' in qnt for n in v['qntScope'].split(';')))
            assert all(('theorem ' + n + ' ' in lean for n in v['leanScope'].split(';')))
        assert len(c['targetMissing']) == 7 and (not c['targetCandidate'])
        assert not results['all-scoped-control']['targetCandidate']
        assert len(results['synthetic-gates']['targetCandidate']) == 1
        assert not results['missing-release']['targetCandidate']

    def prepare_base(_science):
        old = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service'
        target = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/target-sealing-base'
        target.mkdir(exist_ok=True)
        original = json.loads((old / 'input.json').read_text())
        selected = {('build-planner', 'IS-S')}
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
        return 'target-sealing-base'

    def local_models(_science, study):
        """Independent rule evaluation, never a replacement for host attestation."""
        import re
        from ascent import Engine
        cache = _science.ROOT / '.cache/tasks' / _science.stem
        evidence = _science.ROOT / '.cache/tasks' / _science.stem / 'runs/research'
        receipt = json.loads((cache / 'formal-receipt.json').read_text())
        assert all((_science.engine.sha(_science.ROOT / p) == h for p, h in receipt['subjects'].items()))
        assert all((_science.engine.sha(cache / p) == h for p, h in receipt['logs'].items()))
        p = json.loads((cache / 'projection.json').read_text())['detail']
        raw = (_science.ROOT / _science.rules).read_text()
        typed = re.sub('\\(relation (\\w+) \\(([^()]*)\\)\\)', lambda m: '(relation ' + m[1] + ' (' + ' '.join(('(' + f + ' string?)' for f in m[2].split())) + '))', raw)
        fragment = '(ascent-fragment (relation scenarioFact ((scenario string?) (role string?)))\n' + typed + ')'
        _study_write_text(cache / 'local-model.fragment.scm', fragment)
        results = {}
        native = Engine()
        try:
            session = native.open_sources(fragment)
            queries = ['targetWriter', 'targetRefinement', 'targetMissing', 'targetBlocked', 'targetCandidate']
            assert session.run(queries=queries)['complete']
            for scenario in ['current', 'synthetic-gates', 'missing-release']:
                inputs = dict(scenarioFact=[[scenario, 'local-model-only']], targetWriterFact=[[v['key'], v['anchor']] for v in p['writer']], targetRefinementFact=[[v['key'], v['qntScope'], v['leanScope']] for v in p['refinement']], targetGateFact=[[scenario, g['key'], str(scenario != 'current' and (not (scenario == 'missing-release' and g['key'] == 'graph-seal'))).lower()] for g in p['gate']], targetSourceFact=[[scenario, str(scenario != 'current').lower()]])
                session.replace(inputs)
                result = session.run(queries=queries)
                assert result['complete']
                results[scenario] = result['relations']
            assert len(results['current']['targetWriter']) == 8 and len(results['current']['targetRefinement']) == 4
            assert len(results['current']['targetMissing']) == 7 and (not results['current']['targetCandidate'])
            assert len(results['synthetic-gates']['targetCandidate']) == 1
            assert not results['missing-release']['targetCandidate']
        finally:
            native.close()
        _science.source_checks(cache)
        ancestor = json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/input.json').read_text())['sourceBindings']
        assert all((_science.engine.sha(_science.ROOT / p) == h for p, h in ancestor.items())), 'Ancestor drift'
        bindings = dict(ancestor)
        for path in study.artifacts + _science.sources:
            bindings[path] = _science.engine.sha(_science.ROOT / path)
        _science.engine.save(cache / 'local-input.json', dict(sourceBindings=bindings, rawOutputRoot=str(cache.relative_to(_science.ROOT)), formalLogBindings={str((cache / p).relative_to(_science.ROOT)): h for p, h in receipt['logs'].items()}, formalReceiptSha256=_science.engine.sha(cache / 'formal-receipt.json'), sysmlSha256=_science.engine.sha(cache / 'projection.json'), rulesSha256=_science.engine.sha(_science.ROOT / _science.rules), fragmentSha256=_science.engine.sha(cache / 'local-model.fragment.scm')))
        _science.engine.save(cache / 'local-inference.json', dict(results=results, hostAttested=False, repositoryRegistered=False))
        checks = dict(status='conditional-local-models-pass-registration-blocked', qntHistories=16, qntNegativeControls=6, sampledRuns=100, maxSteps=80, leanBoundaryLemmas=8, localAscentScenarios=3, sourceRefinement='open', gatesOpen=7, repositoryRegistration='host source attestation mismatch; retained register failure', runtimeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False)
        _science.engine.save(cache / 'local-model-checks.json', checks)
        for path in cache.iterdir():
            if path.is_file() and path.suffix not in {'.png', '.txt', '.log', '.stdout', '.stderr'}:
                _study_write_bytes(evidence / path.name, path.read_bytes())
        _science.engine.save(evidence / 'checks.json', checks)
        _science.engine.save(evidence / 'local-artifacts.json', {str(path.relative_to(_science.ROOT)): _science.engine.sha(path) for path in evidence.iterdir() if path.is_file() and path.name != 'local-artifacts.json'})
        print(json.dumps(checks))

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent=_science.prepare_base(), package='TargetStageSealing', prefix='TS', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/target_stage_sealing.qnt', lean='models/build/TargetStageSealing.lean', parent_design='dev/architecture/toolchain/iter-compiler-service-design.org', parent_matrix='dev/architecture/toolchain/iter-compiler-service-matrix.org', groups=_science.groups, scalars=['capacity', 'actualAdmitted'], histories=16, controls=6, kernels=8, inits=['init'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='targetWriter targetRefinement targetMissing targetBlocked targetCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/target_stage_sealing.qnt', 'models/build/TargetStageSealing.lean', 'src/gambit_smp/scientific_target_stage_sealing_study.py', 'src/gambit_smp/scientific_formal_study.py'])
        if args.local_models:
            _science.local_models(study)
        else:
            _science.engine.execute(study, resume=args.resume)

# Preserved scientific source notes (in original order).
# Raw census publication precedes Org link validation; no pass receipt is issued here.
# Retain every earlier failure. No host-registered current receipt is fabricated.
