"""Source/formal evidence only. Native SysML owns research routing. No native tests."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy, json, re, shutil

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
        _science.STEM = 'callback-carry-closure'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitCallbackCarryClosure'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def formal(_science):
        e = _science.context.library('callback_carry_closure_projection')
        cfg = e.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        _science.context.command('typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, rc = e.generate(ir)
        path = _science.BASE + 'models/lean/CallbackCarryAst.lean'
        _study_write_text(_science.ROOT / path, ast)
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**rc, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / path), scope='restricted typed IR; JSON parser and projection trusted; C23 source simulation open'))
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
                e.generate(bad)
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError(case)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        for n in ['CallbackCarryAst', 'CallbackCarry']:
            src = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', src.read_text())
            target = _study_workspace('CACHE') / (n + '.lean')
            _study_write_bytes(target, src.read_bytes())
            _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(target)], policy=_science.process_profile)
        tests = _science.context.command('histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 7
        _science.context.command('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '223', '--verbosity', '1'], policy=_science.process_profile)
        neg = _study_workspace('CACHE') / 'negative-release'
        neg.mkdir(exist_ok=True)
        bad = '\n'.join((line.replace('(q.closed=true)', 'True').replace('(q.mapped=true)', 'True').replace('(q.roots=(0))', 'True').replace('(q.active=(0))', 'True') if line.startswith('def releaseGuard') else line for line in ast.splitlines())) + '\n'
        assert bad != ast
        _study_write_text(neg / 'CallbackCarryAst.lean', bad)
        _science.context.command('negative-ast', ['lean', '-o', str(neg / 'CallbackCarryAst.olean'), str(neg / 'CallbackCarryAst.lean')], policy=_science.process_profile)
        try:
            _science.context.command('negative-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/CallbackCarry.lean'], policy=_science.process_profile)
        except RuntimeError:
            assert 'error:' in (_study_workspace('CACHE') / 'negative-proof.stdout').read_text()
        else:
            raise AssertionError('weak release guard accepted')
        lemmas = [['CallbackCarry.' + n] for n in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/CallbackCarry.lean')).read_text(), re.M)]
        return ([[cfg['module'] + '.' + n] for n in cfg['actions']], lemmas)

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/callback-carry-closure/config.json').read_text())
        snap = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for f, v in snap.items():
            assert _science.sha(_science.ROOT / f) == _science.sha(_science.ROOT / v['path']) == v['sha256'], f
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/emission-pipe-refinement/input.json'
        parentHash = _science.sha(parent)
        adapter = _science.context.library('default_lease_admission_study')
        for k, v in dict(CACHE=_study_workspace('CACHE'), OUT=_study_workspace('OUT'), PKG=_science.PKG, GROUPS=cfg['groups'], SLOTS=cfg['slots']).items():
            setattr(adapter, k, v)
        p, scope = adapter.project()
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        view = _science.context.library('copy_producer_envelope_study')
        for k, v in dict(ROOT=_science.ROOT, GROUPS=cfg['groups'], MATRIX=_science.BASE + _science.STEM + '-matrix.org', D2=_science.BASE + 'diagrams/' + _science.STEM + '.d2').items():
            setattr(view, k, v)
        view.views(p)
        matrix = _science.ROOT / (_science.BASE + _science.STEM + '-matrix.org')
        _study_write_text(matrix, matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'Callback Authority, Carry-over and Root Custody Matrix').replace('GambitCopyProducerEnvelope', _science.PKG).replace('source-and-C11-open', 'source-root-exception-C23-platform-open'))
        d2 = _science.ROOT / (_science.BASE + 'diagrams/' + _science.STEM + '.d2')
        _study_write_text(d2, d2.read_text().replace('legal-input and C11 OPEN', 'source / roots / exceptions / C23 OPEN'))
        witnesses = []
        for v in p['source']:
            text = (_science.ROOT / snap[v['path']]['path']).read_text()
            assert v['needle'] in text, v
            witnesses.append(dict(**v, sha256=snap[v['path']]['sha256'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        io = (_science.ROOT / snap['vendor/gambit/lib/_io.scm']['path']).read_text()
        slices = []
        for name, end, guard in [('##char-ready?1', '##char-ready?0', '(##fx< char-rlo char-rhi)'), ('##peek-char1', '##peek-char0', '(##fx< char-rlo char-rhi)'), ('##read-char1', '##read-char1?', '(##fx< char-rlo char-rhi)'), ('##read-substring', 'read-substring', '(##fx< 0 chars-buffered)')]:
            start = io.index('(define-prim (' + name + ' ' if name != '##read-substring' else '(define-prim (##read-substring\n')
            stop = io.index('(define-prim (' + end, start + 1)
            text = io[start:stop]
            call = '((macro-character-port-rbuf-fill port)'
            assert text.count(call) == 1 and guard in text
            slices.append(dict(caller=name, startLine=io[:start].count('\n') + 1, endLine=io[:stop].count('\n') + 1, guard=guard, call=call, digest=snap['vendor/gambit/lib/_io.scm']['sha256']))
        assert io.count('((macro-character-port-rbuf-fill port)') == 4
        _science.save(_study_workspace('CACHE') / 'reader-caller-slices.json', dict(slices=slices, scope='four direct lexical character callers; valid index and no hidden mutation premises remain open'))
        inventoryFiles = sorted(set((_science.ROOT / 'vendor/gambit/gsc').glob('*.scm')) | set((_science.ROOT / 'vendor/gambit/lib').glob('*.scm')))
        inventoryInputs = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in inventoryFiles}
        matches = []
        tokens = ['(##wr-set!', '(##add-gc-interrupt-job!', '(##clear-gc-interrupt-jobs!', '(##port-io-exception-handler-set!', '(port-io-exception-handler-set!', '(##primordial-exception-handler-hook-set!']
        for f in inventoryFiles:
            for lineNo, line in enumerate(f.read_text().splitlines(), 1):
                for token in tokens:
                    if token in line:
                        matches.append(dict(path=str(f.relative_to(_science.ROOT)), line=lineNo, token=token, text=line.strip(), comment=line.lstrip().startswith(';'), definition='define-prim' in line or '(define (' in line))
        _science.save(_study_workspace('CACHE') / 'registration-inventory.json', dict(inputs=inventoryInputs, matches=matches, scope='direct lexical tokens in immediate gsc/lib Scheme files; comments and definitions classified; nested libraries, aliases, native stores and loaded user code not closed'))
        actions, lemmas = _science.formal()
        for v in p['proof']:
            assert [v['lemma']] in lemmas, v
        needs = [[v[k] for k in ['obligationId', 'kind', 'subjectPath']] + [_science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        sources = [[v[k] for k in ['key', 'path', 'sha256', 'needle']] for v in witnesses]
        callbacks = [[v[k] for k in ['key', 'registrant', 'closure', 'authority', 'status']] for v in p['callback']]
        results = {}
        cases = ['current', 'synthetic-all', 'stale-source', 'missing-action', 'missing-lemma', 'wrong-callback', 'missing-formal', 'wrong-scope']
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, path, digest, sc] for n, k, path, digest, sc in needs if case != 'current' or n == 'CC-formal']
                if case == 'missing-formal':
                    receipts = [v for v in receipts if v[1] != 'CC-formal']
                if case == 'wrong-scope':
                    receipts[0][-1] = 'native-performance'
                obs = copy.deepcopy(sources)
                if case == 'stale-source':
                    obs[0][2] = 'stale'
                cb = copy.deepcopy(callbacks)
                if case == 'wrong-callback':
                    cb[0][3] = 'effect-free-without-proof'
                session.replace(dict(scenario=[[case]], need=needs, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if case != 'missing-lemma' or v != ['CallbackCarry.beginLegalPreserves']], sourceNeed=sources, sourceObservation=obs, callbackNeed=callbacks, callbackObservation=cb))
                r = session.run(queries=['blocked', 'candidate', 'linked', 'sourceLinked', 'callbackLinked'])
                assert r['complete']
                results[case] = r['relations']
        finally:
            engine.close()
        assert [k for k in cases if results[k]['candidate']] == ['synthetic-all']
        gaps = sorted((v[1] for v in results['current']['blocked']))
        assert len(gaps) == 6, gaps
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT))], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(status='conditional-formal-pass-actual-retirement-denied', languageBaseline='C23', sourceSnapshots=len(snap), sourceAnchors=len(witnesses), directReaderSlices=len(slices), callbackClasses=len(callbacks), qntActions=len(actions), qntHistories=7, qntSamples=500, seed=223, leanTheorems=len(lemmas), allStepInduction=True, typedIrControls=4, negativeReleaseControl=True, ascentScenarios=len(cases), actualCandidate=False, firstNativeRetirement=False, secondNativeRetirement=False, legalPublicCarryWitness=False, compiledRootMapQualified=False, blockers=gaps, nativeTestsRun=False, performanceTestsRun=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for old, new in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.BASE + _science.STEM + '-design.org'), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.BASE + _science.STEM + '-matrix.org'), ('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')]:
            org = org.replace(old, new)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        for f, v in snap.items():
            assert _science.sha(_science.ROOT / f) == v['sha256'], f
        assert _science.sha(parent) == parentHash
        for f, digest in inventoryInputs.items():
            assert _science.sha(_science.ROOT / f) == digest, ('inventory drift', f)
        for f, digest in scope.items():
            assert _science.sha(_science.ROOT / f) == digest, ('sysml drift', f)
        own = [_science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + 'models/quint/callback_carry_closure.qnt', _science.BASE + 'models/lean/CallbackCarryAst.lean', _science.BASE + 'models/lean/CallbackCarry.lean', _science.BASE + 'index.org', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT)), 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', 'src/gambit_smp/scientific_default_lease_admission_study.py', 'src/gambit_smp/scientific_copy_producer_envelope_study.py', 'src/gambit_smp/scientific_advantage_architecture_study.py', str((_study_workspace('CACHE') / 'config.json').relative_to(_science.ROOT)), str((_study_workspace('CACHE') / 'source-snapshots.json').relative_to(_science.ROOT))] + [v['path'] for v in snap.values()]
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), parentPath=str(parent.relative_to(_science.ROOT)), parentInputSha256=parentHash, sourceBindings={f: _science.sha(_science.ROOT / f) for f in own}, sourceSnapshots=snap, sysmlInputs=scope, lexicalInputs=inventoryInputs))

        def copy_receipts():
            for f in _study_workspace('CACHE').iterdir():
                if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                    shutil.copyfile(f, _study_workspace('OUT') / f.name)
        copy_receipts()
        _science.context.command('org-check', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        data = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
        data['logs'] = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}
        _science.save(_study_workspace('CACHE') / 'input.json', data)
        copy_receipts()
        shutil.copytree(_study_workspace('CACHE') / 'negative-release', _study_workspace('OUT') / 'negative-release', dirs_exist_ok=True)
        for d in _study_workspace('CACHE').glob('retained-*-failure'):
            shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Exact bounded lexical slices, not a Scheme parser or a whole-program call graph.
# Simple literal token inventory avoids treating Scheme syntax as Python grammar.
# Native Org parser and link audit, without Babel evaluation.
