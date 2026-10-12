"""Project observed execution facts; the installed ASCENT engine evaluates rules."""
import json
from pathlib import Path
import sys


def validate(args, inputs):
    from gambit_smp.recipes import fields
    entries = set(args) & {"module", "dsl", "rules"}
    if len(entries) != 1:
        raise ValueError("exactly one Evidence entry required")
    entry = next(iter(entries))
    fields(args, (entry, "queries", "expected"), ("recordedQueries",))
    if entry != "rules":
        if (not isinstance(args[entry], str) or args[entry] not in inputs
                or not args[entry].endswith(".json")):
            raise ValueError("declared Evidence JSON entry required")
    elif (not isinstance(args["rules"], list) or not args["rules"] or
          any(name not in inputs or not name.endswith(".ss") for name in args["rules"])):
        raise ValueError("declared native ASCENT rule sources required")
    recorded = args.get("recordedQueries", [])
    if (not isinstance(args["queries"], dict) or not args["queries"]
            or any(not isinstance(key, str) or not isinstance(value, str) for key, value in args["queries"].items())
            or not isinstance(recorded, list) or any(not isinstance(key, str) for key in recorded)
            or len(set(recorded)) != len(recorded) or not isinstance(args["expected"], dict)
            or set(recorded) & set(args["expected"])
            or set(args["expected"]) | set(recorded) != set(args["queries"])):
        raise ValueError("exact native query and result inventory required")
    for rows in args["expected"].values():
        if not isinstance(rows, list) or any(not isinstance(row, list) or
                any(type(value) not in (str, int, bool) for value in row) for row in rows):
            raise ValueError("typed expected relation rows required")


def graph(step, by_id, registry):
    previous = set(by_id) - {step["id"]}
    if set(step["dependsOn"]) != previous:
        raise ValueError("evidence evaluation must depend on the complete observation graph")


def facts(receipt):
    result = {name: [] for name in ("observed_step", "required_step", "step_dependency", "source_binding",
                                   "workspace_projection", "compiled_workspace", "tested_executable",
                                   "control_case", "native_process")}
    for step in receipt["steps"]:
        if step["capability"] == "evidence.evaluate":
            continue
        name, args = step["id"], step["arguments"]
        result["required_step"].append([name])
        result["observed_step"].append([name, step["outcome"], step["capability"]])
        result["step_dependency"].extend([name, parent] for parent in step["dependsOn"])
        if step["outcome"] == "PASS":
            if step["capability"] == "source.bind":
                result["source_binding"].append([name, args["workspace"]["step"]])
            if step["capability"] == "source.project":
                result["workspace_projection"].append([name, args["source"]["step"]])
            if step["capability"] == "native.workspace-build":
                result["compiled_workspace"].append([name, args["binding"]["step"]])
            if step["capability"] == "native.test":
                result["tested_executable"].append([name, args["executable"]["step"]])
                result["control_case"].extend([name, case, case in step.get("expectedFailureControls", [])]
                                              for case in step["passedCases"])
        result["native_process"].extend([name, row["stage"], row["exit"], row["timeout"]]
                                        for row in step.get("commands", []))
    return result


def evaluate(args, ctx):
    actual = evaluate_observations(ctx, args.get("rules", []), facts(ctx.receipt), args["queries"],
                                   "rule-evaluation", module=args.get("module"), dsl=args.get("dsl"))
    if any(not isinstance(actual[key], list) or
           sorted(actual[key], key=repr) != sorted(rows, key=repr) for key, rows in args["expected"].items()):
        raise ValueError("native ASCENT relation outcomes differ from the declared exact inventory")
    return {"claim": "native-rule-evaluation-of-local-observations-only", "answers": actual,
            "recordedOnlyQueries": args.get("recordedQueries", []),
            "sourceRefinementAdmitted": False, "runtimeAdmitted": False}


def module_entry(value):
    from gambit_smp.recipes import fields
    fields(value, ("schema", "module", "constructor", "arguments", "sourceSha256"))
    if (value["schema"] != "ascent.evidence-module-entry.v1"
            or not isinstance(value["module"], str) or not value["module"].startswith(":")
            or len(value["module"]) > 4096
            or not isinstance(value["constructor"], str) or not 0 < len(value["constructor"]) < 129
            or not isinstance(value["arguments"], list)
            or not isinstance(value["sourceSha256"], str) or len(value["sourceSha256"]) != 64
            or any(char not in "0123456789abcdef" for char in value["sourceSha256"])):
        raise ValueError("typed native Evidence module identity required")
    return value


def module_source(entry, build):
    from gambit_smp.framework import digest
    producer = build.get("producerBuild", build)
    bound = producer.get("linkedSchemeSources", {}).get(entry["module"].lstrip(":"))
    if not bound or bound["sha256"] != entry["sourceSha256"]:
        raise ValueError("Evidence module does not match the sealed compiled producer")
    source = Path(bound["path"])
    if digest(source) != entry["sourceSha256"]:
        raise ValueError("Evidence module source changed after its native build")
    return source


def dsl_entry(value):
    from gambit_smp.recipes import fields
    components = value.get("schema") == "ascent.evidence-component-entry.v1"
    required = ("schema", "sources", "constructor", "arguments", "trusted")
    fields(value, required + (("manifest", "entry") if components else ()))
    if (value["schema"] not in ("ascent.evidence-dsl-entry.v1", "ascent.evidence-component-entry.v1") or value["trusted"] is not True
            or not isinstance(value["constructor"], str) or not 0 < len(value["constructor"]) < 129
            or not isinstance(value["arguments"], list) or not isinstance(value["sources"], list)
            or not value["sources"]):
        raise ValueError("typed trusted host Evidence DSL entry required")
    paths = set()
    inventory = value["sources"] + ([value["manifest"]] if components else [])
    if components and (not isinstance(value["entry"], str) or not 0 < len(value["entry"]) < 129):
        raise ValueError("Evidence component entry name required")
    for item in inventory:
        fields(item, ("path", "sha256"))
        path, sha = item["path"], item["sha256"]
        suffix = ".json" if components and item is value["manifest"] else ".ss"
        if (not isinstance(path, str) or not path.endswith(suffix) or Path(path).is_absolute()
                or ".." in Path(path).parts or path in paths
                or not isinstance(sha, str) or len(sha) != 64
                or any(char not in "0123456789abcdef" for char in sha)):
            raise ValueError("unique relative hash-bound DSL sources required")
        paths.add(path)
    return value


def dsl_sources(entry, root):
    from gambit_smp.framework import digest
    from gambit_smp.recipes import source_path
    inventory = entry["sources"] + ([entry["manifest"]] if "manifest" in entry else [])
    paths = [source_path(root, item["path"]) for item in inventory]
    if any(digest(path) != item["sha256"] for path, item in zip(paths, inventory)):
        raise ValueError("Evidence DSL source changed before execution")
    return paths


def evaluate_observations(ctx, rules, projected, queries, label, *, module=None, dsl=None):
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.research_kernel import execution_identity
    engine = Path(ctx.receipt["engine"]["path"])
    execution_identity(engine)
    directory = ctx.directory / label
    directory.mkdir()
    paths = [source_path(ctx.root, name) for name in rules]
    (directory / "facts.json").write_text(json.dumps(projected, sort_keys=True, indent=2) + "\n")
    request = {"rules": [str(path) for path in paths], "facts": projected, "queries": queries,
               "output": str(directory), "engineId": ctx.receipt["engine"]["engineId"]}
    if module is not None:
        entry_path = source_path(ctx.root, module)
        request["module"] = module_entry(read_json(entry_path))
        request["moduleInput"] = str(entry_path)
        source = module_source(request["module"], read_json(engine / "native" / "receipt.json"))
        ctx.bind([entry_path, source])
        request["moduleInputSha256"] = ctx.extra_inputs[str(entry_path.resolve())]
    if dsl is not None:
        entry_path = source_path(ctx.root, dsl)
        request["dsl"] = dsl_entry(read_json(entry_path))
        paths = dsl_sources(request["dsl"], ctx.root)
        inventory = request["dsl"]["sources"] + ([request["dsl"]["manifest"]] if "manifest" in request["dsl"] else [])
        if any(item["path"] not in ctx.receipt["declaredInputs"] for item in inventory):
            raise ValueError("all DSL sources must be declared recipe inputs")
        ctx.bind([entry_path, *paths])
        request.update(dslInput=str(entry_path), dslInputSha256=ctx.extra_inputs[str(entry_path.resolve())],
                       dslRoot=str(ctx.root))
    target = directory / "evaluation.json"
    target.write_text(json.dumps(request, sort_keys=True, indent=2) + "\n")
    ctx.require("native-" + label, [sys.executable, "-I", "-B", engine / "runner.py", "rules", target],
                ctx.root, ctx.remaining())
    return read_json(directory / "answers.json")


def native_evaluate(request):
    from gambit_smp.ascent_program import load_catalog, load_module_catalog, load_evidence_catalog, load_component_catalog, engine_api, query
    from gambit_smp.framework import digest
    from gambit_smp.recipes import read_json
    directory = Path(request["output"])
    paths = [Path(name) for name in request["rules"]]
    if ("module" in request and "dsl" in request) or (paths and ("module" in request or "dsl" in request)):
        raise ValueError("Evidence entries are exclusive")
    metrics = {}
    with engine_api() as (engine, identities):
        if "module" in request:
            entry = module_entry(request["module"])
            source = module_source(entry, engine.build_receipt)
            entry_path = Path(request["moduleInput"])
            if digest(entry_path) != request["moduleInputSha256"] or read_json(entry_path) != entry:
                raise ValueError("Evidence module entry changed before native execution")
            catalog = load_module_catalog(entry["module"], entry["constructor"], entry["arguments"],
                                          inputs=[source, entry_path])
        elif "dsl" in request:
            entry = dsl_entry(request["dsl"])
            entry_path = Path(request["dslInput"])
            if digest(entry_path) != request["dslInputSha256"] or read_json(entry_path) != entry:
                raise ValueError("Evidence DSL entry changed before execution")
            paths = dsl_sources(entry, Path(request["dslRoot"]))
            if "manifest" in entry:
                catalog = load_component_catalog(paths[-1], entry=entry["entry"], constructor=entry["constructor"],
                                                arguments=entry["arguments"], trusted=entry["trusted"])
                expected = {str(path.resolve()): item["sha256"]
                            for path, item in zip(paths, entry["sources"] + [entry["manifest"]])}
                if catalog["sourceInputs"] != expected:
                    raise ValueError("Evidence component entry omits or changes its complete source inventory")
            else:
                catalog = load_evidence_catalog(*paths, constructor=entry["constructor"],
                                            arguments=entry["arguments"], trusted=entry["trusted"])
            catalog["sourceInputs"][str(entry_path.resolve())] = request["dslInputSha256"]
        else:
            catalog = load_catalog(*paths)
        answers = query(request["facts"], catalog, request["queries"], engine=engine, metrics=metrics)
        if any(digest(Path(path)) != sha for path, sha in catalog["sourceInputs"].items()):
            raise ValueError("Evidence entry source changed during execution")
        actual = {key: rows if isinstance(rows, dict) else [list(row) for row in rows]
                  for key, rows in answers.items()}
        explanations = {}
        if "module" in request or "dsl" in request:
            for key, relation in request["queries"].items():
                proof = engine.request({"operation": "native-result", "handle": metrics["nativeSessionHandle"],
                                        "result": metrics["nativeResultHandle"], "action": "explain",
                                        "relation": relation})
                explanations[key] = proof
                engine.request({"operation": "native-result", "handle": metrics["nativeSessionHandle"],
                                "result": proof["explanationHandle"], "action": "release"})
        (directory / "explanations.json").write_text(json.dumps({"answers": explanations,
            "status": "recorded-only", "handleLifetime": "native-worker-process",
            "runtimeAdmitted": False, "sourceRefinementAdmitted": False}, sort_keys=True, indent=2) + "\n")
    (directory / "answers.json").write_text(json.dumps(actual, sort_keys=True, indent=2) + "\n")
    (directory / "native-engine.json").write_text(json.dumps({"identities": identities, **metrics}, sort_keys=True, indent=2) + "\n")


def capabilities(Capability):
    return {"evidence.evaluate": Capability(validate, executor=evaluate, graph=graph)}
