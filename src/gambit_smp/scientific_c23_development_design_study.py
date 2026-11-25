"""Research-only coordination of existing architecture owners and formal models."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import copy, hashlib, json, re, shutil, os
from decimal import Decimal
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
        _science.os = os
        _science.Decimal = Decimal
        _science.Path = Path
        _science.Engine = Engine
        _science.ROOT = _science.context.root
        _science.BASE = _science.ROOT / 'dev/architecture/toolchain'
        _science.GROUPS = [('costFactor', 9, ['key', 'evidence.key', 'evidence.path', 'evidence.needle', 'evidence.established', 'evidence.excludes', 'sourcePath', 'needle', 'status', 'missing', 'gate', 'elimination']), ('c23Feature', 6, ['key', 'origin', 'application', 'limit', 'benefit', 'primary']), ('c23Boundary', 4, ['key', 'role.roleId', 'stage.key', 'descriptor.fieldId', 'producer', 'consumer', 'contract', 'retirement', 'added', 'sourcePath', 'needle', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'proofLimit']), ('c23Edge', 56, ['fromNode', 'toNode', 'contract']), ('linkCut', 4, ['key', 'role.roleId', 'stage.key', 'descriptor.fieldId', 'producer', 'consumer', 'contract', 'retirement', 'added', 'sourcePath', 'needle', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'proofLimit']), ('stageCut', 5, ['key', 'role.roleId', 'stage.key', 'descriptor.fieldId', 'producer', 'consumer', 'contract', 'retirement', 'added', 'sourcePath', 'needle', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'proofLimit']), ('linkCaller', 11, ['key', 'route', 'sourcePath', 'needle', 'kind', 'inputProjection', 'admission', 'retirement', 'openCallers']), ('linkPropagation', 8, ['key', 'route', 'change', 'retained', 'invalidated', 'condition', 'qntPath', 'qntTest']), ('preparationCut', 16, ['key', 'role.roleId', 'stage.key', 'descriptor.fieldId', 'producer', 'consumer', 'contract', 'retirement', 'added', 'sourcePath', 'needle', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'proofLimit']), ('preparationOwner', 6, ['key', 'route', 'sourcePath', 'needle', 'historyPath', 'historyNeedle', 'calls', 'timing', 'replacement', 'retained', 'retirement']), ('readinessDependency', 9, ['key', 'route', 'sourcePath', 'needle', 'observation', 'invalidation', 'admission', 'qntTest']), ('foundationWriter', 8, ['key', 'route', 'sourcePath', 'needle', 'writes', 'owner', 'requiredEvidence', 'unknownCustody', 'qntTest']), ('groupCaller', 9, ['key', 'route', 'sourcePath', 'needle', 'currentAction', 'custodyBefore', 'requiredHandoff', 'refusal', 'qntTest']), ('foreignResult', 10, ['key', 'route', 'sourcePath', 'needle', 'observation', 'handoff', 'obligation', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'ownDuty', 'storageFact', 'descendantFact', 'semanticClass']), ('providerDuty', 8, ['key', 'route', 'sourcePath', 'needle', 'observation', 'handoff', 'obligation', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'ownDuty', 'storageFact', 'descendantFact', 'semanticClass', 'manifest', 'issuer']), ('groupShutdown', 13, ['key', 'route', 'sourcePath', 'needle', 'observation', 'handoff', 'obligation', 'qntPath', 'qntTest', 'leanPath', 'lemma']), ('shutdownCase', 8, ['key', 'expected0', 'expected1', 'present0', 'present1', 'stage0', 'stage1', 'unknown0', 'unknown1', 'process0', 'process1', 'admitting', 'writers', 'rawWriter', 'anchor', 'producer', 'vmLive', 'moduleLive', 'ready', 'qntTest', 'debt0', 'debt1']), ('groupCustody', 9, ['key', 'route', 'sourcePath', 'needle', 'observation', 'handoff', 'obligation', 'qntPath', 'qntTest', 'leanPath', 'lemma']), ('groupLifetime', 10, ['key', 'route', 'sourcePath', 'needle', 'observation', 'handoff', 'obligation', 'qntPath', 'qntTest', 'leanPath', 'lemma']), ('groupSync', 3, ['key', 'route', 'sourcePath', 'needle', 'basisPath', 'protectedState', 'visibility', 'obligation', 'qntTest']), ('preparationPartition', 1, ['preparation.key', 'evidence.key', 'compilerCoveredMicroseconds', 'uncoveredMicroseconds', 'meaning']), ('reconstruction', 6, ['key', 'component.key', 'stage.key', 'boundary.key', 'historyPath', 'historyNeedle', 'sourcePath', 'needle', 'pain', 'replacement', 'retirement', 'measure', 'added', 'refusal', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'proofLimit']), ('benefit', 8, ['key', 'pain.key', 'creditClass', 'metric', 'accounting.metric', 'oldShape', 'newShape', 'condition', 'counterexample', 'interaction', 'platformPolicy', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'scope', 'evidenceReuse', 'remainingDuty']), ('target', 3, ['key', 'comparison', 'numerator', 'denominator', 'achieved', 'planningRange', 'scope', 'requiredNetReduction', 'floorCondition', 'linuxCondition', 'evidenceUse', 'qntPath', 'qntModule', 'qntTest', 'leanPath', 'lemma', 'measurementScope']), ('lever', 9, ['key', 'benefit.key', 'benefit.pain.historyPath', 'sourcePath', 'needle', 'mechanism', 'removedDuty', 'mandatory', 'added', 'composition', 'scopeTransfer', 'retirement', 'evidenceStatus']), ('causal', 8, ['key', 'lever.key', 'cohort', 'kind', 'path', 'needle', 'clock', 'established', 'excludes', 'implication']), ('observed', 5, ['key', 'evidence.key', 'cohort', 'clock', 'microseconds', 'sourceLabel'])]
        _science.LEAN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, x):
        _study_write_text(Path(p), json.dumps(x, indent=2) + '\n')

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        h = _science.context.library('size_family_hold_balance_study')
        model = _science.BASE / 'models/sysml/macos-development.sysml'
        rules = _science.ROOT / 'dev/modeling/ascent/c23-development-design.rules.scm'
        files = [str(p.relative_to(_science.ROOT)) for p in (_science.ROOT / 'dev').rglob('*.sysml')] + [str(p.relative_to(_science.ROOT)) for p in (_science.ROOT / 'dev').rglob('*.kerml')]
        ix = {}
        for f in files:
            for name in re.findall('\\bpackage\\s+([A-Za-z_]\\w*)\\s*\\{', (_science.ROOT / f).read_text()):
                ix.setdefault(name, set()).add(f)
        selected = {str(model.relative_to(_science.ROOT))}
        todo = list(selected)
        while todo:
            f = todo.pop()
            for name in set(re.findall('\\b[A-Za-z_]\\w*\\b', (_science.ROOT / f).read_text())).intersection(ix):
                for dep in ix[name]:
                    if dep not in selected:
                        selected.add(dep)
                        todo.append(dep)
        selected = sorted(selected)
        bindings = {f: _science.sha(_science.ROOT / f) for f in selected}
        for f in [str(Path(str(_science.context.root / 'src/gambit_smp/scientific_c23_development_design_study.py')).relative_to(_science.ROOT)), str(rules.relative_to(_science.ROOT))]:
            bindings[f] = _science.sha(_science.ROOT / f)
        keys = [(g, i, f, 'GambitDarwinDevelopment::' + g + str(i) + '.' + f) for g, n, fs in _science.GROUPS for i in range(n) for f in fs]
        vals = []
        for start in range(0, len(keys), 100):
            field_expressions = []
            for *_, expr in keys[start:start + 100]:
                field_expressions.append(expr)
            raw = _study_fields(_science.ROOT, None, 'c23-development-design', field_expressions, ordered=True, models=selected)
            values = raw['orderedValues']
            assert len(values) == len(keys[start:start + 100])
            vals += values
        rows = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            rows.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(v.values()) for g, v in rows.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        formalRoutes = p['c23Boundary'] + p['linkCut'] + p['stageCut'] + p['preparationCut'] + p['reconstruction']
        for b in formalRoutes:
            for name in ['sourcePath', 'qntPath', 'leanPath']:
                f = _science.ROOT / b[name]
                assert f.exists()
                bindings[b[name]] = _science.sha(f)
            assert b['needle'] in (_science.ROOT / b['sourcePath']).read_text()
            assert re.search('\\brun ' + b['qntTest'] + '\\s*=', (_science.ROOT / b['qntPath']).read_text())
            assert re.search('^theorem ' + b['lemma'] + '\\b', (_science.ROOT / b['leanPath']).read_text(), re.M)
        for b in p['reconstruction']:
            f = _science.ROOT / b['historyPath']
            assert b['historyNeedle'] in f.read_text()
            bindings[b['historyPath']] = _science.sha(f)
        for b in p['benefit'] + p['target']:
            for name in ['qntPath', 'leanPath']:
                f = _science.ROOT / b[name]
                assert f.exists()
                bindings[b[name]] = _science.sha(f)
            assert re.search('\\brun ' + b['qntTest'] + '\\s*=', (_science.ROOT / b['qntPath']).read_text())
            assert re.search('^theorem ' + b['lemma'] + '\\b', (_science.ROOT / b['leanPath']).read_text(), re.M)
        for b in p['linkCaller']:
            f = _science.ROOT / b['sourcePath']
            assert b['needle'] in f.read_text()
            bindings[b['sourcePath']] = _science.sha(f)
        for b in p['linkPropagation']:
            f = _science.ROOT / b['qntPath']
            assert re.search('\\brun ' + b['qntTest'] + '\\s*=', f.read_text())
            bindings[b['qntPath']] = _science.sha(f)
        for b in p['preparationOwner']:
            for path, needle in [('sourcePath', 'needle'), ('historyPath', 'historyNeedle')]:
                f = _science.ROOT / b[path]
                assert b[needle] in f.read_text()
                bindings[b[path]] = _science.sha(f)
        for b in p['readinessDependency'] + p['foundationWriter'] + p['groupCaller'] + p['groupSync']:
            f = _science.ROOT / b['sourcePath']
            assert b['needle'] in f.read_text()
            bindings[b['sourcePath']] = _science.sha(f)
            assert re.search('\\brun ' + b['qntTest'] + '\\s*=', (_science.BASE / 'models/quint/preparation_reuse.qnt').read_text())
        for b in p['groupLifetime'] + p['groupCustody'] + p['groupShutdown'] + p['foreignResult'] + p['providerDuty']:
            for k in ['sourcePath', 'qntPath', 'leanPath']:
                f = _science.ROOT / b[k]
                assert f.exists()
                bindings[b[k]] = _science.sha(f)
            assert b['needle'] in (_science.ROOT / b['sourcePath']).read_text()
            assert re.search('\\brun ' + b['qntTest'] + '\\s*=', (_science.ROOT / b['qntPath']).read_text())
            assert re.search('^theorem ' + b['lemma'] + '\\b', (_science.ROOT / b['leanPath']).read_text(), re.M)
        for b in p['groupSync']:
            f = _science.ROOT / b['basisPath']
            assert json.loads(f.read_text())['primary'] == 'https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3096.pdf'
            bindings[b['basisPath']] = _science.sha(f)
        provenance = _science.ROOT / 'evidence/research/source-references/compiler-consumer/provenance.json'
        historical = json.loads(provenance.read_text())
        assert historical['commit'] == '21e3638687d42ecfc36acebb28991987435ebc60'
        bindings[str(provenance.relative_to(_science.ROOT))] = _science.sha(provenance)
        for row in historical['files']:
            f = provenance.parent / row['path']
            assert _science.sha(f) == row['sha256']
            bindings[str(f.relative_to(_science.ROOT))] = _science.sha(f)
        for b in p['lever']:
            f = _science.ROOT / b['sourcePath']
            assert b['needle'] in f.read_text()
            bindings[b['sourcePath']] = _science.sha(f)
        vendor = _science.ROOT / 'vendor/gambit'
        baseState = {name: _science.context.process(['git', '-C', str(vendor)] + args, capture_output=True, text=True, check=True, timeout=10, name='source-110').stdout.strip() for name, args in [('branch', ['branch', '--show-current']), ('head', ['rev-parse', 'HEAD']), ('status', ['status', '--porcelain'])]}
        baseState['scope'] = 'Current working source bytes, including staged and unstaged edits; not an installed SDK or historical binary identity'
        _science.save(_study_workspace('CACHE') / 'vendor-modern-c-base.json', baseState)
        for f in ['vendor/gambit/config.status', 'vendor/gambit/include/gambit.h', 'vendor/gambit/include/_gambit/gvm_operations.h.in', 'vendor/gambit/gsc/_gsclib.scm', 'vendor/gambit/gsc/makefile.in', 'vendor/gambit/lib/makefile.in', 'vendor/gambit/include/gambit.h.in', 'vendor/gambit/include/_gambit/module_generation.h.in']:
            bindings[f] = _science.sha(_science.ROOT / f)
        for b in p['costFactor']:
            for path, needle in [('evidence.path', 'evidence.needle'), ('sourcePath', 'needle')]:
                f = _science.ROOT / b[path]
                assert b[needle] in f.read_text()
                bindings[b[path]] = _science.sha(f)
        for b in p['causal']:
            f = _science.ROOT / b['path']
            assert b['needle'] in f.read_text()
            bindings[b['path']] = _science.sha(f)
        d803 = json.loads((_science.ROOT / p['causal'][1]['path']).read_text())
        assert d803['decision']['import_or_macro_expansion_is_primary_tail'] is False
        assert d803['real_mcp_consumer']['workers'] == 12
        source = (_science.ROOT / p['causal'][3]['path']).read_text()
        total = int(Decimal(re.search('interval is \\*\\*([0-9.]+) seconds', source).group(1)) * 1000000)
        for row in p['observed']:
            match = re.search('\\| ' + re.escape(row['sourceLabel']) + ' \\| ([0-9.]+) \\|', source)
            assert match, row
            assert int(Decimal(match.group(1)) * 1000000) == row['microseconds']
        assert sum((row['microseconds'] for row in p['observed'])) == total
        assert {row['cohort'] for row in p['observed']} == {'ASCENT-phase-reuse'}
        assert {row['clock'] for row in p['observed']} == {'monotonic-disjoint-microseconds'}
        partition = p['preparationPartition'][0]
        covered = int(Decimal(re.search('Preparation contains \\*\\*([0-9.]+) seconds', source).group(1)) * 1000000)
        uncovered = int(Decimal(re.search('and \\*\\*([0-9.]+) seconds\\*\\* outside', source).group(1)) * 1000000)
        assert covered == partition['compilerCoveredMicroseconds'] and uncovered == partition['uncoveredMicroseconds']
        assert covered + uncovered == p['observed'][0]['microseconds']
        fields = ['preparation', 'generation', 'objects', 'finalLink', 'casesAndAdmission']
        record = dict(total=total, **{k: row['microseconds'] for k, row in zip(fields, p['observed'], strict=True)})
        case = _study_workspace('CACHE') / 'observed_partition_case.qnt'
        importPath = os.path.relpath(_science.ROOT / 'models/build/incremental_build', _study_workspace('CACHE'))
        _study_write_text(case, 'module observed_partition_case {\n val uncovered:int=' + str(uncovered) + '\n import darwin_development_work.* from ' + json.dumps(importPath) + '\n val p:ElapsedPartition={' + ','.join((k + ':' + str(v) for k, v in record.items())) + '}\n' + '\n run observedPartitionTest=all{partitionValid(p)}\n run preparationCeilingTest=all{stageCannotDouble(p.total,p.preparation)}\n run objectCeilingTest=all{stageCannotDouble(p.total,p.objects)}\n run generationCeilingTest=all{stageCannotDouble(p.total,p.generation)}\n run extraRemovalTest=all{val needed=(p.total-2*p.preparation+1)/2;\n   all{2*(p.preparation+needed)>=p.total,2*(p.preparation+needed-1)<p.total}}\n run nestedDoubleCountRejectsTest=all{not(partitionValid({...p,objects:p.objects+1}))}\n run uncoveredOnlyCannotDoubleTest=all{stageCannotDouble(p.total,uncovered)}\n run gapAndLinkStillNeedOtherWorkTest=all{stageCannotDouble(p.total,uncovered+p.generation+p.finalLink)}\n run gapLinkAdditionalRemovalTest=all{(p.total+1)/2-uncovered-p.generation-p.finalLink>0}\n run nativeOnlyCannotDoubleTest=all{stageCannotDouble(p.total,p.generation+p.objects+p.finalLink)}\n run retainedPreparationFloorTest=all{val floor=p.preparation+p.casesAndAdmission;\n   all{2*floor>p.total,floor-p.total/2>0}}\n run linkOnlyNeedsOtherRemovalTest=all{val known=p.generation+p.finalLink;\n   all{(p.total+1)/2-known>0,2*(known+((p.total+1)/2-known))>=p.total}}\n}\n')
        bindings[str(case.relative_to(_science.ROOT))] = _science.sha(case)
        _science.context.command('observed-partition-type', ['quint', 'typecheck', str(case)], policy=h.process_profile)
        _science.context.command('observed-partition-histories', ['quint', 'test', str(case), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=h.process_profile)
        ceilings = [dict(stage=row['key'], share=str(Decimal(row['microseconds']) / total), idealSingleStageCeiling=str(Decimal(total) / (total - row['microseconds']))) for row in p['observed']]
        _science.save(_study_workspace('CACHE') / 'observed-partition-analysis.json', dict(sourcePath=p['causal'][3]['path'], sourceSha256=_science.sha(_science.ROOT / p['causal'][3]['path']), cohort='ASCENT-phase-reuse', unit='microseconds', partition=record, derived=ceilings, uncoveredMicroseconds=uncovered, compilerCoveredPreparationMicroseconds=covered, idealUncoveredOnlyCeiling=str(Decimal(total) / (total - uncovered)), minimumOtherRemovalAfterUncoveredAndLinkZero=(total + 1) // 2 - uncovered - record['generation'] - record['finalLink'], minimumIdealExtraAfterZeroPreparation=(total - 2 * record['preparation'] + 1) // 2, minimumPreparationRemovalIfAllNativeZeroAndCasesFixed=record['preparation'] + record['casesAndAdmission'] - total // 2, minimumOtherRemovalIfLinkGenerationAndFinalLinkZero=(total + 1) // 2 - record['generation'] - record['finalLink'], assumption='Unselected elapsed partition fixed; selected stage entirely removable; no added cost. Diagnostic ceilings, not candidate forecasts.'))
        qntLeanRoutes = formalRoutes + p['benefit'] + p['target']
        importQueue = [_science.ROOT / b['qntPath'] for b in qntLeanRoutes] + [case]
        importClosure = {}
        while importQueue:
            sourceFile = importQueue.pop().resolve()
            sourceName = str(sourceFile.relative_to(_science.ROOT))
            if sourceName in importClosure:
                continue
            imports = []
            for name in re.findall('\\bfrom\\s+"([^"\\n]+)"', sourceFile.read_text()):
                dep = (sourceFile.parent / name).resolve()
                if dep.suffix != '.qnt':
                    dep = Path(str(dep) + '.qnt')
                assert dep.is_file(), (sourceName, name)
                depName = str(dep.relative_to(_science.ROOT))
                imports.append(depName)
                importQueue.append(dep)
            importClosure[sourceName] = sorted(set(imports))
            bindings[sourceName] = _science.sha(sourceFile)
        _science.save(_study_workspace('CACHE') / 'qnt-import-closure.json', importClosure)
        for q in sorted({b['qntPath'] for b in qntLeanRoutes}):
            stem = Path(q).stem
            _science.context.command(stem + '-type', ['quint', 'typecheck', q, '--out', str(_study_workspace('CACHE') / (stem + '-ir.json'))], policy=h.process_profile)
            tests = sorted({b['qntTest'] for b in qntLeanRoutes if b['qntPath'] == q})
            match = '^(' + '|'.join(tests) + ')$' if stem not in ['native_artifact_partition', 'link_product_admission', 'link_stage_contract', 'preparation_reuse', 'task_group_roots', 'task_group_root_composition'] else 'Test$'
            moduleOpts = ['--main', 'darwin_development_work'] if q == 'models/build/incremental_build.qnt' else []
            if moduleOpts:
                match = '^target.*Test$'
            if stem == 'service_shutdown':
                localTests = re.findall('^ run (\\w+Test)=', (_science.ROOT / q).read_text(), re.M)
                assert len(localTests) == 40
                match = '^(' + '|'.join(localTests) + ')$'
            if stem == 'task_group_custody':
                localTests = re.findall('^ run (\\w+Test)=', (_science.ROOT / q).read_text(), re.M)
                assert len(localTests) == 22
                match = '^(' + '|'.join(localTests) + ')$'
            if stem == 'link_context_composition':
                match = 'BridgeTest$'
            _science.context.command(stem + '-histories', ['quint', 'test', q] + moduleOpts + ['--backend', 'typescript', '--match', match, '--max-samples', '1', '--seed', '953'], policy=h.process_profile)
        _science.context.command('shutdown-samples', ['quint', 'run', str(_science.BASE / 'models/quint/service_shutdown.qnt'), '--backend', 'typescript', '--init', 'init', '--step', 'step', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=h.process_profile)
        _science.context.command('group-family-samples', ['quint', 'run', str(_science.BASE / 'models/quint/task_group_custody.qnt'), '--backend', 'typescript', '--init', 'init', '--step', 'step', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=h.process_profile)
        _science.context.command('group-root-samples', ['quint', 'run', str(_science.BASE / 'models/quint/task_group_roots.qnt'), '--backend', 'typescript', '--init', 'init', '--step', 'step', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=h.process_profile)
        q = _science.BASE / 'models/quint/native_artifact_partition.qnt'
        _science.context.command('partition-samples', ['quint', 'run', str(q), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=h.process_profile)
        foundations = ['FrameRoots', 'FrameContract', 'FutureCoordinates', 'FrameBitmapComposition', 'FrameCursorClosure', 'FrameCursorAst', 'FrameCursorRefinement', 'FrameCursorWords']
        leanFiles = [_science.ROOT / 'dev/refactoring/modern-c/models/lean' / (n + '.lean') for n in foundations]
        leanFiles += sorted({_science.ROOT / b['leanPath'] for b in qntLeanRoutes if Path(b['leanPath']).stem not in foundations})
        leanFiles.sort(key=lambda f: (f.stem == 'DevelopmentBenefit', f.stem == 'TaskGroupCustody'))
        for f in leanFiles:
            bindings[str(f.relative_to(_science.ROOT))] = _science.sha(f)
            assert not re.search('\\bsorry\\b|\\baxiom\\s', f.read_text())
            _science.context.command('lean-' + f.stem, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (f.stem + '.olean')), str(f)], policy=h.process_profile)
        audit = _study_workspace('CACHE') / 'benefit-axioms.lean'
        names = re.findall('^theorem (\\w+)', (_science.BASE / 'models/lean/DevelopmentBenefit.lean').read_text(), re.M)
        _study_write_text(audit, 'import DevelopmentBenefit\n' + ''.join(('#print axioms Gambit.DevelopmentBenefit.' + n + '\n' for n in names)))
        assert 'sorryAx' not in _science.context.command('benefit-axioms', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(audit)], policy=h.process_profile)
        routes = [[b[k] for k in ['key', 'role.roleId', 'stage.key', 'descriptor.fieldId', 'sourcePath', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'proofLimit']] for b in p['c23Boundary'] + p['linkCut'] + p['stageCut'] + p['preparationCut']]
        painRoutes = [[b[k] for k in ['key', 'component.key', 'stage.key', 'boundary.key', 'historyPath', 'sourcePath', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'proofLimit']] for b in p['reconstruction']]
        artifacts = sorted({(b[k], _science.sha(_science.ROOT / b[k])) for b in formalRoutes for k in ['sourcePath', 'qntPath', 'leanPath']} | {(b[k], _science.sha(_science.ROOT / b[k])) for b in p['groupLifetime'] + p['groupCustody'] + p['groupShutdown'] + p['foreignResult'] + p['providerDuty'] for k in ['sourcePath', 'qntPath', 'leanPath']} | {(b[k], _science.sha(_science.ROOT / b[k])) for b in p['benefit'] + p['target'] for k in ['qntPath', 'leanPath']} | {(b['historyPath'], _science.sha(_science.ROOT / b['historyPath'])) for b in p['reconstruction']} | {(b['sourcePath'], _science.sha(_science.ROOT / b['sourcePath'])) for b in p['lever']} | {(b['path'], _science.sha(_science.ROOT / b['path'])) for b in p['causal']} | {(b['sourcePath'], _science.sha(_science.ROOT / b['sourcePath'])) for b in p['linkCaller']} | {(b[k], _science.sha(_science.ROOT / b[k])) for b in p['preparationOwner'] for k in ['sourcePath', 'historyPath']} | {(b['sourcePath'], _science.sha(_science.ROOT / b['sourcePath'])) for b in p['readinessDependency'] + p['foundationWriter'] + p['groupCaller'] + p['groupSync']} | {(b['basisPath'], _science.sha(_science.ROOT / b['basisPath'])) for b in p['groupSync']})
        need = [[b['key'], 'actual-source-refinement:' + b['key']] for b in formalRoutes] + [['link-caller-capability-closure', 'all-indirect-callers-and-effect-capabilities-managed'], ['preparation-exclusive-attribution', 'same-cohort-exclusive-per-caller-costs-and-removable-work'], ['readiness-read-effect-closure', 'actual-dynamic-positive-negative-reader-and-native-input-closure'], ['snapshot-writer-alias-closure', 'actual-managed-writers-private-outputs-and-external-alias-boundary'], ['group-c23-lock-root-refinement', 'actual-rooted-member-lifetime-and-qualified-lock-or-reads-from'], ['group-public-member-caller-closure', 'every-compiler-bootstrap-public-registration-and-derived-grant-managed'], ['group-root-slot-forward-simulation', 'actual-Scheme-supervisor-anchor-and-context-GC-slot-abstraction-preserved'], ['group-resolver-physical-retirement', 'actual-generation-lookup-pin-close-and-all-native-observer-aliases-drained']]
        perf = [['matched-macos-whole-request-and-runtime-cost'], ['matched-linux-nonregression']]
        benefitRoutes = [[b[k] for k in ['key', 'pain.key', 'creditClass', 'metric', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'scope']] for b in p['benefit']]
        credits = [[b['creditClass'], b['key'], b['metric']] for b in p['benefit']]
        assert len({c[0] for c in credits}) == len(credits), 'Declared credit classes need one canonical owner'
        targetRoutes = [[str(b[k]) for k in ['key', 'comparison', 'numerator', 'denominator', 'qntPath', 'qntModule', 'qntTest', 'leanPath', 'lemma', 'scope']] for b in p['target']]
        ratioNeed = [[b['key'], b['measurementScope']] for b in p['target']]
        leverRoutes = [[b[k] for k in ['key', 'benefit.key', 'sourcePath', 'composition', 'scopeTransfer', 'retirement']] for b in p['lever']]
        causalRoutes = [[b[k] for k in ['key', 'lever.key', 'cohort', 'kind', 'path', 'clock', 'established', 'excludes']] for b in p['causal']]
        observedRoutes = [[str(b[k]) for k in ['key', 'evidence.key', 'cohort', 'clock', 'microseconds']] for b in p['observed']]
        callerRoutes = [[b[k] for k in ['key', 'route', 'sourcePath', 'kind', 'inputProjection', 'admission', 'retirement', 'openCallers']] for b in p['linkCaller']]
        propagationRoutes = [[b[k] for k in ['key', 'route', 'change', 'retained', 'invalidated', 'condition', 'qntPath', 'qntTest']] for b in p['linkPropagation']]
        lifetimeRoutes = [[b[k] for k in ['key', 'route', 'sourcePath', 'observation', 'handoff', 'obligation', 'qntPath', 'qntTest', 'leanPath', 'lemma']] for b in p['groupLifetime'] + p['groupCustody'] + p['groupShutdown'] + p['foreignResult'] + p['providerDuty']]
        lemmaFacts = [[b['leanPath'], b['lemma']] for b in p['groupLifetime'] + p['groupCustody'] + p['groupShutdown'] + p['foreignResult'] + p['providerDuty']]
        modelTests = [[b['qntPath'], b['qntTest']] for b in p['groupLifetime'] + p['groupCustody'] + p['groupShutdown'] + p['foreignResult'] + p['providerDuty']] + [[b['qntPath'], b['qntTest']] for b in p['linkPropagation']] + [['dev/architecture/toolchain/models/quint/preparation_reuse.qnt', b['qntTest']] for b in p['readinessDependency'] + p['foundationWriter'] + p['groupCaller'] + p['groupSync']]
        preparationRoutes = [[b[k] for k in ['key', 'route', 'sourcePath', 'historyPath', 'calls', 'timing', 'replacement', 'retained', 'retirement']] for b in p['preparationOwner']]
        dependencyRoutes = [[b[k] for k in ['key', 'route', 'sourcePath', 'observation', 'invalidation', 'admission', 'qntTest']] for b in p['readinessDependency']]
        writerRoutes = [[b[k] for k in ['key', 'route', 'sourcePath', 'writes', 'owner', 'requiredEvidence', 'unknownCustody', 'qntTest']] for b in p['foundationWriter']]
        groupCallerRoutes = [[b[k] for k in ['key', 'route', 'sourcePath', 'currentAction', 'custodyBefore', 'requiredHandoff', 'refusal', 'qntTest']] for b in p['groupCaller']]
        groupSyncRoutes = [[b[k] for k in ['key', 'route', 'sourcePath', 'basisPath', 'protectedState', 'visibility', 'obligation', 'qntTest']] for b in p['groupSync']]
        for row in p['shutdownCase']:
            assert re.search('\\brun ' + row['qntTest'] + '\\s*=', (_science.BASE / 'models/quint/service_shutdown.qnt').read_text())
        factorRoutes = [[b[k] for k in ['key', 'sourcePath', 'evidence.path', 'evidence.established', 'evidence.excludes', 'missing', 'gate']] for b in p['costFactor']]
        providerCoverage = [[b['key'], b['manifest'], b['issuer']] for b in p['providerDuty']]
        foreignContracts = [[b[k] for k in ['key', 'ownDuty', 'storageFact', 'descendantFact', 'semanticClass']] for b in p['foreignResult'] + p['providerDuty']]
        results = {}
        shutdownResults = {}
        engine = Engine()
        try:
            session = engine.open_sources(rules.read_text())
            assert session.run(queries=['gap'])['complete']
            for case in ['current', 'synthetic-all', 'stale-source', 'wrong-stage', 'wrong-descriptor', 'wrong-proof', 'model-is-source', 'component-is-speedup', 'wrong-pain-owner', 'patch-is-refactor', 'scheme-is-c-expansion', 'missing-pain-source', 'wrong-benefit-metric', 'duplicated-work-credit', 'darwin-is-linux-acceptance', 'theory-is-measurement', 'target-number-tamper', 'component-is-whole-target', 'twofold-is-stretch', 'old-linux-is-final', 'missing-lever-source', 'macro-is-dominant-tail', 'shift-is-work-elimination', 'worker-sum-is-wall', 'cross-cohort-budget', 'uncovered-gap-is-macro', 'acceleration-is-residual-gap', 'double-count-nested-intervals', 'link-order-is-set', 'link-group-partial', 'link-unknown-is-reexecute', 'occupancy-is-cpu', 'fpo-is-separate-mode', 'pkg-config-is-link-only', 'shared-context-is-parallel', 'caller-family-is-complete', 'missing-propagation-test', 'all-five-scans-before-link', 'other-cohort-is-gap-timer', 'skip-live-binding-initializer', 'entry-hit-is-library-authority', 'unknown-writer-is-success', 'gap-is-guaranteed-saving', 'ssi-imports-are-complete', 'selected-file-is-lookup', 'entry-is-always-local', 'exception-is-group-drain', 'lane-controls-external-writers', 'unknown-candidate-may-discard', 'queue-before-root-registration', 'unrelated-acquire-is-enough', 'unknown-means-grant-revoked', 'diagnostic-name-is-member-id', 'one-process-status-is-group-success', 'duplicate-result-may-overwrite', 'root-is-copied-word', 'scheme-end-is-process-terminal', 'successor-retires-observers', 'gc-waits-for-observer', 'pid-is-invocation-generation', 'tgroup-is-terminal-anchor', 'still-transfer-moves-rc', 'release-error-is-not-freed', 'one-known-member-is-all', 'unknown-free-is-retry', 'lexical-set-is-all-writers', 'retained-vm-is-root-domain', 'logical-closed-is-physical', 'cleared-wrapper-is-completion', 'group-error-is-drain', 'early-dlclose-is-safe', 'cleanup-error-is-retry', 'gc-normal-return-is-resource-complete', 'zero-is-native-free', 'own-free-is-descendant-complete', 'generic-final-error-is-posix-path', 'gc-policy-change-is-equivalent', 'missing-provider-resource', 'wrong-provider-issuer', 'factor-wrong-source', 'factor-erases-counterevidence', 'factor-gap-is-cause', 'factor-plan-is-attribution']:
                factorSeen = copy.deepcopy(factorRoutes)
                if case == 'factor-wrong-source':
                    factorSeen[0][1] = 'unrelated-caller'
                if case == 'factor-erases-counterevidence':
                    factorSeen[1][4] = 'imports-are-always-primary-tail'
                if case == 'factor-gap-is-cause':
                    factorSeen[6][5] = 'all-uncovered-time-is-macro'
                if case == 'factor-plan-is-attribution':
                    factorSeen[2][6] = 'LinkPlan-design-proves-Darwin-root-cause'
                coverageSeen = copy.deepcopy(providerCoverage)
                if case == 'missing-provider-resource':
                    coverageSeen[0][1] = 'outer-allocation-only'
                if case == 'wrong-provider-issuer':
                    coverageSeen[0][2] = 'unauthorized-callback-return'
                contractSeen = copy.deepcopy(foreignContracts)
                if case == 'zero-is-native-free':
                    contractSeen[0][2] = 'native-payload-free-proved-by-zero'
                if case == 'own-free-is-descendant-complete':
                    contractSeen[7][3] = 'all-nested-resources-known-by-outer-free'
                if case == 'generic-final-error-is-posix-path':
                    contractSeen[8][2] = 'nonzero-final-release-is-proved-darwin-path'
                if case == 'gc-policy-change-is-equivalent':
                    contractSeen[4][4] = 'unchanged-all-caller-error-policy'
                lifetimeSeen = copy.deepcopy(lifetimeRoutes)
                if case == 'root-is-copied-word':
                    lifetimeSeen[4][4] = 'Keep a copied Scheme word across GC'
                if case == 'scheme-end-is-process-terminal':
                    lifetimeSeen[5][4] = 'Thread terminal result closes all native work'
                if case == 'successor-retires-observers':
                    lifetimeSeen[8][4] = 'Successor publication retires every observer'
                if case == 'gc-waits-for-observer':
                    lifetimeSeen[3][4] = 'Freeze waits for every result observer to finish'
                if case == 'pid-is-invocation-generation':
                    lifetimeSeen[7][4] = 'PID alone authenticates invocation generation'
                if case == 'tgroup-is-terminal-anchor':
                    lifetimeSeen[12][4] = 'Thread-group membership roots every completed result forever'
                if case == 'still-transfer-moves-rc':
                    lifetimeSeen[15][4] = 'Existing still transfer rehomes every RC block and borrower'
                if case == 'release-error-is-not-freed':
                    lifetimeSeen[17][4] = 'Nonzero final release result proves allocation remains live'
                if case == 'one-known-member-is-all':
                    lifetimeSeen[10][4] = 'One known member proves the whole group terminal'
                if case == 'unknown-free-is-retry':
                    lifetimeSeen[17][4] = 'Retry native release after outcome becomes unknown'
                if case == 'lexical-set-is-all-writers':
                    lifetimeSeen[21][4] = 'Lexical set! sites exclude all indirect root mutation'
                if case == 'retained-vm-is-root-domain':
                    lifetimeSeen[24][4] = 'Retaining VM shell preserves freed global cells'
                if case == 'logical-closed-is-physical':
                    lifetimeSeen[27][4] = 'Logical CLOSED certifies physical descriptor close'
                if case == 'cleared-wrapper-is-completion':
                    lifetimeSeen[28][4] = 'Cleared foreign wrapper proves destructor completed'
                if case == 'group-error-is-drain':
                    lifetimeSeen[26][4] = 'Void device group cleanup proves complete drain after error'
                if case == 'early-dlclose-is-safe':
                    lifetimeSeen[30][4] = 'Unload callback code before unknown cleanup settles'
                if case == 'cleanup-error-is-retry':
                    lifetimeSeen[27][4] = 'Reset whole close operation on every returned error'
                if case == 'gc-normal-return-is-resource-complete':
                    lifetimeSeen[31][4] = 'Normal callback return proves all native resources settled'
                groupCallerSeen = copy.deepcopy(groupCallerRoutes)
                groupSyncSeen = copy.deepcopy(groupSyncRoutes)
                dependencySeen = copy.deepcopy(dependencyRoutes)
                writerSeen = copy.deepcopy(writerRoutes)
                preparationSeen = copy.deepcopy(preparationRoutes)
                callerSeen = copy.deepcopy(callerRoutes)
                propagationSeen = copy.deepcopy(propagationRoutes)
                testSeen = copy.deepcopy(modelTests)
                causalSeen = copy.deepcopy(causalRoutes)
                observedSeen = copy.deepcopy(observedRoutes)
                targetSeen = copy.deepcopy(targetRoutes)
                ratioSeen = copy.deepcopy(ratioNeed)
                leverSeen = copy.deepcopy(leverRoutes)
                benefitSeen = copy.deepcopy(benefitRoutes)
                creditSeen = copy.deepcopy(credits)
                seen = copy.deepcopy(routes)
                painSeen = copy.deepcopy(painRoutes)
                av = copy.deepcopy(artifacts)
                sv = copy.deepcopy(need)
                pv = copy.deepcopy(perf)
                if case == 'queue-before-root-registration':
                    groupCallerSeen[0][5] = 'Queue visibility before stable root registration is safe'
                if case == 'unrelated-acquire-is-enough':
                    groupSyncSeen[1][5] = 'Any unrelated atomic acquire publishes payload'
                if case == 'unknown-means-grant-revoked':
                    groupCallerSeen[8][6] = 'Unknown observation revokes all live producer grants'
                if case == 'diagnostic-name-is-member-id':
                    groupCallerSeen[2][6] = 'Same diagnostic name deduplicates real executions'
                if case == 'one-process-status-is-group-success':
                    groupCallerSeen[8][5] = 'One native exit zero closes the entire group'
                if case == 'duplicate-result-may-overwrite':
                    groupSyncSeen[2][4] = 'Repeated notifications can overwrite the known result slot'
                if case == 'ssi-imports-are-complete':
                    dependencySeen[0][3] = 'Only SSI imports matter'
                if case == 'selected-file-is-lookup':
                    dependencySeen[1][5] = 'Selected file bytes alone close lookup'
                if case == 'entry-is-always-local':
                    dependencySeen[7][4] = 'Entry changes never affect libraries'
                if case == 'exception-is-group-drain':
                    writerSeen[7][5] = 'Parent exception proves all children drained'
                if case == 'lane-controls-external-writers':
                    writerSeen[3][5] = 'The package lane excludes all editors and native writers'
                if case == 'unknown-candidate-may-discard':
                    writerSeen[6][6] = 'Discard pending attempt and blindly retry unknown producer'
                if case == 'all-five-scans-before-link':
                    preparationSeen[0][4] = 'All five inventories are exclusively inside preparation'
                if case == 'other-cohort-is-gap-timer':
                    preparationSeen[1][5] = '11.616248 seconds allocated to this exact 26.907860-second gap'
                if case == 'skip-live-binding-initializer':
                    preparationSeen[3][7] = 'Live binding identity and initializer effects may be skipped'
                if case == 'entry-hit-is-library-authority':
                    seen[13][9] = 'Only an upper entry HIT can admit unchanged library layers'
                if case == 'unknown-writer-is-success':
                    seen[14][8] = 'unknownRefusesSuccessorNotNeeded'
                if case == 'gap-is-guaranteed-saving':
                    causalSeen[3][6] = 'All uncovered preparation time is removable hashing'
                if case == 'fpo-is-separate-mode':
                    callerSeen[1][3] = 'separate-executable'
                if case == 'pkg-config-is-link-only':
                    propagationSeen[3][4] = 'final executable only'
                if case == 'shared-context-is-parallel':
                    seen[10][9] = 'shared target state needs no private owner'
                if case == 'caller-family-is-complete':
                    sv[-1][1] = 'direct-text-search-only'
                if case == 'missing-propagation-test':
                    testSeen = [x for x in testSeen if x[1] != 'ccMetadataInvalidatesObjectTest']
                if case == 'link-order-is-set':
                    seen[5][9] = 'ordered metadata can be deduplicated'
                if case == 'link-group-partial':
                    seen[6][7] = 'partial output group suffices'
                if case == 'link-unknown-is-reexecute':
                    seen[7][8] = 'repeat native action after lost reply'
                if case == 'occupancy-is-cpu':
                    causalSeen[6][6] = '11.89 CPUs fully busy'
                if case == 'wrong-benefit-metric':
                    benefitSeen[0][3] = 'memory'
                if case == 'duplicated-work-credit':
                    creditSeen.append([credits[0][0], credits[1][1], credits[0][2]])
                if case == 'darwin-is-linux-acceptance':
                    pv = [['matched-macos-whole-request-and-runtime-cost']]
                if case == 'theory-is-measurement':
                    pv = [['conditional-algebra-is-both-platforms-performance']]
                if case == 'current':
                    sv = []
                    pv = []
                    ratioSeen = []
                if case == 'target-number-tamper':
                    targetSeen[0][1] = '1'
                if case == 'component-is-whole-target':
                    ratioSeen = [[a, 'historical-single-object-time'] for a, b in ratioNeed]
                if case == 'twofold-is-stretch':
                    ratioSeen[1][1] = ratioNeed[0][1]
                if case == 'old-linux-is-final':
                    ratioSeen[0][1] = 'whole-request-against-old-linux'
                if case == 'macro-is-dominant-tail':
                    causalSeen[1][6] = 'macro expansion is the established dominant owner'
                if case == 'shift-is-work-elimination':
                    causalSeen[2][6] = 'six seconds of imports were eliminated'
                if case == 'worker-sum-is-wall':
                    causalSeen[1][5] = 'monotonic-disjoint-microseconds'
                if case == 'cross-cohort-budget':
                    observedSeen[0][2] = 'D803-owner'
                if case == 'uncovered-gap-is-macro':
                    causalSeen[3][6] = 'all uncovered preparation is macro expansion'
                if case == 'acceleration-is-residual-gap':
                    ratioSeen[0][1] = ratioNeed[2][1]
                if case == 'double-count-nested-intervals':
                    observedSeen[2][4] = str(int(observedSeen[2][4]) + 1)
                if case == 'missing-lever-source':
                    av = [x for x in av if x[0] != leverRoutes[2][2]]
                if case == 'stale-source':
                    av = [(x[0], 'stale') for x in av]
                if case == 'wrong-stage':
                    seen[0][2] = 'native-manifest'
                if case == 'wrong-descriptor':
                    seen[0][3] = 'FS-SEMANTIC'
                if case == 'wrong-proof':
                    seen[0][8] = 'sourceProofSeparate'
                if case == 'model-is-source':
                    sv[0][1] = 'typecheck-and-samples-only'
                if case == 'wrong-pain-owner':
                    painSeen[0][1] = 'resource-scheduler'
                if case == 'patch-is-refactor':
                    sv[-1][1] = 'historical-patch-PASS'
                if case == 'scheme-is-c-expansion':
                    painSeen[0][2] = 'generated-modern-c'
                if case == 'missing-pain-source':
                    av = [x for x in av if x[0] != painRoutes[0][5]]
                if case == 'component-is-speedup':
                    pv = [['historical-single-object-result']]
                session.replace(dict(factorPair=[[r[0], 'synthetic-pair', 'same-work', 'same-contract', 'same-clock', 'closed'] for r in factorRoutes] if case == 'synthetic-all' else [], factorIntervention=[[r[0], 'synthetic-pair', 'qualified'] for r in factorRoutes] if case == 'synthetic-all' else [], factorNeed=factorRoutes, factorSeen=factorSeen, providerCoverageNeed=providerCoverage, providerCoverageSeen=coverageSeen, foreignContractNeed=foreignContracts, foreignContractSeen=contractSeen, lifetimeNeed=lifetimeRoutes, lifetimeSeen=lifetimeSeen, lemmaFact=lemmaFacts, groupCallerNeed=groupCallerRoutes, groupCallerSeen=groupCallerSeen, groupSyncNeed=groupSyncRoutes, groupSyncSeen=groupSyncSeen, dependencyNeed=dependencyRoutes, dependencySeen=dependencySeen, writerNeed=writerRoutes, writerSeen=writerSeen, preparationNeed=preparationRoutes, preparationSeen=preparationSeen, callerNeed=callerRoutes, callerSeen=callerSeen, propagationNeed=propagationRoutes, propagationSeen=propagationSeen, modelTest=testSeen, causalNeed=causalRoutes, causalSeen=causalSeen, observedNeed=observedRoutes, observedSeen=observedSeen, targetNeed=targetRoutes, targetSeen=targetSeen, ratioEvidenceNeed=ratioNeed, ratioEvidenceSeen=ratioSeen, leverNeed=leverRoutes, leverSeen=leverSeen, benefitNeed=benefitRoutes, benefitSeen=benefitSeen, creditNeed=credits, creditSeen=creditSeen, routeNeed=routes, routeSeen=seen, painNeed=painRoutes, painSeen=painSeen, artifactNeed=artifacts, artifactSeen=av, sourceNeed=need, sourceSeen=sv, performanceNeed=perf, performanceSeen=pv))
                result = session.run(queries=['factorMapped', 'factorCausalReady', 'providerCoverageLinked', 'foreignContractLinked', 'lifetimeLinked', 'groupCallerLinked', 'groupSyncLinked', 'dependencyLinked', 'writerLinked', 'preparationLinked', 'callerLinked', 'propagationLinked', 'designLinked', 'painLinked', 'theoreticalBenefitLinked', 'targetLinked', 'leverLinked', 'causalLinked', 'observedLinked', 'targetRatioAccepted', 'gap', 'nativeGainAccepted'])
                assert result['complete']
                results[case] = result['relations']
            for row in p['shutdownCase']:
                scope = row['key']
                expected = [[scope, str(i)] for i in range(2) if row['expected' + str(i)] == 'yes']
                members = [[scope, str(i), row['stage' + str(i)], row['unknown' + str(i)], row['process' + str(i)], row['debt' + str(i)]] for i in range(2) if row['present' + str(i)] == 'yes']
                owner = [[scope] + [row[k] for k in ['admitting', 'writers', 'rawWriter', 'anchor', 'producer', 'vmLive', 'moduleLive']]]
                session.replace(dict(shutdownRequest=[[scope]], shutdownExpected=expected, shutdownMember=members, shutdownOwner=owner))
                result = session.run(queries=['shutdownModelReady', 'shutdownBlocked', 'shutdownUnsafeTeardown'])
                assert result['complete']
                shutdownResults[scope] = result['relations']
                assert bool(result['relations']['shutdownModelReady']) == (row['ready'] == 'yes')
                if row['ready'] == 'no':
                    assert result['relations']['shutdownBlocked']
            assert shutdownResults['retained-shell']['shutdownUnsafeTeardown'] and shutdownResults['freed-container-debt']['shutdownUnsafeTeardown']
        finally:
            engine.close()
        assert len(results['current']['targetLinked']) == 3 and len(results['current']['leverLinked']) == 9
        assert len(results['current']['causalLinked']) == 8 and len(results['current']['observedLinked']) == 5
        assert not results['current']['targetRatioAccepted'] and len(results['synthetic-all']['targetRatioAccepted']) == 3
        assert all((not v['targetRatioAccepted'] for k, v in results.items() if k != 'synthetic-all'))
        assert len(results['current']['theoreticalBenefitLinked']) == 8
        assert len(results['current']['painLinked']) == 6
        assert len(results['current']['designLinked']) == 29 and (not results['current']['nativeGainAccepted'])
        assert [k for k, v in results.items() if v['nativeGainAccepted']] == ['synthetic-all']
        assert len(results['current']['lifetimeLinked']) == 50
        assert len(results['current']['foreignContractLinked']) == 18
        assert len(results['current']['providerCoverageLinked']) == 8
        assert len(results['current']['factorMapped']) == 9
        assert len(results['synthetic-all']['factorCausalReady']) == 9
        assert all((not v['factorCausalReady'] for k, v in results.items() if k != 'synthetic-all'))
        for case in ['factor-wrong-source', 'factor-erases-counterevidence', 'factor-gap-is-cause', 'factor-plan-is-attribution']:
            assert len(results[case]['factorMapped']) == 8 and results[case]['gap']
        for case in ['missing-provider-resource', 'wrong-provider-issuer']:
            assert len(results[case]['providerCoverageLinked']) == 7 and results[case]['gap']
        for case in ['zero-is-native-free', 'own-free-is-descendant-complete', 'generic-final-error-is-posix-path', 'gc-policy-change-is-equivalent']:
            assert len(results[case]['foreignContractLinked']) == 17 and results[case]['gap']
        for case in ['root-is-copied-word', 'scheme-end-is-process-terminal', 'successor-retires-observers', 'gc-waits-for-observer', 'pid-is-invocation-generation', 'tgroup-is-terminal-anchor', 'still-transfer-moves-rc', 'release-error-is-not-freed', 'one-known-member-is-all', 'unknown-free-is-retry', 'lexical-set-is-all-writers', 'retained-vm-is-root-domain', 'logical-closed-is-physical', 'cleared-wrapper-is-completion', 'group-error-is-drain', 'early-dlclose-is-safe', 'cleanup-error-is-retry', 'gc-normal-return-is-resource-complete']:
            assert len(results[case]['lifetimeLinked']) == 49
            missing = set((r[0] for r in results['current']['lifetimeLinked'])) - set((r[0] for r in results[case]['lifetimeLinked']))
            assert missing and missing.issubset(set((r[0] for r in results[case]['gap'])))
        assert len(results['current']['groupCallerLinked']) == 9 and len(results['current']['groupSyncLinked']) == 3
        assert len(results['current']['dependencyLinked']) == 9 and len(results['current']['writerLinked']) == 8
        assert len(results['current']['preparationLinked']) == 6
        assert len(results['current']['callerLinked']) == 11 and len(results['current']['propagationLinked']) == 8
        _science.save(_study_workspace('CACHE') / 'shutdown-ascent-model-guards.json', dict(cases=shutdownResults, scope='SysML illustrative model observations, not extracted native executions', nativeAdmission=False))
        _science.save(_study_workspace('CACHE') / 'ascent.json', dict(results=results, syntheticIsNotEvidence=True))
        lines = ['#+TITLE: C23 Development Refactor Decisions and Retirement Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitDarwinDevelopment', ':STATUS: design checked; native source and performance open', ':END:']
        for g, _, _ in _science.GROUPS:
            fields = list(p[g][0])
            lines += ['', '** ' + g, '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(r[k]).replace('|', ' / ') for k in fields)) + ' |' for r in p[g]]
        matrix = _science.BASE / 'c23-development-refactor-matrix.org'
        _study_write_text(matrix, '\n'.join(lines) + '\n')
        d2 = _science.BASE / 'diagrams/c23-development-refactor.d2'
        _study_write_text(d2, 'direction: right\n' + '\n'.join((json.dumps(e['fromNode']) + ' -> ' + json.dumps(e['toNode']) + ': ' + json.dumps(e['contract']) for e in p['c23Edge'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=h.process_profile)
        factorDiagram = _science.BASE / 'diagrams/darwin-cost-factors.d2'
        _study_write_text(factorDiagram, 'direction: right\n' + '\n'.join((json.dumps(b['evidence.key']) + ' -> ' + json.dumps(b['key']) + ': ' + json.dumps(b['status']) + '\n' + json.dumps(b['key']) + ' -> ' + json.dumps(b['gate']) + ': ' + json.dumps(b['missing']) for b in p['costFactor'])) + '\n')
        _science.context.command('darwin-cost-factors-d2', ['d2', '--layout', 'elk', str(factorDiagram), str(factorDiagram.with_suffix('.svg'))], policy=h.process_profile)
        providerDiagram = _science.BASE / 'diagrams/provider-manifest.d2'
        _study_write_text(providerDiagram, 'direction: right\n' + '\n'.join((json.dumps(b['key']) + ' -> ' + json.dumps(b['manifest']) + ': ' + json.dumps(b['issuer']) for b in p['providerDuty'])) + '\n')
        _science.context.command('provider-manifest-d2', ['d2', '--layout', 'elk', str(providerDiagram), str(providerDiagram.with_suffix('.svg'))], policy=h.process_profile)
        foreignDiagram = _science.BASE / 'diagrams/foreign-destructor-outcome.d2'
        _study_write_text(foreignDiagram, 'direction: right\n' + '\n'.join((json.dumps(e['fromNode']) + ' -> ' + json.dumps(e['toNode']) + ': ' + json.dumps(e['contract']) for e in p['c23Edge'][52:56])) + '\n')
        _science.context.command('foreign-outcome-d2', ['d2', '--layout', 'elk', str(foreignDiagram), str(foreignDiagram.with_suffix('.svg'))], policy=h.process_profile)
        for f in [_science.BASE / 'darwin-cost-factor-design.org', _science.BASE / 'darwin-turbo-study.org', factorDiagram, factorDiagram.with_suffix('.svg'), providerDiagram, providerDiagram.with_suffix('.svg'), _science.BASE / 'foreign-destructor-outcome-design.org', foreignDiagram, foreignDiagram.with_suffix('.svg'), _science.BASE / 'stable-task-group-design.org', _science.BASE / 'preparation-product-design.org', _science.BASE / 'c23-development-refactor-design.org', matrix, d2, d2.with_suffix('.svg'), _science.BASE / 'index.org']:
            bindings[str(f.relative_to(_science.ROOT))] = _science.sha(f)
        drift = [f for f, v in bindings.items() if _science.sha(_science.ROOT / f) != v]
        assert not drift, drift
        checks = dict(costFactorRoutes=9, qualifiedPlatformCauses=0, newNativeExperimentsAuthorizedByThisStudy=False, nativeSysml=True, nativeSysmlFiles=len(selected), wholeDevValidation=False, qntSourceClosureFiles=len(importClosure), featurePolicies=6, typedBoundaryRoutes=29, foreignResultFamilies=10, providerDutyFamilies=8, shutdownHistories=40, shutdownLeanLaws=26, shutdownSamples=500, shutdownGuardCases=8, shutdownCallerFamilies=13, wholeGroupCustodyHistories=22, wholeGroupCustodyLeanLaws=12, wholeGroupCustodySamples=500, rootCompositionHistories=6, groupLifetimeCallerFamilies=10, groupCustodyCallerFamilies=9, rootRetirementHistories=18, rootRetirementLeanLaws=14, rootRetirementSamples=500, stableGroupCallerFamilies=9, groupSynchronizationContracts=3, readinessDependencyFamilies=9, foundationWriterFamilies=8, preparationOwnerFamilies=6, preparationHistories=56, preparationLeanLaws=25, linkContextCompositionHistories=5, linkCallerFamilies=11, linkPropagationCases=8, linkStageHistories=18, linkStageLeanLaws=18, linkProductHistories=8, linkProductLeanLaws=8, reconstructionRoutes=6, sourceAndPerformanceGaps=len(results['current']['gap']), historicalPatchesAreAdmission=False, theoreticalBenefitRoutes=8, elapsedTargets=3, sourceBoundGainLevers=9, targetBudgetHistories=12, causalEvidenceCases=8, observedPartitionStages=5, observedPartitionHistories=12, achievedTargetRatios=[], benefitLeanLaws=len(names), newDarwinLinuxMeasurementPerformed=False, proposedReplacementLinuxNonRegressionAccepted=False, existingEvidenceInvalidated=False, newPartitionHistories=11, partitionSamples=500, maxSteps=80, seed=953, partitionLeanLaws=8, ascentScenarios=len(results), sourceRefinement=False, verifiedExtractor=False, measuredSpeedup=False, runtimeImplementation=False, nativeTests=0, pathsRetired=0, timeoutSeconds=60)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(sourceBindings=bindings, leanBinarySha256=_science.sha(_science.LEAN), scope='C23 design and conditional formal routes; no native admission'))
        for f, digest in bindings.items():
            snapshot = Path(f) if '..' not in Path(f).parts else Path('external') / hashlib.sha256(f.encode()).hexdigest()[:16] / Path(f).name
            target = _study_workspace('CACHE') / 'input-cut' / snapshot
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(_science.ROOT / f, target)
            assert _science.sha(target) == digest
        for f in _study_workspace('CACHE').rglob('*'):
            if f.is_file():
                target = _study_workspace('OUT') / f.relative_to(_study_workspace('CACHE'))
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(f, target)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks, indent=2))

# Preserved scientific source notes (in original order).
# Literal projection from native SysML, numerically checked against the original
# receipt. Existing pure QNT predicates own the arithmetic; no new scheduler.
# Pin local literal QNT imports, including parameter modules. This is an
# auditable import-syntax projection, not a verified module resolver.
# Existing scheduler/context models retain their owners; check the selected routes.
