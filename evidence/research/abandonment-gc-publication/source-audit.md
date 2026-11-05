# Abandonment, publication, and unlock lock order

Candidate `405d1b9db14bb7d8084db3c1e283ace0ab52bda890fb19a218d33dfe8b10df37` is upstream `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus `patches/fixtures/pipe-predicate-sync-participation-cumulative.patch`. This delta is written against the unchanged text of the functions below and calls `##lock-scheduler-object-with-sync-participation!`, which that cumulative patch adds. It is not a standalone patch on upstream.

The registered chain in `evidence/scenarios/concurrent-gc/pipe-predicate.view.json`
retains bootstrap and original GSC stress PASS for that lock only. Complete GSI
is TIMEOUT, digest `baab2530d94adf54370403f42af681806f189a50cd127316aa2edbe98e2c41dc`,
premise `mutex-condvar-participation-alone-does-not-resolve-pipe-timeout`. The
abandon gap is `thread-end-abandon-lock-order-qualified`, premise
`termination-publication-and-ownership-revalidation-on-retry`, and the registered
link says it is separate from that timeout. Nothing here assigns TFIB or pipe
timeouts to this protocol. Runtime read tokens are local state, not portable
evidence references. The current Grok source-edit window did not execute a new
Trajectory query and therefore does not establish Agent checkpoint reuse.

## What current source does

`##thread-end-locked!` holds the thread ticket and clears `macro-thread-end-condvar` before the abandon loop. SMP readers of termination (`##thread-join!`, `##thread-interrupt!`, `##thread-state`, `##thread-intr-propagate!`) take that ticket first. `macro-terminated-thread-given-initialized?` is only `(##not (macro-thread-end-condvar thread))`. The queued waiter is woken by `##condvar-signal-no-reschedule!` on the condvar captured before the clear, and that call is after the ticket unlock.

`##btq-abandon!` takes the btq with raw `macro-lock-btq!` while the thread ticket is still held. `___TICKETLOCK_LOCK2` does not read `INTR_SYNC_OP`. On the candidate, `macro-lock-mutex!` and `macro-lock-thread!` do participate, but this call does not use them.

`macro-mutex-lock!` locks the mutex and then blocks in `macro-lock-thread!` while still holding it. `##mutex-lock-out-of-line!` does the same at both `##lock-2-threads!` sites (about lines 3656 and 3735).

`macro-mutex-unlock!` locks the mutex. With no waiter it calls `macro-lock-thread!` on the owner (about line 1765). With a waiter, `##mutex-unlock-out-of-line!` (line 3819) keeps the mutex and calls `##lock-3-threads!` on `first-thread`, `new-owner`, and `current-owner`. Any of those slots may be `#f` or the same thread. The third acquire in `##lock-3-threads!` skips `thread3` only when it is `eq?` to `thread2`, not when it is `eq?` to `thread1`. `##unlock-3-threads!` does test both. `##object-before?` is a primitive; this audit assumes it is irreflexive, which keeps true duplicates adjacent in that comparison tree. The new helpers also treat `thread1` and `thread3` as one ticket so the proposal does not depend on that assumption.

If the terminating thread still holds its ticket and is in the abandon wait, an unlocker that holds this mutex and needs that ticket is the same cycle as a locker that holds the mutex and waits for the ticket. Locker-only inverse does not cover it. Alias 0 in the model is current-owner = target. Alias 1 is new-owner = target. Alias 2 is neither (`#f` or some other thread). Collapsing two slots onto the target still needs that one ticket; it is alias 0 or 1, not a skip.

## Proposal

`patches/fixtures/abandonment-gc-publication.patch` applies on foundation lock `405d1b9db14bb7d8084db3c1e283ace0ab52bda890fb19a218d33dfe8b10df37`. It is not a replacement of that lock.

- Leave the end-condvar clear where current source puts it: before the abandon loop, while `##thread-end-locked!` still holds the thread ticket. SMP termination readers take that ticket first. Moving the clear until after abandon would leave it set while `##mutex-signal-no-reschedule!` decides whether a waiter's `new-owner` is terminated. When that `new-owner` is the terminator, `macro-btq-link!` would put the mutex back on the owner list that `##btq-abandon!` just removed, and the abandon loop would see it again.
- `##thread-end-locked!` trylocks the thread group and, on failure, calls the helper. The thread ticket stays held. Thread then thread group is the prescribed order. The helper returns owning the group.
- `##btq-abandon!` trylocks, and on failure calls the helper once. The helper returns owning the btq.
- `macro-mutex-lock!` trylocks the new owner. On failure it drops the mutex, calls the helper, and locks the mutex again before the owner read.
- `##mutex-lock-out-of-line!` trylocks the required threads in `##object-before?` order. On failure it drops the mutex, waits with the helper, releases those tickets, relocks the mutex, and retries the read. The two old blocking acquires are removed. The timeout arm releases the tickets it now holds.
- `macro-mutex-unlock!` reads `macro-btq-leftmost` and calls either `##mutex-unlock-no-waiter!` or `##mutex-unlock-out-of-line!`.
- The no-waiter path trylocks the owner. On failure it drops the mutex, waits, relocks, and retries, including when a waiter appeared.
- The waiter path trylocks the three slots. On failure it drops the mutex, waits, releases the tickets, relocks, rereads the head, and either retries or switches to the no-waiter path. It does not keep the `first-thread` sampled before the drop.
- `##lock-3-threads!` skips `thread3` when it is `eq?` to `thread1` or to `thread2`, matching `##unlock-3-threads!`.
- `##mutex-signal-no-reschedule!` takes a distinct `new-owner` before it edits the queue. The current thread is not locked again. On a failed trylock it drops the mutex, calls the helper, releases that ticket, relocks the mutex, and retries until the trylock holds. The waiter ticket stays held. The final unlock uses the same exception.

## Model to qualify

`models/gambit/abandonment_gc_publication.qnt` is the finite protocol, not a proof of the patch. `initEither` retains the ticket through the drain, clears end-condvar while that ticket is held, and uses inverse locker entry, inverse slow path, inverse unlock, recheck, marker admission, and abandon participation. Role and alias are free. The ten `oldInitializers` are incomplete repairs and are meant to fail their named invariants. The state machine does not include the thread-group lock or the signal `new-owner` acquire. A finite pass is not native acceptance.

The retained finite acceptance is model `407646d402e608ebecc1d02ee549b7fb0c314de2319c73716b31b382b600d19f`, patch `5b22a3468c26917d46b5af7f988ed3e6b4e7f35ce298954e7408118b7f453b15`, receipt identity `204c013d2cbdb2d69e0adb544faf51af92a3cd7f80f91e7c4a51662ea36fb10f`: `initEither` at 346 distinct states and ten counterexamples. That acceptance used a delayed end-condvar clear. It does not transfer to this correction.

The manifest binds this audit, the candidate delta and its foundation source
lock through `contextInputs`. The verifier separately binds the model source.
Do not edit these files during a run or transfer its result to a changed patch.

## Still unresolved

- The signal repair holds the waiter ticket while the helper waits for `new-owner`. Address order between those two threads is not reestablished on that path.
- `macro-thread-btq-remove-if-in-btq!` still raw-spins on a btq while the thread ticket is held. `macro-lock-toq!` is also raw. Neither is the abandon/mutex cycle above.
- Trylock barging versus the old FIFO ticket lock.
- One mutex, one waiter, one GC, and two processors. The finite model does not refine the Scheme.
- Foundation bootstrap `9e5b57e6f86d8589480905eb1c3140be745526892115153b81c0f91ac5059da9` and compiled stress `db1efd12140c9ae457a5f99bc915c08de4355118d57d1d0b61a141d513755d7a` remain the 6/12 qualification of lock `405d1b9…` and producer `35a73f4911228a146bdfa163a218b6970bc6c2219d362978d8977f3047915c96`. They do not cover this delta. Interpreted TFIB and complete GSI stay TIMEOUT, and their observations set `unchangedRetryAuthorized` to false. Do not rebuild that producer to restate those results.

## Recorded patch failure

The original dry-run exited 2 with malformed hunk `@@ -3642,20 +3653,74 @@`
at line 39; it changed no source. A later version parsed but its context-free
hunks failed under the build's patch parser, including on the retained foundation.
Git accepted that version only with explicit zero-context support. The supervisor
added source context without changing the proposed Scheme bodies; the build's
`patch --dry-run` then passed against the retained foundation.

A later signal hunk failed the same way. The supervisor dry-run exited 2 at
line 204, hunk `@@ -3934,4 +3938,21 @@`, and changed no source. A zero-length
line inside that hunk is not a diff prefix. That failure stays recorded.

After the prefixes were corrected, the foundation dry-run parsed and exited 1.
`_thread.scm` hunk 1 failed at 869 and hunk 3 failed at 1668. The other eleven
`_thread.scm` hunks and all three `_thread#.scm` hunks matched. No source
changed. Foundation `_thread.scm` is
`0250e820e99119e15a37f0f77328244374b43baa04cda4ad862e161deb197541` and
`_thread#.scm` is
`eab2eb89e79fa695dcb6275d3fcc9142a25769a7c7d53371567f91c7f0863bc6`, the lock
`405d1b9db14bb7d8084db3c1e283ace0ab52bda890fb19a218d33dfe8b10df37` bytes.
`##lock-3-threads!` ordered locking is at foundation line 889, and the
thread-group lock is at line 1671. A three-line hunk at 889 still failed on
that exact text. The same parser already rejected an earlier context-free
hunk. A diagnostic control, not a portable receipt, put the lock-3 change
between original lines before and after it; that hunk succeeded at 888 with
exit 0 on this foundation. The real patch now uses that shape for lock-3 and
the same before-and-after context for the thread-group lock. The following
dry-run exited 0: every `_thread.scm` hunk and all three `_thread#.scm`
hunks, including lock-3 at 888 and the thread-group hunk at 1666. No source
was changed. This delta is not an upstream patch: the foundation already
contains `##lock-scheduler-object-with-sync-participation!`. Raw
attempt payloads and Grok's unbound summary stay in the ignored cache; they are
not additional source-bound qualification receipts.

The current sealed engine applies a second overlay with `git apply --whitespace=error`, not BSD `patch`. On this foundation, `git apply` rejects `358cb1ecd68c8c43fda1a8388654dffb450db00b3e1b2e193e9bc58911d670c3`: `_thread#.scm` does not match at 1641, and `_thread.scm` hunks after lock-3 land at different offsets than the BSD dry-run, including the thread-group hunk at 1763 rather than 1666. `patches/fixtures/abandonment-gc-publication-engine.patch` (`d61142c65fc01fb04e9f65b70c264098eb836d53f1a60deaa6b8173f70f98a80`) is a unified diff of that same BSD-applied tree. `git apply --whitespace=error` applies it cleanly. The applied files are `_thread.scm` `436b7ed0e37c8ca0c6995c8e1bcb0b069d9b54276fa9d36967f17c90ada9ab5f` and `_thread#.scm` `c101ffba2a793b772ebdd8561320dc46956ef3d459e998624702e3bb2a8b3107`, identical to the BSD apply. This is the adapter form of the verified delta. The model is unchanged. The finite receipt stays bound to `358cb1ec` and still does not cover thread-group locking or the signal `new-owner` acquire.

## Current Native Follow-Through

The original delta omitted one closing parenthesis in
`##mutex-unlock-out-of-line!`. The current delta repairs it; the previous
malformed source and its complete lock remain reproducible separately.
See `native-reader-bootstrap-observation.md` for the native reader
counterexample, completed bootstrap, incomplete interrupt2 stress, unauthorized
budget expansion and restored original windows. These observations do not
refine the finite protocol or establish full-source qualification.

## Historical Pre-Native Supervisor Commands

The following was the earlier pre-native instruction window, not a current
blocker or a new execution grant. It required: do not apply the patch and do not
raise the 90 second verifier timeout. Its dry-run and verification receipts stay
historical; later candidates need their own byte bindings.

```sh
patch --dry-run -p1 -d "$FOUNDATION_SOURCE" < patches/fixtures/abandonment-gc-publication.patch
```

```sh
.venv/bin/gambit-smp verify \
  --manifest evidence/research/abandonment-gc-publication/model.manifest.json \
  --out .cache/abandonment-gc-publication
```

`FOUNDATION_SOURCE` is the existing managed source whose lock matches the
candidate above; do not create another source tree. The verifier output directory
must not already exist. Quint must print `0.33.0`. Resume only if model bytes,
initializer names and context hashes are unchanged. Preserve failures and retain
only source-bound portable verdicts here. Do not treat a TLC pass as native
evidence.
