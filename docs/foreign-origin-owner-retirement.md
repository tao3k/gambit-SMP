# Foreign-Origin Owner Retirement

## Decision And Source Correspondence

The admission model validated processor incarnation as an abstract assumption.
The next source question is narrower and concrete: what protects the processor
pointer between `___PSTATE` lookup and publication of the foreign-frame lease?
Adding an incarnation check after dereferencing freed storage cannot answer it.

The source candidate uses the current OS thread's TLS. Pinned `os_thread.c`
sets that TLS in `___thread_set_pstate`; `start_processor_execution` installs it
before Scheme startup. SFUN capture/admission contains no Scheme allocation or
interrupt/GC poll until the lease has been published. Processor retirement must
therefore rendezvous with this thread, let it exit and successfully join it
before reclaiming its backing storage. An existing lease instead causes resize
to return busy before collective entry. A rejected entry can finish its native
path and subsequently participate in retirement.

This is a conditional source correspondence, not a whole-program ownership
proof. Shrink preserves the VM containing the embedded pstate. Separate VM
cleanup must also preserve that VM's allocation; unrelated host cleanup is not
made safe merely by the per-processor lease. `PSTATE_BIND`, escaped pointers,
unregistered external threads and processor-slot reincarnation remain separate
obligations. Historical memory-resource cleanup is not evidence that the
embedded pstate itself was freed before join.

The public runtime table exports `___set_tls_ptr` and `___setup_vmstate`.
Pinned `os_thread.c:___set_tls_ptr` stores the caller's pointer without acquiring
a VM/processor lifetime lease; its existence is not proof of managed attachment
or permission for arbitrary concurrent Scheme entry. The owner-thread model
therefore must not silently qualify that setter or `___BEGIN_PSTATE_BIND`.
The whole-VM lifetime and bound/external TLS obligations remain explicitly open
in the manifest rather than being inferred from the positive check.

## Actual Framework Verification

Model: `models/gambit/foreign_origin_owner_retirement.qnt`.
Manifest: `evidence/fixtures/foreign-origin-lease-admission/owner-retirement-contract.json`.
Portable current binding: `evidence/model-results/fixtures/foreign-origin-lease-admission/owner-retirement-bundle-binding/receipt.json`.

The existing `gambit-smp verify` and `publish-protocol` interfaces ran without
Python implementation changes. The manifest binds the source lock, candidate
patch, TLS implementation and header by hash. The existing bundle registry now
exposes these checked facts to the existing evidence pipeline; no new DSL or
independent graph implementation was introduced.

- Whole model execution: 15.323 seconds; each check retained its 15-second cap.
- Early backing-store destruction: expected counterexample, 5.669 seconds.
- Escaped TLS after join: expected counterexample, 5.655 seconds.
- Positive safety plus weak-fair completion: 5.052 seconds, 41 distinct states,
  63 generated, zero queued.
- Positive no-stall plus weak-fair completion: 4.595 seconds, same exhausted
  finite inventory. Completion permits a pending-join error which retains
  storage; it does not assert eventual success of an OS join retry.
- Host-auto selected 12 available processors; controls ran in parallel with
  six TLC workers each, positive checks used 12 workers. Those are observations
  of this host, not constants in the model or native topology configuration.
- Portable publication returned `PROTOCOL-EVIDENCE-OK`, with logs, model snapshot
  and negative traces bound and checked. Full ASCENT graph execution was not run.

The first bundle extraction rejected the manifest because its evidence metadata
lacked the required `composes` field. That was a declaration error, not a model
or framework repair. The original manifest is retained with the first portable
receipt as `standalone-manifest.json`. The declaration now has explicit empty
composition/paper lists and three open refinement obligations. The existing
framework revalidated/reused all four same-model, same-context checks under the
corrected declaration without rerunning TLC or modifying any old receipt.

Both negative controls are injected protocol violations, not new native bug
attributions. GC relocation is a bounded marker-root abstraction, not the
complete parallel collector. Weak fairness is a model premise, not P99 latency.

## Mainline Consequences

Do not add a global registry lock or generation check merely to repair a
pre-publication lifetime gap already excluded by valid OS-thread ownership.
First establish the supported FFI entry contract and whole-VM lifetime at each
real entry path. An escaped raw TLS pointer needs an earlier ownership protocol,
not a check after dereference.

The standard startup thunk initializes queues and publishes readiness before
scheduling; no SFUN call was found in that pre-readiness source sequence. The
earlier startup/admission-window audit is therefore not evidence of a required
native fix. Arbitrary startup callbacks and post-readiness rejection semantics
remain unqualified, not a reason to patch growth speculatively.

The current source successor still needs its completed bootstrap producer and
official-FFI frame roundtrip before the unchanged full correctness/performance
gates. No C patch changed in this audit, and no old seed is promoted to a runtime.
Retained acceptance remains **3/12**, with all nine full gates OPEN.
