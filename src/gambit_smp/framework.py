"""Shared execution primitives; protocol adapters own semantic admission."""
from datetime import datetime, timezone
import argparse
import hashlib
import os
from pathlib import Path
import signal
import shlex
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor

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
    path = (root / name).resolve()
    path.relative_to(root.resolve())
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


def execute(argv, cwd, timeout, env=None, metadata=None):
    if timeout <= 0:
        raise ValueError("positive execution timeout required")
    start = time.monotonic()
    process = subprocess.Popen(argv, cwd=cwd, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True, start_new_session=True, env=env)
    if metadata is not None:
        metadata.update(pid=process.pid, startedAt=datetime.now(timezone.utc).isoformat())
    timed_out = False
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        output, _ = process.communicate()
    if metadata is not None:
        metadata["endedAt"] = datetime.now(timezone.utc).isoformat()
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
