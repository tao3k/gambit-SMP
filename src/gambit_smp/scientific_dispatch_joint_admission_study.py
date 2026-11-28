"""C23 Tcl source custody research; native SysML, ASCENT, QNT and Lean only."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy, hashlib, json, re, shutil, time
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.hashlib = hashlib
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.time = time
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.TASK = 'dispatch-joint-admission'
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
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/dispatch-joint-admission/config.json').read_text())
        keys = [(g, i, f, 'GambitDispatchJointAdmission::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs.split()]
        model = _science.BASE / 'models/sysml' / f'{_science.TASK}.sysml'
        modelHash = _science.sha(model)
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'dispatch-joint-admission', field_expressions, ordered=True, models=[str(model)])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(rs.values()) for g, rs in p.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        bindings = {}
        sources = []
        snaps = _study_workspace('CACHE') / 'source-snapshots'
        snaps.mkdir(exist_ok=True)
        for row in p['source']:
            file = _science.ROOT / row['path']
            b = file.read_bytes()
            text = b.decode()
            assert row['needle'] in text
            digest = _science.sha(file)
            snapshot = snaps / (digest + '.txt')
            if snapshot.exists():
                assert snapshot.read_bytes() == b
            else:
                _study_write_bytes(snapshot, b)
            sources.append(dict(**row, sha256=digest, snapshot=_science.rel(snapshot), lines=[text.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(row['needle']), text)]))
            bindings[row['path']] = digest
        old = _study_workspace('CACHE') / 'source-witnesses.json'
        if old.exists():
            shutil.copyfile(old, _study_workspace('CACHE') / ('source-witnesses-' + str(time.time_ns()) + '.json'))
        _science.save(old, sources)
        pinned = json.loads((_study_workspace('CACHE') / 'pinned-tcl-sources.json').read_text())
        for r in pinned['records']:
            f = _science.ROOT / r['capturePath']
            b = f.read_bytes()
            assert _science.sha(f) == r['sha256'] and hashlib.sha1(b'blob ' + str(len(b)).encode() + b'\x00' + b).hexdigest() == r['gitBlobSha1']
        paper = json.loads((_science.ROOT / 'dev/modeling/inputs/dispatch-joint-admission/pvm-paper-source.json').read_text())
        for name, h in paper['files'].items():
            file = _study_workspace('CACHE') / name
            assert _science.sha(file) == h
            canonical = _science.ROOT / paper['canonicalFiles'][name]
            assert _science.sha(canonical) == h
            bindings[_science.rel(canonical)] = h
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/tcl-source-borrow/input.json'
        parentHash = _science.sha(parent)
        pdata = json.loads(parent.read_text())
        parentAst = _science.BASE / 'models/lean/TclBorrowAst.lean'
        assert pdata['sourceBindings'][_science.rel(parentAst)] == _science.sha(parentAst)
        bindings[_science.rel(parentAst)] = _science.sha(parentAst)
        for name in ['TclRefusalAst.lean']:
            f = _science.BASE / 'models/lean' / name
            assert pdata['sourceBindings'][_science.rel(f)] == _science.sha(f)
            bindings[_science.rel(f)] = _science.sha(f)
        _science.save(_study_workspace('CACHE') / 'parent-currentness.json', dict(parentSha256=parentHash, formalParentUnchanged=True, nativeEvidenceReused=False, drift=[dict(path=k, previous=v, current=_science.sha(_science.ROOT / k)) for k, v in pdata['sourceBindings'].items() if _science.sha(_science.ROOT / k) != v]))
        data = json.loads((_science.ROOT / 'dev/modeling/inputs/dispatch-joint-admission/model-data.json').read_text())
        asts = {}
        actions = []
        projections = []
        formal = [model, parentAst, Path(str(_science.context.root / 'src/gambit_smp/scientific_dispatch_joint_admission_study.py')), _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_study.py']
        for group, d in data.items():
            qnt = _science.BASE / 'models/quint' / (d['name'] + '.qnt')
            projector = _science.ROOT / 'dev/modeling/tools' / (d['name'].replace('_', '-') + '-projection.py')
            mod = _science.context.library(d['name'] + '_projection')
            _science.context.command(group + '-typecheck', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / (group + '-ir.json'))], policy=_science.process_profile)
            ir = json.loads((_study_workspace('CACHE') / (group + '-ir.json')).read_text())
            ast, receipt = mod.generate(ir)
            assert (_science.BASE / 'models/lean' / (d['namespace'] + '.lean')).read_text() == ast
            asts[group] = ast
            controls = {}
            for label in ['binding', 'field', 'roster', 'expression']:
                bad = copy.deepcopy(ir)
                ds = {x['name']: x for x in bad['modules'][0]['declarations']}
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
            _science.save(_study_workspace('CACHE') / (group + '-projection.json'), dict(**receipt, typedIrSha256=_science.sha(_study_workspace('CACHE') / (group + '-ir.json')), astSha256=_science.sha(_science.BASE / 'models/lean' / (d['namespace'] + '.lean')), controls=controls))
            projections.append(receipt)
            actions += [[d['name'] + '.' + a] for a in d['actions']]
            formal += [qnt, projector]
        modules = ['TclBorrowAst', 'TclRefusalAst', 'DispatchJointAst'] + json.loads((_science.ROOT / 'dev/modeling/inputs/dispatch-joint-admission/proof-modules.json').read_text())
        lemmas = []
        formal += [_science.BASE / 'models/lean' / (n + '.lean') for n in modules]
        formalStart = {_science.rel(f): _science.sha(f) for f in formal}
        proofInputs = {k: v for k, v in formalStart.items() if k.endswith(('.lean', '.qnt')) or 'projection.py' in k}
        proofInputs['leanBinary'] = _science.sha(_science.LEAN)
        qualified = []
        for n in modules:
            file = _science.BASE / 'models/lean' / (n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', file.read_text())
            capsule = _study_workspace('CACHE') / ('qualified-' + n + '.json')
            prior = json.loads(capsule.read_text()) if capsule.exists() else None
            reusable = prior and prior['inputs'] == proofInputs and (_study_workspace('CACHE') / (n + '.olean')).exists() and (_science.sha(_study_workspace('CACHE') / (n + '.olean')) == prior['objectSha256']) and all((_science.sha(_science.ROOT / f) == h for f, h in prior['logs'].items())) and (_science.sha(_science.ROOT / prior['sourceSnapshot']) == prior['sourceSnapshotSha256'])
            if not reusable:
                _science.context.command('lean-' + n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(file)], policy=_science.process_profile)
                status = max(_study_workspace('CACHE').glob('lean-' + n + '-*.status.json'), key=lambda f: f.stat().st_mtime)
                stem = status.name.removesuffix('.status.json')
                snap = _study_workspace('CACHE') / (stem + '-' + file.name)
                prior = dict(inputs=proofInputs, objectSha256=_science.sha(_study_workspace('CACHE') / (n + '.olean')), logs={_science.rel(f): _science.sha(f) for f in _study_workspace('CACHE').glob(stem + '.*')}, sourceSnapshot=_science.rel(snap), sourceSnapshotSha256=_science.sha(snap))
                _science.save(capsule, prior)
            qualified.append(dict(name=n, reused=bool(reusable), **prior))
            ns = 'DispatchJointBridge' if n == 'DispatchJointBridge' else 'DispatchJoint'
            if not n.endswith('Ast'):
                lemmas += [ns + '.' + v for v in re.findall('^theorem (\\w+)', file.read_text(), re.M)]
        _science.save(_study_workspace('CACHE') / 'formal-qualified-scopes.json', qualified)
        for group, d in data.items():
            qnt = _science.BASE / 'models/quint' / (d['name'] + '.qnt')
            hist = _science.context.command(group + '-histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=_science.process_profile)
            assert hist.count('ok ') == len(d['histories'])
            _science.context.command(group + '-samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=_science.process_profile)
        counters = json.loads((_science.ROOT / 'dev/modeling/inputs/dispatch-joint-admission/counter-config.json').read_text())
        for label, group, action, part, before, after, witness, prefix in counters:
            folder = _study_workspace('CACHE') / ('negative-' + label)
            folder.mkdir(exist_ok=True)
            ns = data[group]['namespace']
            changed = []
            for line in asts[group].splitlines():
                if line.startswith('def ' + action + ('Next' if part == 'AppendNext' else part)):
                    line = line.split(':=', 1)[0] + ':= True' if part == 'Guard' else line.rstrip()[:-1] + ', ' + after + '}' if part == 'AppendNext' else line.replace(before, after)
                changed.append(line)
            mutant = '\n'.join(changed) + '\n'
            assert mutant != asts[group]
            _study_write_text(folder / (ns + '.lean'), mutant)
            _science.context.command(label + '-ast', [_science.LEAN, '-o', str(folder / (ns + '.olean')), str(folder / (ns + '.lean'))], policy=_science.process_profile)
            sequence = list(reversed(re.findall('(\\w+)Next \\(', prefix)))
            prior = 'initial'
            guards = []
            defs = []
            for step in sequence:
                guards.append('example : ' + step + 'Guard (' + prior + ') := by simp [' + ','.join([step + 'Guard', 'initial'] + defs) + ']')
                prior = step + 'Next (' + prior + ')'
                defs.append(step + 'Next')
            guardText = '\n'.join(guards) + '\n'
            goal = 'Safe (' + action + 'Next witness)'
            text = 'import ' + ns + '\nopen ' + ns + '\ndef witness : State := ' + witness + '\nexample : witness = ' + prefix + ' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n'
            text = text.replace('example : witness =', guardText + 'example : witness =')
            failureLine = 8 + len(guards)
            _study_write_text(folder / 'Control.lean', text)
            out = _science.context.command(label + '-control', ['env', 'LEAN_PATH=' + str(folder), _science.LEAN, str(folder / 'Control.lean')], expected=1, policy=_science.process_profile)
            assert out.count('error:') == 1 and 'Control.lean:' + str(failureLine) + ':' in out, label
        _science.save(_study_workspace('CACHE') / 'countercontrols.json', [r[0] for r in counters])
        src = [[r[k] for k in ['key', 'path', 'sha256', 'needle']] for r in sources]

        def rows(g, fs):
            return [[r[k] for k in fs.split()] for r in p[g]]
        routes = rows('route', 'component actionName lemma producerAnchor obligationId')
        needs = rows('need', 'key status condition')
        issuers = rows('issuer', 'key source existing candidate gap')
        composition = rows('composition', 'key lemma source obligation boundary')
        components = rows('component', 'componentId sharedContract')
        paths = rows('path', 'key producer consumer classification missing')
        memory = rows('memory', 'key order premise obligation')
        results = {}
        engine = Engine()
        try:
            session = engine.open_sources((_science.ROOT / 'dev/modeling/ascent' / f'{_science.TASK}.rules.scm').read_text())
            assert session.run(queries=['blocked'])['complete']
            cases = ['current', 'synthetic-all', 'stale-source', 'missing-action', 'missing-lemma', 'wrong-component', 'forged-issuer', 'wrong-bridge', 'gc-waits-native-scope', 'scheduler-means-quiescence', 'registration-means-domain-lock', 'unmanaged-needs-no-accounting', 'shared-mail-is-isolated', 'paper-already-implements-service', 'normal-free-is-Scheme-reentry', 'raw-setters-closed', 'refusal-calls-Scheme', 'missing-finisher', 'wrong-shared-contract', 'missing-paper']
            learning = rows('learning', 'key source mechanism fact mismatch candidate status')
            for case in cases:
                so = copy.deepcopy(src)
                ro = copy.deepcopy(routes)
                io = copy.deepcopy(issuers)
                co = copy.deepcopy(composition)
                cn = copy.deepcopy(components)
                po = copy.deepcopy(paths)
                mo = copy.deepcopy(memory)
                lo = copy.deepcopy(learning)
                aa = copy.deepcopy(actions)
                ll = [[l] for l in lemmas]
                nr = [[case, k, t, c] for k, t, c in needs if case != 'current' or t != 'unresolved']
                if case == 'stale-source':
                    so[0][2] = 'stale'
                if case == 'missing-action':
                    aa = aa[1:]
                if case == 'missing-lemma':
                    ll = ll[1:]
                if case == 'wrong-component':
                    ro[0][0] = 'other'
                if case == 'forged-issuer':
                    io[0][3] = 'already verified'
                if case == 'wrong-bridge':
                    co[0][1] = 'DispatchJointBridge.nativeC23Complete'
                if case == 'gc-waits-native-scope':
                    mo[2][2] = 'all native scopes must exit before GC freeze'
                if case == 'scheduler-means-quiescence':
                    lo[3][5] = 'any Scheme yield proves native C references dropped'
                if case == 'registration-means-domain-lock':
                    lo[1][3] = 'registered thread automatically holds domain access'
                if case == 'unmanaged-needs-no-accounting':
                    lo[4][3] = 'unmanaged readers need no delay handle'
                if case == 'shared-mail-is-isolated':
                    lo[5][5] = 'copy all Scheme messages without alias change'
                if case == 'paper-already-implements-service':
                    lo[0][3] = 'paper implements the C23 joint source service'
                if case == 'normal-free-is-Scheme-reentry':
                    po[4][3] = 'observed Scheme reentry from release_string'
                if case == 'raw-setters-closed':
                    po[2][-1] = 'all public writers closed'
                if case == 'refusal-calls-Scheme':
                    io[4][3] = 'invoke old Scheme error translator on refusal'
                if case == 'missing-finisher':
                    nr = [r for r in nr if r[1] != 'stable-finisher']
                if case == 'wrong-shared-contract':
                    cn[0][1] = 'filename-only'
                if case == 'missing-paper':
                    so = [r for r in so if r[0] != 'feeley-paper']
                session.replace(dict(scenario=[[case]], need=needs, receipt=nr, sourceNeed=src, sourceObservation=so, routeNeed=routes, routeObservation=ro, actionName=aa, lemmaName=ll, issuerNeed=issuers, issuerObservation=io, compositionNeed=composition, compositionObservation=co, memoryNeed=memory, memoryObservation=mo, componentNeed=components, componentObservation=cn, pathNeed=paths, pathObservation=po, learningNeed=learning, learningObservation=lo))
                res = session.run(queries=['blocked', 'candidate', 'routeLinked', 'compositionLinked', 'groundingLinked', 'pathLinked', 'learningLinked'])
                assert res['complete']
                results[case] = res['relations']
        finally:
            engine.close()
        assert [k for k, v in results.items() if v['candidate']] == ['synthetic-all']
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotNativeEvidence=True))
        matrix = ['#+TITLE: Native-scope admission — learning, custody and net return', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML authority', ':PROPERTIES:', ':CUSTOM_ID: dispatch-joint-admission-matrix', ':AUTHORITY: GambitDispatchJointAdmission', ':END:', 'Formal and source-bound rows qualify only their named abstract boundaries. Native issuers remain unresolved.']
        for group in ['component', 'learning', 'profile', 'path', 'issuer', 'composition', 'need', 'memory', 'gain', 'route', 'source']:
            fs = list(p[group][0])
            matrix += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|'] + ['| ' + ' | '.join((str(r[k]).replace('\n', ' / ').replace('|', ' / ') for k in fs)) + ' |' for r in p[group]]
        _study_write_text(_science.BASE / f'{_science.TASK}-matrix.org', '\n'.join(matrix) + '\n')
        d2 = _science.BASE / 'diagrams' / f'{_science.TASK}.d2'
        _study_write_text(d2, 'direction: down\ntitle: "C23 native-scope grace, joint root admission and whole-runtime learning"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['custody']) for r in p['contract'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=_science.process_profile)
        checks = dict(sourceAnchors=len(sources), pinnedTclFiles=len(pinned['records']), components=len(components), callerPaths=len(paths), qntActions=len(actions), borrowSafetyOnly=True, nativeScopeCensusQualified=False, histories=sum((len(d['histories']) for d in data.values())), samplesPerModel=500, maxSteps=80, seed=953, leanTheorems=len(lemmas), stepInduction=True, typedIrControls=4, countercontrols=len(counters), ascentScenarios=len(results), compositionJoins=len(composition), learningRows=len(p['learning']), actualCandidate=False, unresolved=[r['key'] for r in p['need'] if r['status'] == 'unresolved'], sourcePinPredicateBridge=True, parentFullSimulation=False, sourceBorrowIssuerQualified=False, stableFinisherQualified=False, actualSmpScalingClaim=False, loadedTclIdentityQualified=False, c23MemoryRefinement=False, slotValueFidelity=False, destinationCompletionRefined=False, nativePathsRetired=0, runtimeImplementation=False, nativeTests=False, nativeCompilerOrPreprocessorRun=False, performanceTests=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('OUT') / 'checks.json', checks)
        shutil.copyfile(_study_workspace('CACHE') / 'pinned-tcl-sources.json', _study_workspace('OUT') / 'pinned-tcl-sources.json')
        shutil.copyfile(_study_workspace('CACHE') / 'reference-revisions.json', _study_workspace('OUT') / 'reference-revisions.json')
        shutil.copyfile(_study_workspace('CACHE') / 'pvm-paper-source.json', _study_workspace('OUT') / 'pvm-paper-source.json')
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for a, b in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.rel(_science.BASE / f'{_science.TASK}-design.org')), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.rel(_science.BASE / f'{_science.TASK}-matrix.org')), ('dev/architecture/toolchain/index.org', _science.rel(_science.BASE / 'index.org'))]:
            org = org.replace(a, b)
        org = org.replace(')) (links 0)', ' "dev/refactoring/modern-c/runtime-blueprint.org" "dev/knowledge/ocaml/index.org" "dev/knowledge/erlang/index.org")) (links 0)')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = formal + [_science.ROOT / 'dev/modeling/ascent' / f'{_science.TASK}.rules.scm', _science.BASE / f'{_science.TASK}-design.org', _science.BASE / f'{_science.TASK}-matrix.org', _science.BASE / 'index.org', _science.BASE / 'runtime-blueprint.org', _science.ROOT / 'dev/knowledge/ocaml/index.org', _science.ROOT / 'dev/knowledge/erlang/index.org', d2, d2.with_suffix('.svg')] + [_study_workspace('CACHE') / n for n in ['config.json', 'model-data.json', 'proof-modules.json', 'counter-config.json', 'pinned-tcl-sources.json', 'reference-revisions.json', 'pvm-paper-source.json']]
        bindings.update({_science.rel(f): _science.sha(f) for f in files})
        assert modelHash == _science.sha(model) and parentHash == _science.sha(parent)
        assert all((_science.sha(_science.ROOT / k) == v for k, v in formalStart.items()))
        assert all((_science.sha(_science.ROOT / k) == v for k, v in bindings.items()))
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), sourceBindings=bindings, parentInputSha256=parentHash, parentInputPath=_science.rel(parent), leanBinarySha256=_science.sha(_science.LEAN), nativeClaim=False))
        _science.save(_study_workspace('CACHE') / 'formal-inputs.json', formalStart)
        for f in _study_workspace('CACHE').rglob('*'):
            if f.is_file():
                t = _study_workspace('OUT') / f.relative_to(_study_workspace('CACHE'))
                t.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(f, t)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {_science.rel(f): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks, indent=2))
