require 'json'; require 'digest'; require 'fileutils'
b=ARGV.fetch(0); out=ARGV.fetch(1); e='evidence/research/smp-factor-conditions'
raise 'fresh archive required' if File.exist?(e)
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json')); a=JSON.parse(File.read(out+'/receipt.json'))
raise 'incomplete controls' unless a['complete'] && a['scenarios'].size==5
raise 'model/policy drift' unless a['projectionSha256']==sha.call(b+'/native-projection.json') && a['policySha256']==sha.call('dev/modeling/ascent/smp-factor-conditions.rules.scm')
raise 'wrong actual closure' unless a['scenarios']['current']['relations']['smpBlocked'].size==8 && a['scenarios']['current']['relations']['smpSupplied'].empty?
raise 'overclaim' unless a['scenarios'].values.all? { |s| s['relations']['smpModernReady'].empty? }
raise 'adapter/formal drift' unless sha.call(a['adapterReceipt'])==a['adapterReceiptSha256'] && sha.call(a['formalReceipt'])==a['formalReceiptSha256']
alias_validation='evidence/research/frame-alias-contract/validation.json'
alias_archive=JSON.parse(File.read(alias_validation))
raise 'inconsistent alias identity' unless alias_archive['sourceDigest']==a['sourceDigest'] && alias_archive['profileSha256']==a['profileSha256']
audit=JSON.parse(File.read(File.dirname(a['adapterReceipt'])+'/source-witnesses.json'))
audit['files'].each { |p,h| raise 'current source drift' unless sha.call(p)==h }
paths=File.readlines(b+'/native-model-inputs.txt',chomp:true)
paths+=Dir.glob(b+'/**/*').select { |p| File.file?(p) }
[out,'.cache/tasks/modern-c-frame-contract/cohort/smp-factor-conditions-controls'].each { |dir| paths+=Dir.glob(dir+'/**/*').select { |p| File.file?(p) } }
paths+=m['factors'].flat_map { |f| f['argument_evidence'].split(';').map(&:strip) }
paths+=%w[
 dev/refactoring/modern-c/smp-factor-conditions.org
 dev/refactoring/modern-c/causal-architecture.org
 dev/refactoring/modern-c/index.org
 dev/refactoring/modern-c/diagrams/smp-factor-conditions.d2
 dev/refactoring/modern-c/diagrams/smp-factor-conditions.svg
 dev/modeling/ascent/smp-factor-conditions.rules.scm
 dev/modeling/ascent/obligation-ownership.rules.scm
 dev/modeling/tools/project-smp-factor-conditions.rb
 dev/modeling/tools/check-smp-factor-conditions.rb
 dev/modeling/tools/render-smp-factor-conditions.rb
 dev/modeling/tools/retain-smp-factor-conditions.rb
 evidence/research/modern-c-bootstrap/request-custody-source.lock.json
 evidence/fixtures/gerbil-bazel-build-profile/profile.json
]
paths+=[m['gateLedger'],m['priorEvidence'],alias_validation,a['adapterReceipt'],a['formalReceipt']]
raise 'missing retained input '+paths.reject { |p| File.file?(p) }.join(', ') unless paths.all? { |p| File.file?(p) }
FileUtils.mkdir_p(e+'/records')
records=paths.uniq.sort.to_h do |p|
 h=sha.call(p); dst=e+'/records/'+p.gsub('/','__'); FileUtils.cp(p,dst)
 raise 'copy drift' unless sha.call(p)==h && sha.call(dst)==h
 [p,{path:dst,sha256:h}]
end
File.write(e+'/validation.json',JSON.pretty_generate({
 authority:'GambitSmpFactorConditions',scope:'Eight canonical pressure arguments refined into necessary source/native conditions and dependency-driven evidence admission; not new state-machine or algebra proofs',
 sourceDigest:a['sourceDigest'],sourceScope:a['sourceScope'],profileSha256:a['profileSha256'],
 factors:8,conditions:16,dependencies:6,criterionLinks:14,scenarios:a['scenarios'],
 sourceRefinementAdmitted:false,modernSmpAdmitted:false,runtimeSourceChanged:false,nativeTestsRun:false,commitAdmitted:false,
 formal:{reexecuted:false,receipt:a['formalReceipt'],sha256:a['formalReceiptSha256'],quintObligations:1,leanObligations:1},
 priorCausalEvidence:m['priorEvidence'],aliasEvidence:alias_validation,
 interpretation:['Gambit already has SMP; maturity is not a binary thread-count claim',
  'Eight pressures and twelve acceptance duties are different classifications',
  'Missing root prerequisite propagates to worker and lifecycle conditions',
  'All synthetic local conditions cannot close original source/native obligations or five submission gates',
  'Work counts, wait time, scaling and physical peak remain distinct; no measured speedup claimed'],records:records
})+"\n")
puts JSON.generate(records:records.size,factors:8,conditions:16,controls:5,formalReexecuted:false,commitAdmitted:false)
