"""Branch qualification identities and verdicts; execution stays with recipes.

A dirty vendor checkout is not a branch producer. Source bytes come from a
fixed Git archive and observations must bind that revision, its manifest and
the declared profile. Patch-line progress is deliberately not an input.
"""
import hashlib
import io
import json
from pathlib import PurePosixPath
import tarfile


def content_digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True,
                                    separators=(",", ":")).encode()).hexdigest()


def archive_sources(raw):
    """Read immutable Git archive bytes without creating another checkout."""
    sources = {}
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        for entry in archive:
            name = PurePosixPath(entry.name)
            if name.is_absolute() or ".." in name.parts or str(name) in {"", "."}:
                raise ValueError("safe relative Git source path required")
            if entry.isdir():
                continue
            if str(name) in sources:
                raise ValueError("duplicate archive source")
            if entry.isfile():
                data = archive.extractfile(entry).read()
                mode = "100755" if entry.mode & 0o111 else "100644"
            elif entry.issym():
                data, mode = entry.linkname.encode(), "120000"
            else:
                raise ValueError("unsupported Git source kind")
            sources[str(name)] = {"mode": mode, "sha256": hashlib.sha256(data).hexdigest(),
                                  "bytes": len(data), "data": data}
    if not sources:
        raise ValueError("nonempty Git source archive required")
    return sources


def source_manifest(sources):
    return {name: {key: row[key] for key in ("mode", "sha256", "bytes")}
            for name, row in sorted(sources.items())}


def canonical_source(name):
    """Generated checked-in files keep their own producer identity after build."""
    path = PurePosixPath(name)
    return not (name in {"configure", "aclocal.m4"}
                or (path.parent.name in {"lib", "gsi", "gsc"}
                    and path.name.startswith("_") and path.suffix == ".c"))


def unit_inventory(manifest, *, stress=False):
    """Match the upstream runner's unit/stress input classification."""
    return sorted(name for name in manifest
                  if name.startswith("tests/unit-tests/") and name.endswith(".scm")
                  and PurePosixPath(name).name != "#.scm"
                  and name.endswith("_stress.scm") == stress)


def bind_case(plan, case, producer):
    if case not in plan["cases"]:
        raise ValueError("declared branch case required")
    for field in ("revision", "tree", "sourceManifestSha256", "profileSha256"):
        if producer.get(field) != plan.get(field):
            raise ValueError("branch producer mismatch: " + field)
    if producer.get("sourceOverlay") is not False:
        raise ValueError("branch qualification cannot borrow a research overlay")
    if not producer.get("artifacts"):
        raise ValueError("explicit native artifact identity required")
    return {"case": case, "planSha256": content_digest(plan),
            "producerSha256": content_digest(producer),
            "revision": plan["revision"], "definition": plan["cases"][case]}


def terminal_status(process, *, contract_complete):
    """Validate terminal/process evidence, without granting source admission."""
    valid_exit = type(process.get("exit")) is int
    complete = (valid_exit and process.get("exit") == 0 and process.get("timeout") is False
                and process.get("parentReaped") is True
                and process.get("processGroupQuiescent") is True
                and contract_complete is True)
    if complete:
        status = "PASS"
    elif (not valid_exit or type(process.get("timeout")) is not bool
          or process.get("parentReaped") is not True or process.get("processGroupQuiescent") is not True):
        status = "UNRESOLVED"
    else:
        status = "FAIL"
    return status


def case_verdict(binding, process, *, contract_complete):
    """A successful process alone never means complete original coverage."""
    status = terminal_status(process, contract_complete=contract_complete)
    return {"case": binding["case"], "revision": binding["revision"],
            "planSha256": binding["planSha256"],
            "producerSha256": binding["producerSha256"],
            "status": status, "contractComplete": contract_complete,
            "process": process, "runtimeAdmitted": False,
            "inheritedPatchCredit": False, "aggregateProgress": None}


def inspect_preprocessed_macros(source):
    """Classify recorded end-of-TU macros, never object ABI or run authenticity."""
    import re
    if not isinstance(source, bytes):
        raise ValueError('preprocessed macro bytes required')
    expected = {'___WORD_WIDTH': '64', '___WS': '8', '___LWS': '3',
        '___FLONUM_SIZE': '1', '___FLONUM_SELF_TAGGING_TAGS': '0',
        '__GNUC__': '16', '__STDC_VERSION__': '202311L',
        '___ALLOC': '___hp+=(n)', '___ALLOC_ALIGN64': '___ALLOC(n)',
        '___F64BOX': '___MEM_ALLOCATED_FLONUM_ALLOC(x)',
        '___MEM_ALLOCATED_FLONUM_ALLOC':
        '(___ALLOC_ALIGN64(1+___FLONUM_SIZE),___hp[-(1+___FLONUM_SIZE)]='
        '___MAKE_HD_WORDS(___FLONUM_SIZE,___sFLONUM),'
        '*___CAST(___F64*,___hp-___FLONUM_SIZE)=(val),___GET_FLONUM())'}
    # Close the observed branch through tag construction and result creation;
    # a matching outer allocator must not hide a changed inner helper.
    expected.update({'___GET_FLONUM': '___FLONUM_FROM_END(___hp)',
        '___FLONUM_FROM_END': '___FLONUM_FROM(ptr,___FLONUM_SIZE)',
        '___FLONUM_FROM': '___TAG(___CAST(___WORD*,ptr)-(___REFERENCE_TO_BODY+(n)),___tFLONUM)',
        '___tFLONUM': '___tMEM4', '___tMEM4': '7', '___REFERENCE_TO_BODY': '1',
        '___WORD': '___S64', '___S64': '___LONGLONG', '___LONGLONG': 'long long',
        '___CAST': '((type)(val))', '___TAG': '(___CAST(___WORD,ptr)+(tag))',
        '___F64': 'double', '___sFLONUM': '30',
        '___MAKE_HD_WORDS': '___MAKE_HD(((words)<<___LWS),subtype,___MOVABLE0)',
        '___MOVABLE0': '0', '___MAKE_HD': '(((bytes)<<___LF)+((subtype)<<___HTB)+(tag))',
        '___HTB': '3', '___LF': '(___HTB+___SB)', '___SB': '5',
        '__SIZEOF_DOUBLE__': '8', '__SIZEOF_LONG_LONG__': '8', '__CHAR_BIT__': '8'})
    excluded = {'___GAMBIT_DEV_RESTORE_PROBE', '___NAN_BOXING', '___USE_HANDLES', '__clang__'}
    parameters = {'___ALLOC': 'n', '___ALLOC_ALIGN64': 'n', '___F64BOX': 'x',
                  '___MEM_ALLOCATED_FLONUM_ALLOC': 'val', '___GET_FLONUM': '',
                  '___FLONUM_FROM_END': 'ptr', '___FLONUM_FROM': 'ptr,n',
                  '___CAST': 'type,val', '___TAG': 'ptr,tag',
                  '___MAKE_HD_WORDS': 'words,subtype', '___MAKE_HD': 'bytes,subtype,tag'}
    protected = set(expected) | excluded
    # Preserve operator/identifier boundaries; removing whitespace could turn
    # the invalid token pair "+ =" into the admitted operator "+=".
    token = re.compile(r'[A-Za-z0-9_]+|>>=|<<=|->|\+\+|--|<<|>>|<=|>=|==|!=|&&|\|\||\+=|-=|\*=|/=|%=|&=|\|=|\^=|##|[^\s]')
    definitions, signatures, lines = {}, {}, {}
    for line in source.decode('utf-8').splitlines():
        match = re.fullmatch(r'#define ([A-Za-z_]\w*)(?:\(([^)]*)\))?(?:[ \t]+(.*))?', line)
        if not match or match[1] not in protected:
            continue
        name, params, body = match.groups()
        if name in definitions:
            raise ValueError('duplicate protected macro context: ' + name)
        definitions[name] = token.findall(body or '')
        signatures[name] = params
        lines[name] = line
    gaps = sorted(name for name, body in expected.items()
                  if definitions.get(name) != token.findall(body)
                  or signatures.get(name) != parameters.get(name))
    gaps.extend(sorted(name for name in excluded if name in definitions))
    return dict(macroSourceSha256=hashlib.sha256(source).hexdigest(),
        selectedDefinitions=lines, standard64MemoryBoxMatched=not gaps,
        unresolvedMacros=gaps, perBoxWordsUpperBound=2 if not gaps else None,
        observationPoint='end-of-translation-unit', runtimeAdmitted=False,
        effectiveRuntimeAbiQualified=False, dependencyClosureQualified=False,
        boundary='Exact recorded macro graph only; argument effects, per-point stability, physical grant, historical environment equivalence, calling convention and native execution are not proved')


def inspect_directive_macro_points(source, procedure, markers):
    """Replay a restricted GCC -E -fdirectives-only transcript, not C semantics.

    Matching statements must be unique inside the named PH_PROC. Unknown
    directives and macro-stack pragmas are unsupported, never silently ignored.
    """
    import re
    if not isinstance(source, bytes) or not isinstance(procedure, str):
        raise ValueError('directive bytes and procedure required')
    if not markers or len(markers) != len(set(markers)) or any(
            not isinstance(m, str) or '\n' in m or not re.fullmatch(r'___\w+\(.*\)', m)
            for m in markers):
        raise ValueError('unique canonical generated statements required')
    text = source.decode('utf-8')
    if '\\\n' in text or '\\\r\n' in text:
        raise ValueError('unspliced directive transcript unsupported')
    tokens = re.compile(r'/\*|\*/|//|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
    definitions, found = {}, {}
    in_comment = False
    for number, raw in enumerate(text.splitlines(), 1):
        # Preserve strings in macro bodies while excluding directives or marker
        # lookalikes inside comments. GCC has already performed conditional selection.
        visible, start = [], 0
        while start < len(raw):
            if in_comment:
                end = raw.find('*/', start)
                if end < 0:
                    break
                in_comment = False
                start = end + 2
                continue
            token = tokens.search(raw, start)
            if token is None:
                visible.append(raw[start:])
                break
            visible.append(raw[start:token.start()])
            value = token.group()
            if value == '/*':
                visible.append(' ')
                in_comment = True
            elif value == '//':
                break
            else:
                visible.append(value)
            start = token.end()
        line = ''.join(visible).strip()
        if line.startswith('#'):
            define = re.fullmatch(r'#define ([A-Za-z_]\w*)(?:\([^)]*\))?(?:[ \t]+.*)?', line)
            undef = re.fullmatch(r'#undef ([A-Za-z_]\w*)', line)
            if define:
                definitions[define[1]] = line
            elif undef:
                definitions.pop(undef[1], None)
            elif not (re.fullmatch(r'#\s*\d+ "[^"\n]*"(?: \d+)*', line)
                      or re.fullmatch(r'#pragma GCC diagnostic (?:push|pop|ignored "-Wpedantic")', line)):
                raise ValueError('unsupported directive at line ' + str(number))
            continue
        if definitions.get('___PH_PROC') != '#define ___PH_PROC ' + procedure or line not in markers:
            continue
        if line in found:
            raise ValueError('ambiguous generated statement in procedure')
        state = ('\n'.join(definitions.values()) + '\n').encode()
        observed = inspect_preprocessed_macros(state)
        # Retain the exact classified dependency graph, not unrelated SDK macros.
        graph = ('\n'.join(sorted(observed['selectedDefinitions'].values())) + '\n').encode()
        found[line] = dict(transcriptLine=number, definitions=graph.decode(),
                           inspection=inspect_preprocessed_macros(graph))
    if in_comment or set(found) != set(markers):
        raise ValueError('incomplete directive transcript or missing generated statement')
    return dict(transcriptSha256=hashlib.sha256(source).hexdigest(), procedure=procedure,
                observationPoint='before-selected-unexpanded-statements', points=found,
                runtimeAdmitted=False, effectiveRuntimeAbiQualified=False,
                boundary='Restricted directive history and selected macro graph only; no expanded argument effects, physical ownership, complete ABI or native execution proof')


def _boxing_groups(body):
    """Recognize canonical emitted boxing groups; never infer expanded effects."""
    import re
    header = re.compile(
        r'^if\(!___group_demand_enter\(___ps,&___hp,&___fp,(\d+),(\d+),'
        r'___LBL\((\d+)\),&___demand_attempt\)\)\{___ps->temp1=___LBL\(\3\);'
        r'___JUMPEXTPRM\(___NOTHING,___ps->handler_stack_limit\);\}$', re.M)
    store = re.compile(r'___SET_(R\d+|STK)\((?:(-?\d+),)?___F64BOX\((___F64V\d+)\)\)')
    groups, unsupported = [], 0
    for match in header.finditer(body):
        commit = '___group_demand_commit(___ps,___LBL(' + match[3] + '),___demand_attempt);'
        end = body.find(commit, match.end())
        text = body[match.end():end] if end >= 0 else ''
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        stores = [store.fullmatch(line) for line in lines]
        if not lines or not all(stores) or any(
                (item[1] == 'STK') != (item[2] is not None) for item in stores):
            unsupported += 1
            continue
        groups.append(dict(label=int(match[3]), stackWords=int(match[1]),
            heapWords=int(match[2]), boxStores=[dict(location=item[1],
                stackOffset=int(item[2]) if item[2] is not None else None,
                value=item[3]) for item in stores],
            sourceFragment=body[match.start():end+len(commit)],
            bodySha256=hashlib.sha256(text.encode()).hexdigest(),
            capacityAdmitted=False))
    return dict(groups=groups, unsupportedCanonicalHeaders=unsupported,
                boundary='Canonical emitted macro witnesses only; conditional macro allocation, C control flow, effective ABI and physical capacity are not proved')


def inspect_generated_c(source, roots):
    """Scan the direct GSC procedure closure for allocation/poll witnesses.

    This is a witness scan of generated macros, not a C parser, expanded-macro
    proof or runtime admission. Unknown Scheme jumps stay explicit. The source
    digest binds the actual bytes scanned; callers retain producer provenance.
    """
    import re
    if not isinstance(source, bytes) or not roots or len(set(roots)) != len(roots):
        raise ValueError('source bytes and unique explicit procedure roots required')
    text = source.decode('utf-8')
    marks = list(re.finditer(r'^#define ___PH_PROC (\S+)$', text, re.M))
    chunks = {}
    for i, mark in enumerate(marks):
        name = mark[1]
        if name in chunks:
            raise ValueError('duplicate generated procedure identity')
        chunk = text[mark.end():marks[i + 1].start() if i + 1 < len(marks) else len(text)]
        if chunk.count('___BEGIN_P_COD') != 1 or chunk.count('___END_P_COD') != 1:
            raise ValueError('one complete generated body per procedure required')
        start, end = chunk.index('___BEGIN_P_COD'), chunk.index('___END_P_COD')
        if end < start:
            raise ValueError('ordered generated body delimiters required')
        chunks[name] = chunk[start:end]
    todo, procedures = list(roots), {}
    while todo:
        name = todo.pop()
        if name in procedures:
            continue
        if name not in chunks:
            raise ValueError('generated procedure root unavailable: ' + str(name))
        body, children, unknown = chunks[name], set(), []
        for line in re.findall(r'^.*___JUMP.*$', body, re.M):
            if '___JUMPRET(' in line:
                continue
            target = re.search(r',(___L[^(),]+)\)', line)
            child = target[1].replace('___L', '___H', 1) if target else None
            if child in chunks:
                children.add(child)
            else:
                unknown.append(line.strip())
        witnesses = [line.strip() for line in body.splitlines()
                     if re.search(r'CHECK_(HEAP|STACK)|POLL|F64BOX|ALLOC|MAKE_|HEAP_LIMIT', line)]
        procedures[name] = dict(children=sorted(children), unknownSchemeJumps=unknown,
            witnesses=witnesses, bodySha256=hashlib.sha256(body.encode()).hexdigest(),
            boxingGroups=_boxing_groups(body))
        todo.extend(children)
    return dict(status='generated-opcode-witness-scan-completed',
        generatedSourceSha256=hashlib.sha256(source).hexdigest(), roots=list(roots),
        helperCount=len(procedures), procedures=procedures,
        witnessCount=sum(len(p['witnesses']) for p in procedures.values()),
        unknownSchemeJumpCount=sum(len(p['unknownSchemeJumps']) for p in procedures.values()),
        runtimeAdmitted=False,
        boundary='Listed emitted macros and direct Scheme jumps only; expanded C semantics and producer authenticity require separate source review')


def validate_compiler_products(record):
    """Recompute the recorded native ledger; this does not authenticate a run."""
    contract = record['compilerProductContract']
    histories = {h['id']: h for h in record['histories']}
    if len(histories) != len(record['histories']):
        raise ValueError('unique compiler histories required')
    stages = [histories[contract[key]] for key in ('cold', 'continuation')]
    ledgers = []
    for history in stages:
        ledger = history['nativeProducts']; rows = ledger['products']
        parent = next(c['process'] for c in history['commands'] if c['id'].endswith(':gerbil-stdlib'))
        if parent.get('parentReaped') is not True or parent.get('processGroupQuiescent') is not True:
            raise ValueError('native ledger requires quiescent producer custody')
        case = next(c for c in record['cases'] if c['id'] == next(c['id'] for c in history['commands'] if c['id'].endswith(':gerbil-stdlib')))
        if case['process'] != parent:
            raise ValueError('native ledger parent differs from its terminal case')
        if type(ledger['stageComplete']) is not bool or ledger['stageComplete'] != (parent['exit'] == 0 and parent['timeout'] is False):
            raise ValueError('native ledger cannot change producer completion')
        if (len({x['id'] for x in rows}) != len(rows) or
                len({x['source'] for x in rows}) != len(rows) or
                any(x['outcome'] not in ('executed', 'reused') or type(x['reusable']) is not bool for x in rows)):
            raise ValueError('unique typed native tasks required')
        for field, outcome in [('executed', 'executed'), ('reused', 'reused')]:
            if type(ledger[field]) is not int or ledger[field] != sum(x['outcome'] == outcome for x in rows):
                raise ValueError('native count contradicts guarded task inventory')
        if type(ledger['unfinishedRequests']) is not int or ledger['unfinishedRequests'] < 0:
            raise ValueError('nonnegative unfinished native debt required')
        ledgers.append(ledger)
    cold, warm = ledgers; admission = record['warmAdmission']
    eligible = {x['source']: x for x in cold['products'] if x['reusable']}
    if (cold['frontendReuse'] is not False or warm['frontendReuse'] is not False or admission['frontendReuse'] is not False or
            cold['context'] != warm['context'] or warm['context'] != admission['context'] or
            len(admission['admitted']) != len(set(admission['admitted'])) or
            set(admission['admitted']) != {x['id'] for x in eligible.values()} or admission['stale']):
        raise ValueError('continuation lacks the same eligible native cohort')
    comparisons = record['reuseReasons']['rows']; counts = {}; matches = set()
    if len(comparisons) != len(eligible) or {x['source'] for x in comparisons} != set(eligible):
        raise ValueError('every eligible native source needs one comparison')
    for row in comparisons:
        before, after = row['coldRequest'], row['warmRequest']
        if (not isinstance(before, list) or len(before) != 7 or not isinstance(after, list) or len(after) != 7 or
                before[0] != cold['context'] or before[4] != row['source'] or
                before[6] != eligible[row['source']]['output'] or before[:5]+before[6:] != after[:5]+after[6:]):
            raise ValueError('native request comparison has unmatched context/argv/cwd/source')
        reason = 'same-request' if before[5] == after[5] else 'source-changed'
        if row['reason'] != reason:raise ValueError('native miss reason contradicts input identity')
        counts[reason] = counts.get(reason, 0) + 1
        if reason == 'same-request':matches.add(row['source'])
    if counts != record['reuseReasons']['counts'] or matches != {x['source'] for x in warm['products'] if x['outcome'] == 'reused'}:
        raise ValueError('native reuse claim contradicts actual task comparisons')
    return dict(status='recorded-product-ledger-consistency-checked', admitted=len(eligible),
                reused=warm['reused'], executed=warm['executed'], inputChanges=counts.get('source-changed', 0),
                wholeProducerPassed=warm['stageComplete'], runtimeAdmitted=False,
                boundary='Recorded source-guard/journal observations and arithmetic; not independent process authentication or frontend semantic proof')


def validate_module_products(record):
    """Check recorded module custody and actual uses, not macro purity."""
    cases = {c['id']: c for c in record['cases']}
    summaries = []
    for history in record['moduleProductHistories']:
        parent = cases[history['parentCase']]['process']
        native = history['nativeProducts']
        modules = history['moduleProducts']
        if parent.get('parentReaped') is not True or parent.get('processGroupQuiescent') is not True:
            raise ValueError('module ledger requires producer quiescence')
        passed = parent['exit'] == 0 and parent['timeout'] is False
        if native['stageComplete'] is not passed or modules['parentComplete'] is not passed:
            raise ValueError('module ledger cannot change failed parent completion')
        tasks = {x['id']: x for x in native['products']}
        raw = history['moduleCompletions']
        if len({x[3] for x in raw}) != len(raw) or modules['count'] != len(raw):
            raise ValueError('unique completed module programs required')
        for value in raw:
            if len(value) != 9 or value[0] != native['context']:
                raise ValueError('module completion context differs')
            keys = [x[0] for x in value[5]]
            if not keys or len(set(keys)) != len(keys) or any(k not in tasks for k in keys):
                raise ValueError('module references unfinished or duplicate native task')
            emitted = {x[0] for x in value[6]}
            if any(tasks[k]['source'] not in emitted for k in keys):
                raise ValueError('module omitted its owned native input')
        advertised = modules['completed']
        if ({x['moduleId']: x['nativeTasks'] for x in advertised} !=
                {x[3]: len(x[5]) for x in raw} or
                modules['reusable'] != sum(x['reusable'] is True for x in advertised)):
            raise ValueError('module counts contradict completion inventory')
        admitted = {x['moduleId']: x for x in history['admittedPrograms']}
        if len(admitted) != len(history['admittedPrograms']):
            raise ValueError('unique admitted module program required')
        used = modules['usedInterfaces']
        if len({x['moduleId'] for x in used}) != len(used):
            raise ValueError('one module consumption per producer required')
        for use in used:
            prior = admitted.get(use['moduleId'])
            if prior is None or use['nativeTasks'] != len(prior['nativeTasks']):
                raise ValueError('module use lacks admitted native inventory')
            if type(use['rebuilt']) is not bool:
                raise ValueError('typed module rebuild outcome required')
        hits = [x for x in used if not x['rebuilt']]
        if (modules['reusedPrograms'] != len(hits) or
                modules['avoidedNativeTasks'] != sum(x['nativeTasks'] for x in hits)):
            raise ValueError('module reuse claim contradicts actual consumption')
        summaries.append(dict(parentCase=history['parentCase'], parentPassed=passed,
                              completed=len(raw), reused=len(hits),
                              avoidedNativeTasks=modules['avoidedNativeTasks']))
    return dict(histories=summaries, runtimeAdmitted=False,
                boundary='Recorded custody and arithmetic only; source adapter, native execution and arbitrary macro effects remain separate obligations')


def validate_recorded_cases(record):
    """Recheck recorded terminal consistency, not the authenticity of a run.

    Source/artifact provenance remains an explicit recorded scope. This does
    not rerun programs, resolve source copies, or grant branch admission.
    """
    if (record.get('schema') != 'gambit-smp.recorded-cases.v1'
            or record.get('runtimeAdmitted') is not False
            or record.get('branchQualified') is not False):
        raise ValueError('recorded cases cannot self-authorize runtime admission')
    for key, lengths in [('sourceTree', (40, 64)), ('profileSha256', (64,))]:
        value = record.get(key)
        if not isinstance(value, str) or len(value) not in lengths or any(c not in '0123456789abcdef' for c in value):
            raise ValueError('explicit recorded source/profile scope required')
    seen, counts = set(), dict(execution=0, compilation=0, **{'historical-counterexample': 0})
    outcomes = dict(PASS=0, FAIL=0, UNRESOLVED=0)
    cases = record.get('cases')
    if not isinstance(cases, list) or not cases:
        raise ValueError('nonempty recorded case inventory required')
    for case in cases:
        identity, role, markers = case.get('id'), case.get('role'), case.get('markers')
        if (not isinstance(identity, str) or not identity or identity in seen or role not in counts
                or not isinstance(markers, dict) or any(not isinstance(k, str) or not k
                    or type(v) is not bool for k, v in markers.items())):
            raise ValueError('unique typed case identities and assertions required')
        seen.add(identity)
        counts[role] += 1
        process = case.get('process')
        if not isinstance(process, dict) or (process.get('exit') is not None and type(process['exit']) is not int):
            raise ValueError('typed process exit required')
        for key in ('timeout', 'parentReaped', 'processGroupQuiescent'):
            if process.get(key) is not None and type(process[key]) is not bool:
                raise ValueError('typed process flags required')
        complete = role != 'historical-counterexample' and all(markers.values())
        status = terminal_status(case['process'], contract_complete=complete)
        if status != case.get('terminalStatus') or case.get('streamIdentitiesChecked') is not True:
            raise ValueError('case verdict contradicts recorded terminal evidence')
        outcomes[status] += 1
        if role == 'historical-counterexample':
            accepted = case.get('acceptedByScenario')
            if (status == 'PASS' or type(accepted) is not bool
                    or not isinstance(case.get('signature'), str) or not case['signature']
                    or (accepted and (type(case['process'].get('exit')) is not int
                        or case['process']['exit'] == 0 or case['process'].get('timeout') is not False
                        or case['process'].get('parentReaped') is not True
                        or case['process'].get('processGroupQuiescent') is not True))):
                raise ValueError('expected counterexample is not a passing execution')
        elif role == 'execution' and not markers:
            raise ValueError('positive case lacks a terminal/assertion contract')
        elif (role == 'compilation' and status == 'PASS'
                and (not isinstance(case.get('outputSha256'), str)
                     or len(case['outputSha256']) != 64
                     or any(c not in '0123456789abcdef' for c in case['outputSha256']))):
            raise ValueError('successful compilation requires an output identity')
    for key, role in [('positiveExecutions', 'execution'), ('compilations', 'compilation'),
                      ('historicalCounterexamples', 'historical-counterexample')]:
        if type(record.get(key)) is not int or record[key] != counts[role]:
            raise ValueError('case count contradicts its inventory')
    positive_passes = sum(c['role'] != 'historical-counterexample' and c['terminalStatus'] == 'PASS' for c in cases)
    counter_matches = sum(c['role'] == 'historical-counterexample' and c['acceptedByScenario'] for c in cases)
    products = validate_compiler_products(record) if 'compilerProductContract' in record else None
    modules = validate_module_products(record) if 'moduleProductHistories' in record else None
    return dict(status='recorded-terminal-consistency-checked', sourceTree=record['sourceTree'],
                profileSha256=record['profileSha256'], counts=counts, outcomes=outcomes, runtimeAdmitted=False,
                **({'compilerProducts': products} if products is not None else {}),
                **({'moduleProducts': modules} if modules is not None else {}),
                positiveScenarioPasses=positive_passes, expectedCounterexamplesMatched=counter_matches,
                allExpectedOutcomes=(positive_passes + counter_matches == len(cases)),
                boundary='Consistency of recorded terminal/assertion facts; no program replay or general correctness proof')


def progress(plan, producer, observations):
    """Report only this producer; leave semantic gate acceptance explicit."""
    statuses = {}
    for name in plan["cases"]:
        binding = bind_case(plan, name, producer)
        observation = observations.get(name)
        if observation is None:
            statuses[name] = "NOT-RUN"
            continue
        for field in ("revision", "planSha256", "producerSha256"):
            if observation.get(field) != binding[field]:
                raise ValueError("observation cannot transfer across branch producers")
        if observation.get("case") != name:
            raise ValueError("case identity mismatch")
        checked = case_verdict(binding, observation["process"],
                               contract_complete=observation["contractComplete"])
        if observation.get("status") != checked["status"]:
            raise ValueError("case status contradicts its terminal evidence")
        statuses[name] = observation["status"]
    return {"branch": plan["branch"], "revision": plan["revision"],
            "producerSha256": content_digest(producer), "cases": statuses,
            "requirements": {name: "UNESTABLISHED" for name in plan["requirements"]},
            "aggregateProgress": None, "inheritedPatchCredit": False}
