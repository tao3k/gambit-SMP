"""Native SysML + source/formal research. Never builds or runs Gambit."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy, json, re, shutil
from pathlib import Path

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
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.STEM = 'frame-seal-root-scope'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitFrameSealRootScope'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.EMITTER = _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_'))
        _science.GROUPS = [['source', 32, 'key path needle obligation'], ['alias', 8, 'key writer custody gap'], ['claim', 5, 'key mechanism condition result gap'], ['memory', 5, 'key publication consumer gap'], ['gain', 6, 'key avoided added condition'], ['contract', 12, 'fromNode toNode custody'], ['binding', 20, 'actionName lemma scope'], ['proof', 11, 'key lemma'], ['seam', 3, 'producer.componentId consumer.componentId contract actionName lemma']]
        _science.SLOTS = ['history', 'induction', 'composition', 'projection', 'source', 'platform']
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/copy-producer-envelope/input.json'
        parentDigest = _science.sha(parent)
        snapshots = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for v in snapshots.values():
            assert _science.sha(_science.ROOT / v['path']) == v['sha256']
        adapter = _science.context.library('default_lease_admission_study')
        for k, v in dict(CACHE=_study_workspace('CACHE'), OUT=_study_workspace('OUT'), PKG=_science.PKG, GROUPS=_science.GROUPS, SLOTS=_science.SLOTS).items():
            setattr(adapter, k, v)
        p, scope = adapter.project()
        view = _science.context.library('copy_producer_envelope_study')
        for k, v in dict(ROOT=_science.ROOT, GROUPS=_science.GROUPS, MATRIX=_science.MATRIX, D2=_science.D2).items():
            setattr(view, k, v)
        view.views(p)
        f = _science.ROOT / _science.MATRIX
        _study_write_text(f, f.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'Private Frame Plan and Resize Root Scope Matrix').replace('GambitCopyProducerEnvelope', _science.PKG))
        witnesses = []
        for v in p['source']:
            snap = snapshots[v['path']]
            text = (_science.ROOT / snap['path']).read_text()
            assert v['needle'] in text, v['key']
            witnesses.append(dict(**v, snapshotPath=snap['path'], sha256=snap['sha256'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('OUT') / 'source-witnesses.json', witnesses)
        inventories = []
        for key, path, pattern, count in [('source-thunk-stores', 'vendor/gambit/lib/setup.c', 'source->thunk\\s*=(?!=)', 2), ('ledger-thunk-stores', 'vendor/gambit/lib/setup.c', 'r->thunk\\s*=(?!=)', 2), ('setup-source-store', 'vendor/gambit/lib/setup.c', '___vms->resize_requests\\[i\\]\\.thunk\\s*=(?!=)', 1), ('setup-ledger-store', 'vendor/gambit/lib/setup.c', '___vms->resize\\.thunk\\s*=(?!=)', 1), ('return-wrappers', 'vendor/gambit/gsc/_t-c-2.scm', "\\(targ-make-frame-spec '(?:normal|task|internal)", 3), ('label-payload-replacements', 'vendor/gambit/gsc/_t-c-2.scm', '\\(vector-set! lbl-struct [23] ', 2)]:
            snapshot = snapshots[path]
            text = (_science.ROOT / snapshot['path']).read_text()
            hits = list(re.finditer(pattern, text))
            assert len(hits) == count, key
            inventories.append(dict(key=key, path=path, sha256=snapshot['sha256'], count=count, lines=[text[:h.start()].count('\n') + 1 for h in hits], scope='Bounded lexical aliases only; no preprocessor or whole-program alias proof'))
        _science.save(_study_workspace('OUT') / 'writer-inventory.json', inventories)
        emitter = _science.context.library('frame_seal_root_scope_projection')
        cfg = emitter.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        _science.context.command('qnt-typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / (cfg['module'] + '.json'))], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / (cfg['module'] + '.json')).read_text())
        ast, rc = emitter.generate(ir)
        _study_write_text(_science.ROOT / (_science.BASE + 'models/lean/FrameSealRootAst.lean'), ast)
        _science.save(_study_workspace('CACHE') / 'projection-receipt.json', dict(**rc, irSha256=_science.sha(_study_workspace('CACHE') / (cfg['module'] + '.json')), astSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/FrameSealRootAst.lean'))))
        controls = {}
        for case in ['wrong-state-binding', 'wrong-field-kind', 'missing-step', 'unsupported-expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if case == 'wrong-state-binding':
                bad['table'][str(rc['stateReferences'][0][0])]['id'] = -1
            if case == 'wrong-field-kind':
                ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if case == 'missing-step':
                ds['step']['expr']['args'].pop(0)
            if case == 'unsupported-expression':
                ds['safe']['expr']['opcode'] = 'unsupported'
            try:
                emitter.generate(bad)
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError(case)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        prior = json.loads(parent.read_text())
        oldCache = _science.ROOT / '.cache/tasks/copy-producer-envelope'
        imported = []
        for f, d in prior['sourceBindings'].items():
            if '/models/lean/' not in f:
                continue
            assert _science.sha(_science.ROOT / f) == d, f
            n = Path(f).name
            cached = oldCache / n
            obj = cached.with_suffix('.olean')
            assert cached.read_bytes() == (_science.ROOT / f).read_bytes() and obj.is_file(), n
            shutil.copyfile(cached, _study_workspace('CACHE') / n)
            shutil.copyfile(obj, _study_workspace('CACHE') / obj.name)
            imported.append(f)
        _science.save(_study_workspace('CACHE') / 'imported-proof-bindings.json', {f: _science.sha(_science.ROOT / f) for f in imported})
        for n in ['FrameSealRootAst', 'FrameSealRoot', 'FrameRootComposition']:
            original = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', original.read_text())
            f = _study_workspace('CACHE') / (n + '.lean')
            _study_write_bytes(f, original.read_bytes())
            _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(f)], policy=_science.process_profile)
        tests = _science.context.command('qnt-histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 13 and tests.count('ControlTest passed') == 5
        _science.context.command('qnt-samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '107', '--verbosity', '1'], policy=_science.process_profile)
        neg = _study_workspace('CACHE') / 'negative-issue'
        neg.mkdir(exist_ok=True)
        bad = '\n'.join((l.replace('(q.covered=true)', 'True') if l.startswith('def issueGuard') else l for l in ast.splitlines())) + '\n'
        assert bad != ast
        _study_write_text(neg / 'FrameSealRootAst.lean', bad)
        _science.context.command('negative-ast', ['lean', '-o', str(neg / 'FrameSealRootAst.olean'), str(neg / 'FrameSealRootAst.lean')], policy=_science.process_profile)
        try:
            _science.context.command('negative-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/FrameSealRoot.lean'], policy=_science.process_profile)
        except RuntimeError:
            assert 'error' in (_study_workspace('CACHE') / 'negative-proof.stdout').read_text()
        else:
            raise AssertionError('mutant proof accepted')
        actions = [['frame_seal_root_scope.' + a] for a in cfg['actions']]
        lemmas = [[n + '.' + v] for n in ['FrameSealRoot', 'FrameRootComposition'] for v in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        ws = [[v['key'], v['path'], v['sha256'], v['needle']] for v in witnesses]
        bridges = [['source-cover-parent', str(parent.relative_to(_science.ROOT)), parentDigest, 'FrameRootComposition.sourceBudgetFromReceipt']]
        cases = ['current', 'synthetic-all', 'stale-digest', 'wrong-scope', 'missing-action', 'missing-proof', 'missing-anchor', 'wrong-parent', 'missing-seam']
        seams = [[v[f] for f in ['producer.componentId', 'consumer.componentId', 'contract', 'actionName', 'lemma']] for v in p['seam']]
        results = {}
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, f, d, s] for n, k, f, d, s in needs if case != 'current' or k in ['induction', 'interleaving', 'restricted-projection']]
                if case == 'stale-digest':
                    receipts[0][3] = 'stale'
                if case == 'wrong-scope':
                    receipts[0][4] = 'native-pass'
                bridge = copy.deepcopy(bridges)
                if case == 'wrong-parent':
                    bridge[0][2] = 'stale'
                session.replace(dict(scenario=[[case]], need=needs, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if case != 'missing-proof' or v != ['FrameRootComposition.sourceBudgetFromReceipt']], witness=ws, observation=ws[1:] if case == 'missing-anchor' else ws, compositionNeed=[[v['key'], v['lemma']] for v in p['proof']], refinementNeed=[], targetActionName=[], bridgeNeed=bridges, bridgeObservation=bridge, inventoryNeed=[], inventoryObservation=[], seamNeed=seams, seamObservation=seams[1:] if case == 'missing-seam' else seams))
                result = session.run(queries=['blocked', 'candidate', 'linked', 'compositionLinked', 'observed', 'bridgeLinked', 'seamLinked'])
                assert result['complete']
                results[case] = result['relations']
            assert {v[1] for v in results['current']['blocked']} == {'FS-source', 'FS-platform'}
            assert [len(results['current'][k]) for k in ['linked', 'compositionLinked', 'observed', 'bridgeLinked']] == [20, 11, 32, 1]
            assert len(results['current']['seamLinked']) == 3
            assert [c for c in cases if results[c]['candidate']] == ['synthetic-all']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(status='conditional-formal-pass', sourceSnapshots=len(snapshots), sourceAnchors=len(witnesses), qntActions=len(actions), qntHistories=13, negativeHistories=5, samples=500, sampleSeed=107, leanTheorems=len(lemmas), allStepInduction=True, priorSourceCoverComposition=True, projectionControls=len(controls), negativeLeanControls=1, ascentScenarios=len(cases), actualCandidate=False, sourceAliasClosure=False, allOriginProductRefinement=False, nativeC11Refinement=False, totalFallbackProved=False, nativeTestsRun=False, performanceTestsRun=False, liveSourceDrift=[f for f, v in snapshots.items() if _science.sha(_science.ROOT / f) != v['sha256']])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        own = [_science.MODEL, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.RULES, _science.EMITTER, _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), qnt] + [_science.BASE + 'models/lean/' + n + '.lean' for n in ['FrameSealRootAst', 'FrameSealRoot', 'FrameRootComposition']]
        own += imported + [v['path'] for v in snapshots.values()]
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentDigest, sourceBindings={f: _science.sha(_science.ROOT / f) for f in own}, sourceSnapshots=snapshots, sysmlInputs=scope, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Bounded lexical inventory, including every direct assignment under the known aliases.
