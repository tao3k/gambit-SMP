"""Shared execution primitives; protocol adapters own semantic admission."""
from datetime import datetime, timezone
import argparse
import hashlib
import math
import os
from pathlib import Path
import signal
import shlex
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from contextvars import ContextVar

_path_root = ContextVar('checked_repository_path_root', default=None)


@contextmanager
def path_resolution(root):
    """Reuse a canonical root only; every child path is still resolved afresh."""
    root = Path(root).resolve(strict=True)
    token = _path_root.set(root)
    try:
        yield root
    finally:
        _path_root.reset(token)
        if root.resolve(strict=True) != root:
            raise ValueError('repository root became a path alias')


def resolved_root(root):
    root = Path(root)
    scope = _path_root.get()
    if scope is not None and root.is_absolute() and '..' not in root.parts and root.is_relative_to(scope):
        return root
    return root.resolve()

def project_root():
    """Find research data separately from the installed Python package."""
    explicit = os.environ.get("GAMBIT_SMP_ROOT")
    candidates = ([Path(explicit)] if explicit else
                  [Path.cwd(), *Path.cwd().parents, Path(__file__).resolve().parents[2]])
    for candidate in candidates:
        if ((candidate / "models/gambit/cases.json").is_file()
                and (candidate / "evidence").is_dir()):
            return candidate.resolve()
    raise ValueError("research checkout not found; use gambit-smp --root PATH COMMAND")


ROOT = project_root()


def positive_int(value):
    try:
        number = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("positive integer required") from error
    if number <= 0:
        raise argparse.ArgumentTypeError("positive integer required")
    return number


def available_processors():
    query = getattr(os, "process_cpu_count", os.cpu_count)
    count = query() or 1
    affinity = getattr(os, "sched_getaffinity", None)
    if affinity is not None:
        try:
            count = min(count, len(affinity(0)))
        except OSError:
            pass
    return max(1, count)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(root, name):
    if not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts:
        raise ValueError("relative evidence path required")
    root = resolved_root(root)
    path = (root / name).resolve()
    path.relative_to(root)
    return path


def parallel_jobs(items, worker, jobs, timeout):
    if jobs <= 0 or timeout <= 0:
        raise ValueError("positive parallel capacity and whole budget required")
    deadline = time.monotonic() + timeout
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = [pool.submit(worker, item, deadline) for item in items]
        return [future.result() for future in futures]


def apply_untracked_patch(root, data, allowed):
    if not data:
        raise ValueError("empty patch")
    command = ["git", "--git-dir=/dev/null", "apply"]
    stats = subprocess.run(command + ["--numstat", "-z"], input=data,
                           cwd=root, capture_output=True, check=True, timeout=10).stdout
    names = []
    for row in stats.decode().split("\0"):
        if not row:
            continue
        added, removed, name = row.split("\t", 2)
        target = (root / name).resolve()
        if (not added.isdecimal() or not removed.isdecimal() or name not in allowed
            or Path(name).is_absolute() or not target.is_relative_to(root.resolve())
            or not target.is_file() or name in names):
            raise ValueError("patch must remain inside unique allowed existing files")
        names.append(name)
    if not names:
        raise ValueError("empty patch")
    for arguments in (("--check",), ()):
        subprocess.run(command + ["--whitespace=error", *arguments], input=data,
                       cwd=root, capture_output=True, check=True, timeout=10)
    if any(not (root / name).is_file() for name in names):
        raise ValueError("patch cannot remove a file")
    return {name: digest(root / name) for name in names}


def snapshot_fixture(source, out):
    content = source.read_bytes()
    target = out / source.name
    with target.open("xb") as stream:
        stream.write(content)
    if source.read_bytes() != content:
        raise ValueError("fixture changed during snapshot")
    return target


def execute(argv, cwd, timeout, env=None, metadata=None, *, completion_check=None, completion_grace=0,
            progress_check=None, on_spawn=None, process_recorder=None):
    if metadata is not None and not isinstance(metadata, dict):
        raise ValueError("execution metadata must be a mutable dictionary")
    if isinstance(timeout, bool) or not math.isfinite(timeout) or timeout <= 0:
        raise ValueError("positive finite execution timeout required")
    if (isinstance(completion_grace, bool) or not math.isfinite(completion_grace)
            or completion_grace < 0):
        raise ValueError("nonnegative finite finalization grace required")
    start = time.monotonic()
    token = os.urandom(16).hex()
    if process_recorder is not None:
        process_recorder("planned", token, {"argv": [str(arg) for arg in argv], "cwd": str(cwd)})
    try:
        process = subprocess.Popen(argv, cwd=cwd, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, text=True, start_new_session=True, env=env)
    except OSError:
        if process_recorder is not None:
            process_recorder("spawn-failed", token, {})
        raise
    if metadata is not None:
        metadata.update(pid=process.pid, startedAt=datetime.now(timezone.utc).isoformat())
    timed_out = False
    try:
        if process_recorder is not None:
            process_recorder("started", token, {"pid": process.pid})
        if on_spawn is not None:
            on_spawn(process.pid)
        if progress_check is None:
            output, _ = process.communicate(timeout=timeout)
        else:
            from gambit_smp.process_observation import communicate_progress
            output, _ = communicate_progress(process, timeout, progress_check,
                                              recorder=process_recorder, token=token)
    except subprocess.TimeoutExpired:
        try:
            completed = completion_check is not None and completion_grace > 0 and completion_check()
        except BaseException:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.communicate()
            raise
        if metadata is not None:
            metadata.update(**({"wallBudgetExceeded": True} if progress_check is None
                               else {"idleWatchdogExceeded": True}), finalizationGraceGranted=completed)
        if completed:
            finalization_started = time.monotonic()
            try:
                output, _ = process.communicate(timeout=completion_grace)
            except subprocess.TimeoutExpired:
                timed_out = True
            if metadata is not None:
                metadata["finalizationSeconds"] = time.monotonic() - finalization_started
        else:
            timed_out = True
        if timed_out:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            output, _ = process.communicate()
    except BaseException:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.communicate()
        raise
    if metadata is not None:
        metadata["endedAt"] = datetime.now(timezone.utc).isoformat()
        metadata["parentReaped"] = process.returncode is not None
        try:
            os.killpg(process.pid, 0)
        except ProcessLookupError:
            metadata["processGroupQuiescent"] = True
        except PermissionError:
            metadata["processGroupQuiescent"] = None
        else:
            metadata["processGroupQuiescent"] = False
    return process.returncode, output, timed_out, time.monotonic() - start


def gnu_compiler(gcc):
    compiler = str(gcc.resolve(strict=True))
    environment = {key: val for key, val in os.environ.items()
        if key not in ("SDKROOT", "LIBRARY_PATH", "CPATH")}
    environment["PATH"] = os.pathsep.join((str(gcc.absolute().parent),
        "/usr/bin", "/bin", "/usr/sbin", "/sbin"))
    code, output, timeout, _ = execute([compiler, "--version"], ROOT, 10, env=environment)
    if code != 0 or timeout or "gcc" not in output.lower() or "clang" in output.lower():
        raise ValueError("GNU GCC required")
    return compiler, environment, output


def gnu_build_driver(runtime, compiler):
    driver = runtime / "bin/gambuild-C"
    bindings = [line.split("=", 1)[1] for line in driver.read_text().splitlines()
                if line.startswith("C_COMPILER=")]
    if len(bindings) != 1:
        raise ValueError("build driver must bind one configured compiler")
    words = shlex.split(bindings[0])
    if len(words) != 1:
        raise ValueError("build driver compiler must be one executable")
    configured = words[0] if Path(words[0]).is_absolute() else shutil.which(
        words[0], path=os.pathsep.join((str(Path(compiler).parent), "/usr/bin", "/bin")))
    if not configured or Path(configured).resolve() != Path(compiler).resolve():
        raise ValueError("build driver differs from admitted GNU GCC")
    helpers = {name: digest(runtime / "bin" / name) for name in (
        "gambit-native-object-cache", "gambit-static-object-reuse", "gambit-file-sha256")
        if (runtime / "bin" / name).is_file()}
    reuse = os.environ.get("GAMBIT_DARWIN_NATIVE_OBJECTS") == "1"
    if reuse and "gambit-native-object-cache" not in helpers:
        raise ValueError("requested native object reuse helper is missing")
    return {"relativePath": "bin/gambuild-C", "sha256": digest(driver),
            "configuredCompilerVerified": True, "helperSha256": helpers,
            "nativeObjectReuseRequested": reuse}
