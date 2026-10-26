require 'json'
b=ARGV.fetch(0); out=ARGV.fetch(1)
m=JSON.parse(File.read(b+'/native-projection.json'))
a=JSON.parse(File.read(out+'/receipt.json')); raise 'incomplete controls' unless a['complete']
alias_model=JSON.parse(File.read('.cache/tasks/modern-c-frame-contract/cohort/frame-alias-contract-model/native-projection.json'))
clean=->s { s.to_s.gsub('|','/').gsub("\n",' ') }
tables={
 'smp-factor-conditions'=>[%w[Factor Canonical-owner Mechanism-to-exclude Required-source-condition Required-native-observation Work-and-wait-metric Physical-memory-metric],m['factors'].map { |f| %w[id argument_pressure_responsibleModule mechanism sourceCondition nativeCondition workMetric memoryMetric].map { |k| f[k] } }],
 'smp-factor-evidence'=>[%w[Factor Existing-evidence Evidence-class Existing-bad-history Counterexample-and-boundary Gates],m['factors'].map { |f| [f['id'],f['argument_evidence'],f['argument_evidenceClass'],f['argument_badHistory'],f['argument_refutation']+'; '+f['boundary'],f['argument_gates']] }],
 'smp-factor-dependencies'=>[%w[Dependent Prerequisite Necessary-handoff],m['dependencies'].map { |d| %w[dependent_id prerequisite_id why].map { |k| d[k] } }],
 'smp-factor-criteria'=>[%w[Criterion Relevant-factors Necessary-contract Observation Still-open],alias_model['criteria'].map do |c|
  [c['id'],m['effects'].select { |e| e['criterion_id']==c['id'] }.map { |e| e['factor_id'] }.join('; '),c['necessary'],c['observation'],c['limitation']]
 end],
 'smp-factor-closure'=>[%w[Control Synthetic Supplied-conditions Blocked-factors Locally-covered-factors Original-verification Full-SMP-admission],a['scenarios'].map do |name,s|
  v=s['relations']; [name,s['synthetic'],v['smpSupplied'].size.to_s+'/16',v['smpBlocked'].sort.join('; '),v['smpLocalReady'].sort.join('; '),'2/8 existing obligations; five submission gates open',v['smpModernReady'].empty? ? 'NO' : 'ERROR']
 end]
}
p='dev/refactoring/modern-c/smp-factor-conditions.org'; text=File.read(p)
tables.each do |kind,(heads,rows)|
 table='| '+heads.join(' | ')+" |\n|"+(['---']*heads.size).join('+')+"|\n"+rows.map { |r| '| '+r.map { |s| clean.call(s) }.join(' | ')+" |\n" }.join
 pattern=/(\#\+BEGIN: (?:sysml|ascent)-view :kind #{kind}[^\n]*\n).*?(\#\+END:)/m
 raise 'missing view '+kind unless text.match?(pattern); text.sub!(pattern,"\\1"+table+"\\2")
end
File.write(p,text)
d="direction: right\nvars: { d2-config: { layout-engine: elk } }\n"
m['factors'].each do |f|
 id='factor_'+f['id']; d<<id+': '+JSON.generate(f['id']+' / '+f['argument_pressure_responsibleModule'])+"\n"
 %w[source native].each do |method|
  c='condition_'+f['id']+'_'+method
  d<<c+': '+JSON.generate(method+' condition OPEN: '+f['id'])+"\n"
  d<<c+' -> '+id+": necessary evidence; not a new formal proof\n"
 end
end
m['dependencies'].each { |e| d<<'factor_'+e['prerequisite_id']+' -> factor_'+e['dependent_id']+': '+JSON.generate(e['why'])+"\n" }
alias_model['criteria'].each { |c| d<<'criterion_'+c['id'].tr('-','_')+': '+JSON.generate(c['id']+' / CS-NATIVE OPEN')+"\n" }
m['effects'].each { |e| d<<'factor_'+e['factor_id']+' -> criterion_'+e['criterion_id'].tr('-','_')+": relevance; not causal closure\n" }
d<<"qnt: \"Existing QNT: schedules and permit lifetime\"\nlean: \"Existing Lean: data and mapping algebra\"\nsource: \"Concrete C refinement OPEN\"\nnative: \"Native observation OPEN\"\nascent: \"ASCENT: method + identity + prerequisite closure\"\ngates: \"Five submission gates OPEN\"\nadmission: \"Modern SMP admission: NO\"\n"
d<<"qnt -> ascent: retained evidence; no new run\nlean -> ascent: retained evidence; no new run\nsource -> ascent\nnative -> ascent\ngates -> ascent\nascent -> admission\n"
File.write('dev/refactoring/modern-c/diagrams/smp-factor-conditions.d2',d)
puts JSON.generate(factors:m['factors'].size,conditions:a['needs'].size,dependencies:m['dependencies'].size,criterionLinks:m['effects'].size,controls:a['scenarios'].size,commitAdmitted:false)
