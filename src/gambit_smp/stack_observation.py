"""Bounded Darwin sampling of an already-owned child, never runtime admission."""
import json
import os
from pathlib import Path
import signal
import subprocess
import time

from gambit_smp.framework import digest


def sample(process, cwd, budget, environment, diagnostic):
    directory = Path(diagnostic["directory"])
    tool = Path(diagnostic["tool"])
    report = directory / "stack-sample.txt"
    receipt = directory / "stack-sample.json"
    if report.exists() or receipt.exists():
        raise ValueError("fresh diagnostic observation paths required")
    if digest(tool) != diagnostic["toolSha256"]:
        raise ValueError("sealed Darwin sampling tool drift")
    if process.poll() is not None:
        receipt.write_text(json.dumps({"schema": "owned-child-stack-observation.v1",
            "status": "CHILD_COMPLETED", "runtimeAdmitted": False}) + "\n")
        return
    started = time.monotonic()
    argv = [str(tool), str(process.pid), "1", "-file", str(report)]
    child = subprocess.Popen(argv, cwd=cwd, env=environment,
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, start_new_session=True)
    timed_out = False
    try:
        stdout, stderr = child.communicate(timeout=budget)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = child.communicate()
    (directory / "stack-sample.stdout").write_text(stdout)
    (directory / "stack-sample.stderr").write_text(stderr)
    receipt.write_text(json.dumps({"schema": "owned-child-stack-observation.v1",
        "targetPid": process.pid, "argv": argv, "toolSha256": diagnostic["toolSha256"],
        "exit": child.returncode, "timeout": timed_out,
        "seconds": time.monotonic() - started,
        "reportSha256": digest(report) if report.is_file() else None,
        "runtimeAdmitted": False}, indent=2) + "\n")
    if digest(tool) != diagnostic["toolSha256"]:
        raise ValueError("Darwin sampling tool changed during observation")
