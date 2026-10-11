# Resource Users And Setup Rollback

## Decision Before Runtime Edits

The resource-retirement model excluded retirement during a published sender's
locked interval and collapsed resource users into one counter. This model
extends those obligations independently, preserving the original model and
its receipts. It is not a new native failure or a runtime patch.

The selected `SYNC_SEND_MSG` publishes, unlocks, then signals. `SYNC_GET_MSG`
can observe the flag on its spin path; its blocking fallback locks the mutex,
checks the predicate and calls `___sync_wait`. These exact source transitions
motivate separate holder, waiter and delayed-signaler states. No paper is
claimed to specify Gambit's processor-resource teardown. The collector papers
motivate retaining ownership until a worker can no longer produce work; the
source determines which resource uses must be counted here.

## Bounded Protocol

`sync_resource_users.qnt` contains one external sender and one receiver that
can hold the mutex or sleep on the condition variable. The sender has distinct
locked, published-but-locked, unlocked-before-signal and completed states.
Mutex exclusion and atomic condition-wait registration are assumptions.
The predicate loop permits the waiter to observe publication without waiting
for the explicit signal. Retirement after publication seals admission, but
does not cancel previously admitted operations: they must finish.

Successful mutex initialization is the initial condition. A nondeterministic
branch either initializes the condition variable or fails and rolls back the
owned mutex. This does not cover borrowed resources or failure of the initial
mutex initialization. No initialization failure is inferred from a native
report; this branch establishes a proposed repair's required failure contract.

Independent controls violate:

- Mutex-holder drainage, including publication while still locked.
- Sleeping-waiter drainage.
- External delayed-signaler drainage.
- Sealing new admission at retirement.
- Owned mutex rollback after condition initialization fails.

Destruction and rollback are candidate abstract actions, not implementations
already present in Gambit. Keeping resources initialized for the VM lifetime
remains an alternative design; this model does not rule it out.

## Acceptance Boundary

Attempt 004 used Quint 0.33.0 / TLC and admitted all six checks with stable
model bytes. Each of the five independent controls produced its own frozen
counterexample. The combined positive invariant exhausted 35 distinct / 56
generated states, depth 11, with two initial states and zero states remaining
on the queue. The holder trace retires the resources with `sender == 2`:
publication has completed but the sender still holds the mutex. The waiter
and signaler controls independently preserve the corresponding outstanding
resource users. The rollback trace retains an initialized mutex after failed
condition initialization.

The receipt is `evidence/model-results/sync-resource-users.json`; portable
negative traces are `models/gambit/counterexamples/sync_resource_users-*.json`.
The three earlier DENY receipts are retained beside it, separately classified
below. Raw verifier logs remain in local `.data/sync-resource-users-model-004/`
because they contain machine-local paths.

Keep verifier tool failures separate from protocol counterexamples. Attempt
001 failed parsing a parameterized action without its explicit return type;
no protocol check was admitted. Do not convert that failure into a model pass.
Attempt 002 failed the Quint-to-TLA+ translation of a shared initialization
action. Use direct initializer alternatives, as in the already working GC
membership model; both success and failure branches remain present.
Attempt 003 failed because the sandbox denied binding Apalache's local
translation-service port. That environment denial is not a protocol failure.
Admit a positive result only from a source-stable receipt with all five
negative controls and the combined invariant exhausted by TLC.

Even an admitted positive result covers only these finite safety obligations.
It does not prove nonterminal deadlock freedom, scheduling fairness, C memory
ordering, POSIX implementation behavior, slot-generation reuse, interrupt
producers or VM-wide cleanup. The epoch/work and scan-claim composition models
are separate obligations. Source refinement and native regression must follow
before any destructor patch; full bootstrap and Gerbil admission remain open.
