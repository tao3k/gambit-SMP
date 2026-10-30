# Datagram witness: model, source and native correspondence

## Design and checks

The original report-forwarding failure is preserved. Human-readable GC messages
can interleave across processors; Scheme forwarding can itself allocate or wait
on ports. Neither permissive parsing nor a larger inactivity window addresses
that observation contract.

The replacement is a separately compiled module using the ordinary loader and
public no-argument void FFI. Its callback uses a fixed stack record, a one-shot
lock-free sequence publication and a nonblocking loopback socket. Contention or
send failure drops a notification; it never retries. It preserves errno, does
not format a report, and does not write a Scheme port. Registration allocates
before the original workload; each notification does not create Scheme values.
Generated C and a separate measured allocation control support that limited
source claim. They do not prove scheduler-neutral behavior on every OS.

`models/gambit/gc_datagram_witness.qnt` explicitly separates source binding,
active child, PID, per-file cookie, atomic framing, sequence freshness and GC
completion from mutator progress and admission. The positive finite protocol
has 38 distinct / 110 generated states, with its conditional drain property.
All twelve negative controls produce decoded counterexamples: allocating,
port-writing, blocking, interleaving, wrong PID, old file cookie with reused PID,
inactive child, wrong source, replay, fabricated completion, mutator attribution
and runtime admission. The source-bound receipt is
`6cec325ab572817f48984f7bc9ed5588ce8c6516ab7f42103ea385e1ca6a94be`.
Atomic datagram boundaries, nonblocking send and fair draining of pending
notifications are explicit assumptions, not a theorem that the application
eventually collects or terminates. The finite model is not C refinement proof.

The existing Scheme progress component retains strict identity and cursor
admission. Python only frames and transports observations. Wrong, truncated,
replayed or late datagrams cannot renew the watchdog; dropped events remain
missing. A quiet stdout/stderr does not disable socket polling: the existing
communicate loop invokes the observer on each bounded poll. Regression coverage
includes that actual loop and per-file identity changes with reused PIDs.

## Native evidence and retained failed attempts

The [original-suite result](gc-datagram-native-observation.md) passes all four
unchanged interpreted files. The fixed workload was not reduced. Its small
verbatim runner output is retained in [Markdown](gc-datagram-original-suite.md).
The GNU GCC profile and original 300-second inactivity semantics are unchanged.

Earlier attempts remain distinct failures: cross-recipe checkpoint migration
rejected before execution; unsupported dynamic compiler argument placement;
nonconstant file-scope atomic assertion; loader entry mismatch; unavailable
`##c-code` compilation context. Each was corrected through the existing build
or public FFI contract, not by accepting a failed native receipt. No bootstrap
was repeated for those adapter failures. Raw outputs remain disposable cache;
the portable source, model and final identities are versioned.

The current adapter additionally rejects cookie collisions before modifying the
driver. All four actual run cookies were independently checked distinct.
Post-run metadata refinements and the strengthened model are qualified
separately; they are not relabeled as the frozen native execution engine.

The run discards 134 invalid packets without individual rejection reasons. No
specific cause or lossless transport claim follows. A completed original suite
under this declared observer does not qualify every GC/FFI path, close historical
full-inventory failures, or establish release performance.
