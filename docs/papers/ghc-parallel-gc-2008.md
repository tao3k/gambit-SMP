# GHC Parallel Copying GC (ISMM 2008)

Source: [Marlow, Harris, James and Peyton Jones](https://simonmar.github.io/bib/papers/parallel-gc.pdf).
Reviewed PDF identity: `evidence/papers.lock.json`, `ghc-parallel-gc-2008`.
These are repository-owned analysis notes, not the paper's full text.

## Protocol Obligations

Sections 3.1-3.5 distinguish the winning copy, private allocation, pending scan
regions and global termination. Empty shared work does not imply completion
while an active scanner can discover and export another region. A resumed
scanner must rejoin activity accounting. Section 3.6 motivates partial export;
it does not permit publishing unfinished data. Section 3.7's false-sharing
experience cautions against inferring elapsed-time gains from balanced work.

## Gambit Correspondence

Pinned candidate027 publishes forwarding identity before the copy loop; the
paper's copy/forward sequence cannot be transplanted. `end_heap_chunk` publishes
complete regions; `mark_reachable_from_marked` coordinates queue acquisition and
activity counts. Queues belong to processors, not source-object groups. Local
scanning of an unexported allocation region is a separate legal path.

## QNT And Open Gates

Reuse `gc_forward_publication`, `gc_work_closure` and
`gc_queue_wait_composition`. Recursive discovery with explicit waiting needs
its own composed check; independent positives do not prove the interaction.
Keep source refinement, weak memory, phase/resize composition and full native
acceptance open. No paper-derived performance estimate is admitted.

Detailed chapter audit: [reading ledger](../paper-source-reading-ledger.md).
