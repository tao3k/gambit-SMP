"""Native architecture projection, candidate behavioral model and semantic kernels; no runtime work."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import copy, hashlib, json, re, shutil, subprocess
from pathlib import Path
from ascent import Engine

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.hashlib = hashlib
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.subprocess = subprocess
        _science.Path = Path
        _science.Engine = Engine
        _science.ROOT = _science.context.root
        _science.BASE = _science.ROOT / 'dev/refactoring/modern-c'
        _science.GROUPS = [['source', 28, ['key', 'path', 'needle', 'limit']], ['obligation', 8, ['key', 'scope', 'missing']], ['edge', 23, ['fromNode', 'toNode', 'contract']], ['alternative', 3, ['key', 'choice', 'benefit', 'cost', 'decision']], ['domain', 6, ['key', 'owner.moduleId', 'role', 'owns', 'lifetime', 'modelFields', 'boundary']], ['cursorStep', 5, ['key', 'condition', 'update', 'projection', 'obligation']], ['bitmapStage', 6, ['key', 'sourceKey', 'operand', 'result', 'obligation']], ['enumerationOp', 4, ['key', 'sourceKey', 'authority', 'operand', 'rights', 'reuse', 'invalidation']], ['writerFamily', 6, ['key', 'sourceKey', 'authority', 'targetContract', 'observed', 'closure']], ['slotFamily', 6, ['key', 'sourceKey', 'cells', 'issuer', 'custody', 'order', 'gap']], ['mathScope', 15, ['kind', 'key', 'lawKey', 'kernelPath', 'kernel', 'claim', 'limit']], ['law', 37, ['key', 'domain.key', 'predicate', 'kernel', 'law', 'proofLimit', 'refinement', 'seam.interfaceId', 'sourceKey', 'modelPath', 'kernelPath']]]
        _science.LEAN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def rel(_science, p):
        return str(Path(p).relative_to(_science.ROOT))

    def save(_science, p, x):
        _study_write_text(Path(p), json.dumps(x, indent=2) + '\n')

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        h = _science.context.library('size_family_hold_balance_study')
        sampleResults = {}

        def sample(name, args):
            try:
                _science.context.command(name, args, policy=h.process_profile)
            except subprocess.TimeoutExpired:
                sampleResults[name] = dict(passed=False, reason='60-second-timeout', requestedSamples=500, maxSteps=80, seed=953)
            else:
                sampleResults[name] = dict(passed=True, requestedSamples=500, maxSteps=80, seed=953)
            _science.save(_study_workspace('CACHE') / 'sample-results.json', sampleResults)

        def sampled(name):
            return 500 if sampleResults[name]['passed'] else None
        frameq = _science.BASE / 'models/quint/frame_roots.qnt'
        contractq = _science.BASE / 'models/quint/frame_contract.qnt'
        bitmap = _science.BASE / 'models/lean/FrameBitmapComposition.lean'
        enumq = _science.BASE / 'models/quint/root_enumeration.qnt'
        slotq = _science.BASE / 'models/quint/root_store_projection.qnt'
        model = _science.BASE / 'models/sysml/runtime-ownership.sysml'
        qnt = _science.BASE / 'models/quint/runtime_ownership.qnt'
        lean = _science.BASE / 'models/lean/RuntimeOwnership.lean'
        dsl = _science.ROOT / 'dev/modeling/ascent/runtime-ownership.rules.scm'
        files = _science.context.command('sysml-files', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=h.process_profile).splitlines()
        bindings = {f: _science.sha(_science.ROOT / f) for f in files}
        for f in [qnt, slotq, enumq, frameq, contractq, bitmap, lean, dsl, _science.ROOT / 'src/gambit_smp/scientific_frame_cursor_projection.py', _science.BASE / 'models/lean/FrameCursorAst.lean', _science.BASE / 'models/lean/FrameCursorRefinement.lean', _science.BASE / 'models/lean/FrameCursorWords.lean', Path(str(_science.context.root / 'src/gambit_smp/scientific_runtime_ownership_study.py')), _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_study.py']:
            bindings[_science.rel(f)] = _science.sha(f)
        _science.save(_study_workspace('CACHE') / 'sysml-input-cut.json', bindings)
        keys = [(g, i, f, 'GambitRuntimeOwnership::' + g + str(i) + '.' + f) for g, n, fs in _science.GROUPS for i in range(n) for f in fs]
        packageFiles = {}
        for f in files:
            for name in re.findall('\\bpackage\\s+([A-Za-z_]\\w*)\\s*\\{', (_science.ROOT / f).read_text()):
                packageFiles.setdefault(name, set()).add(f)
        selected = {_science.rel(model), 'dev/architecture/runtime/models/sysml/composition.sysml'}
        todo = list(selected)
        while todo:
            f = todo.pop()
            for name in set(re.findall('\\b[A-Za-z_]\\w*\\b', (_science.ROOT / f).read_text())).intersection(packageFiles):
                for dep in packageFiles.get(name, []):
                    if dep not in selected:
                        selected.add(dep)
                        todo.append(dep)
        selected = sorted(selected)
        _science.save(_study_workspace('CACHE') / 'sysml-selection.json', dict(files=selected, scope='runtime-ownership and canonical composition dependency closure', wholeDevValidation=False, selectionIsNotSemanticValidation=True))
        vals = []
        queryBatches = 0
        for start in range(0, len(keys), 160):
            field_expressions = []
            for *_, expr in keys[start:start + 160]:
                field_expressions.append(expr)
            raw = _study_fields(_science.ROOT, None, 'runtime-ownership', field_expressions, ordered=True, models=selected)
            batch = raw['orderedValues']
            assert len(batch) == len(keys[start:start + 160])
            vals += batch
            queryBatches += 1
        assert len(vals) == len(keys)
        rows = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            rows.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(v.values()) for g, v in rows.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        composition = _science.ROOT / 'dev/architecture/runtime/models/sysml/composition.sysml'
        assert 'ref part ownershipContract : GambitRuntimeOwnership::CompositionContract = GambitRuntimeOwnership::contract;' in composition.read_text()
        sources = []
        for r in p['source']:
            f = _science.ROOT / r['path']
            text = f.read_text()
            assert r['needle'] in text, r
            bindings[r['path']] = _science.sha(f)
            _study_write_text(_study_workspace('CACHE') / ('source-' + _science.sha(f) + '.txt'), text)
            sources.append(dict(**r, sha256=_science.sha(f), lines=[text.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(r['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', sources)
        assert all((r['sourceKey'] in {x['key'] for x in sources} for r in p['slotFamily'] + p['writerFamily'] + p['enumerationOp'] + p['bitmapStage']))
        _science.context.command('frame-type', ['quint', 'typecheck', str(frameq), '--out', str(_study_workspace('CACHE') / 'frame-typed-ir.json')], policy=h.process_profile)
        projectionPath = _science.ROOT / 'src/gambit_smp/scientific_frame_cursor_projection.py'
        projector = _science.context.library('size_family_hold_balance_study')
        ir = json.loads((_study_workspace('CACHE') / 'frame-typed-ir.json').read_text())
        ast, projection = projector.generate(ir)
        astpath = _science.BASE / 'models/lean/FrameCursorAst.lean'
        assert astpath.read_text() == ast
        controls = {}
        for label in ['binding', 'field', 'callee', 'expression', 'roster', 'word-offset']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if label == 'binding':
                bad['table'][str(projection['nameReferences'][0][0])]['id'] = -1
            if label == 'field':
                ds['Scan']['type']['fields']['fields'][0]['fieldName'] = 'unqualified'
            if label == 'callee':
                bad['table'][str(projection['callReferences'][0][0])]['id'] = -1
            if label == 'expression':
                ds['runStep']['expr']['args'][1]['args'][1]['args'][1]['args'][2]['value'] = 4
            if label == 'word-offset':
                offsets = []

                def findOffsets(e):
                    if isinstance(e, dict):
                        args = e.get('args', [])
                        if e.get('opcode') == 'iadd' and len(args) == 2 and (args[0].get('opcode') == 'field') and (args[0]['args'][1].get('value') == 'next') and (args[1].get('value') == 1):
                            offsets.append(args[1])
                        for v in e.values():
                            findOffsets(v)
                    elif isinstance(e, list):
                        for v in e:
                            findOffsets(v)
                findOffsets(ds['advanceCursor']['expr'])
                assert len(offsets) == 2
                offsets[0]['value'] = 2
            if label == 'roster':
                bad['modules'][0]['declarations'] = [d for d in bad['modules'][0]['declarations'] if d['name'] != 'advanceCursor']
            try:
                changed, _ = projector.generate(bad)
            except (AssertionError, KeyError):
                controls[label] = 'rejected'
            else:
                assert changed != ast, label
                controls[label] = 'different-generated-AST-rejected'
        _science.save(_study_workspace('CACHE') / 'cursor-projection.json', dict(**projection, typedIrSha256=_science.sha(_study_workspace('CACHE') / 'frame-typed-ir.json'), generatedLeanSha256=_science.sha(astpath), projectorSha256=_science.sha(projectionPath), controls=controls))
        _science.context.command('qnt-type', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=h.process_profile)
        assert not re.search('\\bsorry\\b|\\baxiom\\s', lean.read_text())
        _science.context.command('lean', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / 'RuntimeOwnership.olean'), str(lean)], policy=h.process_profile)
        for name in ['FrameRoots', 'FrameContract', 'FutureCoordinates', 'FrameBitmapComposition', 'FrameCursorClosure', 'FrameCursorAst', 'FrameCursorRefinement', 'FrameCursorWords', 'FrameCursorNativeBounds']:
            f = _science.BASE / 'models/lean' / (name + '.lean')
            bindings[_science.rel(f)] = _science.sha(f)
            assert not re.search('\\bsorry\\b|\\baxiom\\s', f.read_text())
            _science.context.command('lean-' + name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(f)], policy=h.process_profile)
        audit = _study_workspace('CACHE') / 'cursor-proof-axioms.lean'
        _study_write_text(audit, 'import FrameCursorClosure\nimport FrameCursorRefinement\nimport FrameCursorWords\nimport FrameCursorNativeBounds\n' + ''.join(('#print axioms Gambit.FrameCursorClosure.' + n + '\n' for n in ['preserves', 'pendingRangeIsFresh', 'totalCorrect', 'initialBudget'])) + ''.join(('#print axioms Gambit.FrameCursorRefinement.' + n + '\n' for n in ['coverageReflects', 'actualStepSimulation', 'stepIdentity', 'actualStepPreserves'])) + ''.join(('#print axioms Gambit.FrameCursorWords.' + n + '\n' for n in ['advanceWord', 'qualifiedNext', 'sourceTotalCorrectAll'])) + ''.join(('#print axioms Gambit.FrameCursorNativeBounds.' + n + '\n' for n in ['unsignedShift', 'boundaryMask', 'tailReadBound', 'reversedRunBounds', 'reversedSlotIdentity', 'bitmapCapacity'])) + '\nexample : Gambit.FrameCursorWords.Width 4 := Or.inl rfl\nexample : Gambit.FrameCursorWords.Width 32 := Or.inr (Or.inl rfl)\nexample : Gambit.FrameCursorWords.Width 64 := Or.inr (Or.inr rfl)\n')
        axioms = _science.context.command('lean-cursor-axioms', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(audit)], policy=h.process_profile)
        assert 'sorryAx' not in axioms
        _science.context.command('histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=h.process_profile)
        sample('samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'])
        _science.context.command('slot-type', ['quint', 'typecheck', str(slotq), '--out', str(_study_workspace('CACHE') / 'slot-typed-ir.json')], policy=h.process_profile)
        _science.context.command('slot-histories', ['quint', 'test', str(slotq), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=h.process_profile)
        sample('slot-samples', ['quint', 'run', str(slotq), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'])
        _science.context.command('enum-type', ['quint', 'typecheck', str(enumq), '--out', str(_study_workspace('CACHE') / 'enum-typed-ir.json')], policy=h.process_profile)
        _science.context.command('enum-histories', ['quint', 'test', str(enumq), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=h.process_profile)
        sample('enum-samples', ['quint', 'run', str(enumq), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'])
        for label, f in [('frame', frameq), ('contract', contractq)]:
            if label != 'frame':
                _science.context.command(label + '-type', ['quint', 'typecheck', str(f), '--out', str(_study_workspace('CACHE') / (label + '-typed-ir.json'))], policy=h.process_profile)
            _science.context.command(label + '-histories', ['quint', 'test', str(f), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=h.process_profile)
            sample(label + '-samples', ['quint', 'run', str(f), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'])
        sample('cursor-microstep-samples', ['quint', 'run', str(frameq), '--backend', 'typescript', '--init', 'runInit', '--step', 'runStep', '--invariant', 'runSafe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'])
        predicates = re.findall('^ val (\\w+)\\s*=', qnt.read_text(), re.M)
        lemmas = re.findall('^theorem (\\w+)', lean.read_text(), re.M)
        assert all((re.search('^\\s*val ' + re.escape(r['predicate']) + '\\s*=', (_science.ROOT / r['modelPath']).read_text(), re.M) and re.search('^theorem ' + re.escape(r['kernel']) + '\\b', (_science.ROOT / r['kernelPath']).read_text(), re.M) for r in p['law']))
        src = [[r['key'], r['path'], r['sha256'], r['needle']] for r in sources]
        routes = [[r['key'], r['domain.key'], r['seam.interfaceId'], r['sourceKey'], r['modelPath'], r['predicate'], r['kernelPath'], r['kernel'], 'candidate-ownership;whole-source-open'] for r in p['law']]
        symbols = [[r['modelPath'], r['predicate'], _science.sha(_science.ROOT / r['modelPath'])] for r in p['law']] + [[r['kernelPath'], r['kernel'], _science.sha(_science.ROOT / r['kernelPath'])] for r in p['law']]
        ref = [[r['key'], 'actual-source-simulation:' + r['key']] for r in p['law']]
        whole = [[r['key'], r['scope'] + ':whole-composition-open'] for r in p['obligation']]
        scopes = [[r['key'], r['kernelPath'], r['kernel'], _science.sha(_science.ROOT / r['kernelPath']), r['claim']] for r in p['mathScope']]
        assert all((any((l['key'] == r['lawKey'] and l['kernel'] == r['kernel'] and (l['kernelPath'] == r['kernelPath']) for l in p['law'])) for r in p['mathScope']))
        proofChecks = sorted({(r['kernelPath'], _science.sha(_science.ROOT / r['kernelPath']), _science.sha(_science.LEAN), 'lean-accepted-default') for r in p['mathScope']})
        engine = Engine()
        scenarios = {}
        try:
            session = engine.open_sources(dsl.read_text())
            assert session.run(queries=['gap'])['complete']
            for case in ['current', 'synthetic-all', 'stale-source', 'wrong-owner', 'wrong-seam', 'wrong-predicate', 'wrong-kernel', 'wrong-root-source', 'sample-is-source', 'kernel-is-full-semantics', 'physical-pool-inferred', 'wrong-symbol-hash', 'missing-kernel-check', 'stale-kernel-check', 'scope-inflation', 'conditional-is-native', 'extracted-is-native', 'bounds-is-native']:
                seen = copy.deepcopy(src)
                rt = copy.deepcopy(routes)
                sy = copy.deepcopy(symbols)
                rf = copy.deepcopy(ref)
                wh = copy.deepcopy(whole)
                sc = copy.deepcopy(scopes)
                pc = copy.deepcopy(proofChecks)
                if case == 'current':
                    rf = []
                    wh = []
                if case == 'missing-kernel-check':
                    pc = []
                if case == 'stale-kernel-check':
                    pc = [(x[0], 'old', x[2], x[3]) for x in pc]
                if case == 'scope-inflation':
                    sc[0][4] = 'full-native-C23-GC-closure'
                if case == 'bounds-is-native':
                    wh[0][1] = 'integer-bounds-are-native-pointer-and-whole-GC-closure'
                if case == 'extracted-is-native':
                    wh[0][1] = 'supported-cursor-family-is-whole-native-runtime'
                if case == 'conditional-is-native':
                    wh[0][1] = 'conditional-cursor-step-is-native-closure'
                if case == 'stale-source':
                    seen[0][2] = 'old'
                if case == 'wrong-owner':
                    rt[0][1] = 'collector'
                if case == 'wrong-seam':
                    rt[0][2] = 'WorkClosure'
                if case == 'wrong-predicate':
                    rt[0][5] = 'closedComplete'
                if case == 'wrong-kernel':
                    rt[0][7] = 'returnIdentityPreserved'
                if case == 'wrong-root-source':
                    rt[1][3] = 'pvm'
                if case == 'sample-is-source':
                    rf[0][1] = '500-samples-not-source-simulation'
                if case == 'kernel-is-full-semantics':
                    wh[1][1] = 'pure-slot-lemma'
                if case == 'physical-pool-inferred':
                    wh[3][1] = 'logical-worker-is-native-pool'
                if case == 'wrong-symbol-hash':
                    sy[0][2] = 'old'
                session.replace(dict(sourceNeed=src, sourceSeen=seen, routeNeed=routes, routeSeen=rt, symbolNeed=symbols, symbolSeen=sy, sourceRefinementNeed=ref, sourceRefinementSeen=rf, wholeNeed=whole, wholeSeen=wh, scopeNeed=scopes, scopeSeen=sc, kernelCheckNeed=proofChecks, kernelCheckSeen=pc, scopeKind=[[r['key'], r['kind']] for r in p['mathScope']]))
                result = session.run(queries=['routeLinked', 'gap', 'candidate', 'mathematicalClosure', 'abstractClosure', 'conditionalRefinement', 'structuralRefinement', 'cursorFamilyClosure', 'cFacingArithmetic'])
                assert result['complete']
                scenarios[case] = result['relations']
        finally:
            engine.close()
        assert [k for k, v in scenarios.items() if v['candidate']] == ['synthetic-all']
        assert len(scenarios['current']['routeLinked']) == 37
        assert len(scenarios['current']['mathematicalClosure']) == 15
        assert len(scenarios['current']['abstractClosure']) == 6 and len(scenarios['current']['conditionalRefinement']) == 3 and (len(scenarios['current']['structuralRefinement']) == 1) and (len(scenarios['current']['cursorFamilyClosure']) == 1)
        assert len(scenarios['current']['cFacingArithmetic']) == 4
        assert not scenarios['missing-kernel-check']['mathematicalClosure'] and (not scenarios['stale-kernel-check']['mathematicalClosure'])
        assert len(scenarios['scope-inflation']['mathematicalClosure']) == 14
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=scenarios, syntheticNotEvidence=True, sourceRefinement=False))
        lines = ['#+TITLE: Runtime ownership architecture — responsibilities, alternatives and proof boundaries', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitRuntimeOwnership', ':STATUS: candidate behavioral witnesses and parametric kernels; whole composition open', ':END:']
        for group in ['alternative', 'domain', 'mathScope', 'law', 'cursorStep', 'bitmapStage', 'enumerationOp', 'slotFamily', 'writerFamily', 'obligation', 'edge', 'source']:
            fields = list(p[group][0])
            lines += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(r[f]).replace('|', ' / ') for f in fields)) + ' |' for r in p[group]]
        matrix = _science.BASE / 'runtime-ownership-matrix.org'
        _study_write_text(matrix, '\n'.join(lines) + '\n')
        d2 = _science.BASE / 'diagrams/runtime-ownership.d2'
        _study_write_text(d2, 'direction: right\ntitle: "Gambit C23 target: independently owned execution, roots, work and control"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['contract']) for r in p['edge'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=h.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', 'dev/refactoring/modern-c/runtime-ownership-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', 'dev/refactoring/modern-c/runtime-ownership-matrix.org').replace('dev/architecture/toolchain/index.org', 'dev/refactoring/modern-c/index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=h.process_profile)
        for f in [_science.BASE / 'runtime-ownership-design.org', matrix, _science.BASE / 'index.org', _science.BASE / 'runtime-blueprint.org', d2, d2.with_suffix('.svg')]:
            bindings[_science.rel(f)] = _science.sha(f)
        drift = [f for f, v in bindings.items() if _science.sha(_science.ROOT / f) != v]
        _science.save(_study_workspace('CACHE') / 'source-currentness.json', dict(changedDuringCheck=drift))
        assert not drift, 'Concurrent source drift: retain attempts; refresh or bind an explicit snapshot.'
        checks = dict(nativeSysmlValidated=True, nativeSysmlScope='runtime-ownership dependency closure', nativeSysmlFiles=len(selected), wholeDevValidation=False, sysmlQueryBatches=queryBatches, sysmlQueryBatchSize=160, ownershipDomains=6, laws=37, mathematicalScopes=15, cFacingArithmeticScopes=4, nativeBoundsKernels=len(re.findall('^theorem ', (_science.BASE / 'models/lean/FrameCursorNativeBounds.lean').read_text(), re.M)), nativePointerProof=False, cursorSourceFamilyTotal=True, cursorWordObservationPremiseDischarged=True, cursorSupportedWidths=[4, 32, 64], cursorProjectionControls=len(controls), cursorWordKernels=len(re.findall('^theorem ', (_science.BASE / 'models/lean/FrameCursorWords.lean').read_text(), re.M)), cursorSliceProjection=True, cursorVerifiedExtractor=False, cursorConditionalRefinementScopes=3, cursorStructuralRefinementScopes=1, cursorRefinementKernels=len(re.findall('^theorem ', (_science.BASE / 'models/lean/FrameCursorRefinement.lean').read_text(), re.M)), cursorClosureKernels=len(re.findall('^theorem ', (_science.BASE / 'models/lean/FrameCursorClosure.lean').read_text(), re.M)), cursorAbstractTotalCorrectness=True, cursorLogicalStepBound='3*fs+2', bitmapCompositionKernels=20, frameHistories=len(re.findall('^  run .*Test=', frameq.read_text(), re.M)), cursorMicrostepSamples=sampled('cursor-microstep-samples'), cursorMicrostepMaxSteps=80, frameContractHistories=len(re.findall('^\\s*run .*Test=', contractq.read_text(), re.M)), frameSampledTraces=sampled('frame-samples'), frameContractSampledTraces=sampled('contract-samples'), enumerationOps=4, enumerationHistories=13, enumerationNegativeWitnesses=8, enumerationSampledTraces=sampled('enum-samples'), alternatives=3, sourceAnchors=len(sources), deterministicHistories=11, negativeArchitectureWitnesses=6, slotHistories=13, slotNegativeWitnesses=8, slotSampledTraces=sampled('slot-samples'), sampledTraces=sampled('samples'), allModelSamplesPassed=all((v['passed'] for v in sampleResults.values())), sampleResults=sampleResults, maxSteps=80, seed=953, exhaustiveStateProof=False, leanKernels=len(lemmas), quintToLeanExtraction=False, wholeSemanticProof=False, sourceRefinement=False, c23WeakMemoryProof=False, physicalWorkerScheduling=False, ascentScenarios=len(scenarios), unclosedObligations=len(scenarios['current']['gap']), nativeRuns=0, runtimeImplementation=False, nativeAdmission=False, pathsRetired=0)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(sourceBindings=bindings, leanBinarySha256=_science.sha(_science.LEAN), scope='candidate ownership mechanism; not repair execution or native admission'))
        for f in _study_workspace('CACHE').rglob('*'):
            if f.is_file():
                t = _study_workspace('OUT') / f.relative_to(_study_workspace('CACHE'))
                t.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(f, t)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {_science.rel(f): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks, indent=2))

# Preserved scientific source notes (in original order).
# Preserve the unchanged bounded request and its timeout evidence, then let
# independent research checks finish. A timeout is NEVER a passed sample gate.
# Conservative lexical namespace discovery selects inputs only; native SysML
# resolves and validates the selected dependency closure, never Python semantics.
# Each invocation retains the existing 60-second limit and uncached native parse.
# Extract the actual existing cursor slice, not a separately handwritten step.
