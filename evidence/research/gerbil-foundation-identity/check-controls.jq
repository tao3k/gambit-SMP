def size($k;$n): (.[$k]|length)==$n;
size("modelRequired";24) and
size("imageCandidate";1) and size("canonicalDefinition";1) and
size("reconstructionRequired";6) and size("serializedInstanceRequired";2) and
size("supportClosure";9) and size("opaqueSupport";3) and
size("stateOwnership";8) and size("sourceRoute";3) and
size("dependencyCycle";0) and size("danglingDependency";0) and
size("unboundDependency";0) and size("unroutedNeed";0) and
.foundationAdmissionBlocked==[[$scenario,"foundation-source-open"]] and
(.sourceAdmissionBlocked|length)>0 and .runtimeAdmitted==false and
.counts.hypotheses==1 and .counts.support==0 and
if $scenario=="all-scoped-control" then
  size("locallyChecked";24) and size("componentReady";3) and size("componentFrontier";0)
else
  size("componentReady";0) and
  if $scenario=="current" then
    size("componentFrontier";18) and
    ([.locallyChecked[][2]]|sort)==["FI-H","FI-I","GM-H","GM-I","GS-H","GS-I"]
  else size("locallyChecked";5) and size("componentFrontier";19) end
end
