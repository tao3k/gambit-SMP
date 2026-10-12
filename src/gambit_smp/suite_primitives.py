"""Suite inventory, topology and exit contracts without feature producer imports."""
from math import isqrt
from pathlib import Path

from gambit_smp.framework import digest, relative


def check_runtime(runtime, identity):
    if any(digest(relative(runtime, name)) != expected for name, expected in identity["sourceFiles"].items()):
        raise ValueError("candidate input inventory changed")
    for field, name in (("binarySha256", "gsi/gsi"), ("gscSha256", "gsc/gsc"), ("librarySha256", "lib/libgambit.a")):
        if digest(runtime / name) != identity[field]:
            raise ValueError("candidate artifact changed: " + name)


def selected_files(root, selections):
    root = root.resolve()
    files = set()
    for selection in selections:
        selected = relative(root, selection)
        if not selected.exists():
            raise ValueError("suite selection must exist inside upstream unit-tests")
        candidates = selected.rglob("*.scm") if selected.is_dir() else (selected,)
        files.update(path.relative_to(root) for path in candidates
                     if path.suffix == ".scm" and path.name != "#.scm" and not path.name.endswith("_stress.scm"))
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
