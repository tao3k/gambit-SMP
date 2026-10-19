# Host-capacity interpreted continuation

## Identity and reuse

Installed ASCENT: `e119827e588ea7b6d8a3195ac8e0ee8f61de6c11`.
Sealed engine: `4846475cc6f3f60705d410dc798239f51436c57ae6e84ac8e4a3e152d2ea5b88`.
Unchanged 26-file source lock:
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
Source, configure, seed and core reused successful checkpoints: no bootstrap.

Host-capacity selection used one driver and eleven target VM processors from
twelve available CPUs. This is not a timing comparison with the earlier
three-driver, three-processor regime. Original stress files, assertions and
fixed workload parameters were unchanged.

## Actual outcome

The original interpreted continuation returned **DENY**, not native success.
Supervising time was 402.233 seconds; the stress group lasted 383.455 seconds,
ending with inactivity timeout and exit -9. The parent was reaped, its process
group was quiescent, inputs were stable, and the outer supervisor did not time
out. That differs from the child-stage timeout.

TFIB was first. No file completed; interrupt2, interrupt and terminate were not
reached. The child emitted 4,167 report envelopes; 3,711 complete reports renewed
the source-bound cursor, while 456 malformed reports were rejected. Following
the final accepted report, the unchanged 300-second inactivity guard expired.
No total-wall performance gate replaced that guard.

Reports contain interleaved fragments, including a second `*** GC:` inside an
unfinished report. The human-readable reporter therefore did not provide a
reliable framed transport in this execution. This does not establish the
instruction responsible, why reports stopped, a TFIB deadlock, or an
observer-independent C defect. GC completion alone is not mutator progress or
termination. Relaxing the parser would not establish those missing premises.

## Retained evidence and open obligation

- Outer receipt SHA-256:
  `10edc207d76274b9234f4f0cd2d075b4d7f68a1d05b076196cda18020ad5eb38`.
- Child recipe receipt SHA-256:
  `c2f21f870910b92b8fcaf00ccb2feb7a6689877a2fba5117d3d7946770e2b8ab`.
- Child stderr SHA-256:
  `c614e45b6f97052812b5df4a3ece2b4f854eaa6a9cb5740eea64907ed72096b2`.

Raw transport/process receipts remain cache artifacts. This normalized Git
observation does not make a cache path a source dependency. Earlier failed
observer attempts remain separate historical evidence.

The target-child observation obligation is **not closed**. A source-backed,
noninterfering progress contract and original natural test completion remain
necessary. Do not repeat this unchanged reporter configuration as qualification,
promote GC to mutator progress, or promote framework checks to SMP acceptance.
Historical progress remains 6/12.
