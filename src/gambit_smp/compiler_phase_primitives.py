"""Pure compiler phase commands and observation predicates, no execution."""
from pathlib import Path
import json
import re
from collections import Counter, defaultdict


def numeric_execution_expression(witness):
    """Use the actual generated linker name, including its .o1 suffix."""
    return ('(begin (##eval (quote (define ##failed-test? (quote numeric-not-executed)))) '
            '(##load "_test.o1" (lambda (script path) #f) #t #t "_test.o1" #f) '
            '(if (eq? ##failed-test? #f) (begin (display '+json.dumps(witness+'\n')+') (exit 0)) (exit 2)))')


def assertion_group_manifest(lines, original_kinds=None):
    """Independently check order, coverage, barriers and the 32-form bound."""
    eligible={'test-eqv','test-eq','test-equal','test-assert','test-approximate'}
    rows=[];groups=Counter();closed=set();active=None
    for line in lines:
        fields=line.rstrip('\n').split('\t')
        if len(fields)!=3:raise ValueError('malformed assertion manifest')
        index,kind,group=int(fields[0]),fields[1],int(fields[2])
        if index!=len(rows):raise ValueError('dropped, duplicated or reordered original form')
        if group>0:
            if kind not in eligible:raise ValueError('definition or exception barrier outlined')
            if group!=active:
                if group in closed or group!=len(groups)+1:raise ValueError('noncontiguous assertion group')
                if active is not None:closed.add(active)
                active=group
            groups[group]+=1
            if groups[group]>32:raise ValueError('oversized assertion group')
        elif group==-1:
            if kind in eligible:raise ValueError('eligible assertion missing from groups')
            if active is not None:closed.add(active)
            active=None
        else:raise ValueError('invalid assertion group')
        rows.append(dict(index=index,kind=kind,group=group))
    if not rows:raise ValueError('empty original form manifest')
    if original_kinds is not None and [r['kind'] for r in rows]!=list(original_kinds):
        raise ValueError('manifest differs from independent original reader')
    return dict(forms=len(rows),groups=len(groups),maxGroup=max(groups.values(),default=0),
                kinds=dict(Counter(r['kind'] for r in rows)),rows=rows)


def generated_host_census(lines):
    """Count generator constructs within actual per-procedure C bodies."""
    functions=[]; name=None; row=None
    for number,line in enumerate(lines,1):
        if line.startswith('#define ___PH_PROC '):name=line.split()[2]
        elif line.strip()=='___BEGIN_P_COD':
            if row is not None:raise ValueError('nested generated procedure')
            row=dict(function=name,startLine=number,lines=0,macros=Counter(),globalCalls=Counter())
        elif line.strip()=='___END_P_COD':
            if row is None:raise ValueError('unmatched generated procedure end')
            row.update(endLine=number,macros=dict(row['macros']),globalCalls=dict(row['globalCalls']))
            functions.append(row);row=None
        elif row is not None:
            row['lines']+=1
            row['macros'].update(re.findall(r'\b(___[A-Z][A-Z0-9_]*)\(',line))
            if '___JUMPGLOSAFE(' in line:
                row['globalCalls'].update(re.findall(r',(___G_\w+)\)',line))
    if row is not None:raise ValueError('incomplete generated C body')
    return dict(functions=functions,scope='generated constructs, not GCC blocks or runtime call counts')


def owned_cc1(parent, child):
    """Only a direct cc1 child in this exact owned compiler group qualifies."""
    return bool(parent and child and child.get('ppid')==parent['pid'] and
        child.get('pgid')==parent['pgid']==parent['pid'] and child.get('uid')==parent['uid'] and
        child.get('name')=='cc1')


def numeric_generation_runtime_options(producer):
    """Keep test-console I/O unchanged while buffering the generated C file."""
    return ('-:debug-settings=-,io-settings=lu,' +
            ','.join('~~'+name+'='+str(Path(producer)/name) for name in ('lib','bin','include')) +
            ',file-settings=lf')


def cfg_representation_census(lines):
    """Observed CFG rows even if SSA never completed; no completion inference."""
    functions=[]; row=None
    for line in lines:
        if line.startswith(';; Function '):
            row=dict(function=line.split()[2],bodyBlocksObserved=0,edgesObserved=0,maxFanoutObserved=0)
            functions.append(row)
        elif row is not None:
            if re.match(r'^\s*<bb \d+\b',line):row['bodyBlocksObserved']+=1
            if match:=re.match(r'^;; \d+ succs \{([^}]*)\}',line):
                n=len(match[1].split());row['edgesObserved']+=n
                row['maxFanoutObserved']=max(row['maxFanoutObserved'],n)
    return dict(functions=functions,scope='observed CFG rows only; not translation-unit or SSA completion')


def alias_detail_census(lines):
    """Read actual GCC constraint/solution sections, retaining incomplete scope.

    Equivalence IDs, named points-to targets and repeated memberships are three
    different units. EOF, compile success and an empty section are not proof of
    a completed solution: the function's alias-information marker must follow.
    """
    rows = []
    row = None
    mode = None
    pointers = set(); locations = set(); targets = set()
    members = re.compile(r'^(\S+) = \{(.*?)\}(?: same as \S+)?$')
    equivalent = re.compile(r'^Equivalence classes for (?:in)?direct node id (\d+) ".*": pointer (\d+), location (\d+)$')

    def finish():
        if row is not None:
            row.update(pointerEquivalenceClassesObserved=len(pointers),
                       locationEquivalenceClassesObserved=len(locations),
                       pointsToNamedTargetsObserved=len(targets))
            rows.append(row.copy())

    for number, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith(';; Function '):
            finish()
            row = dict(function=stripped.split()[2], constraintsObserved=0,
                constraintsClosed=False, equivalenceNodesObserved=0,
                maxEquivalenceNodeIdObserved=0, pointsToSectionSeen=False,
                solutionClosed=False, pointsToRowsObserved=0,
                pointsToMembershipsObserved=0, maxPointsToSetObserved=0,
                malformedSolutionLines=0, partialLineObserved=False)
            pointers = set(); locations = set(); targets = set(); mode = None
        elif row is not None:
            if not line.endswith('\n'):
                row['partialLineObserved'] = True
            if stripped == 'Constraints:':
                mode = 'constraints'
            elif stripped == 'Collapsing static cycles and doing variable substitution':
                row['constraintsClosed'] = mode == 'constraints'
                mode = 'equivalence'
            elif match := equivalent.match(stripped):
                row['equivalenceNodesObserved'] += 1
                row['maxEquivalenceNodeIdObserved'] = max(row['maxEquivalenceNodeIdObserved'], int(match[1]))
                if int(match[2]): pointers.add(int(match[2]))
                if int(match[3]): locations.add(int(match[3]))
            elif stripped == 'Points-to sets':
                row['pointsToSectionSeen'] = True
                mode = 'solution'
            elif stripped == 'Alias information for '+row['function']:
                row['solutionClosed'] = mode == 'solution' and not row['malformedSolutionLines'] and not row['partialLineObserved']
                mode = None
            elif mode == 'constraints' and ' = ' in stripped:
                row['constraintsObserved'] += 1
            elif mode == 'solution' and stripped:
                match = members.fullmatch(stripped)
                if match is None or not line.endswith('\n'):
                    row['malformedSolutionLines'] += 1
                else:
                    values = match[2].split()
                    if len(values) != len(set(values)):
                        row['malformedSolutionLines'] += 1
                    row['pointsToRowsObserved'] += 1
                    row['pointsToMembershipsObserved'] += len(values)
                    row['maxPointsToSetObserved'] = max(row['maxPointsToSetObserved'], len(values))
                    targets.update(values)
    finish()
    return dict(schema='gcc-alias-details-census.v1', functions=rows,
        allSolutionsClosed=bool(rows) and all(r['solutionClosed'] for r in rows),
        units='function-local named dump targets; not runtime addresses or bitmap allocation size')


def retained_ir_representation(cfg_lines, ssa_lines):
    """Census retained GCC IR, not a points-to graph or compiler cost estimate.

    Count PHI operand occurrences separately from distinct incoming edges. GCC's
    abnormal-edge annotation `(ab)` belongs to the SSA name, not its predecessor.
    Reject unparsed PHIs rather than silently reporting a small graph.
    """
    functions = {}
    function = re.compile(r'^;; Function (\S+)')
    block = re.compile(r'^\s*<bb (\d+)\b')
    successors = re.compile(r'^;; (\d+) succs \{([^}]*)\}')
    phi = re.compile(r'^\s*# (\S+) = PHI <(.*)>\s*$')
    predecessor = re.compile(r'\((\d+)\)(?:,\s*|$)')
    name = None
    for line in cfg_lines:
        if match := function.match(line):
            name = match[1]
            if name in functions:
                raise ValueError('duplicate CFG function')
            functions[name] = dict(blocks=set(), edges=set(), phis=[], indirect=0, comments=0)
        elif name is not None:
            row = functions[name]
            if match := block.match(line):
                row['blocks'].add(int(match[1]))
            if match := successors.match(line):
                source = int(match[1])
                row['edges'].update((source, int(n)) for n in match[2].split())
    name = None
    current_block = None
    seen = set()
    for line in ssa_lines:
        if match := function.match(line):
            name = match[1]
            if name not in functions or name in seen:
                raise ValueError('CFG/SSA function identity mismatch')
            seen.add(name)
            current_block = None
        elif name is not None:
            row = functions[name]
            if match := block.match(line):
                current_block = int(match[1])
            if ' = PHI <' in line:
                match = phi.match(line)
                if match is None or current_block is None:
                    raise ValueError('malformed or unlocated PHI')
                operands = match[2]
                parts = list(predecessor.finditer(operands))
                if not parts or parts[-1].end() != len(operands):
                    raise ValueError('unparsed PHI operands')
                # Each nonempty operand must end in exactly one predecessor.
                start = 0
                for part in parts:
                    value = operands[start:part.start()]
                    if not value.strip() or ',' in value:
                        raise ValueError('ambiguous PHI operand')
                    start = part.end()
                preds = [int(part[1]) for part in parts]
                if len(preds) != len(set(preds)):
                    raise ValueError('duplicate PHI predecessor')
                base = re.sub(r'_\d+(?:\(ab\))?$', '', match[1])
                base = re.sub(r'\.\d+$', '', base)
                row['phis'].append((current_block, base, preds))
            stripped = line.strip()
            if stripped.startswith('//') and 'goto' in stripped:
                row['comments'] += 1
            elif re.match(r'goto (?!<bb )[^;]+;', stripped):
                row['indirect'] += 1
    if seen != set(functions) or not seen:
        raise ValueError('incomplete CFG/SSA function coverage')
    result = []
    for name, row in functions.items():
        classes = Counter()
        joins = defaultdict(lambda: dict(phis=0, operands=0, predecessors=set(), supports=set(), classes=Counter()))
        supported = set()
        missing = set()
        for target, base, preds in row['phis']:
            classes[base] += len(preds)
            join = joins[target]
            join['phis'] += 1
            join['operands'] += len(preds)
            join['predecessors'].update(preds)
            join['supports'].add(frozenset(preds))
            join['classes'][base] += len(preds)
            for source in preds:
                edge = (source, target)
                supported.add(edge)
                if edge not in row['edges']:
                    missing.add(edge)
        outdegree = Counter(source for source, _ in row['edges'])
        result.append(dict(function=name, blocks=len(row['blocks']), edges=len(row['edges']),
            maxFanout=max(outdegree.values(), default=0),
            phiCount=len(row['phis']), phiOperands=sum(classes.values()),
            maxPhiArity=max((len(preds) for _, _, preds in row['phis']), default=0),
            phiIncomingEdges=len(supported), phiEdgesAbsentFromEarlierCfg=len(missing),
            operandClasses=dict(classes.most_common()),
            indirectGotos=row['indirect'], gotoComments=row['comments'],
            topJoins=[dict(block=target, phis=j['phis'], operands=j['operands'],
                incomingEdges=len(j['predecessors']), sharedPredecessorSet=len(j['supports']) == 1,
                operandClasses=dict(j['classes'].most_common()))
                for target, j in sorted(joins.items(), key=lambda pair: pair[1]['operands'], reverse=True)[:10]]))
    return dict(schema='retained-ir-representation.v1', functions=result,
        pointsToGraphExtracted=False, compilerTimeEstimated=False)

EXECUTION_WITNESS = "COMPILER-PHASE:module-initialized,assertions-passed"


def alias_passes_exercised(exit_code, warning, texts, function='numeric_alias_probe'):
    """Each requested pass needs its own real function and constraint section."""
    return exit_code == 0 and not warning and all(
        any((';; Function '+function+' ') in text and 'Constraints:' in text for text in texts.get(phase, []))
        for phase in ('alias', 'ealias'))
LOAD_PROBE = '''(begin
  (##eval '(define ##failed-test? 'phase-module-not-executed))
  (##load "probe.o1" (lambda (script path) #f) #t #t "probe" #f)
  (if (eq? ##failed-test? #f)
      (begin (display "COMPILER-PHASE:module-initialized,assertions-passed\\n") (exit 0))
      (exit 2)))'''


def stage_accepted(code, timed_out, output, artifact, witness=None):
    return (code == 0 and not timed_out and "FAILED" not in output
            and "Unknown or improperly placed" not in output
            and (artifact is None or artifact.is_file())
            and (witness is None or output.splitlines().count(witness) == 1))


def phase_commands(selection, work):
    return [
        ("scheme-to-c", "gsc/gsc", ["-f", "-verbose", "-c", "-o", "probe.c", str(Path("unit-tests") / selection)], work / "probe.c"),
        ("c-to-dynamic-module", "gsc/gsc", ["-f", "-e", '(exit (if (compile-file "probe.c" options: (quote (verbose)) output: "probe.o1") 0 1))'], work / "probe.o1"),
        ("compiled-execution", "gsi/gsi", ["-f", "-e", LOAD_PROBE], None),
    ]



NUMERIC_GROUP_DRIVER = "models/gambit/native/numeric-alias/outline-assertions.scm"
NUMERIC_FIXTURE_SHA = "b757a18805a38f48e55055907a983d53f0e50d1acb627c462fe6d34924bd0d9d"


def validate_numeric_grouping(config, inputs, enabled):
    if (not enabled or not isinstance(config, dict)
            or set(config) != {"source", "sha256", "fixtureSha256"}
            or config["source"] != NUMERIC_GROUP_DRIVER or config["source"] not in inputs
            or not isinstance(config["sha256"], str)
            or not re.fullmatch(r"[0-9a-f]{64}", config["sha256"])
            or config["fixtureSha256"] != NUMERIC_FIXTURE_SHA):
        raise ValueError("exact declared original numeric grouping source required")


def bind_numeric_grouping(ctx, work, config):
    from gambit_smp.recipes import source_path
    from gambit_smp.framework import digest
    driver = source_path(ctx.root, config["source"])
    fixture = work / "unit-tests/03-number/_num.scm"
    if digest(driver) != config["sha256"] or digest(fixture) != config["fixtureSha256"]:
        raise ValueError("numeric grouping source or original fixture drift")
    originals = [fixture, work / "unit-tests/03-number/#.scm", work / "unit-tests/#.scm"]
    if any(b"smp-numeric-35f9489c4e709579-group-" in path.read_bytes() for path in originals):
        raise ValueError("private numeric group name collides with original input")
    ctx.bind([driver, *originals])
    return driver


def numeric_group_observation(work):
    path = work / "unit-tests/03-number/_num.c.forms.tsv"
    with path.open() as stream:
        value = assertion_group_manifest(stream)
    if (value["forms"], value["groups"], value["maxGroup"]) != (1592, 79, 32):
        raise ValueError("original numeric grouping partition changed")
    from gambit_smp.framework import digest
    return dict(forms=value["forms"], groups=value["groups"], maxGroup=value["maxGroup"],
                manifestSha256=digest(path), claim="ordered-original-forms-not-general-contextual-equivalence")


def suite_phase_commands(selection, work, grouping=None):
    """Preserve run-unit-tests.scm's module/linker names and original loader."""
    selected = Path(selection)
    if selected.is_absolute() or ".." in selected.parts or selected.suffix != ".scm":
        raise ValueError("one relative Scheme fixture required")
    source = Path("unit-tests") / selected
    target = source.with_suffix(".c")
    emit = ('(exit (if (compile-file-to-target ' + json.dumps(str(source)) +
            ' options: (quote ((module-ref _test) (linker-name "_test.o1"))) '
            'output: ' + json.dumps(str(target)) + ') 0 1))')
    if grouping is not None:
        if str(selected) != "03-number/_num.scm":
            raise ValueError("grouping is only validated for the original numeric fixture")
        emit = ('(begin (setenv "GAMBIT_NUMERIC_GENERATED_C" ' + json.dumps(str(work / target)) +
                ') (load ' + json.dumps(str(grouping)) + '))')
    compile_c = ('(exit (if (compile-file ' + json.dumps(str(target)) +
                 ' options: (quote (verbose)) output: "_test.o1") 0 1))')
    plan = [
        ("scheme-to-c", "gsc/gsc", ["-:debug-settings=-,io-settings=lu", "-f", "-e", emit], work / target),
        ("c-to-dynamic-module", "gsc/gsc", ["-:debug-settings=-,io-settings=lu", "-f", "-e", compile_c], work / "_test.o1"),
        ("compiled-execution", "gsi/gsi", ["-:debug-settings=-,io-settings=lu", "-f", "_test.o1"], None),
    ]

    if grouping is not None:
        plan[0][2][0] += ",file-settings=lf"
    return plan


def run_suite_phases(ctx, runtime, work, selection, prefix, idle_window, grouping=None):
    """Record real phase exits; never synthesize an upstream suite PASS marker."""
    driver = bind_numeric_grouping(ctx, work, grouping) if grouping is not None else None
    plan = suite_phase_commands(selection, work, driver)
    if any(artifact is not None and artifact.exists() for _, _, _, artifact in plan):
        raise ValueError("compiled phase output must not reuse an existing artifact")
    results = []
    for name, executable, options, artifact in plan:
        code, output, timeout, seconds = ctx.run(prefix + "-" + name,
            [runtime / executable, *options], work, idle_window)
        accepted = stage_accepted(code, timeout, output, artifact)
        # A successful subprocess is necessary but cannot stand in for its output.
        if accepted and artifact is not None:
            from gambit_smp.framework import digest
            artifact_sha = digest(artifact)
        else:
            artifact_sha = None
        grouped = numeric_group_observation(work) if accepted and grouping is not None and name == "scheme-to-c" else None
        results.append({**({"sourceGrouping": grouped} if grouped is not None else {}), "phase": name, "exit": code, "timeout": timeout,
                        "seconds": seconds, "accepted": accepted,
                        "artifactSha256": artifact_sha})
        if not accepted:
            break
    return results
