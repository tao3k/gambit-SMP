require 'json'
b='.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-model'
m=JSON.parse(File.read(b+'/native-projection.json'))
raise 'wrong authority' unless m['facets'].size==7&&m['obligations'].size==8
clean=->s { s.to_s.gsub('|','/').gsub("\n",' ') }
tables={
 'continuation-obligations'=>['| Obligation | Semantic key | Exclusive owner | Claim / interface | Remaining limit |\n|---+---+---+---+---|\n',m['obligations'].map { |o| [o['id'],o['semanticKey'],o['owner'],o['scope'],o['limitation']] }],
 'continuation-benefits'=>['| Facet | Replaced responsibility | Retirement | Benefit | Added cost | Refutation |\n|---+---+---+---+---+---|\n',m['facets'].map { |f| [f['id'],f['replacement'],f['retirement'],f['benefit'],f['cost'],f['refutation']] }]
}
p='dev/architecture/runtime/control/continuation-segments.org';text=File.read(p)
tables.each do |kind,(header,rows)|
 table=header.gsub('\\n',"\n")+rows.map { |r| '| '+r.map { |s| clean.call(s) }.join(' | ')+" |\n" }.join
 pattern=/(\#\+BEGIN: sysml-view :kind #{kind}[^\n]*\n).*?(\#\+END:)/m
 raise 'missing Org view' unless text.match?(pattern)
 text.sub!(pattern,"\\1"+table+"\\2")
end
File.write(p,text)
p='dev/modeling/verification-responsibilities.org';text=File.read(p)
table="| Owner | Domains | Exclusive responsibility | Excluded responsibility |\n|---+---+---+---|\n"+
 m.fetch('responsibilities').map { |r| '| '+%w[id domains owns excludes].map { |k| clean.call(r[k]) }.join(' | ')+" |\n" }.join
text.sub!(/(\#\+BEGIN: sysml-view :kind verification-responsibilities[^\n]*\n).*?(\#\+END:)/m,"\\1"+table+"\\2")
File.write(p,text)
d="direction: right\nvars: { d2-config: { layout-engine: elk } }\n"
m['facets'].each { |f| d<<f['id']+': '+JSON.generate(f['id']+': '+f['ownerPath'])+"\n" }
m['edges'].each { |e| d<<e['producer']+' -> '+e['consumer']+': '+JSON.generate(e['contract'])+"\n" }
m['obligations'].each do |o|
 name=o['id'].tr('-','_');d<<name+': '+JSON.generate(o['id']+' ['+o['owner']+']: '+o['semanticKey'])+"\n"
end
m['uses'].each { |u| d<<u['facet']+' -> '+u['obligation'].tr('-','_')+": requires\n" }
d<<"policy: \"ASCENT: unique obligation and semantic key; exclusive verification owner\"\n"
d<<"CS_SCHEDULE -> policy: schedules only\nCS_COHERENCE -> policy: payload algebra only\nCS_BRIDGE -> policy: source correspondence OPEN\n"
File.write('dev/architecture/runtime/control/diagrams/continuation-segments.d2',d)
puts JSON.generate(facets:m['facets'].size,obligations:m['obligations'].size,uses:m['uses'].size)
