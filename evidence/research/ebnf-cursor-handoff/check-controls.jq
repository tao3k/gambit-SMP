def size($k;$n): (.[$k]|length)==$n;
size("modelRequired";36) and size("cursorReach";9) and size("cursorWitness";1) and
size("cursorNativeWitness";0) and size("modeRepairRequired";3) and size("sourceRoute";6) and
size("dependencyCycle";0) and size("danglingDependency";0) and
size("unboundDependency";0) and size("unroutedNeed";0) and
.runtimeAdmitted==false and .counts.hypotheses==1 and .counts.support==0 and
if $scenario=="all-scoped-control" then
 size("locallyChecked";36) and size("componentReady";3) and size("componentFrontier";0)
 and size("cursorMissingGate";4) and size("cursorAdmissionDenied";5) and size("cursorAdmissionCandidate";0)
elif $scenario=="synthetic-closed-positive" then
 size("locallyChecked";12) and size("componentReady";0) and size("componentFrontier";24)
 and size("cursorMissingGate";0) and size("cursorAdmissionDenied";0) and .cursorAdmissionCandidate==[[$scenario]]
elif $scenario=="missing-positions-control" then
 size("locallyChecked";12) and size("componentReady";0) and size("componentFrontier";24)
 and .cursorMissingGate==[[$scenario,"positions"]] and .cursorAdmissionDenied==[[$scenario,"positions"]]
 and size("cursorAdmissionCandidate";0)
else
 size("componentReady";0) and size("cursorMissingGate";4) and size("cursorAdmissionDenied";5)
 and size("cursorAdmissionCandidate";0) and
 if $scenario=="current" then
  size("componentFrontier";24) and ([.locallyChecked[][2]]|sort)==
   ["CH-H","CH-I","ER-H","ER-I","FI-H","FI-I","GM-H","GM-I","GS-H","GS-I","IC-H","IC-I"]
 else size("locallyChecked";11) and size("componentFrontier";25) and
  ([.locallyChecked[][2]]|index(if $scenario=="wrong-scope" then "CH-I" else "CH-H" end))==null
 end
end
