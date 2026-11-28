"""Source/formal research only; no native Gambit execution or runtime mutation."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy
import json
import re
import shutil
import textwrap

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.textwrap = textwrap
        _science.ROOT = _science.context.root
        _science.STEM = 'continuation-restore-admission'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.EMITTER = _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_'))
        _science.GROUPS = [['source', 22, 'key path needle obligation'], ['claim', 5, 'key mechanism condition result gap'], ['memory', 5, 'key publication consumer gap'], ['gain', 5, 'key avoided added condition'], ['contract', 12, 'fromNode toNode custody'], ['binding', 14, 'actionName lemma scope'], ['proof', 13, 'key lemma']]
        _science.SLOTS = ['history', 'induction', 'composition', 'projection', 'source', 'platform']
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def project(_science):
        p = _science.context.library('default_lease_admission_study')
        for k, v in dict(CACHE=_study_workspace('CACHE'), OUT=_study_workspace('OUT'), PKG='GambitContinuationRestoreAdmission', GROUPS=_science.GROUPS, SLOTS=_science.SLOTS).items():
            setattr(p, k, v)
        return p.project()

    def views(_science, p):
        lines = ['#+TITLE: Continuation Restore Admission — Evidence and Net Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitContinuationRestoreAdmission', ':STATUS: conditional-model; source-and-C11-open', ':END:']
        for g, _, schema in _science.GROUPS:
            fs = schema.split()
            lines += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]).replace('|', '\\vert{}').replace('\n', '\\n') for f in fs)) + ' |' for v in p[g]]
        lines += ['', '** Model routing', '', '| ID | kind | path | scope |', '|---+---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope'])) + ' |' for v in p['need'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down']
        for n in sorted({v[f] for v in p['contract'] for f in ['fromNode', 'toNode']}):
            graph += [json.dumps(n) + ': ' + json.dumps(n)]
        graph += [json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 27)) for v in p['contract']]
        graph += ['proof: ' + json.dumps('SysML -> ASCENT -> actual QNT / Lean\nConditional model; legal-input and C11 OPEN')]
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def formals(_science):
        e = _science.context.library('continuation_restore_admission_projection')
        cfg = e.SPEC
        ir = json.loads((_study_workspace('CACHE') / 'continuation_restore_plan.json').read_text())
        ast, receipt = e.generate(ir)
        assert ast == (_science.ROOT / (_science.BASE + 'models/lean/ContinuationRestoreAst.lean')).read_text()
        _science.save(_study_workspace('CACHE') / 'projection-receipt.json', dict(**receipt, typedIrSha256=_science.sha(_study_workspace('CACHE') / 'continuation_restore_plan.json'), astSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/ContinuationRestoreAst.lean'))))
        controls = {}
        for case in ['wrong-state-binding', 'wrong-field-kind', 'missing-step', 'unsupported-expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if case == 'wrong-state-binding':
                bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
            if case == 'wrong-field-kind':
                ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if case == 'missing-step':
                ds['step']['expr']['args'].pop(0)
            if case == 'unsupported-expression':
                ds['safe']['expr']['opcode'] = 'unsupported'
            try:
                e.generate(bad)
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError(case)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        if '--reuse-formal' in _science.context.arguments:
            cp = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            for f, d in cp['sourceBindings'].items():
                assert _science.sha(_science.ROOT / f) == d, f
            for f, d in cp['logs'].items():
                assert _science.sha(_science.ROOT / f) == d, f
            actions = [['continuation_restore_plan.' + a] for a in cfg['actions']]
            lemmas = [[n + '.' + v] for n in ['ContinuationRestore', 'RestoreAdmissionComposition'] for v in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
            return (actions, lemmas)
        parent = json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/default-lease-admission/input.json').read_text())
        names = ['ContinuationRestoreAst', 'ContinuationRestore', 'CapacityCollectiveAst', 'CapacityCollective', 'RestoreAdmissionComposition']
        for n in names:
            orig = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
            f = _study_workspace('CACHE') / (n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', orig.read_text())
            if n.startswith('CapacityCollective'):
                assert _science.sha(orig) == parent['sourceBindings'][str(orig.relative_to(_science.ROOT))]
            if '--reuse-compiled' in _science.context.arguments:
                assert f.read_bytes() == orig.read_bytes() and (_study_workspace('CACHE') / (n + '.olean')).is_file() and ('error:' not in (_study_workspace('CACHE') / (n + '.stdout')).read_text()), n
            else:
                _study_write_bytes(f, orig.read_bytes())
                _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(f)], policy=_science.process_profile)
        test = _science.context.command('planner-histories', ['quint', 'test', _science.BASE + 'models/quint/continuation_restore_plan.qnt', '--match', 'Test$'], policy=_science.process_profile)
        assert test.count('ok ') == 10 and test.count('ControlTest passed') == 4
        _science.context.command('planner-samples', ['quint', 'run', _science.BASE + 'models/quint/continuation_restore_plan.qnt', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '103', '--verbosity', '1'], policy=_science.process_profile)
        neg = _study_workspace('CACHE') / 'negative-share'
        neg.mkdir(exist_ok=True)
        bad = '\n'.join((l.replace('(20)', '(64)') if l.startswith('def share1Guard') else l for l in ast.splitlines())) + '\n'
        assert bad != ast
        f = neg / 'ContinuationRestoreAst.lean'
        _study_write_text(f, bad)
        _science.context.command('negative-share-ast', ['lean', '-o', str(neg / 'ContinuationRestoreAst.olean'), str(f)], policy=_science.process_profile)
        try:
            _science.context.command('negative-share-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/ContinuationRestore.lean'], policy=_science.process_profile)
        except RuntimeError:
            assert 'error:' in (_study_workspace('CACHE') / 'negative-share-proof.stdout').read_text()
        else:
            raise AssertionError('mutant proved')
        neg = _study_workspace('CACHE') / 'negative-publication'
        neg.mkdir(exist_ok=True)
        orig = (_science.ROOT / (_science.BASE + 'models/lean/RestoreAdmissionComposition.lean')).read_text()
        bad = orig.replace('(d.poolReady=true → p.outcome=1)', '(d.poolReady=true → p.outcome=2)')
        assert bad != orig
        f = neg / 'RestoreAdmissionComposition.lean'
        _study_write_text(f, bad)
        try:
            _science.context.command('negative-publication-proof', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', str(f)], policy=_science.process_profile)
        except RuntimeError:
            assert re.search('\\berror(?:\\([^)]*\\))?:', (_study_workspace('CACHE') / 'negative-publication-proof.stdout').read_text())
        else:
            raise AssertionError('bad gate proved')
        actions = [['continuation_restore_plan.' + a] for a in cfg['actions']]
        lemmas = [[n + '.' + v] for n in ['ContinuationRestore', 'RestoreAdmissionComposition'] for v in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        return (actions, lemmas)

    def ascend(_science, p, w, actions, lemmas):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        bindings = [[v['actionName'], v['lemma']] for v in p['binding']]
        proofs = [[v['key'], v['lemma']] for v in p['proof']]
        witnesses = [[v['key'], v['path'], v['sha256'], v['needle']] for v in w]
        cases = ['current', 'synthetic-all', 'stale-hash', 'wrong-scope', 'missing-action', 'missing-geometry', 'missing-source', 'missing-platform', 'missing-witness', 'wrong-collective-digest']
        parentPath = '.cache/research/legacy-evidence/evidence/research/default-lease-admission/input.json'
        bridges = [['prior-collective', parentPath, _science.sha(_science.ROOT / parentPath), 'RestoreAdmissionComposition.collectivePreserves']]
        engine = _science.h.Engine()
        results = {}
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, f, d, s] for n, k, f, d, s in needs if case != 'current' or k in ['induction', 'interleaving', 'restricted-projection']]
                if case == 'stale-hash':
                    receipts[0][3] = 'stale'
                if case == 'wrong-scope':
                    receipts[0][4] = 'native-pass'
                if case in ['missing-source', 'missing-platform']:
                    receipts = [r for r in receipts if r[1] != 'CR-' + case.removeprefix('missing-')]
                observedBridge = copy.deepcopy(bridges)
                if case == 'wrong-collective-digest':
                    observedBridge[0][2] = 'stale'
                session.replace(dict(scenario=[[case]], need=needs, receipt=receipts, binding=bindings, actionName=[a for a in actions if case != 'missing-action' or a != ['continuation_restore_plan.share1']], lemmaName=[v for v in lemmas if case != 'missing-geometry' or v != ['RestoreAdmissionComposition.actualWriteSeparation']], witness=witnesses, observation=witnesses[1:] if case == 'missing-witness' else witnesses, compositionNeed=proofs, refinementNeed=[], targetActionName=[], bridgeNeed=bridges, bridgeObservation=observedBridge))
                result = session.run(queries=['checked', 'blocked', 'candidate', 'linked', 'compositionLinked', 'observed', 'bridgeLinked'])
                assert result['complete']
                results[case] = result['relations']
            assert {r[1] for r in results['current']['blocked']} == {'CR-source', 'CR-platform'}
            assert [len(results['current'][k]) for k in ['linked', 'compositionLinked', 'observed', 'bridgeLinked']] == [14, 13, 22, 1]
            assert [c for c in cases if results[c]['candidate']] == ['synthetic-all']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/default-lease-admission/input.json'
        parentHash = _science.sha(parent)
        snapshots = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for v in snapshots.values():
            assert _science.sha(_science.ROOT / v['path']) == v['sha256']
        p, scope = _science.project()
        _science.views(p)
        w = []
        for v in p['source']:
            s = snapshots[v['path']]
            t = (_science.ROOT / s['path']).read_text()
            assert v['needle'] in t, v['key']
            w.append(dict(**v, snapshotPath=s['path'], sha256=s['sha256'], lines=[t[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), t)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', w)
        _science.save(_study_workspace('OUT') / 'source-witnesses.json', w)
        actions, lemmas = _science.formals()
        _science.ascend(p, w, actions, lemmas)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        org = org.replace('(missing nil))', '(missing nil) (external-missing nil))')
        org = org.replace('(unless (file-exists-p target) (push (list file target) missing))', '(unless (file-exists-p target) (if (and (string-suffix-p "/index.org" file) (not (string-match-p "continuation[-_]restore[-_]admission\\\\|ContinuationRestore\\\\|RestoreAdmission" target))) (push (list file target) external-missing) (push (list file target) missing)))')
        org = org.replace('missing=%S; no Babel executed" (length files) links missing', 'missing=%S; concurrent-index-missing=%S; no Babel executed" (length files) links missing external-missing')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        assert _science.sha(parent) == parentHash
        checks = dict(status='conditional-restore-plan-model-pass', sourceAnchors=len(w), qntModels=1, qntActions=len(actions), qntHistories=10, negativeHistories=4, samples=500, leanTheorems=len(lemmas), allStepInduction=True, priorCollectiveComposition=True, projectionControls=4, negativeLeanControls=2, ascentScenarios=10, actualCandidate=False, legalSchemeQuarterBound=False, legalSchemeCounterexample=False, sourceProvenanceComplete=False, nativeC11Refinement=False, globalCopyCapacityProved=False, nativeTestsRun=False, performanceTestsRun=False, liveSourceDrift=[f for f, v in snapshots.items() if _science.sha(_science.ROOT / f) != v['sha256']], sysmlScopeDrift=[f for f, d in scope.items() if _science.sha(_science.ROOT / f) != d])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        files = {_science.MODEL, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.RULES, _science.EMITTER, _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_default_lease_admission_study.py', 'src/gambit_smp/scientific_advantage_architecture_study.py', 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.BASE + 'models/quint/continuation_restore_plan.qnt'} | {_science.BASE + 'models/lean/' + n + '.lean' for n in ['ContinuationRestoreAst', 'ContinuationRestore', 'RestoreAdmissionComposition', 'CapacityCollectiveAst', 'CapacityCollective']} | {v['path'] for v in snapshots.values()}
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, sourceSnapshots=snapshots, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for name in ['checks.json', 'input.json']:
            shutil.copyfile(_study_workspace('CACHE') / name, _study_workspace('OUT') / name)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        identity = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
        identity['logs'] = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}
        _science.save(_study_workspace('CACHE') / 'input.json', identity)
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.el', '.lean']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name not in ['artifacts.json', 'final-audit.json']})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# The preceding native SysML query adapter preserves independent model failures.
