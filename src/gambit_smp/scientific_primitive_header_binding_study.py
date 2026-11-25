"""Static source and formal research; never runs or builds native Gambit."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy
import hashlib
import json
import re
import shutil

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.hashlib = hashlib
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.ROOT = _science.context.root
        _science.STEM = 'primitive-header-binding'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitPrimitiveHeaderBinding'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def bytes_audit(_science, snapshots):
        path = 'vendor/gambit/lib/_kernel.c'
        raw = (_science.ROOT / snapshots[path]['path']).read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        name = b'##get-monotonic-time!'
        encoded = b'___G__23__23_get_2d_monotonic_2d_time_21_'
        section = b'globals-s-nd'
        marker = b'( #|*/"*/"' + section + b'|#\n'
        begin = raw.index(marker) + len(marker)
        end = raw.index(b') #|*/"*/"' + section + b'|#', begin)
        records = []

        def add(key, start, stop, **fields):
            assert 0 <= start < stop <= len(raw)
            payload = raw[start:stop]
            row = dict(key=key, start=start, stop=stop, line=raw[:start].count(b'\n') + 1, payload=payload.decode('ascii'), payloadSha256=hashlib.sha256(payload).hexdigest(), **fields)
            records.append(row)
            return row
        header = b'"' + name + b'"\n'
        pos = raw.index(header, begin, end)
        add('header-name', pos, pos + len(header), section='globals-s-nd')
        binding = {}
        for role in ['PRM', 'GLO']:
            pattern = b'^___DEF_MOD_' + role.encode() + b'\\((\\d+),(' + re.escape(encoded) + b'),(\\d+)\\)\\n'
            matches = list(re.finditer(pattern, raw, re.M))
            assert len(matches) == 1
            m = matches[0]
            binding[role] = (int(m[1]), m[2].decode(), int(m[3]))
            add(role, m.start(), m.end(), slot=int(m[1]), label=int(m[3]), fields=[dict(start=m.start(i), stop=m.end(i), text=m[i].decode()) for i in [1, 2, 3]])
        assert binding['PRM'] == binding['GLO'] == (146, encoded.decode(), 828)
        m = re.search(b'^___DEF_GLO\\((\\d+),"' + re.escape(name) + b'"\\)\\n', raw, re.M)
        assert m and int(m[1]) == binding['PRM'][0]
        add('global-index', m.start(), m.end(), slot=int(m[1]))
        host = b'#define ___PH_PROC ___H__23__23_get_2d_monotonic_2d_time_21_\n'
        start = raw.index(host)
        m = re.match(b'#define ___PH_PROC [^\\n]+\\n#undef ___PH_LBL0\\n#define ___PH_LBL0 (\\d+)\\n', raw[start:])
        assert m and int(m[1]) == binding['PRM'][2]
        add('host-label', start, start + m.end(), label=int(m[1]))
        intro = b',___DEF_LBL_INTRO(___H__23__23_get_2d_monotonic_2d_time_21_,'
        pos = raw.index(intro)
        add('label-intro', pos, raw.index(b'\n', pos) + 1)
        table_start = raw.index(b'___BEGIN_LBL\n') + len(b'___BEGIN_LBL\n')
        table_stop = raw.index(b'___END_LBL\n', table_start)
        entries = list(re.finditer(b'^[ ,]___DEF_LBL_(INTRO|PROC|RET)\\([^\\n]+\\)\\n', raw[table_start:table_stop], re.M))
        assert b''.join((m[0] for m in entries)) == raw[table_start:table_stop]
        entry = entries[binding['PRM'][2]]
        assert entry[0] == b',___DEF_LBL_PROC(___H__23__23_get_2d_monotonic_2d_time_21_,2,-1)\n'
        add('label-proc', table_start + entry.start(), table_start + entry.end(), label=binding['PRM'][2])
        records.sort(key=lambda x: x['start'])
        assert all((a['stop'] <= b['start'] for a, b in zip(records, records[1:])))

        def validate(rs):
            for v in rs:
                assert raw[v['start']:v['stop']].decode() == v['payload']
                assert hashlib.sha256(raw[v['start']:v['stop']]).hexdigest() == v['payloadSha256']
            by = {v['key']: v for v in rs}
            for role in ['PRM', 'GLO']:
                v = by[role]
                assert v['payload'] == f"___DEF_MOD_{role}({v['slot']},{encoded.decode()},{v['label']})\n"
            assert by['PRM']['slot'] == by['GLO']['slot'] and by['PRM']['label'] == by['GLO']['label']
        validate(records)
        controls = {}
        for case in ['shifted-span', 'wrong-label', 'swapped-role']:
            rs = copy.deepcopy(records)
            v = next((x for x in rs if x['key'] == 'PRM'))
            if case == 'shifted-span':
                v['start'] += 1
            if case == 'wrong-label':
                v['label'] += 1
            if case == 'swapped-role':
                v['key'] = 'GLO'
            try:
                validate(rs)
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError(case)
        all_bindings = {role: [tuple(m.groups()) for m in re.finditer(b'^___DEF_MOD_' + role.encode() + b'\\((\\d+),([^,\\n]+),(\\d+)\\)\\n', raw, re.M)] for role in ['PRM', 'GLO']}
        assert all_bindings['PRM'] == all_bindings['GLO'] and len(set(all_bindings['PRM'])) == 455
        witness = dict(source=path, sha256=digest, bytes=len(raw), intervals='zero-based-half-open-bytes', records=records, selectedBinding=binding, wholeOutputCovered=False, artifactPrimitiveRecords=455, artifactBindingRecords=910, productionModuleSpec=False, sourceGenerationProvenance='unresolved', darwinProfileProvenance='unresolved', controls=controls)
        _science.save(_study_workspace('OUT') / 'byte-witness.json', witness)
        return [[v['key'], digest, str(v['start']), str(v['stop']), v['payloadSha256']] for v in records]

    def formal(_science):
        e = _science.context.library('primitive_header_binding_projection')
        cfg = e.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        _science.context.command('qnt-typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, receipt = e.generate(ir)
        astpath = _science.BASE + 'models/lean/PrimitiveHeaderAst.lean'
        _study_write_text(_science.ROOT / astpath, ast)
        _science.save(_study_workspace('CACHE') / 'projection-receipt.json', dict(**receipt, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / astpath)))
        controls = {}
        for case in ['wrong-state-binding', 'wrong-field-kind', 'missing-step', 'unsupported-expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if case == 'wrong-state-binding':
                bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
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
        proof_names = ['PrimitiveHeaderAst', 'PrimitiveHeader', 'PrimitiveBindingAlgebra']
        formal_paths = [qnt, _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE + 'models/lean/' + n + '.lean' for n in proof_names]
        if '--reuse-formal' in _science.context.arguments:
            cp = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            assert {f: _science.sha(_science.ROOT / f) for f in formal_paths} == cp['sourceBindings']
            assert all((_science.sha(_science.ROOT / f) == d for f, d in cp['logs'].items()))
            lemmas = [[n + '.' + x] for n in proof_names[1:] for x in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
            return ([[cfg['module'] + '.' + a] for a in cfg['actions']], lemmas)
        for name in ['PrimitiveHeaderAst', 'PrimitiveHeader', 'PrimitiveBindingAlgebra']:
            src = _science.ROOT / (_science.BASE + 'models/lean/' + name + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', src.read_text())
            target = _study_workspace('CACHE') / (name + '.lean')
            _study_write_bytes(target, src.read_bytes())
            _science.context.command(name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(target)], policy=_science.process_profile)
        output = _science.context.command('qnt-histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert output.count('ok ') == 11 and output.count('ControlTest passed') == 4
        _science.context.command('qnt-samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '149', '--verbosity', '1'], policy=_science.process_profile)
        neg = _study_workspace('CACHE') / 'negative-close'
        neg.mkdir(exist_ok=True)
        bad = '\n'.join((line.replace('(q.closed=true)', 'True') if line.startswith('def issueGuard') else line for line in ast.splitlines())) + '\n'
        assert bad != ast
        _study_write_text(neg / 'PrimitiveHeaderAst.lean', bad)
        _science.context.command('negative-ast', ['lean', '-o', str(neg / 'PrimitiveHeaderAst.olean'), str(neg / 'PrimitiveHeaderAst.lean')], policy=_science.process_profile)
        try:
            _science.context.command('negative-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/PrimitiveHeader.lean'], policy=_science.process_profile)
        except RuntimeError:
            assert 'error' in (_study_workspace('CACHE') / 'negative-proof.stdout').read_text()
        else:
            raise AssertionError('missing close proved')
        lemmas = [[n + '.' + x] for n in ['PrimitiveHeader', 'PrimitiveBindingAlgebra'] for x in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sourceBindings={f: _science.sha(_science.ROOT / f) for f in formal_paths}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and f.stem in proof_names + ['qnt-histories', 'qnt-samples', 'negative-ast', 'negative-proof']}))
        return ([[cfg['module'] + '.' + a] for a in cfg['actions']], lemmas)

    def caller_audit(_science, p, snapshots):
        path = 'vendor/gambit/gsc/_t-c-2.scm'
        text = (_science.ROOT / snapshots[path]['path']).read_text()
        definitions = list(re.finditer('^\\(define \\(([^\\s()]+)', text, re.M))
        rows = []
        for m in re.finditer('\\(targ-use-glo name (#t|#f)\\)', text):
            owner = [d for d in definitions if d.start() < m.start()][-1].group(1)
            rows.append((owner, m.group(1), text[:m.start()].count('\n') + 1))
        wanted = {v['caller'] for v in p['caller']}
        assert len(rows) == 6 and {v[0] for v in rows} == wanted
        expected = {'demand false': '#f', 'supply true': '#t', 'supply then demand': '#t'}
        for v in p['caller']:
            assert [r[1] for r in rows if r[0] == v['caller']] == [expected[v['effect']]]
        start = next((d.start() for d in definitions if d.group(1) == 'targ-loc-opnd'))
        stop = next((d.start() for d in definitions if d.start() > start))
        assert text[start:stop].index('(targ-use-glo name #t)') < text[start:stop].index('(targ-opnd loc)')
        out = [[owner, flag, str(line), snapshots[path]['sha256']] for owner, flag, line in rows]
        _science.save(_study_workspace('CACHE') / 'caller-audit.json', dict(rows=out, scope='six lexical direct callers; dynamic alias closure OPEN'))
        return out

    def ascent(_science, p, witnesses, spans, actions, lemmas, callers):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        ws = [[v['key'], v['path'], v['sha256'], v['needle']] for v in witnesses]
        migrations = [[v[k] for k in ['key', 'producerAnchor', 'consumerAnchor', 'actionName', 'lemma']] for v in p['migration']]
        results = {}
        engine = _science.h.Engine()
        cases = ['current', 'synthetic-all', 'stale-digest', 'wrong-scope', 'missing-action', 'missing-lemma', 'missing-source', 'missing-migration', 'wrong-producer', 'wrong-span', 'wrong-span-digest', 'wrong-caller']
        try:
            ss = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert ss.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, f, d, s] for n, k, f, d, s in needs if case != 'current' or k in ['induction', 'interleaving', 'restricted-projection']]
                if case == 'stale-digest':
                    receipts[0][3] = 'stale'
                if case == 'wrong-scope':
                    receipts[0][4] = 'native-pass'
                mo = copy.deepcopy(migrations)
                if case == 'missing-migration':
                    mo = mo[1:]
                if case == 'wrong-producer':
                    mo[0][1] = 'unknown-producer'
                observed = copy.deepcopy(spans)
                if case == 'wrong-span':
                    observed[0][2] = str(int(observed[0][2]) + 1)
                if case == 'wrong-span-digest':
                    observed[0][4] = 'stale'
                callerObservation = copy.deepcopy(callers)
                if case == 'wrong-caller':
                    callerObservation[0][0] = 'unknown-caller'
                ss.replace(dict(scenario=[[case]], need=needs, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if case != 'missing-lemma' or v != ['PrimitiveHeader.seedSupplyPreserves']], witness=ws, observation=ws[1:] if case == 'missing-source' else ws, compositionNeed=[[v['key'], v['lemma']] for v in p['proof']], refinementNeed=[], targetActionName=[], bridgeNeed=[], bridgeObservation=[], inventoryNeed=[], inventoryObservation=[], seamNeed=[], seamObservation=[], migrationNeed=migrations, migrationObservation=mo, spanNeed=spans, spanObservation=observed, callerNeed=callers, callerObservation=callerObservation))
                result = ss.run(queries=['blocked', 'candidate', 'linked', 'compositionLinked', 'observed', 'migrationLinked', 'spanLinked', 'callerLinked'])
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
            assert {v[1] for v in results['current']['blocked']} == {'PH-source', 'PH-emission', 'PH-platform'}
            assert [c for c in cases if results[c]['candidate']] == ['synthetic-all']
            assert len(results['current']['linked']) == 12
            assert len(results['current']['observed']) == len(witnesses)
            assert len(results['current']['migrationLinked']) == 4
            assert len(results['current']['spanLinked']) == len(spans)
            assert len(results['current']['callerLinked']) == 6
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        config = json.loads((_science.ROOT / 'dev/modeling/inputs/primitive-header-binding/config.json').read_text())
        snapshots = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for path, v in snapshots.items():
            assert _science.sha(_science.ROOT / path) == _science.sha(_science.ROOT / v['path']) == v['sha256'], path
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/emission-view-correspondence/input.json'
        parentHash = _science.sha(parent)
        adapter = _science.context.library('default_lease_admission_study')
        for k, v in dict(CACHE=_study_workspace('CACHE'), OUT=_study_workspace('OUT'), PKG=_science.PKG, GROUPS=config['groups'], SLOTS=config['slots']).items():
            setattr(adapter, k, v)
        p, scope = adapter.project()
        views = _science.context.library('copy_producer_envelope_study')
        for k, v in dict(ROOT=_science.ROOT, GROUPS=config['groups'], MATRIX=_science.BASE + _science.STEM + '-matrix.org', D2=_science.BASE + 'diagrams/' + _science.STEM + '.d2').items():
            setattr(views, k, v)
        views.views(p)
        matrix = _science.ROOT / (_science.BASE + _science.STEM + '-matrix.org')
        _study_write_text(matrix, matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'Primitive Header, Native Binding and Net Benefit Matrix').replace('GambitCopyProducerEnvelope', _science.PKG))
        witnesses = []
        for v in p['source']:
            snap = snapshots[v['path']]
            text = (_science.ROOT / snap['path']).read_text()
            assert v['needle'] in text, v
            witnesses.append(dict(**v, sha256=snap['sha256'], snapshotPath=snap['path'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        spans = _science.bytes_audit(snapshots)
        callers = _science.caller_audit(p, snapshots)
        actions, lemmas = _science.formal()
        _science.ascent(p, witnesses, spans, actions, lemmas, callers)
        d2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', d2, d2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', d2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for old, new in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.BASE + _science.STEM + '-design.org'), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.BASE + _science.STEM + '-matrix.org'), ('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')]:
            org = org.replace(old, new)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        assert _science.sha(parent) == parentHash
        assert not [path for path, v in snapshots.items() if _science.sha(_science.ROOT / path) != v['sha256']]
        checks = dict(status='conditional-formal-and-selected-artifact-pass', sourceSnapshots=len(snapshots), sourceAnchors=len(witnesses), directCallerLinks=6, qntActions=len(actions), qntHistories=11, negativeHistories=4, qntSamples=500, sampleSeed=149, leanTheorems=len(lemmas), allStepInduction=True, projectionNegativeControls=4, leanNegativeControls=1, spanNegativeControls=3, ascentScenarios=12, byteSpans=len(spans), migrationLinks=4, actualCandidate=False, blockers=['PH-source', 'PH-emission', 'PH-platform'], artifactGenerationProvenance=False, fullEmissionCorrespondence=False, c11Refinement=False, nativeTestsRun=False, performanceTestsRun=False, sourceDrift=[])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        own = [_science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', d2, d2[:-3] + '.svg', _science.BASE + 'index.org', 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), _science.BASE + 'models/quint/primitive_header_binding.qnt']
        own += [_science.BASE + 'models/lean/' + n + '.lean' for n in ['PrimitiveHeaderAst', 'PrimitiveHeader', 'PrimitiveBindingAlgebra']]
        own += [_science.context.library_source(n.removesuffix('.py').replace('-', '_')) for n in ['advantage-architecture-study.py', 'default-lease-admission-study.py', 'copy-producer-envelope-study.py', 'chunk-capacity-charge-projection.py']]
        own += [v['path'] for v in snapshots.values()] + [str((_study_workspace('CACHE') / n).relative_to(_science.ROOT)) for n in ['config.json', 'source-snapshots.json']]
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, sourceBindings={f: _science.sha(_science.ROOT / f) for f in own}, sourceSnapshots=snapshots, sysmlInputs=scope, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.context.command('org-check', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        bound = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
        bound['logs'] = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}
        _science.save(_study_workspace('CACHE') / 'input.json', bound)
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        for d in _study_workspace('CACHE').glob('retained-*-failure'):
            shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# A missing close guard must break the actual inductive proof.
# This is the second edge in the supply-then-demand source sequence.
