require 'json'; require 'digest'; require 'fileutils'; require 'open3'
b=ARGV.fetch(0); out=ARGV.fetch(1); prior_dir=ARGV[2]; limit=Integer(ARGV.fetch(3,'3')); calls=0
raise 'fresh output required' if File.exist?(out)
FileUtils.mkdir_p(out)
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json'))
raise 'SysML failed' unless JSON.parse(File.read(b+'/native-metadata.json'))['exit']==0
raise 'canonical factor mismatch' unless m['factors'].size==8 && m['factors'].all? { |f| f['id']==f['argument_id'] }
raise 'dependency mismatch' unless m['dependencies'].size==6 && m['effects'].size==14
ap='.cache/tasks/modern-c-frame-contract/cohort/frame-alias-contract-complete/receipt.json'
a=JSON.parse(File.read(ap)); raise 'incomplete adapter audit' unless a['complete']
raise 'adapter policy drift' unless sha.call('dev/modeling/ascent/frame-alias-contract.rules.scm')==a['policySha256']
audit_path=File.dirname(ap)+'/source-witnesses.json'
raise 'audit identity drift' unless sha.call(audit_path)==a['sourceWitnessesSha256']
audit=JSON.parse(File.read(audit_path)); audit['files'].each { |p,h| raise 'source drift' unless sha.call(p)==h }
candidate='evidence/research/modern-c-bootstrap/request-custody-source.lock.json'
JSON.parse(File.read(candidate))['files'].each { |p,h| raise 'candidate drift' unless sha.call('vendor/gambit/'+p)==h['candidateSha256'] }
profile_path='evidence/fixtures/gerbil-bazel-build-profile/profile.json'
profile=sha.call(profile_path); raise 'profile drift' unless profile==a['profileSha256']
source=a['sourceDigest']
fp=a['formalReceipt']; formal=JSON.parse(File.read(fp))
raise 'formal receipt drift' unless sha.call(fp)==a['formalReceiptSha256'] && formal['rows'].size==13 && formal['rows'].all? { |r| r['matched'] }
formal['artifacts'].each { |p,h| raise 'formal artifact drift' unless sha.call(p)==h }
formal['rows'].each { |r| raise 'formal log drift' unless sha.call(File.dirname(fp)+'/'+r['id']+'.log')==r['logSha256'] }
old=JSON.parse(File.read('.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-model/native-projection.json'))
cut=JSON.parse(File.read('.cache/tasks/modern-c-frame-contract/cohort/control-refinement-qualified/native-projection.json'))
obligations=old['obligations'].map { |o| [o['id'],o['semanticKey'],o['owner'],o['artifact'],sha.call(o['artifact']),o['scope']] }
observations=obligations.select { |r| %w[quint lean].include?(r[2]) }.map { |r| [r[0],r[2],r[3],r[4],r[5]] }
needs=m['factors'].flat_map do |f|
 [['source','sourceCondition'],['native','nativeCondition']].map do |method,field|
  [f['id'],f['id']+'/'+method,method,Digest::SHA256.hexdigest(JSON.generate([f['id'],method,f[field],f['boundary']]))]
 end
end
parse=lambda do |text,name|
 i=text.index('("'+name+'" '); raise 'missing relation '+name unless i
 part=text[(i+name.size+4)..]; depth=0; quoted=false; escaped=false; past=nil
 part.each_char.with_index do |ch,n|
  if quoted
   if escaped then escaped=false elsif ch=='\\' then escaped=true elsif ch=='"' then quoted=false end
  elsif ch=='"' then quoted=true
  elsif ch=='(' then depth+=1
  elsif ch==')' then depth-=1; if depth==0 then past=n; break end
  end
 end
 raise 'truncated relation '+name unless past
 part[0..past].scan(/"(?:\\.|[^"\\])*"/).map { |x| JSON.parse(x) }
end
data=->name,cols,rows { '(relation '+name+' ('+cols+') ('+rows.map { |r| '('+r.map { |x| JSON.generate(x.to_s) }.join(' ')+')' }.join(' ')+'))' }
prior=prior_dir && JSON.parse(File.read(prior_dir+'/receipt.json')); results={}
names=%w[current alias-only native-only missing-root-prerequisite local-complete]
names.each do |name|
 evidence=name=='current' ? [] : needs.map { |r| [r[1],r[2],source,profile,r[3],'pass'] }
 case name
 when 'alias-only' then evidence.select! { |r| r[0]=='frames/source' }
 when 'native-only' then evidence.select! { |r| r[1]=='native' }
 when 'missing-root-prerequisite' then evidence.reject! { |r| r[0]=='ffi/source' }
 end
 outputs=%w[question verificationChecked verificationMissing verificationReady verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch smpSupplied smpRejected smpLocalGap smpGap smpBlocked smpLocalReady smpGateMissing smpModernReady]
 selector='(define-evidence (query) (sources clue factor binding) (outputs '+outputs.join(' ')+") (include clue-selection-schema)\n"+
 File.read('dev/modeling/ascent/obligation-ownership.rules.scm')+File.read('dev/modeling/ascent/smp-factor-conditions.rules.scm')
 rows={
  'verificationObligation'=>['id semantic owner artifact digest scope',obligations],
  'verificationDomain'=>['owner domain',old['responsibilities'].flat_map { |r| r['domains'].split(';').map { |d| [r['id'],d] } }],
  'verificationKeyDomain'=>['semantic domain',obligations.map { |r| [r[1],r[1].split('/').first] }.uniq],
  'verificationObservation'=>['id owner artifact digest scope',observations],
  'verificationUse'=>['component obligation',old['uses'].map { |u| [u['facet'],u['obligation']] }],
  'verificationCandidate'=>['id',[['smp-factor-conditions']]],
  'smpIdentity'=>['source profile',[[source,profile]]],
  'smpFactor'=>['id',m['factors'].map { |f| [f['id']] }],
  'smpNeed'=>['factor condition method contract',needs],
  'smpDependency'=>['dependent prerequisite',m['dependencies'].map { |d| [d['dependent_id'],d['prerequisite_id']] }],
  'smpRecord'=>['condition method source profile contract outcome',evidence],
  'smpCandidate'=>['id',[['smp-factor-conditions']]],
  'smpGate'=>['id',cut['gates'].map { |g| [g['id']] }],
  'smpGateEvidence'=>['id source profile outcome',[]]
 }
 rows.each do |key,(cols,values)|
  decl='(relation '+key+' ('+cols+'))'; raise 'missing declaration '+key unless selector.include?(decl)
  selector.sub!(decl,data.call(key,cols,values))
 end
 request='((displayBytes 65536) (selector '+JSON.generate(selector+")\n")+'))'+"\n"
 prev=prior && prior['scenarios'][name]; reuse=prev && prev['requestSha256']==Digest::SHA256.hexdigest(request)
 break if !reuse && calls>=limit
 File.write(out+'/'+name+'.request.scm',request)
 if reuse
  raise 'prior identity drift' unless prior['sourceDigest']==source && prior['profileSha256']==profile && prior['projectionSha256']==sha.call(b+'/native-projection.json')
  raise 'prior control drift' unless sha.call(prior_dir+'/'+name+'.request.scm')==prev['requestSha256'] && sha.call(prior_dir+'/'+name+'.result.scm')==prev['resultSha256']
  stdout=File.read(prior_dir+'/'+name+'.result.scm'); stderr=File.read(prior_dir+'/'+name+'.stderr'); success=true
 else
  stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request.chomp)
  success=status.success?; calls+=1
 end
 File.write(out+'/'+name+'.result.scm',stdout); File.write(out+'/'+name+'.stderr',stderr)
 raise 'incomplete ASCENT '+name unless success && stdout.include?('("evaluationComplete" #t)')
 v=outputs.reject { |k| k=='question' }.to_h { |k| [k,parse.call(stdout,k)] }
 expected={'current'=>0,'alias-only'=>1,'native-only'=>8,'missing-root-prerequisite'=>15,'local-complete'=>16}.fetch(name)
 raise 'supplied mismatch' unless v['smpSupplied'].size==expected && v['smpRejected'].empty?
 blocked=name=='local-complete' ? [] : (name=='missing-root-prerequisite' ? %w[exit ffi work] : m['factors'].map { |f| f['id'] })
 raise 'dependency propagation mismatch' unless v['smpBlocked'].sort==blocked.sort
 raise 'local closure mismatch' unless v['smpLocalReady'].size==8-blocked.size
 raise 'root failure not propagated' if name=='missing-root-prerequisite' && !%w[exit work ffi].all? { |id| v['smpGap'].each_slice(2).include?([id,'ffi/source']) }
 raise 'original evidence promoted' unless v['verificationChecked'].sort==%w[CS-COHERENCE CS-SCHEDULE] && v['verificationMissing'].size==12 && v['verificationReady'].empty?
 raise 'ownership conflict' unless %w[verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch].all? { |k| v[k].empty? }
 raise 'global overclaim' unless v['smpModernReady'].empty? && v['smpGateMissing'].size==5
 results[name]={synthetic:name!='current',relations:v,requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm')}
 results[name][:reusedFrom]=prior_dir+'/receipt.json' if reuse
 File.write(out+'/receipt.json',JSON.pretty_generate({
  projectionSha256:sha.call(b+'/native-projection.json'),policySha256:sha.call('dev/modeling/ascent/smp-factor-conditions.rules.scm'),
  sourceDigest:source,sourceScope:'Selected current source audit and candidate lock; not complete build closure',profileSha256:profile,
  adapterReceipt:ap,adapterReceiptSha256:sha.call(ap),formalReceipt:fp,formalReceiptSha256:sha.call(fp),formalReexecuted:false,
  needs:needs,scenarios:results,complete:results.size==names.size,runtimeSourceChanged:false,nativeTestsRun:false,commitAdmitted:false
 })+"\n")
end
puts JSON.generate(completed:results.size,total:names.size,newCalls:calls,reused:results.size-calls,factors:8,conditions:16,dependencies:6,formalReexecuted:false,commitAdmitted:false)
