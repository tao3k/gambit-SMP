require 'json';require 'digest';require 'fileutils';require 'open3'
b=ARGV.fetch(0);out=ARGV.fetch(1);priorDir=ARGV[2];limit=Integer(ARGV.fetch(3,'3'));calls=0
raise 'fresh output required' if File.exist?(out);FileUtils.mkdir_p(out+'/sources')
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json'));raise 'SysML failure' unless JSON.parse(File.read(b+'/native-metadata.json'))['exit']==0
raise 'wrong source scope' unless m['clauses'].size==10&&m['clauses'].all? { |c| c['obligation_owner']=='source'&&%w[CS-BRIDGE CS-WRITERS].include?(c['obligation_id']) }
raise 'wrong native scope' unless m['criteria'].size==6&&m['criteria'].all? { |c| c['acceptance_obligation_id']=='CS-NATIVE' }
old=JSON.parse(File.read('.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-model/native-projection.json'))
cut=JSON.parse(File.read('.cache/tasks/modern-c-frame-contract/cohort/control-refinement-qualified/native-projection.json'))
fpath='.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-separated/receipt.json';f=JSON.parse(File.read(fpath))
raise 'incomplete formal receipt' unless f['rows'].size==13&&f['rows'].all? { |r| r['matched'] }
f['artifacts'].each { |p,h| raise 'formal input drift' unless sha.call(p)==h }
f['rows'].each { |r| raise 'formal log drift' unless sha.call(File.dirname(fpath)+'/'+r['id']+'.log')==r['logSha256'] }
candidate='evidence/research/modern-c-bootstrap/request-custody-source.lock.json'
JSON.parse(File.read(candidate))['files'].each { |p,h| raise 'runtime candidate drift' unless sha.call('vendor/gambit/'+p)==h['candidateSha256'] }
files={};witnesses=m['witnesses'].map do |w|
 p=w['file'];h=sha.call(p);lines=File.readlines(p);a=w['firstLine'];z=w['lastLine']
 raise 'invalid source interval '+w['id'] unless a>0&&z>=a&&z<=lines.size
 dst=out+'/sources/'+w['id']+'.txt';File.write(dst,lines[(a-1)..(z-1)].join)
 raise 'source changed' unless h==sha.call(p)
 files[p]=h;w.merge('sourceSha256'=>h,'excerpt'=>dst,'excerptSha256'=>sha.call(dst))
end
source=Digest::SHA256.hexdigest(JSON.generate(files.sort.to_h.merge('candidateLock'=>sha.call(candidate))))
profile=sha.call(m['profile']);raise 'profile changed' unless profile==JSON.parse(File.read(m['predecessor']))['profileSha256']
File.write(out+'/source-witnesses.json',JSON.pretty_generate({files:files,witnesses:witnesses,sourceDigest:source,scope:'Selected source audit, not complete build closure or source refinement'})+"\n")
os=old['obligations'].map { |o| [o['id'],o['semanticKey'],o['owner'],o['artifact'],sha.call(o['artifact']),o['scope']] }
obs=os.select { |r| %w[quint lean].include?(r[2]) }.map { |r| [r[0],r[2],r[3],r[4],r[5]] }
clauses=m['clauses'].map { |c| [c['id'],c['obligation_id'],Digest::SHA256.hexdigest(JSON.generate(c))] }
criteria=m['criteria'].map { |c| [c['id'],c['acceptance_obligation_id'],Digest::SHA256.hexdigest(JSON.generate(c))] }
prior=priorDir && JSON.parse(File.read(priorDir+'/receipt.json'));results={}
parse=lambda do |text,name|
 i=text.index('("'+name+'" ');raise 'missing relation '+name unless i
 part=text[(i+name.size+4)..];depth=0;quoted=false;escaped=false;past=nil
 part.each_char.with_index do |ch,n|
  if quoted
   if escaped then escaped=false elsif ch=='\\' then escaped=true elsif ch=='"' then quoted=false end
  elsif ch=='"' then quoted=true
  elsif ch=='(' then depth+=1
  elsif ch==')' then depth-=1;if depth==0 then past=n;break end
  end
 end
 raise 'truncated relation '+name unless past
 part[0..past].scan(/"(?:\\.|[^"\\])*"/).map { |x| JSON.parse(x) }
end
data=->name,cols,rows { '(relation '+name+' ('+cols+') ('+rows.map { |r| '('+r.map { |x| JSON.generate(x.to_s) }.join(' ')+')' }.join(' ')+'))' }
names=%w[current wrong-method wrapper-only logical-only eager-snapshot stale-native-profile conflicting-native local-complete]
names.each do |name|
 synthetic=name!='current';pe=[];ne=[]
 if synthetic
  pe=clauses.map { |r| [r[0],'source',source,r[2],'pass'] }
  ne=criteria.map { |r| [r[0],'native',source,profile,r[2],'pass'] }
 end
 if name=='wrong-method'
  pe.each { |r| r[1]='lean' };ne.each { |r| r[1]='source' }
 elsif name=='wrapper-only' then pe.reject! { |r| r[0]=='alias-domain' }
 elsif name=='logical-only' then pe.reject! { |r| r[0]=='relocation-projection' }
 elsif name=='eager-snapshot' then pe.reject! { |r| r[0]=='lazy-fragment-commit' }
 elsif name=='stale-native-profile' then ne.first[3]='different-profile'
 elsif name=='conflicting-native' then x=ne.first.dup;x[-1]='unknown';ne<<x
 end
 outputs=%w[question verificationChecked verificationMissing verificationReady verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch aliasLocated aliasPremiseSupplied aliasPremiseMissing aliasNativeSupplied aliasNativeMissing aliasNativeRejected aliasLocalPremises aliasLocalSmpEvidence aliasModernSmpReady]
 selector='(define-evidence (query) (sources clue factor binding) (outputs '+outputs.join(' ')+") (include clue-selection-schema)\n"+
 File.read('dev/modeling/ascent/obligation-ownership.rules.scm')+File.read('dev/modeling/ascent/frame-alias-contract.rules.scm')
 rows={
 'verificationObligation'=>['id semantic owner artifact digest scope',os],
 'verificationDomain'=>['owner domain',old['responsibilities'].flat_map { |r| r['domains'].split(';').map { |d| [r['id'],d] } }],
 'verificationKeyDomain'=>['semantic domain',os.map { |r| [r[1],r[1].split('/').first] }.uniq],
 'verificationObservation'=>['id owner artifact digest scope',obs],
 'verificationUse'=>['component obligation',old['uses'].map { |u| [u['facet'],u['obligation']] }],
 'verificationCandidate'=>['id',[['frame-alias-contract']]],
 'aliasIdentity'=>['source profile',[[source,profile]]],
 'aliasClause'=>['id obligation digest',clauses],
 'aliasWitness'=>['id file digest',witnesses.map { |w| [w['id'],w['file'],w['sourceSha256']] }],
 'aliasUse'=>['clause witness',m['uses'].map { |u| [u['clause_id'],u['witness_id']] }],
 'aliasPremiseEvidence'=>['id owner source contract outcome',pe],
 'aliasCriterion'=>['id obligation digest',criteria],
 'aliasNativeEvidence'=>['id owner source profile contract outcome',ne],
 'aliasCandidate'=>['id',[['frame-alias-contract']]],
 'aliasGate'=>['id',cut['gates'].map { |g| [g['id']] }],
 'aliasGateEvidence'=>['id source profile outcome',[]]
 }
 rows.each do |key,(cols,values)|
  decl='(relation '+key+' ('+cols+'))';raise 'missing DSL declaration '+key unless selector.include?(decl)
  selector.sub!(decl,data.call(key,cols,values))
 end
 request='((displayBytes 65536) (selector '+JSON.generate(selector+")\n")+'))'
 prev=prior && prior['scenarios'][name];reuse=prev&&prev['requestSha256']==Digest::SHA256.hexdigest(request+"\n")
 break if !reuse&&calls>=limit
 File.write(out+'/'+name+'.request.scm',request+"\n")
 if reuse
  raise 'prior identity drift' unless prior['sourceDigest']==source&&prior['profileSha256']==profile&&prior['projectionSha256']==sha.call(b+'/native-projection.json')
  raise 'prior request drift' unless sha.call(priorDir+'/'+name+'.request.scm')==prev['requestSha256']
  raise 'prior result drift' unless sha.call(priorDir+'/'+name+'.result.scm')==prev['resultSha256']
  stdout=File.read(priorDir+'/'+name+'.result.scm');stderr=File.read(priorDir+'/'+name+'.stderr');success=true
 else
  stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request)
  success=status.success?;calls+=1
 end
 File.write(out+'/'+name+'.result.scm',stdout);File.write(out+'/'+name+'.stderr',stderr)
 raise 'incomplete ASCENT '+name unless success&&stdout.include?('("evaluationComplete" #t)')
 v=outputs.reject { |k| k=='question' }.to_h { |k| [k,parse.call(stdout,k)] }
 expectedSource=%w[current wrong-method].include?(name) ? 0 : (%w[wrapper-only logical-only eager-snapshot].include?(name) ? 9 : 10)
 expectedNative=%w[current wrong-method].include?(name) ? 0 : (%w[stale-native-profile conflicting-native].include?(name) ? 5 : 6)
 raise 'source locating mismatch' unless v['aliasLocated'].size==10
 raise 'incorrect local source match' unless v['aliasPremiseSupplied'].size==expectedSource
 raise 'incorrect local native match' unless v['aliasNativeSupplied'].size==expectedNative
 raise 'missing conflict rejection' if name=='conflicting-native'&&v['aliasNativeRejected'].empty?
 raise 'incorrect source premise admission' unless v['aliasLocalPremises'].empty? == (expectedSource!=10)
 raise 'incorrect local SMP premise admission' unless v['aliasLocalSmpEvidence'].empty? == (expectedSource!=10||expectedNative!=6)
 raise 'local records promoted original obligations' unless v['verificationChecked'].sort==%w[CS-COHERENCE CS-SCHEDULE]&&v['verificationMissing'].size==12&&v['verificationReady'].empty?
 raise 'modern SMP overclaim' unless v['aliasModernSmpReady'].empty?
 raise 'ownership conflict' unless %w[verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch].all? { |k| v[k].empty? }
 results[name]={synthetic:synthetic,relations:v,requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm')}
 results[name][:reusedFrom]=priorDir+'/receipt.json' if reuse
 File.write(out+'/receipt.json',JSON.pretty_generate({projectionSha256:sha.call(b+'/native-projection.json'),sourceDigest:source,profileSha256:profile,sourceWitnessesSha256:sha.call(out+'/source-witnesses.json'),
  formalReceipt:fpath,formalReceiptSha256:sha.call(fpath),formalReexecuted:false,policySha256:sha.call('dev/modeling/ascent/frame-alias-contract.rules.scm'),
  scenarios:results,complete:results.size==names.size,runtimeSourceChanged:false,nativeTestsRun:false,commitAdmitted:false})+"\n")
end
puts JSON.generate(completed:results.size,total:names.size,newCalls:calls,reused:results.size-calls,sourceClauses:10,sourceWitnesses:witnesses.size,formalReexecuted:false,commitAdmitted:false)
