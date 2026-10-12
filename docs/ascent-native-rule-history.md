# Native Rule Reader And History Acceptance

The audit frontend had migrated to inert native ASCENT Scheme fragments, but
the selected API library predated the `read-rules` operation. Thirteen audit
tests therefore failed before inference. History also still supplied old rule
text to an API requiring a native catalog.

History now uses versioned `evidence/history-rules.ss`, loaded by the installed
ASCENT engine. Python does not parse or evaluate this rule source. History
records bind its digest and reject a change during inference. Audit and graph
snapshots also bind the rule file and history interpreter. Test inputs use the
same native fragment interface, not a Python fallback.

## Local Native Qualification

On 2026-10-11, the current ASCENT checkout was built with GNU GCC 16.2.0,
machine-derived CPU concurrency and bounded build stages. The new C ABI
library includes the source reader and dispatch operation. A new CFFI API was
built in `.data/ascent-api-native-rule-reader`; previous API directories were
not overwritten.

The real audit, history and evidence-review suite passed **31 tests in
10.599 seconds**. This includes repeated observations, a 1,100-input history,
withdrawal of old conclusions, corruption rejection and missing/non-native
API rejection. The real audit CLI then returned `AUDIT-CHECKED`, including
8 unclosed Requirements, 15 pending conditions and 28 Reference links.

| Artifact | SHA-256 |
| --- | --- |
| Bundled native library | `7304321dfd54ca89c072b11031f4664df4f12e7e398daceb1f4cac2d592d409f` |
| CFFI extension | `6a0c185aa1f01ae576992382c72774ab293d0ae3d9d6a7d6953331848eb5f3e2` |
| Public C ABI header | `f1b7cba2d4b63f4cf35198b4f89f52f320fdfe085d8b9147fe40268f20370974` |

Two failures were retained separately: the first link encountered an obsolete
OpenSSL Cellar search path; relinking added the current stable `opt` search
path and reused existing objects. The first CFFI attempt lacked setuptools;
installing setuptools 84.0.0 into the local build environment enabled the
real GNU GCC extension build. Neither failure was rewritten as a pass.

## Boundary

This is local working-tree qualification of the evidence engine and history
interface, not exact-head CI, portable-wheel qualification or a clean-checkout
dependency-pin claim. The external ASCENT checkout has concurrent changes;
these observations do not substitute for a versioned producer source pin.
The SDK used for this evidence-engine build is not candidate029's configured
SMP runtime. No native Gambit GC, multi-VM, bootstrap or Gerbil performance
admission follows from these 31 tests.

With the newly built API selected, the scoped checks are reproducible by:

```sh
PYTHONPATH=.data/ascent-api-native-rule-reader python -m unittest \
  tests.test_research_audit tests.test_reasoning_history tests.test_ascent_review
PYTHONPATH=.data/ascent-api-native-rule-reader python -m gambit_smp.research_audit --check
```

These commands require the matching compiled API, its build receipt and Python
bindings. An absent or old library must fail closed; it cannot trigger a host
parser or alternate inference engine.
