# Native Evidence Provider Contract

## Failure Boundary

The shared-budget Gambit source-core compiled and linked successfully, but its
final native Datalog verdict failed. The current Python evidence implementation
requires upstream native DSL operations; the selected API library exposed the
older open/replace/run/read-rules interface. Library hash agreement alone did
not establish interface compatibility.

This is an evidence-provider mismatch, not a Gambit compiler or GC failure.
The original complete campaign stays DENY. Passing source-core stages do not
override its verdict, and no full SMP, bootstrap or Gerbil admission is inferred.

## Preflight

Before creating a new seal, the framework probes the selected API and Python
binding in an isolated interpreter with the native backend explicitly selected.
It requires ABI 1 and open-sources, source-replace, source-run and close. Malformed
descriptions, missing operations, probe errors, timeouts and nonquiescent process
groups fail closed. The probe has a 10-second budget. Input bytes are checked
again after sealing; the observed provider contract participates in the seal ID.

An actual old-API control was rejected in approximately 0.072 seconds, before a
seal directory or expensive compiler campaign was created. This checks interface
admission, not native DSL semantics or the complete Datalog evidence graph.

## Provider Build Observations

The old Python-owned native library builder hit its unchanged 90-second budget
after expanding 444 modules and compiling phase objects. During that run the
upstream build adapter was changed by concurrent work to packaging only;
build.ss/std/make now owns compilation. The invocation's complete source snapshot
was not captured, so its observation is not source-refinement admission.

The subsequent std/make-owned build used 12 host-selected workers and GNU GCC.
It also hit the 90-second budget while compiling executable objects. No completed
library/receipt was published. Retain both budget denials; do not rerun either
unchanged whole build or describe them as passing native-provider qualification.

The next repair must identify object compilation costs/currentness under the
single upstream build owner, preserve source and artifact identities, and qualify
the real native DSL before evaluating the saved Gambit observations. An evidence
verdict repair does not justify recompiling the already successful Gambit core.
