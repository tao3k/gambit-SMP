"""Observe an explicit opam tool environment; never eval shell output or install."""
import argparse
from dataclasses import asdict
import json
import math
import os
from pathlib import Path
import re
import shutil
import time

from gambit_smp.framework import ROOT, digest, positive_int
from gambit_smp.process_observation import capture


def declaration(record):
    required = {"schema", "switch", "tool", "versionArguments", "variables"}
    if not isinstance(record, dict) or set(record) != required or record["schema"] != "opam-tool-discovery.v1":
        raise ValueError("explicit opam tool discovery declaration required")
    switch, tool = record["switch"], record["tool"]
    if not isinstance(switch, str) or not switch.strip() or any(c in switch for c in "\0\n\r"):
        raise ValueError("explicit nonempty switch required")
    if not isinstance(tool, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.+-]*", tool):
        raise ValueError("tool must be an executable basename, not shell syntax or a path")
    arguments = record["versionArguments"]
    if arguments not in (["--version"], ["-version"], ["-V"], ["-vV"],
                          ["-dumpversion"], ["-dumpfullversion"], ["-dumpfullversion", "-dumpversion"]):
        raise ValueError("supported information-only version probe required; not arbitrary argv")
    variables = record["variables"]
    if (not isinstance(variables, list)
            or any(not isinstance(var, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.:+-]*", var)
                   for var in variables) or len(set(variables)) != len(variables)):
        raise ValueError("unique read-only opam variable names required")
    return record


def observe(record, *, cwd, budget=15, environment=None, opam=None):
    """Version probes execute trusted host binaries, not a sandbox or model run."""
    declaration(record)
    if type(budget) not in (int, float) or not math.isfinite(budget) or budget <= 0:
        raise ValueError("positive finite whole discovery budget required")
    started = time.monotonic()
    env = dict(os.environ if environment is None else environment)
    located = str(opam) if opam is not None else shutil.which("opam", path=env.get("PATH", os.defpath))
    result = {"schema": "opam-tool-observation.v1", "declaration": record,
              "budgetSeconds": budget, "probes": [], "tool": None, "launchPrefix": None,
              "manager": None, "identityStable": False, "complete": False,
              "identityScope": "manager-and-tool-bytes-only; not dependency/model closure",
              "error": None, "modelExecuted": False, "executionAuthorized": False,
              "inheritedContext": {key: env[key] for key in ("PATH", "OPAMROOT", "OPAMSWITCH") if key in env}}

    def probe(operation, argv):
        remaining = budget - (time.monotonic() - started)
        if remaining <= 0:
            raise TimeoutError("whole opam discovery deadline exhausted")
        observed = capture(argv, Path(cwd), remaining, env)
        result["probes"].append({"operation": operation, "argv": argv,
                                 "processBudgetSeconds": remaining, **asdict(observed)})
        if observed.exit != 0 or observed.timeout or observed.group_quiescent is not True:
            raise ValueError("opam probe did not complete: " + operation)
        return observed.stdout.strip()

    try:
        if located is None:
            raise FileNotFoundError("opam is not on the declared PATH")
        manager = Path(located).resolve(strict=True)
        if not manager.is_file() or not os.access(manager, os.X_OK):
            raise ValueError("executable opam manager required")
        manager_sha = digest(manager)
        result["manager"] = {"declared": located, "path": str(manager), "sha256": manager_sha}
        result["manager"]["version"] = probe("manager-version", [str(manager), "--version"])
        switch = "--switch=" + record["switch"]
        directory = probe("switch-bin", [str(manager), "var", switch, "bin"])
        if not directory or "\n" in directory or not Path(directory).is_absolute():
            raise ValueError("opam returned no unique absolute switch bin directory")
        declared_tool = Path(directory) / record["tool"]
        tool = declared_tool.resolve(strict=True)
        if not tool.is_file() or not os.access(tool, os.X_OK):
            raise ValueError("executable tool in the selected switch required")
        tool_sha = digest(tool)
        result["tool"] = {"declared": str(declared_tool), "path": str(tool), "sha256": tool_sha}
        prefix = [str(manager), "exec", switch, "--set-switch", "--", str(tool)]
        result["launchPrefix"] = prefix
        result["tool"]["version"] = probe("tool-version", [*prefix, *record["versionArguments"]])
        result["variables"] = {name: probe("variable:" + name, [str(manager), "var", switch, name])
                               for name in record["variables"]}
        result["identityStable"] = (manager.resolve(strict=True) == manager and digest(manager) == manager_sha
                                    and declared_tool.resolve(strict=True) == tool and digest(tool) == tool_sha)
        if not result["identityStable"]:
            raise ValueError("opam manager or selected tool changed during discovery")
        if time.monotonic() - started >= budget:
            raise TimeoutError("whole opam discovery deadline exhausted")
        result["complete"] = True
    except (OSError, ValueError, TimeoutError) as error:
        result["error"] = {"type": type(error).__name__, "message": str(error)}
    result["seconds"] = time.monotonic() - started
    return result


def main():
    from gambit_smp.artifact_storage import runtime_argument
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--request", type=Path, required=True)
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--opam", type=Path, help="explicit manager, otherwise resolve declared PATH")
    parser.add_argument("--timeout", type=positive_int, default=15)
    args = parser.parse_args()
    if args.out.exists():
        parser.error("new output directory required; observations are never overwritten")
    request = args.request.resolve(strict=True)
    before = digest(request)
    record = declaration(json.loads(request.read_text()))
    result = observe(record, cwd=ROOT, budget=args.timeout, opam=args.opam)
    result["request"] = {"path": str(request), "sha256": before}
    if digest(request) != before:
        result.update(complete=False, error={"type": "ValueError", "message": "discovery declaration changed"})
    args.out.mkdir(parents=True, exist_ok=False)
    receipt = args.out / "observation.json"
    receipt.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"complete": result["complete"], "tool": result["tool"],
                      "launchPrefix": result["launchPrefix"], "seconds": result["seconds"],
                      "error": result["error"], "receipt": str(receipt), "sha256": digest(receipt)}))
    return 0 if result["complete"] else 2


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('tool-environment')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('tool-environment', main))
