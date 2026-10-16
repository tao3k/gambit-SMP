# Default Profile Compiled Cost Audit

## Verified Boundaries

The completed default-profile producer uses dynamic C O1 and runtime C O3.
Its actual generated `gambuild-C` already contains
`-ftrack-macro-expansion=0`, GCC scheduling options, inline jumps and trusted C
tail calls. The old numeric compiler-phase archive also records O1 and
`-ftrack-macro-expansion=0` in its actual command. The balanced compiled archive's
image-bound configuration also records O1, RTS optimization, GCC options,
inline jumps, dynamic clib and trusted C tail calls.

Authoritative old inputs:
- `evidence/source-results/fixtures/thread-completion-contract/numeric-compiler-phase-history/compiler-invocation.json`
- `evidence/source-results/fixtures/thread-completion-contract/balanced-compiled-suite-history/compiler-configuration.json`

The latter is an embedded configuration projection, not a recovered executed
command; that distinction remains unchanged. The current source lock and
completed producer are the ones used by the passing default-profile interpreted
379-file stage, not its old O0 predecessor.

## Consequence

The existing `native_compiler_options_correspondence` and
`native_compiler_configuration_correspondence` protocols require a strictly
lower optimization level for those specific cost-retry routes. O1 to O1 does
not satisfy them. Removing a duplicate sibling-call option is not established
as a cost reduction. A changed compiler image alone does not show that the old
C-to-module timeout has been addressed. No full compiled retry is launched on
these unchanged cost premises, and no rule or original budget is relaxed.

Next compiled work must establish a source- or command-bound cost change that
is relevant to the actual failed phase, then model and test its retry contract.
Previously passing runtime protocol changes remain necessary for correctness,
but cannot by themselves explain a historical C compilation timeout. Native
default-profile topology qualification can advance independently on the same
producer without reinterpreting either old timeout.
