require 'json';require 'digest';require 'fileutils';require 'open3'
root=Dir.pwd;sha=->p{Digest::SHA256.file(p).hexdigest};quote=->x{JSON.generate(x)}
fact=->n,*a{"(fact (#{n} #{a.map{|v|quote.call(v)}.join(' ')}))\n"}
b='.cache/tasks/modern-c-frame-contract/cohort/copy-custody-model'
e='evidence/research/modern-c-bootstrap';sys='dev/refactoring/modern-c/models/sysml/copy-custody.sysml'
m=JSON.parse(File.read(b+'/native-projection.json'));lock=m.fetch('sourceLock');profile='evidence/fixtures/gerbil-bazel-build-profile/profile.json';identity=[sha.call(lock),sha.call(profile)]
JSON.parse(File.read(lock)).fetch('files').each{|p,h|raise 'source drift '+p unless sha.call('vendor/gambit/'+p)==h.fetch('candidateSha256')}
formal=ARGV.fetch(0);f=JSON.parse(File.read(formal));raise 'formal failure' unless f.fetch('rows').all?{|r|r.fetch('matched')}
f.fetch('artifacts').each{|p,h|raise 'formal drift '+p unless sha.call(p)==h}
run='.cache/tasks/modern-c-frame-contract/runs/bazel-request-custody/run'
campaignPath=File.dirname(run)+'/receipt.json';campaign=JSON.parse(File.read(campaignPath))
raise 'campaign failure not retained' unless campaign['outcome']=='DENY'&&campaign['timeout']&&campaign['parentReaped']&&campaign['processGroupQuiescent']
raise 'campaign identity' unless campaign['inputs'][lock]==identity[0]&&campaign['inputs'][profile]==identity[1]

snapshot=e+'/request-custody-model-input.sysml';raise 'snapshot drift' unless campaign['inputs'][sys]==sha.call(snapshot)
fields=%w[id cSource invariant nativeMethod nativeClass nativeScope]
contracts=->p{File.read(p).scan(/  part \w+:Contract \{.*?^  \}/m).map{|s|fields.to_h{|n|[n,s[/attribute :>> #{n}="([^"]*)";/,1]]}}}
raise 'native scope drift' unless contracts.call(sys)==contracts.call(snapshot)
executed=JSON.parse(File.read(File.dirname(run)+'/request.json')).fetch('recipe')
raise 'executed recipe drift' unless campaign['inputs'][executed]==sha.call(executed)
raise 'bootstrap artifact not executed' unless m.fetch('contracts').find{|c|c['id']=='COPY-FROZEN'}.fetch('nativeArtifact')==executed
artifactCorrection={scope:'Quint builtin select renamed selectRequest after preserved parse failure; C behavior and native scope/artifact match frozen campaign snapshot'}
control='.cache/tasks/modern-c-frame-contract/cohort/request-custody-managed-controls/receipt.json';ctrl=JSON.parse(File.read(control))
handoff='.cache/tasks/modern-c-frame-contract/cohort/request-custody-handoffs/receipt.json';handoffs=JSON.parse(File.read(handoff))
requests='.cache/tasks/modern-c-frame-contract/cohort/request-custody-concurrent/receipt.json';req=JSON.parse(File.read(requests))
[ctrl,handoffs,req].each{|r|raise 'control identity' unless r['sourceLockSha256']==identity[0]&&r['inputsStable']}
raise 'request acceptance' unless req['rows'].select{|r|r.key?('oracleMatched')}.size==3&&req['rows'].select{|r|r.key?('oracleMatched')}.all?{|r|r['oracleMatched']}
isolationArtifact=m['contracts'].find{|c|c['id']=='ABORT-ISOLATION'}.fetch('nativeArtifact')
raise 'isolation caller not observed' unless ctrl.fetch('inputSnapshot')[isolationArtifact]==sha.call(isolationArtifact)
# Prior failures remain tied to their original locks. They are not relabeled
# current-source failures. Synthetic veto facts below are only negative controls.
native={}
boot=JSON.parse(File.read(run+'/bootstrap/step-receipt.json'))
native['native-bootstrap']=run+'/bootstrap/step-receipt.json' if boot['fullTwoPassBootstrapEstablished']&&boot['phaseCounts'].values.all?{|n|n==2}
native['native-fault']=control if ctrl['adapterCalibrated']&&ctrl['rows'].any?{|r|r['id']=='unknown-multi'&&r['oracleMatched']}
native['native-startup']=control if ctrl['allControlOraclesMatched']&&handoffs['rows'].select{|r|%w[publication reuse].include?(r['id'])}.size==2&&handoffs['rows'].select{|r|%w[publication reuse].include?(r['id'])}.all?{|r|r['oracleMatched']}
native['native-request']=requests
native['native-collision']=handoff if handoffs['rows'].any?{|r|r['id']=='collision'&&r['oracleMatched']}
# Artifact, scope and declaration tokens are interned as exact tuples, not
# merged by spelling. The catalog itself is part of the bound model bundle.
catalog={};intern=->kind,value{key=JSON.generate([kind,value]);catalog[key]||="i#{catalog.size}"}
needs=[];routes=[];tokens=[]
m['contracts'].each do |c|
  [['quint',c.fetch('quintArtifact'),c['quint'],'finite-model'],['lean',c.fetch('leanArtifact'),c['lean'],'conditional-proof'],['source-refinement',sys,c['sourceScope'],'source-simulation'],[c['nativeMethod'],c['nativeArtifact'],c['nativeScope'],c['nativeClass']]].each do |method,path,scope,klass|
    raise 'unexecuted formal artifact '+path if %w[quint lean].include?(method)&&f['artifacts'][path]!=sha.call(path)
    needs<<[c['id'],method,intern.call('artifact',path),sha.call(path),intern.call('scope',scope),klass]
  end
  %w[quint lean].each do |method|
    path=c.fetch(method+'Artifact');c[method].split(';').map(&:strip).each do |route|
      token=route.split('.').last;id=intern.call('declaration',[method,path,token]);routes<<[c['id'],method,id]
      kind=method=='quint' ? '(?:action|pure def|pure val|val|run)' : 'theorem'
      tokens<<[method,id] if File.read(path).match?(/\b#{kind}\s+#{Regexp.escape(token)}\b/)
    end
  end
  declared=nil
  c['cSource'].split(';').map(&:strip).each do |route|
    words=route.split
    declared=words.shift if words.first&.match?(/\.(?:c|h|h\.in)\z/)
    token=words.fetch(0)
    locations=JSON.parse(File.read(lock)).fetch('files').keys.select do |p|
      p.match?(/\.(?:c|h|h\.in)\z/)&&File.read('vendor/gambit/'+p).match?(/\b#{Regexp.escape(token)}\b/)
    end
    id=intern.call('declaration',['c-structure',declared,token,locations.sort]);routes<<[c['id'],'c-structure',id]
    tokens<<['c-structure',id] unless locations.empty?
  end
end
catalogPath=b+'/evidence-catalog.json';File.write(catalogPath,JSON.pretty_generate(catalog)+"\n")
rules='dev/modeling/ascent/copy-custody.rules.scm'
inputs=File.readlines(b+'/native-model-inputs.txt',chomp:true)+f['artifacts'].keys+[catalogPath]+%w[dev/modeling/tools/project-copy-custody.rb dev/modeling/tools/render-copy-custody.rb dev/modeling/tools/check-resize-sources.rb dev/modeling/tools/qualify-resize-sources.rb]
bindings={'target-model-bundle-sha256'=>Digest::SHA256.hexdigest(inputs.uniq.sort.map{|p|p+"\0"+sha.call(p)}.join("\n")),'native-output-sha256'=>sha.call(b+'/native-metadata.json'),'planner-dsl-sha256'=>sha.call(rules)}
claim='modern-c-resize-source-custody:'+Digest::SHA256.hexdigest(JSON.generate([identity,bindings]));history=e+'/request-custody-history/'+claim.split(':').last;FileUtils.mkdir_p(history)
register="(define-evidence (register) (sources binding) (outputs clue factor) (relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))\n"+fact.call('clue',claim,claim,'support',sys)
bindings.each{|k,v|register<<fact.call('factor',claim,k,v)};register<<")\n"
o,err,s=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','submit',"((selector #{quote.call(register)}) (constructor \"register\"))");File.write(history+'/register.log',o+err);raise 'registration' unless s.success?||err.include?('already retained')
# The native catalog admits at most 256 rules. Qualify the lexical C-anchor
# inventory separately, then require its exact-source receipt in every final
# evidence join. This does not replace any C simulation requirement.
anchorResults={}
%w[current missing-anchor].each do |scenario|
 part="(define-evidence (query) (sources clue factor binding) (outputs question copyRouteMissing anchorReady) (include clue-selection-schema)\n"+File.read(rules)+fact.call('copyStudyFact',claim)+fact.call('copyIdentityFact',*identity)
 part<<"(relation anchorReady (source profile))\n((anchorReady L P) <-- (copyBound _) (copyIdentityFact L P) (not (copyRouteMissing _ _ _)))\n"
 routes.uniq.select{|_,method,_|method=='c-structure'}.each{|r|part<<fact.call('copyRouteFact',*r)}
 cTokens=tokens.uniq.select{|method,_|method=='c-structure'}
 cTokens.each_with_index{|r,i|part<<fact.call('copyTokenFact',*r) unless scenario=='missing-anchor'&&i==0}
 part<<")\n";request="((displayBytes 32768) (selector #{quote.call(part)}) (bindings (#{bindings.map{|k,v|"(#{quote.call(k)} #{quote.call(v)})"}.join(' ')})))\n"
 prefix=history+'/c-anchors-'+scenario;File.write(prefix+'.request.scm',request)
 o,err,s=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request);File.write(prefix+'.result.scm',o);File.write(prefix+'.stderr',err)
 raise 'C anchor evaluation '+scenario unless s.success?&&o.include?('("evaluationComplete" #t)')
 ready=!o.include?('("anchorReady" ())');raise 'C anchor gate '+scenario unless ready==(scenario=='current')
 anchorResults[scenario]={ready:ready,requestSha256:Digest::SHA256.hexdigest(request),resultSha256:Digest::SHA256.hexdigest(o),result:prefix+'.result.scm'}
end
anchorEvidence=anchorResults.fetch('current').fetch(:result)
base="(define-evidence (query) (sources clue factor binding) (outputs question copyRequired copyChecked copyMissing copyRouteMissing copyDepends copyDependencyGap copyAllReady copyNativeFailure) (include clue-selection-schema)\n"+File.read(rules)+fact.call('copyStudyFact',claim)+fact.call('copyIdentityFact',*identity)
base<<fact.call('copyNativeFailureFact',*identity,'COPY-SOURCE','aggregate-600-second-budget',campaignPath,sha.call(campaignPath))
# Real failed rows keep current source/profile identity when present.
[control,handoff,requests].each do |path|
 JSON.parse(File.read(path))['rows'].select{|r|r['oracleMatched']==false}.each{|r|base<<fact.call('copyNativeFailureFact',*identity,'RESIZE-SOURCES',r.fetch('id'),path,sha.call(path))}
end
needs.each{|r|base<<fact.call('copyNeedFact',*r)};routes.uniq.reject{|_,method,_|method=='c-structure'}.each{|r|base<<fact.call('copyRouteFact',*r)}
m['edges'].each{|r|base<<fact.call('copyEdgeFact',r['consumer'],r['producer'])}
results={}
%w[current stale-source wrong-artifact diagnostic-as-whole missing-law wrong-scope wrong-model-token missing-c-anchor all-scopes-with-failure].each do |scenario|
  part=base.dup;ids=identity.dup;ids[0]='0'*64 if scenario=='stale-source';part<<fact.call('copyCandidateFact',scenario,*ids)
  part<<fact.call('copyAnchorEvidence',*identity,sha.call(anchorEvidence)) unless scenario=='missing-c-anchor'
  tokens.uniq.each do |method,id|
    next if method=='c-structure'
    tuple=JSON.parse(catalog.key(id))[1]
    next if scenario=='missing-law'&&tuple.last=='copyBoundNeedsUniqueSources'
    next if scenario=='wrong-model-token'&&tuple==['quint','dev/refactoring/modern-c/models/quint/copy_custody.qnt','freeze']
    part<<fact.call('copyTokenFact',method,id)
  end
  needs.each do |component,method,path,digest,scope,klass|
    observation=%w[quint lean].include?(method) ? formal : native[method]
    observation=requests if scenario=='diagnostic-as-whole'&&method=='native-whole'
    observation=sys if scenario=='all-scopes-with-failure'&&(%w[source-refinement native-round-plan native-whole].include?(method))
    next unless observation
    observed= scenario=='diagnostic-as-whole'&&method=='native-whole' ? 'native-diagnostic' : klass
    observedDigest=scenario=='wrong-artifact'&&component=='COPY-FROZEN'&&method=='quint' ? '0'*64 : digest
    observedScope=scenario=='wrong-scope'&&component=='RESIZE-SOURCES'&&method=='native-request' ? 'wrong-scope' : scope
    part<<fact.call('copyObservedFact',scenario,*ids,component,method,path,observedDigest,observedScope,observed,sha.call(observation),'pass')
  end
  # Standard ASCENT `facts` batches keep every parsed list below the native
  # 256-item bound. Do not widen or bypass the reader's bounds.
  lines=part.lines;facts,body=lines.partition{|line|line.start_with?('(fact (')}
  # Need rows are immutable catalog data, not forty zero-body Datalog rules.
  # Native relation initial-row syntax preserves the same six-column tuples.
  needRows,facts=facts.partition{|line|line.start_with?('(fact (copyNeedFact ')}
  rowText=needRows.map{|line|'('+line.delete_prefix('(fact (copyNeedFact ').sub(/\)\)\n\z/,')')}.join("\n")
  declaration="(relation copyNeedFact (component method artifact digest scope class))"
  bodyText=body.join.sub(declaration,"(relation copyNeedFact (component method artifact digest scope class) (\n#{rowText}\n))")
  part=bodyText+facts.each_slice(128).map{|group|"(facts\n"+group.map{|line|line.delete_prefix('(fact ').sub(/\)\n\z/,"\n")}.join+")\n"}.join+")\n"
  request="((displayBytes 65536) (selector #{quote.call(part)}) (bindings (#{bindings.map{|k,v|"(#{quote.call(k)} #{quote.call(v)})"}.join(' ')})))\n"
  prefix=history+'/'+scenario;File.write(prefix+'.request.scm',request)
  o,err,s=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request);File.write(prefix+'.result.scm',o);File.write(prefix+'.stderr',err)
  raise 'evaluation '+scenario unless s.success?&&o.include?('("evaluationComplete" #t)')&&o.include?('("copyAllReady" ())')
  section=o[/\("copyChecked" (.*?) \("copyDependencyGap"/m,1];raise 'missing checked output' unless section
  checked=section.scan(/\("#{scenario}" "[^"]+" "[^"]+"\)/).size
  # 44 obligations; eleven C simulations and the pre-flip C planner stay open.
  expected={'current'=>28,'stale-source'=>0,'wrong-artifact'=>27,'diagnostic-as-whole'=>28,'missing-law'=>26,'wrong-scope'=>27,'wrong-model-token'=>27,'missing-c-anchor'=>0,'all-scopes-with-failure'=>44}.fetch(scenario)
  raise "cardinality #{scenario}: #{checked} expected #{expected}" unless checked==expected
  results[scenario]={checked:checked,allReady:false,requestSha256:Digest::SHA256.hexdigest(request),resultSha256:Digest::SHA256.hexdigest(o)}
  File.write(e+'/request-custody-admission.json',JSON.pretty_generate({scope:'artifact-qualified structural routes and independently scoped evidence; no C simulation or full-round allocator admission',claim:claim,bindings:bindings,sourceLockSha256:identity[0],artifactCorrection:artifactCorrection,catalogSha256:sha.call(catalogPath),components:m['contracts'].size,needs:needs.size,routes:routes.uniq.size,tokens:tokens.uniq.size,cAnchorControls:anchorResults,native:native.transform_values{|p|{path:p,sha256:sha.call(p)}},scenarios:results,runtimeAdmitted:false,commitAdmitted:false})+"\n")
end
puts JSON.generate(components:m['contracts'].size,needs:needs.size,scenarios:results.size,commitAdmitted:false)
