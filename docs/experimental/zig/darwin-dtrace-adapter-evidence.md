# Darwin DTrace Adapter: Evidence Ledger

Date: 2026-10-20. Companion
[architecture and qualification boundaries](darwin-dtrace-adapter-architecture.md).
Static source/header/manual reads and primary-source web research only. No
consumer build/load, live device/probe access, tracing or performance validation.

Research checkout HEAD: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
SDK alias MacOSX26.sdk resolves to MacOSX26.5.sdk; headers and stubs do not identify
the running library/kernel. Source identities from the
[previous ledger](darwin-external-observer-evidence.md) remain separate from the
materialized Darwin patch checkout.

## Source Map

| ID | Inspected source / anchor | Supports / does not establish |
| --- | --- | --- |
| N1 | SDK usr/lib/libdtrace.tbd:1-6 and exported symbols | TAPI v4 stub lists x86_64-macos and arm64e-macos; no literal arm64 target. Does not establish arm64 rejection, arm64e loading eligibility or callbacks |
| N2 | SDK usr/include/mach/machine.h:342-348 | ARM64_ALL/V8/E subtypes and pointer-auth version bits; not executable eligibility |
| N3 | SDK usr/include/dtrace.h:44-117,129-133,257-273,345-404,505-519 | Apple types, implementation-interface warning, version 3, D-model flags, callbacks/errors/drops and process-control APIs; not a stable cross-version Zig ABI |
| N4 | SDK usr/include/sys/dtrace.h:1070-1101,1142-1185,1198-1268,1294-1298 | Bitness-neutral kernel record descriptions, total size/offset/alignment, options, loss/fault classes; not universal bitness neutrality of user-library structures |
| N5 | SDK usr/include/dtrace.h:165-198,605-625 | Program match counts/attributes, EMPTY/ZDEFS flags, declared as well as device probe iteration and argument information; visibility and firing still need qualification |
| N6 | SDK man1/dtrace.1:894-929,965-1002; /usr/bin/dtruss:393-416 | Provider-specific return-slot distinctions and string-oriented shipped IO display; not lossless bytes or a live provider inventory |
| N7 | Published Apple XNU kern_exec.c:exec_handle_file_actions, CONFIG_DTRACE final failure block | Internal actions and limited failure hooks; no installed-kernel/probe equivalence |
| N8 | Apple archived SIP runtime protections | Protected-process tracing restrictions; not a current-host permissions audit |
| N9 | Materialized Gambit lib/os_io.c:9146-9161,9182-9340; vendor lib/os_io.c:9225-9335; SDK spawn.h:52 | Spawn recipe versus fallback/error pipe and opaque actions; not actual execution witnesses |
| N10 | SDK man2/read.2 and write.2; existing external-observer K01-K15 | Completed count versus request and proposed bounded IO controls; no calibration receipt |
| N11 | Published Apple dt_consume.c:2038-2079,2172-2199,2241-2275 | Callback pointer movement and action/format handling; published implementation is not installed-library identity |
| N12 | Published Apple ld64 textstub_dylib_file.cpp:92-121,365-380; Clang Pointer Authentication, C function pointers and language ABI | TAPI selection inputs and pointer-auth callback concerns; no local linker/loader or Zig PAC compatibility result |

## Local Source Links and Content Identity

| Source read | SHA-256 |
| --- | --- |
| [dtrace.h](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/dtrace.h) | `8a7bab21a6934f0c453e70083f7d02b18a58180a0b94697056f299f739e3421a` |
| [sys/dtrace.h](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/sys/dtrace.h) | `52ff3efde25e6df9631e5d58cd1e5acc0169af261a0884794912732d20ace03c` |
| [libdtrace.tbd](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/lib/libdtrace.tbd) | `ad62632d9aefb0561888f39f932ab440e30bdc6da47830d1aee838eb846c2412` |
| [mach/machine.h](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/mach/machine.h) | `f315bbdab024f89b45756410d1459c85cefe07316f57b67d0fdb2d0087fa6697` |

The previous ledger binds [materialized Gambit source](../../../../../.data/ci-source-patch-check/src/gambit/lib/os_io.c),
[vendor fallback](../../../vendor/gambit/lib/os_io.c),
[DTrace manual](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man1/dtrace.1),
[spawn header](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/spawn.h)
and IO manuals by hash. No source recipe is relabeled as an observed invocation.

## Online Primary Sources Read

- [Apple DTrace consumer source](https://github.com/apple-oss-distributions/dtrace/blob/main/lib/libdtrace/common/dt_consume.c): raw record and callback handling. Correct source path was resolved this turn; earlier failed guessed paths are not absence evidence.
- [Apple XNU spawn source](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_exec.c): internal file actions, failure probes and emitter-context distinction.
- [Apple ld64 stub parser](https://github.com/apple-oss-distributions/ld64/blob/main/src/ld/parsers/textstub_dylib_file.cpp): delegates architecture/subtype matching; does not independently resolve installed TAPI rules.
- [Clang pointer authentication](https://clang.llvm.org/docs/PointerAuthentication.html): typed indirect-call ABI obligations; not evidence of a particular Zig release's support.
- [Apple archived SIP runtime protections](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/RuntimeProtections/RuntimeProtections.html): platform restriction context retained from the prior ledger.

Apple rolling-main sources and current upstream Clang documentation are source
research references, not pinned binaries for this host. Publication paths are
recorded for review; runtime qualification must archive revision/content and
prove installed correspondence. A version-specific ld64 source URL failed to
fetch; no subtype acceptance rule was inferred from that failure. No third-party
workaround, boot argument or protection bypass is part of this design.

## Explicit Unresolved Results

All A01-A06 obligations remain unrun. In particular: native arm64 link/load
support; eligible arm64e distribution/loading and callback ABI; exact installed
consumer record behavior; target-specific live probe visibility; original libc
pre-syscall failures; complete spawn fd transitions; kernel-consumed byte fidelity;
DTrace-to-ES process-generation joins; and original Scheme state delivery.
These refine V1-V9, and close no E01-E32 acceptance row or M2-M8 retirement gate.

The maximum defensible future result is a set of qualified scopes with explicit
fidelity classes. There is no single platform-wide “DTrace supported” verdict.
