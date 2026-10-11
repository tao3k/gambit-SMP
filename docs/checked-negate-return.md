# Checked Negation Return

This is a residual correctness repair, not a replacement for PR988/PR1038 and
not a Darwin-specific or SMP root-cause claim.

The original compiled `01-fixnum/fxmul.scm` fails its overflow assertion for
`(fx* -1 (##least-fixnum) -1)`. The generated C correctly branches on the
checked multiplication predicate. In `include/gambit.h`, the multiplier-minus-one
branch assigns `___FIXNEGP(x)` but unconditionally reports success, including
when `x` is the least fixnum. The one-line candidate uses the existing
`___FIXNEGP_NOTFALSEP` predicate instead.

The bounded QNT model covers representative boundary values and aliased and
separate destinations: 17 distinct states, 27 generated states, empty queue.
The old implementation has a frozen counterexample. Actual GNU GCC header
tests cover 18 cases; the original fails three minimum-value cases and the
patched header passes all 18. These are not a proof of general C arithmetic.

Runtime020 completed a real GNU GCC core rebuild with the exact header patch.
Core binary bytes may remain identical because this header macro is consumed
when compiling user modules. This is not a complete two-pass bootstrap.
The unchanged upstream fxmul test then passes interpreted execution in
0.070 seconds and compiled execution in 10.368 seconds under the original
20-second per-mode budget. No assertions were removed or weakened.

Receipts remain under `.data/checked-negate-runtime-020` and
`.data/upstream-fxmul-020-atomic`. Complete compiled upstream tests, threaded
bootstrap, Linux and Gerbil acceptance remain open.
