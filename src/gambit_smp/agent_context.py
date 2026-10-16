"""Emit and recheck an Agent handoff linked to the current evidence catalog."""
import argparse
import json
from pathlib import Path

from gambit_smp.framework import ROOT, digest, positive_int


def markdown(result):
    brief = result["taskBrief"]
    graph = result["agentGraph"]
    validation = result["frameworkValidation"]
    lines = ["# Agentic AI Evidence Context: " + brief["task"], "",
             "Snapshot: `" + graph["snapshot"] + "`.",
             "Checkout: `" + graph["checkout"]["root"] + "` at `" + graph["checkout"]["head"] + "`.", "",
             "Framework validation: **" + validation["status"] + "**; profile `" +
             validation.get("profile", "none") + "`, " + str(validation.get("testsRun", 0)) + " tests.",
             "Read [the complete information graph](graph.json) and [the review receipt](review.json)",
             "for exact source bindings, recorded outcomes and open premises. Paths and Git status are recorded per input.", "",
             "## Reusable Evidence", "", "| Claim | Receipt | Binding |", "| --- | --- | --- |"]
    for entry in brief["reusable"]:
        lines.append("| `" + entry["claim"] + "` | `" + str(entry["path"]) + "` | " + entry["binding"] + " |")
    if not brief["reusable"]:
        lines.append("| None | | |")
    lines.extend(["", "## Open Premises", ""])
    lines.extend("- `" + claim + "`" for claim in brief["openPremises"])
    lines.extend(["", "## Invalidated Or Unverified", ""])
    lines.extend("- `" + entry["receipt"] + "`: " + ", ".join(entry["reasons"])
                 for entry in brief["invalidated"] + brief["unverified"])
    lines.extend(["", "## Recorded Failed Routes", ""])
    lines.extend("- `" + entry["id"] + "`: " + entry["routeDecision"] + "; `" + entry["receipt"] + "`."
                 for entry in brief["knownFailedRoutes"])
    lines.extend(["", "## Recorded Audit Suggestions", "",
                  "These historical suggestions are not a required action order or execution policy.", ""])
    lines.extend("- `" + issue["id"] + "`: " + issue["next"] for issue in brief.get("relatedAuditIssues", []))
    lines.extend(["", "## Source References", ""])
    lines.extend("- `" + location + "`" for location in brief.get("sourceReferences", []))
    lines.extend(["", "## Engineering Gates", ""])
    lines.extend("- " + gate + ": " + status for gate, status in brief["gates"].items())
    lines.extend(["", "## Dependency Overview", "", "The overview shows the target claim's immediate links.",
                  "The JSON graph also includes catalog pointers, logs, counterexamples, inputs, reports and papers.",
                  "", "```mermaid", mermaid_text(graph).rstrip(), "```", "",
                  "This context does not grant execution authorization. Host authorization remains independent.",
                  "Generated local context must be rechecked after input changes; Git status does not imply runtime acceptance.", ""])
    return "\n".join(lines)


def mermaid_text(graph):
    from gambit_smp.review_graph import mermaid
    return mermaid(graph)


def write_bundle(out, result):
    from gambit_smp.review_graph import validate
    validate(result["agentGraph"])
    contents = {"review.json": json.dumps(result, indent=2) + "\n",
                "graph.json": json.dumps(result["agentGraph"], indent=2) + "\n",
                "context.md": markdown(result), "graph.mmd": mermaid_text(result["agentGraph"])}
    artifacts = {}
    for name, content in contents.items():
        path = out / name
        with path.open("x") as stream:
            stream.write(content)
        artifacts[name] = {"path": name, "sha256": digest(path)}
    manifest = {"schema": "gambit-agent-context.v1", "task": result["taskBrief"]["task"],
                "snapshot": result["agentGraph"]["snapshot"],
                "graphSha256": result["agentGraph"]["graphSha256"], "artifacts": artifacts,
                "frameworkValidated": result["frameworkValidation"]["frameworkValidated"],
                "validationReceipt": result["frameworkValidation"].get("receiptPath"),
                "executionAuthorized": False, "runtimeAdmitted": False}
    with (out / "context.json").open("x") as stream:
        stream.write(json.dumps(manifest, indent=2) + "\n")
    read_bundle(out)
    return manifest


def read_bundle(path):
    from gambit_smp.review_graph import validate
    path = Path(path).resolve()
    if path.is_dir():
        path = path / "context.json"
    manifest = json.loads(path.read_text())
    if manifest.get("schema") != "gambit-agent-context.v1" or set(manifest["artifacts"]) != {
            "review.json", "graph.json", "context.md", "graph.mmd"}:
        raise ValueError("unknown or incomplete Agent context bundle")
    for name, artifact in manifest["artifacts"].items():
        if artifact["path"] != name or digest(path.parent / name) != artifact["sha256"]:
            raise ValueError("Agent context artifact identity mismatch: " + name)
    review = json.loads((path.parent / "review.json").read_text())
    graph = json.loads((path.parent / "graph.json").read_text())
    validate(graph)
    if (graph != review["agentGraph"] or graph["graphSha256"] != manifest["graphSha256"] or
            graph["snapshot"] != manifest["snapshot"] or graph["task"] != manifest["task"]):
        raise ValueError("Agent context graph differs from its review")
    if (manifest.get("executionAuthorized") is not False or manifest.get("runtimeAdmitted") is not False or
            manifest["frameworkValidated"] != graph["frameworkValidated"] or
            manifest["frameworkValidated"] != review["frameworkValidation"]["frameworkValidated"]):
        raise ValueError("Agent context admission status mismatch")
    return manifest, review


def recheck(root, path):
    from gambit_smp.ascent_program import engine_api
    from gambit_smp.review_graph import checkout
    from gambit_smp.review_validation import changed_inputs, load
    manifest, review = read_bundle(path)
    inputs = {**review["inputs"], **review["receiptCurrentInputs"]}
    changed = changed_inputs(root, inputs)
    with engine_api() as (_, engine_inputs):
        backend_changed = engine_inputs != review["engineInputs"]
    state = checkout(root, inputs)
    previous = review["agentGraph"]["checkout"]
    checkout_changed = any(state[key] != previous[key] for key in ("root", "head", "branch"))
    checkout_changed = checkout_changed or state.get("submodules", {}) != previous.get("submodules", {})
    validation = load(root, manifest["validationReceipt"], review["inputs"], engine_inputs) if manifest.get("validationReceipt") else {
        "status": "not-supplied", "frameworkValidated": False}
    return {"status": "STALE" if (changed or backend_changed or checkout_changed or validation["status"] == "STALE") else "CURRENT",
            "task": manifest["task"], "snapshot": manifest["snapshot"],
            "changedInputs": changed, "backendChanged": backend_changed,
            "checkoutChanged": checkout_changed, "frameworkValidation": validation["status"],
            "frameworkValidated": validation["frameworkValidated"] and not changed and not backend_changed and not checkout_changed,
            "executionAuthorized": False, "runtimeAdmitted": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--model")
    mode.add_argument("--read", type=Path, help="recheck a previously emitted Agent context")
    parser.add_argument("--out", type=Path)
    parser.add_argument("--validation", type=Path, help="reuse an unchanged validation receipt")
    parser.add_argument("--profile", choices=("evidence-review", "full"), default="evidence-review")
    parser.add_argument("--timeout", type=positive_int, default=300)
    parser.add_argument("--history-lineage", help="stable caller-owned task/branch/policy journal label")
    args = parser.parse_args()
    if args.read:
        if args.out or args.validation or args.history_lineage:
            parser.error("--read does not accept --out or --validation")
        summary = recheck(ROOT.resolve(), args.read)
        print(json.dumps(summary, sort_keys=True))
        return 0 if summary["status"] == "CURRENT" and summary["frameworkValidated"] else 2
    if args.out is None or args.out.exists():
        parser.error("--model requires a new --out directory")
    from gambit_smp.artifact_storage import runtime_output
    args.out = runtime_output(ROOT, args.out)
    args.out.mkdir(parents=True, exist_ok=False)
    from gambit_smp.ascent_review import run_review
    from gambit_smp.review_validation import supervise
    validation_path = args.validation
    if validation_path is None:
        validation_path, _ = supervise(ROOT.resolve(), args.profile, args.model,
                                       args.out / "validation", args.timeout)
    result = run_review(ROOT.resolve(), task_model=args.model,
                        validation_path=validation_path, validation_profile=args.profile,
                        history_lineage=args.history_lineage)
    manifest = write_bundle(args.out, result)
    print(json.dumps({"task": args.model, "snapshot": manifest["snapshot"],
                      "contextPath": str(args.out / "context.json"),
                      "agentInstructionsPath": str(args.out / "context.md"),
                      "graphPath": str(args.out / "graph.json"),
                      "graphSha256": manifest["graphSha256"],
                      "frameworkValidation": result["frameworkValidation"]["status"],
                      "frameworkValidated": manifest["frameworkValidated"],
                      "reusableReceipts": result["taskBrief"]["metrics"]["reusableReceipts"],
                      "openPremises": result["taskBrief"]["openPremises"],
                      "executionAuthorized": False}, sort_keys=True))
    return 0 if manifest["frameworkValidated"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
