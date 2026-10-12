# Numeric Compiler Gate: Current Configuration

## Route Review

The retained runtime021 numeric probe completed Scheme-to-C but timed out in
GNU C-to-module compilation. It is not evidence of a Scheme GC deadlock.
Do not repeat its unchanged O1/single-host/inline-jumps input or relax its
90-second whole-probe budget.

The current source-core producer's bound `bin/gambuild-C` instead has O0 for
both generated C and RTS, and lacks the historical driver's SINGLE_HOST and
INLINE_JUMPS definitions. These are causal compiler-cost inputs, not an
unrelated candidate rename. Its source/runtime fixes also differ, so this is
not a matched A/B speedup measurement. Expected benefit is admitting execution
of the original numeric assertions within the existing diagnostic budget;
the magnitude is unknown before observation.

Use the existing `compiler_cost` framework to regenerate the unchanged upstream
`03-number/_num.scm`, compile the new C using that exact configured GNU driver,
then execute on the same bound runtime. Bind actual source, compiler, driver,
generated artifact and observed parent exits; use available host processors.
Keep all three SMP/VM switches, all fixture assertions and the whole budget.
The original timeout stays negative evidence.

This is a phase probe, not full suite, bootstrap, production optimization,
source-refinement or performance admission. A completed O0 diagnostic cannot
replace optimized native correctness or retained Gerbil startup/build/test
performance gates. Separate Scheme, C compilation and execution times and
inspect the complete original result before asserting a pass.
