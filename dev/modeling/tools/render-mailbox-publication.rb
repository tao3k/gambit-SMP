require 'json';require 'digest';require 'fileutils';require 'zlib'
m=JSON.parse(File.read(ARGV.fetch(0)));a=JSON.parse(File.read(ARGV.fetch(1)+'/receipt.json'));sha=->p{Digest::SHA256.file(p).hexdigest}
raise 'projection/evidence mismatch' unless a['modelSha256']==sha.call(ARGV[0])
plan=JSON.parse(File.read('evidence/research/modular-smp-bootstrap/ci-plan.json'))
raise 'CI and mailbox authority differ' unless plan['sourceLock']==m['sourceLock'] && plan['profile']==m['profile']
cases=plan['lanes'].to_h do |lane|
 path='.cache/tasks/modern-c-frame-contract/runs/mailbox-named-cases/'+lane['id']+'/receipt.json'
 path=a['observed']['first-publishers']['path'] if lane['name']=='concurrent-first-publishers'
 r=JSON.parse(File.read(path))
 raise 'current case not qualified '+lane['id'] unless r['outcome']=='PASS' && r['module']==lane['id'] && r['programSha256']==sha.call(lane['program']) && r['runnerSha256']==sha.call('vendor/gambit/tests/smp/suite.scm') && r['planSha256']==sha.call('vendor/gambit/tests/smp/catalog.scm')
 r['runtimeSource'].each{|f,h|raise 'runtime source drift' unless sha.call('vendor/gambit/'+f)==h}
 r['commands'].each{|c|raise 'native custody incomplete' unless c['exit']==0 && !c['timeout'] && c['parentReaped'] && c['processGroupQuiescent'];raise 'output drift' unless sha.call(File.dirname(path)+'/'+c['output'])==c['outputSha256']}
 raise 'Scheme result drift' if lane['kind']=='scheme' && File.binread(File.dirname(path)+'/run.output')!=lane['stdout']
 [lane['id'],{path:path,sha256:sha.call(path),kind:lane['kind'],outcome:r['outcome'],seconds:r['seconds'],processors:r['executionProcessors']}]
end
repeats={}
%w[boundaries qualified-boundaries].each do |name|
 dir='.cache/tasks/modern-c-frame-contract/runs/mailbox-publication/'+name
 text=File.read(dir+'/observations.scm');statuses=text.scan(/\(raw-wait-status \. ([^\)]+)\)/).flatten
 raise 'incomplete repeat campaign '+name unless statuses.size==73 && statuses.all?{|v|v=='0'} && text.scan('(reader-completed . #t)').size==73
 {'original'=>nil,'serial'=>'both','no-gc'=>'none','sender-gc'=>'sender','receiver-gc'=>'receiver','both-gc'=>'both'}.each do |group,mode|
  expected=mode ? '(MAILBOX-BOUNDARIES-PASS '+JSON.generate(mode)+' 64)'+"\n" : "MAILBOX-ROOTS-PASS messages=64\n"
  12.times{|i|raise 'repeat output drift' unless File.binread(dir+'/'+group+'-'+i.to_s+'.output')==expected}
 end
 repeats[name]={observations:72,currentRuntimeControls:name=='qualified-boundaries' ? 60 : 0,immutableOriginalControls:12,rawWaitStatusPassed:true,independentProcessGroupClaim:false,receipt:dir+'/observations.scm',sha256:sha.call(dir+'/observations.scm')}
end
modularPath='.cache/tasks/modern-c-frame-contract/cohort/mailbox-modular-qualified/receipt.json'
modular=JSON.parse(File.read(modularPath))
raise 'current modular controls incomplete' unless modular['complete'] && modular['sourceLockSha256']==a['sourceLockSha256'] && modular['scenarios'].size==6 && modular['scenarios']['current']['supplied'].size==cases.size && !modular['commitAdmitted']
org='dev/refactoring/modern-c/mailbox-publication.org';text=File.read(org)
rows="| Responsibility | Retirement | Added work / ownership cost |\n|---+---+---|\n"+m['responsibilities'].map{|r|"| =#{r['id']}= | #{r['retires']} | #{r['added']} |\n"}.join
text.sub!(/(\#\+BEGIN: sysml-view :kind mailbox-responsibilities\n).*?(\#\+END:)/m){$1+rows+$2}||raise('missing view')
rows="| Obligation / control | Observation | Limit |\n|---+---+---|\n"
a['scenarios'].each{|n,r|rows<<"| #{n} | #{r['supplied'].size}/#{m['obligations'].size} supplied#{r['synthetic'] ? '; synthetic control' : ''} | commit blocked; historical schedule unknown |\n"}
a['observed'].each{|id,r|rows<<"| #{id} | #{r['outcome']} | exact receipt hash; local evidence only |\n"}
cases.each{|id,r|rows<<"| =#{id}= | #{r[:outcome]} | #{r[:kind]}; #{r[:processors] || 'kernel/build'} processors; exact current-source receipt |\n"}
rows<<"| Complete named-module ASCENT | 6/6 controls;11 current observations | canonical architecture absent; commit blocked |\n"
rows<<"| Baseline repeats | 72/72 | 12 immutable original +60 boundary controls; no historical cause inference |\n| Candidate repeats | 72/72 | 12 immutable original +60 current-runtime boundary controls; no rate/speed claim |\n"
text.sub!(/(\#\+BEGIN: ascent-view :kind mailbox-observations\n).*?(\#\+END:)/m){$1+rows+$2}||raise('missing view')
text.sub!('CANDIDATE-NATIVE-QUALIFICATION-OPEN',a['bootstrapEstablished'] ? 'BOOTSTRAP-OBSERVED; SCOPED-TEST-RESULTS-BELOW' : 'CANDIDATE-NATIVE-QUALIFICATION-OPEN')
File.write(org,text)
global='dev/refactoring/modern-c/modular-smp-validation.org';g=File.read(global)
body="| Current named case | Native result | Scope |\n|---+---+---|\n"+cases.map{|id,r|"| =#{id}= | #{r[:outcome]} | #{r[:kind]}; exact current-source receipt |\n"}.join
if !g.include?('#+BEGIN: ascent-view :kind current-mailbox-source-cases')
 g+="\n* Current mailbox source qualification\n:PROPERTIES:\n:CUSTOM_ID: current-mailbox-source-qualification\n:AUTHORITY: GambitMailboxPublication; GambitModularSmpValidation\n:STATUS: LOCAL-BOUNDED-CASES-PASS; BROAD-SMP-AND-COMMIT-OPEN\n:END:\nThe source successor has a complete two-pass bootstrap (345.995 seconds for\nthe actual command under the original600-second cap) and eleven named native\ncase receipts. The original campaign's first-publisher fixture failure remains\nFAIL; the one-API constructor correction has its own source-bound receipt.\nSix actual module ASCENT controls supply eleven current observations without\nproducing commit authority. Previous nine-case rows remain historical.\n\n#+BEGIN: ascent-view :kind current-mailbox-source-cases\n#+END:\n"
end
g.sub!(/([#][+]BEGIN: ascent-view :kind current-mailbox-source-cases\n).*?([#][+]END:)/m){$1+body+$2}||raise('missing global view')
File.write(global,g)

d="direction: down\nvars: { d2-config: { layout-engine: elk } }\n"
d<<"authority: \"Native SysML: responsibilities / transfer / obligation\"\n"
m['responsibilities'].each{|r|d<<r['id']+': '+JSON.generate(r['id']+"\n"+r['anchor'])+"\n";d<<'authority -> '+r['id']+"\n"}
m['transfers'].each{|t|d<<t['origin_id']+' -> '+t['destination_id']+': '+JSON.generate(t['condition'].scan(/.{1,60}(?:\s|$)|\S+/).map(&:strip).join("\n"))+"\n"}
d<<"source: \"Actual SMP receive AST\\nold: observes33 / GC0\\ncandidate: excludes writer / gets32 /64 messages\"\n"
d<<"native: "+JSON.generate("Built-in mailbox / blocked-cell GC / first publishers\nexact source and native process receipts")+"\n"
d<<"ascent: "+JSON.generate("ASCENT: method, identity, conflicts and missing evidence")+"\n"
d<<"formal: "+JSON.generate("Existing continuation QNT / root-view Lean\nno mailbox queue theorem or duplicated models")+"\n"
d<<"open: "+JSON.generate("Historical schedule unknown / portable lock proof open\nwhole SMP and five commit gates remain open")+"\n"
d<<"authority -> ascent\nsource -> ascent\nnative -> ascent\nformal -> ascent\nascent -> open\n"
File.write('dev/refactoring/modern-c/diagrams/mailbox-publication.d2',d)
e='evidence/research/mailbox-publication';FileUtils.mkdir_p(e+'/records');records={}
retain=->path do
 next unless File.file?(path)
 h=sha.call(path);dest=e+'/records/'+h[0,16]+'-'+File.basename(path)
 if File.size(path)>65536
  dest+='.gz';unless File.exist?(dest);Zlib::GzipWriter.open(dest){|g|g.mtime=0;g.write(File.binread(path))};end
  raise 'archive drift' unless Zlib::GzipReader.open(dest){|g|Digest::SHA256.hexdigest(g.read)}==h
 else
  if File.exist?(dest);raise 'archive drift' unless sha.call(dest)==h;else FileUtils.cp(path,dest);end
 end
 records[path]={path:dest,sourceSha256:h,storedSha256:sha.call(dest)}
end
[File.dirname(ARGV[0]),ARGV[1],File.dirname(modularPath),e,'.cache/tasks/modern-c-frame-contract/cohort/mailbox-source-witness','.cache/tasks/modern-c-frame-contract/cohort/mailbox-fixed-source-witness','.cache/tasks/modern-c-frame-contract/runs/mailbox-publication/boundaries'].each do |dir|
 Dir.glob(dir+'/**/*').each{|p|retain.call(p) if !p.include?('/records/') && p!=e+'/validation.json' && p.match?(/\.(scm|json|stdout|stderr|log|output|tsv)$/)}
end
%w[mailbox-native-current mailbox-native-managed mailbox-native-qualified mailbox-native-bootstrap mailbox-named-cases].each do |name|
 Dir.glob('.cache/tasks/modern-c-frame-contract/runs/'+name+'/**/*').each{|p|retain.call(p) if p.match?(/\.(json|stdout|stderr|log|output|scm)$/) && !p.include?('/source/') && !p.include?('/generation/')}
end
cases.each_value{|r|Dir.glob(File.dirname(r[:path])+'/*').each{|p|retain.call(p) if p.match?(/\.(scm|json|output)$/)}}
Dir.glob('.cache/tasks/modern-c-frame-contract/runs/mailbox-publication/qualified-boundaries/*').each{|p|retain.call(p) if p.match?(/\.(scm|json|output)$/)}
Dir.glob('.cache/tasks/modern-c-frame-contract/cohort/mailbox-*').each{|p|retain.call(p) if File.file?(p)}
[org,'dev/refactoring/modern-c/models/sysml/mailbox-publication.sysml','dev/refactoring/modern-c/models/sysml/modular-smp-validation.sysml','dev/modeling/ascent/mailbox-publication.rules.scm',__FILE__,'dev/modeling/tools/check-mailbox-publication.rb','dev/modeling/tools/project-mailbox-publication.rb','dev/modeling/tools/project-mailbox-witness.scm','vendor/gambit/tests/smp/suite.scm','vendor/gambit/tests/smp/catalog.scm','vendor/gambit/tests/smp/campaign.scm','vendor/gambit/lib/_thread.scm','vendor/gambit/lib/_fifo#.scm','dev/refactoring/modern-c/diagrams/mailbox-publication.d2'].each{|p|retain.call(p)}
m['obligations'].each{|r|retain.call(r['program'])}
retain.call('.cache/tasks/modern-c-frame-contract/cohort/mailbox-baseline/thread.scm')
retain.call('.cache/tasks/modern-c-frame-contract/cohort/mailbox-baseline/publication-evidence.scm')
retain.call('dev/modeling/tools/check-modular-smp-validation.rb')
retain.call('dev/modeling/ascent/modular-smp-validation.rules.scm')
retain.call('dev/modeling/tools/project-modular-smp-validation.rb')
retain.call('dev/refactoring/modern-c/diagrams/mailbox-publication.svg')
Dir.glob('.cache/tasks/modern-c-frame-contract/runs/gambit-shell-qualified/mailbox-roots/*').each{|p|retain.call(p) if p.match?(/\.(json|stdout|stderr|scm)$/)}
base='.cache/tasks/modern-c-frame-contract';bins=[base+'/runs/gambit-shell-qualified/mailbox-roots/fixture',base+'/cohort/mailbox-source-witness/witness',base+'/cohort/mailbox-fixed-source-witness/witness',base+'/runs/mailbox-publication/boundaries/boundaries']
summary=a.merge(scope:'Mailbox source responsibility replacement, native observations and unresolved historical schedule',qualifiedCases:cases,repeatedControls:repeats,moduleAscent:{path:modularPath,sha256:sha.call(modularPath),controls:6,currentObservations:cases.size,commit:false},records:records,retainedBinaries:bins.to_h{|p|[p,{sha256:sha.call(p),bytes:File.size(p),storedInGit:false}]},heapIncreased:false,waitExtended:false,qntLeanDuplicated:false,modernCHead:`git -C vendor/gambit rev-parse HEAD`.strip)
File.write(e+'/validation.json',JSON.pretty_generate(summary)+"\n")
puts JSON.generate(records:records.size,bootstrap:a['bootstrapEstablished'],commit:false)
