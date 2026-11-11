def fact($r;$row): " (fact ("+$r+" "+($row|map(@json)|join(" "))+"))";
.needs|map({subjectPath,digest})|unique|. as $items|
range(0;length;7) as $i|$items[$i:$i+7] as $group|
($group+[range(0;7-($group|length))|$group[0]]) as $padded|
fact("availableSubjectSeptFact";[$s]+[$padded[]|.subjectPath,.digest])
