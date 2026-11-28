"""Research-only native SysML routing, ASCENT DSL, QNT and Lean checks.
No native compiler, preprocessor, runtime build, benchmark or test is invoked.
"""
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
        _science.TASK = 'size-family-hold-balance'
        _science.BASE = _science.ROOT / 'dev/refactoring/modern-c'
        _science.LEAN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'assertion', 'failParameter': False, 'expectedParameter': True}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, v):
        _study_write_text(Path(p), json.dumps(v, indent=2) + '\n')

    def rel(_science, p):
        try:
            return str(Path(p).relative_to(_science.ROOT))
        except ValueError:
            return str(p)

    def analyze(_science):
        from ascent import Engine
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/size-family-hold-balance/config.json').read_text())
        keys = [(g, i, f, 'GambitSizeFamilyHoldBalance::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs.split()]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        model = _science.BASE / 'models/sysml' / f'{_science.TASK}.sysml'
        raw = _study_fields(_science.ROOT, None, 'size-family-hold-balance', field_expressions, ordered=True, models=[str(model)])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(rs.values()) for g, rs in p.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        sources = []
        bindings = {}
        for row in p['source']:
            path = _science.ROOT / row['path']
            data = path.read_text()
            assert row['needle'] in data
            sources.append(dict(**row, sha256=_science.sha(path), lines=[data.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(row['needle']), data)]))
            bindings[row['path']] = _science.sha(path)
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', sources)
        paperBase = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/sfun-converter-use-closure'
        paper = json.loads((paperBase / 'primary-paper.json').read_text())
        for name, digest in paper['files'].items():
            file = paperBase / name
            assert _science.sha(file) == digest
            bindings[_science.rel(file)] = digest
        header = _science.ROOT / 'vendor/gambit/include/_gambit/foreign_conversion.h.in'
        text = header.read_text()
        registry = (_science.ROOT / 'vendor/gambit/gsc/_parms.scm').read_text()
        inventory = []
        for family in ['SIZE_T', 'SSIZE_T', 'PTRDIFF_T']:
            typ = family.lower()
            assert re.search('\\(cons ' + typ + '-sym\\s+\\(vector \\\'c-type.*?"' + family + '_TO_SCMOBJ"\\s+"SCMOBJ_TO_' + family + '"\\s+#f\\)\\)', registry, re.S)
            for d, args, end in [('SFUN', 'c,s,i', '}'), ('CFUN', 'c,s', '')]:
                pattern = '^#define ___END_' + d + '_' + family + '_TO_SCMOBJ\\(' + args + '\\)([^\\n]*)$'
                match = re.search(pattern, text, re.M)
                assert match and match.group(1) == end
                inventory.append(dict(family=family, direction=d, endEffect=end or 'empty', automaticRelease=False))
        _science.save(_study_workspace('CACHE') / 'macro-inventory.json', inventory)
        output = _science.context.command('release-writer-inventory', ['rg', '-n', 'still_obj_refcount_dec|release_scmobj|STILL_REFCOUNT.*(--|-=|=)|free_still_objs', 'vendor/gambit/lib', 'vendor/gambit/include/_gambit', '-g', '*.inc', '-g', '*.c', '-g', '*.scm', '-g', '*.in'], policy=_science.process_profile)
        hits = output.splitlines()
        _science.save(_study_workspace('CACHE') / 'release-writer-inventory.json', dict(pattern='still decrement/release/init/teardown', rows=hits, openIndirectAliases=True, notAnAllWritersProof=True))
        for line in hits:
            path = line.split(':', 1)[0]
            bindings[path] = _science.sha(_science.ROOT / path)
        profile = p['profile'][0]
        power = 1 << int(profile['fixWidth']) - 1
        assert profile['minimum'] == str(-power) and profile['maximum'] == str(power - 1)
        assert int(profile['bits']) == 64 and profile['unsignedMax'] == str(2 ** 64 - 1)
        assert profile['signedMin'] == str(-2 ** 63) and profile['signedMax'] == str(2 ** 63 - 1)
        qnt = _science.BASE / 'models/quint/size_family_hold_balance.qnt'
        _science.context.command('quint-typecheck', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        proj = _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_projection.py'
        mod = _science.context.library('size_family_hold_balance_projection')
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, receipt = mod.generate(ir)
        astpath = _science.BASE / 'models/lean/SizeHoldAst.lean'
        assert astpath.read_text() == ast
        assert str(2 ** 64 - 1) in ast and str(2 ** 63 - 1) in ast
        assert str(power) in ast and '(-(' + str(power) + '))' in ast and (str(power - 1) in ast)
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**receipt, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(astpath)))
        ctrls = {}
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
                ds['safe']['expr']['opcode'] = 'unqualified'
            try:
                mod.generate(bad)
            except (AssertionError, KeyError):
                ctrls[label] = 'rejected'
            else:
                raise AssertionError(label)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', ctrls)
        formalStart = {_science.rel(f): _science.sha(f) for f in [model, qnt, proj, _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + list((_science.BASE / 'models/lean').glob('SizeHold*.lean'))}
        modules = ['SizeHoldAst'] + json.loads((_science.ROOT / 'dev/modeling/inputs/size-family-hold-balance/proof-modules.json').read_text())
        lemmas = []
        for name in modules:
            source = _science.BASE / 'models/lean' / f'{name}.lean'
            assert not re.search('\\bsorry\\b|\\baxiom\\s', source.read_text())
            _science.context.command('lean-' + name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(source)], policy=_science.process_profile)
            lemmas += ['SizeHold.' + n for n in re.findall('^theorem (\\w+)', source.read_text(), re.M)]
        result = _science.context.command('quint-histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '521'], policy=_science.process_profile)
        assert result.count('ok ') == 8
        _science.context.command('quint-samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '521', '--verbosity', '1'], policy=_science.process_profile)
        negative = [('missing-drop', 'physicalDrop', 'Next', 'hold:=(0)', 'hold:=(q.hold)', '{initial with phase:=4,x:=18446744073709551615,created:=1,hold:=1,critical:=1,exited:=1}'), ('double-drop', 'physicalDrop', 'Next', 'effects:=q.created', 'effects:=(q.created+1)', '{initial with phase:=4,x:=18446744073709551615,created:=1,hold:=1,critical:=1,exited:=1}'), ('unrooted-cfun', 'finishNative', 'Guard', None, None, '{initial with phase:=2,direction:=1,x:=1152921504606846976,created:=1,hold:=1}'), ('gc-in-effect-gap', 'beginGc', 'Guard', None, None, '{initial with phase:=4,x:=18446744073709551615,created:=1,hold:=1,critical:=1,exited:=1}')]
        for label, action, part, before, after, witness in negative:
            folder = _study_workspace('CACHE') / ('negative-' + label)
            folder.mkdir(exist_ok=True)
            lines = []
            for line in ast.splitlines():
                if line.startswith('def ' + action + part):
                    line = line.split(':=', 1)[0] + ':= True' if part == 'Guard' else line.replace(before, after)
                lines.append(line)
            mutant = '\n'.join(lines) + '\n'
            assert mutant != ast
            path = folder / 'SizeHoldAst.lean'
            _study_write_text(path, mutant)
            _science.context.command(label + '-ast', [_science.LEAN, '-o', str(folder / 'SizeHoldAst.olean'), str(path)], policy=_science.process_profile)
            goal = 'Safe (' + action + 'Next witness)'
            prefix = 'convertBoxedNext (selectAboveFixNext initial)' if label == 'unrooted-cfun' else 'enterDropNext (finishNativeNext (convertBoxedNext (selectSizeMaxNext initial)))'
            test = 'import SizeHoldAst\nopen SizeHoldAst\ndef witness : State := ' + witness + '\nexample : witness = ' + prefix + ' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n'
            path = folder / 'Control.lean'
            _study_write_text(path, test)
            out = _science.context.command(label + '-control', ['env', 'LEAN_PATH=' + str(folder), _science.LEAN, str(path)], expected=1, policy=_science.process_profile)
            assert out.count('error:') == 1 and 'Control.lean:8:' in out
        _science.save(_study_workspace('CACHE') / 'countercontrols.json', [v[0] for v in negative])
        needs = [[r['key'], r['status'], r['condition']] for r in p['need']]
        src = [[r['key'], r['path'], r['sha256'], r['needle']] for r in sources]
        routes = [[r[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for r in p['route']]
        profiles = [[r[k] for k in ['key', 'fixWidth', 'minimum', 'maximum', 'status']] for r in p['profile']]
        engine = Engine()
        results = {}
        try:
            session = engine.open_sources((_science.ROOT / 'dev/modeling/ascent' / f'{_science.TASK}.rules.scm').read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in ['current', 'synthetic-all', 'wrong-source', 'missing-action', 'missing-proof', 'wrong-component', 'wrong-boundary', 'wrong-release-direction', 'GC-is-release', 'forged-native-cohort']:
                so = copy.deepcopy(src)
                ro = copy.deepcopy(routes)
                po = copy.deepcopy(profiles)
                iv = copy.deepcopy(inventory)
                needrows = [[case, k, s, c] for k, s, c in needs if case != 'current' or s != 'unresolved']
                if case == 'wrong-source':
                    so[0][2] = 'stale'
                if case == 'wrong-component':
                    ro[0][0] = 'unrelated'
                if case == 'wrong-boundary':
                    po[0][3] = str(power)
                if case == 'wrong-release-direction':
                    iv[0]['direction'] = 'Scheme-to-C'
                if case == 'GC-is-release':
                    iv[0]['automaticRelease'] = True
                if case == 'forged-native-cohort':
                    needrows = [r for r in needrows if r[1] != 'generated-cohort']

                def inv(rs):
                    return [[r['family'], r['direction'], r['endEffect'], str(r['automaticRelease'])] for r in rs]
                session.replace(dict(scenario=[[case]], need=needs, receipt=needrows, sourceNeed=src, sourceObservation=so, routeNeed=routes, routeObservation=ro, actionName=[[mod.SPEC['module'] + '.' + a] for a in mod.SPEC['actions'][1 if case == 'missing-action' else 0:]], lemmaName=[[x] for x in lemmas[1 if case == 'missing-proof' else 0:]], profileNeed=profiles, profileObservation=po, inventoryNeed=inv(inventory), inventoryObservation=inv(iv), groundingNeed=[['ffi-conversion', r[3], 'paper-fulltext', r[4]] for r in routes]))
                res = session.run(queries=['blocked', 'candidate', 'routeLinked', 'groundingLinked'])
                assert res['complete']
                results[case] = res['relations']
        finally:
            engine.close()
        assert [k for k, v in results.items() if v['candidate']] == ['synthetic-all']
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotNativeEvidence=True))
        matrix = ['#+TITLE: Size-family conversion ownership and net return matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projections', ':PROPERTIES:', ':CUSTOM_ID: size-family-hold-matrix', ':AUTHORITY: GambitSizeFamilyHoldBalance', ':END:', 'These rows are evaluated by native SysML. Formal routes do not qualify native issuers.']
        for g in ['profile', 'releaser', 'need', 'gain', 'memory', 'route', 'source']:
            fs = list(p[g][0])
            matrix += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|'] + ['| ' + ' | '.join((r[f].replace('\n', ' / ').replace('|', ' / ') for f in fs)) + ' |' for r in p[g]]
        _study_write_text(_science.BASE / f'{_science.TASK}-matrix.org', '\n'.join(matrix) + '\n')
        diagram = 'direction: down\ntitle: "C23 size conversions: native holds and Scheme roots"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['custody']) for r in p['contract'])) + '\n'
        d2 = _science.BASE / 'diagrams' / f'{_science.TASK}.d2'
        _study_write_text(d2, diagram)
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=_science.process_profile)
        checks = dict(sourceAnchors=len(sources), macroResponsibilities=len(inventory), qntActions=len(mod.SPEC['actions']), histories=8, samples=500, maxSteps=80, seed=521, leanTheorems=len(lemmas), stepInduction=True, quintBackend='typescript', rustBackendU64Rejected=True, typedIrControls=len(ctrls), effectCountercontrols=len(negative), ascentScenarios=len(results), routes=len(routes), releaseInventoryRows=len(hits), unresolved=[r[0] for r in needs if r[1] == 'unresolved'], actualCandidate=False, sourceMismatchConditional=True, nativeLeakObserved=False, allWritersClosed=False, preprocessorOrNativeCompilerRun=False, runtimeImplementation=False, nativeTests=False, performanceTests=False, c23Refinement=False, nativePathsRetired=0)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for a, b in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.rel(_science.BASE / (_science.TASK + '-design.org'))), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.rel(_science.BASE / (_science.TASK + '-matrix.org'))), ('dev/architecture/toolchain/index.org', _science.rel(_science.BASE / 'index.org'))]:
            org = org.replace(a, b)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org-check', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = [model, qnt, proj, _science.ROOT / 'dev/modeling/tools' / f'{_science.TASK}-study.py', _science.ROOT / 'dev/modeling/ascent' / f'{_science.TASK}.rules.scm', _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.BASE / f'{_science.TASK}-design.org', _science.BASE / f'{_science.TASK}-matrix.org', _science.BASE / 'index.org', d2, d2.with_suffix('.svg')] + [_science.BASE / 'models/lean' / f'{n}.lean' for n in modules] + [_study_workspace('CACHE') / 'config.json', _study_workspace('CACHE') / 'model-data.json', _study_workspace('CACHE') / 'proof-modules.json']
        bindings.update({_science.rel(f): _science.sha(f) for f in files})
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), sourceBindings=bindings, leanBinarySha256=_science.sha(_science.LEAN), nativeClaim=False))
        assert all((_science.sha(_science.ROOT / f) == h for f, h in bindings.items())), 'source drift during study'
        assert all((_science.sha(_science.ROOT / f) == h for f, h in formalStart.items())), 'formal input drift during study'
        assert all((_science.sha(_science.ROOT / r['path']) == r['sha256'] for r in sources)), 'source witness drift during study'
        _science.save(_study_workspace('CACHE') / 'formal-inputs.json', formalStart)
        for f in _study_workspace('CACHE').rglob('*'):
            if f.is_file():
                target = _study_workspace('OUT') / f.relative_to(_study_workspace('CACHE'))
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(f, target)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {_science.rel(f): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks, indent=2))

# Preserved scientific source notes (in original order).
# Enumerate six macro responsibilities independently from actual source text.
# A textual inventory is not an all-aliases or indirect-call proof.
# Each mutated effect/guard has a Safe witness and an enabled step, then
# a proved unsafe postcondition. The final intentionally false goal must fail.
# Actual ASCENT evaluates source + semantic profile + component/action/proof joins.
# Source hashes are rechecked at the end; concurrent runtime work is not overwritten.
