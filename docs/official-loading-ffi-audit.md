# Upstream loading and FFI qualification

## Interface ownership

Gerbil documents its FFI as delegation to the Gambit C interface through
`begin-foreign`. The Library uses `c-define`, the generated linker unit,
`___setup` and `___cleanup`; Python consumers use the C ABI, not a Scheme
compiler. Module loading remains upstream's responsibility.

Primary references:

- https://gerbil.scheme.org/guide/ffi.html
- https://gambitscheme.org/4.9.8/manual/#The-c_002ddefine-special-form
- https://gerbil.scheme.org/reference/gerbil/runtime/misc-procedures.html#load-module

The Library's `interface/generated-resources.ss` global expansion hook is
removed. `interface/evidence-module.ss`, `interface/dsl-source.ss` and
`bindings/build-entry.ss` now enter the existing upstream expander directly.
No replacement loader, downstream import scaffolding, compiler workflow or
silent compiled-module fallback was introduced. Upstream's own runtime hooks
are not modified.

One remaining version-bound internal dependency is explicit:
`bindings/artifact.ss` reads upstream `__find-library-module` to inventory the
actual selected compiled generation. This is not a documented stable public
API, and is not a Library runtime loader. The audit must not describe the whole
packaging implementation as a public-API-only integration. Replacing it needs
an upstream artifact-inventory contract, not a second resolution algorithm.

## Fixed Candidate

The isolated `/private/tmp/ascent-upstream-entry-002` matches the maintenance
checkout's 131 build-source inputs. The upstream full clean/build completed
in 84.674/120 seconds, exit 0, without timeout and with a quiescent process
group. The earlier overlapping build001 timeout remains DENY.

Package002 completed in 1.287/15 seconds. An attempted API002 output was already
present from the copied historical tree and was rejected; it was not reused.
Fresh API003 completed in 3.072/45 seconds. Its identities are:

| Artifact | SHA-256 |
| --- | --- |
| Producer Library | `a99caf2ac8ae16b09aa59b3a5ba58399ab77280c5038af49f2391b7c175c2d9f` |
| Packaged Library | `e792e756b8319f1d00904bd2ff90293ea0f0fe047ca8aad43d070df348f36439` |
| Python extension | `ea7c022a174806a2028e5f967b1da5286865d991c6ded1d42e49366a627f3fc6` |
| API receipt | `746e71e13404e8b8f504560f7ca284ac50121d9edd8df3612323cb7fe68df603` |

The receipt binds 2189 resources and 927 compiled origins, retaining actual
module generation names. Only the two linked entry files are explicit source
resources. Maintenance also repaired ABI packaging to replace a fully checked
resource tree, rather than retaining old `.oN` generations on an overlay copy.

## Actual Denials

Build success is not execution acceptance. The complete Library matrix planned
32 fresh processes. Matrix001 failed at missing Quint/incorrect subprocess
imports; matrix002 bound explicit subprocess paths and required tools, then
completed eight processes before `test_dsl_collection` timed out at its first
declaration-negative test. The remaining processes were not executed. The
whole matrix remains DENY; no tests or failures were removed.

The real sealed consumer closure is
`263ea7a5c4ba4ee29b8593f7cb6360dcdbfb25354567fc2f208eb5294bd87323`.
Its 105-test review domain failed at the original 60-second ceiling: both
workers claimed their first test without complete outcomes. The whole graph
parent reached 300.006/300 seconds, exit -9, timeout true and group quiescent.
There is no successful complete CURRENT graph for this candidate.

Earlier hook-free build001 diagnostic API controls completed a simple call
and the real investigation/Actor scenario. They are historical observations,
not results for build002. New build002's constant-only and declaration controls
both timed out, so neither invalid bindings nor exception projection is a
proven unique cause.

## Platform Loading Observation

Maintenance's permitted plain-gxi sample observes `___dynamic_load -> dyld ->
mapSegments -> fcntl` as the main wait. This can reproduce without Python or
JSON error projection. A denied Python sampling request was not bypassed.

The system `man dyld` documents `DYLD_PRINT_APIS`, `DYLD_PRINT_LIBRARIES` and
`DYLD_PRINT_TO_FILE`. File-directed diagnostics are necessary here: temporary
host-I/O preservation buffers stderr until a C ABI request returns, which a
stalled request never does.

The API003 trace's pending `dlopen` is
`syntax/std/encoding/hex~1.o1`. Its SHA-256 is
`8915b0cf00563236d099d0655391ee37f09c176f7cddb92b3a315abc0f034df3`;
both its signature verification and comparison with the old diagnostic copy
succeed. These observations do not establish the cause of the kernel wait.
An exact APFS COW copy also timed out, this time while loading
`gerbil/core/contract~TypeEnv~0.o1`. COW transport alone is not a fix.
No SDK, signature, security setting or extended attribute was changed.

Maintenance subsequently reported a crossed resource-tree control: its static
entry Library with the old resource tree completed in 1.70/15 seconds; the same
Library with symlinks to the original producer resources completed in 1.73/15
seconds; the old Library with the newly packaged resources timed out. These are
diagnostic observations, not independently admitted consumer results. The
symlink tree is not a self-contained package and cannot qualify portability or
the sealed consumer closure.

Origin-to-fresh-tree `copy2` and system `clonefile` controls also timed out at
the original 15-second ceiling, despite matching all 2189 resource hashes.
Thus preserving timestamps or using APFS cloning is not an established fix.
Neither copied-file metadata nor a particular module is yet a proven unique
cause. No unchanged full matrix or graph is retried on these observations.

The SDK loader's actual rule is a contiguous `.o1`, `.o2`, ... prefix, selecting
the last existing generation before the first gap. The original names must
remain intact because Gambit's linker symbols depend on them. The pending
`hex~1.o1` image has only `libSystem.B.dylib` as a dynamic dependency; this
read-only Mach-O inspection does not explain the observed loading wait.

Apple's published dyld `Loader.cpp` calls signature registration and
`fcntl(F_CHECK_LV)` in `mapSegments` before mapping image segments:
https://github.com/apple-oss-distributions/dyld/blob/main/dyld/Loader.cpp
Consequently an observed `mapSegments -> fcntl` stack is not sufficient to
describe a POSIX file-lock deadlock. Signature verification outside the target
process also does not establish that its library-validation call completes.
This published source has not been matched to the host's exact dyld build, and
the sampled command is not yet identified; neither a security-policy cause
nor permission to change security settings follows from this audit.

## Static Closure Candidate 018

Candidate 018 adds the Evidence facade imports to the upstream entry's static
closure and retains canonical compiled-generation inodes when packaging.
It is a different source/artifact identity from official-entry002. No loader
hook, generated-name rewrite or security-policy change is involved. This
local generation-sharing transport is not a portable distribution claim.

The fixed API receipt is
`7790797369bf69b8595e65bc262e5140b7535dc3bd6f54a7787dd21a1c2f241b`.
ROOT's unchanged 32-process selection retained 15-second per-process and
120-second whole limits. Thirteen process groups completed successfully,
including the previously stalled DSL collection; the fourteenth group
failed with eight passing tests and one initialization error. The matrix
stopped after 32.016 seconds, all children reaped and quiescent, with all
bound source, resource, test and helper hashes unchanged. Eighteen planned
groups remain unexecuted; the overall matrix is DENY.

The typed root cause is separate from module loading: a caller's explicit
128-byte request ceiling also applies to the Library's initialization
`configure-syntax` request containing its installation path. The long
package path exceeds that ceiling before the caller submits a request.
Fixing this requires separating verified Library initialization transport
from the caller request policy, not shortening the path, increasing the
test ceiling or exempting caller-selected operations from policy checks.
Raw results are retained under
`.data/dsl-session-reuse-001/static-generation-matrix-018-001`.

No new shared-generation seal is admitted yet. The existing seal chmods
independent copies to 0444; applying that operation to a hard link would
also mutate the producer inode. Any new ownership contract must avoid that
side effect, retain full SHA checks and alias-mutation negative controls,
and state its trusted-host and cross-filesystem limits explicitly. Old
seal schemas, manifests and failed qualification results remain unchanged.

## Current Qualification Boundary

After separating verified Library initialization from public request policy,
matrix018-002 completed all 32 fresh processes: 197 test executions, zero
skips, failures or errors, 75.645/120 seconds. API018 binary/resources were
unchanged; the updated Python/helper/test inventory was bound before and
after. The prior matrix's initialization failure remains retained.

The consumer now creates `research-engine-seal.v2` with an explicit
`checked-generation-sharing.v1` ownership inventory. Only receipt-bound
canonical compiled generations use the Library's shared transfer helper.
All other implementation files are independent copies. Shared generations
are never chmodded; target inode and full SHA are bound to the new identity.
Historical v1 manifests remain readable, not rewritten. The 46 focused
kernel tests include source-alias mutation rejection, original-name
unlink/replacement, independent EXDEV copying and EIO rejection. These are
transport controls, not consumer admission or a portability guarantee.

Graph001 rejected a concurrent current-framework change, with exit 2 at
134.758/300 seconds. A fresh seal bound that change:
`eda0e81578985d7cef5152a1b777bcec429567d3b8ee488d91967e70c19f08b3`.
Graph002 completed with exit 2 at 289.502/300 seconds, no parent timeout and
quiescent children. Its complete reported inventory contains 1169 tests,
zero skips, one failure and 117 errors. The 105-test sealed domain timed
out at 60.624 seconds; two first tests started without terminal outcomes.
The remaining domain errors are incomplete-inventory outcomes, not 105
individually executed native failures. Actual `agent-context --read` reports
CURRENT with frameworkValidation DENY and no changed inputs. CURRENT is
identity freshness, not PASS.

A subsequent recorded-only diagnostic checked all 927 generation source
and target device/inode pairs and both hashes. The same two first test
identities completed in 3.504/15 and 4.513/15 seconds with official
file-directed dyld logging and Python call-boundary profiling enabled.
Both processes were reaped and quiescent. This instrumented, directly
selected-test observation differs from the full validation worker's import
closure and execution context; it does not qualify the failed domain or
prove a unique timing cause. Raw logs and generation inventory are under
`.data/dsl-session-reuse-001/review-loading-018-001`. No unchanged full
domain retry, timeout increase or new loader follows from this observation.

Raw process receipts, stdout/stderr and dyld traces are retained locally under
`.data/dsl-session-reuse-001/upstream-entry-*`. They are ignored local evidence,
not committed raw-log admission. Original 15/45/60/120/300-second ceilings
remain unchanged. Matched performance and full consumer closure remain open;
the earlier compiled-candidate speed observation is not a current speed claim.
