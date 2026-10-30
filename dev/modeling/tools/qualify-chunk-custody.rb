require 'json';require 'digest';require 'open3';require 'fileutils'
b='.cache/tasks/modern-c-frame-contract/cohort/copy-custody-model';e='evidence/research/modern-c-bootstrap';sha=->p{Digest::SHA256.file(p).hexdigest};q=->x{JSON.generate(x)};fact=->name,*xs{"(fact (#{name} #{xs.map{|x|q.call(x)}.join(' ')}))\n"}
m=JSON.parse(File.read(b+'/native-projection.json'));lock=m['sourceLock'];identity=[sha.call(lock),sha.call('evidence/fixtures/gerbil-bazel-build-profile/profile.json')]
JSON.parse(File.read(lock))['files'].each{|p,h|raise 'source drift '+p unless sha.call('vendor/gambit/'+p)==h['candidateSha256']}
rules='dev/modeling/ascent/copy-custody.rules.scm';sys='dev/refactoring/modern-c/models/sysml/copy-custody.sysml';qnt='dev/refactoring/modern-c/models/quint/copy_custody.qnt';lean='dev/refactoring/modern-c/models/lean/CopyCustody.lean';formal='.cache/tasks/modern-c-frame-contract/cohort/chunk-transport-formal/receipt.json'
f=JSON.parse(File.read(formal));raise 'formal drift' unless f['quintSha256']==sha.call(qnt)&&f['leanSha256']==sha.call(lean)&&f['rows'].size==11&&f['rows'].all?{|r|r['matched']};raise 'axiom audit' if File.read(File.dirname(formal)+'/axioms.log').include?('sorryAx')
inputs=File.readlines(b+'/native-model-inputs.txt',chomp:true)+[qnt,lean];bindings={'target-model-bundle-sha256'=>Digest::SHA256.hexdigest(inputs.uniq.sort.map{|p|p+"\0"+sha.call(p)}.join("\n")),'native-output-sha256'=>sha.call(b+'/native-metadata.json'),'planner-dsl-sha256'=>sha.call(rules)}
claim='modern-c-copy-custody:'+Digest::SHA256.hexdigest(JSON.generate([bindings,identity]));history=e+'/copy-custody-history/'+claim.split(':').last;FileUtils.mkdir_p(history)
reg="(define-evidence (register) (sources binding) (outputs clue factor) (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))\n"+fact.call('clue',claim,claim,'support',sys);bindings.each{|k,v|reg<<fact.call('factor',claim,k,v)};reg<<")\n"
o,err,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','submit',"((selector #{q.call(reg)}) (constructor \"register\"))");File.write(history+'/register.log',o+err);raise 'register' unless status.success?||err.include?('already retained')
base="(define-evidence (query) (sources clue factor binding) (outputs question copyRequired copyChecked copyMissing copyRouteMissing copyDepends copyDependencyGap copyAllReady copyOpenQuestion) (include clue-selection-schema)\n"+File.read(rules)+fact.call('copyStudyFact',claim)+fact.call('copyIdentityFact',*identity)
needs=[];routes=[];tokens=[]
m['contracts'].each do |c|
 base<<fact.call('copyOpenFact',c['id'],c['open'])
 [['quint',qnt,c['quint'],'finite-model'],['lean',lean,c['lean'],'conditional-proof'],['source-refinement',sys,c['open'],'source-simulation'],[c['nativeMethod'],c['nativeArtifact'],c['nativeScope'],c['nativeClass']]].each do |method,path,scope,klass|
  needs<<[c['id'],method,path,sha.call(path),scope,klass];base<<fact.call('copyNeedFact',*needs[-1])
 end
 %w[quint lean].each do |method|
  c[method].split(';').map(&:strip).each do |t|
   token=t.split('.').last;routes<<[c['id'],method,token];base<<fact.call('copyRouteFact',*routes[-1]);content=File.read(method=='quint' ? qnt : lean)
   tokens<<[method,token] if content.match?(/\b#{method=='quint' ? 'action' : 'theorem'}\s+#{Regexp.escape(token)}\b/)
  end
 end
end
c_source=%w[mem setup os_thread].map{|u|File.read('vendor/gambit/lib/'+u+'.c')}.join("\n")
m['contracts'].each do |c|
 c['cSource'].split(';').each do |r|
  t=r.strip.split.last;routes<<[c['id'],'c-structure',t];base<<fact.call('copyRouteFact',*routes[-1])
  tokens<<['c-structure',t] if c_source.match?(/\b#{Regexp.escape(t)}\b/)
 end
end
m['edges'].each{|x|base<<fact.call('copyEdgeFact',x['consumer'],x['producer'])}

run='.cache/tasks/modern-c-frame-contract/runs/bazel-chunk-custody/run'
campaign=JSON.parse(File.read(run+'/receipt.json'))
raise 'native campaign' unless campaign['outcome']=='PASS'&&campaign['inputsStable']
raise 'native source/profile' unless campaign['inputs'][File.expand_path(lock)]==identity[0]&&campaign['inputs'][File.expand_path('evidence/fixtures/gerbil-bazel-build-profile/profile.json')]==identity[1]
snapshot=e+'/chunk-custody-model-input.sysml'
raise 'native model snapshot drift' unless campaign['inputs'][File.expand_path(sys)]==sha.call(snapshot)
contract_blocks=->p{File.read(p).scan(/  part \w+:Contract \{.*?^  \}/m)}
raise 'native contract scope changed' unless contract_blocks.call(snapshot)==contract_blocks.call(sys)
boot=JSON.parse(File.read(run+'/bootstrap/step-receipt.json'))
whole=JSON.parse(File.read(run+'/wide-map-host/step-receipt.json'))
population=JSON.parse(File.read(run+'/wide-map-host/run-executable.process.json'))['environment']['GAMBIT_SMP_EXPECTED_PROCESSORS']
control='.cache/tasks/modern-c-frame-contract/cohort/chunk-custody-controls/receipt.json'
ctrl=JSON.parse(File.read(control))
raise 'control identity' unless ctrl['sourceLockSha256']==identity[0]&&ctrl['inputsStable']&&ctrl['multiFixtureSha256']==sha.call('evidence/research/modern-c-bootstrap/scan-ownership-isolation-multi.scm')
native={}
native['native-bootstrap']=run+'/bootstrap/step-receipt.json' if boot['fullTwoPassBootstrapEstablished']&&boot['phaseCounts'].values.all?{|n|n==2}
native['native-whole']=run+'/wide-map-host/step-receipt.json' if whole['outcome']=='PASS'&&population=='11'
native['native-fault']=control if ctrl['adapterCalibrated']&&ctrl['allControlOraclesMatched']&&ctrl['rows'].any?{|r|r['id']=='unknown-multi'&&r['oracleMatched']}
raise 'missing native observation' unless native.size==3

results={}
%w[current stale-source wrong-artifact diagnostic-as-whole missing-law wrong-scope].each do |scenario|
 part=base.dup;ids=identity.dup;ids[0]='0'*64 if scenario=='stale-source';part<<fact.call('copyCandidateFact',scenario,*ids)
 tokens.uniq.each{|method,t|part<<fact.call('copyTokenFact',method,t) unless scenario=='missing-law'&&t=='copyBoundNeedsUniqueSources'}
 needs.each do |component,method,path,digest,scope,klass|
  evidence=%w[quint lean].include?(method) ? formal : native[method]
  next unless evidence
  observed=scenario=='diagnostic-as-whole'&&method=='native-whole' ? 'native-diagnostic' : klass
  observed_digest=(scenario=='wrong-artifact'&&component=='COPY-FROZEN'&&method=='quint') ? '0'*64 : digest
  observed_scope=scenario=='wrong-scope'&&component=='CHUNK-TRANSPORT'&&method=='native-whole' ? 'fixture-only' : scope
  part<<fact.call('copyObservedFact',scenario,*ids,component,method,path,observed_digest,observed_scope,observed,sha.call(evidence),'pass')
 end
 part<<")\n";request="((displayBytes 32768) (selector #{q.call(part)}) (bindings (#{bindings.map{|k,v|"(#{q.call(k)} #{q.call(v)})"}.join(' ')})))\n";File.write(history+'/'+scenario+'.request.scm',request)
 o,err,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request);File.write(history+'/'+scenario+'.result.scm',o);File.write(history+'/'+scenario+'.stderr',err);raise 'evaluation '+scenario unless status.success?&&o.include?('("evaluationComplete" #t)');raise 'false closure' unless o.include?('("copyAllReady" ())')
 raise 'missing law missed' if scenario=='missing-law'&&!o.include?('"copyBoundNeedsUniqueSources"')
 section=o[/\("copyChecked" (.*?) \("copyDependencyGap"/m,1]
 raise 'checked relation absent' unless section
 checked=section.scan(/\("#{scenario}" "[^"]+" "(?:quint|lean|native-whole|native-bootstrap|native-fault|source-refinement)"\)/).size
 expected={'current'=>12,'stale-source'=>0,'wrong-artifact'=>11,'diagnostic-as-whole'=>10,'missing-law'=>10,'wrong-scope'=>11}.fetch(scenario)
 raise "wrong checked cardinality #{scenario}: #{checked}" unless checked==expected
 results[scenario]={checked:checked,resultSha256:Digest::SHA256.hexdigest(o),allReady:false};File.write('dev/modeling/ascent/copy-custody.request.scm',request) if scenario=='current'
end
File.write(e+'/chunk-custody-admission.json',JSON.pretty_generate({scope:'structural routes, finite/conditional laws and scoped native observations; all four source-simulation obligations remain missing',claim:claim,bindings:bindings,sourceLockSha256:identity[0],nativeEvidence:native.transform_values{|p|{path:p,sha256:sha.call(p)}},components:m['contracts'].size,needs:needs.size,routes:routes.size,tokens:tokens.uniq.size,scenarios:results,runtimeAdmitted:false,commitAdmitted:false})+"\n")
puts JSON.generate(components:m['contracts'].size,needs:needs.size,routes:routes.size,structuralTokens:tokens.uniq.size,scenarios:results.size,commitAdmitted:false)
