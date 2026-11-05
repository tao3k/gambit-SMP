require 'json';require 'digest';require 'fileutils';require 'open3'
e='evidence/research/continuation-segments';b='.cache/tasks/modern-c-frame-contract/cohort'
dest=e+'/records';manifest=e+'/validation.json'
raise 'fresh publication required' if File.exist?(manifest)||File.exist?(dest)
sha=->p { Digest::SHA256.file(p).hexdigest }
model=b+'/continuation-segments-model';formal=b+'/continuation-segments-separated';admit=b+'/continuation-segments-catalog-ownership'
m=JSON.parse(File.read(model+'/native-projection.json'));f=JSON.parse(File.read(formal+'/receipt.json'));a=JSON.parse(File.read(admit+'/receipt.json'))
raise 'qualification incomplete' unless a['scenarios'].size==5&&a['scenarios'].values.all? { |s| s['ready'].empty? }
raise 'ownership partition' unless a['quintObligations']==1&&a['leanObligations']==1&&a['remainingSourceNativeObligations']==6
raise 'source lock drift' unless sha.call(e+'/source.lock.json')==a['sourceLockSha256']
raise 'native model drift' unless sha.call(model+'/native-projection.json')==a['sysmlProjectionSha256']
raise 'policy drift' unless sha.call('dev/modeling/ascent/obligation-ownership.rules.scm')==a['policySha256']
raise 'formal drift' unless sha.call(formal+'/receipt.json')==a['formalReceiptSha256']&&f['rows'].size==13&&f['rows'].all? { |r| r['matched'] }
f['artifacts'].each { |p,h| raise 'model changed' unless sha.call(p)==h }
lock=JSON.parse(File.read(e+'/source.lock.json'))
lock['files'].each { |_,r| raise 'reference source changed' unless sha.call(r['source'])==r['sha256']&&sha.call(r['path'])==r['sha256'] }
candidate=JSON.parse(File.read(lock['projects']['gambit']['candidateLock']))
candidate['files'].each { |p,h| raise 'runtime changed' unless sha.call('vendor/gambit/'+p)==h['candidateSha256'] }
versions={}
%w[sysml quint lean d2].each do |tool|
  o,err,status=Open3.capture3(tool,'--version');raise 'tool identity' unless status.success?
  File.write(model+'/'+tool+'-version.log',o+err);versions[tool]=(o+err).strip
end
paths=File.readlines(model+'/native-model-inputs.txt',chomp:true)
paths+=Dir.glob(model+'/**/*').select { |p| File.file?(p) }
%w[continuation-segments-formal continuation-segments-formal-qualified continuation-segments-separated continuation-segments-ownership continuation-segments-catalog-ownership].each do |name|
  paths+=Dir.glob(b+'/'+name+'/*').select { |p| File.file?(p) }
end
paths+=Dir.glob(b+'/control-references/*').select { |p| File.file?(p)&&p.match?(/\.(?:rb|json|log|qnt|lean)\z/) }
paths+=f['artifacts'].keys
paths+=%w[
 dev/architecture/runtime/control/continuation-segments.org
 dev/architecture/runtime/control/index.org
 dev/architecture/runtime/control/models/quint/index.org
 dev/architecture/runtime/control/models/lean/index.org
 dev/architecture/runtime/control/diagrams/continuation-segments.d2
 dev/architecture/runtime/control/diagrams/continuation-segments.svg
 dev/refactoring/modern-c/index.org
 dev/refactoring/modern-c/causal-architecture.org
 dev/modeling/index.org
 dev/modeling/verification-responsibilities.org
 dev/modeling/ascent/obligation-ownership.rules.scm
 dev/modeling/tools/pin-continuation-references.rb
 dev/modeling/tools/project-continuation-segments.rb
 dev/modeling/tools/render-continuation-segments.rb
 dev/modeling/tools/check-continuation-segments.rb
 dev/modeling/tools/qualify-continuation-segments.rb
 dev/modeling/tools/retain-continuation-segments.rb
 evidence/research/continuation-segments/source.lock.json
 evidence/research/modern-c-bootstrap/architecture-causal-validation.json
]
FileUtils.mkdir_p(dest)
records=paths.uniq.sort.to_h do |p|
  raise 'missing publication input '+p unless File.file?(p)
  h=sha.call(p);target=dest+'/'+p.gsub('/','__');FileUtils.cp(p,target)
  raise 'publication changed' unless sha.call(p)==h&&sha.call(target)==h
  [p,{path:target,sha256:h}]
end
File.write(manifest,JSON.pretty_generate({
 scope:'Pinned Scheme-control research, exclusive verification obligations and conditional models; no runtime implementation or native acceptance',
 authority:'GambitContinuationSegments; GambitVerificationResponsibilities',sourceLockSha256:sha.call(e+'/source.lock.json'),
 sourceFiles:lock['files'].size,papers:lock['papers'].count { |p| p['pdf'] },facets:m['facets'].size,obligations:8,
 partition:{quint:{obligations:['CS-SCHEDULE'],purpose:'schedules and root/permit lifetimes only'},
   lean:{obligations:['CS-COHERENCE'],purpose:'unbounded issued-view algebra only'},
   open:%w[CS-BRIDGE CS-WRITERS CS-HOOKS CS-PROMPTS CS-NATIVE CS-FRAMES]},
 formal:{checks:13,quintHistories:13,samples:1000,maxSteps:60,seed:23,conditionalLeanLaws:6,sorryAx:false},
 admission:a['scenarios'],tools:versions,
 sourceFindings:['Gambit already supports stack-backed capture and GC materialization',
   'Gambit frame and denv reflection forbid an unconditional immutable-image assumption',
   'Chez representation, Scheme wind implementation and GC generator form a joint control/root contract',
   'Guile partial composition checks rewindability and relocates dynamic prompts; BDW stack marking is not a moving-root proof',
   'Version matching requires authentic issuance and complete writer history, not just integer equality'],
 history:['Initial Quint local binding scope error retained',
   'Initial Lean reserved parameter name retained',
   'Earlier payload assertions removed from Quint to establish exclusive responsibilities; their source and receipts remain historical',
   'Unchanged Lean artifact/logs reused while the separated Quint protocol was rechecked',
   'Shared responsibility catalogue evaluated by native SysML; all five final ASCENT controls qualified anew'],
 llm:'default working environment; no extra component, service or approval stage',
 historicalStudiesAutomaticallyReadmitted:false,runtimeSourceChanged:false,nativeTestsRun:false,
 runtimeAdmitted:false,commitAdmitted:false,records:records
})+"\n")
puts JSON.generate(records:records.size,sourceFiles:lock['files'].size,papers:3,quintObligations:1,leanObligations:1,remaining:6,commitAdmitted:false)
