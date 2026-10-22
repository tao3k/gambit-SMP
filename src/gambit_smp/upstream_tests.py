"""Official Make transport; Evidence DSL owns scope/dependency inference."""
import json
import re
import time
import subprocess
from pathlib import Path

from gambit_smp.framework import digest

CONTRACT = "evidence/research/ci/upstream-tests.json"
ENTRY = "evidence/research/ci/test-scope.entry.json"
RULES = "evidence/dsl/upstream-test-scope.ss"
POLICIES = {CONTRACT: "policy/upstream-tests.json", ENTRY: "policy/upstream-test-scope.entry.json",
            RULES: "policy/upstream-test-scope.ss",
            "evidence/research/incremental-builds/qualified-upstream-tests.json": "policy/qualified-upstream-tests.json",
            "evidence/research/incremental-builds/qualified-suite-review-rules.ss": "policy/qualified-suite-review-rules.ss"}


def validate(args, inputs):
    from gambit_smp.recipes import fields
    from gambit_smp.native_capabilities import reference
    fields(args, ("runtime", "identity", "targets", "failures", "reviewRules"),
           ("reviews", "environmentProbe", "additionalFixtures", "fileBudgetSeconds", "scopeContract", "reviewRulesExtension", "targetProcessors"))
    reference(args["runtime"])
    reference(args["identity"])
    if "environmentProbe" in args:
        reference(args["environmentProbe"])
    if "scopeContract" in args and args["scopeContract"] not in POLICIES:
        raise ValueError("sealed source-bound Make scope contract required")
    if "scopeContract" in args and args["scopeContract"] not in inputs:
        raise ValueError("declared scope contract required")
    if 'reviewRulesExtension' in args and (args['reviewRulesExtension'] not in inputs
            or args['reviewRulesExtension'] not in POLICIES or not args['reviewRulesExtension'].endswith('.ss')):
        raise ValueError('declared sealed retry extension required')
    caps = args.get("fileBudgetSeconds", {})
    if not isinstance(caps, dict):raise ValueError("typed per-file budgets required")
    from gambit_smp.recipes import budget
    for name, cap in caps.items():
        if not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts:
            raise ValueError("contained file budget required")
        budget(cap)
    processors = args.get('targetProcessors', {})
    if (not isinstance(processors, dict) or any(not isinstance(name,str)
            or not re.fullmatch(r'[a-z][a-z0-9-]{0,63}',name)
            or type(count) is not int or count < 1 for name,count in processors.items())):
        raise ValueError('typed target processor counts required')
    targets = args["targets"]
    if (not isinstance(targets, list) or not targets or len(targets) != len(set(targets))
            or any(not isinstance(name, str) or not re.fullmatch(r"[a-z][a-z0-9-]{0,63}", name) for name in targets)):
        raise ValueError("unique literal official Make test targets required")
    if (args["failures"] != "evidence/native-failures.json" or args["failures"] not in inputs
            or args["reviewRules"] not in inputs or not args["reviewRules"].endswith(".ss")
            or not {CONTRACT, ENTRY, RULES} <= set(inputs)):
        raise ValueError("canonical failures, sealed policy and scope sources required")
    fixtures = args.get("additionalFixtures", {})
    if not isinstance(fixtures, dict):
        raise ValueError("hash-bound additional fixtures required")
    for name, item in fixtures.items():
        if (not isinstance(name, str) or not name.endswith(".scm")
                or Path(name).is_absolute() or ".." in Path(name).parts
                or not isinstance(item, dict)):
            raise ValueError("contained Scheme fixture name required")
        fields(item, ("source", "sha256"))
        if (item["source"] not in inputs or not item["source"].endswith(".scm")
                or not isinstance(item["sha256"], str)
                or not re.fullmatch(r"[0-9a-f]{64}", item["sha256"])):
            raise ValueError("declared hash-bound Scheme test fixture required")
    if "reviews" in args:
        reviews = args["reviews"]
        if (not isinstance(reviews, dict) or not reviews or not set(reviews) <= {"gsi", "gsc"}
                or any(not (isinstance(path, str) and path in inputs and path.endswith(".json")
                            or isinstance(path, dict) and set(path) == {"step", "output"})
                       for path in reviews.values())):
            raise ValueError("declared per-mode typed review documents required")
        for path in reviews.values():
            if isinstance(path, dict):
                reference(path)


def scope_contract(ctx, runtime, *, declaration=CONTRACT):
    """Validate byte correspondence only; do not interpret Make or infer closure."""
    from gambit_smp.recipes import fields, read_json, source_path
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.framework import relative
    manifest = manifest_paths(Path(ctx.receipt["engine"]["path"]))
    for name in {CONTRACT, ENTRY, RULES, declaration}:
        sealed = POLICIES[name]
        path = source_path(ctx.root, name)
        if digest(path) != manifest["files"].get(sealed):
            raise ValueError("test scope policy differs from the sealed implementation")
        ctx.bind([path])
    if declaration not in POLICIES:raise ValueError("unsealed Make scope contract")
    contract_path = source_path(ctx.root, declaration)
    contract = read_json(contract_path)
    ctx.bind([contract_path])
    fields(contract, ("schema", "template", "makefile", "targets", "unitModes", "scope"), ("inventories",))
    fields(contract["template"], ("path", "sha256"))
    template = relative(runtime, contract["template"]["path"])
    if contract["schema"] != "upstream-make-test-contract.v1" or digest(template) != contract["template"]["sha256"]:
        raise ValueError("official Make source contract drift")
    makefile = relative(runtime, contract["makefile"])
    source_lines, configured_lines = template.read_text().splitlines(), makefile.read_text().splitlines()
    targets = contract["targets"]
    if not isinstance(targets, dict) or not targets:
        raise ValueError("nonempty source-bound target declarations required")
    for name, row in targets.items():
        fields(row, ("executable", "headers", "dependencies", "unitSelections"))
        if not re.fullmatch(r"[a-z][a-z0-9-]{0,63}", name) or type(row["executable"]) is not bool:
            raise ValueError("typed official target declaration required")
        headers_for = lambda lines: [line for line in lines if ":" in line
            and name in line.split(":", 1)[0].split() and not line.startswith((" ", "\t"))]
        headers = headers_for(source_lines)
        if (not headers or row["headers"] != headers
                or headers_for(configured_lines) != headers):
            raise ValueError("complete configured/source target headers required")
        dependencies = list(dict.fromkeys(word for line in headers for word in line.partition(":")[2].split()))
        if row["dependencies"] != dependencies or not set(dependencies) <= targets.keys():
            raise ValueError("literal target prerequisite correspondence differs")
        selections = row["unitSelections"]
        if (not isinstance(selections, list) or len(selections) != len(set(selections))
                or any(not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts for name in selections)):
            raise ValueError("typed unit-suite containment required")
    modes = contract["unitModes"]
    if (not isinstance(modes, dict) or any(
            name not in targets or not targets[name]["unitSelections"]
            or not isinstance(selected, list) or not selected or len(selected) != len(set(selected))
            or not set(selected) <= {"gsi", "gsc"}
            for name, selected in modes.items())):
        raise ValueError("source-bound unit-mode declarations required")
    inventories = contract.get('inventories', {})
    if (not isinstance(inventories, dict) or not set(inventories) <= targets.keys()
            or any(value not in {'unit', 'stress'} for value in inventories.values())):
        raise ValueError('typed unit/stress inventories required')
    ctx.bind([template, makefile])
    return contract, makefile


def infer_scope(ctx, contract, makefile, targets, *, unit_root=None, resolve_files=True, label="upstream-review-scope"):
    """Use the same sealed Make closure for bound review and actual execution."""
    from gambit_smp.suite_primitives import selected_files
    from gambit_smp.evidence_capabilities import evaluate_observations
    declarations = contract["targets"]
    if any(name not in declarations or declarations[name]["executable"] is not True for name in targets):
        raise ValueError("requested official target is not declared executable")
    if any((makefile.parent / name).exists() for name in targets):
        raise ValueError("official non-file test target is shadowed by a filesystem entry")
    projected = {
        "selected_make_target": [[name] for name in targets],
        "make_dependency": [[name, parent] for name, row in declarations.items() for parent in row["dependencies"]],
        "make_unit_selection": [[name, selection] for name, row in declarations.items() for selection in row["unitSelections"]]}
    projected["make_unit_mode"] = [[name, mode] for name, modes in contract["unitModes"].items() for mode in modes]
    inferred = evaluate_observations(ctx, [], projected,
        {"scope": "review_make_scope", "selection": "review_unit_selection",
         "mode": "review_unit_mode", "cycle": "scope_cycle"},
        label, dsl=ENTRY)
    if inferred["cycle"] or not inferred["scope"]:
        raise ValueError("native test scope is cyclic or missing")
    operations = sorted(row[0] for row in inferred["scope"])
    if not set(targets) <= set(operations) or not set(operations) <= declarations.keys():
        raise ValueError("inferred review scope escaped its source contract")
    selections = sorted(row[0] for row in inferred["selection"])
    modes = [mode for mode in ("gsi", "gsc") if [mode] in inferred["mode"]]
    inventories = {contract.get("inventories", {}).get(name, "unit") for name in operations
                   if declarations[name]["unitSelections"]}
    if len(inventories) > 1:raise ValueError("separate unit and stress invocations required")
    files = selected_files(unit_root or makefile.parent / "unit-tests", selections,
                           inventory=next(iter(inventories), "unit")) if selections and resolve_files else []
    return makefile, operations, files, modes, inferred


def preflight_import(ctx, runtime):
    """Check declared Make consumers before compilation; execute no tests here."""
    plan = getattr(ctx, 'planned_steps', ctx.receipt.get('plannedSteps', ()))
    imports = {step['id'] for step in plan if step['capability'] == 'gambit.runtime-import'}
    checked = []
    for step in plan:
        if step['capability'] != 'gambit.upstream-tests' or step['arguments']['runtime']['step'] not in imports:
            continue
        origin = next(row for row in plan if row['id'] == step['arguments']['runtime']['step'])
        if origin['arguments']['source']['step'] != ctx.directory.name and origin['id'] != ctx.directory.name:
            continue
        args = step['arguments']
        contract, makefile = scope_contract(ctx, runtime, declaration=args.get('scopeContract', CONTRACT))
        _, operations, _, modes, _ = infer_scope(ctx, contract, makefile, args['targets'],
            resolve_files=False, label='make-preflight-' + step['id'])
        checked.append(dict(step=step['id'], operations=operations, modes=modes,
                            fixtureInventoryChecked=False, runtimeAdmitted=False))
    return checked


def execute(args, ctx):
    from gambit_smp.native_capabilities import additional_fixtures, clone, compiler
    from gambit_smp.native_review import preflight
    from gambit_smp.recipes import read_json
    from gambit_smp.suite_primitives import check_runtime
    if "engine" not in ctx.receipt:
        raise ValueError("upstream tests require the sealed review lane")
    original = ctx.artifact(args["runtime"], "source-runtime")
    identity_path = ctx.artifact(args["identity"], "runtime-identity")
    identity = read_json(identity_path)
    check_runtime(original, identity)
    compiler(ctx)
    runtime = clone(ctx, args["runtime"], "source-runtime")
    additional_fixtures(args, ctx, runtime / "tests/unit-tests")
    contract, makefile = (scope_contract(ctx, runtime, declaration=args['scopeContract'])
                          if 'scopeContract' in args else scope_contract(ctx, runtime))
    fixture_inputs = {path: digest(path) for path in makefile.parent.rglob("*")
                      if path.is_file() and path.suffix in {".scm", ".c", ".h", ".in"}}
    ctx.bind([identity_path])
    step = next(row for row in ctx.receipt["steps"] if row["id"] == ctx.directory.name)
    observed = {"schema": "upstream-test-observations.v1", "requested": args["targets"],
                "candidateReceiptSha256": digest(identity_path),
                "wholeUpstreamTestBudget": step["budgetSeconds"],
                "wholeRecipeBudget": ctx.receipt["budgetSeconds"],
                "executionStarted": False, "outcome": "PENDING", "reviews": [],
                "runtimeAdmitted": False, "performanceAdmitted": False}
    output = ctx.directory / "upstream-observations.json"
    def retain():
        output.write_text(json.dumps(observed, indent=2) + "\n")
    retain()
    try:
        _, operations, files, modes, inferred = infer_scope(ctx, contract, makefile, args["targets"])
        observed["scopeInference"] = inferred
        retain()
        for mode in modes:
            review = {key: args[key] for key in ("failures", "reviewRules")}
            if mode in args.get("reviews", {}):
                review["retryReview"] = args["reviews"][mode]
            if args.get('fileBudgetSeconds'):review['fileBudgetSeconds'] = args['fileBudgetSeconds']
            if 'reviewRulesExtension' in args:review['reviewRulesExtension'] = args['reviewRulesExtension']
            if 'targetProcessors' in args:review['targetProcessors'] = args['targetProcessors']
            review.update(mode=mode, regime="upstream-make", operation=" ".join(args["targets"]),
                          operations=operations, requestedOperations=args["targets"], unitModes=modes,
                          makefileScope=makefile.relative_to(runtime).as_posix())
            if "environmentProbe" in args:
                review["environmentProbe"] = args["environmentProbe"]
            result = preflight(ctx, review, runtime, identity_path, files, makefile.parent / "unit-tests",
                               label="retry-review-" + mode)
            observed["reviews"].append(result)
            retain()
            if result["decision"] not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}:
                raise ValueError("upstream retry preflight: " + result["decision"])
        processor_plan = validate_target_processors(args,contract,operations)
        if 'environmentProbe' in args:
            environment = read_json(ctx.artifact(args['environmentProbe'],'current-producer-observation'))
            ctx.env['GAMBOPT'] = 'p'+str(environment['processors'])
        make_options = []
        if processor_plan or 'environmentProbe' in args:
            observations = []
            old = ctx.env.get('GAMBOPT')
            try:
                for name,count in [('default',None),*processor_plan.items()]:
                    if count is not None:ctx.env['GAMBOPT'] = 'p'+str(count)
                    elif old is None:ctx.env.pop('GAMBOPT',None)
                    else:ctx.env['GAMBOPT'] = old
                    flags = '-:~~bin='+str(runtime/'bin')+',~~lib='+str(runtime/'lib')+',~~include='+str(runtime/'include')
                    code,text,timeout,_ = ctx.run('upstream-processors-'+name,
                        [runtime/'gsi/gsi',flags,'-e','(write (##current-vm-processor-count))'],
                        makefile.parent,min(10,ctx.remaining()))
                    command = ctx.commands[-1]
                    if (code or timeout or not text.strip().isdigit()
                            or command.get('parentReaped') is not True
                            or command.get('processGroupQuiescent') is not True):
                        raise ValueError('actual Make processor configuration was not observed')
                    actual = int(text.strip())
                    if count is not None and actual != count:raise ValueError('target processor observation differs')
                    if count is None and 'environmentProbe' in args:
                        expected = read_json(ctx.artifact(args['environmentProbe'],'current-producer-observation'))['processors']
                        if actual != expected:raise ValueError('default Make topology differs from its environment observation')
                    observations.append(dict(target=name,processors=actual))
            finally:
                if old is None:ctx.env.pop('GAMBOPT',None)
                else:ctx.env['GAMBOPT'] = old
            overlay_sha = None
            if processor_plan:
                overlay = ctx.directory/'target-processors.mk'
                overlay.write_text(''.join(name+': export GAMBOPT := p'+str(count)+'\n'
                                           for name,count in processor_plan.items()))
                ctx.bind([overlay])
                make_options = ['-f',makefile,'-f',overlay]
                overlay_sha = digest(overlay)
            observed['processorConfiguration'] = dict(targets=processor_plan,observed=observations,
                                                      makeOverlaySha256=overlay_sha)
            retain()
        # One official invocation retains Make's prerequisite de-duplication.
        observed.update(executionRequested=True, executionStarted=None)
        retain()
        guard = file_budget_guard(args, ctx, runtime, files)
        if guard:
            observed['fileBudgetPlan'] = guard.observations()
            retain()
        try:
            code, _, timeout, seconds = ctx.run("upstream-tests",
                [ctx.tools["make"], *make_options, *(['-j1'] if guard else []), *args["targets"]],
                makefile.parent, ctx.remaining(), **({'boundary': guard} if guard else {}))
        finally:
            if guard:
                observed['fileBudgetObservations'] = guard.observations()
                retain()
        if guard and code == 0 and not timeout:guard.complete()
        command = ctx.commands[-1]
        observed.update(executionStarted=True, exit=code, timeout=timeout, seconds=seconds,
                        parentReaped=command.get("parentReaped"),
                        processGroupQuiescent=command.get("processGroupQuiescent"))
        if (code != 0 or timeout or observed["parentReaped"] is not True
                or observed["processGroupQuiescent"] is not True):
            raise ValueError("official upstream test exit/timeout/teardown not admitted")
        if any(digest(path) != sha for path, sha in fixture_inputs.items()):
            raise ValueError("official test fixture changed")
        check_runtime(original, identity)
        observed["outcome"] = "PASS"
    except BaseException as error:
        observed.update(outcome="DENY", reason=str(error))
        retain()
        raise
    retain()
    # Tests create real builder outputs. Publish a new observed workspace view
    # for the next consumer instead of rewriting the earlier producer identity.
    return {"outputs": {**ctx.publish("observations", "upstream-test-observations", output),
                        **ctx.publish('runtime','source-runtime',runtime),
                        **ctx.publish('identity','runtime-identity',identity_path)},
            "targets": args["targets"], "claim": "official-make-tests-not-full-native-or-performance-admission"}


class FileBudgetGuard:
    """Time actual flushed upstream file frames; never renew the whole budget."""
    frame = re.compile(r"(?m)^\[\s*(\d+)\|\s*(\d+)\][^\r\n]*?s(?: ([^\r\n]+))?(?=[\r\n]|$)")
    def __init__(self, caps):
        self.caps, self.active, self.rows, self.last_count = dict(caps), None, [], -1
    def __call__(self, stdout, stderr):
        now = time.monotonic()
        if self.active is not None:
            row = self.active
            row['observedSeconds'] = now - row['startedMonotonic']
            if row['observedSeconds'] > row['budgetSeconds']:
                row['outcome'] = 'TIMEOUT'
                raise subprocess.TimeoutExpired(row['file'], row['budgetSeconds'])
        for match in self.frame.finditer(stdout):
            count = int(match[1]) + int(match[2])
            if count < self.last_count:continue
            if self.active is not None and count > self.active['completedBefore']:
                self.active.update(outcome='COMPLETED', observedSeconds=now-self.active['startedMonotonic'])
                self.active = None
            self.last_count = count
            name = match[3]
            if name in self.caps and (not self.rows or self.rows[-1]['completedBefore'] != count):
                row = dict(file=name, completedBefore=count, startedMonotonic=now,
                           budgetSeconds=self.caps[name], outcome='RUNNING', observedSeconds=0)
                self.rows.append(row); self.active = row
    def observations(self):
        return dict(schema='upstream-file-boundaries.v1', budgets=self.caps, intervals=self.rows,
                    wholeDeadlineRenewed=False)
    def complete(self):
        if (self.active is not None or set(self.caps) != {row['file'] for row in self.rows}
                or any(row['outcome'] != 'COMPLETED' for row in self.rows)):
            raise ValueError('upstream did not close every required real file interval')


def file_budget_guard(args, ctx, runtime, files):
    caps = args.get('fileBudgetSeconds', {})
    if not caps:return None
    if ctx.receipt.get('timeoutPolicy', {}).get('mode') == 'progress':
        raise ValueError('official per-file guards require a fixed enclosing wall deadline')
    if not set(caps) <= set(map(str, files)):
        raise ValueError('file budget escaped actual official fixture inventory')
    runner = runtime / 'tests/run-unit-tests.scm'
    if digest(runner) != "4418e155febd6e346f814a71d6262e6f55e068cb26446c10adce8e7803137496":
        raise ValueError('upstream file boundary protocol source changed')
    ctx.bind([runner])
    return FileBudgetGuard(caps)


def validate_target_processors(args, contract, operations):
    from gambit_smp.framework import available_processors
    plan = args.get('targetProcessors', {})
    for name,count in plan.items():
        row = contract['targets'].get(name,{})
        if (name not in operations or row.get('executable') is not True
                or row.get('dependencies') or row.get('unitSelections')
                or name in contract['unitModes'] or type(count) is not int
                or not 0 < count <= available_processors()):
            raise ValueError('processor override requires an independent non-unit upstream target')
    return plan
