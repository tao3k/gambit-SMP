# Shared task supervision: Grok adapter

Use the single installed entry, `gambit-smp --task TASK agent`. The direct module
and imported `main()` delegate to the same dispatcher. The adapter fixes
`grok-4.7` and `high`, records authorization references, and uses the exact same
Python task execution/reconciliation/completion/retention core as Codex.

```sh
# Reviewable specification only; --execute requires current authorization.
gambit-smp --task repair-9-12 agent \
  --owner diagnostic \
  --prompt-file .cache/tasks/repair-9-12/agents/diagnostic/prompt.txt \
  --authorization 'Current user consent for this exact scope' \
  --script <sealed-program-key> --max-turns 10
```

Programs are admitted through `workspace migrate-script` and stored inside
`.cache/tasks/TASK/programs`. `--script` accepts a sealed program key, not an
arbitrary owner Python filename. The exact terminal grant invokes
`workspace run-script`; edited or disabled programs cannot reuse their seal.
The adapter grants editing under the owner directory, not the durable registry.
Source/grant review precedes execution. This document does not restart Grok.

Nested tools reuse a held descriptor. When the provider closes inherited FDs,
a private authenticated local broker passes the same real lease through
`SCM_RIGHTS`. A lost capability is not replaced by a boolean. The parent attempt
and all recorded child groups must be quiescent before task reconciliation or
completion. A failed/turn-limited/timed-out provider attempt requires explicit
`workspace resume`; a provider UUID must also match durable task/owner/authorization
custody before `--resume` is accepted. These operations do not recover native
pending joins, reset native budgets or admit a runtime.

An inherited nested `workspace run` cleans up its own process group and its
registered descendants. It leaves the provider and sibling groups in the same
task run to their respective owners. A planned birth without a resolved group
remains an unresolved cleanup result.

Each launch defaults to ten turns. An explicit scoped launch may request up to
fifteen. Review the diff and artifact receipts before the next authorized
launch. Resuming a provider conversation applies the new launch's own turn
budget. Account usage and native acceptance remain separate.

A fresh private `grok-runs/NNNN` directory records each attempt. Raw thought,
tool and debugger streams remain private; only session/termination metadata is
extracted. Prompt content is replaced by a digest in reviewable specifications.
CLI end-turn is a provider event, not native descendant quiescence or acceptance.
Negative attempts retain their outcome when raw artifacts later expire.

## Live instruction transport

The current launcher uses one headless prompt with stdin closed. A running
headless attempt cannot receive an interjection through this launcher. A new
instruction can be supplied on an authenticated resume after that attempt is
reconciled. That is a new prompt, not an in-turn delivery.

The supervisor creates a private session context with native project permission
rules for read, search, edit and shell operations. A retained control attestation
binds the active provider executable, the Python framework source tree, task
registration and real positive and negative control events. The interpreter
and third-party dependencies are not covered by this source fingerprint.
Live ACP is refused when those
fingerprints do not match. `GROK_CONFIG` does not enforce permission rules;
an earlier negative control demonstrated that the overlay alone allowed an
outside read. The native rules and corrected tool names have since been tested
in real sessions. Session resumes must retain the original context and policy.

When admitted, `agent --acp --execute` starts the provider through the same task owner and
process journal. Once the prompt is active it exposes a private local control
endpoint bound to the task run, owner, provider session and authorization
reference. Use `agent --interject-file PATH --interjection-id UUID` with that
same task, owner and authorization to send an owner-local instruction. The
instruction ID is durable and a retry with the same ID and bytes returns the
existing receipt without sending again. A different instruction requires a
different ID. The endpoint closes when the prompt ends.

The provider's `queued` response confirms admission to its buffer. It does
not attest model consumption. A timeout, connection loss or interrupted
dispatch has an unknown outcome and cannot authorize a blind resend. ACP
permission requests are evaluated against the registered task profile and
the same session ID. Only one-time approvals are selected. Unknown, ambiguous
or outside-profile requests are refused. ACP session adoption is not supported.
An already-running headless process cannot be converted into an ACP session.

See [task lifecycle](task-workspace-lifecycle.md) for one task identity, two-day
retention, source/Git custody and actual interruption tests. Local test doubles
exercise process and descriptor behavior without contacting a model service.
