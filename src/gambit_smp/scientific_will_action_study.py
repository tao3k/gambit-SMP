"""Native SysML/ASCENT projection hooks for callback root retirement research."""
from gambit_smp.research_flow import write_text as _study_write_text
import json
import textwrap
from pathlib import Path
from types import SimpleNamespace

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.textwrap = textwrap
        _science.Path = Path
        _science.SimpleNamespace = SimpleNamespace
        _science.engine = _science.context.library('formal_study')
        _science.ROOT = _science.context.root
        _science.stem = 'will-action-admission'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/will_action_parameters.qnt'
        _science.groups = [('cohort', 3, 'key anchor observation limit'), ('point', 8, 'key anchor rootDuty deadMask condition'), ('gate', 7, 'key qualified condition'), ('gain', 4, 'key avoided added condition')]
        _science.sources = ['vendor/gambit/' + v for v in ['lib/_kernel.c', 'lib/_kernel.scm', 'lib/c_intf.c', 'include/gambit.h.in', 'lib/makefile.in', 'lib/header.scm', 'gsc-boot.unix', 'configure.ac', 'gsc/_ptree2.scm']]
        for _science.base in ['../ci-source-patch-check/src/gambit', '../gerbil-gambit-bootstrap-audit/src/gambit']:
            _science.sources += [_science.base + '/' + v for v in ['lib/_kernel.c', 'lib/_kernel.scm', 'lib/makefile', 'lib/header.scm', 'include/gambit.h', 'include/config.h', 'config.log', 'config.status', 'bin/gambuild-C.unix']]
        _science.sources += ['../gerbil-gambit-bootstrap-audit/' + v for v in ['src/std/db/sqlite.ss', 'src/std/db/sqlite-driver.ss', 'src/std/ffi.ss', 'build/lib/std/db/sqlite~0.scm', 'build/lib/std/db/sqlite-driver~0.scm', 'build/lib/std/db/sqlite~0.o1', 'build/lib/std/db/sqlite~0.o1.dSYM/Contents/Resources/DWARF/sqlite~0.o1']]
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, f"// Native WillActionAdmission projection.\nmodule will_action_parameters {{\n  pure val RetainedCiMatch = {str(p['retainedCiMatch']).lower()}\n  pure val ActionMaskAvailable = {str(p['actionMaskAvailable']).lower()}\n  pure val RestrictedAction = {str(p['restrictedAction']).lower()}\n}}\n")
        lines = ['#+TITLE: Real Will Action, Darwin Cohorts and Net-Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: will-action-matrix', ':AUTHORITY: WillActionAdmission', ':END:', '', 'Derived from native SysML. Proposed root-retirement protocol is not current implementation.']
        for name, _, schema in _science.groups:
            fields = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(row[field]) for field in fields)) + ' |' for row in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['# Derived from native SysML; no current action or native issuer admission.', 'direction: down', 'cohorts: "Three distinct retained cohorts" {', ' grid-columns: 3']
        graph += [f' c{n}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['observation'], 36)) for n, v in enumerate(p['cohort'])]
        graph += ['}', 'points: "Real SQLite statement-close action / root duties" {']
        graph += [f' p{n}: ' + json.dumps(v['key'] + '\nmask: ' + v['deadMask']) for n, v in enumerate(p['point'])]
        graph += ['}']
        graph += [f'points.p{n} -> points.p{n + 1}' for n in range(7)]
        graph += ['debug: "Matched arm64 object/dSYM UUID / four source-line labels"', 'gap: "Generated action C, GVM masks and causal object/source binding missing"', 'profile: "Native cleanup + mutation is outside restricted notifier profile"', 'proof: "SysML WA-H/I/S/E -> ASCENT -> QNT / Lean"', 'open: "Seven gates OPEN / modern C mainline"', 'cohorts -> points', 'cohorts -> debug', 'debug -> gap', 'points -> profile', 'gap -> proof', 'profile -> proof', 'proof -> open']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        import re, hashlib

        def observe(name, argv):
            q = _science.context.process(argv, cwd=_science.ROOT, capture_output=True, text=True, timeout=30, name='source-69')
            _science.engine.save(cache / (name + '.command.json'), argv)
            _study_write_text(cache / (name + '.stdout'), q.stdout)
            _study_write_text(cache / (name + '.stderr'), q.stderr)
            assert q.returncode == 0, (name, q.stderr)
            return q.stdout
        cohort = {name: _science.context.output(['git', '-C', path, 'rev-parse', 'HEAD'], cwd=_science.ROOT, text=True, name='source-75').strip() for name, path in [('research', '.'), ('gerbil', '../gerbil-gambit-bootstrap-audit'), ('gambit', 'vendor/gambit')]}
        _science.engine.save(cache / 'source-cohort.json', cohort)
        proj = json.loads((cache / 'projection.json').read_text())['detail']
        vendor = _science.ROOT / 'vendor/gambit'
        ci = _science.ROOT / '../ci-source-patch-check/src/gambit'
        boot = _science.ROOT / '../gerbil-gambit-bootstrap-audit/src/gambit'
        hashes = {path: _science.engine.sha(_science.ROOT / path) for path in _science.sources}
        lineage = {}
        for path in ['lib/_kernel.c', 'lib/_kernel.scm']:
            b = _science.context.output(['git', '-C', str(vendor), 'show', 'HEAD:' + path], cwd=_science.ROOT, name='source-83')
            lineage[path] = dict(headEqualsWorking=b == (vendor / path).read_bytes(), headSha256=hashlib.sha256(b).hexdigest(), lastCommit=observe('lineage-' + Path(path).suffix[1:], ['git', '-C', str(vendor), 'log', '-1', '--format=%H', '--', path]).strip())
            assert lineage[path]['headEqualsWorking']
        same = _science.engine.sha(vendor / 'lib/_kernel.c') == _science.engine.sha(ci / 'lib/_kernel.c')
        assert same == proj['retainedCiMatch']
        assert _science.engine.sha(vendor / 'lib/_kernel.scm') == _science.engine.sha(ci / 'lib/_kernel.scm') == _science.engine.sha(boot / 'lib/_kernel.scm')
        hosts = {}
        names = ['will_2d_execute_21_', 'gc_2d_finalize_21_', 'gc_2d_final_2d_will_2d_registry_21_', 'handle_2d_gc_2d_interrupt_21_', 'execute_2d_jobs_21_']
        for name in names:
            values = []
            for root in [vendor, ci, boot]:
                text = (root / 'lib/_kernel.c').read_text()
                host = '___H__23__23_' + name
                start = text.index('#define ___PH_PROC ' + host + '\n')
                end = text.index('\n#undef ___PH_PROC', start)
                body = text[start:end]
                descs = re.findall('___DEF_LBL_RET\\(' + re.escape(host) + ',([^\\n]+)', text)
                values.append(dict(bodySha256=hashlib.sha256(body.encode()).hexdigest(), descriptors=descs))
            assert values[0] == values[1] == values[2], name
            hosts[name] = values[0]
        profiles = {}
        for name, root in [('ci', ci), ('bootstrap', boot)]:
            header = (root / 'include/gambit.h').read_text()
            cfg = (root / 'include/config.h').read_text()
            mk = (root / 'lib/makefile').read_text()
            assert '#define ___SINGLE_THREADED_VMS' in header
            assert '#define ___MAX_PROCESSORS 1' in header
            assert proj['configuredMaxProcessors'] == 1
            profiles[name] = dict(configureLogSha256=_science.engine.sha(root / 'config.log'), headerSha256=_science.engine.sha(root / 'include/gambit.h'), selectedMakeBindings=[l for l in mk.splitlines() if l.startswith(('C_COMPILER =', 'FLAGS_OPT =', 'FLAGS_OPT_RTS =', 'PRELUDE_OPT ='))], singleHostDefault='#define ___SINGLE_HOST /**/' in cfg, inlineJumpsDefault='#define ___INLINE_JUMPS /**/' in cfg, nativeThreadingDefault='single-threaded', maxProcessorsDefault=1, preludeSmp='|enable-smp|' in mk, effectiveObjectArgv='unresolved')
        assert profiles['ci']['preludeSmp'] and (not profiles['bootstrap']['preludeSmp'])
        assert profiles['ci']['inlineJumpsDefault'] and (not profiles['bootstrap']['inlineJumpsDefault'])
        assert 'dummy gsc-boot script' in (vendor / 'gsc-boot.unix').read_text()
        db = _science.ROOT / '../gerbil-gambit-bootstrap-audit/build/lib/std/db'
        obj = db / 'sqlite~0.o1'
        debug = db / 'sqlite~0.o1.dSYM/Contents/Resources/DWARF/sqlite~0.o1'
        ids = [re.search('UUID: ([0-9A-F-]+) \\(arm64\\)', observe('uuid-' + name, ['/usr/bin/dwarfdump', '--uuid', str(path)]))[1] for name, path in [('object', obj), ('debug', debug)]]
        assert ids[0] == ids[1]
        dwarf = observe('action-dwarf-info', ['/usr/bin/dwarfdump', '--debug-info', str(debug)])
        blocks = dwarf.split('DW_TAG_label')
        labels = []
        for block in blocks[1:]:
            name = re.search('DW_AT_name\\s+\\("([^"]+)"\\)', block)
            if name and re.fullmatch('___L[0-3]_std_2f_db_2f_sqlite_23_____sqlite_2d_statement_2d_close', name[1]):
                labels.append(dict(label=name[1], line=int(re.search('DW_AT_decl_line\\s+\\((\\d+)\\)', block)[1]), nativeAddress=re.search('DW_AT_low_pc\\s+\\((0x[0-9a-f]+)\\)', block)[1], machineDeadMask=None))
        assert len(labels) == 4 and [v['line'] for v in labels] == [537, 543, 543, 547]
        absent = [str(db / name) for name in ['sqlite~0.c', 'sqlite.c'] if not (db / name).exists()]
        assert len(absent) == 2 and (not proj['actionMaskAvailable']) and (not proj['restrictedAction'])
        expanded = (db / 'sqlite~0.scm').read_text()
        start = expanded.index('(define std/db/sqlite#__sqlite-statement-close\n')
        end = expanded.index('(define std/db/sqlite#sqlite-statement-close\n', start)
        body = expanded[start:end]
        assert body.index('sqlite3_finalize') < body.index('foreign-release!') < body.index('##unchecked-structure-set!')
        assert '(make-will _%stmt141239%_ std/db/sqlite#__sqlite-statement-close)' in expanded
        _science.engine.save(cache / 'cohort-correspondence.json', dict(hashes=hashes, lineage=lineage, profiles=profiles, selectedHostEquality=hosts, vendorEqualsCi=same, originalGeneratorReceipt='unresolved', objectToGeneratedC='unresolved', actualAdmitted=False))
        _science.engine.save(cache / 'action-point-audit.json', dict(uuid=ids[0], labels=labels, expandedBody=body, machineMasksQualified=0, semanticAuditPoints=len(proj['point']), generatedCAbsentAt=absent, objectToCurrentExpandedSource='unresolved', effectClosure='unresolved', actualAdmitted=False))
        _science.engine.save(cache / 'source-census.json', dict(bindings=hashes, generation='unresolved', deadMasks='unresolved', selectedAction='std/db/sqlite#__sqlite-statement-close', currentNotifier=False, externalReferences=[dict(url=url, role=role) for url, role in [('https://www.sqlite.org/c3ref/finalize.html', 'disposal despite error status; not selected binary proof'), ('https://www.sqlite.org/c3ref/bind_blob.html', 'data lifetime alternatives; selected helpers use TRANSIENT'), ('https://www.sqlite.org/c3ref/create_function.html', 'callback capability; no selected callback graph proof')]]))
        assert (_science.ROOT / 'models/build/WillActionAdmission.lean').read_text().count('theorem ') == 8

    def facts(_science, p, scenario):
        out = [_science.engine.fact('actionPointFact', [v[k] for k in ['key', 'anchor', 'rootDuty', 'deadMask', 'condition']]) for v in p['point']]
        out += [_science.engine.fact('actionCohortFact', [v[k] for k in ['key', 'anchor', 'observation', 'limit']]) for v in p['cohort']]
        for gate in p['gate']:
            qualified = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and gate['key'] == 'action-dead-masks'))
            out.append(_science.engine.fact('actionGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
        out.append(_science.engine.fact('actionSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        c = results['current']
        assert sorted(c['actionPoint']) == sorted((['current'] + [v[k] for k in ['key', 'anchor', 'rootDuty', 'deadMask', 'condition']] for v in p['point']))
        assert sorted(c['actionCohort']) == sorted((['current'] + [v[k] for k in ['key', 'anchor', 'observation', 'limit']] for v in p['cohort']))
        assert len(c['actionMissing']) == len(p['gate']) and (not c['actionCandidate'])
        assert not results['all-scoped-control']['actionCandidate']
        assert len(results['synthetic-gates']['actionCandidate']) == 1
        assert not results['missing-release']['actionCandidate']

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent='gc-drain-retirement-cut', package='WillActionAdmission', prefix='WA', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/will_action_admission.qnt', lean='models/build/WillActionAdmission.lean', parent_design='dev/architecture/toolchain/gc-drain-retirement-cut-design.org', parent_matrix='dev/architecture/toolchain/gc-drain-retirement-cut-matrix.org', groups=_science.groups, scalars=['retainedCiMatch', 'actionMaskAvailable', 'restrictedAction', 'configuredMaxProcessors', 'actualAdmitted'], histories=31, controls=15, kernels=8, inits=['init', 'initQualified'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='actionPoint actionCohort actionMissing actionBlocked actionCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/will_action_admission.qnt', 'models/build/WillActionAdmission.lean', 'src/gambit_smp/scientific_will_action_study.py', 'src/gambit_smp/scientific_formal_study.py'])
        _science.engine.execute(study, resume=args.resume)
