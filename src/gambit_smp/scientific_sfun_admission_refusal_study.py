"""Source-bound C23 admission/refusal research. No runtime/native compiler or tests."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import copy, hashlib, json, re, shutil
from pathlib import Path

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
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.TASK = 'sfun-admission-refusal'
        _science.BASE = _science.ROOT / 'dev/refactoring/modern-c'
        _science.LEAN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
        _science.helper = _science.context.library('size_family_hold_balance_study')
        _science.process_profile = _science.helper.process_profile

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, x):
        _study_write_text(Path(p), json.dumps(x, indent=2) + '\n')

    def rel(_science, p):
        return str(Path(p).relative_to(_science.ROOT))

    def analyze(_science):
        from ascent import Engine
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/sfun-admission-refusal/config.json').read_text())
        keys = [(g, i, f, 'GambitSfunAdmissionRefusal::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs.split()]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        model = _science.BASE / 'models/sysml' / f'{_science.TASK}.sysml'
        startModel = _science.sha(model)
        raw = _study_fields(_science.ROOT, None, 'sfun-admission-refusal', field_expressions, ordered=True, models=[str(model)])
        values = raw['orderedValues']
        assert len(values) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, values, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(rs.values()) for g, rs in p.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        sources = []
        bindings = {}
        for row in p['source']:
            file = _science.ROOT / row['path']
            text = file.read_text()
            assert row['needle'] in text
            sources.append(dict(**row, sha256=_science.sha(file), lines=[text.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(row['needle']), text)]))
            bindings[row['path']] = _science.sha(file)
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', sources)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/size-family-guard-gc/input.json'
        parentDigest = _science.sha(parent)
        pdata = json.loads(parent.read_text())
        parentFiles = ['dev/refactoring/modern-c/models/lean/SizeGuardAst.lean', 'dev/refactoring/modern-c/models/quint/size_family_guard_gc.qnt', 'src/gambit_smp/scientific_size_family_guard_gc_projection.py']
        for path in parentFiles:
            assert pdata['sourceBindings'][path] == _science.sha(_science.ROOT / path)
            bindings[path] = _science.sha(_science.ROOT / path)
        drift = [dict(path=k, previous=v, current=_science.sha(_science.ROOT / k)) for k, v in pdata['sourceBindings'].items() if _science.sha(_science.ROOT / k) != v]
        _science.save(_study_workspace('CACHE') / 'parent-currentness.json', dict(inputSha256=parentDigest, formalParentsUnchanged=True, drift=drift, parentNativeEvidenceReused=False))
        paperBase = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/sfun-converter-use-closure'
        paper = json.loads((paperBase / 'primary-paper.json').read_text())
        for name, digest in paper['files'].items():
            assert _science.sha(paperBase / name) == digest
            bindings[_science.rel(paperBase / name)] = digest
        callText = (_science.ROOT / 'vendor/gambit/lib/setup.c').read_text()
        start = callText.index('___EXP_FUNC(___SCMOBJ,___call)')
        end = callText.index('___EXP_FUNC(___SCMOBJ,___run)', start)
        body = callText[start:end]
        returns = [line.strip() for line in body.splitlines() if line.lstrip().startswith('return ')]
        assert returns == ['return ___FIX(___UNKNOWN_ERR);', 'return ___FIX(___NO_ERR);']
        macros = (_science.ROOT / 'vendor/gambit/include/_gambit/foreign_conversion.h.in').read_text()
        loops = []
        for shape in ['VOID', 'SCMOBJ', 'TYPED']:
            suffix = '_' + shape if shape != 'TYPED' else ''
            lines = [line for line in macros.splitlines() if line.startswith('#define ___SFUN_ERROR' + suffix + ' ')]
            assert len(lines) == 1
            line = lines[0]
            assert '___NO_ERR' in line and '___UNWIND_C_STACK' in line and ('___UNKNOWN_ERR' not in line) and ('___EXT(___call)' in line)
            loops.append(dict(shape=shape, line=line, gateCodeClassified=False))
        _science.save(_study_workspace('CACHE') / 'operation-inventory.json', dict(callNormalReturns=returns, sfunLoops=loops, requiresSuccessfulMarker=True, notAFullPreprocessorProof=True, nativeLibraryBindingQualified=False))
        qnt = _science.BASE / 'models/quint/sfun_admission_refusal.qnt'
        proj = _science.ROOT / 'dev/modeling/tools' / f'{_science.TASK}-projection.py'
        mod = _science.context.library('sfun_admission_refusal_projection')
        formal = [model, qnt, proj, _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_study.py', _science.ROOT / 'dev/modeling/tools' / f'{_science.TASK}-study.py'] + list((_science.BASE / 'models/lean').glob('SfunAdmission*.lean')) + [_science.ROOT / v for v in parentFiles]
        formalStart = {_science.rel(f): _science.sha(f) for f in formal}
        _science.context.command('typecheck', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, receipt = mod.generate(ir)
        assert (_science.BASE / 'models/lean/SfunAdmissionAst.lean').read_text() == ast
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**receipt, typedIrSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.BASE / 'models/lean/SfunAdmissionAst.lean')))
        controls = {}
        for label in ['binding', 'field', 'roster', 'expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if label == 'binding':
                bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
            if label == 'field':
                ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if label == 'roster':
                ds['step']['expr']['args'].pop(0)
            if label == 'expression':
                ds['safe']['expr']['opcode'] = 'not-qualified'
            try:
                mod.generate(bad)
            except (AssertionError, KeyError):
                controls[label] = 'rejected'
            else:
                raise AssertionError(label)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        modules = ['SizeGuardAst', 'SfunAdmissionAst'] + json.loads((_science.ROOT / 'dev/modeling/inputs/sfun-admission-refusal/proof-modules.json').read_text())
        lemmas = []
        proofInputs = {_science.rel(f): _science.sha(f) for f in [qnt, proj, _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE / 'models/lean' / f'{n}.lean' for n in modules]}
        proofInputs['leanBinary'] = _science.sha(Path(_science.LEAN))
        qualified = []
        for n in modules:
            file = _science.BASE / 'models/lean' / f'{n}.lean'
            assert not re.search('\\bsorry\\b|\\baxiom\\s', file.read_text())
            capsule = _study_workspace('CACHE') / ('qualified-' + n + '.json')
            prior = json.loads(capsule.read_text()) if capsule.exists() else None
            reusable = prior and prior['inputs'] == proofInputs and (_study_workspace('CACHE') / (n + '.olean')).exists() and (_science.sha(_study_workspace('CACHE') / (n + '.olean')) == prior['objectSha256']) and all((_science.sha(_science.ROOT / f) == h for f, h in prior['logs'].items())) and (_science.sha(_science.ROOT / prior['sourceSnapshot']) == prior['sourceSnapshotSha256'])
            if not reusable:
                _science.context.command('lean-' + n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(file)], policy=_science.process_profile)
                status = max(_study_workspace('CACHE').glob('lean-' + n + '-*.status.json'), key=lambda p: p.stat().st_mtime)
                stem = status.name.removesuffix('.status.json')
                snap = _study_workspace('CACHE') / (stem + '-' + file.name)
                prior = dict(inputs=proofInputs, objectSha256=_science.sha(_study_workspace('CACHE') / (n + '.olean')), logs={_science.rel(f): _science.sha(f) for f in _study_workspace('CACHE').glob(stem + '.*')}, sourceSnapshot=_science.rel(snap), sourceSnapshotSha256=_science.sha(snap), qualifiedFrom='fresh current-task formal invocation')
                _science.save(capsule, prior)
            qualified.append(dict(name=n, reused=bool(reusable), **prior))
            if n.startswith('SfunAdmission'):
                lemmas += ['SfunAdmissionBridge.' + v if n == 'SfunAdmissionBridge' else 'SfunAdmission.' + v for v in re.findall('^theorem (\\w+)', file.read_text(), re.M)]
        _science.save(_study_workspace('CACHE') / 'formal-qualified-scopes.json', qualified)
        histories = _science.context.command('histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '947'], policy=_science.process_profile)
        assert histories.count('ok ') == 14
        _science.context.command('samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '947', '--verbosity', '1'], policy=_science.process_profile)
        counters = json.loads((_science.ROOT / 'dev/modeling/inputs/sfun-admission-refusal/counter-config.json').read_text())
        for row in counters:
            label, action, part, before, after, witness, prefix = row
            folder = _study_workspace('CACHE') / ('negative-' + label)
            folder.mkdir(exist_ok=True)
            changed = []
            for line in ast.splitlines():
                if line.startswith('def ' + action + ('Guard' if part == 'GuardExtra' else part)):
                    line = line + ' ∧ (' + after + ')' if part == 'GuardExtra' else line.split(':=', 1)[0] + ':= True' if part == 'Guard' else line.replace(before, after)
                changed.append(line)
            mutant = '\n'.join(changed) + '\n'
            assert mutant != ast, label
            _study_write_text(folder / 'SfunAdmissionAst.lean', mutant)
            _science.context.command(label + '-ast', [_science.LEAN, '-o', str(folder / 'SfunAdmissionAst.olean'), str(folder / 'SfunAdmissionAst.lean')], policy=_science.process_profile)
            goal = 'Safe (' + action + 'Next witness)'
            if part == 'GuardExtra':
                text = 'import SfunAdmissionAst\nopen SfunAdmissionAst\ndef witness : State := ' + witness + '\nexample : witness = ' + prefix + ' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : ¬ ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]\n'
                line = 7
            else:
                text = 'import SfunAdmissionAst\nopen SfunAdmissionAst\ndef witness : State := ' + witness + '\nexample : witness = ' + prefix + ' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n'
                line = 8
            _study_write_text(folder / 'Control.lean', text)
            out = _science.context.command(label + '-control', ['env', 'LEAN_PATH=' + str(folder), _science.LEAN, str(folder / 'Control.lean')], expected=1, policy=_science.process_profile)
            assert out.count('error:') == 1 and 'Control.lean:' + str(line) + ':' in out, label
        _science.save(_study_workspace('CACHE') / 'countercontrols.json', [r[0] for r in counters])
        src = [[r['key'], r['path'], r['sha256'], r['needle']] for r in sources]
        routes = [[r[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for r in p['route']]
        needs = [[r['key'], r['status'], r['condition']] for r in p['need']]
        issuers = [[r[k] for k in ['key', 'source', 'existing', 'candidate', 'gap']] for r in p['issuer']]
        composition = [[r[k] for k in ['key', 'lemma', 'source', 'obligation', 'boundary']] for r in p['composition']]
        components = [[r['componentId'], r['sharedContract']] for r in p['component']]
        engine = Engine()
        results = {}
        try:
            session = engine.open_sources((_science.ROOT / 'dev/modeling/ascent' / f'{_science.TASK}.rules.scm').read_text())
            assert session.run(queries=['blocked'])['complete']
            paths = [[r[k] for k in ['key', 'producer', 'consumer', 'classification', 'phase', 'missing', 'loopStatus']] for r in p['path']]
            cases = ['current', 'synthetic-all', 'stale-source', 'missing-action', 'missing-lemma', 'wrong-component', 'forged-issuer', 'wrong-bridge', 'raw-call-is-SFUN', 'ordinary-callback-is-cleanup', 'delete-is-Scheme-call', 'mutex-is-GC-gate', 'marker-failure-enters-loop', 'global-UNKNOWN-blacklist', 'missing-native-root-adapter', 'wrong-shared-contract', 'missing-paper']
            for case in cases:
                so = copy.deepcopy(src)
                ro = copy.deepcopy(routes)
                io = copy.deepcopy(issuers)
                co = copy.deepcopy(composition)
                cn = copy.deepcopy(components)
                po = copy.deepcopy(paths)
                mo = [[r[k] for k in ['key', 'order', 'premise', 'obligation']] for r in p['memory']]
                mn = copy.deepcopy(mo)
                nr = [[case, k, s, c] for k, s, c in needs if case != 'current' or s != 'unresolved']
                if case == 'stale-source':
                    so[0][2] = 'stale'
                if case == 'wrong-component':
                    ro[0][0] = 'unrelated'
                if case == 'forged-issuer':
                    io[0][3] = 'existing verified guard signer'
                if case == 'wrong-bridge':
                    co[0][1] = 'SfunAdmission.nativeC23Complete'
                if case == 'raw-call-is-SFUN':
                    po[0][-1] = 'observed-SFUN-loop'
                if case == 'ordinary-callback-is-cleanup':
                    po[2][4] = 'OWNER_CLEANUP'
                if case == 'delete-is-Scheme-call':
                    po[4][-1] = 'observed-SFUN-loop'
                if case == 'mutex-is-GC-gate':
                    po[6][3] = 'complete-GC-admission'
                if case == 'marker-failure-enters-loop':
                    co[3][-1] = 'marker failure suffices for legacy inner retry'
                if case == 'global-UNKNOWN-blacklist':
                    mo[2][2] = 'Every UNKNOWN value means admission refusal'
                if case == 'missing-native-root-adapter':
                    nr = [r for r in nr if r[1] != 'guard-and-root-registration']
                if case == 'wrong-shared-contract':
                    cn[0][1] = 'filename-only'
                if case == 'missing-paper':
                    so = [r for r in so if r[0] != 'feeley-paper']
                session.replace(dict(scenario=[[case]], need=needs, receipt=nr, sourceNeed=src, sourceObservation=so, routeNeed=routes, routeObservation=ro, actionName=[[mod.SPEC['module'] + '.' + a] for a in mod.SPEC['actions'][1 if case == 'missing-action' else 0:]], lemmaName=[[l] for l in lemmas[1 if case == 'missing-lemma' else 0:]], issuerNeed=issuers, issuerObservation=io, compositionNeed=composition, compositionObservation=co, memoryNeed=mn, memoryObservation=mo, componentNeed=components, componentObservation=cn, pathNeed=paths, pathObservation=po))
                res = session.run(queries=['blocked', 'candidate', 'routeLinked', 'compositionLinked', 'groundingLinked', 'pathLinked'])
                assert res['complete']
                results[case] = res['relations']
        finally:
            engine.close()
        assert [k for k, v in results.items() if v['candidate']] == ['synthetic-all']
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotNativeEvidence=True))
        matrix = ['#+TITLE: SFUN admission refusal — caller reachability and net return', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML authority', ':PROPERTIES:', ':CUSTOM_ID: sfun-admission-refusal-matrix', ':AUTHORITY: GambitSfunAdmissionRefusal', ':END:', 'Formal and source-bound rows qualify only their named abstract boundaries. Native issuers remain unresolved.']
        for group in ['component', 'path', 'issuer', 'composition', 'need', 'memory', 'gain', 'route', 'source']:
            fs = list(p[group][0])
            matrix += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|'] + ['| ' + ' | '.join((str(r[k]).replace('\n', ' / ').replace('|', ' / ') for k in fs)) + ' |' for r in p[group]]
        _study_write_text(_science.BASE / f'{_science.TASK}-matrix.org', '\n'.join(matrix) + '\n')
        d2 = _science.BASE / 'diagrams' / f'{_science.TASK}.d2'
        _study_write_text(d2, 'direction: down\ntitle: "C23 SFUN admission refusal, source roots and native outcomes"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['custody']) for r in p['contract'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=_science.process_profile)
        checks = dict(sourceAnchors=len(sources), components=len(components), callerPaths=len(paths), qntActions=len(mod.SPEC['actions']), histories=14, samples=500, maxSteps=80, seed=947, leanTheorems=len(lemmas), stepInduction=True, managedModeInvariant=True, legacyRecurrenceConditional=True, legacyLoopNativeObserved=False, actualGcToSfunEdgeEstablished=False, markerSuccessRequired=True, markerFailureSkipsInnerLoop=True, callReturnInventoryExact=True, parentAdmissionPredicateBridge=True, parentFullSimulation=False, typedIrControls=len(controls), countercontrols=len(counters), ascentScenarios=len(results), compositionJoins=len(composition), actualCandidate=False, unresolved=[r['key'] for r in p['need'] if r['status'] == 'unresolved'], sourcePathNotNativeTrace=True, sourcePinIssuerQualified=False, allNativeIssuersQualified=False, c23MemoryRefinement=False, nestedGuardSubtreeRefinement=False, allAliasesClosed=False, nativePathsRetired=0, runtimeImplementation=False, nativeTests=False, nativeCompilerOrPreprocessorRun=False, performanceTests=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('OUT') / 'checks.json', checks)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for a, b in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.rel(_science.BASE / f'{_science.TASK}-design.org')), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.rel(_science.BASE / f'{_science.TASK}-matrix.org')), ('dev/architecture/toolchain/index.org', _science.rel(_science.BASE / 'index.org'))]:
            org = org.replace(a, b)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = formal + [_science.ROOT / 'dev/modeling/ascent' / f'{_science.TASK}.rules.scm', _science.BASE / f'{_science.TASK}-design.org', _science.BASE / f'{_science.TASK}-matrix.org', _science.BASE / 'index.org', d2, d2.with_suffix('.svg')] + [_study_workspace('CACHE') / n for n in ['config.json', 'model-data.json', 'proof-modules.json', 'counter-config.json']]
        bindings.update({_science.rel(f): _science.sha(f) for f in files})
        assert startModel == _science.sha(model) and parentDigest == _science.sha(parent)
        assert all((_science.sha(_science.ROOT / k) == v for k, v in formalStart.items())) and all((_science.sha(_science.ROOT / r['path']) == r['sha256'] for r in sources))
        assert all((_science.sha(_science.ROOT / k) == v for k, v in bindings.items()))
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), sourceBindings=bindings, parentInputSha256=parentDigest, parentInputPath=_science.rel(parent), leanBinarySha256=_science.sha(_science.LEAN), nativeClaim=False))
        _science.save(_study_workspace('CACHE') / 'formal-inputs.json', formalStart)
        for f in _study_workspace('CACHE').rglob('*'):
            if f.is_file():
                target = _study_workspace('OUT') / f.relative_to(_study_workspace('CACHE'))
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(f, target)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {_science.rel(f): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks, indent=2))
