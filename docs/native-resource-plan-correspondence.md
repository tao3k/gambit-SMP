# Native Resource Plan Correspondence

The retained parallel compiled denial records twelve shards, twelve jobs and
twelve processors per child. Its exact receipt, identity, shard logs and source
inventory are in the semantic `parallel-compiled-suite-history` archive. The
recorded child population is 144. The receipt does not record original host
capacity or runner processor population: those facts must not be invented.

The current scheduler computes its topology from observed available processors
and selected files. Each parallel runner has one processor; its child population
and runner are jointly charged. On the current twelve-CPU host, three jobs with
three child processors each require twelve execution positions in total.
This is a real scheduling-input change, not a source/GC repair or evidence of
physical utilization. The old child lower bound and current complete demand are
different quantities; the latter is smaller even than the former.

The existing Python bridge transports a `resource-plan` change only with the
exact original denied receipt and current producer. It requires positive typed
populations, a matching original mode, corroborating original shard count, and
current fields equal to the actual shared-capacity scheduler. The projected
plan is digest-bound. Missing original metadata cannot be inferred from a
different campaign. Neither elapsed time nor local CPU load is used as a cap.

Scheme DSL determines eligibility. It requires a positive current total, no
current host-capacity violation, strict demand reduction and an explicit
`resource-plan-cause-review`. Only budget routes are compatible: assertion,
signal and environment failures are not waived. Exact scope, containing and
nested deadlines, producer binding and historical evidence remain independently
mandatory. `native_resource_plan_correspondence.qnt` retains nonreduction,
overcapacity, missing-binding and wrong-category counterexamples.

For the old parallel whole-suite timeout, this permits a materially changed
bounded investigation; it does not identify a unique timeout cause or establish
success. The later balanced three-by-three timeout is not repaired by the same
plan and must remain independently blocked. No `thread_start` fixture repair is
asserted as the cause of these earlier numeric-compilation timeouts.
