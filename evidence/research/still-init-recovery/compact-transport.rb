p='dev/modeling/ascent/assurance-planner.ss';s=File.read(p);a=s.index(';; Lossless subject transport');b=s.index(' (relation methodFact',a)
s[a...b]=<<~SS
 ;; Lossless formal-receipt transport. Native obligations must be globally unique.
 ;; Exact subject strings are already present in needFact; qualification is unchanged.
 (relation subjectIdentityFact (ref artifact scope))
 ((subjectIdentityFact O A T) <-- (needFact _ O _ _ A T))
 (relation receiptRefPairFact (scenario status c1 o1 m1 r1 h1 k1 c2 o2 m2 r2 h2 k2))
 ((receiptFact S C O M A H K T V) <-- (receiptRefPairFact S V C O M R H K _ _ _ _ _ _) (subjectIdentityFact R A T))
 ((receiptFact S C O M A H K T V) <-- (receiptRefPairFact S V _ _ _ _ _ _ C O M R H K) (subjectIdentityFact R A T))
 ;; Five edges share only their dependent owner; every obligation/prerequisite survives.
 (relation dependencyOwnerQuintFact (component o1 p1 q1 o2 p2 q2 o3 p3 q3 o4 p4 q4 o5 p5 q5))
 ((dependencyFact C O P Q) <-- (dependencyOwnerQuintFact C O P Q _ _ _ _ _ _ _ _ _ _ _ _))
 ((dependencyFact C O P Q) <-- (dependencyOwnerQuintFact C _ _ _ O P Q _ _ _ _ _ _ _ _ _))
 ((dependencyFact C O P Q) <-- (dependencyOwnerQuintFact C _ _ _ _ _ _ O P Q _ _ _ _ _ _))
 ((dependencyFact C O P Q) <-- (dependencyOwnerQuintFact C _ _ _ _ _ _ _ _ _ O P Q _ _ _))
 ((dependencyFact C O P Q) <-- (dependencyOwnerQuintFact C _ _ _ _ _ _ _ _ _ _ _ _ O P Q))
SS
File.write(p,s)
p='.cache/tasks/still-init-recovery/facts.jq';s=File.read('.cache/tasks/still-init-safepoint/facts.jq');a=s.index('(.edgeGroups[]');b=s.index('(.contracts[]',a);s[a...b]=<<~JQ
(.dependencies|group_by(.component)[]|. as $es|range(0;length;5) as $i|$es[$i:$i+5] as $g|
 if ($g|length)==5 then fact("dependencyOwnerQuintFact";[$g[0].component]+[$g[]|.obligation,.prerequisiteComponent,.prerequisite])
 else $g[]|fact("dependencyFact";[.component,.obligation,.prerequisiteComponent,.prerequisite]) end),
JQ
File.write(p,s)
# Elide exactly the old edge transport declarations/expansions on empty inputs,
# in addition to the seven metadata-only forms. New owner transport is retained.
p='.cache/tasks/still-init-recovery/specialize-inference.el';s=File.read(p).sub("'(sourceRouteFact sourceRoutePairFact contractFact)","'(sourceRouteFact sourceRoutePairFact contractFact dependencyTripleFact dependencyQuintFact)").sub('(when drop (push form removed)) drop)',"(let ((old-edge (and (listp form) (listp (car form)) (eq (caar form) 'dependencyFact) (seq-some (lambda (x) (and (listp x) (memq (car x) '(dependencyTripleFact dependencyQuintFact)))) (cddr form)))))\n                    (when (or drop old-edge) (push form removed)) (or drop old-edge)))").sub('(length removed) 7','(length removed) 17').sub('(removedForms . 7)','(removedForms . 17)').sub('Exactly seven metadata-only forms elided; qualification policy retained.','Seven metadata and ten empty legacy-edge forms elided; qualification policy retained.');File.write(p,s)
p='.cache/tasks/still-init-recovery/compose.sh';s=File.read(p).sub("jq -e '.exit==0'", "jq -e '.exit==0'");s=s.sub('bundle=$(openssl',"jq -e '(.refinementNeeds|length)==74' \"$r/native-projection.json\" >/dev/null\nbundle=$(openssl");File.write(p,s)
p='.cache/tasks/still-init-recovery/cuts.jq';s=File.read(p).sub('["gc-work","host-roots","continuation","gc-synchronous-publication"]','["gc-work","host-roots","continuation","gc-synchronous-publication","resource-exit"]');File.write(p,s)
