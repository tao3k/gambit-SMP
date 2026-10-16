# ASCENT C ABI Consumption

The consumer loads ASCENT through `Engine(library=...)`. It does not import
`_ascent_cffi`, generate CFFI glue, or compile Scheme. The Library owns its
build and packaging workflow.

An unsealed invocation must set `ASCENT_ENGINE_LIBRARY` to the packaged shared
library. Its adjacent `<library>.json` must be an `ascent.c-abi-build.v1`
receipt with `buildOwner` equal to `build.ss/std/make`. Every listed syntax
resource is checked by its individual SHA, as are the library, receipt and
the complete Python binding tree. Unsealed request exit also checks the
inventory itself, so adding or removing a binding file is drift even if every
previous file still matches. Missing configuration or mismatched identities fail
closed; there is no extension fallback.

The research seal accepts the directory containing `libascent.dylib` (Darwin)
or `libascent.so`, its adjacent JSON receipt and `syntax/`. It copies and binds
that exact artifact inventory. Sealed requests select the library inside the
seal, not an ambient environment override. The provider probe also uses the
explicit library path. Request boundaries retain complete before/after SHA
checks and process teardown requirements.

New seals also copy every exact provider build source into `provider-source/`.
The separate `ascent.provider-source-archive.v1` mapping binds the unchanged
C ABI receipt, full source-input inventory and compiled module identities to
these physical files. It never rewrites the original source root or substitutes
a live checkout. Missing, changed, aliased or unbound source bytes reject
sealing. Module consumers resolve the archived bytes inside a verified seal,
including after the original build directory disappears.

Legacy extension receipts and previous sealed engines remain historical
evidence. They do not qualify this migrated implementation. Latest-source
build, bootstrap, complete consumer regression, sealed review and current graph
qualification must each record their own matching identities and real exits.
