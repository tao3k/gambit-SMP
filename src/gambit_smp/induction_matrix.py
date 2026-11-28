"""Bounded symbolic obligations for the original GC step; no native admission."""
from gambit_smp.task_processes import check_output as _task_check_output
import argparse
import json
from pathlib import Path
import re
import subprocess

from gambit_smp.framework import ROOT, available_processors, digest, execute
from gambit_smp.generator_contract import audit as audit_generator, canonical
from gambit_smp.model_schedule import physical_memory, resources, run_batch
from gambit_smp.protocol_evidence import portable, relative
from gambit_smp.quint_backend import isolated_endpoint

MANIFEST = "evidence/gc-induction-matrix.json"


def scoped_declarations(ir, module, pending=()):
    """Resolve explicit wildcard imports; reject ambiguous or unsupported scopes."""
    if module in pending:
        raise ValueError("cyclic protocol imports")
    modules = [item for item in ir["modules"] if item["name"] == module]
    if len(modules) != 1:
        raise ValueError("exactly one protocol module required")
    result = {}
    for declaration in modules[0]["declarations"]:
        if declaration.get("kind") == "import":
            if declaration.get("defName") != "*" or declaration.get("qualifiedName"):
                raise ValueError("only explicit unqualified wildcard imports supported")
            imported = scoped_declarations(ir, declaration["protoName"], (*pending, module))
            for name, value in imported.items():
                if name in result and result[name] != value:
                    raise ValueError("ambiguous imported protocol declaration: " + name)
                result[name] = value
        elif "name" in declaration:
            name = declaration["name"]
            value = (module, declaration)
            if name in result and result[name] != value:
                raise ValueError("ambiguous protocol declaration: " + name)
            result[name] = value
    return result


def action_members(ir, module, step):
    if ir.get("stage") != "parsing" or ir.get("errors"):
        raise ValueError("successful Quint parse required")
    declarations = {name: value[1] for name, value in scoped_declarations(ir, module).items()}
    expression = declarations[step]["expr"]
    if expression.get("kind") != "app" or expression.get("opcode") != "actionAny":
        raise ValueError("protocol step must be an explicit disjunction of named actions")
    names = []
    for item in expression["args"]:
        name = item.get("name")
        if (item.get("kind") != "name" or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", name or "") or
                declarations.get(name, {}).get("qualifier") != "action" or name in names):
            raise ValueError("unsupported, duplicate or non-action protocol branch")
        body = declarations[name].get("expr", {})
        if body.get("kind") == "name" or body.get("opcode") == "actionAny":
            raise ValueError("alias or nested action disjunction requires explicit expansion")
        names.append(name)
    if not names:
        raise ValueError("empty protocol step")
    return names


def proof_adapters(ir, module, prefix, actions, combined=None, updates=None):
    modules = [item for item in ir["modules"] if item["name"] == module]
    if len(modules) != 1 or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", prefix):
        raise ValueError("one exact adapter module and valid prefix required")
    declarations = {item["name"]: item for item in modules[0]["declarations"] if "name" in item}
    ghosts = {item["name"] for item in declarations.values() if item.get("kind") == "var"}
    if "s" in ghosts or not ghosts:
        raise ValueError("adapter may own only distinct proof history variables")
    result = {}
    for original in actions:
        wrapper = prefix + original
        declaration = declarations.get(wrapper, {})
        body = declaration.get("expr", {})
        if declaration.get("qualifier") != "action" or body.get("opcode") != "actionAll":
            raise ValueError("explicit original-action plus history assignments required")
        calls = [arg for arg in body["args"] if arg.get("kind") == "name"]
        assignments = [arg for arg in body["args"] if arg.get("opcode") == "assign"]
        if (len(calls) != 1 or calls[0]["name"] != original or
                len(body["args"]) != 1 + len(ghosts) or len(assignments) != len(ghosts) or
                {arg["args"][0].get("name") for arg in assignments} != ghosts or
                any(arg["args"][0].get("kind") != "name" for arg in assignments)):
            raise ValueError("adapter must not add guards or write original state")
        if updates is not None and (set(updates) != ghosts or any(
                canonical(arg["args"][1]) != canonical(updates[arg["args"][0]["name"]])
                for arg in assignments)):
            raise ValueError("adapter history assignments differ from required update")
        result[original] = wrapper
    if combined is not None:
        actual = action_members(ir, module, combined)
        if actual != list(result.values()):
            raise ValueError("combined adapter must cover every original transition in order")
    return result


def symbolic_check(snapshot, *, initializer, invariant, step, length, cwd, timeout=90):
    if length not in (0, 1) or timeout <= 0 or timeout > 90:
        raise ValueError("induction obligations use lengths 0/1 and at most 90 seconds")
    command = ["quint", "verify", str(snapshot), "--backend", "apalache",
        "--apalache-version", "0.62.1", "--init", initializer, "--step", step,
        "--invariant", invariant, "--max-steps", str(length),
        "--server-endpoint", isolated_endpoint(), "--verbosity", "2"]
    code, output, timed_out, seconds = execute(command, cwd, timeout)
    proved = (not timed_out and code == 0 and "[ok] No violation found" in output and
              "The outcome is: NoError" in output)
    counterexample = (not timed_out and code != 0 and "[violation] Found an issue" in output and
                     "[State 0]" in output)
    return {"initializer": initializer, "invariant": invariant, "step": step,
            "length": length, "exit": code, "timeout": timed_out,
            "timeoutBudgetSeconds": timeout,
            "seconds": round(seconds, 3), "obligationProved": proved,
            "counterexample": counterexample}, output


def safety_obligations(root, receipt_path, model_paths):
    root = root.resolve()
    receipt = relative(root, receipt_path)
    saved = json.loads(receipt.read_text())
    archive_path = receipt.parent / "archive.json"
    archive = json.loads(archive_path.read_text())
    if (saved.get("accepted") is not False or saved.get("runtimeAdmitted") is not False or
            saved.get("releaseAdmitted") is not False or
            saved.get("schema") != "gambit-induction-matrix-result.v1" or
            saved.get("proofKind", "safety") != "safety" or not saved.get("initialProved") or
            not saved.get("preservationComplete") or not saved.get("implicationProved") or
            not saved.get("contextStable") or saved.get("failedActions") or saved.get("uncoveredActions") or
            archive.get("archiveOnly") is not True or archive.get("accepted") is not False):
        raise ValueError("complete archived safety obligations required")
    inputs = {receipt_path: digest(receipt), str(archive_path.relative_to(root)): digest(archive_path)}
    for path in model_paths:
        if saved["modelInputs"].get(Path(path).name) != digest(relative(root, path)):
            raise ValueError("ranking dependency differs from checked safety model")
    for filename, identity in archive["files"].items():
        artifact = relative(receipt.parent, filename)
        if digest(artifact) != identity["portableSha256"]:
            raise ValueError("safety archive artifact drift")
        inputs[str(artifact.relative_to(root))] = digest(artifact)
    if archive["files"]["receipt.json"]["rawSha256"] != archive["originalReceiptSha256"]:
        raise ValueError("safety receipt attestation mismatch")
    for row in saved["results"]:
        log = row["log"]
        if (not row["obligationProved"] or row["timeout"] or row["exit"] != 0 or
                archive["files"][log]["rawSha256"] != row["logSha256"]):
            raise ValueError("safety check did not pass or log attestation drift")
        output = relative(receipt.parent, log).read_text()
        if "The outcome is: NoError" not in output or "[ok] No violation found" not in output:
            raise ValueError("safety log lacks real checker success")
    if (len(saved["results"]) != len(saved["originalActions"]) + 2 or
            any(row["invariant"] != ("safe" if row["kind"] == "implication" else "candidateInvariant")
                for row in saved["results"])):
        raise ValueError("safety archive must prove the actual candidate and safety goal")
    return saved, inputs


def campaign(manifest, out, selected=None, jobs=None, timeout=90):
    if out.exists():
        raise ValueError("fresh campaign output required")
    config = json.loads(manifest.read_text())
    if config.get("schema") != "gambit-induction-matrix.v1":
        raise ValueError("unsupported induction manifest")
    version = _task_check_output(["quint", "--version"], text=True, timeout=10).strip()
    if version != config["quintVersion"]:
        raise ValueError("Quint version differs from pinned matrix")
    jar = Path.home() / ".quint/apalache-dist-0.62.1/apalache/lib/apalache.jar"
    if digest(jar) != config["apalacheJarSha256"]:
        raise ValueError("installed Apalache jar differs from pin")
    paths = [config["model"], config["protocol"]] + config.get("dependencies", [])
    context = json.loads(relative(ROOT, config["contextManifest"]).read_text())["contextInputs"]
    inputs = {str(manifest.resolve().relative_to(ROOT)): digest(manifest),
              config["contextManifest"]: digest(relative(ROOT, config["contextManifest"]))}
    for name in paths + list(context):
        path = relative(ROOT, name)
        observed = digest(path)
        if name in context and observed != context[name]:
            raise ValueError("source/paper context drift")
        inputs[name] = observed
    reused_safety = None
    if config.get("safetyReceipt"):
        reused_safety, archived_inputs = safety_obligations(ROOT, config["safetyReceipt"],
            [config["protocol"]] + config.get("dependencies", []))
        inputs.update(archived_inputs)
    framework = ("induction_matrix", "framework", "quint_backend", "model_schedule")
    if config.get("generatorContract") or config.get("adapterPrefix"):
        framework += ("generator_contract",)
    inputs.update({"src/gambit_smp/" + name + ".py": digest(ROOT / "src/gambit_smp" / (name + ".py"))
                   for name in framework})
    out.mkdir(parents=True)
    snapshots = {}
    for name in paths:
        target = out / Path(name).name
        target.write_bytes(relative(ROOT, name).read_bytes())
        snapshots[target.name] = digest(target)
    protocol = out / Path(config["protocol"]).name
    parsed = out / "protocol-ir.json"
    code, output, expired, _ = execute(["quint", "parse", str(protocol), "--out", str(parsed)], out, 10)
    if code or expired:
        raise ValueError("protocol IR parse failed: " + output[-500:])
    actions = action_members(json.loads(parsed.read_text()), config["protocolModule"], config["step"])
    if reused_safety and reused_safety["originalActions"] != actions:
        raise ValueError("safety receipt does not cover the same original action set")
    contract = None
    proof_ir = out / "proof-ir.json"
    if config.get("generatorContract") or config.get("adapterPrefix"):
        proof = out / Path(config["model"]).name
        code, output, expired, _ = execute(["quint", "typecheck", str(proof)], out, 10)
        if code or expired:
            raise ValueError("generator contract requires a typechecked model: " + output[-500:])
        code, output, expired, _ = execute(["quint", "parse", str(proof), "--out", str(proof_ir)], out, 10)
        if code or expired:
            raise ValueError("generator contract IR parse failed: " + output[-500:])
        if config.get("generatorContract"):
            contract = audit_generator(json.loads(proof_ir.read_text()),
                initializer=config["inductionInitializer"], invariant=config["invariant"],
                **config["generatorContract"])
            contract["proofIrSha256"] = digest(proof_ir)
    adapters = (proof_adapters(json.loads(proof_ir.read_text()), config["adapterModule"],
                config["adapterPrefix"], actions, config.get("queryStep"), config.get("ghostUpdates"))
                if config.get("adapterPrefix") else {})
    if config.get("proofKind") == "ranking" and not config.get("ghostUpdates"):
        raise ValueError("ranking requires exact pre-measure and advance-flag updates")
    chosen = actions if selected is None else selected
    if not chosen or len(set(chosen)) != len(chosen) or any(name not in actions for name in chosen):
        raise ValueError("selected transitions must be distinct real step branches")
    schedule = resources(available_processors(), physical_memory(), jobs)
    receipt = {"schema": "gambit-induction-matrix-result.v1", "accepted": False,
        "runtimeAdmitted": False, "releaseAdmitted": False, "temporalProved": False,
        "native": {"status": "not-run"}, "scope": "symbolic-partial-obligations-not-runtime-admission",
        "quintVersion": version, "apalacheJarSha256": digest(jar), "inputs": inputs,
        "modelInputs": snapshots, "protocolIrSha256": digest(parsed), "scheduling": schedule,
        "originalActions": actions, "selectedActions": chosen, "results": [],
        "initialProved": False, "preservationComplete": False, "implicationProved": False,
        "generatorCoverageProved": False, "inductiveSafetyAdmitted": False}
    receipt["generatorContract"] = contract
    receipt["proofKind"] = config.get("proofKind", "safety")
    receipt["reusedSafetyReceipt"] = config.get("safetyReceipt")
    receipt["safetyObligationsRevalidated"] = reused_safety is not None
    if proof_ir.exists():
        receipt["proofIrSha256"] = digest(proof_ir)
    receipt["stepAdapters"] = adapters
    receipt["ghostUpdatesChecked"] = bool(config.get("ghostUpdates"))
    snapshot = out / Path(config["model"]).name
    def run(kind, name, initializer, invariant, length):
        directory = out / "checks" / (kind + "-" + name)
        directory.mkdir(parents=True)
        target = adapters.get(name, name)
        if kind != "preservation" and name == config["step"]:
            target = config.get("queryStep", target)
        row, log = symbolic_check(snapshot, initializer=initializer, invariant=invariant,
            step=target, length=length, cwd=directory, timeout=timeout)
        row["originalStep"] = name
        log_path = out / (kind + "-" + name + ".log")
        log_path.write_text(log)
        row.update(kind=kind, case=snapshot.stem, variant="diagnostic",
            modelSha256=snapshots[snapshot.name], log=log_path.name, logSha256=digest(log_path))
        row["contextStable"] = (digest(jar) == receipt["apalacheJarSha256"] and
            all(digest(relative(ROOT, name)) == sha for name, sha in inputs.items()) and
            all(digest(out / name) == sha for name, sha in snapshots.items()) and
            digest(parsed) == receipt["protocolIrSha256"] and
            ("proofIrSha256" not in receipt or digest(proof_ir) == receipt["proofIrSha256"]))
        row["obligationProved"] = row["obligationProved"] and row["contextStable"]
        return row
    try:
        initial = run("initial", config["step"], config["initializer"], config["invariant"], 0)
        receipt["results"].append(initial)
        receipt["initialProved"] = initial["obligationProved"]
        if initial["obligationProved"]:
            for offset in range(0, len(chosen), schedule["parallelControls"]):
                batch = chosen[offset:offset + schedule["parallelControls"]]
                rows = run_batch(batch, lambda name: run("preservation", name,
                    config["inductionInitializer"], config["invariant"], 1))
                receipt["results"].extend(rows)
                for row in rows:
                    print(f"{row['step']}: {'PROVED' if row['obligationProved'] else 'DENY'} ({row['seconds']}s)", flush=True)
                if any(not row["obligationProved"] for row in rows):
                    break
            preservation = [row for row in receipt["results"] if row["kind"] == "preservation"]
            receipt["preservationComplete"] = (selected is None and set(chosen) == set(actions) and
                len(preservation) == len(actions) and all(row["obligationProved"] for row in preservation))
            if receipt["preservationComplete"]:
                row = run("implication", config["step"], config["inductionInitializer"], config["goal"], 0)
                receipt["results"].append(row)
                receipt["implicationProved"] = row["obligationProved"]
    finally:
        preservation = [row for row in receipt["results"] if row["kind"] == "preservation"]
        receipt["checkedActions"] = [row["originalStep"] for row in preservation]
        receipt["provedActions"] = [row["originalStep"] for row in preservation if row["obligationProved"]]
        receipt["failedActions"] = [row["originalStep"] for row in preservation if not row["obligationProved"]]
        receipt["uncoveredActions"] = [name for name in actions if name not in receipt["checkedActions"]]
        receipt["contextStable"] = (digest(jar) == receipt["apalacheJarSha256"] and
            all(digest(relative(ROOT, name)) == sha for name, sha in inputs.items()) and
            all(digest(out / name) == sha for name, sha in snapshots.items()) and
            digest(parsed) == receipt["protocolIrSha256"] and
            ("proofIrSha256" not in receipt or digest(proof_ir) == receipt["proofIrSha256"]))
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=ROOT / MANIFEST)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--step", action="append", help="filtered partial obligations, never complete preservation")
    parser.add_argument("--jobs", type=int)
    args = parser.parse_args()
    existed = args.out.resolve().exists()
    try:
        receipt = campaign(args.manifest.resolve(), args.out.resolve(), args.step, args.jobs)
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        out = args.out.resolve()
        if not existed and not (out / "receipt.json").exists():
            out.mkdir(parents=True, exist_ok=True)
            denied = {"schema": "gambit-induction-preflight-deny.v1", "accepted": False,
                "native": {"status": "not-run"}, "runtimeAdmitted": False,
                "releaseAdmitted": False, "temporalProved": False,
                "scope": "preflight-denial-not-protocol-counterexample",
                "errorType": type(error).__name__, "reason": portable(str(error)),
                "modelInputs": {path.name: digest(path) for path in out.glob("*.qnt")},
                "results": []}
            (out / "receipt.json").write_text(json.dumps(denied, indent=2) + "\n")
        raise SystemExit("INDUCTION-PREFLIGHT-DENY: " + portable(str(error))) from error
    if not receipt["contextStable"] or any(not row["obligationProved"] for row in receipt["results"]):
        raise SystemExit(1)
    print("INDUCTION-OBLIGATIONS-PROVED-NOT-NATIVE-ADMITTED")


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('induction-matrix')(main)

if __name__ == "__main__":
    main()
