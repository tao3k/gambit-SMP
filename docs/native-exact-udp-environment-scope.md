# Exact UDP Environment Scope

The retained compiled atomic denial reports `udp_close.scm`, exit HI=70/LO=0,
`Operation not permitted` and `(open-udp '(direction: input-output))`. This is
the `023-compiled-atomic-udp-permission` route, not the containing compiler-budget
route in the same receipt. The pinned upstream file performs that exact open
before its close/assertion tests. Its SHA-256 is
`77523b3eb8ef8e5ff41e7bb3a32188ed27842339ffb8095bf54a96c4c98cab1e`.

The current-producer probe performs `udp-open`, checks its result and exits zero
under the same producer identity and host-derived processor count. Its existing
framework adapter rejects foreign producer observations, incomplete probes,
missing operations, source drift and unbound environment artifacts. Availability
does not establish that the full UDP test passes or explain compiler timeouts.

The Scheme DSL previously mapped only aggregate `11-network` to `udp-open`.
The reviewed projection now also maps exactly `11-network/udp_close.scm`.
It does not infer permission for arbitrary filenames under that directory.
Native policy controls deny an unrelated operation and an unaudited UDP file.

`native_environment_scope.qnt` independently explores exact operation/scope
matching and loss of source/review binding. Its bypass control must produce a
counterexample. The existing `native_environment_correspondence.qnt` separately
retains same-run producer/probe, original evidence and unchanged-budget premises.
Neither finite model is a formal proof of native syscall implementation.

Only a conditional retry is justified: preserve the complete 379-file compiled
inventory, original atomic-to-whole budget correspondence, all nested deadlines,
all three concurrency switches and the actual current environment observation.
The original receipt, identity and raw log are retained; no old raw-log digest,
passing suite or successful parent exit is invented. Other routes remain subject
to their independent source/configuration, scope and budget reviews.
