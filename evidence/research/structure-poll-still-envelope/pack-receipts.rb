r='.cache/tasks/structure-poll-still-envelope'
%w[render-cases.sh compose.sh].each do |n|
 p="#{r}/#{n}";s=File.read(p)
 a=s.index('($a[0].needs[] as $q|');b=s.index(' end)',a)
 old=s[a...b]
 replacement=<<~JQ.strip
[$a[0].needs[] as $q|$a[0].methods[]|select(.kind==$q.kind)|. as $m|
 select((["SP-H","SP-I"]|index($q.obligationId))!=null or ($inherited[0]|any(.[];.need==$q.obligationId)))|
 [$q.component,$q.obligationId,$m.method,$q.subjectPath,$q.digest,$m.requiredCheck,$q.subjectScope,"pass"]] as $rs|
 range(0;($rs|length);2) as $j|$rs[$j:$j+2] as $pair|
 if ($pair|length)==2 then fact("receiptPairFact";[$s]+($pair|add)) else $pair[]|fact("receiptFact";[$s]+.) end)
JQ
 # Existing suffix starts with ' end)' closing scenario conditional. Remove
 # old receipt expression including its closing ')' before that suffix.
 s=s[0...a]+replacement+s[b..]
 File.write(p,s)
end
