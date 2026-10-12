"""Fail closed on native provider mismatches before expensive research runs."""
import json
import os
from pathlib import Path
import sys

from gambit_smp.process_observation import capture


REQUIRED_OPERATIONS = frozenset({"open-sources", "open-module", "native-result",
                                 "source-replace", "source-run", "close"})


def validate_description(description):
    if not isinstance(description, dict):
        raise ValueError("native provider description must be an object")
    if type(description.get("abi")) is not int or description["abi"] != 1:
        raise ValueError("native provider ABI 1 required")
    operations = description.get("operations")
    if (not isinstance(operations, list) or
            any(not isinstance(value, str) for value in operations) or
            len(operations) != len(set(operations))):
        raise ValueError("native provider operations must be unique strings")
    missing = REQUIRED_OPERATIONS - set(operations)
    if missing:
        raise ValueError("native provider lacks required operations: " + ", ".join(sorted(missing)))
    return {"abi": 1, "requiredOperations": sorted(REQUIRED_OPERATIONS),
            "observedOperations": sorted(operations), "status": "matched"}


def inspect_provider(api, binding):
    api, binding = Path(api).resolve(), Path(binding).resolve()
    code = ("import sys,json; sys.path[:0]=sys.argv[1:3]; "
            "from ascent_engine import Engine; e=Engine(); "
            "print(json.dumps(e.request({'operation':'describe'}))); e.shutdown()")
    environment = {**os.environ, "ASCENT_ENGINE_BACKEND": "api"}
    result = capture([sys.executable, "-I", "-B", "-c", code, str(api), str(binding.parent)],
                     api, 10, environment)
    if result.exit != 0 or result.timeout or result.group_quiescent is not True:
        raise ValueError("native provider probe failed or did not quiesce")
    try:
        description = json.loads(result.stdout)
    except (ValueError, TypeError) as error:
        raise ValueError("native provider probe returned invalid JSON") from error
    return validate_description(description)
