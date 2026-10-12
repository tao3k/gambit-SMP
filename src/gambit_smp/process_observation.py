"""Bounded process observations with distinct stdout, stderr and final exit."""
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import os
import math
import signal
import subprocess
import time


@dataclass(frozen=True)
class Observation:
    stdout: str
    stderr: str
    exit: int
    timeout: bool
    seconds: float
    pid: int
    started_at: str
    ended_at: str
    group_quiescent: bool | None


def capture(argv, cwd, budget, environment):
    if budget <= 0:
        raise ValueError("positive process budget required")
    started = time.monotonic()
    timestamp = datetime.now(timezone.utc).isoformat()
    process = subprocess.Popen(argv, cwd=cwd, env=environment, stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, start_new_session=True)
    timeout = False
    try:
        stdout, stderr = process.communicate(timeout=budget)
    except subprocess.TimeoutExpired:
        timeout = True
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = process.communicate()
    try:
        os.killpg(process.pid, 0)
    except ProcessLookupError:
        quiescent = True
    except PermissionError:
        quiescent = None
    else:
        quiescent = False
    return Observation(stdout, stderr, process.returncode, timeout, time.monotonic() - started,
                       process.pid, timestamp, datetime.now(timezone.utc).isoformat(), quiescent)


def capture_batch(jobs, *, workers, budget):
    """Threaded process transport under one deadline, including queue time.

    Each job supplies argv/cwd/environment/budget. Threads only supervise
    independent child processes; no Library runtime crosses an OS thread.
    A queued job that misses the deadline has no invented exit or PID.
    """
    if type(workers) is not int or workers <= 0:
        raise ValueError("positive worker count required")
    if isinstance(budget, bool) or not math.isfinite(budget) or budget <= 0:
        raise ValueError("positive finite batch budget required")
    jobs = list(jobs)
    for job in jobs:
        ceiling = job["budget"]
        if isinstance(ceiling, bool) or not math.isfinite(ceiling) or ceiling <= 0:
            raise ValueError("positive finite job budget required")
    started = time.monotonic()
    deadline = started + budget

    def launch(job):
        queued = time.monotonic() - started
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return {"started": False, "queuedSeconds": queued,
                    "deadlineExpired": True, "processBudgetSeconds": None,
                    "observation": None}
        ceiling = min(job["budget"], remaining)
        observed = capture(job["argv"], job["cwd"], ceiling, job["environment"])
        return {"started": True, "queuedSeconds": queued,
                "deadlineExpired": False, "processBudgetSeconds": ceiling,
                "observation": asdict(observed)}

    if jobs:
        with ThreadPoolExecutor(max_workers=min(workers, len(jobs))) as pool:
            runs = list(pool.map(launch, jobs))
    else:
        runs = []
    return {"workers": min(workers, len(jobs)), "budgetSeconds": budget,
            "seconds": time.monotonic() - started, "runs": runs}
