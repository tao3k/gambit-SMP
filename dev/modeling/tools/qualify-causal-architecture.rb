# Qualifies only the causal join policy and retained scoped observations.
# Hypothetical controls below never become observed C proofs.
require 'json'; require 'digest'; require 'fileutils'; require 'open3'
sha=->p { Digest::SHA256.file(p).hexdigest }
base='.cache/tasks/modern-c-frame-contract/cohort/causal-architecture-model'
out=ARGV.fetch(0)
raise 'fresh output required' if File.exist?(out)
FileUtils.mkdir_p(out)
modelPath=base+'/native-projection.json'
m=JSON.parse(File.read(modelPath))
raise 'wrong authority' unless m['arguments'].size==8 && !m['runtimeAdmitted'] && !m['commitAdmitted']
raise 'native SysML error' unless JSON.parse(File.read(base+'/native-metadata.json'))['exit']==0
sys='dev/refactoring/modern-c/models/sysml/causal-architecture.sysml'
rules='dev/modeling/ascent/causal-architecture.rules.scm'
profile='evidence/fixtures/gerbil-bazel-build-profile/profile.json'
lock=m.fetch('sourceLock'); identity=[sha.call(lock),sha.call(profile)]
JSON.parse(File.read(lock)).fetch('files').each do |p,h|
  raise 'source drift '+p unless sha.call('vendor/gambit/'+p)==h.fetch('candidateSha256')
end
m['arguments'].each do |a|
  a['evidence'].split(';').map(&:strip).each { |p| raise 'missing evidence '+p unless File.file?(p) }
end
formalPath='.cache/tasks/modern-c-frame-contract/cohort/request-formal-retained/receipt.json'
formal=JSON.parse(File.read(formalPath))
raise 'formal result' unless formal['rows'].size==44 && formal['rows'].all? { |r| r['matched'] }
formal['artifacts'].each { |p,h| raise 'formal artifact drift '+p unless sha.call(p)==h }
formal['rows'].each { |r| raise 'formal log drift' unless sha.call(File.dirname(formalPath)+'/'+r['id']+'.log')==r['logSha256'] }
widePath='.cache/tasks/modern-c-frame-contract/cohort/reused-wide/receipt.json'
wide=JSON.parse(File.read(widePath))
raise 'wide identity' unless wide['sourceLockSha256']==identity[0] && wide['profileSha256']==identity[1] && wide['inputsStable']
raise 'changed wide limits' if wide['bootstrapRerun'] || wide['heapIncrease']
raise 'wide inventory' unless wide['runtimeInventoryEntries']==2505
raise 'wide completion' unless wide['rows'].count { |r| r['oracleMatched'] && r['naturalShutdown'] && r['exit']==0 && !r['timeout'] && r['limitSeconds']==30 }==2
wide['inputs'].each { |p,h| raise 'wide input drift '+p unless sha.call(p)==h }
controlsPath='.cache/tasks/modern-c-frame-contract/cohort/request-custody-managed-controls/receipt.json'
requestsPath='.cache/tasks/modern-c-frame-contract/cohort/request-custody-concurrent/receipt.json'
[controlsPath,requestsPath].each do |p|
  j=JSON.parse(File.read(p))
  raise 'native control source' unless j['sourceLockSha256']==identity[0] && j['inputsStable']
  raise 'native control failure' if j['rows'].any? { |r| r['oracleMatched']==false }
end
raise 'unknown actor witness' unless JSON.parse(File.read(controlsPath))['rows'].any? { |r| r['id']=='unknown-multi' && r['oracleMatched'] }
campaignPath='.cache/tasks/modern-c-frame-contract/runs/bazel-request-custody/receipt.json'
campaign=JSON.parse(File.read(campaignPath))
raise 'historical failure drift' unless campaign['outcome']=='DENY' && campaign['timeout'] && campaign['inputs'][lock]==identity[0] && campaign['inputs'][profile]==identity[1]
needs=[]; observed=[]
m['arguments'].each do |a|
  %w[c-refinement progress retirement net-benefit].each do |method|
    needs << [a['id'],method,sys,sha.call(sys),method+':'+a['id']]
  end
end
%w[work copy ffi frames].each do |id|
  n=[id,'finite-model-and-law',formalPath,sha.call(formalPath),'conditional:'+id]
  needs<<n;observed<<n+identity
end
{'exit'=>controlsPath,'copy'=>widePath,'ffi'=>requestsPath,'frames'=>widePath}.each do |id,p|
  n=[id,'native-scope',p,sha.call(p),'scoped:'+id]
  needs<<n;observed<<n+identity
end
# Canonical compact output relation rows contain only string-valued columns.
relation=lambda do |text,name|
  start=text.index('("'+name+'" '); raise 'missing relation '+name unless start
  offset=start+name.size+4; fragment=text[offset..]; depth=0; quoted=false; escaped=false; past=nil
  fragment.each_char.with_index do |ch,i|
    if quoted
      if escaped then escaped=false elsif ch=='\\' then escaped=true elsif ch=='"' then quoted=false end
    elsif ch=='"' then quoted=true
    elsif ch=='(' then depth+=1
    elsif ch==')' then depth-=1; if depth==0 then past=i;break end
    end
  end
  raise 'incomplete relation '+name unless past
  fragment[0..past].scan(/"(?:\\.|[^"\\])*"/).map { |s| JSON.parse(s) }
end
data=lambda do |name,columns,rows|
  '(relation '+name+' ('+columns+') ('+rows.map { |row| '('+row.map { |v| JSON.generate(v) }.join(' ')+')' }.join(' ')+"))\n"
end
scenarios={}
expected={'current'=>8,'stale-source'=>0,'native-as-c-proof'=>8,'all-but-cost'=>32,'all-with-native-failure'=>40}
expected.each do |scenario,count|
  observations=observed.map(&:dup)
  observations.each { |r| r[-2]='0'*64 } if scenario=='stale-source'
  if scenario=='native-as-c-proof'
    # A relabeled native observation has the wrong artifact/digest/scope for C.
    observations += observed.select { |r| r[1]=='native-scope' }.map { |r| [r[0],'c-refinement',*r[2..]] }
  end
  if %w[all-but-cost all-with-native-failure].include?(scenario)
    needs.each do |n|
      next if observed.any? { |r| r[0,5]==n }
      next if scenario=='all-but-cost' && n[1]=='net-benefit'
      observations << n+identity # hypothetical negative-control evidence only
    end
  end
  failures=scenario=='all-but-cost' ? [] : [[*identity,sha.call(campaignPath)]]
  selector="(define-evidence (query) (sources clue factor binding) (outputs question causalMatched causalGap causalReady causalGateBlocked) (include clue-selection-schema)\n"+File.read(rules)
  rows={
    'causalArgument'=>['component',m['arguments'].map { |a| [a['id']] }],
    'causalIdentity'=>['source profile',[identity]],
    'causalNeed'=>['component method artifact digest scope',needs],
    'causalObservation'=>['component method artifact digest scope source profile',observations],
    'causalDependency'=>['dependent prerequisite',m['dependencies'].map { |e| [e['dependent'],e['prerequisite']] }],
    'causalGateNeed'=>['gate component',m['arguments'].flat_map { |a| a['gates'].split(';').map { |g| [g,a['id']] } }],
    'causalFailure'=>['source profile receipt',failures]
  }
  rows.each do |name,(columns,values)|
    declaration='(relation '+name+' ('+columns+'))'
    raise 'missing DSL declaration' unless selector.include?(declaration)
    selector.sub!(declaration,data.call(name,columns,values).strip)
  end
  selector+=")\n"
  request='((displayBytes 65536) (selector '+JSON.generate(selector)+'))'
  File.write(out+'/'+scenario+'.request.scm',request+"\n")
  stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request)
  File.write(out+'/'+scenario+'.result.scm',stdout);File.write(out+'/'+scenario+'.stderr',stderr)
  raise 'ASCENT incomplete '+scenario unless status.success? && stdout.include?('("evaluationComplete" #t)')
  matches=relation.call(stdout,'causalMatched');gaps=relation.call(stdout,'causalGap');ready=relation.call(stdout,'causalReady')
  raise 'bad columns' unless matches.size.even? && gaps.size.even?
  raise 'unexpected join '+scenario unless matches.size/2==count && gaps.size/2==40-count && ready.empty?
  scenarios[scenario]={matched:matches.size/2,gaps:gaps.size/2,ready:ready,hypotheticalControl:scenario.start_with?('all-'),
    requestSha256:sha.call(out+'/'+scenario+'.request.scm'),resultSha256:sha.call(out+'/'+scenario+'.result.scm')}
  File.write(out+'/receipt.json',JSON.pretty_generate({sourceLockSha256:identity[0],profileSha256:identity[1],
    sysmlSha256:sha.call(sys),projectionSha256:sha.call(modelPath),dslSha256:sha.call(rules),needs:needs.size,
    scenarios:scenarios,nativeFailureRetained:true,runtimeAdmitted:false,commitAdmitted:false})+"\n")
end
puts JSON.generate(scenarios:scenarios.size,needs:needs.size,currentMatched:scenarios['current'][:matched],currentGaps:scenarios['current'][:gaps],commitAdmitted:false)
