# Current Repair: Observable Consumer Interfaces

## Scope

Two missing interfaces refine existing models, without changing their bytes,
their historical receipts or the runtime. Both concern current repair; no new
host attachment API, root ABI or collector organization is selected. Such a
mechanism redesign still belongs in Experimental.

The reference candidate is the retained mutex-return source lock, not an
assertion that every later native candidate has identical behavior. Source
correspondence must be reviewed for the implementation task's exact successor.
The accepted candidate and the cumulative patch remain unchanged by this work.

## Delivered Invocation Versus C Admission

`handler_admission_window.qnt` imports `runtime_generation_recovery.qnt`.
Its delivery epoch is ghost state representing OS causality, not an immutable
token available to C at delivery. It splits delivery-before-first-instruction,
C entry, registry admission/rejection and actual invocation return.

The retained cumulative patch maps `user_intr` to
`___raise_root_user_interrupt`. Its `vm_registry_enter` counts readers only
after the gate CAS; `vm_registry_leave` releases that counted lease. This is
valuable admitted-reader accounting but does not enumerate already delivered
invocations that have not executed that CAS. Uninstalling a handler and draining
those counted readers do not establish the missing OS lifetime premise.

The new negative control permits reopening while the C count is zero and an
old delivered invocation remains outside C. It then reaches new-generation
admission. The positive protocol waits for actual invocation completion in the
finite ghost population; its completion control excludes a permanently closed
gate as the reason for safety. It does **not** supply a source implementation
or a generally observable OS-drain operation. Native recovery and old-handler
quiescence therefore remain open, rather than becoming model PASS credit.

## Registered Roots Versus Last In-Flight Access

`saved_stack_last_access.qnt` imports the unchanged root-closure model, which
already composes the unchanged arena and saved-frame retirement models.
The original declared-root safety remains independently checked. An additional
reader interval can outlive retargeting the declared origins and draining the
published target work. This is a possible omitted consumer, not an assertion
that a particular native C read is outside the existing collector protocol.

The distinguishing negative schedule keeps the original root protocol safe
while reusing storage before that additional last access. The conditional
positive protocol includes that consumer in the reuse premise; a completion
control requires a real started/returned reader followed by reuse. No guard is
claimed to have been added to Gambit.

The source work remaining is to enumerate actual saved-thread slots, receiver
break links, older frames, escaped continuations, private scan work and C/FFI
tails; identify the surviving scanner/consumer and the actual last-access
boundary for each supported path. Source scope includes no-GC shrink, ordinary
and exceptional return, and half/incarnation reuse. Legitimately empty sets
require a scoped absence witness, not a nonempty-list rule. A pointer to a
PERM carrier alone does not establish payload scanning.

Chez's preserved thread-context/continuation carriers and explicit scans, and
OCaml's stack-parent/handler traversal and completion handshakes, support these
questions. They do not prove that Gambit has the same protocol or defect.
The existing root-closure Recipe and source sections remain the source owners;
this extension does not replace them with another source census.

## Proof And Handoff

`RepairConsumerInterfaces.lean` imports existing `WorkAccounting` and states
parameterized invocation-drain, public/private consumer composition and epoch
separation lemmas. Complete enumeration and actual discharge are explicit
premises. The guarded existing Lean driver checks elaboration and axiom output;
neither a theorem nor a finite QNT check authenticates a native event.

Implementation handoff requires the exact source/configuration, actual consumer
enumeration, mapped acquire/release or collective order, failure/exception
paths and a discriminating original-producer observation. An entry counter
cannot substitute for OS lifetime, and root retargeting cannot substitute for
the last consumer. A different source mechanism can satisfy these obligations;
the models do not dictate a lock, TLS change or Agent investigation sequence.

The existing current-repair Scheme view binds model/checker/proof/source review
identities and exposes the remaining correspondence as a counter. Withdrawing
or changing a bound premise must expose its gap, never close a native contract.
