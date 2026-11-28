"""Design/model orchestration only; native SysML is canonical. No native runtime tests."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import hashlib, json, re, textwrap
from pathlib import Path
from ascent import Engine

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.hashlib = hashlib
        _science.json = json
        _science.re = re
        _science.textwrap = textwrap
        _science.Path = Path
        _science.Engine = Engine
        _science.ROOT = _science.context.root
        _science.STEM = 'marker-audit-quiescence'
        _science.PACKAGE = 'MarkerAuditQuiescence'
        _science.BASE = 'dev/architecture/toolchain/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.DIAGRAM = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.QNT = 'models/build/marker_audit_quiescence.qnt'
        _science.LEAN = 'models/build/MarkerAuditQuiescence.lean'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.GROUPS = [('policy', 1, 'key identity roots executor'), ('writer', 11, 'key kind anchor target admission status'), ('memory', 9, 'key writer publication reader observation lifetime'), ('contract', 8, 'key anchor actionName lemmaName guardName duty status'), ('gain', 4, 'key avoided added condition'), ('gate', 7, 'key qualified duty'), ('profile', 1, 'key driver header compiler declaredMode macroParity sourceMatch status')]
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, v):
        _study_write_text(Path(p), json.dumps(v, indent=2, ensure_ascii=False) + '\n')

    def project(_science):
        keys = []
        for group, count, schema in _science.GROUPS:
            keys += [(group, str(i), f, f'{_science.PACKAGE}::{group}{i}.{f}') for i in range(count) for f in schema.split()]
        for i in range(10):
            keys += [('edge', str(i), f, f'{_science.PACKAGE}::edge{i}.{f}') for f in ['dependent.key', 'prerequisite.key', 'reason']]
        for slot in ['history', 'induction', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PACKAGE}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope', 'owner.componentId']]
        for i in range(4):
            keys += [('dependency', str(i), f, f'{_science.PACKAGE}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId']]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        files = sorted(_science.context.command('model-inputs', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', dict(scope='whole DEV native SysML load', files={f: _science.sha(_science.ROOT / f) for f in files}, excluded={}))
        native = _study_fields(_science.ROOT, None, 'marker-audit-quiescence', field_expressions, ordered=True, models=['dev'])
        vals = native['orderedValues']
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
        lines = ['#+TITLE: Marker Audit Quiescence — Closure and Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: marker-audit-quiescence-matrix', ':AUTHORITY: MarkerAuditQuiescence', ':STATUS: conditional-models-source-open', ':END:', '', 'Derived by native SysML queries. Benefits are conditional work/capacity bounds, not timings.']
        for group, _, schema in _science.GROUPS:
            fields = schema.split()
            lines += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fields)) + ' |' for v in p[group]]
        lines += ['', '** Shared-contract dependencies', '', '| dependent | prerequisite | obligation |', '|---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['dependent.key', 'prerequisite.key', 'reason'])) + ' |' for v in p['edge'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down']
        for v in p['contract']:
            graph.append(json.dumps(v['key']) + ': ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['duty'], 52)))
        for edge in p['edge'].values():
            graph.append(json.dumps(edge['prerequisite.key']) + ' -> ' + json.dumps(edge['dependent.key']))
        graph += ['proof: "SysML -> ASCENT -> QNT / Lean; source + platform OPEN"', '"storage-commit" -> proof']
        for i, v in enumerate(p['gain']):
            graph += [f'gain{i}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['condition'], 55)), f'proof -> gain{i}']
        _study_write_text(_science.ROOT / _science.DIAGRAM, '\n'.join(graph) + '\n')

    def ascend(_science, p, prior):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        deps = [[v['dependent.obligationId'], v['prerequisite.obligationId']] for v in p['dependency'].values()]
        contracts = p['contract']
        queries = ['checked', 'missing', 'route', 'blocked', 'candidate', 'aligned', 'prioraligned', 'componentmapped', 'edgealigned', 'guardaligned', 'profilechecked', 'policyaligned', 'writeraligned']
        engine = Engine()
        results = {}
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert session.run(queries=queries)['complete']
            for case in ['current', 'stale-subject', 'wrong-scope', 'missing-step', 'missing-component', 'missing-prior', 'parent-open', 'missing-guard', 'wrong-guard', 'unmatched-profile', 'missing-policy', 'wrong-policy', 'missing-writer', 'wrong-writer', 'synthetic-all']:
                full = case not in ['current', 'stale-subject', 'wrong-scope']
                receipts = [[case, n, path, h, scope] for n, k, path, h, scope in needs if full or k in ['interleaving', 'induction']]
                if case == 'stale-subject':
                    receipts = [x[:3] + ['stale'] + x[4:] if x[1] == 'MAQ-H' else x for x in receipts]
                if case == 'wrong-scope':
                    receipts = [x[:4] + ['wrong'] if x[1] == 'MAQ-I' else x for x in receipts]
                steps = [[v['actionName'], v['lemmaName']] for v in contracts if not (case == 'missing-step' and v['key'] == 'derived-credit')]
                components = [[v['key'], v['anchor'], v['actionName'], v['lemmaName']] for v in contracts]
                priorrows = [[v['key'], v['path'], v['sha256'], v['invariant'], v['action'], v['lemma']] for v in prior]
                session.replace(dict(scenario=[[case]], need=needs, method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source-audit'], ['environment-refinement', 'platform']], receipt=receipts, dependency=deps, external=[[case, 'RCC-S', str(full and case != 'parent-open').lower()]], gate=[[case, v['key'], str(full).lower()] for v in p['gate']], anchor=[[v['key'], v['anchor']] for v in contracts], binding=[[v['key'], v['actionName'], v['lemmaName'], v['anchor']] for v in contracts], modelstep=steps, component=components, componentbinding=[v for v in components if not (case == 'missing-component' and v[0] == 'storage-commit')], componentedge=[[v['dependent.key'], v['prerequisite.key'], v['reason']] for v in p['edge'].values()], prior=priorrows, priorbinding=[v for v in priorrows if not (case == 'missing-prior' and v[0] == 'old-roster')], writerneed=[[v['key'], v['anchor'], v['kind'], v['target']] for v in p['writer']], writerbinding=[[v['key'], 'wrong-anchor' if case == 'wrong-writer' and v['key'] == 'native-exports' else v['anchor'], v['kind'], v['target']] for v in p['writer'] if not (case == 'missing-writer' and v['key'] == 'scheme-primitives')], policyneed=[[v['key'], v['identity'], v['roots'], v['executor']] for v in p['policy']], policybinding=[] if case == 'missing-policy' else [[v['key'], v['identity'], v['roots'], 'retry-any-executor' if case == 'wrong-policy' else v['executor']] for v in p['policy']], guardneed=[[v['key'], v['actionName'], v['guardName'], v['lemmaName']] for v in contracts], profilewitness=[[case, v['key'], _science.sha(_science.ROOT / v['driver']), _science.sha(_science.ROOT / v['header']), str(full and case != 'unmatched-profile').lower()] for v in p['profile']], guardreceipt=[[v['actionName'], 'wrong' if case == 'wrong-guard' and i == 0 else v['guardName'], v['lemmaName']] for i, v in enumerate(contracts) if not (case == 'missing-guard' and i == 0)]))
                result = session.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            assert len(results['current']['writeraligned']) == 11
            assert len(results['missing-writer']['writeraligned']) == 10 and len(results['wrong-writer']['writeraligned']) == 10
            assert len(results['current']['checked']) == 2
            assert len(results['current']['aligned']) == 8 and len(results['current']['componentmapped']) == 8
            assert len(results['current']['prioraligned']) == 4
            assert len(results['current']['edgealigned']) == 10
            assert len(results['missing-component']['edgealigned']) < 10
            assert len(results['missing-step']['aligned']) == 7
            assert len(results['missing-component']['componentmapped']) == 7
            assert len(results['missing-prior']['prioraligned']) == 3
            for k in ['stale-subject', 'wrong-scope']:
                assert len(results[k]['checked']) == 1
            assert len(results['current']['guardaligned']) == 8
            assert len(results['missing-guard']['guardaligned']) == 7 and len(results['wrong-guard']['guardaligned']) == 7
            assert not results['current']['profilechecked'] and (not results['unmatched-profile']['profilechecked'])
            assert len(results['synthetic-all']['profilechecked']) == 1
            assert not results['missing-policy']['policyaligned'] and (not results['wrong-policy']['policyaligned'])
            assert len(results['current']['policyaligned']) == 1
            assert len(results['synthetic-all']['candidate']) == 1
            assert all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-model-results.json', dict(results=results, repositoryRegistered=False, hostAttested=False, syntheticNotRealReceipt=True))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/release-commit-custody/input.json'
        parenthash = _science.sha(parent)
        bindings = json.loads(parent.read_text())['sourceBindings'].copy()
        drift = [dict(path=path, parentSha256=h, currentSha256=_science.sha(_science.ROOT / path)) for path, h in bindings.items() if _science.sha(_science.ROOT / path) != h]
        _science.save(_study_workspace('CACHE') / 'parent-drift.json', dict(mismatches=drift, parentReceiptPreserved=True, inheritedSourceQualified=False))
        for row in drift:
            bindings[row['path']] = row['currentSha256']
        p = _science.project()
        _science.views(p)
        graph = {v['key']: set() for v in p['contract']}
        for e in p['edge'].values():
            graph[e['dependent.key']].add(e['prerequisite.key'])

        def visit(k, trail):
            assert k not in trail, 'Cyclic contract dependencies'
            for dep in graph[k]:
                visit(dep, trail | {k})
        for k in graph:
            visit(k, set())
        q = (_science.ROOT / _science.QNT).read_text()
        l = (_science.ROOT / _science.LEAN).read_text()
        assert 'sorry' not in l and 'axiom ' not in l
        guardrows = []
        for v in p['contract']:
            pattern = 'action\\s+' + v['actionName'] + '(?:\\([^\\n]*?\\))?=all\\{(.*?)(?=\\n action|\\n run|\\n})'
            body = re.search(pattern, q, re.S)
            assert body and v['guardName'] in body.group(1).split("s'=", 1)[0], v
            assert 'theorem ' + v['lemmaName'] + ' ' in l
            guardrows.append(dict(key=v['key'], action=v['actionName'], guard=v['guardName'], lemma=v['lemmaName'], qualification='syntactic pre-update guard and theorem declaration; implication/source simulation not proved'))
        _science.save(_study_workspace('CACHE') / 'guard-alignment.json', guardrows)
        prior = []
        for key, path, inv, action, lemma in [('old-roster', 'models/build/gate_empty_root_materialization.qnt', 'safe', 'retireRoots', 'retirementNeedsCallerDone'), ('foreign-closure', 'models/build/foreign_cleanup_closure.qnt', 'safe', 'confirmAuditExit', 'unknownKeepsCustody'), ('still-authority', 'models/gambit/still_authority_handoff.qnt', 'safe', 'auditDrop', 'dropPreserves'), ('work-closure', 'models/gambit/gc_work_closure.qnt', 'terminationSafe', 'reclaim', 'joinDoesNotTransferArena')]:
            assert re.search('(?:val|def)\\s+' + inv + '\\s*=', (_science.ROOT / path).read_text())
            prior.append(dict(key=key, path=path, invariant=inv, action=action, lemma=lemma, sha256=_science.sha(_science.ROOT / path), productSimulationProved=False, rerun=False))
        _science.save(_study_workspace('CACHE') / 'prior-model-alignment.json', prior)
        sources = ['vendor/gambit/lib/' + f for f in ['setup.c', '_kernel.scm', '_kernel.c', 'c_intf.c', '_thread.scm']] + ['vendor/gambit/include/gambit.h.in', 'vendor/gambit/configure.ac']
        setup = (_science.ROOT / sources[0]).read_text()
        kernel = (_science.ROOT / sources[1]).read_text()
        cint = (_science.ROOT / sources[3]).read_text()
        header = (_science.ROOT / sources[5]).read_text()
        sources += ['vendor/gambit/gsc/_ptree2.scm', 'vendor/gambit/examples/tcltk/tcltk.scm', 'vendor/gambit/examples/pthread/pthread.c', 'vendor/gambit/examples/pthread/mylib.scm']
        sources += ['vendor/gambit/lib/mem.c', 'vendor/gambit/lib/os_dyn.c', 'vendor/gambit/lib/os_setup.c', 'vendor/gambit/lib/os_tty.c', 'vendor/gambit/lib/os_thread.c', 'vendor/gambit/lib/_io.scm', 'vendor/gambit/lib/os_base.c', 'vendor/gambit/lib/os_base.h']
        mem = (_science.ROOT / 'vendor/gambit/lib/mem.c').read_text()
        assert '___BODY0(obj)[___STILL_REFCOUNT-___STILL_BODY]++;' in mem
        assert 'base[___STILL_REFCOUNT] = 1;' in mem
        assert 'free_still_objs (___ps);' in mem
        assert '___thread_join (t); /* ignore error */' in setup
        assert '(##still-obj-refcount-inc!' in (_science.ROOT / 'vendor/gambit/examples/pthread/mylib.scm').read_text()
        _science.save(_study_workspace('CACHE') / 'audit-source-facts.json', dict(namedCounterFieldWrites=['initialization', 'inc', 'dec'], genericCAndSchemeWriters=True, markerOnlyKillDoesNotCloseAliases=True, processorCleanupBeforeExit=True, shrinkIgnoresJoinError=True, stillCleanupIgnoresRefcount=True, auditRootMustNotAddNativeCredit=True, universalSingleCreditInvariantProved=False))
        tty = (_science.ROOT / 'vendor/gambit/lib/os_tty.c').read_text()
        oss = (_science.ROOT / 'vendor/gambit/lib/os_setup.c').read_text()
        assert '___tty_mod.user_interrupt_handler ();' in tty
        assert '___INTR_USER);' in oss
        drop = mem.split('___EXP_FUNC(void,___still_obj_refcount_dec)', 1)[1].split('/*', 1)[0]
        assert '___BODY0(obj)[___STILL_REFCOUNT-___STILL_BODY]--;' in drop
        assert '___EXP_FUNC(___WORD,___still_obj_refcount)' in mem
        assert '___garbage_collect' not in drop and '___throw_error' not in drop
        _science.save(_study_workspace('CACHE') / 'release-source-facts.json', dict(ordinaryDropBodyHasNoGcOrThrow=True, sourceBodyNotEscapeClosure=True, pendingSigintRoute=True, atomicTokenAuthorityImplemented=False, tokenManagedAllocatorImplemented=False, unknownOutcomeKeeper='stable VM root/session guardian', nativeCancellationAbsenceNotInferred=True))
        dyn = (_science.ROOT / 'vendor/gambit/lib/os_dyn.c').read_text()
        assert 'TODO: c_closure_self needs to be thread local' in dyn
        assert 'return c_closure_self;' in dyn
        assert '___set_data_rc (c_closure, proc);' in dyn
        _science.save(_study_workspace('CACHE') / 'closure-source-facts.json', dict(selfCarrierIsGlobal=True, threadLocalTodoPresent=True, conversionFailureOnUnsupportedDynamicClosure=True, effectiveDarwinDynamicClosureQualified=False, nestedGlobalOverwriteReachability='not claimed; needs effective callback schedule and architecture'))
        assert '___BODY0(obj)[___STILL_REFCOUNT-___STILL_BODY]--;' in mem
        assert 'if (___garbage_collect (___PSP words))' in mem
        assert 'base[___STILL_REFCOUNT] = 1;' in mem
        assert 'mark_array (___PSP &h->data, 1);' in mem
        _science.save(_study_workspace('CACHE') / 'settlement-source-facts.json', dict(markerKillHasNonIdempotentDrop=True, markerAllocMayCollect=True, procRootTodoStillPresent=True, currentRefcountDecrementAtomic=False, vmRootRegistryImplemented=False, cleanupCrashRecoveryQualified=False))
        generator = (_science.ROOT / sources[7]).read_text()
        assert '(if cleanup? "BEGIN_CFUN_BODY_CLEANUP" "BEGIN_CFUN_BODY")' in generator
        assert '#define ___END_CFUN_BODY_CLEANUP ___AT_END ___END_TRY ___R_ALL_INL' in header
        assert setup.index('___err = ___run (___PSP thunk);') < setup.index('sop.op = OP_PROCESSOR_0_THROW_ERROR;')
        assert 'for (;;)' in setup.split('void ___run_and_throw_error_on_processor_0', 1)[1].split('___HIDDEN void start_processor_execution', 1)[0]
        call = setup.split('___EXP_FUNC(___SCMOBJ,___call)', 1)[1].split('___EXP_FUNC(___SCMOBJ,___run)', 1)[0]
        assert 'stack_marker != ___ps->fp[___FRAME_SPACE(2)-2]' in call
        assert '___ps->fp += ___FRAME_SPACE(2);' in call and '___PSR0 = ___ps->fp[-1];' in call
        assert '___ps->catcher = ___old_catcher;' in header and '___ps->longjmp_err' in header
        assert '___VECTORELEM(marker, 0) = ___FAL;' in cint
        assert "TODO: proc_or_false may have been GC'd" in cint
        ret = kernel.split('This is the return to C handler.', 1)[1].split('end-of-code', 1)[0]
        assert ret.index('WRONG_PROCESSOR') < ret.index('MULTIPLE_RETURN') < ret.index('___throw_error')
        assert '#define ___THREAD_RESTORE' in header and '___CONTINUATION_DENV_FIELD(cont)' in header
        profile = json.loads((_study_workspace('CACHE') / 'darwin-declared-profile.json').read_text())
        nativeProfile = p['profile'][0]
        assert nativeProfile['driver'] == profile['driver'] and nativeProfile['header'] == profile['header'] and (not nativeProfile['sourceMatch'])
        assert _science.sha(profile['driver']) == profile['driverSha256'] and _science.sha(profile['header']) == profile['headerSha256']
        installed = Path(profile['driver']).read_text()
        installedHeader = Path(profile['header']).read_text()
        assert 'C_COMPILER="/opt/homebrew/bin/gcc-16"' in installed and '-D___TRUST_C_TCO' in installed
        assert '#define ___SINGLE_THREADED_VMS' in installedHeader and '#define ___VERSION 409008' in installedHeader
        spans = [('r1-local-direct', '#define ___PSR1 ', '#if ___NB_ARG_REGS == 1'), ('host-exit', '#define ___END_COD ', '#define ___CALL_LABEL_HOST'), ('catcher', '#define ___BEGIN_TRY ', '#define ___ON_THROW_AUX'), ('thread-restore', '#define ___THREAD_RESTORE ', '#define ___JUMP_THREAD_RESTORE2'), ('continuation-capture', '#define ___CONTINUATION_CAPTURE ', '#define ___JUMP_CONTINUATION_CAPTURE1'), ('self-transfer', '#define ___JUMPNOTSAFE', '#define ___JUMPGENSAFE'), ('sfun-boundary', '#define ___BEGIN_SFUN_VOID', '#define ___BEGIN_SFUN_ARG'), ('cfun-context', '#define ___BEGIN_CFUN_CTX', '#define ___CFUN_ARG(i)'), ('c-cleanup', '#ifdef ___USE_CPLUSPLUS_CLEANUP', '#ifdef ___USE_SETJMP')]
        parity = []
        for key, start, end in spans:
            x = header[header.index(start):header.index(end, header.index(start))]
            y = installedHeader[installedHeader.index(start):installedHeader.index(end, installedHeader.index(start))]
            assert x == y, key
            parity.append(dict(key=key, equal=True, sourceSha256=hashlib.sha256(x.encode()).hexdigest(), installedSha256=hashlib.sha256(y.encode()).hexdigest(), sourceLines=[header[:header.index(start)].count('\n') + 1, header[:header.index(end, header.index(start))].count('\n') + 1], installedLines=[installedHeader[:installedHeader.index(start)].count('\n') + 1, installedHeader[:installedHeader.index(end, installedHeader.index(start))].count('\n') + 1]))
        _science.save(_study_workspace('CACHE') / 'installed-macro-parity.json', dict(spans=parity, qualification='literal macros only; not selected branch, effective argv, masks or object identity'))
        external = [profile['driver'], profile['header'], '../../gerbil/gambit_runtime.bzl', '../../gerbil/host_system.bzl', '../../gerbil/repository.bzl', '../../patches/gerbil-v19-darwin/0004-gambit-darwin-gcc-macro-expansion.patch']
        externalHashes = {path: _science.sha(_science.ROOT / path) for path in external}
        _science.save(_study_workspace('CACHE') / 'source-facts.json', dict(callTailUsesPstate=True, catchRestoreUsesPstate=True, normalMarkerInvalidation=True, allAbnormalMarkerCleanup=False, wrongProcessorCheckBeforeMarker=True, continuationUsesCurrentContext=True, staticSdkDriverAndHeaderPinned=True, existingCfunCleanup=True, allPathAtEnd=False, secondaryRunStillParticipates=True, effectiveArgvObserved=False, matchedSmpObject=False, c11GraphProved=False))
        raw = _science.context.command('source-census', ['rg', '--json', 'catcher|longjmp_err|kill_sfun_stack_marker|make_sfun_stack_marker|CONTINUATION_CAPTURE|CONTINUATION_GRAFT|THREAD_RESTORE|CALL_LABEL_HOST|END_SFUN|TRUST_C_TCO|SUPPORT_MULTIPLE_C_COMPILERS|CFUN_BODY_CLEANUP|CFUN_ERROR_CLEANUP|type-needs-cleanup|___ON_THROW|tcltk_call|OP_PROCESSOR_0_THROW_ERROR|STILL_REFCOUNT|mark_rc|rc_head|user_intr|tty_signal_handler|pthread_cancel|pthread_setcancel|___POLL|garbage_collect \\(', *sources], policy=_science.process_profile)
        matches = [json.loads(x)['data'] for x in raw.splitlines() if json.loads(x)['type'] == 'match']
        _science.save(_study_workspace('CACHE') / 'source-census.json', dict(matches=matches, scope=sources, qualification='bounded syntactic witnesses; not complete alias/embedding/configuration closure'))
        rcraw = _science.context.command('refcount-census', ['rg', '--json', 'still_obj_refcount|still-obj-refcount|STILL_REFCOUNT|kill_sfun_stack_marker|release_scmobj', 'vendor/gambit/lib', 'vendor/gambit/gsc', 'vendor/gambit/examples', 'vendor/gambit/include/gambit.h.in', '-g', '*.c', '-g', '*.h', '-g', '*.h.in', '-g', '*.scm'], policy=_science.process_profile)
        rcm = [json.loads(x)['data'] for x in rcraw.splitlines() if json.loads(x)['type'] == 'match']
        direct = [v for v in rcm if v['path']['text'] == 'vendor/gambit/lib/mem.c' and re.search('STILL_REFCOUNT.*(?:\\+\\+|--| = )', v['lines']['text'])]
        assert len(direct) == 3
        _science.save(_study_workspace('CACHE') / 'refcount-census.json', dict(matches=rcm, directNamedFieldWrites=direct, scope='bounded named-field/API syntax census; raw native aliases and pointer arithmetic not closed'))
        for row in rcm:
            f = row['path']['text']
            if f not in sources:
                sources.append(f)
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 20 and tests.count('ControlTest passed') == 10
        _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '200', '--max-steps', '120', '--seed', '17', '--verbosity', '1'], policy=_science.process_profile)
        _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
        _science.ascend(p, prior)
        _science.context.command('d2-svg', ['d2', _science.DIAGRAM, _science.DIAGRAM[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.DIAGRAM, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        _science.save(_study_workspace('OUT') / 'checks.json', dict(status='pending-local-checks', runtimeAdmitted=False))
        _science.save(_study_workspace('OUT') / 'input.json', dict(status='pending-receipt-finalization', parentInputSha256=parenthash))
        for name in ['prior-model-alignment.json', 'ascent-model-results.json', 'darwin-declared-profile.json', 'installed-macro-parity.json']:
            _study_write_bytes(_study_workspace('OUT') / name, (_study_workspace('CACHE') / name).read_bytes())
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('iter-compiler-service-design.org', _science.STEM + '-design.org').replace('iter-compiler-service-matrix.org', _science.STEM + '-matrix.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        for path in sources + [_science.MODEL, _science.DESIGN, _science.MATRIX, _science.DIAGRAM, _science.DIAGRAM[:-3] + '.svg', _science.QNT, _science.LEAN, _science.RULES, _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_'))] + [v['path'] for v in prior]:
            bindings[path] = _science.sha(_science.ROOT / path)
        assert all((_science.sha(_science.ROOT / path) == h for path, h in externalHashes.items()))
        bindings.update(externalHashes)
        assert _science.sha(parent) == parenthash
        _science.save(_study_workspace('CACHE') / 'input.json', dict(sourceBindings=bindings, parentInputSha256=parenthash, parentFrozen=True, inheritedSourceQualified=False, parentDrift=drift, head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), dirtySourceIdentity='per-file SHA256', logs={str(p.relative_to(_science.ROOT)): _science.sha(p) for p in _study_workspace('CACHE').iterdir() if p.suffix in {'.stdout', '.stderr'}}))
        checks = dict(status='conditional-local-models-pass', wholeDevSysmlPass=True, sysmlScope='whole DEV native load', qntHistories=20, negativeControls=10, sampledRuns=200, maxSteps=120, leanTheorems=len(re.findall('^theorem ', l, re.M)), ascentCases=15, memoryEdges=9, writerRoutes=11, cleanupPolicyBindings=1, componentBindings=8, guardBindings=8, contractDependencies=10, priorBindings=4, gatesOpen=7, staticDarwinProfile=True, matchedMacroSpans=9, effectiveArgvObserved=False, matchedSmpObject=False, sourceSimulation='open', inheritedSourceQualified=False, parentDriftCount=len(drift), cMemoryOrder='designed-release-acquire-graph; implementation refinement open', hostRegistration='inherited unresolved; not retried', runtimeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        for path in _study_workspace('CACHE').iterdir():
            if path.is_file() and path.suffix in {'.json', '.el'}:
                _study_write_bytes(_study_workspace('OUT') / path.name, path.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(p.relative_to(_science.ROOT)): _science.sha(p) for p in _study_workspace('OUT').iterdir() if p.is_file() and p.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Retain earlier whole-DEV failure; current corrected model is included again.
# Rebind current source observations without rewriting or qualifying historical receipts.
