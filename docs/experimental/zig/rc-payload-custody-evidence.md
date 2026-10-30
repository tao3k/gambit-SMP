# RC Custody and Teardown: Source and Paper Evidence

Reviewed: 2026-10-20. Research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; vendor Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Whole-file SHA-256 bindings and
selected spans are in the [trace map](rc-payload-custody-traceability.json).
These are working-source correspondence and conditional deductions, not installed
Darwin/OpenSSL/collector qualification. No implementation or native test ran.

## Selected Source Ledger

| ID | Reviewed source span | Observation / limit |
| --- | --- | --- |
| PC-S01 | [`mem.c:674--829`](../../../vendor/gambit/lib/mem.c#L674), [`gambit.h.in:11309--11315`](../../../vendor/gambit/include/gambit.h.in#L11309) | Intrusive RC header has prev/next/refcount/data. alloc_rc registers; addref/release/data operations use ordinary mutations. cleanup_rc resets list and frees all remaining headers without checking refcount. It is not an independently refcount-drained service domain. |
| PC-S02 | [`mem.c:3969--3989`](../../../vendor/gambit/lib/mem.c#L3969), [`6839--6851`](../../../vendor/gambit/lib/mem.c#L6839), [`candidate patch:3433--3452`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3433) | mark_rc traverses the processor RC list and passes data by address to mark_array. Vendor calls it in the processor-0 branch; candidate makes it per processor. Root-owner/list migration and nonzero-processor coverage cannot be assumed from native allocation. |
| PC-S03 | [`os_io.c:3929--3972`](../../../vendor/gambit/lib/os_io.c#L3929), [`4142--4160`](../../../vendor/gambit/lib/os_io.c#L4142), [`4550--4564`](../../../vendor/gambit/lib/os_io.c#L4550) | TLS context RC allocation owns five optional string fields and SSL_CTX pointer; destructor releases strings/library context/RC block. Wrapper-conversion failure invokes same destructor. Complete live child set and provider effects matter; TLS worker admission is not established. |
| PC-S04 | [`os_io.c:5804--5815`](../../../vendor/gambit/lib/os_io.c#L5804), [`6048--6063`](../../../vendor/gambit/lib/os_io.c#L6048), [`6108--6120`](../../../vendor/gambit/lib/os_io.c#L6108), [`10868--10925`](../../../vendor/gambit/lib/os_io.c#L10868) | Server saves raw tls_context_p, and later accept dereferences it for SSL_new; opening extracts pointer from Scheme foreign object. No enclosing-context addref is inferred from a library reference. This is a real borrower obligation, not a current-source UAF finding. |
| PC-S05 | [`_io.scm:8583--8605`](../../../vendor/gambit/lib/_io.scm#L8583), [`8487--8511`](../../../vendor/gambit/lib/_io.scm#L8487), [`_io#.scm:659--673`](../../../vendor/gambit/lib/_io%23.scm#L659), [`846--861`](../../../vendor/gambit/lib/_io%23.scm#L846) | Server creation passes tls-context and preserves psettings in the server port; psettings includes tls-context. Existing managed retention is credited. Moving to native tasks requires preserving or deliberately replacing this user chain under the managed contract. |
| PC-S06 | [`os_io.c:1591--1623`](../../../vendor/gambit/lib/os_io.c#L1591), [`10094--10128`](../../../vendor/gambit/lib/os_io.c#L10094), [`10160--10177`](../../../vendor/gambit/lib/os_io.c#L10160) | Example raw device allocation is ordinary ALLOC_MEM, with device refcount/free and conversion rollback to device_cleanup. Not every foreign object payload has an RC header. |
| PC-S07 | [`c_intf.c:1729--1809`](../../../vendor/gambit/lib/c_intf.c#L1729), [`3228--3253`](../../../vendor/gambit/lib/c_intf.c#L3228), [`3576--3607`](../../../vendor/gambit/lib/c_intf.c#L3576) | Strings/lists use RC storage; string-list final release walks elements. Allocation/ref/disposition closure can involve multiple native blocks. Existing error funnels are a modern C reuse baseline. |
| PC-S08 | [`os_dyn.c:744--785`](../../../vendor/gambit/lib/os_dyn.c#L744), [`c_intf.c:6509--6550`](../../../vendor/gambit/lib/c_intf.c#L6509) | C closure uses alloc_rc, data=proc, generated trampoline/self identity; stack marker later reads data_rc. Commented marker GC/TLS concerns remain unresolved. Arbitrary closure copying or VM-independent survivor status is not established. |
| PC-S09 | [`c_intf.c:1683--1713`](../../../vendor/gambit/lib/c_intf.c#L1683), [`2838--2856`](../../../vendor/gambit/lib/c_intf.c#L2838), [`5176--5191`](../../../vendor/gambit/lib/c_intf.c#L5176), [`_kernel.scm:3869--3910`](../../../vendor/gambit/lib/_kernel.scm#L3869) | Foreign release clears fields before callback; generic pointer conversion/address access exposes raw pointers; pointer-to-Scheme with nonnull processor constructs a still foreign wrapper. Wrapper status/ownership and task/storage transfer need an explicit common authority. |
| PC-S10 | [`mem.c:1487--1498`](../../../vendor/gambit/lib/mem.c#L1487), [`1676--1689`](../../../vendor/gambit/lib/mem.c#L1676), [`4389--4455`](../../../vendor/gambit/lib/mem.c#L4389), [`4928--4939`](../../../vendor/gambit/lib/mem.c#L4928) | Still allocation prepends list; sweep invokes release for unreachable wrappers; final free_still_objs detaches the head to a private cursor, releases remaining foreign wrappers and frees them; cleanup_rc follows. Private discovery survives a zero public head. Reentrant creation is a conditional countermodel requiring separately admitted effects. |
| PC-S11 | [`os_io.c:183--194`](../../../vendor/gambit/lib/os_io.c#L183), [`1625--1670`](../../../vendor/gambit/lib/os_io.c#L1625), [`11807--11831`](../../../vendor/gambit/lib/os_io.c#L11807), [`11895--11907`](../../../vendor/gambit/lib/os_io.c#L11895), [`11936--11955`](../../../vendor/gambit/lib/os_io.c#L11936) | device cleanup unlinks before close/wait; group cleanup frees group even after error; pstate closes wake handles; module cleans group and provider globals. These are separate work/user/dependency cuts, not a deferred task drain protocol. |
| PC-S12 | [`setup.c:4572--4606`](../../../vendor/gambit/lib/setup.c#L4572), [`4626--4630`](../../../vendor/gambit/lib/setup.c#L4626), [`4839--4885`](../../../vendor/gambit/lib/setup.c#L4839), [`mem.c:4938--4971`](../../../vendor/gambit/lib/mem.c#L4938), [`os_setup.c:3224--3237`](../../../vendor/gambit/lib/os_setup.c#L3224) | Pstate/VM/global cleanup orders memory before OS; global cleanup shuts interrupts/resizes, then pstate/VM/module teardown. VM cleanup destroys scan synchronization before residual pstate cleanup. A new task cannot depend on already destroyed participation/scan/OS support. Non-single-VM global cleanup holds vm_list_mut around VM cleanup. VM cleanup explicitly revisits processor-0 memory cleanup; repeated teardown needs disposition identity. Source TODOs do not prove processor-wide completeness. |
| PC-S13 | [`candidate patch:3160--3234`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160), [`4362--4385`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4362), [`4482--4505`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4482) | Joined donor transfer splices still/RC lists to live receiving pstate and then clears donor state; successful join is checked at callers. Credit existing C support. No service survivor, arbitrary concurrent list move, failure-join success or native result is inferred. |

The paths shown with `%23` in Markdown denote the literal `#` in `_io#.scm`;
trace entries use the actual filesystem spelling. They are local source links,
not claims about an upstream deployed checkout.

## Primary Literature / Interface Ledger

| ID | Source | Narrow use and qualification boundary |
| --- | --- | --- |
| PC-P01 | [Herlihy and Wing, Linearizability (1990), author-hosted paper](https://cs.brown.edu/people/mph/HerlihyW90/p463-herlihy.pdf), abstract and sections 1--2 | Motivates a legal sequential handoff state machine and an explicit ownership cut between invocation and response. It does not prove RCO05, its memory ordering, alias census or progress. |
| PC-P02 | [Dijkstra and Scholten, EWD684](https://www.cs.utexas.edu/~EWD/transcriptions/EWD06xx/EWD684.html), stock/deficit/termination argument | Work decided but not sent belongs in termination accounting; finite generation is an explicit scope premise. This motivates private cursor/reservation permits. Our centralized I/J/N/D ledger is not the distributed cornet algorithm and inherits no theorem without its own premises. |
| PC-P03 | [Maged M. Michael, Hazard Pointers (2004), IBM Research publication abstract](https://research.ibm.com/publications/hazard-pointers-safe-memory-reclamation-for-lock-free-objects) | Safe memory reclamation/reuse and ABA require dedicated lifetime mechanisms. This study cites the accessible author-organization abstract only; it does not implement hazard pointers or claim their lock-free/progress bounds for a mutex/list handoff. |
| PC-P04 | [OpenSSL SSL_CTX_free manual, description and warnings](https://docs.openssl.org/3.4/man3/SSL_CTX_free/) | Library refcount disposal may release nested objects and invoke configured session-removal callbacks. It does not retain the enclosing Gambit allocation. This reference identifies possible effect edges, not the installed library/configuration or an admitted callback profile. |
| PC-P05 | [Zig language reference 0.15.1, Lifetime and Ownership](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership) and [errdefer](https://ziglang.org/documentation/0.15.1/#errdefer) | Pointer lifetime remains the programmer's responsibility; lexical ordinary-error cleanup can help precommit construction. It does not transfer RC headers/GC roots, drain borrows, enforce affine task ownership or release accepted asynchronous custody. |

Publication/manual/tool identifiers are evidence identities, not architecture
names. The Toronto full-paper hazard-pointer endpoint timed out, the WG21 PDF
endpoint returned 403, and the ACM deadlock-paper PDF was unavailable. No detailed
algorithm/theorem is attributed to those unseen contents. The operational-rank
argument in this study is an explicit project deduction, not a quoted result
from an unread deadlock paper. All primary-source summaries are bounded to their
selected mechanisms; no upstream performance result is adopted.

## Evidence Boundary

RCU/PC-S rows are selected actual-user/source correspondence, not a complete FFI
export inventory. RCP/RCO/RPS/RDD and RCT/RCX are proposed contracts, conditional
paper arguments and logical countermodels. In particular, root transfer remains
conditional on PA03/PA04 and the worker/effect/frontier gates, even when header
rewiring is structurally straightforward. The [cost matrix](rc-payload-custody-cost-matrix.md)
keeps shared reconstruction benefits separate from any Zig-only increment.
