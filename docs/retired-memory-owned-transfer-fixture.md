# Retired Memory Owned Transfer Fixture

## Review Before Repair

The source and real native failure show that processor cleanup frees a reachable
still object when the allocating processor leaves an otherwise live VM. Moving
the shrink caller alone cannot repair that ownership defect. The existing
resource-transfer design contract covers the required list/accounting handoff,
successful join and scanner drain, but not the complete runtime. Expected
performance benefit is zero: this is a correctness repair.

## Source Change

Only `lib/mem.c`, `lib/mem.h` and `lib/setup.c` differ from the cumulative atomic
message parent. The retiring processor closes its interrupt/OS resources and
exits without destructively freeing its memory lists. P0 checks the actual join
result. After successful join, `___transfer_mem_pstate` moves the still list,
registered RC list and both still-word counters to P0 under the VM MISC lock;
then the retired processor's memory resources are cleaned up. The donor lists
are emptied so later cleanup does not release transferred allocations twice.

A failed join does not transfer or free that donor's memory; the first join
error is returned after the loop. This is not full failed-join recovery: slot
quarantine, retry/drain, GC coverage and reuse prevention remain unresolved.
Likewise, the caller must establish GC/queue borrower drain; join alone is not
a proof of that premise. No global cleanup bypass or permanent-list leak is an
accepted repair.

## Real Validation

Source authority is the pinned submodule plus
`evidence/fixtures/retired-memory-owned-transfer/source.lock.json` and its
cumulative overlay. The 14 parent files are reproduced; all except the three
listed above retain their parent hashes.

The source-core recipe consumes source authority and execution rules, not
archived producer observations. The historical motivating control remains
`evidence/source-results/fixtures/sync-message-atomic-publication/still-survival-observation.json`;
it is a reference, not a runtime input to materialization or compilation.
Removing it from the recipe input list does not admit the old result as a new
execution or weaken the archived-producer policy.

Both complete GNU GCC C translation units compiled successfully against the
verified parent configuration. A fresh configuration attempt then hit its
unchanged 90-second budget during a system-function probe; no source compile
result follows from that attempt. The recipe dispatcher had separately denied
the old execution-rule input before compilation. Neither DENY is discarded.

An explicit incremental build reused the verified parent's configuration and
46 generated-C inputs, after proving all Scheme inputs unchanged. It rebuilt
affected C objects and relinked gsi/gsc/library in 81.682 seconds. Host-auto
selected 12 outer make jobs and one compiler child processor. All three
SMP/multiple-VM flags remain enabled. This is not fresh configuration, new SCM
regeneration, two-pass bootstrap, or sealed campaign acceptance.

| Native component | Outcome | Seconds |
| --- | --- | --- |
| Original still-survival fixture, interpreted | PASS | 1.010764 |
| Mixed-key forced GC, interpreted | PASS | 2.531067 |
| Original still-survival fixture, compiled | PASS | 1.304744 |

The compiled fixture initially failed at link time: the inherited PATH selected
`/run/current-system/sw/bin/ld`. Selecting the same verified GNU environment
used by the core build selected `/usr/bin/ld`; the unchanged fixture then
compiled in 11.124015 seconds and passed. This is an environment correction,
not a source patch or budget increase. Generated test C/object files were moved
to the execution cache rather than retained beside canonical Scheme fixtures.

Native cases used the host-selected VM population (12 on this host), retained
their 30-second budgets and had quiescent process groups. Source/artifact hashes
were checked before and after. Portable summary:
`evidence/source-results/fixtures/retired-memory-owned-transfer/observation.json`.

## Remaining Gates

The original unpinned requester timeout remains a separate denied route; this
fixture does not implement Scheme-thread drain. Native RC/foreign callbacks,
repeated growth/reuse, failed joins, GC phase composition, fresh/full bootstrap,
upstream suites and Gerbil acceptance are not established. Runtime/release
admission stays false. These results are not build/test speedup claims.
