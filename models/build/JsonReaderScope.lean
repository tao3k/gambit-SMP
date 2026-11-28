import RuntimeImportDemand

/-!
Acceptance for the JSON reader workload. The ordinary arm supplies semantics.
The hand-narrowed arm supplies the footprint and latency target. A physical
image above that target needs a derivation from independently established
binding and initialization roots. A timing budget is an input to the check.
-/
namespace JsonReaderScope

open RuntimeImportDemand RuntimeImportDemand.NativeReplay

abbrev Observation := String × String
abbrev NativeRun := Run String Observation

inductive Fixture where
  | jsonAndInitialization
  | readerMacro
  | directNativeLoader
  deriving DecidableEq, Repr

def requiredFixtures : List Fixture :=
  [.jsonAndInitialization, .readerMacro, .directNativeLoader]

def itinerary : Fixture → List (Checkpoint String String)
  | .jsonAndInitialization =>
    [⟨"json-receipt", ["json", "before-parameter", "before-flags"]⟩,
     ⟨"tmpdir-after-explicit-import", ["same-parameter", "directory", "after-flags", "temporary-call"]⟩]
  | .readerMacro =>
    [⟨"canonical-binding", ["binding"]⟩,
     ⟨"public-transformer-and-repeat-import",
       ["same-binding", "transformer-procedure", "compiles", "same-transformer"]⟩]
  | .directNativeLoader =>
    [⟨"direct-load-module", ["parameter-published", "function-published"]⟩]

def requiredValues : Fixture → List Observation
  | .jsonAndInitialization =>
    [("json", "\"[false,null,[true]]\""), ("before-parameter", "#t"),
     ("same-parameter", "#t"), ("directory", "earlier"), ("temporary-call", "#t")]
  | .readerMacro =>
    [("same-binding", "#t"), ("transformer-procedure", "#t"),
     ("compiles", "#t"), ("same-transformer", "#t")]
  | .directNativeLoader => [("parameter-published", "#t"), ("function-published", "#t")]

structure SemanticFixture where
  id : Fixture
  ordinary : NativeRun
  automatic : NativeRun

def passesSemantics (fixture : SemanticFixture) : Bool :=
  let ordinaryEvents := fixture.ordinary.checkpoints.flatMap Checkpoint.events
  (requiredValues fixture.id).all ordinaryEvents.contains &&
    runMatches Prod.fst (itinerary fixture.id) 0 fixture.ordinary fixture.automatic

inductive DemandNode where
  | binding (identity : String) (phase : Int)
  | initializer (identity : String)
  | image (name : String)
  deriving DecidableEq, Repr

def physicalImage : DemandNode → Option String
  | .image name => some name
  | _ => none

private theorem mem_physical_images (image : String) (nodes : List DemandNode) :
    image ∈ nodes.filterMap physicalImage ↔ DemandNode.image image ∈ nodes := by
  induction nodes with
  | nil => simp
  | cons head tail ih =>
    cases head with
    | binding name phase =>
      change image ∈ tail.filterMap physicalImage ↔ .image image ∈ .binding name phase :: tail
      have distinct : DemandNode.image image ≠ .binding name phase := by
        intro equal
        cases equal
      rw [List.mem_cons, or_iff_right distinct]
      exact ih
    | initializer name =>
      change image ∈ tail.filterMap physicalImage ↔ .image image ∈ .initializer name :: tail
      have distinct : DemandNode.image image ≠ .initializer name := by
        intro equal
        cases equal
      rw [List.mem_cons, or_iff_right distinct]
      exact ih
    | image name =>
      change image ∈ name :: tail.filterMap physicalImage ↔ .image image ∈ .image name :: tail
      simp only [List.mem_cons, DemandNode.image.injEq, ih]

inductive EdgeReason where
  | visibility
  | bindingUse
  | initialization
  | evaluationOrder
  deriving DecidableEq, Repr

structure Dependency where
  target : DemandNode
  reason : EdgeReason

/-- A facade can expose a name without forcing its provider. Expansion
must preserve that binding, while the execution table follows verified
binding, effect and order edges. A missing row remains unknown. -/
def executionDependencies (rows : DemandNode → Option (List Dependency)) (node : DemandNode) : Option (List DemandNode) :=
  (rows node).map fun row =>
    (row.filter (fun edge => edge.reason != .visibility)).map Dependency.target

theorem executable_edge_is_retained
    {rows : DemandNode → Option (List Dependency)} {node : DemandNode}
    {row : List Dependency} {edge : Dependency}
    (found : rows node = some row) (inRow : edge ∈ row)
    (executable : edge.reason ≠ .visibility) :
    ∃ selected, executionDependencies rows node = some selected ∧ edge.target ∈ selected := by
  refine ⟨(row.filter (fun item => item.reason != .visibility)).map Dependency.target, ?_, ?_⟩
  · simp [executionDependencies, found]
  · apply List.mem_map_of_mem
    simp [inRow, executable]

structure Boundary where
  manual : List String
  automatic : List String
  demand : List DemandNode
  initialization : List DemandNode

def extraImages (boundary : Boundary) : List String :=
  boundary.automatic.filter (fun image => !(boundary.manual.contains image))

/-- The reference rows describe required startup work independently of
the candidate. An unavailable required row rejects the boundary. -/
def passesImages (reference : Table DemandNode) (fuel : Nat) (boundary : Boundary) : Bool :=
  match plan reference fuel (boundary.demand ++ boundary.initialization) with
  | none => false
  | some required =>
    let physical := required.filterMap physicalImage
    decide boundary.automatic.Nodup &&
      physical.all boundary.automatic.contains &&
      (extraImages boundary).all physical.contains

theorem passed_extra_is_required {reference : Table DemandNode} {edge : Graph DemandNode}
    {fuel : Nat} {boundary : Boundary} {image : String}
    (exactRows : Exact reference edge)
    (accepted : passesImages reference fuel boundary = true)
    (externallyObserved : image ∈ boundary.automatic)
    (aboveManual : image ∉ boundary.manual) :
    Required (boundary.demand ++ boundary.initialization) edge (.image image) := by
  unfold passesImages at accepted
  split at accepted
  next => contradiction
  next required computed =>
    have extra : image ∈ extraImages boundary := by
      simp [extraImages, externallyObserved, aboveManual]
    simp only [Bool.and_eq_true] at accepted
    have member := List.contains_iff_mem.mp (List.all_eq_true.mp accepted.2 _ extra)
    exact (plan_exact exactRows computed).2 _ |>.mp ((mem_physical_images image required).mp member)

theorem passed_retains_required {reference : Table DemandNode} {edge : Graph DemandNode}
    {fuel : Nat} {boundary : Boundary} {image : String}
    (exactRows : Exact reference edge)
    (accepted : passesImages reference fuel boundary = true)
    (needed : Required (boundary.demand ++ boundary.initialization) edge (.image image)) :
    image ∈ boundary.automatic := by
  unfold passesImages at accepted
  split at accepted
  next => contradiction
  next required computed =>
    have included := (mem_physical_images image required).mpr
      ((plan_exact exactRows computed).2 _ |>.mpr needed)
    simp only [Bool.and_eq_true] at accepted
    exact List.contains_iff_mem.mp (List.all_eq_true.mp accepted.1.2 _ included)

structure TimedRun where
  importUs : Nat
  receiptUs : Nat
  exitUs : Nat
  peakBytes : Nat
  deriving Repr

structure Pair where
  trial : Nat
  automatic : TimedRun
  manual : TimedRun
  deriving Repr

/-- Twice the median avoids rounding half a microsecond in even samples. -/
def medianTwice (samples : List Int) : Option Int :=
  let sorted := samples.mergeSort (· ≤ ·)
  match sorted.length with
  | 0 => none
  | n + 1 => (· + ·) <$> sorted[n / 2]? <*> sorted[(n + 1) / 2]?

def pairedMedianTwice (metric : TimedRun → Nat) (pairs : List Pair) : Option Int :=
  medianTwice (pairs.map fun pair => (metric pair.automatic : Int) - (metric pair.manual : Int))

structure LatencyBudget where
  importUs : Nat
  receiptUs : Nat

def passesLatency (trialIds : List Nat) (budget : LatencyBudget) (pairs : List Pair) : Bool :=
  decide (trialIds.Nodup ∧ pairs.map Pair.trial = trialIds) &&
    (pairedMedianTwice TimedRun.importUs pairs).any (· ≤ 2 * (budget.importUs : Int)) &&
    (pairedMedianTwice TimedRun.receiptUs pairs).any (· ≤ 2 * (budget.receiptUs : Int))

structure Scope where
  semanticFixtures : List SemanticFixture
  afterImport : Boundary
  afterReceipt : Boundary
  pairedTrials : List Pair

def passes (reference : Table DemandNode) (fuel : Nat) (trialIds : List Nat)
    (budget : LatencyBudget) (scope : Scope) : Bool :=
  decide (scope.semanticFixtures.map SemanticFixture.id = requiredFixtures) &&
    scope.semanticFixtures.all passesSemantics &&
    passesImages reference fuel scope.afterImport &&
    passesImages reference fuel scope.afterReceipt &&
    passesLatency trialIds budget scope.pairedTrials

-- Two images can share a name in malformed telemetry. Count them once in
-- the planner and reject the malformed observation at this gate.
def exampleRows : Table DemandNode
  | .binding "reader-binding" 0 => some [.image "reader"]
  | .initializer "capture" => some [.image "capture", .image "flags"]
  | .image "reader" | .image "capture" | .image "flags" => some []
  | _ => none

def exampleBoundary : Boundary :=
  ⟨["reader"], ["reader", "capture", "flags"], [.binding "reader-binding" 0], [.initializer "capture"]⟩

#guard passesImages exampleRows 5 exampleBoundary
#guard !passesImages exampleRows 5
  { exampleBoundary with automatic := ["reader", "capture", "flags", "unused"] }
#guard !passesImages exampleRows 5 { exampleBoundary with automatic := ["reader", "capture"] }
#guard !passesImages exampleRows 5 { exampleBoundary with automatic := ["reader", "reader"] }
#guard !passesImages exampleRows 5 { exampleBoundary with initialization := [.initializer "unknown"] }
#guard !passesImages exampleRows 5 { exampleBoundary with automatic := [] }
#guard medianTwice [] == none
#guard medianTwice [3, 1, 8, 2] == some 5
#guard medianTwice [3, 1, 8] == some 6


-- The ordinary IO import preserves visibility of socket names. Actual
-- reader binding demand and the environment capture still reach their
-- physical providers. An untreated effect dependency cannot be erased.
def rowKinds : DemandNode → Option (List Dependency)
  | .binding "reader" 0 =>
    some [⟨.binding "socket" 0, .visibility⟩, ⟨.image "reader-body", .bindingUse⟩]
  | .initializer "capture" =>
    some [⟨.image "capture-body", .initialization⟩, ⟨.initializer "earlier", .evaluationOrder⟩]
  | .initializer "earlier" =>
    some [⟨.image "earlier-body", .initialization⟩]
  | .image "reader-body" | .image "capture-body" | .image "earlier-body" => some []
  | _ => none

def reasonedBoundary : Boundary :=
  ⟨["reader-body"], ["reader-body", "earlier-body", "capture-body"],
   [.binding "reader" 0], [.initializer "capture"]⟩

#guard passesImages (executionDependencies rowKinds) 8 reasonedBoundary
#guard !passesImages (executionDependencies rowKinds) 8
  { reasonedBoundary with automatic := ["reader-body", "capture-body"] }
#guard !passesImages (executionDependencies rowKinds) 8
  { reasonedBoundary with demand := [.binding "socket" 0] }


/-- References come from the expanded consumer, and reexport checks retain
binding identity without adding an executable dependency. -/
inductive ExpandedObservation where
  | name (origin : ExportName) (expected : BindingKey)
  | read (key : BindingKey)
  | expand (key : BindingKey)
  | initialize (owner : Nat) (phase : Int) (slot : Nat)
  | opaqueBoundary
  deriving DecidableEq, Repr

def expandedRoots (exports : Exports) (nameFuel : Nat)
    (observations : List ExpandedObservation) : Option (List Request) := do
  let chunks ← observations.mapM fun event =>
    match event with
    | .name origin expected =>
      if resolveName exports nameFuel origin = some expected then some [] else none
    | .read key => some [.value key]
    | .expand key => some [.transformer key]
    | .initialize owner phase slot => some [.initialize owner phase slot]
    | .opaqueBoundary => none
  pure chunks.flatten

theorem lookup_only_has_no_work {exports : Exports} {name : ExportName} {key : BindingKey}
    (resolved : resolveName exports fuel name = some key) :
    expandedRoots exports fuel [.name name key] = some [] := by
  simp [expandedRoots, resolved]

def scheduledRequest : Request → Bool
  | .initialize .. | .image .. => true
  | _ => false

/-- Uses the existing least-closure kernel. The supplied schedule is the
audited ordinary prefix at this boundary, with one action per identity. -/
def prepareBoundary (table : Table Request) (fuel : Nat) (roots ordinary : List Request) :
    Option (List Request) := do
  let kept ← plan table fuel roots
  if (kept.filter scheduledRequest).all ordinary.contains && decide ordinary.Nodup then
    some (projectSchedule kept id ordinary)
  else none

theorem prepared_boundary_preserves_order {table : Table Request} {roots ordinary actions : List Request}
    (accepted : prepareBoundary table fuel roots ordinary = some actions) : actions.Sublist ordinary := by
  cases closure : plan table fuel roots with
  | none => simp [prepareBoundary, closure] at accepted
  | some kept =>
    simp [prepareBoundary, closure] at accepted
    rw [← accepted.2]
    exact schedule_keeps_order kept id ordinary

theorem prepared_boundary_retains_required
    {table : Table Request} {edge : Graph Request} {roots ordinary actions : List Request}
    (exactRows : Exact table edge)
    (accepted : prepareBoundary table fuel roots ordinary = some actions)
    (needed : Required roots edge request) (scheduled : scheduledRequest request = true) :
    request ∈ actions := by
  cases closure : plan table fuel roots with
  | none => simp [prepareBoundary, closure] at accepted
  | some kept =>
    have retained := (plan_exact exactRows closure).2 request |>.mpr needed
    simp [prepareBoundary, closure] at accepted
    have inOrdinary : request ∈ ordinary := by
      simpa [scheduled] using accepted.1.1 request retained
    rw [← accepted.2]
    simp [projectSchedule, retained, inOrdinary]

theorem prepared_boundary_is_minimal
    {table : Table Request} {edge : Graph Request} {roots ordinary actions : List Request}
    (exactRows : Exact table edge)
    (accepted : prepareBoundary table fuel roots ordinary = some actions)
    (present : request ∈ actions) : Required roots edge request := by
  cases closure : plan table fuel roots with
  | none => simp [prepareBoundary, closure] at accepted
  | some kept =>
    simp [prepareBoundary, closure] at accepted
    rw [← accepted.2] at present
    have retained : request ∈ kept := by simpa [projectSchedule] using (List.mem_filter.mp present).2
    exact (plan_exact exactRows closure).2 request |>.mp retained

structure ReaderStartup where
  selection : StartupSelection
  onImport : List Request
  beforeFirstReceipt : List Request
  deriving DecidableEq, Repr

/-- Preparation happens once against the exact selected compilation.
The second boundary may add work after the first boundary. It cannot
insert a previously omitted event ahead of an action already executed. -/
def prepareReaderStartup (selection : StartupSelection) (exports : Exports)
    (nameFuel : Nat) (table : Table Request) (fuel : Nat)
    (importUses receiptUses : List ExpandedObservation)
    (ordinaryImport ordinaryReceipt : List Request) : Option ReaderStartup := do
  let importRoots ← expandedRoots exports nameFuel importUses
  let receiptRoots ← expandedRoots exports nameFuel receiptUses
  let early ← prepareBoundary table fuel importRoots ordinaryImport
  let complete ← prepareBoundary table fuel (importRoots ++ receiptRoots) ordinaryReceipt
  let late := complete.drop early.length
  if early ++ late = complete then
    some ⟨selection, early, late⟩
  else none

/-- This entry does no export resolution, graph discovery or schedule replay.
The existing loader owns executing the two deltas and publishing readiness. -/
def selectReaderStartup (selection : StartupSelection) (opaqueBoundary : Bool)
    (prepared : ReaderStartup) : Option (List Request × List Request) :=
  if opaqueBoundary then none
  else if selection = prepared.selection then some (prepared.onImport, prepared.beforeFirstReceipt)
  else none

theorem reader_selection_uses_prepared_actions (prepared : ReaderStartup) :
    selectReaderStartup prepared.selection false prepared =
      some (prepared.onImport, prepared.beforeFirstReceipt) := by simp [selectReaderStartup]

theorem reader_stale_selection_falls_back (prepared : ReaderStartup)
    (changed : selection ≠ prepared.selection) :
    selectReaderStartup selection false prepared = none := by simp [selectReaderStartup, changed]

namespace StartupExample

def facadeName : ExportName := ⟨1, 0, 9⟩
def forwardedName : ExportName := ⟨2, 0, 9⟩
def socketName : ExportName := ⟨1, 0, 12⟩
def reader : BindingKey := ⟨3, 0, 1⟩
def socket : BindingKey := ⟨4, 0, 1⟩
def writer : BindingKey := ⟨5, 0, 1⟩
def readerMacro : BindingKey := ⟨3, 1, 1⟩
def capture : Request := .initialize 6 0 1
def flags : Request := .initialize 7 0 1
def readerBody : Request := .image 3 0 0
def writerBody : Request := .image 5 0 0
def socketBody : Request := .image 4 0 0
def macroBody : Request := .image 3 1 0

def exports (name : ExportName) : Option ExportEntry :=
  if name = facadeName then some (.reexported forwardedName)
  else if name = forwardedName then some (.defined reader)
  else if name = socketName then some (.defined socket)
  else none

def rows (request : Request) : Option (List Request) :=
  if request = .value reader then some [readerBody]
  else if request = .value writer then some [writerBody]
  else if request = .value socket then some [socketBody]
  else if request = .transformer readerMacro then some [macroBody]
  else if request = capture then some [flags]
  else if [readerBody, writerBody, flags, macroBody, socketBody].contains request then some []
  else none

def importUses : List ExpandedObservation :=
  [.name facadeName reader, .name socketName socket, .read reader, .initialize 6 0 1]
def receiptUses : List ExpandedObservation := [.read writer]
def ordinaryImport : List Request := [socketBody, macroBody, flags, capture, readerBody]
def ordinaryReceipt : List Request := ordinaryImport ++ [writerBody]
def selection : StartupSelection := ⟨1, 2, 3⟩
def prepared : Option ReaderStartup :=
  prepareReaderStartup selection exports 4 rows 16 importUses receiptUses ordinaryImport ordinaryReceipt

#guard prepared.map ReaderStartup.onImport == some [flags, capture, readerBody]
#guard prepared.map ReaderStartup.beforeFirstReceipt == some [writerBody]
#guard expandedRoots exports 4 [.name socketName reader] == none
#guard expandedRoots exports 4 [.opaqueBoundary, .read reader] == none
#guard prepareBoundary rows 16 [.value reader, capture] [readerBody, capture] == none
#guard prepareBoundary rows 16 [.value reader, .transformer readerMacro] ordinaryImport ==
  some [macroBody, readerBody]
#guard prepareReaderStartup selection exports 4 rows 16 importUses receiptUses ordinaryImport
  [writerBody, flags, capture, readerBody] == none
#guard prepared.bind (selectReaderStartup ⟨1, 2, 4⟩ false) == none

end StartupExample

/-- Bind each required action to its actual executable image before checking
the ordered effects. An unknown action-to-image row prevents admission. -/
def preparePhysicalBoundary (delivery : Request → Option Effects.ImageIdentity)
    (success failure : List Nat) (ordinary : List Effects.ImageGroup)
    (actions : List Request) : Option (List Effects.ImageGroup) :=
  (actions.mapM delivery).bind (Effects.checkImagePlan success failure ordinary)

theorem prepared_physical_boundary_refines
    {delivery : Request → Option Effects.ImageIdentity} {success failure : List Nat}
    {ordinary selected : List Effects.ImageGroup} {actions : List Request}
    (unknown : Effects.UnknownEffect) (store : Effects.Store)
    (accepted : preparePhysicalBoundary delivery success failure ordinary actions = some selected) :
    Effects.SameResult success failure
      (Effects.execute unknown store (Effects.imageActions ordinary))
      (Effects.execute unknown store (Effects.imageActions selected)) := by
  cases delivered : actions.mapM delivery with
  | none => simp [preparePhysicalBoundary, delivered] at accepted
  | some images =>
    have checked : Effects.checkImagePlan success failure ordinary images = some selected := by
      simpa [preparePhysicalBoundary, delivered] using accepted
    exact Effects.checked_images_refine_ordinary unknown store checked

private def imageContract (image : Effects.ImageGroup) : Effects.ImageIdentity × List Effects.Action :=
  (image.identity, image.actions)

/-- Reject a receipt plan that would insert an image ahead of an image
already executed at import, or change the action list of an existing image. -/
def physicalReceiptDelta (early complete : List Effects.ImageGroup) :
    Option (List Effects.ImageGroup) :=
  let delta := complete.drop early.length
  if (early ++ delta).map imageContract = complete.map imageContract
  then some delta
  else none

theorem physical_delta_preserves_prefix {early complete delta : List Effects.ImageGroup}
    (accepted : physicalReceiptDelta early complete = some delta) :
    early.map imageContract ++ delta.map imageContract = complete.map imageContract := by
  dsimp [physicalReceiptDelta] at accepted
  split at accepted
  next same =>
    have equal := Option.some.inj accepted
    subst delta
    simpa only [List.map_append] using same
  next _ => contradiction

structure PhysicalReaderStartup where
  selection : StartupSelection
  onImport : List Effects.ImageGroup
  beforeFirstReceipt : List Effects.ImageGroup

def preparePhysicalReaderStartup (logical : ReaderStartup)
    (delivery : Request → Option Effects.ImageIdentity)
    (importLive receiptLive failureLive : List Nat)
    (ordinaryImport ordinaryReceipt : List Effects.ImageGroup) : Option PhysicalReaderStartup := do
  let early ← preparePhysicalBoundary delivery importLive failureLive ordinaryImport logical.onImport
  let complete ← preparePhysicalBoundary delivery receiptLive failureLive ordinaryReceipt
    (logical.onImport ++ logical.beforeFirstReceipt)
  let delta ← physicalReceiptDelta early complete
  pure ⟨logical.selection, early, delta⟩

namespace PhysicalStartupExample

def addressRegistration : Request := .initialize 1 0 1
def readerLoad : Request := .image 2 0 0
def writerLoad : Request := .image 3 0 0

def addressInit : Effects.ImageGroup := ⟨⟨1, 0, some 0⟩, [.emit 1]⟩
def reader : Effects.ImageGroup := ⟨⟨2, 0, some 0⟩, [.put 2 5]⟩
def writer : Effects.ImageGroup := ⟨⟨3, 0, some 0⟩, [.put 3 6]⟩
def unusedVisit : Effects.ImageGroup := ⟨⟨4, 1, some 1⟩, [.put 4 7]⟩

def delivery (action : Request) : Option Effects.ImageIdentity :=
  if action = addressRegistration then some addressInit.identity
  else if action = readerLoad then some reader.identity
  else if action = writerLoad then some writer.identity
  else none

def logical : ReaderStartup := ⟨⟨1, 2, 3⟩, [addressRegistration, readerLoad], [writerLoad]⟩
def ordinaryImport : List Effects.ImageGroup := [unusedVisit, addressInit, reader]
def ordinaryReceipt : List Effects.ImageGroup := ordinaryImport ++ [writer]

#guard (preparePhysicalReaderStartup logical delivery [2] [2, 3] [] ordinaryImport ordinaryReceipt).map
    (fun p => p.onImport.map Effects.ImageGroup.identity) == some [addressInit.identity, reader.identity]
#guard (preparePhysicalReaderStartup logical delivery [2] [2, 3] [] ordinaryImport ordinaryReceipt).map
    (fun p => p.beforeFirstReceipt.map Effects.ImageGroup.identity) == some [writer.identity]
#guard (preparePhysicalReaderStartup { logical with onImport := [readerLoad] }
    delivery [2] [2, 3] [] ordinaryImport ordinaryReceipt).isNone
#guard (preparePhysicalReaderStartup logical (fun _ => none) [2] [2, 3] []
    ordinaryImport ordinaryReceipt).isNone
#guard (preparePhysicalReaderStartup logical delivery [2] [2, 3] []
    ordinaryImport [writer, addressInit, reader]).isNone
#guard (physicalReceiptDelta [addressInit, reader]
    [addressInit, { reader with actions := [.put 2 99] }, writer]).isNone

end PhysicalStartupExample

end JsonReaderScope
