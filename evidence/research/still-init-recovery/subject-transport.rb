p='dev/modeling/ascent/assurance-planner.ss';s=File.read(p)
new=<<~SS
 ;; Lossless subject transport for formal needs and their independent receipts.
 ;; A ref is data: dictionary joins recover exact artifact/scope before qualification.
 (relation subjectIdentityFact (ref artifact scope))
 (relation subjectTripleFact (r1 a1 t1 r2 a2 t2 r3 a3 t3))
 ((subjectIdentityFact R A T) <-- (subjectTripleFact R A T _ _ _ _ _ _))
 ((subjectIdentityFact R A T) <-- (subjectTripleFact _ _ _ R A T _ _ _))
 ((subjectIdentityFact R A T) <-- (subjectTripleFact _ _ _ _ _ _ R A T))
 (relation needRefTripleFact (component o1 k1 p1 r1 o2 k2 p2 r2 o3 k3 p3 r3))
 (relation needRefFact (component obligation kind premise ref))
 ((needRefFact C O K P R) <-- (needRefTripleFact C O K P R _ _ _ _ _ _ _ _))
 ((needRefFact C O K P R) <-- (needRefTripleFact C _ _ _ _ O K P R _ _ _ _))
 ((needRefFact C O K P R) <-- (needRefTripleFact C _ _ _ _ _ _ _ _ O K P R))
 ((needFact C O K P A T) <-- (needRefFact C O K P R) (subjectIdentityFact R A T))
 (relation receiptRefPairFact (scenario status c1 o1 m1 r1 h1 k1 c2 o2 m2 r2 h2 k2))
 ((receiptFact S C O M A H K T V) <-- (receiptRefPairFact S V C O M R H K _ _ _ _ _ _) (subjectIdentityFact R A T))
 ((receiptFact S C O M A H K T V) <-- (receiptRefPairFact S V _ _ _ _ _ _ C O M R H K) (subjectIdentityFact R A T))
SS
s=s.sub(' (relation methodFact',new+' (relation methodFact');File.write(p,s)
p='.cache/tasks/still-init-recovery/facts.jq';s=File.read(p);start=s.index('(.needs|group_by');stop=s.index('(.methods[]');s[start...stop]=<<~JQ
(.needs|map(select(.kind=="interleaving" or .kind=="induction"))|sort_by(.obligationId)|. as $ns|range(0;length;3) as $i|$ns[$i:$i+3] as $g|
 if ($g|length)==3 then fact("subjectTripleFact";[$g[]|.obligationId,.subjectPath,.subjectScope]) else $g[]|fact("subjectIdentityFact";[.obligationId,.subjectPath,.subjectScope]) end),
(.needs|group_by([.component,(.kind=="interleaving" or .kind=="induction")])[]|. as $ns|range(0;length;3) as $i|$ns[$i:$i+3] as $g|
 if ($g[0].kind=="interleaving" or $g[0].kind=="induction") then
  if ($g|length)==3 then fact("needRefTripleFact";[$g[0].component]+[$g[]|.obligationId,.kind,.premise,.obligationId])
  else $g[]|fact("needRefFact";[.component,.obligationId,.kind,.premise,.obligationId]) end
 else if ($g|length)==3 then fact("needTripleFact";[$g[0].component]+[$g[]|.obligationId,.kind,.premise,.subjectPath,.subjectScope]) else $g[]|fact("needFact";[.component,.obligationId,.kind,.premise,.subjectPath,.subjectScope]) end end),
JQ
File.write(p,s)
p='.cache/tasks/still-init-recovery/render-cases.sh';s=File.read(p).sub('fact("receiptPairFact";[$s,$pair[0][7]]+[$pair[]|.[:7][]])','fact("receiptRefPairFact";[$s,$pair[0][7]]+[$pair[]|[.[0],.[1],.[2],.[1],.[4],.[5]][]])');File.write(p,s)
