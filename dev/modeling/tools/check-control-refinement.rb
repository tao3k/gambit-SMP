# Source byte witnesses and actual ASCENT admission controls, not a C proof.
require 'json';require 'digest';require 'fileutils';require 'open3'
b=ARGV.fetch(0);out=ARGV.fetch(1);priorDir=ARGV[2];maxCalls=Integer(ARGV.fetch(3,'3'));calls=0
prior=priorDir && JSON.parse(File.read(priorDir+'/receipt.json'))
raise 'fresh output required' if File.exist?(out);FileUtils.mkdir_p(out+'/witnesses')
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json'))
raise 'native SysML failure' unless JSON.parse(File.read(b+'/native-metadata.json'))['exit']==0
base='.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-model/native-projection.json'
old=JSON.parse(File.read(base))
raise 'partition changed' unless m['routes'].count { |r| r['obligation_owner']=='source' }==5 && m['routes'].count { |r| r['obligation_owner']=='native' }==1
raise 'wrong target' unless m['target']=='full-control'
pre=JSON.parse(File.read(m['predecessor']))
pre['records'].each { |_,r| raise 'prior retained record drift' unless sha.call(r['path'])==r['sha256'] }
formalPath='.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-separated/receipt.json'
formal=JSON.parse(File.read(formalPath))
raise 'formal evidence incomplete' unless formal['rows'].size==13 && formal['rows'].all? { |r| r['matched'] }
formal['artifacts'].each { |p,h| raise 'formal artifact drift' unless sha.call(p)==h }
formal['rows'].each { |r| raise 'formal log drift' unless sha.call(File.dirname(formalPath)+'/'+r['id']+'.log')==r['logSha256'] }
candidatePath='evidence/research/modern-c-bootstrap/request-custody-source.lock.json'
candidate=JSON.parse(File.read(candidatePath))
candidate['files'].each { |p,h| raise 'runtime candidate drift' unless sha.call('vendor/gambit/'+p)==h['candidateSha256'] }
profile=sha.call(m['profile'])
baseline=JSON.parse(File.read('evidence/research/modern-c-bootstrap/architecture-causal-validation.json'))
raise 'profile drift' unless profile==baseline['profileSha256']
files={};witnesses=[]
m['witnesses'].each do |w|
 p=w['file'];hash=sha.call(p);lines=File.readlines(p)
 first=w['firstLine'];last=w['lastLine']
 raise 'invalid witness interval '+w['id'] unless first.is_a?(Integer)&&last.is_a?(Integer)&&first>0&&last>=first&&last<=lines.size
 snippet=lines[(first-1)..(last-1)].join;target=out+'/witnesses/'+w['id']+'.txt'
 File.write(target,snippet);raise 'source changed while reading' unless hash==sha.call(p)
 files[p]=hash;witnesses<<w.merge('sourceSha256'=>hash,'excerpt'=>target,'excerptSha256'=>sha.call(target))
end
source=Digest::SHA256.hexdigest(JSON.generate({files:files.sort.to_h,candidateLock:sha.call(candidatePath)}))
File.write(out+'/source-witnesses.json',JSON.pretty_generate({sourceDigest:source,files:files,witnesses:witnesses,meaning:'Reviewed source locations; no semantic refinement or native result'})+"\n")
obligations=old['obligations'].map { |o| [o['id'],o['semanticKey'],o['owner'],o['artifact'],sha.call(o['artifact']),o['scope']] }
formalObs=obligations.select { |r| %w[quint lean].include?(r[2]) }.map { |r| [r[0],r[2],r[3],r[4],r[5]] }
sourceObs=obligations.select { |r| r[2]=='source' }.map { |r| [r[0],r[2],r[3],r[4],r[5]] }
caseRows=m['cases'].map { |c| [c['id'],c['target'],Digest::SHA256.hexdigest(JSON.generate(c))] }
required=caseRows.select { |r| r[1]==m['target'] }
raise 'wrong native suite' unless required.size==7 && m['cases'].all? { |c| c['obligation_id']=='CS-NATIVE' }
data=->name,columns,rows { '(relation '+name+' ('+columns+') ('+rows.map { |r| '('+r.map { |x| JSON.generate(x.to_s) }.join(' ')+')' }.join(' ')+'))' }
relation=lambda do |text,name|
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
 part[0..past].scan(/"(?:\\.|[^"\\])*"/).map { |s| JSON.parse(s) }
end
results={}
names=%w[current audit-is-not-proof native-is-not-source stale-native-source stale-native-profile wrong-case-recipe native-failure missing-gate complete-routing-control]
names.each do |name|
 hypothetical=!%w[current audit-is-not-proof native-is-not-source].include?(name)
 observed=formalObs.map(&:dup);native=[];gates=[]
 if hypothetical
  # Synthetic positive premises test routing only, never publish proof evidence.
  observed+=sourceObs.map(&:dup)
  native=required.map { |r| [r[0],source,profile,r[2],'pass'] }
  gates=m['gates'].map { |g| [g['id'],source,profile,'pass'] }
 end
 if name=='audit-is-not-proof'
  observed+=sourceObs.map { |r| x=r.dup;x[1]='audit';x }
 elsif name=='native-is-not-source'
  x=sourceObs.find { |r| r[0]=='CS-BRIDGE' }.dup;x[1]='native';observed<<x
 elsif name=='stale-native-source' then native.first[1]='different-source'
 elsif name=='stale-native-profile' then native.first[2]='different-profile'
 elsif name=='wrong-case-recipe' then native.first[3]='different-recipe'
 elsif name=='native-failure' then native.first[4]='unknown'
 elsif name=='missing-gate' then gates.reject! { |r| r[0]=='questions' }
 end
 outputs=%w[question verificationChecked verificationMissing verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch verificationReady controlMapped controlSourceClosed controlOpen controlCasePassed controlCaseMissing controlGateMissing controlCommitCandidate]
 selector='(define-evidence (query) (sources clue factor binding) (outputs '+outputs.join(' ')+") (include clue-selection-schema)\n"+
 File.read('dev/modeling/ascent/obligation-ownership.rules.scm')+File.read('dev/modeling/ascent/control-refinement.rules.scm')
 rows={
 'verificationObligation'=>['id semantic owner artifact digest scope',obligations],
 'verificationDomain'=>['owner domain',old['responsibilities'].flat_map { |r| r['domains'].split(';').map { |d| [r['id'],d] } }],
 'verificationKeyDomain'=>['semantic domain',obligations.map { |r| [r[1],r[1].split('/').first] }.uniq],
 'verificationObservation'=>['id owner artifact digest scope',observed],
 'verificationUse'=>['component obligation',old['uses'].map { |u| [u['facet'],u['obligation']] }],
 'verificationCandidate'=>['id',[['control-refinement']]],
 'controlRoute'=>['route obligation owner',m['routes'].map { |r| [r['id'],r['obligation_id'],r['obligation_owner']] }],
 'controlWitness'=>['route witness file digest first last',witnesses.map { |w| [w['route_id'],w['id'],w['file'],w['sourceSha256'],w['firstLine'],w['lastLine']] }],
 'controlIdentity'=>['source profile target',[[source,profile,m['target']]]],
 'controlCase'=>['id target digest',caseRows],
 'controlCaseResult'=>['id source profile digest outcome',native],
 'controlGate'=>['id requirement',m['gates'].map { |g| [g['id'],g['criterion']] }],
 'controlGateEvidence'=>['id source profile outcome',gates]
 }
 rows.each do |key,(cols,values)|
  decl='(relation '+key+' ('+cols+'))';raise 'missing declaration '+key unless selector.include?(decl)
  selector.sub!(decl,data.call(key,cols,values))
 end
 selector+=")\n";request='((displayBytes 65536) (selector '+JSON.generate(selector)+'))'
 oldResult=prior && prior['scenarios'][name]
 reusable=oldResult && oldResult['requestSha256']==Digest::SHA256.hexdigest(request+"\n")
 break if !reusable && calls>=maxCalls
 File.write(out+'/'+name+'.request.scm',request+"\n")
 if reusable
  raise 'prior source identity drift' unless prior['sourceDigest']==source && prior['profileSha256']==profile && prior['sysmlProjectionSha256']==sha.call(b+'/native-projection.json')
  raise 'prior request drift' unless sha.call(priorDir+'/'+name+'.request.scm')==oldResult['requestSha256']
  raise 'prior result drift' unless sha.call(priorDir+'/'+name+'.result.scm')==oldResult['resultSha256']
  stdout=File.read(priorDir+'/'+name+'.result.scm');stderr=File.read(priorDir+'/'+name+'.stderr');success=true
 else
  stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request)
  success=status.success?;calls+=1
 end
 File.write(out+'/'+name+'.result.scm',stdout);File.write(out+'/'+name+'.stderr',stderr)
 raise 'incomplete ASCENT '+name unless success && stdout.include?('("evaluationComplete" #t)')
 values=outputs.reject { |k| k=='question' }.to_h { |k| [k,relation.call(stdout,k)] }
 raise 'source mapping incomplete' unless values['controlMapped'].sort==m['routes'].map { |r| r['id'] }.sort
 raise 'owner mismatch' unless %w[verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch].all? { |k| values[k].empty? }
 full=%w[missing-gate complete-routing-control].include?(name)
 expected=hypothetical ? (full ? 8 : 7) : 2
 raise 'incorrect evidence closure '+name unless values['verificationChecked'].size==expected
 raise 'incorrect source closure '+name unless values['controlSourceClosed'].size==(hypothetical ? 5 : 0)
 raise 'incorrect native gap '+name unless values['controlCaseMissing'].size==(hypothetical ? (full ? 0 : 1) : 7)
 raise 'wrong commit admission '+name unless values['controlCommitCandidate'].empty? == (name!='complete-routing-control')
 results[name]={hypothetical:hypothetical,relations:values,requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm')}
 results[name][:reusedFrom]=priorDir+'/receipt.json' if reusable
 File.write(out+'/receipt.json',JSON.pretty_generate({sourceDigest:source,profileSha256:profile,target:m['target'],sysmlProjectionSha256:sha.call(b+'/native-projection.json'),
   formalReceipt:formalPath,formalReceiptSha256:sha.call(formalPath),formalReexecuted:false,
   policies:%w[dev/modeling/ascent/obligation-ownership.rules.scm dev/modeling/ascent/control-refinement.rules.scm].to_h { |p| [p,sha.call(p)] },
   sourceWitnessesSha256:sha.call(out+'/source-witnesses.json'),scenarios:results,
   runtimeSourceChanged:false,nativeTestsRun:false,runtimeAdmitted:false,commitAdmitted:false})+"\n")
end
if results.size<names.size
 puts JSON.generate(checkpointOnly:true,completed:results.size,total:names.size,newCalls:calls,reused:results.size-calls,commitAdmitted:false)
 exit
end
current=results.fetch('current').fetch(:relations)
p='dev/architecture/runtime/control/control-refinement.org';text=File.read(p)
rows=m['routes'].map do |r|
  closed=current['verificationChecked'].include?(r['obligation_id'])
  sourceState=r['method']=='source' ? (current['controlSourceClosed'].include?(r['id']) ? 'closed' : 'open') : 'not a source-proof obligation'
  nativeState=r['method']=='native' ? "#{current['controlCasePassed'].size}/#{required.size} full-control case families qualified for replacement" : 'Assigned to CS-NATIVE; not executed'
  '| '+[r['obligation_id'],r['obligation_owner'],current['controlMapped'].include?(r['id']) ? 'yes' : 'no',sourceState,nativeState,closed ? 'CLOSED' : 'OPEN'].join(' | ')+" |\n"
end
table="| Obligation | Method | Source mapped | Source refined | Native status | Closure |\n|---+---+---+---+---+---|\n"+rows.join
text.sub!(/(\#\+BEGIN: ascent-view :kind control-refinement-closure[^\n]*\n).*?(\#\+END:)/m,"\\1"+table+"\\2")
File.write(p,text)
puts JSON.generate(scenarios:results.size,sourceWitnesses:witnesses.size,sourceFiles:files.size,mapped:current['controlMapped'].size,sourceRefined:current['controlSourceClosed'].size,
 remaining:current['controlOpen'].size/2,nativeCasesRequired:required.size,formalReexecuted:false,commitAdmitted:false)
