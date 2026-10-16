# Compiler Image Configuration Correspondence

## Previously Missing Balanced Evidence

The original balanced compiled suite records three jobs, three child processors
and one runner processor per job, under a 300-second whole-suite cap. This equals
the current shared resource plan. Its missing configured-driver digest cannot
be borrowed from numeric or PR1037 receipts.

An independent artifact was located and checked: the original gsc image SHA-256
is `d1d4d12d0b4efe2c330b3685f3601ceff949b27595a5e1046f73fd78ed62e59f`,
matching both the original suite receipt and its exact candidate identity
`c00987439e0ec02297202cb9c265ddb774a77768aa543325d0a3a492a5ae1224`.
The image contains one unambiguous null-terminated configure string with
`--enable-c-opt=-O1`, `--enable-c-opt-rts=yes`, `--enable-gcc-opts`, GNU gcc-16,
and all three SMP/multiple-VM switches.

This is source-supported metadata: `lib/os_setup.c` initializes
`configure_command_string` from `___CONFIGURE_COMMAND`; `lib/_kernel.scm`
exposes it through `os-configure-command-string-saved`. The framework inspected
the image as data. It did not execute the historical VM or consume it as a new
producer.

## Evidence Type And Limits

`native_archive --compiler-image` checks the semantic failed-suite archive,
exact receipt/identity/image hashes, GNU description and stable bytes before
and after extraction. It records offset, raw string length/hash and portable
arguments. Personal prefix/compiler paths are projected, not copied into Git.
Ambiguous strings, unknown/duplicated optimization, conflicting concurrency
flags, compiler mismatch, changed image and existing output are rejected.

The versioned observation is
`evidence/source-results/fixtures/thread-completion-contract/balanced-compiled-suite-history/compiler-configuration.json`.
The original configure-string hash is
`153f93fceafd5d3f9133f355a06688a37ac40f8453ca45ba41cec1785a1b6c56`.
It explicitly retains `historicalDriverSha256=null` and
`historicalCommandObserved=false`. Embedded build configuration is not proof of
the later driver bytes or exact command actually used by the failed suite.
The original whole timeout's unique cause and failed subphase remain unknown.

For a fresh checkout, this archived observation is historical evidence, not an
executable input. Recollecting it requires the original hash-bound image; if that
image is unavailable, do not manufacture a new collection from another binary.
Current execution must still use the source-locked completed current producer.

## Model And Verification

`native_compiler_configuration_correspondence.qnt` exhausted 16,385 distinct
states, 245,763 generated, empty queue. The bypass counterexample is retained
(156 distinct / 198 generated); four positive/negative trajectories passed.
The model checks image/identity/current binding, complete scope, unchanged
budget, enabled flags, compiled-budget category and explicit review. It forbids
turning this observation into a recorded command, driver hash or runtime pass.
This finite correspondence model is not a C memory-model or GC proof.

Twenty-six focused archive/Grid framework tests passed. No budget, old failed
receipt, native flag or Gambit source was changed. The complete Grid remains at
11/12 retry-eligible routes: integrating this distinct evidence type into actual
Scheme policy and exact causal intent is still required before balanced can
qualify. No native suite has been executed on the strength of this observation.
