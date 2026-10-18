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
    group_probes: tuple[str, ...] = ()


def probe_group(pid, deadline):
    """Only ESRCH proves absence; transient denied/interrupted probes are unknown."""
    probes = []
    end = min(deadline, time.monotonic() + 0.05)
    while True:
        try:
            os.killpg(pid, 0)
        except ProcessLookupError:
            probes.append("absent")
            return True, tuple(probes)
        except PermissionError:
            probes.append("permission-denied")
        except InterruptedError:
            probes.append("interrupted")
        else:
            probes.append("present")
            return False, tuple(probes)
        remaining = end - time.monotonic()
        if remaining <= 0:
            return None, tuple(probes)
        time.sleep(min(0.01, remaining))


def communicate_progress(process, window, progress):
    """Renew only for a strictly increasing completed-work counter."""
    last, completed = time.monotonic(), 0

    def observe(stdout, stderr):
        nonlocal last, completed
        text = lambda value: value.decode(errors="replace") if isinstance(value, bytes) else value or ""
        count = progress(text(stdout), text(stderr))
        if type(count) is not int or count < 0:
            raise ValueError("nonnegative completed-work count required")
        if count > completed:
            completed, last = count, time.monotonic()

    while True:
        remaining = window - (time.monotonic() - last)
        if remaining <= 0:
            raise subprocess.TimeoutExpired(process.args, window)
        try:
            stdout, stderr = process.communicate(timeout=min(0.25, remaining))
            observe(stdout, stderr)
            return stdout, stderr
        except subprocess.TimeoutExpired as error:
            observe(error.output, error.stderr)


def capture(argv, cwd, budget, environment, *, diagnostic=None, progress=None, recorder=None):
    if budget <= 0:
        raise ValueError("positive process budget required")
    started = time.monotonic()
    timestamp = datetime.now(timezone.utc).isoformat()
    token = os.urandom(16).hex()
    if recorder is not None:
        recorder("planned", token, {"argv": [str(arg) for arg in argv], "cwd": str(cwd)})
    try:
        process = subprocess.Popen(argv, cwd=cwd, env=environment, stdin=subprocess.DEVNULL,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, start_new_session=True)
    except OSError:
        if recorder is not None:
            recorder("spawn-failed", token, {})
        raise
    timeout = False
    try:
        if recorder is not None:
            recorder("started", token, {"pid": process.pid})
        if progress is not None:
            if diagnostic is not None:
                raise ValueError("progress and stack-sampling transports must be selected separately")
            stdout, stderr = communicate_progress(process, budget, progress)
        elif diagnostic is not None:
            try:
                stdout, stderr = process.communicate(timeout=min(budget, diagnostic["afterSeconds"]))
            except subprocess.TimeoutExpired:
                remaining = budget - (time.monotonic() - started)
                if remaining > 0:
                    from gambit_smp.stack_observation import sample
                    sample(process, cwd, min(remaining, 5), environment, diagnostic)
                remaining = budget - (time.monotonic() - started)
                if remaining <= 0:
                    raise subprocess.TimeoutExpired(argv, budget)
                stdout, stderr = process.communicate(timeout=remaining)
        else:
            stdout, stderr = process.communicate(timeout=budget)
    except subprocess.TimeoutExpired:
        timeout = True
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = process.communicate()
    except BaseException:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.communicate()
        raise
    quiescent, probes = probe_group(process.pid, started + budget)
    return Observation(stdout, stderr, process.returncode, timeout, time.monotonic() - started,
                       process.pid, timestamp, datetime.now(timezone.utc).isoformat(), quiescent, probes)


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
        try:
            observed = capture(job["argv"], job["cwd"], ceiling, job["environment"])
        except OSError as error:
            return {"started": False, "queuedSeconds": queued, "deadlineExpired": False,
                    "processBudgetSeconds": ceiling, "observation": None,
                    "launchError": {"type": type(error).__name__, "message": str(error)}}
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


def main():
    """Host-requested process observation only; not a research capability."""
    import argparse
    import json
    from pathlib import Path
    from gambit_smp.framework import ROOT, available_processors
    from gambit_smp.artifact_storage import runtime_output
    from gambit_smp.recipes import fields, read_json
    parser = argparse.ArgumentParser(description=main.__doc__)
    parser.add_argument("request", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    args.out = runtime_output(ROOT, args.out)
    value = read_json(args.request)
    fields(value, ("schema", "budgetSeconds", "jobs"))
    if value["schema"] != "process-observation-batch.v1" or not isinstance(value["jobs"], list) or not value["jobs"]:
        raise ValueError("explicit nonempty process observation batch required")
    jobs = []
    for job in value["jobs"]:
        fields(job, ("argv", "cwd", "budgetSeconds"))
        if (not isinstance(job["argv"], list) or not job["argv"]
                or any(not isinstance(arg, str) or "\0" in arg for arg in job["argv"])):
            raise ValueError("explicit process argv required")
        jobs.append({"argv": job["argv"], "cwd": Path(job["cwd"]).resolve(strict=True),
                     "environment": dict(os.environ), "budget": job["budgetSeconds"]})
    args.out.mkdir(parents=True, exist_ok=False)
    (args.out / "request.json").write_text(json.dumps(value, indent=2) + "\n")
    result = capture_batch(jobs, workers=min(available_processors(), len(jobs)), budget=value["budgetSeconds"])
    result.update(scope="process-observation-only", runtimeAdmitted=False)
    (args.out / "receipt.json").write_text(json.dumps(result, indent=2) + "\n")
    for index, row in enumerate(result["runs"]):
        observed = row["observation"]
        print(json.dumps({"job": index, "started": row["started"], "observation": observed}), flush=True)
    return 0 if all(row["started"] and row["observation"]["exit"] == 0
                    and row["observation"]["timeout"] is False
                    and row["observation"]["group_quiescent"] is True for row in result["runs"]) else 1


if __name__ == "__main__":
    raise SystemExit(main())
