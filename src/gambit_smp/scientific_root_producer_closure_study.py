"""Native SysML projection and bounded formal research; never executes runtime code."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import json, re, shutil

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.ROOT = _science.context.root
        _science.STEM = 'root-producer-closure'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitRootProducerClosure'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.QNT = _science.BASE + 'models/quint/root_producer_closure.qnt'
        _science.LEAN = _science.BASE + 'models/lean/RootProducerClosure.lean'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.GROUPS = [('root', 13, 'key sourcePath needle identity worker condition'), ('flow', 14, 'key sourcePath needle nextNode custody diagramLabel'), ('obligation', 8, 'key status scope'), ('gain', 7, 'key avoided added condition'), ('binding', 3, 'actionName lemma condition'), ('parameter', 5, 'key sourcePath needle value'), ('diagramedge', 4, 'fromNode toNode label')]
        _science.process_profile = _science.h.process_profile

    def project(_science, projection_run=None):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        keys += [('need', n, f, f'{_science.PKG}::{n}.{f}') for n in ['history', 'induction', 'source', 'bridge'] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        p, scope = _study_fields(_science.ROOT, projection_run, 'root-producer-closure', keys)
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', scope)
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        return (p, scope)

    def views(_science, p):
        lines = ['#+TITLE: Physical Root and Producer Closure Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitRootProducerClosure', ':STATUS: conditional-formal-results; source-bridge-open', ':END:']
        for g, _, fields in _science.GROUPS:
            fs = fields.split()
            lines += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((v[f] for f in fs)) + ' |' for v in p[g]]
        lines += ['', '** Proof routing', '', '| ID | kind | subject | scope |', '|---+---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope'])) + ' |' for v in p['need'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down', 'classes: {', '  open: {style.fill: "#fff0dd"}', '}']
        nodes = {v['key'] for v in p['flow']} | {v['nextNode'] for v in p['flow']}
        nodes |= {v['fromNode'] for v in p['diagramedge']} | {v['toNode'] for v in p['diagramedge']}
        for n in sorted(nodes):
            graph.append(json.dumps(n) + ': ' + json.dumps(n))
        for v in p['flow']:
            graph.append(json.dumps(v['key']) + ' -> ' + json.dumps(v['nextNode']) + ': ' + json.dumps(v['diagramLabel']))
        for v in p['diagramedge']:
            graph.append(json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(v['label']))
        graph += ['qualification: "Conditional formal model\nFull source / C11 closure open"'.replace('\n', '\\n')]
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def ascend(_science, p, witness):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        bindings = [[v['actionName'], v['lemma']] for v in p['binding']]
        actions = [[x] for x in re.findall('^ action (\\w+)', (_science.ROOT / _science.QNT).read_text(), re.M)]
        lemmas = [[x] for x in re.findall('^theorem (\\w+)', (_science.ROOT / _science.LEAN).read_text(), re.M)]
        rows = [[v['key'], v['sourcePath'], v['sha256'], v['needle']] for v in witness]
        assert len({v[0] for v in rows}) == len(rows)
        results = {}
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            queries = ['checked', 'blocked', 'candidate', 'linked', 'observed']
            assert session.run(queries=queries)['complete']
            for case in ['current', 'synthetic-all', 'stale-digest', 'wrong-scope', 'missing-source', 'missing-action', 'wrong-lemma', 'missing-witness', 'missing-bridge']:
                receipts = [[case, n, path, d, scope] for n, k, path, d, scope in needs if case != 'current' or k in ['interleaving', 'induction']]
                if case == 'stale-digest':
                    receipts[0][3] = 'stale'
                if case == 'wrong-scope':
                    receipts[0][4] = 'all-runtime-proved'
                if case == 'missing-source':
                    receipts = [v for v in receipts if v[1] != 'RPC-source']
                if case == 'missing-bridge':
                    receipts = [v for v in receipts if v[1] != 'RPC-bridge']
                ac = actions if case != 'missing-action' else [x for x in actions if x != ['claim']]
                ls = lemmas if case != 'wrong-lemma' else [x for x in lemmas if x != ['claimPreserves']]
                session.replace(dict(scenario=[[case]], need=needs, receipt=receipts, binding=bindings, actionName=ac, lemmaName=ls, witness=rows, observation=rows if case != 'missing-witness' else rows[1:]))
                result = session.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', results)
            assert len(results['current']['checked']) == 2 and len(results['current']['linked']) == 3
            assert len(results['synthetic-all']['candidate']) == 1
            for case in results:
                if case != 'synthetic-all':
                    assert not results[case]['candidate'], case
            assert ['current', 'RPC-source'] in results['current']['blocked'] and ['current', 'RPC-bridge'] in results['current']['blocked']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotRealEvidence=True, sourceQualified=False, expressionBridgeQualified=False))

    def analyze(_science, projection_run=None):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/manifest-scan-qualification/input.json'
        parentHash = _science.sha(parent)
        p, scope = _science.project(projection_run)
        _science.views(p)
        witness = []
        for group, v in [(g, v) for g in ['root', 'flow', 'parameter'] for v in p[g]]:
            text = (_science.ROOT / v['sourcePath']).read_text()
            assert v['needle'] in text, v['key']
            witness.append(dict(**{**v, 'key': group + ':' + v['key']}, sha256=_science.sha(_science.ROOT / v['sourcePath']), line=text[:text.index(v['needle'])].count('\n') + 1))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witness)
        census = {v['key']: int(v['value']) for v in p['parameter']}
        fixed = census['registers'] + census['saved'] + census['type-cache'] + 2 + census['processor-body']
        assert fixed == 34 and census['vm-body'] + 3 == 23
        _science.save(_study_workspace('CACHE') / 'root-census.json', dict(templateDefaultContextVisits=fixed, vmAndTablesVisits=census['vm-body'] + 3, formula='34*W+23+G+RC+F+W_break_links', notDistinctObjects=True, includesDerivedGraph=False, effectiveDarwinConfigurationQualified=False, parameters=census))
        _science.context.command('source-mark-array-callers', ['rg', '-n', 'mark_array \\(work|mark_captured_continuation|setup_still_objs_to_scan', 'vendor/gambit/lib/mem.c'], policy=_science.process_profile)
        _science.context.command('frame-and-denv-anchors', ['rg', '-n', '___frame_root_(begin|advance|next_run)|___CONTINUATION_DENV|___THREAD_DENV|___CONTEXT_PROCESSOR_SCMOBJ', 'vendor/gambit/include/gambit.h.in'], policy=_science.process_profile)
        reuse = '--reuse-formal' in _science.context.arguments
        lean = (_science.ROOT / _science.LEAN).read_text()
        if reuse:
            previous = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
            for f in [_science.QNT, _science.LEAN]:
                assert _science.sha(_science.ROOT / f) == previous['sourceBindings'][f], f
            for f, d in previous['logs'].items():
                if any((k in f for k in ['typecheck.', 'quint-tests.', 'quint-samples.', '/lean.', 'negative-lean.'])):
                    assert _science.sha(_science.ROOT / f) == d, f
        else:
            _science.context.command('typecheck', ['quint', 'typecheck', _science.QNT, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
            tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
            assert tests.count('ok ') == 10 and tests.count('ControlTest passed') == 6
            _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '41', '--verbosity', '1'], policy=_science.process_profile)
            lean = (_science.ROOT / _science.LEAN).read_text()
            assert 'sorry' not in lean and 'axiom ' not in lean
            _science.context.command('lean', ['lean', '-o', str(_study_workspace('CACHE') / 'RootProducerClosure.olean'), _science.LEAN], policy=_science.process_profile)
            mutant = lean.replace(' ∧ ¬s.tail=true', '')
            assert mutant != lean
            _study_write_text(_study_workspace('CACHE') / 'WrongIdle.lean', mutant)
            try:
                _science.context.command('negative-lean', ['lean', str(_study_workspace('CACHE') / 'WrongIdle.lean')], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-lean.stdout').read_text()
            else:
                raise AssertionError('Tail guard mutation unexpectedly proved')
        _science.ascend(p, witness)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        for f, d in scope.items():
            assert _science.sha(_science.ROOT / f) == d, f
        for w in witness:
            assert _science.sha(_science.ROOT / w['sourcePath']) == w['sha256']
        assert _science.sha(parent) == parentHash
        files = {_science.MODEL, _science.QNT, _science.LEAN, _science.RULES, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py', 'vendor/gambit/include/gambit.h.in', 'vendor/gambit/lib/mem.c', 'vendor/gambit/lib/setup.c'}
        old = json.loads(parent.read_text())
        drift = [f for f, d in old['sourceBindings'].items() if not (_science.ROOT / f).is_file() or _science.sha(_science.ROOT / f) != d]
        _science.save(_study_workspace('CACHE') / 'predecessor-source-drift.json', dict(parentFrozen=True, changed=drift))
        checks = dict(status='conditional-models-pass', formalChecksReused=reuse, sysmlInputs=len(scope), rootFamilies=13, producerAnchors=14, qntHistories=10, negativeQntControls=6, samples=500, maxSteps=200, leanTheorems=len(re.findall('^theorem ', lean, re.M)), negativeLeanControls=1, ascentScenarios=9, actualCandidate=False, sourceEnumerationQualified=False, qntLeanExtractionQualified=False, c11Refinement=False, wholeGcTerminationProved=False, nativeTestsRun=False, performanceTestsRun=False, runtimeFilesModifiedByStudy=[])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, parentFrozen=True, sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.suffix in ['.json', '.el', '.lean']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
