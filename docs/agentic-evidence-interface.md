# Evidence interface

Primary artifact: `evidence.json` (`ascent.agent-evidence.v1`).

| Field | Exact content |
| --- | --- |
| `definition` | Original Evidence view bytes, SHA addressed |
| `manifest` | Original component declaration bytes |
| `components` | Original declarations, dependency edges, raw DSL file descriptors |
| `facts` | Actual resolved inputs supplied to ASCENT |
| `queries` | Public query to relation mapping |
| `answers` | Actual ASCENT results, including empty relations |
| `bindings` / `references` | Complete original source identities and JSON pointers |
| `explanation` | Pointer into the unchanged review explanation |

Sources are copied byte-for-byte, never regenerated or paraphrased. Components
remain separate: read the selected entry's raw `.ss`, follow its manifest
dependencies on demand. No Python rule parsing, dependency slicing, new DSL,
downstream Scheme import or compiler. The Library still owns linking/inference.

Python: `gambit_smp.research_actions.discover(root, context)`,
`select(root, snapshot, action_id, inputs, request_id, authorize_execution=...)`,
`observe(root, request_id)`. Actual Working context:
`evidence/scenarios/concurrent-gc/action-context.json`.

Discovery returns bound facts, queries, actual answers and action IDs. The view
and its original component manifest identify the raw rules. Selection rechecks
revision and host authority. New evidence requires rediscovery. No automatic
MCP registration, model-context injection, server-side lazy inference or token
savings is claimed. A host must expose this entry in its tools/task context.

`context.md` is links only. `context.json` v2 binds every generated artifact;
historical v1 readback remains explicit and does not rewrite old identities.
The full graph and review retain complete rows, origins and explanation gaps.

Local Evidence is the observation surface for Working and other Agentic AI
consumers. Inspect actual source/review/model writes and recorded action results,
binding their exact bytes, receipt pointers and current candidate identity.
Rediscover after those inputs change; historical snapshots remain historical.
Chat acknowledgement is neither required nor an admission gate. A local write
establishes its recorded content, not the writer's identity, an unrecorded action,
or successful repair. Attribute execution only when its recorded provenance
supports that conclusion. No message to another chat is needed for local review.

Open-world, optional, unordered. DSL readability is not proof admission:
Agentic AI proposes/questions/edits; ASCENT computes; the host checks provenance
and the kernel checks execution authority. No method run or code change follows
automatically from a derived option. Interface qualification is not Gambit source
correctness, runtime repair or performance acceptance.
