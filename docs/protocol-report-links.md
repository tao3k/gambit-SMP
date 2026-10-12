# Exact-Head Protocol Report Coverage

`evidence/protocol-report-links.json` associates a finite protocol slice with a
specific upstream report. It does not add an unknown model to the base-case
catalog or weaken its identity checks. The exporter requires the registered
model hash, a digest-bound portable report snapshot, the same snapshot digest in
the model's context inputs, and a report head matching both snapshot and catalog.
Unknown identities, duplicate links, changed model/report bytes and unbound
contexts are rejected. New source or model versions require an explicit review.

`protocol_report_links` exposes the exact association in Datalog.
`reports_without_models` means absence of any registered finite coverage, not
absence of unresolved issues or a failed native route. Use
`protocol_reports_without_checks` to distinguish an association from an admitted
model check, and the contract/open/native queries for the remaining gates.
No relation here grants source-cause admission, runtime execution or release.

The first link covers the PR #1035 thread-abandonment contract at head
`ad2bd23fcc689ce76a96c725e4c579d77bcdc71d`. Its whole lock graph, waiter delivery,
priority queues and native tests remain outside the finite result; see
`thread-abandonment-completion.md`. Other reports remain independently pending.
