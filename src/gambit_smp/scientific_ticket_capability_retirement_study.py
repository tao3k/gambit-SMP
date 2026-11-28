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
        _science.STEM = 'ticket-capability-retirement'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitTicketCapabilityRetirement'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def formal(_science):
        e = _science.context.library('ticket_capability_retirement_projection')
        cfg = e.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        formalPaths = [qnt, _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE + 'models/lean/' + n + '.lean' for n in ['TicketCapabilityAst', 'TicketCapability', 'TicketIdentityAlgebra']]
        if '--reuse-formal' in _science.context.arguments:
            checkpoint = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            assert {f: _science.sha(_science.ROOT / f) for f in formalPaths} == checkpoint['sources']
            assert all((_science.sha(_science.ROOT / f) == d for f, d in checkpoint['logs'].items()))
            lemmas = [[ns + '.' + n] for ns in ['TicketCapability', 'TicketIdentityAlgebra'] for n in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + ns + '.lean')).read_text(), re.M)]
            return ([[cfg['module'] + '.' + n] for n in cfg['actions']], lemmas)
        _science.context.command('typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, rc = e.generate(ir)
        path = _science.BASE + 'models/lean/TicketCapabilityAst.lean'
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
        for n in ['TicketCapabilityAst', 'TicketCapability', 'TicketIdentityAlgebra']:
            src = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', src.read_text())
            target = _study_workspace('CACHE') / (n + '.lean')
            _study_write_bytes(target, src.read_bytes())
            _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(target)], policy=_science.process_profile)
        tests = _science.context.command('histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 15
        _science.context.command('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '293', '--verbosity', '1'], policy=_science.process_profile)
        neg = _study_workspace('CACHE') / 'negative-root'
        neg.mkdir(exist_ok=True)
        bad = '\n'.join((line.replace('(¬(q.s0open=true))', 'True') if line.startswith('def retireRootGuard') else line for line in ast.splitlines())) + '\n'
        assert bad != ast
        _study_write_text(neg / 'TicketCapabilityAst.lean', bad)
        _science.context.command('negative-ast', ['lean', '-o', str(neg / 'TicketCapabilityAst.olean'), str(neg / 'TicketCapabilityAst.lean')], policy=_science.process_profile)
        try:
            _science.context.command('negative-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/TicketCapability.lean'], policy=_science.process_profile)
        except RuntimeError:
            assert 'error:' in (_study_workspace('CACHE') / 'negative-proof.stdout').read_text()
        else:
            raise AssertionError('live scanner root retirement accepted')
        lemmas = [[ns + '.' + n] for ns in ['TicketCapability', 'TicketIdentityAlgebra'] for n in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + ns + '.lean')).read_text(), re.M)]
        for name, old, new in [('negative-other-ticket', 'if q=key then finish (ledger key) payload value else ledger q', 'finish (ledger key) payload value'), ('negative-other-handle', 'if q=key then false else handles q', 'false')]:
            algebra = (_science.ROOT / (_science.BASE + 'models/lean/TicketIdentityAlgebra.lean')).read_text()
            bad = algebra.replace(old, new)
            assert bad != algebra
            target = _study_workspace('CACHE') / (name + '.lean')
            _study_write_text(target, bad)
            try:
                _science.context.command(name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', str(target)], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / (name + '.stdout')).read_text()
            else:
                raise AssertionError('identity mutation proved ' + name)
        _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sources={f: _science.sha(_science.ROOT / f) for f in formalPaths}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and f.stem in ['typecheck', 'TicketCapabilityAst', 'TicketCapability', 'TicketIdentityAlgebra', 'histories', 'samples', 'negative-ast', 'negative-proof', 'negative-other-ticket', 'negative-other-handle']}))
        return ([[cfg['module'] + '.' + n] for n in cfg['actions']], lemmas)

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/ticket-capability-retirement/config.json').read_text())
        snap = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for f, v in snap.items():
            assert _science.sha(_science.ROOT / f) == _science.sha(_science.ROOT / v['path']) == v['sha256'], f
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/will-action-drain/input.json'
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
        _study_write_text(matrix, matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'Exact Ticket Settlement and Capability Retirement Matrix').replace('GambitCopyProducerEnvelope', _science.PKG).replace('source-and-C11-open', 'source-root-exception-C23-platform-open'))
        d2 = _science.ROOT / (_science.BASE + 'diagrams/' + _science.STEM + '.d2')
        _study_write_text(d2, d2.read_text().replace('legal-input and C11 OPEN', 'source / roots / exceptions / C23 OPEN'))
        witnesses = []
        for v in p['source']:
            text = (_science.ROOT / snap[v['path']]['path']).read_text()
            assert v['needle'] in text, v
            witnesses.append(dict(**v, sha256=snap[v['path']]['sha256'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        slices = []
        specs = [('vendor/gambit/lib/_thread.scm', '(define-prim (##call-with-current-continuation', '(define-prim (call-with-current-continuation', '(define (reify-continuation cont)'), ('vendor/gambit/lib/_thread.scm', '(define-prim (##continuation-unwind-wind src dst continue)', '(define-prim (##continuation-graft-aux', '((macro-dynwind-before dst))'), ('vendor/gambit/lib/_thread.scm', '(define-prim (##continuation-return-aux cont val1 val2 val3 others)', '(define-prim (##continuation-return\n', '(if (or (##eq? src dst)'), ('vendor/gambit/lib/_kernel.scm', '(define-prim (##continuation-copy cont)', '(define-prim (##continuation-next! cont)', '___SCMOBJ frame = ___CONTINUATION_FRAME_FIELD(cont);'), ('vendor/gambit/lib/_io.scm', '(define-prim (##implode-continuation re fields)', '(define-prim (##explode-procedure proc)', '(##make-continuation'), ('vendor/gambit/lib/_kernel.scm', '(define-prim (##will-execute! will)', '(define ##final-will-registry', '(action testator)')]
        for path, begin, end, call in specs:
            text = (_science.ROOT / snap[path]['path']).read_text()
            for i, hit in enumerate(re.finditer(re.escape(begin), text)):
                stop = text.index(end, hit.end())
                body = text[hit.start():stop]
                assert call in body
                slices.append(dict(path=path, sha256=snap[path]['sha256'], occurrence=i, startLine=text[:hit.start()].count('\n') + 1, endLine=text[:stop].count('\n') + 1, call=call, scope='bounded lexical slice; source/ABI/authority correspondence open'))
        _science.save(_study_workspace('CACHE') / 'source-call-slices.json', slices)
        inventoryInputs = {f: v['sha256'] for f, v in snap.items()}
        matches = []
        for path, v in snap.items():
            for lineNo, line in enumerate((_science.ROOT / v['path']).read_text().splitlines(), 1):
                if any((t in line for t in ['continuation-copy', 'continuation-return-no-winding', 'procedure->continuation', 'implode-continuation', 'refcount', 'will-execute!'])):
                    matches.append(dict(path=path, line=lineNo, text=line.strip()))
        _science.save(_study_workspace('CACHE') / 'source-token-inventory.json', dict(inputs=inventoryInputs, matches=matches, scope='selected source snapshots only; aliases and caller closure unproved'))
        actions, lemmas = _science.formal()
        for v in p['proof']:
            assert [v['lemma']] in lemmas, v
        needs = [[v[k] for k in ['obligationId', 'kind', 'subjectPath']] + [_science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        owners = [[v['obligationId'], v['owner.componentId']] for v in p['need'].values()]
        sources = [[v[k] for k in ['key', 'path', 'sha256', 'needle']] for v in witnesses]
        issuers = [[v[k] for k in ['key', 'proposedIssuer', 'actualSource', 'status', 'responsibility']] for v in p['issuer']]
        routes = [[v[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for v in p['route']]
        proofs = [[v['key'], v['lemma']] for v in p['proof']]
        results = {}
        cases = ['current', 'synthetic-all', 'stale-source', 'missing-action', 'missing-lemma', 'wrong-issuer', 'missing-formal', 'wrong-scope', 'wrong-owner', 'missing-raw-route', 'missing-projection']
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, path, digest, sc] for n, k, path, digest, sc in needs if case != 'current' or n in ['TC-formal', 'TC-algebra']]
                if case == 'missing-formal':
                    receipts = [v for v in receipts if v[1] != 'TC-formal']
                if case == 'wrong-scope':
                    receipts[0][-1] = 'native-performance'
                obs = copy.deepcopy(sources)
                if case == 'stale-source':
                    obs[0][2] = 'stale'
                io = copy.deepcopy(issuers)
                if case == 'wrong-issuer':
                    io[4][2] = 'existing-global-last-alias-signer-without-evidence'
                ro = copy.deepcopy(routes)
                if case == 'wrong-owner':
                    ro[0][0] = 'roots'
                if case == 'missing-raw-route':
                    ro = [r for r in ro if r[1] != 'ticket_capability_retirement.discoverRawEscape']
                session.replace(dict(scenario=[[case]], need=needs, needOwner=owners, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if (case != 'missing-lemma' or v != ['TicketCapability.stepPreserves']) and (case != 'missing-projection' or v != ['TicketIdentityAlgebra.commitProjection0'])], sourceNeed=sources, sourceObservation=obs, issuerNeed=issuers, issuerObservation=io, routeNeed=routes, routeObservation=ro, proofNeed=proofs))
                r = session.run(queries=['blocked', 'candidate', 'linked', 'sourceLinked', 'issuerLinked', 'routeLinked', 'proofLinked'])
                assert r['complete']
                results[case] = r['relations']
        finally:
            engine.close()
        assert [k for k in cases if results[k]['candidate']] == ['synthetic-all']
        gaps = sorted((v[1] for v in results['current']['blocked']))
        assert len(gaps) == 5, gaps
        assert len(results['current']['routeLinked']) == len(routes)
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT))], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(status='conditional-per-key-and-capability-safety-pass-native-retirement-denied', languageBaseline='C23', sourceSnapshots=len(snap), sourceAnchors=len(witnesses), issuerRoles=len(issuers), sourceCallSlices=len(slices), componentSourceActionRoutes=len(routes), qntActions=len(actions), qntHistories=15, qntSamples=500, seed=293, leanTheorems=len(lemmas), allStepInduction=True, typedIrControls=4, negativeProofControls=3, ascentScenarios=len(cases), concreteTicketIds=2, genericKeyedAlgebra=True, fullUnboundedProductRefinement=False, actualCandidate=False, firstNativeRetirement=False, secondNativeRetirement=False, realIssuerClosure=False, genericSchemeLastAliasSigner=False, compiledRootMapQualified=False, eventualCompletionProved=False, crashRecoveryProved=False, c23RefinementProved=False, blockers=gaps, nativeTestsRun=False, performanceTestsRun=False)
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
        own = [_science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + 'models/quint/ticket_capability_retirement.qnt', _science.BASE + 'models/lean/TicketCapabilityAst.lean', _science.BASE + 'models/lean/TicketCapability.lean', _science.BASE + 'index.org', _science.BASE + 'language-baseline-design.org', _science.BASE + 'will-action-drain-design.org', _science.BASE + 'models/lean/TicketIdentityAlgebra.lean', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT)), 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', 'src/gambit_smp/scientific_default_lease_admission_study.py', 'src/gambit_smp/scientific_copy_producer_envelope_study.py', 'src/gambit_smp/scientific_advantage_architecture_study.py', str((_study_workspace('CACHE') / 'config.json').relative_to(_science.ROOT)), str((_study_workspace('CACHE') / 'source-snapshots.json').relative_to(_science.ROOT))] + [v['path'] for v in snap.values()]
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
        shutil.copytree(_study_workspace('CACHE') / 'negative-root', _study_workspace('OUT') / 'negative-root', dirs_exist_ok=True)
        for f in _study_workspace('CACHE').glob('negative-other-*.lean'):
            shutil.copyfile(f, _study_workspace('OUT') / f.name)
        for d in _study_workspace('CACHE').glob('retained-*-failure'):
            shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Exact bounded slices; lexical call ordering is not full source simulation.
# Native Org parser and link audit, without Babel evaluation.
