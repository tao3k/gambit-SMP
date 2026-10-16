# Rust Python Dependency Cutover

The consumer pins `gerbil-ascent` from PR #1 at
`e6884b83c7b141ec66e2095252e4fb9e17da9869`, subdirectory `python`.
That package uses maturin and imports as `ascent`; the old
`ascent-test-support` / `ascent_engine` dependency is not a fallback.

The deployment contract is a prebuilt Python wheel: downstream imports
`ascent` and supplies DSL definitions, without a Gerbil SDK, environment setup,
package manager or compiler. Library maintainers own compilation and packaging.
The currently pinned Git source installation is a build qualification input,
not a completed implementation of this deployment contract.

## Identity

`ascent.build.runtime_identity()` supplies the actual extension's compiled
source and runtime-resource inventories. The Library provides `sourceRoot`
inside its installed package; downstream does not configure a source or SDK
directory. It must not point at a different revision merely because the API
names agree. The consumer checks
every source and resource path before and after an audit, as well as the
installed `ascent` package and `_core` extension. New observations identify
their backend as `ascent-rust`; old observations are not rewritten.

New seals reject runtime resources outside the installed `ascent` package,
even when caller environment variables could make them loadable. Sealing and
execution never inject `GERBIL_HOME` or `GERBIL_PATH`. This rejection does not
constitute a relocation implementation: Library packaging must resolve and
verify packaged resources through supported Library/runtime interfaces.
Historical seals retain their original inventories and external-path checks;
they are not upgraded or rewritten as portable packages.

The pinned wheel currently embeds build-machine absolute paths and fails this
new deployment gate. Its full DSL is not yet qualified for SDK-free downstream
use. Do not repair that failure by environment injection, a private loader,
fallback to an old extension, or projection to a less capable execution mode.
Once Library packaging is fixed, qualify a relocated wheel with the SDK and
original build tree unavailable, and exercise real catalog/review/history DSL,
withdrawal, explanations and teardown under the original budgets.

## Local Development Candidate

The current upstream head `e6884b8` has seven successful CI checks. The older
`091e7aa` watchdog failure below is historical, not its current status.
The upstream head still has the same packaging implementation; CI restores
its runtime resources separately from the wheel.

With explicit user authorization, a separate local source candidate based on
`e6884b8` adds packaging changes. Its patch is
`.data/rust-python-cutover-972d533/wheel-packaging-e6884b8-local.patch`, SHA256
`28aeb06f89092e86f093dc0273a7507b5a6e7be4d50613631a1648d008bcc795`.
The `006` wheel SHA256 is
`22fede79c78c76eddc756dc029c56896d9ae60b438ad123cd996fe5511074336`;
the installed extension SHA256 is
`7de4477d51ed473f67284ef155f8d3c97e19279e10528b72a7343a790994c438`.
It includes 523 source inputs, 3719 runtime resources and repaired dependent
shared libraries. It was built in 36.257 seconds under the original 120-second
cap, using prepared caches; this is not a cold-build performance result.

The main consumer `.venv` now actually runs that local wheel, not `972d533`.
The lock records the published base revision, not the unpublished local patch.
Use the explicit environment for this development experiment; a source sync
would replace this wheel and is not the approved deployment/install route.
Neither identity is reported as an upstream release containing the patch.

New seals preserve the package-relative resource layout and validate the full
wheel RECORD, including bundled shared libraries. Historical seals retain
their old identities and external-path checks. Duplicate bindings hash the
same path once within each boundary, with a fresh full hash at the next
boundary; no cross-request metadata-only cache replaces source validation.

The full investigation and history tests still exceed their original
15-second budgets in the build-tree/SDK-denied subprocess. A real system
sample places 680/770 samples in dyld's file-validation `fcntl` path while
loading Scheme modules. This is observed location evidence, not a complete
causal proof. The patch was handed to the upstream maintenance conversation;
full consumer, sealed review and current-graph acceptance remain open.

## Direct API Changes

- `Engine()` and `describe()` replace the old library-path constructor and
  JSON request dispatcher.
- `ascent.derivations.slice_program` owns dependency slicing.
- Component constructors return owned values; `open_session(limits=...)`
  applies explicit caller limits without dropping them.
- Consumer query and proof owners live in consumer registries, not arbitrary
  attributes attached to a Rust Engine. Explicit close retires those owners.
- `sessionOwner` is an explicitly scoped consumer lifetime token, not a
  fabricated native handle, source identity or execution permission.
- The Rust proof interface receives typed scalar values directly; it does not
  use the retired Python symbol-codec frontend.

## Qualification Boundary

PR CI, dependency installation, consumer semantic regressions, sealed review,
the full current graph and matched performance are separate gates. A passing
provider CI or successful installation is not a complete consumer result.
Local raw logs are retained under `.data/rust-python-cutover-972d533`.

## Upstream Handoff

On 2026-10-15 the maintenance conversation was sent both the actual external
resource deployment failure and the exact-head CI failure. PR #1 head
`091e7aaaef3e8946464ba9a49917abafdb920796` only changes CI and its README;
the Python/Rust/interface sources are unchanged from the installed pin.
Run `38696124589`, job `116292985653`, fails in the Python/Scheme interface
semantics step: `pyo3-test_uf_materialization` exceeds the original deadline or
real-output watchdog. This is separate from successful Cargo/Clippy/wheel
construction and from the resource packaging gap. Its original failed-step
log is retained as `upstream-rust-pyo3-091e7aa-failed.log` (SHA256
`7d5ea902ffcffdc7f9d74f08b2333bab86013bd62a3e45ece78d26b83ef01af2`).

Downstream proof transport now preserves typed Library conclusions directly,
without the retired symbol-codec table. A real PyO3 proof-owner transport
control passes without SDK configuration; its assembled-program boundary is
stubbed deliberately, so it does not qualify DSL loading or full consumer
execution. Full DSL, all consumers and the current graph must be requalified
against the new packaged revision and actual installed artifact when available.
