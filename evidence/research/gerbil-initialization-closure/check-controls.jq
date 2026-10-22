def size($k;$n): (.[$k]|length)==$n;
size("modelRequired";28) and size("initializationReach";12) and
size("initializationBoundary";4) and size("sourceRoute";4) and
size("dependencyCycle";0) and size("danglingDependency";0) and
size("unboundDependency";0) and size("unroutedNeed";0) and
.runtimeAdmitted==false and .counts.hypotheses==1 and .counts.support==0 and
if $scenario=="all-scoped-control" then
  size("locallyChecked";28) and size("componentReady";3) and size("componentFrontier";0)
  and size("freezeMissingGate";8) and size("freezeDenied";9) and size("freezeCandidate";0)
elif $scenario=="synthetic-closed-positive" then
  size("locallyChecked";8) and size("componentReady";0) and size("componentFrontier";20)
  and size("freezeMissingGate";0) and size("freezeDenied";0) and .freezeCandidate==[[$scenario]]
elif $scenario=="missing-lifetime-control" then
  size("locallyChecked";8) and size("componentReady";0) and size("componentFrontier";20)
  and .freezeMissingGate==[[$scenario,"lifetime"]] and .freezeDenied==[[$scenario,"lifetime"]]
  and size("freezeCandidate";0)
else
  size("componentReady";0) and size("freezeMissingGate";8) and size("freezeDenied";9)
  and size("freezeCandidate";0) and
  if $scenario=="current" then
    size("componentFrontier";20) and
    ([.locallyChecked[][2]]|sort)==["FI-H","FI-I","GM-H","GM-I","GS-H","GS-I","IC-H","IC-I"]
  else size("locallyChecked";7) and size("componentFrontier";21) and
    ([.locallyChecked[][2]]|index(if $scenario=="wrong-scope" then "IC-I" else "IC-H" end))==null
  end
end
