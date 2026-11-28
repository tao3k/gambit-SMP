"""Source-bound formal study only; native SysML is routing authority."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import copy, hashlib, json, re, shutil, textwrap
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
        _science.textwrap = textwrap
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.STEM = 'sfun-owner-use-closure'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.LEAN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'assertion', 'failParameter': True, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, x):
        _study_write_text(Path(p), json.dumps(x, indent=2) + '\n')

    def analyze(_science):
        from ascent import Engine
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/sfun-owner-use-closure/config.json').read_text())
        keys = [(g, i, f, 'GambitSfunOwnerUseClosure::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs.split()]
        field_expressions = []
        for *_, e in keys:
            field_expressions.append(e)
        raw = _study_fields(_science.ROOT, None, 'sfun-owner-use-closure', field_expressions, ordered=True, models=[_science.BASE + 'models/sysml/' + _science.STEM + '.sysml'])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(v.values()) for g, v in p.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        sources = []
        for v in p['source']:
            data = (_science.ROOT / v['path']).read_text()
            assert v['needle'] in data
            sources.append([v['key'], v['path'], _science.sha(_science.ROOT / v['path']), v['needle']])
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', [dict(key=k, path=f, sha256=h, needle=n, lines=[s.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(n), s)]) for k, f, h, n in sources for s in [(_science.ROOT / f).read_text()]])
        qnt = _science.BASE + 'models/quint/sfun_owner_use_closure.qnt'
        proofmodules = json.loads((_science.ROOT / 'dev/modeling/inputs/sfun-owner-use-closure/proof-modules.json').read_text())
        formalpaths = [_science.BASE + 'models/lean/' + name + '.lean' for name in proofmodules] + [qnt, _science.BASE + 'models/lean/SfunOwner.lean', 'src/gambit_smp/scientific_sfun_owner_use_closure_projection.py', 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py']
        formalinputs = {f: _science.sha(_science.ROOT / f) for f in formalpaths}
        _science.context.command('typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        m = _science.context.library('sfun_owner_use_closure_projection')
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, rec = m.generate(ir)
        astpath = _science.ROOT / (_science.BASE + 'models/lean/SfunOwnerAst.lean')
        _study_write_text(astpath, ast)
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**rec, typedIrSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(astpath), c23Refinement=False))
        controls = {}
        for kind in ['binding', 'field', 'roster', 'expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if kind == 'binding':
                bad['table'][str(rec['stateReferences'][0][0])]['id'] = -1
            if kind == 'field':
                ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if kind == 'roster':
                ds['step']['expr']['args'].pop(0)
            if kind == 'expression':
                ds['safe']['expr']['opcode'] = 'unsupported'
            try:
                m.generate(bad)
            except (AssertionError, KeyError):
                controls[kind] = 'rejected'
            else:
                raise AssertionError(kind)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        _science.context.command('ast', [_science.LEAN, '-o', str(_study_workspace('CACHE') / 'SfunOwnerAst.olean'), str(astpath)], policy=_science.process_profile)
        proof = _science.ROOT / (_science.BASE + 'models/lean/SfunOwner.lean')
        assert not re.search('\\bsorry\\b|\\baxiom\\s', proof.read_text())
        proofbasis = {k: v for k, v in formalinputs.items() if not k.endswith('.lean')}
        proofbasis.update(generatedAst=_science.sha(astpath), leanBinary=_science.sha(_science.LEAN))
        qualified = []

        def scope_inputs(name, part, seen=None):
            seen = set() if seen is None else seen
            assert name not in seen, 'cyclic proof imports'
            seen = seen | {name}
            answer = {str(part.relative_to(_science.ROOT)): _science.sha(part)}
            imports = re.findall('^import (\\w+)$', part.read_text(), re.M)
            assert imports, 'proof must import the projected AST or qualified scopes'
            for dependency in imports:
                if dependency == 'SfunOwnerAst':
                    continue
                assert dependency in proofmodules, dependency
                answer.update(scope_inputs(dependency, _science.ROOT / (_science.BASE + 'models/lean/' + dependency + '.lean'), seen))
            return answer

        def qualify(name, part):
            proofinputs = dict(proofbasis, **scope_inputs(name, part))
            assert not re.search('\\bsorry\\b|\\baxiom\\s', part.read_text())
            capsule = _study_workspace('CACHE') / ('qualified-' + name + '.json')
            obj = _study_workspace('CACHE') / (name + '.olean')
            if capsule.exists():
                prior = json.loads(capsule.read_text())
                if all((prior['inputs'].get(k) == v for k, v in proofinputs.items())) and obj.exists() and (_science.sha(obj) == prior['objectSha256']) and all((_science.sha(_science.ROOT / f) == h for f, h in prior['logs'].items())):
                    qualified.append(dict(name=name, requiredInputs=proofinputs, objectSha256=prior['objectSha256'], logs=prior['logs'], reused=True))
                    return
            command = ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(obj), str(part)]
            _science.context.command('proof-' + name, command, policy=_science.process_profile)
            assert all((_science.sha(_science.ROOT / f) == h for f, h in formalinputs.items()))
            _science.save(capsule, dict(inputs=proofinputs, objectSha256=_science.sha(obj), command=command, logs={str((_study_workspace('CACHE') / ('proof-' + name + suffix)).relative_to(_science.ROOT)): _science.sha(_study_workspace('CACHE') / ('proof-' + name + suffix)) for suffix in ['.command.json', '.status.json', '.stdout', '.stderr']}))
            qualified.append(dict(name=name, requiredInputs=proofinputs, objectSha256=_science.sha(obj), logs=json.loads(capsule.read_text())['logs'], reused=False))
        for name in proofmodules:
            qualify(name, _science.ROOT / (_science.BASE + 'models/lean/' + name + '.lean'))
        qualify('SfunOwner', proof)
        _science.save(_study_workspace('CACHE') / 'formal-qualified-scopes.json', qualified)
        lemmas = [['SfunOwner.' + x] for x in re.findall('^theorem (\\w+)', '\n'.join([proof.read_text()] + [(_science.ROOT / (_science.BASE + 'models/lean/' + name + '.lean')).read_text() for name in proofmodules]), re.M)]
        histories = _science.context.command('histories', ['quint', 'test', qnt, '--match', 'Test$', '--max-samples', '1', '--seed', '521'], policy=_science.process_profile)
        assert histories.count('ok ') == 24
        _science.context.command('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '521', '--verbosity', '1'], policy=_science.process_profile)
        neg = []
        for label, action, which, before, after, witness in json.loads((_science.ROOT / 'dev/modeling/inputs/sfun-owner-use-closure/counter-config.json').read_text()):
            d = _study_workspace('CACHE') / ('negative-' + label)
            d.mkdir(exist_ok=True)
            changed = '\n'.join((line.split(':=', 1)[0] + ':= True' if which == 'GuardAll' and line.startswith('def ' + action + 'Guard') else line.replace(before, after) if which != 'GuardAll' and line.startswith('def ' + action + which) else line for line in ast.splitlines())) + '\n'
            assert changed != ast
            _study_write_text(d / 'SfunOwnerAst.lean', changed)
            _science.context.command(label + '-ast', [_science.LEAN, '-o', str(d / 'SfunOwnerAst.olean'), str(d / 'SfunOwnerAst.lean')], policy=_science.process_profile)
            goal = 'Safe (' + action + 'Next witness)'
            t = 'import SfunOwnerAst\nopen SfunOwnerAst\ndef witness : State := ' + witness + '\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n'
            _study_write_text(d / 'Control.lean', t)
            out = _science.context.command(label + '-control', ['env', 'LEAN_PATH=' + str(d), _science.LEAN, str(d / 'Control.lean')], fail=True, policy=_science.process_profile)
            assert out.count('error:') == 1 and 'Control.lean:7:' in out
            neg.append(label)
        _science.save(_study_workspace('CACHE') / 'countercontrols.json', neg)
        compat = _study_workspace('CACHE') / 'negative-origin-equality'
        compat.mkdir(exist_ok=True)
        original = (_science.ROOT / qnt).read_text()
        needle = 'action resumeOldReturn=all{s.stage==1 and s.captured==1'
        assert original.count(needle) == 1
        altered = original.replace(needle, 'action resumeOldReturn=all{s.origin==s.epoch and s.stage==1 and s.captured==1')
        _study_write_text(compat / 'sfun_owner_use_closure.qnt', altered)
        diagnostic = _science.context.command('origin-equality-compatibility', ['quint', 'test', str(compat / 'sfun_owner_use_closure.qnt'), '--match', 'twoOldResumptionsTest', '--max-samples', '1', '--seed', '521'], fail=True, policy=_science.process_profile)
        assert 'twoOldResumptionsTest' in diagnostic and 'failed' in diagnostic.lower()
        _science.save(_study_workspace('CACHE') / 'compatibility-control.json', dict(originalHistory='twoOldResumptionsTest', alteration='require origin epoch equal current invocation', expectedFailure=True, nativeCompatibilityProved=False))
        actions = [[m.SPEC['module'] + '.' + a] for a in m.SPEC['actions']]
        needs = [[v['key'], v['kind'], v['path'], _science.sha(_science.ROOT / v['path']), v['scope']] for v in p['need']]
        routes = [[v[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for v in p['route']]
        issuers = [[v[k] for k in ['key', 'proposedIssuer', 'actualSource', 'status', 'responsibility']] for v in p['issuer']]
        composition = [[v[k] for k in ['key', 'fromAction', 'toAction', 'lemma', 'fromComponent', 'toComponent', 'sharedConstraint']] for v in p['composition']]
        leaf = [[v[k] for k in ['key', 'component', 'actionName', 'lemma', 'producerAnchor', 'qualification', 'boundary']] for v in p['leaf']]
        engine = Engine()
        results = {}
        try:
            s = engine.open_sources((_science.ROOT / 'dev/modeling/ascent/sfun-owner-use-closure.rules.scm').read_text())
            assert s.run(queries=['blocked'])['complete']
            for case in ['current', 'synthetic-all', 'missing-action', 'missing-lemma', 'wrong-owner', 'stale-source', 'wrong-scope', 'wrong-issuer', 'substituted-Gambit-paper', 'missing-grounding-source', 'wrong-composition', 'missing-leaf-permit', 'wrong-leaf-boundary', 'wrong-owner-use-boundary', 'reject-old-scheme-origin', 'void-has-typed-retry']:
                receipt = [[case, n, path, h, scope] for n, kind, path, h, scope in needs if case != 'current' or kind in ['formal', 'bridge']]
                if case == 'missing-leaf-permit':
                    receipt = [row for row in receipt if row[1] != 'Sfun-release']
                observations = copy.deepcopy(sources)
                ro = copy.deepcopy(routes)
                io = copy.deepcopy(issuers)
                lo = copy.deepcopy(leaf)
                if case == 'wrong-leaf-boundary':
                    lo[3][-1] = 'Callbacks allowed after decrement before receipt'
                if case == 'wrong-owner-use-boundary':
                    lo[0][-1] = 'Any returned ___call closes its SFUN marker owner even if later conversion retry is permitted'
                if case == 'reject-old-scheme-origin':
                    lo[1][-1] = 'All live native returns require originEpoch equal to current InvocationEpoch'
                profiles = [[v[k] for k in ['key', 'repeatable', 'actionName', 'lemma', 'producerAnchor', 'boundary']] for v in p['profile']]
                pf = copy.deepcopy(profiles)
                if case == 'void-has-typed-retry':
                    pf[1][1] = 'unbounded typed result conversion retries'
                co = copy.deepcopy(composition)
                if case == 'wrong-composition':
                    co[0][3] = 'SfunOwner.settledExactlyOnce'
                papers = [[v[k] for k in ['key', 'title', 'url', 'section', 'basis', 'boundary']] for v in p['paper']]
                po = copy.deepcopy(papers)
                if case == 'substituted-Gambit-paper':
                    po[0][4] = 'OCaml documentation substitutes for Gambit primary proof'
                if case == 'missing-grounding-source':
                    observations = [v for v in observations if v[0] != 'paper-fulltext']
                if case == 'wrong-owner':
                    ro[0][0] = 'other'
                if case == 'stale-source':
                    observations[0][2] = 'stale'
                if case == 'wrong-scope':
                    receipt[0][-1] = 'native-performance'
                if case == 'wrong-issuer':
                    io[0][3] = 'existing verified signer'
                s.replace(dict(profileNeed=profiles, profileObservation=pf, leafNeed=leaf, leafObservation=lo, compositionNeed=composition, compositionObservation=co, scenario=[[case]], need=needs, needOwner=[[v['key'], v['owner.componentId']] for v in p['need']], receipt=receipt, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=lemmas[1:] if case == 'missing-lemma' else lemmas, sourceNeed=sources, sourceObservation=observations, routeNeed=routes, routeObservation=ro, proofNeed=[[v['key'], v['lemma']] for v in p['proof']], issuerNeed=issuers, issuerObservation=io, paperNeed=papers, paperObservation=po, groundingNeed=[[v[k] for k in ['component', 'producerAnchor', 'paperKey', 'obligationId']] for v in p['grounding']]))
                res = s.run(queries=['candidate', 'blocked', 'routeLinked', 'proofLinked', 'paperLinked', 'groundingLinked', 'compositionLinked', 'leafLinked', 'profileLinked'])
                assert res['complete']
                results[case] = res['relations']
        finally:
            engine.close()
        assert [k for k, v in results.items() if v['candidate']] == ['synthetic-all']
        gaps = sorted((v[1] for v in results['current']['blocked']))
        assert len(gaps) == 5
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotNativeEvidence=True))
        matrix = ['#+TITLE: SFUN marker reuse, final use and receipt identity — net benefit matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML evaluated authority', ':PROPERTIES:', ':CUSTOM_ID: sfun-owner-use-closure-matrix', ':AUTHORITY: GambitSfunOwnerUseClosure', ':END:', 'Generated rows below come from the native SysML evaluator. No native issuer is qualified by a formal route.']
        for group in ['role', 'profile', 'leaf', 'composition', 'gain', 'memory', 'issuer', 'paper', 'grounding', 'need', 'route', 'proof', 'source']:
            fields = list(p[group][0])
            matrix += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|'] + ['| ' + ' | '.join((v[f] for f in fields)) + ' |' for v in p[group]]
        matrix += ['', '** Closure', '', '| Obligation | Receipt |', '|---+---|'] + ['| ' + v['key'] + ' | ' + ('Unresolved native contract' if v['key'] in gaps else 'Scoped conditional formal evidence') + ' |' for v in p['need']]
        _study_write_text(_science.ROOT / (_science.BASE + _science.STEM + '-matrix.org'), '\n'.join(matrix) + '\n')
        graph = ['direction: down', 'title: "C23 SFUN owner closure, current invocation and multi-shot Scheme control"'] + [json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 38)) for v in p['contract']]
        d2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _study_write_text(_science.ROOT / d2, '\n'.join(graph) + '\n')
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', d2, d2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', d2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(baseline='C23', sourceAnchors=len(sources), qntActions=len(actions), histories=24, samples=500, maxSteps=80, seedArgument=521, leanTheorems=len(lemmas), allStepInduction=True, typedIrControls=len(controls), countercontrols=len(neg), compatibilityControls=1, ascentScenarios=len(results), routes=len(routes), blockers=gaps, actualCandidate=False, compositionJoins=len(composition), leafQualificationConditions=len(leaf), sourceProfiles=len(profiles), modelProfile='general typed result with successfully rooted owner', boundedOwnerGenerations=2, boundedCallsPerOwner=4, boundedSchemeShots=2, boundedNestedBorrowers=1, physicalEffectReceiptGapModeled=True, oldSchemeOriginDistinctFromReceiptIdentity=True, normalAndEscapedOwnerClosureDistinct=True, noAbandonNativePremiseAssumed=True, noAbandonNativeQualificationProved=False, c23RefinementProved=False, allAliasesClosed=False, globalImageRetirementProved=False, parentModelSimulationProved=False, sourcePathArgumentNotNativeTrace=True, fullContinuationEquivalenceProved=False, converterUseClosureProved=False, nativePathsRetired=0, runtimeImplementation=False, nativeTestsRun=False, performanceTestsRun=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/catcher-landing-marker-settlement/input.json'
        parenthash = _science.sha(parent)
        pdata = json.loads(parent.read_text())
        composition = {f: _science.sha(_science.ROOT / f) for f in pdata['compositionInputs']}
        drift = [dict(path=f, parent=h, current=composition[f]) for f, h in pdata['compositionInputs'].items() if h != composition[f]]
        _science.save(_study_workspace('CACHE') / 'parent-composition-drift.json', drift)
        checks.update(parentRuntimeInputDrift=len(drift), parentEvidenceReusedAsCurrentNative=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        paths = set((_science.BASE + 'models/lean/' + name + '.lean' for name in proofmodules)) | {v[1] for v in sources} | {'.cache/tasks/' + _science.STEM + '/' + name for name in ['feeley-sfp-paper.ps', 'feeley-sfp-paper.pdf', 'primary-paper.json', 'external-evidence.json']} | {_science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'index.org', _science.BASE + 'models/sysml/' + _science.STEM + '.sysml', qnt, str(astpath.relative_to(_science.ROOT)), str(proof.relative_to(_science.ROOT)), d2, d2[:-3] + '.svg', _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', '.cache/tasks/' + _science.STEM + '/config.json', '.cache/tasks/' + _science.STEM + '/model-data.json', '.cache/tasks/' + _science.STEM + '/proof-modules.json'}
        data = dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), parentPath=str(parent.relative_to(_science.ROOT)), parentInputSha256=parenthash, sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(paths)}, compositionInputs=composition)
        _science.save(_study_workspace('CACHE') / 'input.json', data)

        def receipts():
            for f in _study_workspace('CACHE').iterdir():
                if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr', '.ps', '.pdf', '.txt']:
                    shutil.copyfile(f, _study_workspace('OUT') / f.name)
        receipts()
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for a, b in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.BASE + _science.STEM + '-design.org'), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.BASE + _science.STEM + '-matrix.org'), ('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')]:
            org = org.replace(a, b)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org-check', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        assert _science.sha(parent) == parenthash and all((_science.sha(_science.ROOT / f) == h for f, h in data['sourceBindings'].items()))
        assert all((_science.sha(_science.ROOT / f) == h for f, h in formalinputs.items())), 'formal input drift'
        assert all((_science.sha(_science.ROOT / f) == h for f, h in composition.items())), 'composition drift'
        _science.save(_study_workspace('CACHE') / 'formal-inputs.json', formalinputs)
        data['logs'] = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}
        _science.save(_study_workspace('CACHE') / 'input.json', data)
        receipts()
        for d in list(_study_workspace('CACHE').glob('negative-*')) + list(_study_workspace('CACHE').glob('retained-*')):
            if d.is_dir():
                shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Preserve every prior invocation separately; never bind a stale timeout to a new success.
# Source-bound formal receipts allow later controls to resume without recompiling passed scopes.
# Countercontrols use Safe admissible witnesses also matched by complete actual-QNT prefix histories.
