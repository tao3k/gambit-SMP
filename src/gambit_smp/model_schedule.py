"""Bound independent TLC controls without multiplying per-check CPU/heap use."""
from concurrent.futures import ThreadPoolExecutor
from math import isqrt
import os


def physical_memory():
    try:
        pages = os.sysconf("SC_PHYS_PAGES")
        size = os.sysconf("SC_PAGE_SIZE")
        return pages * size if pages > 0 and size > 0 else None
    except (ValueError, OSError, AttributeError):
        return None


def resources(cpus, memory_bytes, requested=None):
    if type(cpus) is not int or cpus <= 0:
        raise ValueError("positive CPU budget required")
    # Quint 0.33.0 defaults: TLC 8 GiB and Apalache 4 GiB per concurrent check.
    # Reserve a quarter of physical memory; unknown capacity means serial.
    memory_jobs = max(1, memory_bytes * 3 // 4 // (12 * 1024 ** 3)) if memory_bytes else 1
    maximum = min(cpus, memory_jobs)
    jobs = min(isqrt(cpus), maximum) if requested is None else requested
    if type(jobs) is not int or not 1 <= jobs <= maximum:
        raise ValueError("check jobs exceed CPU/memory budget")
    return {"availableProcessors": cpus, "physicalMemoryBytes": memory_bytes,
            "parallelControls": jobs, "controlTlcWorkers": max(1, cpus // jobs),
            "positiveTlcWorkers": cpus, "perCheckTlcHeap": "-Xmx8G",
            "selection": "host-auto" if requested is None else "explicit-bounded",
            "memoryScope": "physical capacity, not a live free-memory guarantee"}


def batches(checks, jobs):
    if jobs <= 0:
        raise ValueError("positive batch capacity required")
    pending = []
    for check in checks:
        if check[0] == "old":
            pending.append(check)
            if len(pending) == jobs:
                yield pending
                pending = []
        else:
            if pending:
                yield pending
                pending = []
            # Positive exhaustive checks retain the whole per-model CPU budget.
            yield [check]
    if pending:
        yield pending


def run_batch(items, worker):
    if len(items) == 1:
        return [worker(items[0])]
    with ThreadPoolExecutor(max_workers=len(items)) as pool:
        # Results retain manifest order; each worker owns a distinct check dir.
        return list(pool.map(worker, items))
