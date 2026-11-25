def cell: tostring | gsub("\\|"; "/") | gsub("\n"; " ");
def row: "| " + (map(cell) | join(" | ")) + " |";
def minor_sites: .sourceSites[] | select(.role == "minor-admission");
def service_sites: .sourceSites[] | select(.role == "request-service-design");
def service_flows: [.flows[] | select(.contract | startswith("Repair9:"))];
{
  serviceOrg: (["#+NAME: request-service-source-contracts", "| Source / current mechanism | Required refinement | Open boundary |", "|---+---+---|"] +
    [service_sites | [.id + " / " + .artifact + ":" + (.lines|map(tostring)|join(",")) + " / " + .observed, .required, .gap] | row] | join("\n")) + "\n",
  serviceD2: (service_flows as $edges | ($edges | map(.producer,.consumer) | unique) as $ids |
    ["direction: right", "scope: { label: \"Modern C request / wait / service / GC / exit\\nConditional source refinement; native Repair9 closure OPEN\"; style.fill: \"#fff0c2\" }"] +
    [.components[] | select(.id as $i | $ids | index($i)) | .id + ": { label: " + (.label|tojson) + " }"] +
    [$edges[] | .producer + " -> " + .consumer + ": " + (.contract|tojson)] | join("\n")) + "\n",
  minorOrg: ([
    "#+NAME: minor-gc-source-admission",
    "| Existing gate / source | Evidence | Proposed contract | Native gate still open |",
    "|---+---+---+---|"
  ] + [minor_sites | [
    .question + " / " + .artifact + ":" + (.lines|map(tostring)|join(",")),
    .observed, .required, .gap
  ] | row] | join("\n")) + "\n",
  minorD2: ([
    "direction: right",
    "mvp: { label: \"DEV p1 control / full collector overlay\" }",
    "admission: { label: \"One product minor GC subject / OPEN\"; style.fill: \"#fff0c2\" }"
  ] + [minor_sites | (.id|tojson) + ": { label: " + ((.question + "\n" + .id + " / OPEN")|tojson) + " }"] +
  [minor_sites | (.id|tojson) + " -> admission: \"required\""] +
  (if ([minor_sites | .id] | contains(["minorGcPauseBoundary", "minorGcReturnTarget"])) then
    ["minorGcPauseBoundary -> minorGcReturnTarget: \"restored address and same-GC operation witness\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["workerGuardedPublication", "workerGuardedPark", "minorGcCollectorCosts"])) then
    ["workerGuardedPublication -> workerGuardedPark: \"publish, release FIFO gate, notify\"",
     "workerGuardedPark -> minorGcCollectorCosts: \"queue recheck before idle; measure separately from tree wake\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorGcCollectorCosts", "minorGcPauseBoundary"])) then
    ["minorGcCollectorCosts -> minorGcPauseBoundary: \"carrier work, CPU and same-call condition timeline\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["workerGuardedPark", "workerWaiterGatedPark"])) then
    ["workerGuardedPark -> workerWaiterGatedPark: \"register before FIFO recheck; notify only below full phase count\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorGcPauseBoundary", "minorParticipantHandoff"])) then
    ["minorGcPauseBoundary -> minorParticipantHandoff: \"request, last arrival, collector, last loop drain\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorExecAdmissionClose", "minorSuccessorRetire"])) then
    ["minorExecAdmissionClose -> minorSuccessorRetire: \"close registration; replay admitted ACKs after crash and last lease drain\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorWeakEntry", "minorWeakTableRepair", "minorWeakTableReopen"])) then
    ["minorWeakEntry -> minorWeakTableRepair: \"weak work drains before cleanup\"",
     "minorWeakTableRepair -> minorWeakTableReopen: \"final slots before bank commit and owner reopen\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorTablePermutation", "minorTableReplacement", "minorTableBankReader"])) then
    ["minorTablePermutation -> minorTableBankReader: \"layout revision redirects old records\"",
     "minorTableReplacement -> minorTableBankReader: \"independent backing identities\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorTableFreezeJoin", "minorTablePartialCoverage", "minorTableRetentionBudget", "minorTableBankReader"])) then
    ["minorTablePartialCoverage -> minorTableFreezeJoin: \"root both backings before freeze\"",
     "minorTableRetentionBudget -> minorTableFreezeJoin: \"reserve before invalidation\"",
     "minorTableFreezeJoin -> minorTableBankReader: \"sealed current typed coverage\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorTableFreezeJoin", "minorSuccessorClaim", "minorSuccessorFinish", "minorSuccessorRetire"])) then
    ["minorTableFreezeJoin -> minorSuccessorClaim: \"deduplicated sealed coverage\"",
     "minorSuccessorClaim -> minorSuccessorFinish: \"exact claim and final typed receipt\"",
     "minorSuccessorFinish -> minorSuccessorRetire: \"successor coverage plus last-reader drain\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorTakeoverFrontier", "minorTakeoverWeak", "minorTakeoverStop", "minorSuccessorFinish"])) then
    ["minorTakeoverFrontier -> minorTakeoverStop: \"settled frontier and writer closure\"",
     "minorTakeoverWeak -> minorTakeoverStop: \"durable weak effect custody\"",
     "minorTakeoverStop -> minorSuccessorFinish: \"authorized takeover then final receipt\""]
   else [] end) +
  (if ([minor_sites | .id] | contains(["minorAtomicStop", "minorWeakCommit", "minorParticipantHandoff", "minorSuccessorFinish"])) then
    ["minorWeakCommit -> minorAtomicStop: \"settle exact child publication\"",
     "minorAtomicStop -> minorParticipantHandoff: \"grant successor and settled frontier together\"",
     "minorParticipantHandoff -> minorSuccessorFinish: \"W debt transferred; R custody verified\""]
   else [] end) +
  ["mvp -> admission: \"scoped evidence only\""] | join("\n")) + "\n",
  org: ([
    "#+NAME: shared-heap-smp-contracts",
    "#+BEGIN: sysml-view :kind shared-heap-smp :source models/sysml/shared-heap-smp.sysml",
    "| Declared proof dependency | Release / immutable revision | Toolchain |",
    "|---+---+---|",
    ([.leanLibraryModule, .leanLibraryRelease + " / " + .leanLibraryRevision, .leanLibraryToolchain] | row),
    "", "| Progress axis | Reported source-period status | Meaning | Credit boundary |",
    "|---+---+---+---|"
  ] + [.progressAxes[] | [.id, .reported, .meaning, .credit] | row] + [
    "", "| SysML responsibility module | Native package | Single source | Lines |",
    "|---+---+---+---|"
  ] + [(.sourceModules // [])[] | [.responsibility,.namespace,.source,.lines] | row] + [
    "", "| Workstream / authority | Complete delivery unit | Entry / exit | Excluded work | Benefit and added cost |",
    "|---+---+---+---+---|"
  ] + [.workstreams[] | [.label + " / " + .authority, .unit, .entry + " / " + .exit, .excluded, .netBenefit] | row] + [
    "", "| Workstream | ASCENT-derived blocker |", "|---+---|"
  ] + [.workOpen[] | row] + [
    "", "| Supporting factor / existing owner | Exact subject / scope | Actual observation | Boundary |",
    "|---+---+---+---|"
  ] + [.supportFactors[] | [.id + " / " + .authority,
    .artifact + " / " + .subjectSha256 + " / " + .scope,
    (if .checked then .owner + " scoped support checked" else "OPEN" end), .boundary] | row] + [
    "", "| Question | Primary workstream |", "|---+---|"
  ] + [.assignments[] | [.question, .workstream] | row] + [
    "", "| Component / authority | Guarantee | Responsibility retired after qualification | Added cost | Falsifier |",
    "|---+---+---+---+---|"
  ] + [.components[] | [.label + " / " + .authority, .guarantee, .retirement, .cost, .falsifier] | row] + [
    "", "| Obligation | Exclusive owner | Actual local evidence | Remaining boundary |",
    "|---+---+---+---|"
  ] + [.questions[] | . as $q | [$q.id + " / " + $q.semanticKey, $q.owner,
      (if .checked then "checked exact declared local scope" else "OPEN" end), $q.question] | row] + [
    "", "| Joint implementation gate | Primary workstream | Source/native requirement |",
    "|---+---+---|"
  ] + [. as $flow | .questions[] | select(.owner == "source" or .owner == "native") |
      . as $q | [$q.id + " / " + $q.owner,
      ([$flow.assignments[] | select(.question == $q.id) | .workstream] | join(", ")),
      $q.question] | row] + [
    "", "| Implementation call boundary | Observed mechanism | Required replacement | Unclosed premise |",
    "|---+---+---+---|"
  ] + [.sourceSites[] | select(.role == "implementation-handoff") |
      [.id + " / " + .question + " / " + .artifact + ":" + (.lines|map(tostring)|join(",")),
       .observed, .required, .gap] | row] + [
    "", "| Whole source adapter | Full subject digest | Actual clause evidence |",
    "|---+---+---|"
  ] + [.adapters[] | [.id + " / " + .question, .subjectSha256, (if .sourceClauseSetChecked then "scoped source clause attestations checked; not native acceptance" else "SOURCE_REFINEMENT_OPEN" end)] | row] + [
    "", "| Adapter | Contract field | Required meaning |", "|---+---+---|"
  ] + [.adapters[] | . as $a | ["inputs","precondition","authorization","linearization","postcondition","recovery","retirement","stateModel","dataModel","acceptance","rejection","benefit"][] | . as $field | [$a.id, $field, $a[$field]] | row] + [
    "", "| Source adapter clause | Actual evidence | Required rule | Implementation gap | Acceptance |",
    "|---+---+---+---+---|"
  ] + [.adapters[].clauses[] | [.adapter + " / " + .id + " / " + .kind, (if .checked then "exact-subject source attestation checked" else "OPEN" end), .rule, .missing, .acceptance] | row] + [
    "", "| Unified handoff | Contract field | Required meaning |", "|---+---+---|"
  ] + [.adapters[].protocols[] | . as $p | ["key","joinRule","scope","valuePolicy","unknownRule","retirement","acceptance","nonGoals"][] | . as $field | [$p.id,$field,$p[$field]] | row] + [
    "", "| Receipt role | Identity / condition | Outcomes | Permitted fact / forbidden inference | Unknown custody |",
    "|---+---+---+---+---|"
  ] + [.adapters[].protocols[].receipts[] | [.id + " / " + .kind, .identity + " / " + .condition, .outcomes, .permits + " / " + .forbids, .unknown] | row] + [
    "", "| Actual call boundary / site | Required input and commit point | Remaining implementation gap | Unknown-result custodian | Whole acceptance |",
    "|---+---+---+---+---|"
  ] + [.adapters[].protocols[].points[] | [.id + " / " + .site + " / " + .caller, .precondition + " / " + .linearization, .missing, .unknown, .acceptance] | row] + [
    "", "| Call boundary | Receipt role | Use | Conditional guard |", "|---+---+---+---|"
  ] + [.adapters[].protocols[].uses[] | [.point,.receipt,.role + " / " + .purpose,.condition] | row] + [
    "", "| Guarded source case | Required premise | Actual source argument / local conclusion | Remaining implementation gap | Acceptance / model boundary |",
    "|---+---+---+---+---|"
  ] + [.adapters[].sourceCases[] | [.id + " / existing clause " + .clause, .precondition, .argument + " / " + .conclusion, .missing, .acceptance + " / " + .formalBoundary] | row] + [
    "", "| Source counterargument | Conditions and limitation |", "|---+---|"
  ] + [.adapters[].sourceCases[] | [.id, .counterexample] | row] + [
    "", "| Adapter inventory | Declared source scope | Bound eligible files | Explicitly excluded products | Evidence class |",
    "|---+---+---+---+---|"
  ] + [.adapters[] | select(.inventory.scopes|length>0) | . as $a | .inventory.scopes[] | [$a.id, .path + " / " + .suffixes, ($a.inventory.files|length), ($a.inventory.excluded|length), .boundary] | row] + [
    "", "| Root-freeze access family | Lexical candidates / files | Known producer and consumer chain | Required access / publication / last use | Remaining gap / acceptance |",
    "|---+---+---+---+---|"
  ] + [.adapters[].inventory.families[] | [.id + " / " + .role, ((.matchCount|tostring) + " / " + (.artifactCount|tostring) + " / lexical only"), .knownCallers, .guard + " / " + .publication + " / " + .release, .gap + " / " + .acceptance] | row] + [
    "", "| Existing owner reused | Authority | Unresolved composition premise |",
    "|---+---+---|"
  ] + [.external[] | [.id, .authority, .premise] | row] + [
    "", "| Source site / question | Observed working bytes | Required adapter | Remaining gap |",
    "|---+---+---+---|"
  ] + [.sourceSites[] | [.id + " / " + .question, .artifact + ":" + (.lines|map(tostring)|join(",")) + " / " + .status + " / sha256=" + .sha256 + " / " + .observed, .required, .gap] | row] + [
    "", "Source/native frontier remains OPEN. These are assurance questions, not a new runtime/SMP progress denominator.",
    "#+END:"
  ] | join("\n")) + "\n",
  d2: (["direction: right", "classes: { component: { style.fill: \"#e8f1fb\" } }"] +
    ["modelModules: { label: \"SysML source modules / native import assembly\"; direction: down"] +
    [(.sourceModules // [])[] | (.namespace|tojson) + ": { label: " + ((.responsibility + "\n" + (.lines|tostring) + " source lines")|tojson) + " }"] +
    ["}"] +
    [.components[] | .id + ": { label: " + (.label|tojson) + "; class: component }"] +
    ["program: { label: \"Independent DEV workstreams / no progress transfer\"; direction: down"] +
    [.workstreams[] | .id + ": { label: " + (.label|tojson) + " }"] +
    [.workDependencies[] | .prerequisite + " -> " + .dependent + ": \"source-bound prerequisite\""] +
    ["}", "assurance: { label: \"Exclusive verification owners / source and native OPEN\"; direction: down"] +
    [.questions[] | (.id|tojson) + ": { label: " + ((.id + "\n" + .owner + " / " + (if .checked then "local scope checked" else "OPEN" end))|tojson) + " }"] +
    ["}"] +
    ["implementationBoundary: { label: \"Real call boundaries / implementation and acceptance gaps OPEN\"; direction: down"] +
    [.sourceSites[] | select(.role == "implementation-handoff") |
      (.id|tojson) + ": { label: " + ((.id + "\n" + .artifact + "\n" + .question)|tojson) + "; style.fill: \"#fff8e8\" }"] +
    ["}"] +
    [.sourceSites[] | select(.role == "implementation-handoff") |
      "implementationBoundary." + (.id|tojson) + " -> assurance." + (.question|tojson) + ": \"source-bound handoff; not closure\""] +
    [(.workOpen | map(.[0]) | unique)[] | "program." + . + ".style.fill: \"#fff0c2\""] +
    ["proofLibrary: { label: " + ((.leanLibraryModule + "\n" + .leanLibraryRelease + "\n" + .leanLibraryRevision + "\n" + .leanLibraryToolchain + "\nConditional data adapter; C proof still required")|tojson) + " }"] +
    [.questions[] | select(.owner=="lean") | "proofLibrary -> assurance." + (.id|tojson) + ": \"typed refinement dependency\""] +
    ["workFactors: { label: \"Model-owned work factors / source bridges remain required\"; direction: down"] +
    [.supportFactors[] | (.id|tojson) + ": { label: " + ((.id + "\n" + .owner + " / " + (if .checked then "scoped support checked" else "OPEN" end))|tojson) + " }"] +
    ["}"] +
    [.supportFactors[] | .component + " -> workFactors." + (.id|tojson) + ": \"existing owner support\""] +
    [.supportFactors[] | "workFactors." + (.id|tojson) + " -> assurance." + (.requiredFor|tojson) + ": \"required factor; no native promotion\""] +
    ["adapters: { label: \"Complete source adapters / clause set remains OPEN\"; direction: down"] +
    [.adapters[] | (.id|tojson) + ": { label: " + ((.id + "\n" + (.clauses|length|tostring) + " source clauses / " + (if .sourceClauseSetChecked then "scoped attestations checked" else "OPEN" end))|tojson) + "; style.fill: \"#fff0c2\" }"] +
    ["}"] +
    ["handoffFacts: { label: \"Unified root handoff / required facts, not runtime grants\"; direction: down"] +
    [.adapters[].protocols[].receipts[] | (.id|tojson) + ": { label: " + ((.id + "\n" + .kind)|tojson) + "; style.fill: \"#e8f7ed\" }"] +
    ["}", "callBoundaries: { label: \"Generator / native / collector / exit source refinement OPEN\"; direction: down"] +
    [.adapters[].protocols[].points[] | (.id|tojson) + ": { label: " + ((.id + "\n" + .clause + " / OPEN")|tojson) + "; style.fill: \"#fff8e8\" }"] +
    ["}"] +
    [.adapters[].protocols[].uses[] | (if .role=="establishes" then "callBoundaries." + (.point|tojson) + " -> handoffFacts." + (.receipt|tojson) else "handoffFacts." + (.receipt|tojson) + " -> callBoundaries." + (.point|tojson) end) + ": " + ((.role + " / " + .purpose)|tojson)] +
    ["sourceArguments: { label: \"Guarded C refinement arguments / full source proof OPEN\"; direction: down"] +
    [.adapters[].sourceCases[] | (.id|tojson) + ": { label: " + ((.id + "\n" + .clause + " / source premise OPEN")|tojson) + "; style.fill: \"#fff8e8\" }"] +
    ["}"] +
    [.caseDependencies[] | "sourceArguments." + (.prerequisite|tojson) + " -> sourceArguments." + (.dependent|tojson) + ": " + (.condition|tojson)] +
    [.adapters[] | . as $a | .sourceCases[] | "sourceArguments." + (.id|tojson) + " -> adapters." + ($a.id|tojson) + ": \"guarded source argument\""] +
    ["rootCoverage: { label: \"Whole root-freeze candidate coverage / source refinement OPEN\"; direction: down"] +
    [.adapters[].inventory.families[] | (.id|tojson) + ": { label: " + ((.id + "\n" + (.matchCount|tostring) + " lexical candidates / OPEN")|tojson) + "; style.fill: \"#f1f5ff\" }"] +
    ["}"] +
    [.adapters[] | . as $a | .inventory.families[] | "rootCoverage." + (.id|tojson) + " -> adapters." + ($a.id|tojson) + ": \"coverage premise\""] +
    [.adapters[] | "adapters." + (.id|tojson) + " -> assurance." + (.question|tojson) + ": \"full-subject refinement required\""] +
    [.assignments[] | "program." + .workstream + " -> assurance." + (.question|tojson) + ": \"primary obligation\""] +
    [.dependencies[] | "assurance." + (.[1]|tojson) + " -> assurance." + (.[0]|tojson) + ": { label: \"prerequisite\"; style.stroke-dash: 4 }"] +
    [.flows[] | .producer + " -> " + .consumer + ": " + (.contract|tojson)] +
    ["boundary: { label: \"Local formal evidence only\\nsource + native composition OPEN\"; style.fill: \"#fff0c2\" }",
     "qualification -> boundary: \"no automatic runtime promotion\""] | join("\n")) + "\n"
}
