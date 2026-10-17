// Research protocol only: finite identities are not runtime capacity limits.
module ResearchFunnel {
  const Mutation: str
  type State = {generation: int, source: int, product: int, probe: str,
    launched: bool, modeled: bool, bootstrapped: bool, early: bool,
    receiptGeneration: int, receiptSource: int, receiptProduct: int,
    nativeComplete: bool, counted: bool, observed: Set[int], history: Set[int],
    authorized: bool, closedLaunchInventory: bool, unstartedClaim: bool}
  var q: State
  action init = q' = {generation: 0, source: 0, product: 0, probe: "unknown",
    launched: false, modeled: false, bootstrapped: false, early: false,
    receiptGeneration: -1, receiptSource: -1, receiptProduct: -1,
    nativeComplete: false, counted: false, observed: Set(), history: Set(),
    authorized: false, closedLaunchInventory: false, unstartedClaim: false}
  action ProbeFailure = all {q.probe == "unknown",
    q' = {...q, probe: "failed", observed: q.observed.union(Set(q.generation)),
      history: q.history.union(Set(q.generation))}}
  action ProbeSuccess = all {q.probe == "unknown", q' = {...q, probe: "passed"}}
  action ModelSuccess = all {not(q.modeled),
    q' = {...q, modeled: true, counted: q.counted or Mutation == "model-credit"}}
  action BootstrapSuccess = all {not(q.bootstrapped),
    q' = {...q, bootstrapped: true, counted: q.counted or Mutation == "bootstrap-credit"}}
  action EarlySuccess = all {not(q.early),
    q' = {...q, early: true, counted: q.counted or Mutation == "early-credit"}}
  action Authorize = all {not(q.authorized), q' = {...q, authorized: true}}
  action CloseLaunchInventory = all {q.probe == "failed", not(q.launched),
    not(q.closedLaunchInventory), q' = {...q, closedLaunchInventory: true}}
  action ClassifyUnstarted = all {not(q.unstartedClaim),
    (q.closedLaunchInventory and not(q.launched)) or Mutation == "unknown-launch",
    q' = {...q, unstartedClaim: true}}
  action Launch = all {not(q.launched),
    q.authorized or Mutation == "unauthorized",
    q.probe == "passed" or (Mutation == "failed-launch" and q.probe == "failed"),
    q' = {...q, launched: true, closedLaunchInventory: false, unstartedClaim: false}}
  // This event assumes a host-verified, complete native gate receipt, not a probe.
  action NativeComplete = all {q.launched, q.probe == "passed", not(q.nativeComplete),
    q' = {...q, nativeComplete: true, receiptGeneration: q.generation,
      receiptSource: q.source, receiptProduct: q.product}}
  val OwnNativeReceipt = all {q.nativeComplete, q.receiptGeneration == q.generation,
    q.receiptSource == q.source, q.receiptProduct == q.product}
  action Publish = all {OwnNativeReceipt, not(q.counted), q' = {...q, counted: true}}
  action Advance = all {q.generation < 2,
    q' = {...q, generation: q.generation + 1, source: 1 - q.source, product: 1 - q.product,
      probe: "unknown", launched: false, modeled: false, bootstrapped: false, early: false,
      counted: if (Mutation == "stale-credit") q.counted else false,
      nativeComplete: false, authorized: false, closedLaunchInventory: false, unstartedClaim: false,
      history: if (Mutation == "drop-history") Set() else q.history}}
  action Idle = q' = q
  action step = any {ProbeFailure, ProbeSuccess, ModelSuccess, BootstrapSuccess,
    EarlySuccess, Authorize, CloseLaunchInventory, ClassifyUnstarted,
    Launch, NativeComplete, Publish, Advance, Idle}
  val Safe = all {q.generation >= 0, q.generation <= 2,
    not(q.launched) or q.probe == "passed",
    not(q.launched) or q.authorized,
    not(q.unstartedClaim) or (q.closedLaunchInventory and not(q.launched)),
    not(q.counted) or OwnNativeReceipt,
    q.observed.subseteq(q.history)}
}
