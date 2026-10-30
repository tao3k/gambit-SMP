"""Bind the focused fairness variant to the original public Quint action IR."""
import argparse
import json
from pathlib import Path

from gambit_smp.framework import ROOT, digest
from gambit_smp.induction_matrix import action_members
from gambit_smp.protocol_evidence import portable


def focused_members(declarations, name, visiting=()):
    """Expand named disjunctions only; reject aliases and recursive wrappers."""
    if name in visiting:
        raise ValueError("recursive focused action disjunction")
    declaration = declarations.get(name, {})
    if declaration.get("qualifier") != "action":
        raise ValueError("focused branch must name an action")
    body = declaration.get("expr", {})
    if body.get("kind") == "name":
        raise ValueError("focused action aliases are unsupported")
    if body.get("opcode") != "actionAny":
        return [name]
    if body.get("kind") != "app" or not body.get("args"):
        raise ValueError("explicit nonempty focused disjunction required")
    result = []
    for branch in body["args"]:
        if branch.get("kind") != "name":
            raise ValueError("focused disjunction must use named actions")
        result.extend(focused_members(declarations, branch.get("name"), (*visiting, name)))
    if len(set(result)) != len(result):
        raise ValueError("duplicate expanded focused branch")
    return result


def audit(ir):
    modules = {item["name"]: item for item in ir.get("modules", [])}
    if set(modules) != {"gc_recursive_queue_wait", "gc_wakeup_fairness"}:
        raise ValueError("exact original and fairness modules required")
    original = action_members(ir, "gc_recursive_queue_wait", "step")
    if len(original) != 22 or "spuriousWake" not in original:
        raise ValueError("original 22-action identity required")
    base = modules["gc_recursive_queue_wait"]["declarations"]
    local = modules["gc_wakeup_fairness"]["declarations"]
    names = {item["name"] for item in base if "name" in item}
    if any(item.get("name") in names or item.get("kind") == "var" for item in local):
        raise ValueError("fairness module shadows original state or declarations")
    variant = action_members(ir, "gc_wakeup_fairness", "fullUnbounded")
    expected = ["wakeUnbounded" if name == "spuriousWake" else name for name in original]
    if variant != expected:
        raise ValueError("full fairness disjunction changed beyond wake replacement")
    declarations = {item["name"]: item for item in base + local if "name" in item}
    focused = focused_members(declarations, "stepUnbounded")
    bounded = focused_members(declarations, "stepBounded")
    expected_focus = ["copyWord", "startProbe", "probeEmptyQueue", "finishProbe",
                      "lockTermination", "probeRecheckQueue", "countOrRetry",
                      "registerWait", "resume", "wakeUnbounded"]
    if focused != expected_focus or not set(focused).issubset(variant):
        raise ValueError("focused Next is not the required full-protocol subrelation")
    if bounded != ["spuriousWake" if name == "wakeUnbounded" else name for name in focused]:
        raise ValueError("focused bounded control differs beyond wake replacement")
    return {"originalActions": original, "variantActions": variant,
            "replacedAction": "spuriousWake", "replacementAction": "wakeUnbounded",
            "importedOriginalBranches": 21, "fullDisjunctionCorrespondence": True,
            "focusedActions": focused, "focusedNext": "stepUnbounded",
            "fairnessAction": "fullUnbounded", "focusedSubrelationChecked": True,
            "fullNextChecked": False, "positiveResultTransfers": False,
            "wakeBodyEquivalenceProved": False, "sourceFairnessProved": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ir", type=Path, required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    args = parser.parse_args()
    observation = audit(json.loads(args.ir.read_text()))
    args.out.mkdir(parents=True, exist_ok=False)
    sources = ("gc_recursive_queue_wait.qnt", "gc_wakeup_fairness.qnt")
    record = {"schema": "gc-wakeup-fairness-ir-audit.v1", **observation,
              "accepted": False, "runtimeAdmitted": False, "releaseAdmitted": False,
              "temporalProved": False, "native": {"status": "not-run"}, "auditPassed": True,
              "modelInputs": {}, "results": [], "protocolIrSha256": digest(args.ir)}
    files = {"protocol-ir.json": args.ir}
    for name in sources:
        files[name] = ROOT / "models/gambit" / name
        record["modelInputs"][name] = digest(files[name])
    for name, source in files.items():
        (args.out / name).write_text(portable(source.read_text()))
    receipt = args.out / "receipt.json"
    receipt.write_text(json.dumps(record, indent=2) + "\n")
    files[receipt.name] = receipt
    archive = {"schema": "gambit-model-attempt-archive.v1", "archiveOnly": True,
               "accepted": False, "runtimeAdmitted": False, "releaseAdmitted": False,
               "files": {name: {"rawSha256": digest(source),
                                  "portableSha256": digest(args.out / name)}
                         for name, source in files.items()}}
    (args.out / "archive.json").write_text(json.dumps(archive, indent=2) + "\n")
    print("FAIRNESS-IR-CORRESPONDENCE-ONLY-NOT-SOURCE-ADMISSION")


from gambit_smp.task_entry import managed_tool as _managed_tool
main = _managed_tool('wakeup-fairness')(main)

if __name__ == '__main__':
    from gambit_smp.task_entry import tool_main
    raise SystemExit(tool_main('wakeup-fairness',main))
