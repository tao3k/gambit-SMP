"""Native SysML/ASCENT projection hooks for incremental compiler architecture research."""
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import json
import textwrap
from types import SimpleNamespace

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.textwrap = textwrap
        _science.SimpleNamespace = SimpleNamespace
        _science.engine = _science.context.library('formal_study')
        _science.ROOT = _science.context.root
        _science.stem = 'incremental-compiler-architecture'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/incremental_compiler_parameters.qnt'
        _science.groups = [('component', 6, 'key anchor responsibility replacement'), ('placement', 4, 'key owner anchor responsibility boundary'), ('stage', 8, 'key role inputs result'), ('node', 8, 'key number dependencySet anchor contract'), ('gate', 7, 'key qualified condition'), ('gain', 6, 'key avoided added condition')]
        _science.sources = ['../gerbil-gambit-bootstrap-audit/src/' + v for v in ['std/make.ss', 'gerbil/compiler/driver.ss', 'gerbil/compiler/base.ss', 'gerbil/compiler/optimize.ss', 'gerbil/compiler/optimize-base.ss', 'gerbil/expander/module.ss', 'gerbil/expander/core.ss', 'gerbil/runtime/loader.ss', 'std/iter/macros.ss', 'std/string/misc.ss', 'std/sync/wg.ss']]
        _science.sources += ['vendor/gambit/' + v for v in ['include/gambit.h.in', 'lib/setup.c', 'lib/mem.c', 'gsc/_t-c-3.scm', 'gsc/_front.scm', 'gsc/_t-c-1.scm']]
        _science.sources += ['../gerbil-gambit-bootstrap-audit/build/' + v for v in ['lib/std/db/sqlite~0.o1', 'lib/std/db/sqlite~0.o1.dSYM/Contents/Resources/DWARF/sqlite~0.o1', 'include/gambit.h']]
        _science.sources += ['/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/mach-o/fixup-chains.h', '../../patches/gerbil-v19-darwin/receipts/d884-patched-staging-bootstrap-coverage.md', '../../patches/gerbil-v19-darwin/receipts/d881-gvm-live-block-budget-source-probe.md', 'vendor/ocaml/typing/persistent_env.ml']
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, f"// Native IncrementalCompilerArchitecture projection.\nmodule incremental_compiler_parameters {{\n  pure val NodeCount = {p['nodeCount']}\n  pure val Capacity = {p['capacity']}\n" + '  pure val Parents = Map(' + ', '.join((str(v['number']) + ' -> ' + v['dependencySet'] for v in p['node'])) + ')\n}\n')
        lines = ['#+TITLE: Incremental Compiler Architecture, Retirement and Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: incremental-compiler-matrix', ':AUTHORITY: IncrementalCompilerArchitecture', ':END:', '', 'Derived from native SysML. Proposed compiler-service architecture is not current implementation.']
        for name, _, schema in _science.groups:
            fields = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(row[field]) for field in fields)) + ' |' for row in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['# Native SysML owns responsibilities/stages/graph; arrows denote logical contracts, not implementation.', 'direction: down', 'components: "Replacement architecture / modern C + Scheme" {', ' grid-columns: 2']
        graph += [f' c{n}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['responsibility'], 45)) for n, v in enumerate(p['component'])]
        graph += ['}', 'placement: "Gambit foundation / Gerbil service" {', ' grid-columns: 2']
        graph += [f' p{n}: ' + json.dumps(v['owner'] + '\n' + textwrap.fill(v['responsibility'], 45)) for n, v in enumerate(p['placement'])]
        graph += ['}', 'stages: "Typed results / live session instances are separately owned" {', ' grid-columns: 2']
        graph += [f' s{n}: ' + json.dumps(v['key']) for n, v in enumerate(p['stage'])]
        graph += ['}', 'dag: "Bounded formal graph / not the full production graph" {']
        graph += [f" n{v['number']}: " + json.dumps(v['key']) for v in p['node']]
        graph += ['}']
        import re
        for v in p['node']:
            for dep in re.findall('\\d+', v['dependencySet']):
                graph.append(f"dag.n{dep} -> dag.n{v['number']}")
        graph += ['dag.n7 -> dag.n2: "dynamic / suspended demand" {style.stroke-dash: 4}', 'proof: "SysML IC-H/I/S/E -> ASCENT -> QNT / Lean"', 'benefit: "Separate work W, span S, overhead H and retained memory M"', 'gate: "Seven source/platform gates OPEN; no measured speedup"', 'components -> placement', 'placement -> stages', 'stages -> dag', 'dag -> proof', 'proof -> benefit', 'benefit -> gate']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        cohort = {name: _science.context.output(['git', '-C', path, 'rev-parse', 'HEAD'], cwd=_science.ROOT, text=True, name='source-73').strip() for name, path in [('research', '.'), ('gerbil', '../gerbil-gambit-bootstrap-audit'), ('gambit', 'vendor/gambit')]}
        _science.engine.save(cache / 'source-cohort.json', cohort)
        tests = [(_science.sources[0], '(getenv "GERBIL_BUILD_CORES" "0")'), (_science.sources[0], '(def import-mx (make-mutex'), (_science.sources[0], '(completion-wait! completion)'), (_science.sources[0], ';; TODO: split that'), (_science.sources[1], '(with-driver-mutex (optimize! ctx))'), (_science.sources[1], '(with-driver-mutex (import-module srcpath))'), (_science.sources[1], '(compile-runtime-code ctx)'), (_science.sources[1], '(inexact->exact (floor (time->seconds (current-time))))'), (_science.sources[2], '(make-symbol "__" sym "__" (current-compile-timestamp))'), (_science.sources[1], '(compile-meta-code ctx)'), ('vendor/gambit/gsc/_front.scm', '(parsed-program (normalize-program lst))'), ('vendor/gambit/gsc/_front.scm', '(define (compile-frontend'), ('vendor/gambit/gsc/_front.scm', '(virtual.begin!)'), ('vendor/gambit/gsc/_front.scm', '(compile-parsed-program (car (last-pair supply-modules))'), ('vendor/gambit/lib/setup.c', 'hlbl_ptr++; /* skip INTRO label */'), ('vendor/gambit/include/gambit.h.in', '#define ___IFD_FS_WIDTH 5'), ('vendor/gambit/include/gambit.h.in', '#define ___KIND_WIDTH 2'), ('/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/mach-o/fixup-chains.h', 'DYLD_CHAINED_PTR_64_OFFSET')]
        for path, fragment in tests:
            assert fragment in (_science.ROOT / path).read_text(), (path, fragment)
        module = _science.context.library('inspect_action_descriptors')
        recovered = module.inspect(_science.ROOT, cache)
        assert recovered['returnDescriptorsRecovered'] == 3 and recovered['deadRegisterMasksQualified'] == 0
        assert (_science.ROOT / 'models/build/IncrementalCompilerArchitecture.lean').read_text().count('theorem ') == 8
        _science.engine.save(cache / 'source-census.json', dict(checks=[dict(path=p, fragment=f) for p, f in tests], bindings={p: _science.engine.sha(_science.ROOT / p) for p in _science.sources}, fullCompilerRefinement='open', nativeTests=False, descriptorRecovery='static-read-only', deadRegisters='unresolved', originalActionGeneration='unresolved', primaryReferences=['https://simon.peytonjones.org/assets/pdfs/build-systems-original.pdf', 'https://raw.githubusercontent.com/ocaml/dune/main/src/memo/memo.ml', 'https://raw.githubusercontent.com/ocaml/dune/main/src/dune_engine/build_system.ml', 'https://ocaml.org/manual/5.5/comp.html']))

    def facts(_science, p, scenario):
        out = [_science.engine.fact('compilerComponentFact', [v[k] for k in ['key', 'anchor']]) for v in p['component']]
        out += [_science.engine.fact('compilerPlacementFact', [v[k] for k in ['key', 'owner', 'anchor']]) for v in p['placement']]
        for gate in p['gate']:
            qualified = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and gate['key'] == 'tracked-inputs'))
            out.append(_science.engine.fact('compilerGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
        out.append(_science.engine.fact('compilerSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        c = results['current']
        assert sorted(c['compilerComponent']) == sorted((['current', v['key'], v['anchor']] for v in p['component']))
        assert sorted(c['compilerPlacement']) == sorted((['current', v['key'], v['owner'], v['anchor']] for v in p['placement']))
        assert len(c['compilerMissing']) == 7 and (not c['compilerCandidate'])
        assert not results['all-scoped-control']['compilerCandidate']
        assert len(results['synthetic-gates']['compilerCandidate']) == 1
        assert not results['missing-release']['compilerCandidate']

    def prepare_base(_science):
        """Project native-query addresses for GS-S and its transitive prerequisites.

    Historical receipts stay intact. This is a selection, not a new pass receipt.
    """
        old = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/will-action-admission'
        target = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/compiler-architecture-base'
        target.mkdir(parents=True, exist_ok=True)
        original = json.loads((old / 'input.json').read_text())
        selected = {('build-scheduler', 'GS-S')}
        while True:
            added = {(d['prerequisiteComponent'], d['prerequisite']) for d in original['dependencies'] if (d['component'], d['obligation']) in selected}
            if added <= selected:
                break
            selected |= added
        needs = [n for n in original['needs'] if (n['component'], n['obligationId']) in selected]
        deps = [d for d in original['dependencies'] if (d['component'], d['obligation']) in selected]
        queries = json.loads((old / 'native-queries.json').read_text())
        projection = json.loads((_science.ROOT / '.cache/tasks/will-action-admission/projection.json').read_text())
        need_keys = {k for k, v in projection['needs'].items() if (v['owner']['componentId'], v['obligationId']) in selected}
        dep_keys = {k for k, v in projection['dependencies'].items() if (v['dependent']['owner']['componentId'], v['dependent']['obligationId']) in selected}
        queries = [q for q in queries if q[0].startswith(('components.', 'methods.')) or (q[0].split('.')[0] == 'needs' and q[0].split('.')[1] in need_keys) or (q[0].split('.')[0] == 'dependencies' and q[0].split('.')[1] in dep_keys)]
        _science.engine.save(target / 'native-queries.json', queries)
        _science.engine.save(target / 'input.json', dict(original, needs=needs, dependencies=deps))
        current = json.loads((old / 'current.json').read_text())
        current['brief']['association']['locallyChecked'] = [row for row in current['brief']['association']['locallyChecked'] if (row[1], row[2]) in selected]
        current['projectionOnly'] = True
        _science.engine.save(target / 'current.json', current)
        for name in ['planner-policy.ss', 'check-org.el']:
            _study_write_bytes(target / name, (old / name).read_bytes())
        _science.engine.save(target / 'selection.json', dict(projectionOnly=True, sourceInputSha256=_science.engine.sha(old / 'input.json'), sourceReceiptSha256=_science.engine.sha(old / 'current.json'), selected=sorted(selected), originalNeeds=len(original['needs']), selectedNeeds=len(needs), unselectedRetainedAt=str(old.relative_to(_science.ROOT))))
        return 'compiler-architecture-base'

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent=_science.prepare_base(), package='IncrementalCompilerArchitecture', prefix='IC', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/incremental_compiler_architecture.qnt', lean='models/build/IncrementalCompilerArchitecture.lean', parent_design='dev/architecture/toolchain/will-action-admission-design.org', parent_matrix='dev/architecture/toolchain/will-action-admission-matrix.org', groups=_science.groups, scalars=['nodeCount', 'capacity', 'actualAdmitted'], histories=26, controls=11, kernels=8, inits=['init', 'initOpaque'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='compilerPlacement compilerComponent compilerMissing compilerBlocked compilerCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/incremental_compiler_architecture.qnt', 'models/build/IncrementalCompilerArchitecture.lean', 'src/gambit_smp/scientific_incremental_compiler_study.py', 'src/gambit_smp/scientific_formal_study.py', 'src/gambit_smp/scientific_inspect_action_descriptors.py'])
        _science.engine.execute(study, resume=args.resume)

# Preserved scientific source notes (in original order).
# Native dependencySet strings already drive Quint; numeric edges below are view-only values of that projection.
# Keys are retained exactly; all required values are evaluated by native SysML.
