"""Check reviewed queue/wait source ordering, not C semantics or native admission."""
import argparse
import json
from pathlib import Path
import re

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import checked_rows
from gambit_smp.source_binding import region, queue_acquire_handoff


def ordered(body, fragments):
    positions = []
    for fragment in fragments:
        if body.count(fragment) != 1:
            raise ValueError("missing or ambiguous protocol fragment: " + fragment)
        positions.append(body.index(fragment))
    if positions != sorted(positions):
        raise ValueError("protocol source ordering differs")


def inspect(source):
    # Preserve newlines for exact function-boundary guards before normalization.
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    publisher = region(source, "___HIDDEN void end_heap_chunk\n",
                       "___HIDDEN void set_heap_msection\n")
    ordered(publisher, (
        "___SPINLOCK_LOCK(heap_chunks_to_scan_lock);",
        "*heap_chunks_to_scan_tail=___TAG(new_tail,___FORW);",
        "heap_chunks_to_scan_tail=new_tail;",
        "___SPINLOCK_UNLOCK(heap_chunks_to_scan_lock);",
        "___CONDVAR_SIGNAL(scan_termination_condvar);",
    ))
    if "___MUTEX_LOCK(" in publisher:
        raise ValueError("publisher mutex changes require a fresh lock audit")
    link = "*heap_chunks_to_scan_tail=___TAG(new_tail,___FORW);"
    tail = "heap_chunks_to_scan_tail=new_tail;"
    unlock = "___SPINLOCK_UNLOCK(heap_chunks_to_scan_lock);"
    fence = "___SHARED_MEMORY_BARRIER();"
    if (publisher[publisher.index(link):publisher.index(tail)].count(fence) != 1 or
            publisher[publisher.index(tail):publisher.index(unlock)].count(fence) != 1):
        raise ValueError("both publication barriers required")
    queue_acquire_handoff(source)
    own = region(source, "___HIDDEN void scan_movable_objs_to_scan\n",
                 "___HIDDEN void free_unmarked_still_objs\n")
    stolen = region(source, "___HIDDEN void mark_reachable_from_marked\n",
                    "___HIDDEN void garbage_collect_setup_phase\n")
    ordered(own, (
        "heap_chunks_to_scan_head=ptr;",
        "___SPINLOCK_UNLOCK(heap_chunks_to_scan_lock);#endifscan_complete_heap_chunk",
        "scan_complete_heap_chunk(___PSPptr+1);",
    ))
    ordered(stolen, (
        "___SPINLOCK_LOCK(ps->mem.heap_chunks_to_scan_lock_);",
        "ps->mem.heap_chunks_to_scan_head_=ptr;",
        "___SPINLOCK_UNLOCK(ps->mem.heap_chunks_to_scan_lock_);scan_complete_heap_chunk",
        "scan_complete_heap_chunk(___PSPptr+1);",
        "___MUTEX_LOCK(scan_termination_mutex);",
        "if(--(*workers_count)==0)",
        "___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex);",
        "if(*workers_count==0){___MUTEX_UNLOCK(scan_termination_mutex);break;}",
        "(*workers_count)++;",
    ))
    resume = ("___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex);"
              "___ACTLOG_END_PS();if(*workers_count==0){"
              "___MUTEX_UNLOCK(scan_termination_mutex);break;}"
              "(*workers_count)++;___MUTEX_UNLOCK(scan_termination_mutex);")
    if stolen.count(resume) != 1:
        raise ValueError("zero/nonzero resume branch changed; fresh audit required")
    return {"bindingKind": "lexical-order-not-semantic",
            "publisherUnlockBeforeSignal": True, "twoPublicationBarriers": True,
            "consumerPostTicketAcquire": True, "scanOutsideQueueLock": True,
            "zeroWakeExitsWithoutRestore": True, "nonzeroRestoreBeforeUnlock": True,
            "combinedPolicyImplemented": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    source = args.source.resolve(strict=True)
    manifest_path = ROOT / "evidence/gc-queue-wait-composition.json"
    proof = ROOT / "evidence/model-results/gc-queue-wait-composition/receipt.json"
    manifest = json.loads(manifest_path.read_text())
    rows = checked_rows(ROOT, manifest, proof)
    name = source.relative_to(ROOT).as_posix()
    if manifest["contextInputs"].get(name) != digest(source):
        raise ValueError("source differs from reviewed model context")
    inputs = {**manifest["contextInputs"],
              "evidence/gc-queue-wait-composition.json": digest(manifest_path),
              "evidence/model-results/gc-queue-wait-composition/receipt.json": digest(proof)}
    for path in (Path(__file__).resolve(), ROOT / "src/gambit_smp/source_binding.py",
                 ROOT / "src/gambit_smp/protocol_evidence.py",
                 ROOT / "src/gambit_smp/check_gambit.py",
                 ROOT / "models/gambit/gc_queue_wait_composition.qnt"):
        inputs[path.relative_to(ROOT).as_posix()] = digest(path)
    for _, checks in rows:
        for row in checks:
            for key in ("log", "trace"):
                if key in row:
                    path = proof.parent / row[key]
                    inputs[path.relative_to(ROOT).as_posix()] = digest(path)
    observed = inspect(source.read_text())
    if any(digest(ROOT / name) != sha for name, sha in inputs.items()):
        raise ValueError("binding context changed during inspection")
    receipt = {"schema": "gambit-gc-queue-source-binding.v1", "inputs": inputs,
               "status": "lexical-order-observed", "diagnosticOnly": True,
               "runtimeAdmitted": False, "releaseAdmitted": False,
               "native": {"status": "not-run"}, "observed": observed,
               "remaining": manifest["cases"][0]["openObligations"]}
    args.out.mkdir(parents=True, exist_ok=False)
    (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("GC-QUEUE-LEXICAL-BINDING-OK; runtimeAdmitted=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
