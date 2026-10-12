# Combined Interrupt Result Model Result

The source-bound composition exhausts 47 generated / 28 distinct states with
zero queued states. Combined safety and the explicit weak-fair completion
property passed. Four controls were independently rejected:

| Restored failure | Generated | Distinct | Seconds |
| --- | ---: | ---: | ---: |
| Linked node at transfer | 2 | 2 | 5.171 |
| Wrong recipient / repeated delivery | 43 | 28 | 5.169 |
| Ended-target low-level lock leak | 41 | 26 | 5.275 |
| Abandoned result reported as success | 43 | 28 | 5.269 |
| Combined policy, safety and completion | 47 | 28 | 4.310 |

These are model-check times, not native startup/build/test times. The existing
driver selected CPU/memory capacity automatically and retained the original
90-second campaign budget. Publication checked current context hashes, compiled
artifacts, typed traces, safety and completed temporal logs.

Portable evidence is under
`evidence/model-results/fixtures/abandoned-result-state/interrupt-delivery-composition`.
The manifest is
`evidence/fixtures/abandoned-result-state/interrupt-delivery-contract.json`.
After the separately coordinated graph qualification became terminal, the
global bundle registry was extended with this composition, the real native
abandonment feedback model, and the corrected queued-waiter source dispatch
model. All three registered bundles passed current-context publication checks.
The earlier graph receipt precedes this registry change and does not qualify
the new inputs. Fresh full graph admission remains pending.

The model combines queue transfer and abandoned-result observation in one
interleaved state, but keeps native combined-fixture, source simulation,
GC-root/relocation, callback exception, requester cancellation and retirement
obligations open. Terminal result observation is not physical queue reclamation.
No new runtime patch, release admission or SMP-wide green is claimed.
