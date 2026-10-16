# Shared Msection Fresh Return

## Historical Native Boundary

This record is retained History. The successor's pre-store observation in
`shared-msection-header-damage.md` closes the missing predecessor/stored-next
discriminator below; it does not close first-writer or lifetime requirements.

`darwin-gc-complete-probe-round` completes both bootstrap passes and final
ASCENT review: 117.699944 native make seconds, 122.211779 bootstrap-stage
seconds, 190.055749 child whole seconds. The unchanged complete compiled
stress inventory remains DENY: two pass, TFIB aborts, thread_interrupt2 times
out at 300.004864 seconds. The candidate is not a qualified repair or release.

The exact TFIB record binds PID 28615 and `origin=fresh-allocation`:
selected and post-update cursor are `0x723666c11`, to-space offset is zero,
private pool is zero, custom allocator is zero and assigned count is 659.
The selected raw pointer is not word aligned. The private pool route did not
produce this observed selection. Do not reuse the earlier PC-only attribution.

The source function obtains a fresh section from the arena head when the
assigned count is zero, otherwise from `alloc_msection->next`. A non-null result
replaces the shared cursor and increments the count before the current selection
diagnostic runs. Thus the diagnostic loses the predecessor cursor. It does not
independently observe the stored successor word or prove a corrupting writer,
an allocator lifetime failure, or bad compiler code generation.

## Source Audit And Model

`adjust_msections` is the explicit writer of linked arena topology: growth
appends raw allocated sections and contraction clears the surviving tail's next
link. The current GC lower bound retains assigned sections plus allocation
headroom. These source mechanisms must be refined with actual lifetime and
memory-write evidence; their presence is not a proof of this failing execution.

`shared_msection_successor.qnt` imports the existing stack-ownership model.
Its positive case selects and installs a legal shared successor. The native
observation control imports an invalid post-return shared cursor while leaving
the private pool empty and local stack unchanged, matching the rejection before
stack installation. It does not fabricate a write to the arena's stored next.
The observation initializer's unused next map is not a measured native value.
Both checks pass through the sealed Quint/ASCENT framework; this is not runtime
admission or identification of the missing legal source transition.

## Original Discriminator And Current Status

- Predecessor captured before overwrite: closed by the successor observation.
- Independently read stored next and match catalog membership: closed;
  allocation lifetime remains open.
- Bad stored memory word versus selected-return-only mismatch: closed for the
  captured successor execution; independent read equals selected.
- If the stored word is bad, bind the first header write or reclamation event;
  do not replace the list with a side table merely to hide the symptom.
- Retain the interrupt2 timeout as a separate failure until a shared cause is
  established. No unchanged full stress retry is admitted.

Evidence and source locks are under `evidence/fixtures/darwin-gc-complete-probe-round`.
The exact source is reproduced from the pinned submodule and versioned patch,
not from a cached fixture pathname. Overall milestone remains 5/12.
