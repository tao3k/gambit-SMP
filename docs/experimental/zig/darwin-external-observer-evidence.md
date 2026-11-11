# External Darwin Observer: Source and Platform Evidence

Date: 2026-10-20. Companion
[capability and calibration design](darwin-external-observer-design.md).
All evidence here is from static reads and primary-source web research. No
DTrace/ES initialization, listing of live probes, permissions/audit changes,
compiler/linker, fixture, trace or performance workload was run.

## Evidence Map

| ID | Inspected source / locations | Supported fact / limit |
| --- | --- | --- |
| X1 | /usr/bin/dtruss:212-272,393-416 | Thread-local syscall argument retention; string-oriented read/write display after copied memory. This is not proof of raw-byte fidelity, available variants or a complete live trace |
| X2 | SDK man1/dtrace.1:894-929,965-1002 | syscall/mach_trap return slots versus pid/fbt return slots; errno, pid/tid and time descriptions. Probe ABI/provider/emitter identity still needs live qualification |
| X3 | SDK sys/dtrace.h:1142-1185,1198-1268,1294-1298; man1/dtrace.1:800-814,877-878 | Buffer policy, per-CPU data/errors/drops, other dynamic/speculative loss classes and copy/scratch faults; rawbytes display option does not itself prove capture completeness |
| X4 | Apple published XNU kern_exec.c, exec_handle_file_actions:2736-3004 and failure-probe block:4633-4668 | Internal spawn fd transforms and error-bearing spawn/exec probes under CONFIG_DTRACE; rolling source is not installed-kernel identity/probe availability |
| X5 | Materialized Gambit lib/os_io.c:9146-9161,9182-9340; vendor os_io.c:9225-9261 | Real project spawn flags/inherit/dup/close/cwd actions plus fallback fd closure; neither source is an actual observed native invocation |
| X6 | SDK man2/pipe.2:description/return; close.2:description/errors; dup.2:description; fcntl.2:F_DUPFD/F_DUPFD_CLOEXEC/F_SETFD; man3/posix_spawn_file_actions_adddup2.3:description | Endpoint lifetime, shared references, fd flags and before-exec spawn action semantics. Does not establish a complete original fd snapshot or concurrency linearization |
| X7 | SDK man2/read.2,write.2:RETURN VALUES and vector-I/O sections | Actual completed byte count/EOF/error differs from requested length; finite records must bind vector boundaries and actual outcomes |
| X8 | SDK EndpointSecurity/ESMessage.h:199-261,2617-2687; ESMessageCore.h:60-77 | Exec fd descriptions may be a subset; ES process-generation/version/sequence semantics; no generic syscall-to-audit crosswalk guaranteed |
| X9 | SDK spawn.h:52,72-89,181-188; man2/posix_spawn.2:RETURN VALUES | Opaque action pointer and native spawn API/error distinctions; not a portable user-memory layout for reconstructing kernel effects |
| X10 | Apple archived SIP runtime protections; local dtruss.1m | Protected-process visibility and tool privilege constraints. No live protection/probe privilege check performed; no SIP changes proposed |
| X11 | Existing supplemental evidence design/ledger; historical d1510-object-request-cost.md Excluded Attempts | Previous output-layer/Scheme-delivery gaps and observer-context contamination boundaries retained; no performance promotion |
| X12 | SDK dtrace.h:108-117,257-273,345-383,505-519; usr/lib/libdtrace.tbd:1-6 | Raw data callbacks, error/drop handlers, mutable implementation interface warning, process-control APIs and x86_64/arm64e stub targets. No project-target link/runtime support established |

SDK root: `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk`, previously
resolved to MacOSX26.5.sdk. These installed headers/manuals/link stubs do not
identify the running DTrace implementation, current protection policy or past
D1510 platform. Research HEAD is `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
source-tree/patch identity boundaries from earlier ledgers remain in force.

Links: [shipped dtruss](/usr/bin/dtruss),
[DTrace man source](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man1/dtrace.1),
[DTrace library header](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/dtrace.h),
[DTrace kernel ABI header](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/sys/dtrace.h),
[link stub](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/lib/libdtrace.tbd),
[spawn header](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/spawn.h),
[fd API header](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/sys/fcntl.h),
[pipe manual](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/pipe.2),
[close manual](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/close.2),
[dup manual](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/dup.2),
[fcntl manual](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/fcntl.2),
[spawn action manual](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man3/posix_spawn_file_actions_adddup2.3),
[ES message header](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/EndpointSecurity/ESMessage.h),
[materialized Gambit spawn source](../../../../../.data/ci-source-patch-check/src/gambit/lib/os_io.c),
[vendor fallback source](../../../vendor/gambit/lib/os_io.c),
[previous supplemental ledger](darwin-supplemental-evidence.md),
[historical invalid controls](../../../../../patches/gerbil-v19-darwin/receipts/d1510-object-request-cost.md).
Host-local links can drift; the hashes below bind the actual read bytes.

## Primary Online Source Evidence and Its Scope

[Apple XNU kern_exec.c](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_exec.c)
was read at the named function/blocks on 2026-10-20. It supports candidate
spawn-action and failure-probe boundaries. Its comments distinguish Darwin's
in-kernel spawn from a fork/exec model. It does not prove this host exports
those probes, that user syscall tracing sees internal actions, or that any
provider supplies full fd/payload/process identity. Exact kernel/provider
qualification remains required.

[Apple archived SIP runtime protections](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/RuntimeProtections/RuntimeProtections.html)
was reread for protected-process tracing/attachment limits. This archived guide
is not a live audit of the current host. No recommendation to disable protection
or relaunch the workload as root is made.

Guessed Apple DTrace consumer/source and systrace raw-file URLs failed; no
conclusion depends on their absence. Oracle/third-party search results were not
used to qualify Darwin's return ABI or recorder semantics. The installed Apple
SDK/manuals and actual shipped dtruss are the nearer sources. A failed guessed
libdtrace.h filename was resolved to the existing dtrace.h, not treated as proof
that a native consumer interface is absent.

## Content Digests Read This Turn

| Source | SHA-256 |
| --- | --- |
| `/usr/bin/dtruss` | `bcad1cc5acd97fcfd28c889ee56121968de7a1d290051254537f5a2e4b084a57` |
| `/usr/share/man/man1/dtruss.1m` | `107ecdf1a98de716a28bff409c379bb809271974c42083268fb39d50d3c46c25` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man1/dtrace.1` | `bb92b5c4389002d76d0387f8641d49c6565b37a8858d22d79a059a933e2becc6` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/dtrace.h` | `8a7bab21a6934f0c453e70083f7d02b18a58180a0b94697056f299f739e3421a` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/sys/dtrace.h` | `52ff3efde25e6df9631e5d58cd1e5acc0169af261a0884794912732d20ace03c` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/lib/libdtrace.tbd` | `ad62632d9aefb0561888f39f932ab440e30bdc6da47830d1aee838eb846c2412` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/spawn.h` | `2d90f16beec60b2080553613234f004b58f384003feaa5eb809fe5e91b42b884` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/sys/fcntl.h` | `805fd8c695f8e5e1c327b6852382cc5533738bbfd8f18bc11f850531166e4fe8` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/EndpointSecurity/ESMessage.h` | `35cb9dd0fa3bc58d224fee5a39cb5ab5f648e124822ced7cba46f6031159b759` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/EndpointSecurity/ESMessageCore.h` | `a63c06e47c5ecf825da334a9db6c88516611183397313b22cc1ceff809883375` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/pipe.2` | `e1b9d9e1a50a8dbaf504d7e691680672054bd9e491b80173ef39644952b8940b` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/close.2` | `90217028d7a7ff139ddb419f0a7673446c2c65273a9996e1ad4d76e896c255ac` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/dup.2` | `bda76cc56fae4ded7d4ffc2c508dc81e3a49c7af72facd9f063739b11fcc907b` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/fcntl.2` | `75f4c8574c1778d501de61708cf08b785dd6adca432b9162c23ea042ba4ab644` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/read.2` | `abced071814b22402dd2e6886b38861153679ab6f1fa51f071579abd4a0bf38f` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/write.2` | `c901c9512813ba2542a4ab3cf59414a73a992e6865c07fbea7ca251cd2bd5bad` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/posix_spawn.2` | `0abbcdbe2fc62306f1d3b2aff6e00858ff03a0f0c20c312b9e58fb08caceb4f7` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man3/posix_spawn_file_actions_adddup2.3` | `6ef6b3dd0b138a0fcaecfb3f2c3263c4cf7ff6bb81fa5b0348740905f25a929f` |
| `.data/ci-source-patch-check/src/gambit/lib/os_io.c` | `e17daf7fb752e9eb85b8b6e6e4672d81ae05435332392cff273ceaf6f5f223fa` |
| `.data/gambit-smp/vendor/gambit/lib/os_io.c` | `c0e7dc077c7dd6b6a2ee39028506c8a6d5313d29f881bda22d056cd6fce7d93f` |

## Qualification Status

K01-K15 controls, A-D capabilities and V1-V9 unresolved verdicts are architecture
requirements, not executed results. No raw byte buffer, failed return, fd graph,
ES join or loss-free stream was acquired. The native-consumer candidate remains
version/architecture/permission-bound and unbuilt. Existing E-row, Scheme-delivery
and M2-M8 retirement gates remain open; no performance statement follows.

## Documentation Verification

479 local file references resolve; 161 Markdown tables have consistent columns.
K01-K15 and V1-V9 each occur exactly once in their calibration/verdict tables.
Both D2 sources render with D2 0.9.0 (dagre/theme 0); rasterized SVGs were visually
inspected for readable labels and clipping. These checks are document validation,
not a consumer build, probe census, raw trace, ES association or native result.
