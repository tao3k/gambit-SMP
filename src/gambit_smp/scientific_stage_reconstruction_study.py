"""Native SysML projections and exclusive protocol/data proof slices; no builds."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import copy
import hashlib
import json
import re
import shutil
from pathlib import Path
from ascent import Engine
from gambit_smp.storage_policy import EVIDENCE_CACHE_SUFFIXES

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
        _science.Engine = Engine
        _science.EVIDENCE_CACHE_SUFFIXES = EVIDENCE_CACHE_SUFFIXES
        _science.ROOT = _science.context.root
        _science.BASE = _science.ROOT / 'dev/architecture/toolchain'
        _science.MODEL = _science.BASE / 'models/sysml/stage-reconstruction-contracts.sysml'
        _science.QNT = _science.BASE / 'models/quint/stage_context_handoff.qnt'
        _science.LEAN = _science.BASE / 'models/lean/StageProductLayout.lean'
        _science.RULES = _science.ROOT / 'dev/modeling/ascent/stage-reconstruction.rules.scm'
        _science.LEAN_BIN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
        _science.GROUPS = [('endpoint', 14, ['contract.key', 'component.key', 'endpointRole']), ('publication', 1, ['key', 'ledger', 'prepare', 'publish', 'observe', 'gcInteraction', 'release', 'failure', 'mapping']), ('contract', 5, ['key', 'schema', 'producer', 'consumers', 'seal', 'invalidation', 'failureCustody', 'retirement', 'gap']), ('anchor', 12, ['key', 'sourcePath', 'needle', 'contract.key', 'fact', 'limit']), ('migration', 8, ['key', 'dependsOn', 'replaces', 'admission', 'completion', 'blocked']), ('proof', 4, ['key', 'owner.key', 'owner.primary', 'owner.semantic', 'owner.evidenceStatus', 'artifact', 'question', 'excludes', 'proofStatus'])]
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, x):
        _study_write_text(p, json.dumps(x, indent=2) + '\n')

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        helper = _science.context.library('size_family_hold_balance_study')
        prior = _science.ROOT / '.cache/tasks/future-frame-commit/runs/research/package-benchmark/input.json'
        old = json.loads(prior.read_text())
        files = sorted(set(old['nativeSysmlClosure']) | {str(_science.MODEL.relative_to(_science.ROOT))})
        bindings = {f: _science.sha(_science.ROOT / f) for f in files}
        for name in ['dev/architecture/toolchain/models/sysml/package-development-benchmark.sysml', 'dev/modeling/models/sysml/verification-responsibilities.sysml']:
            assert _science.sha(_science.ROOT / name) == old['sourceBindings'][name], 'Canonical owner changed; explicit ownership review required'
        ownership = prior.parent / 'ownership.json'
        bindings[str(ownership.relative_to(_science.ROOT))] = _science.sha(ownership)
        for f in [_science.QNT, _science.LEAN, _science.RULES, Path(str(_science.context.root / 'src/gambit_smp/scientific_stage_reconstruction_study.py')), prior]:
            bindings[str(f.relative_to(_science.ROOT))] = _science.sha(f)
        queries = [(g, i, f) for g, n, fields in _science.GROUPS for i in range(n) for f in fields]
        vals = []
        for start in range(0, len(queries), 100):
            field_expressions = []
            for g, i, f in queries[start:start + 100]:
                field_expressions.append(f'GambitStageReconstruction::{g}{i}.{f}')
            raw = _study_fields(_science.ROOT, None, 'stage-reconstruction', field_expressions, ordered=True, models=files)
            chunk = raw['orderedValues']
            assert len(chunk) == len(queries[start:start + 100])
            vals += chunk
        rows = {}
        for (g, i, f), v in zip(queries, vals, strict=True):
            rows.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(rows[g].values()) for g, _, _ in _science.GROUPS}
        _science.save(_study_workspace('OUT') / 'projection.json', p)
        for a in p['anchor']:
            source = _science.ROOT / a['sourcePath']
            assert a['needle'] in source.read_text(), a['key']
            bindings[a['sourcePath']] = _science.sha(source)
        for r in p['proof']:
            assert r['owner.evidenceStatus'] == 'open', 'A subset must not close its canonical obligation'
            assert (_science.ROOT / r['artifact']).exists()
            bindings[r['artifact']] = _science.sha(_science.ROOT / r['artifact'])
        assert p['proof'][0]['owner.primary'] == 'quint' and p['proof'][1]['owner.primary'] == 'lean'
        assert p['proof'][0]['owner.semantic'] != p['proof'][1]['owner.semantic']
        closure = {}
        todo = [_science.QNT]
        while todo:
            f = todo.pop()
            name = str(f.resolve().relative_to(_science.ROOT))
            if name in closure:
                continue
            imports = []
            for dep in re.findall('\\bfrom\\s+"([^"]+)"', f.read_text()):
                target = (f.parent / dep).resolve()
                target = target if target.suffix == '.qnt' else Path(str(target) + '.qnt')
                assert target.is_file()
                imports.append(str(target.relative_to(_science.ROOT)))
                todo.append(target)
            closure[name] = imports
            bindings[name] = _science.sha(f)
        _science.context.command('qnt-type', ['quint', 'typecheck', str(_science.QNT), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=helper.process_profile)
        _science.context.command('qnt-histories', ['quint', 'test', str(_science.QNT), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=helper.process_profile)
        _science.context.command('qnt-samples', ['quint', 'run', str(_science.QNT), '--backend', 'typescript', '--init', 'init', '--step', 'step', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=helper.process_profile)
        foundation = _science.ROOT / 'dev/refactoring/modern-c/models/lean/FrameContract.lean'
        bindings[str(foundation.relative_to(_science.ROOT))] = _science.sha(foundation)
        _science.context.command('lean-frame-contract', [_science.LEAN_BIN, '-o', str(_study_workspace('CACHE') / 'FrameContract.olean'), str(foundation)], policy=helper.process_profile)
        assert not re.search('\\bsorry\\b|\\baxiom\\s', _science.LEAN.read_text())
        _science.context.command('lean-layout', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN_BIN, str(_science.LEAN)], policy=helper.process_profile)
        contracts = [[r[k] for k in ['key', 'schema', 'producer', 'consumers', 'seal', 'invalidation', 'failureCustody', 'retirement', 'gap']] for r in p['contract']]
        slices = [[r[k] for k in ['key', 'owner.primary', 'owner.semantic', 'artifact', 'proofStatus']] for r in p['proof']]
        gates = [[r[k] for k in ['key', 'admission', 'completion', 'blocked']] for r in p['migration']]
        dependencies = [[r['key'], dep] for r in p['migration'] if r['dependsOn'] != 'none' for dep in r['dependsOn'].split(';')]
        known = set()
        for r in p['migration']:
            assert r['dependsOn'] == 'none' or all((dep in known for dep in r['dependsOn'].split(';'))), 'Migration must be acyclic and explicit'
            known.add(r['key'])
        artifacts = [[r['artifact'], _science.sha(_science.ROOT / r['artifact'])] for r in p['proof'][:2]]
        scenarios = ['current', 'qualified-fixture', 'child-receipt-before-parent', 'old-reader', 'shared-context', 'live-vector-is-frozen', 'shared-native-pointer', 'code-only-manifest', 'semantic-layout-key-collapsed', 'wrong-slice-owner', 'subset-promoted-to-full', 'proof-drift']
        engine = Engine()
        results = {}
        try:
            session = engine.open_sources(_science.RULES.read_text())
            assert session.run(queries=['contractGap'])['complete']
            for case in scenarios:
                seen = copy.deepcopy(contracts)
                sliceSeen = copy.deepcopy(slices)
                artSeen = copy.deepcopy(artifacts)
                receipts = [] if case == 'current' else [[g[0], g[2], 'source-and-native-qualified'] for g in gates]
                readers = []
                if case == 'child-receipt-before-parent':
                    receipts = receipts[1:]
                if case == 'old-reader':
                    readers = [[gates[-1][0]]]
                if case == 'shared-context':
                    seen[1][1] = 'shared-live-target-and-primitive-state'
                if case == 'live-vector-is-frozen':
                    seen[3][4] = 'validated-vector-is-already-immutable'
                if case == 'shared-native-pointer':
                    seen[4][1] = 'native-pointer-in-shared-ModulePlan'
                if case == 'code-only-manifest':
                    seen[3][1] = 'code-without-FrameSpec-and-image-holds'
                if case == 'semantic-layout-key-collapsed':
                    seen[0][1] = 'one-key-all-options-and-VM-state'
                if case == 'wrong-slice-owner':
                    sliceSeen[0][1] = 'lean'
                if case == 'subset-promoted-to-full':
                    sliceSeen[0][4] = 'canonical-obligation-closed'
                if case == 'proof-drift':
                    artSeen[0][1] = 'stale'
                session.replace(dict(contractNeed=contracts, contractSeen=seen, sliceNeed=slices, sliceSeen=sliceSeen, artifactNeed=artifacts, artifactSeen=artSeen, gateNeed=gates, depends=dependencies, gateReceipt=receipts, oldReader=readers))
                r = session.run(queries=['contractLinked', 'contractGap', 'checkedSlice', 'sliceGap', 'gateBlocked', 'gateReady', 'retirementReady'])
                assert r['complete']
                results[case] = r['relations']
                if case == 'qualified-fixture':
                    assert len(r['relations']['retirementReady']) == len(gates)
                elif case == 'old-reader':
                    assert len(r['relations']['gateReady']) == len(gates) and len(r['relations']['retirementReady']) == len(gates) - 1
                else:
                    assert not r['relations']['retirementReady'], case
            assert len(results['current']['checkedSlice']) == 2 and len(results['current']['sliceGap']) == 2
        finally:
            engine.close()
        _science.save(_study_workspace('OUT') / 'ascent.json', dict(scenarios=results, syntheticQualificationIsNotNativeEvidence=True))
        lines = ['#+TITLE: Shared Stage Contracts, Migration and Retirement Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection']
        for g, _, _ in _science.GROUPS:
            fields = list(p[g][0])
            lines += ['', '** ' + g, '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(r[k]).replace('|', ' / ') for k in fields)) + ' |' for r in p[g]]
        matrix = _science.BASE / 'stage-reconstruction-matrix.org'
        _study_write_text(matrix, '\n'.join(lines) + '\n')
        diagram = _science.BASE / 'diagrams/stage-reconstruction.d2'
        _study_write_text(diagram, 'direction: right\n' + '\n'.join((json.dumps(r['producer']) + ' -> ' + json.dumps(r['key']) + ': ' + json.dumps(r['seal']) + '\n' + json.dumps(r['key']) + ' -> ' + json.dumps(r['consumers']) + ': ' + json.dumps(r['invalidation']) for r in p['contract'])) + '\n')
        _science.context.command('d2-contracts', ['d2', '--layout', 'elk', str(diagram), str(diagram.with_suffix('.svg'))], policy=helper.process_profile)
        migration = _science.BASE / 'diagrams/stage-migration.d2'
        _study_write_text(migration, 'direction: right\n' + '\n'.join((json.dumps(dep) + ' -> ' + json.dumps(r['key']) + ': ' + json.dumps(r['completion']) for r in p['migration'] if r['dependsOn'] != 'none' for dep in r['dependsOn'].split(';'))) + '\n')
        _science.context.command('d2-migration', ['d2', '--layout', 'elk', str(migration), str(migration.with_suffix('.svg'))], policy=helper.process_profile)
        for f in [_science.BASE / 'stage-reconstruction-design.org', _science.BASE / 'index.org', matrix, diagram, diagram.with_suffix('.svg'), migration, migration.with_suffix('.svg')]:
            bindings[str(f.relative_to(_science.ROOT))] = _science.sha(f)
        assert all((_science.sha(_science.ROOT / f) == digest for f, digest in bindings.items())), 'Input drift'
        _science.save(_study_workspace('OUT') / 'input.json', dict(sourceBindings=bindings, qntClosure=closure, canonicalObligationsRemainOpen=True))
        checks = dict(nativeSysmlFiles=len(files), sharedContracts=5, typedComponentEndpoints=14, c23PublicationProtocols=1, sourceAnchors=12, migrationGates=8, exclusiveProofSlices=2, qntHistories=18, qntSamples=500, maxSteps=80, seed=953, leanDataLaws=9, existingFrameLawsReused=4, existingFrameLawsAvailable=7, ascentScenarios=len(scenarios), canonicalObligationsClosed=0, actualRetirementPermits=0, nativeTests=0, wholePackageSpeedupEstablished=False, scope='Conditional interface/data subsets; source alias closure, RETI/OFD/all-ABI and native refinement OPEN')
        _science.save(_study_workspace('OUT') / 'checks.json', checks)
        raw = []
        for f, d in bindings.items():
            if Path(f).suffix.casefold() in EVIDENCE_CACHE_SUFFIXES:
                raw.append(dict(path=f, sha256=d))
                continue
            target = _study_workspace('OUT') / 'input-cut' / hashlib.sha256((f + ':' + d).encode()).hexdigest()[:16] / Path(f).name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(_science.ROOT / f, target)
        for f in _study_workspace('CACHE').iterdir():
            if not f.is_file():
                continue
            if f.suffix.casefold() in EVIDENCE_CACHE_SUFFIXES:
                raw.append(dict(path=str(f.relative_to(_science.ROOT)), sha256=_science.sha(f)))
            else:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'raw-artifact-references.json', raw)
        print(json.dumps(checks, indent=2))

# Preserved scientific source notes (in original order).
# Reuse the original DAG; its code and every import are source-bound.
