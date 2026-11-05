# Child progress qualification and retained failures

Candidate source lock: `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
These observations do not increase the historical 6/12 milestone count.

## Native observations before the host-capacity continuation

Every attempt reused source, configure, seed and core, with
`executionLaunched=false`. No bootstrap or runtime rebuild occurred.

1. The first observer attempt stopped at a concurrent checkpoint CAS conflict
   before stress. Its retained receipt is
   `161c5af1e7dc98d3470e816cebe1800e121ced60c587fcdb6c6c776d2f2fa60f`.
   Self-contained process and stage observations now append under the existing
   SQLite transaction; prefix-dependent analysis still uses strict CAS and a
   terminal prefix still rejects any append. Real concurrent and terminal
   controls pass without bypassing the source or history checks.
2. Allocation-frontier observation is refuted. Real completed reports included
   `-143115.4K alloc` and `-272539.0K alloc`. Interrupt children naturally
   exited zero at 99.882 and 146.281 seconds, but the observer rejected their
   signed statistics. The still-active TFIB group was explicitly cancelled for
   that invalid observation contract, not classified as deadlocked. Aggregate
   DENY, timeout false, 524.774 seconds; parent reaped and group quiescent.
   Receipt: `2fd5721acacff2be71e7b1b4e8d80c4282eaa52b2b481e6862ad07ad86b9754a`.
3. Completed-report occurrence forwarding worked on TFIB. In the first
   three-driver configuration only TFIB was selected for observation. The
   original unobserved interrupt test passed in 81.532 seconds. The other
   unobserved interrupt2 file hit completed-file inactivity at 300.017 seconds;
   this does not identify absence of internal work or a deadlock. After that
   campaign was already denied, active TFIB was explicitly cancelled to use
   host-wide VM capacity; it was not killed by a total-wall gate. Aggregate
   DENY, timeout false, 691.095 seconds, parent/group quiescent. Receipt:
   `30e38571a3b0a2954cd540d446a7e090f31a4b7fe68aba142f7f74aba97a471c`.

The allocation observation is a statistics/correspondence defect, not a proven
cause of TFIB, interrupt or barrier failures. No clamping or fabricated progress
was added. Current collection occurrences are attested by the owned child port,
fresh nonce, actual `process-pid`, exact file/reporter/driver identities and
strict Scheme cursor advancement. They do not establish a TFIB result, mutator
share, termination or freedom from observer interference.

## Grok behavior

The first locked related query matched existing TFIB evidence and returned its
checkpoint. A later broad implementation window nevertheless ended without
edits: 101 public read/search calls, including one identical repeated call.
The interruption was requested at call 93; remaining calls drained before exit.
Different read ranges are not automatically classified as redundant reasoning.
Public trace SHA-256:
`9dc1dd966c1abc3466572d857be25392bee4a6061d67e989d76b64ad9cfa0875`.

A narrower model-review window produced the source review, QNT and manifest.
Its trace is `dd195ea5b2b87b0f49f7e0a8dee396bb8d226fbaff04d51061d09f387f04b228`.
This role split is not proof that Trajectory alone improved reasoning cost.
The relevant correspondence and prior failures are now directly related in the
existing Evidence DSL, without prescribing an action or a closed search scope.

## Remote acceptance boundary

The initially published ASCENT revision passed its formal job but failed the
Rust inline-test layout gate and the old formal inventory enumeration. The
shared PR's inventory correction was retained; this task moved its two Rust
tests to the existing unit tree. Local exact-feature library tests pass 17/17,
strict Clippy passes, and the corrected inventory tests pass 9/9.

SMP run `39210698594` built the older
`darwin-stack-trip-owner-limit` source lock, not this collective-wait candidate.
Its numeric compiled file timed out at 90.048 seconds, official error handling
returned 70, compiled TFIB exited with signal status 139, and interpreted TFIB
had no completed-file witness. Those failures remain evidence for that older
source identity; they are not current-candidate results or grounds to rerun an
unchanged failed route.
