"""Official Make transport; Evidence DSL owns scope/dependency inference."""
import json
import re
from pathlib import Path

from gambit_smp.framework import digest

CONTRACT = "evidence/research/ci/upstream-tests.json"
ENTRY = "evidence/research/ci/test-scope.entry.json"
RULES = "evidence/dsl/upstream-test-scope.ss"
POLICIES = {CONTRACT: "policy/upstream-tests.json", ENTRY: "policy/upstream-test-scope.entry.json",
            RULES: "policy/upstream-test-scope.ss"}


def validate(args, inputs):
    from gambit_smp.recipes import fields
    from gambit_smp.native_capabilities import reference
    fields(args, ("runtime", "identity", "targets", "failures", "reviewRules"),
           ("reviews", "environmentProbe"))
    reference(args["runtime"])
    reference(args["identity"])
    if "environmentProbe" in args:
        reference(args["environmentProbe"])
    targets = args["targets"]
    if (not isinstance(targets, list) or not targets or len(targets) != len(set(targets))
            or any(not isinstance(name, str) or not re.fullmatch(r"[a-z][a-z0-9-]{0,63}", name) for name in targets)):
        raise ValueError("unique literal official Make test targets required")
    if (args["failures"] != "evidence/native-failures.json" or args["failures"] not in inputs
            or args["reviewRules"] not in inputs or not args["reviewRules"].endswith(".ss")
            or not set(POLICIES) <= set(inputs)):
        raise ValueError("canonical failures, sealed policy and scope sources required")
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


def scope_contract(ctx, runtime):
    """Validate byte correspondence only; do not interpret Make or infer closure."""
    from gambit_smp.recipes import fields, read_json, source_path
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.framework import relative
    manifest = manifest_paths(Path(ctx.receipt["engine"]["path"]))
    for name, sealed in POLICIES.items():
        path = source_path(ctx.root, name)
        if digest(path) != manifest["files"].get(sealed):
            raise ValueError("test scope policy differs from the sealed implementation")
        ctx.bind([path])
    contract = read_json(source_path(ctx.root, CONTRACT))
    fields(contract, ("schema", "template", "makefile", "targets", "unitModes", "scope"))
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
        headers = [line for line in source_lines if line.startswith(name + ":")]
        if (not headers or row["headers"] != headers
                or [line for line in configured_lines if line.startswith(name + ":")] != headers):
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
    ctx.bind([template, makefile])
    return contract, makefile


def infer_scope(ctx, contract, makefile, targets):
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
        "upstream-review-scope", dsl=ENTRY)
    if inferred["cycle"] or not inferred["scope"]:
        raise ValueError("native test scope is cyclic or missing")
    operations = sorted(row[0] for row in inferred["scope"])
    if not set(targets) <= set(operations) or not set(operations) <= declarations.keys():
        raise ValueError("inferred review scope escaped its source contract")
    selections = sorted(row[0] for row in inferred["selection"])
    modes = [mode for mode in ("gsi", "gsc") if [mode] in inferred["mode"]]
    files = selected_files(makefile.parent / "unit-tests", selections, inventory="unit") if selections else []
    return makefile, operations, files, modes, inferred


def execute(args, ctx):
    from gambit_smp.native_capabilities import clone, compiler
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
    contract, makefile = scope_contract(ctx, runtime)
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
        # One official invocation retains Make's prerequisite de-duplication.
        observed.update(executionRequested=True, executionStarted=None)
        retain()
        code, _, timeout, seconds = ctx.run("upstream-tests",
            [ctx.tools["make"], *args["targets"]], makefile.parent, ctx.remaining())
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
    return {"outputs": ctx.publish("observations", "upstream-test-observations", output),
            "targets": args["targets"], "claim": "official-make-tests-not-full-native-or-performance-admission"}
