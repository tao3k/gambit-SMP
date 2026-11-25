"""Formal research pipeline only; native SysML, ASCENT, QNT and Lean."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy, json, re, shutil, textwrap

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.textwrap = textwrap
        _science.ROOT = _science.context.root
        _science.STEM = 'frame-chunk-weak-producers'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitFrameChunkWeakProducers'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.QNT = _science.BASE + 'models/quint/frame_chunk_coverage.qnt'
        _science.LEAN = _science.BASE + 'models/lean/ChunkCoverage.lean'
        _science.AST = _science.BASE + 'models/lean/ChunkCoverageAst.lean'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.EMITTER = _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_'))
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.GROUPS = [['source', 33, 'key path needle obligation'], ['mapping', 8, 'key formula premise gap'], ['producer', 24, 'key caller callee family phase gate custody'], ['contract', 20, 'fromNode toNode custody'], ['obligation', 11, 'key status scope gap'], ['gain', 8, 'key avoided added condition'], ['binding', 29, 'actionName lemma scope'], ['composition', 14, 'key lemma scope'], ['seam', 4, 'producer.moduleId consumer.moduleId contract modelNeed']]
        _science.process_profile = _science.h.process_profile

    def project(_science):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        keys += [('need', n, f, f'{_science.PKG}::{n}.{f}') for n in ['frameHistory', 'weakHistory', 'frameInduction', 'weakInduction', 'projection', 'source', 'platform'] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope', 'owner.componentId']]
        scope = {p: _science.sha(_science.ROOT / p) for p in sorted(_science.context.command('sysml-inputs', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())}
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', scope)
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'frame-chunk-weak-producers', field_expressions, ordered=True, models=['dev'])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        for g, _, _ in _science.GROUPS:
            p[g] = list(p[g].values())
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        return (p, scope)

    def views(_science, p):

        def cell(v):
            return str(v).replace('\n', '\\n').replace('|', '\\vert{}')
        lines = ['#+TITLE: Physical Frame Coverage and Weak Producer Admission — Closure and Net Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitFrameChunkWeakProducers', ':STATUS: conditional-model-induction; source-schedule-and-c11-open', ':END:']
        for g, _, fields in _science.GROUPS:
            fs = fields.split()
            lines += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((cell(v[f]) for f in fs)) + ' |' for v in p[g]]
        lines += ['', '** Proof routing', '', '| ID | kind | subject | scope |', '|---+---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope'])) + ' |' for v in p['need'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        width = None
        for line in lines:
            if not line.startswith('|'):
                width = None
                continue
            if set(line) <= set('|-+ '):
                continue
            n = len(line.split('|'))
            if width is None:
                width = n
            assert n == width, line
        _science.save(_study_workspace('CACHE') / 'org-table-columns.json', dict(status='pass', embeddedNewlinesEscaped=True, pipeEntitiesEscaped=True))
        graph = ['direction: down']
        nodes = {v[f] for v in p['contract'] for f in ['fromNode', 'toNode']}
        for n in sorted(nodes):
            graph.append(json.dumps(n) + ': ' + json.dumps(n))
        for v in p['contract']:
            graph.append(json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 22)))
        graph += ['qualification: "Conditional model induction\\nNative allocation / phase / C11 open"']
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def projection(_science):
        emitter = _science.context.library('frame_chunk_weak_producers_projection')
        receipts = {}
        for cfg in emitter.SPECS:
            ir = json.loads((_study_workspace('CACHE') / (cfg['module'] + '.json')).read_text())
            ast, receipt = emitter.generate(ir, cfg['module'], cfg['fields'], cfg['actions'], cfg['namespace'])
            path = _science.BASE + 'models/lean/' + cfg['namespace'] + '.lean'
            _study_write_text(_science.ROOT / path, ast)
            receipts[cfg['module']] = dict(**receipt, typedIrSha256=_science.sha(_study_workspace('CACHE') / (cfg['module'] + '.json')), astSha256=_science.sha(_science.ROOT / path), sourceSimulation=False)
            controls = {}
            for case in ['wrong-state-binding', 'wrong-field-kind', 'missing-step', 'unsupported-expression']:
                bad = copy.deepcopy(ir)
                defs = {d['name']: d for d in bad['modules'][0]['declarations']}
                if case == 'wrong-state-binding':
                    bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
                if case == 'wrong-field-kind':
                    field = defs['State']['type']['fields']['fields'][0]['fieldType']
                    field['kind'] = 'int' if field['kind'] == 'bool' else 'bool'
                if case == 'missing-step':
                    defs['step']['expr']['args'].pop(0)
                if case == 'unsupported-expression':
                    defs['safe']['expr']['opcode'] = 'unsupported'
                try:
                    emitter.generate(bad, cfg['module'], cfg['fields'], cfg['actions'], cfg['namespace'])
                except (AssertionError, KeyError):
                    controls[case] = 'rejected'
                else:
                    raise AssertionError('accepted ' + case)
            _science.save(_study_workspace('CACHE') / (cfg['module'] + '-projection-controls.json'), controls)
        _science.save(_study_workspace('CACHE') / 'expression-projection.json', receipts)
        return emitter

    def ascend(_science, p, witness, emitter):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        bindings = [[v['actionName'], v['lemma']] for v in p['binding']]
        actions = []
        lemmas = []
        for cfg in emitter.SPECS:
            ir = json.loads((_study_workspace('CACHE') / (cfg['module'] + '.json')).read_text())
            actions += [[cfg['module'] + '.' + d['name']] for d in ir['modules'][0]['declarations'] if d.get('qualifier') == 'action']
            proof = (_science.ROOT / (_science.BASE + 'models/lean/' + cfg['proof'] + '.lean')).read_text()
            assert 'namespace ' + cfg['proof'] in proof
            lemmas += [[cfg['proof'] + '.' + x] for x in re.findall('^\\s*theorem (\\w+)', proof, re.M)]
        rows = [[v['key'], v['path'], v['sha256'], v['needle']] for v in witness]
        assert len({x[0] for x in rows}) == len(rows)
        calls = _science.audit_calls(p)
        routes = [[v['caller'], v['callee']] for v in p['producer']]
        results = {}
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            queries = ['checked', 'blocked', 'candidate', 'linked', 'observed', 'compositionLinked', 'coveredCall']
            assert session.run(queries=queries)['complete']
            for case in ['current', 'synthetic-all', 'stale-digest', 'wrong-scope', 'missing-source', 'missing-action', 'wrong-lemma', 'missing-witness', 'missing-projection', 'missing-c11', 'missing-induction', 'missing-route', 'missing-frame-route']:
                receipts = [[case, n, path, d, scope] for n, k, path, d, scope in needs if case != 'current' or k in ['interleaving', 'induction', 'restricted-projection']]
                if case == 'stale-digest':
                    receipts[0][3] = 'stale'
                if case == 'wrong-scope':
                    receipts[0][4] = 'native-all-paths-closed'
                for label, need in [('missing-source', 'PW-source'), ('missing-projection', 'PW-projection'), ('missing-c11', 'PW-platform')]:
                    if case == label:
                        receipts = [v for v in receipts if v[1] != need]
                ac = [x for x in actions if case != 'missing-action' or x != ['weak_producer_admission.openWeak']]
                ls = [x for x in lemmas if (case != 'wrong-lemma' or x != ['WeakAdmission.openWeakPreserves']) and (case != 'missing-induction' or x != ['ChunkCoverage.mixedChunkLinkCovered'])]
                session.replace(dict(scenario=[[case]], need=needs, receipt=receipts, binding=bindings, actionName=ac, lemmaName=ls, witness=rows, observation=rows if case != 'missing-witness' else rows[1:], compositionNeed=[[v['key'], v['lemma']] for v in p['composition']], sourceCall=calls, callRoute=[v for v in routes if (case != 'missing-route' or v != ['scan', 'mark_array']) and (case != 'missing-frame-route' or v != ['scan', 'mark_frame'])]))
                result = session.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', results)
            assert len(results['current']['checked']) == 5 and len(results['current']['linked']) == 29 and (len(results['current']['compositionLinked']) == 14)
            assert len(results['current']['coveredCall']) == len(calls)
            assert len(results['missing-frame-route']['coveredCall']) == len(calls) - 1
            assert len(results['synthetic-all']['candidate']) == 1
            for case in results:
                if case != 'synthetic-all':
                    assert not results[case]['candidate'], case
            assert ['current', 'PW-source'] in results['current']['blocked'] and ['current', 'PW-platform'] in results['current']['blocked']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotRealEvidence=True, sourceQualified=False, c11Qualified=False))

    def audit_calls(_science, p):
        text = (_science.ROOT / 'vendor/gambit/lib/mem.c').read_text()
        lines = text.splitlines()
        owner = None
        rows = []
        for lineNo, line in enumerate(lines, 1):
            decl = re.match('^___HIDDEN\\s+(?:void|___SIZE_TS|int|___BOOL)\\s+(\\w+)', line)
            if decl:
                owner = decl.group(1)
            if line.lstrip().startswith(('#', '___HIDDEN', '/*', '*', '//')):
                continue
            for hit in re.finditer('\\b(mark_array|mark_frame|mark_captured_continuation)\\s*\\(', line):
                assert owner, (lineNo, line)
                rows.append([str(lineNo), owner, hit.group(1), _science.sha(_science.ROOT / 'vendor/gambit/lib/mem.c')])
        _science.save(_study_workspace('CACHE') / 'direct-mark-call-inventory.json', dict(scope='Lexical direct marking calls in mem.c; no preprocessing or external callback proof', rows=rows))
        return rows

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/chain-seal-will-cut/input.json'
        parentHash = _science.sha(parent)
        baseline = json.loads((_study_workspace('CACHE') / 'reviewed-runtime-inputs.json').read_text())
        for f, d in baseline.items():
            assert _science.sha(_science.ROOT / f) == d, f
        p, scope = _science.project()
        _science.views(p)
        witness = []
        for v in p['source']:
            text = (_science.ROOT / v['path']).read_text()
            assert v['needle'] in text, v['key']
            witness.append(dict(**v, sha256=_science.sha(_science.ROOT / v['path']), line=text[:text.index(v['needle'])].count('\n') + 1))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witness)
        _science.context.command('frame-and-weak-callers', ['rg', '-n', 'mark_captured_continuation|publish_object_scan|process_wills|UNMARKED_TESTATOR_WILL|process_gc_hash_tables|scan_ptr =', 'vendor/gambit/lib/mem.c'], policy=_science.process_profile)
        emitter = _science.context.library('frame_chunk_weak_producers_projection')
        reuse = '--reuse-formal' in _science.context.arguments
        formalFiles = [_science.EMITTER] + [_science.BASE + 'models/' + suffix for cfg in emitter.SPECS for suffix in ['quint/' + cfg['module'] + '.qnt', 'lean/' + cfg['namespace'] + '.lean', 'lean/' + cfg['proof'] + '.lean']]
        if reuse:
            old = json.loads((_study_workspace('CACHE') / ('input.json' if (_study_workspace('CACHE') / 'input.json').exists() else 'formal-checkpoint.json')).read_text())
            for f in formalFiles:
                assert _science.sha(_science.ROOT / f) == old['sourceBindings'][f], f
            for f, d in old['logs'].items():
                if any((k in f for k in ['quint-', 'typecheck', 'ChunkCoverage', 'WeakAdmission', 'negative-lean'])):
                    assert _science.sha(_science.ROOT / f) == d, f
        else:
            for cfg in emitter.SPECS:
                _science.context.command(cfg['module'] + '-typecheck', ['quint', 'typecheck', _science.BASE + 'models/quint/' + cfg['module'] + '.qnt', '--out', str(_study_workspace('CACHE') / (cfg['module'] + '.json'))], policy=_science.process_profile)
        emitter = _science.projection()
        if not reuse:
            for cfg, n, neg in zip(emitter.SPECS, [7, 8], [4, 5], strict=True):
                qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
                tests = _science.context.command(cfg['module'] + '-quint-tests', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
                assert tests.count('ok ') == n and tests.count('ControlTest passed') == neg
                _science.context.command(cfg['module'] + '-quint-samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '41', '--verbosity', '1'], policy=_science.process_profile)
                for name in [cfg['namespace'], cfg['proof']]:
                    src = _study_workspace('CACHE') / (name + '.lean')
                    _study_write_bytes(src, (_science.ROOT / (_science.BASE + 'models/lean/' + name + '.lean')).read_bytes())
                    assert 'sorry' not in src.read_text() and 'axiom ' not in src.read_text()
                    _science.context.command(name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(src)], policy=_science.process_profile)
                negdir = _study_workspace('CACHE') / ('negative-' + cfg['proof'])
                negdir.mkdir(exist_ok=True)
                ast = (_science.ROOT / (_science.BASE + 'models/lean/' + cfg['namespace'] + '.lean')).read_text()
                if cfg['proof'] == 'ChunkCoverage':
                    mutant = '\n'.join((line.replace('custody:=(1)', 'custody:=(1),bseal:=false') if line.startswith('def publishChunkNext') else line for line in ast.splitlines())) + '\n'
                else:
                    mutant = '\n'.join((line.replace('phase:=(2)', 'phase:=(2),db:=false') if line.startswith('def openWeakNext') else line for line in ast.splitlines())) + '\n'
                assert mutant != ast
                _study_write_text(negdir / (cfg['namespace'] + '.lean'), mutant)
                _science.context.command('negative-lean-' + cfg['proof'] + '-ast', ['lean', '-o', str(negdir / (cfg['namespace'] + '.olean')), str(negdir / (cfg['namespace'] + '.lean'))], policy=_science.process_profile)
                try:
                    _science.context.command('negative-lean-' + cfg['proof'] + '-proof', ['env', 'LEAN_PATH=' + str(negdir) + ':' + str(_study_workspace('CACHE')), 'lean', str(_science.ROOT / (_science.BASE + 'models/lean/' + cfg['proof'] + '.lean'))], policy=_science.process_profile)
                except RuntimeError:
                    assert 'error:' in (_study_workspace('CACHE') / ('negative-lean-' + cfg['proof'] + '-proof.stdout')).read_text()
                else:
                    raise AssertionError('negative mutation proved ' + cfg['proof'])
        _science.ascend(p, witness, emitter)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        for f, d in scope.items():
            assert _science.sha(_science.ROOT / f) == d, f
        for w in witness:
            assert _science.sha(_science.ROOT / w['path']) == w['sha256'], w['path']
        for f, d in baseline.items():
            assert _science.sha(_science.ROOT / f) == d, f
        assert _science.sha(parent) == parentHash
        files = {_science.MODEL, _science.RULES, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.EMITTER, _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py'} | set(formalFiles) | {w['path'] for w in witness}
        old = json.loads(parent.read_text())
        _science.save(_study_workspace('CACHE') / 'predecessor-source-drift.json', dict(parentInputSha256=parentHash, parentFrozen=True, changed=[f for f, d in old['sourceBindings'].items() if not (_science.ROOT / f).is_file() or _science.sha(_science.ROOT / f) != d]))
        theoremCount = sum((len(re.findall('^\\s*theorem ', (_science.ROOT / (_science.BASE + 'models/lean/' + cfg['proof'] + '.lean')).read_text(), re.M)) for cfg in emitter.SPECS))
        checks = dict(status='conditional-model-induction-pass', formalChecksReused=reuse, sysmlInputs=len(scope), sourceAnchors=33, qntActions=29, qntHistories=15, negativeQntControls=9, samplesPerModel=500, maxSteps=200, leanTheorems=theoremCount, allStepInduction=True, negativeLeanControls=2, projectionNegativeControls=8, ascentScenarios=13, formalBindings=29, formalCompositionBindings=14, legacySourceSchedule='enabled-under-explicit-premises', actualCandidate=False, sourceQualified=False, c11Refinement=False, parserVerified=False, emitterVerified=False, fullFrameChainRefinement=False, mixedSpanArithmeticProved=True, producerCutModelProved=True, allNativeWeakProducersProved=False, crossModelSourceCompositionProved=False, taskRetryDeduplicationProved=False, sharedSentinelC11Proved=False, fullHashCleanupRefinement=False, nativeTestsRun=False, performanceTestsRun=False, runtimeFilesModifiedByStudy=[])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, parentFrozen=True, sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.el', '.lean']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
