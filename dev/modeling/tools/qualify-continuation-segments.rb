require 'json';require 'digest';require 'fileutils';require 'open3'
b='.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-model'
out=ARGV.fetch(0);raise 'fresh output required' if File.exist?(out);FileUtils.mkdir_p(out)
sha=->p { Digest::SHA256.file(p).hexdigest }
m=JSON.parse(File.read(b+'/native-projection.json'))
raise 'SysML failure' unless JSON.parse(File.read(b+'/native-metadata.json'))['exit']==0
raise 'wrong obligation ownership' unless m['obligations'].count { |o| o['owner']=='quint' }==1 && m['obligations'].count { |o| o['owner']=='lean' }==1
lock=JSON.parse(File.read(m.fetch('sourceLock')))
lock['files'].each { |_,f| raise 'reference drift' unless sha.call(f['path'])==f['sha256'] && sha.call(f['source'])==f['sha256'] }
formalPath='.cache/tasks/modern-c-frame-contract/cohort/continuation-segments-separated/receipt.json'
f=JSON.parse(File.read(formalPath));raise 'formal failure' unless f['rows'].size==13 && f['rows'].all? { |r| r['matched'] }
f['artifacts'].each { |p,h| raise 'formal drift' unless sha.call(p)==h }
f['rows'].each { |r| raise 'formal log drift' unless sha.call(File.dirname(formalPath)+'/'+r['id']+'.log')==r['logSha256'] }
q=f['artifacts'].keys.find { |p| p.end_with?('.qnt') };l=f['artifacts'].keys.find { |p| p.end_with?('.lean') }
raise 'payload algebra leaked into Quint' if File.read(q).match?(/\b(?:imageValue|viewValue|sharedValue|lastValue|Coherent)\b/)
raise 'scheduler leaked into Lean' if File.read(l).match?(/\b(?:windDelta|beginHook|hookTakeover|commitResume|safe)\b/)
rules='dev/modeling/ascent/obligation-ownership.rules.scm'
obligations=m['obligations'].map do |o|
  raise 'missing obligation artifact' unless File.file?(o['artifact'])
  [o['id'],o['semanticKey'],o['owner'],o['artifact'],sha.call(o['artifact']),o['scope']]
end
observed=m['obligations'].select { |o| %w[quint lean].include?(o['owner']) }.map do |o|
  raise 'unexecuted model route' unless f['artifacts'][o['artifact']]==sha.call(o['artifact'])
  kind=o['owner']=='quint' ? '(?:val|action|run)' : 'theorem'
  raise 'missing route declaration' unless File.read(o['artifact']).match?(/\b#{kind}\s+#{Regexp.escape(o['declaration'])}\b/)
  [o['id'],o['owner'],o['artifact'],sha.call(o['artifact']),o['scope']]
end
relation=lambda do |text,name|
  i=text.index('("'+name+'" ');raise 'missing output '+name unless i
  part=text[(i+name.size+4)..];depth=0;quoted=false;escaped=false;past=nil
  part.each_char.with_index do |ch,n|
    if quoted
      if escaped then escaped=false elsif ch=='\\' then escaped=true elsif ch=='"' then quoted=false end
    elsif ch=='"' then quoted=true
    elsif ch=='(' then depth+=1
    elsif ch==')' then depth-=1;if depth==0 then past=n;break end
    end
  end
  raise 'incomplete output' unless past
  part[0..past].scan(/"(?:\\.|[^"\\])*"/).map { |s| JSON.parse(s) }
end
data=->name,columns,rows { '(relation '+name+' ('+columns+') ('+rows.map { |r| '('+r.map { |x| JSON.generate(x) }.join(' ')+')' }.join(' ')+'))' }
results={}
%w[current dual-owner renamed-overlap wrong-owner-evidence wrong-domain].each do |scenario|
  os=obligations.map(&:dup);es=observed.map(&:dup)
  if scenario=='dual-owner'
    extra=os.find { |r| r[0]=='CS-SCHEDULE' }.dup;extra[2]='lean';os<<extra
  elsif scenario=='renamed-overlap'
    extra=os.find { |r| r[0]=='CS-COHERENCE' }.dup;extra[0]='CS-COHERENCE-RENAMED';os<<extra
  elsif scenario=='wrong-owner-evidence'
    es.find { |r| r[0]=='CS-COHERENCE' }[1]='quint'
  elsif scenario=='wrong-domain'
    os.find { |r| r[0]=='CS-COHERENCE' }[2]='quint'
  end
  selector="(define-evidence (query) (sources clue factor binding) (outputs question verificationChecked verificationMissing verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch verificationReady verificationComponentGap) (include clue-selection-schema)\n"+File.read(rules)
  rows={
    'verificationObligation'=>['id semantic owner artifact digest scope',os],
    'verificationDomain'=>['owner domain',m.fetch('responsibilities').flat_map { |r| r['domains'].split(';').map { |d| [r['id'],d] } }],
    'verificationKeyDomain'=>['semantic domain',os.map { |r| [r[1],r[1].split('/').first] }.uniq],
    'verificationObservation'=>['id owner artifact digest scope',es],
    'verificationUse'=>['component obligation',m['uses'].map { |u| [u['facet'],u['obligation']] }],
    'verificationCandidate'=>['id',[['continuation-segments']]]
  }
  rows.each do |name,(columns,values)|
    decl='(relation '+name+' ('+columns+'))';raise 'missing policy declaration' unless selector.include?(decl)
    selector.sub!(decl,data.call(name,columns,values))
  end
  selector+=")\n";request='((displayBytes 65536) (selector '+JSON.generate(selector)+'))'
  File.write(out+'/'+scenario+'.request.scm',request+"\n")
  stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',request)
  File.write(out+'/'+scenario+'.result.scm',stdout);File.write(out+'/'+scenario+'.stderr',stderr)
  raise 'incomplete ASCENT '+scenario unless status.success? && stdout.include?('("evaluationComplete" #t)')
  checked=relation.call(stdout,'verificationChecked');missing=relation.call(stdout,'verificationMissing')
  conflicts=relation.call(stdout,'verificationOwnerConflict');overlap=relation.call(stdout,'verificationSemanticOverlap')
  mismatches=relation.call(stdout,'verificationRoleMismatch');ready=relation.call(stdout,'verificationReady')
  expected=%w[current renamed-overlap].include?(scenario) ? 2 : 1
  raise 'wrong evidence matches' unless checked.size==expected && ready.empty?
  raise 'missing bridge disappeared' unless missing.include?('CS-BRIDGE')
  raise 'dual-owner escaped' if scenario=='dual-owner' && conflicts.empty?
  raise 'semantic alias escaped' if scenario=='renamed-overlap' && overlap.empty?
  raise 'wrong responsibility escaped' if scenario=='wrong-domain' && mismatches.empty?
  raise 'current ownership invalid' if scenario=='current' && !(conflicts+overlap+mismatches).empty?
  results[scenario]={checked:checked,missing:missing.each_slice(2).to_a,ownerConflicts:conflicts.each_slice(3).to_a,
    semanticOverlap:overlap.each_slice(3).to_a,roleMismatch:mismatches.each_slice(3).to_a,ready:ready,
    requestSha256:sha.call(out+'/'+scenario+'.request.scm'),resultSha256:sha.call(out+'/'+scenario+'.result.scm')}
  File.write(out+'/receipt.json',JSON.pretty_generate({sourceLockSha256:sha.call(m['sourceLock']),sysmlProjectionSha256:sha.call(b+'/native-projection.json'),
    policySha256:sha.call(rules),formalReceiptSha256:sha.call(formalPath),obligations:8,quintObligations:1,leanObligations:1,
    remainingSourceNativeObligations:6,scenarios:results,runtimeAdmitted:false,commitAdmitted:false})+"\n")
end
puts JSON.generate(scenarios:results.size,uniqueQuintObligations:1,uniqueLeanObligations:1,remaining:6,commitAdmitted:false)
