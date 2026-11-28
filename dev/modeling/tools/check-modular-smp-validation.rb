require 'json'; require 'digest'; require 'fileutils'; require 'open3'
model=ARGV.fetch(0); out=ARGV.fetch(1); prior=ARGV[2]; limit=Integer(ARGV.fetch(3,'2'))
prior=nil if prior==''
bindings=ARGV[4] && JSON.parse(File.read(ARGV[4]))
raise 'fresh output required' if File.exist?(out); FileUtils.mkdir_p(out)
sha=->p { Digest::SHA256.file(p).hexdigest }; m=JSON.parse(File.read(model))
s=sha.call(m['sourceLock']); p=sha.call(m['profile']); cases=m['lanes']
contracts=cases.map do |c|
 files=[c['program'],'vendor/gambit/tests/smp/suite.scm','vendor/gambit/tests/smp/catalog.scm']
 covered=m['coverage'].select { |x| x['lane_id']==c['id'] }.map { |x| m['contracts'].find { |q| q['id']==x['contract_id'] } }
 covered.each { |x| raise 'missing source anchor '+x['id'] unless File.read(x['source']).include?(x['anchor']) }
 payload={lane:c,coverage:covered,files:files.to_h { |f| [f,sha.call(f)] },sources:covered.to_h { |x| [x['source'],sha.call(x['source'])] }}
 [c['id'],c['kind'],Digest::SHA256.hexdigest(JSON.generate(payload))]
end
method={'make'=>'native-build-graph','kernel'=>'native-kernel','scheme'=>'native-scheme'}
data=->name,cols,rows { '(relation '+name+' ('+cols+') ('+rows.map { |r| '('+r.map { |v| JSON.generate(v.to_s) }.join(' ')+')' }.join(' ')+'))' }
if bindings
 raise 'observation binding identity differs' unless bindings['sourceLockSha256']==s && bindings['profileSha256']==p && bindings['modelSha256']==sha.call(model) && bindings['cases'].keys.sort==cases.map{|c|c['id']}.sort
end
main=bindings ? bindings.fetch('bootstrap') : '.cache/tasks/modern-c-frame-contract/runs/modular-smp-current'
outer=JSON.parse(File.read(main+'/receipt.json')); child=JSON.parse(File.read(main+'/run/receipt.json'))
raise 'main campaign unbound' unless outer['outcome']=='PASS' && outer['timeout']==false && outer['parentReaped'] && outer['processGroupQuiescent'] && outer['childReceiptSha256']==sha.call(main+'/run/receipt.json') && child['inputsStable']
raise 'bootstrap source binding differs' unless child['inputs'][File.expand_path(m['sourceLock'])]==s
lock=JSON.parse(File.read(m['sourceLock'])); lock['files'].each { |f,r| raise 'candidate drift' unless sha.call('vendor/gambit/'+f)==r['candidateSha256'] }
observed={}; evidence={}
cases.each do |lane|
 id=lane['id']; path=bindings ? bindings['cases'].fetch(id) : '.cache/tasks/modern-c-frame-contract/runs/gambit-namespaced-qualified/'+id+'/receipt.json'
 next unless File.file?(path)
 r=JSON.parse(File.read(path)); evidence[id]={path:path,sha256:sha.call(path),outcome:r['outcome'],scope:method[lane['kind']]}
 if r['outcome']!='PASS'; observed[id]='fail'; next; end
 raise 'module source or harness drift '+id unless r['programSha256']==sha.call(lane['program']) && r['runnerSha256']==sha.call('vendor/gambit/tests/smp/suite.scm') && r['planSha256']==sha.call('vendor/gambit/tests/smp/catalog.scm')
 r['runtimeSource'].each { |f,h| raise 'runtime drift '+f unless sha.call('vendor/gambit/'+f)==h }
 r['commands'].each do |c|
  raise 'incomplete process '+id unless c['exit']==0 && !c['timeout'] && c['parentReaped'] && c['processGroupQuiescent']
  raise 'output drift '+id unless sha.call(File.dirname(path)+'/'+c['output'])==c['outputSha256']
 end
 if lane['kind']=='scheme'
  raise 'Scheme output mismatch' unless File.binread(File.dirname(path)+'/run.output')==lane['stdout']
 end
 observed[id]='pass'; evidence[id].merge!(seconds:r['seconds'],executionProcessors:r['executionProcessors'])
end
boot=child['steps'].find { |x| x['id']=='bootstrap' }
raise 'incomplete bootstrap' unless boot['fullTwoPassBootstrapEstablished'] && boot['phaseCounts']==%w[phase1 phase2 phase3 phase4].to_h { |x| [x,2] }
shape='phase1=2,phase2=2,phase3=2,phase4=2'; policy='dev/modeling/ascent/modular-smp-validation.rules.scm'
previous=prior && JSON.parse(File.read(prior+'/receipt.json')); results={}; calls=0
%w[kernel-as-scheme wrong-source unknown-result single-pass all-modules-only current].each do |name|
 rows=contracts.select { |r| name!='current' || observed[r[0]] }.map { |id,k,h| [id,method[k],s,p,h,name=='current' ? observed[id] : 'pass'] }
 bootstrap=[[s,p,shape,'pass']]; gates=[]
 case name
 when 'kernel-as-scheme' then rows.find { |x| x[0]=='gambit.smp.control.continuation.map-multishot' }[1]='native-kernel'
 when 'wrong-source' then rows.each { |r| r[2]='stale' }
 when 'unknown-result' then rows<<rows.find { |x| x[0]=='gambit.smp.gc.frame-roots.single-processor' }[0..4]+['unknown']
 when 'single-pass' then bootstrap=[[s,p,'phase1=1,phase2=1,phase3=1,phase4=1','pass']]
 when 'all-modules-only' then gates=%w[tests architecture process models questions].map { |x| [x,s,'pass'] }
 end
 d='(define-evidence (query) (sources clue factor binding) (outputs question msSupplied msRejected msMissing msBootstrap msGateMissing msCommitReady) (include clue-selection-schema)'+"\n"+File.read(policy)+"\n(relation question (claim))\n((question C) <-- (msCandidate C))\n)\n"
 {'msIdentity'=>['source profile',[[s,p]]],'msLane'=>['id kind contract',contracts],
 'msObservation'=>['id method source profile contract outcome',rows],
 'msBootstrapObservation'=>['source profile phases outcome',bootstrap],
 'msGateEvidence'=>['id source outcome',gates],'msCandidate'=>['id',[['modular-smp']]]}.each { |rel,(cols,v)| d.sub!('(relation '+rel+' ('+cols+'))',data.call(rel,cols,v)) || raise('missing relation '+rel) }
 req='((displayBytes 65536) (selector '+JSON.generate(d)+'))'+"\n"; prev=previous && previous['scenarios'][name]
 reuse=prev && prev['requestSha256']==Digest::SHA256.hexdigest(req)
 break if !reuse && calls>=limit
 File.write(out+'/'+name+'.request.scm',req)
 if reuse
  raise 'prior result drift' unless sha.call(prior+'/'+name+'.result.scm')==prev['resultSha256'] && sha.call(prior+'/'+name+'.request.scm')==prev['requestSha256']
  stdout=File.read(prior+'/'+name+'.result.scm'); stderr=File.read(prior+'/'+name+'.stderr'); ok=true
 else
  stdout,stderr,status=Open3.capture3('.venv/bin/gambit-smp','--task','modern-c-frame-contract','trajectory','clues',req.chomp); ok=status.success?; calls+=1
 end
 File.write(out+'/'+name+'.result.scm',stdout); File.write(out+'/'+name+'.stderr',stderr)
 raise 'incomplete ASCENT '+name unless ok && stdout.include?('("evaluationComplete" #t)') && stdout.include?('("msCommitReady" ())')
 expected=case name; when 'current' then observed.select { |_,v| v=='pass' }.keys; when 'wrong-source' then []; when 'kernel-as-scheme' then cases.map { |c| c['id'] }-['gambit.smp.control.continuation.map-multishot']; when 'unknown-result' then cases.map { |c| c['id'] }-['gambit.smp.gc.frame-roots.single-processor']; else cases.map { |c| c['id'] }; end
 # Parse only the supplied unary relation; do not count explanatory text.
 supplied=stdout[/\("msSupplied" (\(.*?\))\) (?=\(")/,1]
 raise 'missing supplied relation' unless supplied
 actual=supplied.scan(/"([a-z0-9.-]+)"/).flatten
 raise 'method/source classification failure '+name unless actual.sort==expected.sort
 raise 'one pass promoted' if name=='single-pass' && !stdout.include?('("msBootstrap" ())')
 results[name]={synthetic:name!='current',requestSha256:sha.call(out+'/'+name+'.request.scm'),resultSha256:sha.call(out+'/'+name+'.result.scm'),supplied:actual.sort,commitReady:false}
 File.write(out+'/receipt.json',JSON.pretty_generate({modelSha256:sha.call(model),policySha256:sha.call(policy),sourceLockSha256:s,profileSha256:p,evidence:evidence,bootstrap:{path:main+'/receipt.json',sha256:sha.call(main+'/receipt.json')},scenarios:results,complete:results.size==6,formalReexecuted:false,remoteCIExecuted:false,commitAdmitted:false})+"\n")
end
puts JSON.generate(controls:results.size,localObserved:observed.size,complete:results.size==6,commitAdmitted:false)
