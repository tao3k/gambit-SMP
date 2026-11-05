def fact($r;$row): " (fact ("+$r+" "+($row|map(@json)|join(" "))+"))";
.needs|map({subjectPath,digest})|unique|. as $items|
range(0;length;7) as $i|$items[$i:$i+7] as $group|
if ($group|length)==7 then fact("availableSubjectSeptFact";[$s]+[$group[]|.subjectPath,.digest])
else $group[]|fact("availableSubjectFact";[$s,.subjectPath,.digest]) end
