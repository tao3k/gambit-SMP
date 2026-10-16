"""Compose archived induction obligations only under exact dependency identity."""
import argparse
import json
from pathlib import Path

from gambit_smp.framework import ROOT, digest
from gambit_smp.generator_contract import audit as audit_generator
from gambit_smp.induction_matrix import action_members, safety_obligations, scoped_declarations
from gambit_smp.protocol_evidence import relative
from gambit_smp.reasoning_history import fingerprint


def semantic(node):
    """Ignore parser allocation IDs, not identifiers, literals, guards or types."""
    if isinstance(node, dict):
        return {key: semantic(value) for key, value in node.items() if key != "id"}
    if isinstance(node, list):
        return [semantic(value) for value in node]
    return node


def modules_equal(before, after, names):
    for name in names:
        old = [row for row in before["modules"] if row["name"] == name]
        new = [row for row in after["modules"] if row["name"] == name]
        if len(old) != 1 or len(new) != 1 or semantic(old[0]) != semantic(new[0]):
            raise ValueError("induction dependency changed: " + name)


def predicate(ir, module, name, seen=()):
    if name in seen:
        raise ValueError("cyclic predicate alias")
    scope = scoped_declarations(ir, module)
    origin, declaration = scope[name]
    expression = declaration.get("expr", {})
    if expression.get("kind") == "name":
        return predicate(ir, origin, expression["name"], (*seen, name))
    if declaration.get("qualifier") not in {"val", "pureval"}:
        raise ValueError("safety predicate must be a value")
    return origin, semantic(declaration)


def checked_delta(root, name):
    path = relative(root, name)
    saved = json.loads(path.read_text())
    archive_path = path.parent / "archive.json"
    archive = json.loads(archive_path.read_text())
    if (saved.get("schema") != "gambit-induction-matrix-result.v1" or
            saved.get("accepted") is not False or saved.get("runtimeAdmitted") is not False or
            saved.get("releaseAdmitted") is not False or saved.get("contextStable") is not True or
            saved.get("initialProved") is not True or saved.get("failedActions") or
            archive.get("schema") != "gambit-model-attempt-archive.v1" or
            archive.get("archiveOnly") is not True or archive.get("accepted") is not False):
        raise ValueError("stable non-admitted archived obligations required")
    inputs = {name: digest(path), archive_path.relative_to(root).as_posix(): digest(archive_path)}
    for filename, identity in archive["files"].items():
        artifact = relative(path.parent, filename)
        if digest(artifact) != identity["portableSha256"]:
            raise ValueError("delta archive artifact drift")
        inputs[artifact.relative_to(root).as_posix()] = digest(artifact)
    if archive["files"]["receipt.json"]["rawSha256"] != archive["originalReceiptSha256"]:
        raise ValueError("delta receipt attestation mismatch")
    initial = [row for row in saved["results"] if row["kind"] == "initial"]
    if len(initial) != 1:
        raise ValueError("one initial inclusion obligation required")
    keys = set()
    for row in saved["results"]:
        key = (row["kind"], row["originalStep"])
        if key in keys or row["kind"] not in {"initial", "preservation"}:
            raise ValueError("duplicate or unsupported delta obligation")
        keys.add(key)
        if saved["modelInputs"].get(row["case"] + ".qnt") != row["modelSha256"]:
            raise ValueError("delta obligation model differs from snapshot")
        text = relative(path.parent, row["log"]).read_text()
        if (row.get("obligationProved") is not True or row["exit"] != 0 or row["timeout"] or
                row.get("contextStable") is not True or
                row["logSha256"] != archive["files"][row["log"]]["rawSha256"] or
                "The outcome is: NoError" not in text or "[ok] No violation found" not in text):
            raise ValueError("delta obligation lacks successful checker evidence")
    return saved, inputs


def compose(root, baseline, delta, manifest):
    root = Path(root).resolve()
    config = json.loads(relative(root, manifest).read_text())
    if config.get("schema") != "gambit-induction-matrix.v1":
        raise ValueError("induction manifest required")
    target, inputs = checked_delta(root, delta)
    old_path = relative(root, baseline)
    old_record = json.loads(old_path.read_text())
    common = set(old_record["modelInputs"]) & set(target["modelInputs"])
    if common != set(old_record["modelInputs"]):
        raise ValueError("all baseline model dependencies must be retained")
    paths = [config["model"], config["protocol"], *config.get("dependencies", [])]
    by_name = {Path(path).name: path for path in paths}
    if len(by_name) != len(paths) or not common.issubset(by_name):
        raise ValueError("unique complete dependency paths required")
    old, bound = safety_obligations(root, baseline, [by_name[name] for name in sorted(common)])
    inputs.update(bound)
    inputs[manifest] = digest(relative(root, manifest))
    for name, path in by_name.items():
        actual = digest(relative(root, path))
        if target["modelInputs"].get(name) != actual:
            raise ValueError("target dependency differs from checked model")
        if name in common and old["modelInputs"][name] != actual:
            raise ValueError("baseline dependency differs from target")
        inputs[path] = actual
    old_ir = json.loads((old_path.parent / "proof-ir.json").read_text())
    new_ir = json.loads((relative(root, delta).parent / "proof-ir.json").read_text())
    for receipt, path in ((old, old_path), (target, relative(root, delta))):
        expected = receipt.get("proofIrSha256") or receipt.get("generatorContract", {}).get("proofIrSha256")
        if expected != digest(path.parent / "proof-ir.json"):
            raise ValueError("proof IR differs from checked obligation")
    contract = audit_generator(new_ir, initializer=config["inductionInitializer"],
                              invariant=config["invariant"], **config["generatorContract"])
    modules = [Path(name).stem for name in sorted(common)]
    modules_equal(old_ir, new_ir, modules)
    scope = scoped_declarations(new_ir, Path(config["model"]).stem)
    old_scope = scoped_declarations(old_ir, Path(old["results"][0]["case"]).stem)
    for name, value in old_scope.items():
        if name not in scope or (value[0], semantic(value[1])) != (scope[name][0], semantic(scope[name][1])):
            raise ValueError("baseline scope not preserved: " + name)
    actions = action_members(new_ir, config["protocolModule"], config["step"])
    fresh = {row["originalStep"]: row for row in target["results"] if row["kind"] == "preservation"}
    old_preservation = [row for row in old["results"] if row["kind"] == "preservation"]
    old_rows = {row.get("originalStep", row["step"]): row for row in old_preservation}
    if len(old_rows) != len(old_preservation) or set(old_rows) != set(old["originalActions"]):
        raise ValueError("baseline branch coverage is ambiguous")
    if not set(fresh).issubset(actions):
        raise ValueError("delta covers a branch outside target relation")
    coverage = []
    for action in actions:
        if action in fresh:
            row = fresh[action]
            if (row["initializer"] != config["inductionInitializer"] or row["invariant"] != config["invariant"] or row["length"] != 1):
                raise ValueError("delta induction domain or predicate differs")
            receipt = delta
        else:
            row = old_rows.get(action)
            if row is None or action not in old_scope or scope[action][0] != old_scope[action][0]:
                raise ValueError("uncovered target action: " + action)
            if (row["initializer"] != config["inductionInitializer"] or row["invariant"] != config["invariant"] or row["length"] != 1):
                raise ValueError("baseline induction domain or predicate differs")
            receipt = baseline
        if row["step"] != action:
            raise ValueError("wrapped obligations require separate refinement")
        coverage.append({"action": action, "receipt": receipt, "log": row["log"],
                         "reused": receipt == baseline})
    initial = next(row for row in target["results"] if row["kind"] == "initial")
    if initial["initializer"] != config["initializer"] or initial["invariant"] != config["invariant"] or initial["length"] != 0:
        raise ValueError("target initial inclusion differs")
    implication = [row for row in old["results"] if row["kind"] == "implication"]
    if len(implication) != 1 or implication[0]["initializer"] != config["inductionInitializer"] or implication[0]["length"] != 0:
        raise ValueError("one matching safety implication required")
    if predicate(new_ir, config["protocolModule"], config["goal"]) != predicate(old_ir, implication[0]["case"], implication[0]["invariant"]):
        raise ValueError("safety implication goal differs")
    for name in ("induction_reuse", "induction_matrix", "generator_contract", "framework", "protocol_evidence", "reasoning_history"):
        path = root / "src/gambit_smp" / (name + ".py")
        inputs[path.relative_to(root).as_posix()] = digest(path)
    if any(digest(relative(root, name)) != sha for name, sha in inputs.items()):
        raise ValueError("composition inputs changed")
    result = {"schema": "gambit-induction-composition.v1", "accepted": False,
              "runtimeAdmitted": False, "releaseAdmitted": False, "temporalProved": False,
              "inductiveSafetyAdmitted": False, "solverCoverageProved": False,
              "symbolicObligationsComplete": True, "coverage": coverage,
              "generatorContract": contract,
              "initialReceipt": delta, "implicationReceipt": baseline, "inputs": inputs,
              "scope": "Exact shared module/scope identity composes bounded symbolic obligations; Cartesian generator semantics remain a trusted audit rule, not solver-proved C refinement."}
    result["compositionSha256"] = fingerprint(result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--delta", required=True)
    parser.add_argument("--manifest", required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", required=True, type=runtime_argument)
    args = parser.parse_args()
    result = compose(ROOT, args.baseline, args.delta, args.manifest)
    args.out.mkdir(parents=True, exist_ok=False)
    (args.out / "receipt.json").write_text(json.dumps(result, indent=2) + "\n")
    print("INDUCTION-COMPOSED-NOT-NATIVE-ADMITTED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
