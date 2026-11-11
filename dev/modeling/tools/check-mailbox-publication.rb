require 'json'; require 'digest'; require 'fileutils'; require 'open3'
model=ARGV.fetch(0); out=ARGV.fetch(1); runs=ARGV[2]
raise 'fresh output required' if File.exist?(out);FileUtils.mkdir_p(out)
sha=->p{Digest::SHA256.file(p).hexdigest};m=JSON.parse(File.read(model));s=sha.call(m['sourceLock']);p=sha.call(m['profile'])
lock=JSON.parse(File.read(m['sourceLock']))
lock['files'].each{|f,r|raise 'source drift '+f unless sha.call('vendor/gambit/'+f)==r['candidateSha256']}
m['responsibilities'].each{|r|raise 'missing source anchor' unless File.read(r['source']).include?(r['anchor'])}
formal=m.fetch('formalBoundaries').to_h do |r|
 kind=r['owner']=='quint' ? '(?:val|action|run)' : 'theorem'
 raise 'original declaration missing' unless File.read(r['artifact']).match?(/\b#{kind}\s+#{Regexp.escape(r['declaration'])}\b/)
 [r['id'],{owner:r['owner'],artifact:r['artifact'],sha256:sha.call(r['artifact']),scope:r['scope'],executed:false,mailboxTheorem:false}]
end
needs=m['obligations'].map{|r|[r['id'],r['method']]};observed=[];records={}
base='.cache/tasks/modern-c-frame-contract'
old=base+'/cohort/mailbox-source-witness/launch.stdout';fixed=base+'/cohort/mailbox-fixed-source-witness-launch.stdout'
raise 'negative witness changed' unless File.read(old).include?('expected 32 observed #(33 (33 34)) writer-excluded #f gc-delta 0.')
raise 'candidate witness changed' unless File.read(fixed).include?('expected 32 observed #(32 (32 33)) writer-excluded #t gc-delta 0.') && File.read(fixed).include?('SOURCE-MAILBOX-EXCLUSION-PASS messages=64')
old_lock=JSON.parse(File.read('evidence/research/modular-smp-bootstrap/qualified/source.lock.json'))
raise 'baseline source drift' unless sha.call(base+'/cohort/mailbox-baseline/thread.scm')==old_lock['files']['lib/_thread.scm']['candidateSha256']
# AST files are exact executable Scheme evidence: the native projector requires
# exactly one source point; identities bind those files and both source texts.
%w[mailbox-source-witness mailbox-fixed-source-witness].each{|d|raise 'missing source projection' unless File.file?(base+'/cohort/'+d+'/witness.scm.source.scm')}
observed<<['source-interleave','source-projection',s,p,'pass']
history=base+'/runs/mailbox-publication/boundaries/observations.scm'
text=File.read(history);statuses=text.scan(/\(raw-wait-status \. ([^\)]+)\)/).flatten
raise 'incomplete baseline campaign' unless statuses.size==73 && statuses.all?{|x|x=='0'} && text.scan('(reader-completed . #t)').size==73
observed<<['bounded-controls','native-scheme-history',s,p,'pass']
boot=[];boot_path=base+'/runs/mailbox-native-qualified/receipt.json'
if File.file?(boot_path)
 r=JSON.parse(File.read(boot_path)); child_path=File.dirname(boot_path)+'/run/receipt.json';c=JSON.parse(File.read(child_path))
 raise 'bootstrap binding changed' unless r['childReceiptSha256']==sha.call(child_path)
 b=c['steps'].find{|x|x['id']=='bootstrap'}
 if r['outcome']=='PASS' && !r['timeout'] && r['parentReaped'] && r['processGroupQuiescent'] && c['inputsStable'] && b['fullTwoPassBootstrapEstablished'] && b['phaseCounts']==%w[phase1 phase2 phase3 phase4].to_h{|x|[x,2]}
  raise 'bootstrap source binding changed' unless c['inputs'][File.expand_path(m['sourceLock'])]==s
  boot=[[s,p]];records['bootstrap']={path:boot_path,sha256:sha.call(boot_path),outcome:r['outcome']}
 end
end
mapping={'ordered'=>'ordered-shared-values','blocked-cell'=>'blocked-cell-roots','first-publishers'=>'concurrent-first-publishers'}
corrections=ARGV[3] ? JSON.parse(File.read(ARGV[3])) : {}
raise 'unsupported fixture successor' unless (corrections.keys-['first-publishers']).empty?
mapping.each do |id,name|
 path=runs && runs+'/gambit.smp.scheduler.mailbox.'+name+'/receipt.json';next unless path && File.file?(path)
 previous=nil
 if corrections[id]
  previous=path;path=corrections[id];old=JSON.parse(File.read(previous))
  program=m['obligations'].find{|o|o['id']==id}['program']
  old_text=File.read(File.dirname(previous)+'/fixture.scm')
  raise 'fixture correction must preserve workload and deadline' unless old_text.sub('(make-time deadline)','(seconds->time deadline)')==File.read(program) && old['outcome']=='FAIL' && old['programSha256']==sha.call(File.dirname(previous)+'/fixture.scm') && File.read(File.dirname(previous)+'/run.output').include?('Operator is not a PROCEDURE')
 end
 r=JSON.parse(File.read(path));status=r['outcome']=='PASS' ? 'pass' : 'fail'
 if status=='pass'
  %w[lib/_thread.scm lib/_fifo#.scm].each{|f|raise 'runtime source mismatch' unless r['runtimeSource'][f]==lock['files'][f]['candidateSha256']}
  raise 'fixture or harness drift' unless r['programSha256']==sha.call(m['obligations'].find{|o|o['id']==id}['program']) && r['runnerSha256']==sha.call('vendor/gambit/tests/smp/suite.scm') && r['planSha256']==sha.call('vendor/gambit/tests/smp/catalog.scm')
  r['commands'].each{|cmd|raise 'incomplete native custody' unless cmd['exit']==0 && !cmd['timeout'] && cmd['parentReaped'] && cmd['processGroupQuiescent'];raise 'native output drift' unless sha.call(File.dirname(path)+'/'+cmd['output'])==cmd['outputSha256']}
 end
 observed<<[id,'native-scheme',s,p,status];records[id]={path:path,sha256:sha.call(path),outcome:r['outcome']}
 records[id][:retainedFixtureFailure]={path:previous,sha256:sha.call(previous),outcome:'FAIL',change:'make-time -> exported seconds->time; absolute deadline unchanged'} if previous
end
policy='dev/modeling/ascent/mailbox-publication.rules.scm'
data=->rel,cols,rows{'(relation '+rel+' ('+cols+') ('+rows.map{|row|'('+row.map{|v|JSON.generate(v)}.join(' ')+')'}.join(' ')+'))'}
results={}
%w[current wrong-source projection-as-native unknown-result all-scoped-only].each do |name|
 rows=Marshal.load(Marshal.dump(observed));bootstrap=boot;gates=[]
 case name
 when 'wrong-source' then rows.each{|r|r[2]='stale'}
 when 'projection-as-native' then rows.find{|r|r[0]=='source-interleave'}[1]='native-scheme'
 when 'unknown-result' then rows<<['source-interleave','source-projection',s,p,'unknown']
 when 'all-scoped-only' then rows=needs.map{|id,method|[id,method,s,p,'pass']};bootstrap=[[s,p]];gates=%w[tests architecture process models questions].map{|g|[g,s]}
 end
 body=File.read(policy)
 {'mbIdentity'=>['source profile',[[s,p]]],'mbNeed'=>['id method',needs],'mbObservation'=>['id method source profile outcome',rows],'mbBootstrap'=>['source profile',bootstrap],'mbGateReceipt'=>['id source',gates]}.each{|rel,(cols,items)|body.sub!('(relation '+rel+' ('+cols+'))',data.call(rel,cols,items))||raise('missing relation '+rel)}
 d="(define-evidence (query) (sources clue factor binding) (outputs question mbSupplied mbMissing mbRejected mbScopedClosure mbHistoricalSchedule mbCommitReady) (include clue-selection-schema)\n"+body+"\n(relation question (claim))\n((question I) <-- (mbNeed I _))\n)\n"
 req='((displayBytes 65536) (selector '+JSON.generate(d)+'))'+"\n"
 File.write(out+'/'+name+'.request.scm',req)
 stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',req.chomp)
 File.write(out+'/'+name+'.result.scm',stdout);File.write(out+'/'+name+'.stderr',stderr)
 raise 'incomplete ASCENT '+name unless status.success? && stdout.include?('("evaluationComplete" #t)') && stdout.include?('("mbCommitReady" ())') && stdout.include?('("mbHistoricalSchedule" ())')
 supplied=stdout[/\("mbSupplied" (\(.*?\))\) (?=\(")/,1];raise 'missing result' unless supplied
 actual=supplied.scan(/"([a-z0-9.-]+)"/).flatten.sort
 expected=case name;when 'wrong-source' then [];when 'projection-as-native','unknown-result' then observed.select{|r|r[4]=='pass'}.map(&:first)-['source-interleave'];when 'all-scoped-only' then needs.map(&:first);else observed.select{|r|r[4]=='pass'}.map(&:first);end
 raise 'invalid evidence classification '+name unless actual==expected.sort
 results[name]={synthetic:name!='current',supplied:actual,commitReady:false,requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm')}
end
File.write(out+'/receipt.json',JSON.pretty_generate({modelSha256:sha.call(model),sourceLockSha256:s,profileSha256:p,policySha256:sha.call(policy),scenarios:results,observed:records,formalBoundaries:formal,baselineTrials:72,bootstrapEstablished:!boot.empty?,historicalScheduleResolved:false,formalReexecuted:false,commitAdmitted:false})+"\n")
puts JSON.generate(controls:results.size,observations:observed.size,bootstrap:!boot.empty?,commit:false)
