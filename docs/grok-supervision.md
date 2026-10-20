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
  --script <sealed-program-key> --max-turns 45
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

A fresh private `grok-runs/NNNN` directory records each attempt. Raw thought,
tool and debugger streams remain private; only session/termination metadata is
extracted. Prompt content is replaced by a digest in reviewable specifications.
CLI end-turn is a provider event, not native descendant quiescence or acceptance.
Negative attempts retain their outcome when raw artifacts later expire.

See [task lifecycle](task-workspace-lifecycle.md) for one task identity, two-day
retention, source/Git custody and actual interruption tests. Local test doubles
exercise process and descriptor behavior without contacting a model service.
