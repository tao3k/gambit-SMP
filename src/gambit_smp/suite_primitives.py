"""Suite inventory, topology and exit contracts without feature producer imports."""
from math import isqrt
from pathlib import Path
import re
from contextlib import contextmanager
import json
import hashlib
import os
import shutil
from queue import Queue

from gambit_smp.framework import digest, relative


def check_runtime(runtime, identity):
    from gambit_smp.recipes import _leased_tree_checks, tree_identity
    fragments = {p.relative_to(runtime).as_posix() for p in (runtime / "lib").rglob("*.inc")
                 if p.is_file()}
    if not fragments.issubset(identity["sourceFiles"]):
        raise ValueError("runtime identity omits native source fragments")
    checks = _leased_tree_checks.get()
    inventory = tree_identity(runtime) if checks is not None and runtime in checks.roots else None
    def sha(name):
        if inventory is not None:
            # The held tree checker already resolved every link, checked the
            # root generation and observed every entry's inode/ctime. Regular
            # entries need no second deep realpath walk for each source file.
            row = inventory.get(name, {})
            if 'sha256' in row:return row['sha256']
        path = relative(runtime, name)
        if inventory is None:return digest(path)
        row = inventory.get(path.relative_to(runtime).as_posix(), {})
        if "sha256" not in row:
            raise ValueError("leased runtime file is absent from checked inventory")
        return row["sha256"]
    if any(sha(name) != expected for name, expected in identity["sourceFiles"].items()):
        raise ValueError("candidate input inventory changed")
    for field, name in (("binarySha256", "gsi/gsi"), ("gscSha256", "gsc/gsc"), ("librarySha256", "lib/libgambit.a")):
        if sha(name) != identity[field]:
            raise ValueError("candidate artifact changed: " + name)


def selected_files(root, selections, *, inventory="unit"):
    if inventory not in {"unit", "stress"}:
        raise ValueError("explicit unit or stress inventory required")
    root = root.resolve()
    files = set()
    for selection in selections:
        selected = relative(root, selection)
        if not selected.exists():
            raise ValueError("suite selection must exist inside upstream unit-tests")
        candidates = selected.rglob("*.scm") if selected.is_dir() else (selected,)
        files.update(path.relative_to(root) for path in candidates
                     if path.suffix == ".scm" and path.name != "#.scm"
                     and path.name.endswith("_stress.scm") == (inventory == "stress"))
    if not files:
        raise ValueError("empty suite selection")
    return sorted(files)


def runtime_view(runtime, mirror):
    mirror.mkdir(parents=True)
    for name in ("gsi", "gsc", "lib", "include", "bin"):
        (mirror / name).symlink_to(runtime / name, target_is_directory=True)
    tests = mirror / "tests"
    tests.mkdir()
    return tests


@contextmanager
def suite_workers(root, run, jobs):
    """Lease one bounded task-local pool; run directories contain receipts only.

    Slots retain bytes, never test success. Every requested execution still runs.
    The existing workspace lease also follows children after supervisor failure.
    """
    from gambit_smp.artifact_storage import workspace_lease
    from gambit_smp.workspace import bounded, task_output
    root, run = Path(root).resolve(), Path(run).resolve()
    if type(jobs) is not int or jobs < 1:
        raise ValueError('positive suite worker capacity required')
    tasks = root / '.cache/tasks'
    if run.is_relative_to(tasks):
        parts = run.relative_to(tasks).parts
        offset = 3 if len(parts) > 2 and parts[1] == 'processes' else 1
        if len(parts) <= offset or parts[offset] != 'runs':
            raise ValueError('suite observations require a task run')
        pool = tasks.joinpath(*parts[:offset], 'build', 'suite-tests')
    else:
        # Existing unscoped fixture consumers, including isolated unit controls.
        pool = root / '.cache/fixtures/suite-tests'
    pool = bounded(root, pool.relative_to(root))
    if task_output(root, pool) != pool:
        raise ValueError('suite workspace belongs to another task')
    pool.mkdir(parents=True, exist_ok=True)
    def identity(path):
        return [path.stat().st_dev, path.stat().st_ino]
    with workspace_lease(root, pool, identity(pool), identity_reader=identity):
        allowed = {'worker-' + str(index) for index in range(jobs)}
        # A reduced parallel budget must not allocate another generation. Old
        # inactive slots remain bounded by the largest admitted worker count.
        for path in pool.iterdir():
            if path.is_symlink() or not path.is_dir() or not re.fullmatch(r'worker-[0-9]+', path.name):
                raise ValueError('foreign entry in fixed suite workspace')
        slots = Queue()
        for name in sorted(allowed):
            slots.put(pool / name)
        yield slots


def _suite_worker_binding(runtime, copied, context):
    inputs = {}
    directories = set()
    for path in copied.rglob('*'):
        if path.is_symlink():
            raise ValueError('suite input aliases require explicit materialization')
        if path.is_file():
            inputs[path.relative_to(copied).as_posix()] = digest(path)
        elif path.is_dir():
            directories.add(path.relative_to(copied).as_posix())
    binding = dict(runtime=str(runtime), inputs=inputs,
                   artifacts={name: digest(runtime / name) for name in
                              ('gsi/gsi', 'gsc/gsc', 'lib/libgambit.a', 'include/gambit.h')
                              if (runtime / name).is_file()},
                   contextSha256=hashlib.sha256(json.dumps(context, sort_keys=True).encode()).hexdigest())
    return binding, directories


@contextmanager
def suite_worker_inputs(runtime, copied, context):
    """Share one donor snapshot across workers and recheck before returning results."""
    runtime = Path(runtime).resolve(strict=True)
    binding, directories = _suite_worker_binding(runtime, copied, context)

    def prepare(slot):
        return _prepare_suite_worker(runtime, copied, slot, binding, directories, recheck_donor=False)

    yield prepare
    if _suite_worker_binding(runtime, copied, context) != (binding, directories):
        raise ValueError('suite inputs changed during the campaign')


def prepare_suite_worker(runtime, copied, slot, *, context=None):
    """Reuse a slot in place; reset only owned test data when its inputs change."""
    runtime = Path(runtime).resolve(strict=True)
    binding, directories = _suite_worker_binding(runtime, copied, context)
    return _prepare_suite_worker(runtime, copied, slot, binding, directories, recheck_donor=True)


def _prepare_suite_worker(runtime, copied, slot, binding, directories, *, recheck_donor):
    from gambit_smp.artifact_storage import transfer_tree
    inputs = binding['inputs']
    manifest = slot / 'inputs.json'
    reused = False
    outputs_invalidated = False
    if slot.exists():
        if slot.is_symlink() or not manifest.is_file() or manifest.is_symlink():
            raise ValueError('unowned suite slot requires explicit cleanup')
        if set(p.name for p in slot.iterdir()) != {'gsi','gsc','lib','include','bin','tests','inputs.json'}:
            raise ValueError('foreign entry in suite slot')
        previous = json.loads(manifest.read_text())
        if previous.get('quiescenceUnknown'):
            raise ValueError('suite slot retains an unresolved child; cleanup requires quiescence')
        for name in ('gsi', 'gsc', 'lib', 'include', 'bin'):
            if (not (slot / name).is_symlink() or
                    os.readlink(slot / name) != str(Path(previous['runtime']) / name)):
                raise ValueError('suite runtime view is not an owned alias')
        work = slot / 'tests'
        if work.is_symlink() or not work.is_dir():
            raise ValueError('suite test data contains an escaping alias')
        paths = list(work.rglob('*'))
        if any(p.is_symlink() for p in paths):
            raise ValueError('suite test data contains an escaping alias')
        reused = (all(previous.get(key) == binding[key] for key in ('runtime', 'inputs', 'artifacts'))
                  and all((work / name).is_dir() for name in directories)
                  and all((work / name).is_file() and digest(work / name) == sha
                          for name, sha in inputs.items()))
        if reused and previous != binding:
            # A new execution context invalidates derived runner output.
            # Byte-verified original inputs stay at their exact cwd.
            expected = set(inputs) | directories
            for path in sorted(paths, key=lambda p: len(p.parts), reverse=True):
                if path.relative_to(work).as_posix() not in expected:
                    if path.is_dir():
                        path.rmdir()
                    else:
                        path.unlink()
            outputs_invalidated = True
        if not reused:
            # Tests have no Make target. Never clean the leased bootstrap tree
            # to reset disposable runner data or instrumentation in this slot.
            manifest.unlink()
            shutil.rmtree(work)
            work.mkdir()
        for name in ('gsi', 'gsc', 'lib', 'include', 'bin'):
            if os.readlink(slot / name) != str(runtime / name):
                (slot / name).unlink()
                (slot / name).symlink_to(runtime / name, target_is_directory=True)
    else:
        work = runtime_view(runtime, slot)
    storage = (dict(method='verified-in-place', filesCopied=0) if reused else
               transfer_tree(copied, work, dirs_exist_ok=True))
    if any((not reused and (not (work / name).is_file() or digest(work / name) != sha))
           or (recheck_donor and digest(copied / name) != sha) for name, sha in inputs.items()):
        raise ValueError('suite inputs changed during workspace preparation')
    pending = manifest.with_suffix('.pending')
    pending.write_text(json.dumps(binding, sort_keys=True) + '\n')
    os.replace(pending, manifest)
    return work, dict(storage, workspaceReused=reused, workspace=str(slot),
                      runnerOutputsInvalidated=outputs_invalidated,
                      compiledResultReused=False)


def retain_unquiesced_suite_worker(slot, commands):
    """Never reuse a timed-out slot while a prior child may still write it."""
    if any(row.get('processGroupQuiescent') is not True or row.get('parentReaped') is not True
           for row in commands):
        manifest = slot / 'inputs.json'
        record = json.loads(manifest.read_text())
        record['quiescenceUnknown'] = True
        pending = manifest.with_suffix('.pending')
        pending.write_text(json.dumps(record, sort_keys=True) + '\n')
        os.replace(pending, manifest)
        raise ValueError('suite child quiescence unresolved; fixed slot retained')


def admitted_suite(code, output, timed_out, expected):
    marker = f"PASSED ALL {expected} UNIT TESTS"
    return code == 0 and not timed_out and output.splitlines().count(marker) == 1 and "*** FAILED" not in output


def completed_suite_files(output, expected):
    """Bind each printed fixture to the next successful runner counter."""
    rows = re.findall(r"^\[\s*(\d+)\|\s*(\d+)\]\s+\d+%\s+[.#]+\s+"
                      r"[0-9.]+s(?: ([^\r\n]+\.scm))?\s*$", output, re.MULTILINE)
    if (len(rows) != len(expected) + 1
            or any(int(good) != i or int(failed) != 0
                   for i, (good, failed, _) in enumerate(rows))
            or rows[-1][2]):
        return []
    files = [file for _, _, file in rows[:-1]]
    return files if sorted(files) == sorted(map(str, expected)) else []


class SuiteCompletionProgress:
    """Read the pinned runner's completed good/failed counters, not output volume."""
    def __init__(self, expected):
        self.expected = expected
        self.completed = 0
        self.witness = None

    def __call__(self, stdout, stderr):
        for good, failed in re.findall(r"^\[\s*(\d+)\|\s*(\d+)\]\s+\d+%", stdout, re.MULTILINE):
            count = int(good) + int(failed)
            if self.completed < count <= self.expected:
                self.completed = count
                self.witness = dict(kind='upstream-suite-counter', reportedGood=int(good),
                                    reportedFailed=int(failed), completed=count, expected=self.expected)
        return self.completed


def completed_unit_cases(files, output):
    """Decode one-mode upstream counters; unfinished cases stay unresolved.

    run-unit-tests.scm prints a filename before executing that case, then
    advances exactly one good/failed counter. A printed filename alone is
    never success. Process exit/quiescence and input authenticity are separate.
    """
    names = [str(file) for file in files]
    if not names or len(set(names)) != len(names):
        raise ValueError('unique nonempty selected unit inventory required')
    rows = [dict(file=name, status='UNRESOLVED') for name in names]
    bars = list(re.finditer(r'^\[\s*(\d+)\|\s*(\d+)\]\s+\d+%[^\n]*$', output, re.M))
    if not bars:
        return rows
    good = failed = 0
    for index, bar in enumerate(bars):
        g, f = int(bar[1]), int(bar[2])
        count = g + f
        if index == 0:
            if (g, f) != (0, 0):
                raise ValueError('initial upstream counter missing')
        else:
            if (g - good, f - failed) not in ((1, 0), (0, 1)) or count > len(names):
                raise ValueError('one selected completion per upstream transition required')
            rows[count - 1]['status'] = 'PASS' if g > good else 'FAIL'
        if count < len(names) and not bar[0].endswith(' ' + names[count]):
            raise ValueError('upstream filename does not match selected order')
        good, failed = g, f
    return rows


def campaign_status(results, modes, atomic=False):
    if any(not row["accepted"] for row in results):
        return "DENY"
    return ("COVERAGE-PASS" if atomic else "PASS") if len(results) == len(modes) else "RUNNING"


def admitted_processors(code, output, timed_out, requested):
    return code == 0 and not timed_out and output.strip() == f"PROCESSORS:{requested}"


def partitions(files, jobs):
    if jobs <= 0 or len(files) != len(set(files)):
        raise ValueError("positive capacity and unique test files required")
    return [files[index::jobs] for index in range(min(jobs, len(files)))]


def capacity(cpu, files, parallel, processors=None, jobs=None):
    if cpu <= 0 or files <= 0:
        raise ValueError("positive host capacity and file count required")
    budget = max(2, cpu)
    if not parallel:
        population = processors or budget - 1
        if population + 1 > budget:
            raise ValueError("runner and child VM populations exceed available CPU budget")
        return population, 1
    workers = min(files, jobs or (max(1, budget // (processors + 1)) if processors else isqrt(cpu)))
    population = processors or max(1, budget // workers - 1)
    if workers * (population + 1) > budget:
        raise ValueError("parallel VM populations exceed available CPU budget")
    return population, workers


def runner_option(option):
    return ",".join("p1" if part.startswith("p") and part[1:].isdigit() else part for part in option.split(","))


def thread_request_fixture(original, header):
    """Refine the old private request constructor; retain every assertion.

    The consumer supplies the exact producer-bound header. Its existing macro
    owns record layout; this projection neither duplicates fields nor adds a
    legacy runtime representation.
    """
    signature = b"(##define-macro (macro-make-thread-request target thunk completion state result)"
    include = b'(include "#.scm")\n'
    old = b"(##thread-intr-propagate! (vector '() request))"
    new = (b"(##thread-intr-propagate!\n"
           b"       (macro-make-thread-request target (lambda () 'unused)\n"
           b"                                  request 'queued (##void)))")
    if header.count(signature) != 1:
        raise ValueError("exact producer thread-request constructor required")
    if original.count(include) != 1 or original.count(old) != 1:
        raise ValueError("one original private request call and harness required")
    headers = (b'(##include "~~lib/_gambit#.scm")\n'
               b'(##include "~~lib/_thread#.scm")\n')
    result = original.replace(include, include + headers, 1).replace(old, new, 1)
    # An inverse byte check makes the source refinement boundary explicit.
    if result.replace(include + headers, include, 1).replace(new, old, 1) != original:
        raise ValueError("request projection changed another source span")
    return result
