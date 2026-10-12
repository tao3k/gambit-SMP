# Pthread Error Identity And Retirement Admission

This source audit refines the open join-error obligation; it does not add a
runtime repair, reproduce a native failure, or qualify resource reclamation.
Candidate027 source identities are bound in `evidence/research-audit.json`.

## Distinct Findings

1. `os_thread.c:500-506,553-554` discards nonzero pthread return values and
   calls `err_code_from_errno`. Pthread returns the error number directly.
   The existing conversion can therefore lose the actual cause or report an
   unrelated prior errno.
2. `os_base.c:1063-1076` explicitly maps zero errno to `___UNKNOWN_ERR`, not
   success. Do not model this wrapper as turning `errno == 0` into `NO_ERR`.
   `gambit.h.in:9635-9636` separately supplies `___ERRNO_ERR(code)` for a known
   returned error number; direct conversion need not mutate ambient errno.
3. `setup.c:988` ignores the entire join result. That caller-side admission
   defect is independent of error-code fidelity: preserving the correct errno
   does not prove the thread was joined or authorize slot reuse/destruction.
4. `thread_init_common:462-468` currently returns success unconditionally.
   There is no source-supported post-successful-create allocation failure in
   this helper. Do not invent rollback of an already-started thread on that
   premise when refining the current source.

The POSIX return-value contract is documented in
[pthread_create](https://pubs.opengroup.org/onlinepubs/000095399/functions/pthread_create.html).
The attempted current-edition pthread_join page was unavailable during this
audit; no successful web retrieval of it is claimed. The selected source's
discarded return value and caller ignoring its translated error are directly
inspected facts, independent of a new native run.

## Repair Constraints

Capture each pthread result once and preserve its error identity. Keep the
success-only assignment of `thread_id` after pthread_create; on failure the
output identifier cannot be used as a new thread handle. This small translation
repair must remain separate from processor-population and resource ownership.

Growth publishes the target processor count before the create loop
(`setup.c:974,1008`). On creation failure current code calls `___fatal_error`.
Replacing that with a local return or ordinary cleanup is not a safe recovery
without handling already-created workers and peers waiting in the published
population's next barrier. A model should preserve this boundary rather than
silently treating creation failure like pre-publication setup failure.

Likewise a failed join must not become success because a local error was
translated or an observation says the worker exited. A quarantine contract
must specify remaining senders, resource ownership, result distribution and VM
teardown. `execute_sync_op_loop:1111-1116` copies results for the winning requester
or combining operations; a processor-zero-only return does not automatically
distribute the failure to a different requester.

## Admission

Reuse the retirement-generation model's distinct joined/failed states. Its
error terminal state is an abstract retained-ownership contract, not actual
source quarantine or successful resize. Add native failure injection only after
a corresponding source candidate, complete error/ownership contract and new
artifact identity exist. Neither this audit nor corrected error messages admit
bootstrap, GC or Gerbil full-test success. No old native failure was rerun.
