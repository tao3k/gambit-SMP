"""Observed host prerequisites, never tool success or execution authority."""
import errno
import math
import socket

SCHEMA = "host-loopback-observation.v1"
ERROR = "TLC loopback prerequisite denied before execution"


def execution_environment(root, inherited):
    """Keep required host identity without importing arbitrary shell controls."""
    result = {"GAMBIT_SMP_ROOT": str(root), "PYTHONDONTWRITEBYTECODE": "1",
              "PATH": "/usr/bin:/bin", "HOME": inherited.get("HOME", str(root)),
              "LANG": "C", "LC_ALL": "C"}
    for name in ("USER", "USERNAME"):
        value = inherited.get(name)
        if isinstance(value, str) and value and "\0" not in value:
            result[name] = value
    return result


def observe(steps):
    if not any(step["capability"] == "quint.verify" for step in steps):
        return None
    from gambit_smp.research_kernel import clock_epoch
    row = {"schema": SCHEMA, "operation": "ipv4-loopback-bind", "epoch": clock_epoch(),
           "available": False, "errno": None}
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
            listener.bind(("127.0.0.1", 0))
        row["available"] = True
    except OSError as error:
        row["errno"] = error.errno
    return row


def repaired(receipt, current, *, fresh_attempt=False):
    old = receipt.get("hostEnvironment")
    fields = {"schema", "operation", "epoch", "available", "errno"}
    if any(not isinstance(row, dict) or set(row) != fields for row in (old, current)):
        return False
    same_epoch = (isinstance(old["epoch"], str) and bool(old["epoch"])
                  and old["epoch"] == current["epoch"])
    spent, cap = receipt.get("wholeSeconds"), receipt.get("budgetSeconds")
    retained_cost = (type(spent) in (int, float) and math.isfinite(spent)
                     and type(cap) in (int, float) and math.isfinite(cap) and 0 < spent <= cap)
    clock_bound = retained_cost if fresh_attempt is True else same_epoch
    matched = (old["schema"] == current["schema"] == SCHEMA
               and old["operation"] == current["operation"] == "ipv4-loopback-bind"
               and clock_bound
               and old["available"] is False and type(old["errno"]) is int
               and old["errno"] in {errno.EPERM, errno.EACCES}
               and current["available"] is True and current["errno"] is None)
    child_prelaunch = (receipt.get("schema") == "evidence-recipe-run.v1"
                       and receipt.get("steps") == [] and receipt.get("error") == ERROR)
    outer_prelaunch = (receipt.get("schema") == "sealed-research-run.v1"
                       and receipt.get("executionLaunched") is False
                       and receipt.get("childReceiptSha256") is None and receipt.get("denial") == ERROR)
    return matched and receipt.get("outcome") == "DENY" and (child_prelaunch or outer_prelaunch)
