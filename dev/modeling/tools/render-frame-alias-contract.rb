require 'json'
b=ARGV.fetch(0);out=ARGV[1];m=JSON.parse(File.read(b+'/native-projection.json'))
clean=->s { s.to_s.gsub('|','/').gsub("\n",' ') }
tables={
 'frame-alias-witnesses'=>[%w[Witness Source Lines Clause-or-SMP-link Finding],m['witnesses'].map do |w|
  links=m['uses'].select { |u| u['witness_id']==w['id'] }.map { |u| u['clause_id'] }+
   m['criterionUses'].select { |u| u['witness_id']==w['id'] }.map { |u| u['criterion_id'] }
  [w['id'],w['file'],"#{w['firstLine']}-#{w['lastLine']}",links.join('; '),w['finding']]
 end],
 'frame-alias-clauses'=>[%w[Clause Original-obligation Operation Existing-model-premise Real-adapter Failure-custody Source-gap],m['clauses'].map { |c| %w[id obligation_id operation premise realization failure sourceGap].map { |k| c[k] } }],
 'frame-alias-smp'=>[%w[Criterion Existing-native-case Necessary-contract Native-observation Limitation],m['criteria'].map { |c| %w[id acceptance_id necessary observation limitation].map { |k| c[k] } }],
 'frame-alias-benefits'=>[%w[Mechanism Avoided-work Added-work Positive-gain-condition],m['benefits'].map { |c| %w[id avoided added condition].map { |k| c[k] } }]
}
p='dev/architecture/runtime/control/frame-alias-contract.org';text=File.read(p)
tables.each do |kind,(heads,rows)|
 table='| '+heads.join(' | ')+" |\n|"+(['---']*heads.size).join('+')+"|\n"+
 rows.map { |r| '| '+r.map { |s| clean.call(s) }.join(' | ')+" |\n" }.join
 pattern=/(\#\+BEGIN: sysml-view :kind #{kind}[^\n]*\n).*?(\#\+END:)/m
 raise 'missing Org view '+kind unless text.match?(pattern);text.sub!(pattern,"\\1"+table+"\\2")
end
if out
 a=JSON.parse(File.read(out+'/receipt.json'));raise 'incomplete checks' unless a['complete']
 current=a['scenarios']['current']['relations']
 rows=%w[CS-BRIDGE CS-WRITERS].map do |id|
  ids=m['clauses'].select { |c| c['obligation_id']==id }.map { |c| c['id'] }
  [id,(ids&current['aliasLocated']).size.to_s+'/'+ids.size.to_s,(ids&current['aliasPremiseSupplied']).size,'OPEN','CS-NATIVE; not executed']
 end
 rows<<['Modern SMP acceptance','6 necessary criteria',current['aliasNativeSupplied'].size,'OPEN','Existing original obligations and five gates still required']
 table="| Scope | Source coverage / criteria | Supplied implementation or native evidence | Closure | Acceptance owner / dependency |\n|---+---+---+---+---|\n"+
  rows.map { |r| '| '+r.map { |s| clean.call(s) }.join(' | ')+" |\n" }.join
 text.sub!(/(\#\+BEGIN: ascent-view :kind frame-alias-closure[^\n]*\n).*?(\#\+END:)/m,"\\1"+table+"\\2")
end
File.write(p,text)
d="direction: right\nvars: { d2-config: { layout-engine: elk } }\n"
m['clauses'].each do |c|
 id='clause_'+c['id'].tr('-','_');d<<id+': '+JSON.generate(c['id']+' / '+c['operation'])+"\n"
 d<<id+' -> '+c['obligation_id'].tr('-','_')+": source premise; not a duplicate proof\n"
end
m['criteria'].each do |c|
 id='smp_'+c['id'].tr('-','_');d<<id+': '+JSON.generate(c['id']+' / '+c['acceptance_id'])+"\n"
 d<<id+" -> CS_NATIVE: native criterion OPEN\n"
end
m['witnesses'].each { |w| d<<'source_'+w['id'].tr('-','_')+': '+JSON.generate(w['file']+':'+w['firstLine'].to_s+' / '+w['finding'])+"\n" }
m['uses'].each { |u| d<<'source_'+u['witness_id'].tr('-','_')+' -> clause_'+u['clause_id'].tr('-','_')+": located source\n" }
m['criterionUses'].each { |u| d<<'source_'+u['witness_id'].tr('-','_')+' -> smp_'+u['criterion_id'].tr('-','_')+": source gap / required replacement\n" }
d<<"CS_BRIDGE: \"CS-BRIDGE: real issuance/history/relocation refinement OPEN\"\nCS_WRITERS: \"CS-WRITERS: complete admitted writer closure OPEN\"\nCS_NATIVE: \"CS-NATIVE: one execution acceptance owner; no runs here\"\n"
d<<"quint: \"Existing QNT schedule/permit evidence reused\"\nlean: \"Existing Lean image algebra reused\"\n"
d<<"CS_BRIDGE -> quint: establish concrete ticket interface\nCS_BRIDGE -> lean: establish authentic issuance/history premises\n"
d<<"ascent: \"SysML-driven ASCENT: source located vs refined vs native; full-cut gates remain OPEN\"\nCS_BRIDGE -> ascent\nCS_WRITERS -> ascent\nCS_NATIVE -> ascent\nquint -> ascent\nlean -> ascent\n"
File.write('dev/architecture/runtime/control/diagrams/frame-alias-contract.d2',d)
puts JSON.generate(clauses:m['clauses'].size,sourceLinks:m['uses'].size,criteria:m['criteria'].size,witnesses:m['witnesses'].size)
