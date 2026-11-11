def containsRow($r): any(.[]; .==$r);
(.counts.hypotheses==1 and .counts.support==0 and .counts.counter==0) and
(.modelRequired|length==24) and (.qualifiedSlice|length==6) and
(.missingModel|containsRow(["missing-qnt","gc-synchronous-publication","SP-HISTORY","QNT"])) and
(.qualifiedSlice|map(select(.[0]=="current"))|length==2) and
(.qualifiedSlice|all(.[]; .[2]!="SP-SOURCE" and .[2]!="SP-MEMORY")) and
(.unmetDependency|containsRow(["current","gc-synchronous-publication","SP-SOURCE","SP-MEMORY"])) and
(.nextAction|containsRow(["current","gc-synchronous-publication","SP-SOURCE","resolve-prerequisite","Lean","SP-MEMORY"])) and
(["no-receipts","typecheck-only","stale-receipt","wrong-scope"] | all(.[]; . as $s | $data[0].pendingCheck | any(.[]; .[0]==$s and .[2]=="SP-HISTORY"))) and
(.dependencyCycle|length==0) and (.unroutedNeed|length==0)
