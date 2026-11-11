# Original interpreted stress with a source-bound datagram observer

## Actual result

The original runner reports **PASSED ALL 4 UNIT TESTS**, exit zero, no timeout.
The unchanged files are TFIB, interrupt2, interrupt and terminate stress. Their
source bytes, assertions and fixed workload parameters were not rewritten.
The runner's stdout is retained verbatim in `gc-datagram-original-suite.md`.

- Original stress group: **1828.146 seconds**.
- Supervising process: **1844.205 seconds**; parent reaped, process group quiescent.
- Original runner cumulative timestamps: TFIB 1536.3; interrupt2 1730.4;
  interrupt 1808.1; terminate 1828.2 seconds. These are rounded cumulative log
  values, not independent precise per-file timers.
- Host-derived allocation: one driver and eleven tested VM processors on a
  twelve-CPU host. The host numbers are observations, not configured constants.
- Source, configure, seed and core stages were reused, each with
  `executionLaunched=false`. **No bootstrap was repeated.**
- The unchanged 300-second genuine-witness inactivity window did not impose a
  total-wall limit. Stable inputs and natural original assertions determined PASS.

## Identity

- Source lock: `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
- Cumulative patch: `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
- GSI: `f4e12910d834d9e46346241e90fee3c65053d57acda84f9478910e7dd36a848f`.
- Frozen execution engine: `d90f207bc5e83dc1e1d41953ee8960013e96fb95b37bbec9a2f7016fca70239f`.
- Installed ASCENT: `e119827e588ea7b6d8a3195ac8e0ee8f61de6c11`.
- Observer Scheme: `d2846ef4c50d6c4027e73b437b386c62d4e0a17a40ef727e82098aee758da3ff`.
- Generated observer C: `b7ba177828bd2e8e632720fbdc84da4ce1c8d9de9424c5918d361c235173166f`.
- Loaded observer: `d56af2ee14cb1304627766060d9ec9e1446bc7be9b7fd04555f31b286a4f06aa`.
- Outer receipt: `5d11476d35f918455b781c9ede71513106d32f0778af9eb625cffc76209d6572`.
- Child recipe receipt: `0066035bcc76b76c0b558977e7dcb3cbb94ebcd1e2b8a019c2a23663b2a9d5ca`.

## Observation boundary

Human-readable GC printing was never enabled. The separately compiled module
uses the standard loader and a no-argument void FFI callback. It sends a fixed
40-byte, nonblocking loopback datagram; it does not format reports or write
Scheme ports. GC-job FIFO traversal reads an existing list. The generated
callback has no argument/result conversions or Scheme heap allocator call.

A separate control process checked **10,000 direct callback invocations with
zero measured Scheme allocation**, then exercised real forced collections.
That control passed in 2.077 seconds. Its direct calls simulate notifications;
they are not original stress or physical-GC evidence. The four original files
do not invoke that diagnostic entry point.

The original run records 76,593 renewal events, including four runner file
completions. This is not a count of physical collections or total datagrams.
The highest callback sequence may skip dropped or reordered publications.
134 packets were discarded by strict validation; their individual rejection
reasons were not recorded. Do not invent those reasons or claim lossless delivery.
No malformed packet was repaired or used to renew the watchdog.

Actual PID, per-file cookie, fresh launch epoch and source identity bind accepted
records. All four actual file cookies were checked distinct. The current adapter
adds an explicit collision rejection before launch; it does not alter launches
with these observed distinct cookies. It also removes literal allocation verdicts
from transport metadata: allocation qualification belongs to source/control
evidence, not a hardcoded Boolean. Those post-run changes are not misrepresented
as having run inside the frozen engine above.

This establishes complete original interpreted stress under this declared
observer. It is not an uninstrumented timing comparison, a universal scheduling
noninterference theorem, whole GC/FFI qualification or release admission.
Earlier human-report interleaving and inactivity failures remain historical;
they are not evidence that this successful original run deadlocked.

## Framework qualification

The complete dispatcher passed **1794/1794**, zero failures/errors/skips and no
changed inputs, in 467.467 suite seconds. Receipt:
`70a2e6baf708c4a47b8c72d2e4bbc70d30062632d57f7de0f4612be9afe6be58`.
Subsequent raw-input projection, metadata and cookie-collision refinements
passed 44 focused tests, including real loopback transport and cross-process
recovery; they are not represented as another complete dispatcher run.

An actual concurrent-read failure was also reproduced and corrected: read-only
inspection now returns an authenticated immutable prefix with `prefixStillHead`
and its observed head identity. It preserves raw recorded input bindings and
grants no execution authority. Recovery used for execution still requires the
current prefix; no live process or stage was launched again to fix inspection.
