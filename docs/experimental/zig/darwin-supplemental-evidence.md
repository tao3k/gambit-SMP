# Supplemental Darwin Source and Platform Evidence

Date: 2026-10-20. Companion
[failure/output/delivery design](darwin-supplemental-evidence-design.md).
Only static source/header/manual reads and official web research occurred.
No audit status probe, audit trail read, tracer, source hook or target process
was executed. Symbols, declarations and manuals establish possibilities and
limits; they do not establish a working original-context observer.

## Evidence Map

| ID | Read source / locations | What it establishes / limit |
| --- | --- | --- |
| F1 | Materialized Gambit lib/os_io.c:9146-9161,9182-9378 | Spawn/fallback route, first-error preparation checks, addchdir action, spawnp nonzero return converted through errno; no execution of this branch |
| F2 | Vendor lib/os_io.c:8500-8558,9251-9335,9547-9565 | waitpid raw-status ownership, fallback errno pipe, cwd sentinel, parent full/partial/EOF handling and stored-status exposure; distinct revision from F1 |
| F3 | Vendor lib/gambit/process/process.scm:76-149 | Fixnum OS-error versus process-port branch, cwd failure mapped to ENOENT, port drain/capture before status/continuation, environment inheritance |
| F4 | Vendor bin/gambuild-C.unix.in:155-193,239-283,333-411 | Shell metadata warnings to /dev/tty, unavailable resolver path, query command substitutions/set -e, CC/LD accumulation and native-mode eval |
| F5 | Vendor lib/_io.scm:7336-7389; os_io.c:3543-3595; materialized Gerbil driver.ss:395-457,1190-1206; base.ss:455-481; vendor gsc/_gsclib.scm:363-393,451-495 | Process-status wait/false/error/return logic, raw status commit, compile exception and job/barrier consumer boundaries; source-visible behavior, not original continuation observation |
| F6 | SDK EndpointSecurity/ESMessage.h:296-312,708-743,2617-2687; ESMessageCore.h:60-77 | OPEN/WRITE fields omit payload/returned fd or full syscall status; EXIT wait format and lifecycle/sequence identity support; no generic output-byte API established |
| F7 | SDK man2/posix_spawn.2:228-241; man2/execve.2:186-196; Apple archived spawn manual | Spawn nonzero function result/no child and execve -1/errno return distinction; current source/runtime still needs pinned qualification |
| F8 | SDK man2/read.2:157-164,write.2:162-167,dup.2:75-96,wait.2:169-203; local tty.4/script.1/bash.1:2541-2560 | Actual read/write counts/errors, shared descriptor references, raw wait decoding, terminal/session effects, command-substitution newline loss; cannot certify original stream completeness |
| F9 | Local audit_control.5:36-47,100-102,143-164; audit.log.5:34-45,374-392,550-570; SDK bsm/audit_kevents.h:75,593 | Documented deprecated/disabled legacy auditing, global policy effects, return/exec args/env token formats and exec/spawn event IDs; no actual audit selection or retained record proven |
| F10 | /usr/bin/dtruss:393-416; local dtruss.1m; Apple archived SIP runtime protections | String-oriented read/write formatting, error display and tracing/protection constraints; shipped tool not a byte-exact framed oracle |
| F11 | Prior darwin-observation-platform-evidence.md D1-D6; independent-equivalence-evidence-plan.md | ES candidate remains uninitialized/unqualified; no full original-context join merely from available SDK types |
| F12 | Historical d1510-object-request-cost.md Excluded Attempts | Observer labels/variables can contaminate context; no environment injection for correlation accepted by default |

Direct repository links: [materialized spawn code](../../../../../.data/ci-source-patch-check/src/gambit/lib/os_io.c),
[vendor fallback/reaper](../../../vendor/gambit/lib/os_io.c),
[process wrapper](../../../vendor/gambit/lib/gambit/process/process.scm),
[Scheme status implementation](../../../vendor/gambit/lib/_io.scm),
[shell native driver](../../../vendor/gambit/bin/gambuild-C.unix.in),
[Gambit callers](../../../vendor/gambit/gsc/_gsclib.scm),
[Gerbil invocation/barrier](../../../../../.data/ci-source-patch-check/src/gerbil/compiler/driver.ss),
[Gerbil jobs](../../../../../.data/ci-source-patch-check/src/gerbil/compiler/base.ss),
[previous ES ledger](darwin-observation-platform-evidence.md),
[historical invalid controls](../../../../../patches/gerbil-v19-darwin/receipts/d1510-object-request-cost.md).

Direct platform links: [ES message header](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/EndpointSecurity/ESMessage.h),
[spawn man source](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/posix_spawn.2),
[exec man source](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/execve.2),
[write man source](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/write.2),
[dup man source](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/dup.2),
[audit-control man source](/usr/share/man/man5/audit_control.5),
[audit-record man source](/usr/share/man/man5/audit.log.5),
[tty man source](/usr/share/man/man4/tty.4),
[script man source](/usr/share/man/man1/script.1),
[bash man source](/usr/share/man/man1/bash.1),
[shipped dtruss source](/usr/bin/dtruss).
Host-local links may drift after platform updates. No private audit/user process
contents were inspected. The prior ledger binds host macOS 26.6.1 / SDK alias
resolving to 26.5; no new runtime capability is inferred from those versions.

## Official Platform Sources Read Online

[Apple's archived spawn manual](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/posix_spawn.2.html)
supports the function-return error distinction. Its 2007 date is explicit;
current installed SDK manual and materialized caller code are the nearer local
reference, and still do not constitute a live test.
[Apple's archived write manual](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/write.2.html)
describes byte-count/error returns; current SDK read/write manuals ground the
local framing requirements.
[Apple's archived SIP runtime protections](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/RuntimeProtections/RuntimeProtections.html)
explains why root/attach/DTrace/DYLD assumptions cannot replace visibility
qualification for protected processes. It is not a live protection-state audit.

The ES WRITE documentation page returned a JavaScript stub; the inspected local
SDK struct is the evidence for its fields, not an assumed complete web page.
An archived tty web page failed to load; local tty/script manuals are used.
No Linux spawn behavior or third-party tracing claim is used to qualify Darwin.
The local Bash manual documents expected newline behavior, but /bin/sh interpreter
identity/version and actual substitutions must still be bound in a future run;
reading a Bash manual does not identify an original shell binary's implementation.

## Identity and Search Limits

Research HEAD rechecked `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor and materialized sources retain their distinct revision/patch identities
from prior ledgers. Bounded searches of os_io.c, _io.scm, process.scm and the
Gerbil driver found no DTRACE_PROBE/STAP_PROBE/USDT/TRACEPOINT hook at the named
state-delivery boundaries. This does not claim whole-repository probe absence
or prove an optimized original binary has an accessible stable ABI for Scheme
values. Missing guessed /usr/share/man/man2 paths were resolved to SDK man2
sources; their initial absence did not imply unavailable platform APIs.

| Inspected file | SHA-256 |
| --- | --- |
| `.data/ci-source-patch-check/src/gambit/lib/os_io.c` | `e17daf7fb752e9eb85b8b6e6e4672d81ae05435332392cff273ceaf6f5f223fa` |
| `.data/gambit-smp/vendor/gambit/lib/os_io.c` | `c0e7dc077c7dd6b6a2ee39028506c8a6d5313d29f881bda22d056cd6fce7d93f` |
| `.data/gambit-smp/vendor/gambit/lib/_io.scm` | `614475a2f37f9a5fbd95b0b9180e06a7ba236cfcdaf1aacdbd4cc8a6887c9e33` |
| `.data/gambit-smp/vendor/gambit/lib/gambit/process/process.scm` | `31029718e7798ad764a3895ceccb10d4a8b29d2a41ea4558e9cfe2b859dfe17c` |
| `.data/gambit-smp/vendor/gambit/bin/gambuild-C.unix.in` | `bdd99a03bb24206e348bdc6ae760a02c04573694090e21cc0a9b748dc8522b4c` |
| `.data/gambit-smp/vendor/gambit/gsc/_gsclib.scm` | `c4068e8d8c34135354d26c8a6e79adcac73bf34f432b857961bdb4932da94dd0` |
| `.data/ci-source-patch-check/src/gerbil/compiler/driver.ss` | `07a175646c90b16c690cf32d670b8368d534963966bbc84d89896f9bb8e5e300` |
| `.data/ci-source-patch-check/src/gerbil/compiler/base.ss` | `0ac4b2f61d39a46f6640075417f04ce215a94d968f318a7ed7611039f268f79a` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/EndpointSecurity/ESMessage.h` | `35cb9dd0fa3bc58d224fee5a39cb5ab5f648e124822ced7cba46f6031159b759` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/bsm/audit_kevents.h` | `d283b6c5aa34d58faf239f8b16bab2f5ce087306c557b27f604e695593b5bd1b` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/posix_spawn.2` | `0abbcdbe2fc62306f1d3b2aff6e00858ff03a0f0c20c312b9e58fb08caceb4f7` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/execve.2` | `551d9ae27d03112b9db14479fe283e16f9bcd722868ce43e8861adcc6fe2d770` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/read.2` | `abced071814b22402dd2e6886b38861153679ab6f1fa51f071579abd4a0bf38f` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/write.2` | `c901c9512813ba2542a4ab3cf59414a73a992e6865c07fbea7ca251cd2bd5bad` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/dup.2` | `bda76cc56fae4ded7d4ffc2c508dc81e3a49c7af72facd9f063739b11fcc907b` |
| `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/share/man/man2/wait.2` | `2178648ce5091cba439ca601216ec3f368ed64487f91385f68b65e7b5e5e5409` |
| `/usr/share/man/man5/audit_control.5` | `337678d884baf43d3a4abe727a1b9def8ffe104680326ee8d3b61c3edd99a832` |
| `/usr/share/man/man5/audit.log.5` | `5ab957b29dbc28843e2c70bd9841ee9304f5b638a6e1510cb7243542bba38164` |
| `/usr/share/man/man4/tty.4` | `e5cadf3c455b2802285020cb6532ea2d2c01a621f8e9cbd19aad26c0467e4699` |
| `/usr/share/man/man1/script.1` | `6148637d4aa2e134f1b47a299b80279e26edd538299030cc0aff124c5b57a748` |
| `/usr/share/man/man1/bash.1` | `f20bfaa1a29cf61800622a892d97b9a736c605d4eb30ecbbf2b553e40597e931` |
| `/usr/bin/dtruss` | `bcad1cc5acd97fcfd28c889ee56121968de7a1d290051254537f5a2e4b084a57` |

## Evidence Status

S01-S10 and R1-R7 are proposed controls/unresolved obligations. No new stream
record, API return, query byte, tty write, Scheme value or ES join was collected.
The existing U6/U7/U8 gaps are refined rather than closed. Static source evidence
proves where a future witness would need to observe; it cannot certify that an
unchanged original binary delivered the expected outcome during an unobserved run.

## Documentation Verification

446 local file references resolve; 153 Markdown tables have consistent columns.
S01-S10 and R1-R7 each occur exactly once in their control/gap tables. Both
D2 sources render with D2 0.9.0 (dagre/theme 0), and rasterized SVGs were visually
inspected. These document checks do not provide an acquired failure/output/
Scheme-delivery witness, ES correlation, native pass or retirement evidence.
