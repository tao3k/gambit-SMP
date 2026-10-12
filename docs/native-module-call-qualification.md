# Native Module Calls: Local Qualification 038

This work qualifies ASCENT's Python/native-module interface, independently of
Gambit runtime acceptance. It does not claim that every Agent consumer has
migrated from rule documents to native modules.

## Interface

`Engine.module(module)` owns native values returned by actual compiled Scheme
exports. `NativeModule.call(export, *arguments, module=...)` passes references
between exports, including exports in another module under the same owner.
`NativeValue.apply(*arguments)` invokes an actual Scheme closure. Multiple
Scheme values remain ordered native values with an explicit `valueCount`.

The upstream owns constructors, macro expansion, operator composition, lattice
semantics, change plans, sessions and inference. Python transports calls and
references; it does not rebuild these objects or interpret a second language.
`Fragment` remains an upstream composition object, not a mandatory entry tier.
`open_module` remains a Program convenience, not the full module boundary.

Native values remain retained when graph projection cannot represent them.
Result ownership and explanation ownership are independent;
`NativeResult.explanation()` releases its own explanation handle without
releasing the original result. Closing a generic owner releases references,
not arbitrary user-defined external resources. Trusted native code must invoke
its own resource protocols. The generic entry does not establish permissions,
source refinement or proof admission.

The Agent entry is `gambit_smp.ascent_program.native_modules(module)`. It binds
the actual API artifacts, generated load resources and complete compiled
provider source inventory, and rejects unbound modules without a Fragment
fallback. Native modules must first be compiled by the provider's existing
`build.ss` / `defbuild-script` / `stdmake` tasks.

## Actual New Producer

The build used `/private/tmp/ascent-provider-native-calls-038`, GNU GCC 16.2.0,
debug/O0 settings and the existing native build entry. It reused a copied
prepared compilation cache; it was not a cold build. Changed native modules
were compiled and the final library was rebuilt. The old034 tree was untouched.

- Build: actual exit0, 75.079507 seconds within the original120-second cap.
- ABI packaging: actual exit0, 0.604940 seconds within15 seconds.
- CFFI API: actual exit0, 2.156054 seconds within45 seconds.
- API directory: `/private/tmp/ascent-native-calls-api-038`.
- Producer SHA256: `df297d75a671795d66ec6c6bd38deeed1971d32bb267fd96b7f43e21ba584ad3`.
- API library SHA256: `b22d891b377c2e989499390c40cd0b3b53fc24c3702a2ca5c5ccb6d6d29d2daa`.
- API extension SHA256: `2aeef4c1d5ee27837dcc382b8f0192e72cd6095fa1b92e732353b97bfdced4a3`.
- API receipt SHA256: `972d86b8c52fa90c278f0b91a1804ce070155888bb761b27a213c52d9e49c354`.

Independent rehash matched131 provider sources and1262 generated load resources.
Python bindings remain the current editable source, not a qualified portable
wheel or immutable research-engine seal.

## Executed Controls

All successful processes below exited0 without timeout and confirmed process
group quiescence. Raw receipts are preserved in the ignored local directory
`.data/ascent-native-calls-038`; this document does not make them Git-persistent
admitted evidence.

- Seven generic-call tests with SDK/load paths hidden: 2.767299/15 seconds.
  Actual objects cross module boundaries; operator composition, retained
  replacement/withdrawal, compiled closures, multiple values, wrong exports,
  foreign/released references, value capacity and independent explanations are
  exercised. The checked relational session still rejects arbitrary min
  lattices; the general upstream Program session executes its supported lattice.
- Fresh native wire fixture: six cases/36 contracts, 41.151193/120 seconds.
- Complete Python engine matrix:142 tests,24 fresh processes, zero skips,
  32.457302/120 seconds. Each process has at most15 seconds and consumes the
  same actual new producer/API/wire fixture.
- Actual Agent module entry plus existing module/session consumers: nine
  tests, zero skips, 4.830783/15 seconds with SDK/load paths hidden.
- Typed raw-observation binding regression:14 tests, zero skips,
  3.981632/15 seconds. Flat and nested events retain exact pointers; sibling
  event substitution, stale hashes and missing budgets remain rejected.

Initial lattice misuse, missing wire fixture, wrong Python executable,
observation-pointer errors and the stale reopen-session test failures remain
in separate raw receipts. Later controls have the corresponding actual fixture,
argv, schema or test correction, not an unchanged retry.

## Open Consumer Boundaries

The actual catalog/review/history consumers still load rule documents. The
generic Agent entry is usable but is not yet their sole inference path. Old
inert-wire dependency selection is not a complete native Scheme interface.

The broad19-test Agent audit currently has18 passes and one actual rejection:
`source-unit receipt omits locked source inputs` in source correspondence.
Latest receipt is `ascent-native-calls-038-consumers-004.json`, actual exit1,
5.309177/15 seconds, no timeout and quiescent teardown. The prior inventory
drift has been bound to the actual three new observations, without altering
their failure outcomes; this does not repair a different source-unit receipt.

Production history's previously measured4269 current source occurrences and
5683 combined occurrences exceed its4096 cap. That failure remains unclosed.
The new native module API neither increases that cap nor turns an incomplete
history query into a pass. No fresh full graph or total Agent integration PASS
is claimed. The next closure work belongs to actual native consumer migration
and an explicit history capacity/execution contract, not Python inference or
Gambit runtime acceptance.
