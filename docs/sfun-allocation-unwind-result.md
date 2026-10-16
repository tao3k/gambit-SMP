# SFUN Allocation Unwind Result

## Framework Observation

Recipe: `sfun-allocation-unwind-contract`.
Outcome: PASS, all 9 steps, 27.714560250 seconds within the 50-second
model-only ceiling. No native rebuild or qualification-budget renewal occurred.

| Obligation | Check | Result |
| --- | --- | --- |
| Correct root/catcher/lease ordering | safe, all nine fault pairs | 576 distinct states, queue empty |
| Throw must clear saved root | initRootLeak | Expected violation, 7-state decoded trace |
| Throw must release lease | initLeaseLeak | Expected violation, 8-state decoded trace |
| Cleanup must use the admitted processor | initWrongProcessor | Expected violation, 7-state decoded trace |
| Catcher restored before rethrow | initEarlyRethrow | Expected violation, 7-state decoded trace |

TLC uses the framework's available CPU count (12 observed), not a fixed runtime
worker limit. The two modeled processor identities are a finite state bound.
An initial typecheck rejected an unsupported `isEmpty` operator before launch;
the model uses the established set-size expression instead. No native failure
is reclassified by that correction.

Engine ID:
`fc943732ddf04239f2dd9426f57ad71f00af2b384ff04ecd77337fadffa7ff2b`.
Outer receipt SHA-256:
`926bfd32eb718cbfe0fd4bceef60e7500b9ee2a2baffe5ef848dbf1680e1086d`.
Child receipt SHA-256:
`77adad145c0ad990474d5091f92384614d95a6270143161b70d68682a2576846`.

Decoded counterexamples were copied byte-for-byte to
`evidence/fixtures/sfun-marker-explicit-context/allocation-*.counterexample.json`.
They do not contain machine-local paths. Their SHA-256 values are:

- root: `1fb2b3ac2c2adb4ed30a3a5e9ac17b2d1c47d50238588b75259aff5831469a40`
- lease: `9c9560bb5e59f99ca0a0e2d8123639435c6bdee904eb7a688e4c286a72a991e9`
- owner: `3c95b1e72d65de463f4aa4d41957cdf5dade65e149248bfb16037154e000c10b`
- catcher: `37b12964dad9fb1112b80e6a99ca15da515554cc78d1d33051448a21ffe3bb7a`

## Source Binding And Remaining Requirements

The source step validates
`evidence/fixtures/sfun-marker-explicit-context/source.lock.json` against the
pinned submodule and candidate patch, reusing the one retained source tree.
The framework's terminal ASCENT evaluation checked all required steps. This is
not yet a full protocol/source-refinement graph qualification or a native gate.

In addition to the four preceding GCC/G++ syntax checks, both G++ direct-import
and late-binding configurations pass with explicit `___USE_SETJMP`, exercising
the passed-processor catcher path as well as C++'s default exception path.
Those compile-only checks do not execute injected faults or private helpers.

The native successor still needs a source-bound bootstrap and public-path
allocation-unwind witness, followed by complete compiled/stress inventories,
lifecycle/registry/GC-FFI, Gerbil correctness and release performance. In
particular, this finite model does not prove allocation failure reachable in
the real runtime or arbitrary nested-callback correctness.

Cumulative progress remains 3/12; the source successor has not inherited the
old executable's qualification. The original qualification ledger remains
468.695876834 / 600 seconds, leaving 131.304123166 seconds. Per user direction,
no full rebuild is attempted under a new budget.
