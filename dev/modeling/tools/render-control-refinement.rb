require 'json'
b=ARGV.fetch(0);m=JSON.parse(File.read(b+'/native-projection.json'))
clean=->s { s.to_s.gsub('|','/').gsub("\n",' ') }
tables={
 'control-refinement-routes'=>[
 %w[Obligation Owner Claim Source-closure Remaining-gap Replacement-cut],
 m['routes'].map { |r| %w[obligation_id obligation_owner claim sourceClosure gap cut].map { |k| r[k] } }],
 'control-refinement-witnesses'=>[
 %w[Route Witness Source Lines Observed-finding],
 m['witnesses'].map { |w| [w['route_id'],w['id'],w['file'],"#{w['firstLine']}-#{w['lastLine']}",w['finding']] }],
 'control-refinement-native'=>[
 %w[Case Target Required-observation Baseline Remaining-work],
 m['cases'].map { |c| %w[id target observation baseline missing].map { |k| c[k] } }],
 'control-refinement-gates'=>[%w[Gate Requirement],m['gates'].map { |g| [g['id'],g['criterion']] }]
}
p='dev/architecture/runtime/control/control-refinement.org';text=File.read(p)
tables.each do |kind,(heads,rows)|
 table='| '+heads.join(' | ')+" |\n|"+(['---']*heads.size).join('+')+"|\n"+
 rows.map { |r| '| '+r.map { |s| clean.call(s) }.join(' | ')+" |\n" }.join
 pattern=/(\#\+BEGIN: sysml-view :kind #{kind}[^\n]*\n).*?(\#\+END:)/m
 raise 'missing Org view '+kind unless text.match?(pattern)
 text.sub!(pattern,"\\1"+table+"\\2")
end
File.write(p,text)
d="direction: down\nvars: { d2-config: { layout-engine: elk } }\n"
m['routes'].each { |r| d<<r['id']+': '+JSON.generate(r['obligation_id']+' / '+r['method']+' / SOURCE MAPPED; CLOSURE OPEN')+"\n" }
%w[bridge writers hooks prompts frames].each { |r| d<<r+" -> source_refinement: requires source correspondence\n" }
d<<"source_refinement: \"Source refinement: authentic issuance / all writers / semantic relation / coordinates\"\n"
d<<"native -> native_acceptance: sole execution owner\nnative_acceptance: \"CS-NATIVE: exact source + profile + case receipts\"\n"
m['cases'].each do |c|
 id='case_'+c['id'].tr('-','_');d<<id+': '+JSON.generate(c['id']+' ['+c['target']+']')+"\n"
 d<<id+" -> native_acceptance: scoped evidence\n"
end
d<<"source_refinement -> ascent: unique source obligations\nnative_acceptance -> ascent: one native obligation\n"
d<<"ascent: \"SysML-driven ASCENT closure; audits and formal endpoints cannot substitute for refinement/native evidence\"\n"
endpoints=JSON.parse(File.read('.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-model/native-projection.json'))
endpoints['obligations'].select { |o| %w[quint lean].include?(o['owner']) }.each do |o|
 id='existing_'+o['owner'];d<<id+': '+JSON.generate(o['id']+' / unchanged '+o['owner']+' evidence reused')+"\n"
 d<<id+" -> ascent: distinct obligation; no duplicate model\n"
 d<<'source_refinement -> '+id+": establish concrete interface premises\n"
end
m['gates'].each { |g| d<<'gate_'+g['id']+': '+JSON.generate(g['id'])+"\nascent -> gate_"+g['id']+": conjunctive gate\n" }
File.write('dev/architecture/runtime/control/diagrams/control-refinement.d2',d)
puts JSON.generate(routes:m['routes'].size,witnesses:m['witnesses'].size,nativeCases:m['cases'].size,gates:m['gates'].size)
