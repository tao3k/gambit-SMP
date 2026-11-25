"""Source/formal research only. Native SysML owns routing. No native builds."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy
import json
import re
import shutil

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
        _science.ROOT = _science.context.root
        _science.STEM = 'binding-observer-reentry'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitBindingObserverReentry'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def ascend(_science, p, witnesses, inventory, actions, lemmas, parent):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        ws = [[v['key'], v['path'], v['sha256'], v['needle']] for v in witnesses]
        migrations = [[v[k] for k in ['key', 'producerAnchor', 'consumerAnchor', 'actionName', 'lemma']] for v in p['migration']]
        bridges = [['prior-value-algebra', str(parent.relative_to(_science.ROOT)), _science.sha(parent), 'BindingWriterClosure.secondAfterNamedHistory']]
        cases = ['current', 'synthetic-all', 'stale-digest', 'wrong-scope', 'missing-action', 'missing-lemma', 'missing-source', 'missing-migration', 'wrong-producer', 'wrong-inventory', 'wrong-parent']
        results = {}
        engine = _science.h.Engine()
        try:
            ss = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert ss.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, f, d, s] for n, k, f, d, s in needs if case != 'current' or k in ['induction', 'interleaving', 'restricted-projection']]
                if case == 'stale-digest':
                    receipts[0][3] = 'stale'
                if case == 'wrong-scope':
                    receipts[0][4] = 'native-pass'
                mo = copy.deepcopy(migrations)
                if case == 'missing-migration':
                    mo = mo[1:]
                if case == 'wrong-producer':
                    mo[0][1] = 'unknown-producer'
                io = copy.deepcopy(inventory)
                if case == 'wrong-inventory':
                    io[0][2] = '999'
                bo = copy.deepcopy(bridges)
                if case == 'wrong-parent':
                    bo[0][2] = 'stale'
                ss.replace(dict(scenario=[[case]], need=needs, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if case != 'missing-lemma' or v != ['BindingObserver.plainProfilePreserves']], witness=ws, observation=ws[1:] if case == 'missing-source' else ws, compositionNeed=[[v['key'], v['lemma']] for v in p['proof']], refinementNeed=[], targetActionName=[], bridgeNeed=bridges, bridgeObservation=bo, inventoryNeed=inventory, inventoryObservation=io, seamNeed=[], seamObservation=[], migrationNeed=migrations, migrationObservation=mo, spanNeed=[], spanObservation=[], callerNeed=[], callerObservation=[]))
                result = ss.run(queries=['blocked', 'candidate', 'linked', 'compositionLinked', 'observed', 'migrationLinked', 'bridgeLinked', 'inventoryLinked'])
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
            assert {v[1] for v in results['current']['blocked']} == {'BO-source', 'BO-exceptions', 'BO-platform', 'BO-emission'}
            assert [c for c in cases if results[c]['candidate']] == ['synthetic-all']
            assert len(results['current']['linked']) == 29
            assert len(results['current']['observed']) == 40
            assert len(results['current']['migrationLinked']) == 8
            assert len(results['current']['inventoryLinked']) == 4
            assert len(results['current']['bridgeLinked']) == 1
            contractResults = {}
            for row in p['policy']:
                key = row['key']
                ss.replace(dict(profile=[[key]], assumption=[[key, v] for v in row['assumptions'].split(';') if v], writerClass=[[key, row['writerClass']]], canonicalClass=[[v, 'BindingWriterClosure.historyKeepsCanonical'] for v in ['none', 'named-only']], lemmaName=lemmas))
                result = ss.run(queries=['firstRetirable', 'secondValueRetirable'])
                assert result['complete']
                rel = result['relations']
                contractResults[key] = rel
                assert bool(rel['firstRetirable']) == (row['firstExpected'] == 'true')
                assert bool(rel['secondValueRetirable']) == (row['secondExpected'] == 'true')
            _science.save(_study_workspace('CACHE') / 'contract-profiles.json', dict(results=contractResults, assumptionsOnly=True, actualNativeAdmission=False))
        finally:
            engine.close()

    def formal(_science):
        e = _science.context.library('binding_observer_reentry_projection')
        cfg = e.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        _science.context.command('qnt-typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, receipt = e.generate(ir)
        astpath = _science.BASE + 'models/lean/BindingObserverAst.lean'
        _study_write_text(_science.ROOT / astpath, ast)
        _science.save(_study_workspace('CACHE') / 'projection-receipt.json', dict(**receipt, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / astpath)))
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
        proof_names = ['BindingObserverAst', 'BindingObserver', 'BindingWriterClosure']
        formal_paths = [qnt, _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE + 'models/lean/' + n + '.lean' for n in proof_names]
        if '--reuse-formal' in _science.context.arguments:
            cp = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            assert {f: _science.sha(_science.ROOT / f) for f in formal_paths} == cp['sourceBindings']
            assert all((_science.sha(_science.ROOT / f) == d for f, d in cp['logs'].items()))
            lemmas = [[n + '.' + x] for n in proof_names[1:] for x in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
            return ([[cfg['module'] + '.' + a] for a in cfg['actions']], lemmas)
        for name in ['BindingObserverAst', 'BindingObserver', 'BindingWriterClosure']:
            src = _science.ROOT / (_science.BASE + 'models/lean/' + name + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', src.read_text())
            target = _study_workspace('CACHE') / (name + '.lean')
            _study_write_bytes(target, src.read_bytes())
            _science.context.command(name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(target)], policy=_science.process_profile)
        output = _science.context.command('qnt-histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert output.count('ok ') == 20 and output.count('ControlTest passed') == 5
        _science.context.command('qnt-samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '163', '--verbosity', '1'], policy=_science.process_profile)
        neg = _study_workspace('CACHE') / 'negative-error'
        neg.mkdir(exist_ok=True)
        bad = '\n'.join((line.replace('(¬(q.errorSeen=true))', 'True') if line.startswith('def issueGuard') else line for line in ast.splitlines())) + '\n'
        assert bad != ast
        _study_write_text(neg / 'BindingObserverAst.lean', bad)
        _science.context.command('negative-ast', ['lean', '-o', str(neg / 'BindingObserverAst.olean'), str(neg / 'BindingObserverAst.lean')], policy=_science.process_profile)
        try:
            _science.context.command('negative-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/BindingObserver.lean'], policy=_science.process_profile)
        except RuntimeError:
            assert 'error' in (_study_workspace('CACHE') / 'negative-proof.stdout').read_text()
        else:
            raise AssertionError('ignored prior error proved')
        lemmas = [[n + '.' + x] for n in ['BindingObserver', 'BindingWriterClosure'] for x in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sourceBindings={f: _science.sha(_science.ROOT / f) for f in formal_paths}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and f.stem in proof_names + ['qnt-histories', 'qnt-samples', 'negative-ast', 'negative-proof']}))
        return ([[cfg['module'] + '.' + a] for a in cfg['actions']], lemmas)

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/binding-observer-reentry/config.json').read_text())
        snapshots = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for path, v in snapshots.items():
            assert _science.sha(_science.ROOT / path) == _science.sha(_science.ROOT / v['path']) == v['sha256'], path
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/primitive-header-binding/input.json'
        parentHash = _science.sha(parent)
        prior = json.loads(parent.read_text())
        imported = _science.BASE + 'models/lean/PrimitiveBindingAlgebra.lean'
        assert _science.sha(_science.ROOT / imported) == prior['sourceBindings'][imported]
        old = _science.ROOT / '.cache/tasks/primitive-header-binding'
        assert (old / 'PrimitiveBindingAlgebra.lean').read_bytes() == (_science.ROOT / imported).read_bytes()
        for ext in ['lean', 'olean']:
            shutil.copyfile(old / ('PrimitiveBindingAlgebra.' + ext), _study_workspace('CACHE') / ('PrimitiveBindingAlgebra.' + ext))
        adapter = _science.context.library('default_lease_admission_study')
        for k, v in dict(CACHE=_study_workspace('CACHE'), OUT=_study_workspace('OUT'), PKG=_science.PKG, GROUPS=cfg['groups'], SLOTS=cfg['slots']).items():
            setattr(adapter, k, v)
        p, scope = adapter.project()
        view = _science.context.library('copy_producer_envelope_study')
        for k, v in dict(ROOT=_science.ROOT, GROUPS=cfg['groups'], MATRIX=_science.BASE + _science.STEM + '-matrix.org', D2=_science.BASE + 'diagrams/' + _science.STEM + '.d2').items():
            setattr(view, k, v)
        view.views(p)
        matrix = _science.ROOT / (_science.BASE + _science.STEM + '-matrix.org')
        _study_write_text(matrix, matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'Binding Callbacks — Observation and Canonical Writer Closure Matrix').replace('GambitCopyProducerEnvelope', _science.PKG).replace('source-and-C11-open', 'source-exception-C23-platform-open'))
        d2 = _science.ROOT / (_science.BASE + 'diagrams/' + _science.STEM + '.d2')
        _study_write_text(d2, d2.read_text().replace('legal-input and C11 OPEN', 'source / exceptions / C23 qualification OPEN'))
        witnesses = []
        for v in p['source']:
            snap = snapshots[v['path']]
            text = (_science.ROOT / snap['path']).read_text()
            assert v['needle'] in text, v
            witnesses.append(dict(**v, sha256=snap['sha256'], snapshotPath=snap['path'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        inventory = []
        occurrences = []
        for v in p['inventory']:
            snap = snapshots[v['path']]
            text = (_science.ROOT / snap['path']).read_text()
            hits = list(re.finditer(v['pattern'], text))
            assert len(hits) == int(v['count'])
            inventory.append([v['key'], v['path'], str(len(hits)), snap['sha256'], v['scope']])
            definitions = list(re.finditer('^\\(define (?:\\()?([^\\s()]+)', text, re.M))
            for hit in hits:
                owners = [d for d in definitions if d.start() <= hit.start()]
                occurrences.append(dict(key=v['key'], path=v['path'], line=text[:hit.start()].count('\n') + 1, identifier=hit[0], precedingTopLevelDefinition=owners[-1].group(1) if owners else None))
        _science.save(_study_workspace('CACHE') / 'resource-footprint.json', dict(rows=inventory, occurrences=occurrences, scope='lexical source occurrences, includes definitions; indirect alias closure OPEN'))
        actions, lemmas = _science.formal()
        _science.ascend(p, witnesses, inventory, actions, lemmas, parent)
        d2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', d2, d2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', d2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for oldpath, new in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.BASE + _science.STEM + '-design.org'), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.BASE + _science.STEM + '-matrix.org'), ('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')]:
            org = org.replace(oldpath, new)
        org = org.replace("(files '", "(files '")
        org = org.replace('"' + _science.BASE + _science.STEM + '-design.org"', '"' + _science.BASE + _science.STEM + '-design.org" "' + _science.BASE + 'language-baseline-design.org"')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        assert _science.sha(parent) == parentHash
        assert not [f for f, v in snapshots.items() if _science.sha(_science.ROOT / f) != v['sha256']]
        checks = dict(status='conditional-callback-writer-closure-pass', languageBaseline='C23 / ISO IEC 9899:2024', sourceSnapshots=len(snapshots), sourceAnchors=len(witnesses), lexicalFootprints=len(inventory), qntActions=len(actions), qntHistories=20, negativeHistories=5, qntSamples=500, sampleSeed=163, leanTheorems=len(lemmas), allStepInduction=True, projectionNegativeControls=4, leanNegativeControls=1, ascentScenarios=11, migrationLinks=8, contractProfiles=7, canonicalNamedWriterHistoryProved=True, firstNativeRetirement=False, secondNativeRetirement=False, actualCandidate=False, blockers=['BO-source', 'BO-exceptions', 'BO-platform', 'BO-emission'], installedCallbackClosure=False, sourceAliasClosure=False, exceptionPrefixEquivalence=False, c23PlatformQualified=False, fullEmissionFidelity=False, nativeTestsRun=False, performanceTestsRun=False, sourceDrift=[])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        own = [_science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'language-baseline-design.org', _science.BASE + 'index.org', d2, d2[:-3] + '.svg', _science.BASE + 'models/quint/binding_observer_reentry.qnt', 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), imported]
        own += [_science.BASE + 'models/lean/' + n + '.lean' for n in ['BindingObserverAst', 'BindingObserver', 'BindingWriterClosure']]
        own += [_science.context.library_source(n.removesuffix('.py').replace('-', '_')) for n in ['advantage-architecture-study.py', 'default-lease-admission-study.py', 'copy-producer-envelope-study.py', 'chunk-capacity-charge-projection.py']]
        own += [v['path'] for v in snapshots.values()] + [str((_study_workspace('CACHE') / n).relative_to(_science.ROOT)) for n in ['config.json', 'source-snapshots.json']]
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, sourceBindings={f: _science.sha(_science.ROOT / f) for f in own}, sourceSnapshots=snapshots, sysmlInputs=scope, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.context.command('org-check', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        bound = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
        bound['logs'] = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}
        _science.save(_study_workspace('CACHE') / 'input.json', bound)
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        for d in _study_workspace('CACHE').glob('retained-*-failure'):
            shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        neg = _study_workspace('OUT') / 'negative-error'
        neg.mkdir(exist_ok=True)
        shutil.copyfile(_study_workspace('CACHE') / 'negative-error/BindingObserverAst.lean', neg / 'BindingObserverAst.lean')
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Native SysML policy rows describe assumptions, never actual native receipts.
# Removing the sticky-error guard must break the actual inductive proof.
# Include the baseline in the same native Org parse/link check.
