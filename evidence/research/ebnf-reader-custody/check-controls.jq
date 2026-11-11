def size($k;$n): (.[$k]|length)==$n;
size("modelRequired";32) and size("readerReach";12) and
size("readerFreezeCandidate";2) and size("readerOwnerRequired";3) and
size("readerBoundary";6) and size("sourceRoute";5) and
size("dependencyCycle";0) and size("danglingDependency";0) and
size("unboundDependency";0) and size("unroutedNeed";0) and
.runtimeAdmitted==false and .counts.hypotheses==1 and .counts.support==0 and
if $scenario=="all-scoped-control" then
  size("locallyChecked";32) and size("componentReady";3) and size("componentFrontier";0)
  and size("readerMissingGate";5) and size("readerAdmissionDenied";6) and size("readerAdmissionCandidate";0)
elif $scenario=="synthetic-closed-positive" then
  size("locallyChecked";10) and size("componentReady";0) and size("componentFrontier";22)
  and size("readerMissingGate";0) and size("readerAdmissionDenied";0) and .readerAdmissionCandidate==[[$scenario]]
elif $scenario=="missing-cursor-control" then
  size("locallyChecked";10) and size("componentReady";0) and size("componentFrontier";22)
  and .readerMissingGate==[[$scenario,"cursorHandoff"]] and .readerAdmissionDenied==[[$scenario,"cursorHandoff"]]
  and size("readerAdmissionCandidate";0)
else
  size("componentReady";0) and size("readerMissingGate";5) and size("readerAdmissionDenied";6)
  and size("readerAdmissionCandidate";0) and
  if $scenario=="current" then
    size("componentFrontier";22) and
    ([.locallyChecked[][2]]|sort)==["ER-H","ER-I","FI-H","FI-I","GM-H","GM-I","GS-H","GS-I","IC-H","IC-I"]
  else size("locallyChecked";9) and size("componentFrontier";23) and
    ([.locallyChecked[][2]]|index(if $scenario=="wrong-scope" then "ER-I" else "ER-H" end))==null
  end
end
