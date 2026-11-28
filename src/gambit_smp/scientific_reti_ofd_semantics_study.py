"""Native SysML, official typed IR and Lean certificates; no runtime implementation/test."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import json, re, copy, textwrap
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.re = re
        _science.copy = copy
        _science.textwrap = textwrap
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.STEM = 'reti-ofd-semantics'
        _science.PKG = 'GambitRetiOfdSemantics'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.QNT = _science.BASE + 'models/quint/reti_ofd_retirement.qnt'
        _science.PARENTQ = _science.BASE + 'models/quint/map_frame_abi.qnt'
        _science.LEAN = _science.BASE + 'models/lean/RetiOfdSemantics.lean'
        _science.AST = _science.BASE + 'models/lean/MapExpressionAst.lean'
        _science.PARENTL = _science.BASE + 'models/lean/MapFrameAbi.lean'
        _science.HELPER = 'src/gambit_smp/scientific_advantage_architecture_study.py'
        _science.PROJECTOR = 'src/gambit_smp/scientific_map_expression_projection.py'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.sha = _science.h.sha
        _science.save = _science.h.save
        _science.GROUPS = [('owner', 9, 'moduleId ownerPath owns'), ('route', 10, 'key sourcePath needle obligation proofScope'), ('shape', 9, 'key kind count storedFs linkSlot mask actualFs provenance'), ('bridge', 8, 'key qualified lemma premise gap'), ('user', 8, 'key sourcePath needle resource close finalUse unknown'), ('gain', 4, 'key avoided added condition'), ('gate', 7, 'key qualified duty')]
        _science.process_profile = _science.h.process_profile

    def project(_science):
        keys = []
        for group, count, schema in _science.GROUPS:
            keys += [(group, str(i), f, f'{_science.PKG}::{group}{i}.{f}') for i in range(count) for f in schema.split()]
        for slot in ['history', 'induction', 'expression', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PKG}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        for i in range(5):
            keys += [('dependency', str(i), f, f'{_science.PKG}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId', 'prerequisite.subjectPath', 'prerequisite.subjectScope']]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        files = sorted(_science.context.command('sysml-files', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', dict(files={f: _science.sha(_science.ROOT / f) for f in files}, excluded={}))
        raw = _study_fields(_science.ROOT, None, 'reti-ofd-semantics', field_expressions, ordered=True, models=['dev'])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        for g, _, _ in _science.GROUPS:
            p[g] = list(p[g].values())
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        return p

    def views(_science, p):
        lines = ['#+TITLE: RETI/OFD, Typed Expression Bridge and Retirement Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: reti-ofd-semantics-matrix', ':AUTHORITY: GambitRetiOfdSemantics', ':STATUS: restricted-AST-proved; trusted-extraction-and-source-open', ':END:']
        for g, _, schema in _science.GROUPS:
            fs = schema.split()
            lines += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fs)) + ' |' for v in p[g]]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down']
        for i, v in enumerate(p['route']):
            graph.append(f'r{i}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['obligation'], 55)))
        for a, b in [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (5, 7), (2, 8), (8, 5), (8, 9)]:
            graph.append(f'r{a} -> r{b}')
        graph += ['ast: "Official typed IR -> rejecting extraction -> Lean AST interpreter\\nKernel meaning proofs: selected AST only"', 'trust: "Parser/extractor conformance + concrete Scheme/C/native: OPEN"', 'ast -> trust', 'r6 -> trust', 'r9 -> trust']
        for i, v in enumerate(p['gain']):
            graph += [f'g{i}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['condition'], 52)), f'trust -> g{i}']
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def ascend(_science, p):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        v = next((v for v in p['dependency'].values() if v['prerequisite.obligationId'] == 'MF-S'))
        external = [[v['prerequisite.obligationId'], v['prerequisite.subjectPath'], _science.sha(_science.ROOT / v['prerequisite.subjectPath']), v['prerequisite.subjectScope']]]
        rows = [[v['key'], v['sourcePath'], _science.sha(_science.ROOT / v['sourcePath']), v['needle'], v['proofScope']] for v in p['route']]
        queries = ['candidate', 'blocked', 'checked', 'route', 'witnessok', 'bridgeok', 'externalok']
        results = {}
        engine = _science.h.Engine()
        cases = ['current', 'stale-digest', 'wrong-scope', 'missing-witness', 'wrong-witness', 'missing-parent', 'widened-tcb', 'missing-bridge', 'synthetic-all']
        try:
            s = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert s.run(queries=queries)['complete']
            for case in cases:
                full = case != 'current'
                rec = [[case, n, path, d, scope] for n, k, path, d, scope in needs if full or k in ['interleaving', 'induction']]
                if case == 'stale-digest':
                    rec = [x[:3] + ['stale'] + x[4:] if x[1] == 'RO-X' else x for x in rec]
                if case == 'wrong-scope':
                    rec = [x[:4] + ['whole-tool-proof'] if x[1] == 'RO-X' else x for x in rec]
                wr = [r.copy() for i, r in enumerate(rows) if not (case == 'missing-witness' and i == 0)]
                if case == 'wrong-witness':
                    wr[0][2] = 'wrong-source-digest'
                br = [[case, v['key'], v['lemma']] for v in p['bridge'] if (full or v['qualified']) and (not (case == 'missing-bridge' and v['key'] == 'typed-ast-meaning'))]
                if case == 'widened-tcb':
                    br = [x[:2] + ['stepMeaning'] if x[1] == 'trusted-extraction' else x for x in br]
                s.replace(dict(scenario=[[case]], need=needs, method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source'], ['environment-refinement', 'platform']], receipt=rec, gate=[[case, v['key'], str(full).lower()] for v in p['gate']], witnessneed=rows, witnessbinding=wr, bridge=[[v['key'], v['lemma']] for v in p['bridge']], bridgereceipt=br, externalneed=external, externalreceipt=[[case] + r for r in external if full and case != 'missing-parent']))
                result = s.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', results)
            assert len(results['current']['checked']) == 3 and len(results['current']['bridgeok']) == 6 and (len(results['current']['witnessok']) == 10)
            assert len(results['synthetic-all']['candidate']) == 1 and all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotRealEvidence=True, fullQuintToolProof=False, repositoryRegistered=False))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/map-frame-abi/input.json'
        ph = _science.sha(parent)
        old = json.loads(parent.read_text())['sourceBindings']
        _science.save(_study_workspace('CACHE') / 'parent-drift.json', dict(parentSha256=ph, drift=[dict(path=f, old=d, current=_science.sha(_science.ROOT / f)) for f, d in old.items() if _science.sha(_science.ROOT / f) != d], inheritedSourceQualified=False))
        p = _science.project()
        _science.views(p)
        import collections
        block = (_science.ROOT / 'vendor/gambit/lib/_std.c').read_text().split(',___DEF_LBL_INTRO(___H_map,', 1)[1].split(',___DEF_LBL_INTRO', 1)[0]
        actual = collections.Counter(((kind, int(fs), int(link), int(mask, 16)) for kind, fs, link, mask in re.findall('DEF_LBL_RET\\(___H_map,___IFD\\((___RET[INT]),(\\d+),(\\d+),(0x[0-9a-f]+)L\\)\\)', block)))
        expected = {(v['kind'], v['storedFs'], v['linkSlot'], v['mask']): v['count'] for v in p['shape']}
        assert dict(actual) == expected and sum(actual.values()) == 22 and ('___OFD(' not in block)
        _science.save(_study_workspace('CACHE') / 'stored-shape-observations.json', dict(rows=p['shape'], total=22, directOfd=0, nativeProvenance=False))
        witnesses = []
        for v in p['route'] + p['user']:
            text = (_science.ROOT / v['sourcePath']).read_text()
            assert v['needle'] in text, v
            witnesses.append(dict(key=v['key'], path=v['sourcePath'], sha256=_science.sha(_science.ROOT / v['sourcePath']), line=text[:text.index(v['needle'])].count('\n') + 1))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        _science.context.command('typecheck', ['quint', 'typecheck', _science.PARENTQ, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        projector = _science.context.library('map_expression_projection')
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, meta = projector.generate(ir, _science.sha(_science.ROOT / _science.PARENTQ))
        _study_write_text(_science.ROOT / _science.AST, ast)
        _science.save(_study_workspace('CACHE') / 'expression-projection.json', dict(**meta, sourceSha256=_science.sha(_science.ROOT / _science.PARENTQ), irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / _science.AST), extractorSha256=_science.sha(_science.ROOT / _science.PROJECTOR)))
        negatives = []
        for case in ['unknown-op', 'dynamic-field', 'unknown-field', 'duplicate-update', 'wrong-int-type', 'extra-state', 'wrong-initial']:
            bad = copy.deepcopy(ir)
            ds = {d.get('name'): d for d in bad['modules'][0]['declarations']}
            if case == 'unknown-op':
                ds['safe']['expr']['opcode'] = 'unsupported'
            if case == 'dynamic-field':
                ds['safe']['expr']['args'][0]['args'][0]['args'][1] = {'kind': 'name', 'name': 'dynamic'}
            if case == 'unknown-field':
                ds['safe']['expr']['args'][0]['args'][0]['args'][1]['value'] = 'notAField'
            if case == 'duplicate-update':
                rhs = ds['capture']['expr']['args'][-1]['args'][1]
                ds['capture']['expr']['args'][-1]['args'][1] = {'kind': 'app', 'opcode': 'with', 'args': [rhs, {'kind': 'str', 'value': 'shots'}, {'kind': 'int', 'value': 2}]}
            if case == 'wrong-int-type':
                ds['safe']['expr']['args'][0]['args'][1] = {'kind': 'bool', 'value': True}
            if case == 'extra-state':
                bad['modules'][0]['declarations'].append({'kind': 'var', 'name': 'extra', 'id': 100000})
            if case == 'wrong-initial':
                ds['init']['expr']['args'][1]['name'] = 's'
            try:
                projector.generate(bad, _science.sha(_science.ROOT / _science.PARENTQ))
            except (AssertionError, KeyError):
                negatives.append(case)
        assert len(negatives) == 7
        _science.save(_study_workspace('CACHE') / 'projection-refusals.json', dict(rejected=negatives, notTranslatorProof=True))
        for name, path in [('MapFrameAbi', _science.PARENTL), ('RetiOfdSemantics', _science.LEAN), ('MapExpressionAst', _science.AST)]:
            src = _study_workspace('CACHE') / (name + '.lean')
            _study_write_bytes(src, (_science.ROOT / path).read_bytes())
            args = ['lean', f"--root={_study_workspace('CACHE')}", '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(src)]
            if name != 'MapFrameAbi':
                args = ['env', f"LEAN_PATH={_study_workspace('CACHE')}"] + args
            _science.context.command(name, args, policy=_science.process_profile)
        mutant = []
        for line in ast.splitlines():
            mutant.append(line.replace('(.lt (.get .shots) (.lit (3)))', '(.le (.get .shots) (.lit (3)))') if line.startswith('def a_resume ') else line)
        assert '\n'.join(mutant) != ast.strip()
        _study_write_text(_study_workspace('CACHE') / 'MutatedAst.lean', '\n'.join(mutant) + '\n')
        try:
            _science.context.command('negative-guard-certificate', ['env', f"LEAN_PATH={_study_workspace('CACHE')}", 'lean', f"--root={_study_workspace('CACHE')}", str(_study_workspace('CACHE') / 'MutatedAst.lean')], policy=_science.process_profile)
        except RuntimeError:
            assert 'error:' in (_study_workspace('CACHE') / 'negative-guard-certificate.stdout').read_text()
        else:
            raise AssertionError('wrong AST unexpectedly certified')
        alllean = (_science.ROOT / _science.LEAN).read_text() + ast
        assert 'sorry' not in alllean and 'axiom ' not in alllean
        for v in p['bridge']:
            if v['qualified']:
                assert 'theorem ' + v['lemma'] + ' ' in alllean, v
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 9 and tests.count('ControlTest passed') == 4
        _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '300', '--max-steps', '160', '--seed', '31', '--verbosity', '1'], policy=_science.process_profile)
        _science.ascend(p)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        _science.save(_study_workspace('OUT') / 'checks.json', dict(status='pending', nativeAdmitted=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = {v['sourcePath'] for v in p['route'] + p['user']} | {_science.MODEL, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.RULES, _science.QNT, _science.PARENTQ, _science.PARENTL, _science.LEAN, _science.AST, _science.HELPER, _science.PROJECTOR, _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.BASE + 'index.org', 'dev/architecture/runtime/models/sysml/composition.sysml', _science.BASE + 'models/sysml/map-frame-abi.sysml'}
        installed = Path('/opt/homebrew/Cellar/quint/0.33.0/libexec/lib/node_modules/@informalsystems/quint/dist/src')
        for f in ['cli.js', 'runtime/impl/builtins.js', 'runtime/impl/builder.js']:
            files.add(str(installed / f))
        for v in witnesses:
            assert _science.sha(_science.ROOT / v['path']) == v['sha256']
        assert _science.sha(parent) == ph
        scope = json.loads((_study_workspace('CACHE') / 'sysml-input-scope.json').read_text())
        for f, d in scope['files'].items():
            assert _science.sha(_science.ROOT / f) == d, f
        checks = dict(status='conditional-local-models-pass', wholeDevSysmlInputs=len(scope['files']), sourceRoutes=10, retirementUserClasses=8, storedShapes=9, directMapOfd=0, storedReti=13, storedRetn=9, selectedAstActions=12, astTheorems=len(re.findall('^theorem ', ast, re.M)), interpreterFrameTheorems=len(re.findall('^theorem ', (_science.ROOT / _science.LEAN).read_text(), re.M)), projectionRefusals=7, negativeLeanCertificates=1, qntRetirementHistories=9, negativeQntControls=4, sampledRuns=300, maxSteps=160, ascentScenarios=9, qualifiedBridgeScopes=6, openLargerScopes=2, openGates=7, parserExtractorVerified=False, fullQuintToolVerified=False, sourceSimulation=False, c11Refinement=False, nativeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False, hostRegistration='inherited unresolved; not retried')
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, parentInputSha256=ph, parentFrozen=True, inheritedSourceQualified=False, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in {'.stdout', '.stderr'}}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in {'.json', '.el', '.lean'}:
                _study_write_bytes(_study_workspace('OUT') / f.name, f.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
