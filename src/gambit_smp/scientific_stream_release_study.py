"""Native SysML projection hooks for the proposed release-authority study."""
from gambit_smp.research_flow import write_text as _study_write_text
import json
from types import SimpleNamespace

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.SimpleNamespace = SimpleNamespace
        _science.engine = _science.context.library('formal_study')
        _science.ROOT = _science.context.root
        _science.stem = 'stream-release-authority'
        _science.model = f'dev/architecture/toolchain/models/sysml/{_science.stem}.sysml'
        _science.design = f'dev/architecture/toolchain/{_science.stem}-design.org'
        _science.matrix = f'dev/architecture/toolchain/{_science.stem}-matrix.org'
        _science.diagram = f'dev/architecture/toolchain/diagrams/{_science.stem}.d2'
        _science.rules = f'dev/modeling/ascent/{_science.stem}.rules.scm'
        _science.param = 'models/build/stream_release_parameters.qnt'
        _science.groups = [('issuer', 5, 'key anchor existing mayIssue cannotIssue'), ('gate', 6, 'key qualified condition'), ('gain', 4, 'key avoided added condition')]
        _science.sources = ['vendor/gambit/' + path for path in ['lib/mem.c', 'lib/_kernel.scm', 'lib/_thread.scm', 'lib/os_dyn.c', 'examples/tcltk/tcltk.scm', 'lib/_io.scm']]
        _science.sources += ['../gerbil-gambit-bootstrap-audit/src/gerbil/runtime/error.ss']
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.param, f"// Native StreamReleaseAuthority projection.\nmodule stream_release_parameters {{\n  pure val OwnerGeneration = {p['ownerGeneration']}\n}}\n")
        lines = ['#+TITLE: Stream Release Issuers, Closure and Net-Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: stream-release-matrix', ':AUTHORITY: StreamReleaseAuthority', ':END:', '', 'Derived from native SysML; proposed credentials are not existing runtime APIs.']
        for name, _, schema in _science.groups:
            fields = schema.split()
            lines += ['', '** ' + name.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(row[field]) for field in fields)) + ' |' for row in p[name]]
        _study_write_text(_science.ROOT / _science.matrix, '\n'.join(lines) + '\n')
        graph = ['# Native SysML issuer containment and proof obligations; not a runtime schedule.', 'direction: down', 'domain: "Old stream release / modern C baseline"', 'issuers: "Existing mechanisms / proposed authority boundaries" {', '  grid-columns: 2']
        graph += [f' i{n}: ' + json.dumps(v['key'] + '\n' + v['anchor']) for n, v in enumerate(p['issuer'])]
        graph += ['}', 'proof: "RA-H QNT / RA-I Lean; RA-S source / RA-E native"', 'ascent: "ASCENT exact scopes / ancestor SH-S dependencies"', 'gates: "Six source/native qualification gates remain open"', 'domain -> issuers', 'issuers -> proof', 'proof -> ascent', 'ascent -> gates']
        _study_write_text(_science.ROOT / _science.diagram, '\n'.join(graph) + '\n')

    def source_checks(_science, cache):
        cohort = {name: _science.context.output(['git', '-C', path, 'rev-parse', 'HEAD'], cwd=_science.ROOT, text=True, name='source-53').strip() for name, path in [('research', '.'), ('gerbil', '../gerbil-gambit-bootstrap-audit'), ('gambit', 'vendor/gambit')]}
        cohort['selectedGambitStatus'] = _science.context.output(['git', '-C', 'vendor/gambit', 'status', '--porcelain', '--', 'lib/mem.c', 'lib/_kernel.scm', 'lib/_thread.scm', 'lib/os_dyn.c', 'examples/tcltk/tcltk.scm', 'lib/_io.scm'], cwd=_science.ROOT, text=True, name='source-55')
        _science.engine.save(cache / 'source-cohort.json', cohort)
        tests = [(_science.sources[0], '#define ___PSTATE_MEM(var) ___ps->mem.var'), (_science.sources[0], '#define rc_head                 ___PSTATE_MEM(rc_head_)'), (_science.sources[0], 'mark_array (___PSP &h->data, 1);'), (_science.sources[0], '___PROCESSOR_ID(___ps,___vms) == 0'), (_science.sources[0], 'mark_array (___PSP body+2, 1); /* scan action only */'), (_science.sources[1], '(##will-testator-set! will #f)'), (_science.sources[1], '(action testator)'), (_science.sources[3], '___set_data_rc (c_closure, proc);'), (_science.sources[4], '___EXT(___release_rc) (___CAST(void*,client_data));'), (_science.sources[-1], '(unless (&StackTrace-continuation exn)')]
        for path, fragment in tests:
            assert fragment in (_science.ROOT / path).read_text(), (path, fragment)
        _science.engine.save(cache / 'source-census.json', dict(checks=[dict(path=p, fragment=f) for p, f in tests], bindings={p: _science.engine.sha(_science.ROOT / p) for p in _science.sources}, compositeIssuer='absent-in-selected-sources', ownerAliasCoverage='open', nativeRootCoverage='open'))

    def facts(_science, p, scenario):
        out = [_science.engine.fact('releaseIssuerFact', [v[k] for k in ['key', 'anchor', 'existing', 'mayIssue', 'cannotIssue']]) for v in p['issuer']]
        for gate in p['gate']:
            qualified = scenario in {'synthetic-gates', 'missing-release'} and (not (scenario == 'missing-release' and gate['key'] == 'owner-token-coverage'))
            out.append(_science.engine.fact('releaseGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
        out.append(_science.engine.fact('releaseSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-release'}).lower()]))
        return out

    def check_inference(_science, p, results):
        c = results['current']
        assert sorted(c['releaseIssuer']) == sorted((['current'] + [v[k] for k in ['key', 'anchor', 'existing', 'mayIssue', 'cannotIssue']] for v in p['issuer']))
        assert len(c['releaseMissing']) == len(p['gate']) and (not c['releaseCandidate'])
        assert not results['all-scoped-control']['releaseCandidate']
        assert len(results['synthetic-gates']['releaseCandidate']) == 1
        assert not results['missing-release']['releaseCandidate']

    def analyze(_science):
        args = _science.context.options
        study = SimpleNamespace(task=_science.stem, parent='span-storage-handoff', package='StreamReleaseAuthority', prefix='RA', model=_science.model, design=_science.design, matrix=_science.matrix, diagram=_science.diagram, rules=_science.rules, param=_science.param, qnt='models/build/stream_release_authority.qnt', lean='models/build/StreamReleaseAuthority.lean', parent_design='dev/architecture/toolchain/span-storage-handoff-design.org', parent_matrix='dev/architecture/toolchain/span-storage-handoff-matrix.org', groups=_science.groups, scalars=['ownerGeneration', 'actualAdmitted'], histories=25, controls=11, kernels=8, inits=['init'], views=_science.views, source_checks=_science.source_checks, facts=_science.facts, check_inference=_science.check_inference, outputs='releaseIssuer releaseMissing releaseBlocked releaseCandidate', sources=_science.sources, artifacts=[_science.model, _science.design, _science.matrix, _science.diagram, _science.rules, _science.param, 'models/build/stream_release_authority.qnt', 'models/build/StreamReleaseAuthority.lean', 'src/gambit_smp/scientific_stream_release_study.py', 'src/gambit_smp/scientific_formal_study.py'])
        _science.engine.execute(study, resume=args.resume)
