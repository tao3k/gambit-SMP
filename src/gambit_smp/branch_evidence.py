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
            witnesses=witnesses, bodySha256=hashlib.sha256(body.encode()).hexdigest())
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
