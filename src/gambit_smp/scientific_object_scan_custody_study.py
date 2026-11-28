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
        _science.STEM = 'object-scan-custody'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitObjectScanCustody'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.QNT = _science.BASE + 'models/quint/object_scan_custody.qnt'
        _science.LEAN = _science.BASE + 'models/lean/ObjectScanCustody.lean'
        _science.AST = _science.BASE + 'models/lean/ObjectScanAst.lean'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.EMITTER = _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_'))
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.GROUPS = [('source', 19, 'key path needle obligation'), ('contract', 14, 'fromNode toNode custody c11 premise'), ('obligation', 9, 'key status scope'), ('gain', 7, 'key avoided added condition'), ('binding', 20, 'actionName lemma scope'), ('composition', 3, 'key lemma scope'), ('seam', 4, 'producer.moduleId consumer.moduleId contract modelNeed')]
        _science.process_profile = _science.h.process_profile

    def project(_science):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        keys += [('need', n, f, f'{_science.PKG}::{n}.{f}') for n in ['history', 'induction', 'projection', 'source', 'platform'] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        scope = {p: _science.sha(_science.ROOT / p) for p in sorted(_science.context.command('sysml-inputs', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())}
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', scope)
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'object-scan-custody', field_expressions, ordered=True, models=['dev'])
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
        lines = ['#+TITLE: Object Scan Custody — Closure and Net Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitObjectScanCustody', ':STATUS: abstract-induction-closed; source-and-c11-open', ':END:']
        for g, _, fields in _science.GROUPS:
            fs = fields.split()
            lines += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((v[f] for f in fs)) + ' |' for v in p[g]]
        lines += ['', '** Proof routing', '', '| ID | kind | subject | scope |', '|---+---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope'])) + ' |' for v in p['need'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down']
        nodes = {v[f] for v in p['contract'] for f in ['fromNode', 'toNode']}
        for n in sorted(nodes):
            graph.append(json.dumps(n) + ': ' + json.dumps(n))
        for v in p['contract']:
            graph.append(json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 22)))
        graph += ['qualification: "Abstract induction closed\\nFrame fixups / C11 / epochs open"']
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def projection(_science):
        emitter = _science.context.library('object_scan_custody_projection')
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, receipt = emitter.generate(ir)
        _study_write_text(_science.ROOT / _science.AST, ast)
        _science.save(_study_workspace('CACHE') / 'expression-projection.json', dict(**receipt, typedIrSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / _science.AST), sourceSimulation=False))
        controls = {}
        for case in ['wrong-state-binding', 'wrong-field-kind', 'missing-step', 'unsupported-expression']:
            bad = copy.deepcopy(ir)
            ds = bad['modules'][0]['declarations']
            defs = {d['name']: d for d in ds}
            if case == 'wrong-state-binding':
                bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
            if case == 'wrong-field-kind':
                defs['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if case == 'missing-step':
                defs['step']['expr']['args'].pop(0)
            if case == 'unsupported-expression':
                defs['safe']['expr']['opcode'] = 'unsupported'
            try:
                emitter.generate(bad)
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError('accepted ' + case)
        _science.save(_study_workspace('CACHE') / 'projection-negative-controls.json', controls)
        return (emitter, ast)

    def ascend(_science, p, witness):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        bindings = [[v['actionName'], v['lemma']] for v in p['binding']]
        actions = [[x] for x in re.findall('^ action (\\w+)', (_science.ROOT / _science.QNT).read_text(), re.M)]
        lemmas = [[x] for x in re.findall('^theorem (\\w+)', (_science.ROOT / _science.LEAN).read_text(), re.M)]
        rows = [[v['key'], v['path'], v['sha256'], v['needle']] for v in witness]
        assert len({x[0] for x in rows}) == len(rows)
        results = {}
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            queries = ['checked', 'blocked', 'candidate', 'linked', 'observed', 'compositionLinked']
            assert session.run(queries=queries)['complete']
            for case in ['current', 'synthetic-all', 'stale-digest', 'wrong-scope', 'missing-source', 'missing-action', 'wrong-lemma', 'missing-witness', 'missing-projection', 'missing-c11', 'missing-induction']:
                receipts = [[case, n, path, d, scope] for n, k, path, d, scope in needs if case != 'current' or k in ['interleaving', 'induction', 'restricted-projection']]
                if case == 'stale-digest':
                    receipts[0][3] = 'stale'
                if case == 'wrong-scope':
                    receipts[0][4] = 'all-native-termination'
                for label, need in [('missing-source', 'OSC-source'), ('missing-projection', 'OSC-projection'), ('missing-c11', 'OSC-platform')]:
                    if case == label:
                        receipts = [v for v in receipts if v[1] != need]
                ac = [x for x in actions if case != 'missing-action' or x != ['own1']]
                ls = [x for x in lemmas if (case != 'wrong-lemma' or x != ['own1Preserves']) and (case != 'missing-induction' or x != ['reachableSafe'])]
                session.replace(dict(scenario=[[case]], need=needs, receipt=receipts, binding=bindings, actionName=ac, lemmaName=ls, witness=rows, observation=rows if case != 'missing-witness' else rows[1:], compositionNeed=[[v['key'], v['lemma']] for v in p['composition']]))
                result = session.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', results)
            assert len(results['current']['checked']) == 3 and len(results['current']['linked']) == 20 and (len(results['current']['compositionLinked']) == 3)
            assert len(results['synthetic-all']['candidate']) == 1
            for case in results:
                if case != 'synthetic-all':
                    assert not results[case]['candidate'], case
            assert ['current', 'OSC-source'] in results['current']['blocked'] and ['current', 'OSC-platform'] in results['current']['blocked']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotRealEvidence=True, sourceQualified=False, c11Qualified=False))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/root-producer-closure/input.json'
        parentHash = _science.sha(parent)
        p, scope = _science.project()
        _science.views(p)
        witness = []
        for v in p['source']:
            text = (_science.ROOT / v['path']).read_text()
            assert v['needle'] in text, v['key']
            witness.append(dict(**v, sha256=_science.sha(_science.ROOT / v['path']), line=text[:text.index(v['needle'])].count('\n') + 1))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witness)
        _science.context.command('publisher-callers', ['rg', '-n', 'publish_object_scan|GC_SCAN_|scan_workers_count|scan_and_advance', 'vendor/gambit/lib/mem.c'], policy=_science.process_profile)
        _science.context.command('atomics-and-trailer', ['rg', '-n', '___COMPARE_AND_SWAP_WORD|msection_scan_words|sizeof_msection', 'vendor/gambit/include/gambit.h.in'], policy=_science.process_profile)
        reuse = '--reuse-formal' in _science.context.arguments
        if reuse:
            old = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
            for f in [_science.QNT, _science.LEAN, _science.AST, _science.EMITTER]:
                assert _science.sha(_science.ROOT / f) == old['sourceBindings'][f], f
            for f, d in old['logs'].items():
                if any((k in f for k in ['quint-', 'typecheck.', 'ObjectScan', 'negative-lean'])):
                    assert _science.sha(_science.ROOT / f) == d, f
        else:
            _science.context.command('typecheck', ['quint', 'typecheck', _science.QNT, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        emitter, ast = _science.projection()
        if not reuse:
            tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
            assert tests.count('ok ') == 12 and tests.count('ControlTest passed') == 7
            _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '1000', '--max-steps', '200', '--seed', '41', '--verbosity', '1'], policy=_science.process_profile)
            for name, path in [('ObjectScanAst', _science.AST), ('ObjectScanCustody', _science.LEAN)]:
                src = _study_workspace('CACHE') / (name + '.lean')
                _study_write_bytes(src, (_science.ROOT / path).read_bytes())
                assert 'sorry' not in src.read_text() and 'axiom ' not in src.read_text()
                _science.context.command(name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(src)], policy=_science.process_profile)
            neg = _study_workspace('CACHE') / 'negative'
            neg.mkdir(exist_ok=True)
            mutant = '\n'.join((line.replace('(¬(q.child1=true))', 'True') if line.startswith('def idle1Guard') else line for line in ast.splitlines())) + '\n'
            assert mutant != ast
            _study_write_text(neg / 'ObjectScanAst.lean', mutant)
            _science.context.command('negative-lean-ast', ['lean', '-o', str(neg / 'ObjectScanAst.olean'), str(neg / 'ObjectScanAst.lean')], policy=_science.process_profile)
            try:
                _science.context.command('negative-lean-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', str(_science.ROOT / _science.LEAN)], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-lean-proof.stdout').read_text()
            else:
                raise AssertionError('missing child debt guard was proved')
        _science.ascend(p, witness)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        for f, d in scope.items():
            assert _science.sha(_science.ROOT / f) == d, f
        for w in witness:
            assert _science.sha(_science.ROOT / w['path']) == w['sha256'], w['path']
        assert _science.sha(parent) == parentHash
        files = {_science.MODEL, _science.QNT, _science.LEAN, _science.AST, _science.RULES, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.EMITTER, _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py'} | {w['path'] for w in witness}
        lean = (_science.ROOT / _science.LEAN).read_text()
        old = json.loads(parent.read_text())
        _science.save(_study_workspace('CACHE') / 'predecessor-source-drift.json', dict(parentInputSha256=parentHash, parentFrozen=True, changed=[f for f, d in old['sourceBindings'].items() if not (_science.ROOT / f).is_file() or _science.sha(_science.ROOT / f) != d]))
        checks = dict(status='abstract-model-induction-pass', formalChecksReused=reuse, sysmlInputs=len(scope), sourceAnchors=19, qntActions=len(emitter.ACTIONS), qntHistories=12, negativeQntControls=7, samples=1000, maxSteps=200, leanTheorems=len(re.findall('^theorem ', lean, re.M)), allStepInduction=True, negativeLeanControls=1, projectionNegativeControls=4, ascentScenarios=11, actualCandidate=False, sourceQualified=False, c11Refinement=False, parserVerified=False, emitterVerified=False, arbitraryTaskRefinement=False, epochRefinement=False, phaseFootprintRefinement=False, frameFixupRefinement=False, nativeTestsRun=False, performanceTestsRun=False, runtimeFilesModifiedByStudy=[])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, parentFrozen=True, sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.el', '.lean']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
