"""Source-bound necessary action guards, not an enabledness equivalence proof."""
from gambit_smp.task_processes import check_output as _task_check_output
import argparse
import json
from pathlib import Path
import shutil
import subprocess

from gambit_smp.framework import ROOT, digest, execute
from gambit_smp.generator_contract import app, name
from gambit_smp.generator_contract import audit as audit_generator
from gambit_smp.induction_matrix import action_members, symbolic_check


def normalized(node):
    """Drop parser identities while preserving expression and binder structure."""
    if isinstance(node, list):
        return [normalized(item) for item in node]
    if isinstance(node, dict):
        return {key: normalized(value) for key, value in node.items()
                if key not in ("id", "typeAnnotation")}
    return node


def free_names(node):
    kind = node.get("kind")
    if kind == "name":
        return {node["name"]}
    if kind == "let":
        binding = node["opdef"]
        return free_names(binding["expr"]) | (free_names(node["expr"]) - {binding["name"]})
    if kind == "lambda":
        return free_names(node["expr"]) - {param["name"] for param in node["params"]}
    if kind == "app":
        return set().union(*(free_names(arg) for arg in node["args"]))
    if kind in ("bool", "int", "str"):
        return set()
    raise ValueError("unsupported guard expression: " + str(kind))


def pure_expression(node):
    """Reject action/temporal constructs even when buried in a predicate."""
    kind = node.get("kind")
    if kind in ("name", "bool", "int", "str"):
        return
    if kind == "app":
        if node["opcode"] in ("assign", "oneOf", "actionAll", "actionAny", "next",
                               "always", "eventually", "weakFair", "strongFair", "enabled"):
            raise ValueError("guard must be a state predicate")
        for arg in node["args"]:
            pure_expression(arg)
        return
    if kind in ("let", "lambda"):
        binding = node["opdef"] if kind == "let" else node
        if binding.get("qualifier") not in ("val", "def", "pureval", "puredef"):
            raise ValueError("unsupported guard binding")
        pure_expression(binding["expr"])
        if kind == "let":
            pure_expression(node["expr"])
        return
    raise ValueError("unsupported guard expression: " + str(kind))


def conjunction(nodes):
    nodes = [node for node in nodes if node != {"kind": "bool", "value": True}]
    return app("and", *nodes) if len(nodes) > 1 else (
        nodes[0] if nodes else {"kind": "bool", "value": True})


def project(expression, state="s"):
    """Erase one total-state assignment; existentially bind original choices.

    Erasing RHS expressions is deliberately an over-approximation. A true
    projected guard cannot qualify the action without a separate definedness
    and evaluation-semantics proof.
    """
    assignments = []

    def walk(node):
        if node.get("kind") == "let":
            binding = node["opdef"]
            body = walk(node["expr"])
            if binding.get("qualifier") == "nondet":
                choice = binding["expr"]
                if choice.get("opcode") != "oneOf" or len(choice["args"]) != 1:
                    raise ValueError("original choices must use oneOf")
                pure_expression(choice["args"][0])
                return app("exists", normalized(choice["args"][0]), {
                    "kind": "lambda", "qualifier": "def",
                    "params": [{"name": binding["name"]}], "expr": body})
            if binding.get("qualifier") != "val":
                raise ValueError("only original value bindings supported")
            pure_expression(binding["expr"])
            if binding["name"] not in free_names(body):
                return body
            return {"kind": "let", "opdef": normalized(binding), "expr": body}
        if node.get("opcode") == "actionAll":
            return conjunction([walk(arg) for arg in node["args"]])
        if node.get("opcode") == "assign":
            if len(node["args"]) != 2 or normalized(node["args"][0]) != name(state):
                raise ValueError("one assignment to original state required")
            assignments.append(normalized(node["args"][1]))
            return {"kind": "bool", "value": True}
        pure_expression(node)
        return normalized(node)

    result = walk(expression)
    if len(assignments) != 1:
        raise ValueError("exactly one original assignment required")
    return result


def projections(ir, module="gc_recursive_queue_wait", step="step"):
    actions = action_members(ir, module, step)
    declarations = {item["name"]: item for item in next(
        item for item in ir["modules"] if item["name"] == module)["declarations"] if "name" in item}
    if {key for key, declaration in declarations.items() if declaration.get("kind") == "var"} != {"s"}:
        raise ValueError("exactly one original state variable required")
    result = {action: project(declarations[action]["expr"]) for action in actions}

    def check_calls(node, bound=frozenset(), resolving=()):
        kind = node["kind"]
        identifier = node.get("name") if kind == "name" else node.get("opcode")
        if identifier in declarations and identifier not in bound:
            declaration = declarations[identifier]
            if declaration.get("qualifier") == "action" or identifier in resolving:
                raise ValueError("action or recursive call in projected guard: " + identifier)
            if "expr" in declaration:
                pure_expression(declaration["expr"])
                check_calls(declaration["expr"], bound, resolving + (identifier,))
        if kind == "app":
            for arg in node["args"]:
                check_calls(arg, bound, resolving)
        elif kind == "lambda":
            check_calls(node["expr"], bound | {param["name"] for param in node["params"]}, resolving)
        elif kind == "let":
            check_calls(node["opdef"]["expr"], bound, resolving)
            check_calls(node["expr"], bound | {node["opdef"]["name"]}, resolving)

    for expression in result.values():
        check_calls(expression)
    return result


def formatter():
    executable = shutil.which("quint")
    if not executable:
        raise ValueError("Quint installation required")
    target = Path(executable).resolve().parent / "ir/IRprinting.js"
    if not target.is_file():
        raise ValueError("selected Quint installation has no official IR formatter")
    return target


def format_module(expressions, cwd):
    payload = {"name": "gc_recursive_queue_guards", "declarations": [
        {"kind": "import", "protoName": "gc_recursive_queue_wait", "defName": "*",
         "fromSource": "./gc_recursive_queue_wait"},
        {"kind": "import", "protoName": "gc_recursive_queue_induction", "defName": "*",
         "fromSource": "./gc_recursive_queue_induction"}]}
    payload["declarations"].extend({"kind": "def", "qualifier": "val", "name": "guard_" + action,
        "expr": expression} for action, expression in expressions.items())
    payload["declarations"].extend([
        {"kind": "def", "qualifier": "val", "name": "guardCoverage",
         "expr": app("or", name("terminal"), *(name("guard_" + action) for action in expressions))},
        {"kind": "def", "qualifier": "val", "name": "rejectsTerminalOnly",
         "expr": name("terminal")}])
    return format_ir(payload, cwd)


def format_ir(payload, cwd):
    """Use the selected Quint installation's own source printer."""
    script = ("const fs=require('fs'); const p=require(process.argv[1]); "
              "process.stdout.write(p.moduleToString(JSON.parse(fs.readFileSync(0,'utf8')))+'\\n');")
    return _task_check_output(["node", "-e", script, str(formatter())],
        input=json.dumps(payload), text=True, cwd=cwd, timeout=10)


def verify_generated(ir, expressions):
    if ir.get("stage") != "parsing" or ir.get("errors"):
        raise ValueError("successful generated-model parse required")
    module = next(item for item in ir["modules"] if item["name"] == "gc_recursive_queue_guards")
    definitions = {item["name"]: item for item in module["declarations"] if "name" in item}
    for action, expected in expressions.items():
        actual = definitions.get("guard_" + action, {})
        if actual.get("qualifier") != "val" or normalized(actual.get("expr")) != expected:
            raise ValueError("generated guard differs from original projection: " + action)
    expected = app("or", name("terminal"), *(name("guard_" + action) for action in expressions))
    if normalized(definitions["guardCoverage"]["expr"]) != expected:
        raise ValueError("coverage must include every original branch")
    if normalized(definitions["rejectsTerminalOnly"]["expr"]) != name("terminal"):
        raise ValueError("negative control differs")


def campaign(out, sufficient=False):
    out.mkdir(parents=True, exist_ok=False)
    model_inputs = {}
    framework_inputs = {path: digest(ROOT / path) for path in (
        "src/gambit_smp/guard_projection.py", "src/gambit_smp/induction_matrix.py",
        "src/gambit_smp/framework.py", "src/gambit_smp/quint_backend.py")}
    if sufficient:
        framework_inputs["src/gambit_smp/expression_definedness.py"] = digest(
            ROOT / "src/gambit_smp/expression_definedness.py")
    framework_inputs["src/gambit_smp/generator_contract.py"] = digest(
        ROOT / "src/gambit_smp/generator_contract.py")
    receipt = {"schema": "gc-necessary-guard-audit.v1", "accepted": False,
        "native": {"status": "not-run"}, "runtimeAdmitted": False, "releaseAdmitted": False,
        "temporalProved": False, "enablednessProved": False, "rhsDefinednessProved": False,
        "auditPassed": False, "frameworkInputs": framework_inputs, "modelInputs": model_inputs,
        "projectionKind": "conservative-defined-transition" if sufficient else "necessary-guards",
        "results": []}
    try:
        receipt["quintVersion"] = _task_check_output(["quint", "--version"], text=True, timeout=10).strip()
        if receipt["quintVersion"] != "0.33.0":
            raise ValueError("reviewed Quint 0.33.0 required")
        for file in ("gc_recursive_queue_wait.qnt", "gc_recursive_queue_induction.qnt"):
            source = ROOT / "models/gambit" / file
            (out / file).write_bytes(source.read_bytes())
            model_inputs[file] = digest(source)
        ir_path = out / "protocol-ir.json"
        code, output, expired, _ = execute(["quint", "parse", str(out / "gc_recursive_queue_wait.qnt"),
            "--out", str(ir_path)], out, 10)
        if code or expired:
            raise ValueError("original IR parse failed: " + output[-500:])
        expressions = projections(json.loads(ir_path.read_text()))
        if sufficient:
            from gambit_smp.expression_definedness import sufficient_projections
            expressions, partial = sufficient_projections(json.loads(ir_path.read_text()), expressions)
            receipt["partialOperationsCovered"] = partial
        receipt.update(originalActions=list(expressions), protocolIrSha256=digest(ir_path))
        generated = out / "gc_recursive_queue_guards.qnt"
        generated.write_text(format_module(expressions, out))
        model_inputs[generated.name] = digest(generated)
        proof_ir = out / "proof-ir.json"
        code, output, expired, _ = execute(["quint", "parse", str(generated), "--out", str(proof_ir)], out, 10)
        if code or expired:
            raise ValueError("guard IR parse failed: " + output[-500:])
        verify_generated(json.loads(proof_ir.read_text()), expressions)
        receipt["generatorContract"] = audit_generator(json.loads(proof_ir.read_text()),
            "gc_recursive_queue_induction", "initSafetyCandidate", "candidateInvariant")
        receipt["generatorContract"]["proofIrSha256"] = digest(proof_ir)
        receipt.update(projectionVerified=True, proofIrSha256=digest(proof_ir),
                       formatterSha256=digest(formatter()))
        for invariant, positive in (("guardCoverage", True), ("rejectsTerminalOnly", False)):
            directory = out / invariant
            directory.mkdir()
            result, output = symbolic_check(generated, initializer="initSafetyCandidate",
                invariant=invariant, step="step", length=0, cwd=directory)
            log = out / (invariant + ".log")
            log.write_text(output)
            result.update(case=generated.stem, variant="diagnostic", modelSha256=digest(generated),
                          log=log.name, logSha256=digest(log))
            receipt["results"].append(result)
            if not (result["obligationProved"] if positive else result["counterexample"]):
                break
        receipt["contextStable"] = (all(digest(ROOT / "models/gambit" / file) == sha
            for file, sha in model_inputs.items() if file != generated.name) and
            all(digest(ROOT / file) == sha for file, sha in framework_inputs.items()) and
            digest(ir_path) == receipt["protocolIrSha256"] and
            digest(proof_ir) == receipt["proofIrSha256"] and
            digest(generated) == model_inputs[generated.name] and
            digest(formatter()) == receipt["formatterSha256"])
        receipt["auditPassed"] = (receipt["contextStable"] and len(receipt["results"]) == 2 and
            receipt["results"][0]["obligationProved"] and receipt["results"][1]["counterexample"])
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        receipt["error"] = str(error)
    finally:
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--sufficient", action="store_true",
                        help="include conservative original expression/RHS definedness, not guard-only coverage")
    args = parser.parse_args()
    result = campaign(args.out.resolve(), args.sufficient)
    print(json.dumps({key: result.get(key) for key in (
        "auditPassed", "error", "contextStable", "enablednessProved", "results")}, sort_keys=True))
    if not result["auditPassed"]:
        parser.exit(1)


from gambit_smp.task_entry import managed_tool as _managed_tool
main = _managed_tool('guard-projection')(main)

if __name__ == '__main__':
    from gambit_smp.task_entry import tool_main
    raise SystemExit(tool_main('guard-projection',main))
