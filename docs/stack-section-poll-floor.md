# Physical stack floor after the protected write

The page-guard run bound a `gsi` SIGBUS to `stur x22, [x20,#-0x48]` in
`___H___thread`. The register target was 40 bytes before the section payload,
within the protected allocation prefix. The incident does not show a store to
the 24-byte `___msection` header itself.

The candidate records `start_of_tospace(stack_msection) + ___MSECTION_FUDGE`
when a processor installs a stack section. Darwin/GNU generated-code polls
also trip below that physical guard, independent of `stack_trip`. The finite
model checks that a stale low `stack_trip` cannot permit a bounded frame-write
burst past the section floor if every burst has an intervening poll and the
burst is no larger than the fudge reserve. The negative initializer omits the
physical guard and must reach a counterexample.

The compiler poll-frequency premise, the origin of any stale limit, concurrent
visibility and complete native behavior remain separate obligations. This
model does not turn the page-guard diagnostic into a native repair result.
