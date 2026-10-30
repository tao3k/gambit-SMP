"""Suite inventory, topology and exit contracts without feature producer imports."""
from math import isqrt
from pathlib import Path
import re

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


def admitted_suite(code, output, timed_out, expected):
    marker = f"PASSED ALL {expected} UNIT TESTS"
    return code == 0 and not timed_out and output.splitlines().count(marker) == 1 and "*** FAILED" not in output


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
