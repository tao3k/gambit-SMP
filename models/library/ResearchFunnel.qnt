// Research protocol only: finite identities are not runtime capacity limits.
module ResearchFunnel {
  const Mutation: str
  // A lost parent receipt does not make a fully recorded failure a live resume.
  // These are host-verified premises, not values inferred from missing evidence.
  pure def freshRetryAllowed(complete: bool, failed: bool, quiescent: bool,
      changed: bool, sameGraph: bool, budgetPreserved: bool): bool =
    complete and failed and quiescent and changed and sameGraph and budgetPreserved
  pure val BoolDomain = Set(false, true)
  // Research discrimination only. Identity tokens denote authenticated host
  // records; neither token equality nor this finite check authenticates bytes.
  type MechanismObservation = { hypothesis: int, alternative: int,
    source: int, observedSource: int, product: int, observedProduct: int,
    fixture: int, observedFixture: int, configuration: int, observedConfiguration: int,
    generation: int, observedGeneration: int, prediction: int, alternativePrediction: int,
    outcome: int, complete: bool }
  pure def distinguishes(o: MechanismObservation): bool =
    o.hypothesis != o.alternative and o.prediction != o.alternativePrediction and
    o.source == o.observedSource and o.product == o.observedProduct and
    o.fixture == o.observedFixture and o.configuration == o.observedConfiguration and
    o.generation == o.observedGeneration and o.complete and
    (o.outcome == o.prediction or o.outcome == o.alternativePrediction)
  pure val matchedObservation: MechanismObservation = {hypothesis: 1, alternative: 2,
    source: 1, observedSource: 1, product: 1, observedProduct: 1,
    fixture: 1, observedFixture: 1, configuration: 1, observedConfiguration: 1,
    generation: 1, observedGeneration: 1, prediction: 0, alternativePrediction: 1,
    outcome: 0, complete: true}
  run discriminationControlsTest = init.then(all {
    assert(distinguishes(matchedObservation)),
    assert(not(distinguishes({...matchedObservation, alternativePrediction: 0}))),
    assert(not(distinguishes({...matchedObservation, observedSource: 2}))),
    assert(not(distinguishes({...matchedObservation, observedProduct: 2}))),
    assert(not(distinguishes({...matchedObservation, observedFixture: 2}))),
    assert(not(distinguishes({...matchedObservation, observedConfiguration: 2}))),
    assert(not(distinguishes({...matchedObservation, observedGeneration: 2}))),
    assert(not(distinguishes({...matchedObservation, complete: false}))),
    assert(not(distinguishes({...matchedObservation, outcome: 3}))), q' = q })
  val RetryPolicySound = BoolDomain.forall(complete => BoolDomain.forall(failed =>
    BoolDomain.forall(quiescent => BoolDomain.forall(changed =>
    BoolDomain.forall(graph => BoolDomain.forall(budget =>
      freshRetryAllowed(complete, failed, quiescent, changed, graph, budget).implies(
        complete and failed and quiescent and changed and graph and budget)))))))
  type State = {generation: int, source: int, product: int, probe: str,
    launched: bool, modeled: bool, bootstrapped: bool, early: bool,
    receiptGeneration: int, receiptSource: int, receiptProduct: int,
    nativeComplete: bool, counted: bool, observed: Set[int], history: Set[int],
    authorized: bool, closedLaunchInventory: bool, unstartedClaim: bool,
    conclusions: Set[int], conclusionHistory: Set[int], restored: Set[int]}
  var q: State
  action init = q' = {generation: 0, source: 0, product: 0, probe: "unknown",
    launched: false, modeled: false, bootstrapped: false, early: false,
    receiptGeneration: -1, receiptSource: -1, receiptProduct: -1,
    nativeComplete: false, counted: false, observed: Set(), history: Set(),
    authorized: false, closedLaunchInventory: false, unstartedClaim: false,
    conclusions: Set(), conclusionHistory: Set(), restored: Set()}
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
  // Provider return and completed good+failed counts are display facts only.
  action ObserveExecution = {
    nondet completed = Set(0, 1, 2).oneOf()
    q' = {...q, counted: q.counted or (Mutation == "projection-credit" and completed > 0)}
  }
  // Abstract conclusion identities are not a limit on hypotheses or tool calls.
  action RecordConclusion = {
    nondet identity = Set(0, 1).oneOf()
    q' = {...q, conclusions: q.conclusions.union(Set(identity)),
      conclusionHistory: q.conclusionHistory.union(Set(identity))}
  }
  action RestoreInvestigation = q' = {...q, restored: q.conclusions,
    counted: q.counted or (Mutation == "hypothesis-credit" and q.conclusions != Set())}
  action ClearReadHint = q' = {...q, restored: Set(),
    conclusions: if (Mutation == "erase-conclusions") Set() else q.conclusions}
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
    EarlySuccess, ObserveExecution, RecordConclusion, RestoreInvestigation, ClearReadHint,
    Authorize, CloseLaunchInventory, ClassifyUnstarted,
    Launch, NativeComplete, Publish, Advance, Idle}
  val Safe = all {RetryPolicySound, q.generation >= 0, q.generation <= 2,
    not(q.launched) or q.probe == "passed",
    not(q.launched) or q.authorized,
    not(q.unstartedClaim) or (q.closedLaunchInventory and not(q.launched)),
    not(q.counted) or OwnNativeReceipt,
    q.observed.subseteq(q.history), q.conclusionHistory.subseteq(q.conclusions),
    q.restored.subseteq(q.conclusions)}
}
