"""Source/formal evidence only. Native SysML owns research routing. No native tests."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy, json, re, shutil
import os

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
        _science.os = os
        _science.ROOT = _science.context.root
        _science.STEM = 'registry-slot-issuance'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitRegistrySlotIssuance'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def run(_science, name, args):
        args = [os.environ.get('CARRIER_LEAN', 'lean') if x == 'lean' else x for x in args]
        return _science.context.command(name, args, policy=_science.h.process_profile)

    def formal(_science):
        e = _science.context.library('registry_slot_issuance_projection')
        cfg = e.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        imported = ['SlotMappingAst', 'SlotCensus']
        parent = json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/carrier-slot-mapping/input.json').read_text())
        for name in imported:
            source = _science.BASE + 'models/lean/' + name + '.lean'
            assert _science.sha(_science.ROOT / source) == parent['sourceBindings'][source], source
            target = _study_workspace('CACHE') / (name + '.lean')
            if '--reuse-imports' in _science.context.arguments:
                cp = json.loads((_study_workspace('CACHE') / 'imported-checkpoint.json').read_text())
                assert all((_science.sha(_science.ROOT / f) == d for f, d in cp.items()))
                assert target.read_bytes() == (_science.ROOT / source).read_bytes()
            else:
                _study_write_bytes(target, (_science.ROOT / source).read_bytes())
            if '--reuse-formal' not in _science.context.arguments and '--reuse-imports' not in _science.context.arguments:
                _science.context.command(name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(target)], policy=_science.process_profile)
        formalPaths = [qnt, _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE + 'models/lean/' + n + '.lean' for n in imported + ['SlotIssuanceAst', 'SlotIssuance', 'StorageIntervals', 'SlotIssuanceBridge']]
        namespaces = ['SlotIssuance', 'StorageIntervals', 'SlotIssuanceBridge']

        def names():
            return [[ns + '.' + n] for ns in namespaces for n in re.findall('^\\s*theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + ns + '.lean')).read_text(), re.M)]
        if '--reuse-formal' in _science.context.arguments:
            cp = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            assert {f: _science.sha(_science.ROOT / f) for f in formalPaths} == cp['sources']
            assert all((_science.sha(_science.ROOT / f) == d for f, d in cp['logs'].items()))
            return ([[cfg['module'] + '.' + n] for n in cfg['actions']], names())
        if '--reuse-positive' in _science.context.arguments:
            cp = json.loads((_study_workspace('CACHE') / 'positive-checkpoint.json').read_text())
            assert {f: _science.sha(_science.ROOT / f) for f in formalPaths} == cp['sources']
            assert all((_science.sha(_science.ROOT / f) == d for f, d in cp['logs'].items()))
            ast = (_science.ROOT / (_science.BASE + 'models/lean/SlotIssuanceAst.lean')).read_text()
            assert e.generate(json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text()))[0] == ast
        else:
            _science.context.command('typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
            ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
            ast, rc = e.generate(ir)
            path = _science.BASE + 'models/lean/SlotIssuanceAst.lean'
            _study_write_text(_science.ROOT / path, ast)
            _science.save(_study_workspace('CACHE') / 'projection.json', dict(**rc, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / path), scope='restricted typed IR; JSON parser/projector trusted; source and GC witness fidelity open'))
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
            for n in ['SlotIssuanceAst', 'SlotIssuance', 'StorageIntervals', 'SlotIssuanceBridge']:
                src = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
                assert not re.search('\\bsorry\\b|\\baxiom\\s', src.read_text())
                target = _study_workspace('CACHE') / (n + '.lean')
                _study_write_bytes(target, src.read_bytes())
                _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(target)], policy=_science.process_profile)
            tests = _science.context.command('histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
            assert tests.count('ok ') == 14
            _science.context.command('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '457', '--verbosity', '1'], policy=_science.process_profile)
            _science.save(_study_workspace('CACHE') / 'positive-checkpoint.json', dict(sources={f: _science.sha(_science.ROOT / f) for f in formalPaths}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and f.stem in imported + ['typecheck', 'SlotIssuanceAst', 'SlotIssuance', 'StorageIntervals', 'SlotIssuanceBridge', 'histories', 'samples']}))
        for label, decl, old, new in [('negative-alias-release', 'def releaseRetiredAliasLeaseGuard', '(q.reg=(4))', 'True'), ('negative-copy-ack', 'def releaseCopyLeaseGuard', '(q.known=(1))', 'True'), ('negative-interval-overlap', 'def issueFreshGuard', '((q.lo≥(8)) ∨ (q.hi≤(0)))', 'True'), ('negative-generation-reuse', 'def reuseStorageNext', 'generation:=(q.generation+(1))', 'generation:=q.generation')]:
            neg = _study_workspace('CACHE') / label
            neg.mkdir(exist_ok=True)
            bad = '\n'.join((line.replace(old, new) if line.startswith(decl) else line for line in ast.splitlines())) + '\n'
            if label == 'negative-interval-overlap':
                bad = '\n'.join((line.replace('(q.request=(2))', '((q.request=(2)) ∨ (q.request=(3)))') if line.startswith(decl) else line for line in bad.splitlines())) + '\n'
            assert bad != ast, (label, old)
            _study_write_text(neg / 'SlotIssuanceAst.lean', bad)
            _science.context.command(label + '-ast', ['lean', '-o', str(neg / 'SlotIssuanceAst.olean'), str(neg / 'SlotIssuanceAst.lean')], policy=_science.process_profile)
            witnesses = {'negative-alias-release': 'def witness : State := {initial with reg:=3, mode:=1, lease:=1, boundGeneration:=1, known:=1, key:=1, keyGeneration:=1, lo:=2, hi:=4}', 'negative-copy-ack': 'def witness : State := {initial with reg:=2, mode:=2, lease:=1, boundGeneration:=1, copy:=1, key:=1, keyGeneration:=1, lo:=2, hi:=4, fresh:=1, freshLo:=8, freshHi:=12}', 'negative-interval-overlap': 'def witness : State := {initial with request:=3, lo:=6, hi:=10}', 'negative-generation-reuse': 'def witness : State := {initial with storage:=3, backing:=1}'}
            action = {'negative-alias-release': 'releaseRetiredAliasLease', 'negative-copy-ack': 'releaseCopyLease', 'negative-interval-overlap': 'issueFresh', 'negative-generation-reuse': 'reuseStorage'}[label]
            goal = '(' + action + 'Next witness).generation > witness.generation' if label == 'negative-generation-reuse' else 'Safe (' + action + 'Next witness)'
            control = 'import SlotIssuanceAst\nopen SlotIssuanceAst\n' + witnesses[label] + '\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n'
            _study_write_text(neg / 'Control.lean', control)
            try:
                _science.context.command(label + '-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', str(neg / 'Control.lean')], policy=_science.process_profile)
            except RuntimeError:
                output = (_study_workspace('CACHE') / (label + '-proof.stdout')).read_text()
                assert output.count('error:') == 1 and 'Control.lean:7:' in output and ('false' in output.lower()), output
            else:
                raise AssertionError('unsafe issuance accepted ' + label)
        _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sources={f: _science.sha(_science.ROOT / f) for f in formalPaths}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and (f.stem in imported + ['typecheck', 'SlotIssuanceAst', 'SlotIssuance', 'StorageIntervals', 'SlotIssuanceBridge', 'histories', 'samples'] or f.stem.startswith('negative-'))}))
        return ([[cfg['module'] + '.' + n] for n in cfg['actions']], names())

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/registry-slot-issuance/config.json').read_text())
        snap = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for f, v in snap.items():
            assert _science.sha(_science.ROOT / f) == _science.sha(_science.ROOT / v['path']) == v['sha256'], f
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/carrier-slot-mapping/input.json'
        parentHash = _science.sha(parent)
        cfgPath = _study_workspace('CACHE') / 'config.json'
        model = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        scope = {model: _science.sha(_science.ROOT / model)}
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in cfg['groups'] for i in range(n) for f in fs.split()]
        keys += [('need', slot, f, f'{_science.PKG}::{slot}.{f}') for slot in cfg['slots'] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope', 'owner.componentId']]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'registry-slot-issuance', field_expressions, ordered=True, models=[model])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        for g, _, _ in cfg['groups']:
            p[g] = list(p[g].values())
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        _science.save(_study_workspace('CACHE') / 'global-sysml-status.json', dict(status='scoped-native-only-no-whole-DEV-qualification', wholeDevValidated=False, scopedNativeValidation=True))
        view = _science.context.library('copy_producer_envelope_study')
        for k, v in dict(ROOT=_science.ROOT, GROUPS=cfg['groups'], MATRIX=_science.BASE + _science.STEM + '-matrix.org', D2=_science.BASE + 'diagrams/' + _science.STEM + '.d2').items():
            setattr(view, k, v)
        view.views(p)
        matrix = _science.ROOT / (_science.BASE + _science.STEM + '-matrix.org')
        _study_write_text(matrix, matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'Registry and SlotKey Issuance — Identity, Overlap and Lease Matrix').replace('GambitCopyProducerEnvelope', _science.PKG).replace('source-and-C11-open', 'source-root-exception-C23-platform-open'))
        d2 = _science.ROOT / (_science.BASE + 'diagrams/' + _science.STEM + '.d2')
        _study_write_text(d2, d2.read_text().replace('legal-input and C11 OPEN', 'source / roots / exceptions / C23 OPEN'))
        witnesses = []
        for v in p['source']:
            text = (_science.ROOT / snap[v['path']]['path']).read_text()
            assert v['needle'] in text, v
            witnesses.append(dict(**v, sha256=snap[v['path']]['sha256'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        wrapper = _science.ROOT / 'vendor/gambit/include/gambit.h.in'
        includes = re.findall('^#include "(_gambit/[^"\\n]+)"', wrapper.read_text(), re.M)
        make = _science.ROOT / 'vendor/gambit/include/makefile.in'
        mt = make.read_text()
        config = re.search('^HEADER_CONFIG = (.+)$', mt, re.M).group(1).split(':')
        templates = re.findall('_gambit/[A-Za-z_]+\\.h\\.in', mt.split('HEADER_TEMPLATES =', 1)[1].split('HEADER_CONFIG =', 1)[0])
        assert config[0] == 'include/gambit.h'
        assert config[1:] == ['include/' + v for v in templates]
        assert set(includes).issubset(templates)
        mem = _science.ROOT / 'vendor/gambit/lib/mem.c'
        chunks = re.findall('^#include "(_mem/[^"\\n]+)"', mem.read_text(), re.M)
        compositionPaths = ['vendor/gambit/include/' + x for x in templates] + ['vendor/gambit/lib/' + x for x in chunks] + ['vendor/gambit/include/gambit.h.in', 'vendor/gambit/include/makefile.in', 'vendor/gambit/lib/mem.c']
        compositionInputs = {f: _science.sha(_science.ROOT / f) for f in compositionPaths}
        _science.save(_study_workspace('CACHE') / 'modular-source-composition.json', dict(wrapperIncludes=includes, configuredFragments=templates, memoryIncludes=chunks, inputs=compositionInputs, scope='literal include/configuration order only', preprocessingRun=False, generatedArtifactQualified=False))
        corpus = ['vendor/gambit/lib', 'vendor/gambit/include', 'vendor/gambit/examples']
        globs = ['-g', '*.c', '-g', '*.h', '-g', '*.inc', '-g', '*.scm', '-g', '*.h.in']
        paths = _science.context.command('writer-corpus', ['rg', '--files'] + corpus + globs, policy=_science.process_profile).splitlines()
        inventoryInputs = {f: _science.sha(_science.ROOT / f) for f in sorted(paths)}
        pattern = '___alloc_rc|___gc_root_task_|___gc_origin_|___set_data_rc|___register_rc|___addref_rc|___release_rc|cleanup_rc|___cleanup_mem_pstate|___cleanup_mem_vmstate|h->data'
        raw = _science.context.command('writer-sites', ['rg', '-n', '--no-heading', pattern] + corpus + globs, policy=_science.process_profile)
        matches = []
        for line in raw.splitlines():
            path, no, body = line.split(':', 2)
            matches.append(dict(path=path, line=int(no), text=body.strip()))
        _science.save(_study_workspace('CACHE') / 'source-token-inventory.json', dict(inputs=inventoryInputs, matches=matches, scope=corpus, completeLiteralEnumeration=True, completeWriterAuthorityClosure=False, includesDeclarationsCommentsAndIndirectExports=True))
        slices = []
        for path, begin, end, call in [('vendor/gambit/lib/_mem/rc-allocation.inc', '___EXP_FUNC(void,___release_rc)', '___EXP_FUNC(void,___addref_rc)', '___FREE_MEM(h);'), ('vendor/gambit/lib/_mem/rc-roots.inc', '___HIDDEN void mark_rc', '#define UNMARKED_MOVABLE', 'mark_array (work, &h->data, 1);'), ('vendor/gambit/examples/tcltk/tcltk.scm', '___HIDDEN void scheme_delete_cmd', 'c-declare-end', '___EXT(___release_rc)')]:
            text = (_science.ROOT / snap[path]['path']).read_text()
            start = text.index(begin)
            stop = text.index(end, start + len(begin))
            assert call in text[start:stop]
            slices.append(dict(path=path, sha256=snap[path]['sha256'], startLine=text[:start].count('\n') + 1, endLine=text[:stop].count('\n') + 1, call=call, scope='bounded lexical lifetime/scan order; platform/source simulation open'))
        _science.save(_study_workspace('CACHE') / 'source-call-slices.json', slices)
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
        cases = ['current', 'synthetic-all', 'stale-source', 'missing-action', 'missing-lemma', 'wrong-issuer', 'missing-formal', 'wrong-scope', 'wrong-owner', 'missing-intent-route', 'missing-projection']
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, path, digest, sc] for n, k, path, digest, sc in needs if case != 'current' or n in ['SI-formal', 'SI-bridge']]
                if case == 'missing-formal':
                    receipts = [v for v in receipts if v[1] != 'SI-formal']
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
                    ro[0][0] = 'wrong-component'
                if case == 'missing-intent-route':
                    ro = [r for r in ro if r[1] != 'registry_slot_issuance.releaseRetiredAliasLease']
                session.replace(dict(scenario=[[case]], need=needs, needOwner=owners, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if (case != 'missing-lemma' or v != ['SlotIssuance.stepPreserves']) and (case != 'missing-projection' or v != ['SlotIssuanceBridge.backingReceiptSeparate'])], sourceNeed=sources, sourceObservation=obs, issuerNeed=issuers, issuerObservation=io, routeNeed=routes, routeObservation=ro, proofNeed=proofs))
                r = session.run(queries=['blocked', 'candidate', 'linked', 'sourceLinked', 'issuerLinked', 'routeLinked', 'proofLinked'])
                assert r['complete']
                results[case] = r['relations']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-scenario-diagnostics.json', results)
        assert [k for k in cases if results[k]['candidate']] == ['synthetic-all'], [k for k in cases if results[k]['candidate']]
        gaps = sorted((v[1] for v in results['current']['blocked']))
        assert len(gaps) == 6, gaps
        assert len(results['current']['routeLinked']) == len(routes)
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        closure = ['', '** Closure observation', '', '| Obligation | Owner | Status | Scoped subject |', '|---+---+---+---|']
        for v in p['need'].values():
            status = 'unresolved' if v['obligationId'] in gaps else 'provided: scoped conditional formal receipt'
            closure.append('| ' + ' | '.join([v['obligationId'], v['owner.componentId'], status, v['subjectScope']]) + ' |')
        _study_write_text(matrix, matrix.read_text() + '\n'.join(closure) + '\n')
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT))], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(status='conditional-storage-issuance-and-alias-lease-pass-native-integration-denied', languageBaseline='C23', sourceSnapshots=len(snap), modularHeaderSourceBound=True, configuredHeaderFragments=len(templates), memoryFragments=len(chunks), headerCompositionScope='lexical-not-generated', sourceAnchors=len(witnesses), issuerRoles=len(issuers), sourceCallSlices=len(slices), componentSourceActionRoutes=len(routes), qntActions=len(actions), qntHistories=14, qntSamples=500, seed=457, leanTheorems=len(lemmas), allStepInduction=True, sysmlScope='self-contained-native-package', wholeDevValidated=False, typedIrControls=4, negativeProofControls=4, literalCallerHits=len(matches), callerCorpusFiles=len(paths), completeSemanticIntentCensus=False, completeWriterAuthorityClosure=False, persistentCoverageNativeQualified=False, ascentScenarios=len(cases), fixedRegistryEntries=1, fixedStorageIncarnations=2, rawHeaderInventoryIncludesTemplates=True, genericConcurrentKeyedProtocol=False, genericSlotKeyAlgebra=True, genericIntervalAlgebra=True, genericFiniteCensus=True, nativePointerBijectionProved=False, privateInitializationRefinement=False, canonicalAllocatorCompletenessProved=False, payloadBindingProductProved=False, fullUnboundedProductRefinement=False, actualCandidate=False, firstNativeRetirement=False, secondNativeRetirement=False, realIssuerClosure=False, genericSchemeLastAliasSigner=False, compiledRootMapQualified=False, eventualCompletionProved=False, crashRecoveryProved=False, c23RefinementProved=False, blockers=gaps, nativeTestsRun=False, performanceTestsRun=False)
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
        for f, digest in compositionInputs.items():
            assert _science.sha(_science.ROOT / f) == digest, ('composition drift', f)
        own = [_science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + 'models/quint/registry_slot_issuance.qnt', _science.BASE + 'models/lean/SlotIssuanceAst.lean', _science.BASE + 'models/lean/SlotIssuance.lean', _science.BASE + 'models/lean/SlotIssuanceBridge.lean', _science.BASE + 'models/lean/SlotMappingAst.lean', _science.BASE + 'models/lean/SlotCensus.lean', _science.BASE + 'models/lean/StorageIntervals.lean', _science.BASE + 'index.org', _science.BASE + 'language-baseline-design.org', _science.BASE + 'carrier-slot-mapping-design.org', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT)), 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', 'src/gambit_smp/scientific_default_lease_admission_study.py', 'src/gambit_smp/scientific_copy_producer_envelope_study.py', 'src/gambit_smp/scientific_advantage_architecture_study.py', str((_study_workspace('CACHE') / 'config.json').relative_to(_science.ROOT)), str((_study_workspace('CACHE') / 'source-snapshots.json').relative_to(_science.ROOT))] + [v['path'] for v in snap.values()]
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), parentPath=str(parent.relative_to(_science.ROOT)), parentInputSha256=parentHash, sourceBindings={f: _science.sha(_science.ROOT / f) for f in own}, sourceSnapshots=snap, sysmlInputs=scope, lexicalInputs=inventoryInputs, compositionInputs=compositionInputs))

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
        for n in ['negative-alias-release', 'negative-copy-ack', 'negative-interval-overlap', 'negative-generation-reuse']:
            shutil.copytree(_study_workspace('CACHE') / n, _study_workspace('OUT') / n, dirs_exist_ok=True)
        for f in _study_workspace('CACHE').glob('negative-*.lean'):
            shutil.copyfile(f, _study_workspace('OUT') / f.name)
        for d in _study_workspace('CACHE').glob('retained-*-failure'):
            shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Exact local formal executable may be selected without invoking the version shim.
# The interval mutant also makes a conflicting request eligible, so the
# negative is not merely a weakened guard unreachable under Safe.
# Scope the native query to this self-contained package; the bounded all-DEV
# query timeout is retained separately and is not relabeled as global validation.
# This parses literal source include directives only, never SysML or C semantics.
# Closure status is an observation over SysML-owned obligations, not a second
# manually maintained requirement list.
# Native Org parser and link audit, without Babel evaluation.
